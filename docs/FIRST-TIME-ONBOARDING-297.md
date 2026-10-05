# #297 — Förstagångsvägen: en tydlig väg, utan skötsel och ledning

Ersätter formuleringarna i `UI1-START-CHOICE-CONTRACT.md`, `UI1-WEB-START-CHOICE-CONTRACT.md`,
`ONBOARDING-STEP-CARD-CONTRACT.md` och `WEB-P1A-STABLE-FLOW-CONTRACT.md` där de säger
«Välj hur du börjar», «Gör i ordning själv» eller att uppsittningskortet pekar på boxen.
Produktbeslutet 2026-10-04 (ledning och manuell skötsel borttagna) är oförändrat.

## Bakgrund

Ett förstagångsbarn på iPad förstod inte hur man «förbereder» hästen. Det är ett produktfel:
spelaren ska inte förbereda hästen alls — stallet gör det.

## Vägen (Roblox och webb)

`tilldelad häst → gå till hästen (dörr vid behov) → RIDA NU → stallet gör hästen redo → hon väntar i ridhuset → SITT UPP → ritt/lektion`

| Läge | Kort | Handling |
|---|---|---|
| Hästen långt bort, stängd dörr | **Öppna stalldörren** | — |
| Hästen långt bort | **Gå till {häst}** — «Följ den gyllene pilen till boxen.» | — |
| Vid hästen, inget gjort | **Dags att rida** — «{häst} är din häst idag. Du behöver inte sadla eller tränsa själv — stallet gör {häst} redo.» | exakt en: **Rida nu — {häst}** (`InteractionController.ridaNu` / `stegkortRidaNu`) |
| Efter Rida nu, vid hästen | **Sitt upp på {häst}** — «{häst} är klar och väntar i ridhuset. Välj «Sitt upp».» | Roblox: raden «Sitt upp» i panelen. Webb: knappen **Sitt upp på {häst}** (samma grind som världens prompt, `sittUpp`) |
| Efter Rida nu, spelaren långt från ridhuset (Roblox) | **Gå till {häst}** — «{häst} är klar och väntar i ridhuset. Följ den gyllene pilen dit och välj «Sitt upp».» | — |

Texten är könsneutral (inget «hon/henne/she/her» om hästen) eftersom hästarna har olika kön.

## Revisionens fynd (vad som ändrades)

1. Ett enval-kort hade rubriken «Välj hur du börjar» och en text som inte sa att man slipper sadla.
2. Efter Rida nu står hästen i ridhuset, men en spelare kvar vid boxen fick «Följ pilen till boxen» (Roblox).
3. Webbens uppsittningskort hade ingen knapp — bara en hålltangent-prompt i världen, svår att hitta på touch.

## Det som INTE ändrats

Ingen manuell förberedelse, ingen ledning, inga extra val. Äldre skötselkort (hälsa, rykta, hovar, hämta
sadel/träns, led) ligger kvar i koden men nås inte från förstagångsvägen; proven kräver att inga
skötsel- eller ledhandlingar syns på vägen. #292 (upprepad ritt, «Rida nu» efter räknat pass) är orört.

## Prov

- Roblox: `roblox/tests/klient-guide.spec.luau` sektion 9 (9a–9m) och de uppdaterade raderna i sektion 4–5.
- Webb: `tools/stegkorttest.mjs` sektion A, C, E och **H (touch, iPad liggande, bara pekskärm)**.
- Falsifierat: gamla rubriken, ett andra val, gammal «till boxen»-text, saknat hästnamn, Rida nu som inte går via `ridaNu`,
  webbens «Sitt upp» utan knapp.
