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

**Skalan ommätt 2026-09-03.** Tabellen ovan räknar `andel` mot bildens
omslutande ruta (rad 252–1700). Husets verkliga ytterväggar ligger på rad
**273** (norra) och **1657** (södra), alltså 1384 bildpunkter för 69,95 m —
0,0505 m per bildpunkt, mot 0,0483 i den första körningen. Skillnaden är
4,6 % i skala och en meter i nollpunkt; den genomgående väggen ligger
därför på **12,5 m från norra gaveln (y 57,45)**, inte 12,98 (y 56,97).
Klubbdelens alla mått nedan är tagna med den rättade skalan.

| Zon | Planen | Spelet nu | Avvikelse | Klass |
|---|---|---|---|---|
| Klubbdel, norra änden | N 0 → 16,4 (boxhallens gräns, rad 598) | `klubbY` 52,85 → 69,95, dvs N 0 → 17,1 | 0,65 m — `klubbY` rörs inte, boxarna räknas från den | `PLAN` |
| Genomgående vägg inne i klubbdelen | N 12,5, tvärs hela huset, två dörrar | `klubb.vaggar.genomgaende` y 57,45 med dörrar x 4,1–5,0 och 7,7–8,8 | **stämmer** | `PLAN` / tvärled `ASSUMED_SCALE` |
| Boxhallens södra gräns | andel 0,860 | `boxStartY` 6,8, dvs andel 0,903 | **≈ 3 m** | `CONTRADICTION` |
| Boxfackens delning | 0,0421 av längden ≈ 2,94 m `ASSUMED_SCALE` | `boxB` 3,5 m | **0,56 m per fack** | `CONTRADICTION` |
| Sex band tvärs huset | boxrad–gång–boxrad–boxrad–gång–boxrad | samma sex band, samma ordning | stämmer | `PLAN` |
| Boxar per rad | ~13 (`references/plans/README.md`) | 13, västra raden 12 | stämmer | `PLAN` |
| Tvärgång tvärs huset mitt i boxhallen | **finns inte** — mittraderna och östra raden är obrutna förbi hästgångens höjd (skiljare 38,3 och 41,3 m från norr) | `tvarGang` 27,8–31,3 **borttagen** | rättat | `PLAN` |
| Hästförbindelsens brott i västra raden | väggpar 38,7 och 40,8 m från norr → y 29,15–31,25 | `brott` y 28,35–30,75, läst ur fasaddörren | 0,8 m, inom planbildens skalfel | `PLAN` + `[enligt Tobias]` |

### Rum och zoner — klubbdelen, rättad läsning 2026-09-03

Källordning för raderna nedan: **Tobias rättelse på plats** (rumsidentitet och
faktisk användning) · **planen** (geometri och orientering) · foton (utseende).
"Vänster" i Tobias beskrivning är gående riktning söderut från parkeringen,
alltså **öster**; det är den enda läsningen där teorisalen, sadelkammaren och
toaletterna alla får plats där planen ritar rum. Hästförbindelsen beskrev han
däremot i planbildens riktning ("vänster sida av boxsystemet" = bildens
vänstra = väster), och båda läsningarna stämmer med planen.

