# Gate F01 — UBRF Fidelity: resultat

Struktur enligt `docs/GATE-F01-UBRF-FIDELITY.md`.

Datum: 2026-08-30 (uppdaterad efter Senior Fidelity Review 01)
Implementation: Claude Code
Status: **lämnas till ChatGPT för Senior Fidelity Review 02.**

Sedan Review 01 har fem saker hänt: utrymningsplanerna ligger i repot och är
mätta, stallets bredd är nedgraderad från slutsats till antagande med intervall,
ridhusets evidensklass är omärkt till vad den faktiskt är, och **husen är
byggda ihop** efter Tobias besked att de sitter ihop och att det som binder dem
är en hästgång, och Roblox-spåret har fått anläggningens geometri genererad ur
webbkoden i stället för ingen geometri alls.

Gaten stängs inte av mig, och UBRF kallas inte "100 % identiskt": båda byggnaderna
har kvarvarande `ASSUMPTION` och `REFERENCE GAP` som är listade nedan. Väntat
utfall om alla kända motsägelser är lösta men luckor kvarstår är
`FIDELITY READY WITH DOCUMENTED GAPS`, inte `IDENTICAL`.

---

## 1 · Commits

| Commit | Vad | Zon |
|---|---|---|
| `e23b5fb` | Stallet blir ett dubbelstall: 21 m bredd, fyra boxlängor, två gångar, tvärkorridor | Stall inne + ute |
| `424018c` | Ridhusets fem interiörmotsägelser, och bokstäverna flyttade så att A står vid sargporten | Ridhus inne |
| `0d91f8e` | Utrymningsplanerna in i repot; stallets band mätta i planen i stället för likadelade | Källa + stall inne |
| `2fa66dc` | Stallets entréer går att komma in genom igen (räcket, dörrlistorna, balkongen, markörmarginalen) | Stall ute |
| `9b814d7` | Hästgången mellan husen; ridhusets durkplåtsdörrar ur läktarstommen; längan smalnad | Komplex |
| `5998974` | Dokumentationen följer hästgången; Review 01:s tre första invändningar | Källa |

Föregående gate (`aec77cd`, mergad) rörde ridkänslan, inte miljön.

---

## 2 · Källinventering — vad som faktiskt användes

| Källa | I repot? | Använd till |
|---|---|---|
| `references/buildings/stall/*.jpg` — 5 fasad, 14 entré, 22 stallgång | ✅ | Stallets bredd, takgeometri, fönsterrytm, huvrad, förstukvist, gångens tak/golv/boxfronter |
| `references/buildings/ridhus/ridhus-gavel-0{1,2,3}.jpg` | ✅ | Ridhusets gavel, tak, café, färg |
| `references/video/IMG_024{6..9}.mov`, `IMG_0250.mov` | ✅ | Källfilmerna stillbilderna är tagna ur |
| Utrymningsplan, stallet (Presto AB 2025-10-11) | Refererad i `KORT.md`, bilden ej i repot | Planformen: fyra boxlängor, två gångar, klubbdel, servicedel, utrymningsvägar |
| Utrymningsplan, ridhuset (Presto AB 2025-10-11) | Refererad i `KORT.md`, bilden ej i repot | 25 × 75 m, läktaren längs ena långsidan, djup gaveldel |
| `references/DRIVE-SOURCE-INDEX.md` (ChatGPT-verifierat 2026-08-29) | ✅ | Ridhusets fem interiörmotsägelser |
| `IMG_0179`, `IMG_0183`, `IMG_0198`, `IMG_0191.MOV` — Drive-original | ❌ **Ej i repot** | Bara via indexet ovan. Jag har inte sett dem |
| Satellit- och Street View-avläsningar | ❌ Ej sparade | Citerade tal i `SITEPLAN.md`; kan inte kontrolleras om |

**Det viktigaste i tabellen är sista raden med ❌.** Ridhusets fem motsägelser är
byggda från en verifierad textbeskrivning av bilder jag inte har. Det är ett led
längre från verkligheten än stallet, där jag har fotona.

---

## 3 · Fidelity Matrix

`V` = VERIFIED · `D` = DERIVED · `A` = ASSUMPTION · `G` = REFERENCE GAP · `C` = CONTRADICTION

### Stall — exteriör

