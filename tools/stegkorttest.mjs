/* STEGKORTET — webbens stallflöde som i Roblox, spelat i webbläsaren.

   docs/WEB-P1A-STABLE-FLOW-CONTRACT.md, acceptans 2. Mot dist/ (bygg med
   `python tools/build.py`). Provet sätter bara förutsättningar en spelare
   når på riktigt — en tilldelad häst, ett passnummer, var spelaren står —
   och trycker sedan på panelens egna knappar. Det skriver aldrig i
   förberedelsens tillstånd.

     A. startvalet: exakt två knappar, E = «Rida nu», ingen vänsterruta
     B. «själv»: hela kedjan manuellt till «Sitt upp», dagsform 0,76
     C. «Rida nu»: i ridhuset vid sargporten, dagsform 0,70, E sitter upp
     D. fynddag: frågan, fel svar står kvar, rätt svar stoppar ritten
     E. engelska: ingen svenska i panelen genom hela kedjan
     F. layout: skrivbord 1600×900 och iPad liggande 1180×820

   Körs: node tools/stegkorttest.mjs  (skärmbilder till $STEGKORT_BILDER) */
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8897;
const BILDER = process.env.STEGKORT_BILDER || "";

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

async function oppna(vp = { width: 1600, height: 900 }) {
  const page = await browser.newPage({ viewport: vp });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(600);
  return page;
}

/* En ny dag vid hästens box: passnummer, språk, tilldelning, position. */
async function vidBoxen(page, { pass = 0, sprak = "sv" } = {}) {
  return page.evaluate(({ pass, sprak }) => {
    window.SPRAKET = sprak;
    SPAR.pass = pass;
    startaVandring();
    const id = valbaraHastar().includes("troy") ? "troy" : valbaraHastar()[0];
    sattAktivHast(id);
    const b = hittaBox(id);
    gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1], rikt: 0 });
    return { id, namn: HORSES[id].namn };
  }, { pass, sprak });
}
const vanta = page => page.waitForTimeout(250);
const kort = page => page.evaluate(() => {
  const el = document.getElementById("stegkort");
  const knappar = [...el.querySelectorAll(".skV button")].map(b => ({
    id: b.dataset.id, text: b.textContent.trim(), primar: b.classList.contains("primar") }));
  const rader = [...el.querySelectorAll(".skRader button")].map(b => ({ id: b.dataset.id, text: b.textContent.trim() }));
  const tl = document.getElementById("moment").closest(".hudh");
  return { synlig: !el.hidden, id: el.dataset.kort, text: el.innerText, knappar, rader,
    vagvisare: typeof uppdragVagvisare === "function" ? !!uppdragVagvisare() : null,
    fler: !!el.querySelector("button[data-fler]"),
    rubrik: (el.querySelector(".skR") || {}).textContent || "",
    aterkoppling: (el.querySelector(".skA") || {}).textContent || "",
    vansterruta: tl ? getComputedStyle(tl).display !== "none" : false,
    prompt: VD.prompt ? VD.prompt.text : null, scen: G.scen, plats: G.hastPlats,
    dagsform: G.dagsform, redo: G.forb ? Forb.redo(G.forb) : null };
});
async function klicka(page, id) {
  const ok = await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort button")].find(x => x.dataset.id === id);
    if (b) b.click();
    return !!b;
  }, id);
  await vanta(page);
  return ok;
}
/* En promptrad HÅLLS som en Roblox-prompt: pekaren nere i `ms`. */
async function halla(page, id, ms = 500) {
  const ok = await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort .skRader button")].find(x => x.dataset.id === id);
    if (b) b.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));
    return !!b;
  }, id);
  await page.waitForTimeout(ms);
  await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort .skRader button")].find(x => x.dataset.id === id);
    if (b) b.dispatchEvent(new PointerEvent("pointerup", { bubbles: true }));
  }, id);
  await vanta(page);
  return ok;
}
async function tangent(page, kod, ms) {
  await page.keyboard.down(kod); await page.waitForTimeout(ms); await page.keyboard.up(kod);
  await page.waitForTimeout(250);
}
/* Spelaren gör resten själv: den primära knappen, kort för kort, tills
   kortet är `stopp` (ledningen). Hälsningen väljs med första rätta. */
