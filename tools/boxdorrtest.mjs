/* STALLETS SKJUTDÖRRAR BAKOM STRÖMBRYTAREN (webb).

   Kortet (references/buildings/stall/INTERIOR-MATRIS.md § 2, Tobias besked
   2026-11-28 och stall-inne-06/IMG_0152) säger: varje boxfront har en
   SKJUTDÖRR som hänger i överliggaren. Öppningen sitter till VÄNSTER sett
   från gången, och dörren skjuts åt höger framför den fasta delen.

   Med `?realism=1` bygger v3dStall fronten så, med alla dörrar stängda.
   Utan brytaren byggs fronten som förut.

   Provet lyssnar på varje Bygge.lada/Bygge.cyl medan stallet byggs (samma
   metod som tools/stalltaktest.mjs) och mäter:

   1. AV: inga delar utanför frontens plan, en hel panel per box, och
      reglarna går över hela boxen — som förut.
   2. PÅ, per box i båda raderna:
      · en dörrpanel med den delade datans bredd (boxfront.dorr.bredd),
        utanför frontens plan, mot gången;
      · den fasta delens reglar slutar vid dörren och överlappar den inte;
      · dörren och den fasta delen fyller tillsammans fronten.
   3. VÄNSTER, mätt i bild: kameran ställs i gången rakt framför en box i
      varje rad, och dörrens och boxens mitt projiceras genom samma
      matriser som ritar bilden (GL.proj, GL.vy). Dörren ska ligga till
      vänster på skärmen.

   Falsifiering (ska ge RÖTT): --muter-sida (dörren till höger),
   --muter-lacka (dörrar utan brytare).

   Kör: python3 tools/build.py && node tools/boxdorrtest.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
const PORT = +(process.env.PORT || 8807);
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};
let html = fs.readFileSync(path.join(ROT, "dist/ridskolan.html"), "utf8");
const byt = (fran, till) => {
  if (html.split(fran).length !== 2) { console.error("FEL  mutationen hittar inte sin rad: " + fran); process.exit(2); }
  html = html.replace(fran, till);
};
if (arg.has("--muter-sida")) { console.log("MUTATION: dörren till höger");
  byt("const ut=vetter>0?1:-1, V=-ut;", "const ut=vetter>0?1:-1, V=ut;"); }
if (arg.has("--muter-lacka")) { console.log("MUTATION: dörrar utan brytare");
  byt("if(V3DREAL){ v3dBoxfrontMedDorr(", "if(true){ v3dBoxfrontMedDorr("); }

const srv = http.createServer((q, s) => { s.writeHead(200, { "content-type": "text/html" }); s.end(html); });
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });

/* Bygg stallet, logga delarna, och mät dörrens sida på skärmen. */
async function bygg(fraga) {
  const page = await browser.newPage({ viewport: { width: 960, height: 540 } });
  const sidfel = []; page.on("pageerror", e => sidfel.push(e.message));
  await page.goto(`http://localhost:${PORT}/ridskolan.html${fraga}`, { waitUntil: "load" });
  const ut = await page.evaluate(() => new Promise(klar => {
    const logg = [], r = v => Math.round(v * 1000) / 1000;
    const lada0 = Bygge.prototype.lada, cyl0 = Bygge.prototype.cyl;
    Bygge.prototype.lada = function (w, h, d, farg, mat) {
      logg.push(["lada", r(w), r(h), r(d), mat ? [r(mat[12]), r(mat[13]), r(mat[14])] : null]);
      return lada0.apply(this, arguments);
    };
    Bygge.prototype.cyl = function (r1, r2, h, farg, mat) {
      logg.push(["cyl", r(r1), r(r2), r(h), mat ? [r(mat[12]), r(mat[13]), r(mat[14])] : null]);
      return cyl0.apply(this, arguments);
    };
    overlay(false); SPAR.pass = 3; startaVandring();
    let n = 0, start = -1, stilla = 0, forra = -1;
    (function ruta() {
      n++;
      if (n === 8) { start = logg.length; const d = STALLINNE.dorrar[0]; gaTill("stallinne", { x: d.pos[0], y: d.pos[1], rikt: 0 }); }
      if (n > 8) { stilla = logg.length === forra ? stilla + 1 : 0; forra = logg.length; }
      if ((n > 8 && stilla >= 6 && logg.length > start) || n > 400) {
        const S = STALLINNE, BF = IDENTITET.stall.boxfront, boxar = [];
        for (const rad of S.rader) { const fx = boxFrontX(rad), ut = rad.vetter > 0 ? 1 : -1;
          for (let i = 0; i < antalFack(rad.id); i++) { const my = boxY(i, rad.id);
            if (my + S.boxB / 2 > S.klubbY) break;
            boxar.push({ rad: rad.id, i, fx, ut, my, y0: my - S.boxB / 2, y1: my + S.boxB / 2 }); } }
        return klar({ logg: logg.slice(Math.max(start, 0)), realism: REALISM.pa, tog_slut: n > 400, boxar,
          BF: { heldelH: BF.heldelH, ramZ: BF.ramZ, toppregelZ: BF.toppregelZ, reglar: BF.reglar, dorr: BF.dorr && BF.dorr.bredd }, boxB: S.boxB });
      }
      requestAnimationFrame(ruta);
    })();
  }));
  ut.sidfel = sidfel;
  ut.page = page;
  return ut;
}
/* Delar i en box front: inom 0,3 m från frontlinjen, mellan stolparna. */
function frontdelar(B, b) {
  return B.logg.filter(x => x[4] && Math.abs(x[4][0] - b.fx) < 0.3 && x[4][1] < B.BF.toppregelZ - 0.05
    && x[4][2] > b.y0 - 0.6 && x[4][2] < b.y1 + 0.05);
}
const nara = (a, c, t = 0.011) => Math.abs(a - c) <= t;

