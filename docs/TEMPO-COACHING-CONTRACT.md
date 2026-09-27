# Tempo coaching: one cue at a time, and a comparable repeat (partial C1)

Status: BUILT_NOT_VERIFIED, 2026-09-27. This contract was written BEFORE the
production edits for this slice.
Order: [TEMPO_COACHING_BUILD](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857533061),
base 97a936a. Build now, test last. Claude writes; Codex reviews source;
Tobias plays the whole candidate at the end.

This slice covers the tempo lesson only, "steady walk" (`jamn_skritt`).

It adds:
- ONE optional written cue at a time for observed speed and unevenness;
- a factual comparison with the previous completed attempt in the same ride.

It is not a coaching platform, a skill measure or C1 as a whole. The other
lessons are unchanged.

## Source (read before the edits)

- **What the tempo step already detects.** `TempoLektion.steg` evaluates each
  fresh sample only after the break checks (gaps, missing samples,
  teleports, frame, position, log overflow), the gait and position checks,
  the skipped first step and "exactly one new segment". Then it classifies
  the speed:
  - `too_slow`: below `GOLV` (0.9 m/s);
  - `too_fast`: above `TAK` (2.2 m/s);
  - `steadier`: the spread exceeds `SPRIDNING`.

  Everything else (`unknown`, `walk_on`, `walk_only`, `stay_inside`) is a
  mandatory task text or a reset, not evidence of speed.
- **Why the client can't see repeats today.** `andra` does NOT bump the
  revision when the tip is already the same. A second genuine `too_slow`
  sample therefore cannot be told apart from nothing.
- **How speed within walk is controlled.** The actual control is the forward
  axis. `MovementController.step` sets the target as
  `gait.norm + forward · (max − norm) · 0.35`, within the gait's band.
  - W or the stick pushes the tempo WITHIN walk.
  - DRIVE and SLOW (Ridtrappa) change GAIT, which would break the exercise.
- **The frozen result.** It carries `prov`, `sekunder`, `meter`,
  `medelFart` and `spridning` (defined as (max − min) / mean), plus
  identity. Retry clears `s.resultat`.

## Producer evidence (narrow, in TempoLektion's existing step)

- **A per-attempt counter.** `s.coachNr` counts events, `s.coachSkal` holds
  the reason, and each event adds one revision.
  - It is incremented ONLY at the three speed classifications, which are
    already after every break and freshness check.
  - Sampling rate, continuity resets, completion thresholds and RidForsok
    are unchanged.
  - Start and Retry reset `coachNr` to 0.
- **In the snapshot.** It carries `coachNr` and `coachSkal`, bound to that
  snapshot's `forsokId`, ride and type.
- **Not events:** unknown, a gap, a teleport, the wrong gait, leaving the
  arena, or the first step after a reset. A post-reset "keep going" is also
  not an event and never proves improvement.

## The client cue (VoltLektionController, the actual lesson page)

- **Baseline.** The first snapshot of an attempt (Start, sync, reattach or
  a new `forsokId`) SETS the baseline `coachSedd = coachNr` and shows
  nothing.
