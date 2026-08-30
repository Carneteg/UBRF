# Active Gate

Current gate: **Gate G01 — First Playable Horse Loop** (`docs/GATE-G01-FIRST-PLAYABLE.md`)

## Gate F01 — UBRF Fidelity: `HUMAN_STUDIO_ACCEPTED / CLOSED`

**Tobias genomförde den manuella Studio-genomgången 2026-08-30: 11/11 QA-vyer
PASS, gångvägen PASS.** Gaten är stängd som **FIDELITY READY WITH DOCUMENTED
GAPS** — aldrig som `100 % IDENTICAL`, eftersom luckorna nedan står kvar.

Beslutet är Tobias, inte mitt. Bevisen och observationerna står i
`audits/GATE-F01-UBRF-FIDELITY-RESULT.md`.

**Öppna inte brett byggnadsfidelity-arbete igen.** En stängd gate öppnas av ett
konkret fel, inte av att något kan bli snyggare.

Kvarvarande, dokumenterat och **inte uppfunnet**: hallens orientering,
gavelförskjutningens storlek, motsägelsen sarg mot läktarfront.

Lågprioriterad polish, noterad vid acceptansen: **stallets interiör känns lite
mörk.** Icke-blockerande. Rättas i ljussättningen — aldrig genom att flytta ett
mått eller ändra en mätt yta. Se § 14.0 i resultatauditen.

---

## Bakgrund — Gate F01

Canonical implementation brief:

- `docs/GATE-F01-UBRF-FIDELITY.md`

## Focus decision

Tobias has explicitly reprioritized the project: **building/environment fidelity is now the active focus.**

Gate 01 — Riding Feel is **PAUSED, not closed**. Its remaining Roblox-touch blocker from `audits/GATE-01-CHATGPT-REVIEW-02.md` must be preserved and resumed later. Do not spend implementation time on it while Gate F01 is active unless Tobias explicitly changes priority again.

## Claude

Before making building/world/fidelity changes, read in this order:

1. `CLAUDE.md`
2. `docs/PRODUCT-CANON.md`
3. `docs/ASSET-SOURCE-OF-TRUTH.md`
4. `docs/AI-COLLABORATION.md`
5. `docs/GATE-F01-UBRF-FIDELITY.md`
6. `references/SITEPLAN.md`
7. the relevant building `KORT.md` files and all GitHub-hosted reference material they cite

Do not use Google Drive as a build dependency. If a needed source is not available in GitHub/Supabase, mark `REFERENCE GAP`; do not invent the missing reality.

Do not expand scope beyond Gate F01 while it is active unless Tobias explicitly requests it.

**Platform rule for this gate:** Roblox is the primary game platform and HTML/web is a real playable parallel distribution. Both must use the same fidelity facts about UBRF even when rendering/implementation differs.

After implementation, create:

`audits/GATE-F01-UBRF-FIDELITY-RESULT.md`

It must include the Fidelity Matrix, source chain, before/after contradictions, separate ridhus/stall exterior/interior sections, Roblox/web parity, visual comparison evidence, remaining assumptions/reference gaps and exact tested commit SHAs.

Claude does not mark the gate closed and does not call the whole site `100% identical` while visible assumptions/reference gaps remain.

## ChatGPT

Review as Senior Game Developer / World & Environment Systems Reviewer. Verify the actual diff against the actual source chain, not only against summary documents. A model matching an assumption in `KORT.md` is not proof of real-world fidelity.

## Tobias

Product Owner. Final decision on whether the environment is acceptable and whether new source photos are needed to close remaining reference gaps.
