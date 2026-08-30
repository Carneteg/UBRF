# Gate F01 — UBRF Fidelity

Status: **ACTIVE QUALITY GATE**
Owner: Tobias — Product Owner
Senior review: ChatGPT — Senior Game Developer / World & Environment Systems Reviewer
Implementation: Claude

## North Star

UBRF är inte inspiration till spelvärlden. **UBRF är spelvärlden.**

Målet för denna gate är att göra anläggningen så nära den verkliga UBRF-anläggningen som källmaterialet faktiskt tillåter. En modell får inte kallas "identisk", "1:1", "klar" eller "verifierad" om synliga delar fortfarande bygger på antaganden, saknat underlag eller dokumenterade avvikelser mot verkligheten.

## Arbetsregel

Verkligheten är facit. Prioritet mellan källor:

1. verifierade foton/video/planritningar i GitHub,
2. verifierade derivat och source-index i GitHub/Supabase,
3. mått som kan härledas ur flera verifierade källor,
4. Street View/satellit som dokumenterad sekundär kontroll,
5. befintlig implementation,
6. antaganden — endast som tillfällig placeholder och alltid märkta.

Google Drive får vara upstream-insamling men **får inte vara ett build-dependency**. Claude ska kunna utföra arbetet från GitHub/Supabase. Saknas material där: markera `REFERENCE GAP`; hitta inte på.

## Fidelity-status — exakt terminologi

Varje synlig arkitektur-/miljödetalj ska klassas i en av följande kategorier:

- `VERIFIED` — direkt stödd av foto/video/ritning eller flera oberoende verifierade källor.
- `DERIVED` — mått/placering härledd ur verifierade källor med dokumenterad metod och rimlig felmarginal.
- `ASSUMPTION` — rimlig men inte verifierad.
- `REFERENCE GAP` — underlag saknas; ingen detalj får hittas på för att fylla luckan.
- `CONTRADICTION` — implementationen motsägs av verifierat källmaterial.

Endast `VERIFIED` och välunderbyggd `DERIVED` får räknas som fidelity-pass.

`ASSUMPTION` och `REFERENCE GAP` är inte fel om underlag saknas, men de får aldrig döljas eller räknas som "identiskt".

`CONTRADICTION` är blockerande och ska rättas före gate-acceptans.

## Scope

Denna gate fokuserar på UBRF:s fysiska miljö:

- ridhus exteriör,
- ridhus interiör,
- stall exteriör,
- stall interiör,
- entréer, dörrar, portar och gångvägar,
- café/klubb-/entrédelar som syns i spel,
- hagar, utebanor, parkering, staket, skyltar och omgivningsobjekt,
- korrekta relativa placeringar och orienteringar,
- färger, material, fönster-/dörrrytmer och igenkänningstecken,
- Roblox och HTML/webb där samma värld representeras.

## Inte scope

Under Gate F01 ska Claude inte:

- lägga till nya gameplay-system,
- bygga nya hästmekaniker,
- ändra ridkänslan annat än om en miljökollision bevisligen blockerar playtest,
- skapa nya byggnader som inte finns i verifierat material,
- "förbättra" verkligheten estetiskt,
- göra generiska stall-/ridhuslösningar där UBRF-data finns,
- fylla reference gaps med fantasi.

Gate 01 Riding Feel pausas medan Tobias uttryckligen prioriterar Gate F01. Dess kvarvarande Roblox-touch-blocker ska inte glömmas, men ska inte styra detta arbete.

## P0 — kända fidelity blockers

### Ridhuset — interiör

`references/buildings/ridhus/KORT.md` dokumenterar verifierat material som motsäger den nuvarande implementationen. Följande ska behandlas som blockerande `CONTRADICTION` tills de är korrigerade eller motbevisade av bättre källa:

1. långsidans övre väggyta/material/färg skiljer sig från verkligheten,
2. taket saknar verifierade stål-/metallprofiler, kabelstegar och ventilation,
3. central passage/trappa med klocka saknas eller är ofullständig,
4. området vid dressyrbokstaven E har fel domarbås/trappa/exit-detaljer,
5. bakom sargen saknas verifierade glasade rum/fönsterpartier och korrekt nivåindelad träbänk/läktarmiljö.

Claude ska läsa hela `references/buildings/ridhus/KORT.md` innan implementation.

### Stallet — interiör

`references/buildings/stall/KORT.md` säger uttryckligen att nuvarande `STALLINNE` har känd fel planform. Verifierad utrymningsplan visar ett dubbelstall med fyra boxlängor och två stallgångar, medan spelet fortfarande använder en gång med två boxrader.

Detta är en blockerande `CONTRADICTION`.

Claude får inte gissa exakta boxantal/mått där källan är för svag. Gör följande i ordning:

1. bygg om endast det som kan härledas robust från verifierat material,
2. behåll osäkra exakta mått som `REFERENCE GAP`/`ASSUMPTION`,
3. dokumentera vad som fortfarande behövs för full 1:1-verifiering,
4. prioritera rätt planlogik och igenkänning före dekorativa detaljer.

### Ridhuset — exteriör

Mycket är redan förbättrat, men `KORT.md` har fortfarande antaganden/reference gaps för bland annat takfotshöjd, delar av takytan, östra gaveln och vissa långsidedetaljer. Dessa får inte kallas verifierade.

Known verified/derived features ska bevaras: fotavtryck omkring 25×75 m, vinröd vertikalt korrugerad plåt, svart list/beslag, caféannex/balkong/trappa, entrékaraktär, ridhusets verkliga orientering och 20×60-banan.

