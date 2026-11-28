/* STALLGÅNGENS FOTOMATERIAL — Batch 1.4.

   Med `?realism=1` får fem ytor i stallgången en ruta ur ett riktigt foto
   från UBRF: marksten, boxpanel, galvad ram, takplåt och limträ. Rutorna
   ligger i assets/textures/, bakas in i den enda HTML-filen och har var sin
   rad i KALLOR.tsv. Utan brytaren ska ingenting av det synas eller begäras.

   Provet mäter i en riktig webbläsare:

   AV  ingen av de fem rutorna begärs, ingen yta ritas med en fotoruta,
       och inget lagras under S3.tex.foto.
   PÅ  alla fem begärs och blir «klar»; var och en sitter på sin yta med
       sin storlek i meter (samma tal som i V3D_FOTO); rutans medelfärg är
       kortets färg (fotot bär strukturen, kortet färgen); och från kamera
       STALL-GANG-A har golvet och boxpanelen ungefär SAMMA medelfärg som
       när rutan saknas och reserven (kortets färg rakt av) ritas — men
       betydligt mer struktur. Det visar att fotot syns och att färgen inte
       räknas två gånger.
   KÄLLOR  varje ruta har en källrad som pekar på ett foto som finns i repot
       och som Drive-manifestet säger är utan personer, registreringsskyltar
       och läsbara namn, och samtyckesfilen finns.

   Falsifiering (ska ge RÖTT): --muter-lacka (fotorutorna utan brytare),
   --muter-kalla (en källrad pekar på ett foto med en person).

   Kör: python3 tools/build.py && node tools/fototexturtest.mjs */
import { chromium } from "playwright";
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { lasKameror, stallKamera } from "./qa-webb.mjs";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
const PORT = +(process.env.PORT || 8803);
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
if (arg.has("--muter-lacka")) { console.log("MUTATION: fotorutorna utan brytare");
  byt('const V3DREAL=(typeof REALISM!=="undefined")&&REALISM.pa;', "const V3DREAL=true;"); }

/* Samma sida utan manifest: rutorna saknas, och reserven ritas. */
const MANIFEST = /<script>window\.TEXTUR_DATA=\{.*?\};<\/script>/s;
if (!MANIFEST.test(html)) { console.error("FEL  hittar inte texturmanifestet i dist/ridskolan.html"); process.exit(2); }
const htmlReserv = html.replace(MANIFEST, "<script>window.TEXTUR_DATA={};</script>");

const FILER = { marksten: "stall-marksten.jpg", boxpanel: "stall-boxpanel.jpg", galv: "stall-galv.jpg",
  takplat: "stall-takplat.jpg", limtra: "stall-limtra.jpg" };

/* ── 0. Källorna, utan webbläsare ─────────────────────────────── */
console.log("0  KÄLLOR: varje ruta ur ett foto utan personer");
{
  const kallor = fs.readFileSync(path.join(ROT, "assets/textures/KALLOR.tsv"), "utf8").split("\n").slice(1).filter(r => r.trim())
    .map(r => r.split("\t"));
  const drivefil = fs.readdirSync(path.join(ROT, "references")).filter(f => /^DRIVE-MANIFEST-.*\.tsv$/.test(f)).sort().pop();
  const rader = fs.readFileSync(path.join(ROT, "references", drivefil), "utf8").split("\n").filter(r => r.trim());
  const kol = rader[0].split("\t");
  const drive = rader.slice(1).map(r => Object.fromEntries(r.split("\t").map((v, i) => [kol[i], v])));
  if (arg.has("--muter-kalla")) {
    const med = drive.find(d => d.personer === "ja" && d.slag === "foto") || drive.find(d => d.personer === "ja");
    const k = kallor.find(r => r[0] === FILER.marksten);
    console.log(`MUTATION: ${k[0]} pekar på ${med.drive_sokvag} (personer: ja)`);
    k[1] = (med.repo_sokvag || med.drive_sokvag) + ", " + k[1].split(", ").slice(1).join(", ");
  }
  prova("varje fotomaterial i koden har en källrad", Object.values(FILER).every(f => kallor.some(r => r[0] === f)),
    Object.values(FILER).filter(f => !kallor.some(r => r[0] === f)).join(", ") || "alla fem");
  for (const r of kallor) {
    const foto = r[1].split(",")[0].trim();
    const d = drive.find(x => x.repo_sokvag === foto);
    const ok = r[2] === "ubrf-foto" && fs.existsSync(path.join(ROT, foto)) && d && d.personer === "nej" && d.skyltar === "nej"
      && d.lasbara_namn !== "ja" && fs.existsSync(path.join(ROT, r[3] || "-"));
    prova(`${r[0]}: ur ett foto i repot utan personer, skyltar eller läsbara namn, med samtycket`, ok,
      `${foto} · personer ${d ? d.personer : "?"} · skyltar ${d ? d.skyltar : "?"} · namn ${d ? d.lasbara_namn : "?"} · ${r[3]}`);
  }
}

