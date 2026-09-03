# F02-B — Inredningsmatris: verifierad inredning, utrustning och material

Status: `READY_FOR_CHATGPT_REVIEW`. Bas `a21d6ab` (F02-A). Branch
`claude/f02-b-interior-furnishing`.

F02-A:s topologi är **orörd**. Rumsgränser, väggar, öppningar, entréer,
läktarens läge och djup, C-blocket, domarbåset och exteriören står som i
`a21d6ab`. Det som F02-B ändrar är vad som står, hänger och lyser inne i de
rummen — och det som stod där utan källa.

Klasser: `VERIFIED` (i granskad bild/film) · `FOTO` (i bild som inte granskats
av produktägaren) · `DERIVED` (läget följer av bild + plan) · `ASSUMPTION`
(läget inom rummet är valt; att objektet finns är belagt) · `REFERENCE GAP` ·
`CONTRADICTION`. Per objekt står klassen för *att det finns* i `klass` och
för *var det står* i `lage` i `src/inredning.js`.

## Delad sanning

`src/inredning.js` är den enda listan. Varje post: `id`, `rum`, `typ`, `pos`,
`rikt`, `matt`, `farg`, `kalla`, `klass`, `lage`, `kolliderar`. Webben ritar
den (`v3dInredning` i `src/varld3d.js`, kartan och målarvyn i `src/world.js`)
och kolliderar mot den (`vandringKollision`); `tools/exportera-geometri.js`
skriver den till `UBRFKomplex.luau`, och Roblox bygger den
(`byggInredning` i `roblox/buildings/Anlaggningen.luau`) med källa och klass
som attribut på varje del. Fotavtrycket räknas med samma regel på båda
ytorna (`inredningRekt` ↔ `Geometri.inredningRekt`); läktarens rader med
samma regel (`laktarRader` ↔ `Geometri.laktarRader`).

Renderingen skiljer sig: webben bygger en soffa av sits, rygg och armstöd,
Roblox av två lådor. Läge, mått, färg, typ och källa är samma tal.

## Fas 1–2: audit av det som fanns, och vad som togs bort

| objekt | var | klass efter audit | åtgärd |
|---|---|---|---|
| Läktarens solida mörkbetsade brädfront + ljus kappregel | webb + Roblox | **återkallad** av `references/buildings/ridhus/INTERIOR-MATRIS.md` § 2 (byggd på en beskuren förgrund av -01); kappregeln `REFERENCE GAP` | **borttagen** på båda ytorna; `IDENTITET.ridhus.laktarfront`, `laktare.frontTopp/kappH` borta ur datan |
| Läktarens plana plankdäck | webb + Roblox | matrisen § 2: däcket är gångbräda + stegade rader, inte ett plant däck | **ersatt** av gångbräda + tre bänkrader |
| Räcke längs läktarens framkant | webb | ingen källa; -14 visar inget räcke | **borttaget** |
| Tre orange stolar utspridda på däcket | webb | ingen källa för lägena; -40 visar två orange skalstolar *bakom domarboden* | **borttagna**; två stolar bakom boden ur -40 (`FOTO`, `DERIVED`) |
| Två speglar på y 19 och 37, panelsidan | webb (`RIDHUSINNE.speglar`) | ingen källa för antal eller läge; bilderna visar EN spegel vid B och två på kortsidan vid A | **borttagna**; ersatta av `spegel_B`, `spegel_A_v`, `spegel_A_o` |
| Banderollskena längs 80 % av panelväggen | webb | ingen källa | **borttagen** |
| "Hinderförrådet" — sju bommar och fyra koner vid södra gaveln | webb (målarvyn) | handskrivna koordinater; bilderna sätter upplaget på läktardäckets södra ände | **borttaget**; ersatt av `laktare_bommar`, `laktare_hinderstod`, `laktare_bokstavsstall` |
| Storsäck + brandsläckare mitt i stallgången | webb (målarvyn) | handskrivna koordinater, ingen bild | **borttagna** |
| Nio LODRÄTA spjälor per boxfront | webb (målarvyn) | motsäger den rättade läsningen (fem vågräta reglar, stall-inne-05) | **rättat** till fem vågräta ur `IDENTITET.stall.boxfront` |
| 180°-vridning av dressyrbokstäverna | webb (målarvyn) | dubblett — vridningen ligger i tabellen sedan tidigare; A stod i norr här och i söder i WebGL | **rättat**; bokstäverna läses rakt ur tabellen |
| Lysrörsrader i ridhuset | webb-literal | `VERIFIED` att de finns (-11, -14, -31); delning `REFERENCE GAP` | flyttade till `RIDHUSINNE.lysror` och byggda i Roblox också |
| Hinder, koner, uppsittningspall på banan | webb-only | "står framme mellan lektionerna" ur interiörfotona; lägena `ASSUMPTION` (oförändrat) | exporterade och byggda i Roblox för paritet; lägena är inte ändrade och står som `ASSUMPTION` |
| Elon-dynorna | webb-only | -07: lösa dynor på översta raden (`FOTO`) | flyttade till översta bänkraden, byggda i Roblox också |
| Whiteboarden i gång A | webb | ingen bild av en whiteboard i gången; den är ett spelelement (schemat) | **oförändrad** — spelmekanik utanför F02-B; noterad som `ASSUMPTION` |
| Namnskyltar, hästhuvuden, rosetter på boxarna | webb | spelelement (hästarna som individer) | **oförändrade** — utanför F02-B |

