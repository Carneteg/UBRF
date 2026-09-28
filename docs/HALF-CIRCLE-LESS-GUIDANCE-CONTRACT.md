# Half-circle lesson: less guidance along the track by the player's choice (C3, option A pattern)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code (ACK [#5865002800](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865002800)).
Decision: [TOBIAS_DECISION_C3_HALF_CIRCLE_OPTION_A_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864962898),
after [C3_HALF_CIRCLE_LESS_GUIDANCE_STOP_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864649913).
Semantics as in [ROUTE-LESS-GUIDANCE-CONTRACT.md](ROUTE-LESS-GUIDANCE-CONTRACT.md).
Base `e1daf52`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

## Why not the corner's pattern

The return diagonal (20.6 m) ends at the end ring `(uT, 8)`, on the same track line as the start ring `(uT, 16)`. During the return, both rings are faint. Without the diagonal, the nearer ring (the start ring, 14.1 m away) would look like the target. That is ambiguous, so it is not done.

## The exact reduction (`halvvoltGuide`, client only)

**Removed:** only the **ride-in straight along the track**, `rak(uT, p0v → uT, t1v)`, meaning both its dashes and its chevrons.

**Kept, unchanged:**
- the half-circle's 16 dashes;
- the **return diagonal**, with its dashes and chevrons;
- the start ring and the end ring;
- the solid/faint rule by `delmal`.

**Why what remains is unambiguous from source:**
- The removed part is collinear on `u = uT`, from the start ring to the curve's first dash (10 m).
- It lies on the track by the wall, between two visible features.
- Every other part of the route keeps its drawn line.

**Honest limit:** visual sufficiency from the saddle, with a 1.5 m corridor, is not claimed; it belongs to the physical test.

## Semantics

**Eligibility.** Only when `klarad("halvvolt")` holds (LektionsMinne `sparad`/`vantar`), and only on the half-circle page.

**Label.** The half-circle's own truthful text:
- `halvvoltlektion.mindre_stod`: "Rid utan strecken längs spåret" / "Ride without the lines along the track".
- "Visa vägen" (`vaglektion.visa_vagen`) restores the full guide.

**Lifetime.** The same session-local flag as the route lessons and the corner. It resets on a type switch, a cancel or reattach, and a new ride. It is never saved, never automatic, and sends no server request.

**Unchanged:** the server task, corridor, joins, halt rule, thresholds, feedback and memory; every other guide.

## Acceptance (written as tests; engine and physical play deferred)

The tests are in `halvvoltlektion.spec`, through the real `VoltLektionController` and the real `Voltguide` parts.

**How the parts are classified.** Each part is converted to the frame with `Ridhusplats.tillLokal`:
- **ring:** a ring dash by width;
- **track:** `|u − uT| < 1` and `p0v < v < t1v`;
- **other:** everything else (the curve and the return).

**Checks:**
1. Not completed: no choice; the full guide has track parts > 0, other > 0 and rings > 0.
2. Completed: the half-circle's own label (not the route or corner label).
3. Pressing it sends no request.
4. After pressing: track = 0, while other and rings are unchanged. The button reads "Visa vägen".
5. The ordered route completes as before with less guidance on.
6. "Visa vägen" gives the full counts again.
7. A type switch, cancel plus reattach, and a new ride reset it.
8. Another type is counted and shows no choice.
9. SV/EN.
10. `vaglektion.spec` and `hornlektion.spec` stay green.

**Falsification:**
- the track straight still drawn;
- the return removed as well (it must stay);
- the curve dropped;
- the rings dropped;
- the choice without completion;
- the corner's or route label used;
- no reset.

**Full suite once.**

**Not tested:**
- Studio, runtime and touch;
- visual sufficiency;
- fun.
