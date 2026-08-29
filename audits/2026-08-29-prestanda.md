# UBRF — prestandaaudit (filstorlek och laddning)

Read-only-granskning av `/home/claude/UBRF` 2026-08-29. Inga filer i repot är ändrade.
Mätningarna är gjorda med Playwright/Chromium (headless, swiftshader, 1280×800) mot
`dist/ridskolan.html` över en lokal http-server. Absoluta tal för 3D-ramar är därför
inte representativa för en riktig GPU — men *räkningarna* (draw calls, allokeringar,
DOM-uppslag) och JS-CPU-tiderna är det.

## Sammanfattning

- **Bygget:** `dist/ridskolan.html` = 651 859 byte (209 kB gzip). 28 skript + tre
  stilkällor. Inga sprites bakas in (`assets/*.png` finns inte), så `SPRITE_DATA`-grenen
  i `tools/build.py` är vilande.
- **Tid till första ram** är ~190–260 ms lokalt och domineras helt av att tolka ~580 kB
  JS (`domInteractive` 183 ms mot `responseEnd` 19 ms). Skriptexekveringen i sig är
  ~110 ms varav nästan allt är parse; inget skript gör tung synkron geometri-, ljud-
  eller spritegenerering vid laddning. 3D-motorn byggs lat vid första 3D-ramen.
  **Laddningen är i grunden sund.** Störst vinst på storlek: två helt döda filer
  (`ritt2d.js`, `sprites.js`, 16 kB) och en stilmall som till ~80 % är död (`ui.css`).
- **Stabil bildfrekvens är den verkliga svagheten.** Gården i 3D gör **405 draw calls,
  2 030 `bindBuffer`, ~1 200 `new Float32Array` och 465 hex-parsningar per ram**
  (10,6 ms JS-CPU i headless) — utan avstånds- eller synfältsgallring. Varje dörr
  (stall↔gård) river och bygger om hela scenen (25–105 ms hack). Första 3D-ramen
  kostar ~200–290 ms i ett svep.
- **CSS:** tre lager definierar samma klasser (`.btn` tre gånger, `.box`, `.sheet`, HUD-mätarna
  två gånger). `ui.css` bidrar med `:root`-variabler + `.btn/.btnrow/.gold`; resten
  (sol, moln, kullar, `.hud`, `.pill`, `.quest`, `.panel` …) används aldrig.

## Mätvärden

### Laddning (dist/ridskolan.html, lokal server, kall cache)

| Mått | Kall start | Varm start |
|---|---|---|
| responseEnd | 19 ms | — |
| domInteractive | 183 ms | — |
| DOMContentLoaded | 184 ms | — |
| first-contentful-paint | 188–256 ms | 220 ms |
| Första `requestAnimationFrame`-callback | 115–167 ms* | 157 ms |
| JS-heap efter laddning | 2,8 MB | |
| Konsolfel/`pageerror` | inga | inga |

\* rAF hinner köra medan HTML-parsern pausar mellan skriptblock; loopen i `game.js:557` startar innan de sista skripten är tolkade och väntar aktivt (`typeof gl3dLage!=="function"`).

### Skripttid per fil (parse+exekvering, ms, min av 4 körningar)

| Fil | ms | Kommentar |
|---|---|---|
| scenes.js | 28,5 (median 59) | Slutraden `visaSkaparen("meny")`/`visaMeny()` är själv bara 3–5 ms; resten är första style/layout av overlayn (backdrop-blur) som råkar landa här. [osäker attribution] |
| render.js | 15,9 | `resize()` på toppnivå — allokerar canvas-backbuffer (8,6 ms första gången). Nödvändigt för första ramen. |
| gl.js | 7,0 (median 13) | Ren parse av 34 kB + shadersträngar. Ingen GL-init vid laddning. |
| world.js | 4,0 | Parse av 75 kB. |
| varld3d.js | 2,8 | Parse av 73 kB. Ingen geometri byggs. |
| scen3d.js | 2,2 | Parse av 50 kB. |
| övriga 22 filer | 0,1–2,0 vardera | |
| **Summa** | **111 ms** | |