const sidor = { "/a": html, "/r": htmlReserv };
const srv = http.createServer((req, res) => { res.writeHead(200, { "content-type": "text/html" });
  res.end(sidor[req.url.split("?")[0].replace("/ridskolan.html", "")] || html); });
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const KAMERA = lasKameror().find(k => k.id === "STALL-GANG-A");

async function oppna(sida, fraga) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const sidfel = []; page.on("pageerror", e => sidfel.push(e.message));
  /* Lyssna på GL.bildTextur från början: vilka namn begärs över huvud taget. */
  await page.addInitScript(() => {
    window.__begard = [];
    const vakta = () => {
      if (typeof GL === "undefined" || !GL.bildTextur) return setTimeout(vakta, 5);
      if (GL.__vaktad) return; GL.__vaktad = true;
      const b = GL.bildTextur;
      GL.bildTextur = function (namn) { __begard.push(namn); return b.apply(this, arguments); };
    };
    vakta();
  });
  await page.goto(`http://localhost:${PORT}${sida}/ridskolan.html${fraga}`, { waitUntil: "load" });
  await page.waitForTimeout(800);
  await page.evaluate(() => { overlay(false); SPAR.pass = 3; startaVandring(); });
  await page.waitForFunction(() => typeof GL !== "undefined" && !!GL.gl, null, { timeout: 20000 });
  await page.addStyleTag({ content: "#viewToggle,.hudh,#saga,#ubrfVagvisare,#stegkort,.stegkort,#ugneta,.panel-vanster,#bildmatare{display:none!important}" });
  await stallKamera(page, KAMERA, 600);
  return { page, sidfel };
}
/* Medelfärg och spridning i en rektangel av en skärmdump, räknad i sidan. */
async function ruta(page, x, y, b, h) {
  const png = (await page.screenshot()).toString("base64");
  return page.evaluate(async ({ png, x, y, b, h }) => {
    const img = new Image(); img.src = "data:image/png;base64," + png; await img.decode();
    const c = document.createElement("canvas"); c.width = img.width; c.height = img.height;
    const k = c.getContext("2d"); k.drawImage(img, 0, 0);
    const d = k.getImageData(x, y, b, h).data, n = d.length / 4, m = [0, 0, 0];
    for (let i = 0; i < d.length; i += 4) for (let j = 0; j < 3; j++) m[j] += d[i + j] / n;
    /* Struktur = medelskillnaden mellan grannpunkter. Ett jämnt ljusfall
       (en lampa, avståndet) ger nästan ingenting; en ruta med fogar, ådror
       och korn ger mycket. */
    const L = (xx, yy) => { const i = (yy * b + xx) * 4; return (d[i] + d[i + 1] + d[i + 2]) / 3; };
    let s = 0, t = 0;
    for (let yy = 0; yy < h - 1; yy++) for (let xx = 0; xx < b - 1; xx++) {
      s += Math.abs(L(xx, yy) - L(xx + 1, yy)) + Math.abs(L(xx, yy) - L(xx, yy + 1)); t += 2; }
    return { m: m.map(Math.round), sd: s / t };
  }, { png, x, y, b, h });
}
/* Ytorna i bilden från STALL-GANG-A (1280×720), uppmätta på den byggda sidan. */
const YTOR = { marksten: [480, 668, 110, 44], boxpanel: [280, 630, 100, 70] };
const fmt = r => `${r.m.join("/")} · struktur ${r.sd.toFixed(2)}`;