| Rum | Planen (N = m från norra gaveln, x från västra väggen) | Spelet nu (`klubb.rum`) | Klass | Källa → faktum |
|---|---|---|---|---|
| Gaveldörr och vindfång | dörr x 3,6–5,5, två stumpar N 0–2,0 | `vindfang` 3,6–5,5 × y 67,95–69,95 | `PLAN` | planen; grön utrymningspil ut genom gaveln |
| **Uppehållsrum / väntrum** | x 0–5,9, N 0–9,8 | `uppehallsrum` | `PLAN` + `[enligt Tobias]` | "man kommer först in i uppehållsrummet" |
| Väggspår i uppehållsrummet | x 2,8–3,5, N 5,5–9,8, dubbel linje | `spar`, tjock 0,5 | `PLAN`, funktion `REFERENCE GAP` | |
| **Toalett väster om inre entrén** | x 0–4,0, N 9,8–12,5; dörr mot lobbyn N 10,45–11,5 | `wc_v` | `PLAN` + `[enligt Tobias]` | "två toaletter, en på var sida"; dörrläget `ASSUMPTION` bland två läsbara luckor |
| Lobby / inre entré | x 4,0–5,8, N 9,8–12,5; planens gröna pil ner genom | `lobby` | `PLAN` | |
| **Inre entrén till stallet** | dörr x 4,1–5,0 i den genomgående väggen | `oppningar.inre_entre` | `PLAN` + `[enligt Tobias]` | "rakt fram leder in i stallgång A" — gång A ligger x 4,4–7,0 |
| **Toalett öster om inre entrén** | x 5,8–7,3, N 11,3–12,5 | `wc_o`, `stangt` | `PLAN` + `[enligt Tobias]` | dörr oläsbar → sluten volym |
| Sluten volym utan namn (planens symbolruta) | x 5,9–7,3, N 4,9–11,3 | `sluten_volym`, `stangt`, `label:""` | geometri `PLAN`; funktion `REFERENCE GAP` | se § Symbolrutan; ingen etikett, inget funktionsnamn |
| Passagen öster om uppehållsrummet | x 5,9–11,2, N 0–5,6 | `passage` | `PLAN` | vägen "vänster" från uppehållsrummet |
| Litet rum med grå ruta | x 9,0–11,2, N 0–2,2 | `litet_rum`, `stangt` | `REFERENCE GAP` | grått = utanför utrymningsytan; funktion oläsbar |
| **Teorisal** | x 11,2–17,3, N 0–5,6; öppning i västväggen N 3,0–5,6 | `teorisal` | `PLAN` + `[enligt Tobias]` | "teorisalen till vänster om uppehållsrummet" |
| **Sadelkammare** | x 7,3–15,5, N 5,6–12,5; in från passagen x 7,3–8,8; egen dörr söderut x 7,7–8,8 | `sadelkammare` | `PLAN` + `[enligt Tobias]` | "vänster och sedan höger" = öster, sedan söder |
| Halvvägg i sadelkammaren | x 9,0–12,2 vid N 9,1 | `sadelkammare_mellan` | `PLAN`, funktion `REFERENCE GAP` | |
| Östra rummet | x 15,5–21 N 5,6–12,5 + x 17,3–21 N 0–5,6; utgång österut N 9,9 | `ostrum`, `ostrum_n`, utan namn | `PLAN`, funktion `REFERENCE GAP` | utgången: `DEFERRED BY EXTERIOR LOCK` |
| Pentry (fotoverifierat: valv- och rundfönster, mikro, kyl, bord) | ingen etikett | **inte placerat** | `REFERENCE GAP` | kandidater: det lilla rummet eller östra rummet; ingen källa avgör |
| Tvärkorridor mellan klubbdel och boxhall | N 12,5–16,4, utgångar åt båda långsidorna | gångyta y 52,85–57,45 | `PLAN` | utgångarna `DEFERRED BY EXTERIOR LOCK`; korta väggstumpar i zonen (x 4,5 · 10,9 · 14,2 · 16,5 · 19,1, N 13,6–15,8) är olästa och byggs inte |
| Boxhallens sex band | ja | ja | `PLAN` | andelarna i `KORT.md`, ommätta 2026-08-30 |
| Södra änden, ~5 rum | ja, tydliga partier | två **öppna** bukter | `CONTRADICTION` | se nedan |

**Superseded** — läsningar som stod i det här dokumentet eller i koden och
som nu är ersatta, inte omtolkade:

