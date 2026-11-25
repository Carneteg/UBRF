# Active gate

Read [WORKING-AGREEMENT](WORKING-AGREEMENT.md) for roles, permissions and test policy.

Status date: 2026-09-28. This document records the current delivery gate. It is **not** product acceptance.

## Current active work

- Active issue: **#266** — riding quality, constructive teaching and competition-day progression.
- Active branch: **`codex/circle-lesson-20260926`**.
- PR #264 is merged at `7922d70090f3b968af23a9e080c0e5df1cfcb59a` and is historical.
- Review model: **CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**.
- Standing delivery rule: **BUILD NOW / PHYSICAL TEST LAST**.
- Coordination source of truth: GitHub issue #266 + the remote branch.
- Claude review handoff marker: **`HANDOFF_READY_FOR_CHATGPT`**.

## Also active, 2026-11-23: webb-realism-utvecklingsplanen (Steg 0)

Tobias bad om och godkände en utvecklingsplan (genom `ExitPlanMode`) för att
föra webbspelet från Minecraft-aktigt till verklighetstroget, byggd på en
156-agents jämförelseanalys av Drive-mappen UBRF mot `src/*.js`. Planfilen
ligger kvar i den session som skrev den; dess sju faser (A–G, ~60 steg) och
deras beslutsspärrar är auktoritativa för det här arbetet.

- Aktivt spår: **webb-realism-utvecklingsplanen, Fas 0** (inget beslut krävs,
  inga Roblox-beroenden för de batcher som redan är levererade).
