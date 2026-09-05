#!/usr/bin/env node
/* G02-A — REVIEW-ONLY A/B-UNDERLAG för de fyra blockerande parametrarna
   (issue #82, senior re-review av PR #86).

   Kör samma manövrer två gånger i den byggda sidan — en gång med webbens
   Gate 01-värden (A) och en gång med Roblox värden (B) — och skriver ut
   mätvärdena sida vid sida. Samma häst, samma startläge, samma insatser.

   HÄR ÄNDRAS INGEN PRODUKTKANON. Harnessen anropar `ridSattAB()`, som
   bara finns för review, och produktionen kör alltid A. Att välja A, B
   eller en tredje trimning är Tobias produktbeslut.

   Kör: python3 tools/build.py && node tools/abtest.mjs
        node tools/abtest.mjs --md   (markdown-tabell för PR/dokument) */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8861;
const MD = process.argv.includes("--md");
const srv = http.createServer((q, s) => {
  const p = path.join(DIST, decodeURIComponent(q.url.split("?")[0] === "/" ? "/ridskolan.html" : q.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { s.writeHead(404); s.end(); return; } s.writeHead(200, { "content-type": "text/html" }); s.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage();
page.on("pageerror", e => console.log("PAGEERROR", e.message));
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(1500);

/* Minsta-kvadrat-cirkel (Kåsa), samma som i ridtest.mjs. */
function cirkel(p) {
  let Sx = 0, Sy = 0, Sxx = 0, Syy = 0, Sxy = 0, Sz = 0, Szx = 0, Szy = 0;
  for (const [x, y] of p) { const z = x * x + y * y;
    Sx += x; Sy += y; Sxx += x * x; Syy += y * y; Sxy += x * y; Sz += z; Szx += z * x; Szy += z * y; }
  const n = p.length, M = [[Sxx, Sxy, Sx], [Sxy, Syy, Sy], [Sx, Sy, n]], v = [-Szx, -Szy, -Sz];
  for (let i = 0; i < 3; i++) {
    let b = i; for (let k = i + 1; k < 3; k++) if (Math.abs(M[k][i]) > Math.abs(M[b][i])) b = k;
    [M[i], M[b]] = [M[b], M[i]]; [v[i], v[b]] = [v[b], v[i]];
    for (let k = i + 1; k < 3; k++) { const f = M[k][i] / M[i][i];
      for (let j = i; j < 3; j++) M[k][j] -= f * M[i][j]; v[k] -= f * v[i]; }
  }
  const x3 = v[2] / M[2][2], x2 = (v[1] - M[1][2] * x3) / M[1][1],
        x1 = (v[0] - M[0][1] * x2 - M[0][2] * x3) / M[0][0];
  const cx = -x1 / 2, cy = -x2 / 2, r = Math.sqrt(cx * cx + cy * cy - x3);
  let max = 0; for (const [x, y] of p) max = Math.max(max, Math.abs(Math.hypot(x - cx, y - cy) - r));
  return { r, max };
}

/* En mätomgång i den valda uppsättningen. Samma häst, samma startläge,
   samma insatser i båda — det är HELA poängen med jämförelsen. */
async function omgang(vilken) {
  return await page.evaluate(async (vilken) => {
    ridSattAB(vilken);
    const s = ridAB();
    const HAST = Object.keys(HORSES)[0];
    const dt = 1 / 60;
    const nytt = () => { G.hastId = HAST; G.hamtad = true; G.npcs = [];
      G.ride = nyState(0.7, 0.5, 0.8); G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0; };
    const kor = (n, skankel, styr, tygel) => {
      for (let i = 0; i < n; i++) { RIDIN.skankel = skankel; RIDIN.styr = styr;
        RIDIN.tygel = tygel || 0; RIDIN.sits = 0.5; stegaRitt(dt); } };

    /* 1. GÅNGARTERNA: hur snabbt går ekipaget, och vilken volt ger full
       styrning i var och en? Skänkel/tygel valda så att alla tre nås. */
    const gangarter = [];
    /* Skänkeln som ger den BEGÄRDA gångarten söks upp i stället för att
       gissas: samma insats ger olika gångart i A och B (bandgränserna
       skiljer), och en rad märkt "skritt" som i själva verket rids i trav
       är inte en mätning utan ett fel. Hittas ingen insats som håller
       gångarten redovisas den som faktiskt rids. */
    const sokSkankel = (mal, tygel) => {
      let bast = null;
      const stege = [];
      for (let v = 0.01; v <= 0.30; v += 0.01) stege.push(+v.toFixed(2));
      for (const v of [0.34, 0.45, 0.60, 0.85, 1.0]) stege.push(v);
      for (const sk of stege) {
        /* Söker med SAMMA styrutslag som mätningen använder. Söker man
           utan styrning hittar man en skänkel som inte håller gångarten
           när volten väl rids, och raden blir fel märkt. */
        nytt(); kor(60 * 18, sk, 1.0, tygel);
        if (G.ride.gangart === mal) { bast = sk; break; }
      }
      return bast;
    };
    for (const [namn, gissning, tygel] of [["skritt", 0.08, 0], ["trav", 0.34, 0], ["galopp", 0.85, 0]]) {
      const skankel = sokSkankel(namn, tygel) ?? gissning;
      nytt(); kor(60 * 20, skankel, 1.0, tygel);
      const punkter = [];
      for (let i = 0; i < 60 * 14; i++) { RIDIN.skankel = skankel; RIDIN.styr = 1.0;
        RIDIN.tygel = tygel || 0; RIDIN.sits = 0.5; stegaRitt(dt);
        if (i % 6 === 0) punkter.push([G.px, G.py]); }
      gangarter.push({ begard: namn, skankel, gangart: G.ride.gangart, tempo: G.ride.tempo,
        styrning: G.aids.styrning, kappa: Math.abs(G.kappa), punkter,
        steglangd: G.ride.steglangd });
    }

    /* 2. 20 M VOLT: vilket styrutslag krävs för radie 10 m i trav? */
    let volt20 = null;
    { nytt(); kor(60 * 20, 0.34, 0, 0);
      const tak = s.KAPPA_MAX * s.GANGSVANG[G.ride.gangart] *
        (0.78 + 0.44 * Math.min(Math.max(HORSES[HAST].kanslighet, 0), 1));
      /* κ = 0,1 ⇒ radie 10 m. styrning mättas vid 0,72 för råinsats 1,00. */
      const kravdStyrning = 0.1 / tak;
      volt20 = { tak, kravdStyrning, mojlig: kravdStyrning <= 0.72,
        minstaRadie: 1 / (tak * 0.72), gangart: G.ride.gangart };
    }

    /* 3. ÖVERGÅNGARNA: trappan upp och ned, och var banden ligger. */
    let overgangar = null;
    { nytt();
      const upp = [];
      for (let i = 0; i < 60 * 30; i++) { RIDIN.skankel = 1.0; RIDIN.styr = 0;
        RIDIN.tygel = 0; RIDIN.sits = 0.5; stegaRitt(dt);
        const g = G.ride.gangart; if (!upp.length || upp[upp.length - 1] !== g) upp.push(g); }
      const topp = G.ride.tempo;
      const ned = [G.ride.gangart];
      for (let i = 0; i < 60 * 60; i++) { RIDIN.skankel = 0; RIDIN.styr = 0;
        RIDIN.tygel = 1.0; RIDIN.sits = 0.2; stegaRitt(dt);
        const g = G.ride.gangart; if (ned[ned.length - 1] !== g) ned.push(g); }
      overgangar = { upp, ned, topptempo: topp, galoppMax: Gait.G.galopp.max };
    }

    return { namn: s.namn, kalla: s.kallа, KAPPA_MAX: s.KAPPA_MAX,
      GANGSVANG: s.GANGSVANG, galoppMax: s.galoppMax,
      kanslighet: HORSES[HAST].kanslighet, hast: HAST,
      gangarter, volt20, overgangar };
  }, vilken);
}

const A = await omgang("A");
const B = await omgang("B");
await page.evaluate(() => ridSattAB("A"));          // lämna sidan i produktionsläge
await browser.close(); srv.close();

const tal = (v, d = 2) => (v === null || v === undefined || !Number.isFinite(v)) ? "—" : v.toFixed(d);
for (const s of [A, B]) for (const g of s.gangarter) {
  /* Står ekipaget stilla finns ingen bana att anpassa en cirkel till.
     Då redovisas ingen radie — hellre ett streck än en siffra som ser
     ut som en mätning men är brus. */
  const rorde = g.tempo > 0.25 && g.kappa > 1e-3;
  const c = rorde ? cirkel(g.punkter) : null;
  g.riddRadie = c ? c.r : null; g.riddAvvik = c ? c.max : null;
  g.gradPerSek = rorde ? g.kappa * g.tempo * 180 / Math.PI : null;
  g.steglangd = g.tempo > 0.25 ? g.steglangd : null;
}

if (MD) {
  console.log(`### A/B — samma häst (\`${A.hast}\`, känslighet ${tal(A.kanslighet)}), samma startläge, samma insatser\n`);
  console.log(`| | A — webb (Gate 01) | B — Roblox |`);
  console.log(`|---|---|---|`);
  console.log(`| Kurvaturtak | ${tal(A.KAPPA_MAX)} 1/m | ${tal(B.KAPPA_MAX)} 1/m |`);
  console.log(`| Galoppens svängfaktor | ${tal(A.GANGSVANG.galopp)} | ${tal(B.GANGSVANG.galopp)} |`);
  console.log(`| Galoppens övre band | ${tal(A.galoppMax)} m/s | ${tal(B.galoppMax)} m/s |`);
  console.log("");
  console.log(`| Manöver | A | B | skillnad |`);
  console.log(`|---|---|---|---|`);
  for (let i = 0; i < A.gangarter.length; i++) {
    const a = A.gangarter[i], b = B.gangarter[i];
    const varning = (a.gangart !== a.begard || b.gangart !== b.begard)
      ? ` ⚠️ begärd ${a.begard}, reds som ${a.gangart}/${b.gangart}` : "";
    console.log(`| **${a.begard}**${varning} — ridd volt vid full styrning | ${tal(a.riddRadie)} m (${a.gangart}, ${tal(a.tempo)} m/s) | ${tal(b.riddRadie)} m (${b.gangart}, ${tal(b.tempo)} m/s) | ${tal(b.riddRadie - a.riddRadie)} m |`);
    console.log(`| **${a.begard}** — vridhastighet | ${tal(a.gradPerSek, 1)}°/s | ${tal(b.gradPerSek, 1)}°/s | ${tal(b.gradPerSek - a.gradPerSek, 1)}°/s |`);
    console.log(`| **${a.begard}** — cykellängd | ${tal(a.steglangd)} m | ${tal(b.steglangd)} m | ${tal(b.steglangd - a.steglangd)} m |`);
  }
  console.log(`| 20 m volt — krävd styrning (${A.volt20.gangart}) | ${tal(A.volt20.kravdStyrning)} av 0,72 | ${tal(B.volt20.kravdStyrning)} av 0,72 | ${tal(B.volt20.kravdStyrning - A.volt20.kravdStyrning)} |`);
  console.log(`| Snävast möjliga volt | ${tal(A.volt20.minstaRadie)} m | ${tal(B.volt20.minstaRadie)} m | ${tal(B.volt20.minstaRadie - A.volt20.minstaRadie)} m |`);
  console.log(`| Trappan upp | ${A.overgangar.upp.join(" → ")} | ${B.overgangar.upp.join(" → ")} | |`);
  console.log(`| Trappan ned | ${A.overgangar.ned.join(" → ")} | ${B.overgangar.ned.join(" → ")} | |`);
  console.log(`| Topptempo, full skänkel | ${tal(A.overgangar.topptempo)} m/s | ${tal(B.overgangar.topptempo)} m/s | ${tal(B.overgangar.topptempo - A.overgangar.topptempo)} m/s |`);
} else {
  const rad = (namn, a, b) => console.log(`  ${namn.padEnd(42)} A ${String(a).padStart(12)}   B ${String(b).padStart(12)}`);
  console.log(`\nA/B — ${A.namn} mot ${B.namn}`);
  console.log(`häst ${A.hast}, känslighet ${tal(A.kanslighet)}, samma startläge och insatser\n`);
  rad("kurvaturtak (1/m)", tal(A.KAPPA_MAX), tal(B.KAPPA_MAX));
  rad("galoppens svängfaktor", tal(A.GANGSVANG.galopp), tal(B.GANGSVANG.galopp));
  rad("galoppens övre band (m/s)", tal(A.galoppMax), tal(B.galoppMax));
  console.log("");
  for (let i = 0; i < A.gangarter.length; i++) {
    const a = A.gangarter[i], b = B.gangarter[i];
    rad(`${a.begard}: gångart som faktiskt reds`, `${a.gangart} ${tal(a.tempo)}`, `${b.gangart} ${tal(b.tempo)}`);
    rad(`${a.begard}: ridd volt vid full styrning (m)`, tal(a.riddRadie), tal(b.riddRadie));
    rad(`${a.begard}: vridhastighet (°/s)`, tal(a.gradPerSek, 1), tal(b.gradPerSek, 1));
    rad(`${a.begard}: cykellängd (m)`, tal(a.steglangd), tal(b.steglangd));
  }
  console.log("");
  rad("20 m volt: krävd styrning (max 0,72)", tal(A.volt20.kravdStyrning), tal(B.volt20.kravdStyrning));
  rad("snävast möjliga volt (m)", tal(A.volt20.minstaRadie), tal(B.volt20.minstaRadie));
  rad("topptempo, full skänkel (m/s)", tal(A.overgangar.topptempo), tal(B.overgangar.topptempo));
  console.log(`  trappan upp    A ${A.overgangar.upp.join(" → ")}`);
  console.log(`                 B ${B.overgangar.upp.join(" → ")}`);
  console.log(`  trappan ned    A ${A.overgangar.ned.join(" → ")}`);
  console.log(`                 B ${B.overgangar.ned.join(" → ")}`);
  console.log("\nProduktbeslut. Harnessen mäter, den väljer inte.");
}
