/* MJUKA FIGURER OCH HELA HÄSTAR I DE NÄRMASTE BOXARNA — Batch 1.8.

   Med `?realism=1` byggs figurerna i det mjuka formspråket («svept»), och
   de boxar som ligger närmast spelaren visar en HEL stående häst i stället
   för ett löst huvud över dörren. Utan brytaren ska allt vara som förut.

   Provet lyssnar på ritaren i en riktig webbläsare — vilka hela hästar
   och vilka lösa huvuden som faktiskt ritas — och mäter:

   AV  inga hela boxhästar, ett huvud per bebodd box, formspråket «kloss».
   PÅ  högst sex hela hästar, och de står i de boxar som ligger NÄRMAST;
       aldrig både huvud och häst i samma box; övriga boxar har kvar
       huvudet; varje häst står innanför sin egen box, vänd mot gången,
       och är samma häst som boxen hade; formspråket «svept».
       Går spelaren längre in i gången följer de hela hästarna med.

   VILKA boxar som har en häst räknas här med samma villkor som ritaren
   använder — provet kontrollerar att formen byts, inte att beläggningen
   ändras.

   Falsifiering (ska ge RÖTT): --muter-lacka (hela hästar utan brytare),
   --muter-dubbel (huvudet ritas också).

   Kör: python3 tools/build.py && node tools/boxhasttest.mjs */
import { chromium } from "playwright";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
const PORT = +(process.env.PORT || 8799);
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
if (arg.has("--muter-lacka")) { console.log("MUTATION: hela hästar utan brytare");
  byt("const hela=V3DREAL?v3dNarmasteBoxar(S):null;", "const hela=v3dNarmasteBoxar(S);"); }
if (arg.has("--muter-dubbel")) { console.log("MUTATION: huvudet ritas också");
  byt('skugga:true, box:rad2.id+":"+i});\n            continue;', 'skugga:true, box:rad2.id+":"+i});'); }

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
  await page.evaluate(() => { overlay(false); SPAR.pass = 3; startaVandring(); });
  await page.waitForFunction(() => typeof GL !== "undefined" && !!GL.gl, null, { timeout: 20000 });
  /* Lyssna på ritaren: hela hästar (s3RitaHast med fältet `box`) och lösa
     huvuden (GL.rita med huvudnätet). Båda samlas som mängder, så att det
     inte spelar någon roll hur många bildrutor som hinner ritas. */
  await page.evaluate(() => {
    window.__logg = { hast: new Map(), huvud: new Set(), iHast: 0 };
    const gammal = s3RitaHast;
    s3RitaHast = function (o) { if (o && o.box) __logg.hast.set(o.box, { x: o.x, z: o.z, rikt: o.rikt, farg: o.hast && o.hast.farg, gangart: o.gangart });
      __logg.iHast++; try { return gammal.apply(this, arguments); } finally { __logg.iHast--; } };
    const rita = GL.rita;
    /* En hel häst ritar också ett huvud — sitt eget. Bara huvuden som
       ritas UTANFÖR en hel häst är lösa huvuden över en boxdörr. */
    GL.rita = function (nat, m) { if (!__logg.iHast && nat && nat === S3.del.huvud) __logg.huvud.add(m[12].toFixed(2) + ";" + m[14].toFixed(2));
      return rita.apply(this, arguments); };
  });
  return { page, sidfel };
}
/* Ställ spelaren i gång A, `in` meter in från första boxen, och läs vad
   som ritas under minst tre bildrutor därefter. */
async function mat(page, inMeter) {
  const b0 = await page.evaluate(m => { const S = STALLINNE;
    gaTill("stallinne", { x: (S.gangar.A.x0 + S.gangar.A.x1) / 2, y: S.boxStartY + m, rikt: Math.PI / 2 }); return V3D.bild || 0; }, inMeter);
  await page.waitForFunction(b => V3D.plats === "stallinne" && (V3D.bild || 0) >= b + 2, b0, { timeout: 60000, polling: 50 });
  const b1 = await page.evaluate(() => { __logg.hast.clear(); __logg.huvud.clear(); return V3D.bild || 0; });
  await page.waitForFunction(b => (V3D.bild || 0) >= b + 3, b1, { timeout: 60000, polling: 50 });
  return page.evaluate(() => {
    const S = STALLINNE, bebodda = [];
    for (const rad of S.rader) { const boxar = S.boxar[rad.id] || [], fx = boxFrontX(rad);
      for (let i = 0; i < antalFack(rad.id); i++) { const my = boxY(i, rad.id);
        if (my + S.boxB / 2 > S.klubbY) break;
        const h = boxHast(boxar[i]); if (!h) continue;
        bebodda.push({ k: rad.id + ":" + i, x0: rad.x0, x1: rad.x0 + rad.djup, z0: my - S.boxB / 2, z1: my + S.boxB / 2, fx, ut: rad.vetter,
          huvud: (fx + rad.vetter * 0.22).toFixed(2) + ";" + my.toFixed(2), farg: (HORSES[boxar[i]] || h).farg,
          avst: Math.hypot((rad.x0 + rad.djup / 2) - VD.px, my - VD.py) }); } }
    return { bebodda, hast: [...__logg.hast].map(([k, v]) => ({ k, ...v })), huvud: [...__logg.huvud], stil: STIL, px: VD.px, py: VD.py };
  });
}