| Tidigare | Ersatt av | Varför |
|---|---|---|
| Genomgående väggen "öppen 0 → 8,97 m i väster" | tvärs hela huset, dörrar 4,1–5,0 och 7,7–8,8 | den mörka andelen 0,61 var den slutna volymens och dörrarnas linjer, inte ett hål |
| `tvarGang` 27,8–31,3 tvärs alla fyra rader, sex boxar på var sida | brott i västra raden enbart | mittraderna är obrutna i planen; Tobias: "bryter boxraden" |
| `rum`: tre solida lådor (uppehållsrum V, teorisal Ö, sadelkammare hörn) | planens rum som gångbara regioner med väggar | inget av de tre var läst ur planen; Product Owner underkände |
| `STALLINNE.trappa` (18 steg upp från klubbdelen) | `sluten_volym` — namnlös sluten volym | Tobias: trappan man går nås via ridhusets läktare |
| Rummet `trapphus` med etiketten `TRAPPHUS` (runda 928e090) | `sluten_volym`, `label:""`; väggarna `volym_*` | ChatGPT-review: "trapphus" var en ny funktionstolkning av samma symbol utan oberoende källa |
| Tolv boxar per rad | tretton, västra raden tolv | tolv var en följd av tvärgången |

**`CONTRADICTION` mot den låsta fasaden**, redovisade och inte rättade:

- planens gaveldörr sitter x 3,6–5,5; fasadens entré (`[PRODUKTBESLUT]`
  i `KORT.md`) sitter mitt på gaveln, x 10,5. Spelets `ut_n` pekar in i
  planens vindfång; fasadmarkören står kvar. Avståndet är 5,9 m.
- fasadens långsidesdörr 5,6 m från gaveln (`ut_n2`, `[enligt Tobias]`)
  finns inte i planen; den mynnar i uppehållsrummet och behålls.
- gavelns två runda fönster (x 8,2 och 11,4) hamnar i passagen och
  teorisalen; fotona ger uppehållsrummet både valv- och rundfönster.

**Nytt om bredden.** Den raka planbilden mäter huset **432 × 1384**
bildpunkter, förhållandet 3,20 : 1. Vid 69,95 m ger det **21,9 m** —
inne i intervallet 15–23 och en oberoende avläsning som pekar nära
arbetsvärdet 21. `DERIVED`; `STALL_BREDD` ändras inte på en enda bild.
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
| Trappa upp från klubbdelen | `CONTRADICTION` | byggs inte — se § Symbolrutan |
| Spiraltrappan leder till Plan 2 | `PLAN` + `FOTO` | exteriört byggd, leder ingenstans invändigt |
| Rumsindelning på Plan 2 | delvis läsbar, bilden är beskuren | `REFERENCE GAP` |

Plan 2 är **utanför F02-A:s leverans** — men det står här därför att den
förklarar två saker i Plan 1 som annars ser omotiverade ut: symbolrutan och
balkongdörren — utan att därför ge rutan en funktion.

---

## Ridhuset

| Zon | Planstöd | Spelet | Klass |
|---|---|---|---|
| Entréplanets rum | `ridhus-entreplan-utrymning.jpg` | planens väggar och rum, namn bara där Tobias ord ger dem | `PLAN` + `[enligt Tobias]` |
| Banan, sarg | foto + plan | ja | `FOTO` + `PLAN` |
| Sargport för folk till fots | ingen källa visar en grind; bredden vald | **inte fidelity** — spelets `SPELABSTRAKTIONER.ridhus.sargport`, märkt | `REFERENCE GAP` i fidelity; `SPELABSTRAKTION` i spelet |
| Läktare, kortända (C-blocket) | foto + plan | ja, **vänd** — se § Superseded | `FOTO` + `PLAN` |
| Café/överbyggnad i norr | foto + Tobias | ja, eget lager ovanpå entrédelen | `FOTO` + `[enligt Tobias]` |
| Domarbås | foto | ja | `FOTO` |

**Rektifieringen av ridhusets entréplan är fortfarande olöst**, och Tobias kan
inte fotografera om planen — den frågan är stängd. Föregående runda underkände
rektifieringsförsöket (kantresidual 8,11 % / 4,89 % mot kravet 3 %). Talen
nedan är därför tagna i ett rutnät lagt på den sneda bilden, skalat mot det
`VERIFIED` fotavtrycket 25 × 77,18 m: ±0,5 m i båda leder, `ASSUMED_SCALE`.
Fyndet från PR #33/#50 är bevis, inte sanning; de är stängda som reference only.