| Komponent | Status | Källa |
|---|---|---|
| Liggande träpanel, mörk falurött (80,35,47) | **V** | Median av tre fasadbilder |
| Blågrått bandtäckt plåttak (103,112,121) | **V** | Median av bild 03 och 05 |
| Huvrad på nocken, en per box, börjar efter förstukvisten | **V** | Bild 03, 04 |
| Valvfönsterrytm, ett per box, 3,5 m | **V** | Bild 03, 04 |
| Förstukvist: vitt ribbräcke, ockragul dörr, två runda fönster | **V** | Bild 01, 03, 06 |
| Snörasskydd, hängränna, vit fascia och undertak | **V** | Bild 03, 04 |
| Spiraltrappa och balkong på norra gaveln | **V** | Bild 04, 05 |
| Takfot 4,4 m | **D** | Entrédörrens 2,05 m i bild 04 |
| Nock 10,0 m | **D** | Takfot + 28° över 21 m; direkt mätning ger 9,8 m |
| **Bredd 21 m** | **D** | Tre oberoende vägar, se § 6 |
| Längd 54 m | **D** | Satellit 236 px vid 4,4 px/m; stämmer med boxantalet |
| Taklutning 28° | **A** | Flackaste rimliga avläsning; gaveln står vriden i båda bilderna |
| Södra gavelns dörrar och trappa | **A** | Street View på avstånd |
| Östra långsidan | **A** | Speglad från västra; Street View på avstånd |
| Takytan uppifrån | **G** | Inget foto |

### Stall — interiör

| Komponent | Status | Källa |
|---|---|---|
| **Planform: boxrad–gång–boxrad–boxrad–gång–boxrad** | **V** | Utrymningsplanen |
| Klubbdel i ena änden, servicedel i den andra | **V** | Utrymningsplanen + fasadfoton |
| Utrymningsvägar på båda långsidorna och en korridor mitt på | **V** | Utrymningsplanen |
| Sadeltak med galvad korrugerad undersida | **V** | 22 bildrutor ur gången |
| Tegelröda tvärbalkar, snedstag, nockbalk | **V** | Samma |
| Galvade dragstag ner till boxarnas överkant | **V** | Samma |
| Takfönster i rad, runda pendelarmaturer | **V** | Samma |
| Markstensgång med ljus spånremsa längs fronterna | **V** | Samma |
| Boxfronter: mörkgrå komposit nedtill, galvad ram och galler upptill | **V** | Samma |
| Grå port med rund klocka i fonden | **V** | Samma — `[ej byggt]` |
| Fördelning box/gång, 3,5 / 3,5 m | **A** | Residual ur bredden; filmen antyder bredare gång |
| Nio boxar per länga (36 totalt) | **A** | Planen antyder "ett tiotal per länga" |
| Vilken gång filmerna visar | **A** | Spelet lägger den som den västra |
| Sakerna på boxfronterna (sadlar, täcken, grimmor) | **G** | Syns i film, `[ej byggt]` |
| Exakta boxmått och rumsindelning i klubb-/servicedelen | **G** | Planbilden för sned |

### Ridhus — exteriör

| Komponent | Status | Källa |
|---|---|---|
| Vinröd vertikalt korrugerad plåt (97,45,57) | **V** | Median av tre gavelbilder |
| Svart list, vindskivor, takfot, beslag | **V** | Bild 01–03 |
| Vitt skärmtak över svarta dörren | **V** | Bild 01 |
| Caféannex: fyra valvfönster, balkong, ståltrappa | **V** | Bild 03 |
| Runt ventilationsgaller på gaveln | **V** | Bild 01 |
| Fotavtryck 25 × 75 m | **D** | Utrymningsplanen med banans 20×60 som skala |
| Takfot 6,2 m | **A** | Ingen bild visar var taket möter långsidan |
| Taklutning 13° | **A** | Mätspann 11–17° ur bild 03 |
| Takyta och täckning | **G** | Inget foto |
| Långsidorna på nära håll, östra gaveln | **G** | Bara Street View på avstånd |
| Om svarta listen går runt hela huset | **G** | Street Views upplösning räcker inte |

### Ridhus — interiör

| Komponent | Status | Källa |
|---|---|---|
| Vit sarg med svart sockel | **V** | Interiörfoton + indexet |
| Brun ridbaneyta | **V** | Samma |
| Sponsorplåtar på långsidan ovanför sargen | **V** | Samma |
| Höga smala translucenta fönsterband nära taknivå | **V** | Indexet (`IMG_0183`) |
| Läktare i trästomme med nivåer | **V** | Interiörfoton |
| **Mörkröd/maroon övre långsida med horisontella detaljer** | **V** | Indexet (`IMG_0183`) |
| **Stål-/metallprofiler, kabelstegar, ventilation i taket** | **V** | Indexet (`IMG_0179`, `IMG_0183`) |
| **Klocka vid central passage/trappa** | **V** | Indexet (`IMG_0179`) |
| **Trappa med träräcken upp till mörkt träbås med exit-skylt vid E** | **V** | Indexet (`IMG_0198`) |
| **Glasade rum/fönsterpartier bakom sargen** | **V** | Indexet (`IMG_0179`) |
| A vid sargporten ⇒ K-V-E-S-H mot läktaren | **D** | Dressyrkonvention + portens läge + `IMG_0198` |
| Antal och mått på glasade rum, takinstallationer, klockan, båset | **A** | Indexet säger att de finns, inte hur stora |
| Entréhallens möbler och rumsindelning | **A** | Planen visar rum, inte möbler |
| Bildgåtorna vid åtta av tolv bokstäver | **A** | Fyra läsbara i foto, åtta konstruerade |
| Allt som bara finns i Drive-originalen | **G** | Jag har inte sett bilderna |

