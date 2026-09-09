/* KARAKTÄRSSKAPARENS TRÄFFYTOR (#153 fix 4 / QA-3).

   `src/mobil.js` sätter ett golv och motiverar det själv i klartext:
   "Touchmål: fingret behöver 44 px, inte 26." Regeln är
   `.pek .btn{min-height:44px; min-width:44px}`.

   Karaktärsskaparen använder `.skapChip` och `.skapFlik` — inte `.btn` —
   och gick därför fri. Det är den allra första skärmen en spelare rör
   vid på en iPad.

   Provet mäter de FAKTISKT renderade knapparna på pekvyer. Golvet läses
   ur mobil.js självt, inte ur ett tal skrivet här.
*/
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8899;

/* Golvet ur källan: `.pek .btn{min-height:44px…}` i src/mobil.js. Ändras
   det där ska det ändras här av sig självt — inte glömmas bort. */
const mobilKalla = fs.readFileSync(path.join(ROT, "src/mobil.js"), "utf8");
const golvM = mobilKalla.match(/\.pek\s+\.btn\{min-height:(\d+)px/);
const GOLV = golvM ? Number(golvM[1]) : null;

let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};

const srv = http.createServer((q, s) => {
  const f = q.url === "/" ? "ridskolan.html" : q.url.slice(1).split("?")[0];
  const abs = path.join(DIST, f);
  if (!abs.startsWith(DIST) || !fs.existsSync(abs)) { s.writeHead(404); s.end(); return; }
  s.writeHead(200, { "content-type": "text/html" });
  s.end(fs.readFileSync(abs));
});
await new Promise(r => srv.listen(PORT, r));

const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  headless: true,
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

console.log(`\nGolvet läst ur src/mobil.js: ${GOLV} px`);
prova("golvet gick att läsa ur mobil.js", GOLV === 44, `${GOLV}`);

const vyer = [
  { namn: "iPhone SE 320", width: 320, height: 568 },
  { namn: "telefon 390", width: 390, height: 844 },
  { namn: "iPad landscape 1024", width: 1024, height: 768 },
];

for (const vy of vyer) {
  console.log(`\n── ${vy.namn} (${vy.width}×${vy.height}) ──`);
  const page = await browser.newPage({
    viewport: { width: vy.width, height: vy.height }, hasTouch: true,
  });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(800);

  const m = await page.evaluate(() => {
    const pek = document.body.classList.contains("pek");
    const las = sel => [...document.querySelectorAll(sel)]
      .filter(b => b.offsetParent !== null)
      .map(b => { const r = b.getBoundingClientRect();
        return { t: (b.textContent || "").trim().slice(0, 14),
          w: Math.round(r.width), h: Math.round(r.height) }; });
    return { pek, chips: las(".skapChip"), flikar: las(".skapFlik"),
      knappar: las("#sheet .btn") };
  });

  prova(`${vy.namn}: sidan är i pekläge`, m.pek === true, `body.pek ${m.pek}`);

  const forSma = k => k.filter(b => b.h < GOLV);
  const visa = k => k.slice(0, 5).map(b => `"${b.t}" ${b.w}×${b.h}`).join(" · ");

  prova(`${vy.namn}: skaparens chips når golvet`,
    m.chips.length > 0 && forSma(m.chips).length === 0,
    m.chips.length === 0 ? "inga chips synliga"
      : `${forSma(m.chips).length} av ${m.chips.length} under ${GOLV} px${
          forSma(m.chips).length ? " — " + visa(forSma(m.chips)) : ` (lägsta ${Math.min(...m.chips.map(b => b.h))} px)`}`);

  prova(`${vy.namn}: skaparens flikar når golvet`,
    m.flikar.length > 0 && forSma(m.flikar).length === 0,
    m.flikar.length === 0 ? "inga flikar synliga"
      : `${forSma(m.flikar).length} av ${m.flikar.length} under ${GOLV} px${
          forSma(m.flikar).length ? " — " + visa(forSma(m.flikar)) : ` (lägsta ${Math.min(...m.flikar.map(b => b.h))} px)`}`);

  /* Kontrollmätning: `.btn` i samma ark ska REDAN nå golvet. Faller den
     är det inte skaparen som är fel utan mobil.js — och då mäter provet
     något annat än det heter. */
  prova(`${vy.namn}: kontrollmätning — vanliga .btn når redan golvet`,
    m.knappar.length === 0 || forSma(m.knappar).length === 0,
    `${m.knappar.length} knappar${forSma(m.knappar).length ? ", " + visa(forSma(m.knappar)) : ""}`);

  await page.close();
}

/* KONTROLLMÄTNING PÅ SKRIVBORD. Golvet ska gälla FINGRET, inte alla.
   Utan den här raden kunde rättelsen ha varit "gör chipsen 44 px överallt"
   — grönt ovan, men en tyst designändring av skrivbordsvyn som ingen
   bett om. Här ska de vara kvar kompakta. */
{
  console.log("\n── skrivbord 1366 (utan pekskärm) ──");
  const page = await browser.newPage({ viewport: { width: 1366, height: 768 }, hasTouch: false });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(800);
  const d = await page.evaluate(() => {
    const c = [...document.querySelectorAll(".skapChip")].filter(b => b.offsetParent !== null)
      .map(b => Math.round(b.getBoundingClientRect().height));
    return { pek: document.body.classList.contains("pek"), hojder: c };
  });
  prova("skrivbordet är INTE i pekläge", d.pek === false, `body.pek ${d.pek}`);
  prova("chipsen är kvar kompakta på skrivbord — golvet gäller fingret, inte alla",
    d.hojder.length > 0 && Math.max(...d.hojder) < GOLV,
    d.hojder.length ? `högsta ${Math.max(...d.hojder)} px, golv ${GOLV}` : "inga chips");
  await page.close();
}

console.log(fel ? `\n${fel} FEL` : "\nALLA SKAPARKONTROLLER OK");
await browser.close(); srv.close();
process.exit(fel ? 1 : 0);
