/* LINJÄR FÄRG OCH PROVLJUSET — Batch 1.5.

   Med `?realism=1` räknas belysningen i linjärt ljus och scenen får ett
   neutralt, omättat provljus. Utan brytaren ska INGENTING ha ändrats.
   Provet mäter:

   1. De fyra gamla förinställningarna (dag, mulet, regn, ridhus) är byte
      för byte desamma som när batchen skrevs — ett fryst avtryck.
   2. Brytaren av: varje scen får en av de fyra gamla, och bilden ritas
      med STANDARDSKUGGAREN — vars källtext är ordagrant den som fanns
      före batchen (fryst avtryck). Provet kostar alltså ingenting när
      det är av.
   3. Brytaren på: stallet, ridhuset och gården får var sin
      provförinställning, och bilden ritas med provskuggaren.
   4. RÄKNINGEN: en yta med känd färg under känt ljus, halvvägs in i en
      vit dimma, ritas genom motorn och läses tillbaka. Värdet jämförs med
      det handräknade — i båda lägena. De två lägena ger olika svar
      (dimman blandas olika), så provet skiljer dem åt.

   Falsifiering (ska ge RÖTT): --muter-lacka (provljuset väljs utan
   brytare), --muter-kodning (resultatet kodas inte tillbaka).

   Kör: python3 tools/build.py && node tools/linjartest.mjs */
import { chromium } from "playwright";
import crypto from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
const PORT = +(process.env.PORT || 8798);
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};

/* ── 1. De gamla förinställningarna är orörda ───────────────────── */
console.log("1  de fyra gamla förinställningarna");
{
  /* Avtrycken togs på commiten FÖRE Batch 1.5 (2ac2942) och är identiska
     efter den. Ändras ett tal i en gammal förinställning blir provet rött
     — då har standardutseendet ändrats, och det ska vara ett eget beslut. */
  const FRYST = { dag: "e96231e07ab3719d", mulet: "74db28a7aa4eaaee", regn: "9d7f12b1e94d023a", ridhus: "a609fd6597f1e4d2" };
  const ctx = {}; vm.createContext(ctx);
  vm.runInContext(fs.readFileSync(path.join(ROT, "src/ljus.js"), "utf8") + ";this.LJUS=LJUS;this.ljusFor=ljusFor;", ctx);
  const nu = Object.fromEntries(Object.keys(FRYST).map(n =>
    [n, crypto.createHash("sha256").update(JSON.stringify(ctx.LJUS[n])).digest("hex").slice(0, 16)]));
  prova("dag, mulet, regn och ridhus är byte för byte oförändrade", JSON.stringify(nu) === JSON.stringify(FRYST), JSON.stringify(nu));
  prova("ingen av dem räknar linjärt", Object.keys(FRYST).every(n => ctx.LJUS[n].linjar === undefined));
  prova("utan brytare (ingen REALISM alls) väljer ljusFor som förut",
    ctx.ljusFor("ridhus", "sol") === ctx.LJUS.ridhus && ctx.ljusFor("ute", "sol") === ctx.LJUS.dag &&
    ctx.ljusFor("ute", "mulet") === ctx.LJUS.mulet && ctx.ljusFor("ute", "regn") === ctx.LJUS.regn);
  const prov = ["realUte", "realStall", "realInne"];
  prova("de tre provförinställningarna räknar linjärt, utan höjd mättnad eller exponering",
    prov.every(n => ctx.LJUS[n] && ctx.LJUS[n].linjar === true && ctx.LJUS[n].mattnad === 1 && ctx.LJUS[n].exponering === 1),
    prov.map(n => `${n}: mättnad ${ctx.LJUS[n] && ctx.LJUS[n].mattnad}`).join(" · "));
  const gra = h => { const n = parseInt(h.slice(1), 16), r = n >> 16, g = (n >> 8) & 255, b = n & 255; return Math.max(r, g, b) - Math.min(r, g, b); };
  prova("och deras återsken underifrån är grått, inte grönt (kanalspridning ≤ 14)",
    prov.every(n => gra(ctx.LJUS[n].mark) <= 14) && gra(ctx.LJUS.dag.mark) > 40,
    prov.map(n => `${n} ${ctx.LJUS[n].mark}`).join(" · ") + ` · dag ${ctx.LJUS.dag.mark}`);
}

