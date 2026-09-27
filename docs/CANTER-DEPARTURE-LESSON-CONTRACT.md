# Canter departure at a training target (partial "galoppfattning")

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [CANTER_DEPARTURE_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855857360),
base 8c500cf. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

This is a **PARTIAL** implementation of the catalogue area "galoppfattning": a
deliberate, player-requested **trot → canter transition at a training target**,
followed by observed canter. It does NOT recognise the left or right lead and
does not judge the quality of the departure. It also claims nothing about hoof
rhythm, stride or balance. **Lead recognition remains an explicit, unbuilt
dependency**; no source for it exists yet.

## Existing semantics used (inspected in source)

- **Ridtrappa:** `driv` steps trot → canter up to the ceiling. The ceiling is
  `min(stamina ceiling, Gaits.SPELBAR_TOPP = "canter")`. A tired horse may not
  get canter; the request is then simply not accepted.
- **Logging of transitions:** HorseService logs a transition only when it is
  accepted, through `loggaSteg`:
  - `orsak = "hjalp"` for an accepted rider intent (`onRidingIntent`);
  - `"trotthet"` when the stamina ceiling pulls the gait down;
  - `"stopp"` when the horse is stopped.
- **The event:** it carries `fran`, `till`, `franRyggar` and `tillRyggar`. RidLogg
  stores it as `{ n, t, typ, data }`, where `t` is **seconds since mounting in the
  log's own clock** (`nu − _start`, clamped so it never decreases). `_start` is not
  exposed in the snapshot. `t` is therefore NOT comparable with the lesson's
  `now`, and this lesson never compares them. An earlier draft of this contract
  assumed a shared clock; inspecting the producer corrected that.
- **Observations:** RidObservation and RidPlatsObservation as in the other
  lessons, sampled in the same heartbeat as the lesson step.

## Player outcome

1. Choose Ugneta → "Gaits and pace" → "Transitions" → "Canter departure".
2. Press Start.
3. Trot at least 8 m.
4. Ask for canter inside the green ring **K**.
5. Canter on at least 6 m.

Ugneta gives one positive, useful instruction per state, progress in percent,
"Canter departure completed", and Retry and Finish. **K** is an original training
label, not an arena letter. It is drawn as one non-colliding ring whose radius
equals the server zone. The result is session-local.

## Geometry and numbers (unmeasured gameplay assumptions)

| Name | Value |
|---|---|
| Target K | centre (u0, 30) on the centre line of the resolved frame; zone = distance ≤ 3.0 m (a circle, same as the drawn ring) |
| Fresh trot preparation | ≥ 8.0 m observed in accepted trot after Start or the last reset |
| Post-departure canter | ≥ 6.0 m observed in accepted canter after the departure step |
| Event timing | bound by log ORDER: the event was appended after the previous processed step and is first seen in this step; the step must contain exactly one new valid observed segment (the RidObservation `segment` counter rises by 1) |
| Deadline | 150 s; timeout ends incomplete, never success |
| Fit at Start | layout length ≥ 36 m and half-width ≥ 4 m, otherwise `place` |

## Evidence

The lesson has three phases.

1. **`trot` (preparation):** observed planar distance while the accepted gait is
   trot, not reversing, with both step endpoints in the layout.
   - A transition out of trot (to walk or halt) resets the preparation, with the
     tip `trot_on`.
   - Canter, walk and halt give no preparation credit.
   - Being already in canter at Start never counts.
2. **Departure:** an event first seen in this step, `fran = "trot"`,
   `till = "canter"`, `orsak = "hjalp"`, neither side reversing, and its `t`
   within the timing window. Its position is the step's observed interval:
   - it must be a valid ridplats **segment** with **both** endpoints within 3 m
     of K;
   - it must have preparation ≥ 8 m;
   - if all holds, the attempt moves to `canter` (`vidK` is recorded);
   - with too little preparation the tip is `trot_first`;
   - outside the zone the tip is `canter_outside`;
   - either way the preparation resets and the attempt stays in `trot`;
   - an unknown interval (no valid, observed segment, or not exactly one new
     segment in the step) gives `unknown` and a reset;
   - a canter reached any other way (not `hjalp`, or not from trot) is never a
     departure.
3. **`canter` (post-departure):** observed distance while the accepted gait is
   canter, from steps AFTER the departure step.
   - Any transition event before completion resets to `trot` with a fresh
     preparation: fatigue gives `tired`, and other events give `canter_longer`.
   - A stationary accepted canter adds nothing.
   - **Complete** when the canter reaches 6 m.

- **Step with events:** a step with any gait event credits NO distance to any
  phase, so an interval that straddles a transition is never counted.
- **Physical vs credited:** only credited movement counts; there is no banked
  or uncredited distance.

## Breaks and recovery

The following reset to `trot` with a new baseline and the SAME deadline:
- observation breaks (gap, missing root, teleport, invalid dt);
- frame change or loss;
- an invalid ridplats image;
- RidLogg overflow;
- stale owner, ride or horse identity.

The break checks run BEFORE the time-equality check. There is no reset churn
while nothing is credited. Recovery means trotting fresh again.

## Lifecycle and requests

- **Attempt:** FORSOK1 `ovning = galoppfattning`, definition `server-galopp-1`.
- **Type:** `typ = "galopp"` in the ride-scoped, type-aware request ledger. Late
  requests and the same sequence with another type are refused; a switch is
  refused while an attempt is active; Finish acts on the current lesson.
- **Closing:** success closes once with `slutford`; the deadline closes with
  `tidsgrans` and wins at equality; Finish closes with `avbrutet`; ride
  teardown closes through FORSOK1.
- **Frozen result:** attempt, ride, horse and user identity, `vidK` (the
  departure interval's end point), trot metres, canter metres and start.

## Menu (four-row consumer)

"Gaits and pace" becomes:
- start/halt;
- steady walk;
- **"Transitions"**, a subgroup containing walk–trot transitions, the canter
  departure and Back (to "Gaits and pace");
- Back (to the top level).

The other pages are unchanged, including the compact entry beside 2..3 legacy
cards and "lessons" when free riding.

## Deferred verification (written, NOT run, by decision)

`roblox/tests/galopplektion.spec.luau` contains these written cases.

**Full sequence:**
- trot 8 m or more, canter asked inside K, then canter 6 m or more;
- the result is frozen, carries the evidence summary and does not change
  afterwards.

**Freshness and events:**
- already cantering at Start, plus an old event before Start, never succeed;
- canter asked outside K gives `canter_outside` and a fresh trot is needed;
- canter asked after too little trot gives `trot_first`;
- an event without valid position evidence (a canter request in a step whose
  observation breaks with a gap) is never a departure; the break resets it;
- a fatigue-forced canter → trot gives `tired`;
- an injected canter event with `orsak = "trotthet"` is never a departure.

**Movement and breaks:**
- a stationary accepted canter after a valid departure stays incomplete;
- the departure step's own interval adds neither trot nor canter metres;
- a teleport, then fresh recovery completes.

**Lifecycle and requests:**
- deadline;
- Retry;
- a delayed old start of another type;
- the same sequence with another type;
- all nine lesson types start and finish;
- owner events only to the owner;
- no persistent writes.

**Menu:** the ninth lesson and all old leaves are selectable within four rows
beside 0..3 cards.

**Planned, not written:**
- frame change, invalid dt, missing root, a gap and RidLogg overflow, which use
  the same break code path as start/halt;
- rendered layout, touch and SV/EN;
- whether the real stamina ceiling allows canter in normal play.

Engine, animation, control feel and the player flow are unverified.
