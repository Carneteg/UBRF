# Riding-path lesson: centre line and diagonal (game training paths)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [RIDING_PATHS_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855574219),
base 96da81b. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

These are **game training paths**, NOT official dressage programmes, with no
invented letter positions. The lesson covers two figures of the catalogue area
"väg": a straight centre line and a diagonal change of side. It is not every
riding-path exercise.

## Player outcome

1. Choose "Riding paths" in Ugneta's panel.
2. Choose the figure: "Centre line" or "Diagonal". A Back step returns to the
   top level.
3. Start explicitly.
4. Ride into the start ring, then along the drawn line in walk or trot to the
   end ring.

Ugneta gives one short positive instruction per state, progress in percent,
"Riding path completed", and Retry and Finish. The route is drawn locally
without collision:
- the line has direction chevrons;
- the start ring and end ring are distinct;
- the next target is solid (the start ring before arming; the line and end
  ring while riding) and the rest is faint.

The outcome is session-local only. The lesson claims an **ordered traversal of
the selected line within its corridor**. It does NOT claim the horse's
straightness, bend or aids.

## Panel (fix of an existing limit, inspected in source)

The Naromrade panel shows at most `MAX_VAL = 4` choice rows, and Ugneta's own
card buttons come before a lesson's. Five top-level lesson choices plus
"lessons" were therefore partly hidden after the serpentine and tempo
packages.

The top level is now at most four entries:
- the circle lesson;
- "Gaits and pace", a group with start/halt, transitions and steady walk;
- "Riding paths", a group with the serpentine, the centre line and the
  diagonal;
- "lessons" (back to the ordinary lesson) when free riding.

Each group page has at most three choices plus Back. Every earlier lesson
stays reachable. Long labels wrap: the buttons have `TextWrapped` and the
choice area scrolls. Rendered layout is not verified.

## Geometry (resolved layout frame, metres; `u0 = dressyrMitt.u`, `v` from A)

| Figure | Start P0 | End P1 | Length |
|---|---|---|---|
| Centre line (`vag_mitt`) | (u0, 6) | (u0, 54) | 48 m |
| Diagonal (`vag_diag`) | (u0 − 7, 8) | (u0 + 7, 52) | ≈ 46.2 m |

- **Direction:** P0 → P1 only.
- **Line coordinates:** `s` is the distance along the line from P0, and `e` is
  the perpendicular distance from it.
- **Corridor:** |e| ≤ 2.0 m and −2.0 ≤ s ≤ L + 2.0. It is convex, so a
  segment with both endpoints inside lies wholly inside.
- **Arena:** the horse must also be inside the dressage layout (`iDressyr`)
  at both segment endpoints.
- **Start and end rings:** within 2.0 m of P0 and P1.
- **Fit at Start:** half-width ≥ 7 + 2 + 1 and length ≥ 54 + 2. Otherwise
  Start is refused with `place`. The built layout (20 × 60) fits both
  figures with at least 1 m margin.

## Numbers (unmeasured gameplay assumptions)

| Name | Value |
|---|---|
| Corridor half-width | 2.0 m |
| Start / end ring radius | 2.0 m |
| Coarse segment | > 4.0 m in one step: unknown |
| Backwards | `s` more than 1.0 m behind the furthest reached point: reverse |
| Completion | furthest point ≥ L − 0.5 AND the step ends in the end ring |
| Deadline | 120 s; timeout ends incomplete, never success |

## Evidence

The lesson uses only RidPlatsObservation segments (both endpoints, same
frame), RidObservation break counters, RidLogg gait events after Start, and
the accepted gait.

- **Arming:** in `to_start` the lesson arms when a fresh valid segment ends
  inside the start ring, inside the corridor and the layout, at `s ≤ 2`, in
  walk, trot or halt, and not reversing. The arming step gives NO credit:
  progress starts at 0 from there, so the approach and crossing interval are
  discarded.
