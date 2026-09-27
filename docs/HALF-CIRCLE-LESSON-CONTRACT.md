# Half-circle back to the track (game training route)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [HALF_CIRCLE_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855708420),
base b6dbbad. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

This is an **original game training route**, NOT an official dressage programme, with
no invented letters. It is one more figure in the catalogue area "volter och
serpentiner"; the area is not complete. The lesson claims an **ordered traversal
of the drawn route within its corridor**. It never claims bend, balance, rhythm or
canter lead.

## Player outcome

The player reaches the lesson through Ugneta → "Riding paths" → "Half-circle",
then presses Start. The rider then:

1. rides into the start ring on the track (the long side, towards C);
2. follows the track a short way;
3. turns off in a 10 m half-circle towards the middle;
4. rides the return line back to the track;
5. ends in the end ring, now travelling towards A.

Ugneta gives one short positive instruction per part, progress in percent,
"Half-circle completed", and Retry and Finish. The route is drawn locally
without collision: dashes with direction chevrons, plus distinct start and end
rings. The next part is solid and the rest faint. The result is session-local
only and records the figure `halvvolt`.

## Geometry (resolved layout frame, metres; `u0 = dressyrMitt.u`, `v` from A)

The track is the line `uT = u0 + 8.5`, which is 1.5 m inside the +u long side
of the 20 m layout.

| Part | From → to | Length |
|---|---|---|
| 1 track (towards C) | P0 (uT, 16) → T1 (uT, 26) | 10 m |
| 2 half-circle | T1 → H (uT − 10, 26), centre (uT − 5, 26), R = 5, through (uT − 5, 31) | 5π ≈ 15.71 m |
| 3 return line (towards A) | H → E (uT, 8) | √424 ≈ 20.59 m |

- **Total length:** L ≈ 46.30 m.
- **Route position S:**
  - part 1: `S = s1`;
  - part 2: `S = 10 + 5·θ`;
  - part 3: `S = 10 + 5π + s3`.
- **Arc angle:** `θ = clamp(atan2(|dv|, du), 0, π)`, where (du, dv) is the point
  relative to the centre.
  - This is the upper-half branch, `dv ≥ 0`, which includes a signed zero.
  - The magnitude `|dv|` makes the literal join H give +π and never −π, the
    same rule as the serpentine R1.
  - A point below the diameter (`dv < 0`) projects to the nearer arc end, T1 or
    H.
- **Straight parts:** projections are clamped to the part's own range.
  - Part 1 allows `s1 ∈ [−2, 10]`, so that rear-half arming exists.
  - Part 3 allows `s3 ∈ [0, L3]`.
- **Fit at Start:** half-width ≥ 10 and length ≥ 33. Otherwise Start is refused
  with `place`. The built 20 × 60 layout fits it; the widest point is the track
  at uT + 1.5 = the long side.
- **Separation:** the return line stays ≥ 2.9 m from part 1 and from the start
  ring. The parts touch only at T1 and H, where their route positions agree.

## Numbers (unmeasured gameplay assumptions)

| Name | Value |
|---|---|
| Corridor half-width | 1.5 m |
| Start ring / end ring | 2.0 m around P0 / E |
| Sample spacing | ≤ 0.5 m along each segment's chord |
| Coarse segment | > 4.0 m in one step: unknown |
| Ambiguous projection | candidates from different parts > 3.0 m apart: unknown |
| Continuity | consecutive samples may move ≤ 1.6 × distance + 0.3 m along the route |
| Backwards | a sample more than 1.0 m behind the furthest point: reverse |
| Joins | progress past T1 or H is capped at the join + 1 m until a sample within 1.5 m of that join is seen |
| Completion | furthest point ≥ L − 0.5 AND the step ends in the end ring |
| Deadline | 150 s; timeout ends incomplete, never success |

## Evidence (non-convex arc)

The lesson uses only RidPlatsObservation segments (both endpoints, same frame),
RidObservation break counters, RidLogg gait events after Start, and the accepted
gait.

