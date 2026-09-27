# Wrong equipment: guidance and a real return (saddle and bridle)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [EQUIPMENT_GUIDANCE_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856325151),
base 586323d. Build now, test last. Claude writes; Codex reviews source;
Tobias playtests the whole at the end.

This is ONE equipment slice. It covers the catalogue row for the equipment
instruction and the row "wrong equipment: guidance without a hidden penalty".
It is not the whole equipment area, the helmet cycle or the HRAG attachments.

## What exists (read in source)

- **Taking equipment:** `TackForradService` hangs each horse's saddle (with its
  pad) and bridle on the horse's OWN box front. Their prompts call
  `GameplayService.valjEn`, which:
  - is a transaction: build the carried part, then hide the front group, then
    commit;
  - records ownership in `burenAv[hastId/typ]` (one carrier per item);
  - refuses a second item of the same type with `tack.bar_redan_annan`.
- **Putting it on:**
  - `GameplayService.sadla` / `transa` lead to `TackService.satPa`;
  - a wrong horse's item is refused (`tack.fel_sadel` / `tack.fel_trans`)
    BEFORE anything is attached;
  - a refusal consumes nothing: the item stays in the hands and the horse is
    untouched;
  - the diagnostic counter `felUtrustning` counts it.
- **The view:** `vy.burenUtrustning = { hastId, hastnamn, delar }` is the
  server's truth about what is carried; `vy.hastId` is the assigned horse.
- **The gap: no user return.** `valjEn`'s own note says the player must
  return the first item before taking another, but the only release paths are
  `slappBuret` (leaving, character lost) and attaching. When the item is
  taken, the front group and its prompt are hidden, so the front cannot be used
  to return it. A player holding the wrong saddle is therefore stuck, and the
  existing reason text promises an action that does not exist.

## Narrow new dependency: an explicit return

**`GameplayService.lamnaTillbaka(player, typ, forvantatHastId)`**, through the
remote `LamnaTillbaka` with its own Skopa limit (`tak = 4`, `pafyll = 1`, like the
other equipment handlings).

- **Validation:** each check refuses with its own reason and changes nothing.

  | Check | Reason |
  |---|---|
  | `typ` is `sadel` or `trans` | `tack.okand_utrustning` |
  | the player carries one | `tack.bar_inget` |
  | what they carry is `forvantatHastId` (stale intent) | `tack.bar_inte_den` |
  | the registry says THIS player took it (`burenAv`); "Rida nu" builds carried parts without a registered pickup and is never returned through this path | `tack.kan_inte_lamnas` |
  | the front of the item's OWN horse exists | `tack.ingen_front` |
  | the player is within `STEG_RACKVIDD` of it, the same reach as taking | `tack.ga_till_fronten` |
  | the front is empty, so nothing is duplicated | `tack.front_upptagen` |

- **Transaction** (the reverse of `valjEn`): show the front group, then release
  the carried part, then commit.
  - If the front cannot be shown, nothing changed.
  - If the release fails, the front is hidden again (rollback) and the reason
    is `tack.kunde_inte_slappas`.
- **Commit:**
  - clear `burenAv` and that type in `valdUtrustning`;
  - push the view.
- **Nothing else:**
  - it never disposes of another item, never teleports equipment and never
    equips anything;
  - it grants no progress and no reward;
  - it does not touch the counter `felUtrustning`, welfare, daily condition,
    stamina or score.

## Guidance (client, existing owners only)

PreparationController derives a CORRECTION from each view:
`burenUtrustning.hastId ≠ vy.hastId`, while not riding. Because it is derived
from every view push, it survives pushes and disappears by itself once the
item is returned, the assigned horse changes or the character is lost.

- **Text:** the instruction line says whose item is carried and what to do (SV
  and EN), for example "You are carrying Larry's saddle. Take it back to his
  box front, then fetch Bella's." A timed refusal text keeps priority while
  shown; the correction returns after it.
- **Action:** a choice "Take X's saddle back" (or bridle) is first in the
  existing panel choices, via PreparationController's `panelVal`. With a
  correction the panel's choices are shown even away from the assigned horse,
  because the return happens at the OTHER front; the server judges reach. The
  choice sends `LamnaTillbaka(typ, hastId)`.
  - On success: a confirmation, and the view push clears the correction.
  - On refusal: the reason (for example "go to X's box front").
- **Stale replies:** a reply is shown only if the correction it was sent for
  is still the current one, so a late reply never erases newer feedback.
- **Other refusals** (wrong target horse, order, already on, reach, leading or
  riding, build failure) keep their existing reason texts. No text is parsed.
- **Other surfaces:** the care question priority, the on-foot leading entry
  and the mounted menus are unchanged. There is no second toast or panel.

## R1 (source review #5856404802)

- **Per held item, from the physical state.** The summary
  `burenUtrustning` (`Preparation.buren`) deliberately omits a type the
  ASSIGNED horse already wears and collapses mixed owners, so a real wrong item
  could be invisible. The view now also carries `burnaDelar`: one entry per
  physically carried type (`TackService.barBuren`), with the owner horse,
  whether THIS player registered the pickup (`burenAv`) and the pickup's
  acquisition number. The summary is unchanged for its existing consumers.
  The correction lists every wrong, registered held item.
