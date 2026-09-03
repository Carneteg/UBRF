#!/usr/bin/env node
/* Gångtest — Spatial Canon v2, SCV2-03 (docs/SPATIAL-CANON-V2-IMPLEMENTATION-ORDER.md § 5).

   Kör webbversionen i Chromium och GÅR kedjan
     main_entrance → open_entrance_hall → arena_access → physical_riding_area
   med spelets riktiga kollision (world.js, GA.radie 0,35 m), inte med
   punktprov mot datan. Teleporterar till huvudentréns innerpunkt (fasadens
   dörr under kvisten), håller W i en given riktning och läser var spelaren
   hamnade. Rött om hon inte kommer fram.

   Kör: python3 tools/build.py && node tools/gangtest.mjs
   Kräver Playwright + Chromium (samma harness som golden views). */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const PORT = 8791;
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };
const srv = http.createServer((req, res) => {
  const p = path.join(DIST, decodeURIComponent(req.url.split("?")[0] === "/" ? "/index.html" : req.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { res.writeHead(404); res.end(); return; } res.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" }); res.end(d); });
});
await new Promise(r => srv.listen(PORT, r));

const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on("pageerror", e => console.log("PAGEERROR", e.message));
await page.goto(`http://localhost:${PORT}/ridskolan.html`, { waitUntil: "load" });
await page.waitForTimeout(1500);
await page.evaluate(() => { try { startaVandring(); } catch (e) { console.log("startaVandring:", e.message); } });
await page.waitForTimeout(600);

/* Ett steg: teleportera till (x,y) med blicken i `rikt`, håll W tills
   `klar(pos)` är sant eller `maxMs` gått, läs slutläget. Tangenten är
   kamerarelativ, så W = rakt fram längs `rikt`. Tidsoberoende: headless
   SwiftShader ger få bildrutor per sekund, så sträckan mäts, inte tiden. */
async function ga(scen, x, y, rikt, klar, maxMs) {
  await page.evaluate(({ scen, x, y, rikt }) => gaTill(scen, { x, y, rikt }), { scen, x, y, rikt });
  await page.waitForTimeout(400);
  await page.keyboard.down("KeyW");
  const t0 = Date.now();
  let p;
  do {
    await page.waitForTimeout(200);
    p = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2) }));
  } while (!klar(p) && Date.now() - t0 < maxMs);
  await page.keyboard.up("KeyW");
  await page.waitForTimeout(150);
  return p;
}

const info = await page.evaluate(() => {
  const R = RIDHUSINNE, sp = SPELABSTRAKTIONER.ridhus.sargport;
  const d = R.dorrar.find(d => d.id === "ut_ridhus_W_9");
  return { dorr: d && d.pos, sargport: { x0: sp.x0, x1: sp.x1, y: sp.y }, banaTopp: R.bana.y + R.bana.h, hallY0: R.entrehall.y0 };
});
console.log("huvudentréns innerpunkt", info.dorr, "sargport", info.sargport, "banans norra sarg y", info.banaTopp.toFixed(2));
const [dx, dy] = info.dorr;
const px = (info.sargport.x0 + info.sargport.x1) / 2;
const N = Math.PI / 2, S = -Math.PI / 2, O = 0;
const resultat = [];
function prova(namn, ok, detalj) { resultat.push({ namn, ok, detalj }); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); }

/* 1. main_entrance → open_entrance_hall: från dörren norrut längs västväggen
   genom hallen ända fram till toaletternas verifierade volym (N 2,4 = y 74,8;
   spelaren stannar vid 74,8 − 0,08 − 0,35 ≈ 74,37). 7 m utan någon vägg. */
let p = await ga("ridhusinne", dx, dy, N, q => q.y > 74.0, 20000);
prova("huvudentrén → norrut genom den öppna hallen fram till toaletterna (7 m utan vägg)", p.y > 74.0, `från y ${dy} till ${p.y} (WC-väggen vid 74,8)`);
/* 2. tvärs över hallen österut, norr om receptionens glas och söder om toaletterna. */
p = await ga("ridhusinne", 1.0, 73.5, O, q => q.x > 12.0, 24000);
prova("tvärs över hallen österut (11 m utan rumslådor)", p.x > 12.0, `från x 1,0 till ${p.x}`);
/* 3. open_entrance_hall → arena_access → physical_riding_area: från dörrens
   höjd, i sargportens x, söderut genom porten ut på banan. */
p = await ga("ridhusinne", px, dy, S, q => q.y < info.banaTopp - 3.0, 16000);
prova("huvudentrén → sargporten → ut på banan (söderut förbi sargen)", p.y < info.banaTopp - 3.0, `från y ${dy} till ${p.y} (sarg vid ${info.banaTopp.toFixed(2)})`);
/* 3b. samma sak från själva dörren: snett mot porten (blicken mot portens mitt). */
{
  const rikt = Math.atan2(info.sargport.y - 0.5 - dy, px - dx);
  p = await ga("ridhusinne", dx, dy, rikt, q => q.y < info.sargport.y - 0.4, 16000);
  prova("från dörren snett mot sargporten och igenom", p.y < info.sargport.y - 0.4, `till (${p.x}, ${p.y}), port x ${info.sargport.x0.toFixed(1)}–${info.sargport.x1.toFixed(1)}`);
}
/* 4. receptionens glas är kollision (som en vägg) — man går inte igenom det. */
p = await ga("ridhusinne", 1.0, 70.7, O, q => q.x > 2.2, 5000);
prova("receptionens glas stoppar (GLASS är kollision, inte hål)", p.x < 2.2, `från x 1,0 till ${p.x} (glas vid x 2,2)`);
/* 5. toaletterna är slutna volymer. */
p = await ga("ridhusinne", 0.8, 73.5, N, q => q.y > 74.8, 5000);
prova("toalettvolymen stoppar (WC-väggen N 2,4 är kollision)", p.y < 74.8, `från y 73,5 till ${p.y} (vägg vid 74,8)`);

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
