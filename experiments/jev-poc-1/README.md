# JEV-POC-1 — Jev som beslutslager för Ugnetas coaching

Experiment, **inte produktionskod**. Ingenting här laddas av Roblox eller webben.
Rapport: [REPORT.md](REPORT.md) · issue #269.

```sh
cd experiments/jev-poc-1
npm install
npm run policy                 # policyprov, inget nätverk
TYPESAFE_API_KEY=… npm run eval         # 30 kärnscenarier × 2
TYPESAFE_API_KEY=… npm run eval:stress  # 12 stresscenarier × 2
```

- `scenarios.mjs` — scenarier och godtagbara val (förväntningarna är [antagande] tills en ridlärare granskat dem).
- `policy.mjs` — hårda grindar, allow-list, tröskel, deterministisk Ugneta-fallback.
- `run.mjs` / `analyze.mjs` — anrop mot Jev och analys; nyckeln skrivs aldrig ut.
- `results-*.json`, `report-data-*.md` — rådata från körningen 2026-09-30 (`jev-1.13.0`).
