# Gate 01 — ChatGPT Senior Gameplay Review 02

Status: **CHANGES REQUIRED — ONE BLOCKER REMAINS**
Reviewer: ChatGPT — Senior Game Developer / Game Systems Architect
Date: 2026-08-30
Reviewed head: `9e4521cd31ded0940302e3d58a7260206ebe2caf`

## Executive verdict

Review 01 blocker A, B and C are **resolved**.

The yaw ownership fix is coherent with `Humanoid.AutoRotate = false`, the web gait phase now uses one normalized phase-cycle distance rather than multiplying stride by hoof count, and audit commit traceability is corrected. The new movement bench is materially better because it now advances a rig position instead of only measuring internal locomotion bookkeeping.

Gate 01 is nevertheless **not ready for Product Owner Studio playtest yet**.

One blocker remains: Roblox touch riding is not wired to any real touch UI/input source. The API exists (`Input.setTouch`, `Input.touchGait`, `Input.touchJump`), but repository search shows no caller outside `roblox/src/client/Input.luau`, and `init.client.luau` only binds keyboard/gamepad input. The audit itself currently marks Roblox analog touch as unverified.

This is not a documentation-only yellow item. Without a caller, a Roblox phone/tablet player cannot feed continuous touch steering/forward intent into the horse model through the intended input contract.

---

## Review 01 resolution

### A — Roblox yaw ownership: RESOLVED

`MovementController` now writes the root yaw from `loco.heading` every frame while preserving the current root position:

```luau
local root = rig.root
root.CFrame = CFrame.new(root.CFrame.Position) * CFrame.Angles(0, loco.heading, 0)
```

That matches the server-side architecture where `HorseService` deliberately sets:

```luau
hum.AutoRotate = false
```

The movement test bench was also upgraded from a stationary stub to a moving-rig harness. It now measures physical/root yaw against logical heading at walk/trot/canter, no-steer drift, left→right neutral crossing, turn-in-place and the transition into forward movement.

Evidence reported in `53f874b`:

- root yaw vs `loco.heading`: 0.00e+00 rad deviation,
- no yaw drift over 5 seconds with no steering,
- left→right largest yaw step 0.0147 rad/frame,
- turn-in-place rotates the rig and transitions continuously.

Static review: **PASS**.

Remaining risk is Studio-specific physics interaction from writing root `CFrame` while Humanoid movement is active. That is now a **playtest risk**, not a code ownership contradiction. During Studio playtest watch for jitter, vertical snapping, loss of ground contact, or network-owner disagreement. Do not redesign pre-emptively unless Studio reproduces one of those symptoms.

### B — Web gait phase cycle length: RESOLVED

`src/game.js` no longer multiplies `G.ride.steglangd` by a `CYKELSTEG` hoof-count table. The definition is now unambiguous:

> cycle length = distance travelled during one complete normalized phase cycle 0→1.

That matches the structure in `src/scen3d.js`, where all four legs live inside the same normalized phase with offsets, and it is conceptually aligned with Roblox `Gaits.cycleLength(name) = norm / cycles`.

Reported measurements after `53f874b`:

- web distance/phase-cycle: 1.413 / 1.940 / 3.082 m,
- web computed cycle length: 1.418 / 1.942 / 3.082 m,
- Roblox: 1.450 / 2.133 / 3.200 m,
- 20 m produces approximately twice the phase cycles of 10 m,
- blocked/stationary horse does not continue advancing phase.

Static review: **PASS**.

The small web/Roblox numeric differences are acceptable for Gate 01 because both now express the same design quantity and neither platform is multiplying hoof count twice.

### C — audit commit traceability: RESOLVED

The audit now correctly identifies `33559d9` as the web riding implementation and explicitly records `61d503d` as unrelated Drive/reference work. Evidence tables are mapped to actual implementation commits.

Static review: **PASS**.

---

## BLOCKER D — Roblox touch exists only as an API, not as playable input

### Evidence

`roblox/src/client/Input.luau` exposes:

```luau
function Input.setTouch(forward: number, steer: number)
function Input.touchGait(up: boolean)
function Input.touchJump()
```

