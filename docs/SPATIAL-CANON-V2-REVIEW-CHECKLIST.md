# Spatial Canon v2 — Review Checklist

Används av ChatGPT vid senior review och av Tobias vid produktacceptans.

## Stall

- [ ] Uppehållsrummet läser som en sammanhängande öppen L-formad yta.
- [ ] Ingen intern fullhöjdsvägg/sluten volym delar uppehållsrummet.
- [ ] Spelaren kan gå från parkeringens entré genom uppehållsrummet till inre stallentrén utan artificiell korridor.

## Ridhus

- [ ] Entré-/receptionsområdet läser som öppen hall, inte ett nät av rumslådor.
- [ ] Receptionens verifierade avgränsning är glasad.
- [ ] Funktionsetiketter har inte skapat väggar automatiskt.
- [ ] Huvudentré -> öppen hall -> arena access -> ridyta är visuellt och fysiskt sammanhängande.
- [ ] Ingen opaque vägg blockerar vägen till ridytan.
- [ ] Om exakt vägg/glas saknar evidens är den markerad REFERENCE GAP, inte gissad.

## Proveniens

- [ ] Alla WALL/GLASS i contested areas har canon_id/source_id/confidence.
- [ ] Webb och Roblox använder samma canon-id:n.
- [ ] OPEN_AREA/NO_WALL_ZONE är testbara i båda plattformarna.

## Regression

- [ ] STALL-V1 jämförd mot föregående underkända preview.
- [ ] RIDHUS-V1 jämförd.
- [ ] RIDHUS-V2 jämförd.
- [ ] RIDHUS-V3 jämförd.
- [ ] Mutationer för återkallade väggar ger röda tester.

Ingen merge innan relevanta punkter är gröna och Tobias uttryckligen godkänt den visuella modellen.
