/* BILDTEXTURENS VÄG FRÅN FIL TILL GRAFIKKORT — Batch 1.3.

   Batchen ändrar INGET spelaren ser: assets/textures/ är tom. Provet
   bygger därför en KOPIA av spelet med två testbilder som det skriver
   självt (ingen bildfil ligger i repot), och mäter i en riktig webbläsare:

   1. GL.bildTextur ger en användbar textur DIREKT (reserven), och samma
      texturobjekt får bildens innehåll när den är avkodad.
   2. Bilden hamnar rättvänd: testbildens fyra färgfält läses tillbaka ur
      grafikkortet i rätt hörn och med rätt färg.
   3. Okänt namn och trasig bild: reserven står kvar, inget kastas, och
      den byggda filen frågar ALDRIG nätet efter en textur.
   4. Texturen är inställd som anroparen bad om (upprepning, mipmaps) och
      uppladdningen lämnar inget kvar i grafikkortets inställningar.
   5. Det vanliga bygget har exakt stallgångens fem fotorutor i manifestet
      (Batch 1.4), och utan ?realism=1 begärs ingen av dem.
   6. Utvecklingsversionen (obyggd index.html) läser assets/textures/.

   Avläsningen görs rakt ur texturen (ett rambuffertfäste), inte ur en
   ljussatt och tonmappad bild — det är uppladdningen som provas, och en
   färg som gått genom ljus och efterbehandling går inte att jämföra exakt.

   Falsifiering (ska ge RÖTT): --muter-vand (bilden laddas upp ovänd),
   --muter-reserv (ingen reserv läggs i texturen).

   Kör: node tools/texturtest.mjs      (bygger själv, rör inte dist/) */
import { chromium } from "playwright";
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import zlib from "node:zlib";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
const PORT = +(process.env.PORT || 8797);
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};

/* ── Testbilderna ─────────────────────────────────────────────────── */
const CRC = (() => { const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xEDB88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; }
  return buf => { let c = 0xFFFFFFFF; for (const b of buf) c = t[(c ^ b) & 0xFF] ^ (c >>> 8); return (c ^ 0xFFFFFFFF) >>> 0; }; })();
function png(b, h, pixel) {
  const rad = Buffer.alloc(h * (1 + b * 3));
  for (let y = 0; y < h; y++) for (let x = 0; x < b; x++) rad.set(pixel(x, y), y * (1 + b * 3) + 1 + x * 3);
  const bit = (slag, data) => { const s = Buffer.from(slag, "latin1"), l = Buffer.alloc(4), c = Buffer.alloc(4);
    l.writeUInt32BE(data.length); c.writeUInt32BE(CRC(Buffer.concat([s, data]))); return Buffer.concat([l, s, data, c]); };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(b, 0); ihdr.writeUInt32BE(h, 4); ihdr.set([8, 2, 0, 0, 0], 8);
  return Buffer.concat([Buffer.from([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
    bit("IHDR", ihdr), bit("IDAT", zlib.deflateSync(rad)), bit("IEND", Buffer.alloc(0))]);
}
/* Rött uppe till vänster, grönt uppe till höger, blått nere till vänster,
   vitt nere till höger — fyra olika hörn, så att en spegling syns. */
const FYRFALT = png(64, 64, (x, y) => y < 32 ? (x < 32 ? [255, 0, 0] : [0, 255, 0]) : (x < 32 ? [0, 0, 255] : [255, 255, 255]));
/* Rätt filhuvud (bygget läser måtten) men bilddata som inte går att avkoda. */
const TRASIG = Buffer.concat([FYRFALT.subarray(0, 33), Buffer.from("detta är inte bilddata")]);

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "texturtest-"));
const tex = path.join(tmp, "texturer"); fs.mkdirSync(tex);
fs.writeFileSync(path.join(tex, "prov.png"), FYRFALT);
fs.writeFileSync(path.join(tex, "trasig.png"), TRASIG);
const egen = "\tprovbild skriven av tools/texturtest.mjs\tegen-syntetisk\t\n";
fs.writeFileSync(path.join(tex, "KALLOR.tsv"), "fil\tkalla\trattighet\tsamtycke\nprov.png" + egen + "trasig.png" + egen);
const bygg = (...a) => execFileSync("python3", [path.join(ROT, "tools/build.py"), ...a], { encoding: "utf8" });
bygg("--texturer", tex, "--ut", path.join(tmp, "med.html"));
bygg("--ut", path.join(tmp, "utan.html"));

let med = fs.readFileSync(path.join(tmp, "med.html"), "utf8");
const byt = (fran, till) => {
  if (med.split(fran).length !== 2) { console.error("FEL  mutationen hittar inte sin rad: " + fran); process.exit(2); }
  med = med.replace(fran, till);
};
if (arg.has("--muter-vand")) { console.log("MUTATION: bilden laddas upp ovänd");
  byt("gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);                 // BILDEN RÄTTVÄND", "gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,false);"); }
if (arg.has("--muter-reserv")) { console.log("MUTATION: ingen reserv läggs i texturen");
  byt("t=this.textur(reserv,upprepa);               // RESERVEN", "t=gl.createTexture();"); }