## Fas 3–5: det som byggts, per zon

### Stallhuset — uppehållsrummet

| | |
|---|---|
| Källor | `stall-inne-01-uppehallsrummet.jpg` (IMG_0134); `DRIVE-INVENTORY-2026-08-30.md` |
| Bilden bevisar | två svarta skinnsoffor i vinkel kring två låga svarta bord, rosa träponny med riktig mörk sadel, rund väggklocka, krukväxt, sex inramade hästfoton på pärlspont, valvfönster mot en röd fasad, grå betonggolv |
| Förut | rummet var tomt (F02-A byggde bara väggar och etikett) |
| Ändrat | `uppehall_soffa_v/_s`, `uppehall_bord_1/2`, `uppehall_ponny`, `uppehall_klocka`, `uppehall_vaxt`, `uppehall_fotovagg` |
| Läge | valvfönstren i västväggen sitter i fasaden 2,6 och 8,6 m från gaveln (y 67,35 och 61,35); soffgruppen läggs vid det södra. Att möblerna finns: `VERIFIED`. Var i rummet: `ASSUMPTION` |
| REFERENCE GAP | var i rummet kameran stod; vilket valvfönster gruppen står vid |
| Paritet | webb 3D + karta + målarvy; Roblox `Inredning uppehall_*`; kollision på båda |

### Stallhuset — pentryt: INTE placerat

`stall-inne-02-pentryt.jpg` visar ett pentry (kubhylla, mikro, kyl, bord med
två stolar) i ett hörn med **valvfönster och runt fönster**. I den låsta
fasaden sitter de runda fönstren på norra gaveln 9,8 och 13,0 m från
västväggen — i F02-A:s plan ligger det i passagen/teorisalen, inte i
uppehållsrummet, och inget hörn i planen har både ett valvfönster och ett
runt fönster. `references/buildings/stall/INTERIOR-MATRIS.md` säger redan
"inte placerat". **`REFERENCE GAP` + `CONTRADICTION` (fasad mot plan) —
pentryt byggs inte.** Testet i `geometri.spec.luau` förbjuder ett
`pentry`-objekt tills det kan placeras.

### Stallhuset — teorisalen

