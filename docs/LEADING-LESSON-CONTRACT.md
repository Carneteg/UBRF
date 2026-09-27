# Leading the horse to the arena (on foot)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [LEADING_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856139668),
base 9dff4d5. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

This is ONE on-foot lesson in the catalogue area "ledning": lead your own
horse to the EXISTING arena goal zone. It is not a riding session: it
uses no RidForsok and no mounted ledger. It does not replace or change
movement, navigation, the rope, doors or equipment. It does not change the
preparation step, its acknowledgement or its history.

## Existing semantics used (read in source)

- **The goal:** `LedService.malzon()` is the arena track rectangle in
  plot coordinates (`GameplayService`: `ridhus.rekt + ridhus.bana`).
  `LedService.iRekt` is the one rule for "is she there".
- **Leading state:** `LedService.lage(player)` gives `{ modell, hastId, ... }`
  while leading, and nil after `slapp`.
- **Old flags:** `harNattMal` / `harLamnatBox` are HISTORICAL and survive release;
  the lesson never uses them.
- **The preparation hook:** `satMalKrok` stays the preparation's consumer
  (`GameplayService.kvitteraLedning`). The lesson installs NO hook in
  LedService.
- **Eligible horse:** GameplayService's bound horse (`bunden[player]`, the same
  answer as `satRattHastKrok`).
- **Mounting and dismounting:** `HorseService.lyssnaRyttare` (a list, so it can
  be appended to).
- **Shortcuts:** `stallFram` and `placeraVidMal` teleport the horse. They are
  setup, not leading.

## Narrow new dependency (genuinely missing)

- **Remotes:** `LedLektion` (RemoteFunction: `sync` / `start` / `retry` /
  `finish` with a sequence) and `LedLektionSync` (RemoteEvent, server → owner).
  Both are declared in Networking. The remote goes through `Skopa.grind`, which
  uses the default limit, like `VoltLektion`.
- **Server module:** `LedLektion` keeps per-player, session-local state with a
  bounded answer book of 16. It samples every 0.25 s on its own Heartbeat
  accumulator. `LedLektion.start(deps)` is wired by GameplayService with
  `rattHast(player)` and `rider(player)`.
- **No persistence and no reward.**

## Player flow

1. **On foot, with the horse outside the arena:** Ugneta's on-foot panel shows
   "Lead to the arena". The entry is secondary: it never hides an open care
   question.
2. **Choose:** a page with Start and Back.
3. **Start:**
   - The player must be on foot and alive, the goal must exist, the bound horse
     must exist, and it must be OUTSIDE the goal. Otherwise Start is refused
     with guidance (`inside`, `target`, `horse`, `mounted`).
   - If the player already leads the right horse, the baseline is taken now
     (`leading`).
   - Otherwise the tip is `lead_first`: start leading your horse.
4. **Lead her there:** the SAME horse, led by this player, must travel
   ≥ 12 m of fresh observed movement since the baseline.
5. **Arrive:** she must enter the goal and stay inside ≥ 1.0 s while still led.
   Then the lesson is complete.

The result stands even if the player releases her in the arena afterwards.
Retry and Finish work as in the other lessons:
- Finish never releases or moves the horse.
- The normal leading controls stay separate.

## Evidence (every 0.25 s, gameplay assumptions)

| Name | Value |
|---|---|
| Fresh travel | ≥ 12 m of the horse root's planar movement between consecutive samples WHILE led by this player, after the baseline |
| Jump / teleport | > 3.0 m between two samples (12 m/s): unknown and a reset (stallFram, placeraVidMal, respawn) |
| Gap | a sample interval > 1.0 s: unknown and a reset |
| Arrival | inside `iRekt(malzon)` for ≥ 4 consecutive samples (1.0 s), still led |
| Deadline | 300 s; timeout ends incomplete |

- **Baseline:** set when leading of the right horse is observed after Start. It
  records the horse position and the goal key; nothing from before counts.
- **Stationary:** a horse that does not move adds no travel, whatever
  `MoveTo` or commands happen. Player position alone never counts; only the
  horse root does.
- **Arrival requires the travel:** arriving before 12 m of travel does not
  complete. Settling restarts if she leaves the goal.
- **The evidence resets to `lead_first`** (all travel cleared, same deadline):
  - the lead is released before completion (`released`);
  - leading a different horse or model (`wrong_horse`);
  - the bound horse changes;
  - mounting (`mounted`);
  - the character missing or dead (`character`);
  - the horse model gone;
  - a changed or missing goal (`target`);
  - a jump or gap (`unknown`).
- **Leaving the game:** the state is dropped.

## R1 (source review #5856236775)

- **Session continuity.** At the baseline the lesson records the identity of the
  leading RECORD (`LedService.lage(player)`), the character, its root part and
  the horse root part. Each `borja` creates a new record, so a release and
  re-take of the same horse between two samples, a new or respawned character,
  or a replaced root clears all travel and arrival (`released`, `character`,
  `horse`). The next sample needs a fresh outside baseline. A pause in the SAME
  session is unchanged.
- **Expected attempt.** Start, Retry and Finish carry the attempt number the
  client DISPLAYS. The server applies them only if it equals its current
  attempt. Otherwise the answer is `stale_attempt`, and the newer attempt is
  never touched. The expected attempt is part of duplicate replay: the same
  sequence with a different operation or expectation is refused.
