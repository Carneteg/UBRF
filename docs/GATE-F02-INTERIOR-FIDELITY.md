# Gate F02 — UBRF Interior Fidelity

**Status:** SPECIFICERAD, inte påbörjad. Öppnas som egen branch/PR **efter** att
PR #32 är mergad. Ordningen är låst i `ACTIVE-GATE.md`:
`#32 → F02 → Studio-acceptans → G01 återupptas`.

Källa: Product Owner-direktiv 2026-08-31, arkiverat här för att ett krav som
bara finns i en PR-tråd är borta nästa gång någon öppnar repot.

## Målet

Den som känner UBRF ska kunna gå genom Roblox-modellen och säga **"det här är
samma ställe"** — rum för rum, inte "en trovärdig ridanläggning".

Interiören accepteras **aldrig** på kodgranskning, testutfall eller
prosasammanfattningar. Automatiska prov får verifiera transformer och id:n;
**människans visuella PASS är auktoriteten** för topologi, möblering och
igenkänning.

## Första leverabeln: granskningsmodellen, inte möbler

Det första F02 bygger är ett **Interior Review Mode** för Studio — ett sätt för
Tobias att inspektera den rumsliga modellen utan att slåss med kamera, tak
eller väggar:

- **Cutaway/dollhouse:** tak av/på, yttervägg genomskinlig/av där det behövs,
  top-down över hela interiören, och ögonhöjd fortfarande möjlig.
- **F02-QA-panel** i F01-panelens anda, men per rum: minst en
  top-down/cutaway-kamera och en ögonhöjdskamera från den naturliga
  ankomstriktningen, rummets namn/id, källklass, PASS/FEL.
- Panelen ärver F01-panelens hårda regler: fail-closed kameranavigering och
  aldrig spelar-UI.

## Kanonisk ruminventering ur evidens

Varje rum/zon härleds ur källorna i den här ordningen:

1. `references/plans/` — rumtopologi, cirkulation, WC, trappor, öppningar
2. foton i `references/buildings/`
3. `KORT.md`-byggnadskorten
4. befintlig implementation
5. `ASSUMPTION` endast där källorna faktiskt inte avgör

Regler:

- varje rum får stabilt `RoomId`/`InteriorId`,
- **inga generiska rum** för att en ridanläggning "borde" ha dem,
- olösta ytor står kvar synligt märkta `REFERENCE GAP`/`ASSUMPTION`,
- **okänt betyder tomt/märkt — aldrig påhittat.** Visar planen ett rum men
  inte innehållet byggs det verifierade skalet och luckan markeras. Fidelity
  går före visuell fullständighet.

## Tre acceptanssteg — hoppa aldrig fram

| Steg | Innehåll | Godkänns av |
|---|---|---|
| **A — topologi/layout** | väggar, rumsstorlekar, dörrar, trappor, cirkulation, WC-lägen, öppningar. Ingen polish | Tobias, först |
| **B — möbler/inredning** | soffor, bänkar, café-/receptionsmöbler, WC-porslin, förvaring, diskar — endast där foto/plan stödjer | Tobias, efter A |
| **C — visuell fidelity** | material, färger, lister, skyltar, ljus, igenkänningsdetaljer | Tobias, efter B |

Ett senare steg får **inte** behandlas som accepterat medan ett tidigare har
olösta FEL.

## Objektspårbarhet

Varje betydande interiörobjekt bär kanoniskt id och källklass, där det är
praktiskt som attribut:

- `InteriorId`
- `RoomId`
- `EvidenceClass = VERIFIED | DERIVED | ASSUMPTION`

Syftet är att en soffa/WC/dörr ska kunna flyttas efter återkoppling utan
närmaste-objekt-gissningar — samma kontrakt som `BuildingId`+`OpeningId`
redan ger dörrarna sedan PR #32.

## Leverabler innan F02 får kallas klar

- Studio-granskningspaket med ett klick eller ett uttryckligt kommando
- komplett rum-/zoninventering med källa per post
- cutaway/top-down-vy
- kameralista per rum
- Steg A-QA-rapport
- **först efter Tobias Steg A-PASS:** Steg B; **först efter B-PASS:** Steg C
- slutlista över kvarstående `REFERENCE GAP`

## Rapportformat

Fyra sektioner, inga fler:

1. **VERIFIED byggt** — exakt vilka rum/inredningar, med filreferenser
2. **DERIVED byggt** — vad som härletts och varför
3. **REFERENCE GAPS / ASSUMPTIONS** — varje olöst punkt, uttryckligen
4. **Studio-QA-rutt** — exakt gång-/kamerasekvens för mänsklig acceptans