- Aktiv gren: **`claude/ridspel-stall-omnejd-zo2zce`** — löper vid sidan av
  `codex/circle-lesson-20260926`; de rör olika filer (motor/rendering kontra
  #266:s ridkvalitet/tävling) och ska inte blandas i samma PR.
- Testpolicy för det här spåret: `WORKING-AGREEMENT.md`:s "bygg utan att
  testa, Tobias speltestar allt i slutet"-regel (2026-09-27) är skriven mot
  namngivna #266-paket och gäller **inte** automatiskt här. Full
  `DELIVERY-PROTOCOL.md`-regim (bevis, falsifiering) gäller för varje batch.
- Levererat hittills: **Batch 0.1** — de två motorbuggarna (felvänd
  ljusnormal i `s3Svep` och `glPlatta`, båda i produktionskod, inte i
  triangelvarvet/kulningen — se kommentarerna i `src/scen3d.js` och
  `src/gl.js`), ny falsifierbar `tools/kullningsgrind.mjs` registrerad i
  `grindar.yml` och i `tools/testa-grindar-workflow.py`:s
  INVENTARIE-kontrakt. Ingen Roblox-motsvarighet krävs (ren
  WebGL-korrekthetsfix, inget delat beteende).
- Levererat: **Batch 0.2** — D1 (hästen fastnade permanent i ett hörn när
  spelaren släppte all styrning; de två en-väggs-redirect-grenarna i
  `stegaRitt` (`src/game.js`) skrev över varandra vid en riktig hörnkollision
  med ett tie-break som jämförde samma bildrutas redan klippta position mot
  föregående bildrutas — i ett hörn nästan identiska) och D2 (halt glider
  ~6,8 cm/s i stället för att stå still; `mal` i `stepRide` (`src/model.js`)
  klampades till lägst 0 men lämnade ändå ett litet, stabilt positivt mål via
  spänning×framåtbjudning även när gångarten saknade norm, dvs. i halt).
  Båda rättade; ny falsifierbar hörn- och halt-regression i
  `tools/ridtest.mjs`. Roblox-kontroll genomförd (läsande, ingen ändring):
  `roblox/src/client/MovementController.luau` löser kollision via riktig
  Humanoid-fysik (ingen hand-skriven väggklamp, alltså ingen motsvarande
  hörnbugg möjlig), och dess halt-formel (rad ~546–573) hoppar hela
  nyanstermen när `gait.norm<=0`, så målet är redan exakt 0 där — ingen
  Roblox-ändring behövs eller är gjord.
- Levererat: **Batch 0.3** — D3 (tangentbordet kan rida skolfigurer).
  `InputFeel.RIDE.digitalGain` (0,42) var ett PERMANENT tak på
  tangentbordsstyrningen i `src/input-feel.js`, oavsett hur länge A/D hölls:
  full digital styrning gav högst κ≈0,127 i skritt (minsta volt ~15,7 m i
  diameter), aldrig en 10 m volt. Rättat: ett hållet tryck ligger kvar på
  42 % de första 0,3 s (oförändrat, "korta tryck förblir små
  korrigeringar") men trappar sedan upp mot full styrka. Hålltiden räknas
  i SIMULERAD tid (ackumulerad `dt` i `src/game.js`, `IN.styrHallt`), inte
  väggklocka — annars blir rampen bildrutetaksberoende, vilket bröt mot
  CLAUDE.md:s släppspärr och gjorde det första försöket (väggklocka via
  `performance.now()`) obrukbart i en syntetisk testmiljö med snabbt
  stegad `dt`. `IN.styrHallt`/`IN._styrForra` nollställs i
  `ridNollstallHjalp()`, samma läckagelektion som D1:s `G._fastDt`.
  Nya falsifierbara prov i både `tools/control-feel-test.mjs` (ren
  styrlagertest, uppdaterar även det gamla "ligger kvar på 42 % i 2 s"-
  provet som kodade den gamla buggen som korrekt) och `tools/ridtest.mjs`
  (full kedja: 10 m volt i skritt och trav med hållet A/D, upprepade
  korta tryck som fortsatt ger små korrigeringar, ett stabilt
  galoppvarv). Roblox-kontroll genomförd (läsande, ingen ändring):
  `roblox/src/client/MovementController.luau:_steer` rampar redan mot
  FULL styrkraft (`SteerTauPress`/`SteerTauRelease`, inget
  `digitalGain`-liknande permanent tak) — bekräftat att detta alltid
  varit en webb-bara bugg, ingen Roblox-ändring behövs.
  **Beslutsspärr (acceptans, inte bygg) kvarstår:** `READY_FOR_PRODUCT_ACCEPTANCE`
  kräver Tobias godkännande av själva tangentbordskänslan (öppnar om
  2026-09-08-beslutet) — byggt och verifierat, men inte produktaccepterat.
- Levererat: **Batch 0.4** — C1, C2, C3 (rätt bentakt, små
  rörelsekorrigeringar, övergångar, markkontakt). Webbens häst hade en
  egen benföljdstabell (`S3FAS`) som var fel, inte förenklad: skritten
  satte i vf → hb → vb → hf, galoppen slog i fel ordning i tre lika slag
  utan sväv och utan fattning. Benen läser nu den delade tabellen
  `GANGFAS` (`src/riding/gangfas.js`, som förut inte ens var med i
  webbygget) genom uppslag portade från `Gangfas.luau`. Tabellens tal är
  orörda (`node tools/exportera-ridkanon.mjs --kontrollera` grön).
  - **C1:** lateral fyrtakt i skritt, diagonalpar med sväv i trav, tretakt
    med sväv och fattning i galopp. `G.varv` och `G.fattning` är port av
    `MovementController._varvOchLedande` och är BARA bild.
  - **C2:** en uppresning per travcykel på yttre framben (fel diagonal
    syns), häl och knä stannar vid stigbygeln, nick i skritt/galopp,
    halsen ställs inåt i sväng, språnget lyfter bogen först (`lut` hade
    fel tecken). `s3MittEkipage` är nu den enda beskrivningen av din häst.
  - **C3:** den visuella gångarten (`ridVisGang`) läser faktisk markfart:
    fastklämd ritas som halt, rörelse med etiketten «halt» som skritt, och
    byten korsblandas över ett halvt steg, linjärt i tid. Hovens mål löses
    nerifrån golvet genom hästens riktiga grundmatris; svepet är
    `stod × cykellängd`, så stödhoven står still. Skenbenen var 6 cm för
    korta (hästen svävade i varje scen) och är rättade — mankhöjd, sadel
    och ögonhöjd är orörda.
  - **Uppmätt:** stödhovens glid 0,00 / 0,11 / 0,55 cm i skritt / trav /
    galopp (med det gamla fasta svepet 33–53 cm); största hovflytt per
    bildruta i ett gångartsbyte 12,2 cm mot 73,2 cm utan korsblandning.
  - **Prov:** ny `tools/gangposetest.mjs` (51 mätningar mot ridlärans
    facit, inte mot tabellen själv; i `grindar.yml` + frysta inventariet)
    och nya block i `tools/ridtest.mjs` (varv, fattning och hals mot en
    volts uppmätta mitt; övergångar vid 30 och 120 bilder/s med
    kontrollmätning). Falsifierad med sex mutationer som alla blir röda:
    `--muter-fas`, `--muter-latt`, `--muter-hopp`, `--muter-glid`,
    `--muter-kontakt`, `--muter-ben`.
  - **Avvikelser från planen, redovisade:** (1) «apex ur hinderhöjd» är
    flyttat till Batch 0.5 (D4), som ändå bygger om avstampet. (2) Planen
    sade «sänk kroppen» — i stället är benen förlängda, så att ingenting
    annat (kamera, ryttare, stall) flyttas. (3) Benet töjs upp till 12 %
    i stödets ytterlägen: riggens ben är för korta för ett 1 m långt
    stöd, och utan töjning når hoven inte marken.
  - **Paritet:** webben hinner ikapp Roblox; inga Roblox-filer ändrade.
    Roblox läser redan tabellen och har ingen språnglutning alls (hoppet
    är fysik där), alltså ingen motsvarande bugg. **En plattformsskillnad
    kräver Tobias ställningstagande:** webben låter svängen avgöra varvet
    i en båge och banans mitt bara på rakt spår; Roblox läser bara banans
    mitt, och byter därför varv två gånger per varv i en volt som rids
    utanför mittlinjen. Föreslagen åtgärd: samma regel i Roblox
    `_varvOchLedande`, som eget steg.
  - **Kvar och inte verifierat:** hur rörelsen KÄNNS och ser ut i fart
    går inte att bedöma automatiskt. Knäets vikriktning (bakåt fram,
    framåt bak) är oförändrad och ser anatomiskt omvänd ut — eget fynd för
    C5, inte rört här. NPC-hästarnas fas går på tid, inte sträcka, så de
    kan fortfarande glida. Alla amplituder, trösklar och blandningstiden
    är `[ANTAGANDE]`.
  **Beslutsspärr (acceptans, inte bygg) kvarstår:** Tobias namnger en
  ridkunnig person som bedömer skritt, trav och galopp i rörelse innan
  `PRODUCT_ACCEPTED`. `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.5** — D4 (hopp som startar före hindret). Över
  ridhusets stående hinder började språnget när hon KORSADE bommen: hon
  gick igenom den på marken och flög sedan över tom sand, och varje hinder
  fick samma 1,15 m höga, 0,55 s långa båge. Nu räknas avstampet ur
  samma avsprångszon som anridningsmodellen redan använder
  (`Approach.zon`), bågens längd ur farten och lyftet ur hinderhöjden
  (`ridHoppMatt`, `ridHinderSprang`, `ridHoppSteg` i `src/game.js`).
  Banans språng begärs som förut när utfallet avgörs, och bilden väntar
  till avstampet (`ridHoppBegar`). BARA BILD: vägran, rivning, felpoäng och
  `HinderObs` är orörda. 2D-vyn och kartan läser bågen genom
  `ridLuftNorm()`, så formen är densamma i alla vyer.
  - **Uppmätt (`tools/ridtest.mjs`, riktig ritt mot 0,68 m-hindret):**
    trav — avstamp 1,31 m före, toppen 0,15 m från bommen, landning 1,39 m
    efter; galopp — 1,88 m före, toppen 0,24 m från bommen, 2,08 m efter.
    Bågen 2,70 m i trav mot 3,97 m i galopp. Lyft 0,83 m över 0,68 m och
    0,68 m över 0,52 m.
  - **Falsifiering (kontrollmätning i samma prov):** med den gamla regeln
    börjar hoppet 0,05 m efter bommen och toppen hamnar 1,60 m efter den.
  - **Utanför den här batchen:** «i skritt stannar hon vid hindret med en
    rad från instruktören» (ur fyndet D4) är en ändring av spelbeteendet
    och kräver Roblox i samma leverans — inte gjord, behöver beslut.
  - **Paritet:** ingen Roblox-ändring. Roblox hoppar med Space och riktig
    fysik; webben hoppar av sig själv över hindret. Det är en befintlig
    plattformsskillnad i själva mekaniken, inte införd här, men den bör
    tas upp i paritetsgenomgången.
  - **Inte verifierat:** hur språnget ser ut i fart. Tidsklämman
    (0,45–0,85 s) och lyftets `0,25 + 0,9 × höjd` är `[ANTAGANDE]`.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- **A2 (kantutjämning) uppskjuten, inte löst i 0.1:** en FXAA-shader
  provades i post-kompositeringen men orsakade en mätbar, reproducerbar
  CI-regression i `tools/lektion-e2e-test.mjs` (headless, mjukvaru-
  rastrerad SwiftShader) — bekräftat två gånger på PR #308 och frånvarande
  på oförändrad `main` samma dag. Grundorsaken: `src/game.js:1311`
  klipper `dt` vid 0,05 s (≈20 fps); sjunker bildrutetakten under det på
  CI:s mjukvaruräknade rendering förlorar den ridna sträckan mot riktig
  tid, exakt det testets 60 s skrittfas mätte. Kantutjämning för den här
  rendervägen kräver ett prestandabudgeterat svar (nivåer, se planens
  Fas 3.0a) innan det kan läggas till utan risk för det låsta kravet
  "frame-rate-oberoende beteende" i CLAUDE.md. Kvarstår som öppen del av
  A2, inte avskriven.
- Nästa batcher (0.2 och framåt) kräver ingen ytterligare uppdatering av det
  här dokumentet förrän de öppnar en PR, men varje batch som rör delad
  `src/site.js`-geometri, ridkanon eller spelarbeteende måste redovisa
  Roblox-paritet enligt planens egna regler innan den är klar.

## Locked physical-test candidate

The current runtime candidate is re-locked after the assigned-horse guide fix.

- Runtime HEAD: **`7fdee3061898456631a914c9902e2363c6fd33a1`**.
- Checklist: [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md).
- Roblox build identity `kallhash`: **`0ce4b14c93e2e7ef15e082c5dfd89120c010fa719099356f99b5c5a1f99540f7`**.
- In-game diagnostics must show prefix **`0ce4b14c93e2`**.
- Any later mapped Roblox-source change invalidates this lock and requires a new identity/checklist lock.

The candidate includes the reviewed lesson/teaching work, D1, D2a, D2b, D2c, D5 Option A/R1, B4a knockdown evidence, B4b R1 neutral disobedience evidence, B4c course-aware shadow judgment, D4a prize persistence foundation and the assigned-horse guide. Physical rows remain **NOT_TESTED** except where Tobias explicitly reports them.

## Physical gate A3

A3 is now in progress with Tobias.

Use only [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md). PC, physical iPad and physical iPhone remain separate evidence. Local tests, source review and emulator evidence do not mark physical rows PASS.

## Current #266 package status

### A — first pass
- A2 candidate lock: current and re-locked through assigned-horse guide.
- A3 physical PC/iPad/iPhone test: **IN PROGRESS**.

### B — riding feel and measurement
- **B4a knockdown event: CHATGPT_REVIEW_ACCEPTED.**
- **B4b R1 neutral disobedience evidence: CHATGPT_REVIEW_ACCEPTED.**
- **B4c course-aware shadow consumer: CHATGPT_REVIEW_ACCEPTED.**
- Remaining B4 gaps are physical or later-scope: real pole behaviour/replication/calibration, circle/track logic and any balking decision.
- Shadow judgment remains non-official until a separate reviewed promotion after physical evidence.

### C — teaching and learning
- Concrete feedback, selected comparisons, event-bound advice, free-practice framing and multiple task lessons are built.
- Less-guidance is built where source geometry supports it.
- Remaining gaps require product choice, persistence/schema work, new measurement or final physical judgment.

### D — competition day
- **D1 A: Clear Round base rule profile: CHATGPT_REVIEW_ACCEPTED.**
- **D2a clear-round training ride: CHATGPT_REVIEW_ACCEPTED through R2.**
- **D2b pre-ride flow: CHATGPT_REVIEW_ACCEPTED.**
- **D2c aftercare handoff: CHATGPT_REVIEW_ACCEPTED.**
- **D5 Option A competition clothing: CHATGPT_REVIEW_ACCEPTED through R1.**
- **D4a prize/trophy persistence foundation: CHATGPT_REVIEW_ACCEPTED.**
- Warm-up remains blocked on verified mapping of UBRF's real "Lilla utebanan" or an explicit Tobias game-simplification decision.
- Real Clear Round rosette award remains blocked until physical knockdown/refusal evidence is verified and D2 is explicitly promoted from shadow to official.

### Runtime blocker fixes during Tobias QA
- **Assigned-horse guide: CHATGPT_REVIEW_ACCEPTED.**
  - one local marker only, on the assigned horse;
  - large gold ▼ plus horse name;
  - visible from spawn, hidden close/leading/mounted;
  - survives respawn and delayed/replaced horse model;
  - Studio engine properties verified; human visual quality still requires Tobias.

## Produktbeslut 2026-10-04 (ledning och manuell skötsel borttagna)

- Beslutet finns i [PRODUCT-CANON](PRODUCT-CANON.md), «Produktbeslut 2026-10-04».
- Genomförandet ligger på branch `claude/ta-bort-ledning-skotsel` (#265) och är
  `READY_FOR_REVIEW` först när den granskats; det är inte produktacceptans.
- P1 (ledd häst genom öppningar) är **NO_PORT**.
- Den fysiska testlistan i [FINAL-PLAYTEST-CHECKLIST.md](FINAL-PLAYTEST-CHECKLIST.md)
  innehåller rader för ledning och skötsel som inte längre gäller; den låsta
  kandidaten ovan är därför äldre än beslutet och måste låsas om.

## Limits

- No merge, publication or product acceptance is implied by source review.
- Do not award an official Clear Round rosette while knockdowns/refusals are not truthfully established.
- Do not let HinderObservation make course-aware sporting judgments.
- Do not promote B4c shadow output to official D2 judging without a separate review/decision.
- Do not silently map `UTEBANA` or `PADDOCK` to UBRF's "Lilla utebanan".
- Prize persistence may exist before awarding; no source path currently awards a real Clear Round prize.
- Competition results must stay deterministic, versioned and source-backed.

Historical gate material from #264 is preserved in [history/ACTIVE-GATE-20260926](history/ACTIVE-GATE-20260926.md).
