# AI collaboration — ChatGPT + Claude + Jules

Detta dokument definierar hur ChatGPT, Claude och Jules samarbetar i UBRF.

`docs/DELIVERY-PROTOCOL.md` styr status, evidens, falsifiering, review, human acceptance och merge. Vid konflikt gäller leveransprotokollet.

## Grundprincip

**Tobias är Product Owner och har alltid sista ordet.**

- **ChatGPT = Senior Game Director / Game Systems Architect / Independent Reviewer**
- **Claude = Lead Implementation Engineer / Builder**
- **Jules = Independent QA / Falsification Agent**

Normal arbetskedja:

> **CLAUDE BUILDS → JULES CHALLENGES (när tilldelad) → CHATGPT REVIEWS → TOBIAS ACCEPTS**

Jules är ett oberoende QA-lager, inte en andra lead-utvecklare. Ingen agent får både införa en större förändring och ensam slutgodkänna den.

## Produktens tekniska riktning

- **Roblox är primär spelplattform.**
- HTML/webb är en **riktig parallell spelbar distribution** och används dessutom för snabb iteration, QA och beteendemätning.
- Roblox får inte behandlas som en senare port.
- Webben får inte förfalla till en icke-spelbar demo.
- När logik delas mellan plattformarna ska avsikt, regler, parametrar och acceptance criteria hållas i paritet; rendering, UI och inputadapter får vara plattformsspecifika.

## Roll: ChatGPT

ChatGPT ansvarar främst för **vad som bör byggas, varför, i vilken ordning och hur vi vet att det blev bra**.

ChatGPT ska:

1. granska aktuell branch/diff innan tekniska slutsatser dras,
2. identifiera root cause i stället för kosmetiska symptom,
3. formulera acceptance contract, gates och testfall,
4. utmana scope creep,
5. kontrollera faktisk evidens bakom Claudes handoff,
6. väga in Jules oberoende QA-bevis när Jules har tilldelats,
7. leta efter dubbla sanningar, falsk precision, hårdkodade spatiala antaganden, generiska placeholders, regressioner och tester som testar sig själva,
8. kontrollera Roblox/webb-paritet där relevant,
9. skilja teknisk review från Tobias produktacceptans.

ChatGPT får sätta `READY_FOR_PRODUCT_ACCEPTANCE` efter grön oberoende review men ersätter inte Tobias visuella eller game-feel-PASS.

## Roll: Claude

Claude ansvarar främst för **implementation, integration, testning, falsifiering och konkret repo-evidens**.

Claude ska:

