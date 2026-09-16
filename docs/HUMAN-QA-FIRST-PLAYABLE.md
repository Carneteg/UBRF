# First Playable — residual human QA and acceptance record

PR: [#162](https://github.com/Carneteg/UBRF/pull/162)  
Purpose: close the remaining human-only checks on the already product-accepted candidate.  
This record does **not** authorize a merge or change the existing `PRODUCT_ACCEPTED` decision.

## 0. Candidate lock — stop if any value differs

| Field | Required value |
|---|---|
| Artifact source SHA | `91914a73f4257d7a90f925347a473e98fbc9e04f` |
| Place | `roblox/releases/first-playable-place-91914a7/UBRFFirstPlayable.rbxlx` |
| SHA256 | `4771a340b69a3a986bf56c84ecdcd3edbf208be8add73d8742c2d59195cc115c` |
| Expected startup | `FIRST_PLAYABLE_SHA=91914a73f4257d7a90f925347a473e98fbc9e04f` and `FIRST_PLAYABLE_PREFLIGHT: PASS` |
| Expected world | 3,375 parts · 13 portals · 33/33 horses |

> **Important:** `docs/STUDIO-RUNTIME-QA.md` still pins the older `637ab03`
> artifact. Use its behavioral expectations only. Do not use its artifact path,
> source SHA, hash, instance count, or startup identity for this run.

Tester: `________________`  
Date/time: `________________`  
Studio/Roblox version: `________________`  
iPad + iPadOS: `________________`  
iPhone + iOS: `________________`  
Network: `________________`

Allowed result for every row: **PASS · FAIL · NOT_TESTED**.  
A blank cell is **NOT_TESTED**, never PASS. For FAIL, add evidence and a reproducible sequence.

## 1. Physical iPad touch riding — blocking

Use the physical Roblox app in landscape. Start from the normal gameplay route,
acknowledge the lesson card, then ride for at least five minutes.

| Check | Acceptance criterion | Result / evidence |
|---|---|---|
| Left joystick | Thumb stays inside the control; forward/left/right are correct; horse never travels tail-first | |
| True multitouch | Steering plus gait/jump/help works with two thumbs; neither touch steals or cancels the other | |
| Gaits | Walk/trot/canter, slower and halt respond once per intended tap; transitions are smooth and readable | |
| Touch camera | One-finger camera input works while riding without hijacking the joystick or buttons | |
| Rotation/safe area | Landscape remains usable after rotate away/back; controls do not overlap screen edges or system areas | |
| Focus/cancel | App switch or interruption releases held input; horse does not continue by itself | |
| UI clearance | Joystick, gait controls, help, tracker, lesson card and replay never hide each other or the forward view | |
| Dismount lifecycle | Dismount clears riding input; remount works without duplicate or stuck controls | |

iPad feel note — one sentence:  
`________________________________________________________________________`

## 2. Physical iPhone touch riding — blocking

Repeat the same ride on a physical iPhone in landscape. Specifically verify the
denser phone layout documented in PR #162.

| Check | Acceptance criterion | Result / evidence |
|---|---|---|
| Three-button row | All three 64×44 controls are individually hittable without accidental neighbors | |
| Joystick travel | Knob remains understandable and controllable across its full travel; no unexpected snap or drift | |
| Help button | `?` remains visible, hittable and clear of the objective tracker | |
| True multitouch | Steering plus a riding action works repeatedly with two thumbs | |
| Camera | Camera can be adjusted without accidental gait, help or joystick input | |
| Notch/safe area | No required control or text sits under a notch, home indicator or rounded corner | |
| Focus/respawn | No held input survives app switch, death, respawn or dismount | |

iPhone feel note — one sentence:  
`________________________________________________________________________`

## 3. Camera feel — blocking, record per device

Run in open arena, beside a wall, through a doorway and during a jump.

| Check | iPad | iPhone | Acceptance criterion |
|---|---|---|---|
| Steering relationship | | | Camera movement does not make steering feel delayed, reversed or disconnected |
| Horse framing | | | Head, ears and mane read correctly; horse feels like a horse, not a vehicle |
| Collision/clipping | | | No sustained clipping through horse, walls, boxfronts or roof |
| Turn/jump motion | | | Turns, takeoff and landing are readable and do not cause disorienting snaps |
| Reduced Motion | | | With OS Reduced Motion enabled, play remains usable and comfortable |

Camera verdict: **PASS / FAIL / NOT_TESTED**  
Reason: `_________________________________________________________________`

## 4. Roblox runtime routing — blocking

Use ordinary prompts and movement; do not teleport or edit state.

| Route/check | Acceptance criterion | Result / evidence |
|---|---|---|
| Spawn | Player lands on colliding ground at the canonical entrance; no void or roof trap | |
| Own equipment | Correct saddle/bridle is collected from the assigned horse's boxfront; wrong tack is rejected at the horse | |
| Box exit | Led horse turns and exits its box head-first without crossing a wall or boxfront | |
| Canonical horse route | Horse is led through the **horse corridor and arena gate** into the riding arena | |
| Pedestrian openings | A led horse cannot route through openings classified for pedestrians | |
| Door/prompt routing | Prompts target the intended door/gate, trigger once and land in the correct zone | |
| Full loop | Groom → tack → lead → mount → ride → dismount → aftercare completes without teleport or developer intervention | |
| Recovery | Death/respawn releases rider/lead ownership and permits a clean remount/relead | |

Routing verdict: **PASS / FAIL / NOT_TESTED**  
Evidence (video or screenshots): `___________________________________________`

## 5. Full-world performance — blocking

Run the full generated world with all 33 horses present. Open Roblox performance
stats and play the canonical loop for at least ten continuous minutes. Do not
set a new numeric release threshold during this run: record the measurements and
judge whether they impair control or completion.

| Measurement/check | iPad | iPhone | Acceptance criterion |
|---|---|---|---|
| 33/33 horses present | | | All are present; no roster streaming/pop-in defect blocks play |
| FPS: typical / lowest observed | | | Recorded; no sustained degradation that makes riding or touch input unreliable |
| Memory: start / 10 min | | | Recorded; no runaway growth, OS termination or crash |
| Network ping: typical / worst | | | Recorded; no repeated control loss attributable to runtime routing |
| Frame pacing | | | No repeated long freezes, severe hitching at doors, mounting or gait changes |
| Complete loop | | | Canonical loop finishes without crash, disconnect or required restart |

Performance verdict: **PASS / FAIL / NOT_TESTED**  
Notes: `__________________________________________________________________`

## 6. Multiple led horses — blocking multiplayer check

Use at least two real players in the same server, each with a different horse.
Repeat once with both horses entering the horse corridor close together.

| Check | Acceptance criterion | Result / evidence |
|---|---|---|
| Independent ownership | Each horse follows only its own leader; prompts and state do not cross between players | |
| Simultaneous start/stop | Both players can start, stop and resume leading without releasing the other pair | |
| Shared corridor | Two led horses can use the horse corridor without permanent deadlock, wall traversal or teleport | |
| Close crossing | Horses do not merge, swap leaders, fling or acquire impossible rotation | |
| One leader disconnects | Only that player's lead releases; the other horse remains correctly owned and controllable | |
| Arena arrival | Both horses can reach the arena and satisfy their own lead objective independently | |

Players/devices used: `____________________________________________________`  
Multiple-lead verdict: **PASS / FAIL / NOT_TESTED**

## 7. Separate Roblox-world visual review — non-inherited

This is a visual review of the **Roblox world**. The existing
`CHATGPT_VISUAL_PASS` applies only to the web rendering and must not be copied here.

Capture matched landscape screenshots from stable exterior, entrance/reception,
main stable aisle, representative boxfront, horse corridor, arena entrance,
arena interior and one horse fully tacked.

| Area | Review criterion | Result / evidence |
|---|---|---|
| Exterior/site | Recognizable UBRF layout, coherent scale, no unintended rails/markers or obvious floating geometry | |
| Entrance/reception | Correct spatial hierarchy and usable approach; no blocking decorative geometry | |
| Stable/boxes | Aisles, fronts and doors read as a real stable; all horses stand inside their own boxes | |
| Horse corridor/arena | Canonical openings are visually legible and agree with runtime routing | |
| Signs/doors | UBRF and Café Krubban signs are visible, outward-facing and readable; doors/gates look intentional | |
| Horses/tack | Horse proportions, orientation and tack attachment are visually credible enough for First Playable | |
| Lighting/materials | No severe z-fighting, missing faces, broken transparency, unreadable darkness or glaring placeholder color | |
| Overall fidelity | World is recognizably UBRF and visually coherent enough for the First Playable milestone | |

Visual reviewer: `________________`  
Roblox visual verdict: **PASS / FAIL / NOT_TESTED**  
Evidence folder/links: `___________________________________________________`  
Top three visual findings, if any:

1. `____________________________________________________________________`
2. `____________________________________________________________________`
3. `____________________________________________________________________`

## 8. Acceptance record

| Gate | Result | Evidence |
|---|---|---|
| Candidate identity and preflight | | |
| Physical iPad touch riding | | |
| Physical iPhone touch riding | | |
| Camera feel | | |
| Roblox runtime routing | | |
| Full-world performance | | |
| Multiple led horses | | |
| Separate Roblox visual review | | |

Final residual-human-QA status: **PASS / FAIL / PARTIAL-NOT_TESTED**

Decision rule:

- **PASS:** candidate identity matches and every gate in the table is completed and PASS.
- **FAIL:** at least one acceptance criterion fails. Record repro and do not rebuild until root cause is understood.
- **PARTIAL-NOT_TESTED:** anything is blank, unavailable or not run.
- A visual FAIL does not rewrite the earlier web visual result; it fails only the separate Roblox-world review.
- This record closes residual QA only. Merge remains a separate owner decision.

Signed by: `________________`  
Date: `________________`

### Final PR line

```
HUMAN_QA_<PASS|FAIL|PARTIAL_NOT_TESTED> — PR #162 — source 91914a73… — rbxlx 4771a340… — iPad <result> — iPhone <result> — camera <result> — routing <result> — performance <result> — multi-lead <result> — Roblox visual <result>
```
