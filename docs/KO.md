# Arbetskön — tilldelning före arbete

Ägare av denna fil: **ChatGPT**. Ingen annan skriver i den.

Syftet är en enda sak: **en slice är fördelad innan någon börjar bygga.**

Regler: `docs/INTEGRATION.md` § Tilldelning före arbete, § Kollisionsregeln och § En PR = ett gate-slice.

**Äger filerna** är bindande. Behöver en slice röra något utanför sin köpost ska ägarskapet utökas här först; ingen implementerande agent gör det i tysthet.

---

## Aktiv ordning — 2026-09-02

1. **F02-A — interiörens rum/topologi/fasta arkitektur — ACTIVE P0.** Claude bygger enligt issue #71.
2. **F02-B — möbler/utrustning/fixtures.** Väntar på ChatGPT PASS på F02-A.
3. **F02-C — visuell review/polish.** Väntar på F02-B och Tobias visuella feedback.
4. **G01 hästrigg / issue #31.** Separat produktionsblockerare; får inte tränga undan aktiv F02-A utan nytt Product Owner-beslut.
5. **SEC-01 / Supabase-infra.** Separat säkerhets-/redundansarbete, inte del av F02.

### Låst produktbaseline

Tobias har visuellt godkänt nuvarande byggnad/exteriör på produktion efter #66.

**Exteriören är låst under F02-A/B/C.** Ingen fasad, entré, veranda, spiraltrappa, takrelation eller situationsplan får ändras utan ett nytt konkret Product Owner-fynd.

Accepterad exteriörbas som F02-A-branchen skapades från: `7253d864ce808b56288c6950503304daa05d0893`.

---

## ACTIVE: F02-A — interiörens rum/topologi/fasta arkitektur

Ägare: **Claude**

Arbetsorder: **issue #71**  
Parent/audit: issue #65  
Branch: `claude/f02-a-interior-topology`

### Äger filerna

Primärt:
- `src/site.js`
- `src/varld3d.js`
- `roblox/buildings/`
- `roblox/tests/bygge.spec.luau`
- nya F02-specar under `roblox/tests/` om de behövs
- `docs/F02-*`
- interior-matris/inventeringsmetadata under `references/buildings/stall/` och `references/buildings/ridhus/`

Referensmedia får **läsas**, men råfoto/video ska inte modifieras i denna slice.

Om implementationen kräver en annan befintlig fil: stoppa och begär köutökning i #71 innan filen ändras.

### Beroende av

Inget kvarstående. Exteriören är visuellt accepterad och låst.

### Källordning

1. Tobias uttryckliga korrigeringar.
2. Planer/utrymningsplaner för topologi, väggar, öppningar, trappor och cirkulation.
3. Repo-foton och råvideo/nyckelrutor för synlig verklighet. Relevant rå `.mov` granskas innan ett relevant fynd lämnas som `REFERENCE GAP`.
4. Byggnadskort/interiörmatriser som index/hjälp.
5. Befintlig implementation endast som kodbas — aldrig som bevis.

Varje spatialt faktum klassas `VERIFIED`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP` eller `CONTRADICTION`.

### Klar när

- varje representerad åtkomlig zon finns i Interior Fidelity Matrix med källa + klass;
- verifierade rumsrelationer, innerväggar, öppningar, korridorer, trappor och cirkulation är implementerade;
- inga semantiska rum, exakta mått, dörrar eller symmetrier har hittats på för att fylla luckor;
- webben och Roblox använder samma spatiala fakta, inte parallella handskrivna layouter;
- exteriören är oförändrad relativt accepterad baseline;
- topology/parity-tester är gröna och relevanta falsifieringar redovisas;
- PR:n innehåller source → fact mapping, remaining gaps och `Not tested`;
- Claude stoppar vid `READY_FOR_CHATGPT_REVIEW` och anger exakt head SHA.

**Ingen möblering i F02-A utöver fasta built-ins som krävs för att definiera rummet.**

---

## F02-B — möbler/utrustning/fixtures — WAITING

Ägare: **Claude efter ChatGPT PASS på F02-A**.

Beroende av: F02-A reviewad och accepterad som tillräcklig topologibas.

Kommer att omfatta foto-/videostödda soffor, bord, stolar, bänkar, skåp, toalettinredning, sadelkammarutrustning, café/social/admin-möbler, stallutrustning, lampor, skyltar och andra verifierade fixtures.

Ingen generisk Roblox-furniture dressing. Saknas stöd för exakt placering = `REFERENCE GAP`.

---

## F02-C — visuell review/polish — WAITING

Ägare: Claude bygger reviewstödet; ChatGPT granskar; Tobias accepterar visuellt.

Beroende av: F02-B.

Mål: snabb rum-för-rum review med jämförbar kamera där källa finns och enkel rapportering av fel placering, fel objekt eller saknad geometri.

---

## G01-status

### G01-S2a — KLAR
Mergad via #55. `src/spel/skotsel.js` är pedagogisk källa och Roblox konsumerar exporterad skötseldata.

### G01-S2b — KLAR / MERGAD

Tidigare kötext som kallade S2b "aktiv" är **föråldrad och ersatt av denna filversion**.

PR #61 är mergad till `main` som `15358bc25a5230ff61cd010a3672a6ae332d68ed`.

Kanoniskt resultat:
- server-authoritative preparation;
- exakt `HorseId`-bindning;
- `waiting_model` när rätt rigg saknas;
- mount-gate före `ready_to_mount`;
- klienten presenterar serverns state/revision.

Studio/game-feel acceptance är en separat mänsklig kontroll och gör inte S2b till aktiv implementeringsslice igen.

### G01-S2c — KLAR
Mergad via #57. 33 aktiva hästar/ponnyer finns i kanonen.

### G01 hästrigg / issue #31

Separat blockerare. Öppen PR #51 är endast ett riggkontrakt/prov och **inte** en riktig produktionsrigg. PR #51 är inte aktiv eller mergeklar förrän köägarskapet beslutas separat.

---

## Separata infra-/säkerhetsspår

### SEC-01

Gästläget är avsiktligt. Säkerhetsarbete får inte råka ta bort guest mode. Separat från F02.

### Supabase-referensspegel / PR #35

Separat infra. Ingen Supabase-migration eller hemlighetshantering får blandas in i F02-A/B/C.

---

## Avvisat / superseded / reference-only

| Post | Status |
|---|---|
| PR #33 | **CLOSED — SUPERSEDED / REFERENCE ONLY**. Fynd och bevisindex får konsulteras, men grenen är inte mergebas och får inte cherry-pickas som färdig interiörsanning. |
| PR #50 | **CLOSED — SUPERSEDED / EVIDENCE ONLY**. Panelfyndet får återverifieras mot råkällan inom #71; gamla branchen ska inte mergas. |
| PR #30 | **SUPERSEDED — DO NOT MERGE** av S2b/#58/#61. |
| PR #29 | superseded av landad S2a/#55. |
| PR #67 | stängd; får inte ändra visuellt accepterad exteriör. |
| `Preparation.luau` som webbkällan | avvisat; JS/webb är pedagogisk källa. |
| Generisk/påhittad interiör eller möblering | avvisat; verkligheten är specifikationen och luckor märks `REFERENCE GAP`. |

---

## Leveransprotokoll

**CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS**

Aktuell enda implementeringsorder: **#71 / F02-A**.
