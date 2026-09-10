# Vilken fil ska testas? — canonical pekare

> ## Filen att öppna
>
> **`roblox/releases/first-playable-place-46231de/UBRFFirstPlayable.rbxlx`**
>
> Öppna via **File → Open from File…** i Studio (inte dubbelklick) och tryck
> **Play**. Kontrollera att Output börjar med `FIRST_PLAYABLE_PREFLIGHT: PASS`.
>
> **Fysisk test väntar fortfarande på ChatGPT:s kontroll** av grind och
> distributionsväg, enligt processreviewen 16:31.

| Fält | Värde |
|---|---|
| Sanktionerad fil | `first-playable-place-46231de/UBRFFirstPlayable.rbxlx` |
| Source-SHA | `46231dee2957de9075ae596e3eba5c747b9a4162` |
| SHA256 | `aad3847880cf434a8cdf1f9d53d831e13fd22963bfb223d70c5cb84db0ff6bd7` |
| `END_TO_END_PLAYABILITY_GATE` | **PASS** — kedjan spawn → dörr → gången vid Jacks box är gångbar |
| `FIRST_PLAYABLE_PREFLIGHT` (pakethalvan) | PASS, men se förbehållet nedan |

## Varför den här filen finns

ChatGPT:s processreview 2026-09-10 16:31: Tobias hade då manuellt hittat
**tre** grundläggande Studio-fel i buildar som presenterats som redo —
miljö utan gameplay, spawn över tomrum, och en världsmodul som inte gick
att `require`. Mönstret var att grindarna mätte **avsikt** och inte
**spelbarhet**.

Filen finns för att det aldrig ska vara oklart vilken fil som är rätt, och
för att "det finns en nyare mapp" inte ska räcka som sanktion.

## Förbehåll om `FIRST_PLAYABLE_PREFLIGHT`

Den beställda preflighten hade tio punkter, bland dem **punkt 5** (hela
first-day path smoke) och **punkt 6** (negativa gameplaytester). Det som
finns implementerat mäter paketkompletthet, spawn, dörr, Jack-identitet,
klient/UI och att `SparService` finns — alltså en **delmängd**.

Ett `FIRST_PLAYABLE_PREFLIGHT: PASS` betyder därför **inte** att hela den
beställda preflighten är uppfylld, och ska inte beskrivas så. Det är en
korrigering av hur jag tidigare rapporterade den.

## Historik — bevarade, men `DO_NOT_TEST`

| Mapp | Vad som gick fel |
|---|---|
| `first-playable-506b5a3` | miljö-/QA-paket utan gameplay: ingen spawn, ingen dörrinteraktion, ingen häst |
| `first-playable-place-94ce4c9` | första placen: `iostream stream error` — saknade `<External>`-rader och `Workspace` |
| `first-playable-place-2af5de2` | öppnade och spelade, men spawnen låg 3,2 m ut över tomrummet: spelaren föll och dog |
| `first-playable-place-b1e2a83` | spawnen rättad, men världsmodulen returnerade inget värde — `require()` kastade efter bygget, ingen tjänst startade, frusen himmel utan avatar |
| `first-playable-place-14a0a6e` | returvärdet rättat, men levererad innan spelbarheten mättes |
| `first-playable-place-46231de` | **SANKTIONERAD.** Första filen där `END_TO_END_PLAYABILITY_GATE` är PASS |

Ingen av mapparna regenereras på plats; var och en är pinnad till sin
source-SHA så att det går att se exakt vad som levererades när.