| | |
|---|---|
| Källor | `stall-inne-04-teorisalen.jpg` (IMG_0138) |
| Bilden bevisar | bordsblock i björk med vita stolar på träben, två whiteboards på fondväggen, svart kontorsstol, träskåp med mikro, kartonger med utrustning, två inramade anatomiplanscher, valvfönster på ena långväggen, två långa lysrörsarmaturer, perforerad spiralkanal och grått rör i taket, pärlspont, betonggolv |
| Förut | tomt |
| Ändrat | `teori_whiteboard_1/2`, `teori_bord_1..3`, `teori_stol_1..10`, `teori_skap_mikro`, `teori_plansch_1/2`, `teori_kartong_1..3`, `teori_lysror_1/2`, `teori_ventkanal` |
| Läge | `DERIVED`: rummets enda yttervägg i planen är norra gaveln → fönstren där → kameran tittar österut → whiteboards på östväggen, planscher och kartonger på sydväggen, skåpet i sydöstra hörnet |
| REFERENCE GAP | exakt antal stolar och bord (bilden beskär blocket); den svarta kontorsstolen och det hopfällda bordet byggs inte; gaveln har i fasaden valvfönster med hög bröstning (z0 2,6) — bildens låga valvfönster stämmer inte med fasaden: `CONTRADICTION`, fasaden låst, rapporterad |
| Paritet | båda ytorna; borden, stolarna, skåpet och kartongerna kolliderar |

### Stallhuset — sadelkammaren

| | |
|---|---|
| Källor | `stall-inne-03-sadelkammaren.jpg` (IMG_0137) |
| Bilden bevisar | **inga sadelbockar i bild**: säkerhetsvästar (marin, svart, rosa) på krokrader längs vänstra väggen, vit öppen hylla full av ridstövlar och gummistövlar till höger, grå ståldörr med fönster och skylten "Teorisal" rakt fram, pärlspont, betonggolv |
| Förut | tomt |
| Ändrat | `sadel_vastkrokar` (västväggen), `sadel_stovelhylla` (fristående mitt emot, så att bildens smala passage uppstår) |
| Läge | `DERIVED` ur bilden + dörren från gång A i brandväggen (x 7,7–8,8): västväggen till vänster när man går in |
| REFERENCE GAP | sadlar, träns och övrig utrustning som ordern räknar upp syns inte i bilden och byggs inte; rummets östra del (x > 10) är tom |
| **Strukturell anmärkning (rapporterad, inte rättad)** | dörren "Teorisal" rakt fram leder norrut in i teorisalen. F02-A:s `teorisal_s` (y 64,35) har ingen öppning. F02-B rör inte topologin; dörren byggs inte |

### Stallhuset — gång A:s norra ände

| | |
|---|---|
| Källor | `stall-gang-05.jpg` m.fl. (IMG_0249/0250), `stall/KORT.md` § Gångens ändar |
| Bilden bevisar | grå metallport i vit vägg, rund klocka ovanför, grön utrymningsskylt bredvid |
| Förut | klockan byggd; skylten saknades |
| Ändrat | `gangA_exitskylt` vid brandväggens dörr mot klubbdelen (`DERIVED`) |
| REFERENCE GAP | sakerna som hänger på boxfronterna (sadlar, täcken, grimmor — `VERIFIED` att de finns, okänt per box) och foderhon: byggs inte |

### Ridhuset — läktaren

| | |
|---|---|
| Källor | `ridhus-inne-04` (nyckelbild), `-07`, `-14` (nyckelbild), `-43`, `-32`, `-41`; `INTERIOR-MATRIS.md` § 2 |
| Bilderna bevisar | sarg → plan gångbräda i mörkt trä bakom sargkrönet (`VERIFIED`) → stegade bänkrader i ljus furu i hela långsidans längd (`VERIFIED`); tre rader (`FOTO`); röda kantlister (-04); lösa svarta/blå dynor, en Elon (-07); ljus stående skivpanel bakom (`VERIFIED`, § 5) |
| Förut | plant plankdäck + solid mörk front + kappregel + räcke + tre orange stolar |
| Ändrat | `laktare.gangbrada` + `laktare.rader` i `src/site.js`; byggt ur `laktarRader` på båda ytorna; dynorna på översta raden; fronten, kappan, räcket och stolarna borta |
| Klass på talen | däckhöjd 0,80 `DERIVED` (-43); radernas stighöjd 0,30 och djup 0,80 `ASSUMPTION` — matrisen: `REFERENCE GAP` |
| REFERENCE GAP | stighöjd/djup; om raderna är tre eller fyra; vad som finns bakom raderna; gången bakom läktaren (-39) byggs inte |
| Paritet | båda ytorna, samma regel; test i `geometri.spec` (data) och `bygge.spec` (byggda delar, relationen "stiger bort från banan") |