---

## 4 · Före → efter: motsägelserna

| # | Zon | Motsägelsen | Före | Efter |
|---|---|---|---|---|
| 1 | Stall inne | Utrymningsplanen visar dubbelstall | En gång, två boxrader, 15 m bredd | Fyra längor, två gångar, tvärkorridor, 21 m |
| 2 | Ridhus inne | Långsidans övre yta är mörkröd | Brun panel, och bara i den enkla vandringsvyn | `#5E2C33` med vita läkt, byggd i 3D-interiören |
| 3 | Ridhus inne | Taket har stål, kabelstegar, ventilation | Bara limträbalkar och lysrör | Fyra stålprofiler, två kabelstegar, två ventilationskanaler |
| 4 | Ridhus inne | Klocka vid centrala trappan | Saknades | `klocka:{x:22, y:63.6, z:3.6}` |
| 5 | Ridhus inne | Bås vid E: mörkt trä, trappa med räcken, exit-skylt | Vitt bås på annan plats, ingen trappa, ingen skylt | Byggt vid E, på låg träläktarnivå, med räcken och grön skylt |
| 6 | Ridhus inne | Glasade rum bakom sargen | Bara läktarsteg | Tre partier med ram och mittpost |

**Fynd 7 — inte i briefen, hittat på vägen.** Bokstäverna låg på fel långsida, och
det fanns två sanningar om det: `v3dRidhus` vred hela ringen 180° i renderaren
medan tabellen i `src/data.js` inte var vriden och kartan i `src/render.js` läste
tabellen rått. **2D-kartan visade A i söder samtidigt som 3D-vyn visade A i norr.**
Vridningen ligger nu i tabellen; båda renderarna läser den som den är.

**Fynd 8 — husen var inte sammanbyggda.** Se § 6b. Tobias besked stängde frågan;
hästgången är byggd.

**Fynd 9 — ridhusets durkplåtsdörrar låg inne i läktaren.** Öppningen satt vid
u = 22 i östfasaden, alltså rakt bakom läktaren, som upptar lokala y 9–59. Både
dörrmarkören på gården och landningspunkten inne hamnade inuti en solid
läktarstomme; dörren gick inte att använda i någon riktning. Den hittades först
när hästgången skulle placeras och samma vägg behövde granskas. Flyttad till
u = 5, söder om läktaren.

**Fynd 10 — fyra entréfel i stallet** (`2fa66dc`): förstukvistens räcke gick
obrutet över entrén, två dörrlistor levde parallellt så att `stall_v` satte
spelaren inne i en boxrad, balkongen satt kvar på den gamla gavelmitten 7,5, och
`ridhus_o` låg 0,4 m från väggen mot en kollisionsmarginal på 0,55 m.

---

## 5 · Ridhus exteriör

Inte ändrat i den här gaten. Regressionstestat: fotavtryck 25 × 75, nock nord–syd,
vinröd korrugerad plåt, svarta listen vid 4,10 m, caféannexets fyra valvfönster på
norra gaveln, entrékvisten och den svarta dörren på västra långsidan. Sex
kontroller, alla gröna.

Kvarvarande `A`/`G` enligt matrisen ovan är oförändrade och fortfarande markerade.

---

## 6 · Stall exteriör — bredden

Kortet antog 15 m därför att `STALLINNE` hade en gång och två rader, och
`STALLINNE` byggdes ur de 15 metrarna. Cirkeln bröts av tre oberoende vägar:

**1 · Planformen.** Sex band tvärs huset. Vid 15 m blir varje band 2,50 m. En häst
kan inte stå i en box på 2,5 m djup, och två hästar kan inte mötas i en 2,5 m gång.
15 m är inte bara osäkert utan fysiskt omöjligt givet planformen.