Slutsats: det finns **ingen tung synkron init** att skjuta upp. Vinsten på TTFF ligger i
färre byte att tolka, och den är begränsad (död kod ≈ 3 % av JS:en).

### 3D-uppbyggnad (första gången, ms, headless)

| Steg | ms | Var |
|---|---|---|
| `GL.init` (kontext + shaders) | 14–58 | gl.js:303 |
| `s3Texturer` (7 canvas-texturer; sand = 2 600 fillRect) | 75–85 | scen3d.js:27 |
| `s3BygHast` | 20–44 | scen3d.js |
| `v3dBygg("gard")` — 24 nät, 39 861 trianglar | 78–105 | varld3d.js:993 |
| `v3dBygg("stallinne")` — 34 nät, 16 386 tri | 53 | |
| `v3dBygg("ridhusinne")` — 29 nät, 15 786 tri | 12–14 | |
| `v3dBygFigur` | 12 | |
| **Första 3D-ram på gården, totalt** | **~200–290 ms** | allt sker synkront i `ritaVandring3D` varld3d.js:1370–1387 |
| Omgång 2+ (varm): stall→gård / gård→stall | 25–31 / 6–14 | rivs och byggs om vid *varje* scenbyte, varld3d.js:1386 |

### Ramkostnad (steady state)

| Scen | rAF-median | JS-CPU/ram | drawElements | bindBuffer | `new Float32Array` | `glFarg` | DOM-uppslag |
|---|---|---|---|---|---|---|---|
| Meny | 16,7 ms | ~0 | — | — | — | — | — |
| Gård 2D | 16,7 ms | 0,3 ms | — | — | — | — | — |
| **Gård 3D** (10 hagehästar + 3 figurer) | 500 ms (swiftshader) | **10,6 ms** | **405** | **2 030** | **1 197** | **465** | 6 |
| Stall 3D | 500 ms (swiftshader) | 0,8 ms | — | — | — | — | — |
| Lektion 2D | 16,7 ms | 0,3 ms (max 7,5) | — | — | — | — | ~27 (ritaHUD) |
| Lektion 3D (0 npc) | 16,7 ms | 1,0 ms | 93 | 470 | 229 | 89 | |

De 500 ms i 3D är swiftshaders programvarurasterisering av 40 k trianglar + tre
efterbehandlingspass, inte spelets JS — bortse från det talet, men inte från räkningarna.

## Fynd, sorterade efter påverkan

### 1. Gården i 3D: ~400 draw calls/ram och ~1 200 typed-array-allokeringar/ram — ingen gallring  (stabil FPS — hög)

- `varld3d.js:1402` ritar **alla** hästar i alla hagar varje ram med `s3RitaHast`, oavsett
  avstånd eller om de är bakom kameran. Varje häst ≈ 23 direkta `rita()` + 4 ben × ~4 delar
  ≈ 35–40 draw calls (scen3d.js:523–650), och varje `rita` gör `M4.mul(bas,mat)` som
  allokerar en ny `Float32Array(16)` (scen3d.js:543, 669; gl.js:13–15).
- Statiska nät ritas med `M4.ny()` per nät per ram (varld3d.js:1398, scen3d.js:997) —
  24–34 onödiga allokeringar/ram; en delad identitetsmatris räcker.
- `GL.rita` (gl.js:516–545) gör 5 `bindBuffer` + 4 `vertexAttribPointer` + 1
  `bindTexture` + 6 uniform-anrop per nät, även när samma nät ritas 40 gånger i rad
  (hästens leder/klot). Ingen state-cache, inga VAO:er (OES_vertex_array_object).
- `glFarg(o.ton)` (gl.js:78) parsar hex-strängen och allokerar en array per draw call — 465/ram.
- Uppskattat skräp: ~1 200 × ~100 B ≈ 120 kB/ram ≈ 7 MB/s vid 60 fps → täta minor-GC:er.
  [osäker: GC-frekvens ej mätt, allokeringsräkningen är verifierad.]

