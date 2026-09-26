# One playable circle lesson

Status: DESIGN_READY_FOR_REVIEW, 2026-09-26. No gameplay code changed yet.
Base: 24eae8df2eb5477f01d22c728d8b3b68037d3ade.
Authority: Tobias' [playable-slice decision](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5848553215).
Codex implements; Claude reviews independently; Tobias accepts the experience.
Existing infrastructure stays frozen except the narrow integration below.

## Player outcome

From the existing mounted lesson presentation the player can explicitly choose
"Practice a circle" (SV/EN). No prerequisite completion of other lessons. This
selects a single optional lesson, not a new mandatory onboarding sequence.
Ugneta invites one circle around the existing dressage-layout centre, in either
direction. A non-colliding client guide shows the actual server reference;
it does not move the horse, change arena geometry or create an asset dependency.
No attempt starts until the player presses Start. Free riding remains available.

The existing Ugneta surface shows waiting, riding, feedback and completion.
During riding it must not open a modal or freeze movement. On completion it
shows "Circle completed" and a concrete observation about the ridden line.
This is a visible session-local lesson outcome, NOT currency, XP, an unlock,
a saved achievement or product acceptance. Retry and Finish are explicit choices.
Finishing returns to free riding; the existing lesson sequence remains reachable.
No automatic advance/retry; no requirement to attempt twice.

## Existing paths and bounded changes

- `client/LektionController.luau`: explicit single-lesson mode, start/retry/finish,
  server responses and teardown. Leave other exercises' existing paths intact.
- `client/UgnetaController.luau`, existing panel adapter and language catalogue:
  existing buttons/coach surface, keyed SV/EN text; no second competing HUD.
- `shared/HorseCore/Networking.luau`: narrowly scoped lesson intent and owner-only
  response through the established network layer; use existing request limiting.
- `server/HorseService.luau`: validate the real rider/session, integrate the lesson
  immediately after existing observation sampling, and reuse FORSOK1 lifecycle.
  No second sampling loop. A small lesson-specific evaluator may be factored out.
- `server/VoltObservation.luau`: only the explicit start-boundary hook described
  below, if required by the reviewed design. No new geometry or measurement model.
- Actual production service/client tests and affected regression specs, with
  generated-source/export changes only where existing repository tooling requires.

Do not edit the generated RidKanon directly, shared web exercise definitions,
movement, stamina, horse selection, assets, save/progression or other writers' files.
The single lesson replaces the legacy 22-second/local-radius judgement ONLY in
this mode. It must not call the legacy judgement or replay a version-1 recording
as evidence of `storvolt/server-referens-1` success. Legacy replay is not offered
for this mode in the first slice; other lessons retain their existing replay.

## Ownership and transport

The client sends intent (start, cancel/finish, retry, resync), current rittId and
bounded integer request sequence. It never supplies position, score, rider/horse
identity, verdict or target centre for assessment. The server derives all of
these from the current HorseService session and its observations.
Reject malformed/oversized identifiers, non-finite/fractional sequences, unknown
operations, another rider's attempt, stale rittId and invalid mount/arena state.
Use rate limiting, one lesson per current ride and bounded retained responses.
Duplicates return their original result without restarting or closing a new attempt;
same sequence with a different operation is rejected by the lesson adapter.
The adapter owns FORSOK1's sequence allocation; do not let arbitrary client jumps
consume or collide with internal close operations.

Responses carry rittId, forsokId, revision, state and localized-message keys/data.
Send only to the owning player. Ignore earlier revisions or other rides locally.
Subscribe before requesting initial state; bounded resync recovers missed replies.
Pending start is visibly pending, never optimistically successful. Denied start
returns a useful reason and leaves Start/Finish usable, without locking movement.

## Attempt boundaries: the design risk to review first

FORSOK1 excludes the whole observation section that was already running at start.
Ordinary riding inside the arena may keep that section alive indefinitely. Simply
calling startaForsok and waiting is therefore not a playable consumer.

On a genuinely NEW accepted lesson start, record the existing FORSOK1 marker,
archive (do not reset/rewrite) the prior VOLT1 section, and mark a fresh baseline.
The first server observation after start is baseline-only: discard its crossing
segment, since its start endpoint can predate the button request. Only subsequent
segments belong to the attempt. Keep monotonic section IDs and prior history.
No yield between accepted start and boundary setup. Rejected or duplicate starts
must not split any section. This is one lesson integration hook, not INFRA-3.
An alternative must demonstrate the same usable fresh-start invariant without
making the player leave/re-enter the arena or silently crediting pre-start data.

