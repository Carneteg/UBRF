# UBRF — Ridskolan

Spel om Upplands-Bro Ryttarförening (ubrf.se), Husbyvägen 1A, Bro. Man rider, tränar och
lär sig sköta hästar. Privat familjeprojekt.

## Tekniken

Ett HTML5-spel som byggs till **en enda fil**: `tools/build.py` fogar ihop `index.html` och
`src/*.js` till `dist/ridskolan.html`. Ingen CDN, inga externa filer, inget nätverk vid körning.
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