### 2. Scenen rivs och byggs om vid varje dörr  (hack — hög)

`varld3d.js:1386`: `if(V3D.plats!==G.scen||…){v3dBygg(G.scen);}` → `v3dBygg` (993) frigör
alla nät (`GL.fritt`) och bygger om från grunden. Gården (40 k trianglar) byggs om varje
gång man går ut ur stallet: 25–31 ms varm på desktop-headless, första gången 78–105 ms.
På en mobil i stallet blir det ett synligt hack vid varje dörr. Texturerna är redan
cachade (`v3dTexturer` returnerar tidigt), så det är bara geometrin som slösas.

### 3. Första 3D-ramen gör allt på en gång  (hack — medel)

`ritaVandring3D` (varld3d.js:1370–1387) och `draw3D` (scen3d.js:970–980) kör
`GL.init` + `s3Texturer` + `s3BygHast` + `v3dBygg` synkront i samma rAF-callback:
200–290 ms frysning exakt när spelaren trycker "Bakom dig" eller går ut på gården.
Menyn står stilla med tom rAF-loop i sekunder innan dess — det är gratis tid.

### 4. Död kod: `src/ritt2d.js` och `src/sprites.js` laddas men nås aldrig  (storlek — medel)

- `ritt2d.js` (12 010 B, 292 rader): **ingen** av dess 14 toppnivå-symboler
  (`RITT2D`, `r2Farg`, `r2Matt`, `r2Himmel`, `r2Moln`, `r2Kullar`, `R2FOND`, `r2Fond`,
  `r2Siluett`, `r2Staket`, `r2Mark`, `r2Grastuvor`, `r2Ekipage`, `ritaRitt2D`)
  refereras från någon annan fil eller från `index.html`. Verifierat med `\b`-grep
  över alla filer; inga `window[...]`, `eval` eller `new Function`-anrop finns i `src/`.
  Filen kom in i commit 961f654 ("Ridningen blir sidovy med målade sprites") och
  kopplades ur igen i 0830195, vars meddelande säger det rakt ut: "Sidovyn och
  sprite-pipelinen ligger kvar orörda men används inte." Sedan dess skeppas de i varje bygge.
- `sprites.js` (3 952 B): `sprite`, `ritaSprite`, `hastSprite`, `SPRITE` används bara av
  `ritt2d.js`; `ritaPlatshallare` används inte ens där. Den enda kopplingen utifrån är
  `window.SPRITE_DATA` som `build.py` skulle sätta om `assets/*.png` fanns — vilket de inte gör.
- Tillsammans 16 kB rå / 6,1 kB gzip ≈ 2,5 % av bygget.

Övriga verifierat oanvända toppnivå-symboler (små):

| Symbol | Plats | Rader | Anm. |
|---|---|---|---|
| `fardighetSammanfattning` | framsteg.js:175 | 10 | Kommentaren säger "används i profilen och efter passet" — det gör den inte. |
| `LEKTION` | data.js:86 | ~14 | Ersatt av `byggTavlingsprogram`/`moment.js`. |
| `kursHist` | game.js:155 | 1 | `let kursHist=[]`, aldrig läst. |
| `ritaPlatshallare` | sprites.js:54 | 19 | Faller med sprites.js. |

Falska larm som skriptet först gav och som är *i bruk* (via spread `...fn()`): `simHopp`
(tavling.js:166), `synkProfilRad` (synk.js:150), `stallFonster` (site.js:122).

### 5. `src/ui.css`: ~80 % död, och tre lager definierar samma klasser  (storlek/underhåll — låg–medel)

Av ui.css 126 rader används bara `:root` (18 rader), `.btn`/`.btn:active` (109–116),
`.btnrow` (124) och `.gold` (som textfärg via `.gold` i skin.css — ui.css:s `.coin.gold`
är död). **Aldrig förekommande i markup eller JS-strängar:** `.scene .sun .cloud .c1
.c2 .hills .hill .h1 .h2 .h3 .hud .badge-lvl .pill .coin .gem .heart .plus .xp .bar
.fill .mint .gloss .txt .titlewrap .gametitle .subtitle .row .panel .inner .quest .icon
.info .btn.green/.purple/.big/.round .btnstack .menu-center` samt `@keyframes drift`
och `pulse`. (Det skriptet först listade som "använda" — `bar`, `row`, `info`, `panel`,
`hud` … — var ordträffar i prosa, kontrollerat mot `class="…"`/`classList`.)

