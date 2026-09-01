# UBRF — Ridskolan

Spel om Upplands-Bro Ryttarförening (ubrf.se), Husbyvägen 1A, Bro. Man rider, tränar och lär sig sköta hästar. Privat familjeprojekt.

## Läsordning före arbete

1. `docs/PRODUCT-CANON.md`
2. `docs/DELIVERY-PROTOCOL.md`
3. `docs/ASSET-SOURCE-OF-TRUTH.md`
4. `docs/AI-COLLABORATION.md`
5. `docs/ACTIVE-GATE.md`
6. relevant implementation-/referensdokumentation

`docs/DELIVERY-PROTOCOL.md` är bindande för status, evidens, falsifiering, review, human acceptance och merge. Om äldre dokument antyder att implementerande agent själv kan slutgodkänna sitt arbete gäller leveransprotokollet.

## Låst produktkärna

- spelet ska vara **roligt att spela**,
- spelaren ska **lära sig verklig hästkunskap genom att göra**,
- **ansvaret och plikterna kring hästen är gameplay**, inte dekoration,
- **UBRF är den verkliga spelplatsen och verkligheten är facit**,
- **Roblox är primär spelplattform**,
- **HTML/webb är också en riktig spelbar distribution**, inte bara en intern prototyp.

Webben får användas för snabb iteration, test och delning, men Roblox får aldrig behandlas som en senare port. Samtidigt får webbversionen inte förfalla till en icke-spelbar demo.

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

**Google Drive är inte en build-dependency.** Claude ska kunna genomföra en implementation även om Drive är helt otillgängligt. Om ett viktigt material bara finns där är det `[DRIVE-ONLY]` och arbetet stoppas för just den detaljen tills materialet finns i GitHub/Supabase eller ett verifierat derivat har skapats.

## Roller och samarbete

### Tobias — Product Owner
- bestämmer scope och prioritering,
- godkänner större designförändringar,
- avgör subjektiv game feel,
- håller projektet på Roblox-spelsnivå snarare än simulatornivå.

### ChatGPT — Senior Game Director / Game Systems Architect / Reviewer
- diagnostiserar systemsamband och root causes,
- skriver acceptance criteria och gates,
- förvaltar produkt-/referenskanon,
- reviewar faktisk diff, testbevis, scope, regressioner och plattformsparitet,
- skriver normalt inte parallellt i samma kärnfiler som Claude arbetar i.

### Claude — Lead Implementation Engineer / Builder
- implementerar aktiv gate på feature branch,
- verifierar observationer mot aktuell kod före ändring,
- testar gameplay, inte bara lint/compile,
- använder Sonnet-subagenter om det hjälper men en huvudagent äger integrationen,
- lämnar bevis, kända begränsningar och commit-SHA,
- expanderar inte scope på eget initiativ.

### Arbetsloop
1. Tobias anger mål/problem.
2. ChatGPT diagnos + brief + acceptance criteria.
3. Claude implementerar och testar.
4. Claude lämnar audit/evidence.
5. ChatGPT gör senior review av diff och spelproblem.
6. Tobias avgör accept/ny iteration.

Ingen agent får både införa en större förändring och ensam slutgodkänna den.

## Leveransauktoritet — hårda regler

**CLAUDE BUILDS → CHATGPT REVIEWS → TOBIAS ACCEPTS.**

- Claude får aldrig själv sätta slutstatus `APPROVED`, `ACCEPTED`, `DONE`, `CLOSED` eller `FINAL` på sin egen större leverans.
- Claudes högsta normala status är `READY_FOR_CHATGPT_REVIEW`.
- ChatGPT kan efter oberoende review sätta `READY_FOR_PRODUCT_ACCEPTANCE`.
- Endast Tobias får sätta `PRODUCT_ACCEPTED` när human acceptance krävs.
- Merge, grön CI eller grön lokal testsvit är **inte** i sig produktacceptans.
- Varje icke-trivial leverans ska ha Acceptance Contract enligt `docs/DELIVERY-PROTOCOL.md` innan implementationen expanderar.
- Claude ska aktivt falsifiera centrala tester; ett test som aldrig visats kunna bli rött är otillräcklig evidens för en kritisk gate.
- Claude ska uttryckligen redovisa `Not tested`; frånvaro av tillgång till Studio/runtime får aldrig omskrivas till PASS.
- ChatGPT-review ska utgå från faktisk diff och relevanta källor, inte Claudes summary.
- Visuell fidelity, game feel och målmiljöflöden kräver Tobias uttryckliga PASS där Acceptance Contract säger det.

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

Kärnloop, hästlogik, lärande, ansvar, UBRF-värld och centrala gameplayregler ska motsvara varandra. Rendering, UI och inputadapter får vara plattformsspecifika.

Bygg inte en ny JS-only kärnfeature eller Roblox-only kärnfeature utan att aktivt redovisa hur motsvarande upplevelse hålls möjlig på den andra ytan.

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
6. Verifiera visuellt från motsvarande vinkel innan "klart" — och rapportera då `READY_FOR_PRODUCT_ACCEPTANCE`, inte egen acceptans.
7. Stiliserat betyder förenklat — inte påhittat.
8. Saknas evidens efter full källkontroll: märk `[REFERENCE GAP]`.
9. Placering på tomten styrs av verifierad `references/SITEPLAN.md`.
10. Flytta inte byggnader/dörrar/fönster/möbler för att lösa UI-/kamera-problem.

**Bilder och filmer är specifikation, inte inspiration.** Finns visuell evidens får arkitektur, interiör, färg, proportioner, öppningar, möblering eller placering inte hittas på.

## Referensmaterial och Drive

Drive-mappen `UBRF` är endast insamlings-/originalyta. När nytt material läggs där ska relevant material migreras eller härledas till GitHub/Supabase innan Claude blir beroende av det.

Använd:
- `references/` för verifierade bilder/frames, råfilmer, kort, siteplan och licenser,
- `docs/ASSET-SOURCE-OF-TRUTH.md` för källpolicy,
- Supabase `public.reference_assets` för sökbart manifest.

Claude ska aldrig instrueras att "gå till Drive" som enda väg till en build-kritisk källa.

## Aktiv gate

`docs/ACTIVE-GATE.md` pekar ut aktuell kvalitetsgrind. Läs den före gameplay-, movement-, camera- eller inputändringar. Scope får inte expanderas utanför aktiv gate utan Tobias uttryckliga beslut.

## Git

- arbeta på feature branch,
- beskrivande commitmeddelanden på svenska,
- ett tydligt ansvar per PR,
- undvik parallella PR:er som ändrar samma kärnfiler,
- dokumentera vad som testats **och vad som inte har kunnat verifieras**,
- fyll Acceptance Contract, testbevis, falsifieringsbevis, kvarstående risk och human-gate-status enligt `docs/DELIVERY-PROTOCOL.md`,
- merge först efter oberoende review, relevanta regressionskontroller och eventuell uttrycklig human acceptance.
