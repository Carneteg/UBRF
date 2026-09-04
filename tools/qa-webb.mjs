/* Delad QA-harness för webben (issue #78, Visual Fidelity Gate).

   Serverar dist/ridskolan.html, öppnar den i headless Chromium (SwiftShader),
   startar vandringen och ställer reviewkameror ur qa/visual-gate/kameror.json.
   Kameralägen är UTTRYCK i husets data (S = STALLINNE, R = RIDHUSINNE,
   SA = SPELABSTRAKTIONER) som räknas ut i sidan — samma tal som spelet kör.

   Används av tools/screenshot-pack.mjs och tools/siktgrind.mjs. Bygg först:
       python3 tools/build.py */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";

export const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };

export function lasKameror() {
  const k = JSON.parse(fs.readFileSync(path.join(ROT, "qa", "visual-gate", "kameror.json"), "utf8"));
  const TILLATNA = new Set(["EJ_GRANSKAD", "MISMATCH", "CHATGPT_VISUAL_PASS"]);
  for (const c of k.kameror) {
    const st = c.granskning && c.granskning.status;
    if (!TILLATNA.has(st)) throw new Error(`${c.id}: granskning.status "${st}" är inte tillåten (EJ_GRANSKAD | MISMATCH | CHATGPT_VISUAL_PASS). Automation får aldrig sätta VISUALLY_ACCEPTED.`);
  }
  return k.kameror;
}

/* Exakt vilken kod som renderas: head-SHA, och om arbetsträdet är smutsigt.
   En bild utan SHA är inte evidens för någon PR. */
export function gitHead() {
  const sha = execSync("git rev-parse HEAD", { cwd: ROT }).toString().trim();
  const smutsigt = execSync("git status --porcelain --untracked-files=no", { cwd: ROT }).toString().trim().length > 0;
  return { sha, smutsigt };
}

export async function oppnaWebb({ port = 8792, siktprov = false, bredd = 1280, hojd = 720 } = {}) {
  if (!fs.existsSync(path.join(DIST, "ridskolan.html"))) throw new Error("dist/ridskolan.html saknas — kör python3 tools/build.py");
  const srv = http.createServer((req, res) => {
    const p = path.join(DIST, decodeURIComponent(req.url.split("?")[0] === "/" ? "/index.html" : req.url.split("?")[0]));
    if (!fs.existsSync(p)) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" });
    res.end(fs.readFileSync(p));
  }).listen(port);
  const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
  const browser = await chromium.launch({
    executablePath: fs.existsSync(exe) ? exe : undefined,
    args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"],
  });
  const page = await browser.newPage({ viewport: { width: bredd, height: hojd } });
  const fel = [];
  page.on("pageerror", e => fel.push("pageerror: " + e.message));
  page.on("console", m => { const t = m.text(); if (/misslyckades|is not defined|TypeError|ReferenceError/i.test(t)) fel.push(`${m.type()}: ${t.slice(0, 200)}`); });
  if (siktprov) await page.addInitScript(() => { window.SIKTPROV = true; });
  await page.goto(`http://localhost:${port}/ridskolan.html`, { waitUntil: "load" });
  await page.waitForTimeout(1500);
  await page.evaluate(() => { try { startaVandring(); } catch (e) { console.log("startaVandring misslyckades: " + e.message); } });
  await page.waitForTimeout(800);
  return {
    page, browser, fel,
    async stang() { await browser.close(); srv.close(); },
  };
}

/* Räknar ut ett läge ur uttrycken och teleporterar dit; kameran snappar
   bakom figuren i blickriktningen (kameraNollstall), som vid ett scenbyte.

   Väntar sedan på att scenen är den begärda OCH att minst två bildrutor
   ritats efter teleporten (V3D.bild) — inte en fast tid. En fast väntan
   höll lokalt men inte på CI-runnern, där kameran fortfarande stod kvar
   vid förra kameran när provet togs (run 33841003442). */
export async function stallKamera(page, kamera, vantaMs = 300) {
  const lage = await page.evaluate(({ scen, lage, kam, mal }) => {
    const S = STALLINNE, R = RIDHUSINNE, SA = SPELABSTRAKTIONER, A = ANL;
    const f = e => (e === undefined || e === null) ? 0 : (typeof e === "number" ? e : Function("S", "R", "SA", "A", "Math", `return (${e})`)(S, R, SA, A, Math));
    const p = { x: f(lage.x), y: f(lage.y), z: f(lage.z), rikt: f(lage.rikt) };
    V3D.fast = null;
    gaTill(scen, { x: p.x, y: p.y, rikt: p.rikt, z: p.z });
    /* Explicit kamera (`kamera` + `mal` i kameror.json): spelets följkamera
       hinner inte stå i ögonhöjd i trånga lägen (ett brott i en boxrad),
       så reviewkameran ställs själv — deterministiskt ur samma data. */
    if (kam && mal) V3D.fast = { x: f(kam.x), y: f(kam.h), z: f(kam.y), tx: f(mal.x), ty: f(mal.h), tz: f(mal.y) };
    p.bild0 = V3D.bild || 0;
    return p;
  }, { scen: kamera.scen, lage: kamera.lage, kam: kamera.kamera || null, mal: kamera.mal || null });
  await page.waitForFunction(({ b0, scen }) => V3D.plats === scen && (V3D.bild || 0) >= b0 + 2 && V3D.kam.satt === true,
    { b0: lage.bild0, scen: kamera.scen }, { timeout: 60000, polling: 50 });
  await page.waitForTimeout(vantaMs);
  return lage;
}

export async function lasLage(page) {
  return page.evaluate(() => ({
    kamera: [V3D.kam.x, V3D.kam.y, V3D.kam.z].map(n => +n.toFixed(2)),
    spelare: [VD.px, VD.py, VD.pz || 0].map(n => +n.toFixed(2)),
    tonade: V3D.tonade,
    scen: G.scen,
  }));
}
