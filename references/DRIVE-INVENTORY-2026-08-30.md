# Kanonisk referensinventering — Drive-mapparna

Datum: 2026-08-30
Metod: listad via Drive-API, **dedupliceras på titel + filstorlek**, och det
som faktiskt granskats är visuellt öppnat — inte klassat på mappnamn.

> **Status: PÅBÖRJAD, INTE KLAR.** Omnejd är helt genomgången, Ridhusets tre
> nyckelbilder och sex av Stallhusets är sedda och migrerade. Byggnaden är
> listad men inte visuellt granskad ännu. Raderna nedan säger uttryckligen
> vilka jag har SETT och vilka jag bara har metadata om.

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

- **Staketet runt banan**: trästolpar med **tre liggande reglar**, mörkt
  betsat/väderbitet virke.
- **Belysningsmaster**: höga grå/silverfärgade stolpar med lampahuvuden,
  flera runt banan. Spelet har inga.
- **Röd bod vid banans bortre kant**, mörkt tak — spelets `domarkur` ligger
  vid banans norra kortsida.
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

## Byggnaden — listad, inte granskad

Mapp-ID `1cmyTQ_9AVjAaKlozWE2-lKsMxGRgVaPB`

19 unika: `IMG_0064`–`0077`, `IMG_0126`–`0131`.

`[EJ GRANSKAT]` Ingen av dem är öppnad ännu. Mappnamnet antyder att de rör
byggnadskomplexet och kan bära på svaret om hästgången och de sammanbyggda
volymerna, men **mappnamn är inte evidens** — de ska ses innan något byggs på
dem.

## Vad som gäller härnäst

1. Granska `Byggnaden` visuellt — den kan avgöra förbindelsefrågan.
2. Granska resten av `Stallhuset`.
3. Nyckelbildrutor ur ridhusfilmerna, om någon kan extrahera dem.
4. Först därefter: rätta siteplan, volymer och interiörer.
