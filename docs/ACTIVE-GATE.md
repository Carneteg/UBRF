# Active Gate

Current active implementation: **P0 Grandstand / Läktare — issue #81, PR #114**

Primary builder: **Claude**
Review: **ChatGPT**
Product acceptance: **Tobias**

Mandatory delivery chain:

> **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**

## Current priority

Claude's active work is now **PR #114 / issue #81**. G02-C / PR #119 is `PRODUCT_ACCEPTED` and merged at `9f15475f4137984238325bd533a068684f9daa85`.

Do not start unrelated work while the grandstand P0 is active.

### Grandstand product requirement

The web and Roblox experiences must agree on the same physical grandstand truth:

- player can walk from ground level onto the grandstand without teleporting,
- avatar visibly rises with collision/floor height,
- steps are physically readable and walkable with keyboard and touch/joystick,
- deck stays opaque under the player,
- no yellow/transparent debug abstraction geometry in product view,
- player can move at least 10 m along the grandstand walkway,
- judge booth and seating must not block the usable walkway,
- exterior UBRF geometry stays locked unless a verified source requires a change,
- Vercel is the only UBRF preview/deploy path.

### Known root cause from failed attempts

The previous implementation proved that internal collision/path tests are not enough when rendering reads different state.

Claude must preserve these lessons:

1. `v3dFigurKloss` must use the same vertical player state as collision/camera (`o.y` / `VD.pz`), not hard-coded Y=0.
2. Review/debug geometry such as the yellow transparent stair abstractions must be dev/debug-only, never product-visible.
3. Canonical stair/deck geometry must live in the canonical site/world model, not as a late runtime patch.
4. Rendering, collision, camera and avatar height must be verified together in the actual player-facing path.
5. Web and Roblox must share the same intent/geometry contract rather than parallel truths.

The direct wrapper patch in `src/mobil.js` from the earlier #114 experiment is temporary evidence, not the desired final architecture. Claude should consolidate the real fix into the canonical implementation.

## Required Claude handshake

A GitHub mention alone is not proof that the active Claude session received the task.

Before implementation begins, Claude must post in PR #114:

`CLAUDE_ACK #114 — base/head <SHA> — scope: P0 läktare, fysisk trappa, korrekt avatarhöjd/sikt, web+Roblox`

Only after that ACK is the handoff considered delivered.

When ready for review Claude must post:

- exact HEAD SHA,
- Changed,
- Tested,
- Falsified,
- Not tested,
- Remaining risk,
- human-test requirements,
- `READY_FOR_CHATGPT_REVIEW`.

No merge before ChatGPT review and Tobias product test.

## Accepted / follow-up work

### G02-C / PR #119

`PRODUCT_ACCEPTED` by Tobias and merged. Issue #84 is closed.

Known accepted follow-up debt is tracked in **issue #126**:
- full Roblox Ugneta production wiring,
- physical Ugneta coach at the arena fence in Roblox.

Issue #126 is not the active P0 and must wait until the grandstand is resolved unless Tobias explicitly reprioritizes it.

### PR #116 — Lydia pronoun

Separate technically green language decision. Do not spend active implementation cycles on it unless Tobias reprioritizes it.

## Source-of-truth rule

If this document conflicts with Tobias's newer explicit instruction, Tobias wins and this file must be updated immediately.

If PR comments and this file disagree and there is no newer Tobias instruction, stop implementation and reconcile the task before coding.
