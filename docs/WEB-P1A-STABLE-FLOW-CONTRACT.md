# Web P1a: the stable flow as in Roblox (the step card, the start choice, Rida nu, the welfare stop)

Status: contract written before code, 2026-09-28.
Order: #264 [5872806726](https://github.com/Carneteg/UBRF/issues/264#issuecomment-5872806726) / [5872897649](https://github.com/Carneteg/UBRF/issues/264#issuecomment-5872897649). Audit: `docs/WEB-ROBLOX-PARITY-AUDIT.md` (P1).
Decisions:
- TOBIAS_DECISION_WEB_PARITY_UI_20260928 (the web too; Tobias deploys);
- TOBIAS_DECISION_WEB_EXTRAS_VISIBLE_20260928 (the extras stay as side activities, never a requirement in the main path).

Base `33f513d`. **Roblox is the truth. Nothing about UBRF is invented. Claude triggers no deploy.**

P1 is split in two: **P1a** (this one) is the stable flow at the horse; **P1b** is automatic assignment + the first ride mounted in the arena.

## What is built

### 1. `src/forberedelse.js` (new): the web's port of `Preparation.luau`
It ports intent, rules and parameters, **not** the Luau code line by line. The data comes **only** from `src/spel/skotsel.js` (FASER, HALSNING, VISITPUNKT, RYKTREDSKAP / RYKTKRAV / RYKTZON, HOVAR, SADELFAS, VISITSVAR, VISITFYND).
- **The moment lists per phase, as in Roblox:**
  - `halsa` is a choice (one wrong option);
  - `visitera` has 5 points in order;
  - `rykta` is tool × zone type, with the step = the tool's index;
  - `iordning` is hooves vf/vb/hb/hf, then `utr:1–5`;
  - `leda` is a single moment.
- **Functions:** `nyState(hastId, pass)`, `moment`, `arVal`, `nastaMoment`, `fasKlar`, `nasta`, `redo`, `provaMoment` (the same refusals, in the same order: stop → wrong horse → open finding → phase → already done → wrong option → wrong turn), `utforMoment(…, utforare)` ("auto" is kept apart from the player; a manual moment is never downgraded), `svaraFynd`, `provaUppsittning`, `egenAndel`, `autoForbered` (never `leda`, never a wrong option).
- **`fyndFor(hastId, pass)`:** the **same** FNV/LCG constants and `FYNDCHANS 0.42`, and **pass 1 is always clean**. The same horse and pass give the same finding on both platforms.
- **Tack at the box front:** saddle and bridle are fetched there ("Ta sadeln" / "Ta tränset") before `utr:1` and `utr:5` respectively, as in Roblox (`tack.hamta_forst`). The saddle room's tack matching remains as a side activity, but it is **not** the way in the main path.

### 2. `src/stegkort.js` (new): the web's Näromrade panel
- **Placement:** bottom-left, dark (`24,27,33` at 0.88 opacity, radius 8, 300px wide). On iPad landscape it uses at most 34 % of the width.
- **Hierarchy, as in Roblox:** header → instruction → ≤4 choice buttons → ≤3 rows → "+ Fler handlingar · n/m" → a gold feedback line. Only the primary action gets the accent.
- **Cards in the order of `Naromrade.guideSteg`:**
  - `ga_till` "Gå till {horse}";
  - `valj` "Välj hur du börjar", with **exactly** the two buttons;
  - `halsa`, `visitera` (n/m), `rykta` (n/m), `hovar`, `hamta_sadel`, `hamta_trans`, `sadla`, `transa`, `leda`, `sittupp`.
  - The finding: "Du hittade något" + the finding + 3 answers in their original order.
  - The stop: "Ridläraren tar över".
- **Texts:** all through `tSpr` (`guide.*`, `hud.*`, `forb.*`, `tack.*`). The care content uses `skotsel.js` `*En` when `SPRAKET === "en"`. **No hard-coded Swedish in the panel.**
- **Input:** a click, or touch on the buttons; **E** runs the primary action. This is the declared platform difference: Roblox uses ProximityPrompts with a hold.
- **"Fler handlingar":** the side activities at the box (mucking out, feeding, the rug, the whiteboard).

