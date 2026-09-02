# F02-A — Interior Fidelity Matrix

Arbetsorder: issue #71. Parent: issue #65. Baseline: `main` efter Product Owners
visuella exteriöracceptans. **Exteriören är låst** och rörs inte i denna slice.

Det här dokumentet är steg 1: **inventeringen före ombyggnaden.** Det bygger
ingenting. Det säger vad källorna visar, vad spelet bygger i dag, och var de
skiljer sig — med klass på varje påstående.

---

## Hur talen är framtagna

Tvärgående vägglinjer i stallets Plan 1 är mätta med `tools/f02-planmatning.py`
mot `references/plans/stall-plan1-utrymning-rak.jpg`. Skriptet räknar, rad för
rad, hur stor andel av husets bredd som är mörk; en genomgående vägg ger en topp
eftersom den är mörk tvärs nästan hela huset, medan en boxvägg bara är mörk i
sitt eget band.

Körningen går att göra om: `python3 tools/f02-planmatning.py`.

**Talen är ANDELAR av byggnadens längd, inte meter.** Det är avsiktligt.
Planen saknar skalstock, och stallets bredd är olöst i intervallet 15–23 m
(`references/plans/OAVGJORT.md` fråga 2). Skrivs meter ut här blir arbetsvärdet
21 m kanon bakvägen genom rumsgeometri — vilket senior review underkände
uttryckligen i den förra interiörrundan.

Där en andel räknas om till meter i tabellerna nedan sker det mot den
`VERIFIED` längden 69,95 m och märks `ASSUMED_SCALE` i tvärled.

### Skalklasser som används

| Klass | Betyder |
|---|---|
| `PLAN` | planens proportioner, mätta |
| `ASSUMED_SCALE` | omräknat till meter via ett tal som självt är ett antagande |
| `VERIFIED` | mätt mot verklig källa med känd skala |
| `FOTO` | läsbart i repo-foto/video |
| `DERIVED` | följer av annat verifierat |
| `ASSUMPTION` | valt, inte mätt |
| `REFERENCE GAP` | underlag saknas |
| `CONTRADICTION` | två källor säger olika |

---

## Stallhuset — Plan 1

### Mätta genomgående linjer

Utdrag ur körningen, de linjer som är starkast och som avgränsar zoner.
`andel` räknas från **norra gaveln**.

| andel | max mörk | tolkning | klass |
|---|---|---|---|
| 0,0898–0,0929 | 0,56 | vägg i klubbdelen | `PLAN` |
| 0,1844–0,1865 | 0,61 | **genomgående vägg i klubbdelen** | `PLAN` |
| 0,2396 | 0,60 | **klubbdelens södra gräns mot boxhallen** | `PLAN` |
| 0,2783 … 0,8284 | 0,54–0,71 | boxavdelare, jämnt fördelade | `PLAN` |
| 0,8567–0,8622 | 0,76–0,79 | **boxhallens södra gräns** | `PLAN` |
| 0,9686 | 0,71 | vägg nära södra gaveln | `PLAN` |

Boxavdelarnas delning: 15 linjer mellan 0,2396 och 0,8284 ger **0,0421 per fack**.

### Zonjämförelse — plan mot implementation

| Zon | Planen | Spelet i dag | Avvikelse | Klass |
|---|---|---|---|---|
| Klubbdel, norra änden | andel 0 → 0,2396 | `klubbY` 52,85 → 69,95, dvs andel 0 → 0,2445 | 0,5 % — **stämmer** | `PLAN` |
| Genomgående vägg inne i klubbdelen | andel 0,1855 | finns inte | **saknas helt** | `PLAN` |
| Boxhallens södra gräns | andel 0,860 | `boxStartY` 6,8, dvs andel 0,903 | **≈ 3 m** | `CONTRADICTION` |
| Boxfackens delning | 0,0421 av längden ≈ 2,94 m `ASSUMED_SCALE` | `boxB` 3,5 m | **0,56 m per fack** | `CONTRADICTION` |
| Sex band tvärs huset | boxrad–gång–boxrad–boxrad–gång–boxrad | samma sex band, samma ordning | stämmer | `PLAN` |

