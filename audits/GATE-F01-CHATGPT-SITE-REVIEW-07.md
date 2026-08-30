# Gate F01 — ChatGPT Senior Site Fidelity Review 07

Status: **CHANGES REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `d93f3b0e7cec609eef136b8b01e4c0244fee9598`

## Executive verdict

Review 06 produced real improvements: the training-surface model is now reality-first, the test runner correctly checks Luau exit status, and the interior audit has been rewritten as current-state truth.

However one P0 geometry error remains and the canonical documentation is again out of sync with the implementation.

The new longitudinal stagger is encoded with the **wrong sign**.

PR #22 must not be merged yet.

---

## PASS — Review 06 blockers that are genuinely resolved

### Test runner
`roblox/tests/kor.sh` now records `$?` immediately after the Luau process and requires exit code 0 in addition to zero `FEL` rows and a success footer. PASS.

### Interior audit cleanup
`audits/GATE-F01-INTERIOR-REAUDIT-2026-08-30.md` is substantially cleaner: one current status per finding, with remaining measurement uncertainty called `REFERENCE GAP`. PASS.

### Training surfaces — data-model method
The physical surfaces are no longer defined only through gameplay names. `TRANINGSYTOR.NO_STOR` and `NO_LITEN` are a better canonical layer, and the clean `33.57 m` measurement is attached to `NO_STOR` rather than allowed to invent a gameplay identity. METHOD PASS.

The exact positions/dimensions still remain unresolved and must not be called site-fidelity-correct until anchored to satellite evidence.

---

# BLOCKER A — P0: the stagger direction is reversed

The project itself states:

> `spelets norr är verklighetens nordväst`

The satellite reference shows:

- the **stall** is the building with the row of ridge vent hoods;
- along the common NW–SE axis, the stall's NW end extends **farther toward the NW** than the riding hall's corresponding end;
- the riding hall extends farther toward the opposite SE end.

Therefore, in the game's coordinate convention, the stable's northern/NW gable must be **farther north / higher Y** than the riding hall's corresponding gable.

Current implementation does the opposite:

```js
const RIDHUS_NORR = 119;
const GAVELFORSKJUTNING = 6; // "stallet söderut relativt ridhuset"
const STALL_NORR = RIDHUS_NORR - GAVELFORSKJUTNING; // 113
```

This moves the stable toward real-world SE, opposite the source image.

## Required correction

1. Keep the important improvement that the buildings are **not flush**.
2. Reverse the stagger direction so the stable extends farther toward game-north / real-NW than the riding hall.
3. The magnitude remains `[ASSUMPTION]` / `REFERENCE GAP` until directly measured. Do not promote 6 m to measured truth.
4. Recalculate dependent geometry after the sign correction: stable Y, yards, horse passage interfaces, ancillary overlap, paths and door spawns.
5. Re-run overlap/path/export tests.

Do not use the horse-passage alignment to choose the stagger magnitude.

---

# BLOCKER B — canonical docs are stale and contradict current code

`references/SITEPLAN.md` at this head still says:

- stable south-west corner `y = 49.05`;
- stable north gable `y = 119`;
- stable north gable is **"i liv med ridhusets"**;
- old yard ranges based on the flush model;
- old `20 × 40 Uteridbanan` / old paddock rows rather than the new neutral training-surface inventory.

Those statements contradict the code Claude just changed.

`src/site.js` itself also still contains stale prose immediately above the new stagger code saying that **both northern gables are fixed at y=119**, even though the active constants below no longer do that. The `STALL_X` inline numeric comment is also stale.

## Required correction

Rewrite current-state source documentation after the geometry fix:

- no stale flush-gable statement anywhere;
- SITEPLAN rows must match actual generated coordinates;
- represent `NO_STOR` / `NO_LITEN` as physical surfaces first, with gameplay mappings separately;
- clearly mark all temporary positions/long sides as `ASSUMPTION` / `REFERENCE GAP`;
- PR description must be brought to current truth as part of handoff.

---

# BLOCKER C — training-surface placement is still not solved

The new data model is correct in direction, but the actual rectangles are explicitly working placements:

```js
NO_STOR:  {x:170, y:120, w:33.57, h:46, ...}
NO_LITEN: {x:150, y:132, w:18, h:24, ...}
```

Only `33.57 m` is measured. The other dimensions and both world positions are unresolved.

This is acceptable as temporary geometry, but it does **not** close the Product Owner's reported problem that the training areas are incorrectly placed.

For Review 08, either:

- anchor their relative placement to satellite evidence and classify the resulting coordinates honestly as `DERIVED`, or
- leave placement as an explicit blocker and do not claim site layout complete.

Do not infer precise metres from a visual screenshot without a documented calibration/method.

---

# BLOCKER D — Roblox Studio still required

No change: Studio visual verification remains mandatory after the source/geometry blockers above are resolved.

---

## Required handoff for Review 08

Return after:

1. the building stagger has the correct direction;
2. all dependent site geometry has been regenerated/tested;
3. SITEPLAN, code comments and PR body match the actual current model;
4. training-surface locations are either source-anchored or explicitly still blocked, never presented as corrected when they are working coordinates;
5. export/tests are green.

Then hand back for **ChatGPT Senior Site Fidelity Review 08**.
