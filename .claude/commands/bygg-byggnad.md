---
description: Bygg (eller bygg om) en UBRF-byggnad i spelet utifrån dess foton och byggnadskort, och verifiera mot fotona
argument-hint: <byggnad, t.ex. ridhus>
---

Byggnad: **$ARGUMENTS**.

## Förberedelse (hoppa inte över)
1. Läs `references/buildings/$ARGUMENTS/KORT.md`. Saknas det, eller har det fler än tre
   `[saknas foto]` på huvudfasaderna: stoppa och kör `/fotoanalys $ARGUMENTS` först.
2. **Öppna alla foton i mappen med Read igen**, även om du gjort det tidigare i sessionen.
   Du ska ha bilderna färska när du skriver koden.
3. Läs `references/SITEPLAN.md` för placering och rotation på tomten.
4. Läs byggnadens data i `ANL` (`src/world.js`) och dess geometri i `src/varld3d.js`.

## Bygg
5. Ändra byggnadens rader i `ANL` och dess block i `v3dBygg`. Reglerna:
   - **enbart mått och färger från kortet** — kommentera varje ändring med vilken rad i kortet den följer,
   - måtten skrivs i meter, samma tal i `ANL` som i kortet,
   - färgerna som hexvärden; hör de till paletten läggs de i `MARKFARG` i `src/ljus.js`,
   - formspråket styrs av `STIL` — ändra form och antal, aldrig stilen.
6. Bygg om med `python3 tools/build.py` och kontrollera att `dist/ridskolan.html` byggs utan fel.

## Verifiera (obligatoriskt)
7. Välj det referensfoto som visar huvudfasaden. Starta `python3 -m http.server 8931`
   och kör spelet i Playwright (`executablePath:"/opt/pw-browsers/chromium"`).
   Sätt kameran i motsvarande vinkel genom att ersätta `window.v3dKamera` med en fast
   position — ungefär ögonhöjd 1,6 m, samma sida av byggnaden som fotot.
8. Ta skärmdump och spara som `references/renders/$ARGUMENTS-v<n>.png`.
9. Öppna referensfotot och skärmdumpen efter varandra och jämför punkt för punkt:
   proportioner (bredd:höjd:längd), taklutning, antal och placering av fönster och portar,
   färgton, takutsprång, och kännetecknen i kortet.
10. Skriv en avvikelselista med konkreta siffror. Är listan tom och du är ärlig: klart.
    Annars rätta och gå till steg 6. Gör minst en rättningsrunda även om det "ser bra ut" —
    första bygget är aldrig rätt.
11. Upprepa 7–10 för minst en andra vinkel (gaveln eller baksidan).

## Avslut
12. Uppdatera KORT.md: sätt `Byggd version:` och lista medvetna avvikelser med motivering.
13. Sammanfatta: vad som byggdes, vad som stämmer, vad som fortfarande avviker och vilka
    foton som skulle hjälpa.