Dubbeldefinitioner över lager (senare vinner; index.html → ui.css → skin.css):

| Klass/regel | index.html | ui.css | skin.css | Effekt |
|---|---|---|---|---|
| `.btn` | rad 171 | rad 109 | rad 41 | Tre fullständiga definitioner; ui.css:s ligger helt i skuggan. |
| `.btnrow` | 177 | 124 | 63 | `gap` 10→12→14, `margin-top` 22→4→24 — motstridiga, sista vinner. |
| `.gold` | 312 | (`.coin.gold`) | 36 | Två färger (`--gold-2` vs `--gold`). |
| `--gold` | `:root` #D6AE3C | `:root` #F6C445 | — | ui.css vinner; index.html:s hela "kall stallmorgon"-palett målas över. |
| `.hud` | (`.hudh`) | 43 | — | Krocken CLAUDE.md nämner är löst genom omdöpning, men `.hud` ligger kvar död i ui.css. |
| `.box .sheet #ov #momentBar .ptrack .atrack #saga #approach #viewToggle .note .hcard kbd th td` | ja | — | ja | skin.css skriver om praktiskt taget varje HUD-regel i index.html; index.html:s versioner är basvärden som aldrig syns. |

Oanvända selektorer i index.html:s `<style>`: `.mono`, `.hudh.tc`, `#topbar`
(inget element med id `topbar`). Oanvända variabler: `--p1…--p6`, `--sand`, `--sand-2`,
`--sand-dark` (index.html), `--brown` (ui.css). Variabler som används men sätts inline
via JS (`--prov`, `--hy`, `--hjalm`, `--kavaj`, `--i`) är i sin ordning.

Kvarvarande `backdrop-filter` i spelläge (index.html): `#viewToggle` (rad 296, blur 6px,
alltid synlig i spel — skin.css nollställer `background` men inte filtret) och
`#approach:not(:empty)` (rad 144, blur 7px under anridning). `.box`/`#saga` nollställs
till `none` i skin.css. Blur ovanpå en WebGL-canvas är en känd mobilkostnad. [osäker: ej mätt]

### 6. HUD skriver DOM varje ram  (stabil FPS — låg–medel)

`ritaHUD` (game.js:496–535) gör per ram ~19 `querySelector` (6 rader × 3 + `#inverkan b`)
+ 4 `getElementById` + `.arow … .v`-uppslag, och sätter `textContent` på `#gait`,
`#tempo`, `#inverkan b`, `#gaitWarn` **ovillkorligt** — Chrome byter textnod även när
strängen är identisk, vilket invaliderar layout varje ram. `#vHast i`/`#vDu i`
(framsteg.js:278–280) får ny `width` varje ram trots `transition:width .25s` → evig
övergång. `ritaIntroTangenter` (intro.js:76) är däremot rätt gjord (ritar bara vid ändring).

### 7. Smått

- `GL.efter` (gl.js:670–720) och `GL.himmel` (750–785) slår upp uniform-/attributplatser
  med `getUniformLocation`/`getAttribLocation`/`getParameter(CURRENT_PROGRAM)` varje
  ram (21 + 5 + 4 anrop). `getParameter` kan vara en synkron drivrutinsfråga. Cacha vid
  programskapande som redan görs för huvudprogrammet (`this.u`, `this.a`).
- `s3Texturer` sandtextur: 2 600 `fillRect` med `Math.random` (scen3d.js:31) — 75–85 ms.
  Är en engångskostnad, men den ligger i första 3D-ramen (fynd 3).
- `mobil.js:134` pollar med `setInterval(…,250)` och skriver `style.display` på tre
  element 4 ggr/s även när inget ändrats. Harmlöst men onödigt.