/* ── Servern: de två byggena, och utvecklingsversionen rakt ur repot ── */
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".json": "application/json" };
const fragor = [];
const srv = http.createServer((req, res) => {
  const u = decodeURIComponent(req.url.split("?")[0]);
  fragor.push(u);
  const svar = (kod, typ, d) => { res.writeHead(kod, typ ? { "content-type": typ } : {}); res.end(d); };
  if (u === "/med.html") return svar(200, "text/html", med);
  if (u === "/utan.html") return svar(200, "text/html", fs.readFileSync(path.join(tmp, "utan.html")));
  /* Utvecklingsversionen: allt ur repot, utom texturmappen som är provets. */
  if (u.startsWith("/dev/assets/textures/")) {
    const f = path.join(tex, path.basename(u));
    return fs.existsSync(f) ? svar(200, "image/png", fs.readFileSync(f)) : svar(404);
  }
  if (u.startsWith("/dev/")) {
    const f = path.join(ROT, u.slice(5) || "index.html");
    return fs.existsSync(f) && fs.statSync(f).isFile() ? svar(200, MIME[path.extname(f)] || "application/octet-stream", fs.readFileSync(f)) : svar(404);
  }
  svar(404);
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });

async function oppna(url) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  const sidfel = [];
  page.on("pageerror", e => sidfel.push(e.message));
  await page.goto(`http://localhost:${PORT}${url}`, { waitUntil: "load" });
  await page.waitForTimeout(800);
  await page.evaluate(() => { overlay(false); SPAR.pass = 3; startaVandring(); });
  await page.waitForFunction(() => typeof GL !== "undefined" && !!GL.gl, null, { timeout: 20000 });
  /* Verktyg i sidan: läs en texel rakt ur en textur, och vänta på ett läge. */
  await page.evaluate(() => {
    window.__las = (t, x, y) => { const gl = GL.gl, fb = gl.createFramebuffer();
      gl.bindFramebuffer(gl.FRAMEBUFFER, fb);
      gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, t, 0);
      const ok = gl.checkFramebufferStatus(gl.FRAMEBUFFER) === gl.FRAMEBUFFER_COMPLETE, p = new Uint8Array(4);
      if (ok) gl.readPixels(x, y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, p);
      gl.bindFramebuffer(gl.FRAMEBUFFER, null); gl.deleteFramebuffer(fb);
      return ok ? [p[0], p[1], p[2]] : null; };
    window.__reserv = () => { const c = document.createElement("canvas"); c.width = c.height = 64;
      const k = c.getContext("2d"); k.fillStyle = "rgb(200,0,200)"; k.fillRect(0, 0, 64, 64); return c; };
    window.__vanta = (namn, mal) => new Promise(klar => { const t0 = performance.now();
      const titta = () => { const l = GL.texturLage()[namn];
        if (mal.includes(l) || performance.now() - t0 > 8000) klar(l); else setTimeout(titta, 20); }; titta(); });
  });
  return { page, sidfel };
}
const lika = (a, b, tol = 3) => !!a && a.every((v, i) => Math.abs(v - b[i]) <= tol);
const RESERV = [200, 0, 200];

