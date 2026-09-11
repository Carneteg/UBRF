# Active Gate

Current active implementation: **First Playable stabilization — issue #161 / PR #162**

Primary builder: **Claude**
Review: **ChatGPT**
Product acceptance: **Tobias**

Mandatory delivery chain:

> **CLAUDE BUILDS → AUTOMATED + STUDIO PRE-TOBIAS GATES → CHATGPT REVIEWS → TOBIAS ACCEPTS**

## Current priority

The previous P0 grandstand gate (#81 / PR #114) is **PRODUCT_ACCEPTED and merged** on `main` in `e65675dfe3584f5654aab3280d53692fe9b17f1a`. It is no longer the active implementation gate.

The active priority order is now:

1. **P0 safety / basic playability** — no void deaths, broken startup, blocked entrances, impossible exits or dead-end critical routes.
2. **Topology / traversal correctness** — doors and gates must lead to the correct real-world zone; no portal may lead into a box or wall when the real route is a corridor/pass-through.
3. **First-day core loop** — spawn → stable → assigned horse → care/equipment → yard → arena → ride → return/aftercare → save/reconnect.
4. **Environment fidelity** — orientation/handedness, canonical signs, props, floor/terrain boundaries and real UBRF spatial truth.
5. **Polish** — presentation, feel and non-blocking visual refinement.

Do not start unrelated feature work while these First Playable blockers remain open.

## Hard pre-Tobias release bar

No new `.rbxlx` may be presented to Tobias until the exact candidate has passed the complete `PRE_TOBIAS_FIRST_PLAYABLE_GATE`.

At minimum this combines:

- `FIRST_PLAYABLE_PREFLIGHT`
- `END_TO_END_PLAYABILITY_GATE`
- `NO_VOID_BASIC_PLAYABILITY_GATE`
- `BUILDING_TOPOLOGY_TRAVERSAL_GATE`
- `PHYSICAL_WORLD_COHERENCE_GATE`
- localization and full-horse roster gates
- artifact/source identity checks

Every real defect found by Tobias in a previous Studio build must become a permanent regression/mutation test where technically possible.

## Roblox Studio MCP role

A local Roblox Studio MCP is available on Tobias's Windows machine through `@chrrxs/robloxstudio-mcp` v3.1.3. It is intentionally local-only and cannot be reached from cloud Claude sessions.

Therefore:

- cloud Claude may implement, analyze and prepare candidates,
- **local Claude Code + Roblox Studio MCP is the pre-Tobias runtime/physical QA executor**,
- a cloud-only green CI result is not sufficient to authorize Tobias testing,
- the local Studio pass must run against the exact candidate/source SHA and record failures before handoff.

Do not rely on any `roblox-game` Claude skill until it has been audited against the Chrrxs 3.x MCP API; the old skill may contain obsolete 2.x tool names.

## Branch / PR hygiene

Do **not** keep extending a long stack of PRs based on other unmerged PR branches.

For the First Playable stabilization:

- consolidate the required accepted/fixed work into one clean integration line,
- do not merge the stale `chatgpt/fix-doors-spawn` branch wholesale into `main`,
- selectively recover only still-needed commits/changes after comparing them to current First Playable work,
- do not create new stacked PRs above the current unresolved chain,
- no merge to `main` before ChatGPT review and Tobias product acceptance where required.

## Source-of-truth rule

If this document conflicts with Tobias's newer explicit instruction, Tobias wins and this file must be updated immediately.

If PR comments and this file disagree and there is no newer Tobias instruction, stop implementation and reconcile the task before coding.