### Stallet — exteriör

Bevara verifierade igenkänningstecken: ventilationshuvraden, valvbågad fönsterrytm, förstukvist med vitt ribbräcke och ockragul dörr, spiraltrappa/balkong, snörasskydd, mörkt blågrått plåttak och verklig placering/orientering.

Östra långsidan och andra luckor som saknar underlag ska fortsatt markeras, inte hittas på.

## Obligatorisk arbetsmetod per byggnad/zon

För varje delområde ska Claude göra följande innan kod ändras:

1. Läs relevant `KORT.md`, `SITEPLAN.md`, source-index och alla tillgängliga referensfiler i GitHub.
2. Skapa en **Fidelity Matrix** med en rad per synlig komponent.
3. Klassificera varje rad som `VERIFIED`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP` eller `CONTRADICTION`.
4. Prioritera `CONTRADICTION` först.
5. Ändra modellen.
6. Rendera/testa från samma eller så nära samma kameravinkel som referensen tillåter.
7. Jämför visuellt och lista kvarvarande avvikelser.
8. Gör 1–3 korrigeringsrundor om verifierad geometri/material fortfarande avviker.
9. Uppdatera Fidelity Matrix efter implementation.

Att implementationen matchar `KORT.md` räcker inte om `KORT.md` själv innehåller en dokumenterad avvikelse mot verkligheten. Källkedjan måste hela vägen tillbaka till verifierat underlag.

## Mätning och toleranser

Målet är 1:1 där data finns, men vi ska inte låtsas ha precision vi inte har.

För `VERIFIED`/`DERIVED` geometri ska Claude redovisa:

- källa,
- nominellt mått,
- implementerat mått,
- absolut/relativ avvikelse,
- uppskattad källosäkerhet.

Ett mått kan godkännas när implementationens avvikelse är mindre än källans rimliga osäkerhet.

Färg/material ska jämföras efter spelbelysning där möjligt; rå RGB behöver inte vara identisk om slutrenderingen är den som matchar referensen.

## Roblox + webb

Roblox är primär spelplattform. HTML/webb är parallell spelbar distribution.

För världen gäller:

- samma verifierade planform,
- samma relativa byggnadsplacering,
- samma viktigaste igenkänningstecken,
- samma dörr-/gånglogik,
- samma namn,
- samma kända interiöra strukturer.

Renderingsteknik får skilja sig. Fidelity-fakta får inte skilja sig utan dokumenterad plattformsspecifik anledning.

Claude ska inte bygga två olika versioner av UBRF baserat på två olika antaganden.

## Definition of Done — per byggnad

En byggnad får status `FIDELITY READY` endast när:

- [ ] alla kända `CONTRADICTION` är lösta,
- [ ] varje synlig del är klassad,
- [ ] inga antaganden presenteras som fakta,
- [ ] verifierade proportioner/orienteringar matchar källan,
- [ ] igenkänningstecknen matchar,
- [ ] interiörens huvudsakliga planlogik matchar verifierat material,
- [ ] dörrar/entréer leder till rätt typ av verkligt utrymme,
- [ ] Roblox och webb använder samma fidelity-fakta,
- [ ] visuella jämförelser finns för relevanta referensvinklar,
- [ ] kvarvarande `REFERENCE GAP` är explicit listade.

En byggnad får status `IDENTICAL/1:1 VERIFIED` endast om den **inte har några kvarvarande synliga `ASSUMPTION` eller `REFERENCE GAP`** inom den del som påståendet gäller.

## Gate F01 — acceptance

Gate F01 kan gå till ChatGPT-review när minst:

1. Ridhus interiör: alla fem kända contradictions är implementerade eller tydligt motbevisade med bättre källa.
2. Stall interiör: den kända felaktiga en-gångsplanen är ersatt med den verifierade dubbelstall-logiken så långt materialet stöder, utan påhittade exakta detaljer.
3. Ridhus exteriör: kända verified/derived drag är regressionstestade och alla gaps fortfarande är markerade.
4. Stall exteriör: samma.
5. En gemensam fidelity matrix finns för de fyra zonerna.
6. Roblox/webb parity redovisas.
7. Build/gameflow fungerar fortfarande.
8. Inga nya gameplay-features har smugit in.

## Obligatoriskt resultatdokument

Claude ska skapa:

`audits/GATE-F01-UBRF-FIDELITY-RESULT.md`

Det ska innehålla:

- Exact commits reviewed/implemented
- Source inventory used
- Fidelity Matrix
- Before → after contradictions
- Ridhus exterior
- Ridhus interior
- Stall exterior
- Stall interior
- Roblox/Web parity
- Visual comparison evidence
- Remaining assumptions
- Remaining reference gaps
- Known limitations
- Regression tests

Claude får inte själv stänga Gate F01 eller kalla hela UBRF "100 % identiskt".

## Review protocol

1. Claude implementerar och lämnar resultatdokument + commit SHA.
2. ChatGPT gör Senior Fidelity Review av faktisk diff, source chain och bevisning.
3. Om koden bara matchar en gissning i ett dokument men inte verifierat källmaterial → FAIL.
4. Om en verifierad motsägelse återstår → FAIL.
5. När alla kända contradictions är lösta men reference gaps kvarstår → `FIDELITY READY WITH DOCUMENTED GAPS`, inte `IDENTICAL`.
6. Tobias avgör slutlig produktacceptans och kan komplettera med nya foton för att stänga återstående gaps.
