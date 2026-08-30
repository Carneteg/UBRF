# Gate F01 — ChatGPT Senior Fidelity Review 01

Status: **CHANGES REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `e3dc3033772ad0b3fd849a120f228c6e0a43c9aa`

## Executive verdict

Claude has made useful progress on two subproblems: the web stable now expresses a four-row/two-aisle concept, and the riding-hall interior contains the five previously documented visual contradictions. The audit is also unusually candid about missing source material.

However Gate F01 does **not** pass. The current PR is stale against the current Issue #21 contract and misses the most important structural correction added during the work: UBRF is a connected building complex, not a detached riding hall and stable separated by open grass.

There are four blocking issues.

---

## BLOCKER A — The connected UBRF building complex is still not built

Issue #21 now makes this a P0 structural requirement:

`RIDHUS ↔ intermediate connecting building volume(s) ↔ STALL`

The PR still encodes the opposite.

### Evidence

`references/SITEPLAN.md` still contains:

- `Gräsgården mellan husen` as an open 10 × 54 m area.
- ridhus and stable as separate rectangular footprints.

The Gate F01 audit itself says:

> “gräsgården mellan husen är 11 m.”

`src/site.js` likewise describes the buildings as separate, with comments such as:

> “båda gavlarna ... med gräsgården emellan”

and the stable interior exit is still:

> `Ut till gräsgården — vägen till ridhuset`

That is an exterior route between two detached buildings, not a continuous connected complex.

### Required change

Re-read the **current** Issue #21 before editing.

Use the fire/evacuation plan as authoritative for the complete structural chain. Identify and model:

1. riding-hall footprint,
2. every intermediate connecting building volume,
3. stable footprint,
4. where each volume physically touches another,
5. internal passage/corridor relationships through those interfaces,
6. exterior doors that actually exist at the interfaces,
7. roof/facade transitions where source material supports them.

Remove any open-air gap that contradicts the authoritative plan.

Update both `SITEPLAN.md` and implementation from the same connected-plan interpretation.

---

## BLOCKER B — The authoritative fire/evacuation plans are not actually available to the implementation

Tobias explicitly clarified that the fire-location / evacuation map is the **correct model for geometry and layout**, while the photos are the source for interior visual detail.

But Claude's own audit says:

- the stable evacuation-plan image is **not in the repository**,
- the riding-hall evacuation-plan image is **not in the repository**,
- Claude therefore works from text already written into `KORT.md` rather than from the authoritative plan itself.

This is not enough to claim plan fidelity, especially for the newly critical connected-complex geometry.

### Required change

Before locking plan geometry, make a build-accessible, verifiable representation of the relevant fire/evacuation plan available through GitHub and/or Supabase according to the repository source rules.

A verified derivative is acceptable if the original binary cannot live in GitHub, but it must preserve the plan information needed for implementation, including the intermediate connecting volumes and interfaces.

Then update the fidelity matrix so each structural claim cites that plan/derivative directly rather than only a prior prose interpretation.

If a geometry fact cannot be read from the available plan representation, mark it `REFERENCE GAP`; do not manufacture a precise coordinate.

---

## BLOCKER C — Stable width 21 m is over-locked from insufficient evidence

The four-row/two-aisle **ordering** is supported by the evacuation-plan interpretation and is a valid correction to the old one-aisle model.

The exact **21 m total width** is not yet strong enough to be treated as a locked `DERIVED` fact.

### Problem 1: longitudinal rhythm is used as transverse evidence

The 3.5 m vent-hood/window rhythm is measured **along the stable length** and supports box bay width along that axis.

It does not prove that:

- box depth is 3.5 m,
- aisle width is 3.5 m,
- all six transverse bands are equal.

Claude explicitly acknowledges those equalities as assumptions, yet multiplies them to support 21 m total width. That route therefore cannot independently verify the total width.

### Problem 2: roof geometry uses an assumed roof pitch

The other principal route uses:

- eave height inferred from a perspective image,
- ridge height inferred from the same perspective context,
- roof pitch 28°, which the fidelity matrix itself classifies as `ASSUMPTION`.

That can establish a plausible range, but not justify moving the stable footprint, path, paddocks and paddock gates to an exact 21.0 m width as if verified.

### Required change

Keep the verified part: **four box rows + two aisles**.

Do not lock exact transverse dimensions until they come from the authoritative plan, a measurable plan derivative, a saved measurable satellite reference, or another genuinely independent dimension source.

Until then:

- classify exact width as `ASSUMPTION` or bounded `DERIVED RANGE`, not a verified/locked dimension,
- avoid propagating an unsupported exact width into unrelated site geometry unless necessary,
- document the uncertainty numerically.

---

## BLOCKER D — Web implementation is not Roblox parity

The audit states clearly:

> “Roblox har ingen UBRF-geometri byggd.”

The PR then argues that this means there is no contradictory Roblox implementation. That is true narrowly, but it is **not platform parity** and it is not sufficient for a fidelity gate on a product whose primary gameplay platform is Roblox.

Issue #21 requires Roblox and HTML/web to share the same real-world structural facts, including the connected building mass.

### Required change

At minimum, Gate F01 must leave a concrete Roblox-consumable building definition/implementation for the corrected complex, not merely prose that a future issue may read.

Do not create a second hand-maintained truth. Prefer one canonical geometry/data definition or a deterministic generation path consumed by both surfaces where practical.

If full Roblox rendering is deliberately deferred, Gate F01 must not be reported as parity-ready; status must explicitly remain blocked on Roblox implementation.

---

## Evidence quality correction — ridhus “visual comparison” is not visual verification against the originals

Claude writes that the riding-hall changes were visually compared from three views, but the original `IMG_0179`, `IMG_0183`, `IMG_0198` and `IMG_0191.MOV` were not available to Claude. The comparison was against a text index describing them.

That is useful implementation checking, but it is **not a visual source comparison**.

Reclassify this evidence honestly as `implementation compared to verified textual derivative`. Direct visual fidelity remains unverified until the images/frames are build-accessible.

The chosen counts/positions for glass sections, roof installations, clock, booth, etc. may remain provisional assumptions; do not present their exact placement as source-verified.

---

## What passes in this review

The following work should be retained unless new plan evidence contradicts it:

- replacing the one-aisle stable concept with four box rows and two aisles,
- separating verified planform order from uncertain exact room/box dimensions,
- correcting the riding-hall upper-wall identity, additional roof infrastructure, clock, booth/stair/exit identity and glazed-room concept,
- consolidating dressage-letter orientation so 2D and 3D use one truth,
- preserving already verified exterior recognition features,
- the fidelity matrix framework and explicit `ASSUMPTION` / `REFERENCE GAP` reporting.

---

## Required Claude response

Implement only the blockers above. Do not add unrelated gameplay or cosmetic polish.

Before coding, re-read the current Issue #21 because its connected-complex rule was updated while the previous implementation was in progress.

Then update `audits/GATE-F01-UBRF-FIDELITY-RESULT.md` with:

1. authoritative fire-plan/derivative source actually used,
2. whole-complex planform,
3. `RIDHUS ↔ intermediate volume(s) ↔ STALL` interface table,
4. before/after proof that no false open-air gap remains,
5. corrected confidence classification for stable width,
6. direct-source vs textual-derivative evidence labels,
7. Roblox implementation/parity status,
8. remaining assumptions and reference gaps,
9. exact commit SHAs.

Hand back for **ChatGPT Senior Fidelity Review 02**.

Do not merge PR #22 and do not call Gate F01 fidelity-ready before that review.
