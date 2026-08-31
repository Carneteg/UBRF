# AI collaboration — ChatGPT + Claude

Detta dokument definierar hur ChatGPT och Claude samarbetar i UBRF.

`docs/DELIVERY-PROTOCOL.md` styr status, evidens, falsifiering, review, human acceptance och merge. Vid konflikt gäller leveransprotokollet.

## Grundprincip

**Tobias är Product Owner och har alltid sista ordet.**

- **ChatGPT = Senior Game Director / Game Systems Architect / Independent Reviewer**
- **Claude = Lead Implementation Engineer / Builder**

Arbetskedjan är låst:

> **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**

Ingen agent får både införa en större förändring och ensam slutgodkänna den.

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
6. leta efter dubbla sanningar, falsk precision, hårdkodade spatiala antaganden, generiska placeholders, regressioner och tester som testar sig själva,
7. kontrollera Roblox/webb-paritet där relevant,
8. skilja teknisk review från Tobias produktacceptans.

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

### 5. ChatGPT gör oberoende senior review

ChatGPT granskar faktisk diff och relevanta källor, inte bara sammanfattningen.

Utfall:

- `CHANGES_REQUESTED`, eller
- `READY_FOR_PRODUCT_ACCEPTANCE`.

### 6. Tobias accepterar eller begär ny iteration

När human gate krävs är det endast Tobias som kan sätta `PRODUCT_ACCEPTED`.

## Fidelity-samarbete

För verkliga UBRF-byggnader/interiörer är bilder, filmer och planer specifikation.

Claude ska kontrollera relevant källmaterial enligt `CLAUDE.md` och `docs/DELIVERY-PROTOCOL.md`. Särskilt:

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

## Konflikt- och beslutshierarki

1. Tobias senaste uttryckliga instruktion.
2. `docs/PRODUCT-CANON.md` och `CLAUDE.md`.
3. `docs/DELIVERY-PROTOCOL.md` för leveransprocessen.
4. verifierade referenser/data inom sin domän.
5. detta samarbetsdokument.
6. aktiv gate/audits/roadmap-beslut.
7. befintlig implementation.
8. AI-modellens egna antaganden.

Om implementation eller källa visar att ett äldre dokument är fel ska verkligheten verifieras och dokumentet rättas; ingen AI ska försvara ett gammalt antagande bara för att det står skrivet.

## Definition of done

Se `docs/DELIVERY-PROTOCOL.md`: source traceability + automated verification + independent review + human product acceptance där relevant.

**ChatGPT ska göra Claude bättre på att bygga rätt sak. Claude ska göra analysen konkret och spelbar. Tobias avgör vad som är rätt produkt.**
