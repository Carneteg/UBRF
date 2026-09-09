/* REPLAYPANELEN PÅ RIKTIGA SKÄRMAR (#153 fix 4 / QA-2).

   "Se ritten" är G02-D:s kärna: spelaren ser sin egen väg ritad. Panelen
   byggdes med ett tvåkolumnsrutnät satt som INLINE-stil, och en
   inline-regel kan ingen media query ta över. Kolumnerna låg därför kvar
   hela vägen ner, och på en telefon blev ritt-canvasen — själva poängen —
   en liten ruta bredvid en trång textspalt.

   Roblox-panelen rättades efter reviewen på #151. Webbversionen av samma
   funktion hade bara provats i 1280×720.

   Provet rider ett riktigt pass genom spelets egen loop och mäter sedan
   den verkliga panelen. Uppsättningen är samma som replaytest använder.
*/
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8898;

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

/* Smal skärm ska ha EN kolumn och en canvas som går att se ritten i;
   bred skärm får behålla två. Gränsen läses ur samma tal som CSS:en. */
const vyer = [
  { namn: "iPhone SE 320", width: 320, height: 568, enKolumn: true, minCanvas: 240 },
  { namn: "telefon 390", width: 390, height: 844, enKolumn: true, minCanvas: 300 },
  { namn: "iPad porträtt 768", width: 768, height: 1024, enKolumn: true, minCanvas: 480 },
  { namn: "iPad landscape 1024", width: 1024, height: 768, enKolumn: false, minCanvas: 300 },
  { namn: "skrivbord 1366", width: 1366, height: 768, enKolumn: false, minCanvas: 300 },
];

for (const vy of vyer) {
  console.log(`\n── ${vy.namn} (${vy.width}×${vy.height}) ──`);
  const page = await browser.newPage({
    viewport: { width: vy.width, height: vy.height }, hasTouch: vy.width < 1100,
  });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(800);

  /* Rid ett riktigt pass — samma uppsättning som replaytest.mjs. */
  const kord = await page.evaluate(() => {
    if (typeof SPAR !== "undefined" && SPAR) SPAR.pass = Math.max(1, SPAR.pass || 0);
    G.hastId = G.hastId || Object.keys(HORSES)[0];
    G.hastPlats = "box"; G.npcs = []; G.dagsform = 0.72; G.sadellage = 0.8;
    G.ride = nyState(G.dagsform, hastminne(G.hastId).rang, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
    lararNollstall(); startaLektion();
    const ix = G.lektion.findIndex(m => {
      const o = ugnetaOvningFor(m);
      return o && typeof ovningsDef === "function" && ovningsDef(o.id);
    });
    if (ix < 0) return { fel: "ingen definierad övning" };
    G.momentIx = ix; G.moment = G.lektion[ix]; G.momentForsok = 1;
    G.momentT = 0; G.momentHall = 0; G.momentKlart = false;
    const dt = 1 / 30;
    for (let i = 0; i < 5200; i++) {
      if (G.paus) { const igen = document.getElementById("valIgen");
        if (igen) igen.click(); else break; continue; }
      IN.ned.KeyW = true; if (i % 90 < 45) IN.ned.KeyD = true; else delete IN.ned.KeyD;
      if (typeof stegaRitt === "function") stegaRitt(dt);
      if (typeof stegaLektion === "function") stegaLektion(dt);
    }
    delete IN.ned.KeyW; delete IN.ned.KeyD;
    return { ok: true };
  });
  if (kord.fel) { prova(`${vy.namn}: kunde rida ett pass`, false, kord.fel); await page.close(); continue; }

  const m = await page.evaluate(() => {
    const id = Object.keys(LARARE.forsok || {}).find(k => replayFinns(k));
    if (!id) return { fel: "ingen inspelning" };
    if (!visaReplay(id)) return { fel: "visaReplay nekade" };
    const rutn = document.getElementById("replayRutnat");
    const bana = document.getElementById("replayBana");
    if (!rutn || !bana) return { fel: "panelen saknas" };
    const kol = getComputedStyle(rutn).gridTemplateColumns.trim().split(/\s+/);
    const br = bana.getBoundingClientRect();
    const knappar = [...document.querySelectorAll("#ov button")]
      .filter(b => b.offsetParent !== null)
      .map(b => { const r = b.getBoundingClientRect();
        return { t: (b.textContent || "").trim().slice(0, 14),
          w: Math.round(r.width), h: Math.round(r.height),
          hoger: Math.round(r.right), vanster: Math.round(r.left) }; });
    return { kolumner: kol.length, kolText: kol.join(" "),
      canvas: Math.round(br.width), canvasH: Math.round(br.height),
      hoger: Math.round(br.right), vanster: Math.round(br.left), knappar };
  });
  if (m.fel) { prova(`${vy.namn}: panelen gick att öppna`, false, m.fel); await page.close(); continue; }

  prova(`${vy.namn}: rutnätet har ${vy.enKolumn ? "EN" : "två"} kolumn${vy.enKolumn ? "" : "er"}`,
    vy.enKolumn ? m.kolumner === 1 : m.kolumner >= 2,
    `${m.kolumner} kolumn(er): ${m.kolText}`);
  prova(`${vy.namn}: ritt-canvasen är stor nog att se banan i`,
    m.canvas >= vy.minCanvas, `${m.canvas}×${m.canvasH} px, krav ≥ ${vy.minCanvas}`);
  prova(`${vy.namn}: panelen svämmar inte över kanten`,
    m.vanster >= -1 && m.hoger <= vy.width + 1,
    `canvas h:${m.vanster}–${m.hoger} av ${vy.width}`);
  const utanfor = m.knappar.filter(b => b.hoger > vy.width + 1 || b.vanster < -1);
  prova(`${vy.namn}: alla knappar innanför skärmen`,
    utanfor.length === 0,
    utanfor.length ? utanfor.map(b => `"${b.t}" ${b.vanster}–${b.hoger}`).join(" · ")
      : `${m.knappar.length} knappar`);
  if (vy.width < 1100) {
    const sma = m.knappar.filter(b => b.h < 44);
    prova(`${vy.namn}: knapparna är minst 44 px höga`,
      sma.length === 0,
      sma.length ? sma.map(b => `"${b.t}" ${b.w}×${b.h}`).join(" · ")
        : m.knappar.map(b => `${b.w}×${b.h}`).join(" "));
  }
  await page.close();
}

console.log(fel ? `\n${fel} FEL` : "\nALLA REPLAYLAYOUTKONTROLLER OK");
await browser.close(); srv.close();
process.exit(fel ? 1 : 0);