**2 · Rytmen.** Huvarna på nocken sitter ~3,5 m isär, en per box, och valvfönstren
har samma delning — båda avlästa i bild 03 och 04. Sex band à 3,5 m = **21,0 m**.

**3 · Takgeometrin.** Takfot 4,4 m och nock 9,8 m, båda mätta mot entrédörrens
2,05 m i bild 04. Resningen 5,4 m ger:

| Lutning | Bredd |
|---|---|
| 26° | 22,1 m |
| 28° | **20,3 m** |
| 30° | 18,7 m |
| 36° | 14,9 m |

Gavelns takfall mäter 31° och 48°, båda för branta eftersom gaveln står vriden;
28° var den flackaste rimliga tolkningen. För 15 m krävs 35,8°.

**Nockmätningen 9,8 m avfärdades tidigare som "för hög". Den var inte för hög —
bredden var för smal.** Med 21 m blir nocken 10,0 m.

### Rättelse efter Review 01: 21 m är ett ANTAGANDE, inte en slutsats

Review 01 underkände låsningen med rätta: *"3,5 m fönster-/huvrytm är en
mätning i längdriktningen och kan inte bevisa sex tvärgående band à 3,5 m."*
Det är korrekt — väg 2 ovan mäter längs huset och används på tvären. Den faller.

Utrymningsplanen (`0d91f8e`) avgjorde inte heller frågan. Den visade att
**inget** av alternativen går ihop:

| Om … | då blir … | rimligt? |
|---|---|---|
| längden 54 m (satellit) | bredden 15,2 m, gångarna **1,9 m** | nej, en gång på 1,9 m går inte att leda hästar i |
| boxfacket 3,5 m (rytmen) | längden **~83 m**, bredden 23,3 m | nej, då vore stallet längre än ridhuset |
| bredden 21 m (spelet) | gångarna 2,6 m, boxdjup 3,7–4,4 m, längden 75 m | måtten inne är rimliga, längden inte |

Vad planen däremot gav är **bandens inbördes andelar**, som är skaloberoende och
lika i tre snitt — de används rakt av och är `VERIFIED`. Kvar blir:

- **`STALLINNE.bredd` = 21 m är `ASSUMPTION`** i mitten av intervallet **15–23 m**.
  Den ligger på ett enda ställe i koden; ändras den följer allt annat med.
- **Längden 54 m är `ASSUMPTION`.**
- Väg 1 (15 m är fysiskt omöjligt givet planformen) och väg 3 (takgeometrin)
  står kvar och är det som håller nedre gränsen uppe. Väg 2 är struken.

Se `references/plans/OAVGJORT.md` fråga 2. Det som stänger frågan är **ett
mått** — en skalstock, ett måttsatt rum, eller gångens bredd stegad på plats.

Västra långsidan — den fotograferade — står kvar vid x = 154; huset växer österut
till x = 175. Gången öster om stallet smalnar 7 → 3 m och hagarna flyttas 2 m ut.
Norra gavlarna ligger fortfarande i liv med ridhusets, som i satellitbilden, och
gräsgården mellan husen är 11 m.

Tolv exteriörkontroller på stallet, alla gröna.

---

## 6b · Byggnadskomplexet — husen sitter ihop

Issue #21 la in en connected-complex-regel som P0, men villkorade den i sin egen
text: *"Do not leave a free-standing gap … if the authoritative plan shows
connected building mass."* När utrymningsplanerna kom in i repot visade
situationsplanen **skilda volymer** — två separata former med vit yta emellan,
i båda planerna, med bara färgerna ombytta. Regelns villkor var alltså inte
uppfyllt, och jag stannade där i stället för att gissa: `OAVGJORT.md` fråga 1.

**Tobias avgjorde 2026-08-30:** *"husen är sammanbyggda, jag har varit där"* och
*"det är hästgång mellan byggnaderna"*.

Det är en verklig `CONTRADICTION` mellan två källor, avgjord enligt
konflikthierarkin i `CLAUDE.md`: Tobias uttryckliga produktbeslut (punkt 1) slår
verifierad referens (punkt 3). Situationsplanen skrivs **inte** om till att
"egentligen" visa en förbindelse — den gör den inte, och båda beskeden står kvar
i `OAVGJORT.md`. En låg förbindelse behöver inte ritas som egen volym i en
schematisk situationsplan om den inte är en egen brandcell.

### Vad som byggdes

Hästgången är inte en dekorativ länga utan en **väg för hästen**: man leder den
inomhus mellan stallet och ridhuset i stället för att gå ut över gården. Den är
byggd med samma mekanism som alla andra dörrar i spelet — scenövergång åt båda
hållen — så att gången faktiskt går att använda, inte bara ses.

