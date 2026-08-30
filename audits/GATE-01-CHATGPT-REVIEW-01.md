# Gate 01 — ChatGPT Senior Gameplay Review 01

Status: **CHANGES REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Game Systems Architect
Date: 2026-08-29
Reviewed head: `6cb5ed1640cab200d90010bef57ad6b4c6b2bd62`

## Sammanfattning

Gate 01 har gjort stora riktiga förbättringar: normaliserad ridinput, analog touch i webben, kurvaturbaserad styrning, dt-baserad väggrespons, separat kamerakurs, subtil turn lean och ryttarsekundärrörelse. Roblox- och webbmodellen har också kommit betydligt närmare varandra.

Gaten kan ändå inte gå till Product Owner-playtest ännu. Två blockerande kodproblem finns i den faktiska implementationen, plus en spårbarhetsmiss i auditen.

---

## BLOCKER A — Roblox normal riding yaw contradicts AutoRotate=false

### Evidence

`roblox/src/server/HorseService.luau` sets:

```luau
hum.AutoRotate = false
```

and the comment explicitly says the game owns rotation.

But `roblox/src/client/MovementController.luau` normal movement path computes `loco.heading` and `forwardVector`, then calls:

```luau
hum:Move(dir, false)
```

without applying `loco.heading` to the horse root/rig during normal movement.

The only explicit yaw assignment is inside `turningInPlace`:

```luau
root.CFrame = CFrame.new(root.CFrame.Position) * CFrame.Angles(0, loco.heading, 0)
```

The MovementController comment says “AutoRotate vrider mot den”, but AutoRotate has been disabled by HorseService. These two modules therefore disagree about ownership of yaw.

### Player-facing consequence

The logical movement vector can curve while the actual horse rig does not turn with it. In Studio this can present as sideways/skating movement, incorrect horse facing, camera/animation mismatch or a rig that only visibly yaws during turn-in-place.

The current stub bench does not prove Humanoid/physical rig yaw in Studio.

### Required change

Choose one coherent yaw owner and make it explicit.

Recommended for this architecture: keep `AutoRotate = false` and have MovementController/RigAdapter apply the smoothed logical heading to the physical horse root during normal movement, while preserving vertical position and ground/slope behavior. Do not re-enable Roblox's uncontrolled snap rotation as a shortcut.

Do not write a new physics system.

### Required tests

1. Automated contract test: after a sustained steer input at walk/trot/canter, physical/root yaw must track `loco.heading` within a small tolerance.
2. Straight-line test: no yaw drift when steer = 0.
3. Direction reversal: left → right passes smoothly through neutral; no snap.
4. Turn-in-place still works and blends into forward movement without a discontinuity.
5. Roblox Studio evidence is still required after automated test.

---

## BLOCKER B — Web gait cycle length appears multiplied by hoof count twice

### Evidence

`src/model.js` computes `Gait.steglangd(...)` from horse/category scale and gait stride factor. For a horse-class mount near neutral state this is approximately:

- walk: `3.5 × 0.46` ≈ 1.61 m
- trot: `3.5 × 0.63` ≈ 2.21 m
- canter: `3.5 × 1.00` ≈ 3.50 m

These are already plausible full stride/cycle distances.

`src/game.js` then does:

```js
const CYKELSTEG={halt:0, skritt:4, trav:2, galopp:3};
const cykelLangd=G.ride.steglangd*stegPerCykel;
```

which turns those into roughly 6.4 m / 4.4 m / 10.5 m per animation phase cycle.

But `src/scen3d.js` uses one normalized `fas` cycle for each leg and offsets the four legs within that same phase. A single hoof already completes one stance+swing over phase 0..1. Therefore hoof count should not automatically multiply the travel distance of one animation cycle.

Roblox expresses the same concept differently and more plausibly:

```luau
cycleLength = gait.norm / gait.cycles
```

which is about 1.45 m / 2.13 m / 3.20 m at walk/trot/canter.

### Player-facing consequence

The new “ground-locked” phase can still visibly slide because the animation cycle advances much too slowly relative to actual distance. This directly violates Gate 01's hoof-contact acceptance criterion.

### Required change

Define one unambiguous term: **distance travelled per normalized animation phase cycle**.

Use that directly on both platforms. Do not derive web cycle length by multiplying a stride/cycle distance with `steps` unless a measured animation clip specifically proves that relationship.

Prefer a shared design table/derivation whose walk/trot/canter values can be compared numerically across web and Roblox.

### Required tests

1. Measure distance per complete `fas` 0→1 cycle at norm speed for walk/trot/canter on web and Roblox.
2. Values should be close enough to produce equivalent hoof timing, with intentional differences documented.
3. Run 10 m and 20 m straight-line tests and report number of animation cycles at each gait.
4. At zero actual displacement, phase must not advance.
5. Under collision/blocked movement, phase must follow actual displacement rather than requested speed.

---

## BLOCKER C — Audit commit traceability is incorrect

`audits/GATE-01-RIDING-FEEL-RESULT.md` says:

> `61d503d` (webben)

But `61d503d` is `Gör lektionshandledningen byggbar utan Drive`, not the Gate 01 web riding implementation.

The actual web riding commit is `33559d96e59b8ba7e88f2ba6a5ff7a71ab32c30b` (`Gate 01: ridinputkontrakt, sväng som kurvatur, fas låst till marken`).

### Required change

Correct the audit commit list and make every evidence table traceable to the actual implementation commit(s).

---

## Non-blocking observations

- The curvature-based steering direction is a significant improvement over speed-amplified direct yaw.
- Analog touch evidence on web is meaningful and should be retained.
- Rider secondary motion is deliberately subtle; that is the correct scope for this game.
- Lowering turn lean from 15° to about 4.3° is directionally correct and avoids motorcycle motion.
- `62462d1` touch-target cleanup is slightly outside the narrowest Gate 01 scope but small, low-risk and consistent with the cross-device product requirement; no rollback requested.
- Roblox touch remains unverified and must stay explicitly yellow until tested in Studio/device emulation.
- Camera feel in a 20 m circle/corners remains subjective and cannot be approved from code alone.

---

## Required Claude response

Implement only Blocker A, B and C. Do not add features.

Then update `audits/GATE-01-RIDING-FEEL-RESULT.md` with:

- Changed
- Why
- Tests
- Measurements
- Roblox Studio limitations/evidence
- Web/browser evidence
- Platform parity table
- Exact commit SHA(s)

After that, hand it back for **ChatGPT Senior Review 02**. Do not close Gate 01.
