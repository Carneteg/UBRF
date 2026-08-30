# Gate F01 — ChatGPT Senior Site Fidelity Review 06

Status: **CHANGES REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `74cd52864396014d538addef4dcfb12ffcbe3c1b`

## Executive verdict

Claude's latest pass is materially better. The source-chain cleanup is real, the stable interior has now been re-audited against the correctly classified image set, the riding-hall spectator/glazing topology has been corrected toward the C-end, and the new test runner closes a genuine false-green failure mode.

However, Gate F01 is **not ready**. A new P0 site-layout contradiction is visible in the same satellite evidence already used by the project: the stable and riding hall are longitudinally staggered, but the canonical model still forces both northern gables onto the same line. The training-area model also remains conceptually too simple for the source evidence and the Product Owner's explicit statement that the training arenas/areas are misplaced.

PR #22 must not be merged yet.

---

## What passes in Review 06

### 1. Retracted measurement cleanup — PASS
The old `29.28`, `26.57`, and `39.83` claims are no longer used as verified geometry. The active model now keeps building widths and horse-passage longitudinal placement as unresolved/reference-gap values.

`references/SITEPLAN.md` also marks the old 75 m → pixel scale → 54 m stable argument as `SUPERSEDED`, correctly explaining that it was circular rather than independent evidence.

### 2. Stable interior re-audit — PASS, with remaining gaps honestly classified
`IMG_0159–0162` have now been checked as stable images. The audit explicitly compares the built aisle against box-front construction, top rail, timber roof members, corrugated roof lining, floor character, lights and props, and adds the clock visible at the far end.

The aisle width and exact box count remain unresolved where the images cannot close them. That is the correct evidence discipline.

### 3. Riding-hall C-end spectator/glazing topology — PARTIAL PASS
The source image shows the spectator/stair/glazing block at the **C end** of the arena. Moving the glazing away from the old long-wall-only interpretation is a genuine improvement. The source supports `C-end` much more strongly than the previous geometry.

Do **not** overstate `south end` unless the real-world C-end ↔ site orientation is independently established. The canonical fact should be `C-end`; world-direction mapping is a separate site-orientation fact.

### 4. Crash-aware test runner — GOOD DIRECTION
`roblox/tests/kor.sh` now requires a success footer as well as zero `FEL` rows, which correctly catches the specific premature-crash false greens Claude discovered.

A small robustness improvement is still required below.

### 5. Training-area ambiguity handling — METHOD PASS
Claude is correct not to force `33.57 m` onto an arbitrary existing `UTEBANA`. A measurement must not be allowed to invent its own semantic target.

The next step, however, must change from "which one is the game's single arena?" to a full inventory of the real training surfaces.

---

# BLOCKER A — P0: the two main buildings are longitudinally staggered, not north-gable aligned

Current canonical geometry still does this:

- `NORRA_GAVELN = 119`
- `RIDHUS_Y = NORRA_GAVELN - RIDHUS_LANGD`
- `STALL_Y = NORRA_GAVELN - STALL_LANGD`

`references/SITEPLAN.md` also states that the stable's northern gable is in line with the riding hall and labels that relationship as verified.

That is contradicted by the satellite image already supplied by the Product Owner and used throughout this gate.

From the overhead view:

- the **stable** (roof with the long row of ridge vent hoods) extends materially farther toward the north-west along the common building axis;
- the **riding hall** starts farther south-east at that end;
- at the opposite end the riding hall extends farther south-east than the stable.

The buildings overlap longitudinally, but their end walls are **not flush**.

This is a structural site-layout issue, not cosmetic polish. It affects:

- horse-passage position relative to both buildings;
- the two yard shapes;
- entrance/parking relationships;
- facade correspondence;
- ancillary building placement;
- training-area offsets.

## Required change

1. Remove any claim that the two northern gables are aligned/flush or `[VERIFIED]`.
2. Stop deriving both Y positions from one shared `NORRA_GAVELN` constant.
3. Introduce an explicit longitudinal offset relationship between stable and riding hall.
4. Use the satellite image to establish **topology/order and visible stagger** now.
5. If the exact stagger in metres is not directly measured, classify its numeric value as `REFERENCE GAP` / `DERIVED`, not verified.
6. Do not silently choose a number merely to preserve the current horse-passage alignment.
7. Re-anchor the horse passage after the two building longitudinal positions are corrected.

