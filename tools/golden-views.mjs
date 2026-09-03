#!/usr/bin/env node
/* Golden views — Spatial Canon v2 (docs/SPATIAL-CANON-V2.md § Golden-view-process).

   Fyra fasta kameravyer som renderas exakt likadant varje gång, så att
   Product Owner kan jämföra en build mot den förra utan att navigera.
   Vyerna är regressionsbevis, inte ersättning för produktacceptans.

   Kör: python3 tools/build.py && node tools/golden-views.mjs
   Skriver docs/golden-views/<ID>.png (+ en JSON med kameraläge och
   antalet tonade väggar, så att en ändrad vy syns i diffen).

   Kräver Playwright + Chromium (samma harness som QA-renderingarna). */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const UT = path.join(ROT, "docs", "golden-views");
const PORT = 8790;

/* Kameralägen i husens lokala meter (x från väster, y från söder), som
   gaTill() tar dem. Ändra dem bara med ett dokumenterat skäl — då byts
   regressionsbasen. */
export const VYER = [
  { id: "STALL-V1",  scen: "stallinne",  x: 4.55, y: 68.4, rikt: -Math.PI / 2,
    text: "Parkeringens entré → in i uppehållsrummet: EN öppen L-formad yta, ingen inre vägg" },
  { id: "RIDHUS-V1", scen: "ridhusinne", x: 1.4,  y: 74.0, rikt: 0,
    text: "Huvudentrén → in över entré/reception: öppen hall, ingen korridor av rumslådor" },
  { id: "RIDHUS-V2", scen: "ridhusinne", x: 5.0,  y: 70.5, rikt: -Math.PI / 2,
    text: "Öppna entréhallen → ridbanan: vägen in till ridhuset syns och går att gå" },
  { id: "RIDHUS-V3", scen: "ridhusinne", x: 5.0,  y: 74.5, rikt: Math.PI,
    text: "Receptionens avgränsning: glas där den kan beläggas, inte en solid rumslåda" },
];

const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };
const srv = http.createServer((req, res) => {
  const p = path.join(DIST, decodeURIComponent(req.url.split("?")[0] === "/" ? "/index.html" : req.url.split("?")[0]));
  if (!fs.existsSync(p)) { res.writeHead(404); res.end(); return; }
  res.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" });
  res.end(fs.readFileSync(p));
}).listen(PORT);

const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on("pageerror", e => console.log("PAGEERROR", e.message));
await page.goto(`http://localhost:${PORT}/ridskolan.html`, { waitUntil: "load" });
await page.waitForTimeout(1500);
await page.evaluate(() => { try { startaVandring(); } catch (e) { console.log("startaVandring:", e.message); } });
await page.waitForTimeout(800);
fs.mkdirSync(UT, { recursive: true });
const logg = {};
for (const v of VYER) {
  await page.evaluate(({ scen, x, y, rikt }) => gaTill(scen, { x, y, rikt }), v);
  await page.waitForTimeout(1500);
  const info = await page.evaluate(() => ({
    kamera: [V3D.kam.x, V3D.kam.y, V3D.kam.z].map(n => +n.toFixed(2)),
    spelare: [VD.px, VD.py].map(n => +n.toFixed(2)),
    tonade: V3D.tonade,
  }));
  await page.screenshot({ path: path.join(UT, `${v.id}.png`) });
  logg[v.id] = { ...v, ...info };
  console.log(v.id, JSON.stringify(info), "—", v.text);
}
fs.writeFileSync(path.join(UT, "golden-views.json"), JSON.stringify(logg, null, 2) + "\n");
await browser.close();
srv.close();