- **A new event** is `coachNr > coachSedd` in an ACCEPTED snapshot (it has
  passed `mottag`'s ride, type and revision guards) for the SAME attempt,
  in the `steady` state, with no request pending and no error. The new
  number is always consumed.
- **Eligibility.**
  - The cooldown `LIVE_CD.fel` (8 s) must have run out.
  - No start greeting may be visible, because the greeting wins.
  - An event that is not eligible is consumed without being shown or
    counted.
  - An eligible event calls `UgnetaController.valfriKommentar()` ONCE
    (Normal, Fewer or Off, with the shared Fewer counter). Yes shows the cue
    for `LIVE_CD.visa` (2.6 s); no consumes it.
  - There is no queue and no replay.
- **The text** is one concrete action on the actual control and does not
  repeat the task tip:
  - `too_slow`: hold forward a little more (W or the stick);
  - `too_fast`: ease off forward;
  - `steadier`: keep forward even, no jerks.

  No hands, seat, leg or rhythm.
- **Precedence on the page:** greeting, OR cue, then the task text and the
  progress. The mandatory task text always remains.
- **Removal:**
  - Off removes it immediately (the existing subscription);
  - pending, error, a new attempt, a change of state, choice, ride or
    reattach, or dismount removes it;
  - it runs out in `V.steg`.
- **Redraws.** Language and detail changes redraw, never create.

## The comparison with the previous completed attempt

- **Server.** At completion, TempoLektion keeps the previous DISTINCT valid
  completion `s.forraKlar` (another `forsokId` from the same lesson object,
  so the same ride, horse and definition). It is kept across Retry and
  replaced only by a new valid completion.
- **The frozen comparison** `s.jamforelse = {forsokId, forraForsokId,
  forraSpridning, spridning}` is created only when:
  - both spreads are finite and non-negative;
  - both mean speeds are finite and positive;
  - the version is the same.

  The snapshot carries it only in `complete`, for the same `forsokId`.
- **What never compares:** timeout, closed or a malformed result. Nothing
  becomes zero, and a valid baseline is never overwritten.
- **Reset.** A new lesson object (another ride, or a type switch that
  replaces it) starts without a baseline, so A-B-A gives no comparison.
- **Client (`LektionsAterkoppling`), DETAILED mode:**
  - only when the rounded percentages differ the RIGHT way:
    "More even than your previous attempt: the spread was X %, now Y %";
  - otherwise, when comparable: "Previous attempt: X % spread, now Y %";
  - when not comparable: nothing.
- **Client, CONCISE mode:** only "More even than last time." when that
  holds, otherwise nothing.
- **What it never claims:** mastery, cause, or that the cue worked. The
  frozen summary and the ONE next step remain.

## The leading-memory documentation fix (P3)

`LEADING-MEMORY-CONTRACT.md` is corrected:
- the character and model replacement and future-version save cases are
  PLANNED, not written;
- L4's heading is "Release and re-take; another actor".

## Deferred verification (written, NOT run)

`roblox/tests/tempocoachning.spec.luau` (KOHERENS) uses a TempoLektion
fixture with real HorseService observations.

**Genuine sample-driven fixtures (SYNCHRONOUS):**
- slow, fast and uneven give events with a counter;
- a repeated same-reason event versus a redraw;
- unknown, a gap, a teleport and the wrong gait give no event;
- two real completions give the comparison.

**FABRICATED client snapshots:**
- the baseline on attach and reattach;
- cooldown;
- Normal, Fewer and Off while visible;
- language and detail redraw;
- pending, timeout and Finish;
- reversed delayed replies;
- A-B-A;
- a change of ride;
- the greeting's precedence;
- equal, worse and not-comparable comparisons;
- a duplicate completion;
- the four-row host.

**Planned, not written:**
- physical rendering;
- whether the cue helps (a human gate).

## R1 correction ([TEMPO_COACHING_SOURCE_R1](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857608987))

This section was written BEFORE the R1 production edits.

### Applicability is not the same as event history

- **Event history** is `coachNr`: monotonic, counted only at the three
  classifications.
- **Current applicability** is the snapshot's CURRENT tip: a cue with reason
  X is supported only while `tips == X`. Anything else ends it:
  - the opposite classification;
  - `unknown`, a gap or a teleport;
  - `walk_only`, `walk_on` or `stay_inside`;
  - `keep_going`, a recovery (with no automatic praise);
  - complete or closed;
  - a request or context teardown.
- **Producer.** TempoLektion clears `coachSkal` on every classification that
  is NOT a coaching event (the resets and `keep_going`). A later
  incompatible snapshot therefore carries no retained old reason. `coachNr`
  is untouched.
- **Client, when a snapshot is consumed** (`mottag`, the path every accepted
  snapshot goes through):
  - a visible cue is removed AT ONCE if the newly accepted snapshot no
    longer supports it (another attempt, not `steady`, or `tips ~= skal`),
    so an intermediate invalidating snapshot is never forgotten between
    renders;
  - a NEW cue requires `COACH_SKAL[b.coachSkal]` AND `b.tips ==
    b.coachSkal`, so a higher unseen `coachNr` in an incompatible snapshot
    is consumed without anything being shown.
- **Rendering** has the same check defensively (`b.tips == cg.skal`).
- **Removal never does any of these:**
  - touch the cooldown;
  - count Fewer;
  - queue a replacement;
  - replay a consumed event.

  A genuinely new eligible event after the cooldown is shown as usual, and a
  still-supported cue may finish its lifetime.

### Coverage labels (this list replaces the one above)

- **JOINED path** (real TempoLektion/HorseService samples → the server's
  push to LocalPlayer → the real `VoltLektionController` → the composed
  `UgnetaController.panel(4)`), SYNCHRONOUS:
  - slow gives a cue;
  - slow → fast within the cooldown: removed at once, nothing new;
  - slow → a gap: removed;
  - the wrong gait: removed;
  - a higher unseen event number in a newer incompatible snapshot: nothing
    shown;
  - removal followed by a recovery before a render: nothing;
  - a duplicate or older snapshot: rejected;
  - a fresh event after the cooldown: shown;
  - a real two-completion pair with a Retry through the client button: the
    comparison text in the host.
- **GENUINELY DEFERRED:** a Start request on the scheduler, with the push of
  the new attempt (and its event) BEFORE the delayed reply. The baseline is
  set by the push, the old reply is rejected, and a later fresh event is
  shown.
- **PRODUCER ONLY:** C1–C5.
- **FABRICATED client snapshots:** C6–C8 (the corrected C6 expects removal
  on `too_fast`).
- **Planned, not written:**
  - pending/timeout/Finish through the joined path (the lifecycle is covered
    in C7 with fabricated snapshots);
  - physical rendering and readability.