### Rum och zoner

| Zon | Planstöd | Spelet i dag | Klass | Not |
|---|---|---|---|---|
| Klubbdelens NV-rum, med brandlarmscentral `BC` på väggen | ja, tydlig rektangel | — | `PLAN` | grön utrymningspil norrut genom gaveln, alltså klubbentrén |
| **Intern rak trappa till Plan 2** | ja, trappsymbol med tydliga steg i eget trapphus | **finns inte** | `PLAN` | utrymningspilar leder till den både norr- och söderifrån |
| Litet rum, grått i planen | ja | — | `REFERENCE GAP` | grått = utanför utrymningsytan; funktion oläsbar |
| Klubbdelens östra rum, med utgång **österut** | ja, grön pil genom östfasaden | — | `PLAN` | spelet har ingen östlig utgång i klubbdelen |
| Tvärkorridor mellan klubbdel och boxhall, utgång åt **både** väster och öster | ja, gröna band på båda sidor | delvis | `PLAN` | |
| `UPPEHÅLLSRUM` | ingen etikett i planen | rekt 7,0 × 3,5 | `ASSUMPTION` | funktionen är antagen, inte läst |
| `TEORISAL · WC` | ingen etikett i planen | rekt 7,0 × 3,5 | `ASSUMPTION` | dito |
| `SADELKAMMARE` | ingen etikett i planen | rekt 3,2 × 3,9 | `ASSUMPTION` | dito |
| Boxhallens sex band | ja | ja | `PLAN` | andelarna i `KORT.md`, ommätta 2026-08-30 |
| Tvärgång mitt i boxhallen, utgång **västerut** | ja | `tvarGang` 27,8–31,3 | `PLAN` | läget i längdled behöver kontrollmätas mot linjelistan |
| Södra änden, ~5 rum | ja, tydliga partier | två **öppna** bukter | `CONTRADICTION` | se nedan |
| Södra gavelns skjutdörr | ja, dörrsymbol med dubbelpil | `gaveloppning` | `FOTO` + `PLAN` | |
| Utgång österut i södra änden | ja, grönt band | — | `PLAN` | saknas i spelet |
| Fristående volym söder om gaveln, med cirkel | ja, utanför den gula ytan | — | `REFERENCE GAP` | sannolikt tank/behållare; ingen bild visar den |

### `CONTRADICTION`: södra änden — rum eller öppen bukt?

`stall-plan1-utrymning-rak.jpg` ritar södra änden som **flera slutna rum**.
`stall-inne-07` och `-09` visar ett **öppet genomgångsrum** med fristående
spolbommar och spånsäckar i en öppen bukt.

Den nuvarande implementationen valde fotot, efter att Product Owner underkände
den tidigare slutna versionen i spelarvyn. Det beslutet står — men motsägelsen
är **inte** löst, bara prioriterad, och den ska inte läsas som att planen är fel.

Rimlig läsning som ingen källa ännu avgör: planen ritar brandcellsgränser och
funktionsytor, inte nödvändigtvis väggar i full höjd. `[REFERENCE GAP]` En bild
rakt genom södra änden från gaveln, eller ett besök, avgör.

**Ingen ombyggnad av södra änden i F02-A** förrän den frågan är avgjord.

### `CONTRADICTION`: boxfackens delning

Planen ger 0,0421 av längden per fack. Mot 69,95 m blir det 2,94 m
`ASSUMED_SCALE`. Spelet bygger 3,5 m.

Det här är **inte** avgjort av den här mätningen ensam:

- 3,5 m kommer ur huvarnas och fönstrens rytm på fasaden, mätt i `stall-fasad-04`,
- 2,94 m kommer ur planens fackdelning, mätt här,
- båda är mätningar i längdled, och de säger olika.

