# Training serpentine lesson (three loops) — game training route

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [SERPENTINE_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855357023),
base e31eb1f. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

This is a **game training route**, NOT an official dressage programme or a
competition serpentine. It covers one exercise of the catalogue area
"volter och serpentiner"; it does not complete that area or "väg".

## Player outcome

A fourth choice in the same mounted Ugneta panel, "Ride a serpentine", then an
explicit Start:

1. **To the start:** ride to the start ring on the centre line near A.
2. **Loop 1, 2, 3:** follow the drawn route: three half-circle loops that
   alternate sides, crossing the centre line between them.
3. **Finish:** arrive in the end ring on the centre line near C.

Ugneta gives one short positive instruction per state, progress in percent,
"Serpentine completed" and explicit Retry and Finish. The route is drawn as
local non-colliding dashes. The next portion (the start ring, the current
loop, or the end ring) is drawn solid; the rest is faint. The outcome is
session-local only. The lesson claims an **ordered traversal of the drawn
route within the corridor**. It does NOT claim bend, rhythm, even loop size or
correct aids.

## Geometry (from the resolved layout, not invented letters)

All in the existing Ridhusplats frame, metres: `u` across, `v` from A towards
C. The built layout is 20 × 60 m (`site.js` `dressyr` w 20, h 60). The centre
line is `u0 = dressyrMitt.u`.

| Name | Value |
|---|---|
| Direction | A → C (increasing `v`) only |
| Loop radius `R` | 8 m (half-circles) |
| Crossings on the centre line | `v` = 6 (start), 22, 38, 54 (end) |
| Loop k centre | (`u0`, 14 / 30 / 46) |
| Loop sides | loop 1 towards +u, loop 2 towards −u, loop 3 towards +u |
| Route length | 3 · π · R ≈ 75.4 m |
| Corridor | ≤ 2.5 m from the route curve |
| Start / end ring | within 3 m of (`u0`, 6) / (`u0`, 54) |

A loop point at parameter θ ∈ [0, π] is
`u = u0 + side · R · sin θ`, `v = centre − R · cos θ`; the route position is
`S = (k − 1) · π · R + θ · R`.

**Fit check at Start:** the resolved layout must fit the route with margin:
half-width ≥ R + 1 and length ≥ 54 + 3. Otherwise Start is refused with
`place`. The route never leaves the layout (widest point `u0 ± 8` in a 20 m
layout).

## Numbers (gameplay assumptions, not measured riding facts)

| Name | Value |
|---|---|
| Corridor half-width | 2.5 m |
| Sample spacing inside a segment | ≤ 0.5 m |
| Coarse segment | > 4.0 m in one observation step: unknown |
| Ambiguous projection | candidate positions from different loops differ by > 3.0 m: unknown |
| Continuity | consecutive samples may move ≤ 1.6 × distance + 0.3 m along the route |
| Reverse | a sample more than 1.5 m behind the furthest reached position: reverse |
| Crossing slack | progress past a crossing is capped at +1.0 m until it is confirmed |
| Deadline | 240 s; timeout ends incomplete, never success |

## Evidence

- **Source:** only existing server observations at the existing cadence:
  RidPlatsObservation `segment` (both endpoints, same frame), RidObservation
  break counters, RidLogg gait events after Start, and the accepted gait from
  HorseService. No new sampling, no circle evaluator, no radial metrics.
- **Segment interpretation:** each valid segment is sampled at ≤ 0.5 m along
  its straight chord, including both endpoints. EVERY sample must lie in the
  corridor. A step that is not a valid `segment` gives no credit.
- **Projection:** each sample is projected onto each loop. A sample on the
  wrong side of a loop projects to that loop's nearest end. Candidates within
  the corridor are kept. Candidates from different loops that disagree by
  more than 3 m are ambiguous, so the step is unknown. The route position is
  the nearest candidate.
- **Progress:** the furthest reached position (`frontier`) only grows by
  continuous forward motion. A jump between samples (continuity broken) is
  unknown, never progress.
- **Ordered crossings:** crossing k (between loop k and k + 1) is confirmed only
  when two consecutive samples lie on opposite sides of the centre line (or on
  it), both within 3.5 m of the crossing point. Until then progress is capped
  at the crossing + 1 m. Crossings are recorded in order.
- **Gait:** walk or trot. Halt, or a step without movement, gives no credit and
  no reset. Canter or gallop, reversing, or a gait event into them resets with
  `walk_or_trot`.
