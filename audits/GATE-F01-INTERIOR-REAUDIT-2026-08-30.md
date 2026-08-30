# Om-audit av interiörerna mot rätt klassade bilder — issue #23

Datum: 2026-08-30
Status: **AKTUELL SANNING per 2026-08-30.**

> Den här filen skrevs i lager: först om-auditen, sedan rättningarna, sedan
> stallets genomgång. Punkt A, B och C stod därför två gånger med
> MOTSATT status — först som `KNOWN MISMATCH`, längre ner som åtgärdade.
> Review 06 blocker 4 underkände det, och med rätta: en auditfil som säger
> emot sig själv är värdelös som facit.
>
> Filen är omskriven till EN status per fynd. Historiken ligger i
> git-loggen, inte här.

## Det viktigaste först

Gatens största dokumenterade lucka är stängd. `IMG_0179`, `IMG_0183` och
`IMG_0198` låg bara i Drive, och hela ridhusinteriören byggdes ur ChatGPTs
textbeskrivning av dem. Jag har nu hämtat dem ur Drive-mappen **Ridhuset**,
sett dem, och migrerat dem till repot:

| I repot | Ur Drive | Fil-ID |
|---|---|---|
| `references/buildings/ridhus/ridhus-inne-01-glasrummen.jpg` | `IMG_0179.HEIC` | `1dJratW5hQ2g128lypzhPFbxeSxbLUbhu` |
| `references/buildings/ridhus/ridhus-inne-02-langsidan.jpg` | `IMG_0183.HEIC` | `1Anp0_PYPWZr9RAeHZ0rZQVLGpDSCOKHI` |
| `references/buildings/ridhus/ridhus-inne-03-baset-vid-E.jpg` | `IMG_0198.HEIC` | `1gq6KdDtYxod3C9EIJ4J2NW3JNQ77ermp` |

Auditens § 10 och § 14 kan därmed skrivas om: de raderna är inte längre
*"implementation jämförd med ett verifierat textderivat"*. De är riktiga
bildjämförelser nu.

## Klassificeringen — kontrollerad, inte antagen

Issue #23 säger att stallbilder har behandlats som ridhusmaterial. Jag
kontrollerade båda uppsättningarna visuellt:

| Bilder | Vad de faktiskt visar | Stämmer med #23 |
|---|---|---|
| `IMG_0145`, `0149`, `0161`, `0162` | Stallgång: boxar på båda sidor, grå metallfronter och galler, träbalkar i taket, marksten i mitten | Ja — **stall** |
| `IMG_0179`, `0183`, `0198` | Ridbana, vit sarg med svart sockel, läktare, glasade rum, takinstallationer, båset vid E | Ja — **ridhus** |

Klassificeringen i #23 är alltså riktig. Jag hittar inget spår av att
stallbilder har använts som ridhusunderlag i `src/`, men det kan jag inte
utesluta för arbete som gjordes innan bilderna fanns tillgängliga för mig.

## De fem motsägelserna — nu mot riktiga bilder

| # | Byggt efter textderivatet | Vad fotot visar | Utfall |
|---|---|---|---|
| 1 | Mörkröd övre långvägg med vita läkt | **Delvis rätt.** `-02` visar rostbrun/vinröd liggande panel med **tre vita vågräta band** — men bara på en del av långsidan. Längre bort övergår väggen i **ljus/vit** panel | **DELVIS** |
| 2 | Stålprofiler, kabelstegar, ventilationskanaler | **Ventilationen är klart bekräftad** — `-01` visar stora runda spiralkanaler i taket. Balkar i limträ och stålstag syns också. **Kabelstegar syns inte tydligt** i någon av bilderna | **DELVIS** |
| 3 | Klocka vid centrala trappan | **Bekräftad.** `-01` visar en rund vit klocka på den vita väggen, mellan **två** trappor upp till övre planet | **JA** |
| 4 | Mörkt träbås vid E med trappa, räcken och exit-skylt | **Bekräftad i detalj.** `-03` visar båset i mörkt trä, trappan med räcken, och den **gröna exit-skylten** på båsets framsida | **JA** |
| 5 | Glasade rum bakom sargen | **Bekräftad.** `-01` visar en rad fönsterpartier med bruna karmar på **övre planet**, ovanför läktaren | **JA** |

