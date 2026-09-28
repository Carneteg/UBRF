# Circle: event-bound advice when the circle leaves the line (C1)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code.
Order: [CHATGPT_REVIEW_C1_HALT_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5863698440),
base `20a4df4`, branch `codex/circle-lesson-20260926`. Build now, physical test last.
Claude writes; ChatGPT reviews source; Tobias playtests the whole at the end.

## Why this package, and not the replay link

The order's first preference was a feedback → existing replay link. After
inspecting the source, that is **not** a clean independent package.

1. `ReplayController` plays an `Inspelning.Post`. The post is recorded
   CLIENT-side by `LektionController`, for the canon's legacy client exercises
   only (`Inspelning.spelasIn` → `KANON.OVNING`). The server lessons have no
   recording and no canon exercise id.
2. The only server-observed path is `RidObservation.rutt`, and it has three problems:
   - it is per RIDE, not per attempt;
   - it is capped at 512 points (2 studs apart, about 340 m). After that it is
     truncated for the rest of the ride, so a replay link would silently be
     missing on longer rides;
   - it is not delivered to the client at all. A link would need a new remote
     with rate limiting, per-attempt slicing and conversion to the replay
     format.
3. A replay drawn from the client's own recording would show a different path
   from the one the server judged. `LektionController` warns against exactly
   that.

So this package takes the order's second option: one bounded event-bound
advice slice that uses an already-observed server fact.

## The one fact used

When the attempt is reset because the horse was more than 4 m from the circle
line, `VoltLektion` already computes `avvikelse(p) = |dist(p, centre) − RADIE|`.
The sign of `dist − RADIE` at that very point says whether the horse was
**outside** the line (drifted out) or **inside** it (fell in).
- It is the same point and the same computation as the reset check, without the abs.
- It is not a new observation, and it is not a new threshold.

**Where there is no side:**
- **Aggregate resets:** a section's `maxAvvikelse`, a direction reversal (`motriktning`), or a completion check (`medelAvvikelse` / `aterkomst`). Here the section's side is not known from one point, so there is NO side and the existing generic "line" text stays.
- **Every other reset** (unknown, observation break, frame change) also gets no side.

## Server (`VoltLektion`)

**Setting it.** `disarm(s, "line", sida)` sets `s.linjeSida = "ut"` or `"in"`, together with `s.linjeForsok = s.forsokId`. Only the point-deviation branch sets it.

**Clearing it.** Every other `disarm`, arming (approach → baseline), start and retry clear it.

**The snapshot** carries `linjeSida` only when all of these hold:
- `lage == "approach"`;
- `tips == "line"`;
- `s.linjeForsok == s.forsokId`.

Otherwise it carries `nil`. The side is gone as soon as the player finds the band again, so she is never corrected for something she has already fixed.

**Unchanged:** no result, lifecycle, threshold or frozen result changes.

## Client (`VoltLektionController`)

**When it shows.** Only when the page's key is `line`, the type is `volt`, and `b.linjeSida` is exactly `"ut"` or `"in"`. The page text is then ONE concrete, positive line with a literal key:
- `voltlektion.line_ut`, sv: "Ni gled lite utåt från volten. Styr in mot mitten och titta dit du vill rida – hitta bandet igen, så börjar vi ett nytt varv."
- `voltlektion.line_in`, sv: "Ni kom lite för nära mitten. Styr ut mot bandet och håll samma avstånd runt hela varvet – hitta bandet igen, så börjar vi ett nytt varv."
- Both have English.

**Otherwise** the existing `voltlektion.line` text is unchanged.

**Why the settings don't apply.** This is the lesson's own status explanation for a reset, not an optional live comment, so the comment setting does not remove it. It is already one short line in both detail modes.

**It never claims:**
- cause (a horse or a rider fault);
- aids that are not observed (legs, reins).

"Steer" is the game's own control, named without a device-specific key.

## Acceptance (written as tests; engine and physical play deferred)

**Server and real client (`voltlektion.spec`), on a fresh ride:**
- ride part of a circle, then a point at radius 10 + 4.5 m: the attempt resets with `line`, `linjeSida == "ut"`, and the real `VoltLektionController.panel()` shows the outward advice;
- a point at radius 10 − 4.5 m gives `"in"` and the inward advice;
- re-arming at the band clears it (no side in the snapshot, generic text never forced);
- a declared KONTROLL aggregate reset (`maxAvvikelse` > 4) gives `line` with NO side and the generic text;
- retry and finish carry no side;
- a delayed snapshot from another attempt with a side is not shown by the client;
- the locale switch changes the words;
- both keys exist in SV and EN.

**Falsification:** each of these guards is mutated and must turn a test red:
- the sign (in/out swapped);
- setting a side in the aggregate branch;
- not clearing on arming;
- the snapshot guard for the attempt id;
- the client side check.

**Not tested here:**
- Studio, runtime and touch;
- the rendered text length;
- whether the advice helps a player ride the next circle better. That is the final playtest.