async function gorSjalv(page, stopp = "leda", texter = []) {
  for (let i = 0; i < 60; i++) {
    const k = await kort(page);
    texter.push(k.text);
    if (k.id === stopp || !k.synlig) return k;
    const val = k.id === "halsa" ? k.knappar.find(b => b.id === "halsa1") : k.knappar.find(b => b.primar);
    if (val) { await klicka(page, val.id); continue; }
    /* Kort utan momentknapp (hämta sadel/träns): kortets egen prompt. */
    const rad = k.rader.find(r => r.id !== "rad:rida_nu");
    if (!rad) return k;
    await halla(page, rad.id);
  }
  return kort(page);
}

/* ── A + B ───────────────────────────────────────────────────────── */
console.log("\n── A. Startvalet vid hästen ──");
{
  const page = await oppna();
  const h = await vidBoxen(page);
  await vanta(page);
  let k = await kort(page);
  prova("panelen syns vid hästen", k.synlig && k.id === "valj", `kort ${k.id}`);
  prova("rubriken är «Välj hur du börjar»", k.rubrik === "Välj hur du börjar", k.rubrik);
  prova("exakt två knappar: Rida nu / Gör i ordning själv",
    k.knappar.length === 2 && k.knappar[0].text === `Rida nu — ${h.namn}` && k.knappar[1].text === `Gör i ordning ${h.namn} själv`,
    k.knappar.map(b => b.text).join(" / "));
  prova("bara «Rida nu» är primär", k.knappar[0].primar && !k.knappar[1].primar);
  prova("inget «Fler handlingar» på startvalet", !k.fler);
  prova("ingen hälsningsfråga på startvalet", !/bakifrån|Framifrån/.test(k.text));
  prova("E vid hästen är «Rida nu»", k.prompt === `Rida nu — ${h.namn}`, String(k.prompt));
  prova("den gamla vänsterrutan syns inte till fots", !k.vansterruta);
  if (BILDER) await page.screenshot({ path: path.join(BILDER, "startval-1600x900.png") });

  console.log("\n── B. «Gör i ordning … själv» ──");
  await klicka(page, "start:sjalv");
  k = await kort(page);
  prova("själv → «Hälsa på …» med tre val", k.id === "halsa" && k.rubrik === `Hälsa på ${h.namn}` && k.knappar.length === 3,
    `${k.rubrik} · ${k.knappar.length}`);
  prova("boxen finns under «Fler handlingar»", k.fler);
  prova("R1: «Rida nu» står som prompt med «[Håll inne R]», som i Roblox",
    k.rader.some(r => r.id === "rad:rida_nu" && r.text.includes("[Håll inne R]")), k.rader.map(r => r.text).join(" / "));
  await klicka(page, "halsa3");
  k = await kort(page);
  prova("rakt bakifrån: kanonens svar, hälsningen står kvar",
    k.id === "halsa" && k.aterkoppling === "Hon skräms. Gå aldrig rakt bakifrån.", k.aterkoppling);
  await klicka(page, "halsa1");
  const foreE = await kort(page);
  await tangent(page, "KeyE", 550);
  const efterE = await kort(page);
  prova("R1: E gör inget skötselmoment — momenten är panelknappar, som i Roblox",
    foreE.id === "visitera" && efterE.id === "visitera" && efterE.rubrik === foreE.rubrik, `${foreE.rubrik} → ${efterE.rubrik}`);
  const texter = [];
  k = await gorSjalv(page, "leda", texter);
  const sagda = texter.join("\n");
  prova("kedjan går genom alla Roblox-kort i ordning",
    ["Kolla ", "Rykta ", "Kratsa hovarna", "Hämta sadeln", "Lägg på sadeln", "Hämta tränset", "Sätt på tränset", "Led "]
      .every((t, i, a) => sagda.indexOf(t) >= 0 && (i === 0 || sagda.indexOf(t) > sagda.indexOf(a[i - 1]))),
    `sista kortet ${k.id}`);
  prova("uppsittning nekas innan hon är ledd", !k.redo);
  prova("R1: ledningen är en prompt «[Håll inne L]»", k.rader.some(r => r.id === "leda" && r.text.includes("[Håll inne L]")),
    k.rader.map(r => r.text).join(" / "));
  await halla(page, "leda", 400);
  k = await kort(page);
  prova("«Led …» → hon leds, kortet säger vart", k.plats === "leds" && k.id === "leder", `${k.plats} · ${k.id}`);
  prova("R1: ingen vägvisare när hon leds (Roblox har ingen)", k.vagvisare === false, String(k.vagvisare));
  const ut = await page.evaluate(() => {
    const [x, y] = skSargport(); gaTill("ridhusinne", { x, y: y + 1.2, rikt: 0 });
    VD.hastX = x + 1; VD.hastY = y + 1.6; return true; });
  await vanta(page);
  k = await kort(page);
  prova("framme i ridhuset: ledningen kvitteras, «Sitt upp på …»",
    ut && k.redo && k.id === "sittupp" && k.rubrik === `Sitt upp på ${h.namn}`, `${k.id} · ${k.rubrik}`);
  prova("allt själv: dagsform 0,76 (0,70 + 0,06)", Math.abs(k.dagsform - 0.76) < 1e-9, String(k.dagsform));
  await page.close();
}

