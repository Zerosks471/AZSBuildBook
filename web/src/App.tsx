import { useMemo, useState } from "react";
import data from "./data/builds.json";
import type { Build, BuildsData, PageId } from "./types";

const catalog = data as BuildsData;
const PAGES: PageId[] = ["Overview", "Talents", "Cards", "Jewelry"];

function buildList(entry: BuildsData["builds"][string]): Build[] {
  return Object.values(entry.builds);
}

export default function App() {
  const [classKey, setClassKey] = useState(catalog.classOrder[0] ?? "WARRIOR");
  const entry = catalog.builds[classKey];
  const builds = useMemo(() => (entry ? buildList(entry) : []), [entry]);
  const [buildId, setBuildId] = useState<string | null>(null);
  const [page, setPage] = useState<PageId>("Overview");

  const activeBuildId =
    buildId && builds.some((b) => b.id === buildId)
      ? buildId
      : (entry?.default ?? builds[0]?.id ?? "");
  const build = builds.find((b) => b.id === activeBuildId) ?? builds[0];

  function selectClass(key: string) {
    setClassKey(key);
    setBuildId(null);
    setPage("Overview");
  }

  return (
    <div className="relative isolate min-h-dvh overflow-x-hidden">
      <div
        className="grain pointer-events-none fixed inset-0 z-0 opacity-[0.04] mix-blend-overlay"
        aria-hidden
      />

      <div className="relative z-10 mx-auto max-w-5xl px-4 pb-16 pt-12 sm:px-6 lg:px-8">
        <header className="animate-rise mb-10 max-w-2xl">
          <p className="font-display text-[clamp(3rem,8vw,4.5rem)] leading-[0.92] tracking-tight text-gold">
            AZS Build Book
          </p>
          <h1 className="mt-4 text-lg font-medium tracking-tight text-parchment/90 sm:text-xl">
            Class builds for Azeroth Survivors
          </h1>
          <p className="mt-2 max-w-md text-sm leading-relaxed text-muted sm:text-[0.95rem]">
            Same guides as the in-game addon. Pick a class, then a build.
          </p>
        </header>

        <nav
          className="animate-rise-delay mb-8 -mx-4 px-4 sm:mx-0 sm:px-0"
          aria-label="Classes"
        >
          <div className="flex gap-1 overflow-x-auto pb-1 snap-x snap-mandatory [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            <div className="flex min-w-max gap-1 rounded-full border border-brd bg-surface p-1 backdrop-blur-md">
              {catalog.classOrder.map((key) => {
                const c = catalog.builds[key];
                if (!c) return null;
                const on = key === classKey;
                return (
                  <button
                    key={key}
                    type="button"
                    onClick={() => selectClass(key)}
                    className={
                      on
                        ? "snap-start rounded-full bg-gold px-4 py-2 text-sm font-semibold text-ink shadow-[0_0_24px_rgba(240,197,106,0.25)] transition duration-200"
                        : "snap-start rounded-full px-4 py-2 text-sm font-medium text-muted transition duration-200 hover:bg-surface-2 hover:text-parchment"
                    }
                  >
                    {c.label}
                  </button>
                );
              })}
            </div>
          </div>
        </nav>

        {entry && build && (
          <main className="animate-rise-late">
            <div className="mb-8 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
              <div className="min-w-0">
                <p className="text-xs font-medium uppercase tracking-[0.2em] text-gold-dim">
                  {entry.label}
                </p>
                <h2 className="font-display mt-2 text-[clamp(2rem,4vw,2.75rem)] leading-none tracking-tight text-parchment">
                  {build.name}
                </h2>
                <p className="mt-3 max-w-xl text-base leading-relaxed text-muted">
                  {build.tagline}
                </p>
              </div>

              <div
                className="flex flex-wrap gap-2 lg:justify-end"
                role="tablist"
                aria-label="Builds"
              >
                {builds.map((b) => {
                  const on = b.id === activeBuildId;
                  return (
                    <button
                      key={b.id}
                      type="button"
                      role="tab"
                      aria-selected={on}
                      onClick={() => {
                        setBuildId(b.id);
                        setPage("Overview");
                      }}
                      className={
                        on
                          ? "rounded-2xl border border-gold/40 bg-gold/10 px-4 py-3 text-left transition duration-200"
                          : "rounded-2xl border border-transparent bg-surface px-4 py-3 text-left transition duration-200 hover:border-brd hover:bg-surface-2"
                      }
                    >
                      <span className="block text-[0.65rem] font-semibold uppercase tracking-[0.16em] text-gold-dim">
                        {b.tree}
                      </span>
                      <span
                        className={
                          on
                            ? "mt-1 block text-sm font-medium text-gold"
                            : "mt-1 block text-sm font-medium text-parchment/80"
                        }
                      >
                        {b.name}
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="mb-6 inline-flex rounded-full border border-brd bg-surface p-1">
              <div className="flex flex-wrap gap-0.5" role="tablist" aria-label="Sections">
                {PAGES.map((p) => {
                  const on = page === p;
                  return (
                    <button
                      key={p}
                      type="button"
                      role="tab"
                      aria-selected={on}
                      onClick={() => setPage(p)}
                      className={
                        on
                          ? "rounded-full bg-parchment/10 px-4 py-2 text-sm font-medium text-gold transition duration-200"
                          : "rounded-full px-4 py-2 text-sm font-medium text-muted transition duration-200 hover:text-parchment"
                      }
                    >
                      {p}
                    </button>
                  );
                })}
              </div>
            </div>

            <section
              key={`${activeBuildId}-${page}`}
              className="animate-fade min-h-52"
              aria-live="polite"
            >
              {page === "Overview" && (
                <div className="grid gap-10 lg:grid-cols-[1.35fr_1fr]">
                  <Block title="Core" items={build.core} accent />
                  <div className="space-y-6 border-t border-brd pt-6 lg:border-l lg:border-t-0 lg:pl-8 lg:pt-0">
                    <Meta label="Race" value={build.race} />
                    <Meta label="Armory" value={build.armory} />
                    <Meta label="Tip" value={build.tip} />
                    <Meta label="Avoid" value={build.avoid} danger />
                  </div>
                </div>
              )}
              {page === "Talents" && (
                <Block title="Talent path" items={build.talents} />
              )}
              {page === "Cards" && <Block title="Cards" items={build.cards} />}
              {page === "Jewelry" && (
                <Block title="Jewelry" items={build.jewelry} />
              )}
            </section>
          </main>
        )}

        <footer className="mt-14 border-t border-brd pt-6 text-xs tracking-wide text-muted/80">
          Synced from the AZSBuildBook addon · /azsbuild in-game
        </footer>
      </div>
    </div>
  );
}

function Block({
  title,
  items,
  accent,
}: {
  title: string;
  items: string[];
  accent?: boolean;
}) {
  return (
    <div>
      <h3 className="mb-4 text-xs font-semibold uppercase tracking-[0.18em] text-gold-dim">
        {title}
      </h3>
      <ul className="m-0 grid list-none gap-0 p-0">
        {items.map((line, i) => (
          <li
            key={line}
            className="group flex items-baseline gap-3 border-b border-brd py-3.5 text-[0.95rem] leading-snug text-parchment/90 transition hover:text-parchment"
            style={{ animationDelay: `${i * 30}ms` }}
          >
            <span
              className={
                accent
                  ? "mt-1.5 size-1.5 shrink-0 rounded-full bg-gold"
                  : "mt-1.5 size-1.5 shrink-0 rounded-full bg-gold-dim/50"
              }
            />
            <span>
              {line.includes("*") ? (
                <>
                  {line.replace(" *", "").replace("*", "")}
                  <span className="ml-1 text-gold">★</span>
                </>
              ) : (
                line
              )}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

function Meta({
  label,
  value,
  danger,
}: {
  label: string;
  value: string;
  danger?: boolean;
}) {
  return (
    <div>
      <p className="text-[0.65rem] font-semibold uppercase tracking-[0.18em] text-gold-dim">
        {label}
      </p>
      <p
        className={
          danger
            ? "mt-1.5 text-sm leading-relaxed text-danger"
            : "mt-1.5 text-sm leading-relaxed text-parchment/85"
        }
      >
        {value}
      </p>
    </div>
  );
}
