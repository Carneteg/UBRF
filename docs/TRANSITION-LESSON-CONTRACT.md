# Transition lesson (`skritt_trav` + `trav_skritt`) at marked targets

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [TRANSITIONS_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855283148),
base b6177ce. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

## Player outcome

A third choice in the same mounted Ugneta panel, "Practice transitions", then an explicit Start:

1. **Walk:** walk actively.
2. **Trot at T1:** ask for trot inside training target T1.
3. **Trot:** trot on.
4. **Walk at T2:** ask for walk inside training target T2.
5. **Walk:** walk on calmly.

Ugneta gives one short useful instruction per state, progress in percent, "Transitions completed" and explicit Retry and Finish. Two non-colliding local rings mark T1 and T2. The outcome is session-local only. The lesson claims transitions at the intended places, NOT soft, collected or rhythmic transitions or correct aids.

## Targets (training targets, NOT official dressage letters)

The built arena has no letter markers, so no letter is invented. Both targets are on the dressage centre line (`dressyrMitt.u`) of the existing Ridhusplats frame. `v` is metres from A.

| Target | Centre | Zone |
|---|---|---|
| T1 | u = centre line, v = 18 m | `|u − centre| ≤ 3 m` and `|v − 18| ≤ 3 m` |
| T2 | u = centre line, v = 42 m | `|u − centre| ≤ 3 m` and `|v − 42| ≤ 3 m` |

Both zones lie well inside the 20 × 60 m layout. Either travel direction is allowed; the ORDER (T1 before T2) is what counts.

## Numbers (gameplay assumptions, not measured riding or competition facts)

| Name | Value |
|---|---|
| Initial fresh walk | ≥ 3.0 m observed in walk after Start |
| Trot | ≥ 6.0 m observed in trot after the trot transition, before the walk transition |
| Final fresh walk | ≥ 2.0 m observed in walk after the walk transition |
| Deadline | 180 s (longer route than start/halt); timeout ends incomplete, never success |

## Evidence and freshness

The evidence comes only from existing server observations: RidLogg `gangart` events after Start, RidObservation distance and time, and RidPlatsObservation segments and frame.

- **A transition counts** only if all of these hold:
  - it is accepted with `orsak = hjalp` (the player's aid);
  - the direction is right: walk → trot for T1, trot → walk for T2;
  - it is first seen in the lesson step whose observation is a valid ridplats **segment**;
  - **BOTH** endpoints of that segment (the observed interval that contains the event) are inside the target zone.
- **Conservative handling:**
  - if that interval is not a valid segment, the result is "unknown" and the evidence resets;
  - if only one endpoint is in the zone, it counts as outside;
  - no old last-known point and no later position is used.
- **Movement:** observed planar distance only when the step was observed and the accepted gait is the phase's gait (walk or trot, never canter or reversing). A gait label alone, standing still, pre-Start totals or timers never count.
- **Fatigue:** a fatigue-forced change (`trotthet`) is never the requested walk. A forced drop out of trot, canter, reversing or a transition in the wrong direction resets to the first phase with a useful tip.
- **Wrong place:** a transition at the wrong target or outside a target (early or late) gives recovery. The attempt returns to "walk", and the next sequence needs fresh walking again. It is never success.
- **Breaks:** observation breaks (gap, missing root, teleport, invalid dt), frame change or loss, a ridplats image without a valid position, and RidLogg overflow all reset to the first phase. The reset takes new baselines and keeps the same deadline, and no evidence is joined across the break. The checks run before the time-equality check, exactly as in the start/halt lesson.

## Lifecycle and requests (same rules as the other lessons)

- **Attempt:** FORSOK1 `ovning = overgangar`, definition `server-overgang-1`.
- **Closing:** success closes once with `slutford`; the deadline closes with `tidsgrans` and wins at equality; Finish closes with `avbrutet`; ride teardown closes through FORSOK1.
- **Requests:**
  - the ride-scoped, type-aware request ledger in HorseService applies;
  - `sync` reads the current lesson;
  - Finish always acts on the current lesson;
  - a type switch is refused while an attempt is active.
- **Retry:** fresh baselines.
- **Frozen result:** transition positions, trot and walk metres. Later riding cannot change it.

## Type extension (explicit)

`typ = "overgang"` is added beside `volt` (default) and `halt`, with one module lookup in HorseService. The client adds a third choice and ring guides for the two targets. Circle and start/halt behaviour, keys and replies are unchanged.

## Deferred verification (written, NOT run, by decision)

`roblox/tests/overganglektion.spec.luau` contains these written cases.

**Main path and order:**
- happy path T1 → T2;
- trot requested before T1 (early/outside);
- walk requested outside T2;
- walk requested at T1 instead of T2 (wrong target and order).

**Movement:**
- gait only without movement (standing still in walk);
- trot distance under 6 m before T2.

**Breaks and injected cases:**
- fatigue-forced walk (unit-boundary injection);
- teleport between T1 and T2 with fresh recovery.

**Lifecycle:**
- deadline;
- ride-scoped sequence across a type switch;
- Retry and Finish;
- circle and start/halt still start.

**Planned, not written:** a frame change mid-lesson and invalid dt. The same break code path as start/halt is used; those cases are written there.

Engine, client rendering, SV/EN layout and the player flow are unverified.