- `G.sagaT-=1/60` finns i två kopior (game.js:534 och world.js:1502) och antar 60 Hz —
  repliken försvinner dubbelt så fort på en 120 Hz-skärm. Redundans + bugg, inte prestanda.
- `loop` (game.js:539–541) väntar aktivt på `gl3dLage` med rAF tills alla skript är tolkade;
  den kunde starta i `mobil.js`/sist i stället. Kosmetiskt.
- `render.js:8–13` och `world.js:700,713` skapar `createLinearGradient`/`createRadialGradient`
  per ram i 2D-himlen. Mätt 0,3 ms/ram totalt — ingen åtgärd.
- Kommentarer är 19 % av JS-källan (108 kB rå). En kommentarstrippning i `build.py` skulle ge
  ~15–20 kB gzip, men repot värderar kommentarerna och regex-strippning av JS är riskabel
  (strängar med `//`, shaderkod). Inte rekommenderat utan riktig tokenizer.
- Dubbla toppnivå-definitioner (samma namn i två filer på toppnivå): **inga**. De enda
  namnkollisionerna är lokal skuggning (`K` i hast.js:26/ovningar.js:240 mot model.js:54,
  `cv` i varld3d.js:230, `overlayUppe` som lokal const i mobil.js:136) — ofarliga.

## Topp 5 att åtgärda

| # | Åtgärd | Fil:rad | Föreslagen ändring | Vinst | Risk |
|---|---|---|---|---|---|
| 1 | **Gallra och återanvänd i 3D-gården** | `varld3d.js:1402–1411` (hageloopen), `scen3d.js:543` och `:669` (`rita`-lambdan), `varld3d.js:1398` + `scen3d.js:997` (`M4.ny()` per nät), `gl.js:78` (`glFarg`) | (a) I hageloopen: hoppa över hästar med `dist² > ~60²` från kameran och hästar bakom kameran (`dot(fwd, pos−oga) < 0`); rita avlägsna hästar som `KLOSS`-variant eller med benen som en lada. (b) Låt `rita` skriva in i en återanvänd `Float32Array` (`M4.mul(bas,mat,SCRATCH)` — `mul` har redan `ut`-parameter, gl.js:14). (c) Ersätt `M4.ny()` i statiska loopen med en delad konstant `M4.ID`. (d) Cacha `glFarg` i en `Map<string,array>`. | −60–80 % draw calls på gården, ~0 allokeringar/ram för statiskt | Låg för (b)(c)(d); medel för (a) — kräver att `GL.kamera` exponerar `ogaPos`/`kamBas` (det gör den redan) och att synlighet testas med skärmdump. |
| 2 | **Cacha scenernas geometri i stället för att bygga om vid varje dörr** | `varld3d.js:993–1010` (`v3dBygg`), `:1386` | Byt `S3.statiskt=[]` + `GL.fritt` mot `V3D.cache[scen+"|"+vader] = {statiskt, oppningar}`; vid scenbyte välj ur cachen, bygg bara vid miss. Behåll `GL.fritt` för poster som trängs ut (t.ex. max 3). Minne: ~5 MB för alla tre. | Tar bort 25–105 ms hack vid varje dörr | Låg — inga anropare bryr sig om `S3.statiskt`:s identitet, bara innehåll (verifierat via grep). |
| 3 | **Värm upp 3D under menyn** | `varld3d.js:1370–1383`, `scen3d.js:970–980`, `game.js:539` | Lägg en `v3dForvarm()` som i `requestIdleCallback` (fallback `setTimeout`) kör `GL.init`, `s3Texturer`, `s3BygHast` och `v3dBygg("gard")` medan `G.scen==="meny"` och overlayn är uppe; dela upp i 3–4 idle-steg. Behåll try/catch → `S3.trasig`. | Första 3D-ramen 200–290 ms → ~0 upplevt | Låg–medel: `GL.init` skapar kontexten innan `#gl` är synlig (`display:none`) — fungerar i Chrome/Safari, men verifiera att `canvas.width/height` sätts först i `GL.start`; annars startar man med 0×0-framebuffer och `_post` kastar (fångas). |
| 4 | **Ta bort `ritt2d.js` och `sprites.js` ur bygget** | `index.html:408` och `:427` (script-taggarna); filerna själva; `tools/build.py:24–41` (`sprite_data`) | Ta bort de två `<script src>`-raderna. Radera filerna eller flytta dem till `references/`. Ta bort `sprite_data()`-grenen i build.py eller lämna den (den är no-op utan png). Ta även bort `fardighetSammanfattning` (framsteg.js:175–184), `LEKTION` (data.js:86–97), `kursHist` (game.js:155). | −16 kB rå / −6 kB gzip, −2 skriptblock | **Låg** — noll referenser utifrån, verifierat med ordgräns-grep i alla `src/*.js` + `index.html`; ingen dynamisk uppslagning finns i repot. Kontrollera ASSETS_NEEDED.md/ROADMAP.md som nämner sprites, så att avsikten (sidovy med PNG) dokumenteras som "ej inkopplad" i stället för att tyst försvinna. |
| 5 | **Krymp `ui.css` till det som används och räta upp lagren** | `src/ui.css:18–108, 117–123, 125–126` (allt utom `:root`, `.btn`, `.btn:active`, `.btnrow`); `index.html:296` (`#viewToggle` blur), `:144` (`#approach` blur); `index.html:312` `.gold` | CLAUDE.md säger att ui.css inte ska *redigeras* — så gör det i `build.py`: låt `bädda_css` för `src/ui.css` bara baka in `:root{…}`-blocket (regex på första `{…}`), eftersom `.btn/.btnrow` ändå skrivs över helt av skin.css. Alternativt, om regeln får omtolkas: kapa ui.css till `:root` + de fyra reglerna. Lägg `backdrop-filter:none` på `#viewToggle` och `#approach:not(:empty)` i skin.css (som redan görs för `.box`/`#saga`). Ta bort `.mono`, `.hudh.tc`, `#topbar`, `--p1..6`, `--sand*` i index.html. | −7 kB rå / −2,6 kB gzip; två färre helskärms-blur ovanpå WebGL | Låg för CSS-borttag (inga träffar i markup/JS). **Medel för `--gold`**: ui.css:s `:root` måste vara kvar, annars byter `--gold` till index.html:s #D6AE3C och `--emerald/--cream/--panel-top` blir odefinierade (index.html:71, 83, 89 använder dem). |

