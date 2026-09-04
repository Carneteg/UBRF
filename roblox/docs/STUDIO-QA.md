# UBRF — Studio QA

**Det här är det enda dokument du behöver öppna för den visuella granskningen.**
Du behöver inte kunna kodbasen. Du behöver Roblox Studio och en halvtimme.

`STUDIO-KONTROLL.md` och `RIDHUS-STUDIO-CHECKLISTA.md` finns kvar som bakgrund
och detaljunderlag. Kvitteringen sker här.

## Kom igång

```bash
python3 tools/studio-paket.py
```

Klistra in **hela** `roblox/buildings/.studio/UBRF-klistra-in.luau` i Studio och
kör den **en gång**.

Bygget ska sluta med:

```
OK UBRF byggd: 8 byggnader, 12 dörrar, 4 boxrader, 6 gångytor, N objekt
```

De fyra första talen ska stämma exakt. `N` varierar med bygget och är **inget
godkännandekriterium** — vid senaste körningen utanför Studio blev det 2108.

Sedan öppnas panelen **UBRF QA** av sig själv. Den har:

`◀`  `▶`  vyns namn  `PASS`  `FEL`  `Återställ kameran`

Klicka dig igenom. Panelen går vidare av sig själv efter ett omdöme och skriver
en sammanfattning i Output som går att klistra in direkt i en rapport. Stängde
du den: skriv `UBRFQA()` i Command Bar.

**Vid FEL:** ta en skärmdump och spara den som `qa-<vynamn>-FEL.png`. Panelen
säger vilket filnamn den vill ha. Skriv vad du **såg** och **var** — inte vad du
tror orsakade det.

---

## De elva vyerna

### 1. `oversikt` — komplexet uppifrån

**Ska synas:** hela anläggningen ovanifrån.
**Referens:** satellitbilden, `references/site/SATELLIT-MATNING-2026-08-30.md`.
**Kontrollera:**
- två parallella huvudvolymer, **en** tvärgående förbindelse mellan dem
- mellanrummet delat i **två** gårdsytor
- ingen byggnad står i en annan
- skalan känns som UBRF, inte som en modelljärnväg

PASS / FEL · vid fel: `qa-oversikt-FEL.png`

### 2. `ankomsten` — så man kommer till UBRF

**Ska synas:** grusplanen mot de norra gavlarna, i ögonhöjd.
**Referens:** `references/buildings/stall/stall-gavel-06-silon.jpg`.
**Kontrollera:**
- ridhuset till höger, stallet till vänster
- husen läser som **ett komplex**, inte två fristående lador
- det går att förstå var man ska gå in

`REFERENCE GAP`: gavlarna ligger **inte** i liv — stallet skjuter fram. Att det
är åt det hållet är avgjort mot fotot. **Hur mycket** är inte avgjort, och ska
inte bedömas här. Ser förskjutningen orimlig ut: skriv det som en observation,
inte som ett fel.

PASS / FEL · vid fel: `qa-ankomsten-FEL.png`

### 3. `gardarna` — hästgången stänger gården

**Ska synas:** södra gårdsytan norrut, mot hästgången.
**Referens:** satellitmätningen; gången finns och ligger där, bredden är härledd.
**Kontrollera:**
- gården **stängs** av hästgången — ser du rakt igenom till nästa gårdsyta är
  förbindelsen fel byggd
- gången ser ut att gå att leda en häst genom

PASS / FEL · vid fel: `qa-gardarna-FEL.png`

### 4. `banan` — sand, sarg och spelets sargport (spelabstraktion)

**Ska synas:** ridbanan söderut från norra kortsidan.
**Referens:** `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg`.
**Kontrollera:**
- banans proportioner läser som 20 × 60
- sanden **dovt brungrå**, inte ljus beige och inte orange
- sargen ljus med mörkt sockelband
- gapet i norra sargens västra ände är SPELETS sargport — en `SPELABSTRAKTION`
  med gul genomskinlig markör (attribut `Klass`/`Fidelity`), **inte** verifierad
  UBRF-geometri: ingen bild visar en grind där, bredden är vald. Bedöm sargen,
  inte gapet
- inget flimmer mellan sand och sarg när du panorerar

PASS / FEL · vid fel: `qa-banan-FEL.png`

### 5. `sponsorvaggen` — panelen, skyltarna, fönsterbandet