### Ridhuset — hinderupplaget, returtunnan, stolarna bakom boden

| | |
|---|---|
| Källor | `ridhus-inne-21` (upplaget och bokstavsstället), `-23` (poler i högerkanten vid A), `-43` (returtunnan vid H), `-40` (två orange skalstolar bakom domarboden); granskning A § "hinderupplag i hörn" |
| Ändrat | `laktare_bommar` (7, regnbågsfärger), `laktare_hinderstod` (3), `laktare_bokstavsstall` (F R H V C K M A), `laktare_returtunna`, `laktare_stol_1/2` |
| Läge | på läktardäcket bakom sargen; upplaget vid södra änden (A/K-hörnet) `DERIVED` ur -21 + -23; tunnan vid H `DERIVED` ur -43; stolarna bakom boden `DERIVED` ur -40 |
| REFERENCE GAP | ett andra upplag i "klubbhörnet" vid C (-44) byggs inte — bilden är för nära för att placera; bordsraden bakom boden (-40) byggs inte |

### Ridhuset — speglarna

| | |
|---|---|
| Källor | vid B: `-34`, `-19` (nyckelbild), `-31` (nyckelbild), `IMG_0189-f05` (nyckelbild); vid A: `-23` (nyckelbild) |
| Bilderna bevisar | EN spegel i två rutor, brun träram, direkt ovanpå sargen vid B (`VERIFIED`); TVÅ speglar i träram på den vita kortsidan vid A, en på var sida om dubbeldörren (`VERIFIED`) |
| Förut | två speglar på y 19 och 37 utan källa; inga i Roblox |
| Ändrat | `spegel_B` på panelsidan vid B (läget `VERIFIED`), `spegel_A_v/_o` på sydgaveln ±5,2 m från dörren (`DERIVED` ur -23) |
| **CONTRADICTION** | -23 visar A-väggens speglar direkt ovanför sargen; i F02-A ligger sydgaveln 5,7 m söder om banans sarg (`entre 11,5 → bana y 5,68`). Speglarna hänger på gaveln, alltså 5,7 m bakom sargen. Rapporterad; topologin rörs inte |
| Paritet | båda ytorna (Roblox: glas med reflektans i träram) |

### Ridhuset — skåpkorridoren och entrén

| | |
|---|---|
| Källor | `ridhus-klubb-01` (nyckelbild), `IMG_0169-f02/f03` (nyckelbilder), `IMG_0268-r03/r05/r12/r15`, `ridhus-klubb-14` |
| Bilderna bevisar | höga smala plåtskåp i grått med enstaka röda och mörkgrå dörrar längs den vägg man har till vänster på väg mot valvfönstret (västväggen); vita trästolar med rött mönstrat tyg kring ett litet bord mitt i gången; bänk med ridstövlar under valvfönstret; i entrén en bänk/låda under fönstret mot parkeringen, full av jackor och stövlar |
| Ändrat | `skap_v_1..n` — skåpbankar som fyller **västväggens slutna bitar** mellan F02-A:s öppningar (`DERIVED` ur samma vägglista som kollisionen); `skap_bord`, `skap_stol_1/2` (`ASSUMPTION` mitt i gången); `skap_stovelbank` under fönstret i norr; `entre_bank` under entréfönstret |
| **Strukturell anmärkning (rapporterad, inte rättad)** | bildens högra sida är en bröstningsvägg med **fyra glaspartier** in mot rummet innanför. F02-A läste `skap_o`:s fyra luckor som gångbara öppningar. Bilden talar för fönster, inte dörrar. Topologin rörs inte här |
| REFERENCE GAP | omklädningsrummen (röda/svarta, gräddvita, gröna skåp), toaletterna, duschen med grönt draperi: rummen är fotograferade men **inte placerade** (Bild 2–5 saknas i repot, `F02-INTERIOR-MATRIS.md`). Inredning där byggs inte. Klädhängarnas vägg i entrén syns inte i bild — bara bänken byggs |

