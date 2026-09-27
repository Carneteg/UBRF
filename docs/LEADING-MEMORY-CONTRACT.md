# Leading memory: first genuine completion of the on-foot leading lesson

Status: BUILT_NOT_VERIFIED, 2026-09-27. This contract was written BEFORE the
production edits for this slice.
Order: [LEADING_MEMORY_BUILD](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857423952),
base 6f9cc5e. Build now, test last. Claude writes; Codex reviews source;
Tobias plays the whole candidate at the end.

This slice remembers that the player has genuinely completed the CURRENT
on-foot leading lesson at least once, and shows that history (saved,
pending, unknown) in the lesson's own on-foot page.

It does not make leading, skill memory or the catalogue complete.

## Source (read before the edits)

- **The completion.** `LedLektion.stang(player, s, "slutford")` is the only
  completion transition.
  - It freezes `resultat = {userId, hastId, forsokNr, kontextNr, meter,
    sekunder, frammeProv, malNyckel, start, version}` and sets `complete`.
  - It is reached only from `prov`, after fresh actual movement of at least
    `RESA_M` and `FRAMME_PROV` settled samples inside the goal. It also
    requires the same leading record, character, horse root and goal key.
- **Dependencies.** `LedLektion.start(deps)` receives `rattHast` and `rider`
  from `GameplayService`. LedService's own goal callback for the
  preparation is separate and is NOT touched.
- **What never counts.** The historical flags `harNattMal` and
  `harLamnatBox`, and spawning in or standing in the goal, are not
  completion.

## Authority

- **The callback.** `deps.klar(player, s)` is a new, optional dependency.
  `GameplayService` wires it to `LektionsMinne.ledningKlar`.
  - It is called in `stang` right after `complete`, in the same call.
  - That is before Retry, Finish or a new binding can clear or replace
    anything.
- **`ledningKlar` accepts only:**
  - a real player with a client and a loaded save;
  - the module's ACTUAL state for that player (`LedLektion.arAktuellt`),
    so a forged external table is rejected;
  - `s.lage == "complete"`, with a frozen result whose `version` is
    `LedLektion.VERSION` (the current definition);
  - identity: the result's `userId`, `forsokNr`, `kontextNr` and `hastId`
    equal the state's current `userId`, `forsokNr`, `kontextNr` and
    `hastId`, and `userId` equals the player's;
  - the producer's own conditions, not new ones: `meter` finite and at least
    `GRANSER.RESA_M`, `frammeProv` a whole number of at least
    `GRANSER.FRAMME_PROV`, `sekunder` finite and non-negative, and
    `malNyckel` a string.
- **What never creates a marker:**
  - a client snapshot, op/seq replay or sync;
  - a retained historical result;
  - ready, closed or timeout;
  - old goal flags;
  - an invented mounted ride. There is no RidForsok, and no mounted
    validation is changed.
- **Unchanged.** Leading itself, the rope, the preparation goal hook,
  Start/Retry/Finish/Back, the cadence, the goal and the request guards.

## Storage (existing pipeline, separate namespace)

- **Key:** `ledning:<LedLektion.VERSION>`, for example
  `ledning:server-ledning-1`. A new definition gives a new key.
- **Value:** `{1, 1, nil, 0}`, meaning only "led her all the way at least
  once". No count, quality or award.
- **The existing `LektionsMinne` pipeline.**
  - It has one writer per player, and the saved, pending and unknown states.
  - The `foreSkrivning` hook runs in every transform run.
  - A marker counts as saved only when this module's own write returns true.
  - Follow-ups are bounded, the leave drain applies, and the token dies with
    the session.
- **No IO in the sample loop.** The marker is captured, then the write is
  deferred with `task.defer`.
- **Shared pending set.** Mounted, care and leading markers share the same
  pending set, so all of them are kept through an in-flight write, a cache
  replacement, a re-run transform, a retry and a leave.
- **Retained gaps:** general D3/D4, and the bounded terminal failure on
  leave.

## Projection and the actual on-foot page

- **The projection** gains `ledning`, with the same `session`/`rev`
  stamps.
- **`LedLektionController`.**
  - It has one listener and makes one read, with the same ordering rule:
    older or reversed replies never replace newer facts.
  - The history is kept separate from the attempt/context stream
    (`LedLektionSync`).
- **What is rendered** (the actual host: `Ugneta.satFotVal(L.panel)`, whose
  page is a replacement page):
  - the on-foot entry button ("Lead to the arena") gets " · done" or
    " · done now";
  - on the lesson page, in the ready and closed states, the text adds one
    line:
    - "You have led her all the way before." when saved;
    - "… (not saved yet)" when pending;
    - "I can't read your leading history right now." when unknown;
    - nothing when not yet done.
  - During an active attempt, and on the complete page, the history is NOT
    shown. The frozen feedback of the current attempt applies there, and
    history is never shown as success for a later attempt.
- **What it does not add.** No new row, acknowledgement, modal or
  auto-start. The four-row composition is unchanged, and care questions,
  welfare, equipment return and the mounted choices keep their priority.
- **Language.** SV/EN comes from language keys.

## Care follow-ups (same package)

1. **The version policy for the care keys.**
   - `SKOTSEL_VERSION = {halsa = "v1", visitera = "v1", rykta = "v1",
     hovar = "v1"}`.
   - The key is `skotsel:<id>:<version>:<n>`, the same keys as today, so an
     unchanged definition is not churned.
   - A change to the qualifying SEMANTICS (reordering, replaced moments or
     new rules) REQUIRES a version bump. A change in the NUMBER of moments
     also changes the key automatically.
   - The earlier claim that "any changed canon changes the key" was wrong
     and is corrected.
2. **`CARE-MEMORY-CONTRACT.md` now matches the actual spec:**
   - wrong horse, future/corrupt and newer context in the host are PLANNED;
   - the deferred case uses a care greeting write, not a mounted completion
     or a pass write.
3. **New written cases in `skotselminne.spec`:**
   - a real LocalPlayer care view, with the history in the help section
     next to a care question (the greeting's choices) and an equipment
     return, the four-row cap and SV/EN;
   - a genuinely deferred pass-style write: `Sparning.registreraPass` plus
     `SparService.skriv`, the same persistence step as
     `GameplayService.avslutaPass`, invoked directly (NOT the whole
     `avslutaPass` flow), with a care completion during it.
   - A same versus a revised definition gives the same versus a different
     key.

## Deferred verification (written, NOT run)

Correction (tempo package): a replaced character or model at the completion
sample, a future-version save and unknown history for leading are PLANNED,
not written. L4 covers only release and re-take plus another actor, and L6
covers write failure and recovery plus a full row. The shared pipeline's
future and corrupt loads are written in `lektionsminne.spec`, not here.

`roblox/tests/ledningsminne.spec.luau` (KOHERENS) uses the ledlektion
fixture.

**Synchronous cases:**
- the real `LedLektion` Start, a real leading record, movement samples and
  settling: first success;
- a repeat does not create a new marker;
- Retry and Finish right after success;
- denied, stale and timeout;
- old goal flags and a spawn inside the goal;
- release and re-take (L4); another actor kept apart (L4);
- two players kept apart;
- history kept after a new context without a current success;
- trusted reload;
- write failure, then recovery, and a full row (L6);
- a forged table rejected.

**Genuinely deferred cases** (scheduler):
- a completion while a write is in flight;
- a leave during that write.

**Client cases:**
- ordering;
- the button marker and the ready line in the ACTUAL
  `UgnetaController.panel(4)`, with the care/cards composition, in SV/EN.

**Planned, not written:**
- physical rendering;
- a real DataStore.