- **Riding:** each step needs all of the following:
  - a valid segment that begins exactly where the previous one ended (the
    lesson steps in the same heartbeat as the sampling);
  - length ≤ 4 m;
  - both endpoints in the corridor and the layout.
- **Credit:** the furthest point along the line only grows from observed
  forward motion in walk or trot. Halt is an allowed pause: no credit and no
  reset, as long as the horse stays in the corridor. Reversing, canter or a
  gait event into them resets with `walk_or_trot`.
- **Cannot complete:**
  - Standing still, jitter and oscillating near the start add at most the
    furthest point; going back more than 1 m resets.
  - Riding parallel outside the corridor, cutting to the end, and backwards
    travel all leave the corridor or reset.
  - The end ring alone and distance ridden elsewhere give nothing.
  - A zero turn rate is never used as evidence.

## Recovery and breaks

The following return the attempt to `to_start`, with all line credit cleared
and the deadline kept:
- leaving the corridor or the layout (`off_route`);
- going backwards (`reverse`);
- a wrong gait (`walk_or_trot`);
- an unknown, coarse or discontinuous segment (`unknown`);
- observation breaks (gap, missing root, teleport, invalid dt), frame change
  or loss, a ridplats image without a valid position, and RidLogg overflow.

The break checks run BEFORE the observation-time equality. While in
`to_start` nothing more resets, so there is no restart churn. The player
recovers by riding into the start ring again.

## Lifecycle, identity and requests

- **Attempt:** FORSOK1 `ovning = ridvag`, definition `server-vag-1`, for both
  figures.
- **The figure is the lesson type:** `vag_mitt` or `vag_diag`. It is therefore
  part of the ride-scoped, type-aware request ledger:
  - a delayed or duplicate request from the other figure is refused (same
    sequence with another type) or stale;
  - switching figure while an attempt is active is refused (`active`) until the
    player explicitly Finishes.
- **Closing:** success closes once with `slutford`; the deadline closes with
  `tidsgrans` and wins at equality; Finish closes with `avbrutet`; ride
  teardown closes through FORSOK1.
- **Frozen result:** figure, metres along the line, and start.
- **Retry:** new attempt of the same figure; all evidence cleared.

## Type extension (explicit)

- **HorseService:** `lektionModul` maps `vag_mitt` and `vag_diag` to
  `VagLektion`, and `ny` receives the type as a fourth argument (the other
  lessons ignore it).
- **Client:** the menu groups, the figure choice, and the line guide.
- **Earlier lessons:** behaviour, keys and replies are unchanged.

## Deferred verification (written, NOT run, by decision)

`roblox/tests/vaglektion.spec.luau` contains these written cases.

**Full routes and arming:**
- the full centre line with a frozen result recording the figure;
- the full diagonal;
- approaching through the start ring from behind gives no credit before
  arming;
- literal endpoints P0 and P1 on the line.

**Wrong routes:**
- a parallel line 4 m beside the centre line never arms or progresses;
- visiting only the end ring;
- leaving the diagonal to ride straight towards C (a cut) resets.

**Movement and gait:**
- backwards travel resets;
- oscillating near the start gives no progress;
- standing still;
- a halt pause keeps the credit and continues;
- reversing resets;
- trot counts and canter resets.

**Breaks:**
- a coarse segment;
- a teleport, then fresh recovery.

**Lifecycle and requests:**
- deadline;
- Retry and Finish;
- switching figure while active is refused;
- a delayed old start of the other figure;
- the same sequence with another figure;
- all seven lesson types start and finish;
- owner events go only to the owner;
- no persistent writes.

**Planned, not written:**
- frame change, invalid dt, missing root, a gap and RidLogg overflow, which
  use the same break code path as start/halt (whose spec has them);
- the client menu (no client bench for this panel), and rendered layout on
  PC, touch and SV/EN.

Engine, rendering and the player flow are unverified.
