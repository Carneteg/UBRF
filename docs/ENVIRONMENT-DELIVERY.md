# UBRF — miljöansvar och två spelplattformar

Status 2026-09-26: käll- och integrationskontrakt. Nuvarande ansvar och
behörigheter finns i [WORKING-AGREEMENT](WORKING-AGREEMENT.md). De tidigare
Replit/Claude-tilldelningarna är historik, inte parallella skrivmandat.

## Produktkontrakt

UBRF är ett lätt, roligt ridspel där spelaren lär sig hästkunskap och ansvar genom att göra. Den verkliga anläggningen är facit. Roblox är primär spelplattform och HTML/webb är en fullvärdig, parallell spelbar distribution. Ingen av dem får reduceras till en senare port, statisk demo eller enbart QA-yta. Miljö, hästar, lektioner, interaktioner och centrala regler ska motsvara varandra; renderer, UI och inputadapter får vara plattformsspecifika.

> **Tidsbegränsat produktbeslut 2026-09-22 — Roblox först.** Fram till
> verifierad First Playable är Roblox enda aktiva leveransmålet, och kravet på
> samtidig webbimplementation är pausat. Det räknas som den uttryckligt
> godkända avvikelsen nedan och ska redovisas som en avvikelse, aldrig som
> genomförd paritet. Webben bevaras i befintligt skick. Se
> `docs/PRODUCT-CANON.md`, «Tidsbegränsat produktbeslut 2026-09-22».

> **Ägarskap efter överlämning 2026-09-26:** aktuell ensam skrivare och
> oberoende reviewer följer arbetsöverenskommelsen. Skydda Replits och andra
> skrivares befintliga filer, referenser och accepterade innehåll. Läs verklig
> status och filägarskap innan någon miljöfil ändras; allmän rollövergång är
> inte tillstånd att skriva över oöverlämnat eller smutsigt arbete.

En miljöleverans är inte färdig för oberoende review förrän samma källstyrda miljöändring finns i båda spelbara versionerna, eller en uttryckligt godkänd plattformsspecifik avvikelse är dokumenterad. Webbscreenshots eller grön CI bevisar inte Roblox Studio-funktionalitet.

## Ansvar och arbetsfördelning

Följ [WORKING-AGREEMENT](WORKING-AGREEMENT.md). Miljödata, objekt-ID:n,
interaktionsankare och spatiala kontrakt är gemensamma gränssnitt, inte två
konkurrerande sanningar. Samma fil har en aktiv skrivare. Delade ändringar
integreras efter oberoende review, utan osamordnade cherry-picks.

## Gemensam verktygskedja

Använd endast de delar av den godkända verktygskedjan som uppgiften kräver. Tillgång i ChatGPT eller en annan agent innebär dock inte automatiskt att just deras session har samma autentisering. Kontrollera faktisk åtkomst innan en uppgift påstås vara blockerad eller genomförd.

| Tjänst | Avsedd användning | Verifieringskrav |
| --- | --- | --- |
| Google Drive | Upstream-original: foton, råfilmer, planer, PDF:er och modellmaterial. | Läs relevant UBRF-mapp och öppna ett verkligt original med befintlig auktoriserad anslutning. Inventering av filnamn är inte innehållsverifiering. |
| GitHub | `Carneteg/UBRF`: kanonisk kod, referenser, styrdokument, branches, PR:er och spårbar evidens. | Läs repo och aktuell branch/head; verifiera skrivbehörighet endast när ett godkänt skrivuppdrag kräver det. |
| Supabase | Befintligt UBRF-projekt `tdznhaybxmekznasxtts`: speldata, Storage och `public.reference_assets`. | Verifiera projektidentitet och läs manifest/schema via befintlig anslutning. Skapa inte nytt projekt eller ändra RLS, nycklar, schema eller data för att lösa åtkomstproblem. |
| Vercel | Befintligt UBRF-projekt: officiell webbpreview och deployment, byggstatus och exakta SHA:er. | Läs befintlig projekt/deployment-status. Kontrollera att spelbar preview och evidens gäller samma produktcommit. |
| Replit | Befintlig UBRF-utvecklingsmiljö, miljöbygge, rendering, tester och källarbete. | Fortsätt befintlig app/repo och tilldelad branch. Ingen ny fristående spelkopia eller alternativ produktionshosting. |