### Orientering — tre ankare, rättad läsning 2026-09-03

Planbildens **överkant är väster**. Tre oberoende ankare ger samma svar:
huvudentrén från parkeringen ligger i bildens övre högra hörn (västra
långsidan vid norra gaveln), stallet ligger nedanför (öster), och planens
gaveldörr 16,1–16,7 m från väster är fasadens svarta dörr `u:8.1` — den
enda dörren där plan och låst fasad säger samma sak. Därmed ligger
läktarremsan längs **västra** långsidan, C-blocket i **norr** mot banans
norra kant, och hästgången bryter ingen läktare. Koordinater: N = m från
norra gaveln, x från västra väggen; spelets y = 77,18 − N.

### Rum och passager — källa → faktum

Källordning enligt Product Owners order: **brandplanen** (geometri och
orientering) · **Tobias rättelser** (rumsidentitet) · foton/video (utseende) ·
befintlig implementation bara som jämförelse.

| Rum / passage | Planen | Spelet (`RIDHUSINNE.entrehall` m.fl.) | Klass | Källa → faktum |
|---|---|---|---|---|
| **Huvudentrén** (Bild 1) | cell x 0–2,2 × N 2,4–3,8 innanför västväggen; grön pil ut genom väggen | `entre`, etikett ENTRÉ; fasaddörren `ut_ridhus_W_9` | `PLAN` + `[enligt Tobias]` | "Main entrance = Bild 1"; dörrläget `CONTRADICTION`, se nedan |
| **Två toaletter till vänster om entrén** | x 0–1,7; N 0,3–1,1 och 1,6–2,4 | `wc_n1`, `wc_n2`, `stangt` | `PLAN` + `[enligt Tobias]` | "two toilets left of entrance"; vänster = norr när man går in österut; dörrar olästa → slutna |
| Västkorridoren | x 0–2,2, N 0,3–13; planens gröna stråk | `vastkorridor`, utan namn | `PLAN` | pilarna löper söderut mot läktarremsan |
| Öppningen entré → cellraden | i väggen x 2,2, N 2,4–3,8 | `korridor_o.glasparti` | `PLAN`; glas eller dörr `REFERENCE GAP` | |
| Cellraden, fyra celler | x 2,2–4,2; tvärväggar N 3,9 · 6,4 · 7,9 · 9,8 (halv, x 2,2–3,1); luckor mot skåpkorridoren N 1,1–3,1 · 4,6–5,4 · 6,8–7,6 · 9,8–11,6 | `cell_1`–`cell_4`, `skap_v.a`–`d`; region `cellrad` utan namn | `PLAN`; funktion `REFERENCE GAP` | Bild 2–5 (reception, skåpförvaring, ombytesrum med dusch, HWC) hör hit men urklippen saknas i repot → **inte namngivna, inte placerade** |
| **Skåpkorridoren** | x 4,2–5,7, N 1,6–16; luckor österut N 3,2–4,1 · 5,8–6,5 · 7,6–8,4 · 9,7–10,9 | `skapkorridor`, etikett SKÅPKORRIDOREN | `PLAN` + `FOTO` (`ridhus-klubb-01`) | fortsätter 4,5 m förbi hallens gräns, längs banans nordvästra hörn |
| Den kryssade rutan (schaktet) | kryssad ruta x 5,75–7,6, N 7,3–9,0, tätt öster om skåpväggen | `schakt`, `stangt`, **ingen etikett** | fotavtrycket `PLAN`; funktionen `REFERENCE GAP` | rättad i förstoring 2026-09-03 — låg 3 m fel, i cellraden. Hette `hiss`/`HISS` t.o.m. `a21d6ab`; **superseded** efter Senior Re-review 2026-09-03 (blocker 1): en okänd funktion får inte kanoniseras som hiss |
| Rummet innanför hallens tvärvägg | x 5,7–10,5, N 4,3–7,2; dörr norrut x 7,7–9,6; lucka västerut N 5,8–6,5 | `hall_n_v`, `hall_mitt`, `hall_nv_s`; ingen egen region | `PLAN`; funktion `REFERENCE GAP` | södra väggen N 7,2 saknades i första läsningen |
| Rummen mot nordöstra hörnet | vägg N 4,3 x 15,3–18,4; x 18,4 N 1,3–7,1; N 5,9 x 18,4–21,7 | `hall_n_o`, `hall_no`, `hall_no_s` | `PLAN`; funktion `REFERENCE GAP` | |
| Östra korridoren | x 21,7–25, N 0,2–11,4 | `ostkorridor`, utan namn | `PLAN` | leder mot hästgången |
| **Hästgången** (Bild 7) | östra långsidan, sammanbyggd med stallet | dörren `hastgang` + `sargGrind` | `[enligt Tobias]` + `PLAN` | ett gränssnitt: `stallhus:horse_passage ↔ ridhus:horse_passage`; bryter stallets västra boxrad, inte läktaren |
| Svarta gaveldörren | N-gaveln, 16,1–16,7 m från väster | `ut_ridhus_N_8` (fasadens `u:8.1`) | `PLAN` = fasad | den handskrivna `ut_n` i nordöstra hörnet är borttagen |
| **Ridbanan** (Bild 6) | "till höger om klustret" = söder om det; hallens västra gräns N 11,4 | `bana` y 5,68–65,68, x 4,4–24,4; `entre` 11,5 | `PLAN` + `FOTO` | |
| **Läktaren** | remsa längs västväggen, hela banans längd, däckfront ≈ x 3,9 | `laktare` x 0,6–4,0, utan gap | `PLAN` + `FOTO` | förut öster med gap för hästgången |
| **C-blocket** (bleachers → två trappor) | bänkblock vid banans norra kant x 8,6–21,6, N 7,05–11,5; tre trappsymboler | `kortanda`, `vand:"S"`, `trappor` 13,8 och 17,65 | `PLAN` + `FOTO` + `[enligt Tobias]` | trappornas riktning `REFERENCE GAP` |
| **Övre plan: korridor → Café Krubban** | ingen plan; Tobias: bleachers → två trappor → övre korridor → caféet | `cafe` som eget lager, golv `z0` = glasbandets underkant | `[enligt Tobias]` + `FOTO` | **inte** plattat in i entréplanet; rumsindelningen `REFERENCE GAP` |
| Sargporten för folk till fots | ingen symbol; planens pilar går här | **borttagen ur fidelity-datan** (`RIDHUSINNE.port` finns inte); spelets gap ligger i `SPELABSTRAKTIONER.ridhus.sargport`, x följer banan, bredd 2,2 vald | `REFERENCE GAP` i fidelity; `SPELABSTRAKTION` | Senior Re-review 2026-09-03 (blocker 2): en ruttslutsats får inte bli anläggningsgeometri. Roblox bygger gapet med en märkt, genomskinlig markör; testerna mäter märkningen, inte läget som verklighet |
| Domarbåset | — | `domarbas` på däcket, följer sidan | `FOTO` | |
| Västdörren `u:40` (svarta dörren vid skylten) | i läktarens långsida | `ut_ridhus_W_40`, innerpunkt vid däckets fot på sanden | spelabstraktion | däcket är solitt i kollisionen; annars spawn inne i läktaren (regression vid vändningen, fångad av gångprovet) |
| Södra zonen bakom sargen (y 0–5,68) | — | onåbar till fots | `REFERENCE GAP` | ingen öppning i södra sargen är belagd; var onåbar även i basen |

