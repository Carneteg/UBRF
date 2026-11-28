/* KAMERAN EFTER EN FLYTT — Kimi Q4, P3 § 7. Regression av reproduktionen.

   Reproducerat 2026-09-30 på HEAD 36d832e med tools/_q4repro.mjs (numera
   ersatt av det här provet):
     start               vy 3d men växlaren markerade «Bana» (2d)
     skriv «Vera»        vy 2d — V i namnfältet bytte vy bakom rutan (H1)
     till fots → ritt    vy 2d i sadeln — kartan följde med in i ritten (H2)
   H3 (gå-kamerans lutning inomhus, src/varld3d.js) reproducerades inte i
   den här kedjan och rörs inte i P3 (annan skrivares fil).

   Kravet: efter varje teleport (Rida nu, First Ride, en dörr), en
   uppsittning eller en stängd panel är vyn den 3D-vy spelaren valt —
   aldrig en ovanifrånvy hon inte bett om. Kartan gäller i den scen där
   hon valde den.

   Kör: python3 tools/build.py && node tools/kameratest.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8912;
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};
const srv = http.createServer((q, s) => {
  const f = q.url === "/" ? "ridskolan.html" : q.url.slice(1).split("?")[0];
  const abs = path.join(DIST, f);
  if (!abs.startsWith(DIST) || !fs.existsSync(abs)) { s.writeHead(404); s.end(); return; }
  s.writeHead(200, { "content-type": f.endsWith(".html") ? "text/html" : "application/octet-stream" });
  s.end(fs.readFileSync(abs));
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  headless: true, executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});
const page = await browser.newPage({ viewport: { width: 1366, height: 768 }, locale: "sv-SE" });
page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(1200);
const st = () => page.evaluate(() => ({ vy: G.vy, scen: G.scen, ov: overlayUppe(),
  on: [...document.querySelectorAll("#viewToggle button")].filter(b => b.classList.contains("on")).map(b => b.dataset.v) }));

/* 1. Startläget: växlaren säger samma sak som vyn. */
{
  const s = await st();
  prova("start: 3D-vyn", s.vy === "3d", s.vy);
  prova("start: växlaren markerar den vy som gäller", s.on.length === 1 && s.on[0] === s.vy, s.on.join(","));
}

/* 2. H1 — att skriva i ett namnfält byter aldrig vy. */
{
  const harFalt = await page.$("#skapNamnFalt");
  if (!harFalt) await page.evaluate(() => { if (typeof visaSkaparen === "function") visaSkaparen("meny"); });
  await page.waitForTimeout(300);
  const f = await page.$("#skapNamnFalt");
  prova("karaktärsskaparens namnfält finns", !!f);
  if (f) {
    await f.click();
    await page.keyboard.type("Vera Vilma", { delay: 30 });
    const s = await st();
    prova("H1: «Vera Vilma» i namnfältet lämnar vyn i 3D", s.vy === "3d", JSON.stringify(s));
    const text = await page.evaluate(() => document.getElementById("skapNamnFalt").value);
    prova("och bokstäverna hamnar i fältet", /Vera Vilma$/.test(text), text);
  }
  /* V med en panel uppe gör ingenting — varken tangent eller knapp. */
  await page.evaluate(() => { if (document.activeElement) document.activeElement.blur(); overlay(true, "<p>prov</p>"); });
  await page.keyboard.press("KeyV");
  await page.evaluate(() => { const b = document.querySelector('#viewToggle button[data-v="2d"]'); if (b) b.click(); });
  const s = await st();
  prova("V och vyknappen gör ingenting medan en panel är uppe", s.vy === "3d", JSON.stringify(s));
  await page.evaluate(() => overlay(false));
}

/* 3. H2 — kartan till fots följer inte med genom en dörr eller in i sadeln. */
{
  await page.evaluate(() => { overlay(false); SPAR.pass = 0; SPAR_BETRODD = true; window.SPRAKET = "sv";
    G.tavling = null; startaVandring(); });
  await page.waitForTimeout(600);
  const iSadeln = await st();
  prova("First Ride: uppsuten i 3D", iSadeln.scen === "lektion" && iSadeln.vy === "3d", JSON.stringify(iSadeln));
  await page.keyboard.press("KeyE"); await page.waitForTimeout(400);
  await page.evaluate(() => { overlay(false); SPAR.pass = 3; startaVandring(); });
  await page.waitForTimeout(500);
  await page.keyboard.press("KeyV"); await page.waitForTimeout(150);
  const karta = await st();
  prova("till fots: V ger kartan på gården", karta.vy === "2d" && karta.scen === "gard", JSON.stringify(karta));
  await page.evaluate(() => gaTill("gard", { x: VD.px + 1, y: VD.py, rikt: 0 }));
  prova("en flytt INOM samma scen behåller hennes val (kartan)", (await st()).vy === "2d");
  await page.evaluate(() => { const d = STALLINNE.dorrar[0]; gaTill("stallinne", { x: d.pos[0], y: d.pos[1], rikt: 0 }); });
  const dorr = await st();
  prova("H2: genom dörren till stallet — 3D-vyn igen", dorr.vy === "3d" && dorr.scen === "stallinne", JSON.stringify(dorr));
  prova("växlaren följer med", dorr.on.length === 1 && dorr.on[0] === "3d", dorr.on.join(","));
  await page.keyboard.press("KeyV");
  prova("V i stallet ger kartan där", (await st()).vy === "2d");
  /* Rida nu / uppsittning: kartan valdes i stallet, inte i sadeln. */
  await page.evaluate(() => { G.hastId = G.hastId || valbaraHastar()[0]; if (!G.forb && typeof forbStart === "function") forbStart(); });
  await page.evaluate(() => { SPAR.pass = 0; if (typeof forstaRitten === "function") forstaRitten(); });
  await page.waitForTimeout(500);
  const rida = await st();
  prova("H2: teleport och uppsittning (First Ride) — 3D i sadeln", rida.scen === "lektion" && rida.vy === "3d", JSON.stringify(rida));
  /* Och kartan i sadeln är hennes eget val — den gäller i ritten. */
  await page.keyboard.press("KeyV");
  prova("V i sadeln ger kartan (hennes val i ritten)", (await st()).vy === "2d");
  await page.keyboard.press("KeyV");
  prova("V igen ger tillbaka 3D", (await st()).vy === "3d");
}

