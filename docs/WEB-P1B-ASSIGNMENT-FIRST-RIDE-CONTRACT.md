# Web P1b: automatic assignment and First Ride, as in Roblox

Status: contract written before code, 2026-09-29.
Order: PROGRAM ORDER #266 [5882885526](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5882885526) § 1. Audit: `docs/WEB-ROBLOX-PARITY-AUDIT.md` (P1, first two rows).
Base: `0889d1b` (P1a R1).

**Roblox is the truth. The rule is ported, not invented. No Roblox behaviour changes.** Tobias deploys; Claude triggers no deploy.

## Roblox, read in the source
- **Assignment** (`StallService.tilldela` → `Stallet.tilldelaLedig`, `roblox/game/Stallet.luau:199`):
  - It happens **automatically** at join; there is no assignment screen.
  - **The first day** (`Sparning.forstaDagen(save)`) asks for `blackrock_jack`. If he is **resting** (welfare) the answer is `nil` (wait), and no substitute is given. If he is **taken** by another player on the same server, the rotation takes over.
  - **Otherwise:** the rotation `ordning[(UserId % n + steg) % n + 1]`, skipping taken or resting horses. `ordning` is `Object.keys(HORSES)` from `src/spel/hastar.js` (the export `UBRFSpelData.luau`).
  - **No horse** → `nil`, and the player waits (`spel.ingen_hast` "Du har ingen tilldelad häst").
- **First Ride** (`roblox/src/server/ForstaRitten.luau`):
  - **Applies only when** the save was read **reliably** (`SparService.betroddLasning`) **and** it is session 1 (`Sparning.aktuelltPass(save) == 1`). An unreliable read → **no** First Ride (fail closed).
  - **What happens:** the assigned horse and the player are moved to the arena (`LedService.stallFram`, which **books nothing**: the leading is not credited), the tack is put on **physically** (`TackService.satPa`), and the player is **mounted** (`HorseService.tryMount`).
  - **The care checklist stays undone.** No moment is marked as the player's own **or** the stable's. Day form `dagsformFor` = 0.70 + 0.06 × 0 = **0.70**.
  - After a counted session, First Ride no longer applies.

## What is built on the web

### 1. Automatic assignment (`src/uppdrag.js`, `tilldelaDagensHast`)
- **When:** at the day's start (`startaVandring`), for an ordinary day. The competition day is a side activity (Tobias decision 2026-09-28) and keeps its assignment by the instructor.
- **The rule is a port of `Stallet.tilldelaLedig`:**
  - wish = Jack when `SPAR.pass === 0` (the web's session 0 = Roblox's session 1, the same mapping as in P1a);
  - resting = `hastVilarForSkada(id)` (the web's welfare lock);
  - taken = none (the web has one player);
  - rotation = `Object.keys(HORSES)` from the player's number.
- **The player's number:** Roblox uses `UserId`; the web has no platform identity. The web profile therefore gets `SPAR.spelarId`, a random 32-bit number created **once** per profile and saved with it. It is used exactly as `UserId`: the same horse on the same profile until she is resting. **This is an implementation mapping, not a platform exception:** the player outcome is the same (a stable, deterministic horse per player).
- **No horse** → no card, and the saga shows `spel.ingen_hast` (the Roblox string). The old modal `visaIngenHastIdag` is **not** in the main path.
- **The instructor** in the stable keeps "Byt häst hos ridläraren" as a **side activity** (the web's horse swap, PO 2026-09-06). There is no assignment objective "Prata med ridläraren" in the main path.

### 2. First Ride (`src/stegkort.js`, `forstaRitten`)
- **Applies only when:**
  - the profile was read **reliably**: `SPAR_BETRODD`, true when localStorage was **empty** (a truly new player) or held a **valid** profile, false when the read threw or the data was corrupt (the same fail-closed direction as Roblox);
  - `SPAR.pass === 0`;
  - an ordinary day;
  - a horse was assigned.
- **What happens:**
  - the horse and the player are placed at the arena gate, with the horse at hand;
  - tack is on (`G.utrustning`);
  - the ride state is built with day form `Forb.dagsform` (**0.70**, own share 0);
  - the player is **mounted** through the same mount code as `sittUpp` (the lesson starts).
- **The preparation state (`G.forb`) is not touched:** no `gjorda`, no `klara`, not even "auto". This is exactly Roblox's "the checklist stays undone".
- **Menu:** "Rid nu" on session 0 leads **directly** to First Ride. Before, it led to the yard, and the player walked to the instructor.

### 3. Returning players
`SPAR.pass > 0` or an unreliable read → automatic assignment and the P1a flow at the box (start choice, step card), unchanged.

## Acceptance
1. **`tools/forberedelsetest.mjs`, parity against Luau:** `roblox/tests/forberedelse-webb.spec.luau` prints `Stallet.tilldelaLedig(uid, {}, resting, wish)` for many (uid, resting set, wish) combinations, and the web's `tilldelaDagensHast` gives **the same horse or nil** for each one: Jack on the first day; Jack resting → nil; the rotation from the uid; resting horses skipped.
2. **`tools/stegkorttest.mjs` (Playwright):**
   - **A fresh profile:** menu "Rid nu" → `G.scen === "lektion"`, the horse Blackrock Jack, day form 0.70; `G.forb` has **no** completed moments; no assignment modal was shown.
   - **A returning profile (pass ≥ 1):** "Rid nu" / "Till stallet" → the yard, a horse assigned **without** the instructor, the same horse as the rotation gives for `spelarId`, and the step card's "Gå till …".
   - **An unreliable read** (corrupt profile in localStorage) → **no** First Ride.
   - **Jack resting on day 1** → no horse, and the saga shows "Du har ingen tilldelad häst"; no modal.
3. **Existing tests** are rewritten to the new start (`forstadagentest`, `p0-qa-runner`, `gardtest`, `uppdragstest` as far as they assume the instructor), not deleted.
4. **Falsification:**
   - First Ride on a returning profile;
   - First Ride on an unreliable read;
   - First Ride marking care as done;
   - the rotation with a different start index than `uid % n`;
   - Jack resting giving a substitute.
5. **Build**, the whole web suite + `MOBIL=1`, `kor.sh`, and re-locking if a mapped file changes.

## NOT_TESTED by design
Several players on the same server ("taken"): the web has no multiplayer.
