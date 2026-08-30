# UBRF — Studio QA

> **Genomförd 2026-08-30: 11/11 vyer PASS, gångvägen PASS.**
> Gate F01 är `HUMAN_STUDIO_ACCEPTED / CLOSED`. En observation noterad —
> stallets interiör känns lite mörk — klassad som icke-blockerande polish.
>
> Listan står kvar och används igen efter varje ändring som rör byggnaderna.

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

### 4. `banan` — sand, sarg och porten vid A

**Ska synas:** ridbanan söderut från norra kortsidan.
**Referens:** `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg`.
**Kontrollera:**
- banans proportioner läser som 20 × 60
- sanden **dovt brungrå**, inte ljus beige och inte orange
- sargen ljus med mörkt sockelband
- porten vid A är ett **gap** i norra kortsidan, inte en vägg
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
