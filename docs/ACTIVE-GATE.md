# Active Gate

Current implementation gate: **Gate G01 — First Playable Horse Loop**

Canonical implementation brief:

- `docs/GATE-G01-FIRST-PLAYABLE-HORSE-LOOP.md`

## Gate F01 status

**Gate F01 — UBRF Fidelity is WAITING_FOR_HUMAN_STUDIO_VISUAL_ACCEPTANCE.**

The merged F01 implementation is a checkpoint, not visual acceptance. Linux/runtime evidence has reached its useful limit. Do not spend another implementation cycle broadly polishing buildings unless Tobias reports a concrete Roblox Studio failure.

Canonical Studio handoff:

- `roblox/docs/STUDIO-QA-HANDOFF.md`
- canonical camera definitions: `roblox/buildings/Vyer.luau`

A failed Studio view may reopen only the affected fidelity area. Unknown real-world details remain `REFERENCE GAP`; never guess them into production geometry.

## Gate G01 focus

UBRF must now become a playable horse game. Build vertically around the loop:

**arrive → assigned horse → preparation → lead out → riding hall → mount → simple exercise → return → aftercare → feedback.**

First slice: **G01.1 — Assigned horse + preparation gate.**

Reuse the existing HorseCore/riding stack. Do not create a second riding engine.

## Platform rule

- Roblox is the primary game platform.
- HTML/web is a real playable parallel distribution.
- Core gameplay rules, learning goals and responsibility consequences should correspond across platforms where practical.
- Platform-specific rendering/input/UI are allowed.
- Google Drive is not a build dependency. GitHub + Supabase must contain the material required by implementation agents.

## Claude

Before implementing G01, read:

1. `CLAUDE.md`
2. `docs/PRODUCT-CANON.md`
3. `docs/AI-COLLABORATION.md`
4. `docs/GATE-G01-FIRST-PLAYABLE-HORSE-LOOP.md`
5. `roblox/README.md`
6. the existing `roblox/src/shared/HorseCore`, `roblox/src/server/HorseService.luau` and client controllers
7. relevant web gameplay modules (`src/hast.js`, `src/sysslor.js`, `src/ovningar.js`, `src/efter.js`) as product references

Do not blindly port web code into Roblox. Preserve the same product truth while using Roblox-native architecture.

## ChatGPT

Act as Senior Game Developer / Game Architect. Prioritize complete playable vertical slices, smooth horse feel, clear player goals, server-authoritative state and learning-by-doing. Review actual diffs and tests, not implementation summaries alone.

## Tobias

Product Owner. Performs the final Roblox Studio visual/play acceptance and decides when a gate is accepted.
