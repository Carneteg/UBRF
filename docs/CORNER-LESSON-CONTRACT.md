# Through the corner: one oriented corner as a mounted training lesson

Status: BUILT_NOT_VERIFIED, 2026-09-27. This contract was written BEFORE the
production edits for this slice.
Order: [CORNER_LESSON_BUILD](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857677747),
base a9c129d. Build now, test last. Claude writes; Codex reviews source;
Tobias plays the whole candidate at the end.

`RidKanon` already names the teaching intention `horn` ("Rid genom
hörnet"). This slice makes it a selectable mounted training lesson that
completes a task, driven by server observation. It is ONE additional
definition, not a content programme and not a whole-catalogue completion.

## Identity (never aliases anything)

| | Value |
|---|---|
| Lesson type (request, controller, memory) | `hornet` |
| RidForsok exercise / definition | `genom_hornet` / `server-horn-1` |
| Memory key | `lektion:hornet:server-horn-1` |

- **The legacy `horn`.** The client-only legacy exercise `horn` (RidKanon,
  recording and pass) is NOT used and NOT renamed.
- **The ten existing types** are unchanged.

## Geometry (GAME TRAINING ASSUMPTIONS, metres, in the resolved layout frame)

The frame is `RidPlatsObservation`'s resolved dressage frame:
- `u` runs across the arena, with `u0` = `dressyrMitt.u`;
- `v` runs along the arena from A (0) to C (L);
- the half width is `W = halvTvars / studsPerMeter`, and the length is
  `L = 2·halvLangs / studsPerMeter`.

There are no invented letters or official programme, and the corner is the
one at the `+u` side of the C end:
- **Track line:** `T = 1.5` m inside the edge, so `uT = u0 + W − T`.
- **The quarter circle:** radius `R = 5`, centre `(cu, cv) = (uT − R,
  L − T − R)`.
- **The pieces:**
  1. **Approach:** from `P0 = (uT, cv − 10)` to `P1 = (uT, cv)`, 10 m in the
     `+v` direction (towards C).
  2. **Arc:** `(cu + R·cos θ, cv + R·sin θ)` for θ from 0 to π/2, from `P1` to
     `P2 = (cu, cv + R)`; the heading turns from `+v` to `−u`.
  3. **Exit:** from `P2` to `P3 = (cu − 6, cv + R)`, 6 m in the `−u`
     direction.

  The total length is `10 + R·π/2 + 6` ≈ 23.85 m.
- **Projection:** the nearest piece gives `s` (the distance along the path,
  negative behind `P0`) and `e` (the distance from the path).
- **Corridor:** `e ≤ KORR = 1.2` and `−ZON ≤ s ≤ total + ZON`, with ring
  `ZON = 2`.
- **Why a chord never passes:** a straight line from P1 to P2 lies at most
  `R·(1 − cos 45°)` ≈ 1.46 m from the arc, which is more than 1.2 m.
  Riding deep into the fence corner lies ≈ 2.07 m from the arc. Both fail
  the corridor.
- **The ordered checkpoint** at mid-arc, `Pm = (cu + R·cos 45°, cv +
  R·sin 45°)`, must be reached within `MITT = 1.0` m before completion. A
  chord misses it.
- **Fit check (`ryms`):** `2W ≥ R + T + 6 + 2·KORR + 1` and
  `L ≥ T + R + 10 + ZON`. Otherwise the result is "place" (no guide, no
  start).
- **The guide** (`VoltLektionController.hornGuide`) is drawn from the SAME
  `referens` fields the server projects against: `uT`, `cu`, `cv`, `R`,
  `P0`, `P3`, `ring`. It uses `Plats.tillVarld` with the same frame
  (`plats`), just as the half-circle and path guides do. The dashes are
  clipped to the arena (`streck`).

## Evidence and states (same pattern as `VagLektion`)

- **The states:** `to_start` → `route` → `complete`.
  - In `to_start`, a fresh observed segment ending in the start ring (at
    `P0`, inside the corridor, `s ≤ ZON`, inside the arena) arms the route.
  - Arming gives no credit.
- **In `route`, each fresh observed segment:**
  - must continue from the previous endpoint (within 0.05 m) and be at most
    `GROV_M = 4` m long;
  - must have both endpoints in the corridor and the arena;
  - may go back at most `BAKAT_M = 1` m, otherwise it counts as `reverse`;
  - counts only in walk or trot as accepted gait (halt is a pause, backing
    or canter is wrong);
  - pushes the greatest `s` reached (`langst`) forward only in walk or trot.
- **Completion requires all of:**
  - the mid-arc checkpoint passed;
  - `langst ≥ total − SLUT_M` (0.5 m);
  - the segment ends in the end ring (at `P3`).
- **What returns to `to_start`, with its tip:**
  - `unknown`: a break (gap, missing, teleport, frame), a missing
    observation or a frame change;
  - `off_route`: outside the corridor;
  - `reverse`: going backwards;
  - `walk_or_trot`: the wrong gait.
- **Other ends:** the deadline (120 s) gives `timeout`. Finish, dismount and
  teardown behave as in the other lessons.
- **What never completes:** standing still, pre-start evidence, a stale
  snapshot or a previous completion.
- **Sub-goals (`delmal`):** 0 = to the start, 1 = approach, 2 = the arc,
  3 = exit.
- **The frozen result** is `{forsokId, rittId, userId, hastId, figur =
  "hornet", meter = langst − armS, armS, slutS, langd, mitt = true, radie =
  R, start}`.
- **It claims nothing about:** bending, balance, body, rhythm, contact or
  quality.

## Integration

- **HorseService.** `lektionModul("hornet")` and the type validation. The
  ride-scoped, type-aware request book is unchanged, so A-B-A, retry and
  "another lesson active" work as before.
- **Menu (four rows).** "Riding paths" becomes:
  - "Curved paths" (serpentine, half-circle, corner, Back);
  - "Straight lines and ground pole" (unchanged);
  - Back.

  Serpentine and half-circle therefore move ONE level deeper, and every
  existing choice remains. The four specs' menu-path tables (halvvolt,
  vag, galopp and markbom specs) are updated to match: that is navigation
  data, not a weakened assertion.
