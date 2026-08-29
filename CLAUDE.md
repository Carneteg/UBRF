# UBRF — Ridskolan

Spel om Upplands-Bro Ryttarförening (ubrf.se), Husbyvägen 1A, Bro. Man rider, tränar och lär sig sköta hästar. Privat familjeprojekt.

## Produktkanon — läs först

**Läs `docs/PRODUCT-CANON.md` före allt arbete som påverkar produkt, gameplay, innehåll,
ridning, hästar, stallrutiner, progression, UX eller värld.** Det dokumentet är projektets
North Star och väger tyngre än lokala implementationer och antaganden.

Kärnan är låst:

- spelet ska vara **roligt att spela**,
- spelaren ska **lära sig verklig hästkunskap genom att göra**,
- **ansvaret och plikterna kring hästen är gameplay**, inte dekoration,
- **UBRF är den verkliga spelplatsen och verkligheten är facit**,
- webbversionen är utvecklings- och testmiljö; **Roblox är målplattformen**.

Hitta aldrig på en UBRF-detalj för att fylla ett hål. Saknas underlag: markera `[REFERENCE GAP]`
eller `[antagande]` tills verkligheten kan verifieras.

## Samarbete med ChatGPT

Läs **`docs/AI-COLLABORATION.md`** före uppgifter som rör gameplay, spelkänsla,
arkitektur, UX, större prioriteringar eller review.

Rollerna är medvetet olika:

- **Tobias** är Product Owner och har sista ordet.
- **ChatGPT** är Senior Game Director / Game Systems Architect / Reviewer och ansvarar
  främst för diagnos, prioritering, acceptance criteria och review.
- **Claude** är Lead Implementation Engineer / Builder och ansvarar främst för
  implementation, integration, testning och verifierbara repoändringar.

Repot är den gemensamma överlämningsytan. Anta aldrig att den andra modellen har gjort
eller godkänt något som inte går att verifiera i aktuell kod, commit, PR, audit eller
uttrycklig instruktion från Tobias.

**Aktuell produktprincip:** webbversionen i `src/` är den primära miljön för snabb
utveckling och test av spelupplevelsen. Roblox är målplattformen. Gameplaybeslut ska
bevisas i webben först och hållas rimligt portabla till Roblox, men flytta inte arbete
till `roblox/` om Tobias inte uttryckligen ber om det.

## Tekniken

**Roblox är målplattformen. `src/` är den primära utvecklings- och testmiljön.**

Gameplaybeslut bevisas i webbversionen först och hålls rimligt portabla till Roblox.
Flytta inte arbete till `roblox/` om Tobias inte uttryckligen ber om det.

Målet är ett **bra, lätt, responsivt ridspel** — inte en avancerad hästsimulator.
Prioritera game feel, tydlighet, stabilitet och igenkänning före systemdjup.

*(Det här ersätter formuleringen "Roblox först" från issue #12. Styrdokumenten i
`docs/` är två timmar nyare och gäller: se `docs/PRODUCT-CANON.md` och
`docs/ACTIVE-GATE.md`.)*

### Source of truth

Vid konflikt gäller denna ordning:

1. Originalfoton och originalfilmer i Google Drive-mappen `UBRF`.
2. Verifierade referenser i `references/`, byggnadskort och `references/SITEPLAN.md` som härletts ur originalmaterialet.
3. Tobias uttryckliga produktbeslut.
4. Webbversionen under `src/`, där gameplaybeslut bevisas.
5. Roblox-implementationen under `roblox/`.
6. Antaganden — endast när nödvändigt, minimalt och tydligt markerade `[REFERENCE GAP]` eller `[antagande]`.

**Bilder och filmer är specifikation, inte inspiration.** Finns visuell evidens får arkitektur, interiör, färg, proportioner, öppningar, möblering eller placering inte hittas på.

## Roller och samarbete

### Tobias — Product Owner

- Bestämmer scope och prioritering.
- Avgör subjektiv game feel i faktisk Roblox Studio-playtest.
- Godkänner större designförändringar.
- Håller spelet på Roblox-nivå; ingen simulator-expansion utan uttryckligt beslut.

### ChatGPT — Architect / Reference Custodian / QA Lead

- Läser Google Drive-material och repo parallellt.
- Förvaltar visuell sanning och pekar ut referensluckor.
- Skriver acceptance criteria och prioriterar arbete.
- Granskar Claude Codes PR:er för arkitektur, scope, regressioner och referensfidelitet.
- Skriver normalt inte parallellt i samma produktfiler som Claude Code arbetar i.
- Får skapa governance-, audit- och referensdokument samt separata korrigerings-PR:er.

### Claude Code — Primary Implementer

- Äger implementationen på feature branch, i det spår den aktiva gaten pekar ut
  (`docs/ACTIVE-GATE.md`).
- Bygger mot beslutad task och acceptance criteria; expanderar inte scope på eget initiativ.
- Får använda Sonnet-subagenter för analys/test, men en huvudagent äger integrationen.
- Kör de automatiska tester som går att köra utanför Studio, och Luau-kompilering
  när arbetet rör `roblox/`.