**Ska synas:** långsidan med den rostbruna panelen.
**Referens:** `references/buildings/ridhus/ridhus-inne-02-langsidan.jpg`.
**Kontrollera:**
- panelen på **EN** långsida, inte båda
- den täcker **en del** av väggen, inte hela längden
- tonen dov gråbrun-mauve, inte mättat rödlila
- tre vita vågräta läkt på panelen
- sex sponsorskyltar **på panelen**, inte på den ljusa delen
- fönsterbandet löper **förbi** panelens stycke, med poster som syns som poster
- skyltarna ligger utanpå panelen, inte i dess plan

PASS / FEL · vid fel: `qa-sponsorvaggen-FEL.png`

### 6. `kortandan` — blocket vid C

**Ska synas:** kortändan med trappstegsblock, glasband, klocka och kompassros.
**Referens:** `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg`.
**Kontrollera:**
- trappstegsblock på sockel, flera rader **över** sargkrönet
- två trappor upp, med räcken
- glasbandet i **segment**, brutet av trapporna — inte en obruten remsa
- vit vägg mellan bänkarnas ovankant och glasets underkant
- rund vit klocka **mellan** de två trapporna
- kompassros, linjeritad, **vänster** om vänstra trappan
- blocket möter sargkrönet utan att gå igenom det

PASS / FEL · vid fel: `qa-kortandan-FEL.png`

### 7. `domarbaset` — båset vid E

**Ska synas:** domarbåset sett från banan.
**Referens:** `references/buildings/ridhus/ridhus-inne-03-baset-vid-E.jpg`.
**Kontrollera:**
- båset står **utanför** sargen, på läktardäcket — **inte inne på banan**
- ingen del av båsets volym skjuter in över sargen
- upphöjt, i mörkt trä
- sadeltak med utskjutande takfot — inte en låda med lock
- trappa med räcke på **båda** sidor
- grön exit-skylt vid öppningen

PASS / FEL · vid fel: `qa-domarbaset-FEL.png`

### 8. `takstommen` — taket inifrån

**Ska synas:** takkonstruktionen sedd underifrån, från banan.
**Referens:** `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg`.
**Kontrollera:**
- takstolarna **mörkt gråbruna och nära neutrala** — INTE varmt limträ som
  stallets. En värmemask på referensen gav 35 kpx varma mot 517 kpx neutrala
- stålprofiler tvärs balkarna
- kabelstegar **med stegpinnar** — en slät låda läser som ännu en balk
- stora runda ventilationskanaler
- taket läser som konstruktion, inte som en platt skiva
- takfallen möter långsidesväggarna utan glipa och utan dubbla ytor

PASS / FEL · vid fel: `qa-takstommen-FEL.png`

### 9. `laktaren` — läktaren och grinden

**Ska synas:** läktarens gap och sargens grind mot hästgången.
**Referens:** `references/buildings/ridhus/ridhus-inne-02-langsidan.jpg`.
**Kontrollera:**
- läktaren har ett **gap** rakt fram
- sargen har en **grind** i det gapet — är sargen obruten går det inte att leda
  hästen ut på banan
- läktardäcket skär inte in i banan, och sargen går inte genom däcket

**Dokumenterad motsägelse, ska inte "lösas" här:** `-01`/`-02` visar en mörk
brädvägg som bangräns, `-03` en vit sarg med sittplatser bakom, på samma
långsida. Spelet bygger båda. Noteras, bedöms inte.

PASS / FEL · vid fel: `qa-laktaren-FEL.png`

### 10. `servicedelen` — stallets servicedel

**Ska synas:** spolspiltan, spånförrådet och dagern från gaveln.
**Referens:** `references/buildings/stall/stall-gang-*.jpg` och
`references/buildings/stall/INTERIOR-MATRIS.md`.
**Kontrollera:**
- båda serviceboxarna **öppna** mot gången — inte igenbommade rum
- ljusare servicegolv än gången
- dager från gavelöppningen, med exit-skylten ovanför
- det går att förstå att man kommit in i ett stall

PASS / FEL · vid fel: `qa-servicedelen-FEL.png`

### 11. `stallgangen` — gången och boxfronterna