- **Completion:** all three loops reached (`frontier ≥ length − 0.5 m`), both
  inner crossings confirmed, and the current sample inside the end ring.

**Cannot complete:** shortcuts across loops, reverse traversal, looping at one
marker, skipped or out-of-order crossings, only visiting the end ring,
standing still, and pre-Start motion. Each of these either leaves the
corridor, breaks continuity, fails the crossing check or adds no frontier.

## R1: the exact centre line (source review #5855468769)

- **Angle:** on the correct side of a loop, the semicircle angle is `atan2(|du|, −dv)`
  clamped to [0, π]. Using `side · du` gave −0 for loop 2 at the literal crossing
  (u0, 38), and atan2(−0, negative) may return −π; the valid crossing would then have
  projected to 0 and been rejected as ambiguous. Corridor, ambiguity, continuity and
  crossing checks are unchanged.
- **Endpoints:** the first and last sample of a segment are the observed endpoints
  exactly, not `from + (to − from) · 1` rounded.
- **Honest limit:** the lesson reads positions through the world ↔ frame conversion, so
  a literal zero `du` in the running game depends on that rounding. The direct
  projection cases pin the literal boundary; the consumer traversal lands on the
  crossings as exactly as the frame allows.

## Recovery and breaks

- **Leaving the corridor, reversing, a non-allowed gait, an unknown or
  ambiguous step, or a coarse segment** returns the attempt to "to the start":
  all loop credit and crossings are cleared, and the deadline is kept. The
  player rides back into the start ring to begin fresh. While in "to the
  start" nothing more resets, so there is no restart churn; the recovery tip
  stays until the player enters the route again.
- **Observation breaks** (gap, missing root, teleport, invalid dt), a frame
  change or loss, a ridplats image without a valid position, stale owner or
  ride, and RidLogg overflow (truncated history) do the same. The checks run
  BEFORE the observation-time equality, as in start/halt R1. The recovery
  takes new baselines and never joins evidence across the break.

## Lifecycle and requests (same rules as the other lessons)

- **Attempt:** FORSOK1 `ovning = serpentin`, definition `server-serpentin-1`.
- **Closing:** success closes once with `slutford`; the deadline closes with
  `tidsgrans` and wins at equality; Finish closes with `avbrutet`; ride
  teardown closes through FORSOK1.
- **Requests:** the ride-scoped, type-aware request ledger in HorseService;
  `sync` reads the current lesson; Finish always acts on the current lesson;
  a type switch is refused while an attempt is active; reattachment and late
  replies follow the existing client generation rules.
- **Retry:** new attempt, all evidence cleared.
- **Frozen result:** route id, reached length, crossing points in order and
  the start time. Later riding cannot change it.

## Type extension (explicit)

`typ = "serpentin"` is added beside `volt`, `halt` and `overgang`, with one
line in `lektionModul`. The client adds a fourth choice and a route guide
that redraws only when the frame, the lesson type or the next portion
changes. The other lessons' behaviour, keys and replies are unchanged.

## Deferred verification (written, NOT run, by decision)

`roblox/tests/serpentinlektion.spec.luau` contains these written cases:

- complete traversal A → C with frozen result and two ordered crossings;
- Retry opens a fresh attempt;
- visiting only the end ring does not complete;
- a shortcut straight along the centre line leaves the corridor;
- reverse traversal (from the end towards the start) makes no progress;
- going back along the route resets;
- circling at the start marker gives no progress beyond the start;
- standing still gives no progress;
- a coarse segment (teleport-free long step) is unknown;
- teleport mid-route: reset, then fresh recovery completes;
- canter resets;
- deadline;
- a delayed old serpentine start after a type switch opens no attempt;
- the same sequence with another type is refused;
- R1: literal crossings (u0, 22) and (u0, 38), the start and end points, ±1e-9 around
  (u0, 38), the widest loop points and the centre line between crossings project as
  intended (through a test hook on the real projection);
- R1: a traversal whose loops end exactly on the centre-line crossings keeps the route
  and completes;
- all four lessons start and finish;
- owner events only to the owner; no persistent writes.

**Planned, not written:** frame change mid-route, invalid dt, missing root and
a gap (the same break code path as start/halt, whose spec has them), an
ambiguous projection (no point of this geometry is within the corridor of two
disagreeing loops, so the guard is defensive and only reachable with other
parameters), and skipping a crossing by a sampled path that stays inside the
corridor (the geometry makes this unreachable; the cap is defensive).

Engine, client rendering, SV/EN layout, touch and the player flow are
unverified.
