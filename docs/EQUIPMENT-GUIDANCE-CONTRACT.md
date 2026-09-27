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

**Planned, not written:**
- order, already-on, target and leading or riding refusals in the guidance
  panel (existing reasons and texts; only the texts are reused);
- the Naromrade composition with a care question and the correction choice;
- a delayed reply after the correction changed;
- rendered layout, touch and SV/EN.
