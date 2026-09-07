# Active Gate

Current active implementation: **G02-C follow-up — Roblox Ugneta, issue #126, PR #128**.

Primary builder: **Claude**
Review: **ChatGPT**
Product acceptance: **Tobias**

Mandatory delivery chain:

> **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**

## Current priority

The grandstand P0 is resolved. Tobias confirmed on 2026-09-07 that the stairs work in the playable preview. PR #114 is PRODUCT_ACCEPTED and merged at `e65675dfe3584f5654aab3280d53692fe9b17f1a`; issue #81 is closed.

The next priority is the already existing PR #128 for issue #126. Do not create a duplicate implementation PR or start G02-D before this follow-up is reviewed and resolved.

### Required Roblox Ugneta completion

- Connect `UgnetaController` to the actual Roblox lesson/telemetry lifecycle, not test-only helpers.
- Drive live cues, attempt 1 → 2, reset, comparison and safety takeover from real production state.
- Use HorseCore/Telemetri and the exported RidKanon/Ugneta contract as the shared source of truth. Missing measurements must remain missing, never fabricated as zero or a made-up score.
- Show Ugneta physically at the arena fence as the recognizable older woman with gray hair and glasses, without inventing unsupported UBRF geometry.
- Preserve the approved UX 1+3: short live cues while riding, substantive feedback between attempts, and safety before instruction.
- Prove the actual client path and falsify missing lifecycle hooks, stale UI after dismount, and unsupported measurements.
- Keep web behavior and accepted lessons intact. No unrelated horse-tuning, geometry redesign, or duplicate riding engine.
- Vercel is the only UBRF preview/deploy platform. Roblox Studio runtime and physical touch tests must be reported as Not tested until actually performed.

### Existing work and review handoff

PR #128 already exists on `claude/g02-c-followup-126` and claims READY_FOR_CHATGPT_REVIEW. Reuse it. Claude must reconcile its base with the accepted main before further implementation, preserve the grandstand fix, and resolve any actual conflicts. Do not treat a mergeable metadata field or green CI as proof of product acceptance.

Post in #128:

`CLAUDE_ACK #128 — base/head <SHA> — scope: #126 Roblox Ugneta production lifecycle, physical coach, telemetry and safety`

Then provide exact HEAD SHA, Changed, Tested, Falsified, Not tested, Remaining risk, human-test requirements and READY_FOR_CHATGPT_REVIEW. No merge before ChatGPT review and Tobias acceptance of the relevant Roblox experience.

## Accepted baseline and remaining work

### G02-C / PR #119

PRODUCT_ACCEPTED and merged at `9f15475f4137984238325bd533a068684f9daa85`. Issue #84 closed. The accepted web teaching experience and its source contract remain the baseline. #126 is the explicitly tracked Roblox follow-up, not permission to reopen the accepted web scope.

### Grandstand / PR #114 / issue #81

PRODUCT_ACCEPTED after Tobias's actual web test and merged at `e65675dfe3584f5654aab3280d53692fe9b17f1a`. Issue #81 closed. Preserve the following root-cause lessons:

1. Avatar rendering, collision, camera and navigation must read the same canonical vertical state.
2. Canonical stair/deck geometry belongs in site/world data, never a late runtime patch.
3. Debug/SPELABSTRAKTION markers are dev-only; physical product surfaces remain solid and readable.
4. Cutaway must account for the player's level and cannot remove the surface under their feet.
5. Tests must exercise the real player-facing route and include negative mutations; green pathfinding alone is insufficient.
6. Web and Roblox share the same spatial intent. No parallel geometry truth.

Roblox Studio and physical-device touch validation were not independently completed in this review. Any specific remaining regression should be recorded separately without undoing Tobias's accepted web result.

### PR #116 — Lydia pronoun

Separate technically green language decision. Keep parked until Tobias reprioritizes it. Do not spend active implementation cycles on it while #126 is being resolved.

### Following gate

After #126 is accepted, run an end-to-end Roblox-first playable-slice review before expanding progression in G02-D. Confirm the full stable → horse preparation → riding lesson → feedback → second attempt → return/aftercare loop, keyboard/touch and web/Roblox consistency. Prioritize verified defects rather than inventing new scope.

## Source-of-truth and delivery rules

Read `CLAUDE.md`, product canon, delivery protocol, AI collaboration rules and this active gate before work. Tobias's newer explicit decisions take precedence over older instructions. If PR comments and this file conflict without a newer Tobias decision, stop and reconcile before coding.

A GitHub mention alone is not proof of delivery to an active Claude session. An explicit ACK confirms receipt; commits and tests confirm implementation. Only Tobias can give PRODUCT_ACCEPTED. Never claim unseen runtime, device, visual or deployment checks were performed.
