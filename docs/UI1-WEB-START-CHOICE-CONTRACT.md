> **DELVIS ERSATT (produktbeslut 2026-10-04).** Allt som beskriver att spelaren själv hälsar, kollar, ryktar, kratsar, hämtar och lägger på sadel och träns eller leder hästen gäller inte längre. Det som gäller kvar: startvalet vid boxen har nu ETT val, «Rida nu». Se `docs/PRODUCT-CANON.md`, «Produktbeslut 2026-10-04».

# UI-1 web: the start choice at the box shows only the two real paths

Status: contract written before code, 2026-09-28.
Order: #264 comments [5872220574](https://github.com/Carneteg/UBRF/issues/264#issuecomment-5872220574) (the UI correction) and [5872572178](https://github.com/Carneteg/UBRF/issues/264#issuecomment-5872572178) ("web/Vercel in the same delivery").
Decision: TOBIAS_DECISION_WEB_PARITY_UI_20260928 (#264 5872636980). The Roblox-first pause is lifted **for this UI component only**. Claude builds, tests and pushes; **Tobias deploys to Vercel. Claude triggers no deploy.**
Base: `eb9dc0f` (Roblox UI-1, `docs/UI1-START-CHOICE-CONTRACT.md`). UI-2 (the Ugneta box) and UI-3 (the language gate) are separate packages.

## Today on the web (read in the source at `eb9dc0f`)
- **There is no "Rida nu" on the web.** The only preparation done by someone else is `introForberedd()` (`src/intro.js:96`). It runs automatically on the first pass, only partly prepares the horse, and the player never chooses it.
- **At the horse** (`world.js:888`, "Sköt om … vid boxen"), `visaBoxmeny()` (`src/sysslor.js:208`) opens straight into four actions (the rug, mucking out, feeding, "Visitera, rykta, kratsa, sadla") plus "Stäng", in hard-coded Swedish.
- **Day form on the web** is `utvarderaSkotsel` (`src/model.js:795`), which gives penalties for skipped care. Roblox uses `RidKanon.START.DAGSFORM` (0.7, **shared with the web**: `src/riding/svar.js:178`) plus a small bonus for the player's own share (`GameplayService.dagsformFor`).

## What is built
**1. The start screen at the box (`visaBoxmeny`).**
- **When:** the player has the horse at the box and nothing is done yet: no `G.skotselRes`, `mockat == 0`, `fodrat == 0`, and not yet chosen "själv" for this horse today.
- **What the overlay shows, exactly:**
  - header `guide.valj_rubrik` ("Välj hur du börjar");
  - one short text, `guide.valj_kort_webb` (new, SV/EN);
  - **two** buttons: `#bRidaNu` "Rida nu — {horse}" (`guide.val_rida_nu`, the primary one) and `#bSjalv` "Gör i ordning {horse} själv" (`guide.val_sjalv`).
  - **No** chore rows, **no** "Stäng", and **no** greeting answers.
- **Language:** all text goes through `tSpr`, never hard-coded, so the whole screen follows `SPRAKET`.

**2. "Gör i ordning … själv"** sets `G.startvalSjalv = G.hastId` and opens today's box menu **unchanged**. The whole manual chain is untouched. The choice is cleared at the start of a new day, next to `G.utrustning = false`.

**3. "Rida nu": the stable prepares the horse correctly (no shortcut that teaches the wrong handling).**
- **The rug:** off.
- **Equipment:** the horse's **own** saddle and bridle, fetched by the stable (`G.utrustning = true`). `felUtrustning` is not touched.
- **Care values:** everything that must be right *is* right:
  - saddle position at `SADEL_RATT`, withers clear, girth in three pulls and inside the band;
  - bit checked;
  - all visitation points looked at;
  - grooming and hooves done.
  - These values run through the existing `utvarderaSkotsel`, so the saddle position and the risks are computed by the web's own rule. **No risk may remain.**
- **Day form:** `START.DAGSFORM` (the same value as Roblox with own share 0). The web's existing rest rule for a tired horse still applies (−0.08), because that is the horse's condition, not the preparation.
  - **No** care bonus, **no** skill progress (`fardighetSkotsel`), and **no** penalty remarks: the player did not do the work, and was not punished for not doing it.
- **The box chores** (mucking out, feeding) are **not** horse preparation, so the stable does not do them. `stallro` is computed from them exactly as today.
- **Welfare first (the stable's finding):** if today's visitation has a finding (`VIS.fynd`), the stable **has seen it**, but the decision stays with the player:
  - the overlay shows `guide.stallet_fynd_rubrik`, the finding text (`VISITFYND` / `VISITFYND_EN`) and the three `VISITSVAR` answers in the chosen language;
  - a wrong answer gives `forb.inte_ditt_beslut` and the question stays;
  - only the right answer lets the ride continue.
  - (Same rule as Roblox `autoForbered`: the stable never answers for the player.)
- **After Rida nu**, the ride starts the same way as after the player's own care, through the same code in `avslutaSkotsel` (the horse's mood, the ride state, NPCs and the start position). The game then tells the player, in `guide.rida_nu_klar_webb` (new), that the horse is ready and should be led out: `G.hastPlats = "leds"`.
  - **Platform difference (declared):** on the web the player leads the horse to the arena. The web has no path where the stable moves the horse, and mounting requires `G.leder` at the arena gate. That is why the web text says "du leder ut", while Roblox says "stallet leder henne till ridhuset". **Nothing is invented about UBRF**, and the physical truth about where the horse stands holds on both.

**4. Texts:** new keys `guide.valj_kort_webb`, `guide.stallet_fynd_rubrik` and `guide.rida_nu_klar_webb`, in SV and EN, **without pronouns** (horses are both "han" and "hon"). They go through the export to `roblox/game/UBRFSprak.luau`, which only adds keys. The Roblox runtime is re-locked (kallhash) because the export file changes.

**Unchanged:**
- the assignment (`visaTilldelning`) and the saddle room;
- the box menu after "själv";
- the care canvas;
- the first pass with `introForberedd`;
- the evaluation after the player's own care;
- all riding.

## Acceptance (new `tools/startvaltest.mjs` against `dist/`, plus existing tests)
1. At the box with nothing done: the `#sheet` overlay has **exactly 2** buttons, `#bRidaNu` "Rida nu — {horse}" and `#bSjalv` "Gör i ordning {horse} själv". There is no `#bMocka`, `#bSkots` or `#bStang`, and no greeting text.
2. **`#bSjalv`** leads to the box menu (`#bSkots` exists). The box again the same day goes straight to the box menu.
3. **`#bRidaNu`, a day without a finding:**
   - `G.skotselRes` is set with **0 risks**, `G.dagsform == START.DAGSFORM` (rested horse), `G.utrustning`, and `!G.tackePa`;
   - the skill value is unchanged, and `G.hastPlats == "leds"`.
4. **`#bRidaNu`, a day with a finding:**
   - the finding question is shown with 3 answers;
   - a wrong answer means no `skotselRes` and the question stays;
   - the right answer gives `skotselRes`.
5. **`SPRAKET = "en"`:** "Ride now — {horse}" and "Get {horse} ready myself". The screen contains no Swedish key words.
6. Existing tests (`forstadagentest`, `uppdragstest`, `p0-qa-runner`) go through `#bSjalv`, and the manual chain stays green. `sprakgrind`, `bootkoll` and `kolla-forstadagen.py` stay green.
7. **Falsification (on committed source):**
   - the start screen never shows;
   - the chores remain on the start screen;
   - "själv" doesn't take effect;
   - Rida nu gives the care bonus (full `utvarderaSkotsel` day form);
   - Rida nu skips the finding question.
8. Build `python tools/build.py`. Roblox `kor.sh` green after the export, then re-lock.

**Report:** the exact web files, the test results and the commit SHA. **Tobias deploys and supplies the Vercel URL.** Visual verification in a browser is done at desktop size and iPad landscape (1180×820) with a screenshot through Playwright. `NOT_TESTED` is declared honestly.

## Observed, not fixed (outside UI-1)
On the web, a visitation finding (for example "Höger framben är varmare än vänster") does **not** stop the ride after the right answer "Säg till ridläraren" (only +0.05 day form). Roblox stops it (`forb.lararen_tar_over`). This is a parity/welfare difference that exists today, and UI-1 does not change it. **This needs a separate decision.**
