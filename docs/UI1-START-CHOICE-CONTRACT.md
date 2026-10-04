> **DELVIS ERSATT (produktbeslut 2026-10-04).** Allt som beskriver att spelaren själv hälsar, kollar, ryktar, kratsar, hämtar och lägger på sadel och träns eller leder hästen gäller inte längre. Det som gäller kvar: startskärmen har nu ETT val, «Rida nu» (inget «Gör i ordning själv»). Se `docs/PRODUCT-CANON.md`, «Produktbeslut 2026-10-04».

# UI-1: the start screen shows only the two real paths

Status: contract written before code, 2026-09-28. **BUILT, LOCAL SUITE GREEN, VERIFIED IN STUDIO (engine), NOT VISUALLY VERIFIED** — READY_FOR_CHATGPT_REVIEW.
Order: [#264 comment 5872220574](https://github.com/Carneteg/UBRF/issues/264#issuecomment-5872220574) ("one coherent change at a time"). This is **the first of three packages**:
- **UI-1** (this one): the start screen;
- **UI-2**: the Ugneta box on top, the action box below, the strip integrated, and guidance instead of a quiz;
- **UI-3**: the language gate.

Base `9121186` (runtime `kallhash 3217c09395f2`). **No change to the game rules.** Physical test last.

## Reproduced in Studio (MCP, Play, `3217c09395f2`, Swedish selected)
At Troy (nothing done), the panel shows:
- the header "Välj hur du börjar", and an instruction that mixes the choice and the greeting question;
- **the three greeting answers** as buttons ("Framifrån, och säg hennes namn" / "Från sidan vid bogen …" / "Rakt bakifrån, tyst");
- a row **"Rida nu — Troy [Håll inne R]"**;
- **"+ Fler handlingar · 1/2"**.

This is exactly what the order says must not be on the start screen.

## What is built
- **`InteractionController.ridaNu()`** (new, exported): the body of `RidaNuPrompt.Triggered`, moved out unchanged (`InvokeServer`, refusal to the panel, `uppdatera`). The prompt calls it exactly as before, so there is **one truth** for what "Rida nu" does.
- **`Naromrade`, the start screen:** when the horse is within reach, nothing is done (`halsa`, `klaraFaser == 0`), the context is care, and no correction applies, **and the player has not yet chosen to do it themselves**, the panel shows exactly:
  - the header **"Välj hur du börjar"**, with a short instruction (**no** greeting question): "Rida nu: stallet gör i ordning {horse} rätt och leder henne till ridhuset. Eller gör i ordning henne själv — steg för steg.";
  - **two** choice buttons: **"Rida nu — {horse}"** (the primary one, calling `InteractionController.ridaNu()`) and **"Gör i ordning {horse} själv"**;
  - **no** prompt rows, **no** "+ Fler handlingar", and **no** greeting answers.
- **After "Gör i ordning … själv":**
  - the greeting step is shown: the header **"Hälsa på {horse}"**, the phase's own question, and the greeting choices (UI-2 turns this into guidance instead of a quiz);
  - the choice is session-local per horse, and is cleared when the player is mounted or the horse is ready. It is never saved.
- **"Rida nu":** afterwards the view is `redo`, so the card says "Sitt upp på {horse}", as today.
- **Texts:** new keys `guide.valj_kort`, `guide.val_rida_nu`, `guide.val_sjalv`, `guide.halsa_rubrik` (SV/EN). `guide.valj_text` is removed.

**Unchanged:**
- the door step and "Gå till …";
- the whole manual chain after the greeting;
- the horse marker, the feedback field, corrections, welfare stops, aftercare, riding and `MINIMAL_UI`;
- the "Rida nu" prompt in the world.

## The language bug: **not reproduced** (it is handled in UI-3)
In Studio (`3217c09395f2`) I switched language through **the player attribute** and through **`Sprak.satVal`**, the strip's button, in both directions.
- The panel (header, instruction, choices, rows, "Fler") and Ugneta's strip were **entirely** in the chosen language every time.
- The world prompts (doors, gate, Rida nu, saddle, bridle, box) were also entirely Swedish.

**Tobias: a screenshot or the exact step where the mix was seen would help.** UI-3 adds a gate that fails on any mixed string in the component.

## Acceptance (`klient-guide.spec`, updated)
1. **The start screen:**
   - exactly 2 choices, "Rida nu — Trixie" and "Gör i ordning Trixie själv";
   - **0 prompt rows**, **no** "Fler", **no** greeting answer;
   - the instruction has no greeting question.
2. **"Rida nu"** calls `InteractionController.ridaNu`, which reaches the server's `RidaNu` in the bench. After `autoForbered`, "Sitt upp på …".
3. **"Gör i ordning … själv"** leads to "Hälsa på Trixie", with the question and the greeting choices. The rest of the manual chain is unchanged.
4. **The prompt still works:** `RidaNuPrompt.Triggered` goes through the same function.
5. **English:** "Ride now — Trixie" / "Get Trixie ready myself" / "Choose how to start".
6. **Falsification:**
   - greeting answers on the start screen;
   - prompt rows or "Fler" on the start screen;
   - the "själv" choice not taking effect;
   - "Rida nu" not calling the shared function.

**Full suite; re-lock; Studio before and after.**

## Found during the build: the stable's finding (welfare) must never be hidden
With a stable finding (`vy.svar`, panel mode `fynd`), the finding question arrives at exactly the moment the start screen applies (nothing done yet). The first version of UI-1 **hid it** (caught by `klient-uikontext.spec` "FYNDET").

Now `guide.fynd` (open answer choices) and `lage == "fynd"` stop **both** the start screen and the step card: **a welfare question always goes first.**