/* ── Webbläsaren ─────────────────────────────────────────────────── */
let html = fs.readFileSync(path.join(ROT, "dist/ridskolan.html"), "utf8");
const byt = (fran, till) => {
  if (html.split(fran).length !== 2) { console.error("FEL  mutationen hittar inte sin rad: " + fran); process.exit(2); }
  html = html.replace(fran, till);
};
if (arg.has("--muter-lacka")) { console.log("MUTATION: provljuset väljs utan brytare");
  byt('const REALLJUS=(typeof REALISM!=="undefined")&&REALISM.pa;', "const REALLJUS=true;"); }
if (arg.has("--muter-kodning")) { console.log("MUTATION: resultatet kodas inte tillbaka");
  byt('"farg = pow(max(farg, vec3(0.0)), vec3(1.0/2.2));   // ÅTERKODNING\\n        gl_FragColor = vec4(farg, uAlfa);"',
      '"gl_FragColor = vec4(farg, uAlfa);"'); }

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
  await page.waitForFunction(() => typeof GL !== "undefined" && !!GL.gl && !!GL.ljus, null, { timeout: 20000 });
  return { page, sidfel };
}
/* Gå till en scen, vänta två bildrutor, och läs vilken förinställning
   som gäller och vad skuggaren fått för uLinjar. */
async function scen(page, namn) {
  const b0 = await page.evaluate(n => { const m = { stallinne: () => { const d = STALLINNE.dorrar[0]; gaTill("stallinne", { x: d.pos[0], y: d.pos[1], rikt: 0 }); },
      ridhusinne: () => { const R = RIDHUSINNE; gaTill("ridhusinne", { x: (R.bana.x0 + R.bana.x1) / 2, y: (R.bana.y0 + R.bana.y1) / 2, rikt: 0 }); },
      gard: () => gaTill("gard", { x: VD.px, y: VD.py, rikt: 0 }) }; m[n](); return V3D.bild || 0; }, namn);
  await page.waitForFunction(({ b0, n }) => V3D.plats === n && (V3D.bild || 0) >= b0 + 2, { b0, n: namn }, { timeout: 60000, polling: 50 });
  return page.evaluate(() => { const gl = GL.gl;
    const fs = gl.getAttachedShaders(GL._std.prog).find(sh => gl.getShaderParameter(sh, gl.SHADER_TYPE) === gl.FRAGMENT_SHADER);
    return { ljus: Object.keys(LJUS).find(k => LJUS[k] === GL.ljus) || "(okänd)",
      skuggare: GL.prog === GL._std.prog ? "standard" : (GL._prov && GL.prog === GL._prov.prog ? "prov" : "(okänd)"),
      kalla: gl.getShaderSource(fs), vader: (G.vader && G.vader.typ) || "sol" }; });
}

