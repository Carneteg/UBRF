# D2c: after the ride — from the clear round result into the existing aftercare

Status: contract written before code, 2026-09-28.
Order: [CHATGPT_REVIEW_D2B_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5867354110), which asks for "the smallest source-testable package, D2c or D5".
Base `94a643c`, branch `codex/circle-lesson-20260926`. Build now; physical test last.

## Starting point (verified in the code, not assumed)

The aftercare already exists and applies to **every** ride.
- `HorseService.setRider` → `Pass.vidAvsittning` moves the session `riding` → `aftercare`.
- `GameplayService.eftervard` carries out the steps. Their canon is `UBRFSkotsel.eftervard`, from `src/spel/skotsel.js`: girth, saddle, bridle, legs, water.
- `Pass.farAvsluta` is fail-closed until every step is done. The session is then counted once (`Sparning.registreraPass`).

**D2c therefore builds no new aftercare and no new state.** It builds the bridge from the clear round, plus evidence that the chain holds for a competition ride.

## What is built

| Part | Owner | Content |
|---|---|---|
| Snapshot | server (`ClearRoundLektion`) | In `complete` and in `closed` after a result (including `avbruten`): `eftervard = {names in canon order}`, taken from `Pass.moment()`. **Never** in `ready`/`startlista`/`banskiss`/`to_start`/`course`/`to_finish`. |
| Result card | client (`LektionsAterkoppling`) | One line, only when the snapshot carries `eftervard`: "När ni är klara: sitt av – eftervården väntar: gjord · sadel · träns · ben · vatten." The names come from the snapshot. There is no hard-coded list. |
| Texts | `sprak.js` | The line in SV and EN. It does **not** say where the aftercare happens (no "i stallet"), because the aftercare's presence requirement is the one the care code already has. |

**Not built:**
- warm-up, walking off, cooling down or a return route (no canon in `skotsel.js`; the site mapping is unresolved);
- prize-giving, the rosette, persistence;
- D5 clothing.

**Nothing new is persisted.** The session is counted exactly as today.

## Acceptance

1. `complete` carries `eftervard` in canon order, equal to `Pass.moment()`. `ready`/`startlista`/`banskiss`/`course` do not.
2. The whole chain, through the real `GameplayService` + `HorseService`, runs:
   1. the session `before_ride`;
   2. mount (`riding`);
   3. the clear round `anmal → ga_banan → start →` the course `→ complete`;
   4. dismount (`aftercare`);
   5. the aftercare steps in order;
   6. `done`, and the session counted **once**.
3. A dismount mid-course (`avbruten`) **also** leads to `aftercare`. The horse is cared for whether or not the round was finished.
4. The clear round writes nothing persistent, and the session count is unchanged apart from the one existing registration.
5. **Client:** the aftercare line shows on the result card with the snapshot's names, in SV and EN. It is absent before the result.
6. **Falsification:**
   - the line hard-coded in the client (caught with a declared snapshot with other names);
   - `eftervard` already in `course`;
   - the list order reversed;
   - the chain: `vidAvsittning` skipped for clear round.

**Full suite once; re-lock the identity.**

**Not tested:** Studio, runtime, touch, and the physical walk to where the aftercare is done.