`[REFERENCE GAP]` Ett uppmätt boxfack på plats, eller en bild rakt längs gången
med känd referens. Tills dess ändras `boxB` **inte** — att byta 3,5 mot 2,94 vore
att byta en mätning mot en annan utan att veta vilken som är fel.

---

## Stallhuset — Plan 2

Utrymningsplanen visar en **övre våning** med egna rum, en trappa och
spiraltrappans symbol.

| Faktum | Klass | Spelet |
|---|---|---|
| Plan 2 finns och är utrymningsritad | `PLAN` | **finns inte alls** |
| Trappa upp från klubbdelen | `PLAN` | finns inte |
| Spiraltrappan leder till Plan 2 | `PLAN` + `FOTO` | exteriört byggd, leder ingenstans invändigt |
| Rumsindelning på Plan 2 | delvis läsbar, bilden är beskuren | `REFERENCE GAP` |

Plan 2 är **utanför F02-A:s leverans** — men det står här därför att den
förklarar två saker i Plan 1 som annars ser omotiverade ut: trapphuset och
balkongdörren.

---

## Ridhuset

| Zon | Planstöd | Spelet | Klass |
|---|---|---|---|
| Entréplanets rum | `ridhus-entreplan-utrymning.jpg` | delvis | se nedan |
| Banan, sarg, sargport | foto + plan | ja | `FOTO` |
| Läktare, kortända | foto | ja | `FOTO` |
| Café/överbyggnad i norr | foto | ja | `FOTO` |
| Domarbås | foto | ja | `FOTO` |

**Rektifieringen av ridhusets entréplan är fortfarande olöst.** Föregående runda
mätte försöket och underkände det: kantresidual **8,11 %** respektive **4,89 %**
mot kravet 3 %, eftersom kontrollpunkterna inte omsluter husets fyra hörn —
caféannexet skjuter ut och entrézonens rum bryter den gula ytan i segment.

`[REFERENCE GAP]` Ett rakt omfotograferat entréplan, av samma slag som stallets
`-rak`, eller ett mått på plats. Sex rum i mittblocket kan inte placeras förrän
dess.

Fyndet är återanvänt som **bevis**, inte som färdig sanning: PR #33 och #50 är
stängda som reference only och är inte mergekälla.

---

## Vad F02-A bygger, och vad den inte bygger

**Byggt** — där planen är entydig och spelet saknade något. Alla fyra är
implementerade i den här slicen:

| Byggt | Läge | Klass |
|---|---|---|
| 1. Klubbdelens genomgående vägg | andel 0,1855 → y 56,97, öppen 0 → 8,97 m i väster | `PLAN` / tvärled `ASSUMED_SCALE` |
| 2. Klubbdelens trapphus och trappa | x 5,82–7,67, y 58,45–64,25, 18 steg | `PLAN` / tvärled `ASSUMED_SCALE` |

Båda ligger **helt innanför ytterväggarna** och rör inte fasaden.

### `DEFERRED BY EXTERIOR LOCK` — faktum fastställt, implementation väntar

Följande öppningar är **lästa ur planen och står som fakta**, men får inte
byggas i F02-A: var och en skulle skära ett nytt hål i en ytterfasad, och
exteriören är låst av issue #71 sedan Product Owners visuella acceptans.

| Öppning | Läge ur planen | Klass | Implementation |
|---|---|---|---|
| Klubbdelens utgång österut | andel 0,1492 → y 59,5 | `PLAN` | `DEFERRED BY EXTERIOR LOCK` |
| Tvärkorridorens utgång västerut | andel 0,2521 → y 52,31 | `PLAN` | `DEFERRED BY EXTERIOR LOCK` |
| Tvärkorridorens utgång österut | andel 0,2521 → y 52,31 | `PLAN` | `DEFERRED BY EXTERIOR LOCK` |
| Södra ändens utgång österut | andel 0,8453 → y 10,82, bredd 1,7 m | `PLAN` | `DEFERRED BY EXTERIOR LOCK` **och** ligger i den `CONTRADICTION`-märkta södra änden |