**Ska synas:** gång A mot tvärkorridoren.
**Referens:** `references/buildings/stall/stall-gang-*.jpg`.
**Kontrollera:**
- boxar på båda sidor
- boxfronterna **antracit fyllning med galvad ram**, inte brunt trä
- **fem liggande reglar**, inte stående spjälor
- boxarnas proportioner läser som riktiga boxar att ha en häst i
- tvärkorridoren syns **hela vägen** tvärs huset

PASS / FEL · vid fel: `qa-stallgangen-FEL.png`

---

## Gångvägen — gör den till fots

Vyerna är stillbilder. Det här är det enda som prövar att anläggningen går att
**vara i**. Gå sträckan och tillbaka:

`ankomsten → stallet → hästgången → ridhuset → banan`

**Kontrollera:**
- inget osynligt hinder
- ingen del som sticker in i passagen
- dörrar och öppningar sitter där man förväntar sig dem
- man fastnar inte i en tröskel eller en sarg

PASS / FEL · vid fel: `qa-gangvagen-FEL.png`

---

## Inomhusläsbarhet — väggarna ska tona, inte rummen flytta

Gå in i stallets klubbdel och ridhusets entrédel till fots och vrid kameran
så att en vägg hamnar mellan kameran och karaktären.

**Ska synas:** väggbiten (eller den slutna volymen) blir halvgenomskinlig
medan den står i vägen och blir solid igen när kameran flyttas. Karaktären
ska aldrig försvinna helt bakom en inre vägg. Väggen karaktären själv står
intill ska INTE tona.

**Fynd:** en vägg som förblir solid med karaktären dold bakom den; en vägg
som tonar fast den inte står mellan kameran och karaktären; en vägg som
saknar attributet `Genomsiktlig` (välj den i Explorer och titta under
Attributes). Rör aldrig väggarna för att lösa det — det är
`Genomsikt.luau` som ska rättas.

## Ridhusets entrédel — Spatial Canon v2 (SCV2-03, RIDHUS-V1..V3)

Gå in genom huvudentrén (dubbeldörren under kvisten på västra långsidan)
till fots.

**Ska synas:** EN öppen hall — inga korridorer av rumslådor, inga
skåpkorridorväggar, ingen cellrad. Det enda som står i entrédelen är två
smala toaletter i nordvästra hörnet, den kryssade rutan (`schakt`, sluten
volym utan namn) och receptionens låga bröstning med glas ovanpå (Material
Glass, delen heter `Entrévägg reception_glas:1 glas`). Vyerna
`entrehallen` och `entrehallen_mot_banan` i Vyer.luau visar exakt vad som
förväntas.

**Ska gå att göra:** gå från dörren rakt ut i hallen, tvärs över den, och
söderut genom sargporten (markerad SPELABSTRAKTION) ut på banan — utan att
klippa, hoppa eller passera genom en vägg. Passagen får aldrig kännas som en
smal korridor.

**Fynd:** en vägg eller volym i entrédelen som saknar attributen
`CanonId`/`SourceId`/`Confidence`/`Primitiv`; en opak vägg med `CanonId`
`ridhus_reception_glass`; något som blockerar vägen dörr → hall → sargport;
en byggd del med något av de återkallade id:na (korridor_o, skap_v, skap_o,
cell_1–4, hall_n_v, hall_n_o, hall_nv_s, hall_mitt, hall_no, hall_no_s,
ostkorridor_v). Rör aldrig geometrin för att lösa det — det är datan i
`src/site.js` (`RIDHUSINNE.entrehall`) och kanonen som styr.

## Ridhusets C-trappor — gångbara nivåer (Product Owner 2026-09-03 17:16)

Gå in genom huvudentrén och fram till C-blockets västra ände (bänkblocket
under glasbandet, med stjärnan och klockan).

**Ska gå att göra:** kliva upp för SPELETS bänkradssteg (`Spelabstraktion
bankradsteg steg 1–6` — märkta klossar med gul markör; inte fidelity, inget
foto visar hur publiken kommer upp, senior review 2026-09-04 04:08) till
nedersta raden, upp för de fyra raderna, och från översta raden
vid klockväggen upp för VÄNSTRA trappan västerut (`Trappa c_trappa_v steg
1–9`) eller HÖGRA trappan österut (`Trappa c_trappa_o steg 1–9`) till övre
gången (`Övre gångens golv`, caféplanet 3,68 m) — utan hopp, utan att fastna
och utan att falla ner på banan. Vyerna `c_trapporna_fran_foten` och
`c_trapporna_fran_toppen` i Vyer.luau visar utgångslägena.

