# Corner lesson: less guidance by the player's choice (C3, option A pattern)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code (ACK [#5864537847](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864537847)).
Order: [CHATGPT_REVIEW_C3_ROUTE_LESS_GUIDANCE_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864503678).
Semantics as in [ROUTE-LESS-GUIDANCE-CONTRACT.md](ROUTE-LESS-GUIDANCE-CONTRACT.md) (Tobias' option A).
Base `7b22f02`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

## Which lesson, and why

I inspected the guides in the order given (`serpentinGuide`, `halvvoltGuide`, `hornGuide`):
- **Serpentine: NOT clean.** Its guide is only curves (three loops of radius `r` that alternate sides) plus a start ring and an end ring on the centre line. With the curves removed, two rings say nothing about the loops' size or sides. The reduced guide would be ambiguous, so it is not done.
- **Half-circle and corner:** each is `straight → curve → straight`, plus the rings. The straights can go and the curve can stay, and nothing becomes ambiguous.
- **The corner is the smallest figure:** a ride-in of 10 m on the track, a quarter circle of radius 5 m, and a ride-out of 6 m along the short side. The track lies 1.5 m inside the edge.

## The exact reduction (`hornGuide`, client only)

**Removed:** the dashes **and** chevrons of the two straight parts:
- the ride-in, `rak(p0 → (uT, cv))`;
- the ride-out, `rak((cu, cv + r) → p3)`.

**Kept, unchanged:**
- the quarter circle's 10 dashes;
- the start ring and the end ring;
- the existing solid/faint rule by `delmal`.

**Why what remains is enough to attempt the task:**
- The ride-in runs from the start ring straight to the first dash of the curve.
- The ride-out runs from the last dash of the curve straight to the end ring.
- Each is therefore a straight line between two visible features, and both lie on the arena's track by the wall.
- The direction is given by the start ring (the lesson only arms from it) and by the curve.

The server assessment is untouched, including the corridor of 1.2 m, the mid-arc checkpoint and the thresholds.

**Honest limit:** that this is enough *geometrically* can be read from the source. Whether it is enough *visually* from the saddle, with a 1.2 m corridor, can only be judged in Studio or in play. It is listed under Not tested and not claimed.

## Semantics (as for the route lessons)

**Eligibility.** The choice is offered only when `klarad("hornet")` holds (LektionsMinne `sparad`/`vantar`), and only on the corner page.

**Label.** The button text is new, because the curve's dashes remain and "utan streck" would be untrue:
- **`hornlektion.mindre_stod`:** "Rid med bara bågen och ringarna" / "Ride with only the curve and rings".
- **"Visa vägen":** `vaglektion.visa_vagen`, reused, restores the full guide.

**Lifetime.** The same session-local flag, which:
- resets on a type switch, a cancel or reattach, and a new ride;
- is never saved;
- is never automatic;
- sends no server request.

**Unchanged:** the server task, feedback and memory; the route lessons' behaviour; every other guide.

## Acceptance (written as tests; engine and physical play deferred)

**`hornlektion.spec`**, through the real `VoltLektionController` and the real `Voltguide` parts:
- **how parts are told apart:** straight dashes and curve dashes have the same width, so a curve dash is identified by lying at radius `r` from `(cu, cv)`; ring dashes and chevrons are identified by their widths.

The cases:
1. not completed: no choice, and the full guide has straights, curve and rings;
2. completed: the choice appears; pressing it sends no request; the curve and ring counts are the same as in the full guide, and there are 0 straight dashes and 0 chevrons; the button becomes "Visa vägen";
3. an ordered ride-through completes as before with less guidance on;
4. "Visa vägen" gives the full counts again;
5. a type switch, cancel plus reattach, and a new ride all reset it;
6. another type (halt) is counted and shows no choice;
7. SV/EN.

`vaglektion.spec` (the route lessons) stays green unchanged.

**Falsification:**
- the straights still drawn;
- the curve dropped;
- the rings dropped;
- no completion needed;
- the reset removed;
- the route label used instead of the corner's own label.

**Full suite once.**

**Not tested:** Studio, runtime, touch, visual sufficiency from the saddle, and fun.