**Superseded** — läsningar som stod i koden och nu är ersatta, inte omtolkade:

| Tidigare | Ersatt av | Varför |
|---|---|---|
| Läktaren på **östra** långsidan, med gap för hästgången | västra långsidan, utan gap, hela banans längd | planens läktarremsa ligger längs bildens överkant = väster; hästgången bryter stallets boxrad, inte läktaren |
| C-blocket i **söder** | i norr mot banans norra kant, vänt söderut mot banan | planen + Tobias: bleachers → trappor → övre korridor → caféet, som ligger ovanpå entrédelen i norr |
| `hallMobler`: disk, bänkar, kansli, omklädning, trapphus som handritade rektanglar | planens väggar med luckor och rum som regioner | ingen källa; Product Owner: inga uppfunna rum |
| `trappa` och `klocka` vid "centrala trappan" | borta | dubbletter av C-blockets trappor och klocka |
| Sargporten mitt på norra kortsidan "vid A" | banans nordvästra hörn, väster om C-blocket | C-blocket står där; A står i söder |
| `entre` 13 m | 11,5 m | hallens västra gräns i planen, N 11,4 |
| `ut_n` i nordöstra hörnet (21,9; 74,2) | fasadens `ut_ridhus_N_8` vid svarta gaveldörren | dörren fanns varken i plan eller fasad |
| Dressyrbokstäverna med A i norr | A i söder, C i norr, E mot läktaren | C står framför C-blocket |
| `hiss` i cellraden x 2,6–4,4 (första läsningen i denna gren) | x 5,75–7,6 öster om skåpväggen | förstoring |