**Ska synas:** två raka lopp i mörkt trä LÄNGS gaveln med foten vid
klockväggen, vita snedställda sidostycken mot banan som bryter glasbandet
i tre fält (ridhus-inne-01), träräcken.

**Fynd:** ett steg karaktären inte kliver upp för; ett hål eller en
osynlig spärr i kedjan; att man kan komma upp i övre gången någon annanstans
än via trapporna; att övre gången saknar golv; ett trappsteg som saknar
attributen `CanonId`/`SourceId`/`Confidence`/`Primitiv` (= STAIR); en
`Spelabstraktion bankradsteg`-del som bär `CanonId` eller saknar
`Klass`/`Fidelity` (abstraktionen får aldrig se ut som verklighet). Rör aldrig
trapporna för hand — datan är `RIDHUSINNE.kortanda.trappor` (loppen) →
`RIDHUSINNE.trappor` (härledda STAIR-primitiver) i src/site.js, och stegen
räknas av `Geometri.trappsteg`.

## Visuell grind — reviewkamerorna (issue #78)

Samma arton vyer som webbens screenshot-pack (`qa/visual-gate/kameror.json`),
gruppen **Visuell grind** i `Vyer.lista()`: `STALL-ANKOMST` (exteriör, från gården), `STALL-ENTRE`, `STALL-UPPEHALL`, `STALL-UPPEHALL-SOFFA` (F02-B),
`STALL-TEORISAL`, `STALL-SADELKAMMARE`, `STALL-GANG-A`, `HASTPASSAGE`,
`RIDHUS-ENTRE`, `RIDHUS-SKAPKORRIDOR`, `ARENA-A`, `ARENA-C`, `LAKTARE`,
`C-BLOCK-OVRE`, och ur reviewn 2026-09-04 07:54: `STALL-KLUBBDORRAR`,
`RIDHUS-RECEPTION`, `RIDHUS-ENTRE-INNE`, `RIDHUS-LAKTARTRAPPA`. Kameran står som spelets tredjepersonskamera: 3,6 m bakom
figuren, 2,25 m över hennes golv (lyft när den kläms mot en vägg).

**Ska gå att göra:** `Vyer.ga("<ID>")` för var och en, och jämföra mot
referenserna som kameran listar i `kameror.json`. Varje kamera har ett
ramkontrakt (`ram` i `kameror.json`, `krav` i vyn): det som MÅSTE synas —
syns det inte är kameran fel ställd, inte bilden klar. Ta en skärmdump per ID med
samma namn som webbens — det är Roblox-halvan av reviewpaketet.

**Ska synas:** figuren (eller platsen hon står på, `figur` i vyn) ska vara
synlig från varje reviewkamera; det som står emellan ska tona
(`Genomsiktlig`). `tests/sikt.spec.luau` mäter samma sak mot bygget.

**Fynd:** figuren dold bakom något som inte tonar; en vy som inte matchar
webbens bild av samma ID (olika geometri = datan har glidit isär, kör
`tools/exportera-geometri.js`); en referens kameran pekar på som inte
stämmer med det byggda → skriv `MISMATCH` med vad i review-kommentaren.
Ingen visuell status sätts här av automatik; Studio-passet är Tobias.

## Vad som INTE är ett fynd

Osourcad möblering, kosmetisk polish och avancerad ljussättning. Att
stallgången saknar spånremsa, att boxarna saknar namnskyltar eller att ljuset
är platt — inget av det är vad gaten mäter.

## Vad som inte går att kvittera här

- **Hallens orientering** är `REFERENCE GAP`. Läktarens absoluta öst/väst är
  inte bevisad. Behövs en nordpil eller ett foto som visar läktaren och
  hästgångsdörren i samma bild.
- **Gavelförskjutningens storlek** är `REFERENCE GAP`.
- **Motsägelsen sarg kontra läktarfront** är dokumenterad, inte löst.

Hitta inte på något av dem. Ser något orimligt ut: skriv det som en
observation.

## När du är klar

Panelens sammanfattning i Output är rapporten. Klistra in den, och lägg till en
skärmdump per FEL.

Ett fel öppnar **en riktad fix** — inte ett nytt geometripass.
