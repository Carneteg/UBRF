# Canter departure: event-bound advice when the canter misses K (C1)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code (ACK
[#5864041242](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864041242)).
Order: [CHATGPT_REVIEW_C1_TRANSITION_TIMING_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5864024315),
base `9cd4c38`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

This follows exactly the rule of `TRANSITION-TIMING-ADVICE-CONTRACT.md`,
applied to `GaloppLektion`.

## Failure state and evidence

`canter_outside` means a player-requested trot → canter after ≥ 8 m of trot,
where `iK` is false. `iK` tests both end points of the observed segment in which
the canter first appears against K: a circle with `ZON_R` = 3 m at
`(ref.u, K_V = 30)`.

The tip stays until the player trots again.

## The fact

The same two end points and the same `ZON_R` are used. Only the travel
direction `sign(till.v − fran.v)` is kept. For each end point the signed offset
is `(v − K_V)·sign(Δv)`, and both end points must satisfy `|u − ref.u| ≤ ZON_R`:
- **`fore`:** both offsets are `< −ZON_R`;
- **`efter`:** both offsets are `> +ZON_R`;
- **no side:** everything else, which covers beside the line, across the ring edge, the circle's "corners" inside the band, and no movement along v.

It adds no new observation, no new threshold and no quality metric. The lead stays `ej_bedomd`.

## Server and client

**Server:**
- `tillTrav(s, tips, sida)`;
- only the `canter_outside` branch passes a side, and every other call clears it; start clears it too;
- the snapshot carries `malSida` only in `trot` + `canter_outside`, for the same `forsokId`.

**Client:** only for `galopp` + `canter_outside` with a valid side, there is one literal key:
- `galopplektion.canter_early`;
- `galopplektion.canter_late`.

Both have SV and EN. Otherwise the text is unchanged.

**It never claims:**
- rider aids;
- the lead;
- cause.

## Acceptance

**`galopplektion.spec`**, on a fresh ride through the real HorseService, RidingIntent and the real panel:
- before and after K, and towards A;
- beside the line;
- the ring edge at exactly −ZON_R;
- trotting again clears it;
- `trot_first` has no side;
- finish and start;
- a KONTROLL client snapshot;
- locale and keys.

**Falsification:**
- the direction;
- the on-line check;
- `fore`/`efter` swapped;
- the edge boundary;
- the snapshot tips guard;
- the client key guard.

**Not tested:** Studio, runtime, touch, the rendered length, and the effect on the next departure.
