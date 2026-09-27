# Ugneta's written start greeting (C2 / #234, ten mounted lessons)

Status: BUILT_NOT_VERIFIED, 2026-09-27. This contract was written BEFORE the
production edits for this slice.
Order: [INSTRUCTOR_START_BUILD](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857157415),
base a03dcf2. Build now, test last. Claude writes; Codex reviews source;
Tobias plays the whole at the end.

This slice covers ONE short written greeting when a fresh lesson attempt
starts. It is not all of #234 or C2.

Not included:
- voice or TTS (G02-C still applies);
- BubbleChat or a chat range change;
- on-foot leading;
- legacy lesson redesign;
- auto-start, and any movement or equipment change.

## Source (read before the edits)

- **The request path.** `VoltLektionController.skicka(op)` spawns
  `InvokeServer(id, op, seq, typ)`.
  - The reply is used only if the generation, request token and ride are
    unchanged. `valj`, Finish, `start` and `avbryt` advance them, and
    `V.steg`'s 10 s timeout advances `requestNr`.
  - The reply's snapshot goes to `mottag`, which accepts it only for the
    same ride, the same type and a revision at least as new.
- **Server pushes.** The server sends snapshots from its Heartbeat whenever
  the revision changes (`VoltLektionSync`). The push for a new attempt can
  therefore arrive BEFORE or AFTER the reply.
- **The teacher host.** The mounted lesson page returns `ersatt = true`.
  - Ugneta's teacher text and the host panel read that page's `text` before
    the optional live chip.
  - `LektionController.steg` calls `VoltLektionController.steg` before its
    takeover return. That is the only update tick that runs for mounted
    lessons.
  - `Ugneta.live` and its timer are therefore NOT a visible path here.

## Authority: what creates a greeting

A greeting is created ONLY in the reply handler of an explicit `start` or
`retry`, and only when all of these hold:
1. **The request is still current:** the existing generation, token and
   ride guards pass, and the type at reply time equals the type the request
   was sent with.
2. **The server accepted it:** `ok == true`, and the reply snapshot `b`
   carries an attempt id (`b.forsokId`), the same ride and the same type.
3. **The attempt is still current and active:** after `mottag`, the
   snapshot held (possibly a newer push that arrived first) has the SAME
   attempt id and is in an active state, not complete, timeout, closed or
   ready.
4. **It has not been greeted before:** that attempt id has not been greeted
   or consumed in this ride. The memory holds one attempt id per ride and
   is cleared on a new ride.

These never create a greeting:
- a selected lesson, the mounted state, a ready view or a sync or push
  snapshot;
- a denied request, a transport failure or a timeout;
- a reply that arrives after Finish, another choice, a dismount, a new
  horse, a reattach or a newer request (all fail the guards);
- a reply whose attempt has already completed or been replaced.

## Text

`halsning.<typ>` is one sentence that names the exercise and gives ONE
instruction taken from that lesson's existing contract and texts. For
example: "Now for the circle: follow the line around the middle for one full
circle."

It contains:
- no praise, score or measurement;
- no seat, hand or theme observation (the mounted definition supplies
  none);
- no mastery or reward.

It is formatted when the panel is drawn, so a language change redraws the
same greeting and never creates another.

## Presentation and lifetime

- **Where it appears.** At the FRONT of the lesson page's own text. The
  current task text and the progress % remain after it.
- **It is removed** by whichever of these happens first:
  - 6 s pass (counted in `V.steg`);
  - the attempt id or type changes;
  - the state leaves the active states;
  - a request is pending or an error is shown;
  - Finish, another choice, a new ride or reattach (`V.start`), or a
    dismount (`V.avbryt`).
- **Once removed it never returns.** Language, detail setting, GUI rebuild,
  respawn and reattach do not bring it back.
- **Priority.**
  - A safety takeover dismounts (`avbryt`) and so clears it.
  - Pending and error text win (the greeting is not shown then).
  - The Start, Retry, Finish and Back controls are unchanged.
  - No acknowledgement, no modal and no fifth row.
- **Comment preferences.** At creation the greeting goes through the SAME
  decision as the optional live comments
  (`UgnetaController.valfriKommentar()`):
  - Normal: shown.
  - Fewer: the shared counter decides.
  - Off: not shown.
  - A greeting that is not shown is CONSUMED: its attempt is marked
    greeted, and it never appears later when the setting changes. The
    Fewer counter is still reset only by a change of the comment setting.
- **Left unchanged.** Frozen end-of-exercise feedback, lesson memory,
  leading and the local gaze.

## Deferred verification (written, NOT run)

`roblox/tests/instruktorstart.spec.luau` (KOHERENS) uses the haltlektion
fixture: real HorseService, the real `VoltLektion` remote through the bench,
and the real `VoltLektionController` in the composed
`UgnetaController.panel(4)`.

**Synchronous cases** (the bench runs `task.spawn` directly, so the reply
arrives within the press):
- accepted Start: greeted once, before the task text;
- Retry greets its new attempt once;
- a denied Start (retry without complete) gives no greeting;
- a transport failure gives no greeting;
- sync or push alone gives no greeting;
- a duplicate snapshot does not greet again;
- 6 s, a state change, Finish, another choice, reattach and dismount each
  remove it, and it does not return;
- language: the same greeting in EN, never a second one;
- Off consumes, and Normal afterwards does not replay;
- Fewer uses the shared counter;
- all ten types' keys exist in SV/EN;
- the four-row cap and the controls are unchanged.

**Genuinely deferred cases** (on the scheduler, `__schemaPa`):
- event before reply: a push of the new attempt arrives, then the reply;
- reply before event;
- a delayed reply arriving after Finish or another choice gives no
  greeting;
- a reply whose attempt has already completed gives no greeting.

**Planned, not written:**
- physical rendering;
- a real network `InvokeServer`;
- a respawn with GUI rebuild on a device.

The lesson-memory event-order fixtures are NOT evidence of an executed
deferred `InvokeServer` chain.
