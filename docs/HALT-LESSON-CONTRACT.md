# Start/Halt lesson (`halt_skritt`)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [START_HALT_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855148032),
base cbd6499, under Tobias' build-now/test-last decision
[5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

## Player outcome

From the same mounted Ugneta panel as the circle lesson the player explicitly
chooses "Practice start and halt" (the existing exercise id `halt_skritt`),
then Start. Tasks, in order:

1. **Halt:** stand still in halt.
2. **Walk on:** ask for walk (a player aid), then really walk.
3. **Halt at X:** walk to the marked zone at X and halt there, still.

Ugneta gives one short useful instruction per state, progress in percent,
"Halt completed" at the end and explicit Retry and Finish. A non-colliding
local ring marks X. The outcome is session-local only. It claims a halt at the
intended place, NOT a square or biomechanically correct halt.

## Target and numbers (gameplay assumptions, not measured riding facts)

| Name | Value | Meaning |
|---|---|---|
| Target | X | Dressage-layout centre `dressyrMitt` in the Ridhusplats frame (u, v in metres). |
| `ZON_R` | 1.5 m | Horse root within 1.5 m of X counts as "at X". |
| `STILLA_M` | 0.15 m | Largest observed planar motion per observation step (0.25 s) that still counts as still. |
| `HALT_FORE` | 1.0 s | Initial fresh still halt before walking on. |
| `SKRITT_M` | 4.0 m | Minimum fresh observed walking distance after the requested walk. |
| `HALT_EFTER` | 2.0 s | Still halt inside the zone that completes the task. |
| Deadline | 120 s | Deadline; timeout ends incomplete, never success. |

## Evidence (existing server observations only, no new sampling)

- **Accepted gait and reversing:** `Ridtrappa.gangart`/`ryggar` for the session, passed in by HorseService.
- **Transitions:** RidLogg `gangart` events after Start (`orsak`, `till`, `tillRyggar`).
  - A walk counts only after an accepted transition into walk with `orsak = hjalp`, so a fatigue drop (`trotthet`) does not count.
  - The final halt must be an accepted transition into halt with `orsak = hjalp`.
  - Trot, canter or reversing clears the walk evidence.
  - RidLogg overflow makes the attempt unknown: no success, Retry offered.
- **Motion:** RidObservation cumulative observed distance and observed time.
  - A step without observation (gap, missing root, teleport, invalid dt) is neither still nor walking, and resets the attempt to the first task (see R1 below).
- **Position:** RidPlatsObservation point and frame id.
  - The frame is pinned at Start.
  - A frame change resets to the first task with the new frame (recovery without Retry). Points are never joined across frames.
- **Pre-start motion and events** are excluded by baselines taken at Start.

## Lifecycle (same rules as the circle lesson)

- **Attempt:** FORSOK1 with `ovning = starthalt`, definition `server-halt-1`.
- **Closing:**
  - success closes once with `slutford`;
  - the deadline closes with `tidsgrans` and wins at equality;
  - Finish closes an active attempt with `avbrutet`;
  - dismount, death, leave and teardown close through FORSOK1.
- **Denied dismount** keeps the attempt.
- **Owner-only events** follow the Aktor rule.
- **Requests:** duplicate and stale requests use the same bounded scheme as the circle lesson.
- **One lesson per ride:** changing lesson type is refused while an attempt is active.
- **Retry:** new attempt, new baselines, no old result.
- **Frozen result:** later riding cannot change it.

## Type extension (explicit)

- HorseService keeps one lesson state per ride; `typ` is `volt` (default, unchanged) or `halt`.
- The request handler takes an optional 5th argument `typ`.
- The client adds a second choice and passes `typ`.
- Circle behaviour, keys and replies are unchanged when `typ` is absent.
- **R1, ride-scoped requests:** one request ledger per ride, shared by both lesson types, is validated BEFORE any lesson state changes.
  - Sequences are monotonic over the ride.
  - A duplicate replays its answer only if both operation and type match; otherwise it is refused.
  - An older unknown sequence is stale.
  - A type switch therefore cannot let a delayed old start open an attempt, and an invalid or stale request never replaces the current lesson or its frozen result.
  - `sync` reads the current lesson without changing it; Finish always acts on the current lesson.

## R1: observation breaks (evidence rule)

- **Break signal:** RidObservation's break counters (gap, missing root, teleport, invalid dt), a changed or missing frame, and a ridplats image without a valid position are all checked BEFORE the observation-time equality. An invalid dt increments its counter without moving `tid`.
- **Reset:** any such break returns the attempt to the first task with new baselines and the SAME deadline. Walking or halt evidence from before the break can never be combined with evidence after it.
- **Recovery:** needs fresh evidence in order (halt, requested walk ≥ 4 m, requested halt at X).

## Deferred verification (written, NOT run, by decision)

`roblox/tests/haltlektion.spec.luau` contains exactly these written cases.

**Base cases:**
- happy path at X, with the frozen result unchanged by later riding;
- Retry opens a fresh attempt;
- a halt outside X that recovers without Retry;
- standing still throughout;
- trot is not walk, and trot distance is not evidence;
- a gap is never stillness;
- the deadline;
- a lesson switch refused while active;
- Finish;
- the circle lesson still starts;
- owner events addressed only to the owner;
- no persistent writes.

**R1 cases:**
- 4 m of walking before a teleport into X, then fresh recovery;
- walking split around a gap;
- a missing root;
- invalid dt with unchanged observation time (module-contract injection);
- a fatigue-only walk (unit-boundary injection into RidLogg and the accepted gait);
- a frame change;
- the delayed old halt start after halt → volt;
- the same sequence and operation with another type;
- an invalid sequence on a type switch;
- ordinary volt → halt → volt selection with Finish.

**Not covered by this spec:** a client-less actor (the circle spec has that case for the shared owner-event path).

Engine, client rendering, SV/EN layout and the player flow are unverified.
