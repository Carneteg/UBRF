# Samtycke — Upplands-Bro Ryttarförening

| | |
|---|---|
| Noterat | 2026-11-28, enligt Tobias (produktägare) |
| Givet av | ridskolechefen (bara rollen sparas här) |
| Datum då det gavs | inte angivet |
| Skriftligt eller muntligt | inte angivet |
| Villkor | inga angivna |

Samtycket är noterat utifrån Tobias besked i arbetssessionen 2026-11-28. Själva
meddelandet från klubben finns inte i repot. Läggs det in senare ska det citeras
här, utan personuppgifter utöver avsändarens roll.

## Vad samtycket täcker

1. **Foto, film och mätning.** Anläggningen får fotograferas, filmas och mätas,
   inifrån och utifrån, och bilderna får användas som underlag för spelet.
2. **Igenkännbar återgivning.** Anläggningen får återges i spelet så att den går
   att känna igen, med föreningens namn och platsen — också med ytor tagna ur
   foton (texturer).
3. **Sponsorskyltar och klubbmärke.** Sponsorskyltarna i ridhuset får synas med
   sina riktiga namn, och föreningens märke där det sitter i verkligheten.
4. **Skolhästarna och ljud.** Ridskolans hästar får fotograferas och filmas, och
   deras namn får användas. Ljud får spelas in i ridhuset, stallet och på gården.

## Vad samtycket inte täcker

En förenings samtycke kan inte ge bort andras rätt. Därför gäller fortfarande,
oberoende av det här dokumentet:

- **Inga igenkännbara personer.** Foton och filmer där en person syns används
  inte som texturkälla och läggs inte i repot utan den personens eget samtycke.
- **Inga registreringsskyltar och inga läsbara personnamn** i bild.
- **Inga röster och inget ljud från lektioner.** Barn förekommer aldrig.
- **Privatägda hästar** omfattas inte; samtycket gäller skolhästarna. En
  privatägd häst tas med först när ägaren själv har sagt ja `[REFERENCE GAP]`.
- **Sponsorernas varumärken** tillhör sponsorerna. Klubbens ja gäller att
  skyltarna får synas där de sitter; det är inte en licens från varumärkets ägare.

## Var det används

- `tools/build.py` släpper in en textur med rättigheten `ubrf-foto` i
  `assets/textures/KALLOR.tsv` bara om kolumnen `samtycke` pekar på den här filen
  (Batch 1.3).
- Förfrågan som skrevs i Batch 0.14 (`SAMTYCKE-FORFRAGAN-UTKAST.md`) behövdes inte
  och är borttagen; den finns kvar i git-historiken.
