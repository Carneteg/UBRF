---
description: Analysera fotona på en UBRF-byggnad och fyll i dess byggnadskort (KORT.md)
argument-hint: <byggnad, t.ex. ridhus>
---

Byggnad: **$ARGUMENTS**. Mapp: `references/buildings/$ARGUMENTS/`.

Gör exakt detta, i ordning:

1. Lista alla bildfiler i mappen. Om mappen är tom eller bara innehåller HEIC: stoppa och säg till – kör `tools/convert-photos.sh` först.
2. **Öppna varje foto med Read.** Alla. För varje foto skriv en rad: filnamn, vilken fasad/vinkel den visar, vad som syns.
3. Kopiera `references/buildings/_mall/KORT.md` till `references/buildings/$ARGUMENTS/KORT.md` om kortet inte finns.
4. Fyll i kortet **bara med sådant du faktiskt ser i fotona**. Regler:
   - Mått uppskattas från kända referenser i bild (dörr ≈ 2,1 m, häst ≈ 1,6 m i manken, person ≈ 1,75 m, standardfönster ≈ 1,2 m, plåtprofil ≈ 1 m bred). Skriv hur du kom fram till varje mått.
   - Färger anges som RGB, plockade från en skuggfri del av ytan. Ange även vardagsnamn ("falurött", "ljusgrå plåt").
   - Räkna: fönster, dörrar, portar, takfönster, stuprör – per fasad.
   - Takform, taklutning (uppskattad i grader), taktäckning, takutsprång, nock/gavel-riktning.
   - Kännetecken som gör byggnaden igenkännbar (skylt, rampen, den blå porten, vindskivans färg...). Minst tre.
   - Det du inte kan se markerar du `[saknas foto]`. Det du gissar markerar du `[antagande]`. Hitta aldrig på.
5. Skriv en **"Fotobrist"**-lista längst ner: vilka vinklar Tobias behöver fotografera för att kortet ska bli komplett.
6. Visa kortet för Tobias och fråga om måtten stämmer med hans känsla för platsen innan något byggs. Bygg inte i detta steg.
