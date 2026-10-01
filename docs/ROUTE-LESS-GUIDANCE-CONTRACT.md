# Route lessons: "Rid utan streck" — less guidance by the player's choice (C3, option A)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code (ACK [#5864416219](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864416219)).
Decision: [TOBIAS_DECISION_C3_LESS_GUIDANCE_OPTION_A_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864371448),
after [C3_MAPPING_DECISION_NEEDED](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864316521).
Base `1df0161`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

## Scope: the two route lessons only (`vag_mitt`, `vag_diag`); client only

**The guide today.** `VoltLektionController.vagGuide` draws three things into the local, non-physical `Voltguide` model:
- the line as dashes;
- direction chevrons every 6 m;
- a start ring and an end ring.

The server (`VagLektion`) never reads the guide.

**Eligible.** The lesson is a route type, and `klarad(typ)` holds. That is the existing `LektionsMinne` state for this lesson: `sparad` (saved) or `vantar` (completed, waiting to be saved).

**The choice.** On the route lesson's page, in any state, one extra button:
- `vaglektion.utan_streck` "Rid utan streck" / "Ride without lines", when eligible and the full guide is shown;
- `vaglektion.visa_vagen` "Visa vägen" / "Show the way", whenever less guidance is on, eligible or not.

Pressing it toggles a client flag and redraws the guide at once. It sends nothing to the server.

**Less guidance.** `vagGuide` draws **only the start and end rings**, with their existing solid/faint rule. The dashes and chevrons are not drawn. The guide cache includes the flag, so a toggle always redraws.

**Lifetime.**
- The flag is session-local.
- It resets to the full guide on:
  - a new ride;
  - choosing another lesson type;
  - `V.avbryt`.
- **Nothing is saved.** The guidance **never shrinks by itself**.

**Unchanged:**
- the server task, corridor, thresholds and completion;
- the feedback and memory;
- the other lessons' guides;
- the start/retry/finish buttons.

The page gets at most one more button: start or retry, then the toggle, then finish, which is 3 or fewer and fits within MAX_VAL 4.

**It never claims** a better result, a separate achievement, or that the player "needs" the guide. It is a self-chosen challenge.

## Acceptance (written as tests; engine and physical play deferred)

The tests live in `vaglektion.spec`, through the real `VoltLektionController` and the real `Voltguide`:
1. **Not eligible** (memory not `sparad`/`vantar`): there is no "Rid utan streck" button, and the full guide has dashes, chevrons and rings.
2. **Eligible:** the button is present. Pressing it sends no request. The guide then contains only the ring parts: the count equals the rings' part count, and no line or chevron part remains. The button is now "Visa vägen".
3. **"Visa vägen"** restores the full guide, with the same part count as before.
4. **Unchanged task:** with less guidance on, an ordered ride-through completes exactly as before (same `complete`, same frozen result shape).
5. **Reset:** choosing another type and coming back, and a new ride, both give the full guide.
6. **Other types:** a non-route lesson never shows the button, even when completed.
7. **Keys:** SV and EN.

**Falsification:**
- dashes still drawn with less guidance on;
- rings dropped;
- the button shown without completion;
- the flag not reset on a type switch;
- the cache ignoring the flag.

**Full local suite once.**

**Not tested:**
- Studio, runtime and touch;
- whether the rings alone are visible enough on screen;
- whether players enjoy the challenge.