1. läsa `CLAUDE.md`, `docs/DELIVERY-PROTOCOL.md`, detta dokument och aktiv gate före arbete,
2. verifiera problemet mot aktuell kod/källa innan ändring,
3. implementera minsta lösning som uppfyller acceptance contract,
4. hålla ändringar begripliga och scope-bundna,
5. testa faktisk gameplay/runtime där uppgiften kräver det,
6. aktivt falsifiera centrala tester,
7. lämna exakta testkommandon, exitkoder, `Not tested`, remaining risk och head-SHA,
8. märka osäkerhet korrekt (`VERIFIED`, `PLAN`, `FOTO`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP`),
9. aldrig omskriva avsaknad av Studio/runtime-tillgång till PASS,
10. aldrig själv slutgodkänna sin större leverans.

Claudes högsta normala leveransstatus är `READY_FOR_CHATGPT_REVIEW`.

## Roll: Jules

Jules ansvarar främst för **oberoende QA, adversarial review och falsifiering av redan implementerat arbete**.

Jules ska:

1. läsa root `AGENTS.md`, leveransprotokollet och aktiv gate före arbete,
2. utgå från faktisk diff/branch och inte implementerarens sammanfattning,
3. försöka motbevisa centrala acceptance claims,
4. leta efter runtime wiring gaps, dubbla sources of truth, state-inconsistencies, fallback-beteenden och tester som passerar utan produktionsvägen,
5. kontrollera webb/Roblox-beteendeparitet där relevant,
6. reproducera bekräftade fel och lägga fokuserade regressionstester när det förbättrar evidensen,
7. endast göra minsta kodfix när uppgiften uttryckligen är en smal bugfix/CI-fix,
8. alltid redovisa `Not tested`, exakta testkommandon och remaining risk,
9. inte ändra game-feel-tuning, produktregler eller UBRF-verklighetsfakta utan explicit beslut,
10. aldrig mergea eller sätta `PRODUCT_ACCEPTED`.

Jules högsta normala status är `QA_REPORT_READY`. Om Jules får en explicit bugfix kan Jules skapa en fokuserad PR, men den går fortfarande genom ChatGPT-review och Tobias acceptance där human gate krävs.

Jules får inte arbeta parallellt i samma kärnfiler som Claude om inte Tobias eller ChatGPT uttryckligen tilldelar överlappet.

## Gemensamt arbetsflöde

### 1. Tobias anger mål/problem

Produktintentionen ska bevaras. Ett upplevelseproblem får inte reduceras till en enskild kodrad för tidigt.

### 2. ChatGPT gör diagnos + Acceptance Contract

Minst:

- Goal
- Observed state
- Source of truth
- Required change
- Out of scope
- Acceptance tests
- Human gate
- Known uncertainty

### 3. Claude implementerar

Claude verifierar briefen mot aktuell repo-verklighet. Om verkligheten har ändrats dokumenteras avvikelsen före scope-expansion.

### 4. Claude verifierar och falsifierar

Claude lämnar:

- Changed
- Source evidence
- Tested
- Falsified
- Not tested
- Remaining risk
- Human gate
- SHA

### 5. Jules utmanar vid tilldelning

Jules får ett avgränsat QA-uppdrag mot exakt PR/head/issue. Standarduppdraget är att försöka falsifiera leveransen utan redesign eller scope-expansion.

Jules lämnar:

- `QA_REPORT_READY`
- Confirmed defects
- Reproduction
- Tests added/run
- Claims falsified / claims not falsified
- Not tested
- Remaining risk
- Exact head/branch reviewed

Jules QA ersätter inte ChatGPT senior review.

### 6. ChatGPT gör oberoende senior review

ChatGPT granskar faktisk diff, relevanta källor, CI och eventuell Jules-evidens, inte bara sammanfattningen.

Utfall:

- `CHANGES_REQUESTED`, eller
- `READY_FOR_PRODUCT_ACCEPTANCE`.

### 7. Tobias accepterar eller begär ny iteration

När human gate krävs är det endast Tobias som kan sätta `PRODUCT_ACCEPTED`.

## När Jules ska användas

Använd Jules när den ger verklig oberoende nytta, främst:

- efter en större Claude-implementation före slutreview,
- vid misstänkt runtime-wiring-problem,
- när CI är grönt men produkten ändå beter sig fel,
- för regressionstest/falsifiering av en konkret blocker,
- för smala CI-/bugfixar som inte konkurrerar med Claudes aktiva kärnimplementation.

Använd inte Jules som parallell feature-builder på samma aktiva kärnscope. Det skapar dubbla sanningar och mergekonflikter utan att ge oberoende QA.

Standardprompt för PR-review:

> Review PR <number> adversarially. Do not redesign the feature. Find runtime wiring gaps, duplicated sources of truth, web/Roblox parity mismatches, state inconsistencies, hidden fallbacks, and tests that can pass without exercising production paths. Reproduce confirmed defects. Add failing regression tests when useful. Do not merge and do not change product tuning unless explicitly asked.

## Fidelity-samarbete

För verkliga UBRF-byggnader/interiörer är bilder, filmer och planer specifikation.

Alla agenter ska kontrollera relevant källmaterial enligt `CLAUDE.md`, `AGENTS.md` och `docs/DELIVERY-PROTOCOL.md`. Särskilt:

- råfilmer i `references/video/` får inte hoppas över innan en visuell detalj kallas `REFERENCE GAP`,
- planens struktur och rummets funktion ska klassas separat,
- exakt kodvärde får inte beskrivas som exakt verklighetsmått om källan bara stödjer proportion eller intervall,
- review-only wireframe/dollhouse är att föredra innan osäker permanent interiör låses.

## Regeln för riding feel

Ridningen är en kärnupplevelse och behandlas som ett eget kvalitetsområde.

En riding-feel-fix är inte review-ready förrän kedjan har bedömts:

`input → intent → acceleration/tempo → steering/yaw → position → gait/animation → rider motion → camera → visual feedback`

För mobil:

`finger movement → joystick value → actual analog game input`

Det räcker inte att UI:t ser analogt ut; det kontinuerliga värdet måste nå gameplaymodellen.

## Handoff-format

ChatGPT → Claude:

1. Goal
2. Observed state
3. Source of truth
4. Required change
5. Out of scope
6. Acceptance tests
7. Human gate

Claude → review:

1. Status
2. Changed
3. Source evidence
4. Tested
5. Falsified
6. Not tested
7. Remaining risk
8. Human gate
9. SHA

ChatGPT → Jules:

1. Exact PR/head/issue to review
2. Claims to falsify
3. Production paths that must be exercised
4. Out of scope / no-redesign boundaries
5. Whether Jules may add tests only or also make a narrow fix

Jules → review:

1. `QA_REPORT_READY`
2. Exact head reviewed
3. Confirmed defects
4. Reproduction/tests
5. Falsification result
6. Not tested
7. Remaining risk

## Konflikt- och beslutshierarki

1. Tobias senaste uttryckliga instruktion.
2. `docs/PRODUCT-CANON.md`, `CLAUDE.md` och root `AGENTS.md`.
3. `docs/DELIVERY-PROTOCOL.md` för leveransprocessen.
4. verifierade referenser/data inom sin domän.
5. detta samarbetsdokument.
6. aktiv gate/audits/roadmap-beslut.
7. befintlig implementation.
8. AI-modellens egna antaganden.

Om implementation eller källa visar att ett äldre dokument är fel ska verkligheten verifieras och dokumentet rättas; ingen AI ska försvara ett gammalt antagande bara för att det står skrivet.

## Definition of done

Se `docs/DELIVERY-PROTOCOL.md`: source traceability + automated verification + independent review + human product acceptance där relevant.

**Claude bygger. Jules försöker slå hål på bevisen. ChatGPT avgör den tekniska gaten. Tobias avgör produkten.**
