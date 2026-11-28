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
- Levererat: **Batch 0.6** — F1 (hovslagstakt från den delade
  fottabellen). `ljudRittSteg` delade förut fasen jämnt: skritten fick TVÅ
  slag per cykel (den har fyra) och galoppen tre lika långa (den har tre
  slag och en paus). Nu läser ljudet samma rad i `GANGFAS` som benen, med
  samma fas — port av Roblox `SoundController` (`gangSlag`,
  `gangPasserade` i `src/riding/gangfas.js`). Slagen läggs på
  ljudklockan (`AudioContext.currentTime`) i stället för på bildrutan,
  ett gångartsbyte seedar om utan extra slag, och ljudet följer den
  visuella gångarten och tystnar i språnget.
  - **Prov:** ny `tools/ljudtakttest.mjs` (15 mätningar med en attrapp av
    ljudklockan, i `grindar.yml` + frysta inventariet): fyra / två / tre
    slag per cykel, galoppens paus, under 1 ms fel vid 30, 60 och 120
    bilder/s, inga tappade slag vid 5 bilder/s. Falsifierad:
    `--muter-takt` (56 ms fel) och `--muter-klocka` (22 ms fel) blir röda.
    Detta stänger planens kända lucka «inget ljudtestverktyg finns» för
    just takten.
  - **Paritet:** webben hinner ikapp Roblox; ingen Roblox-ändring.
  - **Inte verifierat:** provet HÖR ingenting. Klang, styrka, betoningen
    på galoppens första slag (`[ANTAGANDE]`, oförändrad) och hur takten
    låter på en riktig telefon kan bara en människa avgöra. Bildrutans
    fördröjning på takten (en bildruta) är ett medvetet val.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.7** — F2 (mobilljudshygien och riktiga UI-toner).
  - **Tonerna:** åtta anrop (`src/framsteg.js`, `src/moment.js`,
    `src/efter.js`) skickade «sine» som FILTERTYP till brusstöten. Det är
    en vågform, inte ett filter; det som hördes var samma brusstöt för 240
    och 990 Hz, så rätt och fel svar lät likadant. Ny `ljudTon` i
    `src/ljud.js` är en riktig sinuston med mjuk in- och uttoning.
  - **Upplåsningen:** ljudet väcktes bara på `pointerdown`/`keydown`.
    Safari på iPhone räknar inte `pointerdown` som en gest som får starta
    ljud; nu lyssnar spelet också på `touchend`, `pointerup` och `click`.
  - **Avbrott:** kontexten återupptas när sidan syns igen
    (`visibilitychange`, `pageshow`), även ur iOS-tillståndet
    `interrupted` — men aldrig i bakgrunden och aldrig på en sida som inte
    rörts. Fortfarande exakt EN `AudioContext`.
  - **Prov:** `tools/ljudtakttest.mjs` utökad till 23 mätningar.
    Falsifierad: `--muter-vack`, `--muter-avbrott` och `--muter-ton` blir
    alla röda.
  - **Medvetet INTE gjort, redovisat:** planens «förrenderade
    engångsbuffertar» och «ljudinbäddning i `tools/build.py`». Det finns
    ingen mätning som visar att nodskapandet kostar något, och inga
    ljudfiler att bädda in. Båda hör hemma efter enhetsmätningen
    (Batch 1.2) respektive inspelningarna (6.6) — att bygga dem nu vore
    infrastruktur utan användare.
  - **Paritet:** webb-specifik ljudmotor; ingen Roblox-motsvarighet.
  - **INTE VERIFIERAT — det här är den viktiga raden:** ingenting av
    detta är provat på en riktig iPhone eller iPad. Provet kör en attrapp
    av ljudklockan och kan inte veta hur Safari faktiskt beter sig.
  **Beslutsspärr (acceptans, inte bygg):** Tobias provar på sin egen
  iPhone, och avgör om spelljudet ska lyda ljudlös-knappen (Web Audio gör
  det av sig självt på iOS; koden försöker inte kringgå det).
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.8** — F3 (underlaget styr fotsteg och hovslag,
  och engångsljuden går att nå).
  - **Underlaget:** fotstegen visste bara «sten» i stallet och «grus»
    överallt annars; hovslagen valde underlag ur plats och väder. Nytt
    uppslag `ytaVid(scen, x, y, z)` i `src/site.js` läser SAMMA markdata
    som ritas — `ANL.mark` och `ANL.cirklar` på gården («senare vinner»),
    stallets gångar/service/klubbdel, ridhusets bana. Ingen ny geometri
    och ingen ny exporterad nyckel (`exportera-geometri.js --kontrollera`
    oförändrat grön).
  - **Belägg per yta:** marksten i stallgångens mittstråk och betong
    längs servicedelens yttervägg (`references/buildings/stall/
    INTERIOR-MATRIS.md` rad 81–82, 121–122), ridbanans sand-/flisblandning
    (`references/buildings/ridhus/INTERIOR-MATRIS.md` rad 73). Spån i
    boxarna är `DERIVED` ur rad 83–84.
  - **`[REFERENCE GAP]`, inget påhittat:** ridhusets läktare, klubbdel
    och kafé samt skogsstigen har inget belagt underlag knutet till en yta
    och svarar `okand`, som låter som förut (grus).
  - **Klangen:** en rad per underlag i `LJUD_YTA` (`src/ljud.js`). Fiber,
    grus, vått grus och stallgångens fotsteg har EXAKT sina gamla värden;
    det nya är att sand, gräs, åker, asfalt, betong och spån inte längre
    låter som grus. Regnet läggs ovanpå underlaget och når inte in i
    ridhuset.
  - **Engångsljuden:** fnys, stamp, gnägg och fågel låg bakom brusbäddens
    typ och spelades därför aldrig (bädden är avstängd med flit och är det
    fortfarande). De väljs nu ur scenen och kräver en synlig källa: en
    häst i en box (`boxHast`) respektive i en hage (`ANL.hagar`). Fågeln
    tiger i regn. Ridhusets inre har inga.
  - **Prov:** `tools/ljudtakttest.mjs` utökad till 34 mätningar (17 kända
    punkter mot facit ur datans kommentarer och INTERIOR-MATRIS).
    Falsifierad: `--muter-yta`, `--muter-senare`, `--muter-puls` och
    `--muter-kalla` blir alla röda.
  - **Utanför batchen:** steg utlösta ur gångcykeln till fots (kräver en
    fotfas som inte finns), stereo/avstånd/rumsklang (0.9).
  - **Paritet:** ingen Roblox-ändring. Roblox väljer redan underlag ur
    markens material (`SoundController.SURFACES`, raycast) i fem klasser;
    webben har nu nio. Att samma punkt ger samma klass på båda ytorna är
    INTE mätt — det kräver Studio.
  - **Inte verifierat:** hur underlagen låter. Klangerna är syntetiska
    `[ANTAGANDE]` tills riktiga inspelningar finns (Batch 6.6).
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.9** — F4 (rumsklang: hall, stall och utomhus).
  Varje ljud kopplades rakt till huvudvolymen: torrt, i mitten, på fast
  nivå — ridhuset, stallet och gården lät identiskt.
  - **En väg ut, tre rum** (`ljudUt`, `ljudByggRum`, `ljudRum` i
    `src/ljud.js`): torr signal plus en sändning till rummets efterklang.
    Hallen (ridhuset, till fots och till häst) lång och mörk, stallet kort
    och ljust, ute ingen alls. Bytet tonas över 0,3 s. Noderna byggs en
    gång.
  - **Källa med läge:** stalljuden och gårdens gnägg (som fick en synlig
    källa i 0.8) placeras nu vid EN av de synliga hästarna —
    panorering ur vinkeln mot blickriktningen, styrka som avtar med
    avståndet (`ljudPlacera`). Egna hovslag och fotsteg ligger i mitten.
  - **Gränssnittets toner är torra**; en knapp ekar inte.
  - **Strömbrytare** `LJUD.rum` (på som standard) om enhetsmätningen
    (Batch 1.2) visar att efterklangen kostar för mycket.
  - **Prov:** `tools/ljudtakttest.mjs` utökad till 47 mätningar och läser
    nu själva ljudgrafen. Falsifierad: `--muter-rum`, `--muter-pan` och
    `--muter-ui` blir röda (totalt tolv mutationer i filen). Rökprov i
    riktig Chromium: rummen byggs med webbläsarens egna noder, 1,6 s och
    0,35 s, impulsen genereras på 4 ms, inga sidfel.
  - **Avvikelse från planen, redovisad:** fyndet sade «tuned by ear».
    Det har inte gjorts och kan inte göras av kod. Efterklangens längd,
    mörkhet och nivå samt avståndskurvan är uttalade `[ANTAGANDE]` och ska
    ersättas av en riktig klappinspelning (G7, Batch 6.6).
  - **Paritet:** webbens egen ljudmotor, ingen delad data, ingen
    Roblox-ändring. Läst: Roblox har avståndsdämpning på sina ljud
    (`RollOffMaxDistance` i `SoundController`) men ingen rumsklang. Det är
    en plattformsskillnad att ta ställning till.
  - **INTE VERIFIERAT — och det är det som avgör batchen:** hur det
    låter. Provet visar att rätt rum väljs och att höger är höger, inte att
    hallen låter som UBRF:s ridhus.
  **Beslutsspärr (acceptans, inte bygg):** Tobias lyssnar, helst i
  hörlurar och på telefon. `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.12** — inga moln inomhus. Molnnätet ritades först
  i varje scen, utan djupskrivning, och syntes därför inomhus i varje
  springa mellan vägg och tak: klotmoln inne i ridhuset och stallgången.
  `s3RitaMoln(k, inne)` i `src/scen3d.js` är nu EN funktion för båda
  ritvägarna (ritten och till fots i `src/varld3d.js`) och ritar bara ute.
  Himlens gradient ritas som förut, så fönster och portar visar himmel.
  - **Prov** (`tools/kameratest.mjs`, riktiga bildrutor): molnnätet ritas
    8 av 8 bildrutor på gården, 0 i stallet, 0 i ridhuset till fots och 0
    i sadeln i ridhuset; kontrollmätning på ett direkt anrop.
  - **INTE gjort, redovisat:** planens «flytta släpvagnsrekvisitan».
    Hästtransportens läge (`src/site.js`, `ANL` rekvisita, `pos:[133,125]`)
    nämns inte i `SITEPLAN.md` eller något `KORT.md`, och det finns inget
    belagt läge att flytta den till. Att flytta den för en jämförelsebilds
    skull bryter mot byggnadsregel 10. Den står kvar; beslutet är Tobias.
  - **Paritet:** ingen Roblox-ändring. Roblox har inget motsvarande
    molnnät i koden (läst `roblox/buildings`, `roblox/src`, `roblox/game`).
  - **Visuellt:** varje innebild ändras (molnen är borta). Skärmdumps-
    paketet behöver ses om medvetet.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.10** — E1 (ordval och pronomen). Texterna ligger i
  den delade språkkatalogen `src/spel/sprak.js`; `roblox/game/UBRFSprak.luau`
  och `UBRFSkotsel.luau` är omgenererade ur den (`tools/exportera-spel.js`),
  så båda plattformarna har samma ord i samma commit.
  - **Ordval:** «mittlinjen» → «medellinjen» (17 rader), «ett halt» →
    «en halt» (3 rader).
  - **Pronomen:** 63 katalograder kallade en ospecificerad häst «hon» —
    alltså även varje valack. De säger nu «hästen» / «din häst» (en:
    «your horse»). Texter om en NAMNGIVEN häst behåller mekanismen som
    redan fanns (`harledPronomen`, `hastPron`): han/hon ur hästens egen
    beskrivning, namnet när källan saknas. Samma genomgång i webbens egna
    rader (`humor.js`, `efter.js`, `moment.js`, `intro.js`, `scenes.js`,
    `sysslor.js`, 22 rader).
  - **Kvarlevor från före 2026-10-04:** «Du hittade något» → «Stallet
    hittade något» (stallet gör visitationen), «Lös det själv och sadla» →
    «…och rid ändå», och hästbytets «börja om med boxen, sadeln och
    skötseln» → «stallet gör den nya hästen redo».
  - **Spärr:** `tools/sprakgrind.mjs` steg 7 nekar «mittlinje», «ett halt»
    och könat pronomen i katalogens strängar på båda språken. Ingen
    undantagslista behövdes. Falsifierad: `--muter-ordval` blir röd.
  - **Prov som uppdaterats:** sju prov citerade de gamla lydelserna
    ordagrant (fem Luau-specar, `simplifytest`, `stegkorttest`,
    `ridpaneltest`). Citaten är bytta till de nya texterna; inga krav är
    ändrade. `roblox/tests/kor.sh` grön lokalt (luau hämtad som i CI).
  - **INTE gjort, kräver beslut:** gruppnamnet «Ledlektion» och ordlistan
    bakom «?»-knappen (ny yta på båda plattformarna, innehåll att
    godkänna).
  **Beslutsspärr (acceptans, inte bygg):** Tobias granskar ordvalen. De är
  ett förslag, skrivna i egna meningar — särskilt valet att säga «hästen»
  i stället för att lägga in hästens namn i varje rad.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.11** — E2 (avsittning bara från halt), **båda
  plattformarna i samma leverans**. Före batchen satt SITT AV av i vilken
  fart som helst — uppmätt galopp 5,76 m/s på webben, och Roblox klient
  hade samma väg (`begarAvsittning` direkt ur knappen).
  - **Regeln, samma på båda ytorna:** står hästen (gångart halt och högst
    0,05 m/s) sker avsittningen direkt, som förut. Rör hon sig blir trycket
    en BEGÄRAN: stallet tar ner henne genom de nedåtgående steg som redan
    finns, en rad säger «Vi stannar först. Du sitter av när hästen står
    still.», och avsittningen sker när hon står. Efter 6 s sitter spelaren
    av ändå (nödutgång). Ett andra tryck startar inte om klockan och
    sitter inte av i förtid; ett DRIV från spelaren tar henne inte upp
    igen; stallets broms besvarar inget lektionskort och räknas inte som
    spelarens hjälp.
  - **Webb:** regeln i `src/riding/avsittning.js` (ren, tre funktioner);
    `ridAvsittning`/`ridAvsittSteg`/`ridAvsittningNu` i `src/game.js`;
    nedtagningen är samma halvhaltsförlopp som BROMS/S. Pekknappen
    SITT AV går samma väg (`data-tap="KeyE"`).
  - **Roblox:** samma tre funktioner i `roblox/src/client/Avsittning.luau`;
    `init.client.luau` låter `E`, styrkorset ned och pekytans SITT AV gå
    genom `onskarAvsittning`, och bildrutans steg ger ridtrappans egna
    BROMS-impulser genom `Input`s spärr (ryggar hon: ett DRIV upp till
    halt, aldrig ett BROMS till). `UgnetaController.sakerhetsrad` går före
    allt annat hon säger. **Servern är orörd** — `HorseService.dismount`
    måste kunna sätta av vid frånkoppling och städning oavsett fart.
  - **Delade tal:** `RID_KANON.AVSITTNING` (webb) → exporteras som
    `RidKanon.AVSITTNING`; Roblox egna tal i `Config.AVSITTNING`, och
    specen faller om de glider isär. Ny språknyckel `avsittning.bromsar`
    (sv/en) i den delade katalogen.
  - **Mätt (webb, `tools/avsittningtest.mjs`):** skritt → halt 1,30 s,
    trav → halt 2,65 s, galopp → halt 3,85–4,00 s; hon står (0,02 m/s)
    när ritten lämnas. Falsifierad: `--muter-halt`, `--muter-nod`,
    `--muter-omstart` blir röda, och kontrollmätningen med den gamla
    regeln sitter av i 5,76 m/s.
  - **Mätt (Roblox-bänken, `klient-sittav-halt.spec`):** galopp → halt
    2,27 s i tre BROMS-steg, `DismountRequest` först vid 0,04 m/s; ur
    ryggning ett DRIV; nödutgången vid 6,03 s. Kontrollmätning med den
    gamla regeln: `DismountRequest` vid 5,73 m/s.
  - **Avvikelse mot arbetsordern:** nödutgången är 6 s, inte 5. Mätningen
    visade ett fall på 5,20–5,35 s (trav, drivande hjälp given strax före
    SITT AV: modellen tappar aldrig bort en hjälp, så hästen fullföljer
    övergången upp till galopp innan stallet tar ner henne). Med 5 s
    löste nödutgången ut vid 0,37 m/s i just det fallet.
  - **Ändrat prov:** ett fall i `klient-ridhandlingar.spec` satt av i
    skritt och väntade sig avsittning i samma tryck. Kravet på vad som ska
    vara rivet efteråt är oförändrat; fallet stegar nu fram till halten.
  - **Känd begränsning, lika på båda ytorna:** ett pågående lektionsförsök
    bedöms som vanligt under de sekunder stallet bromsar och avbryts först
    vid själva avsittningen. En halt som stallet rider kan alltså i
    princip räknas som ryttarens i en haltövning. I Roblox bedöms försöken
    av servern, som den här batchen inte rör; därför är webben lämnad
    likadan i stället för att bli ensam strängare. Föreslagen följd:
    servern får veta att avsittning är begärd och avbryter försöket då.
  - **Inte verifierbart härifrån:** Roblox-delen är stubbad Luau-evidens.
    Att servern godtar BROMS-stegen i klientens takt, att nedtagningen
    känns rätt och att pekknappen beter sig på en riktig enhet är ett
    Studio-prov — NOT TESTED. På webben mäts nödutgången i regeln (30, 60
    och 120 bilder/s) men inte hela vägen i webbläsaren: inget prov får
    där en häst att vägra halt i sex sekunder.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.15** — G8 (lektionshandledningens sammanfattning
  rättad). `references/education/srf-ridning-lektionshandledning.md`
  påstod att Drive-filen `1.pdf` var 2026 års uppdaterade upplaga och gav
  stöd för lektionens upplägg och säkerhet. Alla 32 sidor är lästa som
  bilder: det är «Ridning – lektionshandledning, dressyr» av Bo Tibblin,
  © 2005 Svenska Ridsportförbundet (tryckort s. 4), ett övningshäfte för
  instruktören. Det har **inget** om lektionens upplägg, uppsittning,
  avsittning, uppvärmning, hjälm, avstånd eller lättridning — filen säger
  nu det uttryckligen, sida för sida, och bär i stället de fakta häftet
  faktiskt innehåller (volter, serpentin, galoppfattning, halvhalt,
  övergångar, skänkelvikning), med sidhänvisning och egna ord. UBRF:s
  eget lektionsformat är märkt `[REFERENCE GAP]`. PDF:en förblir
  `[DRIVE-ONLY]`: s. 4 förbjuder kopiering utan förbundets medgivande.
  Tryckorten och s. 9 är kontrollerade två gånger, oberoende; övriga
  sidor en gång. Ingen kod, inget spelbeteende ändrat.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.14** — G2, så långt det går utan Tobias: ett
  **utkast** till samtyckesförfrågan till klubben,
  `references/licenses/SAMTYCKE-FORFRAGAN-UTKAST.md`. Sex frågor som kan
  besvaras var för sig (fotografera/mäta, igenkännbar återgivning,
  sponsorskyltar, klubbmärket, hästarna, ljud), tre utfästelser (inga
  personer, inga barnröster, fotona publiceras inte), hur svaret ska
  sparas, och en tabell över vilka batcher som väntar på vilket svar.
  **Ingenting är skickat.** Fem fält är lämnade åt Tobias (mottagare,
  hur spelet sprids, betalning/reklam, privatägda hästar, kontaktväg).
  Inget i spelet eller referensbiblioteket är ändrat i väntan på svaret.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 0.13** — G1 (Drive-materialet in i
  referensbiblioteket), den del som inte kräver samtycke.
  - **Manifest för allt:** `references/DRIVE-MANIFEST-2026-11-26.tsv` har en
    rad per fil i Drive-mappen — 211 foton, 24 filmer, 64 övriga — med
    Drive-id, sha256 för originalet, byggnad och zon, om personer,
    registreringsskyltar eller läsbara personnamn syns, status och
    repo-filens sökväg och sha256.
  - **92 foton migrerade** som JPEG-derivat (2048 px, kvalitet 85,
    EXIF/XMP borttagna, 52,6 MB) till `buildings/ridhus/drive-2026-11-26/`
    (26), `buildings/stall/drive-2026-11-26/` (60) och
    `omnejd/drive-2026-11-26/` (6). 93 foton låg redan i repot. 185 av 211
    har därmed en repo-motsvarighet.
  - **26 foton och alla 24 filmer är kvar som `[DRIVE-ONLY]`** tills
    samtycket finns: 10 foton med en person, 11 med registreringsskylt, 5
    med läsbara personnamn.
  - **Granskat för hand:** alla 92 på kontaktkartor, med utsnitt i full
    upplösning av bilar, whiteboard, boxskyltar och anslag. Fem bilder som
    maskinläsningen släppt igenom hölls tillbaka — whiteboarden i
    teorisalen bär ett lägerschema med förnamn, och ett anslag en
    kontaktlista. Gränsen: varje skylt och papper är inte läst i full
    upplösning.
  - **Ny grind:** `tools/kolla-referenser.py` (i CI). `CHECKSUMS.sha256`
    hänvisade till verktyget utan att det fanns, och åtta bilder under
    `references/omnejd/` stod aldrig i listan; den täcker nu alla 432
    mediafiler. Grinden faller också om en `IN_REPO`-rad pekar fel, om ett
    foto med person, skylt eller namn fått ett derivat, eller om ett
    derivat bär EXIF. Falsifierad med sex manipulerade kopior.
  - **Supabase:** raderna står som förslag i
    `references/manifest/reference_assets-2026-11-26.sql`. **Inte körd**,
    och med avsikt utanför `supabase/migrations/`.
  - **Ingenting är ändrat i Drive.**
  - **Avvikelser mot arbetsordern:** planen sade 12 felsorterade foton;
    med definitionen «Drive-mappen säger en byggnad, bilden visar en annan»
    är de sex. Planen räknade med upp till ~100 migrerade bilder; det blev
    92. `Ridhuset/IMG_0098.HEIC` gick inte att hämta som original men
    finns redan i repot.
  - **Noterat, inte ändrat:** 28 av de tidigare migrerade bilderna visar en
    person och 4 en registreringsskylt; `stall-inne-07-spolspiltan.jpg`
    ligger upp och ner. Båda står i `references/DRIVE-SOURCE-INDEX.md`.
  - **Inte verifierat:** bildernas innehållsbeskrivningar («visar:») är
    maskinlästa och på engelska; byggnad och zon är min läsning av bilden.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.1** (delvis) — byggnadskorten rättade mot foton som
  migrerades i Batch 0.13. Bara det bilderna belägger; **ingen kod är
  ändrad**, och varje ställe där bygget nu avviker från kortet är utskrivet.
  - **Ridhuskortet:** fasadraderna «Långsida N/S, Gavel Ö» (alla
    `[saknas foto]`, med väderstreck som inte stämde med SITEPLAN) är
    ersatta. Långsidan mot grusvägen är fylld ur fem närbilder. Tre
    uppgifter rättas: den svarta listen går **inte** runt huset; dörrarna
    under entrétaket är svarta, inte vita; raden höga fönster sitter på
    gårdssidan, inte på skyltsidan. **Takfoten är mätt till 5,5 m
    (5,2–5,9)** mot en dörr i samma väggplan — byggt värde är 6,2 m.
  - **Stallkortet:** östra långsidan var `[saknas foto]` och byggd som
    spegling av den västra. Tio närbilder visar en gavlad utbyggnad med hög
    grå pardörr och ett fönsterband under takfoten. Utbyggnadens läge
    längs huset förblir `[REFERENCE GAP]`.
  - **Stallets INTERIOR-MATRIS, taket:** raden «tvärbalkar + snedstag +
    nockbalk» är rättad. Tre bilder (varav den raden själv hänvisade till)
    visar lutande limträsparrar och en lanternin i nocken.
  - **SITEPLAN:** underlagstabellens rader för de berörda fasaderna.
  - **Avvikelser mot bygget som korten nu säger ut** (att rätta i 1.6, 3.3
    och 3.4, inte här): svart list runt hela ridhuset, tvärbalkar i
    stalltaket, speglad östfasad på stallet, takfot 6,2 m.
  - **Inte gjort:** bokstaven H:s bild i ridhuset (ingen av de migrerade
    bilderna visar skylten läsbart), ridhusets INTERIOR-MATRIS, stallets
    södra gavel (underlaget är filmer, som är `[DRIVE-ONLY]`), och
    interiörerna i klubbdelarna. Alla 92 bilder är sedda på kontaktkartor;
    15 är öppnade var för sig för korten.
  - **Min läsning, inte bekräftad:** att «hagsidan» är den östra följer av
    SITEPLAN; mätningen av takfoten vilar på ett antaget dörrblad på 2,05 m.
  Kontroller: `kolla-nyckelbilder.py`, `kolla-dorrfarg.py`,
  `kolla-referenser.py` gröna. `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.2, kodhalvan** — strömbrytaren och bildrutemätaren.
  Enhetsmätningen (Tobias iPad och iPhone) och valet av lägsta stödda
  enhet är INTE gjorda; de är batchens andra halva och kräver beslut.
  - **`?realism=1`** — strömbrytaren för allt Fas 1 ska bygga. AV som
    standard. I den här batchen läser ingenting den: provet faller om någon
    annan källfil än `src/bildmatare.js` nämner `REALISM`.
  - **`?fps=1`** — bildrutemätaren: bilder per sekund över de senaste 60
    rutorna, sämsta rutan i millisekunder, och hur många rutor som slog i
    spelets dt-tak på 0,05 s (det tak som fällde FXAA-försöket i 0.1).
    Syns bara när den är påslagen och tar inga tryck från spelet.
  - **Spelet är orört:** spelloopen har fått EN rad, som lämnar över
    bildrutans längd; `dt` räknas som förut. `tools/bildmataretest.mjs`
    (nytt i CI) mäter det statiskt, räknar mätarens tal i regeln och
    öppnar spelet med och utan parametrarna. Falsifierad: `--muter-pa`,
    `--muter-synlig`, `--muter-klipp` blir röda. Hela ridsviten går också
    med brytaren på: `UBRF_FRAGA='?realism=1&fps=1' node tools/ridtest.mjs`.
  - **Paritet:** ren webbteknik för mätning och jämförelse; ingen
    spelregel, ingen text och inget spelaren ser utan att be om det. Ingen
    Roblox-motsvarighet behövs för ett mätverktyg, men varje senare batch
    som låter brytaren ändra bilden behöver det undantag planen beskriver.
  - **Ett tal ur provet, inte en mätning:** den huvudlösa provwebbläsaren
    här ritar ~7 bilder/s med mjukvarurendering. Det säger ingenting om en
    riktig enhet.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.1, resten** — interiörerna och bokstaven H. Bara
  dokument; **ingen kod är ändrad**.
  - **H är en häst, inte ett hus.** Ridhuskortet hade «H = hus» som
    `[antagande]`. `ridhus-inne-30-sargen-vid-h.jpg`, som redan låg i
    repot, visar skylten på nära håll: svart «H» och intill den en grå häst
    i profil. Bilden sitter till höger om bokstaven sedd inifrån banan.
    `src/data.js` har kvar `bild:"hus"` — delad kanondata, att rätta på
    båda plattformarna i samma leverans (planens Batch 2.3).
  - **Stallets klubb- och servicedel:** nytt avsnitt i stallkortet som
    inventerar sju rum ur 28 bilder (sadelkammaren, lektionssalen,
    uppehållsrummet, besökshörnan, låneutrustningen, toaletterna,
    servicepassagen). Matrisens rad «Rummens inredning» är inte längre
    `[REFERENCE GAP]`; rummens läge i planen är det fortfarande.
  - **Ridhusets klubbdel, läktare och C-ände:** nytt avsnitt i ridhuskortet
    som inventerar sexton bilder.
  - **Boxgångarna:** namnskyltarna på boxfronterna, storsäckarna i gången
    och de vita rören i takhöjd är tillagda.
  - **Gränser:** det här är inventeringar av vad som syns, inte en
    avstämning rad för rad mot `INTERIOR-MATRIS.md` — ridhusets matris
    (750 rader) är inte genomgången. Färger är namngivna, inte mätta.
    Skyltar jag inte själv läst i bilden är märkta som maskinlästa.
    Bilderna är sedda på kontaktkartor; H-skylten och en boxskylt är
    öppnade i full upplösning.
  - En bruten tabell i stallets matris (min egen rättelse i förra halvan
    hade hamnat mitt i tabellen) är lagad.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.6 (webb, bakom strömbrytaren)** — stallgångens tak
  efter kortet. **Standardutseendet är orört.**
  - **Med `?realism=1`:** lutande limträsparrar som följer takfallet, en
    lanternin längs nocken med två ljusa glasband, takskivor som slutar vid
    lanterninen. Inga vågräta tvärbalkar, ingen nockbalk, inga takfönster
    i fallet. Allt i `v3dStall`, `src/varld3d.js`.
  - **Utan brytaren:** exakt samma bygganrop i samma ordning som förut.
    Mätt: stallscenens fingeravtryck (alla 1 286 lådor och cylindrar, mått,
    färg och läge) är `fb5652bdf25b3fac` både före och efter ändringen.
  - **Prov:** `tools/stalltaktest.mjs` (nytt i CI) lyssnar på varje del som
    byggs. Av-läget har den gamla stommen; på-läget har 20 sparrar per
    takfall med 3,5 m delning, lutade 11,3° åt var sitt håll, och en
    lanternin; allt under takfoten är detsamma i båda lägena.
    Falsifierat: `--muter-lacka` (brytaren läcker in i standardvägen) och
    `--muter-balk` (tvärbalkarna byggs ändå) blir röda.
  - `tools/bildmataretest.mjs` krävde att ingen fil läste brytaren. Det
    kravet är nu en uttrycklig lista med `src/varld3d.js`, och filen får
    läsa den på en enda rad.
  - **Bild:** `audits/bilder/stalltak-1.6-av-pa-foto.jpg` — av, på och
    `stall-inne-05` sida vid sida från kamera STALL-GANG-A:s läge.
  - **Tre tal är `[antagande]`:** sparrarnas delning (en per boxmodul),
    deras tvärsnitt (0,14 × 0,42 m) och lanterninens mått (1,6 m bred,
    0,45 m glas). Ingen bild ger ett mått.
  - **Det jag ser i bilden och inte har löst:** sparrarna läser bredare och
    ljusare än på fotot. Tonen är den mätta; delningen och tvärsnittet är
    gissade. Samma iakttagelse står redan som öppen punkt 1 i stallets
    `INTERIOR-MATRIS.md`.
  - **Paritet:** Roblox bygger samma gamla stomme (`Anlaggningen.luau`)
    och är **inte** rättad. Med brytaren av ser plattformarna likadana ut.
    När brytaren blir standard ska Roblox rättas i samma leverans.
  - **Inte gjort:** valvfönstren per box (planens andra halva av 1.6) —
    ordern gällde taket.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 2.3, delen H** — bilden vid bokstaven H är en häst,
  på **båda plattformarna i samma leverans**. Det enda ur 2.3 som går att
  bygga utan att ridhallen byts ut (2.2), och den enda ändringen i den här
  omgången som syns utan strömbrytaren.
  - **Före:** `src/data.js` hade `bild:"hus"` vid H, märkt `[antagande]`.
  - **Belägg:** `references/buildings/ridhus/ridhus-inne-30-sargen-vid-h.jpg`
    (låg redan i repot) visar skylten: svart «H» och intill den en grå
    häst i profil. Samma par i `ridhus-inne-28` och `drive-2026-11-26/IMG_0274`.
  - **Webb:** `bild:"hast"`, `bildKalla:"foto"` i `src/data.js`; en ny
    ritning `case"hast"` i `s3BokstavsBild` (`src/scen3d.js`) — grå häst i
    profil, vänd åt vänster som på skylten.
  - **Roblox:** `roblox/buildings/UBRFKomplex.luau` genererad om ur samma
    lista (`tools/exportera-geometri.js`); skyltens attribut `Bild` blir
    `hast`. Roblox ritar ingen bild på skylten i dag, varken före eller
    efter — det är en skillnad som fanns redan och inte rörs här.
    `roblox/game/UBRFBuild.luau` omräknad.
  - **Prov:** `tools/dressyrbokstavertest.mjs` kräver nu att H är en häst
    ur foto, att ingen bokstav har kvar «hus», att varje bild i listan har
    en ritning, och att Roblox-exporten säger samma sak.
  - **Inte ändrat:** skyltens SIDA. Vid H sitter bilden till höger om
    bokstaven sedd inifrån banan; spelet lägger alla bilder till vänster.
    Det är belagt för H men inte kontrollerat för de andra, och en flytt
    av en enda skylt hade gjort raden ojämn. Sju bokstäver har kvar
    antagna bilder (A, K, V, E, S, P, R).
  - Ritningen är min, gjord för att läsas på håll. Den är inte bedömd av
    någon.
  `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.3** — bildtexturernas väg in i enfilsbygget.
  **Bara röret: ingen yta i spelet byter utseende, och ingen bildfil är
  incheckad.**
  - **Produktbeslut, Tobias 2026-11-26:** (1) webbygget FÅR innehålla
    bildfiler, inbäddade i den enda HTML-filen och fortfarande utan
    nätverk vid körning; (2) den byggda filen får vara högst **4 MB** och
    bygget ska bli rött annars — taket prövas om efter mätningen på riktig
    iPad och iPhone; (3) **bara röret nu**: stallgångens fem material
    (Batch 1.4) väntar på klubbens svar, och brevutkastet ändras inte.
  - **Bygget** (`tools/build.py`): varje fil i `assets/textures/` (JPEG,
    PNG, WebP) bakas in i `window.TEXTUR_DATA`. Bygget AVBRYTS och skriver
    ingen fil när filen går över 4 MB, när en textur inte har sidor som är
    tvåpotenser, när en enskild textur är över 256 kB `[antagande]`, eller
    när en textur saknar rad i `assets/textures/KALLOR.tsv`. En ruta ur
    ett UBRF-foto kräver klubbens sparade svar
    (`references/licenses/SAMTYCKE-UBRF-<datum>.md`); utkastet räknas inte.
    Beslutet «bara röret nu» är alltså en kontroll i bygget, inte en
    minnesregel.
  - **Motorn** (`src/gl.js`): `GL.bildTextur(namn, reserv, upprepa)` ger
    genast en textur med den målade reserven och lägger in bilden i samma
    texturobjekt när den är avkodad. Okänt namn eller trasig bild →
    reserven står kvar. Ingen av de 21 `glCanvasTex`-anropen är utbytt.
  - **Avvikelse från arbetsordern, redovisad:** manifestet skrivs ALLTID,
    också tomt (`window.TEXTUR_DATA={}`, 40 byte). Ordern sade att en tom
    mapp inte skulle lägga till något. Skälet: den byggda filen måste veta
    att den är byggd, annars hade ett okänt texturnamn fått motorn att
    fråga nätet — tvärt emot regeln om inget nätverk.
  - **Storlek:** `dist/ridskolan.html` 1 745 078 → 1 748 111 byte (41 % av
    taket). Ökningen är motorkoden och det tomma manifestet.
  - **Prov:** `tools/testa-texturbygge.py` (23 mätningar; falsifierat med
    `--muter-tak` och `--muter-kalla`) och `tools/texturtest.mjs` (12
    mätningar i webbläsare: reserven direkt, bilden rättvänd i samma
    objekt, okänt och trasigt, aldrig nätet i byggd fil, obyggd version
    läser `assets/textures/`; falsifierat med `--muter-vand` och
    `--muter-reserv`). Båda i `grindar.yml` och inventariet.
  - **Paritet:** ren webbrendering och inget levererat ändras — båda
    plattformarna ser ut som före. Inga Roblox-filer rörda. Ett
    plattformsundantag behövs först när en yta byter utseende (1.4).
  - **Inte verifierbart härifrån:** avkodningstid och minne på en riktig
    telefon. 4 MB och 256 kB är `[antagande]` tills Batch 1.2:s mätning
    på Tobias egna enheter är gjord.
  - Status `READY_FOR_REVIEW`. `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.5 (webb, bakom strömbrytaren)** — linjär färg,
  neutral ton och neutralt omgivningsljus. **Utan `?realism=1` är
  ingenting ändrat.**
  - **Beslut, Tobias 2026-11-27:** «Resten av Fas 1 bakom brytaren».
    Mulet ljus och mjuka figurer får PROVAS bakom `?realism=1`; om de ska
    bli standard avgörs i jämförelsen sida vid sida (Batch 1.10).
  - **Motorn** (`src/gl.js`): en ljusförinställning med `linjar:true` får
    sin belysning räknad i linjärt ljus (`uLinjar`): ytfärgen avkodas,
    ljuset läggs på, resultatet kodas tillbaka. Utan fältet går skuggaren
    samma väg som förut. `gl.js` läser inte brytaren.
  - **Ljuset** (`src/ljus.js`): tre provförinställningar — `realUte`
    (mulet), `realStall`, `realInne` — utan höjd mättnad, utan extra
    exponering och med grått i stället för grönt återsken. `ljusFor`
    väljer dem bara med brytaren på. De fyra gamla är orörda. Alla tal
    `[antagande]`.
  - **Stallet** (`src/varld3d.js`): handkompensationerna mot det gamla
    ljuset (`LYFT`, `PANELLYFT`, golvets dämpning) kopplas förbi med
    brytaren på. Golvet delas då bara med texturens egen medelton
    (uppmätt: marksten 0,592/0,577/0,547, spån 0,826/0,774/0,629).
  - **Mätt på skärmdump från `STALL-GANG-A` med brytaren på**, mot kortets
    färger: markstenen 133/122/103 (kort 134/125/108), spånremsan
    171/151/118 (167/150/121), boxpanelen 64/67/69 (69/74/79), ramen
    166/163/158 (154/155/147), takplåten 111/112/109 (112/113/110).
    Limträet 150/125/106 mot 173/138/112 och väggen 177/164/154 mot
    193/192/195 ligger för mörkt — väntar på innerljuset (1.7).
    **Utan brytaren** ligger boxpanelen på 101/104/101 mot kortets
    69/74/79: provljuset träffar alltså kortet bättre utan någon
    handjustering.
  - **Bevis för «oförändrat utan brytare»:** `tools/linjartest.mjs`
    (fryst avtryck av de fyra gamla förinställningarna, `uLinjar` = 0 i
    alla scener); `tools/stalltaktest.mjs` har kvar fingeravtrycket
    `fb5652bdf25b3fac`. Samma tre kameror renderade på commiten före och
    efter: medelavvikelsen före↔efter (0,0026 / 0,0023 / 0,0039) ligger
    inom bruset mellan två körningar av SAMMA bygge (0,0032 / 0,0021 /
    0,0039), och bildernas medelfärg är lika på 0,1 enheter när.
    **Renderingen är inte reproducerbar pixel för pixel** — slumpade
    texturer och animation — så en exakt pixeljämförelse går inte att göra.
  - **Prov:** `tools/linjartest.mjs` — 15 mätningar; räkningen i båda
    lägena stämmer exakt mot det handräknade (184/156/211 som förut,
    200/189/217 linjärt). Falsifierat: `--muter-lacka` 3 FEL,
    `--muter-kodning` 1 FEL.
  - **Två befintliga prov är ändrade, medvetet:**
    `tools/bildmataretest.mjs` — regeln «en fil, en rad» är nu en
    uttrycklig lista av filer och rader (`src/ljus.js`: `REALLJUS`;
    `src/varld3d.js`: `V3DREAL`, `REALTAK`).
    `tools/stalltaktest.mjs` del 3 — jämför FORMEN under takfoten (typ,
    mått, läge) och kräver att bara boxpanelen bytt färg, i stället för
    att kräva identisk färg överallt.
  - **Med brytaren på är ridhuset och gården halvfärdiga:** de får
    provljuset men har kvar sina handkompensationer. Bara stallgången är
    milstolpen.
  - **Paritet:** webb bakom brytaren; inget levererat skiljer
    plattformarna åt. Inga Roblox-filer rörda.
  - **Inte verifierbart härifrån:** om det ser rätt ut. Det är Tobias
    bedömning, i jämförelsen efter Batch 1.7.
  - Status `READY_FOR_REVIEW`. `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.8 (webb, bakom strömbrytaren)** — mjuka figurer,
  och hela hästar i de närmaste boxarna. **Utan `?realism=1` är ingenting
  ändrat.**
  - **Formspråket** (`src/ljus.js`): `STIL` är «svept» med brytaren på,
    annars «kloss» som förut. Hästen, ryttaren och figurerna hade redan
    en svept form — ingen ny geometri är byggd.
  - **Boxhästarna** (`src/varld3d.js`): de sex bebodda boxar som ligger
    närmast spelaren visar en HEL stående häst (`s3RitaHast`, pose
    «halt») i stället för det lösa huvudet. Boxar längre bort behåller
    huvudet. VILKA boxar som har en häst avgörs av samma villkor som
    förut; bara formen byts. Hästen står vänd mot gången med mitten
    1,35 m från bakre väggen — 2,39–3,04 m från fronten, så att mulen
    också ryms innanför. Sex åt gången och 1,35 m är `[antagande]`.
  - **Skuggan under figuren:** den svepta figuren kastade en projicerad
    skugga per kroppsdel, som överlappade till en fläckig klump under
    fötterna. Med brytaren på får den samma mjuka fläck som klossfiguren.
    Det syntes först när formspråket byttes.
  - **Utgår ur planen:** «släpp mättnadsförstärkningen på pälsar». Någon
    sådan finns inte; pälsen följer den neutrala efterbehandlingen i 1.5.
  - **Inte gjort:** hela hästar i varje box (beslutet om svaga enheter,
    Batch 4.2), vilobeteenden, variation i hur hästarna står.
  - **Prov:** `tools/boxhasttest.mjs` — 15 mätningar: av → 33 huvuden,
    inga hela hästar, «kloss»; på → sex hela hästar i de närmaste
    boxarna, 27 huvuden i de övriga, aldrig båda i samma box, varje häst
    innanför sin box och samma häst som boxen hade; 30 m längre in är det
    sex ANDRA boxar. Falsifierat: `--muter-lacka` 2 FEL, `--muter-dubbel`
    1 FEL. `tools/stalltaktest.mjs` har kvar fingeravtrycket
    `fb5652bdf25b3fac`.
  - **Paritet:** webb bakom brytaren; inget levererat skiljer
    plattformarna åt. Inga Roblox-filer rörda.
  - **Inte verifierbart härifrån:** kostnaden för sex hela hästar på en
    telefon, och om hästarna ser rätt ut. Det senare är Tobias bedömning.
  - Status `READY_FOR_REVIEW`. `JEV_DECISION: JEV_NOT_NEEDED`.
- Levererat: **Batch 1.7 (webb, bakom strömbrytaren)** — innerljus i
  stallgången. **Utan `?realism=1` räknas ingen karta och ingen läses.**
  - **Ljuskällorna** (`src/varld3d.js`, `v3dStallLampor`): EN funktion
    ger pendlarnas och lanterninens lägen. `v3dStall` ritar armaturerna
    ur den och ljuskartan räknas ur den — de kan inte glida isär.
    `src/site.js` är orörd, så ingenting exporteras om till Roblox.
  - **Ljuskartan** (`v3dStallLjuskarta`): 64×256 texlar över stallets
    planyta, ljusnivån vid golvet och i brösthöjd, räknad när stallet
    byggs. 26 pendlar och lanterninen bidrar efter avstånd och
    infallsvinkel, plus en jämn grundnivå. 1,0 är medelnivån på gångens
    golv. Räknetid på den här maskinen: 29–46 ms.
  - **Motorn** (`src/gl.js`): skuggaren skalar scenens ljus med kartan
    efter var ytan ligger. Det gäller allt som ritas i stallet — också
    hästar och figurer. Pendelskärmarna ritas som lysande ytor.
  - **Uppmätt i kartan:** rakt under en pendel 1,05, mitt emellan två
    1,01, i brösthöjd under pendeln 1,48, i en boxes bakre hörn 0,55.
  - **Avvikelse från planen, sagd i förväg i arbetsordern:** kartan
    räknas vid start i webbläsaren och läses per bildpunkt — inte bakad i
    byggsteget och inte per hörn med uppdelade ytor.
  - **Förenklingar, sagda rakt ut:** boxarnas skiljeväggar skuggar inte.
    Klubbdelen norr om den genomgående väggen har inga belagda
    armaturlägen och får en jämn nivå `[REFERENCE GAP]`. Alla styrkor är
    `[antagande]`.
  - **Känd brist som syns i bilden:** ytterväggarna blir mörka (138/126/117
    mot kortets 193/192/195). Kortet säger ett fönster per box längs båda
    långsidorna, men de är inte byggda på insidan (Batch 3.2). Ljus från
    en källa som inte syns har jag inte lagt in.
  - **Prov:** `tools/ljuskartatest.mjs` — 20 mätningar: av → ingen karta;
    på → två räkningar ger samma byte, ljusare under en pendel än
    emellan, gången ljusare än boxens hörn, avtagande ut mot ytterväggen,
    bara grundnivån bakom den genomgående väggen, de 26 pendlar som
    ljussätter är de 26 som ritas, och samma yta RITAS 1,94 gånger
    ljusare under pendeln än i hörnet mot kartans 1,91. Falsifierat:
    `--muter-lacka` 2 FEL, `--muter-lampa` 1 FEL.
    `tools/stalltaktest.mjs` har kvar fingeravtrycket `fb5652bdf25b3fac`.
  - **Underlaget till Batch 1.10:**
    `audits/bilder/fas1-stallgangen-av-pa-foto.jpg` — i dag, provet och
    fotot sida vid sida från `STALL-GANG-A`. Bildrutetakt på den här
    maskinen (mjukvarurendering, säger inget om en telefon): 6,3 bilder/s
    utan brytaren, 5,7 med.
  - **Min läsning av bilden, inte en bedömning:** provet är neutralare,
    hästarna står hela i boxarna och figurerna är mjuka — men det är
    fortfarande långt från fotot. Golvet är ljusare och varmare än
    fotots mörka marksten, boxfronterna saknar fotots stående galler och
    dörrar, och alla ytor är målade, inte fotograferade (1.4 väntar på
    klubben). **Om det övertygar avgör Tobias.**
  - **Paritet:** webb bakom brytaren; inget levererat skiljer
    plattformarna åt. Inga Roblox-filer rörda.
  - Status `READY_FOR_REVIEW`. `JEV_DECISION: JEV_NOT_NEEDED`.
- **Rättelse 2026-11-27 — två skuggare i stället för en** (efter rött
  `ridning` på `09e87bc`, run 45944571668: `lektion-e2e-test`, «fram till
  X i skritt», hästen hann inte fram på 60 s).
  - **Orsak, mätt:** Batch 1.5 och 1.7 lade sina tillägg i den enda
    skuggaren, bakom `if(uLinjar…)` och `if(uLjuskartaPa…)`.
    Mjukvarurenderaren räknar ändå båda grenarna. Bildrutetakt UTAN
    brytare, samma maskin, två mätningar var: före provarbetet
    (`2ac2942`) 12,8/12,9 i ridhuset och 8,9/8,4 i stallet; på `09e87bc`
    9,0/9,0 och 7,3/6,0 — **ungefär 30 % långsammare i ridhuset.**
    Påståendet «utan brytaren är ingenting ändrat» i posterna för 1.5,
    1.8 och 1.7 var alltså sant för UTSEENDET men inte för HASTIGHETEN,
    och det hade jag inte mätt. 1.5 och 1.8 gick igenom CI på marginalen.
  - **Rättning** (`src/gl.js`): två skuggare. Standardskuggaren är
    ordagrant den som fanns före Batch 1.5; provskuggaren görs av samma
    text med fem tillägg (avkodning, återkodning, ljuskartan). Vilken som
    används väljs en gång per bildruta i `GL.start`, av förinställningens
    `linjar`. Efter rättningen: 12,3/11,9 i ridhuset och 8,7/8,2 i
    stallet — tillbaka på nivån före provarbetet, inom mätbruset.
  - **Prov:** `tools/linjartest.mjs` kräver nu att scenerna utan brytare
    ritas med standardskuggaren OCH att dess källtext har det frysta
    avtrycket `c720b40d803d602b` från `2ac2942`. `tools/ljuskartatest.mjs`
    kräver standardskuggaren när brytaren är av. Alla fyra mutationer i de
    två proven är fortfarande röda.
  - **Lärdom för resten av Fas 1:** «bakom brytaren» ska betyda en egen
    kodväg, inte en gren i den gemensamma — och «oförändrat» ska mätas i
    bildrutetakt också, inte bara i färg.
- **Klubbens samtycke, noterat 2026-11-28.** Tobias meddelar att
  samtycket redan är givet, av ridskolechefen. Det täcker alla fyra
  områden: foto, film och mätning · igenkännbar återgivning med
  föreningens namn, också med ytor ur foton · sponsorskyltar och
  klubbmärke · skolhästarna och ljud.
  - **Sparat** i `references/licenses/SAMTYCKE-UBRF-2026-11-28.md`, utifrån
    Tobias besked; själva meddelandet från klubben finns inte i repot, och
    datum och form (skriftligt/muntligt) är inte angivna.
  - **Förfrågan från Batch 0.14 behövdes inte** och är borttagen
    (`SAMTYCKE-FORFRAGAN-UTKAST.md`; finns i historiken). Posten för 0.14
    ovan står kvar som historik.
  - **Står kvar, oberoende av samtycket:** inga igenkännbara personer, inga
    registreringsskyltar eller läsbara namn, inga röster eller
    lektionsljud. De 26 Drive-fotona med sådant och alla 24 filmer
    stannar `[DRIVE-ONLY]`; skälet är nu personerna i bild, inte klubben.
    Privatägda hästar omfattas inte.
  - **Följd:** stallgångens fotomaterial (Batch 1.4) kan byggas; byggets
    spärr släpper in UBRF-fotorutor som pekar på samtyckesfilen.
- **Batch 1.4 — stallgångens fotomaterial, bakom `?realism=1`
  (2026-11-28, READY_FOR_REVIEW).** Tobias: «Bygg Batch 1.4 på riktigt».
  - **Fem rutor ur repots egna foton** (`assets/textures/`, 53 816 byte
    totalt): marksten och limträ ur `stall-inne-05-stallgangen.jpg`;
    boxpanel, galvad ram och takplåt ur
    `drive-2026-11-26/IMG_0153-stall-boxgangar.jpg`. Båda är enligt
    Drive-manifestet utan personer, skyltar och läsbara namn. Varje ruta har
    en rad i `KALLOR.tsv` med källa, utsnittets fyrhörning och samtycket.
    Rutorna görs om med `tools/gor-stalltexturer.py` (Pillow): uträtat
    utsnitt, ljusfallet bortdelat, sömlösa kanter, och medelfärgen satt till
    kortets uppmätta färg — **fotot ger strukturen, kortet färgen.**
  - **Motorn:** provskuggaren (bara den, `GL._prov`) kan lägga en ruta efter
    läget i meter i stället för efter nätets UV (`varld:[bredd,höjd]`), så
    att en ruta får samma storlek på varje yta. Standardskuggaren är
    oförändrad. I `v3dStall` tar golvet, boxfronternas panel och ram,
    takplåten och sparrarna sin ruta via `GL.bildTextur` med kortets färg som
    reserv; ytans egen färg blir vit där fotot bär färgen. Allt på raderna
    `V3DREAL`/`REALTAK` som redan får läsa brytaren.
  - **Utan brytaren:** samma nät och samma skuggare som förut; ingen ruta
    begärs. Bildrutetakten här (SwiftShader, 960×540, två omgångar):
    stallgången 16,4/16,5 b/s före, 16,1/16,4 efter; ridhuset 24,0/25,5
    före, 23,5/24,3 efter — inom spridningen mellan omgångarna. **Filen
    växer i alla byggen**, också utan brytare: 1 765 512 → 1 841 167 byte
    (44 % av taket 4 MB). Med brytaren på i stallgången: 9,7 → 8,7 b/s.
  - **Prov:** nytt `tools/fototexturtest.mjs` (CI, jobb `ridning`): AV
    ingen ruta begärs eller ritas; PÅ alla fem «klar», på sina ytor med sin
    storlek i meter, rutornas medelfärg = kortets (avvikelse 0), och från
    `STALL-GANG-A` har golv och boxpanel samma medelfärg som reserven
    (skillnad ≤ 3) men 5–20 gånger så mycket struktur. Källorna: varje rad
    pekar på ett foto i repot utan personer. Mutationerna `--muter-lacka`
    (2 FEL) och `--muter-kalla` (1 FEL) blir röda.
  - **Medvetet ändrade prov:** `tools/testa-texturbygge.py` krävde att
    `assets/textures/` var tom — nu kräver det att varje bildfil har en
    källrad, att varje UBRF-ruta kommer ur ett foto utan personer, och att
    det riktiga bygget bara skiljer sig från ett tomt i manifestet.
    `tools/stalltaktest.mjs` del 3 tillåter nu, utöver panelen, att ramen
    blir vit med brytaren på — inget annat; fingeravtrycket AV
    `fb5652bdf25b3fac` står kvar.
  - **Inte gjort:** boxfronternas FORM (stående galler, skjutdörrar —
    Batch 3.2, kräver mått), andra rum, Roblox. Rutorna är grova: ljusfall,
    förvrängning och upprepning kan synas, och färgerna är relativa tills
    gråkortsproverna (G4) finns. **Paritet:** webb bakom brytaren; inget
    levererat skiljer plattformarna åt. Samtycket öppnar också för texturer
    i Roblox, som en egen leverans.
  - `JEV_DECISION: JEV_NOT_NEEDED` — deterministisk rendering och data.
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