- **Client controls.** Rendered controls are bound to a page generation and the
  displayed attempt:
  - a new page, Back, any request or a new attempt kills older controls;
  - Back also drops a pending reply;
  - a snapshot from a LOWER attempt, or an older revision of the same attempt,
    is ignored.
- **Health.** Production requires a numeric `Health > 0`; the fixture sets a
  realistic `Health = 100`.

## R2 (source review #5856278551)

- **Context epoch.** The attempt number changes only at Start and Retry, so
  it cannot bind a horse. The lesson therefore keeps a context epoch
  (`kontextNr`) per player: the bound MODEL instance and the CHARACTER
  instance. A replacement with the same HorseId counts as a new context.
  - It is refreshed at every sync, every request and every step, also without
    an active attempt.
  - A change bumps the epoch and pushes the snapshot, which includes
    `kontextNr` and `hastId`.
- **Mutating requests** carry both the displayed attempt and context:
  - a mismatched context is `stale_context`, answered with the current state
    and actionable guidance;
  - nothing is touched, and a completed frozen result stays;
  - both values are part of duplicate replay;
  - after a fresh sync, Start, Retry and Finish act on the current context.
- **Start** uses the context's model, the one just validated.
- **Client.** Controls carry the displayed context too, and a context change
  bumps the page generation.

## Lifecycle and requests

- **Attempt:** a numbered attempt per player (`forsokNr`), session-local.
- **Frozen result:** owner, horse id, attempt number, travelled metres, led
  seconds, arrival sample count, goal key and start.
- **Retry** (from complete or timeout) needs the horse OUTSIDE the goal (fresh
  travel). There is no teleport out and no reset of preparation.
- **Finish** closes the attempt; the horse and the lead are untouched.
- **Requests:** a monotonic sequence per player; a duplicate replays only the
  same operation; an older sequence is stale; the book is bounded. Owner-only
  events go through `Aktor.klient`.

## Client

- **Where the entry lives:** `UgnetaController.satFotVal(fn)` is used only when
  no mounted lesson panel is installed.
- **Composition and capacity:** composition is the same as for the mounted panel
  (renderer capacity, compact list).
- **Secondary entry:** Naromrade skips it while the care preparation has an open
  question (`data.harVal`). This is the only Naromrade change.
- **Guide:** an outline of the goal rectangle at arena-floor height, from the
  server's goal key. It is refreshed on key change and removed when the target is
  invalid.

## Deferred verification (written, NOT run)

`roblox/tests/ledlektion.spec.luau` uses the ledning-integration setup
(SparService, StallService, HorseService, GameplayService, LedService, a
bound horse and another horse). The horse is moved between explicit
`LedLektion._steg` calls; there is no physics.

**Positive path:**
- valid Start, then leading, travel and arrival; the result is frozen;
- the preparation's own goal acknowledgement still happens.

**Refused starts and freshness:**
- Start while the horse is already inside is refused;
- the historical `malNatt` never counts;
- starting while already leading gives a baseline at Start.

**Wrong horse and identity:**
- leading the other horse gives `wrong_horse`;
- a second player's lesson is independent.

**Shortcuts:**
- `placeraVidMal` or a teleport gives `unknown`;
- a gap gives `unknown`;
- a stationary horse never completes.

**Release:**
- release before the goal gives `released`;
- release after completion keeps the result.

**Breaks and retry:**
- a missing or changed goal gives `target`;
- mounting gives `mounted`;
- Retry needs fresh travel.

**Lifecycle and requests:**
- deadline;
- stale and replayed requests;
- owner-only events.

**Panel:**
- the on-foot entry is visible beside 0..3 cards and is secondary;
- choosing opens the lesson page;
- the mounted menus are unchanged.

**R1, written:**
- a pause in the same session keeps its travel;
- releasing and re-taking the same horse between samples clears the evidence,
  and a fresh baseline follows;
- a replaced character between samples clears the evidence;
- a missing or replaced bound horse resets;
- a retained old Finish callback, through the real page callbacks, never closes
  the newer attempt;
- the server rejects an old attempt's Finish and Retry (`stale_attempt`);
- a reordered older-attempt snapshot never replaces the current one;
- the current attempt's own Finish still works.

**R2, written:**
- an old Retry after A → B while complete is `stale_context`, the result stays,
  and a fresh sync then Retry acts on B;
- an old Start after B → A while closed is `stale_context`, and a fresh sync
  then Start acts on A;
- a same-HorseId model replacement during an active attempt is
  `stale_context` for the old Finish, and the fresh Finish closes;
- a never-started player (ready) whose binding changes A → B gets
  `stale_context` for the old Start, and after a fresh sync the Start acts
  on B;
- A → B is injected through `LedLektion.start(deps)`, because the bench's
  StallService always assigns the same horse. The same-HorseId replacement is a
  real new model.
- **P3:** the R1 client section now reopens through the real Choose entry
  after Finish (asserting each control exists) and re-syncs the client through
  its real sync path after direct handler calls.

**Planned, not written:**
- the care question hiding the entry (Naromrade `data.harVal`), which needs
  preparation data in the panel fixture and is checked in source only;
- no persistent writes: the module requires no save API (a source claim, not a
  test);
- a delayed reply after Back or a reopen: the bench runs `task.spawn` at once,
  so a reply cannot be delayed there. `requestNr` covers it in source;
- death and leaving (the same reset path as a missing character);
- a real LedPrompt → LedBorja chain (covered by ledning-integration);
- rendered layout, touch and SV/EN;
- the engine's real navigation and doors.