| Gränssnitt | Var | Fidelity |
|---|---|---|
| Byggnadsvolym `hastgang` | (143, 106), 11 × 6 m, takfot 3,2 m, nock 4,2 m, nock öst–väst | Formen `ASSUMPTION`; att den finns `VERIFIED` (Product Owner på plats) |
| Ridhusets östfasad | öppning `u = 65`, 2,4 × 2,6 m, `intern:true` | `ASSUMPTION` |
| Stallets västfasad | öppning `sV(10.0)`, 2,4 × 2,6 m, `intern:true` | `ASSUMPTION` |
| `RIDHUSINNE.dorrar.hastgang` | (24,0 · 65,0) i entréhallen → stallet | `ASSUMPTION` |
| `STALLINNE.dorrar.hastgang` | (0,9 · 44,0) i klubbdelen → ridhuset, `inne:true` | `ASSUMPTION` |

`intern` gör att fasadöppningen inte får någon dörrmarkör ute på gården, och
`inne` gör detsamma för STALLINNE-dörren i generatorn som annars speglar varje
stalldörr till anläggningen. Utan dem hade förbindelsen fått spökmarkörer i
väggen och ute på gräset.

### Läget är härlett, inte hämtat

`[ASSUMPTION]` Hästgången ligger i norra änden därför att det är **enda stället
där båda husen har gångbar insida mot varandra**: ridhusets läktare upptar hela
östväggen mellan y 53 och 103, och stallets boxlängor upptar y 71–108. Kvar
blir y 108–115 — stallets klubbdel mot ridhusets entréhall. Det är ett
uteslutningsargument ur den befintliga modellen, inte en källa.

`[REFERENCE GAP]` **Frågan till Tobias:** var går hästgången i verkligheten —
norra änden (som spelet gissar), mitten eller söder? Och kommer man ut i
ridhusets hall eller direkt i ridbanan? Ett foto inifrån gången, eller bara
"norra/södra änden", byter ut antagandet mot verklighet.

### Följdändringar

Att stänga gårdens norra ände fick konsekvenser som testerna fångade:

- **Förbindelselängan i söder** smalnades från 10 till 7 m (x 144 → 147). Med
  hästgången i norr och den breda längan i söder blev gräsgården helt innesluten
  och stalldörren mot gräsgården fick ingen väg ut till gårdsplanen.
- **Ridhusets durkplåtsdörrar** flyttades ur läktarstommen, se fynd 9.
- **`ridhus_o`-markören** flyttades med, från (143,9 · 66) till (143,9 · 49).

---

## 7 · Stall interiör

`STALLINNE` är omskriven från "gång i mitten, rad på var sida" till fyra längor med
var sin gång att vetta mot, plus en tvärkorridor mitt på som når båda långsidorna
— planen har utrymningsvägar där.

Kollisionen frågar nu en lista över gångytor i stället för att klämma spelaren in i
ett intervall; det gick inte att uttrycka med två gångar. Samma lista styr var
dörrar får sättas, så vägsökningen och gåendet läser fortfarande samma geometri —
två beskrivningar av samma hus blir förr eller senare oense.

Spelets sjutton hästar står i gång A, den man kommer in i från förstukvisten. Gång
B:s boxar ritas men får ingen häst: spelet har sjutton namn, och fler får inte
hittas på.

---

## 8 · Ridhus interiör

De fem motsägelserna i § 4. Bara det indexet uttryckligen beskriver är byggt.
Indexet säger själv "bygg inte osedda detaljer från denna text", så antal, mått och
placeringar som det inte anger är `ASSUMPTION` i byggnadskortet.

---

## 9 · Roblox / webb-paritet

**Omskriven efter Review 01.** Blocker D hade rätt: *"ingen Roblox-geometri är
inte parity"*. Att det inte fanns någon motsägande Roblox-implementation gjorde
inte spåren likvärdiga — det gjorde bara att bara den ena ytan hade UBRF.

### Vad som finns nu

| Fil | Vad | Underhåll |
|---|---|---|
| `tools/exportera-geometri.js` | kör `src/site.js` och skriver ut geometrin som Luau | — |
| `roblox/buildings/UBRFKomplex.luau` | anläggningens mått, färger och öppningar | **genererad, aldrig för hand** |
| `roblox/buildings/Geometri.luau` | ren geometri: öppningens läge i en fasad, taklutning, om två hus sitter ihop | handskriven, mätt |
| `roblox/buildings/Anlaggningen.luau` | bygger hela komplexet i Studio ur de två ovan | handskriven |
| `roblox/tests/geometri.spec.luau` | 36 mätningar på den exporterade geometrin | handskriven |

