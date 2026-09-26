# UBRF — Ridskolan

Spel om Upplands-Bro Ryttarförening (ubrf.se), Husbyvägen 1A, Bro. Man rider, tränar och lär sig sköta hästar. Privat familjeprojekt.

## Läsordning före arbete

Läs först [WORKING-AGREEMENT](docs/WORKING-AGREEMENT.md). Det är huvudkällan
för nuvarande roller, behörigheter och testpolicy. Claude är oberoende
reviewer med produktions-STOPP, inte builder. Historiska uppdrag återstartas inte.

1. `docs/PRODUCT-CANON.md`
2. `docs/DELIVERY-PROTOCOL.md`
3. `docs/ASSET-SOURCE-OF-TRUTH.md`
4. `docs/ENVIRONMENT-DELIVERY.md` (senaste rollbeslut, verktyg och två spelplattformar)
5. `docs/AI-COLLABORATION.md`
6. `docs/ACTIVE-GATE.md`
7. relevant implementation-/referensdokumentation

`docs/DELIVERY-PROTOCOL.md` styr evidens och acceptans. Tobias senaste
uttryckliga beslut har högst prioritet. Miljökällor och tidigare arbete bevaras;
`docs/ENVIRONMENT-DELIVERY.md` ger inga nya parallella skrivaruppdrag.

## Låst produktkärna

- spelet ska vara **roligt att spela**,
- spelaren ska **lära sig verklig hästkunskap genom att göra**,
- **ansvaret och plikterna kring hästen är gameplay**, inte dekoration — men **manuellt utförande är frivilligt**, se nedan,
- **UBRF är den verkliga spelplatsen och verkligheten är facit**,
- **Roblox är primär spelplattform**,
- **HTML/webb är också en riktig spelbar distribution**, inte bara en intern prototyp.

Webben får användas för snabb iteration, test och delning, men Roblox får aldrig behandlas som en senare port. Samtidigt får webbversionen inte förfalla till en icke-spelbar demo.

## FUN FIRST · RIDE FIRST · LEARN NATURALLY

Produktbeslut 2026-09-14. Spelaren kommer främst för att **rida**.
Hästkunskapen ska göra ridningen bättre och mer meningsfull — inte stå i
vägen för den.

Regeln, som ersätter tolkningen att varje plikt måste utföras manuellt:

> Skötsel och ansvar kring hästen är fortsatt meningsfull gameplay, men
> **manuellt utförande är frivilligt**. Säkerhet och välfärd är det
> **aldrig**. "Rida nu" betyder att stallet förbereder hästen korrekt åt
> spelaren; den som väljer att sköta om henne själv får positiva
> relations- och känsloeffekter — inte befrielse från ett straff.

Vad det innebär i praktiken:

- förberedelser är **bonus, inte barriär**,
- hästen ska **alltid vara korrekt och säkert förberedd** när ritten börjar,
  oavsett vem som gjorde arbetet,
- spelet får **aldrig** lära ut fel hästhantering för att spara tid,
- välfärdsstopp, säkerhetsgrindar och fysisk sanning om var hästen står
  gäller **lika hårt** i båda vägarna,
- belöningen för egen omsorg ska peka **uppåt** — "jag tog extra bra hand om
  henne", aldrig "jag hoppade över, därför fungerar hon dåligt",
- den mekaniska bonusen ska hållas **liten** så att frivillig skötsel inte
  blir en optimeringsplikt.

Hitta aldrig på en UBRF-detalj för att fylla ett hål. Saknas underlag: markera `[REFERENCE GAP]` eller `[antagande]` tills verkligheten kan verifieras.

## Source of truth

Vid konflikt gäller denna ordning:

