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

The current runtime candidate is re-locked after the assigned-horse guide fix.

- Runtime HEAD: **`7fdee3061898456631a914c9902e2363c6fd33a1`**.
- Checklist: [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md).
- Roblox build identity `kallhash`: **`0ce4b14c93e2e7ef15e082c5dfd89120c010fa719099356f99b5c5a1f99540f7`**.
- In-game diagnostics must show prefix **`0ce4b14c93e2`**.
- Any later mapped Roblox-source change invalidates this lock and requires a new identity/checklist lock.

The candidate includes the reviewed lesson/teaching work, D1, D2a, D2b, D2c, D5 Option A/R1, B4a knockdown evidence, B4b R1 neutral disobedience evidence, B4c course-aware shadow judgment, D4a prize persistence foundation and the assigned-horse guide. Physical rows remain **NOT_TESTED** except where Tobias explicitly reports them.

## Physical gate A3

A3 is now in progress with Tobias.

Use only [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md). PC, physical iPad and physical iPhone remain separate evidence. Local tests, source review and emulator evidence do not mark physical rows PASS.

## Current #266 package status

### A — first pass
- A2 candidate lock: current and re-locked through assigned-horse guide.
- A3 physical PC/iPad/iPhone test: **IN PROGRESS**.

### B — riding feel and measurement
- **B4a knockdown event: CHATGPT_REVIEW_ACCEPTED.**
- **B4b R1 neutral disobedience evidence: CHATGPT_REVIEW_ACCEPTED.**
- **B4c course-aware shadow consumer: CHATGPT_REVIEW_ACCEPTED.**
- Remaining B4 gaps are physical or later-scope: real pole behaviour/replication/calibration, circle/track logic and any balking decision.
- Shadow judgment remains non-official until a separate reviewed promotion after physical evidence.

### C — teaching and learning
- Concrete feedback, selected comparisons, event-bound advice, free-practice framing and multiple task lessons are built.
- Less-guidance is built where source geometry supports it.
- Remaining gaps require product choice, persistence/schema work, new measurement or final physical judgment.

### D — competition day
- **D1 A: Clear Round base rule profile: CHATGPT_REVIEW_ACCEPTED.**
- **D2a clear-round training ride: CHATGPT_REVIEW_ACCEPTED through R2.**
- **D2b pre-ride flow: CHATGPT_REVIEW_ACCEPTED.**
- **D2c aftercare handoff: CHATGPT_REVIEW_ACCEPTED.**
- **D5 Option A competition clothing: CHATGPT_REVIEW_ACCEPTED through R1.**
- **D4a prize/trophy persistence foundation: CHATGPT_REVIEW_ACCEPTED.**
- Warm-up remains blocked on verified mapping of UBRF's real "Lilla utebanan" or an explicit Tobias game-simplification decision.
- Real Clear Round rosette award remains blocked until physical knockdown/refusal evidence is verified and D2 is explicitly promoted from shadow to official.

### Runtime blocker fixes during Tobias QA
- **Assigned-horse guide: CHATGPT_REVIEW_ACCEPTED.**
  - one local marker only, on the assigned horse;
  - large gold ▼ plus horse name;
  - visible from spawn, hidden close/leading/mounted;
  - survives respawn and delayed/replaced horse model;
  - Studio engine properties verified; human visual quality still requires Tobias.

## Limits

- No merge, publication or product acceptance is implied by source review.
- Do not award an official Clear Round rosette while knockdowns/refusals are not truthfully established.
- Do not let HinderObservation make course-aware sporting judgments.
- Do not promote B4c shadow output to official D2 judging without a separate review/decision.
- Do not silently map `UTEBANA` or `PADDOCK` to UBRF's "Lilla utebanan".
- Prize persistence may exist before awarding; no source path currently awards a real Clear Round prize.
- Competition results must stay deterministic, versioned and source-backed.

Historical gate material from #264 is preserved in [history/ACTIVE-GATE-20260926](history/ACTIVE-GATE-20260926.md).
