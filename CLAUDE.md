# UBRF — Ridskolan

Spel om Upplands-Bro Ryttarförening (ubrf.se), Husbyvägen 1A, Bro. Man rider, tränar och
lär sig sköta hästar. Privat familjeprojekt.

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

Ett HTML5-spel som byggs till **en enda fil**: `tools/build.py` fogar ihop `index.html` och
`src/*.js` till `dist/ridskolan.html`. Ingen CDN, inga externa filer.

**Local-first.** `localStorage` är sanningen och hela spelet fungerar utan nät. `src/synk.js`
lägger en frivillig molnsynk ovanpå (Supabase-projektet `UBRF`, tabellerna i
`supabase/migrations/`) så att man kan rida på mobilen i stallet och fortsätta på datorn.
Den är aldrig ett krav: utan inloggning, utan nät eller med trasig server spelar man precis
som förut, och varje anrop i den filen får misslyckas tyst. Synken pratar med REST- och
auth-slutpunkterna över vanliga `fetch`-anrop — **dra aldrig in `supabase-js`**, det vore ett
externt beroende och bryter regeln om en enda fil.
3D-delen är en egen WebGL-motor i `src/gl.js` — inget Three.js, inga färdiga modellformat.
Geometri byggs i kod med `Bygge` (lådor, klot, cylindrar, svepta ytor).

### Två spår i samma repo

`src/`, `index.html` och `tools/build.py` är **JS-spelet** ovan. `roblox/` är ett
**separat Roblox-spår** i Luau, med ett eget hästsystem för riggade modeller. De
delar ingen kod. Det enda gemensamma är siffrorna: gångarternas tempoband i
`roblox/src/shared/HorseCore/Gaits.luau` är portade från `src/model.js`, som i sin
tur var en port från Luau.

Roblox-spåret har i sin tur två fristående delar: `roblox/src/` är hästsystemet
och `roblox/buildings/` är byggstenar för anläggningens hus. De delar ingen kod.

Arbetar du i `src/` gäller reglerna nedan. Arbetar du i `roblox/` gäller
`roblox/README.md` — nämn aldrig `Bygge`, `STIL` eller `tools/build.py` där, och
nämn aldrig `BuildKit.luau` eller studs här.

Kör lokalt: `python3 tools/build.py && python3 -m http.server 8931`, öppna
`http://localhost:8931/dist/ridskolan.html`. Skärmdumpar tas med Playwright
(`executablePath:"/opt/pw-browsers/chromium"`).

## Grafisk stil

`STIL` i `src/ljus.js` styr formspråket. `"kloss"` betyder: **figurerna är klossiga,
världen är lågpolygon med plana ytor.** Hästen, träden och rekvisitan får sin form av
fasettering — samma anatomi, färre segment, en egen normal per triangel (`glPlatta`).
Ryttaren och figurerna till fots är rätblock. Det är den kombinationen förlagan använder.

Alla färg- och ljusvärden ligger i `src/ljus.js`. Ändra där, ingen annanstans.
**Ryttarens egna färger** — hy, hår, kavaj, byxor, hjälm — hör inte hemma där utan
i `src/jag.js`, för de är spelarens val och inte världens ljus. Skriv aldrig in dem
i `kloss.js` eller `scen3d.js`: bägge bygger ryttaren ur paletten de får in, och det
finns två uppsättningar delar — `S3.del` för de andra eleverna och `S3.del.jag` för
spelaren. Rör du den ena, rör du inte den andra.
UI:ts formspråk är `ui-kit-demo.html` — dess variabler är utbrutna till `src/ui.css`
och ska inte redigeras där.

## Byggnader — den viktigaste regeln

**Anläggningen ska kännas igen av någon som varit på UBRF.** Byggnaderna ritas i spelets
stil, men proportioner, färger, takform, fönster- och portplacering och placering på tomten
ska stämma med verkligheten. Verkligheten är facit. Fotona i `references/buildings/` är
facit. Gissa aldrig — titta.

### Hårda regler

1. **Bygg aldrig en byggnad utan att först ha öppnat dess foton** (`Read` på varje JPG i
   `references/buildings/<byggnad>/`). Alla foton, inte bara det första.
2. **Bygg aldrig utan ett ifyllt byggnadskort** (`references/buildings/<byggnad>/KORT.md`).
   Saknas det: fyll i det först med `/fotoanalys <byggnad>`. Kortet är kontraktet — mått,
   färger, takvinkel, antal fönster, portar, detaljer. Koden följer kortet, kortet följer fotona.
3. **Verifiera visuellt innan du säger "klart".** Ta en skärmdump från samma vinkel som
   referensfotot, lägg dem bredvid varandra och lista avvikelserna konkret
   ("taket är för flackt — foto ~25°, modell ~40°"). Rätta. Minst en runda, oftast två–tre.
4. **Stiliserat ≠ påhittat.** Förenkla detaljer, men ändra aldrig form, antal, färgton
   eller proportioner. Har ridhuset röd plåtfasad och ljust tak har det det i spelet också.
5. **Namnge som i verkligheten.** Ridhuset, Stallet, Ridbanan — aldrig "Byggnad1".
6. **Hitta inte på.** Saknas ett foto för en fasad: säg det, bygg den som spegling av
   motsatta sidan och markera `[antagande]` i kortet. Be om ett foto.
7. **Mått i meter, överallt.** Samma tal i kortet, i `ANL` (`src/world.js`) och i
   `src/varld3d.js`. Ingen omräkning.
8. **Placering på tomten** styrs av `references/SITEPLAN.md`.

### Arbetsflöde per byggnad

`/fotoanalys <byggnad>` → granska kortet med Tobias → `/bygg-byggnad <byggnad>` →
jämför mot foto → justera → commit.

## Foton

Källa: Google Drive-mappen `UBRF` (HEIC från iPhone). **HEIC kan inte läsas** — konvertera
alltid först med `tools/convert-photos.sh`, och sortera in i
`references/buildings/<byggnad>/` med namnet `<byggnad>-<fasad>-<nr>.jpg`.
Konverteringen måste göras lokalt: `drive.google.com` och `facebook.com` är blockerade av
nätverksproxyn i den här miljön, och Drive-anslutningen returnerar filinnehåll som base64
vilket inte fungerar för fotostora filer.

Klubbens Instagram @ubrflikeshorses och Facebook finns som extra referens, men fotona i
repot är de primära.

## Git

Utveckla på den anvisade grenen, committa med beskrivande meddelanden på svenska, pusha,
och håll utkasts-PR:en uppdaterad.
