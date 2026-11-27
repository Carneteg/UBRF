/* INNERLJUSET I STALLGÅNGEN — Batch 1.7.

   Med `?realism=1` räknas en ljuskarta när stallet byggs: hur mycket ljus
   som når varje plats, från pendlarna över gångarna och lanterninen i
   nocken. Skuggaren läser kartan efter var ytan ligger, så att det är
   ljusare under en lampa än i ett hörn — för väggar, hästar och figurer
   lika. Utan brytaren räknas ingen karta och ingen läses.

   Provet mäter i en riktig webbläsare:

   AV  ingen karta finns, och skuggaren läser ingen.
   PÅ  kartan finns i stallet och bara där; två räkningar ger exakt samma
       byte; ljuset beter sig som ljus:
         · ljusare rakt under en pendel än mitt emellan två,
         · gången ljusare än en boxes bakre hörn,
         · avtagande hela vägen från gångens mitt ut mot ytterväggen,
         · ljusare närmare lampan (brösthöjd) än på golvet under den,
         · norr om den genomgående väggen bara den jämna grundnivån;
       de pendlar som LJUSSÄTTER är exakt de som RITAS;
       och skuggaren använder kartan: samma yta ritas ljusare under en
       pendel än i en boxes hörn.

   Falsifiering (ska ge RÖTT): --muter-lacka (kartan räknas utan brytare),
   --muter-lampa (kartan räknas med lamporna förskjutna 2,25 m).

   Kör: python3 tools/build.py && node tools/ljuskartatest.mjs */
import { chromium } from "playwright";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
const PORT = +(process.env.PORT || 8800);
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
if (arg.has("--muter-lacka")) { console.log("MUTATION: kartan räknas utan brytare");
  byt("if(V3DREAL){                                                  // LJUSKARTAN RÄKNAS", "if(true){"); }
if (arg.has("--muter-lampa")) { console.log("MUTATION: kartan räknas med lamporna förskjutna 2,25 m");
  byt("const L=v3dStallLampor(S);                                    // LAMPORNA",
      "const L=v3dStallLampor(S); L.pendlar=L.pendlar.map(p=>({x:p.x,y:p.y,z:p.z+2.25}));"); }

const srv = http.createServer((req, res) => { res.writeHead(200, { "content-type": "text/html" }); res.end(html); });
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });

async function oppna(fraga) {
  const page = await browser.newPage({ viewport: { width: 640, height: 360 } });
  const sidfel = []; page.on("pageerror", e => sidfel.push(e.message));
  await page.goto(`http://localhost:${PORT}/ridskolan.html${fraga}`, { waitUntil: "load" });
  await page.waitForTimeout(800);
  /* Lyssna på bygget FÖRE första stallbygget: var ritas pendelskärmarna?
     (cylinder med radie 0,20 och höjd 0,09 — bara skärmarna har de måtten.) */
  await page.evaluate(() => {
    window.__skarmar = [];
    const cyl = Bygge.prototype.cyl;
    Bygge.prototype.cyl = function (r1, r2, h, farg, mat) {
      if (Math.abs(r1 - 0.20) < 1e-9 && Math.abs(h - 0.09) < 1e-9 && mat) __skarmar.push([mat[12], mat[13], mat[14]]);
      return cyl.apply(this, arguments); };
    overlay(false); SPAR.pass = 3; startaVandring();
  });
  await page.waitForFunction(() => typeof GL !== "undefined" && !!GL.gl, null, { timeout: 20000 });
  return { page, sidfel };
}
async function scen(page, namn) {
  const b0 = await page.evaluate(n => { window.__skarmar.length = 0;
    if (n === "stallinne") { const S = STALLINNE; gaTill("stallinne", { x: (S.gangar.A.x0 + S.gangar.A.x1) / 2, y: S.boxStartY + 6, rikt: Math.PI / 2 }); }
    else gaTill("gard", { x: VD.px, y: VD.py, rikt: 0 });
    return V3D.bild || 0; }, namn);
  await page.waitForFunction(({ b0, n }) => V3D.plats === n && (V3D.bild || 0) >= b0 + 3, { b0, n: namn }, { timeout: 60000, polling: 50 });
  /* Bara provskuggaren har en ljuskarta att läsa. Med standardskuggaren
     finns ingen sådan ingång alls — då är svaret 0 per definition. */
  return page.evaluate(() => { const prov = !!GL._prov && GL.prog === GL._prov.prog;
    return { karta: !!V3D.ljuskarta, prov, pa: prov ? GL.gl.getUniform(GL.prog, GL.u.uLjuskartaPa) : 0, skarmar: __skarmar.slice() }; });
}

