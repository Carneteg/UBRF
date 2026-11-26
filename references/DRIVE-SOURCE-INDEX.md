# Google Drive UBRF — verifierat referensindex

Syfte: ge Claude Code och andra implementatörer ett textbaserat, spårbart index över originalmaterial som finns i Google Drive-mappen `UBRF`.

**Originalfilerna i Drive är facit.** Detta dokument ersätter inte foton/video; det sammanfattar endast sådant som faktiskt har öppnats och verifierats. Bygg inte osedda detaljer från denna text.

Verifierad av: ChatGPT, 2026-08-29.

## Fullständigt manifest 2026-11-26 (Batch 0.13)

Det här dokumentet beskriver ett urval i ord. **Hela** Drive-mappen — 211
foton, 24 filmer och 64 övriga filer — står sedan 2026-11-26 rad för rad i
`references/DRIVE-MANIFEST-2026-11-26.tsv`: Drive-id, sökväg, storlek, sha256
för originalet, byggnad och zon, om personer, registreringsskyltar eller
läsbara personnamn syns, status (`IN_REPO` / `DRIVE-ONLY`) och repo-filens
sökväg och sha256. `python3 tools/kolla-referenser.py` faller om manifestet
och filerna säger olika saker.

| | Antal | |
|---|---|---|
| Foton i Drive | 211 | |
| — redan i repot före 2026-11-26 | 93 | samma bild, omkodad (perceptuellt avstånd 0–4) |
| — migrerade 2026-11-26 | 92 | JPEG 2048 px, EXIF/XMP borttagna, under `buildings/ridhus/drive-2026-11-26/` (26), `buildings/stall/drive-2026-11-26/` (60), `omnejd/drive-2026-11-26/` (6) |
| — kvar som `[DRIVE-ONLY]` | 26 | 10 med en person i bild, 11 med registreringsskylt, 5 med läsbara personnamn |
| Filmer i Drive | 24 | alla `[DRIVE-ONLY]`; 16 har nyckelrutor under `references/video/` sedan tidigare; 10 visar personer |
| Övrigt | 64 | `1.pdf` (se `references/education/`) och Quaternius CC0-testmodeller under `Models/` (tolv modeller i fyra format, en förhandsbild, en förhandsfilm, licenstexten) |

Att läsa manifestet rätt:

- **«visar:» i anmärkningskolumnen är maskinläst och på engelska.** Den kommer
  ur analysomgången i november och är inte granskad av produktägaren. Den
  duger för att hitta en bild, inte som belägg — öppna bilden.
- **Zon och byggnad är en läsning av bilden, inte Drive-mappen.** Sex foton
  ligger i Drive-mappen `Ridhuset` men visar stallet eller gården
  (`IMG_0250`, `0251`, `0253`, `0303`, `0304`, `0305`); de är sorterade efter
  vad de visar. Mappen `Byggnaden` blandar ridhus, stall och gård.
- **De 92 nya bilderna är granskade för hand** på kontaktkartor, med utsnitt i
  full upplösning av de ställen där något kunde gå att läsa (bilar,
  whiteboard, boxskyltar, anslag). Ingen person och ingen registreringsskylt
  syns. Fem bilder som maskinläsningen släppt igenom hölls tillbaka:
  whiteboarden i teorisalen bär ett lägerschema med förnamn (`IMG_0139`,
  `0228`, `0229`, `0230`), och ett anslag vid larmpanelen en kontaktlista
  (`IMG_0133`). Hästnamn på boxskyltar är kvar — de står på klubbens webbplats.
- **Gränsen för granskningen:** varje skylt och varje papper är inte läst i
  full upplösning. Hittas ett namn i en migrerad bild ska bilden bort ur
  repot och raden sättas till `DRIVE-ONLY`.
- `IMG_0155` är tagen med telefonen upp och ner; derivatet är roterat 180°.
- `Ridhuset/IMG_0098.HEIC` gick inte att hämta som original; den finns redan
  i repot som `ridhus-inne-14-laktaren.jpg`, så ingenting saknas.

Två saker om det som låg i repot **före** den här batchen, noterade men inte
ändrade:

- 28 av de 93 tidigare migrerade bilderna visar en person och 4 en
  registreringsskylt (kolumnerna `personer` / `skyltar` på rader med
  «migrerad före»). Om de ska ligga kvar är samma fråga som samtycket i
  `references/licenses/SAMTYCKE-FORFRAGAN-UTKAST.md`.
- `buildings/stall/stall-inne-07-spolspiltan.jpg` ligger upp och ner (golvet
  överst), som de åtta `stall-entre`-bilderna gjorde före rättelsen i
  `references/README.md`.

## Referensregler

- Filnamnet nedan ska alltid anges när en observation används.
- Ett foto bevisar bara det som faktiskt syns i vinkeln.
- Video ska användas som spatial evidens över flera frames, inte som moodboard.
- Motstridiga vinklar ska lösas genom fler referenser, inte genom gissning.
- Okänd detalj = `[REFERENCE GAP]`.
- Färg kan påverkas av exponering/vitbalans; använd flera bilder innan exakt färgvärde låses.

## Verifierade originalbilder

### IMG_0164.HEIC — utebana

