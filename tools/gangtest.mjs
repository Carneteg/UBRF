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
/* I 2D-vyn är tangenterna ABSOLUTA (W = norr, S = söder, D = öster,
   A = väster), oberoende av kameran. 3D-kameran kläms mot väggar vid
   teleport och styr då figuren snett — det är testets artefakt, inte
   spelets. Kollisionen och nivåerna är desamma i båda vyerna. */
await page.evaluate(() => { if (G.vy !== "2d") vaxlaVy(); });
await page.waitForTimeout(300);
const TANGENT = { N: "KeyW", S: "KeyS", O: "KeyD", V: "KeyA" };

/* Ett steg: teleportera till (x,y) på nivån `z`, håll tangenterna för
   `hall` (t.ex. "S" eller "SO") tills `klar(pos)` är sant eller `maxMs`
   gått, läs slutläget. Tidsoberoende: headless SwiftShader ger få
   bildrutor per sekund, så sträckan mäts, inte tiden. */
async function ga(scen, x, y, hall, klar, maxMs, z) {
  await page.evaluate(({ scen, x, y, z }) => gaTill(scen, { x, y, rikt: 0, z }), { scen, x, y, z: z || 0 });
  await page.waitForTimeout(300);
  const keys = [...hall].map(h => TANGENT[h]);
  for (const k of keys) await page.keyboard.down(k);
  /* BUDGETEN ÄR PROGRESSMEDVETEN, inte en platt klocka.

     Förut var det bara `Date.now() - t0 < maxMs`. På en långsam runner
     kunde en klättring hinna halvvägs innan tiden tog slut, och testet
     blev rött fast geometrin var hel — precis det som hände i CI på
     d8a67da: "bänkraderna går att gå upp för till översta raden" slutade
     på z 1,76 av 2,08, alltså MITT I klättringen.

     Nu skiljs två olika saker åt:
       · figuren rör sig fortfarande när budgeten tar slut  ⇒ förläng EN
         gång, hon var på väg,
       · figuren står still                                  ⇒ hon är
         blockerad, avbryt DIREKT.

     Det gör inte testet mildare — tvärtom. En verklig blockering faller
     nu snabbare och med tydligare orsak, och en långsam bildrutetakt kan
     inte längre se ut som en vägg. Slutläget bär med sig VARFÖR loopen
     slutade, så nästa läsare slipper gissa. */
  const t0 = Date.now();
  let p, forra = null, stillaSedan = 0, tak = maxMs, forlangd = false, orsak = "klar";
  for (;;) {
    await page.waitForTimeout(200);
    p = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2) }));
    if (klar(p)) break;
    const flyttad = forra ? Math.hypot(p.x - forra.x, p.y - forra.y) + Math.abs(p.z - forra.z) : Infinity;
    stillaSedan = flyttad < 0.05 ? stillaSedan + 1 : 0;
    forra = p;
    /* Fem avläsningar utan förflyttning: hon står mot något. */
    if (stillaSedan >= 5) { orsak = "blockerad"; break; }
    if (Date.now() - t0 >= tak) {
      if (!forlangd && stillaSedan === 0) { forlangd = true; tak = maxMs * 2; continue; }
      orsak = forlangd ? "budgeten slut trots förlängning" : "budgeten slut";
      break;
    }
  }
  for (const k of keys) await page.keyboard.up(k);
  await page.waitForTimeout(150);
  p.orsak = orsak;
  p.forlangd = forlangd;
  return p;
}
const gaZ = ga;

const info = await page.evaluate(() => {
  const R = RIDHUSINNE, sp = SPELABSTRAKTIONER.ridhus.sargport;
  const d = R.dorrar.find(d => d.id === "ut_ridhus_W_9");
  return { dorr: d && d.pos, sargport: { x0: sp.x0, x1: sp.x1, y: sp.y }, banaTopp: R.bana.y + R.bana.h, hallY0: R.entrehall.y0 };
});
console.log("huvudentréns innerpunkt", info.dorr, "sargport", info.sargport, "banans norra sarg y", info.banaTopp.toFixed(2));
const [dx, dy] = info.dorr;
const px = (info.sargport.x0 + info.sargport.x1) / 2;
const resultat = [];
function prova(namn, ok, detalj) { resultat.push({ namn, ok, detalj }); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); }

