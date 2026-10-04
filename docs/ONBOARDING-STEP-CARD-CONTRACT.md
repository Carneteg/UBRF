> **DELVIS ERSATT (produktbeslut 2026-10-04).** Allt som beskriver att spelaren själv hälsar, kollar, ryktar, kratsar, hämtar och lägger på sadel och träns eller leder hästen gäller inte längre. Det som gäller kvar: ett steg i taget, «Rida nu», fynd och välfärdsstopp. Se `docs/PRODUCT-CANON.md`, «Produktbeslut 2026-10-04».

# Onboarding: one clear step at a time in the left panel (Tobias C: two paths)

Status: contract written before code, 2026-09-28. **BUILT, LOCAL SUITE GREEN, VERIFIED IN STUDIO (engine), NOT VISUALLY VERIFIED** — READY_FOR_CHATGPT_REVIEW.
Order: TOBIAS_RUNTIME_FAIL_ONBOARDING_MENU_MISSING ([relay](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5871402927),
[ChatGPT](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5871460775)); decision
[TOBIAS_DECISION_ONBOARDING_C](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5871425267). Base `2730558` (runtime `7fdee30`).
**No change to the game rules.** Physical test last.

## Starting point (verified)
- **The panel on the left** (`Naromrade`) shows a header (`rubrikEtikett`), an instruction (`stegEtikett`), and the action buttons (`Fragan`, `Lista`).
  - Its text comes from `PreparationController.panel()`, which is phase-based: "Hälsa lugnt · 0/5" plus the phase or step text.
  - That is the "weak box": it names the **phase** and does not tell you **what to do next** (door, fetching tack, "Rida nu").
- **The full tracker ("Spåraren")** is switched off by `MINIMAL_UI` (PO, 2026-09-17), **which is why "the flow is missing again"**.
- **The game enforces the order:** `halsa → visitera → rykta → iordning (hov:vf, hov:vb, hov:hb, hov:hf, utr:1–5) → leda → sittupp` (`forb.fel_tur`).
- **"Rida nu"** is a hold-R prompt on the horse. The stable prepares the horse correctly and leads her to the arena (`autoForbered` + `placeraVidMal`).
- **Tack:** `vy.burenUtrustning.delar` tells whether the saddle or bridle is being **carried**. The step `utr:3`/`utr:4`/`utr:5` being current means the saddle is **on**.
- **Doors:** a `DorrPrompt` with `SprakNyckel = "dorr.oppna"` means **closed**.

## What is built: **one** instruction system (no parallel menu)
**`PreparationController.panelData`** gets a small state summary `guide`: `status`, `nasta`, `nastaMoment`, `redo`, `klaraFaser`, `buren` (the parts the player carries **for their own horse**), `utomRackhall`, and `rattelse`.

**`Naromrade.fyllText`** turns it into **one current step**: a header plus an instruction. It **replaces** the phase text in the same box, and **the action buttons stay**. It is driven by the game state, and by whether a closed door is **within reach** in the panel's own prompt list:

| State | Header | Instruction |
|---|---|---|
| horse out of reach + a closed door within reach | **Öppna stalldörren** | Open the door in front of you. The gold arrow shows where {horse} is. |
| horse out of reach | **Gå till {horse}** | Follow the gold arrow to her box. |
| at the horse, nothing done (`halsa`) | **Välj hur du börjar** | **Rida nu:** hold «Rida nu» (R) at {horse}; the stable gets her ready properly and leads her to the arena. **Or do it yourself:** + the phase's own question ("Gå fram från sidan …") |
| `visitera` / `rykta` | **Kolla {horse}** / **Rykta {horse}** (· x/y) | the step's own canon text |
| `iordning`, `hov:*` | **Kratsa hovarna** | the step text |
| saddle not on, not carried | **Hämta sadeln** | The saddle hangs on {horse}'s box front. |
| saddle carried, bridle not carried | **Hämta tränset** | The bridle hangs on the box front too. |
| saddle carried, not on (`utr:1`–`2`) | **Lägg på sadeln** | the step text |
| `utr:5`, bridle not carried | **Hämta tränset** | … |
| `utr:5`, bridle carried | **Sätt på tränset** | the step text |
| `leda` | **Led {horse} till ridhuset** | Choose «Led till ridhuset» in the list. She follows you. |
| leading | **Led {horse} till ridhuset** | Walk to the arena; {horse} follows you. You mount there. |
| `redo` / `ready_to_mount` (at the horse) | **Sitt upp på {horse}** | Mount and ride! Then choose a lesson with Ugneta or ride freely. |

**Unchanged (the guide does not step in):**
- `waiting_model`, `welfare_stop`, a correction (another horse's tack), aftercare, the counted session, and riding;
- the feedback field (acknowledgements and refusals);
- the action buttons and the help list;
- the horse marker;
- `MINIMAL_UI`.

**Texts:** new `guide.*` keys in `sprak.js` (SV/EN), exported to `UBRFSprak.luau`.

## Acceptance (`klient-guide.spec`, the client bench, the real `init.client` and `Naromrade` through `PreparationController.tillampa`)
1. **From spawn:** closed door + horse out of reach gives "Öppna stalldörren". Open door + far away gives "Gå till {horse}".
2. **At the horse, nothing done:** "Välj hur du börjar", which offers **both** "Rida nu" **and** the greeting question, and the choice buttons stay.
3. **The whole manual chain is followed through the real `Preparation`** (greet, check, groom, hooves, tack), with the header per step:
   - "Hämta sadeln" before the saddle, "Hämta tränset" once the saddle is carried;
   - "Lägg på sadeln" with the step text, and "Sätt på tränset" once it is carried;
   - "Led … till ridhuset", then leading, then "Sitt upp på …".
4. **The "Rida nu" path:** from "Välj" straight to "Sitt upp på …" when `vy` becomes `redo`.
5. **Unchanged:** a correction, `welfare_stop`, `waiting_model` and riding keep their old texts. **The action buttons stay.**
6. **Falsification:**
   - no door step;
   - "Hämta sadeln" while it is being carried;
   - the choice card without "Rida nu";
   - the guide overriding a correction.

**Full suite; re-lock. Studio:** the before state (the phase text, reproduced), then after the fix: the step card from spawn, at the horse and after "Rida nu".

**Not tested:** whether the texts are **clear** to a human, and how they fit on a phone. That is Tobias's checklist.

## Found during the build (Studio): "Rida nu" did not exist after join

The card says "hold «Rida nu» (R)". **In a fresh session there was no `RidaNuPrompt`** (and no `MountPrompt`) until the player had done something.

The cause: `InteractionController.uppdatera()` only ran on a **new view**. At join, the view arrived before the horse model had streamed in, so no prompt was created, and there was no later refresh.

**The fix (`init.client.luau`):**
- the prompts are also refreshed when a horse **appears** (`GetInstanceAddedSignal("Horse")`);
- and once a second in the existing Heartbeat. The refresh is idempotent: an existing prompt is left alone.

**Verified in Studio:** in a fresh session, `RidaNuPrompt` exists on Troy by itself, and holding R gives "Mount Troy". A bench case covers it (`klient-guide.spec` §6).