Använd tillgängliga anslutningar, pluginverktyg eller befintlig lokal konfiguration. Om en anslutning saknas: undersök dokumenterade alternativ, rapportera exakt fel och be orkestratorn lösa åtkomsten. Begär inte nycklar i chatten, kopiera inte hemligheter till GitHub och sänk aldrig säkerheten. Ingen agent får påstå att den har testat en anslutning som den endast fått beskriven. Dokumentera `VERIFIED`, `UNAVAILABLE` eller `NOT TESTED` per session och tjänst.

Drive är originalarkiv men aldrig enda build-dependency. Material som behövs för att bygga ska migreras eller härledas till GitHub/Supabase med proveniens, verifieringsstatus och rättigheter enligt `docs/ASSET-SOURCE-OF-TRUTH.md`. Saknad binär eller motsägande källa är en markerad lucka, inte tillstånd att gissa.

## Miljöbyggets leveranskontrakt

1. Kontrollera aktivt uppdrag, aktuell repo-head, öppna PR:er och filägarskap. Ingen duplicerad branch eller konkurrerande implementation.
2. Läs relevanta original och råfilmer i Drive/GitHub/Supabase, byggnadskort, siteplan och låsta geometrier. Skilj verifierat mått från fotobaserad uppskattning. Källkonflikter stoppas för just den detaljen och lyfts till Tobias via ChatGPT.
3. Dela arbetet i små, visuellt bedömbara zoner. Förbättra först källstyrda material, möbler och detaljer där geometri redan är låst. Utöka inte scope automatiskt till osäkra rum eller byggnader.
4. Ändra gemensam miljösanning och härled båda plattformarnas implementation där det är möjligt. Håll koordinater, skala, objektnamn, öppningar och interaktionsankare konsekventa. Ingen webb-only miljöfeature utan Roblox-leveransplan och ingen Roblox-only miljöfeature utan motsvarande webbplan.
5. Bevara accepterad läktare, byggnadsgeometri, collision, öppna passager och tidigare underkända sikt-/rumsskaleproblem. Förbättra inte en bild genom att flytta en verklig dörr, vägg eller byggnad utan källstöd.
6. Optimera draw calls, material/texture-budget, meshkomplexitet, LOD/culling och mobilprestanda när det ger faktisk spelarvinst. Behåll läsbarhet, funktion och källtrogenhet. Mät hellre än att gissa; skapa ingen onödig simulatorarkitektur.
7. Kör bygg-, miljö-, geometri-, paritets- och relevanta gameplayregressioner. Falsifiera kritiska skydd. Skapa källkopplade före/efter-bilder från samma kameror och exakt ren produkt-SHA. Kontrollera faktiskt spelbar webbpreview på Vercel; Roblox-export/specs samt verklig Studio-/touch-test redovisas separat.
8. Lämna `READY_FOR_REVIEW` med Changed, Source evidence, Tested, Falsified, Not tested, Remaining risk, Human gate och SHA. Endast den oberoende granskaren kan ge review-PASS och endast Tobias kan ge `PRODUCT_ACCEPTED`. Ingen självacceptans eller merge före gaterna.

## Historiska arbetsströmmar (inte aktuella order)

2026-09-07 beskrev detta dokument miljöspåret PR #131/#132 på
replit/pr-131-theory-fidelity (då inventerat på 93b43fe) och gameplay
PR #128/issue #126. Dessa hänvisningar bevaras för spårbarhet, inte som
nya order till Replit eller Claude. Status på gamla grenar/PR:er måste
kontrolleras före eventuell återanvändning; inget stängs, flyttas eller
raderas inom dokumentstädningen.

Nuvarande arbetsindex är [ACTIVE-GATE](ACTIVE-GATE.md). Den här filen är
varken produktacceptans, geometriändring eller publicerings-/mergetillstånd.