Review 01 skrev: *"Do not create a second hand-maintained truth. Prefer one
canonical geometry/data definition or a deterministic generation path consumed
by both surfaces."* Det är den vägen som är byggd. `src/site.js` är den enda
sanningen; Roblox-modulen är dess utdata, inte dess kopia.

Exporten är **deterministisk** — ingen tidsstämpel, inget versionsnummer, allt
avrundat till sex decimaler — så att den går att kontrollera:

```
node tools/exportera-geometri.js --kontrollera
```

Den faller om `src/site.js` ändrats utan att exporten körts om. Verifierat åt
båda hållen: ett provisoriskt ändrat mått i `src/site.js` gav exit 1, och samma
mått tillbaka gav exit 0 igen.

### Vad specen mäter

36 kontroller, alla gröna, körda på den genererade filen — alltså på de tal
Roblox faktiskt skulle bygga av:

- **Komplexet.** Hästgången möter ridhusets östvägg (x = 143) och stallets
  västvägg (x = 154); ridhus och stall möts inte direkt, utan just via
  hästgången; hästgången ligger inom båda husens längd; de norra gavlarna
  ligger i liv. Flyttar någon ett hus i `src/site.js` utan att flytta
  hästgången faller de här på båda plattformarna samtidigt.
- **Interna öppningar.** En halvmeter utanför varje `intern`-öppning ska ligga
  inuti ett annat hus. Båda två gör det — de är dörrar in i grannen, inte
  dörrar ut i luften.
- **Fasadkonventionen.** `u` mäts från fasadens p0, och p0 → p1 går medurs sett
  utifrån, alltså mot *minskande* koordinat på N och W. Fyra kontroller på en
  provrektangel låser det. Får man det bakvänt hamnar varje dörr i fel ände av
  sitt hus, och en rundvandring märker det inte, för husen är symmetriska nog
  att se rimliga ut ändå.
- **Taken.** Lutningen anges inte utan räknas ur takfot och nock, så att en
  ändrad nockhöjd inte kan lämna ett tak med gammal lutning efter sig. Alla
  åtta husen får en byggbar lutning, och **stallet ger 28,1°** — samma tal som
  byggnadskortet och § 6 räknar med, nu uträknat oberoende ur måtten.
- **Dörrmarkörerna.** Ingen av de tolv står inuti ett hus.

### En bugg som bygget blottade

`BuildKit.gableRoof` läste `model:GetAttribute("GavelFärg")` och `_exempel.luau`
satte samma namn. Roblox tillåter bara `[A-Za-z0-9_]` i attributnamn, så det
hade kastat fel vid körning — exakt den fälla `roblox/buildings/README.md` redan
varnar för, en gång tidigare med `Källa`. Ingen hade byggt ett tak förrän
`Anlaggningen.luau` skulle anropa funktionen. Attributet heter nu `GavelFarg`.

### Vad som fortfarande inte är visat

`[REFERENCE GAP i paritetsredovisningen]` **Ingen har kört skriptet i Studio.**
Alla fyra Luau-filerna kompilerar (`luau-compile --binary`), geometrin är mätt
utanför Studio, men att modellen faktiskt reser sig och ser rätt ut kan bara
avgöras i Studio, av en människa. Två skärmdumpar från samma vinkel — webben och
Roblox — är den bevisning som fattas, och den kräver Studio.

Enligt Review 01: *"If full Roblox rendering is deliberately deferred, Gate F01
must not be reported as parity-ready."* Det gäller. **Gate F01 är inte
parity-ready.** Den strukturella pariteten är byggd och mätt; den visuella är
det inte.

---

## 10 · Visuella jämförelser

**Omärkning efter Review 01.** Review 01 påpekade att ridhusets rader nedan inte
är jämförelser mot bilder: `IMG_0179`, `IMG_0183` och `IMG_0198` finns bara i
Drive och jag har aldrig sett dem. Raderna är **implementation jämförd med ett
verifierat textderivat** av bilder, inte visuell verifiering. De är omärkta
därutefter i kolumnen "Referensens art". Stallets rader är riktiga
bildjämförelser — fotona ligger i repot.

Kolumnen "Vad som stämmer" beskriver alltså för ridhusraderna vad som är byggt
enligt beskrivningen, inte vad jag har sett stämma.

