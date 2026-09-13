# UBRF — miljöansvar och två spelplattformar

Status: processförslag enligt Tobias beslut 2026-09-07. Gäller omedelbart som senaste produktinstruktion i berörda uppdrag; införlivas i huvudkanon efter review. `docs/DELIVERY-PROTOCOL.md` styr leveransgater och Tobias behåller produktacceptans. Detta dokument ersätter äldre uppdragskommentarer som tilldelar Claude interiörbygget eller förbjuder Replit att implementera miljön.

## Produktkontrakt

UBRF är ett lätt, roligt ridspel där spelaren lär sig hästkunskap och ansvar genom att göra. Den verkliga anläggningen är facit. Roblox är primär spelplattform och HTML/webb är en fullvärdig, parallell spelbar distribution. Ingen av dem får reduceras till en senare port, statisk demo eller enbart QA-yta. Miljö, hästar, lektioner, interaktioner och centrala regler ska motsvara varandra; renderer, UI och inputadapter får vara plattformsspecifika.

En miljöleverans är inte färdig för oberoende review förrän samma källstyrda miljöändring finns i båda spelbara versionerna, eller en uttryckligt godkänd plattformsspecifik avvikelse är dokumenterad. Webbscreenshots eller grön CI bevisar inte Roblox Studio-funktionalitet.

## Ansvar och arbetsfördelning

**Tobias — Product Owner:** bestämmer mål, prioriteringar, verklighetsfakta vid motstridiga källor, game feel och slutligt produktgodkännande.

**ChatGPT — orkestrator, senior Game Director och arkitekt:** bestämmer arbetsordning, scope, filägarskap, acceptance contract, integreringsgater och oberoende review. Granskar faktiska diffar, originalkällor, testbevis och båda plattformarna. Skriver inte parallellt i en aktiv builders kärnfiler. Kan delegera smala uppgifter till andra agenter utan att skapa en andra huvudutvecklare.

**Replit — Lead Environment & World Builder:** äger källstyrd rekonstruktion av hela UBRF: terräng, nivåskillnader, vägar, parkering, staket, grindar, byggnaders exteriörer och interiörer, material, möbler, utrustning, skyltar, belysning och miljörekvisita. Äger även miljöasset-pipeline, källinventering, referensjämförelser, miljöprestanda och export till webb/Roblox. Får implementera miljöproduktkod inom tilldelad branch och scope. Är inte begränsad till QA eller teorisalen.

**Claude — Lead Gameplay & Integration Engineer:** äger häst- och ryttarstyrning, fysik/animation, kamera och input, ridning, lektioner, interaktionernas beteende, lärande, progression, sparning, spel-UI och teknisk integration mellan miljö och gameplay. Ansvarar för att spelmekaniken fungerar i både webb och Roblox. Får inte bygga en konkurrerande miljö eller ändra Replits aktiva miljöfiler utan uttrycklig omfördelning. Hjälper till med integrationskontrakt och verifiering av miljön i riktig gameplay.

Replit och Claude kan arbeta parallellt på skilda ansvarsområden. Miljödata, objekt-ID:n, interaktionsankare och spatiala kontrakt är gemensamma gränssnitt, inte två konkurrerande sanningar. Samma fil får bara ha en aktiv skrivande ägare. Delade ändringar förbereds av ägaren och integreras efter samordnad review; inga samtidiga omskrivningar eller osamordnade cherry-picks.

## Gemensam verktygskedja

Båda agenterna ska känna till och använda hela den godkända verktygskedjan. Tillgång i ChatGPT eller en annan agent innebär dock inte automatiskt att just deras session har samma autentisering. Kontrollera faktisk åtkomst innan en uppgift påstås vara blockerad eller genomförd.

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
8. Lämna `READY_FOR_CHATGPT_REVIEW` med Changed, Source evidence, Tested, Falsified, Not tested, Remaining risk, Human gate och SHA. Endast ChatGPT kan ge oberoende review-PASS och endast Tobias kan ge `PRODUCT_ACCEPTED`. Ingen självacceptans eller merge före gaterna.

## Aktuella arbetsströmmar

Miljöspår: PR #131 → draft-PR #132, befintlig Replit-app och branch `replit/pr-131-theory-fidelity`. Senast verifierade käll-audit-head vid detta beslut: `93b43fe706115a116bdac185ac2d8da13411169c`. Replit ska först verifiera ny aktuell head och eventuell pågående uppgift. Teorisalen är nästa avgränsade miljöslice; därefter prioriteras övriga byggnader och området genom källstyrd avvikelsematris. Uppehållsrummets öppna L-form, saknad ridhusplan och motstridiga dörr-/passagelägen är fortsatt separata blockerare för geometriändring.

Gameplayspår: PR #128 / issue #126. Claude behåller detta spår och dess blockerande Ugneta-review. Ingen miljöomfördelning ger tillstånd att stänga gameplayfelet eller ändra dess produktregler.

Tidigare kommentarer om att Claude ska äga teorisalsimplementationen är återkallade av Tobias nyare beslut. Claude ska inte börja den gamla interiörbriefen. Replit ska inte vänta på en Claude-ACK för att påbörja sin separata, godkända miljöslice. Varje aktiv builder ska däremot själv kvittera sin branch, head, scope och ägarskap före kodning.

Detta är ett processdokument, inte produktacceptans, en geometriändring eller tillstånd att mergea befintliga PR:er.