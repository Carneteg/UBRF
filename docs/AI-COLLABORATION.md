# AI collaboration — ChatGPT + Claude + optional Jules

Detta dokument definierar hur ChatGPT, Claude och vid behov Jules samarbetar i UBRF.

`docs/DELIVERY-PROTOCOL.md` styr status, evidens, falsifiering, review, human acceptance och merge. Vid konflikt gäller leveransprotokollet. Tobias senaste uttryckliga produktbeslut har alltid högst prioritet.

## Grundprincip

- **Tobias = Product Owner** — äger scope, prioritet, subjektiv game feel och produktacceptans.
- **ChatGPT = Senior Game Director / Game Systems Architect / Independent Reviewer** — äger acceptance contracts, arkitektur, oberoende senior review och release gating.
- **Claude = Lead Implementation Engineer / Builder** — äger implementation, integration, builder-side tester och falsifiering.
- **Jules = Optional Independent QA / Falsification Agent** — används selektivt som extra QA, aldrig som obligatorisk grind.

Den obligatoriska arbetskedjan är:

> **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**

Jules ligger i en frivillig sidokanal. Leveransen får aldrig stå och vänta på att Jules ska starta, avsluta eller återhämta en fastnad körning.

## Produktens tekniska riktning

- **Roblox är primär spelplattform.**
- HTML/webb är en riktig parallell spelbar distribution och används dessutom för snabb iteration, QA och beteendemätning.
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
6. väga in Jules-evidens när sådan finns, men aldrig blockera på att Jules saknas eller är sen,
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

Jules är ett **extra QA-verktyg**, inte en del av den obligatoriska leveranskedjan och inte en andra lead-utvecklare.

Använd Jules främst för:

- en konkret misstanke om runtime-wiring,
- ett fokuserat regressionstest,
- säkerhetskontroll,
- en smal adversarial falsifiering,
- en isolerad CI-/bugfix som inte konkurrerar med Claudes aktiva kärnimplementation.

Jules ska när den används:

1. utgå från faktisk diff/branch och inte implementerarens sammanfattning,
2. försöka motbevisa centrala acceptance claims,
3. leta efter runtime wiring gaps, dubbla sources of truth, state-inconsistencies, fallback-beteenden och tester som passerar utan produktionsvägen,
4. kontrollera webb/Roblox-beteendeparitet där relevant,
5. reproducera bekräftade fel och lägga fokuserade regressionstester när det förbättrar evidensen,
6. endast göra minsta kodfix när uppgiften uttryckligen är en smal bugfix/CI-fix,
7. alltid redovisa `Not tested`, exakta testkommandon och remaining risk,
8. inte ändra game-feel-tuning, produktregler eller UBRF-verklighetsfakta utan explicit beslut,
9. aldrig mergea eller sätta `PRODUCT_ACCEPTED`.

Jules högsta normala status är `QA_REPORT_READY`. En Jules-rapport är **extra evidens**, inte ett krav för att ChatGPT ska kunna slutföra senior review.

Om Jules blir långsam, fastnar, duplicerar en annan task, kör mot fel head eller öppnar en PR från gammal bas ska uppgiften avbrytas/stängas och huvudkedjan fortsätta. Bekräftade fynd ska däremot fortfarande hanteras.

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

### 5. Optional Jules QA

ChatGPT eller Tobias kan skicka en smal, avgränsad QA-task till Jules. Huvudkedjan fortsätter oberoende. Om Jules levererar i tid används fynden som extra evidens.

### 6. ChatGPT gör oberoende senior review

ChatGPT granskar faktisk diff, relevanta källor, CI och eventuell Jules-evidens, inte bara sammanfattningen.

Utfall:

- `CHANGES_REQUESTED`, eller
- `READY_FOR_PRODUCT_ACCEPTANCE`.

### 7. Tobias accepterar eller begär ny iteration

När human gate krävs är det endast Tobias som kan sätta `PRODUCT_ACCEPTED`.

## Regeln för Jules

**Jules får hjälpa oss hitta fel men får aldrig bli projektets flaskhals.**

Skapa inte breda Jules-tasks för hela features när en smal fråga räcker. Skapa inte dubbla Jules-tasks för samma PR/head. Om en Jules-task fastnar ska den stängas i stället för att stoppa Claude eller ChatGPT.

Standardprompt för en smal PR-review:

> Review PR <number> adversarially on exact head <sha>. Do not redesign the feature. Focus only on <specific risks>. Find production-path gaps, duplicated truths and tests that can pass falsely. Reproduce confirmed defects. Add regression tests only when useful. Do not merge and do not change product tuning.

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

När Jules används:

ChatGPT → Jules:

1. Exact PR/head/issue
2. En liten uppsättning claims att falsifiera
3. Production paths som måste köras
4. Out of scope / no-redesign
5. Om Jules får lägga test eller även göra en smal fix

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

Se `docs/DELIVERY-PROTOCOL.md`: source traceability + automated verification + independent ChatGPT review + human product acceptance där relevant.

**Claude bygger. ChatGPT avgör den tekniska gaten. Tobias avgör produkten. Jules används när extra falsifiering ger mer värde än friktion.**