/* ── C ───────────────────────────────────────────────────────────── */
console.log("\n── C. «Rida nu» ──");
{
  const page = await oppna();
  const h = await vidBoxen(page);
  await vanta(page);
  await tangent(page, "KeyR", 100);
  let k = await kort(page);
  prova("R1: ett kort tryck på R är INTE «Rida nu» (hålltid 0,35 s)", k.id === "valj" && k.scen === "stallinne", `${k.id} · ${k.scen}`);
  await tangent(page, "KeyR", 550);
  await page.waitForTimeout(300);
  k = await kort(page);
  prova("R hållen: «Rida nu» — stallet leder henne till ridhuset", k.scen === "ridhusinne" && k.plats === "leds", `${k.scen} · ${k.plats}`);
  prova("hon är redo: «Sitt upp på …»", k.redo && k.id === "sittupp", k.id);
  prova("stallets hand ger ingen omsorgsbonus: dagsform 0,70", k.dagsform === 0.7, String(k.dagsform));
  prova("E vid sargporten är uppsittningen", /Sitt upp/.test(String(k.prompt)), String(k.prompt));
  const promptRad = await page.evaluate(() => document.getElementById("approach").textContent);
  prova("R1: prompten säger «Håll inne E»", promptRad.startsWith("Håll inne E — "), promptRad);
  await tangent(page, "KeyE", 100);
  prova("R1: ett kort tryck på E sitter inte upp", (await page.evaluate(() => G.scen)) === "ridhusinne");
  await tangent(page, "KeyE", 550);
  await page.waitForTimeout(300);
  const scen = await page.evaluate(() => G.scen);
  prova("E hållen sitter upp och lektionen börjar", scen === "lektion", scen);
  await page.close();
}