try {
  /* ══ Bygget MED testbilderna ═════════════════════════════════════ */
  console.log("1  reserven direkt, bilden när den är avkodad");
  const { page, sidfel } = await oppna("/med.html");
  const a = await page.evaluate(async () => {
    const gl = GL.gl, c = __reserv();
    const t = GL.bildTextur("prov.png", c, true);
    const direkt = { lage: GL.texturLage()["prov.png"], mitt: __las(t, 32, 32) };
    const slut = await __vanta("prov.png", ["klar", "fel", "saknas"]);
    gl.bindTexture(gl.TEXTURE_2D, t);
    return { direkt, slut, samma: GL._bild["prov.png"].tex === t, b: GL._bild["prov.png"].b, h: GL._bild["prov.png"].h,
      nv: __las(t, 16, 48), no: __las(t, 48, 48), sv: __las(t, 16, 16), so: __las(t, 48, 16),
      varv: gl.getTexParameter(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S) === gl.REPEAT &&
            gl.getTexParameter(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T) === gl.REPEAT,
      mip: gl.getTexParameter(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER) === gl.LINEAR_MIPMAP_LINEAR,
      vand: gl.getParameter(gl.UNPACK_FLIP_Y_WEBGL),
      rymd: gl.getParameter(gl.UNPACK_COLORSPACE_CONVERSION_WEBGL) === gl.BROWSER_DEFAULT_WEBGL };
  });
  prova("texturen går att använda på en gång och bär då reserven",
    a.direkt.lage === "vantar" && lika(a.direkt.mitt, RESERV), `läge ${a.direkt.lage} · mitten ${JSON.stringify(a.direkt.mitt)}`);
  prova("bilden avkodas och läggs in i SAMMA texturobjekt",
    a.slut === "klar" && a.samma && a.b === 64 && a.h === 64, `läge ${a.slut} · samma objekt ${a.samma} · ${a.b}×${a.h}`);

  console.log("2  rättvänd");
  prova("de fyra färgfälten ligger i rätt hörn (uppe: rött, grönt · nere: blått, vitt)",
    lika(a.nv, [255, 0, 0]) && lika(a.no, [0, 255, 0]) && lika(a.sv, [0, 0, 255]) && lika(a.so, [255, 255, 255]),
    `uppe ${JSON.stringify(a.nv)} ${JSON.stringify(a.no)} · nere ${JSON.stringify(a.sv)} ${JSON.stringify(a.so)}`);

  console.log("3  okänt namn och trasig bild");
  const fore = fragor.length;
  const b = await page.evaluate(async () => {
    const t1 = GL.bildTextur("finns-inte.png", __reserv(), false);
    const t2 = GL.bildTextur("trasig.png", __reserv(), false);
    const l2 = await __vanta("trasig.png", ["klar", "fel", "saknas"]);
    await new Promise(r => setTimeout(r, 300));
    return { l1: GL.texturLage()["finns-inte.png"], p1: __las(t1, 32, 32), l2, p2: __las(t2, 32, 32) };
  });
  prova("okänt namn: läget är «saknas» och reserven står kvar", b.l1 === "saknas" && lika(b.p1, RESERV), `${b.l1} · ${JSON.stringify(b.p1)}`);
  prova("trasig bild: läget är «fel» och reserven står kvar", b.l2 === "fel" && lika(b.p2, RESERV), `${b.l2} · ${JSON.stringify(b.p2)}`);
  const natfragor = fragor.slice(fore).concat(fragor.filter(u => u.includes("textures")));
  prova("den byggda filen frågar aldrig nätet efter en textur", natfragor.length === 0, JSON.stringify(natfragor));

  console.log("4  inställningar");
  prova("texturen upprepas och har mipmaps, som anroparen bad om", a.varv && a.mip, `upprepning ${a.varv} · mipmaps ${a.mip}`);
  prova("uppladdningen lämnar grafikkortets inställningar som de var", a.vand === false && a.rymd, `vändning kvar: ${a.vand} · färgrymd återställd: ${a.rymd}`);
  const t0 = await page.evaluate(() => G.t); await page.waitForTimeout(600);
  const t1 = await page.evaluate(() => G.t);
  prova("spelet fortsätter rita efteråt, utan fel på sidan", t1 > t0 && sidfel.length === 0, `G.t ${t0.toFixed(2)} → ${t1.toFixed(2)} · sidfel: ${sidfel.join(" | ") || "inga"}`);
  await page.close();

  /* ══ Det vanliga bygget ══════════════════════════════════════════ */
  console.log("5  det vanliga bygget");
  {
    const { page, sidfel } = await oppna("/utan.html");
    const u = await page.evaluate(() => ({ namn: Object.keys(window.TEXTUR_DATA || {}).sort().join(","), lage: JSON.stringify(GL.texturLage()) }));
    const fem = fs.readdirSync(path.join(ROT, "assets/textures")).filter(f => /\.(jpe?g|png|webp)$/i.test(f)).sort().join(",");
    prova("manifestet har exakt filerna i assets/textures/, och ingen textur har begärts", u.namn === fem && u.lage === "{}" && sidfel.length === 0,
      `TEXTUR_DATA ${u.namn || "tomt"} · lägen ${u.lage}`);
    await page.close();
  }

  /* ══ Utvecklingsversionen ════════════════════════════════════════ */
  console.log("6  utvecklingsversionen (obyggd)");
  {
    const { page, sidfel } = await oppna("/dev/index.html");
    const d = await page.evaluate(async () => {
      const t = GL.bildTextur("prov.png", __reserv(), true), t2 = GL.bildTextur("finns-inte.png", __reserv(), false);
      const l = await __vanta("prov.png", ["klar", "fel", "saknas"]);
      const l2 = await __vanta("finns-inte.png", ["klar", "fel", "saknas"]);
      return { manifest: typeof window.TEXTUR_DATA, l, nv: __las(t, 16, 48), l2, p2: __las(t2, 32, 32) };
    });
    prova("utan manifest läses filen ur assets/textures/", d.manifest === "undefined" && d.l === "klar" && lika(d.nv, [255, 0, 0]) &&
      fragor.includes("/dev/assets/textures/prov.png"), `manifest: ${d.manifest} · läge ${d.l} · hörn ${JSON.stringify(d.nv)}`);
    prova("och en fil som inte finns ger «saknas» med reserven kvar", d.l2 === "saknas" && lika(d.p2, RESERV) && sidfel.length === 0,
      `${d.l2} · ${JSON.stringify(d.p2)} · sidfel: ${sidfel.join(" | ") || "inga"}`);
    await page.close();
  }
} catch (e) {
  prova("provet kördes till slut", false, String(e && e.message || e).slice(0, 300));
} finally {
  await browser.close(); srv.close();
  fs.rmSync(tmp, { recursive: true, force: true });
}
if (fel) { console.log(`${fel} FEL`); process.exit(1); }
console.log("ALLA OK");