**`CONTRADICTION`**, redovisade och inte rättade:

- **Huvudentrén.** Planen sätter dubbeldörren 2,2–2,7 m från gaveln; den
  låsta fasaden 9 m (`u:9`). Spelet behåller fasadens dörr; planens entrécell
  ligger 6 m norr om den. Avgörs av exteriörlåset, inte här.
- **Banans nordvästra hörn.** Planen låter skåpkorridoren (till N 16) och
  läktarremsan (från N 13,7) fortsätta förbi hallens gräns N 11,4; spelet
  behåller den rektangulära 20 × 60-banan, så väggstumparna står 1,3 m in i
  sandens hörn. Sanden borde vara urtagen där — inte gjort, banan är en
  rektangel i båda renderarna.
- **Läktaren mot västdörren `u:40`.** Fasadens dörr öppnar mot ett solitt
  däck i spelet; innerpunkten står på sanden.

---

## Vad F02-A bygger, och vad den inte bygger

**Byggt i Stallhuset** — allt innanför ytterväggarna, ur `klubb` och
`brott` i `src/site.js`, genom exportören till båda ytorna:

| Byggt | Läge | Klass |
|---|---|---|
| Klubbdelens genomgående vägg med två dörrar | y 57,45; dörrar x 4,1–5,0 (inre entrén) och 7,7–8,8 (sadelkammaren) | `PLAN` / tvärled `ASSUMED_SCALE` |
| Klubbdelens rum som gångbara regioner med väggar | se tabellen § Rum och zoner | `PLAN` + `[enligt Tobias]` |
| Den namnlösa volymen (`sluten_volym`), Ö-toaletten och det lilla rummet som slutna volymer | dito | geometri `PLAN`; funktion/dörr `REFERENCE GAP` |
| Hästförbindelsens brott i västra boxraden | y 28,35–30,75, läst ur fasaddörren | `PLAN` + `[enligt Tobias]` |
| Tretton boxar per obruten rad, tolv i västra | räknas ur måtten | `PLAN` |

Raden om ett trapphus med trappa stod här en runda och är **återtagen**, och
rundan därpå stod rummet som `trapphus` med etiketten `TRAPPHUS` — också
**återtaget** — se § Symbolrutan nedan. Tvärgången tvärs huset är borttagen — se § Superseded.

**Byggt i Ridhuset** — ur `RIDHUSINNE` i `src/site.js`, samma schema
(`vaggar` med `oppningar`, `rum` med `stangt`) och samma byggare som stallets
klubbdel på båda ytorna (`klubbVaggBitar` / `Geometri.vaggBitar`):

