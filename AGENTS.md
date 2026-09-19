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

### Jules — Optional falsification agent, evidence only

Jules is **not** a second lead implementer, **not** a second reviewer, and **never a blocking delivery gate**. Independent review belongs to ChatGPT. Jules is invoked task by task, for one bounded question at a time, and owns nothing standing.

**A Jules deliverable is evidence a gate can judge — never prose.** A written opinion about the code cannot be falsified, and this repository does not accept unfalsifiable claims as evidence. A report that merely asserts that the suites were run is not a deliverable.

Jules may deliver:

1. a failing regression test that reproduces a suspected defect on the frozen head,
2. a narrow fix plus the test that proves it, when the task explicitly asks for a fix,
3. one named red gate turned green, with the exit code as the receipt,
4. an exact reproduction command chain for a defect it could not turn into a test, including what was `Not tested`.

`QA_REPORT_READY` requires at least one of those four.

Jules must not:

- redesign the active feature,
- expand scope,
- silently change product/game-feel tuning,
- touch geometry, web/Roblox parity, horse canon or facility facts — anything that needs UBRF reality is outside what Jules can verify,
- invent UBRF spatial or horse facts,
- merge its own work,
- mark `PRODUCT_ACCEPTED`,
- work in files Claude has open on the active gate.

## Locked delivery chain

**CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**

Jules is an optional sidecar lane, not part of the mandatory chain. Delivery must not wait for Jules to start, finish or recover from a stalled task.

When Jules is invoked it runs **parallel with ChatGPT review, never before it**:

CLAUDE BUILDS → `READY_FOR_CHATGPT_REVIEW` → head frozen → (optional) JULES FALSIFIES → CHATGPT REVIEWS → TOBIAS ACCEPTS

- Never while Claude is still building: moving target, same core files.
- Never after `PRODUCT_ACCEPTED`: no purpose left.
- Jules findings are additional evidence inside ChatGPT review, never a substitute for it.
- Confirmed defects still need to be resolved.
- A stalled, duplicated or outdated Jules task is cancelled; the main chain continues.

No agent may both introduce a major change and independently grant final approval for that same change. Jules writing the test that tries to fell Claude's work strengthens that separation; Jules reviewing Claude's work in prose does not.

Status authority:

- Builder maximum: `READY_FOR_CHATGPT_REVIEW`
- Jules maximum: `QA_REPORT_READY` or a focused PR for a confirmed defect
- ChatGPT may set: `READY_FOR_PRODUCT_ACCEPTANCE`
- Only Tobias may set: `PRODUCT_ACCEPTED`

Green CI, a mergeable PR or a passing local test suite is not product acceptance.

## How Jules is invoked

One entry point: **a GitHub issue labelled `jules`**, carrying a named file scope, the frozen head and one concrete suspicion. No such issue, no Jules task.

Every Jules PR must carry the `jules` label. Jules PRs are opened under Tobias' account, so the label is the only mechanical way to find existing Jules work — and the duplicate preflight below depends on being able to find it.

Autonomous Jules modes are **off for this repository and stay off**:

- **Suggestions** — self-directed batch fix proposals. They produced ~20 parallel PRs in the same core files, which is exactly the scope expansion and duplication this document forbids.
- **CI Auto-Fixer** — automatic patching of red CI. The gates here are deliberately fail-closed; an agent that turns one green on its own destroys the evidence the gate exists to produce.
- **Scheduled sessions** — recurring open-ended passes over the repository. An open-ended prompt cannot produce bounded evidence.

Turning any of them back on is a product decision for Tobias, not a convenience setting.

### Mandatory duplicate preflight — before Jules starts work

Before Jules creates a task, branch, commit or PR, it **must** search the repository for existing work covering the same root cause, function, file set or acceptance claim.

Minimum preflight:

1. search open PRs and issues for the same function/file/symptom/root cause,
2. inspect existing `jules`-labelled PRs/tasks that touch the same code path,
3. compare the intended change against already-open work, not just titles,
4. if substantially overlapping work exists, **do not create a new branch or PR**.

If overlap is found:

- reuse or comment on the existing issue/PR,
- add evidence/tests to the existing thread only when explicitly useful,
- otherwise stop and report `DUPLICATE — existing #<number>`,
- if two Jules tasks already exist for the same concern, the **newer one is stopped/closed** unless Tobias or ChatGPT explicitly says otherwise.

Hard rule: **one active Jules task/PR per root cause/code path.** Different wording, benchmark framing or test style does not make duplicate work unique.

Examples that count as duplicates:

- two PRs caching the same `ryktChipp(W,H)` allocation path,
- two PRs replacing the same `S.rader.find(...)` render-loop lookup,
- a new QA task for the same PR/head while an existing Jules QA task is still open.

### Task shape

A Jules task names the frozen head, the file scope, the suspicion and the expected evidence. For an existing PR:

> Falsify PR <number> at head <sha>. Scope: <files>. Suspicion: <one concrete mechanism>. Deliver a failing regression test that reproduces it, or the exact command chain showing it cannot be reproduced. Do not redesign the feature, do not change product tuning, do not merge, do not touch geometry or horse canon.

For a bug/CI task, Jules may implement a narrow fix on its own branch, but it must stay within the issue's acceptance contract and ship the test with it.

If Jules becomes slow, stale, duplicates another task or opens a PR from an outdated base, stop that task rather than blocking delivery.

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
