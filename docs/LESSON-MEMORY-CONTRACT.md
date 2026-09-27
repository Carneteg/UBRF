# Lesson memory: first completion and one next practice (C4, first slice)

Status: BUILT_NOT_VERIFIED, 2026-09-27.

Correction (R1): in the first build this contract was written AFTER the first
production edits had started, not before them. The R1 section below was
written before the R1 code changes.
Order: [LESSON_MEMORY_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856911110),
base fd3f592. Build now, test last. Claude writes; Codex reviews source;
Tobias playtests the whole at the end.

The game remembers which of the ten current mounted lesson types the player
has completed AT LEAST ONCE, and suggests one next practice in the existing
chooser.

It is NOT:
- a score, mastery or improvement measure;
- an attempt count;
- canter-lead recognition or hoof/jump quality;
- a reward, level or unlock.

Leading, care, the legacy client-only pass progression and full skill memory
stay separate.

## Source (read before code)

- **`Sparning` v2 `framsteg`.**
  - Each entry is `{forsok, klarade, basta, senast}`, with at most 64 areas.
  - `noteraForsok` increments and leaves idempotency to its caller.
  - `slaIhopV2` merges by max.
- **`SparService`.**
  - `betroddLasning` is true only for a clean read or a truly new row.
  - `skriv` returns false when busy (`skriver`), unsaveable, over the cap,
    on a future-version row or on a network failure.
  - Inside `UpdateAsync` it replaces the cached `sparade[player]` with the
    merged row. Roblox may re-run the transform.
- **Lesson modules.**
  - Each has one transition to `complete`, in its local `stang`, with the
    frozen `resultat`.
  - That `stang` is reached from `steg`. `steg` runs from HorseService's
    Heartbeat and also from INSIDE `begar` for sync, start and retry.
  - A retry in the same `begar` call clears `resultat` immediately after, so
    a check after the call would miss it.
- **`RidForsok`.** Each attempt's snapshot carries `ovning`, `definition`
  (the module `VERSION`), `tillstand` and `orsak`.

## Where the marker is born

- **The hook.** Each of the ten lesson transitions to `complete` calls
  `s.vidKlar(s)`, one line after `andra(s, "complete", ...)`.
  - HorseService sets `vidKlar` when it creates a lesson (`nyLektion`).
  - `vidKlar` calls `LektionsMinne.slutford(session, s)`, which reads the
    session AT CALL TIME.
- **What `slutford` checks:**
  - the rider is a real player with a client (`Aktor.klient`) and a save
    loaded by SparService (a declared test actor gets nothing);
  - the session's current ride and horse equal the lesson's;
  - `player.UserId == s.userId`;
  - `resultat` is frozen and its attempt, ride, user and horse equal the
    lesson's;
  - the producer's own identity holds: halt `mal = "X"`, transitions
    `mal = "T1->T2"`, serpentine `rutt = "serpentin-3"`, tempo `ovning`,
    paths `figur` = type, half-circle `figur`, canter `ovning` with
    `galoppsida = "ej_bedomd"`, ground pole `ovning` with
    `passage = "rotplan"`, circle `avsnitt`;
  - the `RidForsok` snapshot is closed with `orsak = "slutford"` and has the
    same ride, user and horse, the lesson's `ovning` AND the current
    `definition`.
- **What never creates a marker:**
  - a client report;
  - Start or Finish;
  - timeout, closed or aborted;
  - an old snapshot;
  - another player's lesson;
  - sync without a real transition;
  - a missing or malformed result;
  - an old definition;
  - a legacy local score.

## Storage (existing v2 `framsteg`, no schema change)

- **Key:** `lektion:<type>:<definition VERSION>`, for example
  `lektion:halt:server-halt-1`.
  - The circle uses VoltObservation's version, and the two paths share
    VagLektion's.
  - A new definition gets a new key, so an old marker and other `framsteg`
    keys can never count.
- **Value:** `{forsok = 1, klarade = 1, basta = nil, senast = 0}`. It means
  ONLY "completed at least once":
  - it is set once and never incremented;
  - `senast = 0` means no time is stored;
  - a max merge can never lower it;
  - it is displayed only as a boolean.
- **Cap:** the existing 64-entry `framsteg` cap. A full row means the marker
  cannot be added. It then stays "not saved yet", and nothing else is
  removed.

## Confirmed, pending and unknown

| Per lesson | When |
|---|---|
| `sparad` (saved) | in a TRUSTED load, or covered by this module's own write for which `SparService.skriv` returned true |
| `vantar` (pending) | completed this session and marked in memory, not yet confirmed saved |
| `ej_klarad` (not completed) | trusted history, and the marker is absent |
| `okand` (unknown) | history not trusted: read failure, future version, corrupt, no datastore, or not loaded |