but repository search for `setTouch`, `touchGait` and `touchJump` finds only those definitions.

`roblox/src/client/init.client.luau` mounts the riding systems and calls `Input.bind()`, but creates no touch riding UI and does not feed a virtual joystick or touch move vector into `Input.setTouch`.

`ContextActionService:BindAction("HorseControl", ..., false, ...)` explicitly does **not** create touch buttons (`false`). The gamepad polling path only reads `Gamepad1/Thumbstick1`; Roblox mobile touch is not a gamepad state.

Therefore the statement in the audit:

> "pekstöd finns, otestat i klient"

is too generous. The low-level setter API exists, but the player-facing touch path is not connected.

### Why this blocks Gate 01

`docs/GATE-01-PLATFORM-ADDENDUM.md` makes Roblox the primary gameplay target and requires actual Studio playtest of `touch where possible`. The product also targets phone/tablet access. A playtest cannot validate analog Roblox touch if no touch control can drive the horse.

This is exactly the kind of gap a platform-parity gate is supposed to catch before Product Owner testing.

### Required change

Implement the **smallest Roblox-native riding touch surface** that connects to the existing `Input` contract.

Do not rewrite movement, do not add a new input architecture and do not change the web implementation.

Required behaviour while mounted on a touch device:

1. one analog riding control must continuously call `Input.setTouch(forward, steer)` with normalized values in `[-1, 1]`,
2. releasing/cancelling the control must immediately return both axes to zero,
3. touch controls for gait up, gait down, jump and dismount must exist or use an equally clear native Roblox touch interaction,
4. the UI appears only when relevant and is removed/disabled on dismount,
5. keyboard and gamepad remain unchanged,
6. no default Roblox touch control may simultaneously move the rider character in a way that fights the horse,
7. use the existing `Input.consume()` → `MovementController` path; do not bypass it.

A small `TouchControls.luau` owned by the client riding layer is acceptable if that is the simplest implementation. Reusing an existing Roblox-native touch vector is also acceptable if it can be proven not to fight the seated rider/horse.

### Required automated/bench evidence

At minimum:

- 25%, 50%, 100% horizontal touch input reaches three monotonically different `Intent.steer` values,
- left/right signs are correct,
- release returns steer/forward to zero,
- gait up/down are edge-triggered once per tap,
- jump fires and releases,
- mount→touch controls enabled; dismount→controls disabled,
- no keyboard/gamepad regression.

These can be contract tests around the touch adapter/input module even if full GUI gesture testing remains Studio-only.

### Required Studio/device-emulation evidence before Gate close

On Roblox mobile/device emulator:

- analog small correction,
- medium circle steering,
- full steering,
- walk/trot/canter changes,
- jump where allowed,
- dismount,
- no competing movement from the player's default character controls,
- touch UI does not obscure the horse/route excessively in phone and tablet layouts.

Tobias still owns the final subjective feel call.

---

## Non-blocking observations for Product Owner playtest

Once Blocker D is fixed, the implementation is technically strong enough to proceed to subjective Studio testing. During that test, focus on:

- whether explicit root-yaw writes create any Roblox physics/network jitter,
- whether 20 m circles can be held without micro-correction fighting,
- whether canter remains broad but responsive,
- whether camera lag feels intentional rather than detached,
- whether horse lean and rider secondary motion remain subtle,
- whether gait/hoof rhythm reads as planted rather than sliding,
- whether mobile touch feels analog rather than like disguised buttons.

These are feel checks, not reasons to expand systems before testing.

## Required Claude response

Implement **Blocker D only**.

Then update `audits/GATE-01-RIDING-FEEL-RESULT.md` with:

- exact touch implementation commit SHA,
- files changed,
- touch architecture in one paragraph,
- automated touch input measurements,
- what remains Studio-only,
- updated parity table.

Do not add new gameplay features and do not close Gate 01.

After that, hand back for **ChatGPT Senior Review 03**. If Blocker D is clean, the expected outcome is `READY FOR PRODUCT OWNER STUDIO PLAYTEST`, not automatic Gate closure.