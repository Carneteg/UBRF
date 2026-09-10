/* VÄLFÄRDSGRINDEN — en skadad häst ska inte arbeta.

   `docs/PRODUCT-CANON.md`: ansvaret och plikterna kring hästen ÄR
   gameplay. Då är det inte en detalj om spelet delar ut en halt häst när
   poolen tar slut; det är kärnan som går sönder. Kontraktet som mäts:

     1. En häst som vilar för skada får aldrig tilldelas — inte heller
        när alla gruppens hästar vilar. Slut på friska hästar är ett
        VÄNTELÄGE, inte en tilldelning av en skadad häst.
     2. Första dagens Jack är en tilldelning, inte en pool — men den får
        inte heller sätta en skadad häst i arbete.
     3. En genomförd ritt får inte radera en skada. Skador läker på vila,
        ett pass i taget, aldrig på att hästen arbetar.

   Provet SÄTTER upp ett sparläge (skadade hästar) — det är en
   förutsättning en spelare når på riktigt, inte ett hoppat spelarsteg.
   Därefter läses spelets egna funktioner utan att skrivas i.
*/
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8896;   /* fri port: 8873 lastlagetest, 8894 inputsemantik */

let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};

const srv = http.createServer((q, s) => {
  const f = q.url === "/" ? "ridskolan.html" : q.url.slice(1).split("?")[0];
  const abs = path.join(DIST, f);
  if (!abs.startsWith(DIST) || !fs.existsSync(abs)) { s.writeHead(404); s.end(); return; }
  s.writeHead(200, { "content-type": f.endsWith(".html") ? "text/html" : "application/octet-stream" });
  s.end(fs.readFileSync(abs));
});
await new Promise(r => srv.listen(PORT, r));

const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  headless: true,
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(700);
const ev = (f, a) => page.evaluate(f, a);

/* ── 1. ALLA GRUPPENS HÄSTAR VILAR ─────────────────────────────── */
console.log("\n── Alla hästar i gruppen vilar för skada ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    /* Ledlektionens pool är toblerone + lydia. Båda skadas. */
    SPAR.fortroende.toblerone = { rang: .5, pass: 4, skada: { namn: "sten i hoven", passKvar: 2 } };
    SPAR.fortroende.lydia     = { rang: .5, pass: 4, skada: { namn: "skav", passKvar: 2 } };
    G.seed = 1;
    const borta = dagensHandelser();
    const pool = hastpool("ledlektion");
    return { pool, bortaToblerone: !!borta.toblerone, bortaLydia: !!borta.lydia,
      skadade: pool.filter(id => { const m = hastminne(id);
        return !!(m.skada && m.skada.passKvar > 0); }) };
  });
  prova("spelet vet att båda vilar", d.bortaToblerone && d.bortaLydia,
    `toblerone ${d.bortaToblerone} · lydia ${d.bortaLydia}`);
  prova("poolen innehåller INGEN häst som vilar för skada",
    d.skadade.length === 0,
    `pool [${d.pool.join(", ")}] · skadade i poolen [${d.skadade.join(", ")}]`);
}

/* ── 1b. SCHEMA ÄR INTE SAMMA SAK SOM SKADA ────────────────────
   En häst hos hovslagaren är frisk, bara upptagen. Att låta en
   schemakrock låsa ute spelaren vore en ny bugg i stället för den
   gamla — så den vikningen ska finnas kvar. Skadan viker sig aldrig. */
console.log("\n── Schema viker sig, skadan gör det inte ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    /* Ingen skada alls — men leta upp ett frö där BÅDA ledlektionens
       hästar är bokade, och kontrollera att spelaren ändå får rida. */
    let hittat = null;
    for (let s = 0; s < 400; s++) {
      G.seed = s; const b = dagensHandelser();
      if (b.toblerone && b.lydia) { hittat = { seed: s, pool: hastpool("ledlektion") }; break; }
    }
    /* Och samma sak med skada i stället för bokning. */
    SPAR.fortroende.toblerone = { rang: .5, pass: 4, skada: { namn: "sten", passKvar: 2 } };
    SPAR.fortroende.lydia     = { rang: .5, pass: 4, skada: { namn: "skav", passKvar: 2 } };
    G.seed = 1;
    return { hittat, skadadPool: hastpool("ledlektion") };
  });
  if (d.hittat) prova("båda bokade hos hovslagare/veterinär → spelaren får ändå en häst",
    d.hittat.pool.length > 0, `frö ${d.hittat.seed} · pool [${d.hittat.pool.join(", ")}]`);
  else console.log("  NOT  inget frö gav båda bokade — mätningen kunde inte utföras");
  prova("men båda SKADADE → ingen häst, inget undantag",
    d.skadadPool.length === 0, `pool [${d.skadadPool.join(", ")}]`);
}

