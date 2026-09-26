# One playable circle lesson

Status: DESIGN_R1_READY_FOR_REVIEW, 2026-09-26. No gameplay code changed yet.
Base: 24eae8df2eb5477f01d22c728d8b3b68037d3ade.
Authority: Tobias' [playable-slice decision](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5848553215).
Codex implements; Claude reviews independently; Tobias accepts the experience.
Existing infrastructure stays frozen except the narrow integration below.

## Player outcome

From the existing mounted lesson presentation the player can explicitly choose
"Practice a circle" (SV/EN). No prerequisite completion of other lessons. This
selects a single optional lesson, not a new mandatory onboarding sequence.
Ugneta invites one circle around the existing dressage-layout centre, in either
direction. A non-colliding client guide shows the actual server reference as a
tolerance band, clipped visually to the arena interior (not a line in the wall);
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

Start first opens FORSOK1 with its existing marker, then puts the lesson in
`approach` state. It does not split observations or credit the approach path.
Only a genuinely new accepted attempt enters this state; rejected and duplicate
starts never change a section, arm state, marker or existing result.

After each server observation, while approaching, require a fresh valid current
point in the reference frame with abs(radius - referenceRadius) <=2m. Then archive
the old VOLT1 section without rewriting it, record its highest ID as `armAfter`,
pin the frame/centre/radius and set a fresh-baseline flag. The next observation
is baseline-only (discard the crossing segment). Subsequent known segments start
a monotonically newer section. This deliberately excludes both pre-button riding
and the approach. No yield between deciding to arm and setting the boundary.
Do not re-arm every sample while inside the band: `approach -> baseline -> riding`
is a one-time transition until an explicit recovery or a new attempt.

Only the current armed section can succeed. If its maximum radial deviation >4m,
opposite angle >pi/4, or a complete net turn fails the other success thresholds,
archive that section, clear armed evidence and return to approach with one useful
tip. Centre/gap/teleport/reference/frame breaks likewise clear the armed section;
never join it to a later section. A later qualifying point can arm again, but
only a fresh full circle counts. Re-arming does not extend the 120s attempt deadline.
An outside point beyond4m also invalidates the current arm even if its segment
midpoint happens to be within tolerance. Approach and incomplete attempts are
not bad-riding grades. The player need not leave the arena or press Retry to recover.

FORSOK1's start marker stays immutable. Store armAfter separately in the lesson;
the chosen section must be newer than BOTH start.voltHogsta and armAfter. No callback
inside RidForsok.starta or marker relocation is required: its markor reads the
highest ID from BOTH archived and current sections. Archiving an existing section
does not change that ID; only creating the next section increments it. This fixes
ordering explicitly without adding an unnecessary start-hook abstraction.

At success, freeze the selected evidence and close the attempt exactly once before
sending the outcome. Current API only has `avbrytForsok` (reason `avbrutet`): do not
mislabel successful completion as cancellation. Reuse its close/snapshot primitive
with one server-only close path restricted to `slutford` and `tidsgrans`, in addition
to existing explicit `avbrutet` and lifecycle `ritt_slut:*`; no result-store layer.
Finish/cancel during an active attempt uses `avbrutet`. Deadline uses `tidsgrans`.
Before evaluation/close require that this exact attempt is still active and owned
by the current session. Teardown/cancel already accepted wins over later success;
at now >= deadline, timeout wins over a newly sampled candidate. Evaluate, snapshot
the exact chosen section, close and publish without yielding. Failed close means
no success. A late Finish after a frozen success only dismisses the lesson surface.
FORSOK1 remains lifecycle-only (`bedomning=ingen`); lesson verdict is separate.
An externally cancelled/closed attempt is never automatically promoted to success.
Later riding, retry or history pruning cannot change the frozen lesson result.

## Assessment v1: explicit gameplay assumptions

