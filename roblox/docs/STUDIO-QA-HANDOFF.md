# UBRF — Roblox Studio QA handoff

Gate F01 status: **WAITING_FOR_HUMAN_STUDIO_VISUAL_ACCEPTANCE**

This is the canonical human handoff for the visual Studio gate. The Linux/runtime checks prove that the package builds and the cameras resolve; they do not prove materials, lighting, overlaps, z-fighting or visual recognition.

Use the generated Studio package and the canonical view IDs from `roblox/buildings/Vyer.luau`. For every failure, save a screenshot and report only what is visibly wrong and where it occurs. Do not guess the code cause.

## Global pass conditions

Check throughout the pass:

- overall UBRF scale feels coherent;
- stable and riding hall relative placement is believable and recognizable;
- no building overlap;
- no z-fighting/flickering coplanar surfaces;
- entrances and openings appear where movement expects them;
- route remains physically readable: **arrival → stable → horse passage → riding hall → arena**;
- unresolved `REFERENCE GAP` items are not treated as verified facts.

---

## 1 — `oversikt`

**Should show:** UBRF complex from above.  
**Reference:** site/satellite reference chain.  
**Check:** two parallel main building volumes, one transverse horse passage, two yard areas, coherent overall scale and no building overlap.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-01-oversikt.png`

## 2 — `ankomsten`

**Should show:** arrival/gravel area toward the northern gables.  
**Reference:** stable/riding-hall exterior photos and site evidence.  
**Check:** arrival reads as one UBRF complex; stable and riding hall are distinguishable; gables are not falsely aligned; entrance/arrival readability works at player height.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-02-ankomsten.png`

## 3 — `gardarna`

**Should show:** southern yard toward the transverse horse passage.  
**Reference:** site photos and shared geometry.  
**Check:** horse passage closes the yard visually; no unintended sightline straight through; passage appears usable by a player leading a horse.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-03-gardarna.png`

## 4 — `banan`

**Should show:** riding arena toward the A end.  
**Reference:** riding-hall interior photos.  
**Check:** arena proportions, muted brown-grey sand, readable arena boundary, correct opening/gate relationship, no judge booth inside the arena.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-04-banan.png`

## 5 — `sponsorvaggen`

**Should show:** maroon/rust panel section, sponsor boards and window band.  
**Reference:** photographed long wall.  
**Check:** panel exists on **one configured side only** and only over a partial length; sponsor boards sit on the panel; window band relationship is coherent; no duplicated full-length maroon wall on the opposite side.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-05-sponsorvaggen.png`

## 6 — `kortandan`

**Should show:** C-end stepped spectator block.  
**Reference:** riding-hall C-end photos.  
**Check:** stepped block, two stairs, segmented glazing broken by stairs, white wall zone, round clock between stairs and compass rose in its configured wall zone. Look specifically for empty gaps, wrong shell material and z-fighting.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-06-kortandan.png`

## 7 — `domarbaset`

**Should show:** judge booth from the arena.  
**Reference:** interior evidence.  
**Check:** booth is outside the arena boundary/on spectator structure, not on riding surface; access and roof read correctly enough for the current evidence level.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-07-domarbaset.png`

## 8 — `takstommen`

**Should show:** riding-hall roof structure.  
**Reference:** interior roof photos.  
**Check:** roof reads as construction rather than a flat slab; structure is dark/neutral rather than warm stable timber; no obvious intersections or flicker.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-08-takstommen.png`

## 9 — `laktaren`

**Should show:** spectator side and opening toward the horse-passage route.  
**Reference:** riding-hall interior/site route evidence.  
**Check:** usable gap toward the horse passage; arena boundary has a corresponding gate/opening; horse/player route is not blocked by decorative geometry.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-09-laktaren.png`

## 10 — `servicedelen`

**Should show:** stable service end/spaces.  
**Reference:** stable interior photos.  
**Check:** service spaces read open toward the aisle where intended; floor/material transitions do not flicker; light/opening is plausible; no accidental sealed rooms blocking route.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-10-servicedelen.png`

## 11 — `stallgangen`

**Should show:** main stable aisle toward the cross corridor.  
**Reference:** stable aisle photos and plan.  
**Check:** correct aisle proportions; stalls on both sides; anthracite fronts with galvanized framing and five horizontal rails; cross corridor is readable; horse and player can move through without obvious clipping bottlenecks.  
**Result:** PASS / FAIL  
**Failure screenshot:** `F01-11-stallgangen.png`

---

## Final route check

After the static views, move as a player through:

**arrival → stable entrance → stable aisle → assigned-horse area → horse passage → riding hall → arena.**

Check player-height readability, collision, door/gate clearance and camera clipping. When G01.2 leading is implemented, repeat the exact route while leading a horse.

## Decision

- All critical visual/route checks pass → Tobias may visually accept Gate F01.
- Any critical fail → report the view ID + visible symptom + screenshot. Reopen only the failed fidelity area.
- Do not restart broad fidelity work from subjective preference alone.