try {
  console.log("1  AV: som förut");
  {
    const { page, sidfel } = await oppna("/a", "");
    const m = await page.evaluate(F => ({
      begard: __begard.filter(n => Object.values(F).includes(n)),
      lage: Object.keys(GL.texturLage()).filter(n => Object.values(F).includes(n)),
      foto: !!(S3.tex && S3.tex.foto),
      varld: S3.statiskt.filter(s => s.varld).length,
      plats: V3D.plats,
    }), FILER);
    prova("KONTROLL: kameran står i stallet", m.plats === "stallinne", m.plats);
    prova("ingen av de fem rutorna begärs", m.begard.length === 0 && m.lage.length === 0, m.begard.join(", ") || "inga");
    prova("ingen fotoruta lagras och ingen yta ritas med världsläge", !m.foto && m.varld === 0, `foto: ${m.foto} · ${m.varld} ytor`);
    prova("inga fel på sidan", sidfel.length === 0, sidfel.join(" | ") || "inga");
    await page.close();
  }

  console.log("2  PÅ: fem fotomaterial på sina ytor");
  {
    const { page, sidfel } = await oppna("/a", "?realism=1");
    await page.waitForFunction(F => Object.values(F).every(n => GL.texturLage()[n] === "klar"), FILER, { timeout: 30000, polling: 100 })
      .catch(() => {});
    const m = await page.evaluate(async F => {
      const ut = { lage: GL.texturLage(), ytor: {}, medel: {} };
      for (const [namn, fil] of Object.entries(F)) {
        const t = S3.tex.foto && S3.tex.foto[namn];
        const ytor = S3.statiskt.filter(s => t && s.tex === t);
        ut.ytor[namn] = { antal: ytor.length, varld: ytor.map(s => s.varld && s.varld.join("×")), meter: V3D_FOTO[namn].meter.join("×"),
          kort: V3D_FOTO[namn].kort };
        const img = new Image(); img.src = TEXTUR_DATA[fil].uri; await img.decode();
        const c = document.createElement("canvas"); c.width = img.width; c.height = img.height;
        const k = c.getContext("2d"); k.drawImage(img, 0, 0);
        const d = k.getImageData(0, 0, c.width, c.height).data, n = d.length / 4, s = [0, 0, 0];
        for (let i = 0; i < d.length; i += 4) for (let j = 0; j < 3; j++) s[j] += d[i + j] / n;
        ut.medel[namn] = s.map(Math.round);
      }
      return ut;
    }, FILER);
    for (const [namn, fil] of Object.entries(FILER)) {
      const y = m.ytor[namn];
      prova(`${namn}: ${fil} är «klar»`, m.lage[fil] === "klar", m.lage[fil] || "aldrig begärd");
      prova(`${namn}: sitter på sin yta med ${y.meter} m per ruta`, y.antal >= 1 && y.varld.every(v => v === y.meter),
        `${y.antal} ytor · ${y.varld.join(", ") || "inga"}`);
      const kort = [1, 3, 5].map(i => parseInt(y.kort.slice(i, i + 2), 16));
      const avvik = Math.max(...kort.map((v, i) => Math.abs(v - m.medel[namn][i])));
      prova(`${namn}: rutans medelfärg är kortets (${y.kort})`, avvik <= 3, `${m.medel[namn].join("/")} · största avvikelse ${avvik}`);
    }
    const foto = {}; for (const [k, r] of Object.entries(YTOR)) foto[k] = await ruta(page, ...r);
    prova("inga fel på sidan", sidfel.length === 0, sidfel.join(" | ") || "inga");
    await page.close();

    const { page: p2, sidfel: f2 } = await oppna("/r", "?realism=1");
    const reserv = {}; for (const [k, r] of Object.entries(YTOR)) reserv[k] = await ruta(p2, ...r);
    const lage2 = await p2.evaluate(F => Object.values(F).map(n => GL.texturLage()[n]), FILER);
    prova("KONTROLL: utan manifest står reserven kvar för alla fem", lage2.every(l => l === "saknas"), lage2.join(", "));
    for (const k of Object.keys(YTOR)) {
      const d = Math.max(...foto[k].m.map((v, i) => Math.abs(v - reserv[k].m[i])));
      prova(`${k} från STALL-GANG-A: samma medelfärg som reserven (färgen räknas inte två gånger)`, d <= 12,
        `foto ${fmt(foto[k])} · reserv ${fmt(reserv[k])} · största skillnad ${d}`);
      prova(`${k} från STALL-GANG-A: fotot syns — minst dubbelt så mycket struktur som reserven`, foto[k].sd >= 2 * reserv[k].sd + 0.5,
        `${foto[k].sd.toFixed(2)} mot ${reserv[k].sd.toFixed(2)}`);
    }
    prova("inga fel på sidan (utan manifest)", f2.length === 0, f2.join(" | ") || "inga");
    await p2.close();
  }
} catch (e) {
  prova("provet kördes till slut", false, String(e && e.message || e).slice(0, 300));
} finally {
  await browser.close(); srv.close();
}
if (fel) { console.log(`${fel} FEL`); process.exit(1); }
console.log("ALLA OK");
