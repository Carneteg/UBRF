# Gate G01 — First Playable Horse Loop

**Status:** ÖPPEN. Skiva 1 av 6 levererad.

Gate F01 är **`HUMAN_STUDIO_ACCEPTED / CLOSED`** sedan 2026-08-30: Tobias körde
Studio-genomgången med 11/11 vyer PASS och gångvägen PASS. Ingen
byggnadspolering görs medan G01 är aktiv. En stängd gate öppnas av ett konkret
fel, inte av att något kan bli snyggare.

## Målet

UBRF ska sluta vara främst en arkitektonisk rekonstruktion och börja bli ett
spelbart hästspel. Den minsta kompletta loopen:

```
ankomst → stallet → få en häst → gå fram till henne → göra i ordning
       → leda ut → ridhuset → sitta upp → EN enkel övning
       → tillbaka → sitta av → eftervård → återkoppling
```

Spelaren ska redan efter ett varv förstå: **att ha en häst är både roligt och
ett ansvar.**

## Utgångsläget

Webben har hela loopen. Roblox hade bara ridningen.

| | webb | Roblox före G01 |
|---|---|---|
| häströrelse | ja | **ja** (Gate 01, pausad men klar) |
| hästroster | 17 riktiga UBRF-hästar | ingen — `HorseStats` stod på "Namnlös"/"Warmblood" |
| tilldelning | ja | nej |
| skötsel, rykt, sadling | ja (`moment.js`, 751 rader) | nej |
| övning och lärare | ja (`ovningar.js`, `larare.js`) | nej |
| eftervård och återkoppling | ja (`efter.js`) | nej |
| progression | ja (`ryttare.js`, `framsteg.js`) | nej |

## Arkitektur

Samma pipeline som geometrin, för att den är bevisad:

```
src/spel/*.js                     kanonisk speldata
      │
      ├─→ webben läser direkt
      └─→ tools/exportera-spel.js  →  roblox/game/UBRFSpel.luau
                                          │
                                          └─→ ReplicatedStorage
```

`--kontrollera` fäller om de glidit isär. **Regler och parametrar delas.
Rendering, UI och input är plattformsspecifika** — paritetsregeln i CLAUDE.md.

Ren logik ligger i `roblox/game/`, utan Roblox-anrop, så att den går att
falsifiera utan Studio. `roblox/src/server/` gör instanserna. Den uppdelningen
är avsiktlig: regler ska gå att prova härifrån, en ProximityPrompt går inte.

## Skivorna

Vertikalt, och spelet ska vara körbart efter var och en.

- [x] **S1 — hästarna blir riktiga, och en av dem blir din**
      Kanonisk roster delad till Roblox. Tilldelning vid ankomst, box utmärkt
      med hästens namn.
- [ ] **S2 — fram till hästen och göra i ordning**
      Grimma, ryktning, hovar. Reglerna finns i `moment.js` och ska delas.
- [ ] **S3 — leda ut och in i ridhuset**
      Hästgången blir en väg som används, inte bara byggs.
- [ ] **S4 — sitta upp och en enkel övning**
      Kopplar ihop G01 med den redan byggda häströrelsen.
- [ ] **S5 — tillbaka, sitta av, eftervård**
      Ansvaret efter passet, inte bara före.
- [ ] **S6 — återkoppling och det du lärde dig**
      Progression, delad med webbens `framsteg.js`.

## Designprinciper

Roblox-spel, inte simulator för proffsryttare. Men hästbeteende, terminologi,
stallrutiner och ansvar ska vara grundade i verkligheten.

Lätt att förstå · mjukt · responsivt · roligt för barn och unga · lärorikt utan
att kännas som skola · visuellt tydligt · förlåtande för nybörjare · utbyggbart
mot djupare ridmekanik senare.

## Vad som INTE får hittas på

Samma regel som i F01: hitta aldrig på en UBRF-detalj för att fylla ett hål.

Hästarnas namn, ras, födelseår och beskrivningar är **verklighet** — ordagranna
från ubrf.se/hastar. De får inte skrivas om för att låta bättre i spelet.

Parametrarna 0–1 är **spelvärden**, satta för att hästarna ska kännas olika att
rida. De får justeras för game feel.

**Boxfördelningen är `[antagande]`.** Det finns inget verifierat underlag för
UBRF:s faktiska fördelning. Fördelningen i spelet är mekanik — stabil, spridd
över stallets fyra rader, och utbytbar den dag verkligheten säger något annat.

## S1 — vad som gjordes

`src/spel/hastar.js` är nu kanonisk källa för `HORSES`, `FODERSCHEMA` och
`KRAFTVAL`. De låg tidigare i `src/data.js` och `src/sysslor.js`, alltså bara i
JS. Webben läser samma data som förut.

`tools/exportera-spel.js` skriver `roblox/game/UBRFSpel.luau`: 17 hästar med
namn, ras, lynne, färger som `Color3` och foderrader. Exporten fäller om ett
häst-id inte duger som Roblox-attribut, och om foder och hästar går isär.

`roblox/game/Stallet.luau` — ren logik: boxrutnätet härlett ur den mätta
stalldatan (4 rader × 12 = 48 boxar), stabil tilldelning per spelare, och
`dagensHast()` som ger allt på en gång.

`roblox/src/server/StallService.luau` — tilldelar vid ankomst, sätter en
ProximityPrompt vid rätt box med hästens namn, och svarar klienten över
`MinHast`. Klienten frågar, servern bestämmer — samma regel som uppsittningen.

`roblox/tests/spel.spec.luau`, 17 assertions. Fyra falsifieringar körda; en av
dem visade att ett `math.abs` var död kod, vilket är noterat i källan.