1. Tobias uttryckliga produktbeslut.
2. `docs/PRODUCT-CANON.md`.
3. verifierade referenser i GitHub under `references/`, byggnadskort och `references/SITEPLAN.md`.
4. `docs/ASSET-SOURCE-OF-TRUTH.md` och Supabase-manifestet `public.reference_assets`.
5. aktuell implementation i Roblox och HTML/webb enligt aktiv gate.
6. Drive-original endast som upstream/proveniens när materialet ännu inte migrerats.
7. antaganden — endast minimalt och tydligt markerade.

**Google Drive är inte en build-dependency.** Implementeraren ska kunna genomföra en implementation även om Drive är helt otillgängligt. Om ett viktigt material bara finns där är det `[DRIVE-ONLY]` och arbetet stoppas för just den detaljen tills materialet finns i GitHub/Supabase eller ett verifierat derivat har skapats.

## Roller, review och leverans

Följ [WORKING-AGREEMENT](docs/WORKING-AGREEMENT.md) och
[AI-COLLABORATION](docs/AI-COLLABORATION.md); upprepa inte en alternativ
rollfördelning här. Granska faktisk diff, källor och tester på exakt SHA.
Utvecklarens summary och busy process är inte bevis.
Egna reviewerprov sker endast i isolerad kopia. Ingen produktion, installation,
extra agent eller kostnad följer automatiskt av ett granskningsuppdrag.

Lämna konsoliderade reproducerbara fynd, allvar, prov och begränsningar, sedan
STOPP. Oberoende teknisk review är aldrig Tobias produktacceptans.
Skydda källfidelity, accepterat beteende, gränser mellan ryttare/session/försök
och giltig start-/slutevidens. Begär inte att implementeraren provar det
uppskjutna hela spelarflödet mellan paket.

## Plattformskontrakt

### Roblox — primär spelplattform

Följ `roblox/README.md` och `roblox/docs/HORSE-MODEL-SPEC.md`.

Roblox-spåret har två delar:
- `roblox/src/` — hästsystem och gameplay i Luau,
- `roblox/buildings/` — anläggningens Studio-byggstenar.

Prioritera mjuk/responsiv horse movement, stabil kamera, rena animation transitions, keyboard/gamepad/touch, häst/rider-loop, enkel interaction/collision, responsiv Roblox-UI, performance och UBRF-igenkänning.

### HTML/webb — spelbar parallell distribution

`src/`, `index.html`, `tools/build.py` och `dist/` utgör den spelbara HTML/webbversionen.

Webben används dessutom för snabb prototypning, QA och beteendemätning. Den ska fortsatt kunna spelas utan konto och utan Roblox-klienten där produktkraven säger det.

När logik delas mellan plattformarna: porta **avsikt, regler, parametrar och acceptance criteria**, inte implementation rad för rad.

### Paritetsregel

> **Tidsbegränsat undantag 2026-09-22 — Roblox först.** Fram till verifierad
> First Playable är Roblox enda aktiva leveransmålet. Nya webbfeatures och
> kravet att samtidigt implementera varje ny Roblox-funktion på webben är
> pausade. Webben bevaras i befintligt skick — pausen är inte tillstånd att
> radera, avveckla eller försämra den, och befintliga tester och
> regressionsskydd behålls. Delade källor, generering och export får ändras
> när det behövs, utan att en andra Luau-sanning skapas. Fullständig text och
> villkor: `docs/PRODUCT-CANON.md`, «Tidsbegränsat produktbeslut 2026-09-22».
> Återstart kräver ett nytt produktägarbeslut. Stycket nedan gäller i övrigt
> oförändrat och återfår full verkan när etappen är klar.

Kärnloop, hästlogik, lärande, ansvar, UBRF-värld och centrala gameplayregler ska motsvara varandra. Rendering, UI och inputadapter får vara plattformsspecifika.

Bygg inte en ny JS-only kärnfeature eller Roblox-only kärnfeature utan att aktivt redovisa hur motsvarande upplevelse hålls möjlig på den andra ytan. Miljöändringar ska levereras genom gemensam källstyrd miljösanning och båda plattformarnas implementation enligt `docs/ENVIRONMENT-DELIVERY.md`.