try {
  console.log("1  AV: som förut");
  {
    const { page, sidfel } = await oppna("");
    const m = await mat(page, 6);
    prova("KONTROLL: stallet har bebodda boxar att mäta på", m.bebodda.length >= 20, `${m.bebodda.length} bebodda boxar`);
    prova("inga hela boxhästar", m.hast.length === 0, `${m.hast.length} st`);
    const vantade = new Set(m.bebodda.map(b => b.huvud));
    prova("ett löst huvud över varje bebodd box, och inga andra", m.huvud.length === vantade.size && m.huvud.every(h => vantade.has(h)),
      `${m.huvud.length} huvuden · ${vantade.size} bebodda boxar`);
    prova("formspråket är «kloss»", m.stil === "kloss", m.stil);
    prova("inga fel på sidan", sidfel.length === 0, sidfel.join(" | ") || "inga");
    await page.close();
  }

  console.log("2  PÅ: hela hästar i de närmaste boxarna");
  {
    const { page, sidfel } = await oppna("?realism=1");
    const m = await mat(page, 6);
    const B = Object.fromEntries(m.bebodda.map(b => [b.k, b]));
    const helaK = new Set(m.hast.map(h => h.k));
    prova("formspråket är «svept»", m.stil === "svept", m.stil);
    prova("sex hela hästar — inte fler", m.hast.length === 6, `${m.hast.length} st: ${[...helaK].join(", ")}`);
    prova("varje hel häst står i en bebodd box", m.hast.every(h => B[h.k]), [...helaK].filter(k => !B[k]).join(", ") || "alla");
    const huvudVantade = new Set(m.bebodda.filter(b => !helaK.has(b.k)).map(b => b.huvud));
    prova("aldrig både huvud och häst i samma box; övriga boxar har kvar huvudet",
      m.huvud.length === huvudVantade.size && m.huvud.every(h => huvudVantade.has(h)),
      `${m.huvud.length} huvuden · ${huvudVantade.size} boxar utan hel häst · ${m.huvud.filter(h => !huvudVantade.has(h)).length} huvuden på fel plats`);
    const langstHel = Math.max(...m.hast.map(h => B[h.k] ? B[h.k].avst : 99));
    const narmastHuvud = Math.min(...m.bebodda.filter(b => !helaK.has(b.k)).map(b => b.avst));
    prova("de hela hästarna står i de NÄRMASTE boxarna", langstHel <= narmastHuvud + 0.6,
      `längst bort med hel häst ${langstHel.toFixed(1)} m · närmast med bara huvud ${narmastHuvud.toFixed(1)} m`);
    /* Innanför boxen: mitten minst 1,2 m från bakre väggen (bakdelen) och
       minst 1,9 m från fronten (hals och huvud) [antagande om hästens
       längd], och minst 0,8 m från skiljeväggarna åt sidorna. */
    const inne = m.hast.map(h => { const b = B[h.k]; if (!b) return null;
      const fram = Math.abs(b.fx - h.x), bak = (b.x1 - b.x0) - fram;
      return { k: h.k, fram, bak, sida: Math.min(h.z - b.z0, b.z1 - h.z), ok: fram >= 1.9 && bak >= 1.2 && Math.min(h.z - b.z0, b.z1 - h.z) >= 0.8 }; });
    prova("varje häst står innanför sin egen box", inne.every(i => i && i.ok),
      inne.map(i => i ? `${i.k}: ${i.fram.toFixed(2)} m till fronten, ${i.bak.toFixed(2)} bakåt` : "?").join(" · "));
    prova("vänd mot gången och stillastående", m.hast.every(h => B[h.k] && h.gangart === "halt" &&
      Math.abs(Math.cos(h.rikt) - B[h.k].ut) < 1e-6), m.hast.map(h => `${h.k}: ${(h.rikt / Math.PI).toFixed(1)}π`).join(" · "));
    prova("och det är boxens egen häst (samma färg som huvudet hade)", m.hast.every(h => B[h.k] && h.farg === B[h.k].farg),
      m.hast.map(h => `${h.k} ${h.farg}`).join(" · "));

    const langre = await mat(page, 30);
    const hela2 = new Set(langre.hast.map(h => h.k));
    const gemensamma = [...hela2].filter(k => helaK.has(k)).length;
    prova("30 m längre in i gången är det ANDRA boxar som har hela hästar", langre.hast.length === 6 && gemensamma === 0,
      `${[...hela2].join(", ")} · gemensamma med förut: ${gemensamma}`);
    prova("inga fel på sidan", sidfel.length === 0, sidfel.join(" | ") || "inga");
    await page.close();
  }
} catch (e) {
  prova("provet kördes till slut", false, String(e && e.message || e).slice(0, 300));
} finally {
  await browser.close(); srv.close();
}
if (fel) { console.log(`${fel} FEL`); process.exit(1); }
console.log("ALLA OK");