/* 1. main_entrance → open_entrance_hall: från dörren österut in i skåpgången
   och norrut genom hallen ända fram till gaveln (receptionen stänger västra
   bandets norra del sedan 2026-09-04 07:54; gången x 2,2–4,2 är fri). */
let p = await ga("ridhusinne", 2.6, dy + 1.4, "N", q => q.y > 76.0, 20000);
prova("skåpgången norrut genom den öppna hallen fram till gaveln (8 m utan vägg)", p.y > 76.0, `från y ${(dy + 1.4).toFixed(2)} till ${p.y} (gaveln vid 77,18)`);
/* 2. tvärs över hallen österut, norr om receptionens sydvägg. */
p = await ga("ridhusinne", 2.8, 75.7, "O", q => q.x > 12.0, 24000);
prova("tvärs över hallen österut norr om skåpraden (10 m utan rumslådor)", p.x > 12.0, `från x 2,8 till ${p.x}`);
/* 3. open_entrance_hall → arena_access → physical_riding_area: från dörrens
   höjd, i sargportens x, söderut genom porten ut på banan. */
p = await ga("ridhusinne", px, dy, "S", q => q.y < info.banaTopp - 3.0, 16000);
prova("huvudentrén → sargporten → ut på banan (söderut förbi sargen)", p.y < info.banaTopp - 3.0, `från y ${dy} till ${p.y} (sarg vid ${info.banaTopp.toFixed(2)})`);
/* 3b. samma sak från själva dörren i två ben: österut förbi däckstegens
   norra kant, sedan söderut genom porten. Slutläget måste ligga I porten
   och på golvnivå — inte uppe på däcket via stegen. */
{
  p = await ga("ridhusinne", dx, dy, "O", q => q.x > px - 0.2, 16000);
  const p2 = await ga("ridhusinne", p.x, p.y, "S", q => q.y < info.sargport.y - 0.4, 16000);
  const iPort = p2.x > info.sargport.x0 && p2.x < info.sargport.x1;
  prova("från dörren österut och söderut genom sargporten, på golvnivå", p2.y < info.sargport.y - 0.4 && iPort && p2.z < 0.05,
    `till (${p2.x}, ${p2.y}) z ${p2.z}, port x ${info.sargport.x0.toFixed(1)}–${info.sargport.x1.toFixed(1)}`);
}
/* 4. receptionens glas är kollision (som en vägg) — man går inte igenom det
   västerut från gången in i receptionen. */
p = await ga("ridhusinne", 3.4, 75.2, "V", q => q.x < 2.2, 5000);
prova("receptionens glas stoppar (GLASS är kollision, inte hål)", p.x > 2.2, `från x 3,4 till ${p.x} (glas vid x 2,2)`);
/* 5. receptionens sydvägg är kollision: norrut i västra bandet stannar man vid y 72,6. */
p = await ga("ridhusinne", 1.0, 71.0, "N", q => q.y > 72.6, 5000);
prova("receptionens sydvägg stoppar (WALL vid y 72,6; toaletterna finns inte längre i entrédelen)", p.y < 72.6, `från y 71,0 till ${p.y} (vägg vid 72,6)`);

/* ── TRAPPORNA (Product Owner 2026-09-03 17:16): nivåerna ska hänga ihop ──
   Figuren har en golvnivå (VD.pz). Ett steg som ändrar nivån mer än 0,36 m
   tas inte — trappan är därför enda vägen upp. */
