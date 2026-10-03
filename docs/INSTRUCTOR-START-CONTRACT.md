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

## R1 correction ([INSTRUCTOR_START_SOURCE_R1](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857262207))

This section was written BEFORE the R1 production edits.

### 1. Turning comments Off removes a visible greeting immediately

- **The subscription.** `VoltLektionController` holds ONE module-lifetime
  subscription to `LararInstallning.vidByte`, connected once like the
  memory listener. It is never re-connected on reattach or rebuild.
- **On change to "inga".** The current greeting is removed. It is already
  consumed, because its attempt is marked greeted, so switching Off → Normal
  or Off → Fewer never brings it back, however fast the switch.
- **When the panel is drawn.** If comments are "inga", the greeting is
  removed as well. This is a read of the setting, NOT a call to
  `valfriKommentar`, so the Fewer counter never moves on a redraw.
- **Kept on screen.** The task text and progress remain.
- **Unchanged.** A detail change never touches the greeting or the Fewer
  counter. A language change redraws the same greeting.

### 2. The selection generation binds a request to the selection it was made in

- **The defect.** `V.valj` calls `skicka("sync")`, and while a request is
  pending that call returns BEFORE `requestNr` moves. A delayed accepted
  Start could therefore still greet after the player re-selected the same
  lesson, or went A → B → A.
- **The fix.** There is a new counter, `valGen`.
  - It is incremented on EVERY `V.valj`, same type or not, whether or not a
    sync is sent. `V.start` and `V.avbryt` also increment it.
  - `skicka` captures it, and a greeting requires that it is unchanged.
- **Unaffected.** The reply is still used for the view as before: `mottag`
  and the revision and type checks decide. The honest current view (for
  example Finish on an active attempt) is therefore usable once the request
  settles.
- **Unchanged.** No pending state is cleared, and the server's
  replay, ownership and attempt guards are untouched. The Finish, dismount,
  reattach and timeout invalidations remain as before.

### 3. Coverage labels (this list replaces the one above)

- **Long `dt` policy.** Each `V.steg` call counts at most 1 s towards the 6 s
  lifetime; a larger `dt` counts as 1 s. The cases step in 1/60 s frames and
  assert the boundary.
- **Every new attempt** goes through the real chooser. A successful Finish
  makes the lesson free, so the lesson is chosen again with `valj` before
  Start. Every press asserts that its control existed.
- **SYNCHRONOUS cases:**
  - accepted Start and Retry;
  - denied request and transport failure;
  - a start seen only via sync;
  - Off, Fewer and Normal;
  - removal on choice, reattach and dismount;
  - an attempt already completed before the reply (a push before the
    return, within the same synchronous call);
  - all ten keys;
  - Off while visible, including a rapid Off → Normal.
- **GENUINELY DEFERRED cases** (scheduler):
  - the event before the reply;
  - a late reply after:
    - another choice;
    - reselecting the same type;
    - A → B → A;
    - Finish;
    - the 10 s timeout;
    - a reattach.
- **FABRICATED** producer-shaped replies: the nine types other than halt in
  the all-types section. They are not real server starts.
- **NOT covered:**
  - safety, care and equipment priority in the host;
  - physical rendering;
  - a real network `InvokeServer`.

