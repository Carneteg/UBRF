# Vilken fil ska testas? — canonical pekare

> ## ⛔ JUST NU: INGEN FIL ÄR SANKTIONERAD FÖR FYSISK TEST
>
> `END_TO_END_PLAYABILITY_GATE` är **under uppbyggnad** och har ännu inte
> varit PASS på någon build. Ingen mapp under `roblox/releases/` ska öppnas
> för acceptanstest förrän den här filen pekar ut en, med både source-SHA
> och gate-utfall ifyllda.

| Fält | Värde |
|---|---|
| Sanktionerad fil | **ingen ännu** |
| Source-SHA | — |
| Release-SHA | — |
| SHA256 | — |
| `END_TO_END_PLAYABILITY_GATE` | **ej PASS — grinden byggs** |
| `FIRST_PLAYABLE_PREFLIGHT` (pakethalvan) | PASS på `14a0a6e`, men se förbehållet nedan |

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
| `first-playable-place-14a0a6e` | returvärdet rättat. **Machine-verified candidate** — inte sanktionerad för acceptanstest, eftersom `END_TO_END_PLAYABILITY_GATE` inte finns än |

Ingen av mapparna regenereras på plats; var och en är pinnad till sin
source-SHA så att det går att se exakt vad som levererades när.
