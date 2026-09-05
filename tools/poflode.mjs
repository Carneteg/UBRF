#!/usr/bin/env node
/* PO-FLÖDET — den VERKLIGA vägen till läktaren, från spelstart.

   Senior review av #85 hittade luckan: tools/laktartest.mjs kör
   `startaVandring()` och placerar sedan figuren med `gaTill("ridhusinne",
   …)` på dörrens innerkoordinat. Det är inte vad en spelare gör. Testet
   kunde alltså vara grönt medan den faktiska webbrutten var trasig — och
   det var precis vad som hände: PO kunde inte gå på läktaren i previewn.

   Här finns INGEN gaTill in i ridhusinne. Kedjan är spelarens:

     spelstart på gården  →  gå till entrémarkören  →  E  →  ridhusinne
     →  hitta vägen upp  →  läktardäcket

   Allt gås med riktiga tangenter genom spelets inputväg.

   Kör: python3 tools/build.py && node tools/poflode.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8871;
const srv = http.createServer((q, s) => {
  const p = path.join(DIST, decodeURIComponent(q.url.split("?")[0] === "/" ? "/ridskolan.html" : q.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { s.writeHead(404); s.end(); return; } s.writeHead(200, { "content-type": "text/html" }); s.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push({ namn, ok }); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };
const mat = (namn, detalj) => console.log("  mät ", namn, "—", detalj);

for (const mobil of [false, true]) {
  const namn = mobil ? "MOBIL/touch" : "DATOR/tangent";
  const page = await browser.newPage(mobil
    ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 } });
  page.on("pageerror", e => console.log("PAGEERROR", e.message));
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(1600);
  await page.evaluate(() => startaVandring());
  await page.waitForTimeout(600);
  await page.evaluate(() => { if (G.vy !== "3d") vaxlaVy(); });
  await page.waitForTimeout(400);

  const F = await page.evaluate(() => {
    const d = ANL.dorrar.find(d => d.id === "ridhus_n");
    const ls = SPELABSTRAKTIONER.ridhus.laktarSteg, L = RIDHUSINNE.laktare;
    return { start: { x: VD.px, y: VD.py }, markor: d.pos, spawn: d.spawn,
      steg: { x0: ls.x0, x1: ls.x1, y0: ls.y0, y1: ls.y1 },
      dack: { z: L.dackZ, x0: L.x0, d: L.dackDjup } };
  });

  /* Går mot en punkt med riktiga tangenter, som spelaren: spelet räknar
     ix = D − A, iy = W − S och roterar med kameran. Harnessen väljer bara
     vilka tangenter som hålls. */
  const VAL = [{ ix: 0, iy: 1, k: ["KeyW"] }, { ix: 1, iy: 1, k: ["KeyW", "KeyD"] },
    { ix: -1, iy: 1, k: ["KeyW", "KeyA"] }, { ix: 1, iy: 0, k: ["KeyD"] }, { ix: -1, iy: 0, k: ["KeyA"] }];
  const vd = a => Math.atan2(Math.sin(a), Math.cos(a));
  let nere = [], joy = false;
  const tryck = async v => {
    if (mobil) { await page.evaluate(({ ix, iy }) => { window.__mal = { ix, iy }; }, v); return; }
    for (const t of nere) if (!v.k.includes(t)) await page.keyboard.up(t);
    for (const t of v.k) if (!nere.includes(t)) await page.keyboard.down(t);
    nere = v.k.slice();
  };
  const slapp = async () => {
    if (mobil) { await page.evaluate(() => { if (window.__joy) clearInterval(window.__joy); window.__joy = null; IN.joy = null; }); joy = false; return; }
    for (const t of nere) await page.keyboard.up(t); nere = [];
  };
  async function gaMot(mal, maxMs) {
    /* Målet ligger på window.__mal och LÄSES varje tick. Först skapade jag
       intervallet en gång och fångade `mal` i stängningen, så alla ben
       styrde mot det första benets mål — ett fel i harnessen som såg ut
       som ett fel i spelet. */
    await page.evaluate(({ mal }) => { window.__mal = mal; }, { mal });
    if (mobil && !joy) {
      await page.evaluate(() => { window.__joy = setInterval(() => {
        const m = window.__mal; if (!m) return;
        const k = Math.atan2(m[1] - VD.py, m[0] - VD.px);
        const v = vandringYaw(), w = v - k;
        IN.joy = { x: Math.sin(w), y: -Math.cos(w), styrka: 0.95 }; }, 16); });
      joy = true;
    }
    const t0 = Date.now(); let forra = null, still = 0, st = null;
    for (;;) {
      await page.waitForTimeout(120);
      st = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2),
        yaw: vandringYaw(), scen: G.scen }));
      if (Math.hypot(st.x - mal[0], st.y - mal[1]) < 0.7) return { ...st, slut: "framme" };
      const fl = forra ? Math.hypot(st.x - forra.x, st.y - forra.y) : Infinity;
      still = fl < 0.03 ? still + 1 : 0; forra = st;
      if (still >= 8) return { ...st, slut: "STOPP" };
      if (Date.now() - t0 > maxMs) return { ...st, slut: "tid slut" };
      if (!mobil) {
        const m = Math.atan2(mal[1] - st.y, mal[0] - st.x);
        let b = VAL[0], bd = Infinity;
        for (const v of VAL) { const d = Math.abs(vd(st.yaw - Math.atan2(v.ix, v.iy) - m)); if (d < bd) { bd = d; b = v; } }
        if (b.k.join() !== nere.join()) await tryck(b);
      }
    }
  }

  /* 1. Gården → entrémarkören → in. Ingen gaTill. */
  let r = await gaMot(F.markor, 120000); await slapp();
  const vidEntre = r.slut === "framme";
  if (vidEntre) { await page.keyboard.down("KeyE"); await page.waitForTimeout(200);
    await page.keyboard.up("KeyE"); await page.waitForTimeout(900); }
  const inne = await page.evaluate(() => ({ scen: G.scen, x: +VD.px.toFixed(2), y: +VD.py.toFixed(2) }));
  prova(`${namn}: spelstart på gården → entrén → inne i ridhuset (ingen gaTill)`,
    vidEntre && inne.scen === "ridhusinne",
    `gården (${F.start.x}, ${F.start.y}) → markören → scen ${inne.scen} vid (${inne.x}, ${inne.y})`);

  /* 2. DISKOVERBARHET — den fråga PO:s repro ställer.
     Spelaren landar 20 m öster om läktaren och vet inte var uppgången är.
     Finns någon ledtråd i spelet som pekar dit? Markörerna räknas upp och
     mäts; kravet är att MINST EN av dem leder till läktaren eller dess
     uppgång. Utan det finns vägen men går inte att hitta, och det är
     precis vad "kan inte gå på läktaren" betyder för en spelare. */
  const cue = await page.evaluate(({ steg, dack }) => {
    const L = interaktioner();
    const nara = L.map(i => ({ text: i.text, pos: i.pos,
      avst: +Math.hypot(VD.px - i.pos[0], VD.py - i.pos[1]).toFixed(1) })).sort((a, b) => a.avst - b.avst);
    /* En markör "leder till läktaren" om den står på däcket eller vid
       uppgången — inte om den råkar nämna något annat. */
    /* En markör LEDER TILL LÄKTAREN bara om den står PÅ den — alltså på
       däcksnivå — eller uttryckligen nämner den. Att en dörr råkar ligga
       inom däckets x-intervall räcker inte: «Ut» vid (1,6, 67,2) står på
       hallgolvet och leder ut ur huset, inte upp. Första versionen av det
       här filtret godkände den, och det var ett falskt positivt i mitt
       eget test. */
    const pekar = nara.filter(m =>
      /läktar/i.test(m.text) || ridhusNiva(m.pos[0], m.pos[1], 0) >= dack.z - 0.02);
    return { alla: nara.slice(0, 6), pekar };
  }, F);
  mat(`${namn}: markörer inom räckhåll vid ankomsten`,
    cue.alla.map(m => `${m.avst} m «${m.text}»`).join("  ·  "));
  prova(`${namn}: spelet pekar ut vägen upp på läktaren från entrén`,
    cue.pekar.length > 0,
    cue.pekar.length ? cue.pekar.map(m => `«${m.text}» @ ${m.avst} m`).join(", ")
      : "INGEN markör leder till läktaren eller dess uppgång — vägen finns men går inte att hitta");

  /* 3. Den fysiska vägen, när man VET var den är. Skiljer diskoverbarhet
     från framkomlighet: faller den här är det geometri, faller bara 2 är
     det skyltning. */
  const mittX = (F.steg.x0 + F.steg.x1) / 2;
  r = await gaMot([mittX, F.steg.y1 + 0.9], 120000);
  const framme = r.slut === "framme";
  r = await gaMot([mittX, F.steg.y0 - 1.5], 90000); await slapp();
  prova(`${namn}: den fysiska vägen upp fungerar när man vet var den är`,
    framme && r.z >= F.dack.z - 0.02,
    `(${r.x}, ${r.y}) z ${r.z} av ${F.dack.z}`);

  /* 4. NAIV SPELARE: går rakt fram från ankomsten, som den som inte vet. */
  /* HELT ostyrd: bara framåt, ingen A/D, ingen joystickkorrigering. Det
     är vad någon gör som inte vet vart hon ska. Styr man mot en punkt är
     promenaden inte naiv, och då mäter fallet fel sak — så var det i
     första versionen av det här testet. */
  await page.evaluate(({ sp }) => { window.__mal = null; if (window.__joy) { clearInterval(window.__joy); window.__joy = null; }
    slutaGa(); gaTill("ridhusinne", { x: sp.x, y: sp.y, rikt: sp.rikt });
    if (typeof V3D !== "undefined" && V3D.kam) V3D.kam.satt = false; }, { sp: F.spawn });
  await page.waitForTimeout(500);
  let naiv = null;
  if (mobil) {
    await page.evaluate(() => { window.__joy = setInterval(() => {
      IN.joy = { x: 0, y: -1, styrka: 0.95 }; }, 16); });
  } else await page.keyboard.down("KeyW");
  {
    const t0 = Date.now(); let f = null, st = 0;
    for (;;) {
      await page.waitForTimeout(150);
      naiv = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2) }));
      const fl = f ? Math.hypot(naiv.x - f.x, naiv.y - f.y) : Infinity;
      st = fl < 0.03 ? st + 1 : 0; f = naiv;
      if (st >= 8) { naiv.slut = "STOPP"; break; }
      if (Date.now() - t0 > 25000) { naiv.slut = "tid slut"; break; }
    }
  }
  if (mobil) await page.evaluate(() => { clearInterval(window.__joy); window.__joy = null; IN.joy = null; });
  else await page.keyboard.up("KeyW");
  mat(`${namn}: bara framåt från ankomsten, ingen styrning alls`,
    `stannade (${naiv.x}, ${naiv.y}) z ${naiv.z} — ${naiv.slut}` +
    (naiv.z >= F.dack.z - 0.02 ? "  (hamnade ändå på däcket)" : "  (kom aldrig upp)"));

  await page.close();
}
await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
