# Direkt visuell referens — stallets frontfasad från Google Maps

Datum: 2026-08-30
Källa: Google Maps/Street View-skärmbild uppladdad direkt av Product Owner i ChatGPT-konversationen.
Evidensklass: **DIRECT VISUAL SOURCE / PRODUCT OWNER SUPPLIED**.

Den här filen är en build-accessible verifierad derivatbeskrivning av den uppladdade bilden. Exakta meter ska inte läsas ur perspektivbilden utan separat mätning. Däremot är fasadkomposition, relativ form och tydliga objekt direkt observerbara.

## Kritisk slutsats

Nuvarande spelmodell av denna synliga stallgavel/fasad är en **KNOWN MISMATCH**. Den blandar sannolikt drag från andra sidor av byggnaden och reproducerar inte den Google Maps-vy som spelaren jämför mot.

## Direkt observerbara skillnader

### 1. Takform och gavelproportion
- Verkligheten: gaveln är tydligt lägre och flackare/squattare i proportion till husets bredd.
- Spelet: gaveln läser mycket högre och takfallet visuellt betydligt brantare.
- Åtgärd: bygg om proportionen mot fotot; lås inte exakt vinkel från perspektivbilden utan mät/derivera försiktigt.

### 2. Extern trappa — fel typ och fel placering
- Verkligheten: på den synliga frontgaveln finns en **rak/diagonal metalltrappa** upp till en dörr på övre planet, placerad ungefär i den centrala delen av gaveln.
- Spelet: visar en **spiraltrappa** på vänster del av samma gavel.
- Detta är en tydlig `KNOWN MISMATCH` för just denna fasad. Om spiraltrappa finns på annan verklig sida ska den ligga där, inte flyttas till denna frontgavel.

### 3. Fönster- och dörrkomposition på gaveln
- Verkligheten, övre nivå: en välvd/arched öppning till vänster, en övre dörr därefter, samt två välvda fönster till höger.
- Spelet: har en annan ordning/antal och större glapp mellan öppningarna.
- Verkligheten, nedre nivå: flera välvda fönster ligger i en tätare och annorlunda rytm än spelmodellen.
- Åtgärd: mappa öppningarna direkt från fotot, inte från en generisk symmetrisk gavelmall.

### 4. Takventilation — fel identitet
- Verkligheten: en tydlig **sammanhängande/koncentrerad rad av ventilationshuvar/öppningar** ligger längs den långa takytan nära nocken.
- Spelet: läser som många separata små skorstenar/ventstaplar med annan silhuett.
- Åtgärd: använd fotots faktiska ventilationssilhuett och rytm.

### 5. Förstukvist / låg gavelvolym mot framsidan
- Verkligheten: en tydlig lägre gavel-/entrévolym med vitt räcke och stolpar ligger framför/vid högra delen av stallfasaden och påverkar hela byggnadens silhuett.
- Spelet: verandan/entrévolymen har annan placering, längd och proportion och läser mer som en lång sidoporch.
- Åtgärd: bygg denna del efter fotots faktiska footprint och taklinje; använd inte den nuvarande verandan som facit.

### 6. Huvudbyggnadens höjd och massa
- Verkligheten: frontgaveln är lägre i förhållande till bredd och öppningar; takfot och fönster ligger närmare varandra än i spelmodellen.
- Spelet: fasaden är visuellt för hög och öppningarna sitter för glest.

### 7. Färg/listverk
- Den övergripande mörkröda färgriktningen är nära, men spelets vita hörn-/taklist läser betydligt grövre och mer grafisk än fotot.
- Detta är sekundärt efter form, trappa och öppningar.

## Source-priority rule for this facade

För **den här kameravyn/fasaden** vinner denna direkta Google Maps-bild över äldre `ASSUMPTION`, generisk lågpoly-geometri och detaljer som råkat flyttas från andra fasader.

Claude ska därför inte "bevara" spiraltrappan på denna gavel bara för att en spiraltrappa är verifierad någonstans på stallet. Varje identifierande detalj måste sitta på rätt verklig fasad.

## Required implementation method

1. Mark current front-gable implementation as `KNOWN MISMATCH`.
2. Reconstruct the facade composition from this source before further cosmetic polish.
3. Correct in this order:
   1. roof/gable proportion,
   2. straight external stair + upper door,
   3. exact visible window/door rhythm,
   4. porch/low gable volume,
   5. roof ventilation silhouette,
   6. trim/material polish.
4. Keep uncertain absolute dimensions as `ASSUMPTION`; do not infer exact metres from perspective alone.
5. Put shared facade facts into canonical/exportable data so **web and Roblox build the same facade**.
6. Produce a side-by-side screenshot from the closest practical in-game camera angle before calling this facade corrected.

## Acceptance for this facade

- no spiral stair on this visible front gable unless a direct source proves it;
- straight/diagonal external stair and upper door read in the correct relative location;
- roof/gable silhouette matches the photograph materially;
- visible arched-window count/order and entrance composition match the photograph;
- porch/low gable volume reads in the correct place and proportion;
- roof ventilation reads as the same visual system as the photograph;
- Roblox and web agree on the corrected facade;
- remaining unmeasured dimensions remain explicitly `ASSUMPTION`.