Synligt och verifierat:

- Sand-/ridbana med trästaket i flera horisontella nivåer.
- Banan ligger något upp från den närmaste grusytan, med gräs-/jordslänt mellan.
- Tät löv-/blandskog som bakgrund.
- Belysningsmast intill banan.
- Mindre röda byggnader/skjul syns vid banans kanter.
- Närmiljön är funktionell och relativt enkel; lägg inte till dekorativa parkdetaljer utan referens.

Användning: utebana, staket, nivåskillnad, vegetation, småbyggnader och ljusmaster.

### IMG_0179.HEIC — ridhus, läktar-/cafésida

Synligt och verifierat:

- Foto taget från/vid träläktaren ner mot ridbanan.
- Vit sarg med mörk/svart nederkant.
- Brun ridbane-yta.
- Träläktare och träbarriär i förgrunden.
- Bakom sargen finns upphöjda träbänkar/trappor och flera glasade rum/fönsterpartier.
- Central passage/trappa med klocka i närheten.
- Taket visar stora träbalkar, stål-/metallprofiler, kabelstegar, ventilation och många längsgående lysrörsarmaturer.
- Interiören ska därför inte ersättas med ett generiskt modernt ridhus.

Användning: läktargeometri, sarg, takstruktur, belysning, glasade utrymmen och nivåer.

### IMG_0183.HEIC — ridhus, sponsorvägg/långsida

Synligt och verifierat:

- Stor överblick över ridbanan från läktaren.
- Brun ridbane-yta och vit sarg med mörk/svart nederkant.
- Långsidan har mörkröd/maroon övre väggyta med horisontella detaljer.
- Höga smala/translucenta fönsterband nära taknivå.
- Sponsorplåtar sitter på långsidan ovanför sargen.
- Taket har tydliga träbalkar och ett tätt mönster av lysrörsarmaturer.
- Träläktare/barriär och bordsyta syns i förgrunden.

Användning: sponsorvägg, fönsterband, sarg, materialrytm och läktarvinkel.

### IMG_0193.HEIC — klubb-/omklädningsinteriör

Synligt och verifierat:

- Långa rader av höga skåp i grått, rött och svart.
- Skåpen har ljusa/vita stommar och ventilationsöppningar.
- Grått, slätt golv.
- Vita väggar och vitt/ljust tak.
- Synlig vit ventilation nära taket.
- En sittgrupp med vitmålad trästomme och starkt röd textil med vitt blad-/blommönster.
- Lysrörsliknande rektangulära takarmaturer.

Användning: klubbdel/omklädning. Återge layout och möbler endast där fler vinklar stöder placeringen.

### IMG_0198.HEIC — ridhus, läktare vid E

Synligt och verifierat:

- Vit sarg med mörk/svart nederkant och dressyrbokstaven `E`.
- Bakom sargen finns en låg, upphöjd trä-/läktarnivå.
- Trappa med träräcken leder upp mot ett litet mörkt träbyggt bås/utrymme med exit-skylt ovan/vid öppningen.
- Sittplatser/steg fortsätter åt sidan.
- Bilden ger konkret geometri för området bakom E och får inte ersättas av generisk läktare.

Användning: E-sidan, trappor, läktarnivå och lilla båset.

## Verifierad video

### IMG_0191.MOV — ridhusinteriör, ca 31 s

Verifierat genom frames över hela klippet:

- Visar ridhusets interiör från läktar-/publiksidan över flera vinklar.
- Bekräftar samma vita sarg med mörk nederkant och brun ridbane-yta.
- Bekräftar sponsorvägg, läktar-/barriärgeometri och flera fasta öppningar/dörr-/väggpartier.
- Kan användas för att korsreferera placeringar som inte bör bestämmas från ett enda foto.

Vid implementation: extrahera/inspektera relevanta frames för den specifika plats som byggs. Anta inte att en observation från en frame gäller motsatt sida.

## Övrigt material bekräftat i Drive

UBRF-roten innehåller dessutom flera MOV- och HEIC-original, bland annat:

- video: `IMG_0169.MOV`, `IMG_0185.MOV`, `IMG_0188.MOV`, `IMG_0189.MOV`, `IMG_0191.MOV`, `IMG_0192.MOV`, `IMG_0195.MOV`, `IMG_0196.MOV`
- foton i åtminstone serien `IMG_0160`–`IMG_0199` (med luckor/olika filtyper)
- `1.pdf`
- mappen `Models` med modellformat

Detta är **inventering, inte verifierad visuell beskrivning** för varje fil. Öppna materialet innan du bygger mot det.

## Implementationsdisciplin

För varje Roblox-byggnad/interiör:

1. Identifiera vilka Drive-filer som faktiskt visar delen.
2. Låt ChatGPT/Reference Custodian verifiera relevanta bilder/video om Claude Code saknar Drive-åtkomst.
3. Uppdatera byggnadskort eller separat Roblox-reference brief.
4. Claude Code implementerar i `roblox/`.
5. Jämför Roblox Studio-skärmdump från motsvarande vinkel mot originalet.
6. Lista konkreta skillnader och korrigera.
7. Tobias godkänner igenkänning/game feel där en mänsklig Studio-playtest behövs.
