# Gate F01 — ChatGPT Senior Site Fidelity Review 04

Status: **CHANGES REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `3ac59be85153394119d0188698531136cd39a9b0`

## Executive verdict

The latest implementation makes useful progress, especially by correcting the **lengths** of the two main buildings and by re-auditing stable circulation instead of blindly stretching the old layout. However, it is **not ready** against the current source contract. The head commit uses only part of the Product Owner's latest direct satellite measurements and leaves several superseded assumptions active in canonical geometry.

PR #22 must not be merged yet.

## What passes in this round

- Stable length changed from 54 m to **69.95 m**.
- Riding-hall length changed from 75 m to **77.18 m**.
- Stable internal zoning was not merely uniformly stretched; evacuation-plan proportions and box rhythm were reconsidered.
- Stable navigability/circulation regressions found during the rescale were fixed and covered by tests.
- Shared web → Roblox export remains in place.
- Reference inventory work and direct-image review are materially better than earlier rounds.

These are good changes and should be kept.

---

## BLOCKER A — Verified building widths were ignored

Issue #24 locks the Product Owner's direct satellite measurements for the **outer footprints**:

- STALL width: **29.28 m**
- RIDHUS width: **26.57 m**

The current code and `references/SITEPLAN.md` still build:

- STALL width: **21 m `[ASSUMPTION]`**
- RIDHUS width: **25 m**

This is no longer acceptable. The older widths are superseded by the later direct measurements.

### Required change

Rebuild the outer footprints from:

- `STALL = 29.28 × 69.95 m`
- `RIDHUS = 26.57 × 77.18 m`

Do **not** blindly scale interiors. Reconcile the new shells with the evacuation-plan proportions and directly verified photo features.

When widening buildings, re-anchor surrounding geometry instead of allowing the footprint to simply consume yards, paths or props.

---

## BLOCKER B — The measured local building gap is still encoded as 11 m

Issue #24 records a direct Product Owner measurement of **8.10 m** between the two main building edges at the measured southern cross-section.

The current SITEPLAN still encodes the yard between x = 143 and x = 154, i.e. **11 m**, and the implementation retains this geometry.

The 8.10 m measurement is local to the measured cross-section; it does not prove every point between the buildings has identical spacing. But the current 11 m canonical assertion at that same relationship is now superseded.

### Required change

Use **8.10 m as the verified local cross-section constraint** and reconstruct the relative placement of the widened buildings from source geometry. Do not force the entire yard to 8.10 m unless parallelism/constant spacing is separately established.

---

## BLOCKER C — Direct horse-passage measurement was replaced by a model-derived relocation

Issue #24 records a direct measured longitudinal relation:

- **39.83 m** from the southern riding-hall end to the measured horse-passage/riding-hall attachment point.

The latest implementation instead moves the passage to `y = 76.85` because that makes it align with the rescaled stable cross-corridor. This is a model-derived inference, not the latest direct measurement.

A direct Product Owner measurement outranks a derived placement from the model.

### Required change

Anchor the riding-hall attachment to the **39.83 m direct measured offset**. Then reconcile the stable cross-corridor/interior to that real attachment constraint. If the direct exterior attachment and evacuation-plan interior interpretation conflict, record the conflict explicitly; do not move the real-world connection to make the current model convenient.

The 39.83 m fact refers to the measured attachment point, not automatically the passage centerline. Keep passage width/center classification separate until measured.

---

## BLOCKER D — The large training arena still uses the old 20 × 40 geometry

The Product Owner supplied a direct simple corner-to-corner measurement of the large eastern/northeastern training area's short side:

- **33.57 m** — verified short side.

`src/site.js` and SITEPLAN still define `uteridbanan` as **20 × 40 m**.

The long side has **not** yet been cleanly measured and must remain `REFERENCE GAP` / provisional if the game needs a temporary playable extent.

### Required change

- Replace the old 20 m short side with **33.57 m**.
- Do not label 40 m as verified.
- If 40 m must temporarily remain for playability, classify it explicitly as `ASSUMPTION` / provisional and ensure tests do not present it as source truth.
- Re-anchor the arena from the satellite evidence instead of treating the old coordinates as canonical.

---

## BLOCKER E — The site rebuild is only a length rescale, not the requested scale lock

The current `SITEPLAN.md` still contains multiple coordinates derived from the older 21 m / 25 m / 11 m geometry. Correcting lengths alone does not satisfy the P0 order to rebuild the site from the new direct scale.

After A–D, re-audit at minimum:

- yard polygons on both sides of the horse passage,
- paths around the stable,
- paddocks/hagars nearest the stable,
- parking/gravel extents,
- silo and low ancillary volumes,
- training-area offsets,
- door/passages that depend on facade lengths or widths.

No object should be moved merely to "keep its role" if its real placement is unknown. Such objects stay `ASSUMPTION` / `REFERENCE GAP` and should not drive verified geometry.

---

## BLOCKER F — Interior rebuild required by Issue #23 is still not complete

The PR description itself states that the correctly classified stable/riding-hall interiors have been re-audited but **the corrections are not implemented yet**.

That means Gate F01 cannot be called complete even after the site-scale fixes.

Required before final visual-ready status:

- Stable interior rebuilt against the correctly classified stable image set + evacuation plan.
- Riding-hall interior rebuilt against `IMG_0179`, `IMG_0183`, `IMG_0198`, and available video-derived evidence.
- Verified visual identity features present in shared canonical data and consumed by both web and Roblox.

---

## Documentation / status cleanup

After implementation:

1. Update `references/SITEPLAN.md` so no superseded `21`, `25`, `11`, or `20×40` values read as active truth.
2. Update building cards and audit classifications.
3. Update PR #22 description; it currently contains stale statements such as 25×75 and unresolved stable width.
4. Regenerate Roblox export from the canonical data path.
5. Re-run geometry/build/gameflow tests.
6. Leave Studio execution as a separate final visual acceptance step; passing stub/build tests is not visual Studio evidence.

## Stop condition

Return for **ChatGPT Senior Site Fidelity Review 05** only when the latest direct Product Owner measurements have actually been applied or explicitly classified as unresolved — never silently replaced by older assumptions or model-derived convenience.
