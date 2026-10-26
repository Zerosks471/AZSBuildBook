# AZS Build Book (web)

Browser viewer for the same class builds as the in-game **AZSBuildBook** addon.

Stack: **Vite + React + Tailwind CSS v4**.

## Run locally

```bash
cd azs-buildbook-site
npm install
npm run dev
```

Open the URL Vite prints (usually `http://localhost:5173`).

## Sync from the addon

`npm run sync-builds` (also runs before `dev` / `build`) reads:

`../benilla-config/AddOns/AZSBuildBook/Builds.lua`

and writes `src/data/builds.json`.