De byggdes en runda och är **återtagna**. Skälet är värt att skriva ut, för
det är inte att bevisen var svaga: senior review bad om dem som fortsättning,
och den instruktionen stod i konflikt med exteriörlåset i #71. Låset vinner.
Ett godkännande av byggnadens utsida är ett godkännande av utsidan, inte av
en kameravinkel — mitt eget resonemang om att långsidorna låg "utanför den
accepterade vyn" höll inte.

**Låser upp:** ett uttryckligt Product Owner-beslut. Då byggs de fyra ur de
tal som redan står här.

### Ett fynd vid kontrollmätningen

**Tvärgången mitt i boxhallen är INTE en saknad utgång.** Matrisen listade
tidigare "utgång västerut" som obyggd. Planens gröna band där ligger på andel
0,5559 → y 31,06, och **hästgångens port** står redan på y 29,55 med bredden
2,4 m. De överlappar. Utrymningsvägen västerut mitt i huset **är** hästgången
till ridhuset, och den är byggd sedan tidigare. Att lägga en dörr till hade
gett två öppningar för en passage — samma fel som en gång la två markörer på
förstukvistens dörr. Posten är avförd, inte glömd, och den skulle ha varit
felaktig oavsett låset.

### `CONTRADICTION` i den låsta fasaden — redovisad, inte rättad

Vid samma kontroll syntes att den **genererade** fönsterrytmen på östra
långsidan ligger inuti den stora skjutporten:

| Öppning | u-span |
|---|---|
| skjutport `portbla` | 34,35 – 37,95 |
| genererat valvfönster | 33,30 – 34,45 |
| genererat valvfönster | 36,80 – 37,95 |

Ett tredje fönster ligger på samma sätt inuti hästgångens port på västra
långsidan.

Rytmen är mekanisk: den räknar fram fönster ur boxdelningen utan att veta att
det står en port där. Det är ett verkligt fel — men det ligger i den **låsta
fasaden**, det fanns före F02-A, och det rättas inte här.

Ett filter som lät rytmen vika för de handskrivna öppningarna byggdes och är
**återtaget** tillsammans med resten av fasadarbetet. Det tog bort tre
befintliga fönster, vilket är en ändring av den accepterade utsidan oavsett
att geometrin under är trasig. Rättningen, när den får göras, är just det
filtret.



**Bygger inte** — och varför:

| Inte | Skäl |
|---|---|
| södra änden | `CONTRADICTION` plan mot foto, prioriterad av Product Owner till fotots fördel. En utgång österut byggdes här en runda och är återtagen: den låg både i den låsta fasaden och i den uppskjutna zonen |
| fasadöppningar ur planen | `DEFERRED BY EXTERIOR LOCK` — se tabellen ovan |
| fönsterrytmens krock med portarna | ligger i den låsta fasaden, fanns före F02-A |
| `boxB` 3,5 → 2,94 | två mätningar säger olika, ingen avgör |
| ridhusets sex mittrum | rektifieringen underkänd och mätt |
| Plan 2 | utanför slice |
| möblering | F02-B |
| exteriör | låst |
| rumsfunktioner/etiketter | ingen etikett läsbar i något foto; nuvarande namn är `ASSUMPTION` och ärvs oförändrade |

---

## Kvarstående `REFERENCE GAP` — samlat

1. **Stallets bredd**, 15–23 m. Ett uppmätt avstånd på plats stänger den.
2. **Boxfackets längd**, 2,94 mot 3,5 m.
3. **Ridhusets entréplan i djupled** — rektifiering underkänd.
4. **Rumsfunktioner** i båda husen — ingen etikett läsbar.
5. **Plan 2:s rumsindelning** — bilden beskuren.
6. **Volymen söder om stallets gavel** — ingen bild.

Inget av dessa fylls med en rimlig gissning.
