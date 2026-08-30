# Kanonisk referensinventering — Drive-mapparna

Datum: 2026-08-30
Metod: listad via Drive-API, **dedupliceras på titel + filstorlek**, och det
som faktiskt granskats är visuellt öppnat — inte klassat på mappnamn.

> **Status: GENOMGÅNGEN.** Omnejd (3), Byggnaden (19) och Stallhuset (32) är
> alla visuellt öppnade, en och en. Kvar som `[DRIVE-ONLY]` är bara Ridhusets
> åtta filmer, som inte går att hämta genom det här gränssnittet.
>
> **RÄTTELSE AV ANTALET.** Den här filen sade först att Stallhuset hade
> "~20 unika". Det är fel: mappen har **32 unika** (`IMG_0132`–`0162` plus
> `IMG_0168`). Siffran var en uppskattning som skrevs som om den vore räknad.
> Antalet är nu listat ur Drive-API:t, inte gissat.

## Dubbletterna

Varje mapp innehåller **exakt två uppladdningar av samma material**: en
2026-08-27 och en 2026-08-29, med identiska filnamn och identiska filstorlekar.
Nyare kopian gäller; den äldre är dubblett.

| Mapp | Filer totalt | Unika | Dubbletter |
|---|---|---|---|
| Omnejd | 6 | **3** | 3 |
| Byggnaden | 38 | **19** | 19 |
| Stallhuset | 64 | **32** | 32 |
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

### Resten av mappen — nu granskad, 32 av 32

Mappen är stallets **insida**, och den delar sig i två tydliga halvor.

**Klubbdelen** (`IMG_0132`–`0144`)

| I repot | Ur Drive | Vad |
|---|---|---|
| `buildings/stall/stall-entre-16-runda-fonstren.jpg` | `IMG_0132` | Entrédörren: **ockragul** pardörr med **solfjäderformat överljus**, och **ett runt fönster på var sida** |
| `buildings/stall/stall-inne-01-uppehallsrummet.jpg` | `IMG_0134` | Uppehållsrum: vitmålad panel, svarta skinnsoffor, valvfönster **och** runt fönster, inramade foton, klocka, **rosa träklapphäst med sadel** |
| `buildings/stall/stall-inne-02-pentryt.jpg` | `IMG_0135` | **Pentry**: valvfönster, runt fönster, hyllkub med textilier, mikro, kyl, bord |
| `buildings/stall/stall-inne-03-sadelkammaren.jpg` | `IMG_0137` | Hyllor **fulla av ridstövlar** i tak, **täcken hängande** på rad |
| `buildings/stall/stall-inne-04-teorisalen.jpg` | `IMG_0138` | Teorisal: långbord i ljust trä, whiteboard med scheman, **anatomiplanscher**, runda fönster, lysrör |
| — | `IMG_0133`, `0136`, `0139`, `0140` | Fler vinklar av samma klubbrum: bokhylla, hjälmar på krokar, valvfönster, brandsläckare, färglära-plansch |
| — | `IMG_0141`–`0144` | **Två toaletter**, varav en tillgänglighetsanpassad med stödhandtag, plus dörrarna till dem |

**Stalldelen** (`IMG_0145`–`0162`)

| I repot | Ur Drive | Vad |
|---|---|---|
| `buildings/stall/stall-inne-05-stallgangen.jpg` | `IMG_0148` | Stallgången: **galvade boxfronter med lodräta galler** över **mörkt antracitfärgade heldelar**, **orangebruna limträbalkar**, synlig **korrugerad plåt** i taket, hängande lysrörsarmaturer, betonggolv |
| `buildings/stall/stall-inne-06-boxen-inifran.jpg` | `IMG_0150` | Inifrån en box: djup halmbädd, mörkgrå skivväggar |
| `buildings/stall/stall-inne-07-spolspiltan.jpg` | `IMG_0154` | **Spolspilta**: upphöjt räfflat golv med fall mot avlopp, varmvattenberedare och rörinstallation, slangfästen |
| `buildings/stall/stall-inne-08-breda-gangen.jpg` | `IMG_0156` | En **bred, hög inomhusgång** med grå betongväggar och ett **gallergrindsparti i bortre änden** |
| `buildings/stall/stall-inne-09-gangen-ut.jpg` | `IMG_0158` | Gångens ände med **dörr rakt ut i det fria**, städvagn, rörinstallation |
| — | `IMG_0145`–`0149`, `0151`–`0153`, `0155`, `0157`, `0159`–`0162` | Fler vinklar av samma gångar, boxar och spolspilta. Ingen av dem motsäger raderna ovan |

### Vad Stallhuset avgör

**Spelets rumslista stämmer.** `STALLINNE.rum` och `.service` har
uppehållsrum, teorisal, sadelkammare, spolspilta och spånförråd. Alla fem
finns på bild. `VERIFIED`

`[REFERENCE GAP]` **Pentryt saknas i spelet.** `IMG_0135` visar ett riktigt
kök i klubbdelen. Att det FINNS är `VERIFIED`; VAR det ligger i planen är det
inte. Det läggs inte in på gissning — utrymningsplanen får avgöra läget.

**Runda fönster (oxögon) hör till klubbdelen.** De syns i entrén, i
uppehållsrummet, i pentryt och i teorisalen. `VERIFIED`

**Stallgångens material** — galvade gallerfronter, mörka heldelar,
orangebruna limträbalkar, korrugerad plåt i taket — är samstämmigt över ett
dussin bildrutor. `VERIFIED`

Två av dem är nu **mätta** ur `stall-inne-05-stallgangen.jpg` och ligger i
`IDENTITET.stall.stallgang`: limträ **#C39575** och takplåt **#878783**.
Koden hade #9C4A32 och #D9DDE1 — balkarna lästes nästan svarta och taket som
ett platt vitt innertak.