These are never evidence of saving:
- the transform callback running;
- `save().framsteg` changing;
- a queued write.

Unknown history is never "you have done no lessons".

## The write (no IO in the frame or lesson loops)

1. **A new marker.** It is recorded in memory and in the current cached
   save, the client gets its projection, and a write attempt is scheduled
   with `task.defer`.
2. **The write attempt.** `forsokSpara`:
   - re-applies the pending markers to the current cached save;
   - calls `SparService.skriv(player)`.
3. **`SparService.foreSkrivning` hook.** At the START of every transform
   run, before the cap check and the merge, the pending markers are applied
   to the `minnet` table the write is based on (idempotent, respecting the
   cap). The run records the set it carried (`tackt`).
   - The committed value is always the LAST run, so when `skriv` returns
     true, exactly those markers are confirmed.
   - This covers a marker recorded while another write is in flight, after
     `sparade` has been replaced by the merged table, or across a re-run
     transform.
4. **Anything left pending after an attempt** (a failure, or a marker
   recorded after the transform ran):
   - it stays pending;
   - a follow-up is scheduled, immediately after a successful write (the
     write path is free) and after 20 s after a failure;
   - at most 3 follow-ups in a row without a confirmation, so a marker that
     cannot fit never loops;
   - every new completion resets the count and tries again.
5. **Player leaves.**
   - SparService writes as before, and the markers are in memory.
   - This module's state and token are dropped, so late responses and
     scheduled retries touch nothing and never reach a rejoined session.

## Client projection (read only, bounded)

- **Remotes.**
  - `LektionsMinneSync` (server to owner) is sent after load, on a new
    marker and after each write attempt.
  - `LektionsMinne` accepts only `op = "sync"` (Skopa limit 4/1) and returns
    the caller's own projection.
- **The projection itself.**
  - It contains exactly the ten types, one of the four states, and the
    history state (`betrodd` or `okand`).
  - The client sanitises it to the allowlist.
  - There is no write path and no way to name another user.

## Player flow (existing chooser, four-row cap)

- **Group pages.** Gaits and pace, Transitions, Riding paths, Straight lines
  and the top page:
  - each lesson button gets " · done" when saved, or " · done now" when
    pending;
  - the page text adds "What you just completed isn't saved yet" when
    anything is pending, or the neutral "I can't read your lesson history
    right now – every exercise is available" when history is unknown;
  - the same buttons and Back as before.
- **Top level, not free riding.** Up to three buttons existed, and a fourth
  optional "Suggested: <lesson>" is added.
  - It uses the same `V.valj` path, and Start is still required.
  - With Ugneta's card buttons present, the existing compact entry takes
    over as before. With the fourth entry this now happens from ONE card
    instead of two.
- **Free riding.** The page is full (four buttons), so the suggestion
  appears in the page text instead.
- **The fixed teaching order:** halt, tempo, circle, transitions, centre
  line, diagonal, serpentine, half-circle, ground pole, canter departure.
  - The suggestion is the first lesson not completed.
  - When all are completed, it is "Practise again: <first>" (no diploma).
  - With unknown history there is no suggestion.
  - A suggestion claims nothing about assessment.
- **Other settings.** SV/EN comes from language keys. The concise/detailed
  setting is unaffected; it concerns end-of-exercise text.

## Deferred verification (written, NOT run)

**`roblox/tests/lektionsminne.spec.luau` (KOHERENS):**
- a real halt completion (the haltlektion fixture) on the Heartbeat sample
  path, through the memory, the save, a trusted reload and the client
  chooser;
- all ten mappings with real `RidForsok` attempts and crafted
  producer-shaped results;
- invalid shapes, timeout, old definition, other player and ride, lesson
  state not `complete`, unfrozen result, test actor, not loaded;
- repeated completion;
- retry;
- busy save and completion during an in-flight save;
- recording after cache replacement;
- a duplicate transform;
- a failed write, then recovery;
- the capacity cap;
- future, corrupt and unavailable loads;
- leave, rejoin and a stale token;
- the menu: markers, suggestion, all completed, unknown, SV/EN, Back.

**Planned, not written:**
- a real completion reached inside a `begar` sync, start or retry call. The
  hook is in the one `stang` both paths use; a fixture that controls the
  sub-0.25 s Heartbeat accumulator is needed;
- the free-riding page;
- stale client callbacks across rides;
- the real Roblox DataStore;
- physical UI.

