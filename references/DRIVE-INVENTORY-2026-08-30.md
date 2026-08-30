# Kanonisk referensinventering — Drive-mapparna

Datum: 2026-08-30
Metod: listad via Drive-API, **dedupliceras på titel + filstorlek**, och det
som faktiskt granskats är visuellt öppnat — inte klassat på mappnamn.

> **Status: PÅBÖRJAD, INTE KLAR.** Omnejd är helt genomgången. Byggnaden är
> granskad till 14 av 19. Ridhusets tre nyckelbilder och sex av Stallhusets är
> sedda och migrerade. Raderna nedan säger uttryckligen vilka jag har SETT och
> vilka jag bara har metadata om.

## Dubbletterna

Varje mapp innehåller **exakt två uppladdningar av samma material**: en
2026-08-27 och en 2026-08-29, med identiska filnamn och identiska filstorlekar.
Nyare kopian gäller; den äldre är dubblett.

| Mapp | Filer totalt | Unika | Dubbletter |
|---|---|---|---|
| Omnejd | 6 | **3** | 3 |
| Byggnaden | 38 | **19** | 19 |
| Stallhuset | ~40 | ~20 | ~20 |
| Ridhuset | bilder + **8 filmer** | — | — |

## Omnejd — genomgången och migrerad

Mapp-ID `1RInJ-zjFT9dbMdxzyZPj4TmXlzJ7xIv-`

| I repot | Ur Drive | Fil-ID | Vad den visar (sett) |
|---|---|---|---|
| `references/omnejd/banan-01-fran-grusvagen.jpg` | `IMG_0163` | `175aYWOlCwR8ayGkX7bUtuE6xCghUqfQu` | Uteridbanan från grusvägen nedanför. Slänt upp, trästaket, belysningsmast, röd bod vid banans bortre kant |
| `references/omnejd/banan-02-rampen.jpg` | `IMG_0164` | `1qv4b8z_2qi0ccL7S_7ggvnLThRBTTUVa` | Samma bana, med **betongrampen** upp från grusvägen i förgrunden |
| `references/omnejd/banan-03-mot-hagarna.jpg` | `IMG_0165` | `1USBY-4_Vf9di3XmflP50Os9CqQOtZmAr` | Banan mot hagarna, flera belysningsmaster, hästar, staplade torvbalar |

### Vad de tre avgör — och det är ett P0-fynd

**Uteridbanan ligger UPPHÖJD.** Alla tre bilderna visar samma sak: en
**grässlänt** upp från grusvägen till banans nivå, och i `banan-02` en
**betongramp** upp. Banans sandyta ligger tydligt ovanför omgivande mark.

`references/SITEPLAN.md` säger *"Marknivå: plant över hela anläggningen."*

`[KNOWN MISMATCH]` **Marknivån.** Spelet bygger tomten platt. Verkligheten har
en nivåskillnad mellan grusvägen och banan, och den syns i varje bild.

Övrigt som är direkt observerbart och **VERIFIED**:

- **Staketet runt banan** består av tre olika saker, inte tre likadana reglar:

  1. EN kraftig liggande **toppregel** av trä.
  2. **Eltråd** på svarta isolatorer under den — tunna mörka linjer, inte virke.
  3. En grov liggande **syll i marknivå** längs sandkanten, som håller banans
     sand på plats.

  > **RÄTTELSE.** Först skrev jag här *"trästolpar med tre liggande reglar"*.
  > Det var en avläsning gjord på en nedskalad bild, och den höll inte. En
  > beskuren avläsning av den närmaste stolpen i `banan-01` (2,4x) visar tre
  > svarta isolatorer på stolpen, två tunna trådlinjer och syllen. En avläsning
  > av `banan-02` såg mittemellan ut att visa två träreglar — det var det
  > bortre staketets toppregel sedd genom det närmaste.
  >
  > Läxan är densamma som med hästgången: ett påstående som ser mätt ut är
  > inte mätt förrän det gjorts på tillräckligt många pixlar, och från mer än
  > en vinkel.
- **Belysningsmaster**: höga grå/silverfärgade stolpar, flera runt banan.
  Armaturen sitter **dubbel på en tvärarm** — tydligast på den närmaste
  masten i `banan-03`.

  > **RÄTTELSE.** Den här raden sade först *"Spelet har inga."* Det var fel,
  > och felet var mitt: jag skrev det utan att läsa `ANL.props`. Webben hade
  > redan tre master (`{typ:"mast"}` i `src/site.js`), ritade som en 7,5 m
  > stolpe med ett enkelt huvud. Det som verkligen saknades var dels den
  > dubbla armaturen, dels master i Roblox över huvud taget. Den verkliga
  > bristen var alltså en annan än den jag först påstod.

