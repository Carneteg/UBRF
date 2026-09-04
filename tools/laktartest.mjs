#!/usr/bin/env node
/* Läktartest — issue #81 (P0). Kör spelets RIKTIGA movement-loop i 3D-vyn,
   bildruta för bildruta, med tangent OCH touch/joystick. Anropar aldrig
   vägsökaren: det var precis luckan i gangtest.mjs, som växlar till
   2D-kartvyn och därför aldrig provade den runtime PO faktiskt spelar.

   Bevisar per fall: spelaren går från golvnivå (z 0) upp på läktardäcket
   utan teleport (inget hopp > NIVA_STEG mellan bildrutor) och kan sedan
   röra sig minst 10 m längs läktargången.

   Kör: python3 tools/build.py && node tools/laktartest.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8812;
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };
const srv = http.createServer((q, s) => {
  const p = path.join(DIST, decodeURIComponent(q.url.split("?")[0] === "/" ? "/ridskolan.html" : q.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { s.writeHead(404); s.end(); return; } s.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" }); s.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push({ namn, ok }); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };

async function sida(mobil) {
  const page = await browser.newPage(mobil
    ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 } });
  page.on("pageerror", e => console.log("PAGEERROR", e.message));
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(1800);
  await page.evaluate(() => startaVandring());
  await page.waitForTimeout(600);
  await page.evaluate(() => { if (G.vy !== "3d") vaxlaVy(); });   // PO:s vy
  await page.waitForTimeout(400);
  return page;
}
/* Går med spelets riktiga loop och loggar VARJE prov: läge, nivå och att
   nivåbytet aldrig överstiger NIVA_STEG (ingen teleport). `touch` matar
   IN.joy som mobil.js gör; annars hålls W (kamerarelativt framåt). */