- **Memory.** Lesson memory's markers and suggestion follow
  (`MINNE_UNDERGRUPP`), and `hornet` is placed after the half-circle in the
  teaching order.
- **Controller.** The guide, the texts (`hornlektion.*`) and the greeting
  (`halsning.hornet`). The existing mounted lifecycle covers the greeting,
  the gaze, Normal/Fewer/Off, the four rows, pending/error and stale
  controls.
- **Feedback.** `LektionsAterkoppling` shows `hornet` only when
  `figur == "hornet"`, `mitt == true`, `meter ≥ 0` and `langd > 0`:
  - detailed: "Through the corner: X m of the route (Y m) with the corner
    in one flow." plus one next step;
  - concise: without the numbers;
  - an invalid result gives the neutral text.
- **LektionsMinne.** The DEF gets `hornet`, validated against the frozen
  result and the RidForsok definition. Its own key; nothing is migrated.

## Tempo follow-ups (same package)

- **`skicka`** now also clears `coachning` immediately on a new request.
  Neither the cooldown nor Fewer is touched.
- **`tempocoachning.spec`:**
  - J6 is corrected to a sequence that is genuinely NOT drawn between
    events (only `_coachningForProv` is read until the check);
  - J/J9/JD take the request identity from the server's request book
    (`hogsta + 1`) and check that Finish was accepted, instead of assuming
    the helper's own number;
  - the joined coverage that is missing is labelled PLANNED: place,
    duplicate, timeout and Finish.

## Deferred verification (written, NOT run)

`roblox/tests/hornlektion.spec.luau` (KOHERENS) uses the vaglektion
fixture.

**SYNCHRONOUS joined path** (real HorseService, observations and route):
- a genuine approach, arc and exit giving complete, the result and the
  memory;
- a chord across the corner, and outside the corridor;
- reverse, overshoot into the corner and standing still;
- the wrong gait;
- pre-start evidence;
- a gap, a teleport and a frame change;
- Retry, timeout, Finish and dismount;
- A-B-A and another active lesson;
- a duplicate or retry into memory.

**FABRICATED geometry:** the projection and the ordered guide segments
checked against the server's `referens` (the same fields).

**FABRICATED client snapshots:**
- the menu in `UgnetaController.panel(4)`;
- language, detail and Off;
- a malformed frozen result.

**GENUINELY DEFERRED:** a Start request on the scheduler, with the push
arriving before the delayed reply.

**PLANNED, not written:**
- physical rendering and layout;
- respawn on a device;
- memory's deferred save with a real corner completion. The same pipeline
  is written in `lektionsminne` and `skotselminne`.
