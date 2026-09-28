# Active gate

Read [WORKING-AGREEMENT](WORKING-AGREEMENT.md) for roles, permissions and test policy.

Status date: 2026-09-28. This document records the current delivery gate. It is **not** product acceptance.

## Current active work

- Active issue: **#266** — riding quality, constructive teaching and competition-day progression.
- Active branch: **`codex/circle-lesson-20260926`**.
- PR #264 is merged at `7922d70090f3b968af23a9e080c0e5df1cfcb59a` and is historical.
- Review model: **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**.
- Standing delivery rule: **BUILD NOW / PHYSICAL TEST LAST**.
- Coordination source of truth: GitHub issue #266 + the remote branch. Claude handoff marker: **`HANDOFF_READY_FOR_CHATGPT`**.

## Locked physical-test candidate

The current runtime candidate is re-locked after D2b.

- Runtime HEAD: **`56c092041c3585ede58e93c1f8c5c96f4ff1c3d6`**.
- Checklist: [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md).
- Roblox build identity `kallhash`: **`b22335d27996dd18feb11e09d36b3797f840291412a02cabc287fcadc2addb40`**.
- In-game diagnostics must show prefix **`b22335d27996`**.
- Any later mapped Roblox-source change invalidates this lock and requires a new identity/checklist lock.

The candidate includes the reviewed lesson/teaching work, D1, D2a and D2b pre-ride flow. Physical rows remain **NOT_TESTED**.

## Physical gate A3

A3 remains deferred until Tobias starts the final physical test.

Use only [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md). PC, physical iPad and physical iPhone remain separate evidence. Local tests, source review and emulator evidence do not mark physical rows PASS.

## Current #266 package status

### A — first pass
- A2 candidate lock: current and re-locked through D2b.
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
  - entry/registration is session-only;
  - solo start list: start number 1, one entered;
  - course-plan card is server-data-driven and explicitly a simplification of walking the course;
  - no warm-up is claimed or mapped while `references/site/BANIDENTITET.md` remains unresolved;
  - start is refused before the course-plan state.
- Remaining D2: warm-up, prize-giving and aftercare.
- Warm-up is blocked on verified mapping of UBRF's real "Lilla utebanan" or an explicit Tobias game-simplification decision.
- Prize-giving / real Clear Round rosette remain blocked on B4/D4.
- D4 prize persistence/trophy cabinet and D5 competition clothing are not built.

## Limits

- No merge, publication or product acceptance is implied by source review.
- PHYSICAL TEST remains LAST unless Tobias changes that order.
- Do not award an official Clear Round rosette while knockdowns/refusals are not truthfully observable.
- Do not silently map `UTEBANA` or `PADDOCK` to UBRF's "Lilla utebanan".
- Do not invent measurements for rhythm, canter lead, rider body position or unobserved fence events.
- New web feature work remains paused unless a product decision changes that.
- Competition results must stay deterministic, versioned and source-backed.

Historical gate material from #264 is preserved in [history/ACTIVE-GATE-20260926](history/ACTIVE-GATE-20260926.md).