async function ga(page, { x, y, z = 0, rikt, ms, touch, klar }) {
  await page.evaluate(({ x, y, z, rikt }) => { slutaGa(); gaTill("ridhusinne", { x, y, rikt, z }); }, { x, y, z, rikt });
  await page.waitForTimeout(500);
  await page.evaluate(({ rikt }) => { VD.rikt = rikt; if (typeof V3D !== "undefined" && V3D.kam) V3D.kam.satt = false; }, { rikt });
  await page.waitForTimeout(400);
  await page.evaluate(() => { window.__spar = []; window.__hopp = 0; let f = (VD.pz || 0);
    window.__tick = () => { const z = VD.pz || 0; if (Math.abs(z - f) > NIVA_STEG + 1e-6) window.__hopp++; f = z;
      window.__spar.push([+VD.px.toFixed(2), +VD.py.toFixed(2), +z.toFixed(2)]);
      if (window.__gar) requestAnimationFrame(window.__tick); };
    window.__gar = true; requestAnimationFrame(window.__tick); });
  if (touch) await page.evaluate(({ rikt }) => { window.__joy = setInterval(() => {
      const v = vandringYaw(), w = v - rikt; IN.joy = { x: Math.sin(w), y: -Math.cos(w), styrka: 0.95 }; }, 16); }, { rikt });
  else await page.keyboard.down("KeyW");
  /* Tidsoberoende: headless SwiftShader ger få bildrutor per sekund, så
     villkoret avgör, inte klockan (samma princip som gangtest.mjs). `ms`
     är bara taket. */
  const t0 = Date.now();
  for (;;) {
    await page.waitForTimeout(250);
    if (Date.now() - t0 > ms) break;
    if (klar && await page.evaluate(({ f }) => (new Function("p", "return " + f))(
      { x: VD.px, y: VD.py, z: VD.pz || 0 }), { f: klar })) break;
  }
  if (touch) await page.evaluate(() => { clearInterval(window.__joy); IN.joy = null; });
  else await page.keyboard.up("KeyW");
  return await page.evaluate(() => { window.__gar = false;
    return { spar: window.__spar, hopp: window.__hopp, n: window.__spar.length,
      x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2) }; });
}
const S = Math.PI / -2;
for (const mobil of [false, true]) {
  const page = await sida(mobil);
  const namn = mobil ? "MOBIL/touch" : "DATOR/tangent";
  const I = await page.evaluate(() => { const R = RIDHUSINNE, L = R.laktare, ls = SPELABSTRAKTIONER.ridhus.laktarSteg;
    const d = R.dorrar.find(d => d.id === "ut_ridhus_W_9");
    return { dorr: d.pos, ls: { x0: ls.x0, x1: ls.x1, y0: ls.y0, y1: ls.y1 }, L: { dackZ: L.dackZ, y1: L.y1, x0: L.x0, d: L.dackDjup } }; });
  /* 1. Från huvudentrén rakt fram (söderut) upp på däcket — det PO gör. */
  /* Spelaren kliver in genom huvudentrén och går mot trappan hon ser —
     inte mot en osynlig punkt. Läktartrappan vid H upptar däckets
     nordvästra hörn, så däckets gångbara ände börjar strax öster om
     dörren; kursen tas därför mot stegens mitt. */
  const mot = Math.atan2(I.ls.y0 - I.dorr[1], (I.ls.x0 + I.ls.x1) / 2 - I.dorr[0]);
  let q = await ga(page, { x: I.dorr[0], y: I.dorr[1], rikt: mot, ms: 45000, touch: mobil,
    klar: `p.z >= ${I.L.dackZ - 0.02}` });
  prova(`${namn}: från huvudentrén till läktardäcket (kurs mot stegen)`,
    q.z >= I.L.dackZ - 0.02 && q.hopp === 0,
    `(${q.x}, ${q.y}) z ${q.z} efter ${q.n} bildrutor, teleporthopp ${q.hopp}`);
  /* 2. Angreppssvep: från golvet söderut på flera x längs däckets norra ände. */
  /* Svepet mäter STEGENS egen bredd: däckets nordvästra hörn upptas av
     läktartrappan vid H (z 1,7 → café) och är ingen ingång. */
  const bredd = [];
  for (let x = I.ls.x0 + 0.2; x <= I.ls.x1 - 0.2; x += 0.3) {
    const r = await ga(page, { x: +x.toFixed(2), y: I.ls.y1 + 1.0, rikt: S, ms: 20000, touch: mobil,
      klar: `p.z >= ${I.L.dackZ - 0.02}` });
    if (r.z >= I.L.dackZ - 0.02) bredd.push(+x.toFixed(1));
  }
  const antalProv = Math.floor((I.ls.x1 - 0.2 - (I.ls.x0 + 0.2)) / 0.3) + 1;
  prova(`${namn}: hela stegbredden går att gå upp för (inte en smal remsa)`,
    bredd.length >= antalProv - 1,
    `${bredd.length} av ${antalProv} angreppspunkter längs x ${I.ls.x0.toFixed(1)}–${I.ls.x1.toFixed(1)} kom upp: ${JSON.stringify(bredd)}`);
  /* 3. Minst 10 m längs läktargången, kvar på däcksnivå. */
  q = await ga(page, { x: (I.ls.x0 + I.ls.x1) / 2, y: I.ls.y0 - 0.8, z: I.L.dackZ, rikt: S, ms: 60000, touch: mobil,
    klar: `p.y <= ${I.ls.y0 - 0.8 - 10.5}` });
  const langd = (I.ls.y0 - 0.8) - q.y;
  prova(`${namn}: minst 10 m längs läktargången på däcksnivå`,
    langd >= 10 && q.z >= I.L.dackZ - 0.02 && q.hopp === 0,
    `gick ${langd.toFixed(1)} m söderut, slut z ${q.z}, teleporthopp ${q.hopp}`);
  /* MÄTNING, inte pass-krav (#81, öppen fråga till PO/ChatGPT): den som
     kliver in genom huvudentrén (x 1,6) och går RAKT söderut stannar
     fortfarande mot läktartrappan vid H, som når caféplanet (z 3,68) vid
     däckets nordvästra hörn. Det är arkitektur, inte en bugg — men det är
     också precis vad en spelare gör. Redovisas som siffra så att beslutet
     tas av PO, inte tyst av mig. */
  const rakt = await ga(page, { x: I.dorr[0], y: I.dorr[1], rikt: S, ms: 15000, touch: mobil,
    klar: `p.z >= ${I.L.dackZ - 0.02}` });
  console.log(`  mät  ${namn}: rakt söderut från dörren utan att sikta → (${rakt.x}, ${rakt.y}) z ${rakt.z}` +
    `${rakt.z >= I.L.dackZ - 0.02 ? " (kom upp)" : " (stoppas av trappan till caféet — öppen fråga i #81)"}`);
  await page.close();
}
await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
