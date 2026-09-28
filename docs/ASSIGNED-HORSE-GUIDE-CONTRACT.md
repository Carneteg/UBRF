# Assigned horse guide: a clear local marker from spawn to your own horse

Status: contract written before code, 2026-09-28.
Order: [TOBIAS_RUNTIME_FAIL_ASSIGNED_HORSE_NOT_FINDABLE](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5870875685)
and [EXECUTE_RUNTIME_BLOCKER…](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5870906640). Base `dcf2be1` (runtime `fa41803`).
**A human runtime blocker found by Tobias in Play.** No other scope.

## Reproduced in Studio (MCP, Play, the synced candidate `2e0b6a877e69`)
- From spawn, the assigned horse (`troy`) is **97.3 studs** away.
- `DinHastSkylt` exists and is `Enabled`, but it is **160×44 px**, has **no arrow**, and has `MaxDistance = 120`: just inside the limit from spawn, and easy to miss.
- `MINIMAL_UI = true` switches off the HUD line "Idag rider du …" (by product decision, and it is kept).
- **Respawn bug:** the label is a `BillboardGui` directly in `PlayerGui` with `ResetOnSpawn = true`.
  - After a death/respawn it is **deleted and never comes back** (measured: gone 2 s and 6 s after respawn).
  - The cause: `skylt` still points at the destroyed instance, so `if not skylt` never rebuilds it.

## What is built (only `roblox/src/client/DinHast.luau`)
- **The same truth:** the horse comes from `PreparationController.hastId()` (as today). There is no new assignment system, and **only that horse** is marked.
- **An unmistakable world guide on the same billboard:**
  - a large gold **▼ arrow** above the horse with a slow bob;
  - the existing panel "Din häst" plus the name, larger;
  - `AlwaysOnTop`, so it shows through the stable walls;
  - a **fixed pixel size**, so it is just as visible from a distance;
  - `MaxDistance` covering the whole site.
  - It stays local: in the player's own `PlayerGui`.
- **It hides when the question is answered:**
  - **fully hidden** within `NARA` (12 studs) of the horse, where previously it only faded to 12 %;
  - hidden while leading (`ledNamn`) and while mounted (`satDold`), as today;
  - it comes back when you are far from your horse again and neither leading nor riding.
- **Self-healing:**
  - `ResetOnSpawn = false`;
  - the loop rebuilds the label when it is missing, has lost its parent, or its adornee is not in **the current** model of the assigned horse. That covers a respawn, delayed streaming, and a model that is replaced.
- **The HUD stays minimal:** `MINIMAL_UI` is unchanged.

## Acceptance (`klient-dinhast.spec`, the client bench, the real `init.client` through `PreparationController.tillampa`)
1. Only the assigned horse gets the label; **another horse is never marked**, and there is exactly **one** `DinHastSkylt`.
2. From a distance (100 studs) the label shows the arrow and the name, with `AlwaysOnTop`, `MaxDistance` ≥ the site, a fixed pixel size and `ResetOnSpawn = false`.
3. **It is hidden** within 12 studs, while leading and while mounted, and comes back afterwards.
4. **Respawn / lost label:** a label that is removed is rebuilt within a second.
5. **Streaming:** no model means no label; the model arrives and the label appears; the model is replaced and the label follows the new model.
6. **Falsification:**
   - `ResetOnSpawn` back to true / no self-healing;
   - the wrong horse marked;
   - not hidden when close;
   - no arrow.

**Full suite; re-lock** (a mapped client file). **Studio:** reproduce the before state (done above), then verify after the fix: from spawn, near, respawn.

**Not tested:** whether it **looks** clear to a human (size, colour and contrast on PC/iPad/iPhone). That goes on Tobias's checklist.
