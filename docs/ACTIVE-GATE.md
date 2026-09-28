# Active gate

Read [WORKING-AGREEMENT](WORKING-AGREEMENT.md) for roles, permissions and test policy.

Status date: 2026-09-28. This document records the current delivery gate. It is **not** product acceptance.

## Current active work

- Active issue: **#266** — riding quality, constructive teaching and competition-day progression.
- Active branch: **`codex/circle-lesson-20260926`**.
- PR #264 is merged at `7922d70090f3b968af23a9e080c0e5df1cfcb59a` and is historical.
- Review model: **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**.
- Standing delivery rule: **BUILD NOW / PHYSICAL TEST LAST**.

## Locked physical-test candidate

The current runtime candidate is re-locked after D2a/R2.

- Runtime HEAD: **`94b91a2282f8849540e70f7fcc4f3ac7eb3c8fb9`**.
- Checklist: [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md).
- Roblox build identity `kallhash`: **`5a7d81b058276a0a67d786af61677e198b1b8df308d65c6e7a9ca28aa911d34b`**.
- In-game diagnostics must show prefix **`5a7d81b05827`**.
- Any later mapped Roblox-source change invalidates this lock and requires a new identity/checklist lock.

The candidate includes the reviewed lesson/teaching work plus D1 and the current D2a clear-round training ride. Physical rows remain **NOT_TESTED**.

## Physical gate A3

A3 remains deferred until Tobias starts the final physical test.

Use only [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md). PC, physical iPad and physical iPhone remain separate evidence. Local tests, source review and emulator evidence do not mark physical rows PASS.

## Current #266 package status

### A — first pass
- A2 candidate lock: current and re-locked after D2a/R2.
- A3 physical PC/iPad/iPhone test: **NOT_TESTED / LAST**.

### B — riding feel and measurement
- Existing riding core and multiple lesson observations are built.
- Remaining rhythm, canter-lead and full fence-event measurement require new observation/model work.
- B4 knockdown/refusal detection remains missing; therefore D2a uses simplified judging and cannot award a real Clear Round rosette.

### C — teaching and learning
- Concrete feedback, selected comparisons, event-bound advice, free-practice framing and multiple task lessons are built.
- Less-guidance is built where source geometry supports it.
- Remaining gaps require product choice, persistence/schema work, new measurement or final physical judgment.

### D — competition day
- **D1 A: Clear Round base rule profile: CHATGPT_REVIEW_ACCEPTED.**
- **D2a clear-round training ride:** built and source-reviewed through R2.
  - course: blue → red → blue → red;
  - simplified judging only;
  - never claims `felfri`;
  - no Clear Round rosette until B4 can observe knockdowns/refusals truthfully;
  - mid-course ride-end is terminalized as `avbruten`, with truthful cause text.
- Remaining D2: entry/registration, start list, course walk, warm-up, prize-giving and aftercare.
- D4 prize persistence/trophy cabinet and D5 competition clothing are not built.
- Real Clear Round rosettes remain a later earned prize once B4 supports truthful fault-free judging.

## Limits

- No merge, publication or product acceptance is implied by source review.
- PHYSICAL TEST remains LAST unless Tobias changes that order.
- Do not award an official Clear Round rosette while knockdowns/refusals are not truthfully observable.
- Do not invent measurements for rhythm, canter lead, rider body position or unobserved fence events.
- New web feature work remains paused unless a product decision changes that.
- Competition results must stay deterministic, versioned and source-backed.

Historical gate material from #264 is preserved in [history/ACTIVE-GATE-20260926](history/ACTIVE-GATE-20260926.md).