- **Arc part:** the arc is not convex, so endpoints alone prove nothing. EVERY
  segment is sampled every ≤ 0.5 m along its chord, including both observed
  endpoints exactly. Every sample must lie within 1.5 m of the route and project
  unambiguously and continuously. A chord shortcut across the half-circle
  leaves the corridor (its middle is 5 m from the arc); cutting the return line
  also leaves it.
- **Arming:** in `to_start` the lesson arms when a fresh valid segment ends in the
  start ring, projects to part 1 with `−2 ≤ S ≤ 2`, is in the layout, is in walk,
  trot or halt, and is not reversing.
  - The arming step gives NO credit.
  - `armS` (the observed S) and `framst` (the physical furthest S, the reference
    for backwards detection) both start at the arming point, and `kreditM`
    starts at 0 (R2, see below).
  - Progress is `(max(framst, 0) − max(armS, 0)) / (L − max(armS, 0))`.
  - A stationary first step, the approach and a rear-half arming therefore
    neither credit nor reverse.
- **Riding:** each step needs:
  - a valid segment beginning exactly where the previous one ended;
  - length ≤ 4 m;
  - all samples in the corridor and the layout;
  - an unambiguous and continuous projection.

  Only forward movement in walk or trot adds credit (`kreditM`). Halt is an allowed
  pause: no credit and no reset. Reversing, canter or a gait event into them
  resets with `walk_or_trot`.
- **Ordered joins:** the joins are recorded in order. A join counts only when a
  sample within 1.5 m of it is observed.
- **Cannot complete:**
  - touching waypoints or only the end ring;
  - the half-circle chord;
  - riding the figure backwards or out of order (backwards resets; the start
    ring alone arms);
  - standing still, jitter;
  - distance ridden elsewhere.

## R1/R2: halt cannot be banked (source reviews #5855779841, #5855815820)

- **Halt anchor (R1):** during an accepted halt (no credit) the position where the
  halt began is anchored. Movement within **0.5 m** of the anchor is tolerated for
  any length of time; more returns the attempt to the start ring with
  `halt_moved`. The anchor is released by the next credited step.
- **Two separate quantities (R2).** R1's single `langst` mixed position and
  credit; it is replaced by:
  - `framst`: the PHYSICAL furthest route position reached (absolute S, any
    accepted gait). Backwards detection, the join cap and completion
    (`framst ≥ L − 0.5` in the end ring with both joins) use it.
  - `kreditM`: the credited metres. It grows only when `framst` is pushed
    forward by a credited (walk/trot) sample, by exactly that push.
  - `skuld = framst − armS − kreditM`: forward ground covered without credit.
    It can never be credited later, because walking back and forward below
    `framst` pushes nothing. **Rule:** if `skuld` exceeds 0.5 m, the attempt
    returns to the start ring with `halt_moved`, which is clearly recoverable
    with fresh evidence and the same deadline.
- **Consequences:**
  - One tolerated pause never locks the attempt: completion needs only the
    physical `framst`.
  - Repeated pauses that add up to more than 0.5 m re-arm.
  - Nothing moved during halt is ever reclaimed.
- **Joins:** a join counts only from a credited sample.
- **Result:** the result names both quantities: `slutS` (physical end position),
  `meter` (= `kreditM`) and `skuld`. Progress display follows the physical reach.
- **Correction:** R1's report claimed the tolerated drift was "never credited"
  while its incremental formula could reclaim it by a small out-and-back, and
  that a rider could "ride slightly further" to finish (false, because the
  projection clamps at L). Both claims are withdrawn; R2 is the implemented
  model.
- **Unchanged:** rear/front arming, reverse, chord/corridor/order, identity,
  break recovery and deadline.

## Recovery and breaks

The following return the attempt to `to_start`, with all route credit and joins
cleared and the deadline kept:
- leaving the corridor or the layout (`off_route`);
- backwards travel (`reverse`);
- a wrong gait (`walk_or_trot`);
- an unknown, ambiguous, coarse or discontinuous segment (`unknown`);
- observation breaks (gap, missing root, teleport, invalid dt), frame change or
  loss, an invalid ridplats image, and RidLogg overflow.

