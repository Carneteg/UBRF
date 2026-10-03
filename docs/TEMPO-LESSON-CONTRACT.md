# Steady walk lesson ("jämn fart i skritt")

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [TEMPO_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855511583),
base 49788ea. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

This is ONE exercise in the tempo area: **steady observed speed in walk**.
It does NOT measure hoof rhythm, cadence, stride length, bend or aids, and it
does not complete the tempo/rhythm catalogue area. The existing unknown
`rytm` stays unknown; real hoof-rhythm assessment is unbuilt until a genuine
source exists.

## Player outcome

A fifth choice in the same mounted Ugneta panel, "Walk at a steady pace",
then an explicit Start. The player walks forward anywhere inside the dressage
arena at an even pace, straight or on curves. Ugneta says whether evidence is
still being collected, the pace is too slow or too fast, or it varies too
much, with progress in percent, "Steady walk completed" and explicit Retry and
Finish. No route or marker is drawn. The outcome is session-local only.

## Numbers (gameplay assumptions from the existing walk configuration)

Speeds are metres per second; RidObservation reports studs/s and studs, and
3 studs = 1 m (`BuildKit.M`, `Config.STUDS_PER_METRE`).

| Name | Value | Source |
|---|---|---|
| Speed floor | 0.90 m/s | `Gaits.BY_NAME.walk.min` |
| Speed ceiling | 2.20 m/s | walk → trot threshold in `Gaits` |
| Steadiness | (max − min) / mean of the qualifying run ≤ 0.25 | assumption |
| Fresh samples | ≥ 30 | assumption (~7.5 s at the 0.25 s cadence) |
| Observed duration | ≥ 8.0 s | assumption |
| Distance | ≥ 10.0 m | assumption (~7 s at the walk norm 1.45 m/s) |
| Arena | the dressage layout (`iDressyr`), 20 × 60 m | built layout |
| Deadline | 120 s; timeout ends incomplete, never success | assumption |

10 m at walk fits inside the 60 m layout on a straight line, and any curve
inside the layout also counts.

## Evidence (existing observations at the existing cadence only)

The lesson reads, per HorseService step, RidObservation's own counters and
its newest `fonster` sample, RidPlatsObservation's `iDressyr`, and RidLogg
gait events. It does not use the window's aggregate `tempo`, `medelFart`, old
samples or cumulative totals from before the current baseline.

- **Baseline:** at Start, Retry and every recovery the lesson records
  observation time `tid`, the valid-segment counter, distance and the RidLogg
  position. Only steps AFTER that count.
- **Boundary interval:** the first step after a baseline is never credited,
  because its interval may begin before the baseline.
- **One step, one sample:** a step is credited only if exactly ONE new valid
  segment was observed since the previous step, and the newest window sample
  ends at that step's `tid`. Otherwise the run restarts (unknown). A repeated
  snapshot (unchanged `tid`) is ignored.
- **Speed** is the step's own observed distance divided by its own observed
  time, both deltas after the baseline, converted to m/s. Overlapping rolling
  windows are never summed.
- **Gait:** the accepted gait at the step AND the new sample's gait are walk,
  not reversing, and no gait event happened in the step. A gait event restarts
  the run.
- **Arena:** the horse is inside the layout at the start and end of the step.

## Qualifying run

A run is a sequence of consecutive credited steps. Each new step:

- **below 0.90 m/s** (standing still, jitter, drifting) → the run restarts,
  tip "too slow";
- **above 2.20 m/s** → the run restarts, tip "too fast";
- **spread** (max − min) / mean including this step above 0.25 → the run
  restarts WITH this step as its first sample, tip "steadier" (fresh evidence,
  no endless churn);
- otherwise it is added: samples + 1, observed time + dt, distance + d.

**Complete:** samples ≥ 30 AND observed time ≥ 8 s AND distance ≥ 10 m.
Progress is the smallest of the three ratios.

## Breaks and recovery

Handled BEFORE the time-equality check, exactly as in the other lessons:

- observation breaks (gap, missing root, teleport, invalid dt);
- frame change or loss;
- a ridplats image without a valid position;
- RidLogg overflow (truncated history).

Each of these, as well as halt, reversing, trot or canter, and leaving the
layout, discards the whole run. The lesson takes a new baseline and keeps the
original deadline. Recovery is simply walking steadily again. While nothing
is credited, no further reset or revision churn happens. A stale owner or
ride gives no credit.

## Lifecycle and requests (same rules as the other lessons)

- **Attempt:** FORSOK1 `ovning = jamn_skritt`, definition `server-tempo-1`.
- **Closing:** success closes once with `slutford`; the deadline closes with
  `tidsgrans` and wins at equality; Finish closes with `avbrutet`; ride
  teardown closes through FORSOK1.
- **Requests:** the ride-scoped, type-aware request ledger in HorseService;
  `sync` reads the current lesson; Finish always acts on the current lesson; a
  type switch is refused while an attempt is active; reattachment and late
  replies follow the existing client rules.
- **Retry:** new attempt and new baseline; nothing carries over.
- **Frozen result:** samples, observed seconds, metres, mean and spread of the
  qualifying run, and start. Later riding cannot change it.

## Type extension (explicit)

`typ = "tempo"` is added beside `volt`, `halt`, `overgang` and `serpentin`,
with one line in `lektionModul`. The client adds a fifth choice and shows
progress; there is no guide. The other lessons are unchanged.

## Deferred verification (written, NOT run, by decision)

`roblox/tests/tempolektion.spec.luau` contains these written cases:

- **Completion:**
  - fresh steady walk completes, with frozen samples, time, metres and mean;
  - the frozen result does not change afterwards.
- **Freshness:**
  - steady walking before Start does not count (progress starts from 0, and the
    first step after Start is not credited);
  - repeated `sync` reads of the same snapshot add nothing.
- **Movement:**
  - standing still in walk and tiny jitter give "too slow" and no progress;
  - varying speed gives "steadier" and no completion;
  - too few samples, too short time or too short distance do not complete.
- **Gait and arena:**
  - halt, reversing and trot discard the run;
  - leaving the layout discards the run.
- **Breaks and recovery:**
  - a teleport discards the run, then fresh recovery completes;
  - deadline.
- **Lifecycle and requests:**
  - Retry and Finish;
  - a delayed old tempo start after a type switch opens no attempt;
  - the same sequence with another type is refused;
  - all five lessons start and finish;
  - owner events only to the owner;
  - no persistent writes.

**Planned, not written:** frame change, invalid dt, missing root, a gap, and
RidLogg overflow (the same break code path as start/halt, whose spec has
them); a step with two new segments (unreachable while sampling and the
lesson share the heartbeat; the guard is defensive).

Engine, client layout, SV/EN, touch and the player flow are unverified.