| Byggt | Läge | Klass |
|---|---|---|
| Läktaren på västra långsidan, ett stycke utan gap | x 0,6–4,0, y 5,68–65,68; banan x 4,4–24,4 | `PLAN` + `FOTO` |
| C-blocket i norr, vänt mot banan, två trappor, glasband, vit vägg, klocka | y 65,68–70,13, x 8,6–21,6 | `PLAN` + `FOTO` + `[enligt Tobias]` |
| Caféet som eget lager ovanpå entrédelen | z0 ur blockets glasband | `[enligt Tobias]` + `FOTO` |
| Entrédelens väggar segment för segment med planens luckor | `entrehall.vaggar`, 17 väggar | `PLAN` (±0,5 m) |
| Entrén, två toaletter, skåpkorridoren med namn; den kryssade rutan som namnlöst slutet `schakt` | `entrehall.rum` | `PLAN` + `[enligt Tobias]`; schaktets funktion `REFERENCE GAP` |
| Grinden mot hästgången | härledd ur hästgången | `[ASSUMPTION]` (bredd) |
| Sargporten väster om C-blocket | **inte fidelity** — `SPELABSTRAKTIONER.ridhus.sargport` | `SPELABSTRAKTION`; `REFERENCE GAP` i fidelity |
| Dressyrbokstäverna vända (A söder, C norr) | `DRESSYRBOKSTAVER` | `DERIVED` |
| Västdörren `u:40`: innerpunkt vid däckets fot | härledd | spelabstraktion |

Exteriören är orörd: inga fasader, entréöppningar, fönster, tak, spiraltrappa
eller tomtrelationer ändras. Ingen möblering (F02-B).

### Symbolrutan — planens symbol lästes fel två gånger

Utrymningsplanen ritar en symbol i klubbdelens ruta x 5,9–7,3, N 4,9–11,3.
Den lästes först som en **egen, ny trappa i Stallhuset**, från markplan upp
till Plan 2, och byggdes som `STALLINNE.trappa` (x 5,82–7,67, y 58,45–64,25,
18 steg) med egna villkor i `roblox/tests/bygge.spec.luau`.

Det var fel. Tobias, som känner anläggningen, rättade läsningen: trappan man
faktiskt går upp finns, men den nås via **ridhusets läktarplan** — inte som en
fristående uppgång ur klubbdelen på markplan.

Rundan därpå byggdes rutan som sluten volym men med id `trapphus` och den
spelarsynliga etiketten `TRAPPHUS`. Det var samma fel i mindre format: en
funktionstolkning av symbolen utan oberoende källa (ChatGPT-review på 928e090).
Nu heter rutan `sluten_volym`, har ingen etikett, väggarna heter `volym_*`, och
matrisen klassar **geometrin `PLAN`** (fotavtrycket) och **funktionen
`REFERENCE GAP`**. Den enda kanoniska vertikala förbindelsen i anläggningen är
ridhusets: läktarplanet → C-kortändans trappor → övre gången/caféet.

**Rättad källa-till-faktum-koppling:**

| Faktum | Källa | Klass |
|---|---|---|
| Det finns en trappsymbol i klubbdelen på Plan 1 | `references/plans/stall-plan1-utrymning-rak.jpg` | `PLAN` |
| Symbolen betyder en egen stalltrappa från markplan | — | **återtaget**, motsagt av `[enligt Tobias]` |
| Symbolen betyder ett trapphus (sluten volym med namnet `TRAPPHUS`) | — | **återtaget**; ingen oberoende källa; funktion `REFERENCE GAP` |
| Uppgången till den glasade övervåningen går via läktarplanet | `references/buildings/ridhus/granskning-2026-08-31/C-kortandan-och-kafeet.md`, `ridhus-klubb-10-overvaningens-gang.jpg`, `ridhus-inne-39-gangen-bakom-laktaren.jpg` | `VERIFIED` |
| Två raka trappor vid ridhusets C-kortända, mörkt trä, flankerar den vita mellanväggen | `ridhus-inne-01-glasrummen.jpg`, `IMG_0192-f01`, `IMG_0192-f02` | `VERIFIED` |
| Glasbandet ovanför är kafé/korridor och bryts av trapporna | `ridhus-klubb-07-cafeet-genom-glaset.jpg`, `ridhus-klubb-09-cafesalen.jpg` | `VERIFIED` |

