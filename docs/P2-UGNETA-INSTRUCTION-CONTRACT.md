> **DELVIS ERSATT (produktbeslut 2026-10-04).** Allt som beskriver att spelaren själv hälsar, kollar, ryktar, kratsar, hämtar och lägger på sadel och träns eller leder hästen gäller inte längre. Det som gäller kvar: Ugneta instruerar, ett språk i hela panelen, och instruktionerna för ridningen. Se `docs/PRODUCT-CANON.md`, «Produktbeslut 2026-10-04».

# P2 + UI-2 + UI-3: Ugneta instructs, the player acts, one language — Roblox and web together

Status: contract written before code, 2026-09-29. Writer: Claude 4208679f.
Order: #266 [5882885526](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5882885526) § 2, [5882981472](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5882981472) § 2, [5882894578](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5882894578) step 3.
Product source: UI-2/UI-3 [#264 5872220574](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5872220574) §§ 2–4. Audit: `docs/WEB-ROBLOX-PARITY-AUDIT.md` P2 rows. Review note L4 (#5883447933).
Base: `262493c` (P1b R1, production).

**One package on both platforms.** No web-first build that Roblox must redo later. Rendering and input are platform-specific; hierarchy, texts, rules and gates are shared.

## 1. Player outcome

On foot, the near-area component reads top to bottom:

1. **Ugneta · Ridinstruktör.** Her own box, clearly labelled.
   - Her title row carries the existing strip controls: **Text** (Roblox) and the **language flag**, so the strip becomes this box's header instead of a separate element.
   - Beneath the title is her short, natural instruction for what to do now, e.g. «Gå fram från sidan vid bogen — aldrig rakt bakifrån. Säg hennes namn innan du rör henne, och lägg sedan handen på halsen.»
2. **The action box**, directly below and visually attached:
   - the step heading («Hälsa på Troy»);
   - the concrete actions («Gå fram från sidan vid bogen», «Säg hennes namn», «Lägg handen på hennes hals»);
   - prompt rows, «Fler» and feedback.

The player should read it as: *Ugneta tells me what to do; these are the things I do.*

**Swedish selected → no English visible in the component. English selected → no Swedish visible.** This covers:
- the heading, Ugneta's text, actions, helper text and prompt rows;
- «Fler», the buttons and the feedback.

## 2. Greeting: guidance, not a quiz (shared canon)

Today `HALSNING` (src/spel/skotsel.js → `UBRFSkotsel.luau`) has three **answers**, one of them wrong, so `Preparation.arVal("halsa")` is true and the phase is a quiz.

**Change (canon, both platforms through the export).** `HALSNING` becomes three **actions in order**, all correct:

| steg | Swedish action | English action | Confirmation (`svar`) |
|---|---|---|---|
| 1 | Gå fram från sidan vid bogen | Walk up from the side, at her shoulder | Där ser hon dig komma. / There she can see you coming. |
| 2 | Säg hennes namn | Say her name | Nu vet hon att du är där. / Now she knows you are there. |
| 3 | Lägg handen på hennes hals | Put your hand on her neck | Lugnt och vänligt. Nu kan ni börja. / Calm and kind. Now you can begin. |

- **The order follows real practice and the existing phase text:** you speak before you touch. The existing `steg` rule enforces it (`Preparation.provaMoment` → `forb.fel_tur`). There is no new rule logic.
- **The teaching of the old wrong answer is kept** in Ugneta's instruction: «aldrig rakt bakifrån» / «never straight from behind». The phase `text`/`textEn` is updated to the instruction in § 1.
- `halsMoment` (Preparation.luau) and its web mirror (`src/forberedelse.js`) set `steg = i`. The ids stay `halsa1..3`, so saved gjorda keys keep their meaning class (all are `true`/`"auto"` work).
- **Consequence, stated.** The greeting becomes a checklist of 3 moments, not a choice worth 1 in `egenAndel`.
  - Full manual care still gives 1.0 and Rida nu still gives 0.
  - A mixed pass shifts by at most a few hundredths of the own share. At the canon's `0.06 × andel` that is < 0.01 day form.
  - The bonus stays small (FUN FIRST).
- **No welfare or safety rule is touched.** Rida nu's stable preparation runs the three moments as `"auto"`, exactly as it runs every checklist.

## 3. Roblox

- **The strip docks into the panel.** `UgnetaController` keeps owning `Larare`: title, flag, Text, settings and message. A new API gives it a host placement:
  - `UgnetaController.dockaLarare(forälder, ordning)` and `UgnetaController.satInstruktion(text?)`.
  - `Naromrade` docks `Larare` as the panel's **first** block (`LayoutOrder 0`), full panel width, with top-right positioning off while docked.
  - Without a host, it behaves as before.
- **Instruction.** On foot, the step's instruction goes to Ugneta's message line (`satInstruktion`).
  - The panel's own `Steg` line is hidden while Ugneta holds the instruction, so it is not shown twice.
  - Lesson and coach texts keep priority exactly as `lararMeddelande` orders them today.
- **Budget.** `placera` counts the docked box as fixed height, so the 40 % cap, iPad landscape and the touch-stick rules keep holding.
- **Look.** The box keeps the dark visual language, with the gold title as instructor. The action box stays as it is, with the accent on the primary action only. No permanent left-side info box returns.

## 4. Web

- **`src/stegkort.js` gets the same top block** `#stegkort .skU`:
  - the title `tSpr("ugneta.titel")`;
  - a **language flag button** showing `tSpr("sprak.nuvarande")`. It toggles `window.SPRAKET` between `sv` and `en` and redraws.
  - The default is still `sprakFor(navigator.language)`.
  - The choice lives for the page session, like Roblox's `UBRFSprak` attribute, which is not saved either.
- **Instruction.** Ugneta's line = the card's instruction text. The action box keeps the heading, choices, rows, «Fler» and feedback.
- **Text (comment level)** belongs to lesson commentary, which the web gets with P3 (lesson menu). In P2 the web strip has the title and the language flag.
  - **Platform difference needing Tobias' approval:** «Text» is added to the web with P3, not P2. The player outcome in the on-foot care flow is identical: Text only affects lesson commentary.
- **L4 and hard-coded strings in the parity flow go through `tSpr`:**
  - the arrival line `world.js` «Du är framme på Husbyvägen 1A … Ridläraren väntar i stallgången.» — the instructor no longer assigns the horse, so the second sentence is dropped;
  - the weather lines;
  - `larare.js` title and «Nästa steg».

## 5. UI-3: gates that fail on mixed language (both platforms)

- **Static (Roblox):**
  - `tools/kolla-sprak.py` LOKALISERADE gains `Naromrade.luau` (and any file this package makes draw player text).
  - The composed key `"guide." .. nyckel .. "_rubrik"` gets an explicit key table, so every guide key is a literal the gate checks.
  - This is the dynamic-key gap, closed, not silenced.
- **Runtime (Roblox spec, new):** `roblox/tests/klient-sprakblandning.spec.luau`.
  - It renders every on-foot guide step on `sv` and on `en`.
  - It collects **every visible text** in the docked Ugneta box and the panel (`Naromrade._panel/_rader/_val`, `UgnetaController._larare`).
  - It fails when:
    - an `sv` render contains a string that is an English catalogue value (and not also the Swedish one);
    - an `en` render contains å/ä/ö, or a Swedish catalogue value (and not also the English one).
  - Horse names are exempt.
- **Web (new):** `tools/sprakblandningtest.mjs`. The same rule over `#stegkort` innerText, for the same steps, via the language flag. It is added to the CI web job.
- **Falsification.** Each gate is shown red on an injected mixed string:
  - Roblox: an English literal in the panel;
  - web: a Swedish action on `en`.

## 6. Acceptance

1. **Roblox and web, on foot, «Gör i ordning själv» → greeting:**
   - the Ugneta box is on top with her instruction;
   - the action box below has the three actions **in order**, with only the next one primary;
   - an action out of order is refused with the canon's «fel tur».
2. **All three done** → the phase is complete.
   - Full manual care → `egenAndel` 1.0.
   - Rida nu → the three moments are `"auto"` and the own share is 0.
3. **Language:**
   - The flag toggles sv ↔ en on both platforms.
   - After the toggle, no text of the other language remains in the component. The gates in § 5 are green and shown able to go red.
4. **iPad landscape (1180×820) and 1366×768.** The component fits within the existing caps:
   - web: ≤ 34 % width, as before;
   - Roblox: the 40 % height budget.

   No control is lost under CoreGui or the stick.
5. The **start choice (UI-1)** is unchanged: two choices, no quiz.
6. **Rules and export parity:**
   - The Roblox specs are updated to the new greeting, not deleted.
   - `forberedelse-webb` compares the new moments across platforms.
   - The export is in sync, and the build identity is relocked.

## 7. Verification plan

- Focused: `stegkorttest`, `forberedelsetest`, `forstadagentest` (+`MOBIL=1`), `sprakgrind`, the new web gate, `kolla-sprak.py`, and the Roblox specs through `kor.sh`.
- The full node suite, the three `p0-qa-runner` modes, `kor.sh`, the export checks and `bygg-identitet`.
- **Studio (engine check, hypothesis first).** Hypothesis: the docked Larare renders above the panel in Play, and the flag switches the language of both.
  - Pass means a screenshot/property read shows Larare's parent = `Panel` and the texts are all sv, then all en, after the flag.
  - It runs only if Studio shows the current tree.
  - Otherwise it is `NOT_TESTED` with the reason.
- Vercel Preview for the exact SHA, then Production for the same SHA after green (Tobias approves the promote).

## Not in P2

- The riding panel and the lesson menu (P3).
- After the ride and aftercare (P4).
- Side-activity QA.
- The web «Text» control (P3, above).