- **Bound intent.** Each registered pickup gets an acquisition number
  (`burenForvarv`), cleared on return, `slappAgande` and `slappBuret`. A
  return carries the displayed item, acquisition and assigned horse, and the
  server refuses a mismatch as `tack.inaktuell`. A delayed old return after the
  same item was hung back and fetched again, or after the assigned horse
  changed, never touches the newer state.
- **Client.** Every render, including the early branches (welfare stop,
  finding, aftercare, counted pass), kills older return choices. There is one
  numbered pending return at a time (a new one after 10 s without a reply).
  A reply only applies to its own request, so an older reply is dropped. A
  refusal is shown only if the same item (acquisition and assignment) is still
  held, so a success view arriving before the reply never produces a false
  refusal, and the confirmation comes with the reply.
- **Question priority.** While a care question is open (`fragaNu`) the
  question keeps its text and choices, and the correction waits. The Naromrade
  consumer takes the care choices (`data.val`) when Ugneta's non-secondary
  buttons are absent. Corrections are at most two entries, within the four
  rows.

## R2 (source review #5856458359): replies bound to their moment

History: R1 bound a reply only to its own request number. That was not enough.
A delayed old success could replace newer feedback, and a delayed refusal could
overwrite a priority question.

- **Context generation.** `kontextGen` is bumped at the end of every view whose
  context differs from the previous one: the assigned horse, or whether a
  PRIORITY view is shown. The priority views are a care question, welfare
  stop, finding, aftercare and a counted pass. `prioritetNu` is true while
  one is shown.
- **At dispatch** a return captures `kontextGen`, the character and the
  panel's feedback counters (`avslagNr`, `bekraftelseNr`).
- **A reply** (success or refusal) is shown ONLY if all of these hold:
  - it is the same request;
  - the context generation is unchanged;
  - the character is the same;
  - no newer feedback has been shown;
  - no priority view is shown now.

  Otherwise nothing is shown.
- **Its own removal view** changes none of these, so a legitimate success whose
  view arrived first still confirms.
- **Queued clicks.** Validity (render generation and no priority view) is
  checked again immediately before dispatch, so a queued click that crossed
  such a change is not sent.
- **Unchanged:** the server's acquisition guard, the real-held producer, the
  10 s pending bound, and ownership, reach and rollback.

## Deferred verification (written, NOT run)

`roblox/tests/utrustning-rattelse.spec.luau` (KOHERENS, set up like
tack-fas2) contains these written cases.

**Wrong saddle and its recovery:**
- a wrong saddle is refused with the item kept, the horse untouched and no
  progress;
- `felUtrustning` counts it and nothing else changes;
- the return far from the item's front is refused with `tack.ga_till_fronten`;
- at the front the return succeeds: the front shows the saddle, the hands
  are empty and ownership is cleared;
- the player then fetches the right saddle and saddles.

**Wrong bridle:**
- a wrong bridle is refused, then returned, then the right one is fetched.

**Refused returns:**
- nothing carried gives `tack.bar_inget`;
- stale intent (a different expected horse) gives `tack.bar_inte_den`;
- an occupied front gives `tack.front_upptagen`;
- a failed release rolls back.

**Other players and paths:**
- a second player cannot return another player's item (their hands are
  their own);
- a "Rida nu" carried part is not returnable through this path.

**Client guidance:**
- the correction is derived while a wrong item is carried;
- it disappears after the return.

**R1, written:**
- the producer reports a held item with its acquisition;
- a return with a stale assignment is `tack.inaktuell`;
- after hang-back and re-fetch of the SAME item, the old return is
  `tack.inaktuell` and the new pickup stays;
- producer to client, with the REAL producer's `burnaDelar` in the view:
  - B is already saddled and bridled while A's saddle and C's bridle are held
    (the summary would have omitted them, and the owners are mixed), and both
    corrections are listed within four rows;
  - an early-return view (welfare stop) kills the old choice, so no request is
    sent (a counted handler);
  - after an assignment change the old choice stays dead;
  - an open care question keeps priority;
  - after the returns the corrections are gone.

**R2, written** (using a local deferred-transport fixture: `InvokeServer` is
replaced by one that captures the call and yields its coroutine, and replies
are delivered in a chosen order; this assumes the bench's `task.spawn` runs a
coroutine, which a KONTROLL checks):
- a normal success whose removal view came first still confirms;
- an old success after an assignment change shows nothing;
- an older success never replaces a newer refusal;
- an old refusal never overwrites an open care question, nor a welfare stop;
- reversed replies after the timeout: the newer reply confirms, and the older
  reply arriving later is dropped.

**Planned, not written:**
- an old reply after a real character replacement (the check is the same
  identity comparison, but the fixture keeps one character);
- the full LocalPlayer chain (server push through PreparationSync to the
  client): the view is built with the real producer's data but sent through
  the listener;
- order, already-on, target and leading or riding refusals in the guidance
  panel (existing reasons and texts; only the texts are reused);
- the Naromrade composition with a care question and the correction choice;
- a delayed reply after the correction changed;
- rendered layout, touch and SV/EN.