- **Röd bod vid banans bortre kant**, rött tak och öppen förstukvist.
- **Betongplattan/rampen** — spelet har redan `{typ:"betong", rekt:{x:170, y:100, w:6, h:5}}`
  "betongplattan vid uppgången". Den är alltså rätt sak på ungefär rätt plats.
- **Torvbalar** (RS Mustang) staplade utomhus vid banan.

`[REFERENCE GAP]` Ingen av de tre visar banans mått eller dess läge relativt
byggnaderna. Placeringen måste fortfarande komma ur satellit.

## Ridhuset — de tre nyckelbilderna migrerade

Mapp-ID `1N3umwQVcuZ69Xxh1Rv4flMAkpIRHVGmj`

| I repot | Ur Drive | Fil-ID | Sett |
|---|---|---|---|
| `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg` | `IMG_0179` | `1dJratW5hQ2g128lypzhPFbxeSxbLUbhu` | Ja |
| `references/buildings/ridhus/ridhus-inne-02-langsidan.jpg` | `IMG_0183` | `1Anp0_PYPWZr9RAeHZ0rZQVLGpDSCOKHI` | Ja |
| `references/buildings/ridhus/ridhus-inne-03-baset-vid-E.jpg` | `IMG_0198` | `1gq6KdDtYxod3C9EIJ4J2NW3JNQ77ermp` | Ja |

Fynden står i `audits/GATE-F01-INTERIOR-REAUDIT-2026-08-30.md`.

### Filmerna — upstream, inte build-accessible

Åtta `.MOV` på 23–99 MB: `IMG_0169`, `0185`, `0188`, `0189`, `0191`, `0192`,
`0195`, `0196`.

`[DRIVE-ONLY]` De går inte att hämta genom det här gränssnittet — en 99 MB
film blir för stor som base64. **Ingen implementation får vila på dem** förrän
någon extraherar nyckelbildrutor och lägger dem i repot. `IMG_0191.MOV` är den
som pekas ut som ridhusets filmkälla.

## Stallhuset — sex sedda, resten listad

Mapp-ID `1gzcJz-UB78POfvZOXvMP_KNdnfNFJgE0`

| I repot | Ur Drive | Sett | Vad |
|---|---|---|---|
| `references/plans/stall-plan1-utrymning-rak.jpg` | `IMG_0168` | Ja | Utrymningsplan Plan 1, **rakt framifrån** — bättre än repots tidigare |
| `references/buildings/stall/stall-entre-15-dorren.jpg` | `IMG_0132` | Ja | Entrédörren i närbild |
| — | `IMG_0145`, `0149`, `0161`, `0162` | Ja | **Stallgång**: boxar på båda sidor, grå metallfronter och galler, träbalkar, marksten |

Klassificeringen i issue #23 är kontrollerad och stämmer: `0159–0162` är stall,
inte ridhus.

`[EJ GRANSKAT]` Resterande ~14 unika bilder i mappen.

## Byggnaden — 14 av 19 granskade

Mapp-ID `1cmyTQ_9AVjAaKlozWE2-lKsMxGRgVaPB`. 19 unika: `IMG_0064`–`0077`,
`IMG_0126`–`0131`. Sedda: `0064`–`0074`, `0126`, `0129`, `0131`.

Trots mappnamnet handlar de flesta om **ridhusets utsida och omgivningen**,
inte om förbindelsen mellan husen. Mappnamn är inte evidens, och det bekräftas
här.

### Migrerat

| I repot | Ur Drive | Vad (sett) |
|---|---|---|
| `buildings/ridhus/ridhus-gavel-04-statrappan.jpg` | `IMG_0064` | Ridhusets gavel med **rak utvändig ståltrappa** upp till en balkong och dörr på övre plan, valvfönster, och till vänster en lägre röd länga med **två entréer under vita skärmtak** |
| `buildings/ridhus/ridhus-langsida-01-skylten.jpg` | `IMG_0070` | Långsidan med **UBRF-skylten** monterad på plåten, handikappskylt, skärmtak i ena änden, grusväg längs huset |
| `buildings/ridhus/ridhus-langsida-02-trappan.jpg` | `IMG_0072` | Långsidan: **ljus betongsockel** i hela längden, mörk dörr med **utvändig ståltrappa och avsats**, vitt **ventilationsgaller** |
| `omnejd/omnejd-01-roda-boden.jpg` | `IMG_0073` | Fristående **liten röd bod** med mörkt plåttak och två små fönster, vid grusvägen, med container bredvid |
| `omnejd/omnejd-02-sandladan-trahastarna.jpg` | `IMG_0126` | **Sandlåda med två snidade trähästar**, kantad med gatsten, vid parkeringen |
| `omnejd/omnejd-03-garden-mellan-husen.jpg` | `IMG_0129` | **Gården mellan husen**: gräs, picknickbord och bänkar, stallets långsida med valvfönster och **huvraden på nocken** |
| `omnejd/omnejd-04-forstukvisten-och-spiraltrappan.jpg` | `IMG_0131` | Stallets västsida: **förstukvisten** med vitt ribbräcke och ockragul dörr, picknickbord på grus, och **spiraltrappan** på klubbgaveln i bakgrunden |