## Scope guardrail

Målet är ett **bra, lätt, responsivt ridspel** — inte en avancerad hästsimulator.

Bygg inte utan uttryckligt beslut:
- avancerad biomekanik,
- simulatornivå på dressyrfysik,
- onödiga state machines/abstraktionslager,
- stora egna fysikmotorer,
- system som gör projektet större utan tydlig spelarvinst.

## Häst/ridning — release blocker

- kontroll först, smoothness därefter, realism sist,
- snabb men mjuk styrrespons,
- bra low-speed precision,
- ingen creep/jitter,
- förutsägbar acceleration/inbromsning,
- kamera får inte göra styrningen trög,
- keyboard ska inte kännas rått binärt,
- gamepad/touch ska behålla analog precision,
- frame-rate-oberoende beteende,
- hästen får aldrig kännas som ett fordon med hästmodell ovanpå.

Förbättra befintlig arkitektur innan du uppfinner en ny.

## Byggnader och interiörer — hårdaste regeln

**Anläggningen ska kännas igen av någon som varit på UBRF. Verkligheten är facit.**

1. Öppna relevant repo-referens innan implementation.
2. Kontrollera alla tillgängliga verifierade vinklar, inte en enda bild.
3. Kontrollera relevant råfilm i `references/video/` innan en visuell/interiör detalj deklareras `REFERENCE GAP`; en panorering kan innehålla evidens som saknas i extraherade stillbilder.
4. Uppdatera byggnadskort/SITEPLAN först när ny evidens ändrar facit.
5. Koden följer kortet; kortet följer verifierat originalmaterial.
6. Verifiera visuellt från motsvarande vinkel innan "klart" — och rapportera då `READY_FOR_REVIEW`, inte egen acceptans.
7. Stiliserat betyder förenklat — inte påhittat.
8. Saknas evidens efter full källkontroll: märk `[REFERENCE GAP]`.
9. Placering på tomten styrs av verifierad `references/SITEPLAN.md`.
10. Flytta inte byggnader/dörrar/fönster/möbler för att lösa UI-/kamera-problem.

**Bilder och filmer är specifikation, inte inspiration.** Finns visuell evidens får arkitektur, interiör, färg, proportioner, öppningar, möblering eller placering inte hittas på.

## Referensmaterial och Drive

Drive-mappen `UBRF` är endast insamlings-/originalyta. När nytt material läggs där ska relevant material migreras eller härledas till GitHub/Supabase innan någon builder blir beroende av det.

Använd:
- `references/` för verifierade bilder/frames, råfilmer, kort, siteplan och licenser,
- `docs/ASSET-SOURCE-OF-TRUTH.md` för källpolicy,
- Supabase `public.reference_assets` för sökbart manifest.

Ingen builder ska instrueras att "gå till Drive" som enda väg till en build-kritisk källa. Faktisk åtkomst verifieras bara när uppgiften behöver den och inom gällande mandat; tidigare anslutningar är inte nya arbetsorder.

## Aktiv gate

`docs/ACTIVE-GATE.md` pekar ut aktuell kvalitetsgrind. Läs den före gameplay-, movement-, camera- eller inputändringar. Scope får inte expanderas utanför aktiv gate utan Tobias uttryckliga beslut. Vid inaktuellt gate-dokument gäller Tobias senaste beslut och aktuell PR-status; dokumentet ska uppdateras innan motstridig implementation fortsätter.

## Git

- arbeta på feature branch,
- beskrivande commitmeddelanden på svenska,
- ett tydligt ansvar per PR,
- undvik parallella PR:er som ändrar samma kärnfiler,
- dokumentera vad som testats **och vad som inte har kunnat verifieras**,
- fyll Acceptance Contract, testbevis, falsifieringsbevis, kvarstående risk och human-gate-status enligt `docs/DELIVERY-PROTOCOL.md`,
- merge först efter oberoende review, relevanta regressionskontroller och eventuell uttrycklig human acceptance.