**Arbetet som gjordes i blindo var alltså i huvudsak rätt.** Tre av fem
bekräftas rakt av, två delvis. Det är värt att säga rakt ut, eftersom
motsatsen — att det skulle ha varit fel — var en rimlig farhåga.

## Fynden och deras status

En rad per fynd. Ingen historik, bara vad som gäller nu.

| # | Fynd | Status |
|---|---|---|
| A | Läktarens FRONT mot banan är en hög, solid, mörkbetsad brädvägg med plankdäck ovanpå — inte öppna ljusa trappsteg | **RESOLVED** — `IDENTITET.ridhus.laktarfront`, byggd |
| A2 | Läktarens topologi: ett trappstegsblock med TVÅ trappor och glasband ovanför ligger vid **kortändan där C sitter**, inte längs långsidan | **RESOLVED** — `RIDHUSINNE.kortanda`, byggd i webb och Roblox |
| A3 | Långsideläktarens exakta utbredning i meter | `REFERENCE GAP` |
| B | Den mörkröda panelen täcker en DEL av EN långsida, inte båda i full längd | **RESOLVED** — `IDENTITET.ridhus.ovreVagg.sida/y0/y1` |
| B2 | Var panelens stycke börjar och slutar i meter | `REFERENCE GAP` |
| C | Sponsorskyltarna hänger på den rostbruna panelen ovanför sargen | **RESOLVED** — skyltarna samlade innanför panelens stycke |
| D | E har en elefant som bild (`-03`) | **RESOLVED** — uppgraderad från antagande till verifierad |
| E | C har en cykel (`-01`) | **RESOLVED** — bekräftad igen |
| F | Sargen är vit/gräddvit med svart sockelband | **RESOLVED** — verifierad i alla tre bilderna |
| G | Kabelstegar i taket syns inte tydligt i någon bild | `REFERENCE GAP` — byggda, men underlaget bekräftar dem inte |

## Stallinteriören mot `IMG_0159–0162`

Issue #23 punkt 2. Alla fyra öppnade en och en, med `IMG_0145–0149` och
`0152` ur samma serie.

**De motsäger ingenting i den byggda stallgången.** Gallerfronter över mörka
heldelar, genomgående topplist, orangebruna limträåsar, korrugerad plåt som
undertak, markstensgången i mitten och boxar på båda sidor stämmer allihop.
Om-auditens syfte var att pröva, och prövningen föll ut till byggets fördel.

| Fynd | Status |
|---|---|
| Limträets och plåtens färg, mätta ur fotot till `#C39575` och `#878783` | **RESOLVED** — `IDENTITET.stall.stallgang` |
| Klockan i gångens bortre ände, i två oberoende bildrutor | **RESOLVED** — `STALLINNE.klocka`, byggd |
| Gångens bredd i meter | `REFERENCE GAP` — ärver den återtagna husbredden |
| Antalet boxar | `REFERENCE GAP` — bilderna visar aldrig hela längden i en ruta |
| Balkarnas täthet och dimension (var fjärde meter, snedstag) | `REFERENCE GAP` — avläst ur `IMG_0249`/`0250`, som varken finns i repot eller är granskade av mig |

## Kvar för att stänga issue #23

Inget av det nedan går att lösa från befintligt material:

- **Roblox Studio.** Utseende, material, ljus och prestanda är oprövade där.
  Stub- och byggbänksbevis är inte visuellt Studio-bevis.
- `IMG_0249` och `IMG_0250` in i repot, så att takstommen vilar på granskade
  bilder i stället för på en beskrivning.
- Nyckelbildrutor ur ridhusfilmerna (`IMG_0191.MOV` m.fl.), som fortfarande
  är `[DRIVE-ONLY]`.