try {
  console.log("1  AV: ingen karta");
  {
    const { page, sidfel } = await oppna("");
    const s = await scen(page, "stallinne");
    prova("ingen ljuskarta räknas i stallet", s.karta === false, `karta: ${s.karta}`);
    prova("bilden ritas med standardskuggaren, som inte har någon ljuskarta", s.prov === false && s.pa === 0, `provskuggare: ${s.prov}`);
    prova("KONTROLL: pendelskärmarna ritas som förut", s.skarmar.length >= 10, `${s.skarmar.length} skärmar`);
    prova("inga fel på sidan", sidfel.length === 0, sidfel.join(" | ") || "inga");
    await page.close();
  }

  console.log("2  PÅ: kartan finns i stallet, och bara där");
  const { page, sidfel } = await oppna("?realism=1");
  const s = await scen(page, "stallinne");
  prova("ljuskartan är räknad i stallet", s.karta === true);
  prova("skuggaren läser kartan (uLjuskartaPa = 1)", s.pa === 1, `${s.pa}`);
  const m = await page.evaluate(() => {
    const S = STALLINNE, K = V3D.ljuskarta, L = K.lampor, lika = (a, b) => a.length === b.length && a.every((v, i) => v === b[i]);
    const om = v3dStallLjuskarta(S), om2 = v3dStallLjuskarta(S);
    const v = (x, z, h) => v3dLjusVid(K, x, z, h);
    const A = S.gangar.A, ax = (A.x0 + A.x1) / 2;
    /* En pendel mitt i hallen, i gång A, och grannen norr om den. */
    const iA = L.pendlar.filter(p => Math.abs(p.x - ax) < 1e-6).sort((p, q) => p.z - q.z);
    const p = iA[Math.floor(iA.length / 2)], q = iA[Math.floor(iA.length / 2) + 1];
    const W = S.rader.find(r => r.id === "W");
    const tvars = []; for (let x = ax; x >= W.x0 + 0.4; x -= 0.5) tvars.push(+v(x, p.z, 0).toFixed(4));
    const klubb = []; for (let x = 1; x < S.bredd; x += 2) for (let z = L.klubbGrans + 1.5; z < S.langd - 1; z += 2) klubb.push(+v(x, z, 0).toFixed(4));
    let summa = 0, n = 0; for (const g of [S.gangar.A, S.gangar.B]) for (let z = S.boxStartY; z < S.klubbY; z += 0.5) { summa += v((g.x0 + g.x1) / 2, z, 0); n++; }
    return { samma: lika(om.data, om2.data), sparad: lika(om.data, K.data), ms: K.ms, storlek: `${K.b}×${K.h}`,
      under: v(p.x, p.z, 0), emellan: v(p.x, (p.z + q.z) / 2, 0), brost: v(p.x, p.z, 1.6),
      horn: v(W.x0 + 0.5, p.z, 0), tvars, klubb: [Math.min(...klubb), Math.max(...klubb)], gangMedel: summa / n,
      pendlar: L.pendlar.map(p => [p.x, p.y, p.z]), dz: q.z - p.z };
  });
  prova("två räkningar ger exakt samma byte, och det är dem spelet använder", m.samma && m.sparad, `${m.storlek} texlar, ${m.ms.toFixed(1)} ms`);
  prova("måttstocken: gångens golv har medelnivån 1,0", Math.abs(m.gangMedel - 1) < 0.03, m.gangMedel.toFixed(3));
  prova("ljusare rakt under en pendel än mitt emellan två", m.under > m.emellan + 0.01,
    `under ${m.under.toFixed(3)} · emellan ${m.emellan.toFixed(3)} (pendlarna sitter ${m.dz} m isär)`);
  prova("gången ljusare än boxens bakre hörn", m.under > m.horn + 0.15, `gång ${m.under.toFixed(3)} · hörn ${m.horn.toFixed(3)}`);
  prova("avtagande hela vägen från gångens mitt ut mot ytterväggen", m.tvars.every((x, i) => i === 0 || x <= m.tvars[i - 1] + 0.008),
    m.tvars.map(x => x.toFixed(2)).join(" "));
  prova("ljusare närmare lampan: brösthöjd över golv, under pendeln", m.brost > m.under + 0.05, `1,6 m ${m.brost.toFixed(3)} · golv ${m.under.toFixed(3)}`);
  prova("norr om den genomgående väggen: bara den jämna grundnivån", Math.abs(m.klubb[0] - m.klubb[1]) < 0.02 && Math.abs(m.klubb[0] - 1) < 0.03,
    `${m.klubb[0]} – ${m.klubb[1]}`);
  /* Ritarens matris bär enkel precision, listan dubbel: jämför läge för
     läge med en millimeters tolerans i stället för sifferlikhet. */
  const ordnad = l => l.slice().sort((p, q) => p[2] - q[2] || p[0] - q[0]);
  const rit = ordnad(s.skarmar), lys = ordnad(m.pendlar);
  const storstAvvikelse = rit.length === lys.length ? Math.max(...rit.map((p, i) => Math.max(...p.map((v, k) => Math.abs(v - lys[i][k]))))) : Infinity;
  prova("pendlarna som ljussätter är exakt de som ritas", storstAvvikelse < 0.001,
    `${m.pendlar.length} ljussatta · ${s.skarmar.length} ritade · största avvikelse ${storstAvvikelse.toExponential(1)} m`);

  console.log("3  skuggaren använder kartan");
  {
    /* Samma liggande yta, samma färg, ritad på två platser i stallet med
       stallets eget ljus: under en pendel i gången och i en boxes hörn.
       Bildpunkten under pendeln ska vara ljusare — med ungefär den kvot
       kartan säger (i linjärt ljus). */
    const r = await page.evaluate(() => {
      const gl = GL.gl, S = STALLINNE, K = V3D.ljuskarta, L = K.lampor;
      const A = S.gangar.A, ax = (A.x0 + A.x1) / 2, iA = L.pendlar.filter(p => Math.abs(p.x - ax) < 1e-6).sort((p, q) => p.z - q.z);
      const p = iA[Math.floor(iA.length / 2)], W = S.rader.find(r => r.id === "W");
      const b = new Bygge(); b.lada(0.6, 0.02, 0.6, "#808080", M4.translation(0, 0, 0));
      const nat = GL.nat(b), ljus = Object.assign({}, GL.ljus, { dimStyrka: 0, kant: 0, aoStyrka: 0 });
      const rita = (x, z) => {
        GL.start(CW, CH, DPR, ljus);
        GL.anvandLjuskarta(K.tex, K.x0, K.z0, K.bredd, K.langd);
        GL.kamera([x + 0.01, 2.0, z + 1.2], [x, 0.01, z], 0.6);
        GL.rita(nat, M4.translation(x, 0.01, z), {});
        const px = new Uint8Array(4);
        gl.readPixels(gl.drawingBufferWidth >> 1, gl.drawingBufferHeight >> 1, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, px);
        return px[1];
      };
      return { under: rita(p.x, p.z), horn: rita(W.x0 + 0.5, p.z), kUnder: v3dLjusVid(K, p.x, p.z, 0.01), kHorn: v3dLjusVid(K, W.x0 + 0.5, p.z, 0.01) };
    });
    const lin = v => Math.pow(v / 255, 2.2), kvot = lin(r.under) / lin(r.horn), vantad = r.kUnder / r.kHorn;
    prova("samma yta ritas ljusare under pendeln än i boxens hörn", r.under > r.horn + 8, `ritat ${r.under} mot ${r.horn}`);
    prova("och kvoten är den kartan säger (inom 12 %)", Math.abs(kvot / vantad - 1) < 0.12, `ritad kvot ${kvot.toFixed(2)} · kartans ${vantad.toFixed(2)}`);
  }

  console.log("4  utanför stallet");
  {
    const g = await scen(page, "gard");
    prova("på gården finns ingen karta och skuggaren läser ingen", g.karta === false && g.pa === 0, `karta: ${g.karta} · uLjuskartaPa ${g.pa}`);
    const tillbaka = await scen(page, "stallinne");
    prova("tillbaka i stallet räknas den om och används igen", tillbaka.karta === true && tillbaka.pa === 1);
    prova("inga fel på sidan", sidfel.length === 0, sidfel.join(" | ") || "inga");
  }
  await page.close();
} catch (e) {
  prova("provet kördes till slut", false, String(e && e.message || e).slice(0, 300));
} finally {
  await browser.close(); srv.close();
}
if (fel) { console.log(`${fel} FEL`); process.exit(1); }
console.log("ALLA OK");