try {
  console.log("2  brytaren av");
  const av = await oppna("");
  {
    const s = await scen(av.page, "stallinne"), r = await scen(av.page, "ridhusinne"), g = await scen(av.page, "gard");
    const uteGammal = ["dag", "mulet", "regn"].includes(g.ljus);
    prova("stallet och ridhuset får den gamla förinställningen «ridhus»", s.ljus === "ridhus" && r.ljus === "ridhus", `stall ${s.ljus} · ridhus ${r.ljus}`);
    prova("gården får en av de gamla väderförinställningarna", uteGammal, `${g.ljus} (väder: ${g.vader})`);
    prova("alla tre ritas med standardskuggaren", s.skuggare === "standard" && r.skuggare === "standard" && g.skuggare === "standard",
      `${s.skuggare} · ${r.skuggare} · ${g.skuggare}`);
    /* Avtrycket togs på commiten före Batch 1.5 (2ac2942): källtexten som
       standardskuggaren kompileras ur är ordagrant den gamla. */
    const avtryck = crypto.createHash("sha256").update(s.kalla).digest("hex").slice(0, 16);
    prova("standardskuggarens källtext är ordagrant den före Batch 1.5", avtryck === "c720b40d803d602b", avtryck);
  }

  console.log("3  brytaren på");
  {
    const pa = await oppna("?realism=1");
    const s = await scen(pa.page, "stallinne"), r = await scen(pa.page, "ridhusinne"), g = await scen(pa.page, "gard");
    prova("stallet får «realStall», ridhuset «realInne», gården «realUte»",
      s.ljus === "realStall" && r.ljus === "realInne" && g.ljus === "realUte", `${s.ljus} · ${r.ljus} · ${g.ljus}`);
    prova("alla tre ritas med provskuggaren", s.skuggare === "prov" && r.skuggare === "prov" && g.skuggare === "prov",
      `${s.skuggare} · ${r.skuggare} · ${g.skuggare}`);
    prova("inga fel på sidan med brytaren på", pa.sidfel.length === 0, pa.sidfel.join(" | ") || "inga");
    await pa.page.close();
  }

  console.log("4  räkningen");
  {
    /* En lodrät yta mot kameran, 5 m bort. Solen står rakt bakom kameran,
       himmel och mark har samma grå ton, ingen kontaktskugga och inget
       kantljus. Dimman är VIT och når halvvägs vid ytan. Då gäller:
         ljus = ambient·himmel + solStyrka·(1 + 0,72) + 0,16      (sol, halvskugga, kamerafyllnad)
         färg = bas · ljus, sedan hälften mot vitt.
       I linjärt läge avkodas bas och himmel först (^2,2) och resultatet
       kodas tillbaka (^1/2,2); solen är vit och ändras inte. */
    const BAS = [128, 64, 191], AMB = 0.4, SOL = 0.3, HIMMEL = 128;
    const solterm = SOL * (1 + 0.72) + 0.16;
    const vantat = lin => BAS.map(v => {
      const b = v / 255, h = HIMMEL / 255;
      if (!lin) return Math.round(255 * (0.5 * Math.min(1, b * (AMB * h + solterm)) + 0.5));
      const f = Math.pow(b, 2.2) * (AMB * Math.pow(h, 2.2) + solterm);
      return Math.round(255 * Math.pow(0.5 * f + 0.5, 1 / 2.2));
    });
    const matt = lin => av.page.evaluate(({ lin, AMB, SOL }) => {
      const gl = GL.gl;
      const L = { linjar: lin, sol: [0, 0, 1], solFarg: "#FFFFFF", solStyrka: SOL, halvskugga: 0,
        himmel: "#808080", mark: "#808080", ambient: AMB, dimFarg: "#FFFFFF", dimNara: 0, dimFjarr: 9.9, dimStyrka: 1,
        aoHojd: 1, aoStyrka: 0, kantFarg: "#FFFFFF", kant: 0 };
      const b = new Bygge(); b.lada(4, 4, 0.1, "#8040BF", M4.translation(0, 50, 0));
      const nat = GL.nat(b);
      GL.start(CW, CH, DPR, L);
      GL.kamera([0, 50, 5], [0, 50, 0], 1.0);
      GL.rita(nat, M4.identity ? M4.identity() : M4.translation(0, 0, 0), {});
      const p = new Uint8Array(4);
      gl.readPixels(gl.drawingBufferWidth >> 1, gl.drawingBufferHeight >> 1, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, p);
      return [p[0], p[1], p[2]];
    }, { lin, AMB, SOL });
    const nara = (a, b) => a.every((v, i) => Math.abs(v - b[i]) <= 3);
    const gammal = await matt(false), linjar = await matt(true), vg = vantat(false), vl = vantat(true);
    prova("KONTROLL: de två lägena ska ge tydligt olika svar för den här ytan", Math.abs(vg[1] - vl[1]) >= 20, `handräknat: som förut ${vg} · linjärt ${vl}`);
    prova("som förut: det ritade värdet är det handräknade", nara(gammal, vg), `ritat ${gammal} · väntat ${vg}`);
    prova("linjärt: det ritade värdet är det handräknade", nara(linjar, vl), `ritat ${linjar} · väntat ${vl}`);
    await av.page.waitForTimeout(300);
    prova("spelet ritar vidare efteråt, utan fel på sidan", av.sidfel.length === 0, av.sidfel.join(" | ") || "inga");
  }
  await av.page.close();
} catch (e) {
  prova("provet kördes till slut", false, String(e && e.message || e).slice(0, 300));
} finally {
  await browser.close(); srv.close();
}
if (fel) { console.log(`${fel} FEL`); process.exit(1); }
console.log("ALLA OK");