Read the current immutable `HorseService.volt(rittId)` snapshot after server sampling,
not historical aggregates. Validate its version `server-referens-1`, rider, horse,
ride and pinned reference/frame against the active FORSOK1/lesson. Its `pagar` section
must be the armed fresh section above. Never select an archived completed circle.
`forsokVolt` remains a strict historical API: a pruned earlier section can make that
API unavailable without invalidating a fully observed current armed section. Do not
weaken its error semantics or require old history to score a new circle. Freeze the
selected section in the bounded lesson result together with its identities/markers;
FORSOK1 still freezes its own close snapshot. Later reads do not recompute a verdict.
Success requires ONE fresh uninterrupted known
section, `underlag=tillrackligt`, at least one net revolution, mean radial deviation
<=2.0m, maximum radial deviation <=4.0m, return distance <=3.0m and opposite-direction
angle <=pi/4. Reference radius remains the existing RidKanon value (currently10m).
Limits are provisional training tolerances, NOT official riding rules or measured
venue dimensions. Test equality and either side of every limit. Do not average
across sections or invent missing values. Both directions must pass symmetrically.

Unknown/insufficient/missing current evidence means no verdict, never zero error. Centre
crossings, frame changes, sample gaps and teleports cannot join arcs. Recovery
requires an entirely fresh qualifying section. Partial arc + elapsed time or
standing still never completes the lesson. No deadline produces success.
After 120 server-clock seconds offer a neutral incomplete result and retry; a
sample freeze cannot keep an attempt alive forever. Finish/cancel remains usable.
No rhythmic/balance/hand praise is inferred from circle geometry. Praise only what
is observed; use one useful next action for a wide/incomplete/unknown circle.
Live guidance is throttled, not a repeated stream of corrections.

The nominal 20m circle spans the nominal20m arena width. Neither feedback nor
completion demands zero radial error at the walls. Test an inward-offset path
within these tolerances in both directions. Actual horse clearance is unmeasured:
do not turn the reviewer's approximate0.5-1m estimate into a physical fact.

Accepted dismount/death/leave/horse teardown closes the attempt, clears guide and
pending UI, and cannot award completion afterwards. A denied dismount preserves
the same server attempt; client reattachment resyncs it, never creates another.
New ride/horse clears previous lesson display and pending callbacks. Two players
must not share state, evidence, messages or results.

## Acceptance and falsification before code review

1. Real HorseService path: explicit start, fresh baseline, clockwise and opposite
   circle, frozen success, visible keyed outcome, retry new ID and Finish exit.
2. Pre-start full/half circle + post-start remainder cannot pass; a fresh full
   circle after pressing Start while already in the arena can pass. Start at A
   far from the line, approach then circle must pass; one >4m excursion must not
   pass that section, but recovery and a fresh circle can pass without Retry.
3. Half circles linked through centre, reverse arcs, stationary timeout, wrong
   centre/radius, frame replacement, sparse samples and old version cannot pass.
4. No mutation or false success from other player/old ride, duplicate/reordered
   requests, sequence reuse with different payload, lost reply or stale callback.
5. Cancellation vs success ordering, accepted/denied dismount, death, teardown,
   retry and ring eviction retain exactly the correct frozen result or no result.
   More than8 discarded sections followed by a fresh circle must still pass.
   Deadline equality means tidsgrans, not slutford; Finish means avbrutet. Denied
   and duplicate starts preserve the exact current section and arm state.
6. Client integration: start refusal/pending/recovery, language switch in each
   state, existing mouse/keyboard/touch controls, no movement lock while riding,
   no legacy 22-second verdict/unsupported replay; other exercises regressions.
7. Isolated falsification removes start boundary, enables legacy timer success,
   joins unknown sections, swaps ownership and reads a live result after close:
   each mutation must be killed with unchanged positive controls.

Include exact arming threshold and outward-endpoint cases, repeated in-band samples
without endless baseline resets, failed full-turn recovery, an inward wall-clearance
path and immutable result after pruning. These are proposed executable acceptance
cases, not claims of tests already run.

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