/* ── 2. TILLDELNINGEN SJÄLV ────────────────────────────────────── */
console.log("\n── Ridläraren tilldelar inte en häst som vilar ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    SPAR.fortroende.toblerone = { rang: .5, pass: 4, skada: { namn: "sten i hoven", passKvar: 2 } };
    SPAR.fortroende.lydia     = { rang: .5, pass: 4, skada: { namn: "skav", passKvar: 2 } };
    G.grupp = "ledlektion"; G.tavling = false; G.seed = 1;
    const utfall = [];
    /* Varje frö ska ge samma svar: ingen skadad häst i arbete. */
    for (let s = 0; s < 8; s++) {
      G.seed = s;
      let tilldelad = null;
      try { visaTilldelning(); tilldelad = G.hastId; } catch (e) { tilldelad = "KAST:" + e.message; }
      const m = tilldelad && hastminne(tilldelad);
      utfall.push({ seed: s, hast: tilldelad,
        skadad: !!(m && m.skada && m.skada.passKvar > 0) });
    }
    return { utfall, antalSkadade: utfall.filter(u => u.skadad).length };
  });
  prova("ingen av åtta tilldelningar sätter en vilande häst i arbete",
    d.antalSkadade === 0,
    `${d.antalSkadade} av 8 — ${d.utfall.filter(u => u.skadad).map(u => `frö ${u.seed}: ${u.hast}`).join(", ") || "inga"}`);
}

/* ── 3. FÖRSTA DAGENS JACK ─────────────────────────────────────── */
console.log("\n── Första dagen: Jack får inte heller arbeta skadad ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 0;
    SPAR.fortroende.blackrock_jack = { rang: .5, pass: 2,
      skada: { namn: "känning efter sten i hoven", passKvar: 2 } };
    G.grupp = "ledlektion"; G.tavling = false; G.seed = 1;
    let tilldelad = null;
    try { visaTilldelning(); tilldelad = G.hastId; } catch (e) { tilldelad = "KAST:" + e.message; }
    const m = tilldelad && hastminne(tilldelad);
    return { tilldelad, skadad: !!(m && m.skada && m.skada.passKvar > 0) };
  });
  prova("första dagen tilldelar ingen häst som vilar",
    !d.skadad, `fick ${d.tilldelad}`);
}

/* ── 4. EN RITT FÅR INTE TVÄTTA BORT SKADAN ────────────────────── */
console.log("\n── Skadan överlever ett genomfört pass ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    SPAR.fortroende.toblerone = { rang: .5, pass: 4,
      skada: { namn: "sten i hoven", passKvar: 2 } };
    G.hastId = "toblerone"; G.grupp = "ledlektion";
    G.betyg = { a: .8 }; G.bedomda = 1; G.klarade = 1;
    G.dagsform = .7; G.skotselRes = { risker: [] };
    const fore = JSON.parse(JSON.stringify(SPAR.fortroende.toblerone.skada));
    registreraPass({ totalfel: 0, utesluten: false });
    const efter = SPAR.fortroende.toblerone.skada || null;
    return { fore, efter };
  });
  prova("skadan finns kvar efter passet",
    !!d.efter, d.efter ? `${d.efter.namn}, ${d.efter.passKvar} pass kvar`
      : `RADERAD (var: ${d.fore.namn}, ${d.fore.passKvar} pass kvar)`);
  prova("och den läks inte snabbare än vilan medger",
    !!d.efter && d.efter.passKvar >= d.fore.passKvar - 1,
    d.efter ? `${d.fore.passKvar} → ${d.efter.passKvar}` : "n/a");
}

console.log(fel ? `\n${fel} FEL` : "\nALLA VÄLFÄRDSKONTROLLER OK");
await browser.close(); srv.close();
process.exit(fel ? 1 : 0);
