# UBRF Delivery Protocol

Detta dokument styr evidens och acceptans för allt arbete i UBRF-repot.
Aktuella roller, behörigheter och stegvis testpolicy har en huvudkälla:
[WORKING-AGREEMENT](WORKING-AGREEMENT.md). Äldre personnamn/statusmarkörer
får inte återaktivera historiska uppdrag eller ge självacceptans.

Syftet är att förhindra att en AI-agent kan kalla sitt eget arbete "klart" utan oberoende granskning, spårbar evidens och — när upplevelsen är visuell eller spelbar — mänsklig acceptance i den verkliga målmiljön.

## Grundregel

Implementeraren bygger, den oberoende granskaren granskar och Tobias accepterar.
Rolltilldelningen finns endast i arbetsöverenskommelsen, inte i denna mall.
Tobias är ensam slutlig acceptansauktoritet för produkt, game feel och fidelity.

Ingen agent får både införa en större förändring och ensam slutgodkänna den.

---

## 1. Obligatoriskt Acceptance Contract före implementation

Innan Implementeraren börjar en icke-trivial ändring ska PR, issue eller gate innehålla ett kort acceptance contract med:

1. **Goal** — vilken konkret spelar-/produktupplevelse som ska uppnås.
2. **Observed state** — vad som faktiskt är fel eller saknas i aktuell branch.
3. **Source of truth** — vilka filer, referenser, data och produktbeslut som styr.
4. **Required change** — vad som måste ändras.
5. **Out of scope** — vad som uttryckligen inte ska byggas i samma leverans.
6. **Acceptance tests** — automatiska och manuella kontroller som ska passera.
7. **Human gate** — om Studio-/gameplay-/visuell acceptans krävs.
8. **Known uncertainty** — `VERIFIED`, `PLAN`, `FOTO`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP` där relevant.

Om något av ovan är oklart ska Implementeraren stoppa scope-expansion och dokumentera luckan i stället för att fylla den med egna antaganden.

---

## 2. Tillåtna leveransstatusar

Implementeraren får **inte** använda `APPROVED`, `ACCEPTED`, `DONE`, `CLOSED`, `FINAL` eller liknande som slutstatus för sitt eget arbete.

Tillåtna statusar är:

- `DRAFT`
- `IMPLEMENTING`
- `IMPLEMENTED`
- `AUTOMATED_GREEN`
- `READY_FOR_REVIEW`
- `CHANGES_REQUESTED`
- `READY_FOR_PRODUCT_ACCEPTANCE`
- `PRODUCT_ACCEPTED`

Regel:

- Implementeraren får sätta status t.o.m. `READY_FOR_REVIEW`.
- Granskaren kan efter review sätta `READY_FOR_PRODUCT_ACCEPTANCE`.
- **Endast Tobias får sätta `PRODUCT_ACCEPTED`.**

En merge får inte användas som bevis på produktacceptans. En PR kan vara tekniskt mergebar men fortfarande sakna Studio-/gameplay-/fidelity-pass.

För F02 (interiörer) gäller dessutom den visuella kedjan i `docs/VISUAL-FIDELITY-GATE.md` (issue #78): `IMPLEMENTED → AUTOMATED_GREEN → VISUAL_PACK_READY → CHATGPT_VISUAL_PASS → READY_FOR_PRODUCT_ACCEPTANCE → PRODUCT_ACCEPTED`. Ingen F02-PR presenteras för Tobias före `CHATGPT_VISUAL_PASS`, och automation sätter aldrig en visuell status.

---

## 3. Evidence-first, aldrig summary-first

En leverans bedöms på faktisk evidens, inte på implementerarens sammanfattning.

Implementeraren ska länka eller namnge:

- aktuell branch och exakt commit-SHA,
- ändrade kärnfiler,
- exakta testkommandon och exitkoder,
- relevanta screenshots/mätningar där möjligt,
- kända fel och vad som **inte** har testats,
- källor som styr varje betydande fidelity-/produktbeslut.

Granskaren ska vid review läsa faktisk diff och relevanta källor. En sammanfattning från Implementeraren är en handoff, inte ett bevis.

---

## 4. Obligatorisk falsifiering

Implementeraren ska inte bara visa att tester går grönt. För varje icke-trivial gate ska centrala tester visas **kunna bli röda** när skyddet bryts. Mutationer körs endast i isolerade kopior med exakt ankarkontroll; missade prov är fel, inte PASS.

Exempel:

- flytta en dörr från sitt `OpeningId` → test ska falla,
- ta bort ett `RoomId` → test ska falla,
- markera en obyggd planzon som byggd → test ska falla,
- sätt ett semantiskt rumsnamn utan källa → test ska falla,
- ta bort en referenspost → käll-/manifestkontroll ska falla,
- bryt ett gameplay-villkor → server-/gameplaytest ska falla.

Ett test som bara bekräftar sin egen implementation eller sin egen konstant räknas som svag evidens.

---

## 5. Fyra lager Definition of Done

En större ändring är inte färdig förrän alla relevanta lager är gröna:

### Lager A — Source traceability

- källan är identifierad,
- antaganden är märkta,
- inga build-kritiska påståenden vilar på dold Drive-only-information,
- inga visuella `REFERENCE GAP` deklareras innan relevant foto/video har granskats.

### Lager B — Automated verification

- relevanta tester körda,
- regressionssuite körd,
- falsifieringar dokumenterade,
- inga tyst hoppade assertions,
- exitkod verifierad, inte bara "ser grönt ut".

### Lager C — Independent review

- Granskaren granskar faktisk diff och källor,
- letar efter dubbla sanningar, hårdkodade koordinater, falsk precision, scope creep, generiska placeholders och tester som testar sig själva,
- begär ändringar om beviset inte håller.

### Lager D — Product acceptance

När ändringen berör game feel, UX, Studio-värld eller visuell fidelity krävs Tobias uttryckliga PASS i målmiljön.

**Kodtest kan inte ersätta mänsklig fidelity- eller game-feel-acceptance.**

---

## 6. Fidelity protocol — UBRF som verklig plats

För byggnader, interiörer, tomt och visuella detaljer gäller följande källordning:

1. verifierade råfoton och råfilmer i repo/Supabase,
2. plan-/utrymningsritningar,
3. verifierade derivat/stillbilder och byggnadskort,
4. dokumenterade mätningar,
5. aktuell implementation,
6. `ASSUMPTION` endast när evidens verkligen saknas.

### Innan `REFERENCE GAP`

Implementeraren måste kontrollera relevant:

- `references/buildings/`,
- `references/plans/`,
- `references/video/`, inklusive råfilm när en panorering kan visa sådant som en stillbild missat,
- `KORT.md` / `INTERIOR-MATRIS.md`,
- Supabase `reference_assets` när den innehåller ytterligare verifierat material.

Om råfilm finns får en detalj inte klassas som `REFERENCE GAP` enbart för att den saknas i redan extraherade JPG-bilder.

### Struktur och funktion hålls isär

Exempel:

- ett rums gräns kan vara `PLAN`,
- rummets funktion kan samtidigt vara `REFERENCE GAP`.

Okänd funktion får aldrig bli "WC", "kontor" eller liknande för att göra modellen komplett.

### Precision får inte överdrivas

Relativ topologi, absolut meterskala och perspektivhärledning ska klassas separat. Ett arbetsmått får inte börja beskrivas som verifierat bara för att implementationen använder ett exakt tal.

---

## 7. Human review modes före permanent implementation

När en stor visuell eller spatial förändring är osäker ska Implementeraren först bygga en **review-only representation** innan produktionsgeometrin låses.

Exempel för F02:

1. topologi/wireframe/dollhouse,
2. Tobias PASS/FEL per rum/zon,
3. möbler/fasta fixtures,
4. Tobias PASS/FEL,
5. material/färger/detaljer,
6. Tobias slutlig fidelity-acceptance.

Detta minskar kostnaden för omarbete och hindrar gameplay-ankare från att byggas på fel geometri.

---

## 8. PR-regler

Varje PR ska ha **ett tydligt ansvar**.

Undvik:

- stora blandade "allt är klart"-PR:er,
- feature + refactor + governance + polish utan tydlig koppling,
- parallella PR:er som ändrar samma kärnfiler,
- teständringar som gör ett fel grönt genom att sänka kravet.

PR:n ska innehålla:

- Acceptance Contract,
- status,
- ändrad scope,
- testbevis,
- falsifieringsbevis,
- kvarstående risk,
- human acceptance-status.

Om en ändring kräver mänsklig acceptans ska PR:n vara draft eller explicit markerad som väntande tills den är utförd.

### 8.1 Publicering och lokal review

Den äldre regeln från 2026-09-04 (PR #76) om automatisk löpande push är
ersatt för aktuellt arbete av [WORKING-AGREEMENT](WORKING-AGREEMENT.md).
Granskning av en exakt lokal commit är tillåten; kalla den inte publicerad
eller spelbar preview. Framtida push, merge och publicering kräver separat
godkännande, även när en push normalt startar automatiska publiceringar.

När en preview uttryckligen är godkänd och ingår i leveransen ska dess
identitet verifieras mot rätt publicerad SHA. En gammal preview får inte
användas som bevis för ny kod. Saknad preview är en redovisad begränsning,
inte skäl att publicera utan tillstånd.

---

## 9. Stop-the-line triggers

Implementeraren ska stoppa implementation eller mergeförberedelse när något av följande inträffar:

- källor motsäger varandra,
- en build-kritisk referens finns endast i Drive,
- verklig skala/placering saknar evidens men implementationen kräver ett exakt värde,
- ett för den aktuella tekniska leveransen obligatoriskt test saknas; stoppa
  det berörda anspråket, men återstarta inte uppskjutet slutspeltest i strid
  med arbetsöverenskommelsen,
- en regression i tidigare accepterad vy eller gameplay-loop upptäcks,
- PR:n börjar expandera utanför aktiv gate,
- samma domänfakta definieras på flera ställen utan tydlig canonical owner,
- tester blir gröna genom att kravet sänks i stället för att felet fixas.

Status ska då vara `CHANGES_REQUESTED` eller motsvarande blockerad status, aldrig "klart med känd begränsning" om begränsningen träffar acceptance criteria.

---

## 10. Roblox + webb

Roblox är primär spelplattform. HTML/webb är parallell spelbar distribution och snabb testyta.

Kärnregler, hästkunskap, ansvar, UBRF-värld och centrala gameplayparametrar ska hållas i avsiktlig paritet. **Under det tidsbegränsade produktbeslutet 2026-09-22 (Roblox först) är kravet på samtidig webbimplementation pausat; avsaknaden redovisas som avvikelse med hänvisning till `docs/PRODUCT-CANON.md`, aldrig som uppnådd paritet.**

En ändring får inte kallas levererad om den bryter den aktiva plattformens huvudloop eller gör den andra plattformens motsvarande upplevelse omöjlig utan att detta uttryckligen beslutats.

---

## 11. Standardiserad implementerar-handoff

Varje större Implementeraren-leverans ska avslutas med:

### Status
`IMPLEMENTED` / `AUTOMATED_GREEN` / `READY_FOR_REVIEW`

### Changed
Exakta filer och ansvar.

### Source evidence
Vilka produktbeslut, referenser och data som användes.

### Tested
Exakta kommandon, Studio-/runtime-observationer och exitkoder.

### Falsified
Vilka mutationer som medvetet gjordes och hur testen föll.

### Not tested
Sådant Implementeraren inte faktiskt har kunnat verifiera.

### Remaining risk
Kända osäkerheter med rätt evidensklass.

### Human gate
Vad Tobias behöver bedöma och i vilken miljö.

### SHA
Exakt head-SHA.

---

## 12. Standardiserad oberoende review

Granskaren ska vid större review kontrollera minst:

- att acceptance contract fortfarande matchar implementerad scope,
- att källhierarkin följts,
- att summaryn stämmer med diffen,
- att precisionen inte är större än källan tillåter,
- att tester kan falsifiera den centrala defekten,
- att inga gamla accepterade beteenden har brutits,
- att Roblox/webb-paritet hanterats där relevant,
- att human gate är tydlig och inte förklarats "pass" utan Tobias.

Granskaren kan rekommendera `READY_FOR_PRODUCT_ACCEPTANCE`, men inte ersätta Tobias visuella/game-feel-bedömning.

---

## 13. Merge-regel

Merge är tillåten först när:

1. relevant automatiserad gate är grön,
2. oberoende review inte har blockerande fynd,
3. human acceptance är utförd när acceptance contract kräver den,
4. PR:n är i rätt scope och inte har olösta blockerande `REFERENCE GAP` maskerade som implementation.

Undantag kräver Tobias uttryckliga beslut och ska dokumenteras i PR:n.

---

## 14. Den korta versionen

När det råder tvekan, följ detta:

> **Bevisa källan. Bygg minsta korrekta sak. Försök bryta den. Låt någon annan granska den. Låt Tobias acceptera den. Först därefter är den klar.**
