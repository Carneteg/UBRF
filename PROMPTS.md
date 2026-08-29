# Prompt-kokbok — Ridskolan

Prompter att köra i Claude Code på det här repot, på ett schema — inte bara
när något gått sönder. Idén (efter Patrick Neemans "Prompts you should run on
your application, every time"): definiera prompten en gång, kör den på en
kadens, förfina den när resultatet är dåligt. Versionera filen med koden.

Alla prompter förutsätter att Claude Code startas i repots rot så att
`CLAUDE.md` läses. Reglerna där (en fil, inga beroenden, färg bara i
`src/ljus.js`, foton är facit) gäller varje körning och behöver inte upprepas
i prompten.

Tre kadenser:

| När | Kör |
|---|---|
| **Före varje merge till `main`** | A1, A2, A3 |
| **Efter varje ny funktion/scen** | B1, B2 |
| **Var fjärde vecka eller efter större grafikpass** | C1, C2, C3, C4 |

---

## A · Före merge (pre-release-checklista)

### A1 · Bygg- och rökprov

> Bygg spelet med `python3 tools/build.py`, starta `python3 -m http.server 8931`
> och öppna `dist/ridskolan.html` med Playwright (chromium i
> `/opt/pw-browsers/chromium`, `--use-gl=swiftshader`). Gå igenom kedjan
> meny → skapa ryttare → Rid nu → prata med ridläraren → box → skötsel →
> ridhus → första ritten → resultat med tangenttryck. Rapportera varje
> `console.error`/`pageerror` med fil:rad, och om kedjan går att fullfölja.
> Gör samma sak i 390×844 med touch. Ändra ingenting — rapportera bara.

**Bra resultat:** noll fel på desktop och mobil, kedjan går igenom.
**Om det fastnar:** be om skärmdump vid stoppet: "Ta en skärmdump där du
fastnade och läs den, beskriv vad som syns och vilken tangent du väntade på."

### A2 · Regressionskoll mot ändringsloggen

> Läs `git diff main...HEAD --stat` och `git log main..HEAD`. Läs
> `CHANGELOG.md`. Lägg till poster i `CHANGELOG.md` enligt formatet överst i
> filen — en post per sak som märks för spelaren, inte per commit. Lista sedan
> vilka scener/moment som ändringarna kan ha påverkat, så jag vet vad jag ska
> provspela.

**Bra resultat:** 1–4 nya poster med spelarperspektiv, ingen post av typen
"refaktorering av X".

### A3 · Byggnadsregeln

> För varje fil under `src/` som diffen mot `main` rör och som bygger geometri
> för en byggnad (`varld3d.js`, `world.js`, `site.js`): kontrollera att
> måtten stämmer mot `references/buildings/<byggnad>/KORT.md` och
> `references/SITEPLAN.md`. Lista avvikelser som "kort: 25×75 m, kod: 26×66 m"
> med fil:rad. Ändra ingenting.

**Bra resultat:** tom lista, eller konkreta avvikelser med siffror.

---

## B · Efter ny funktion (post-feature-audit)

### B1 · Sidoeffekter på prestanda

> Jämför `dist/ridskolan.html` före och efter (bygg `main` i en worktree).
> Rapportera storlek rå och gzip. Mät sedan med Playwright en bildruta på
> gården i 3D, i stallet och i lektionen: antal `drawElements`, antal
> `new Float32Array`, JS-tid per bildruta (monkey-patcha `gl.drawElements`
> och `Float32Array` som i tidigare audit). Flagga om någon siffra ökat mer
> än 10 %. Ändra ingenting.

**Bra resultat:** en tabell före/efter, inga rader över tröskeln.
**Referensvärden 2026-08-29:** 652 kB rå / 209 kB gzip; gård 3D ~405 draw
calls, ~1 200 allokeringar per ruta (före åtgärd).

### B2 · Ny funktion, gammal onboarding

> Den nya funktionen är: [beskriv]. Läs `src/intro.js` (INTROSTEG),
> `visaUppgift` i `src/world.js` och `#tangenter` i `index.html`. Svarar
> onboardingen på hur en 11-åring som rider på UBRF första gången upptäcker
> funktionen: vilken tangent, vilken pekknapp på mobil, vilken uppgiftstext?
> Om inte: föreslå exakt text för Uppgift-rutan och tangentremsan, på svenska,
> i ridlärarens röst. Kom ihåg att mobilen inte har tangenter — använd
> knappnamnen i `src/mobil.js`.

**Bra resultat:** förslag som kan klistras rakt in, med både tangent- och
pekvariant.

---

## C · Periodisk förbättringsrunda

### C1 · UX-granskning

> Spela spelet med Playwright från första start till resultatskärm, på
> desktop och i 390×844 touch. Ta skärmdumpar av varje scen och läs dem.
> Granska gränssnitt, onboarding och navigation ur perspektivet: en 10–14-
> åring som rider på UBRF, och en förälder. Hitta friktion, otydliga
> affordances, saknade feedback- och tomma tillstånd, instruktioner som
> nämner tangenter på mobil, och ställen där man kan fastna. För varje fynd:
> Problem / Varför / Fix med fil och funktion, och föreslagen text. Prioritera
> efter påverkan på spelaren, inte efter hur lätt det är att fixa. Notera
> även vad som redan fungerar så att det inte "fixas". Avsluta med topp 5
> som går på några timmar.

**Bra resultat:** se `audits/2026-08-29-ux.md` som mall — konkreta
fynd med skärmdumpsnummer, inte generiska råd.
**Om listan blir för lång och lågprioriterad:** "Fokusera bara på första
passet: från Rid nu till resultatskärmen."

### C2 · Prestanda och död kod

> Auditera `src/*.js`, `index.html`, `src/ui.css` och `src/skin.css` för
> död kod, dubbla definitioner, dubbla CSS-regler och per-bildruta-
> allokeringar i renderloopen. Skriv ett skript som listar toppnivåsymboler
> utan referenser och verifiera de tio största manuellt (spread, strängar,
> `window[...]`). Mät laddning och bildruta med Playwright. Rapportera
> sorterat efter påverkan, med "Topp 5 att åtgärda" som fil:rad + ändring +
> risk. Genomför sedan de tre lägsta riskerna och visa diff.

**Bra resultat:** se `audits/2026-08-29-prestanda.md`.
**Om resultatet blir ytligt:** "Auditera bara `src/varld3d.js` och
`src/scen3d.js` för allokeringar i `rita`-funktionerna."

### C3 · Tillgänglighet och läsbarhet

> Granska all UI-text i `index.html`, `src/skin.css` och textsträngar i
> `src/scenes.js`, `src/moment.js`, `src/intro.js`: textstorlek under 12 px,
> kontrast under WCAG AA mot paletten i `:root` (räkna ut kontrastvärdet),
> focus-tillstånd på knappar, och om HUD-texten går att läsa på 390 px bredd.
> Lista med selektor/sträng, uppmätt värde och föreslaget värde. Spelet har
> medvetet ett enda tema — föreslå inte temaväxling.

**Bra resultat:** tabell med selektor, uppmätt kontrast, förslag. Färger
ändras bara i `src/ljus.js`/`:root`, aldrig lokalt.

### C4 · Stildrift mot förlagan

> Läs `ART_STYLE.md`, `ui-kit-demo.html` och `STIL` i `src/ljus.js`. Ta
> skärmdumpar av gården, stallgången och lektionen i 3D. Lista var spelet
> avviker från klosstilen (fasettering, plana ytor, rätblocksfigurer) och
> från UI-kitets formspråk (variabler, knappar, paneler). Konkret: "hästens
> hals har 12 segment, stilen säger 4–6." Ändra ingenting.

**Bra resultat:** kort lista med fil:rad; tom lista är också ett resultat.

---

## Hoppat över med flit

Artikeln föreslår också sitemap-audit och GA4-eventspårning. Ridskolan är en
enda fil som ska gå att öppna utan nät och skickar inga anrop utom den
frivilliga synken — det finns ingen sitemap att hålla aktuell och ingen
spårning som hör hemma här. Ett temasystem med ljust/mörkt läge föreslås
också; spelet har medvetet ett enda uttryck (se kommentaren i `:root`).

## Hur man underhåller kokboken

När en prompt ger dåligt resultat: skriv in vad som gick fel under "Om …"
och en snävare variant. När ett referensvärde ändras (B1): uppdatera det i
samma commit som ändringen. Ta bort prompter som inte körts på två månader.
