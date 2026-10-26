import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const luaCandidates = [
  path.resolve(root, "../Builds.lua"), // AZSBuildBook/web next to addon
  path.resolve(root, "../benilla-config/AddOns/AZSBuildBook/Builds.lua"),
];
const luaPath = luaCandidates.find((p) => fs.existsSync(p));
if (!luaPath) {
  console.error("Builds.lua not found. Tried:\n" + luaCandidates.join("\n"));
  process.exit(1);
}
const outPath = path.resolve(root, "src/data/builds.json");

let src = fs.readFileSync(luaPath, "utf8");
src = src.replace(/--[^\n]*/g, "");

const buildsStart = src.indexOf("AZSBuildBook_Builds");
const orderStart = src.indexOf("AZSBuildBook_ClassOrder");
if (buildsStart < 0 || orderStart < 0) {
  console.error("Missing tables");
  process.exit(1);
}

const buildsAssign = src.slice(buildsStart, orderStart);
const orderAssign = src.slice(orderStart);

function extractTable(assign) {
  const eq = assign.indexOf("=");
  const from = assign.indexOf("{", eq);
  let depth = 0;
  for (let i = from; i < assign.length; i++) {
    const ch = assign[i];
    if (ch === "{") depth++;
    else if (ch === "}") {
      depth--;
      if (depth === 0) return assign.slice(from, i + 1);
    }
  }
  throw new Error("Unbalanced table");
}

/** Convert Lua table literal to JSON text */
function luaToJson(lua) {
  // Tokenize roughly: strings, braces, equals, commas, barewords, numbers
  const tokens = [];
  let i = 0;
  while (i < lua.length) {
    const c = lua[i];
    if (/\s/.test(c)) {
      i++;
      continue;
    }
    if (c === '"' || c === "'") {
      const q = c;
      let j = i + 1;
      let out = '"';
      while (j < lua.length) {
        const ch = lua[j];
        if (ch === "\\") {
          out += ch + (lua[j + 1] || "");
          j += 2;
          continue;
        }
        if (ch === q) break;
        if (ch === '"') out += '\\"';
        else out += ch;
        j++;
      }
      out += '"';
      tokens.push({ t: "str", v: out });
      i = j + 1;
      continue;
    }
    if (c === "{" || c === "}" || c === "," || c === "=") {
      tokens.push({ t: c });
      i++;
      continue;
    }
    if (/[A-Za-z_]/.test(c)) {
      let j = i + 1;
      while (j < lua.length && /[A-Za-z0-9_]/.test(lua[j])) j++;
      tokens.push({ t: "id", v: lua.slice(i, j) });
      i = j;
      continue;
    }
    if (/[0-9.]/.test(c)) {
      let j = i + 1;
      while (j < lua.length && /[0-9.]/.test(lua[j])) j++;
      tokens.push({ t: "num", v: lua.slice(i, j) });
      i = j;
      continue;
    }
    throw new Error(`Unexpected char ${c} at ${i}`);
  }

  // Parse table recursively from token stream
  let p = 0;
  function parseValue() {
    const tok = tokens[p];
    if (!tok) throw new Error("EOF");
    if (tok.t === "{") return parseTable();
    if (tok.t === "str" || tok.t === "num") {
      p++;
      return tok.v;
    }
    if (tok.t === "id") {
      p++;
      if (tok.v === "true" || tok.v === "false" || tok.v === "null") return tok.v;
      throw new Error(`Bare id value ${tok.v}`);
    }
    throw new Error(`Bad value token ${tok.t}`);
  }

  function parseTable() {
    if (tokens[p].t !== "{") throw new Error("Expected {");
    p++;
    const entries = []; // {kind:'arr', value} | {kind:'kv', key, value}
    while (p < tokens.length && tokens[p].t !== "}") {
      if (tokens[p].t === ",") {
        p++;
        continue;
      }
      // key = value ?
      if (
        tokens[p].t === "id" &&
        tokens[p + 1] &&
        tokens[p + 1].t === "="
      ) {
        const key = tokens[p].v;
        p += 2;
        const value = parseValue();
        entries.push({ kind: "kv", key, value });
        continue;
      }
      if (
        tokens[p].t === "str" &&
        tokens[p + 1] &&
        tokens[p + 1].t === "="
      ) {
        const key = tokens[p].v;
        p += 2;
        const value = parseValue();
        entries.push({ kind: "kv", key: key, value });
        continue;
      }
      const value = parseValue();
      entries.push({ kind: "arr", value });
    }
    if (tokens[p]?.t !== "}") throw new Error("Expected }");
    p++;

    const hasKv = entries.some((e) => e.kind === "kv");
    const hasArr = entries.some((e) => e.kind === "arr");
    if (hasKv && hasArr) {
      // Mixed — treat as object, array parts with numeric keys
      const parts = [];
      let n = 0;
      for (const e of entries) {
        if (e.kind === "kv") parts.push(`${JSON.stringify(e.key)}:${e.value}`);
        else {
          n++;
          parts.push(`"${n}":${e.value}`);
        }
      }
      return `{${parts.join(",")}}`;
    }
    if (hasKv) {
      return `{${entries
        .map((e) => `${JSON.stringify(e.key)}:${e.value}`)
        .join(",")}}`;
    }
    return `[${entries.map((e) => e.value).join(",")}]`;
  }

  const json = parseValue();
  if (p !== tokens.length) {
    // trailing junk ok if whitespace already stripped
  }
  return json;
}

const buildsLua = extractTable(buildsAssign);
const orderLua = extractTable(orderAssign);

const buildsJson = luaToJson(buildsLua);
const orderJson = luaToJson(orderLua);

let builds;
let classOrder;
try {
  builds = JSON.parse(buildsJson);
  classOrder = JSON.parse(orderJson);
} catch (err) {
  console.error("JSON parse failed:", err.message);
  fs.mkdirSync(path.resolve(root, "scripts"), { recursive: true });
  fs.writeFileSync(path.resolve(root, "scripts/_debug-builds.json.txt"), buildsJson);
  process.exit(1);
}

const payload = { classOrder, builds };
fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(payload, null, 2));
console.log(
  `Wrote ${outPath} (${classOrder.length} classes, ${Object.keys(builds).length} build tables)`,
);
