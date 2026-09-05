#!/usr/bin/env node
/* STOPPDIAGNOSTIK — VAD står spelaren mot när det tar stopp?

   PO reproducerade felet igen på 8f15bef trots grön `gangbarhet`. Ordern
   var uttrycklig: gissa ingen ny root cause, mät i stället. Det här
   verktyget gissar ingenting — det går, och när det stannar räknar det
   upp ALLT som kolliderar inom 2 m med id, typ och källa.

   Två saker mina tidigare tester INTE gjorde, och som därför står här:

   1. De mätte bara att man kommer UPP på däcket. Acceptansen säger "upp
      på läktaren OCH VIDARE LÄNGS DEN". Att gå längs däcket var otestat.
   2. De körde en handfull raka approacher mot rampen. Här svepes hela
      hallgolvet i alla riktningar, som en spelare som letar.

   Ingen gaTill genom problemområdet. Riktiga tangenter och joystick.

   Kör: python3 tools/build.py && node tools/stoppdiag.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8873;
const srv = http.createServer((q, s) => {
  const p = path.join(DIST, decodeURIComponent(q.url.split("?")[0] === "/" ? "/ridskolan.html" : q.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { s.writeHead(404); s.end(); return; } s.writeHead(200, { "content-type": "text/html" }); s.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });

/* Sidfunktion: allt som kolliderar inom `rackvidd` av en punkt, med
   id/typ/källa. Byggd ur SAMMA listor som vandringKollision() läser, så
   den kan inte råka rapportera en annan värld än den spelaren går i. */
const KOLLIDORER = `(x, y, rackvidd) => {
  const R = RIDHUSINNE, z = VD.pz || 0, ut = [];
  const nara = (rk) => {
    const cx = Math.max(rk.x, Math.min(x, rk.x + rk.w));
    const cy = Math.max(rk.y, Math.min(y, rk.y + rk.h));
    return Math.hypot(x - cx, y - cy);
  };
  const lagg = (id, typ, kalla, rk, extra) => {
    const d = nara(rk);
    if (d <= rackvidd) ut.push({ id, typ, kalla, avst: +d.toFixed(2),
      rekt: [+rk.x.toFixed(2), +rk.y.toFixed(2), +(rk.x+rk.w).toFixed(2), +(rk.y+rk.h).toFixed(2)],
      ...(extra || {}) });
  };
  for (const o of INREDNING.ridhus) if (o.kolliderar)
    lagg(o.id, o.typ, (o.klass || "?") + "/" + (o.lage || "?"), inredningRekt(o),
      { paNiva: inredningPaNiva(o), z0: o.z0 || 0, h: o.matt.h });
  if (R.entrehall) {
    for (const v of R.entrehall.vaggar) { const t = (v.tjock || 0.16) / 2;
      for (const [a0, a1] of klubbVaggBitar(v))
        lagg(v.id || ("vagg_" + v.typ + "_" + (v.y ?? v.x)), "vagg", "entrehall",
          v.typ === "tvar" ? { x:a0, y:v.y-t, w:a1-a0, h:2*t } : { x:v.x-t, y:a0, w:2*t, h:a1-a0 }); }
    for (const rum of R.entrehall.rum) if (rum.stangt)
      lagg(rum.id || rum.namn || "rum", "slutet rum", "entrehall", rum.rekt);
  }
  for (const sek of laktarSektioner(R.laktare))
    lagg("laktare_sektion", "laktardack", "SPÄRRAR BARA VÄGSÖKNING (fx undefined)",
      { x: R.laktare.x0, y: sek.y0, w: R.laktare.dackDjup, h: sek.y1 - sek.y0 });
  if (R.kortanda) { const K = R.kortanda;
    lagg("kortanda", "kortanda", "SPÄRRAR BARA VÄGSÖKNING (fx undefined)",
      { x:K.x0, y:K.y0, w:K.x1-K.x0, h:K.y1-K.y0 }); }
  if (R.domarbas) lagg("domarbas", "domarbas", "ridhus",
    { x: R.domarbas.x - R.domarbas.b/2, y: R.domarbas.y - R.domarbas.b/2, w: R.domarbas.b, h: R.domarbas.b });
  return ut.sort((a, b) => a.avst - b.avst);
}`;

const rad = (t) => console.log(t);
const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push({ namn, ok }); rad((ok ? "  OK   " : "  FEL  ") + namn + " — " + detalj); };