The break checks run BEFORE the time equality. While in `to_start` nothing more
resets.

## Lifecycle and requests

- **Attempt:** FORSOK1 `ovning = halvvolt`, definition `server-halvvolt-1`.
- **Type:** `typ = "halvvolt"` in the ride-scoped, type-aware request ledger. The
  old figures' requests stay isolated, switching is refused while an attempt is
  active, and Finish acts on the current lesson.
- **Closing:** success closes once with `slutford`; the deadline closes with
  `tidsgrans` and wins at equality; Finish closes with `avbrutet`; ride
  teardown closes through FORSOK1.
- **Frozen result:** `figur = "halvvolt"`, `armS`, `slutS` (physical end position),
  `meter` (credited metres), `skuld` (`slutS − armS − meter`),
  the joins and the start.

## Menu (capacity-aware, four rows)

The "Riding paths" group was full (three leaves plus Back). It becomes:
- serpentine;
- half-circle;
- "Centre line and diagonal", a subgroup containing the centre line, the
  diagonal and Back (to Riding paths);
- Back (to the top level).

Every composed page still fits four rows, beside 0..3 legacy cards through the
existing compact entry, and with free riding.

## Deferred verification (written, NOT run, by decision)

`roblox/tests/halvvoltlektion.spec.luau` contains these written cases.

**Full route and arming:**
- the full figure through the literal joins T1 and H and the literal end E, with
  a frozen result (figure, armS, slutS, meter, joins) that later riding cannot
  change;
- rear-half arming at s = −1.9 with a halt, then small forward steps;
- standing still right after arming gives no progress.

**Projection boundaries** (through a test hook on the real projection):
- T1 → 10 and H → 10 + 5π, both unambiguous;
- the arc top → 10 + 2.5π;
- the chord middle is outside;
- a point just below the diameter projects to an arc end;
- ±1e-9 around H.

**Wrong routes:**
- the chord shortcut T1 → H resets;
- visiting only the end ring does not complete;
- riding the figure backwards from E gives no progress;
- going back along the arc resets;
- standing still.

**R1, halt accounting:**
- a stationary halt, then fresh walk, completes;
- movement through the join T1 during halt returns to the start with
  `halt_moved`;
- a full halted traversal, then a stationary walk sample and the next moving
  sample, never completes;
- a credited part, 0.4 m of tolerated halt drift, then a stationary walk
  sample: `kreditM` is unchanged; completion reports `slutS ≥ L − 0.5`,
  `skuld ≈ 0.4` and `meter = slutS − armS − skuld`; moving on past E inside the
  end ring cannot change the result;
- R2: two separate tolerated pauses (0.4 + 0.2 m) exceed 0.5 m of debt and return
  to the start ring (`halt_moved`), and the route then recovers and completes;
- R2: walking back and forward over the paused 0.4 m credits nothing, new ground
  beyond `framst` is credited, and that attempt completes with its debt
  reported;
- bounded ±0.1 m jitter keeps the route and progress, and the figure then
  completes.

**Gait and breaks:**
- halt is a pause;
- canter resets;
- a coarse segment;
- a teleport, then fresh recovery completes.

**Lifecycle and requests:**
- deadline;
- Retry;
- switching to a riding-path figure while active is refused;
- a delayed old start of another figure;
- the same sequence with another type;
- all eight lesson types start and finish;
- owner events go only to the owner;
- no persistent writes.

**Menu composition beside 0..3 cards:** the half-circle and every old leaf,
including those in the new subgroup, are selectable within four rows.

**Planned, not written:**
- frame change, invalid dt, missing root, a gap and RidLogg overflow, which use
  the same break code path as start/halt;
- rendered layout, touch and SV/EN;
- pending requests while the menu is open.

Engine, rendering and the player flow are unverified.
