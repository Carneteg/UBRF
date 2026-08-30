# Om-audit av interiörerna mot rätt klassade bilder — issue #23

Datum: 2026-08-30
Status: **de tre ridhusbilderna finns nu i repot, och jag har sett dem.**

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

## Nya fynd: vad som INTE stämmer

### A · Läktarens karaktär och läge

Spelet bygger läktaren som **ljusa furutrappsteg längs hela östra långsidan**,
lokala y 9–59, alltså 50 m.

Fotona visar något annat:

- `-01`: läktaren ligger vid **kortändan** (vid bokstaven C), som breda
  trappsteg i ljust trä under de glasade rummen, med **två trappor** upp.
- `-02` och `-03`: i förgrunden syns läktarens ovansida som ett **brett
  plankdäck**, och dess framsida mot banan är en **hög, solid, mörkbetsad
  brädvägg** — inte öppna trappsteg.

`[KNOWN MISMATCH]` Läktarens utbredning och dess front mot banan.

### B · Den mörkröda väggen täcker inte hela långsidan

Spelet målar båda långsidorna. Fotot visar den rostbruna panelen med vita band
på **en del** av en långsida; resten är ljus.

`[KNOWN MISMATCH]` Utbredningen.

### C · Sponsorskyltarna sitter på den mörka väggen

`-02` visar skyltar — Agria, RS Mustang, Svenskt Stallströ, Ingeborgs Gård —
hängande på den rostbruna panelen, ovanför sargen. Spelet har sponsorplåtar,
men deras läge är inte kopplat till väggens utbredning.

## Två antaganden som nu kan uppgraderas

| Vad | Var | Status |
|---|---|---|
| **E har en elefant** som bild | `-03`, tydligt bredvid bokstaven E på sargen | `[antagande]` → **VERIFIED** |
| **C har en cykel** | `-01`, bredvid C på sargen | Redan "ur foto" — **bekräftad igen** |
| Sargen är vit/gräddvit med **svart sockelband** | alla tre | **VERIFIED** |

## Vad som ÄR gjort sedan om-auditen skrevs

`28a768f` och framåt:

- **Punkt A — läktarens front.** Läktaren byggde öppna ljusa furutrappsteg
  hela vägen ner. Båda interiörfotona är tagna FRÅN läktaren och visar samma
  sak i förgrunden: ett brett plankdäck upptill och en **hög, solid,
  mörkbetsad brädvägg av liggande panel** mot banan. Fronten finns nu i
  `IDENTITET.ridhus.laktarfront` och byggs av webben. `VERIFIED` att den är
  solid, mörk och liggande; `[ASSUMPTION]` brädhöjd och ton.

- **Punkt B — den mörkröda väggens utbredning.** Spelet målade BÅDA
  långsidorna i hela sin längd. Panelen ligger nu på **en** långsida (väster,
  mitt emot läktaren) och över **ett stycke** av den,
  `IDENTITET.ridhus.ovreVagg.sida/y0/y1`. `VERIFIED` att den är partiell och
  sitter på en sida; `[ASSUMPTION]` var den börjar och slutar.

- **Punkt C — sponsorskyltarna.** De låg utspridda på y 8–53 och hamnade
  därmed delvis på den ljusa delen av väggen. Nu samlade innanför panelens
  stycke, i den ordning `-02` visar dem.

`[REFERENCE GAP]` Läktarens exakta utbredning längs långsidan, och
trappblocket vid kortändan under glasrummen som `-01` visar, är inte
måttsatta. Fronten är rättad; utbredningen är det inte.

## Vad som fortfarande INTE är gjort

Den här filen var från början **om-auditen**, alltså issue #23 punkt 5.
Punkt A, B och C är nu åtgärdade — se avsnittet ovan. Kvar: de ändrar läktarens och väggens geometri,
och den geometrin ligger i den delade datan som båda plattformarna läser.
Att ändra den är ett eget arbete, och det ska göras med samma kedja som
resten — `src/site.js` → webben och exporten → Roblox.

## Stallinteriören mot `IMG_0159–0162` — omgranskad

Issue #23 punkt 2. Alla fyra bilderna är öppnade en och en, tillsammans med
`IMG_0145–0149` och `0152` ur samma serie. De visar samma stallgång från
olika punkter längs den.

### Vad de BEKRÄFTAR i det som redan är byggt

| Drag | Läge i koden | Status |
|---|---|---|
| Boxfronter: galvad ram, lodräta galler upptill, **mörk antracitfärgad heldel** nedtill | `v3dStall`, boxfronterna | `VERIFIED` |
| **Genomgående topplist** i galvat stål ovanför fronterna | `galler.lada(...)` på z = 2,20 | `VERIFIED` — fanns redan |
| **Orangebruna limträåsar** längs taket | `IDENTITET.stall.stallgang.limtra` | `VERIFIED`, färgen mätt |
| **Korrugerad plåt** som undertak, följer takfallet | `IDENTITET.stall.stallgang.takplat` | `VERIFIED`, färgen mätt |
| **Markstensgång i mitten** med ljusare kanter | golvet i `v3dStall` | `VERIFIED` |
| Runda armaturer tätt under plåten | `lykt` | `VERIFIED` — kortade pendlar |
| Boxar på BÅDA sidor hela vägen | `STALL_BAND` | `VERIFIED` |
| Hönät och täcken hängande på fronterna | rekvisita | `VERIFIED` |

Bilderna motsäger alltså ingenting i den byggda stallgången. Det är ett
resultat värt att skriva ut: om-auditens syfte var att pröva, och prövningen
föll ut till byggets fördel.

### Vad de LÄGGER TILL

- **Klockan i gångens bortre ände.** Syns i `IMG_0160` och i
  `stall-inne-05-stallgangen.jpg`. Två oberoende bildrutor. Byggd.

### Vad de INTE avgör

`[REFERENCE GAP]` **Gångens bredd.** Ingen av bilderna har något av känd
storlek att skala mot. Spelets 2,6 m kommer ur `STALL_BAND`:s andelar av den
antagna bredden 21 m — och bredden är själv `[REFERENCE GAP]` efter
återtaget. Gångbredden ärver alltså den osäkerheten och kan inte stängas
härifrån.

`[REFERENCE GAP]` **Antalet boxar.** Bilderna är tagna längs gången och visar
aldrig hela längden i en ruta, så de kan varken bekräfta eller motsäga de
tolv per rad som utrymningsplanen gav.
