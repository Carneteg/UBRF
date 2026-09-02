# Arbetskön — tilldelning före arbete

Ägare av denna fil: **ChatGPT**. Ingen annan skriver i den.

Syftet är en enda sak: **en slice är fördelad innan någon börjar bygga.**

Regler: `docs/INTEGRATION.md` § Tilldelning före arbete, § Kollisionsregeln,
§ En PR = ett gate-slice.

## Så skrivs en köpost

    ### <gate>-<slice> — <en rad om vad som ska bli sant>
    Ägare: Claude | ChatGPT | Tobias | Integrationsledare
    Äger filerna: <exakta sökvägar eller mappar>
    Beroende av: <slice eller PR som måste in först, eller "inget">
    Klar när: <mätbart, med kommando eller mänsklig gate>

**Äger filerna** är bindande. En PR som rör filer utanför sin köpost är inte
färdig — den är ofördelad, och integrationsledaren skickar tillbaka den.

Är en fil redan deklarerad i en annan öppen post eller PR gäller
kollisionsregeln: den öppna posten äger filen.

## Aktiv ordning — 2026-09-02

1. **G01-S2b** — aktiv nästa gameplay-slice. Claude bygger enligt issue #58.
2. **G01 hästrigg / issue #31** — separat produktionsblockerare som kan drivas parallellt men krävs för full spelbar ridloop.
3. **F02** — fortsätter efter G01-S2b när spelvärdesloopen inte längre väntar på preparation.
4. **SEC-01 / Supabase-infra** — säkerhets- och redundansarbete får inte tränga undan den spelbara hästloopen.

## Beslutade slices

### G01-S2a — skötseln som delad kanonisk data — KLAR

Ägare: ChatGPT genom Product Owners uttryckliga undantag.
Levererad via scope-ren ersättare och mergad till `main` genom PR #55.

Kanoniskt resultat:
- `src/spel/skotsel.js` är pedagogisk källa.
- Webben och Roblox delar samma regler via export.
- Roblox har separat genererad `UBRFSkotsel`-modul.
- Huvud = endast mjuk borste; ben = ingen gummiskrapa; visitation har exakt ett rätt svar.

Gamla #29 är stängd och får inte återupplivas.

### G01-S2b — Roblox preparation läser skötseln ur exporten — AKTIV

Ägare: **Claude**.
Arbetsorder: **issue #58**.
Gamla PR #30 är stängd som **SUPERSEDED — DO NOT MERGE** och får endast användas som referens/salvage.

Äger filerna i den rena slicen:
- `roblox/game/Stallet.luau`
- `roblox/src/client/GameplayController.luau`
- `roblox/src/client/InteractionController.luau`
- `roblox/src/client/init.client.luau`
- `roblox/src/server/GameplayService.luau`
- `roblox/src/server/StallService.luau`
- `roblox/src/server/init.server.luau`
- `roblox/src/shared/HorseCore/Networking.luau`
- `roblox/src/shared/HorseCore/Preparation.luau`
- `roblox/src/shared/HorseCore/init.luau`
- `roblox/tests/build.py`
- `roblox/tests/gameplay.spec.luau`
- `roblox/tests/hud.spec.luau`
- `roblox/tests/interaktion.spec.luau`
- `roblox/tests/kor.sh`
- `roblox/tests/preparation.spec.luau`
- `roblox/tests/spel-assignment.spec.luau`
- `roblox/tests/stubs-gameplay.luau`

Får **inte** återinföra `roblox/docs/G01-HORSE-IDENTITY-CONTRACT.md` som konkurrerande kopia; kontraktet finns redan i `main`.

