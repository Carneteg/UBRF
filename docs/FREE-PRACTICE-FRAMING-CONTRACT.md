# Legacy 22 s pass framed honestly as free practice with replay (C3, option A)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code.
Decision: [TOBIAS_DECISION_C3_OPTION_A_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864161019)
("Vi kör A"), after [C1_GAP_SUMMARY_AND_C3_DECISION_NEEDED](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864130394).
Base `63f5279`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

## What the legacy path is today (read in source)

`LektionController` runs the canon pass (`HorseCore/Lektion`, shared with the
web). Every attempt ends on the clock `Lektion.FORSOK_SEK = 22`, and
`Ugneta.observationer` rates the averages.

It is visible in THREE places on Roblox:
1. **By default at mount.** `VoltLektionController.tarOver()` is false until the
   player picks a lesson or free riding, so the pass's presentation card is
   shown with the button `ugneta.borja_lektionen`: "Fortsätt för att börja
   lektionen".
2. **From free riding**, through the button `voltlektion.lessons`: "Andra övningar".
3. **At every attempt end.** `UgnetaController.efterForsok` has the title
   "Prova igen" for the first attempt and "Försök %d" after that, then the
   observation lines. The buttons are Prova igen / Nästa övning, Se ritten and
   Gå vidare.

Nothing is saved as completed and no text says "klarad". But it is presented as
"the lesson", and each round is ended by the clock. That reads like an exercise
the clock approves, and that is exactly what C3 forbids. Every legacy exercise
now has a task-based server lesson.

## Change (Roblox client text only)

**New literal keys, SV/EN, in `src/spel/sprak.js` → `UBRFSprak`:**
1. `voltlektion.fri_traning` replaces the "Andra övningar" label: "Fri träning med återspelning" / "Free practice with replay".
2. `ugneta.borja_fri_traning` replaces the presentation button: "Börja fri träning – rundor på %d s" / "Start free practice – %d s rounds".
3. `ugneta.runda_slut` replaces the attempt-end title for EVERY round: "Runda %d – tiden (%d s) är slut" / "Round %d – time (%d s) is up".

The seconds come from `Lektion.FORSOK_SEK`, read as a constant; it is never copied.

**Unchanged:**
- the shared `HorseCore/Lektion` (clock, pass, grading, history);
- the web;
- the replay and its button;
- the observation lines;
- Prova igen / Nästa övning / Gå vidare as actions;
- the server lessons;
- lesson memory.

The old keys stay in the catalogue (the web must not lose anything). The Roblox source no longer uses them.

**It never claims:**
- that a round is a passed exercise;
- that the clock judged anything.

The observation lines are what they already were: Ugneta's reading of the averages.

## Acceptance (written as tests; engine and physical play deferred)

- **The real `VoltLektionController`**, after finish in free riding: the button reads `voltlektion.fri_traning`, and pressing it still starts the legacy pass. This is the existing `voltlektion.spec` flow, retargeted.
- **The presentation card** (`klient.spec` / `klient-ugnetayta.spec`, wherever the button is asserted today): the button reads `ugneta.borja_fri_traning` with 22.
- **The attempt-end card** (`UgnetaController.efterForsok`): round 1 and round 2 both get the `runda_slut` title with their round number and 22 s. "Prova igen", "Försök" and "lektionen" appear in no title. Se ritten is still offered when a recording exists.
- **Locale:** English words, the same numbers.
- **Keys:** all three exist in SV and EN.
- **Grep gate in the spec:** no Roblox client source still uses `voltlektion.lessons`, `ugneta.borja_lektionen` or the `ugneta.forsok` title.
- **Falsification:**
  - each old key put back;
  - the seconds hard-coded to another value;
  - the round number dropped.
- **The full local suite once.**

**Not tested:**
- Studio, runtime and touch;
- the rendered length of the longer labels on a phone;
- whether players understand the difference between free practice and the task lessons (the final playtest).