const niv = await page.evaluate(() => {
  const R = RIDHUSINNE, K = R.kortanda, f = id => R.trappor.find(t => t.id === id);
  return { cafe: R.cafe.z0, topp: (K.sockelH || 0) + K.steg * K.stegH, K: { x0: K.x0, x1: K.x1, y0: K.y0, y1: K.y1, steg: K.steg, stegD: K.stegD },
    bank: SPELABSTRAKTIONER.ridhus.bankradSteg, cv: f("c_trappa_v"), co: f("c_trappa_o"), G: R.ovreGang };
});
const ym = (t) => (t.y0 + t.y1) / 2;
/* 6. entréhallen → bänkradsstegen (österut) → nedersta bänkraden. */
let q = await gaZ("ridhusinne", niv.bank.x0 - 0.6, ym(niv.bank), "O", r => r.x > niv.bank.x1 + 0.3, 12000);
prova("SPELKRAV (inte fidelity): entréhallen → spelets bänkradssteg (SPELABSTRAKTION) → nedersta bänkraden", q.x > niv.bank.x1 + 0.3 && q.z > niv.bank.z1 - 0.02, `till (${q.x}, ${q.y}) z ${q.z} (rad 1 = ${niv.bank.z1.toFixed(2)})`);
/* 7. upp för bänkraderna (norrut) till översta raden, i vänstra trappans x. */
/* Stoppvillkoret är NIVÅN, inte ett y som ligger inne i rad 3 (pollningen
   var 200 ms stannade figuren 13 cm före rad 4). Riserns spärr (trappan
   stiger 0,8 m i flyktens mitt) stoppar den strax efter. */
q = await gaZ("ridhusinne", (niv.cv.x0 + niv.cv.x1) / 2, niv.K.y0 + 0.5, "N", r => r.z > niv.topp - 0.02 || r.y > niv.K.y1 - 0.5, 12000, niv.bank.z1);
prova("bänkraderna går att gå upp för till översta raden", Math.abs(q.z - niv.topp) < 0.02, `till y ${q.y}, z ${q.z} (översta raden ${niv.topp.toFixed(2)})`);
/* 8a. vänstra C-trappan: från foten vid klockväggen västerut upp till caféplanet. */
q = await gaZ("ridhusinne", niv.cv.x1 - 0.2, ym(niv.cv), "V", r => r.z >= niv.cafe - 0.02, 20000, niv.topp);
prova("c_trappa_v: från foten vid klockan västerut upp till caféplanet", q.z >= niv.cafe - 0.02 && q.x < niv.cv.x0 + 0.5, `till (${q.x}, ${q.y}) z ${q.z} (café ${niv.cafe.toFixed(2)})`);
/* 8b. ... och norrut in i övre gången. */
q = await gaZ("ridhusinne", niv.cv.x0 + 0.3, ym(niv.cv), "N", r => r.y > niv.G.y0 + 0.8, 8000, niv.cafe);
prova("c_trappa_v → övre gången", q.y > niv.G.y0 + 0.8 && Math.abs(q.z - niv.cafe) < 0.02, `till (${q.x}, ${q.y}) z ${q.z}`);
/* 9a. högra C-trappan: från foten österut upp. */
q = await gaZ("ridhusinne", niv.co.x0 + 0.2, ym(niv.co), "O", r => r.z >= niv.cafe - 0.02, 20000, niv.topp);
prova("c_trappa_o: från foten vid klockan österut upp till caféplanet", q.z >= niv.cafe - 0.02 && q.x > niv.co.x1 - 0.5, `till (${q.x}, ${q.y}) z ${q.z}`);
q = await gaZ("ridhusinne", niv.co.x1 - 0.3, ym(niv.co), "N", r => r.y > niv.G.y0 + 0.8, 8000, niv.cafe);
prova("c_trappa_o → övre gången", q.y > niv.G.y0 + 0.8 && Math.abs(q.z - niv.cafe) < 0.02, `till (${q.x}, ${q.y}) z ${q.z}`);
/* 9c. LÄKTARTRAPPAN VID H (PO 2026-09-04 07:54, blocker 3): hallgolvet → spelets
   läktarsteg (SPELABSTRAKTION) → gångbrädan → raderna → översta raden →
   läktartrappan (STAIR) → landgången på övre plan → övre gången. */
const lak = await page.evaluate(() => { const R = RIDHUSINNE, L = R.laktare;
  return { L: { x0: L.x0, dackDjup: L.dackDjup, dackZ: L.dackZ, y1: L.y1, topp: L.dackZ + L.rader.antal * L.rader.stegH, stegH: L.rader.stegH },
    steg: SPELABSTRAKTIONER.ridhus.laktarSteg, t: R.trappor.find(t => t.id === "laktar_trappa_h"), V: R.ovreGangV, G: R.ovreGang }; });