| Vy | Mot vilken referens | Referensens art | Vad som stämmer |
|---|---|---|---|
| Stallet från grusplanen, snett framifrån | `stall-fasad-04.jpg` | **Bild i repot** — visuell jämförelse | Gaveln med spiraltrappa och balkong, förstukvisten med vitt ribbräcke och ockragul dörr, valvfönsterrytmen, huvraden som börjar efter förstukvisten, snörasskyddet, blågrått tak. Gaveln läser nu bredare och flackare, närmare fotot än den smala 15 m-gaveln |
| Gång A inifrån | `stall-gang-*.jpg` | **Bild i repot** — visuell jämförelse | Boxar på båda sidor, hästhuvuden över dörrarna, namnskyltar, galvade stolpar, spånremsa längs fronterna, marksten i mitten, tegelröda tvärbalkar, takfönster, pendelarmaturer |
| Tvärkorridoren, från västra långsidan | — | Härledd ur planen — ingen bild | Man ser genom huset mellan boxlängorna; fyra rader läsbara |
| Vid E, mot båset | `IMG_0198` via indexet | `[DRIVE-ONLY]` — **textderivat**, ej sedd bild | Bokstaven E på sargen, mörkt träbås direkt bakom, grön exit-skylt över öppningen, låg upphöjd träläktarnivå, trappa med räcken |
| Från banan mot läktaren | `IMG_0179` via indexet | `[DRIVE-ONLY]` — **textderivat**, ej sedd bild | Läktarens nivåer och räcke, båset med skylten, mörkröd övre vägg, stålprofiler och ventilationskanaler i taket |
| Mot sponsorväggen | `IMG_0183` via indexet | `[DRIVE-ONLY]` — **textderivat**, ej sedd bild | Mörkröd övre yta med vita läkt, sponsorplåtar, speglarna, takets installationer |
| Gräsgården norrut, mot hästgången | — | Ingen referens; kontroll av **läsbarhet**, inte likhet | Gården stängs i norr av en låg röd volym med blågrått sadeltak som möter ridhusets vägg till vänster och stallets till höger |
| Grusplanen mot nordgavlarna (ankomstvyn) | — | Ingen referens; kontroll av **läsbarhet**, inte likhet | Husen läser som ett sammanhängande komplex, inte som två fristående lador med genomsikt mellan gavlarna |

---

## 11 · Regressionstester

| Svit | Kontroller | Resultat |
|---|---|---|
| Entréer och dörrar (inkl. hästgångens sex) | 17 | alla gröna |
| Stallets planform | 10 | alla gröna |
| Ridhusets interiör och bokstäver | 10 | alla gröna |
| Exteriörerna (ridhus 6, stall 12) | 18 | alla gröna |
| Ridloopen (Gate 01) | 5 | alla gröna |
| Ryttarens sekundärrörelse | 7 | alla gröna |
| Fyra viewports, rörelse och touchmål | 4 | alla gröna |
| **Roblox: anläggningens geometri** | **36** | **alla gröna** |
| Roblox: rörelse, kamera, ryttare, touch | 72 | alla gröna |

Hästgångens sex egna kontroller: dörren finns i båda husen; stalländens
landningspunkt hamnar i en gångyta och inte i en boxrad; ridhusändens
landningspunkt hamnar i entréhallen och inte i läktarstommen; volymen möter
ridhusets östvägg; volymen möter stallets västvägg; och den ligger i liv med
båda husens längdriktning.

Inga konsolfel i någon svit. Framkomlighet mätt: tvärs stallet 1,0 → 20,2 m av 21
genom tvärkorridoren, och längs gång A till y = 42,6, alltså hela boxlängan.

Inga nya gameplay-features. Ridkänslan är orörd.

---

## 12 · Kvarvarande ASSUMPTION

1. **Stallets totalbredd 21 m**, i intervallet 15–23 m — se § 6. Nedgraderad från
   slutsats till antagande efter Review 01. Ligger på ett enda ställe i koden
   (`STALLINNE.bredd`). **Stallets längd 54 m** är antagen på samma sätt.
   Bandens inbördes andelar är däremot mätta i planen och `VERIFIED`.
2. **Nio boxar per länga**, 36 totalt.
2b. **Hästgångens läge, mått och anslutningspunkter** — se § 6b. Att husen sitter
   ihop är avgjort; var gången går är härlett ur var husen har gångbar insida.
3. **Vilken av de två gångarna filmerna visar.**
4. **Stallets taklutning 28°** och därmed nockhöjden.
5. **Södra gaveln och östra långsidan** på stallet.
6. **Ridhusets takfot 6,2 m och lutning 13°.**
7. **Antal och mått** på ridhusets glasade rum, takinstallationer, klocka och bås.
8. **Entréhallens möbler** i ridhuset.
9. **Åtta av tolv bildgåtor** vid dressyrbokstäverna.

## 13 · Kvarvarande REFERENCE GAP

