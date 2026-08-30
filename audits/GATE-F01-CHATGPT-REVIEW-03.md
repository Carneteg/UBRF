# Gate F01 — ChatGPT Senior Fidelity Review 03

Status: **FIDELITY READY WITH DOCUMENTED GAPS — PRODUCT OWNER STUDIO VISUAL ACCEPTANCE REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `56b023df8f67b987e2ac7c9c6df7999fa2b6e794`

## Executive verdict

Review 02:s två blockerare är lösta och den nya direkta satellitreferensen har dessutom korrigerat den viktigaste kvarvarande felplaceringen i byggnadskomplexet.

Jag hittar ingen kvarvarande känd Gate F01-motsägelse som motiverar ännu en kodändringsrunda.

Detta är **inte** ett påstående om att UBRF är 100 % identiskt. Exakta mått och flera detaljområden är fortfarande `ASSUMPTION`/`REFERENCE GAP`, och Roblox Studio har ännu inte använts för mänsklig visuell slutkontroll.

Gate F01 går därför vidare till **Product Owner visual acceptance in Roblox Studio**, inte till automatisk stängning.

---

## 1. Satellite correction — PASS

Den Product Owner-levererade satellitbilden visar direkt att:

- ridhus och stall är två parallella huvudvolymer,
- en tvärgående taktäckt förbindelse binder ihop dem,
- förbindelsen ligger centralt i den gemensamma längden, inte vid en ände,
- mellanrummet delas i två öppna gårdsytor.

Den gamla nordliga placeringen är nu uttryckligen `KNOWN MISMATCH`/historik och är borttagen ur aktiv implementation.

Implementation:

- `hastgang` flyttad till y `89.3–92.8`,
- stallets verifierade tvärkorridor och husens gemensamma mitt pekar mot samma område,
- måtten för själva gången är fortfarande korrekt klassade som `ASSUMPTION`,
- exakt en byggnadsvolym binder ihop ridhus och stall,
- den separata låga längan i söder verifieras i test som **inte** en andra förbindelse.

Bedömning: **PASS**.

---

## 2. The connector is functional, not decorative — PASS

Efter flytten hittade Claude själv ett viktigt funktionellt fel: ridhusets sarg var obruten framför hästgången. Det innebar att spelaren kunde nå ridhussidan av förbindelsen men inte banan.

Det är nu rättat genom en separat `sargGrind`, gemensam för:

- webbkollision,
- webbrendering,
- 2D-karta,
- Roblox-export,
- Roblox-byggare.

Funktionstestet verifierar vägsökning och gångbarhet åt båda håll. Grinden är markerad `ASSUMPTION` i bredd eftersom källan verifierar behov/topologi, inte exakt mått.

Bedömning: **PASS**.

---

## 3. Stable planform and width evidence chain — PASS WITH DOCUMENTED GAP

Review 02 krävde att den gamla 21-metersslutsatsen inte längre skulle ligga kvar som aktiv kanon.

Det är nu korrigerat:

- fyra boxrader + två gångar: `VERIFIED`,
- bandens inbördes proportioner: `VERIFIED`,
- totalbredd: **inte fastställd**,
- 21 m: explicit **arbetsvärde / `ASSUMPTION`** inom dokumenterat intervall,
- det tidigare felaktiga `3.5 m × sex band = 21 m`-argumentet ligger endast i markerad överspelad historik,
- nockhöjd/taklutning som beror på bredden har nedgraderats i samma källkedja.

Detta är korrekt evidenshantering. Ett verkligt uppmätt mått behövs fortfarande för att ersätta arbetsvärdet.

Bedömning: **PASS WITH DOCUMENTED GAP**.

---

## 4. Roblox environment parity — PASS STRUCTURALLY / VISUAL ACCEPTANCE PENDING

Review 02 underkände Roblox-spåret eftersom det bara byggde exteriöra skal trots att interiördata fanns exporterad.

Det är nu löst.

`Anlaggningen.luau` konsumerar den exporterade strukturen och bygger minst följande fidelity-kritiska delar:

### Stall

- fyra boxrader,
- två stallgångar,
- boxfack/fronter,
- genomgående tvärkorridor,
- tvärväggar med verkliga gångöppningar,
- de namngivna huvudrummen från planunderlaget.