q = await gaZ("ridhusinne", (lak.steg.x0 + lak.steg.x1) / 2, lak.steg.y1 + 0.6, "S", r => r.z > lak.L.dackZ - 0.02 && r.y < lak.L.y1 - 0.3, 10000, 0);
prova("SPELKRAV (inte fidelity): hallgolvet → spelets läktarsteg (SPELABSTRAKTION) → läktardäcket", q.z >= lak.L.dackZ - 0.02 && q.y < lak.L.y1 - 0.3, `till (${q.x}, ${q.y}) z ${q.z} (däck ${lak.L.dackZ.toFixed(2)})`);
/* Tvärs över raderna SÖDER om trappans fot: i trappans fotavtryck (läktarens
   västra meter, y ≥ t.y0) ersätter loppet översta raden som nivå. */
q = await gaZ("ridhusinne", lak.L.x0 + lak.L.dackDjup - 0.5, lak.t.y0 - 0.6, "V", r => r.z > lak.L.topp - 0.02 || r.x < lak.L.x0 + 0.8, 10000, lak.L.dackZ);
prova("gångbrädan → raderna → översta raden (0,3 m steg)", Math.abs(q.z - lak.L.topp) < 0.02, `till (${q.x}, ${q.y}) z ${q.z} (översta raden ${lak.L.topp.toFixed(2)})`);
q = await gaZ("ridhusinne", (lak.t.x0 + lak.t.x1) / 2, lak.t.y0 - 0.3, "N", r => r.z >= lak.t.z1 - 0.02, 20000, lak.L.topp);
prova("läktartrappan vid H: från översta raden norrut upp till caféplanet", q.z >= lak.t.z1 - 0.02 && q.y > lak.t.y1 - 0.5, `till (${q.x}, ${q.y}) z ${q.z} (café ${lak.t.z1.toFixed(2)})`);
q = await gaZ("ridhusinne", (lak.V.x0 + lak.V.x1) / 2, lak.V.y0 + 0.3, "N", r => r.y > lak.G.y0 + 0.8, 10000, lak.V.z);
prova("landgången på övre plan → övre gången", q.y > lak.G.y0 + 0.8 && Math.abs(q.z - lak.V.z) < 0.02, `till (${q.x}, ${q.y}) z ${q.z}`);
/* 10. övre gången är gångbar längs hela bredden. */
q = await gaZ("ridhusinne", 2.0, niv.G.y0 + 1.2, "O", r => r.x > 20.0, 30000, niv.cafe);
prova("övre gången är gångbar österut (18 m)", q.x > 20.0 && Math.abs(q.z - niv.cafe) < 0.02, `till x ${q.x}, z ${q.z}`);
/* 11. NEGATIVT: från översta raden mellan trapporna (klockväggen) rakt norrut — ingen väg upp utan trappa. */
q = await gaZ("ridhusinne", (niv.cv.x1 + niv.co.x0) / 2, niv.K.y1 - 0.5, "N", r => r.y > niv.G.y0 + 0.3 && r.z > niv.cafe - 0.1, 5000, niv.topp);
prova("klockväggen mellan trapporna: ingen osynlig väg upp till övre gången", !(r => r)(q.y > niv.G.y0 + 0.3 && q.z > niv.cafe - 0.1), `till (${q.x}, ${q.y}) z ${q.z}`);
/* 12. NEGATIVT: från hallgolvet rakt in i bänkblocket utan stegen — nivåregeln stoppar. */
q = await gaZ("ridhusinne", niv.K.x0 + 3.0, niv.K.y1 + 0.8, "S", r => r.y < niv.K.y1 - 0.5, 5000);
prova("bänkblockets baksida utan trappa stoppar (ingen osynlig ramp)", !(q.y < niv.K.y1 - 0.5 && q.z > 0.5), `till (${q.x}, ${q.y}) z ${q.z}`);

