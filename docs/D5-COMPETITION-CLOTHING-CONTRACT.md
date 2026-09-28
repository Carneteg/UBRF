# D5: competition clothing at the clear round entry (option A)

Status: contract written before code, 2026-09-28. **BUILT, LOCAL SUITE GREEN, NOT PHYSICALLY VERIFIED** — READY_FOR_CHATGPT_REVIEW.
Decision: [TOBIAS_DECISION_D5_A_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5867703495)
(1a on at the entry · 2a off at Avsluta/ride end · 3a optional · 4a colour names only · 5a session only), on
[CLAUDE_D5_DECISION_PACKAGE_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5867673148).
Origin: #248 (the catalogue, server authority, preserving the avatar). Base `15a71aa`. Build now; physical test last.

## What is reused unchanged

- `HorseCore/Tavlingsklader`: the only catalogue (`white`/`pink`/`oak`). `idn()`, `giltig()`, `set()`, `alla()`.
- `TavlingskladerService.nya()`, with `starta`/`avsluta` as they are:
  - both entries are verified before anything is written;
  - shirt/pants only;
  - rollback on any fault;
  - its own guards for respawn, `CharacterRemoving`, `Died` and `PlayerRemoving`.
- **No change to the service or the catalogue.**

## State flow (server-authoritative, inside the `clearround` lesson)

| Event | Clothes | Snapshot `klader` |
|---|---|---|
| **`anmal`** (own clothes) | untouched | `nil` |
| **`anmal_<id>`**, where `<id>` ∈ `Tavlingsklader.idn()` | The entry happens **immediately**, with the same guards and result as `anmal`. Then `starta(player, id)` runs **in the background** (it waits on Roblox). | `{ set = id, lage = "laddar" }`, then `"pa"` or `"misslyckades"`. The revision is bumped and the snapshot pushed. |
| `anmal_<anything else>` / wrong case / an asset number | refused (`unknown`/`request`); no entry | — |
| `ga_banan`, `start`, the course, `complete`, `retry` | **stay on** | unchanged |
| **`finish`** (Avsluta), in any state | `avsluta(player, "tavling_slut")` | `nil` |
| **Ride end** (`setRider`: dismount, character gone, death), in any clear-round state | `avsluta(player, orsak)` | the lesson is closed |
| **Lesson switch** away from clear round (no active attempt) | `avsluta(player, "byte")` | — |
| The service's own guards (respawn, `CharacterRemoving`, `Died`, `PlayerRemoving`) | as today | — |

- **A failed load never stops the ride (3a):**
  - The entry stays and the player rides in their own clothes. The service guarantees the avatar is untouched on refusal.
  - The snapshot shows `misslyckades`.
- **Stale result:**
  - If the entry is withdrawn (finish or ride end) while the lookup is still running, `avsluta` bumps the service's generation, so the lookup writes nothing.
  - The lesson ignores a reply for an entry that no longer exists. It never shows `pa` for a withdrawn entry.
- **Other lessons, stable work and free riding never touch clothing** (#248 §2).
- **Session only (5a):** nothing is persisted and no preference is saved.

## Client (presentation; sends only a catalogue id)

- **`ready`/`closed`:** two buttons, because the panel shows at most four rows:
  - **"Kläder: Egna kläder"** cycles Egna → White → Pink → Oak in catalogue order. *Changed during the build:* the order and names come from the **server snapshot** (`kladerVal = {id, namn}` in `ready`/`closed`, built from `Tavlingsklader.alla()`), not from the client requiring the catalogue. So the client decides nothing, and no asset number ever reaches it;
  - **"Anmäl dig"** sends `anmal` or `anmal_<id>`.
  - The choice lives only in the panel. **Nothing is persisted.**
- **Names:** the catalogue's own `namn` ("White Equestrian Set", …), the product name in both SV and EN.
- **The start list/course plan text** gets one line from `klader`:
  - `laddar`: "Tävlingskläderna laddas …";
  - `pa`: "Tävlingskläder: White Equestrian Set.";
  - `misslyckades`: "Tävlingskläderna kunde inte laddas – du rider i dina egna kläder."
- **No preview (4a).**

## Acceptance (`clearround-klader.spec`, KOHERENS; real HorseService/ClearRoundLektion/TavlingskladerService with an **injected catalogue adapter**, default avatar adapter on the bench's character)

1. **Own clothes:** `anmal` leaves Shirt/Pants untouched and gives `klader == nil`.
2. **`anmal_white`:** `startlista` straight away with `laddar`, then `pa`. The Shirt/Pants templates are the catalogue's; the push is seen through the revision.
3. **`finish` in the start list, course plan, `complete` and a restart:** the original is restored. **A ride end (dismount) mid-course and a lesson switch in the start list:** the original is restored.
4. **`retry` and `complete`:** the clothes stay on.
5. **The catalogue refuses** (or has the wrong AssetType): the entry stays in `startlista` with `misslyckades`. The avatar is untouched, and the start and course work.
6. **`finish` while a lookup is paused:** no write afterwards, and never `pa`.
7. `anmal_xyz`, `anmal_White` and `anmal_11268412339` are refused, with no entry and no lookup.
8. **Two players with different sets:** no state leaks between them.
9. **Other lessons:** `anmal_white` is refused (`unknown`).
10. **Nothing persistent** is written.
11. **Client:** the cycle order and the op sent, the texts for `laddar`/`pa`/`misslyckades` in SV/EN, and no asset number in the client.
12. **Falsification:**
    - `finish` does not restore;
    - a ride end does not restore;
    - a lesson switch does not restore;
    - a failed load stops the entry;
    - an unknown set is accepted;
    - a stale result is shown as `pa`.

**Full suite once; re-lock the identity;** `tools/kolla-tavlingsklader.py` stays green (no asset number outside the catalogue).

**Not tested:**
- whether a server-side `ShirtTemplate`/`PantsTemplate` write shows on a real avatar;
- `GetProductInfoAsync`'s response;
- that the catalogue entries exist;
- touch, and the button text length on a phone.

All of these are Studio/network, PHYSICAL TEST LAST.

## R1 (CHATGPT_REVIEW_D5_CHANGES_REQUESTED_20260928, #5868690505)

**One fail-closed hardening in `TavlingskladerService`**, and the only change to the service. The product behaviour is unchanged.

`bindVakter` runs **after** the shirt/pants write. A throw there used to leave the avatar in competition clothes with no session, so no `avsluta` could restore it. Now:
- binding runs under `pcall`, and on any fault every connection already created is disconnected;
- **a session is registered only when all guards are bound**;
- otherwise the exact pre-write state is restored (`aterstall(character, fore)`);
- `starta` returns a normal refusal, **`vakter_foll`**, and never throws.

The clear round shows `misslyckades`, and the entry and ride continue in the player's own clothes.