`[REFERENCE GAP]` **Balkarnas täthet och dimension.** De byggs var fjärde
meter med snedstag, avläst ur `IMG_0249`/`0250` — bilder som varken finns i
repot eller är granskade av mig. Mot `stall-inne-05` läser de tyngre och
plattare än verkligheten, där plåten dominerar och balkarna är smalare
accenter. Färgen är rättad; **geometrin är inte rörd**, eftersom ett enda
nytt foto inte räcker för att bygga om något som vilar på två bilder jag inte
har sett.

`[REFERENCE GAP]` **Den breda gången i `IMG_0156`/`0157`.** Den är bred och
hög nog att leda en häst genom, och har en gallergrind i bortre änden. Den
skulle kunna vara hästgången mot ridhuset — men bilden visar inte vad den
mynnar i, och jag har inget som binder den till en plats i planen. Den
klassas därför INTE som hästgången. Att kalla den det vore precis samma fel
som när jag placerade hästgången i norränden på ett uteslutningsargument ur
min egen modell.

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

### De sex sista i Byggnaden — nu granskade

| I repot | Ur Drive | Vad |
|---|---|---|
| `buildings/ridhus/ridhus-langsida-03-dubbeldorren.jpg` | `IMG_0075` | Ridhusets långsida: **ljus pardörr** i den mörkröda plåten, ventilationsgaller högt uppe, svart list längs takfoten |
| `buildings/stall/stall-gavel-06-silon.jpg` | `IMG_0076` | **Stallets södra gavel med fodersilon** tätt intill, valvfönster, glasat gavelparti, **huvraden på nocken**, och de vitplastade balarna bredvid. I bakgrunden banorna med belysningsmaster |
| `buildings/ridhus/ridhus-skylten-06-narbild.jpg` | `IMG_0077` | **UBRF-skylten** i närbild: vitt band med hästskologotypen och tre figurer, monterat på den lodrätt korrugerade plåten |
| `buildings/ridhus/ridhus-trappan-05-cafeskylten.jpg` | `IMG_0127` | Ridhusets **raka ståltrappa** med mellanavsats upp till en dörr under litet skärmtak. **CAFÉ-skylten sitter på den ÖVRE avsatsens räcke** |
| `buildings/ridhus/ridhus-durkplatdorrarna-07.jpg` | `IMG_0128` | **Durkplåtsdörrarna** i närbild, med en ljus fönsterdörr bredvid, svart stuprör, kortläsare |
| `omnejd/garden-01-mellan-husen-huvraden.jpg` | `IMG_0130` | **Gården mellan husen**, se nedan |

### Vad de sex avgör

**`IMG_0130` är den bild som visar att husen hänger ihop.** Den står i
gräsgården mellan husen och ser: stallets långsida till vänster med
**huvraden på nocken**, **valvfönsterraden** och **snörasskydden** vid
takfoten; ridhusets vägg till höger med **två luftvärmepumpar** och
durkplåtspartiet; picknickbord och bänk på gräset. Och i fonden **en lägre
byggnadskropp som går tvärs över och binder ihop de båda röda väggarna**,
med en grå dörr i.

Det bekräftar Tobias besked — *"husen är sammanbyggda"* och *"det är
hästgång mellan byggnaderna"* — med bild, inte bara med ord. `VERIFIED`

`[REFERENCE GAP]` Bilden avgör **inte** var längs gården förbindelsen
ligger. Den tvärgående kroppen syns i fondens ände av det synliga utsnittet,
men kameran ser bara en del av gården, och husens flykt gör det omöjligt att
säga hur långt bort den står. Hästgångens läge (y = 89,3) står kvar som det
är, avläst ur satellit.

**Silon står tätt mot stallets gavel.** `IMG_0076` visar den från marknivå,
ungefär mitt för gaveln och drygt halva gavelhöjden hög. Spelet hade den
5 m ut på tomten — ett läge avläst ovanifrån i satellit. Flyttad till
`[164.6, 63.4]`, vilket lägger mantelns kant på 64,9 mot gavelns 65.
`VERIFIED`, och ett litet exempel på samma sak som slänten: **ovanifrån ser
man var något står, inte hur det möter marken eller väggen.**

**CAFÉ-skylten sitter högt.** Kommentaren i `src/site.js` sade *"skylten vid
trappans fot"*. Höjden i `v3dRekvisita` är 3,0 m och stämde redan mot fotot —
det var alltså beskrivningen som var fel, inte geometrin. Rättad, så att
nästa läsare inte "rättar" höjden efter kommentaren.

**Ensilagebalarna ligger vid stallets gavel**, inte bara på satellitgissning.
`IMG_0076` visar dem staplade intill silon. `VERIFIED`

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

Inventeringen är klar. Kvar står tre saker, och ingen av dem kan jag lösa
själv i den här miljön:

1. **Nyckelbildrutor ur ridhusfilmerna.** Åtta `.MOV` på 23–99 MB som inte
   går att hämta genom gränssnittet. `IMG_0191.MOV` är den utpekade källan
   för ridhuset.
2. **Ett mätt höjdmått** mellan grusvägen och uteridbanans yta, så att
   marknivåns `KNOWN MISMATCH` kan stängas.
3. **Ett mätt breddmått i stallet**, så att `STALLINNE.bredd` slutar vara
   ett `[ASSUMPTION]` i intervallet 15–23 m.

Utöver det: pentryts läge i planen, hästgångens läge längs gården, och
grinden in till uteridbanan är alla `[REFERENCE GAP]` som väntar på
underlag — inte på arbete.
4. Först därefter: rätta siteplan, volymer och interiörer.
