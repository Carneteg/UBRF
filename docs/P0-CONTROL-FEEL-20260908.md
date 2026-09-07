# P0 — Styrkänsla, 2026-09-08

## Beslut och avgränsning
Tobias rapporterade för känslig rörelse och svår styrning. Detta är en avgränsad input-fix, inte ett byte av ridmodell eller en godkänd spelrelease. Bas: `2131dee12263d627f74a3c40721d007d341311df`. Implementerad källcommit: `d7420034fc5e92799dffd41b777b71ac3bcc7ea4`.

## Mätning och ändring
Den gamla digitala gångstyrningen hade 5,5 rad/s svängtak, acceleration 8 och broms 13. Ett W+D-prov vid 60 FPS gav cirka 28,1° efter 0,1 s och 39,3° efter 0,2 s. Den nya inputformen använder 3,0 rad/s, acceleration 5,5, broms 9, tidskonstant 0,12 s och analog dödzon 0,12. Digital ridstyrning använder förstärkning 0,42 och en mjuk ramp; analoga och direkta modellprov behåller fullt omfång. Hästens kurvaturkanon, gångarter, individuella egenskaper och bedömning är oförändrade. Värdena är första kalibreringskandidater, inte en påstått perfekt ridkänsla.

## Bevis
- 11 källbaserade inputregressioner passerade på den faktiska integrerade koden: korta tryck, full digital nivå, analogt omfång, släpp, riktningsbyte, bildrutetakt, dödzon, proportionell analog respons, diagonal och oförändrad fysikkanon.
- GitHub Actions `34170348669` byggde sidan, körde 8 webbstartskontroller och 22 första-dagen-kontroller utan pageerror. Första dagen omfattade gäststart, Jack, utrustning, skötsel, ledning, sargport, uppsittning och dubbeltryck.
- Första-dagen-testet använder verkliga UI-handlingar men flyttar spelaren mellan stationerna. Det verifierar inte gångvägarna, hela lektionen, avsittning, eftervård, sparning eller nytt pass.
- Den lokala sandlådans Chromium blockerade både file:// och localhost med ERR_BLOCKED_BY_ADMINISTRATOR. Ingen separat lokal GUI-verifiering görs anspråk på utifrån dessa försök.

## Återstående P0-grind
Kör det ordinarie fullständiga QA-flödet samt tre oberoende tester av riktig väg/navigering, ridning till lektionsslut och touch. Inga manuellt satta tillstånd får ersätta uppsittning i end-to-end-godkännandet. Kontrollera också att E-prompten försvinner efter uppsittning, att kamera inte orsakar oönskad sväng, att tangentbyte/touch inte lämnar kvar input och att fokusförlust stoppar rörelse. Fysisk Roblox Studio, verklig iPad och subjektiv game feel är NOT_TESTED. Ingen PRODUCT_ACCEPTED, main-merge eller publik launch innan blockerarna är stängda och Tobias godkänt spelkänslan.
