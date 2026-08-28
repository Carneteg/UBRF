---
description: Bygg (eller bygg om) en UBRF-byggnad i Roblox Studio utifrån dess foton och byggnadskort, och verifiera mot fotona
argument-hint: <byggnad, t.ex. ridhus>
---

Byggnad: **$ARGUMENTS**.

## Förberedelse (hoppa inte över)
1. Läs `reference/buildings/$ARGUMENTS/KORT.md`. Saknas det, eller har det fler än tre `[saknas foto]` på huvudfasaderna: stoppa och kör `/fotoanalys $ARGUMENTS` först.
2. **Öppna alla foton i mappen med Read igen**, även om du gjort det tidigare i sessionen. Du ska ha bilderna färska när du skriver koden.
3. Läs `src/BuildKit.lua` och, om filen finns, `src/buildings/$ARGUMENTS.lua`.
4. Läs `reference/SITEPLAN.md` för placering och rotation på tomten.

## Bygg
5. Skriv/uppdatera `src/buildings/$ARGUMENTS.lua`. Skriptet ska:
   - börja med att ta bort `workspace.Anläggning.<Namn>` om den finns,
   - bygga en `Model` med `PrimaryPart` = osynlig golvplatta i SV-hörnet,
   - använda BuildKit och **enbart mått/färger från kortet** (kommentera varje block med vilken rad i kortet det följer),
   - sätta attributen `Källa` och `Version` (bumpa Version),
   - avsluta med `print("OK <Namn> byggd, "..#model:GetDescendants().." objekt")`.
6. Kör skriptet i Studio via MCP (`run_code` / `eval`). Läs konsolutdata. Fel → rätta → kör om.

## Verifiera (obligatoriskt)
7. Välj det referensfoto som visar huvudfasaden. Sätt Studio-kameran i motsvarande vinkel (via MCP: sätt `workspace.CurrentCamera.CFrame` med `CFrame.lookAt`, ungefär ögonhöjd 1,6 m, samma sida av byggnaden).
8. Ta skärmdump (`capture_screenshot` om verktyget finns; annars be Tobias klistra in en skärmdump från Studio). Spara/notera som `reference/renders/$ARGUMENTS-v<Version>.png`.
9. Öppna referensfotot och skärmdumpen efter varandra och jämför punkt för punkt:
   proportioner (bredd:höjd:längd), taklutning, antal och placering av fönster/dörrar, färgton, takutsprång, kännetecknen i kortet.
10. Skriv en avvikelselista med konkreta siffror. Är listan tom och du är ärlig: klart. Annars rätta i skriptet och gå till steg 6.
    Gör minst en rättningsrunda även om det "ser bra ut" – första bygget är aldrig rätt.
11. Upprepa 7–10 för minst en andra vinkel (gaveln eller baksidan).

## Avslut
12. Uppdatera KORT.md: sätt `Byggd version:` och lista eventuella medvetna avvikelser från verkligheten med motivering.
13. Sammanfatta för Tobias: vad som byggdes, vad som stämmer, vad som fortfarande avviker och vilka foton som skulle hjälpa.