for (const mobil of [false, true]) {
  const namn = mobil ? "MOBIL/touch" : "DATOR/tangent";
  rad("\n══════ " + namn + " ══════");
  const page = await browser.newPage(mobil
    ? { viewport: { width: 390, height: 844 }, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 } });
  page.on("pageerror", e => rad("PAGEERROR " + e.message));
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(1600);
  await page.evaluate(() => startaVandring());
  await page.waitForTimeout(600);
  await page.evaluate(() => { if (G.vy !== "3d") vaxlaVy(); });
  await page.waitForTimeout(400);
  await page.evaluate(k => { window.__kollidorer = eval(k); }, KOLLIDORER);

  const F = await page.evaluate(() => {
    const d = ANL.dorrar.find(d => d.id === "ridhus_n");
    const ls = SPELABSTRAKTIONER.ridhus.laktarSteg, L = RIDHUSINNE.laktare;
    return { markor: d.pos, steg: { x0: ls.x0, x1: ls.x1, y0: ls.y0, y1: ls.y1 },
      laktare: { x0: L.x0, djup: L.dackDjup, y0: L.y0, y1: L.y1, z: L.dackZ } };
  });

  const VAL = [{ ix:0, iy:1, k:["KeyW"] }, { ix:1, iy:1, k:["KeyW","KeyD"] },
    { ix:-1, iy:1, k:["KeyW","KeyA"] }, { ix:1, iy:0, k:["KeyD"] }, { ix:-1, iy:0, k:["KeyA"] }];
  const vd = a => Math.atan2(Math.sin(a), Math.cos(a));
  let nere = [], joy = false;
  const slapp = async () => {
    if (mobil) { await page.evaluate(() => { if (window.__joy) clearInterval(window.__joy); window.__joy = null; IN.joy = null; }); joy = false; return; }
    for (const t of nere) await page.keyboard.up(t); nere = [];
  };
  async function gaMot(mal, maxMs) {
    await page.evaluate(({ mal }) => { window.__mal = mal; }, { mal });
    if (mobil && !joy) {
      await page.evaluate(() => { window.__joy = setInterval(() => { const m = window.__mal; if (!m) return;
        const k = Math.atan2(m[1] - VD.py, m[0] - VD.px), v = vandringYaw(), w = v - k;
        IN.joy = { x: Math.sin(w), y: -Math.cos(w), styrka: 0.95 }; }, 16); });
      joy = true;
    }
    const t0 = Date.now(); let forra = null, still = 0, st = null;
    for (;;) {
      await page.waitForTimeout(120);
      st = await page.evaluate(() => ({ x:+VD.px.toFixed(2), y:+VD.py.toFixed(2), z:+(VD.pz||0).toFixed(2), yaw: vandringYaw(), scen: G.scen }));
      if (Math.hypot(st.x - mal[0], st.y - mal[1]) < 0.7) return { ...st, slut: "framme" };
      const fl = forra ? Math.hypot(st.x - forra.x, st.y - forra.y) : Infinity;
      still = fl < 0.03 ? still + 1 : 0; forra = st;
      if (still >= 8) return { ...st, slut: "STOPP" };
      if (Date.now() - t0 > maxMs) return { ...st, slut: "tid slut" };
      if (!mobil) { const m = Math.atan2(mal[1] - st.y, mal[0] - st.x);
        let b = VAL[0], bd = Infinity;
        for (const v of VAL) { const d = Math.abs(vd(st.yaw - Math.atan2(v.ix, v.iy) - m)); if (d < bd) { bd = d; b = v; } }
        if (b.k.join() !== nere.join()) { for (const t of nere) if (!b.k.includes(t)) await page.keyboard.up(t);
          for (const t of b.k) if (!nere.includes(t)) await page.keyboard.down(t); nere = b.k.slice(); } }
    }
  }
  /* Går RAKT på fast kurs, som en spelare som håller fram-knappen. */
  async function rakt(kurs, maxMs) {
    await page.evaluate(k => { window.__mal = null; if (window.__joy) { clearInterval(window.__joy); window.__joy = null; }
      VD.rikt = k; if (typeof V3D !== "undefined" && V3D.kam) V3D.kam.satt = false; }, kurs);
    await page.waitForTimeout(300);
    if (mobil) await page.evaluate(k => { window.__joy = setInterval(() => { const v = vandringYaw(), w = v - k;
      IN.joy = { x: Math.sin(w), y: -Math.cos(w), styrka: 0.95 }; }, 16); }, kurs);
    else await page.keyboard.down("KeyW");
    let p = null, f = null, still = 0; const t0 = Date.now(), spar = [];
    for (;;) {
      await page.waitForTimeout(120);
      p = await page.evaluate(() => ({ x:+VD.px.toFixed(2), y:+VD.py.toFixed(2), z:+(VD.pz||0).toFixed(2),
        rikt:+(VD.rikt*180/Math.PI).toFixed(1), niva:+ridhusNiva(VD.px,VD.py,VD.pz||0).toFixed(2),
        nivaer: ridhusNivaer(VD.px,VD.py).map(v => +v.toFixed(2)) }));
      spar.push(p);
      const fl = f ? Math.hypot(p.x - f.x, p.y - f.y) : Infinity;
      still = fl < 0.03 ? still + 1 : 0; f = p;
      if (still >= 7) { p.slut = "STOPP"; break; }
      if (Date.now() - t0 > maxMs) { p.slut = "gick klart"; break; }
    }
    if (mobil) await page.evaluate(() => { clearInterval(window.__joy); window.__joy = null; IN.joy = null; });
    else await page.keyboard.up("KeyW");
    p.spar = spar.slice(-4);
    return p;
  }
  const dumpa = async (p, rubrik) => {
    const koll = await page.evaluate(([x, y]) => window.__kollidorer(x, y, 2.0), [p.x, p.y]);
    rad(`  ${rubrik}`);
    rad(`    läge (${p.x}, ${p.y}) z ${p.z} · kurs ${p.rikt}° · nivå ${p.niva} av ${JSON.stringify(p.nivaer)} · ${p.slut}`);
    rad(`    sista frames: ${p.spar.map(s => `(${s.x},${s.y},z${s.z})`).join(" → ")}`);
    if (!koll.length) rad(`    KOLLIDERANDE INOM 2 m: inga — det är alltså INTE ett objekt som stoppar`);
    for (const k of koll.slice(0, 6))
      rad(`    ${k.avst} m  ${k.id}  [${k.typ}]  källa ${k.kalla}  rekt ${JSON.stringify(k.rekt)}` +
        (k.paNiva === undefined ? "" : `  påNivå=${k.paNiva} z0=${k.z0} h=${k.h}`));
    return koll;
  };

  /* ── 1. In i huset, spelarens väg ── */
  let r = await gaMot(F.markor, 120000); await slapp();
  if (r.slut !== "framme") { prova(`${namn}: nådde entrémarkören`, false, JSON.stringify(r)); continue; }
  await page.keyboard.down("KeyE"); await page.waitForTimeout(200);
  await page.keyboard.up("KeyE"); await page.waitForTimeout(900);
  const inne = await page.evaluate(() => ({ scen: G.scen, x:+VD.px.toFixed(2), y:+VD.py.toFixed(2) }));
  rad(`  inne: scen ${inne.scen} vid (${inne.x}, ${inne.y})`);

  /* ── 2. SVEP: rakt fram i alla riktningar från ankomsten ── */
  rad("\n  ── svep från ankomsten, fast kurs, ingen korrigering ──");
  const stopp = [];
  for (let g = -180; g < 180; g += 30) {
    await page.evaluate(({ sp }) => { window.__mal = null; slutaGa();
      gaTill("ridhusinne", { x: sp.x, y: sp.y, rikt: -Math.PI/2 }); }, { sp: { x: inne.x, y: inne.y } });
    await page.waitForTimeout(300);
    const p = await rakt(g * Math.PI / 180, 9000);
    rad(`    kurs ${String(g).padStart(4)}° → (${p.x}, ${p.y}) z ${p.z}  ${p.slut}`);
    if (p.slut === "STOPP") stopp.push({ g, p });
  }

  /* ── 3. UPP PÅ DÄCKET, och sedan VIDARE LÄNGS DET ── */
  rad("\n  ── upp på däcket, och vidare längs det (acceptanskravet) ──");
  const mittX = (F.steg.x0 + F.steg.x1) / 2;
  for (const wp of [[5.6, 73.4], [3.6, 73.4], [mittX, 71.0]]) { await gaMot(wp, 40000); await slapp(); }
  await gaMot([mittX, F.steg.y1 + 3.0], 60000); await slapp();
  const upp = await rakt(-Math.PI / 2, 12000);
  const paDack = upp.z >= F.laktare.z - 0.02;
  prova(`${namn}: kommer UPP på läktardäcket`, paDack,
    `(${upp.x}, ${upp.y}) z ${upp.z} · ${upp.slut}`);
  if (!paDack) await dumpa(upp, "STOPP PÅ VÄG UPP:");

  if (paDack) {
    /* VIDARE LÄNGS DÄCKET — söderut, längs gångbrädan. Det här är det
       acceptansen kräver och som aldrig har mätts. */
    /* Budgeten måste räcka HELA vägen förbi domarbåset. Med 15 s hann
       datorfallet bara till y 51,9 och gick "klart" på tid — grönt utan
       att ha nått hindret. Ett prov som tar slut före problemet bevisar
       ingenting. Målet är därför y < 28, alltså söder om båsets
       y-intervall, och budgeten är tilltagen därefter. */
    const FORBI = 28;
    const langs = await rakt(-Math.PI / 2, 60000);
    const kvar = langs.z >= F.laktare.z - 0.02;
    prova(`${namn}: kan gå VIDARE LÄNGS däcket förbi domarbåset`,
      langs.slut !== "STOPP" && kvar && langs.y <= FORBI,
      `från (${upp.x}, ${upp.y}) → (${langs.x}, ${langs.y}) z ${langs.z} · ${langs.slut}` +
      ` · däcket går y ${F.laktare.y0}–${F.laktare.y1}, krav y ≤ ${FORBI}, nådde y ${langs.y}`);
    if (langs.slut === "STOPP") await dumpa(langs, "STOPP LÄNGS DÄCKET:");
  }

  /* ── 4. Alla stopp från svepet, med full kollisionskontext ── */
  if (stopp.length) {
    rad("\n  ── stoppen från svepet, med allt inom 2 m ──");
    for (const s of stopp) await dumpa(s.p, `kurs ${s.g}°:`);
  }
  await page.close();
}
await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
rad("\n" + (fel ? `${fel} FEL` : "ALLA OK"));
process.exit(fel ? 1 : 0);
