# Ugneta turns toward the rider (C2, #234 §4)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [INSTRUCTOR_GAZE_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856775560),
base b6ea134. Build now, test last. Claude writes; Codex reviews source;
Tobias playtests the whole at the end.

This is a fresh implementation on the current candidate. No old branch or PR
is merged (#265).

Not built, and still separate scope:
- the start greeting;
- BubbleChat and chat range;
- persistent skill memory;
- the rest of C2;
- on-foot leading presentation (unchanged).

## What exists (read in source)

- **The figure.** `UgnetaGestalt` builds a CLIENT-LOCAL Model:
  - four anchored, non-colliding parts: jacket, face, grey hair, glasses;
  - placed at `RidKanon.UGNETA.PLATS` through `Ridhusplats`;
  - facing A (`-motC`) until now.
- **Lifecycle.**
  - `LektionController.start` calls `visa` and `avbryt` calls `dolj`.
  - `init.client` calls `start` from `mount` and `avbryt` from `dismount`.
  - `dismount` runs:
    - on every dismount;
    - on CharacterRemoving;
    - on a rig that has left the workspace;
    - before every new `mount`.
- **Frame update.** `init.client`'s single `RenderStepped` path calls
  `LektionController.steg(dt, tm, poseAv(ride.rig))` for the current `ride`
  in the same frame. `poseAv` reads `ride.rig.root` and returns
  `{x, z, yaw}`, or nil.
- **Early return.** `LektionController.steg` returns early when
  `VoltLektionController.tarOver()` is true, which covers all ten mounted
  lesson types and free riding.

## Target provenance

- **Where the target comes from.** The target is the `pose` argument only:
  the horse root of the ride that `init.client` has bound, computed that
  same frame.
- **What is never used:**
  - a search for players or horses;
  - a horse name;
  - a stored rig reference;
  - a closure.
- **Remount, same-ID replacement and denied-dismount reassociation.** Each of
  these goes through `dismount`, then `mount`, then `start`: the figure is
  rebuilt and the next frame's pose comes from the new `ride`.
- **Character loss or a destroyed rig.** `dismount` runs, then `avbryt`, then
  `dolj`: the figure is gone, and a later call with any pose does nothing.
- **Ownership.** Presentation reads only numbers. It never moves or rotates
  the player, the horse or the camera, never changes server or world state,
  and never fires a remote. Control ownership is untouched.

## Turning

The turn is yaw only, about the fixed foot anchor. Each part's world pose is
recomputed from the anchor and the part's LOCAL offset every time (x right,
y up, z forward, in studs; the glasses are 0.12 m forward). There is
therefore no incremental transform and no drift, and height and anchor never
change.

| Case | Behaviour |
|---|---|
| target 1.5 m – 71.4 m horizontally from the anchor | turn toward it |
| closer than `NARA_M` = 1.5 m | hold the current yaw (a near-zero vector is never normalised) |
| beyond `LANGT_M` = `PLATS.langd + PLATS.bortomC + PLATS.bredd/2` = 71.4 m (from RidKanon) | turn back toward neutral (facing A) |
| no target, or a non-finite x/z | no turn |
| `dt` ≤ 0 or not finite | no turn |
| `dt` > `MAX_DT` = 0.1 s | counted as 0.1 s |
| smoothing | `step = diff · (1 − e^(−dt/0.4 s))`, capped at 90°/s · dt; `diff` is wrapped to (−π, π], so she never turns the long way round |
| no figure (missing or ambiguous arena) | nothing; the lesson UI runs as before |

These numbers are play assumptions, not measured visual acceptance.

- **Where it runs.** `UgnetaGestalt.steg` is called at the TOP of
  `LektionController.steg`, before the early return. That covers the legacy
  pass, the ten mounted lesson types and free riding alike.
- **No extra loops.** There is no extra loop or Heartbeat subscription.
- **Teardown.** `dolj` clears the model, anchor, parts and yaw.
- **Repeated `visa`.** `visa` tears down first, even when the new figure
  cannot be placed. A repeated start therefore never leaves two models.

## Text-controls follow-up (in the same instructor surface)

- **P3, the hint line.**
  - The flag and the Text button share the hint line.
  - Each sets the owner (`tipsKalla`) on MouseEnter or SelectionGained.
  - The regular redraw writes the OWNER's text in the current language.
  - Leaving or losing focus hides the line only if it still belongs to that
    control.
- **"Fewer" counter.** It restarts only when the comment choice changes, not
  when the detail choice changes.

## Deferred verification (written, NOT run)

**`ugneta-gestalt.spec` (GESTALT):**
- real placement in the built arena;
- a synthetic arena moved and rotated by 37°;
- the anchor and height stay fixed, and all four parts turn together;
- the glasses are always 0.12 m in front;
- a target behind her, across the ±π wrap, takes the short way;
- near-zero, NaN/inf, no target and far targets;
- `dt` ≤ 0, NaN, and a 5 s `dt` bounded like 0.1 s;
- 10 000 steps without drift;
- a figure destroyed from outside;
- repeated `visa` gives one model;
- after `dolj`, nothing turns.

**`klient-ugnetablick.spec` (KLIENT), through `LektionController`:**
- the legacy pass;
- each of the ten mounted types selected (takeover);
- `avbryt` then `start` (remount, same-ID replacement and denied-dismount
  reassociation all take this path) with a new pose;
- a stale pose after `avbryt` does nothing;
- repeated `start` gives one model;
- no ridhus: the lesson panel still starts and no figure is built;
- the horse root and camera are unmoved.

**Text controls:**
- **`klient-lararinstallning.spec`:**
  - the real Text and flag events plus repeated redraws and SV/EN;
  - a real `LektionController` cue through the filter into the teacher
    surface and host, at each setting;
  - the "Fewer" counter is not reset by a detail change.
- **`klient-uikontext.spec`:** a real care question through
  `PreparationController.tillampa` with the settings area open next to 0..3
  legacy card controls, within the four-row capacity.

**Planned, not written:**
- the whole `init.client` `mount` → `RenderStepped` → `poseAv` chain with a
  built rig (the bench drives `LektionController` with the pose it would
  receive);
- physical motion, framing, feel and phone layout.
