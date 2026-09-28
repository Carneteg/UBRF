# Active gate

Read [WORKING-AGREEMENT](WORKING-AGREEMENT.md) for roles, permissions and test policy.

Status date: 2026-09-28. This document records the current delivery gate. It is **not** product acceptance.

## Current active work

- Active issue: **#266** — riding quality, constructive teaching and competition-day progression.
- Active branch: **`codex/circle-lesson-20260926`**.
- PR #264 is merged at `7922d70090f3b968af23a9e080c0e5df1cfcb59a` and is historical. Do not resume its old implementation or closing gate.
- Current review model remains: **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**.
- Current standing delivery rule: **BUILD NOW / PHYSICAL TEST LAST**.

## Locked physical-test candidate

A2 is locked for the final physical playtest.

- Last runtime-mapped code commit in the candidate: **`19df5e69102866a67f3ea09936dcdd30915230ec`**.
- Candidate checklist: [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md).
- Roblox build identity `kallhash`: **`e23198df4614fbfdec56d2a7a5047c2a69e20fbcbc10563c5300faf49469a13e`**.
- The in-game diagnostic must show prefix **`e23198df4614`**. A different value is not this candidate.
- The branch may receive documentation-only commits without invalidating the runtime lock. Any change to a mapped Roblox source requires a new build identity and a new lock.

The candidate includes the reviewed #266 lesson/teaching work through the ground-pole less-guidance package. Local source/bench testing is green; the physical checklist remains **NOT_TESTED** until Tobias runs it.

## Physical gate A3

A3 is intentionally deferred until Tobias starts the final playtest.

Use only [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md) as the physical acceptance list. It covers PC, physical iPad and physical iPhone separately, including:

- spawn, stable and doors;
- care, equipment and leading;
- mounting and free practice;
- Ugneta and lesson navigation;
- every currently built lesson and the less-guidance variants;
- dismount, layout, respawn/reconnect;
- riding feel, clarity, learning and fun.

No checklist row is considered PASS from local tests, emulator evidence or source review alone.

## Current #266 package status

### A — first pass
- Source/build preparation: current.
- A2 candidate lock: **BUILT / CHATGPT review pending on the docs-only lock package**.
- A3 physical PC/iPad/iPhone test: **NOT_TESTED / LAST**.

### B — riding feel and measurement
- Existing riding core and multiple observed lesson facts are built.
- Remaining rhythm, canter-lead and fuller fence measurement require new observation/model work.
- Physical riding feel remains Tobias' acceptance call.

### C — teaching and learning
- Concrete feedback, selected improvement comparisons, event-bound advice, free-practice framing and multiple task lessons are built.
- Less-guidance is built for centre line/diagonal, corner, half-circle and ground pole.
- Serpentine/volt/halt/transitions/canter were intentionally not forced into a reduction where removing guidance would make the task ambiguous.
- Remaining C gaps require a product decision, persistence/schema work, or new measurement.

### D — competition day
- **Not started.**
- D1 is the next major delivery stage after the current candidate lock.
- Before D1 code, Tobias must choose the first competition class/rule profile. #266 currently recommends a clear-round training class before a judged class.

## Limits

- No merge, publication or product acceptance is implied by source review.
- Do not use physical Studio/iPad/manual play as an ad-hoc substitute for the locked A3 checklist.
- Do not invent measurements for rhythm, canter lead, rider body position or similar unobserved facts.
- Do not mechanically expand the less-guidance pattern where the remaining guide would become ambiguous.
- New web feature work remains paused unless a product decision changes that.
- Competition results must be deterministic, versioned and based on verified rule profiles before they can be accepted.

Historical gate material from #264 is preserved in [history/ACTIVE-GATE-20260926](history/ACTIVE-GATE-20260926.md).