/* ── D ───────────────────────────────────────────────────────────── */
console.log("\n── D. En dag med fynd ──");
{
  const page = await oppna();
  /* Första passet med fynd för hästen, ur samma regel som Roblox. */
  const pass = await page.evaluate(() => {
    const id = valbaraHastar().includes("troy") ? "troy" : valbaraHastar()[0];
    for (let p = 2; p < 40; p++) if (Forb.fyndFor(id, p)) return p - 1;
    return -1;
  });
  await vidBoxen(page, { pass });
  await vanta(page);
  await klicka(page, "start:rida_nu");
  let k = await kort(page);
  prova("«Rida nu» stannar vid fyndet: «Du hittade något»", k.id === "fynd" && k.rubrik === "Du hittade något", `${k.id} · ${k.rubrik}`);
  prova("tre svar i kanonens ordning, inget framhävt",
    k.knappar.length === 3 && k.knappar.every(b => !b.primar) && k.knappar[0].text === "Säg till ridläraren",
    k.knappar.map(b => b.text).join(" / "));
  prova("hon är inte flyttad", k.scen === "stallinne" && k.plats === "box", `${k.scen} · ${k.plats}`);
  await klicka(page, "svar:2");
  k = await kort(page);
  prova("fel svar: «inte ditt beslut», frågan står kvar",
    k.id === "fynd" && k.aterkoppling === "Det är inte ditt beslut att ta. Säg till ridläraren.", k.aterkoppling);
  await klicka(page, "svar:1");
  k = await kort(page);
  prova("rätt svar: «Ridläraren tar över»", k.id === "stopp" && k.rubrik === "Ridläraren tar över", k.rubrik);
  const efter = await page.evaluate(() => { sittUpp("ridhus"); return G.scen; });
  prova("välfärdsstoppet: uppsittning nekas", efter !== "lektion", efter);
  await page.close();
}

/* ── E ───────────────────────────────────────────────────────────── */
console.log("\n── E. Engelska ──");
{
  const page = await oppna();
  const h = await vidBoxen(page, { sprak: "en" });
  await vanta(page);
  let k = await kort(page);
  prova("Choose how to start / Ride now / Get … ready myself",
    k.rubrik === "Choose how to start" && k.knappar[0].text === `Ride now — ${h.namn}` && k.knappar[1].text === `Get ${h.namn} ready myself`,
    k.knappar.map(b => b.text).join(" / "));
  const texter = [k.text];
  await klicka(page, "start:sjalv");
  k = await gorSjalv(page, "leda", texter);
  await halla(page, "leda", 400);
  texter.push((await kort(page)).text);
  const SVENSKA = /[åäöÅÄÖ]|\b(och|Välj|Rida|Gör|Hälsa|Rykta|Kratsa|sadeln|tränset|hästen|henne|Sitt upp)\b/;
  const blandat = texter.filter(t => SVENSKA.test(t.replace(h.namn, "")));
  prova("ingen svenska i panelen genom hela kedjan", blandat.length === 0,
    blandat.length ? blandat[0].replace(/\n/g, " ¦ ").slice(0, 140) : `${texter.length} kort`);
  await page.close();
}

/* ── F ───────────────────────────────────────────────────────────── */
console.log("\n── F. Layout ──");
for (const vp of [{ width: 1600, height: 900, namn: "skrivbord" }, { width: 1180, height: 820, namn: "iPad liggande" }]) {
  const page = await oppna(vp);
  await vidBoxen(page);
  await vanta(page);
  await klicka(page, "start:sjalv");
  const r = await page.evaluate(() => {
    const b = document.getElementById("stegkort").getBoundingClientRect();
    return { x: b.x, y: b.y, w: b.width, h: b.height, vw: innerWidth, vh: innerHeight };
  });
  prova(`${vp.namn}: panelen helt synlig och ≤ 34 % av bredden`,
    r.x >= 0 && r.y >= 0 && r.x + r.w <= r.vw && r.y + r.h <= r.vh && r.w <= 0.34 * r.vw,
    `${Math.round(r.w)}×${Math.round(r.h)} vid ${Math.round(r.x)},${Math.round(r.y)} av ${r.vw}×${r.vh}`);
  if (BILDER) await page.screenshot({ path: path.join(BILDER, `halsa-${vp.width}x${vp.height}.png`) });
  await page.close();
}

await browser.close();
srv.close();
console.log(fel ? `\n${fel} fel.` : "\nalla gröna");
process.exit(fel ? 1 : 0);