1. **Ett mått på stallet.** En skalstock i ritningen, ett måttsatt rum, eller ett
   uppmätt avstånd på plats — gångens bredd mellan två boxfronter räcker. Planen
   finns nu i repot men saknar skala, så den kan inte stänga frågan ensam.
1b. **Var hästgången går** — norra änden, mitten eller söder, och vad man kommer
   ut i på ridhussidan. Ett foto inifrån gången, eller ett kort besked.
2. **Samma på "Plan 2"** för övervåningen.
3. **En sparad satellitbeskärning** med byggnadernas längd OCH bredd i bildpunkter.
   Kortets invändning att 20–26 m är "oförenligt med hur smal byggnaden ser ut i
   satellitbilden" är inte kvantifierad, och bilden finns inte i repot.
4. **Ridhusets interiörbilder i repot.** `IMG_0179`, `IMG_0183`, `IMG_0198` och
   `IMG_0191.MOV` finns bara i Drive. Fem av sex motsägelser är byggda från en
   textbeskrivning av bilder jag inte har sett.
5. **Stallets takyta uppifrån** och en rak bild på långsidan.
6. **Ridhusets långsidor på nära håll, östra gaveln och takytan.**
7. **Ridhusets gavel rakt framifrån** — lutningsspannet 11–17° är för brett.

---

## 14 · Kända begränsningar

1. **Jag har inte sett Drive-bilderna.** Ridhusets interiör är byggd ur ChatGPTs
   verifierade index. Det är ett led längre från verkligheten än stallet, och en
   review bör granska just de raderna hårdast.
2. **Utrymningsplanerna ligger nu i repot** (`references/plans/`, `0d91f8e`) och
   är mätta där. Men de saknar skalstock, så de fastställer proportioner, inte
   meter — stallets absoluta mått vilar fortfarande på antaganden, se § 6.
3. **Roblox-pariteten är strukturell, inte visuell.** Geometrin är genererad ur
   webbkoden och mätt med 36 kontroller, men ingen har kört bygget i Studio.
   Gate F01 är därför inte parity-ready — se § 9.
4. **Interiörernas möblering är inte komplett.** Sakerna på boxfronterna och porten
   med klockan i stallgångens fond är kända men obyggda.
5. **Ingen mänsklig igenkänningskontroll.** Att någon som varit på UBRF känner igen
   sig kan bara Tobias avgöra. Hästgången är det första exemplet på att det
   fungerar: den fanns i verkligheten men i ingen av mina källor, och kom in i
   modellen först när Tobias sa att den finns.
6. **Hästgången är byggd på ett besked, inte på en bild.** Att den finns är
   avgjort. Var den går, hur bred den är och vad man kommer ut i är gissat ur
   vad som är möjligt i modellen. Det är den enskilt svagast underbyggda
   byggnaden i spelet just nu, och den bör granskas som sådan.

---

## 15 · Överlämning

Enligt `docs/GATE-F01-UBRF-FIDELITY.md` stänger jag inte gaten och kallar inte
UBRF identiskt. Arbetet lämnas till ChatGPT för Senior Fidelity Review av faktisk
diff och källkedja, och till Tobias för avgörandet om igenkänningen räcker och om
nya foton behövs för att stänga luckorna ovan.

De tre P0-punkterna i gatens acceptance — ridhusets fem interiörmotsägelser,
stallets felaktiga en-gångsplan och connected-complex-regeln — är åtgärdade.
Den tredje var villkorad och kunde inte avgöras ur källorna; den avgjordes av
Tobias och är byggd som hästgången, § 6b.

Review 01:s fyra blockerare är hanterade:

| # | Blocker | Vad som gjordes |
|---|---|---|
| A | Connected-complex saknas | Hästgången byggd, § 6b. Avgjord av Tobias, inte av mig |
| B | Planen används inte direkt | Planerna ligger i repot och är mätta, § 14.2 |
| C | 21 m är överlåst | Nedgraderad till `ASSUMPTION` 15–23 m, beviskedjan rättad, § 6 |
| D | Ingen Roblox-geometri är inte paritet | Deterministisk export ur `src/site.js`, 36 mätningar, § 9 |

Plus evidensomärkningen: ridhusets "visuella jämförelser" är omklassade till
*implementation jämförd med verifierat textderivat*, § 10.

**Gaten kallas inte parity-ready.** Blocker D:s egen villkorsmening gäller: den
visuella pariteten är uppskjuten till någon har kört bygget i Studio. Punkt 3–8 (exteriörernas
regressionstest, den gemensamma matrisen, paritetsredovisningen, byggets
funktion och att inga nya features smugit in) är redovisade ovan.