try {
  console.log("1  AV: fronten som förut");
  const av = await bygg("");
  {
    prova("KONTROLL: stallet byggdes, brytaren av", !av.tog_slut && av.realism === false && av.boxar.length >= 20, `${av.boxar.length} boxar`);
    const utanfor = av.boxar.filter(b => av.logg.some(x => x[4] && nara(x[4][0], b.fx + b.ut * 0.06, 0.005)
      && x[4][2] > b.y0 && x[4][2] < b.y1 && x[4][1] < av.BF.toppregelZ));
    prova("inga delar utanför frontens plan (ingen dörr)", utanfor.length === 0, `${utanfor.length} boxar`);
    const hel = av.boxar.filter(b => av.logg.some(x => x[0] === "lada" && nara(x[4][0], b.fx) && nara(x[4][2], b.my)
      && nara(x[2], av.BF.heldelH) && nara(x[3], av.boxB - 0.04)));
    prova("en hel panel per box", hel.length === av.boxar.length, `${hel.length} av ${av.boxar.length}`);
    prova("inga fel på sidan", av.sidfel.length === 0, av.sidfel.join(" | ") || "inga");
    await av.page.close();
  }

  console.log("2  PÅ: en stängd skjutdörr i varje front");
  const pa = await bygg("?realism=1");
  {
    prova("KONTROLL: stallet byggdes, brytaren på", !pa.tog_slut && pa.realism === true && pa.boxar.length >= 20, `${pa.boxar.length} boxar`);
    const D = pa.BF.dorr;
    prova("KONTROLL: den delade datan har en dörrbredd", D > 0.5 && D < 2, `${D} m`);
    const res = pa.boxar.map(b => {
      const L = frontdelar(pa, b);
      const dorr = L.filter(x => x[0] === "lada" && nara(x[4][0], b.fx + b.ut * 0.06, 0.005) && nara(x[2], pa.BF.heldelH));
      const fast = L.filter(x => x[0] === "lada" && nara(x[4][0], b.fx) && nara(x[2], pa.BF.heldelH));
      const reglar = L.filter(x => x[0] === "cyl" && x[4][1] > pa.BF.ramZ && x[1] < 0.03);
      const d = dorr[0], f = fast[0];
      const dLo = d ? d[4][2] - d[3] / 2 : NaN, dHi = d ? d[4][2] + d[3] / 2 : NaN;
      const fLo = f ? f[4][2] - f[3] / 2 : NaN, fHi = f ? f[4][2] + f[3] / 2 : NaN;
      /* En regel börjar i f0 och går längs +y med längden h. */
      const regelOverlapp = reglar.some(x => { const a = x[4][2], c = x[4][2] + x[3]; return Math.min(c, dHi) - Math.max(a, dLo) > 0.02; });
      const fyller = d && f && nara(Math.min(dLo, fLo), b.y0 + 0.07, 0.02) && nara(Math.max(dHi, fHi), b.y1 - 0.07, 0.02)
        && Math.abs(Math.max(dLo, fLo) - Math.min(dHi, fHi)) < 0.02;
      return { k: b.rad + ":" + b.i, en: dorr.length === 1 && fast.length === 1, bredd: d ? d[3] : 0, regelOverlapp, fyller, nReglar: reglar.length };
    });
    const ej = res.filter(r => !r.en);
    prova("varje box har exakt en dörrpanel utanför frontens plan och en fast panel", ej.length === 0,
      ej.length ? ej.slice(0, 4).map(r => r.k).join(", ") : `${res.length} boxar`);
    prova("dörrens bredd är den delade datans", res.every(r => nara(r.bredd, D)), [...new Set(res.map(r => r.bredd))].join(", ") + " m");
    prova("den fasta delens reglar slutar vid dörren", res.every(r => !r.regelOverlapp && r.nReglar === pa.BF.reglar),
      res.filter(r => r.regelOverlapp || r.nReglar !== pa.BF.reglar).slice(0, 4).map(r => `${r.k} (${r.nReglar})`).join(", ") || "alla");
    prova("dörren och den fasta delen fyller fronten mellan stolparna", res.every(r => r.fyller),
      res.filter(r => !r.fyller).slice(0, 4).map(r => r.k).join(", ") || "alla");

    console.log("3  VÄNSTER sett från gången, mätt genom kamerans matriser");
    const rader = [...new Set(pa.boxar.map(b => b.rad))];
    for (const radId of rader) {
      const b = pa.boxar.filter(x => x.rad === radId)[Math.min(6, pa.boxar.filter(x => x.rad === radId).length - 1)];
      const d = frontdelar(pa, b).find(x => x[0] === "lada" && nara(x[4][0], b.fx + b.ut * 0.06, 0.005) && nara(x[2], pa.BF.heldelH));
      const m = await pa.page.evaluate(async ({ b, dy }) => {
        V3D.fast = { x: b.fx + b.ut * 2.2, y: 1.55, z: b.my, tx: b.fx, ty: 1.25, tz: b.my };
        const b0 = V3D.bild || 0;
        await new Promise(r => { (function v() { (V3D.bild || 0) >= b0 + 3 ? r() : requestAnimationFrame(v); })(); });
        const P = (x, y, z) => { const v = [x, y, z, 1], m1 = GL.vy, m2 = GL.proj, t = [0, 0, 0, 0], c = [0, 0, 0, 0];
          for (let i = 0; i < 4; i++) for (let k = 0; k < 4; k++) t[i] += m1[k * 4 + i] * v[k];
          for (let i = 0; i < 4; i++) for (let k = 0; k < 4; k++) c[i] += m2[k * 4 + i] * t[k];
          return c[0] / c[3]; };
        return { dorr: P(b.fx, 0.7, dy), box: P(b.fx, 0.7, b.my) };
      }, { b, dy: d ? d[4][2] : b.my });
      prova(`rad ${radId}: dörren ligger till vänster på skärmen`, !!d && m.dorr < m.box - 0.05,
        `dörrens mitt x ${m.dorr.toFixed(2)} · boxens mitt x ${m.box.toFixed(2)} (NDC)`);
    }
    prova("inga fel på sidan", pa.sidfel.length === 0, pa.sidfel.join(" | ") || "inga");
    await pa.page.close();
  }
} catch (e) {
  prova("provet kördes till slut", false, String(e && e.message || e).slice(0, 300));
} finally {
  await browser.close(); srv.close();
}
if (fel) { console.log(`${fel} FEL`); process.exit(1); }
console.log("ALLA OK");
