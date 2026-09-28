# D2a: the first clear-round ride — start signal, course, verdict (UBRF training, simplified judging)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code (#5865766798; Tobias reconfirmed B #5865805419).

**Deviations found while building (reported openly):**
- **A dismount during the course** — corrected in R1 (CHATGPT_REVIEW_D2A_CHANGES_REQUESTED, #5866272051):
  - Before the ride teardown, `HorseService.setRider` calls `ClearRoundLektion.vidRittSlut`. An **active** clear-round ride then gets **exactly one** terminal outcome: `utfall = "avbruten"`, with the ride-end reason (`avsittning` or another).
  - It is **not** a fall, because a voluntary dismount is not distinguished from one. It is never success, and gives no restart, no rosette and no `felfri`.
  - The attempt closes once, as `avbrutet`.
  - The outcome is kept per player (session-local, never persistent) and shown the next time clear round opens ("Förra clear round-ritten avbröts …"). It is cleared when a new ride starts.
  - A dismount **after** a finished result changes nothing.
- **The test bundle grew by two modules**, which pushed `voltlektion.spec` over Luau's 200-register limit. Its actor section now has its own function scope.
Decisions: judging **B** ([#5865714893](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865714893)), with the prize rule corrected by
[CHATGPT_CORRECTION_D2_SIMPLIFIED_JUDGING](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865734148), and course **(ii)**
([#5865730798](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865730798)); the UBRF local rosette convention
([#5865623410](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865623410)).
Rules: [`references/rules/TR-III-2025-hoppning-A-clear-round.md`](../references/rules/TR-III-2025-hoppning-A-clear-round.md), plus the TR III moments cited below.
Base `f20d414`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

## Scope: the smallest playable slice of D2

**Included:** one solo clear-round ride in the indoor arena, as a new server lesson type **`clearround`** in the existing lesson framework. The steps are:
1. start (the start signal);
2. ride to the start line;
3. the course;
4. the finish line;
5. the verdict;
6. one restart;
7. finish.

**Not included in this package** (D2b and later, named):
- entry and start list;
- course walk;
- warm-up;
- prize-giving ceremony;
- aftercare;
- rosette persistence and trophy cabinet (D4);
- competition clothes (D5);
- multiplayer.

## The class and the course (data, not code)

- **Class:** "Clear round (UBRF training)". It is a horse class, and the height is that of the built fences: `ridhus_hinder_bla_24` 0.68 m and `ridhus_hinder_rod_38` 0.52 m, so the class height is 0.68 m. That is within TR 314.1.1 (≤ 0.90 m) and UBRF's 2026 range for horses (50–75 cm).
- **Honestly not a TR standard class:** TR 312.18–19 requires 9–11 fences for 0.90 m and lower. This is a two-fence **training course** (UBRF "Trivselhoppet = träning"), and the result card says so.
- **The course (ii)**, 4 jumps over the two fences:
  1. blue towards C;
  2. red towards C;
  3. blue towards A;
  4. red towards C.
  The directions are `[antagande]`, a game course design and not UBRF-verified. They live in data (`bana`), so Tobias or Replit can change them without a code change.
- **Start line:** 8 m before jump 1, on its approach side, perpendicular to the approach, 8 m wide.
- **Finish line:** 8 m after jump 4, on its landing side.
- These follow TR 352.3 (6–15 m before the first fence and after the last); the exact 8 m is an `[antagande]`.

## Judging (B, simplified): only what is observed

Each start line crossing opens the course.

**Per fence**, using the existing `HinderObservation` attempts, after the start line crossing:
- **The next expected fence:**
  - `passage` in the expected direction advances the course;
  - `sidan_om` (a run-out) counts **one disobedience** (TR 385; the rider presents again);
  - `ingen_passage` is **not judged**, and this is stated. A TR refusal or circle is not observed.
- **Any other fence**, or the next fence in the wrong direction: a `passage` means **wrong course**, which eliminates (TR 384.1, 388.2.2).
- **Observation broken** (`brott`, `okant`): the ride **cannot be judged**. No verdict and no rosette, and the text says so.

**Other outcomes:**
- **Dismount** during the course: `avfallning`, which eliminates (TR 388.2.8). `[antagande]`: every dismount counts, since a voluntary one is not told apart.
- **Knockdowns:** **always 0 by construction**. The poles cannot be knocked down in this version, and the card says so.

**Time:**
- TR 312.3.2: horse classes up to 1.05 m have **no maximum time and no time faults**, and the allowed time is **180 s**. Exceeding it eliminates (388.2.6).
- TR 388.2.3.2: crossing the start line more than **45 s** after the start signal means **not started** ("struken"), and the attempt closes without a verdict.
- The per-fence 45 s rules (388.2.3.1 and 2.5) are **not implemented**, and this is stated.

**Verdict: simplified, never "fault-free":**
- The server computes the observed faults with `Klassprofil.clearRound`, using `hojdM = 0.68`, `ponny = false` and `nedslag = 0`, plus the observed `olydnader`, `avfallning`, `felVag`, `overMaxtidS = 0` and `overTillatenTid`.
- The profile moves from `roblox/regler/` into the mapped `src/shared/HorseCore/`, because the server now consumes it.
- The result is **`bedomning = "forenklad"`**, and it has three outcomes:
  - **"inga observerade fel"** (no observed faults) — this is **not** "fault-free", because knockdowns are unobservable;
  - **observed faults**, with their count;
  - **eliminated**.
- The profile's `felfri` and `rosett` are **not** exposed as a clear-round claim.

**No Clear Round rosette in this package.** It is not awarded and not persisted, whether for attempt 1 or attempt 2 (CHATGPT_CORRECTION_D2_SIMPLIFIED_JUDGING):
- "fault-free" is not established while knockdowns are unobservable;
- the result card says the real clear-round rosette comes when knockdowns can be judged (B4);
- the SvRF TR 314.1.1 and UBRF-convention rosette logic stays in D1, ready for when B4 lands;
- a separately named **training keepsake** is optional and **not built here** (Tobias' call, D4).

**Restart:** exactly one, after faults or elimination in attempt 1 (314.1.1). It does not count as a start (301.3.1.2). After attempt 2 there is Finish only.

## Player-facing

**Lesson picker:** one new entry, "Clear round (träning)", in the lesson menu, with SV/EN keys.

**Page texts:**
- "Rid till startlinjen";
- then the next jump by number and colour ("Hinder 2: rött, mot C");
- then "Mot mållinjen".

**Result card:**
- "Inga observerade fel" / "N olydnader" / "Utesluten: <reason>";
- time;
- **"Förenklad bedömning: rivningar bedöms inte ännu — clear round-rosetten delas ut när de kan bedömas"**;
- "Träningsbana, inte en standardklass";
- the Restart button when it applies.
- There is **no rosette text**.

**Guide (client, not physical):** start and finish lines drawn as dashes. The fences are the real ones.

## The lock and the playtest

This package changes **runtime-mapped** sources, so the A2 build identity (`e23198df4614…`) becomes invalid. The package ends by **re-locking**: a new `kallhash`, and the checklist gets new rows for the clear-round ride (§6). The new identity is recorded.

## Acceptance (written as tests; engine and physical play deferred)

**Server (`clearroundlektion.spec`)**, through the real HorseService, the real arena, `HinderObservation` and the observations:
1. The start signal is followed by a start line crossing within 45 s. The course runs blue→C, red→C, blue→A, red→C, then the finish line, giving **"no observed faults"**, `bedomning = "forenklad"` and **no rosette**.
2. One run-out gives 1 disobedience, not fault-free, and a restart is offered.
3. Three run-outs give elimination.
4. Jumping red first (wrong course) gives elimination.
5. Blue in the wrong direction as jump 3 gives elimination.
6. **Dismount mid-course** (R1) gives exactly one terminal outcome, `avbruten` (with reason `avsittning`). It is never success, gives no restart or rosette, and closes the attempt as `avbrutet`. It shows at the next opening, and a new ride clears it. A dismount after a finished result gives nothing.
7. More than 180 s gives elimination.
8. No start line crossing within 45 s gives not started.
9. An observation break mid-course gives cannot be judged, with no rosette.
10. A restart after faults opens attempt 2, which can reach "no observed faults", again with **no rosette**. After attempt 2 there is no further restart.
11. Knockdowns are always 0, and the result carries "simplified".

**Client:**
- the menu entry;
- the page texts per step;
- the result card texts (simplified, training course, and **no** rosette text), SV/EN.

**Also:**
- `regelprofil.spec` stays green after the move;
- the checklist and identity are re-locked.

**Falsification:**
- the direction check;
- the run-out counted as a passage;
- the wrong course not eliminating;
- a dismount not eliminating;
- the 180 s limit;
- the 45 s start;
- a rosette or "felfri" leaking into the result;
- the result missing "forenklad";
- a second restart.

**Full suite once.**

**Not tested:**
- Studio, runtime and touch;
- whether the horse can actually clear 0.68 m in play (the jump physics, B4);
- whether start and finish lines are visible;
- fun.