A clean direct Google Maps two-point measurement can later close the exact offset, but exact metres are not required to stop encoding a visibly false flush alignment.

---

# BLOCKER B — The real training environment contains multiple surfaces; model all verified surfaces

The Product Owner explicitly reported that the **training arenas / training areas** are incorrectly placed, plural. The satellite and ground-level evidence also show multiple separate outdoor surfaces.

`references/site/BANIDENTITET.md` correctly discovers that the source shows at least two sand surfaces while the game has one `UTEBANA` plus a simplified `PADDOCK`. But it still frames the problem primarily as choosing which real surface should map to the game's one arena.

That is too implementation-led for a fidelity gate.

## Required change

Invert the mapping:

**Reality → canonical site inventory → game**, not existing game object → pick one reality object.

Create a training-surface inventory with neutral location-based IDs, for example:

- `training_ne_large`
- `training_ne_small` / `training_central`
- any additional visually distinct fenced/sand surface that the satellite + Omnejd evidence supports

For each record:

- footprint shape/topology;
- position relative to buildings/roads/other surfaces;
- surface type if visually supported;
- fence/light-mast facts;
- measured dimensions only where valid;
- `REFERENCE GAP` for unresolved dimensions or purpose/name.

Do **not** require knowing "which one is the one you ride on" before representing that the physical surface exists.

The clean `33.57 m` measurement belongs to the large north-east surface record, regardless of what gameplay label it eventually receives.

The current single provisional `20 × 40 UTEBANA` must not remain the canonical physical truth for the site.

---

# BLOCKER C — Test runner should also require process exit status = 0

`roblox/tests/kor.sh` is a real improvement, but it currently decides success from output text only:

- zero lines matching `FEL`;
- at least one expected success footer.

It does not explicitly require the Luau process exit code to be zero.

## Required change

Capture the exit status immediately after each Luau invocation and require:

- `exit code == 0`
- zero `FEL` rows
- expected success footer present

This closes the remaining class where a spec prints a footer and then exits abnormally, or otherwise returns non-zero despite text looking successful.

---

# BLOCKER D — Interior audit document still contains stale contradictory status prose

`audits/GATE-F01-INTERIOR-REAUDIT-2026-08-30.md` now contains the new stable audit and new riding-hall work, but earlier sections still read as if the spectator extent/front are `KNOWN MISMATCH` and include a stale "Vad som fortfarande INTE är gjort" paragraph whose wording no longer matches the implementation state.

## Required change

Rewrite the audit as current-state truth instead of accumulating chronological corrections inline:

- resolved findings → `RESOLVED` with implementation SHA;
- unresolved measurements → `REFERENCE GAP`;
- still-wrong geometry → `KNOWN MISMATCH`;
- no sentence should simultaneously say a point is fixed and "still not done".

Preserve history in a short superseded table if needed; do not make future agents reconstruct truth from contradictory chronology.

---

# BLOCKER E — Roblox Studio remains mandatory visual evidence

Issue #23's stop condition still applies. The web/build/stub tests cannot replace visual verification in Roblox Studio.

After A–D and the multi-surface site correction:

1. regenerate Roblox canonical export;
2. run the improved test runner;
3. build the Studio package;
4. inspect the fixed views plus the training-area/site overview;
5. compare against the actual photo/satellite references;
6. record screenshots/evidence.

Do not merge PR #22 before that review.

---

## Required handoff for Review 07

Return only after:

1. shared-northern-gable alignment has been removed and the real stagger represented;
2. training surfaces are inventoried reality-first and the site contains the verified distinct surfaces;
3. `kor.sh` checks exit status as well as output markers;
4. the interior audit is rewritten to one coherent current-state truth;
5. shared web → Roblox export/tests are green.

Then hand back for **ChatGPT Senior Site Fidelity Review 07**. Roblox Studio acceptance remains the final visual gate after source/geometry review passes.
