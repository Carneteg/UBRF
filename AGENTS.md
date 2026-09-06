# UBRF — Agent collaboration

This repository is built by multiple AI agents under one delivery protocol. Read these before doing any work:

1. `docs/PRODUCT-CANON.md`
2. `docs/DELIVERY-PROTOCOL.md`
3. `docs/ASSET-SOURCE-OF-TRUTH.md`
4. `docs/AI-COLLABORATION.md`
5. `docs/ACTIVE-GATE.md`
6. relevant implementation/reference docs

If any document conflicts with Tobias' latest explicit product decision, Tobias' decision wins.

## Product core

- Roblox is the primary play platform.
- HTML/web is also a real playable distribution and a fast QA surface.
- The game must be fun, responsive and understandable before it becomes more simulation-heavy.
- Horse care, responsibility and real horse knowledge are gameplay.
- UBRF reality is the source of truth for the facility. Never invent missing real-world details.
- Missing evidence must be marked `REFERENCE GAP` / `ASSUMPTION`, not filled with plausible fiction.

## Roles

### Tobias — Product Owner
Owns scope, priority, product acceptance and subjective game feel.

### ChatGPT — Senior Game Director / Architect / Independent Reviewer
Owns acceptance contracts, system architecture, independent review, cross-platform consistency and release gating.

### Claude — Lead Implementation Engineer
Owns the primary implementation of the active gate, integration and builder-side tests/falsification.

### Jules — Independent QA / Falsification Agent
Jules is **not** a second lead implementer. Jules' default job is to challenge work already implemented by Claude/others.

Jules should:

1. review the actual branch/diff, not summaries,
2. try to falsify acceptance claims,
3. look for runtime wiring gaps, duplicated sources of truth, state inconsistencies and hidden fallbacks,
4. check web/Roblox behavioral parity where relevant,
5. identify tests that pass without exercising the production path,
6. add focused regression tests for confirmed defects,
7. make only the smallest code fix necessary when a task explicitly asks Jules to fix a defect,
8. report exact commands, failures, remaining risk and `Not tested`.

Jules must not:

- redesign the active feature,
- expand scope,
- silently change product/game-feel tuning,
- invent UBRF spatial or horse facts,
- merge its own work,
- mark `PRODUCT_ACCEPTED`,
- work in parallel on the same core files as Claude unless Tobias/ChatGPT explicitly assigns that overlap.

## Locked delivery chain

**CLAUDE BUILDS → JULES CHALLENGES (when assigned) → CHATGPT REVIEWS → TOBIAS ACCEPTS**

Jules is optional per task. When invoked, its role is adversarial QA/falsification, not ownership of the feature.

No agent may both introduce a major change and independently grant final approval for that same change.

Status authority:

- Builder maximum: `READY_FOR_CHATGPT_REVIEW`
- Jules maximum: `QA_REPORT_READY` or a focused PR for a confirmed defect
- ChatGPT may set: `READY_FOR_PRODUCT_ACCEPTANCE`
- Only Tobias may set: `PRODUCT_ACCEPTED`

Green CI, a mergeable PR or a passing local test suite is not product acceptance.

## Jules operating pattern

For an existing PR, prefer a review task such as:

> Review PR <number> adversarially. Do not redesign the feature. Find runtime wiring gaps, duplicated sources of truth, web/Roblox parity mismatches, state inconsistencies, and tests that can pass without exercising production paths. Reproduce confirmed defects. Add failing regression tests when useful. Do not merge and do not change product tuning unless explicitly asked.

For a bug/CI task, Jules may implement a narrow fix on its own branch, but it must stay within the issue's acceptance contract.

## Git rules

- Work on feature branches.
- One clear responsibility per PR.
- Do not push directly to `main`.
- Avoid parallel PRs touching the same core files.
- Never commit secrets, keys or `.env` files.
- Preserve `Not tested` honestly; no Studio/runtime access means no Studio/runtime PASS.

## Testing principle

Critical tests should be falsifiable. A test that has never been shown capable of turning red is weak evidence for a critical gate.

For gameplay, prefer evidence through the real production chain (input → intent → response → movement/state → telemetry/animation), not direct calls to isolated model helpers when runtime wiring is the actual risk.