### Vad de avgör

**Ridhusets gavel har en RAK utvändig ståltrappa** upp till en dörr på övre
plan, med balkong. Det är byggt i spelet (`v3dRidhusYttre`, "Den utvändiga
ståltrappan"). `VERIFIED`

**Spiraltrappan sitter på STALLETS klubbgavel**, inte på ridhusets. `IMG_0131`
visar den igen, tillsammans med förstukvisten. Det är tredje oberoende bilden
som visar den. `VERIFIED`

Det löser sannolikt tvisten om "frontfasaden": **det finns en rak ståltrappa
och en spiraltrappa på anläggningen, men på olika hus.** Beskrivningen i
`GOOGLE-MAPS-FRONT-2026-08-30.md` — rak/diagonal metalltrappa, övre dörr,
entréer under skärmtak — stämmer med **ridhusets gavel**, som är byggd så.

**Stallets huvrad är separata huvar.** `IMG_0129` visar dem tydligt uppifrån
gården: fristående fyrkantiga huvar med platta hattar, en rad längs nocken.
`VERIFIED` — och det motsäger påståendet att de skulle vara en sammanhängande
ventilationsrad.

**Gården mellan husen är gräs med picknickbord och bänkar.** `VERIFIED` —
spelet har picknickborden.

**Ridhusets långsida har en ljus betongsockel** i hela längden, UBRF-skylten
monterad på plåten, ett vitt ventilationsgaller och en utvändig ståltrappa med
avsats till en dörr. `VERIFIED`

### Nytt som spelet saknar

| Vad | Var | Klass |
|---|---|---|
| **Sandlådan med två snidade trähästar**, kantad med gatsten | vid parkeringen | `VERIFIED` — finns inte i spelet |
| Belysningsmasternas **dubbla armatur** | se `banan-03` | `VERIFIED` — **åtgärdad**, `BANOMRADE.mast` |
| Staketets **uppbyggnad** (toppregel + eltråd + sandsyll) | se `banan-01` | `VERIFIED` — **åtgärdad**, `BANOMRADE.staket` |
| Grinden in till uteridbanan | — | `REFERENCE GAP` — se nedan |
| Torvbalarna vid banan | se `banan-03` | `VERIFIED` — **åtgärdad**, `{typ:"torvbalar"}` |
| Staket och belysning **i Roblox** | — | **åtgärdad** — `byggStaket`/`byggMaster` |
| Marknivåskillnaden upp till banan | se Omnejd | `KNOWN MISMATCH` — **kvarstår**, se nedan |

`[EJ GRANSKAT]` `IMG_0075`, `0076`, `0077`, `0127`, `0128`, `0130`.

### `[REFERENCE GAP]` Ingen grind syns till uteridbanan

Staketet är en sluten kollisionsloop i `src/world.js`, och `navVag` hittar
**ingen väg** från spelarens startpunkt in på uteridbanan. I dag spelar det
ingen roll: uteridbanan är en egen scen (`G.plats === "utebana"`), så man
byter scen i stället för att gå in. Men en ridbana har en grind i
verkligheten, och ingen av de tre Omnejd-bilderna visar var den sitter.

Den gissas inte fram. Om gångläget någon gång ska kunna leda en häst ut på
banan behövs antingen ett foto som visar grinden eller Tobias besked om var
den sitter. Samma sorts fynd som sargens grind i ridhuset — skillnaden är att
den var en aktiv blockerare och den här ännu inte är det.

### Domarkuren stod inne i ridbanan

Ett fynd som inte kom ur Drive utan ur att banområdet mättes för första
gången. `domarkur` låg på x 184..188,5 / y 148..151,5 — **helt innanför
uteridbanans staket** (x 176..196 / y 119..159). En byggnad mitt i banan man
rider på. Ingen källa har någonsin sagt det; läget hade bara aldrig prövats
mot staketrektangeln.

`banan-01` och `-02` visar boden **utanför** banan, bortom staketet och upp
mot trädridån. Den är flyttad dit. `[ASSUMPTION]` vilken kortsida — fotona
avgör bara att den ligger bortom banan sett från vägen.

`roblox/tests/geometri.spec.luau` har nu ett test som räknar fram varje
ridbana ur staket + sandmark och kontrollerar att ingen byggnad överlappar
den. Det testet är kört mot det gamla läget och **föll** där, så det mäter
verkligen det det påstår.

## Vad som gäller härnäst

1. Granska `Byggnaden` visuellt — den kan avgöra förbindelsefrågan.
2. Granska resten av `Stallhuset`.
3. Nyckelbildrutor ur ridhusfilmerna, om någon kan extrahera dem.
4. Först därefter: rätta siteplan, volymer och interiörer.
