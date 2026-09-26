# references/

Lägg 3–4 skärmdumpar här som visar den visuella stil spelet ska ha — färgglad,
målad hästspelsestetik för mobil. Skärmdumpar från Play Store-sidor eller
trailers duger utmärkt som *referens*.

De används bara för att kalibrera stilen. Inga bilder, figurer, logotyper eller
namn härifrån kopieras in i spelet.

Namnge dem så att det syns vad de visar, t.ex.

    01-ridning-ute.png
    02-stall-ui.png
    03-startmeny.png
    04-karaktar-narbild.png

När de ligger här: säg åt mig att läsa `references/` innan något visuellt görs.
Jag kan titta på bilder och kalibrerar då mot dem i stället för att gissa.

## Proveniens: återställt material 2026-09-24

Två poster återfördes när `G8` visade att `references/CHECKSUMS.sha256` aldrig
verifierats i CI — manifestet kom i en gren som inte mergades, och grindens
`if [ -f ]`-sköld dolde att det saknades.

**`buildings/stall/stall-entre-07.jpg` … `-14.jpg` — orienteringsrättelse.**
Källcommit `9cdf350`, *«F02: råfilmerna som källa — åtta referensbilder låg upp
och ner»*. Filerna som låg här var byte för byte versionerna **före** den
rättelsen, alltså upp och ner. De rättvända blobbarna stämmer mot manifestet.
Storleksskillnaden mot de gamla filerna kommer av rotationen och omkodningen —
den säger ingenting om vilken fil som är kanon.

**`plans/ridhus-entreplan-rektifierad.jpg` — historisk diagnostik, inte facit.**
Källcommit `8b11453`. Rektifieringsförsöket **misslyckades**: entrén är beskuren
och residualen ligger över tröskeln. Bilden bevaras som evidens för att försöket
gjordes och hur det gick — **inte** som verifierad geometri, skala eller nya
rummått. Den får inte användas för att mäta rum eller flytta något i modellen.
