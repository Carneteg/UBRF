# Active work

Read [WORKING-AGREEMENT](WORKING-AGREEMENT.md) for current roles, permissions
and test policy. This index is dated 2026-09-26; it is not product acceptance.

## Current state

- PR #264 is merged (2026-09-26 15:44:31 UTC), merge
  7922d70090f3b968af23a9e080c0e5df1cfcb59a. Handover is confirmed.
  Do not resume its old implementation, closeout or human-QA order.
- Delivery-tools candidate c9be9c44276de3aaaabe0720fef0b4b5ed6472a5 on
  codex/delivery-checks-20260926 has independent code review and all 42
  shared checks passing locally in isolation. No new remote PR or Linux CI
  is implied; the tools branch remains frozen.
- Documentation cleanup is reviewed on24eae8df2eb5477f01d22c728d8b3b68037d3ade:
  [independent PASS](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5848620485).
  Its branch remains preserved; nonblocking rest items are in
  [CLEANUP-20260926](CLEANUP-20260926.md).
- Current bounded work: the newly approved end-to-end circle lesson, using existing
  VOLT1/FORSOK1. Freeze new infrastructure, including INFRA-3. Define the
  lesson contract, feedback and visible outcome before code; Claude reviews.
  See the latest decision in [WORKING-AGREEMENT](WORKING-AGREEMENT.md).
  Branch codex/circle-lesson-20260926; the
  [lesson contract](CIRCLE-LESSON-CONTRACT.md) received conditional design PASS
  on00ec03a ([result](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5848762860)).
  Circle candidate e2a800b received independent BANK_ONLY code PASS
  ([result](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5852847754))
  and all 42 shared checks passed locally. Codex now performs the authorized
  bounded unpublished Studio check, not Tobias. Startup and door interaction
  were observed; the lesson itself is not yet engine-verified.
  The test found an opaque static interior door face hiding the opened entrance.
  Current correction is limited to [DOOR-VISUAL-CONTRACT](DOOR-VISUAL-CONTRACT.md):
  attach moving visual details to the existing leaf, preserve the fixed frame.
  Exact-candidate review and a new local visual check are required. No publication
  or product acceptance.
- 2026-09-27 10:40 UTC: build now, test last (WORKING-AGREEMENT). Circle finish
  cbd6499 is BUILT_NOT_VERIFIED. Start/Halt ([contract](HALT-LESSON-CONTRACT.md),
  halt at X) is built on it, BUILT_NOT_VERIFIED; its spec is written, not run.
  Start/Halt R1 (b6177ce) passed Codex source review only. Transitions
  ([contract](TRANSITION-LESSON-CONTRACT.md), trot at T1 and walk at T2 on the
  centre line) is built on it, BUILT_NOT_VERIFIED; its spec is written, not run.
  Transitions e31eb1f passed Codex source review only. The training serpentine
  ([contract](SERPENTINE-LESSON-CONTRACT.md), three loops A → C with ordered
  centre-line crossings) is built on it, BUILT_NOT_VERIFIED; spec written, not run.
  Serpentine R1 49788ea passed Codex source review only. Steady walk
  ([contract](TEMPO-LESSON-CONTRACT.md), steady observed speed in walk, not hoof
  rhythm) is built on it, BUILT_NOT_VERIFIED; spec written, not run.
  Tempo 96da81b passed Codex source review only. Riding paths
  ([contract](RIDING-PATH-LESSON-CONTRACT.md), centre line and diagonal) are built
  on it, with the lesson menu grouped to at most four choices per page;
  BUILT_NOT_VERIFIED, spec written, not run. Riding-paths R1 b6dbbad passed
  Codex source review only. The half-circle back to the track
  ([contract](HALF-CIRCLE-LESSON-CONTRACT.md)) is built on it, with a
  "Centre line and diagonal" subgroup under Riding paths; BUILT_NOT_VERIFIED,
  spec written, not run. Half-circle R2 8c500cf passed Codex source review
  only. Canter departure at K ([contract](CANTER-DEPARTURE-LESSON-CONTRACT.md),
  partial: no lead recognition) is built on it, with a "Transitions" subgroup
  under Gaits and pace; BUILT_NOT_VERIFIED, spec written, not run. Canter
  267ab77 passed Codex source review only. Ground pole in walk, jumping stage 1
  ([contract](GROUND-POLE-LESSON-CONTRACT.md), the existing pole rod_50, root-plane
  passage only) is built on it, with additive `generation`/`flyttad` fields in
  HinderObservation.register(); BUILT_NOT_VERIFIED, spec written, not run.
  Deferred before Tobias' playtest: full42, runtime smoke in engine, both lesson
  flows, guides, entrance door, SV/EN and touch.
- 2026-09-27: the entrance correction 93e16f5 received BANK_ONLY code PASS and a
  bounded Studio entrance check. The circle-lesson finish package on that base is
  Claude-written and Codex-reviewed (WORKING-AGREEMENT, package exception). The
  lesson is still not observed in-engine: in an unpublished copy DataStore is
  denied by design, so First Ride stays off and reaching the lesson needs the
  whole care chain. The package adds the lesson to the existing engine runtime
  smoke (`qa/runtime/smoke.luau`, section `voltlektion`, synthetic route) instead
  of another manual walk; it has not run in the engine yet.

## Approved sequence and limits

The earlier catalogue order was infrastructure, instructor, competition,
house, buildings/grounds, equipment, horse, then final full playtest. The
18:01 UTC amendment prioritizes one playable circle lesson before more
infrastructure. All #266 work remains recorded; merge264 did not complete it.

Keep final journey, R5 interactions/layout/dismount/leading, Ugneta visual,
engine/sampling/performance gaps and physical devices separately tracked.
INFRA-4B remains blocked on the selected asset's original/provenance/offline
tools; do not repeat asset searches or substitute a model without new evidence.
FORSOK1 is reviewed server infrastructure, not completed lessons/progression.

The earlier First Playable gate record is preserved in
[history/ACTIVE-GATE-20260926](history/ACTIVE-GATE-20260926.md).
Its dated observations are not evidence for a newer candidate and its old
role, push, immediate gameplay and workload instructions are no longer active.