**Vad som togs bort:** `STALLINNE.trappa` i `src/site.js`, dess fält i
`tools/exportera-geometri.js`, `UBRFKomplex.stall.trappa`, renderingen i
`src/varld3d.js` och `roblox/buildings/Anlaggningen.luau`, och de fyra villkoren
i `bygge.spec.luau` som bara fanns för den. Den genomgående väggen på y 56,97
står kvar — den vilar på sin egen mätta linje (andel 0,1855) och berörs inte av
rättelsen.

**Åtkomstkedjan som finns byggd i båda ytorna**, ur samma data
(`RIDHUSINNE.kortanda`, `trappor:[7.0, 15.5]`):

| Led | Webb `src/varld3d.js` | Roblox `Anlaggningen.luau` |
|---|---|---|
| Läktarens trappstegsblock | rad ~1437 | rad ~871 |
| C-kortändans två trappor | rad ~1452, ur `K.trappor` | rad ~892, ur `K.trappor` |
| Glasbandet, brutet av trapporna | rad ~1466, segment ur `K.trappor` | rad ~941, segment ur `K.trappor` |

Kedjan **ridhus → läktarplan → C-trapporna → glasat band/kafé** finns alltså som
geometri på båda ytorna och byggs ur samma tal.

`[REFERENCE GAP]` **Kedjan är inte gångbar.** I webben är läktaren solid i
`src/world.js` (`kollideraRekt` över `laktarSektioner`), så spelaren kan inte gå
upp. Om trapporna går att gå i Roblox är **Not tested** — ingen Studio-runtime i
den här miljön. Måtten på själva förbindelsen mellan glasgången och klubbdelen
saknar underlag och **hittas inte på**. Att göra kedjan gångbar är inte F02-A:s
scope.

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
   Den raka planbilden ger 21,9 m som en ny, oberoende avläsning.
2. **Boxfackets längd**, 2,94 mot 3,5 m.
3. **Ridhusets entréplan i djupled** — rektifiering underkänd, omfotografering
   utesluten; talen är ±0,5 m ur ett rutnät på den sneda bilden.
4. **Rumsfunktioner** som ingen källa ger: stallets lilla rum, östra rummet,
   väggspåret och halvväggen; var pentryt ligger. I ridhuset: cellradens fyra
   celler, rummet innanför hallens tvärvägg, rummen mot nordöstra hörnet, och
   vad den kryssade rutan är (den heter `schakt` i datan, utan etikett, och
   får inte kallas hiss förrän belägg eller produktägarbeslut finns).
5. **Dörrar** som planen inte visar: Ö-toaletten, det lilla rummet, den
   namnlösa volymens ingång; ridhusets två toaletter och schaktet; om
   entréöppningen mot cellraden är glas eller dörr; var skåpkorridoren slutar
   vid N 16.
6. **Plan 2:s rumsindelning** — bilden beskuren. Ridhusets **övre plan**
   (övre korridoren, Café Krubban) saknar plan helt.
7. **Volymen söder om stallets gavel** — ingen bild.
8. **Tobias markerade planurklipp (Bild 1–7)** finns inte i repot. Ridhusets
   rumsidentiteter vilar därför på hans verbala beskrivning plus min läsning
   av planen; reception, skåpförvaringsrum, ombytesrum med dusch och HWC
   (Bild 2–5) är **inte placerade** förrän urklippen ligger i
   `references/plans/` så att kopplingen går att kontrollera av någon annan.
9. **C-blockets trappor** — vilket håll de går; planen visar tre trappsymboler,
   fotona två trappor.
10. **Sargporten för folk till fots** — ingen källa visar grinden i sargen;
    läget följer planens pilar. Den finns därför INTE i fidelity-datan utan
    bara som spelets `SPELABSTRAKTIONER.ridhus.sargport`, märkt
    `SPELABSTRAKTION` i data, i Roblox-bygget (gul genomskinlig markör med
    attribut) och i testerna, som mäter märkningen och inte läget som
    verklighet. **Södra sargen** — ingen öppning belagd, zonen bakom är
    onåbar till fots.

Inget av dessa fylls med en rimlig gissning.
