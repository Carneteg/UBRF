# Active Gate

Current active implementation: **G02-C — Training & Feedback Engine / Ugneta**

Primary implementation PR: **#119**
Primary builder: **Claude**
Review: **ChatGPT**
Product acceptance: **Tobias**

Mandatory delivery chain:

> **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**

## Current priority

Claude's active work is **PR #119**. Do not continue implementation work on older/stale PRs unless Tobias explicitly re-prioritizes them.

Current product direction for G02-C:

- instructor name: **Ugneta**,
- Ugneta is an older woman with gray hair and glasses,
- UX direction = combine **variant 1 + variant 3**,
- Ugneta is physically present by the arena fence during the lesson,
- live riding feedback is short and sparse,
- main pedagogical feedback happens between attempts,
- attempt 1 → attempt 2 must be a real production-flow comparison,
- feedback must be derived from actual telemetry/state, never random or fabricated,
- 20 m circle evaluates **line + rhythm + balance**,
- transitions evaluate **timing + softness + horse response**,
- at most two prioritized observations after an attempt,
- safety messages always override instructor feedback,
- responsive UX must preserve the riding view on mobile, tablet and desktop,
- Roblox and web must share the same assessment intent/contract,
- Roblox remains the primary game platform,
- preview/deploy for UBRF uses **Vercel only**.

Reference UX images are linked in PR #119, comment `5560006564`.
Latest builder directive is in PR #119, comment `5560081926`.

## Required Claude handshake

A GitHub `@claude` mention is **not considered proof that the active Claude session received the task**.

Before implementation begins, Claude must post in the active PR:

`CLAUDE_ACK #119 — base/head <SHA> — scope: G02-C Ugneta UX 1+3, försök 1→2, Roblox-paritet`

Only after that ACK is the handoff considered delivered.

When implementation is ready, Claude must post:

- exact HEAD SHA,
- Changed,
- Tested,
- Falsified,
- Not tested,
- Remaining risk,
- human-test requirements,
- `READY_FOR_CHATGPT_REVIEW`.

ChatGPT then reviews the actual diff and evidence. Tobias alone sets `PRODUCT_ACCEPTED` where human acceptance is required.

## Explicitly not active for Claude

### PR #116 — Lydia pronoun

Technically green and separate. It is waiting on Tobias's decision. Claude must not spend active implementation time or repeated monitoring cycles on it unless Tobias reopens the task.

### PR #114 / issue #81 — grandstand P0

Separate problem track. Claude should read the staircase postmortem as a lesson, but **must not overlap #119 implementation with grandstand code** unless Tobias/ChatGPT explicitly hands it back.

Key lesson from the grandstand failure:

- internal state/path tests are insufficient when rendering uses another truth,
- avatar/render/collision must agree on spatial state,
- debug geometry must never leak into the player view,
- verify the real player-facing chain, not just helper functions.

## Completed prerequisite

G02-B is `PRODUCT_ACCEPTED` and merged. G02-C may rely on its telemetry and rider-aid contract but must not retune G02-B game feel without a new explicit product decision.

## Source-of-truth rule

If this document conflicts with Tobias's newer explicit instruction, Tobias wins and this file must be updated immediately.

If PR comments and this file disagree and there is no newer Tobias instruction, **stop implementation and reconcile the task before coding**. Do not silently choose an older task.

## Historical gates

Older G01/F01 material remains valid historical/reference evidence in their respective gate documents, PRs and commits, but it is **not the current Claude execution priority**.