/* 4. En stängd panel: vyn är den hon hade. */
{
  await page.evaluate(() => overlay(true, "<p>prov</p>"));
  await page.keyboard.type("vvv");
  await page.evaluate(() => overlay(false));
  const s = await st();
  prova("panelen stängd: samma 3D-vy som före", s.vy === "3d" && !s.ov, JSON.stringify(s));
}

/* 5. MOLNEN RITAS BARA UTE (miljö-grind 0.12). Molnnätet ritades i varje
   scen, och syntes inomhus i varje springa mellan vägg och tak. Här räknas
   hur många gånger nätet faktiskt ritas under riktiga bildrutor, till fots
   på gården, i stallet och i ridhuset, och i sadeln i ridhuset.

   KONTROLLMÄTNING: samma räknare på ett direkt anrop med «ute». Räknar den
   inte det, mäter provet ingenting. */
{
  const rakna = async (stall) => {
    await page.evaluate(stall);
    await page.waitForTimeout(500);
    return page.evaluate(async () => {
      if (G.vy !== "3d") vaxlaVy();
      const orig = GL.rita.bind(GL); let n = 0, rutor = 0;
      GL.rita = (nat, ...r) => { if (S3.himmel && nat === S3.himmel.nat) n++; return orig(nat, ...r); };
      const b0 = (typeof V3D !== "undefined" && V3D.bild) || 0;
      await new Promise((klar) => { let i = 0; const steg = () => { if (++i >= 8) klar(); else requestAnimationFrame(steg); }; requestAnimationFrame(steg); });
      rutor = ((typeof V3D !== "undefined" && V3D.bild) || 0) - b0;
      GL.rita = orig;
      return { n, scen: G.scen, plats: G.plats, vy: G.vy, rutor };
    });
  };
  const gard = await rakna(() => { overlay(false); gaTill("gard", { x: 130, y: 128, rikt: 0 }); });
  const stall = await rakna(() => { const d = STALLINNE.dorrar[0]; gaTill("stallinne", { x: d.pos[0], y: d.pos[1], rikt: 0 }); });
  const hall = await rakna(() => { gaTill("ridhusinne", { x: RIDHUSINNE.bana.x + 10, y: RIDHUSINNE.bana.y + 20, rikt: 0 }); });
  prova("molnen ritas ute på gården", gard.scen === "gard" && gard.vy === "3d" && gard.n > 0, JSON.stringify(gard));
  prova("molnen ritas INTE i stallet", stall.scen === "stallinne" && stall.vy === "3d" && stall.rutor > 0 && stall.n === 0, JSON.stringify(stall));
  prova("molnen ritas INTE i ridhuset till fots", hall.scen === "ridhusinne" && hall.vy === "3d" && hall.rutor > 0 && hall.n === 0, JSON.stringify(hall));
  const k = await page.evaluate(() => {
    const orig = GL.rita.bind(GL); let n = 0;
    GL.rita = (nat, ...r) => { if (S3.himmel && nat === S3.himmel.nat) n++; return orig(nat, ...r); };
    const kam = { x: 10, y: 2, z: 30 };
    const ute = s3RitaMoln(kam, false), efterUte = n; const inne = s3RitaMoln(kam, true);
    GL.rita = orig;
    return { ute, inne, efterUte, efterInne: n };
  });
  prova("kontrollmätning: räknaren ser ett molnanrop ute och inget inne",
    k.ute === true && k.efterUte === 1 && k.inne === false && k.efterInne === 1, JSON.stringify(k));
  /* I sadeln i ridhuset — den andra ritvägen (rita3D). */
  const sadel = await page.evaluate(async () => {
    G.hastId = G.hastId || valbaraHastar()[0];
    if (typeof Forb !== "undefined") { let p = 1; while (Forb.fyndFor(G.hastId, p + 1)) p++; SPAR.pass = p; sattAktivHast(G.hastId); }
    if (typeof stegkortRidaNu === "function") stegkortRidaNu();
    G.hastPlats = "box"; G.ride = nyState(G.dagsform, 0.5, G.sadellage); sittUpp("ridhus");
    await new Promise((r) => setTimeout(r, 900));
    if (G.vy !== "3d") vaxlaVy();
    const orig = GL.rita.bind(GL); let n = 0, alla = 0;
    GL.rita = (nat, ...r) => { alla++; if (S3.himmel && nat === S3.himmel.nat) n++; return orig(nat, ...r); };
    await new Promise((klar) => { let i = 0; const steg = () => { if (++i >= 8) klar(); else requestAnimationFrame(steg); }; requestAnimationFrame(steg); });
    GL.rita = orig;
    return { n, alla, scen: G.scen, plats: G.plats, vy: G.vy };
  });
  prova("molnen ritas INTE i sadeln i ridhuset", sadel.scen === "lektion" && sadel.plats === "ridhus" && sadel.alla > 0 && sadel.n === 0,
    JSON.stringify(sadel));
}

await browser.close(); srv.close();
console.log(fel ? `KAMERAPROVET (Q4): ${fel} FEL` : "KAMERAPROVET (Q4): alla gröna");
process.exit(fel ? 1 : 0);