Utöver topp 5, billigt och säkert: cacha DOM-noderna i `initHUD` (game.js:479) och sätt
`textContent`/`style.width` bara vid ändring (fynd 6); cacha uniform-platser i
`GL._post`/`GL.himmel` (fynd 7).

## Metod och verktyg

- `python3 tools/build.py` → 651 859 B; `gzip -c | wc -c` → 208 889 B.
- Död kod: eget Python-skript som extraherar toppnivå-`function/const/let/var` (och
  indragna `function` + objektmetoder i en andra körning, 1 114 namn) och räknar
  ordgränsade träffar i alla `src/*.js` + `index.html` efter kommentarstrippning; alla
  kandidater (8 st) verifierade manuellt med `grep -n`. Sökning efter `window[`, `globalThis[`,
  `eval(`, `new Function` gav noll träffar.
- CSS: selektorer ur `index.html <style>`, `ui.css`, `skin.css` matchade mot markup +
  JS-strängar; "träffar" kontrollerade mot `class="…"`/`classList.*` för att sålla ordträffar.
- Mätning: Playwright + `/opt/pw-browsers/chromium` (`--use-gl=swiftshader`), Navigation
  Timing, `performance.mark` runt varje `<script>`-block i en tillfällig kopia av
  dist-filen (raderad efteråt), samt monkey-patchade `gl.drawElements/bindBuffer/…`,
  `M4.ny/mul/translation`, `Float32Array`, `glFarg`, `document.querySelector/getElementById`
  under en ram av `ritaVandring()` respektive `draw3D()`.
- Tillfälliga skript ligger i scratchpad-katalogen, inte i repot.