- Skriver uttryckligen vad som **inte** kunnat verifieras utan Roblox Studio.

### Arbetsloop

1. ChatGPT: referens-/arkitekturanalys + tydlig brief.
2. Claude Code: implementation på egen branch.
3. Claude Code: PR med testbevis, ändrade filer och kända Studio-begränsningar.
4. ChatGPT: PR-review av kod, scope och referensfidelitet.
5. Tobias: subjektiv Roblox Studio-playtest när känsla/visuell träff måste avgöras.
6. Fynd tillbaka till Claude Code som konkreta korrigeringar.

Ingen agent får både införa en större förändring och ensam slutgodkänna den.

**Aktiv kvalitetsgrind:** `docs/ACTIVE-GATE.md` pekar ut vilken gate som gäller nu,
och dess brief är kanon för scope. Läs den före ändringar i gameplay, rörelse,
kamera eller inmatning.

## Roblox — primär teknik

Följ `roblox/README.md` och `roblox/docs/HORSE-MODEL-SPEC.md`.

Roblox-spåret har två separata delar:

- `roblox/src/` — hästsystemet och gameplay i Luau.
- `roblox/buildings/` — byggstenar för anläggningen i Studio.

Behåll befintliga bra gränser: Input → Movement → State/Animation/Rider/Camera, RigAdapter som modellgräns och klientägd lokal rörelse med servervalidering.

### Scope guardrail

Prioritera:

- mjuk och responsiv horse movement
- stabil kamera
- rena animation transitions
- keyboard/gamepad/touch
- häst/rider-loop som fungerar varje gång
- enkel interaction och collision
- anläggning som känns igen från UBRF
- responsiv Roblox-UI
- enkelt test/demo-flöde där relevant
- performance och stabilitet

Bygg inte utan uttryckligt beslut:

- avancerad hästbiomekanik
- simulatornivå på dressyrfysik
- onödiga state machines eller abstraktionslager
- egna stora fysikmotorer när Roblox redan löser problemet bra
- nya JS-only features
- system som gör projektet större utan tydlig spelarvinst

## JS-spåret — referens/prototyp

`src/`, `index.html`, `tools/build.py` och `dist/` får användas för att bevara tidigare spelmekanik, mäta beteenden, jämföra geometri och återanvända verifierad domänlogik. De är inte längre produktens primära destination.

När en gammal JS-funktion ska till Roblox: porta **avsikten och verifierade regler**, inte implementationen rad för rad.

## Byggnader och interiörer — hårdaste regeln

**Anläggningen ska kännas igen av någon som varit på UBRF. Verkligheten är facit.**

1. Öppna relevant foto/video innan implementation.
2. Kontrollera alla tillgängliga vinklar, inte en enda bild.
3. Uppdatera byggnadskort/SITEPLAN först när ny evidens ändrar facit.
4. Koden följer kortet; kortet följer originalmaterialet.
5. Verifiera visuellt från motsvarande vinkel innan "klart".
6. Stiliserat betyder förenklat — inte påhittat.
7. Saknas evidens: använd minsta neutrala antagande och märk `[REFERENCE GAP]`.
8. Placering på tomten styrs av verifierad `references/SITEPLAN.md`.
9. Flytta inte byggnader, dörrar, fönster eller möbler för att lösa UI-/kamera-problem. Lös UI/kamera separat.

## Google Drive-referenser

Google Drive-mappen `UBRF` innehåller original-HEIC och MOV samt andra underlag. ChatGPT kan läsa och analysera dessa via den anslutna Drive-källan och för in verifierade observationer i repoets referenslager.

Claude Code ska **inte gissa** om den själv saknar åtkomst till Drive. Använd då `references/DRIVE-SOURCE-INDEX.md`, befintliga sorterade bilder/frames och byggnadskorten; markera luckor och lämna dem till ChatGPT/Tobias för referenskontroll.

Originalmedia behöver inte dupliceras i GitHub bara för att koden ska byggas. För in härledda fakta, valda referensframes och tydlig proveniens.

## Movement quality — release blocker

För Roblox-ridningen gäller:

- kontroll först, smoothness därefter, realism sist
- snabb men mjuk styrrespons
- bra low-speed precision
- ingen synlig creep/jitter
- förutsägbar acceleration och inbromsning
- kamera får aldrig göra styrningen trög
- keyboard ska inte kännas binärt trots digital A/D
- gamepad/touch ska behålla analog precision
- frame-rate-oberoende beteende

Förbättra befintlig arkitektur innan du uppfinner en ny.

## Git

- Arbeta på feature branch.
- En implementation/ett tydligt ansvar per PR.
- Undvik parallella PR:er som ändrar samma kärnfiler.
- Beskriv vad som testats och vad som kräver Roblox Studio.
- Mergas först efter review och relevanta regressionskontroller.
- Issue #12 beskriver den aktuella AI-arbetsfördelningen och Roblox-first-beslutet.