### Ridhuset — banan, C-blocket, domarbåset, caféet

| zon | läge |
|---|---|
| Banan: sarg, panel, skyltar, fönsterband, tak, installationer | oförändrade från F02-A/F01 (`VERIFIED`/`ASSUMPTION` som förut). Lysrören delade. Hinder/koner/pall exporterade till Roblox |
| C-blocket: bänkar, två trappor, glasband, klocka, stjärna | oförändrade (`VERIFIED`, byggda i F01/F02-A) |
| Domarbåset | oförändrat; insidan `REFERENCE GAP`; bordsraden bakom (-40) byggs inte |
| Café Krubban | `ridhus-klubb-09` (nyckelbild) bevisar vita kvadratiska bord, grå perforerade plåtstolar, två runda pelarbord, värmepump, soffa. **Inget mått, ingen plan för övre plan** (`INTERIOR-MATRIS.md` § 8). Caféet är i webben en golvplatta bakom glasbandet, inte gångbart. **Byggs inte — `REFERENCE GAP`** (placeringen vore påhittad). Testet förbjuder `cafe_`-objekt |
| Reception, skåpförvaring, ombytesrum, HWC | `REFERENCE GAP` (F02-A: Bild 2–5 saknas) |

## Strukturella fynd att rapportera separat (F02-A-topologi, INTE rättade här)

1. **Sadelkammaren → teorisalen**: `stall-inne-03` visar en dörr "Teorisal" i
   sadelkammarens norra vägg; F02-A:s `teorisal_s` saknar öppning.
2. **Skåpkorridorens östvägg**: `ridhus-klubb-01` visar fyra glaspartier
   med bröstning där F02-A har fyra gångbara öppningar i `skap_o`.
3. **Sydgaveln vid A**: `ridhus-inne-23` visar väggen med speglarna direkt
   bakom sargen; F02-A har 5,7 m mellan sargen och gaveln.
4. **Teorisalens fönster**: bildens låga valvfönster mot fasadens
   valvfönster med 2,6 m bröstning på norra gaveln (fasaden låst).
5. **Pentryts fönsterpar** (runt + valv i ett hörn) finns inte i något hörn i
   plan + fasad.

## Tester (maskinkontrollerbart, inte visuell fidelity)

- `roblox/tests/geometri.spec.luau`: läktarens rader i datan (tre, stiger
  inåt, ryms på däcket), fronten och de sourcelösa speglarna borta ur datan;
  inredningens id unika, klasser i vokabulären, källa per objekt, varje objekt
  i sitt rum, rimliga mått, belagda objekt finns, förbjudna (pentry, café,
  reception) finns inte.
- `roblox/tests/bygge.spec.luau`: raderna byggda per sektion, fronten/kappan/
  däcket borta, raderna stiger bort från banan (relation på byggda delar),
  översta sitsen mot sargkrönet, dynorna i Roblox; varje inredningsobjekt
  byggt, i sitt rum, kollisionsparitet, källa och klass; hinder/koner/pall
  och lysrör i Roblox.
- Falsifierat (mutation → röd → återställt via cp): objekt hoppat över i
  byggaren; `laktarRader` tom; soffa flyttad ut ur rummet; soffa utan
  kollision; den gamla fronten återinförd. Alla fem gav rött.
- Webben: Playwright-render av tio vyer från ungefär referensbildernas håll
  (scratchpad `render-f02b.mjs`), kollisionsprov mot soffa, stövelhylla, bord,
  skåprad och stol: alla spärrar.

Testerna bevisar placering, paritet och att inget sourcelöst finns kvar. De
bevisar **inte** att rummen ser ut som UBRF — det avgör Tobias i
webbpreviewn och i Roblox Studio.

## Not tested

`NOT TESTED IN ROBLOX STUDIO`. Roblox-bygget är verifierat mot testbänken
(luau + stubbar) och mot koden, inte mot en skärm: material, ljus, glasets
reflektans och prestanda i Studio är overifierade.