### Ridhus

- 20 × 60-banan,
- sarg och portar/grind,
- läktarsektioner med gap för hästgången,
- glasade rum,
- domarbås/exit-identitet,
- klocka och övriga gate-kritiska strukturdrag som exporterats.

Den deterministiska kedjan är fortsatt:

`src/site.js → tools/exportera-geometri.js → UBRFKomplex.luau → Anlaggningen.luau`

Det finns alltså inte två handunderhållna plan-sanningar.

Roblox-byggbänken kör byggskriptet mot stubbar och har fångat verkliga geometri-/blockeringsfel. Senaste redovisning visar gröna geometri-, bygg- och funktionstester.

**Kvar:** verklig Roblox Studio-rendering och mänsklig visuell jämförelse har inte körts i Claudes miljö. Det är inte längre en kodparitetsblocker för denna review, men det är ett blockerande steg innan Product Owner kan slutacceptera miljön.

Bedömning: **PASS STRUCTURALLY — STUDIO VISUAL ACCEPTANCE PENDING**.

---

## 5. Ridhus known contradictions — PASS WITH SOURCE LIMITATION

De fem tidigare kända interiörmotsägelserna är fortsatt byggda och har inte regressat i den granskade kedjan:

1. mörkröd/maroon övre långsida,
2. metallprofiler/kabelstegar/ventilation,
3. klocka vid passage/trappa,
4. mörkt bås/trappa/exit-identitet vid E,
5. glasade rum/sektioner bakom sarg/läktarmiljö.

Exakt placering/antal/mått för flera av dessa är fortfarande baserade på verifierat textderivat eftersom originalbilderna inte är build-accessible. Auditen klassar detta korrekt.

Bedömning: **PASS WITH DOCUMENTED SOURCE GAP**.

---

## 6. Regression and scope — PASS

Ingen orelaterad gameplay-expansion har införts. Riding Feel-arbetet har inte blandats in i Gate F01.

Senaste rapporterade gröna kontroller inkluderar:

- entréer/dörrar,
- stallplan,
- ridhusinteriör,
- exteriörer,
- viewport/ridloop/ryttare,
- Roblox-geometri,
- Roblox-byggmodell,
- hästgång funktionellt åt båda håll.

Bedömning: **PASS**.

---

## Remaining documented gaps — not blockers for Review 03

Följande får inte beskrivas som verifierat/identiskt:

1. stallets exakta totalbredd och längd,
2. hästgångens exakta bredd, djup, höjd, takform och öppningsmått,
3. bredden på läktargapet och sarggrinden,
4. flera ridhusinteriördetaljers exakta mått/placering eftersom originalbilderna fortfarande inte är build-accessible,
5. vissa fasader/takytor där källmaterial saknas,
6. Roblox Studio visuell rendering från motsvarande referensvinklar.

Dessa är korrekt `ASSUMPTION`/`REFERENCE GAP`, inte kända motsägelser.

---

## Required Product Owner acceptance step

Innan Gate F01 stängs eller PR #22 behandlas som slutligt visuellt godkänd:

1. bygg `Anlaggningen.luau` i Roblox Studio,
2. kontrollera från minst:
   - satellit/översiktslik vy,
   - grusplanen mot huvudbyggnaderna,
   - de två gårdsytorna med hästgången emellan,
   - inne i stallgång A/B och tvärkorridoren,
   - inne i ridhuset mot läktare/E/hästgång,
3. verifiera att hästgången faktiskt kan användas från stall → ridhus → bana och tillbaka,
4. Tobias avgör subjektivt om komplexet känns igen som UBRF.

Om Studio-kontrollen visar en ny verklighetsmotsägelse öppnas en riktad Fidelity fix. Om den visuella kontrollen är grön kan Gate F01 stängas som:

**FIDELITY READY WITH DOCUMENTED GAPS**

— aldrig som `100 % IDENTICAL` så länge dokumenterade reference gaps finns.

## Final Review 03 decision

**PASS FOR IMPLEMENTATION REVIEW.**

**Next state: PRODUCT OWNER STUDIO VISUAL ACCEPTANCE.**

Do not start another speculative geometry pass before that visual acceptance. The current remaining unknowns should stay documented rather than be guessed.