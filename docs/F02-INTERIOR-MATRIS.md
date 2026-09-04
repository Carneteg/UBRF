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
| Gaveldörr och vindfång | dörr x 3,6–5,5, två stumpar N 0–2,0 | region `vindfang` med etikett; **stumparna byggs inte** (Spatial Canon v2: de ligger inne i OPEN_AREA `stall_uppehall_open`; inget foto belägger en vägg) | `PLAN` för dörren; stumparna `REFERENCE GAP` | planen; grön utrymningspil ut genom gaveln |
| **Uppehållsrum / väntrum** — L-format | västdelen x 0–5,9, N 0–10,0 **och** östdelen x 5,9–11,2, N 0–5,6, utan vägg emellan | `uppehallsrum` + `uppehallsrum_o` (`del:"uppehallsrum"`) | `PLAN` + `[enligt Tobias]` | "man kommer först in i uppehållsrummet"; PO 2026-09-03: "uppehållsrummet är för litet" → östdelen (f.d. "passage") hör till rummet; golvyta ≈ 79 m² (grind ≥ 75) |
| Dubbellinjeritad ruta i uppehållsrummets västdel | x 2,0–3,0, N 5,6–10,0 i planen | **byggs inte** — ÅTERKALLAD av Product Owner (PO-2026-09-03-STALL-OPEN-01: "I stallet finns inte denna väggen i uppehållsrummet; det är en öppen yta") | `SUPERSEDED`; NO_WALL_ZONE `stall_uppehall_no_internal_wall` | Spatial Canon v2; planens ruta kvarstår som `REFERENCE GAP` (vad den ritar), inte som geometri |
| **Toalett väster om inre entrén** | x 0–3,0, N 10,0–12,5; dörr i ÖSTVÄGGEN mot lobbyn N 10,8–11,7; lucka x 0–0,9 i nordväggen | `wc_v`, `wc_v_o.oppningar.wc_v_dorr`, `wc_v_n.oppningar.wc_v_lucka_n` | `PLAN` + `[enligt Tobias]` | "två toaletter, en på var sida"; nordluckan är planens linje som börjar 0,9 m från västväggen — dörr eller ritningsglapp: `REFERENCE GAP` |
| Lobby / inre entré | x 3,0–5,9, N 10,0–12,5; planens gröna pil ner genom | `lobby` | `PLAN` | |
| **Inre entrén till stallet** | dörr x 4,1–5,0 i den genomgående väggen | `oppningar.inre_entre` | `PLAN` + `[enligt Tobias]` | "rakt fram leder in i stallgång A" — gång A ligger x 4,4–7,0 |
| **Toalett öster om inre entrén** | x 5,9–7,3, N 10,7–12,5 (cellen vid symbolrutans fot) | `wc_o`, `stangt` | `PLAN` + `[enligt Tobias]` | dörr oläsbar → sluten volym |
| Sluten volym utan namn (planens symbolruta) | x 5,9–7,3, N 4,9–10,7 | `sluten_volym`, `stangt`, `label:""` | geometri `PLAN`; funktion `REFERENCE GAP` | se § Symbolrutan; ingen etikett, inget funktionsnamn |
| Litet rum med grå ruta | x 9,0–11,2, N 0–2,2 | **byggs inte** — plancellen ligger inne i OPEN_AREA `stall_uppehall_open`; en cell utan foto är inte väggbevis (Spatial Canon v2) | `REFERENCE GAP` | grått = utanför utrymningsytan; funktion oläsbar |
| **Teorisal** | x 11,2–17,3, N 0–5,6; öppning i västväggen N 3,0–5,6 | `teorisal` | `PLAN` + `[enligt Tobias]` | "teorisalen till vänster om uppehållsrummet" |
| **Sadelkammare** | x 7,3–15,5, N 5,6–12,5; in från passagen x 7,3–8,8; egen dörr söderut x 7,7–8,8 | `sadelkammare` | `PLAN` + `[enligt Tobias]` | "vänster och sedan höger" = öster, sedan söder |
| Halvvägg i sadelkammaren | x 9,0–12,2 vid N 9,1 | `sadelkammare_mellan` | `PLAN`, funktion `REFERENCE GAP` | |
| Östra rummet | x 15,5–21 N 5,6–12,5 + x 17,3–21 N 0–5,6; utgång österut N 9,9 | `ostrum`, `ostrum_n`, utan namn | `PLAN`, funktion `REFERENCE GAP` | utgången: `DEFERRED BY EXTERIOR LOCK` |
| Pentry (fotoverifierat: valv- och rundfönster, mikro, kyl, bord) | ingen etikett | uppehållsrummets NV-hörn, x 0–3,6 vid gaveln | `FOTO` + `DERIVED` | `stall-inne-02` visar valvfönster med runt fönster till HÖGER och ett hörn med tavla därefter; `stall-entre-01` visar samma par utifrån (runt fönster till vänster om valvfönstret = öster om det) och `stall-entre-15` runda fönster på BÅDA sidor om dörren → paret sitter väster om entrédörren, hörnet är vindfångets västra stump x 3,6. Möbleringen är F02-B |
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
| `uppehallsrum` x 0–5,9 × N 0–9,8 och `passage` som eget rum | L-format uppehållsrum: `uppehallsrum` + `uppehallsrum_o` | Product Owner 2026-09-03: "för litet"; planen har ingen vägg mellan delarna; pentryt sitter i västdelens NV-hörn |
| `sluten_volym_v` 1,0 × 4,4 m i uppehållsrummet (runda 5387324) | ingen — OPEN_AREA | Product Owner 2026-09-03 (Spatial Canon v2): "denna väggen finns inte; det är en öppen yta" |
| `vindfang_v/_o/_fot` och `litet_rum` med väggar | inga — OPEN_AREA | Spatial Canon v2: partitioner inne i den öppna ytan utan fotobelägg byggs inte |
| Tjocka väggen `spar` x 2,8–3,5, N 5,5–9,8 | sluten volym `sluten_volym_v` x 2,0–3,0, N 5,6–10,0 | omläst i originalbilden (4032 px): dubbla linjer = vägg med tjocklek runt en ruta, inte en fristående tjock vägg |
| WC-V x 0–4,0 med dörr N 10,45–11,5 | WC-V x 0–3,0 med dörr i östväggen N 10,8–11,7 + lucka x 0–0,9 i norr | omläst i originalbilden: väggen x 3,0 har ett 0,9 m hål N 10,8–11,7; linjen N 10,0 börjar 0,9 m från västväggen |
| Ö-toaletten N 11,3–12,5, symbolrutan N 4,9–11,3 | N 10,7–12,5 respektive N 4,9–10,7 | omläst i originalbilden: symbolens fot och cellens tvärlinje ligger på N 10,7 |

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
| **Huvudentrén** (Bild 1) | planens cell x 0–2,2 × N 2,4–3,8; grön pil ut genom västväggen; planens "här är du"-linje pekar mot norra gaveln (audit 2026-09-03) | region `entre` med etikett ENTRÉ vid **fasadens låsta dörr** (`u:9`, N 9–11, innerpunkt (1,6, 67,18)); ingen geometri | `CONTRADICTION` — exteriörlåset vinner | tre lägen i källorna (plan 2,2–3,8; "här är du" norra gaveln; fasad 9 m); spelet följer fasaden |
| **Receptionen i nordvästra hörnet** (PO 2026-09-04 07:54: "two toilets where the reception should be") | planens hörnceller x 0–1,7, N 0,3–2,4 + cellen söder om dem (sydvägg vid N ≈ 4,5, beskärning 2026-09-04); planens mellanvägg N 1,1–1,6 | `reception_s` WALL (y 72,6), `reception_dorrvagg` med öppningen `reception_dorr` (x 2,2, y 72,62–73,48), `reception_glas` GLASS x 2,2, y 73,5–77,0 med hylla; region `reception` x 0–2,2 × y 72,6–77,18 utan etikett; möbler ur `ridhus-klubb-02` (F02-B: träskåp, tavlor, stol) | `PRODUCT_OWNER_VERIFIED` + `FOTO` ridhus-klubb-01/-02/-15 + `PLAN` | glaset mot skåpgången (lockers mitt emot), dagsljus i rummets bortre ände = gavelns valvfönster x 0,4 (-02). Planens mellanvägg: `CONTRADICTION` mot fotots sammanhängande rum — byggs inte. Dörrens ände `[antagande]`. Glasets x 2,2 mot cellväggens 1,7: `[antagande]` 0,5 m |
| Toaletterna (`wc_n1`/`wc_n2`) | — | **borttagna ur entrédelen** (`ingaVaggar.aterkallat`: wc_n_s/wc_n_mellan/wc_n_o) | `SUPERSEDED` av PO 2026-09-04 07:54 | var toaletterna (-04/-05/-17) ligger: `REFERENCE GAP` |
| F02-A:s glaslinje x 2,2, N 4,6–8,3 | planens 3,7 m-linje | **återkallad** (`reception_glas@x2.2-N4.6-8.3`) — receptionen ligger i hörnet | `REFERENCE GAP` (vilken vägg linjen är) | inga ersättningsväggar; västra bandet söder om receptionen är öppet |
| Västkorridoren, öppningen entré → cellraden (`korridor_o`, `glasparti`) | planen bär bara x 2,2, N 4,6–8,3 (3,7 m) — inte N 0,3–13 | **borttagen** (Spatial Canon v2, PO-2026-09-03-RIDHUS-OPEN-01); sträckan N 4,6–8,3 är receptionens glas | `SUPERSEDED` | fotona (`ridhus-klubb-01/-15`, `IMG_0169`) visar EN öppen gång med skåp som möbler, ingen vägg |
| Cellraden, fyra celler (`cell_1`–`cell_4`) | < 10 % täckning vid koordinaterna N 3,9 · 6,4 · 7,9 · 9,8 | **borttagna** | `SUPERSEDED`; funktionerna (Bild 2–5: reception, skåpförvaring, ombyte med dusch, HWC) `REFERENCE GAP` | en plancell utan streck är inte väggbevis; HWC får ingen vägg av sin funktion |
| **Receptionen** (Bild 2) — läge t.o.m. 2026-09-04 07:54 | Tobias: glasad; foto: låg bröstning + fyra fasta glaspartier + hylla mot gången; planens 3,7 m-linje x 2,2, N 4,6–8,3 | ersatt av raden *Receptionen i nordvästra hörnet* ovan (PO 2026-09-04 07:54) | `SUPERSEDED` | — |
| Skåpkorridorens två väggar (`skap_v`, `skap_o`) | inga sammanhängande streck vid x 4,2 / 5,7 | **borttagna**; etiketten SKÅPKORRIDOREN borta | `SUPERSEDED` | skåpen är fristående möbler (F02-B), inte väggar |
| Den kryssade rutan (schaktet) | x 5,75–7,6, N 7,3–9,0; oberoende ommätt 5,58–7,42 / 7,15–9,04 | `schakt`, `stangt`, WALL `ridhus_schakt_box`, **ingen etikett** | fotavtrycket `PLAN`; funktionen `REFERENCE GAP` | hette `hiss` t.o.m. `a21d6ab`; står utanför vägen entré → bana |
| Rummet innanför hallens tvärvägg, rummen mot nordöstra hörnet (`hall_n_v`, `hall_n_o`, `hall_nv_s`, `hall_mitt`, `hall_no`, `hall_no_s`) | inga egna streck; `hall_nv_s` = C-blockets framkant; SITEPLAN: "otydlig i mitten, [antagande]" | **borttagna** — `hall_n_v` var väggen som spärrade vägen entré → bana | `SUPERSEDED`; funktion `REFERENCE GAP` | OPEN_AREA `ridhus_open_entrance_hall` |
| Östra korridoren (`ostkorridor_v`) | två korta körningar i takstolsmarkeringarnas rytm | **borttagen** | `SUPERSEDED` | |
| **Kedjan huvudentré → öppen hall → sargport → bana** | planens gröna pilar löper från entréklustret rakt in i hallen; `ridhus-inne-39`: glasad dubbeldörr vid NV-hörnet mellan hall och bana | OPEN_AREA + sargporten (SPELABSTRAKTION x 4,7–6,9); grind SCV2-03 i `bygge.spec` (spelarradie 0,35, ingen opak vägg inom 1,0 m) och `tools/gangtest.mjs` (webben går kedjan) | PO-2026-09-03-RIDHUS-ROUTE-01 | portens exakta läge/bredd `REFERENCE GAP` (abstraktion, ej fidelity) |
| **C-ändans två trappor** (PO 2026-09-03 17:16; senior review 17:18) | två raka lopp i mörkt trä med träräcke LÄNGS gaveln, foten vid den vita klockväggen, stigande utåt (vänstra mot väster, högra mot öster) från översta bänkraden till glasbandets nivå; vita snedställda sidostycken bryter bandet i tre fält: `ridhus-inne-01`, `IMG_0192-f01/-f02`, `ridhus-inne-07`; uppifrån `ridhus-klubb-10`; planens 12,4–15,2 / 16,4–18,9 m från väster | `kortanda.trappor` = `[{x0:12.4,x1:15.2,fot:"E"},{x0:16.4,x1:18.9,fot:"W"}]` → härledda STAIR-primitiver `c_trappa_v` (`ridhus_c_end_stair_west`) och `c_trappa_o` (`ridhus_c_end_stair_east`) i `RIDHUSINNE.trappor`: översta radens remsa, z 2,08 → 3,68, 9 steg à 0,18 m; klockan x 15,8 mellan loppen, stjärnan väster om det vänstra; `ovreGang` norr om vägglinjen | `VERIFIED` (foto) + `PLAN` (läge); riktningen ur `IMG_0192-f02` | gångbara på båda ytorna (webbens nivåregel `VD.pz`, Roblox-steg); grindar i geometri/bygge.spec + `tools/gangtest.mjs`; **Roblox-blockets bänkrader var byggda 0,64 m höga** (bas på fel rad) — rättat **Visuell form (senior visual review 2026-09-04 05:51, MISMATCH ARENA-C/C-BLOCK-OVRE):** från banan är loppen VITA snedställda skivor i liv med den vita väggen med det mörka träräcket ovanpå (`ridhus-inne-01`); loppens mörka steg syns bara från trappan (`IMG_0192-f01/-f02`, `-07`). Sidostycket är ett **trapets**: vågrät underkant i blockets krön (loppets fot), överkant längs räcket 0,9 m över stegen — lågt vid klockväggen, högt vid toppen; ritat i eget otexturerat nät (träreliefen färgade det mörkbrunt). Runda 3 (06:33): den lutande 1,6 m-skivan lästes som "bow-tie" och slukade glasbandet — ersatt av trapetsen. Klockväggen står fri mellan loppens fötter |
| Bänkradsstegen (hallgolvet → nedersta raden) | blocket står i entrédelen (plan); publiken når raderna från hallsidan; **inget foto visar stegen** — full källkontroll (ridhus-inne-01/-07, IMG_0192-f01/-f02, ridhus-klubb-10, planen) ger ingen anslutning | **inte fidelity-geometri.** Bara som spelabstraktion `SPELABSTRAKTIONER.ridhus.bankradSteg` (`klass:"SPELABSTRAKTION"`, `fidelity:"REFERENCE GAP"`, `motiv`), x 7,0–8,6, y 65,68–66,78, z 0 → 1,12; byggd som märkta klossar + gul markör (`Spelabstraktion bankradsteg …`) i Roblox, neutrala steg + gul markör på webben; ingen `canon_id`/`source_id`/`confidence`/`primitiv` | `REFERENCE GAP` (ingen PO-verifierad fidelity — senior review 2026-09-04 04:08, blocker 1) | räknas **inte** in i F02:s PASS; grindarna i `geometri.spec`/`bygge.spec` provar att den INTE finns i `ridhus.trappor` och att fidelity-kedjan (översta raden → C-trappa → övre gången) inte beror på den; gångtestet märker den som SPELKRAV. Läktargångens tredje trappa vid H (`ridhus-inne-14/-15/-10`) hör inte till ordern och byggs inte |
| **Norra gavelns insida** (klubbgaveln, STALL-ENTRE) | den låsta fasaden: ockragul entrédörr med solfjäderfönster och vit karm mitt på gaveln, ett runt fönster med korspröjs på var sida (`stall-entre-15-dorren.jpg`, `-16`); ingen interiörbild av gavelns insida | insidan visar samma öppningar på samma ställen, lästa ur `ANL.byggnader` stall `oppningar` sida N (u från östra hörnet): väggen skuren runt dörren, dörrbladet i öppningen, vit karm, solfjäderfönster, runda fönster som utsidan ritar dem (webb `v3dStall`; Roblox `byggStallInre` "Klubbentrén inifrån", "Runt fönster inifrån") | `FASAD` (låst) → `DERIVED` för insidan; dörrbladets färg inifrån `[antagande]` (samma som utsidan) | **samma fysiska dörr inne som ute (runda 3, 06:33):** `ut_n` (innerpunkten) ligger nu vid fasadens entrédörr, läst ur fasaddatan, så att den som går in under verandan står innanför just den dörren — förut hamnade hon i planens vindfång 5,9 m västerut. Planens vindfångscell står kvar som region utan etikett; motsägelsen plan/fasad är dokumenterad, fasaden (PRODUKTBESLUT 2026-09-02) vinner. Ankaret `stall_entre_samma_dorr` (#80) vaktar relationen. Exteriören är orörd — reviewkameran STALL-ANKOMST (#80) jämför verandan mot `stall-fasad-04`, `stall-entre-01/-03/-15` |
| **Huvudentrén sedd inifrån** (PO 2026-09-04 07:54, blocker 2) | fasadens `dorrvit` u 9 (vit glasad dubbeldörr) på västväggen; inifrån: vit karm, glasrutor, grön utrymningsskylt (`IMG_0169-f05`, `ridhus-klubb-03`) | `v3dDorrarInifran` (webb) / `Fasaddörr inifrån` (Roblox): dörrblad, foder, rutor, handtag och skylt på väggens insida för alla fasaddörrar; etiketten ENTRÉ borttagen | `FOTO` (utseende) + fasaddata (läge) | dörrbladets färg inifrån `[antagande: som utsidan]`; planens tre entrélägen mot fasaden: dokumenterad `CONTRADICTION`, fasaden vinner |
| **Läktartrappan vid H** (PO 2026-09-04 07:54, blocker 3) | `ridhus-inne-39` (däcket löper fram till en trappa i mörkt trä som stiger norrut längs västväggen), `ridhus-klubb-11` (från toppen nedåt, raderna till vänster), `ridhus-inne-15/-14/-20` (vit snedställd sida vid H upp till glasrummet), `ridhus-klubb-10` (övre gången fram till trappan ner), planens trappsymbol vid läktarens norra ände | `laktar_trappa_h` STAIR x 0,6–1,6, y 62,82–65,68, z 1,70 → 3,68 stiger N; `ovreGangV` landgång x 0,6–1,6, y 65,68–70,13 på caféplanet med räcke; caféets frontvägg öppen i landgångens bredd | `VERIFIED_PLAN_OR_PHOTO`; bredd 1,0 m och loppets längd `[uppskattning]` (`osakert`) | foten på översta radens nivå (-39); hallgolv → däck syns bara som nivåskillnad (-39): `SPELABSTRAKTIONER.ridhus.laktarSteg`, gul markör, inte fidelity |
| Övre gången | gången på övre plan innanför glasbandet: `ridhus-klubb-10`, `-07`–`-09` | `ovreGang` x 0,6–24,4, y 70,13–72,63 (norr om C-blockets vägglinje), z 3,68 (caféplanet); golv + räcke utanför blocket | `FOTO`; bredd `[uppskattning]` 2,5 m | Café Krubbans rum innanför `REFERENCE GAP`, byggs inte |
| **Hästgången** (Bild 7) | östra långsidan, sammanbyggd med stallet | dörren `hastgang` + `sargGrind` | `[enligt Tobias]` + `PLAN` | ett gränssnitt: `stallhus:horse_passage ↔ ridhus:horse_passage`; bryter stallets västra boxrad, inte läktaren |
| Svarta gaveldörren | N-gaveln, 16,1–16,7 m från väster | `ut_ridhus_N_8` (fasadens `u:8.1`) | `PLAN` = fasad | den handskrivna `ut_n` i nordöstra hörnet är borttagen |
| **Ridbanan** (Bild 6) — den fysiska ridytan | "till höger om klustret" = söder om det; hallen är en obruten yta från entrédelens gräns N 11,4 till södra gaveln; `ridhus-inne-23`: A-sargen mot gaveln | `bana` y 0,15–65,68 (h 65,53 DERIVED), x 4,4–24,4; `entre` 11,5 | `PLAN` + `FOTO` | senior review 2026-09-03: 60 m var dressyrlayouten, inte sarg-till-sarg |
| **Dressyrlayouten 20 × 60** | — | `dressyr` x = banans, y = banans (förankrad i A), h 60; bokstäverna via `bokstavLage`; C-skylten på norra sargen (`paSarg:"N"`) | 20 × 60 `VERIFIED` (Tobias, SITEPLAN.md); förankringen `FOTO` (-23) | C: fotot visar skylten på sargen, 5,5 m bortom layoutens 60-m-linje — skylten hänger där fotot visar den |
| **Läktaren** | remsa längs västväggen, hela banans längd, däckfront ≈ x 3,9 | `laktare` x 0,6–4,0, utan gap | `PLAN` + `FOTO` | förut öster med gap för hästgången |
| **C-blocket** (bleachers → två trappor) | bänkblock vid banans norra kant x 8,6–21,6, N 7,05–11,5; tre trappsymboler | `kortanda`, `vand:"S"`, `trappor` 13,8 och 17,65 | `PLAN` + `FOTO` + `[enligt Tobias]` | trappornas riktning `REFERENCE GAP` |
| **Övre plan: korridor → Café Krubban** | ingen plan; Tobias: bleachers → två trappor → övre korridor → caféet | `cafe` som eget lager, golv `z0` = glasbandets underkant | `[enligt Tobias]` + `FOTO` | **inte** plattat in i entréplanet; rumsindelningen `REFERENCE GAP` |
| Sargporten för folk till fots | ingen symbol; planens pilar går här | **borttagen ur fidelity-datan** (`RIDHUSINNE.port` finns inte); spelets gap ligger i `SPELABSTRAKTIONER.ridhus.sargport`, x följer banan, bredd 2,2 vald | `REFERENCE GAP` i fidelity; `SPELABSTRAKTION` | Senior Re-review 2026-09-03 (blocker 2): en ruttslutsats får inte bli anläggningsgeometri. Roblox bygger gapet med en märkt, genomskinlig markör; testerna mäter märkningen, inte läget som verklighet |
| Domarbåset | — | `domarbas` på däcket, följer sidan | `FOTO` | |
| Västdörren `u:40` (svarta dörren vid skylten) | i läktarens långsida | `ut_ridhus_W_40`, innerpunkt vid däckets fot på sanden | spelabstraktion | däcket är solitt i kollisionen; annars spawn inne i läktaren (regression vid vändningen, fångad av gångprovet) |
| Södra zonen bakom sargen | — | **borta** — A-sargen står 0,15 m från gaveln | `FOTO` (-23) | var `CONTRADICTION` t.o.m. `e879784`; löst genom att skilja fysisk bana från dressyrlayout |
| **Läktarlångsidans vägg** | — | `IDENTITET.ridhus.laktarVagg`: ljus skivpanel (`hallvagg`) med mörka pelare där takstolarna landar, skivskarvar | `VERIFIED` (`ridhus-inne-14`, PO 2026-08-31) / pelarrytm `DERIVED` (`takstomme`) / skarvar [uppskattning] | omgranskning 2026-09-03 rad 2: väggen var en slät yta i samma ton som alla andra |
| **Sponsorpanelen hörn till hörn** | — | `ovreVagg.y0/y1` härledda till 0 → langd − entre (65,68); pilastrar på fältgränserna | `VERIFIED` (`ridhus-inne-31`, `-17`) | omgranskning rad 3: täckte 44 % (y 6–40) |
| **Fönstren ovanför panelen** | — | `fonsterband.perFalt`: ett fönster per väggfält (`ridhusFalt`), bredd 3,0 m | `VERIFIED` att de är separata (`-31`, `-17`, `-24`); bredd [uppskattning]; höjd `REFERENCE GAP` | omgranskning rad 5: var ett löpande band |
| Skyltraden | — | ordning och andelar mot bokstäverna M/B/F | `VERIFIED` ordning (`-31`, `-17`), lägen `DERIVED` | omgranskning rad 8: två RS Mustang, Hästsportbutik söder om Agria |

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

### Omgranskning 2026-09-03 — käll-för-käll, före rättelse

Product Owner underkände den kombinerade previewn: "Ridhuset läser inte
som det verkliga". Hela källmaterialet gicks igenom mot spelet innan något
ändrades; rapporten med alla 18 rader, vad som stämmer, den rumsliga
läsningen och referensluckorna står i **`docs/F02-RIDHUS-OMGRANSKNING.md`**.
Rättat i F02-A: läktarlångsidans vägg (pelare + skivor), panelen hörn till
hörn, separata fönster per fält, skyltordningen, läktarfrontens
källhänvisning. Redan rättat i F02-B (#76): tre stegade bänkrader, mörk
gångbräda, en delad spegel vid B. Kvar som F02-B/`REFERENCE GAP`:
entrédelens dörrblad, glaspartier och skåp; caféets möbler.

**A-gaveln direkt bakom sargen — löst 2026-09-03 (senior review på
`e879784`).** `ridhus-inne-23-kortsidan-vid-a.jpg`: A-skylten sitter på
sargen, den vita gaveln med dubbel glasdörr står omedelbart bakom. Spelet
hade 5,68 m mellan sargen och gaveln därför att 77,18 m (`VERIFIED`) −
11,5 m entrédel (`PLAN`) − 60 m bana lades i söder — men 60 m är
**dressyrlayoutens** mått, inte hallens fysiska sarg-till-sarg-mått. De två
är nu skilda åt i datan: `bana` = den fysiska ridytan från A-sargen mot
gaveln (0,15 m, [uppskattning] ur -23) till entrédelens gräns (planen),
h ≈ 65,5 m DERIVED; `dressyr` = 20 × 60 förankrad i A. Domarbåset står
vid layoutens E; hästgångens grind, sargporten och C-blocket vilar på
norra kanten som inte flyttade. Kvar som notering: C-skylten hänger enligt
foto på norra sargen, 5,5 m bortom layoutens 60-m-linje — den ritas där
fotot visar den (`paSarg:"N"`). Frågan till Tobias om banans längd är
därmed besvarad av planen + fotot; ett stegat mått på plats vore ändå
välkommet.

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
| Uppehållsrummet L-format med östdelen, WC-V 3,0 m, den slutna 1,0 × 4,4-volymen | § Rum och zoner | `PLAN` (originalbilden) + `[enligt Tobias]` |
| Inomhusläsbarhet: väggbitar och slutna volymer mellan kameran och spelaren tonas; kameran ut ur slutna volymer och upp när den kläms mot ytterväggen | `src/varld3d.js` (`v3dTonas`, `v3dKamera`); Roblox `Genomsiktlig`-attribut + `src/client/Genomsikt.luau` | **spelmekanik, inte fidelity** — inga rum flyttas |

### Spatial Canon v2 — bindande primitivmodell (ACTIVE_OVERRIDE)

`references/spatial/UBRF-SPATIAL-CANON-v2.json` (PR #79, mergad i denna
gren) sätter en hård modell för de omtvistade interiörerna: fysisk
geometri är bara `WALL`, `OPENING`, `GLASS`, `OPEN_AREA`, `NO_WALL_ZONE`;
rumsnamn är metadata och skapar aldrig väggar; en osäker yta får ingen
vägg. I `src/site.js` bär därför varje vägg och sluten volym i klubbdelen
(och entrédelen) fälten `primitiv`, `canon_id`, `source_id`, `confidence`,
och blocken har `oppna` (OPEN_AREA) och `ingaVaggar` (NO_WALL_ZONE).
Exporten tar med dem; Roblox skriver dem som attributen `Primitiv`,
`CanonId`, `SourceId`, `Confidence` på varje del. GLASS byggs som låg
bröstning + glasruta på båda ytorna.

**Stallhuset (klubbdelen):**

| Kanon | I datan | Följd |
|---|---|---|
| `stall_uppehall_open` OPEN_AREA, PRODUCT_OWNER_VERIFIED | `klubb.oppna[0]`: x 0–5,9 × N 0–10 ∪ x 5,9–11,2 × N 0–5,6, utom det 0,7 × 1,4 m hörn där planens symbolruta står (PLAN-geometri som kanonen inte återkallar) | grind SCV2-01: ingen vägg/volym skär ytans inre (tröskel > halv väggtjocklek) |
| `stall_uppehall_no_internal_wall` NO_WALL_ZONE | `klubb.ingaVaggar[0]` med listan över återkallat: `sluten_volym_v`, `vindfang_*`, `litet_*`, `litet_rum` | borttagna ur datan, båda ytorna |
| SCV2-02/04 provenance | alla 13 väggar + 2 slutna volymer: `WALL`, källa PLAN (+PO/FOTO), `VERIFIED_PLAN_OR_PHOTO` | grind: fält saknas → rött; confidence utanför {PO, PLAN/FOTO} → rött |

Kvar i klubbdelen: genomgående väggen, WC-V:s två väggar, symbolrutans
fyra väggar, teorisalens tre, sadelkammarens östvägg och halvvägg; slutna
volymer: Ö-toaletten och symbolrutan. Borttaget: se NO_WALL_ZONE.

### Planläsning i förstoring — uppehållsrummet, 2026-09-03

Product Owner underkände den kombinerade previewn: "Stallhuset uppehållsrum
är för litet". Klubbänden lästes då om i **originalfotot** av planen,
`references/plans/stall-plan1-utrymning.jpg` (4032 × 3024 px), i stället för
den rektifierade 1500 px-bilden. Reproducerbart: beskär (520, 1000)–(1360,
2060), vrid 270° så att norr är upp, förstora 1,6×. I den bilden ligger
västra ytterväggen vid x ≈ 165 px och symbolrutans väggar vid 570/680 px
(→ 69 px/m i tvärled); norra ytterväggen vid y ≈ 55 px och den genomgående
väggen vid 850 px (→ 63,6 px/m i längdled, N 12,5). Avlästa linjer:

| Linje | px | m | Läsning |
|---|---|---|---|
| dubbellinjeritad ruta | x 300–375, y 410–690 | x 2,0–3,0, N 5,6–10,0 | sluten volym, inte tjock vägg |
| tvärlinje N 10 | x 225–375 vid y 690 | x 0,9–3,0 | WC-V:s nordvägg; börjar 0,9 m från västväggen |
| WC-V:s östvägg | x 375, y 690–740 och 800–850 | x 3,0; hål N 10,8–11,7 | dörren mot lobbyn |
| symbolrutans fot | y 735 | N 10,7 | gräns mot cellen (Ö-toaletten) |
| ingen linje x 5,9 mellan y 185 och 360 | — | N 2,0–4,8 | uppehållsrummet fortsätter österut |

Tvärled vilar fortfarande på bredden 21 m (`ASSUMED_SCALE`); blir bredden
en annan skalar allt i x med den. Uppehållsrummets storlek i spelet beror
alltså på två saker: läsningen ovan (rättad) och husbredden (olöst).

### Inomhusläsbarhet — kameran, inte rummen

Product Owner 2026-09-03: "spelaren hamnar bakom väggar, man ser inte vart
man går". Enligt `CLAUDE.md` får inga väggar, dörrar eller rum flyttas för
att lösa ett kameraproblem, så det är bilden som ger vika:

- **Toning.** Varje inre väggbit (`klubb.vaggar`, `entrehall.vaggar`) och
  sluten volym byggs som ett eget nät med sitt fotavtryck. Den bit vars
  fotavtryck (+0,30 m marginal) skär sträckan kamera → spelare ritas med
  alfa 0,22 i ett andra pass (`v3dTonas`). Sträckan slutar 0,35 m före
  spelaren så att väggen hon står intill inte tonas.
- **Kameran** knuffas ut ur slutna volymer (toaletter, schakt, servicerum)
  och lyfts när den kläms mot ytterväggen närmare än 2,0 m från spelaren —
  vid entrén står hon 1,35 m innanför gaveln — så att man ser henne och
  rummet framför henne uppifrån i stället för hennes nacke.
- **Roblox:** samma regel. Anläggningsbygget sätter attributet
  `Genomsiktlig` på varje inre väggbit och sluten volym; klientmodulen
  `src/client/Genomsikt.luau` tonar (LocalTransparencyModifier 0,78) de
  delar vars fotavtryck skär sträckan kamera → karaktär, med samma
  marginaler. Beslutsfunktionen är ren och provas i
  `tests/genomsikt.spec.luau`; att attributet finns på alla inre delar
  provas i `bygge.spec`. `NOT TESTED IN ROBLOX STUDIO`.
- Bevis (webb, Playwright/SwiftShader): lobbyn med blicken österut — WC-V:s
  vägg tonad, spelaren synlig; teorisalen med kameran utanför sydväggen —
  väggen tonad; entrén — kameran lyft, spelaren och vindfånget synliga.

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
| Entrédelens väggar segment för segment — bara källspårade | `entrehall.vaggar`: 3 WALL (toaletterna) + 1 GLASS (receptionen); 14 segment återkallade i `ingaVaggar` | `PLAN` + `FOTO` + PO (Spatial Canon v2); docs/F02-RIDHUS-ENTRE-AUDIT.md |
| Entrén, receptionen, två toaletter med namn; den kryssade rutan som namnlöst slutet `schakt`; OPEN_AREA `ridhus_open_entrance_hall` | `entrehall.rum`, `entrehall.oppna`, `entrehall.ingaVaggar` | `PLAN` + `[enligt Tobias]` + PO; schaktets funktion `REFERENCE GAP` |
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
   väggspåret och halvväggen; var pentryt ligger. I ridhuset: vad som finns
   bakom receptionens glas, var HWC:n och ombytet (Bild 3–5) ligger — de
   byggs INTE som rum (Spatial Canon v2: en funktion är inget väggbevis),
   och vad den kryssade rutan är (den heter `schakt` i datan, utan etikett,
   och får inte kallas hiss förrän belägg eller produktägarbeslut finns).
5. **Dörrar** som planen inte visar: Ö-toaletten, det lilla rummet, den
   namnlösa volymens ingång; ridhusets två toaletter och schaktet.
   Receptionsglasets exakta väderstreck och rummets övriga avgränsning
   (`ridhus_reception_glass`: GEOMETRY_REFERENCE_GAP); huvudentréns läge —
   plan 2,2–3,8, "här är du" mot norra gaveln, fasad 9 m (CONTRADICTION).
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