/* ── GÅ-HIT UPP PÅ LÄKTAREN (Product Owner 2026-09-04 15:20: "spelaren kan
   inte gå upp på läktaren", upptäckt i mobil/webb). Pekskärmens och
   kartvyns primära styrning är gå-hit: ett tryck på läktaren ska ge en väg
   via stegen och figuren ska komma upp — inte stanna bredvid däcket.
   Vägsökningen räknar nu nivåerna (NAV.nivafri + nivåregeln kant för
   kant), rutnätet är mindre försiktigt inomhus (skåpraden/schaktet,
   bordet i gången) och fastnadsvakten mäter mot delmålet. */
async function tapp(fx, fy, fz, tx, ty, maxMs) {
  await page.evaluate(({ fx, fy, fz }) => { slutaGa(); gaTill("ridhusinne", { x: fx, y: fy, rikt: 0, z: fz }); }, { fx, fy, fz });
  await page.waitForTimeout(300);
  const vag = await page.evaluate(({ tx, ty }) => { satMal(tx, ty); return VD.vag; }, { tx, ty });
  const t0 = Date.now(); let p;
  do { await page.waitForTimeout(300); p = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2), mal: !!VD.mal })); }
  while (p.mal && Date.now() - t0 < maxMs);
  return { ...p, vag };
}
const viaSteg = (vag) => !!(vag && vag.some(v => v[0] >= lak.steg.x0 - 0.3 && v[0] <= lak.steg.x1 + 0.3 && v[1] >= lak.steg.y0 - 0.3 && v[1] <= lak.steg.y1 + 0.9));
const dackX = lak.L.x0 + lak.L.dackDjup - 0.6;
/* T1. från huvudentrén: tryck på däcket 3 m in. */
q = await tapp(dx, dy, 0, dackX, lak.L.y1 - 3.0, 30000);
prova("GÅ-HIT: från entrén upp på läktardäcket (vägen via stegen)", q.z >= lak.L.dackZ - 0.02 && Math.hypot(q.x - dackX, q.y - (lak.L.y1 - 3.0)) < 1.0 && viaSteg(q.vag), `till (${q.x}, ${q.y}) z ${q.z}, väg ${JSON.stringify(q.vag && q.vag.map(v => v.slice(0, 2).map(n => +n.toFixed(1))))}`);
/* T2. från hallen öster om skåpraden: tryck på läktargången 20 m söderut. */
q = await tapp(4.8, 72.0, 0, dackX, lak.L.y1 - 20.0, 70000);
prova("GÅ-HIT: från hallen (öster om skåpen) längs läktargången 20 m söderut", q.z >= lak.L.dackZ - 0.02 && Math.abs(q.y - (lak.L.y1 - 20.0)) < 1.0 && viaSteg(q.vag), `till (${q.x}, ${q.y}) z ${q.z}, väg ${q.vag ? q.vag.length + " punkter" : "null"}`);
/* T3. från banan: tryck på översta raden — runt genom sargporten, upp för stegen, över raderna. */
q = await tapp(6.0, 40.0, 0, lak.L.x0 + 0.6, lak.L.y1 - 12.0, 90000);
/* Gå-hit stannar 0,9 m före målet (spelets ankomsttolerans), så figuren kan
   stå på näst översta raden när målet ligger på den översta. */
prova("GÅ-HIT: från banan upp på läktarens rader (via sargporten och stegen; minst näst översta raden)", q.z >= lak.L.topp - lak.L.stegH - 0.02 && Math.abs(q.y - (lak.L.y1 - 12.0)) < 1.2 && viaSteg(q.vag), `till (${q.x}, ${q.y}) z ${q.z} (översta raden ${lak.L.topp.toFixed(2)}), väg ${q.vag ? q.vag.length + " punkter" : "null"}`);
/* T4. NEGATIVT: vägen får inte gå rakt in i däckets kant — ett tryck på däcket
   från banans sida ska ändå gå via stegen. */
q = await tapp(5.0, 60.0, 0, dackX, 60.0, 40000);
prova("GÅ-HIT: från banans sida bredvid däcket — vägen går via stegen, inte in i kanten", viaSteg(q.vag) && q.z >= lak.L.dackZ - 0.02, `till (${q.x}, ${q.y}) z ${q.z}, via stegen: ${viaSteg(q.vag)}`);

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
