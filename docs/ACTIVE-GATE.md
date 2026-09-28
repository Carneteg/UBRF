# Active gate

Read [WORKING-AGREEMENT](WORKING-AGREEMENT.md) for roles, permissions and test policy.

Status date: 2026-09-28. This document records the current delivery gate. It is **not** product acceptance.

## Current active work

- Active issue: **#266** — riding quality, constructive teaching and competition-day progression.
- Active branch: **`codex/circle-lesson-20260926`**.
- PR #264 is merged at `7922d70090f3b968af23a9e080c0e5df1cfcb59a` and is historical.
- Review model: **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**.
- Standing delivery rule: **BUILD NOW / PHYSICAL TEST LAST**.
- Coordination source of truth: GitHub issue #266 + the remote branch.
- Claude review handoff marker: **`HANDOFF_READY_FOR_CHATGPT`**.

## Locked physical-test candidate

The current runtime candidate is re-locked after D2c.

- Runtime HEAD: **`ff8fd2611e054386e7256b178dd12466e091634f`**.
- Checklist: [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md).
- Roblox build identity `kallhash`: **`93f07144a1b5d1de55f3dc0da75876374a0629dd2cfd111ab1def9c208be88c7`**.
- In-game diagnostics must show prefix **`93f07144a1b5`**.
- Any later mapped Roblox-source change invalidates this lock and requires a new identity/checklist lock.

The candidate includes the reviewed lesson/teaching work, D1, D2a, D2b and D2c aftercare handoff. Physical rows remain **NOT_TESTED**.

## Physical gate A3

A3 remains deferred until Tobias starts the final physical test.

Use only [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md). PC, physical iPad and physical iPhone remain separate evidence. Local tests, source review and emulator evidence do not mark physical rows PASS.

## Current #266 package status

### A — first pass
- A2 candidate lock: current and re-locked through D2c.
- A3 physical PC/iPad/iPhone test: **NOT_TESTED / LAST**.

### B — riding feel and measurement
- Existing riding core and multiple lesson observations are built.
- Remaining rhythm, canter-lead and full fence-event measurement require new observation/model work.
- B4 knockdown/refusal detection remains missing; therefore D2 uses simplified judging and cannot award a real Clear Round rosette.

### C — teaching and learning
- Concrete feedback, selected comparisons, event-bound advice, free-practice framing and multiple task lessons are built.
- Less-guidance is built where source geometry supports it.
- Remaining gaps require product choice, persistence/schema work, new measurement or final physical judgment.

### D — competition day
- **D1 A: Clear Round base rule profile: CHATGPT_REVIEW_ACCEPTED.**
- **D2a clear-round training ride: CHATGPT_REVIEW_ACCEPTED through R2.**
- **D2b pre-ride flow: CHATGPT_REVIEW_ACCEPTED.**
- **D2c aftercare handoff: CHATGPT_REVIEW_ACCEPTED.**
  - result snapshot exposes existing canonical aftercare steps only after a completed result;
  - result card reads the server-provided canonical step names;
  - existing pass lifecycle handles dismount → aftercare → counted once;
  - an aborted mid-course ride still enters aftercare, without becoming a competition success or prize.
- Warm-up remains blocked on verified mapping of UBRF's real "Lilla utebanan" or an explicit Tobias game-simplification decision.
- Prize-giving / real Clear Round rosette remain blocked on B4/D4.
- D5 competition clothing exists as an unconsumed service and is the next likely source-testable branch once Tobias chooses the product behaviour.

## Limits

- No merge, publication or product acceptance is implied by source review.
- PHYSICAL TEST remains LAST unless Tobias changes that order.
- Do not award an official Clear Round rosette while knockdowns/refusals are not truthfully observable.
- Do not silently map `UTEBANA` or `PADDOCK` to UBRF's "Lilla utebanan".
- Do not invent measurements for rhythm, canter lead, rider body position or unobserved fence events.
- New web feature work remains paused unless a product decision changes that.
- Competition results must stay deterministic, versioned and source-backed.

Historical gate material from #264 is preserved in [history/ACTIVE-GATE-20260926](history/ACTIVE-GATE-20260926.md).