Beroende av: **inget kvarstående**. S2a (#55) och S2c (#57) är mergade.

Klar när:
- kedjan `Hälsa lugnt → Visitera → Rykta → Gör i ordning → Sitt upp` är server-authoritative;
- `Preparation.luau` hämtar faser/ordning/text ur exporterade `UBRFSkotsel`, inte egna literaler;
- `StallService` äger tilldelad kanonisk `HorseId`;
- `GameplayService` binder endast exakt matchande Horse-taggad rigg med samma `HorseId`;
- saknas matchande rigg blir läget `waiting_model`, aldrig närmaste/fel häst;
- `HorseService` är fortsatt enda mount/dismount/riding-authority;
- två spelare får aldrig samma aktiva hästidentitet;
- mount före `ready_to_mount`, på fel häst eller på annan spelares häst avvisas server-side;
- HUD fungerar vid 320 px samt på mobil/iPad/dator;
- sen init/refresh kan inte skriva över nyare serverfeedback;
- acceptance- och falsifieringsfallen i issue #58 är körda;
- relevanta Luau-, export-, webb-, Rojo-, material- och package-grindar är gröna på exakt PR-head.

Beslut (Tobias): **JS är källan, Roblox läser.** Det omvända är avvisat.

### G01-S2c — hästkanon utökad till hela stallet — KLAR

Ägare: ChatGPT genom Product Owners uttryckliga undantag.
Mergad till `main` genom PR #57.

Kanoniskt resultat:
- exakt 33 aktiva UBRF-hästar/ponnyer: 18 hästar + 15 ponnyer;
- verklighetsfakta matchar versionssnapshot/live-underlag;
- `UNTUNED` används där gameplayprofil inte är beslutad;
- lektionsrotationen innehåller endast giltiga tunade id:n;
- `UBRFSpelData` och `UBRFSkotsel` är separerade;
- gamla felidentiteter/save-minnen migreras utan att relationer flyttas till fel verklig häst;
- individuella fodergivor är uttryckligen övningsdata/`ASSUMPTION` tills verkliga givor verifierats.

Databasen är upstream för fakta, inte direkt gameplay-authority.

### G01-blockerare — hästriggen byggs

Ägare: Tobias (produktion), ChatGPT (kravspec).
Äger: issue #31 och `roblox/` riggmapp när riktig produktionsrigg finns.
Beroende av: inget, men full G01 efter S2 vilar på den.

Klar när en riggad hästmodell med minst skritt, trav och galopp går att importera i Studio och driva från befintlig movement-kod enligt hästriggskravspecen.

Öppen PR #51 är ett riggkontrakt/prov, inte själva riggen. Den är inte automatiskt aktiv eller mergeklar bara för att S2b startar.

### F02-underlag — ridhusets referenser och interior review

Ägare: Integrationsledaren / separat F02-kö.

Källordning:
- `references/buildings/ridhus/`
- `references/video/`
- `references/DRIVE-INVENTORY-2026-08-30.md`
- `references/DRIVE-SOURCE-INDEX.md`

Råfilm ska granskas innan relevant detalj får lämnas som `REFERENCE GAP`.
De sex rummen i ridhusets entréblock och stallets Plan 2 får fortsätta vara `REFERENCE GAP` när beviset verkligen är uttömt; Tobias kan inte förväntas fotografera om materialet.

PR #33 kräver mänsklig Studio-gate och får inte beskrivas som accepterad bara för att automatiska tester är gröna.

### SEC-01 — gästläget dokumenteras som avsiktligt

Ägare: Integrationsledaren.
Äger: `supabase/migrations/` och relevanta säkerhetsavsnitt i docs.
Beroende av: inget.

Klar när `public.ny_ryttare()` har dokumenterad motivering och spärr mot massanrop, samt kvarstående advisor-varningar är kvitterade.

Beslut (Tobias): gästläget är avsiktligt just nu; säkerhetsarbetet får inte råka ta bort guest mode.

### Supabase-referensspegel

PR #35 äger sin migration/infrastruktur. Den privata hinken och manifestreglerna finns, men binärspegeln är fortfarande operativt separat från G01. Ingen får lägga Supabase-migrationsarbete i S2b för att "passa på".

## Avvisat / superseded

| Förslag | Status / varför | När |
|---|---|---|
| `Preparation.luau` som källa, export till webben | avvisat — webben/JS är pedagogisk källa | 2026-08-31 |
| Merga gamla PR #30 | **SUPERSEDED** av issue #58; gammal bas och gammal exportarkitektur | 2026-09-02 |
| Återuppliva #29 som S2a | superseded; S2a landad genom #55 | 2026-09-01 |
| Kurerat urval i kanonen i stället för hela stallet | avvisat; 33 aktiva ska finnas i kanonen | 2026-08-31 |
| Återuppliva #9 | gammal och ersatt av senare Gate 01-arbete | 2026-08-31 |
| Merga #32 "för säkerhets skull" | #33 innehåller dess arbete enligt tidigare integrationskontroll | 2026-08-31 |
