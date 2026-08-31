# Gate F02 — UBRF Interior Fidelity

## Så kör du Fas 1-granskningsläget

Samma paket som F01-QA:n: `python3 tools/studio-paket.py`, klistra in i en
**ren** place (förkontrollen säger till annars). F01-panelen öppnas som
vanligt. Skriv sedan i Command Bar:

```
UBRFF02()
```

Då byggs zonplattorna (gult = `PLAN`, grönt = `FOTO`, blått = `DERIVED`,
rött = `REFERENCE GAP`; **byggda ytor är nedtonade, obyggda lyser**), taken
göms, och panelen byter till interiörvyerna — två kameror per zon, uppifrån
och i ögonhöjd, med källklassen i vytexten. `UBRFDollhouse(false)` sätter
tillbaka taken; `UBRFDollhouse(true)` tar av dem igen.

I Fas 1 bedöms **bara** rumsgränser, cirkulation, dörr-/trapp-/WC-lägen och
öppningar. En röd platta är en dokumenterad lucka — den bedöms som lucka,
inte som slarv.

---

**Status:** Fas 1-granskningsläget byggt, väntar på #32-merge och därefter
Tobias Steg A-granskning. Öppnas som egen branch/PR **efter** att
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

1. **råmaterialet** — foton i `references/buildings/` **och råfilmerna i
   `references/video/`**. Filmerna är facit, inte proveniens: stillbilderna är
   utplock ur dem och urvalet kan ha missat det du letar efter
2. `references/plans/` — rumtopologi, cirkulation, WC, trappor, öppningar
3. verifierade derivat: `KORT.md`-byggnadskorten, `INTERIOR-MATRIS.md`
4. befintlig implementation
5. `ASSUMPTION` endast där steg 1–4 är uttömda och det syns att de är det

Regler:

- **inget `REFERENCE GAP` sätts innan råfilmerna är genomsökta.** Kör
  `tools/videobevis.py` och skriv in film + bildruteintervall i
  `docs/F02-BEVISINDEX.md`. Ett gap utan den noteringen är ogranskat, inte
  belagt,
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