At success, freeze the selected evidence and close the attempt exactly once before
sending the outcome. Current API only has `avbrytForsok` (reason `avbrutet`): do not
mislabel successful completion as cancellation. Reuse its close/snapshot primitive
with a server-only completion path and distinct reason; no new result-store layer.
FORSOK1 remains lifecycle-only (`bedomning=ingen`); lesson verdict is separate.
An externally cancelled/closed attempt is never automatically promoted to success.
Later riding, retry or history pruning cannot change the frozen lesson result.

## Assessment v1: explicit gameplay assumptions

Use only `forsokVolt` from the current attempt, `server-referens-1`, correct rider,
horse, ride and reference frame. Success requires ONE fresh uninterrupted known
section, `underlag=tillrackligt`, at least one net revolution, mean radial deviation
<=2.0m, maximum radial deviation <=4.0m, return distance <=3.0m and opposite-direction
angle <=pi/4. Reference radius remains the existing RidKanon value (currently10m).
Limits are provisional training tolerances, NOT official riding rules or measured
venue dimensions. Test equality and either side of every limit. Do not average
across sections or invent missing values. Both directions must pass symmetrically.

Unknown/insufficient/pruned evidence means no verdict, never zero error. Centre
crossings, frame changes, sample gaps and teleports cannot join arcs. Recovery
requires an entirely fresh qualifying section. Partial arc + elapsed time or
standing still never completes the lesson. No deadline produces success.
After 120 server-clock seconds offer a neutral incomplete result and retry; a
sample freeze cannot keep an attempt alive forever. Finish/cancel remains usable.
No rhythmic/balance/hand praise is inferred from circle geometry. Praise only what
is observed; use one useful next action for a wide/incomplete/unknown circle.
Live guidance is throttled, not a repeated stream of corrections.

Accepted dismount/death/leave/horse teardown closes the attempt, clears guide and
pending UI, and cannot award completion afterwards. A denied dismount preserves
the same server attempt; client reattachment resyncs it, never creates another.
New ride/horse clears previous lesson display and pending callbacks. Two players
must not share state, evidence, messages or results.

## Acceptance and falsification before code review

1. Real HorseService path: explicit start, fresh baseline, clockwise and opposite
   circle, frozen success, visible keyed outcome, retry new ID and Finish exit.
2. Pre-start full/half circle + post-start remainder cannot pass; a fresh full
   circle after pressing Start while already in the arena can pass.
3. Half circles linked through centre, reverse arcs, stationary timeout, wrong
   centre/radius, frame replacement, sparse samples and old version cannot pass.
4. No mutation or false success from other player/old ride, duplicate/reordered
   requests, sequence reuse with different payload, lost reply or stale callback.
5. Cancellation vs success ordering, accepted/denied dismount, death, teardown,
   retry and ring eviction retain exactly the correct frozen result or no result.
6. Client integration: start refusal/pending/recovery, language switch in each
   state, existing mouse/keyboard/touch controls, no movement lock while riding,
   no legacy 22-second verdict/unsupported replay; other exercises regressions.
7. Isolated falsification removes start boundary, enables legacy timer success,
   joins unknown sections, swaps ownership and reads a live result after close:
   each mutation must be killed with unchanged positive controls.

Use focused service/client tests first, then the shared full relevant delivery
chain and exact-SHA independent code review. Design review is not code PASS.
Before any small engine probe: record exact candidate, hypothesis, pass/fail and
prove isolated no-real-save setup; otherwise stop. No publication or CI dispatch.

## Product checks proposed, not silently authorized

After technical review, propose one 10-minute Tobias PC session for this lesson:
find Start, ride one circle, understand feedback, retry, Finish. Repeat only after
a changed player-facing slice, not every internal patch. Full final journey and
physical-device acceptance remain separate. A proposal is not a scheduled reminder.

By the circle code-review checkpoint, report HRAG original/provenance status once.
If still unavailable, offer Tobias a choice: defer final horse-visual acceptance
while exercising the existing supported rig, or supply the approved original.
No deadline automatically authorizes a replacement model, search, download or cost.
Use existing GitHub review messages with Kind/Base/Candidate/ExpectedResult fields;
no new coordination infrastructure is required for this slice.
