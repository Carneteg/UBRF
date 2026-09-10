# Vilken fil ska testas? — canonical pekare

> ### Det FINNS ett provbygge att prova om du vill
>
> `first-playable-place-e9a37ff/` är ett **provbygge** — inte sanktionerat,
> inte produktaccepterat. Det innehåller hästen och de fem rättelser som
> gjordes efter att förra placen frös, och dess README säger exakt vad som
> är rättat och vad som INTE är verifierat. Sanktionen nedan står kvar
> tills hela `END_TO_END_PLAYABILITY_GATE`, lokaliseringen och ChatGPT:s
> nya review är klara.

> ## ⛔ INGEN FIL ÄR SANKTIONERAD FÖR FYSISK TEST
>
> Sanktionen av `first-playable-place-46231de` är **återtagen** efter
> ChatGPT:s senior whole-place review 2026-09-10 16:40. Placen saknar
> hästmodell: den är inte spelbar, hur gångbar världen än är.

| Fält | Värde |
|---|---|
| Sanktionerad fil | **ingen** |
| `END_TO_END_PLAYABILITY_GATE` | PASS på gångbarhet — men grinden mätte inte att hästen finns |
| Blockerare | P0 ingen Jack-rigg · P0 `seat.C0` mot en `Seat` · P0/P1 ingen serverstädning vid död/respawn · P1 `Seat:Sit(nil)` · P0 spelare släpps in före kritisk preflight |

## Verifierade blockerare (16:40-reviewen)

Alla fem kontrollerade mot koden, inte mot reviewtexten:

| Fynd | Verifiering |
|---|---|
| **Ingen hästmodell i placen** | inget i `roblox/src`, `roblox/game` eller `roblox/buildings` skapar en häst-`Model`/`Seat`/`Humanoid`. `HorseService` registrerar bara `CollectionService:GetTagged("Horse")`. Den genererade `.rbxlx` innehåller **0** `Model`, `Humanoid` och `Seat`. Spelaren tilldelas `blackrock_jack` i datan och `bind()` får ingen modell |
| **`seat.C0` mot en `Seat`** | `RigAdapter.setRiderLean` läser och skriver `seat.C0` (rad 190–195), medan `HorseService` använder samma `rig.seat` som en Roblox `Seat` (`seat:Sit(humanoid)` rad 288, `seat.Occupant` rad 312). En `Seat` har ingen `C0`. De två användningarna utesluter varandra |
| **Ingen serverstädning vid död/respawn** | ingen `CharacterRemoving`, ingen `Humanoid.Died`, ingen `Occupant`-lyssnare i `roblox/src/server`. Bara `seat.Occupant == humanoid` inne i `dismount` |
| **`Seat:Sit(nil)`** | `HorseService.luau` rad 313 |
| **Spelare släpps in före kritisk preflight** | `init.server.luau` kallar `slappInSpelare()` före `Preflight.kor(...)`. Jag byggde det så med flit, och reviewens invändning är bättre än mitt argument |

## Länkfelet — och varför filen inte gick att hämta

Reviewen har rätt om releasehygienen, och det förklarar ett tidigare
problem. Mina release-README:er länkade till **source-committen**, men
`.rbxlx`-filen läggs in i den **följande** release-committen. Länken kunde
alltså aldrig fungera:

```
raw/46231de…/roblox/releases/first-playable-place-46231de/UBRFFirstPlayable.rbxlx
→ 404: filen finns inte i den committen
```

Det var den verkliga orsaken till att Tobias inte kom åt filen tidigare.
Jag förklarade det då som ett inloggnings-/`main`-problem. **Den
förklaringen var fel.** Canonical länk ska peka på committen som faktiskt
INNEHÅLLER filen; source-SHA står separat.

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