### 3. The start choice, "Gör i ordning … själv", and "Rida nu"
- **The start choice** appears at the horse when nothing is done; it is stopped by a finding or a stop, as in Roblox UI-1.
- **"Själv"** follows the manual chain through `forberedelse.js`.
- **"Rida nu"** runs `autoForbered` through the real moments with `utforare = "auto"`. It fails closed, and stops at the finding. Then the horse and the player are moved to the arena gate: `gaTill("ridhusinne")`, `hastPlats = "leds"`, and the `leda` moment is signed off. The panel then shows "Sitt upp på {horse}".
- **Day form:** `SVAR_START.DAGSFORM + 0.06 × egenAndel` (the same as `GameplayService.dagsformFor`).
- **Saddle position:** `SVAR_START.SADELLAGE` (the same starting point as Roblox; the preparation is correct).
- **No evaluation table** in the main path, as in Roblox, which has none.

### 4. The welfare stop, as in Roblox
The right answer to the finding makes the instructor take over: `stoppad`, and "Sitt upp" is refused (`forb.lararen_tar_over`).
**This changes the web's behaviour today, where a horse with a finding was ridden anyway.**

### 5. The old left "Uppgift" box
`visaUppgift` / `#moment` is **not** shown during walking and preparation. The panel replaces it. During riding, `#moment` shows the exercise as before (P3).

### 6. The old main path
The main path no longer runs through the box menu, the care canvas or `avslutaSkotsel`:
- **The box menu** stays as a side activity under "Fler".
- **The care canvas** stays in the code, but is **not** reachable from the main path.

The whiteboard's list is updated to show the new chain.

## Unchanged in P1a
- the assignment through the instructor (P1b);
- the first pass's `introForberedd` (P1b takes over with the first ride);
- riding, lessons and results (P3/P4);
- competitions, forest trail, the outdoor arena, the character creator and the rest of the extras.

## Acceptance
**1. `tools/forberedelsetest.mjs` (node, new):**
- the moment lists match Roblox's structure: counts per phase; `halsa` a choice with 1 wrong option; 5 visit points; rykta 6 (1+2+3) in tool order; hooves 4 + `utr` 5;
- the refusal order;
- a wrong option never moves anything forward;
- `autoForbered` never takes `leda` or a wrong option;
- `egenAndel`: all manual = 1, all auto = 0, mixed;
- `fyndFor`: pass 1 = nil. **Cross-check against Luau:** the same (horse, pass) pairs through `roblox/src/shared/HorseCore/Preparation.luau` give the same result (luau is run in the test when available, otherwise `NOT_TESTED`).

**2. `tools/stegkorttest.mjs` (Playwright against `dist/`, new):**
- at the horse with nothing done: **exactly 2** buttons, "Rida nu — X" / "Gör i ordning X själv";
- "själv" → "Hälsa på X" + 3 greeting choices (quiz today; UI-2 changes that on **both**);
- the manual chain gets all the way to "Sitt upp på X", and day form = 0.76;
- Rida nu → in the arena, `leds`, day form 0.70, "Sitt upp på X";
- a finding day: the finding question; a wrong answer → `forb.inte_ditt_beslut`; the right answer → "Ridläraren tar över" and mounting refused;
- `#moment` hidden while walking;
- **English:** no Swedish words in the panel (a list of forbidden words, e.g. "Välj", "Gör i ordning", "Hälsa", "Rykta");
- iPad landscape 1180×820: the panel ≤ 34 % of the width and fully visible; desktop 1600×900.

**3. Existing tests**, rewritten to the new main path, **not deleted**: `forstadagentest`, `uppdragstest`, `p0-qa-runner`, `gardtest`, `uppdragsetikett-test`, and the rest of `fore-leverans.py --run` as far as it runs on Windows.

**4. Falsification (on committed source):**
- the start screen with more than 2 buttons;
- a wrong option counted as done;
- `autoForbered` counted as the player's own (bonus);
- the stop not stopping mounting;
- the panel text hard-coded in Swedish in English;
- `fyndFor` with a different constant.

**5. Build:** `python tools/build.py`, `node tools/sprakgrind.mjs`, `node tools/bootkoll.mjs`. The Roblox `kor.sh` stays green if the export is touched.

**Report:** `HANDOFF_READY_FOR_CHATGPT` with the exact web files, the tests, the falsification, the SHA, and screenshots (desktop + iPad landscape). **Tobias deploys; Vercel is not triggered.**