## R1 correction ([LESSON_MEMORY_SOURCE_R1](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857036865))

### 1. Leave during an in-flight write: the milestone set is drained, not dropped

The defect: `LektionsMinne` dropped its pending set and token on
`PlayerRemoving`. SparService's leave write then found the key busy (write A
still yielding), returned false, and forgot the cache. A marker B recorded
after A's transform returned was therefore lost.

**New order, all inside SparService's existing leave handler:**
1. The before-leave hooks (`SparService.foreAvfard`) run. `LektionsMinne`
   marks the state as leaving:
   - no more UI is sent;
   - no new retries are scheduled;
   - scheduled or late attempts return at once.
   - The pending set and the token are KEPT.
2. `stangningFor(player)` runs (it already exists). It waits, at most
   `STANGNING_VANTETAK` frames, for an in-flight write to finish, then makes
   ONE final `skriv`:
   - it never runs two writes on the same key at once;
   - its `foreSkrivning` hook re-applies the kept pending set to the table
     the write is based on, in every transform run, re-runs included;
   - the table it is based on is the current cache, which already holds B.
3. The after-leave hooks (`SparService.efterAvfard(player, ok)`) run.
   `LektionsMinne` drops the state and token only now.
   - If `ok` is false, the milestones are LOST: the bounded policy (the
     wait cap plus `medRetry`'s 3 attempts) is exhausted, and the game says
     so in a warning.
   - Nothing is shown to the player and nothing claims durability.
4. SparService forgets the player (`glom`), as before.

A rejoin is a new `Player` object with its own state, so old work never
touches it.

### 2. Client ordering: newer facts are never replaced by older replies

- **Server stamps.** Every projection carries:
  - `session`: a server-wide increasing number, assigned when the player's
    memory state is created at load;
  - `rev`: incremented on every change (load, new pending marker,
    confirmation, a finished write attempt).
- **Client rule.** Push and sync replies are handled the same way. A
  projection is accepted only if:
  - its `session` is greater than the one held; or
  - it has the same `session` and a `rev` at least as large.

  An old sync reply that arrives after a newer push is ignored, and so is a
  reply from before a reattach.
- **Scope.** History is player-owned and is not cleared when a ride or
  attempt changes. The frozen result guards are unchanged.
- **The suggestion button.** It is bound to its recommendation: when
  pressed, it acts only if the current suggestion is still the same type.

### 3. The suggestion in the ACTUAL composed chooser (0..3 cards, 4-row cap)

- **The compact case.** With Ugneta's card buttons present, the host uses
  the lesson's single compact entry ("Choose exercise"), which opens the
  replacement page `topp`. Its buttons are unchanged: Circle, Gaits and
  pace, Riding paths, Back.
  - Its text (a replacement page's text IS rendered) now shows:
    - the suggestion and where to find it, for example "Suggested:
      Half-circle (under Riding paths).";
    - the pending or unknown line.
  - The group button that leads to the suggested lesson gets
    " · suggested", and so does the lesson button on that group page (or
    the Circle button when the suggestion is the circle).
- **No cards.** The root keeps its optional fourth button, "Suggested: X".
  - The root is not a replacement page, so its text is NOT rendered and the
    root makes no text claim. The pending/unknown line appears on the
    replacement pages (topp and the groups).
- **Free riding.** A replacement page: the suggestion and the memory line go
  in its text.
- **Unchanged.** Every existing lesson, group, Back, free and "Other
  exercises" button, and care and equipment priority. No fifth row, and no
  start.

### 4. Coverage and documentation

- **The request path.** A real halt reaches its completion condition between
  Heartbeat lesson steps (the observation advances, the lesson does not yet
  step). A KONTROLL confirms the lesson is not yet complete. The completion
  then happens INSIDE `begar`:
  - first with a sync;
  - then with a retry, which resets the result in the same call. The marker
    exists and the new attempt carries no result.
- **The deferred leave.** On the scheduler (`__schemaPa`):
  - write A yields after its row has landed;
  - completion B arrives;
  - `PlayerRemoving` is fired while A is outstanding;
  - A finishes and the bounded final write runs;
  - a trusted reload shows B saved.
  - Variants: a re-run transform, and a failed final write (B is not
    saved, and nothing claims it is).
- **Ordering.** A request before a push, reversed replies, and a reattach.
- **The actual host.** `UgnetaController.panel(4)` / Naromrade with 0 and 1–3
  cards, the compact entry, the topp page text, the markers, Back, free
  riding, SV/EN, all completed and unknown history.
- **The Back case.** The panel is rebuilt after the language switch, and the
  real destination is asserted.
