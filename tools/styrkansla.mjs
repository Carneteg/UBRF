#!/usr/bin/env node
/* G02-A.1 P4 — STYRNINGENS mätvärden.

   ridkansla.mjs mäter tempot i den rena modellen. Kurvaturen bor inte
   där utan i stegaRitt() i src/game.js, tillsammans med gångartstaket
   och hästens smidighet. Den här filen mäter därför i den BYGGDA sidan,
   av samma skäl som ridtest.mjs gör det: en egen reimplementation av
   fem rader integration hade mätt min kopia, inte spelet.

   Skriver en tabell. Kraven ligger i ridtest.mjs — det här är
   instrumentet, inte grinden.

   Kör: python3 tools/build.py && node tools/styrkansla.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8821;
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

/* Kör en manöver och lämna hela spåret tillbaka. Manövern beskrivs som
   segment: [sekunder, styrutslag]. Skänkeln hålls konstant så att det
   som mäts är styrningen och ingenting annat.

   dt är fast. Mätningen ska inte bero på hur snabbt SwiftShader råkar
   rita, och P4 handlar om beteende per sekund, inte per bildruta. */
async function manover(mal, segment) {
  return await page.evaluate(async ([mal, segment]) => {
    G.hastId = G.hastId || Object.keys(HORSES)[0];
    G.hamtad = true;
    G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.npcs = [];
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    const dt = 1 / 60;
    let skankel = 0;
    const satt = st => { RIDIN.skankel = skankel; RIDIN.styr = st; RIDIN.tygel = 0; RIDIN.sits = 0.5; };

    /* UPP I GÅNGART MED IMPULSER, inte med en hållen nivå.
       Första versionen av den här filen satte skänkeln till 0,85 och
       antog galopp. Varenda rad kom tillbaka som "skritt": efter
       cue-modellen i P2 ber en HÖJNING om nästa gångart, en hållen nivå
       ber om ingenting. Mätningen mätte alltså tre gånger samma gångart
       och jag hade läst det som tre. Stegen är samma stege som
       ridtest.mjs använder, och gångarten i tabellen kommer från spelet
       — den skrivs inte av mig. */
    const stege = { skritt: [0.35], trav: [0.35, 0.60], galopp: [0.35, 0.60, 0.85] }[mal];
    for (const niva of stege) {
      skankel = niva;
      for (let i = 0; i < 60 * 4; i++) { satt(0); stegaRitt(dt); }
    }
    /* Och låt kursen lugna sig innan mätningen börjar. */
    for (let i = 0; i < 60 * 3; i++) { satt(0); stegaRitt(dt); }

    const spar = [];
    let t = 0;
    for (const [sek, st] of segment) {
      for (let i = 0; i < Math.round(60 * sek); i++) {
        satt(st); stegaRitt(dt);
        t += dt;
        spar.push({ t, st, kappa: G.kappa, rikt: G.rikt, px: G.px, py: G.py,
          tempo: G.ride.tempo, gangart: G.ride.gangart });
      }
    }
    const h = HORSES[G.hastId];
    return { spar, dt, kanslighet: h.kanslighet,
      tak: (typeof ridKanon === "function") ? ridKanon().KAPPA_MAX : null };
  }, [mal, segment]);
}

/* Derivator ur spåret. Kurvaturens ÄNDRINGSTAKT är P4:s egentliga mått:
   κ säger hur snävt hon går, κ̇ hur våldsamt bågen ändras. Det är i κ̇
   ett ryck syns, inte i κ. */
function derivera(spar, dt) {
  const d = [];
  for (let i = 1; i < spar.length; i++) d.push((spar[i].kappa - spar[i - 1].kappa) / dt);
  return d;
}
const max = a => a.reduce((m, v) => Math.max(m, Math.abs(v)), 0);

/* Tid från segmentbytet tills κ nått `andel` av sitt slutvärde. */
function restid(spar, dt, fran, till, andel) {
  const mal = spar[till - 1].kappa, start = spar[fran].kappa;
  const span = mal - start;
  if (Math.abs(span) < 1e-6) return null;
  for (let i = fran; i < till; i++) {
    if ((spar[i].kappa - start) / span >= andel) return (i - fran) * dt;
  }
  return null;
}

/* Överslag i procent av slutvärdet, inom fönstret. */
function overslag(spar, fran, till) {
  const mal = spar[till - 1].kappa;
  if (Math.abs(mal) < 1e-4) return 0;
  let extrem = mal;
  for (let i = fran; i < till; i++) if (Math.abs(spar[i].kappa) > Math.abs(extrem)) extrem = spar[i].kappa;
  return (Math.abs(extrem) - Math.abs(mal)) / Math.abs(mal) * 100;
}

/* Index där ett segment börjar, givet segmentlistan. */
function granser(segment, dt) {
  const g = [0]; let n = 0;
  for (const [sek] of segment) { n += Math.round(60 * sek); g.push(n); }
  return g;
}

const rader = [];
const rad = (namn, v) => { rader.push({ namn, ...v }); };
const n2 = v => v === null || v === undefined ? "" : (typeof v === "number" ? v.toFixed(3) : String(v));

/* ── 1. RAKT → BÅGE → RAKT ────────────────────────────────────────
   Grundmanövern. Hur lång tid tar det att lägga sig i bågen, hur lång
   att räta ut sig igen, och hur våldsamt ändras kurvaturen på vägen. */
for (const namn of ["skritt", "trav", "galopp"]) {
  const seg = [[3, 0], [4, 0.60], [4, 0]];
  const { spar, dt } = await manover(namn, seg);
  const g = granser(seg, dt);
  const kIn = derivera(spar.slice(g[1], g[2]), dt), kUt = derivera(spar.slice(g[2], g[3]), dt);
  rad(`rakt→båge→rakt (${namn})`, {
    in90: restid(spar, dt, g[1], g[2], 0.90),
    ut90: restid(spar, dt, g[2], g[3], 0.90),
    kappa: Math.abs(spar[g[2] - 1].kappa),
    overslag: overslag(spar, g[1], g[2]),
    kprickIn: max(kIn), kprickUt: max(kUt),
    gangart: spar[g[2] - 1].gangart,
  });
}

/* ── 2. RIKTNINGSBYTE ─────────────────────────────────────────────
   Full vänster, sedan full höger. Bågen måste ur kroppen innan den
   kan läggas åt andra hållet. Här syns ett eventuellt ryck tydligast:
   begäran hoppar 2 × taket i en enda bildruta. */
for (const namn of ["skritt", "trav", "galopp"]) {
  const seg = [[4, -1.0], [5, 1.0]];
  const { spar, dt } = await manover(namn, seg);
  const g = granser(seg, dt);
  const efter = spar.slice(g[1], g[2]);
  /* Tiden genom RAKT: från bytet tills kroppen passerat κ = 0. */
  let genom = null;
  for (let i = 0; i < efter.length; i++) if (efter[i].kappa >= 0) { genom = i * dt; break; }
  rad(`riktningsbyte v→h (${namn})`, {
    genomRakt: genom,
    in90: restid(spar, dt, g[1], g[2], 0.90),
    kappa: Math.abs(spar[g[2] - 1].kappa),
    overslag: overslag(spar, g[1], g[2]),
    kprickIn: max(derivera(efter, dt)),
    gangart: spar[g[2] - 1].gangart,
  });
}

/* ── 3. HÖRN IN OCH UT ────────────────────────────────────────────
   Ett kort styrutslag, som i en kortsidas vändning: lägg i, håll,
   räta. Mäter hur mycket kursen hann ändras och hur mjukt. */
{
  const seg = [[2, 0], [2.5, 0.75], [3, 0]];
  const { spar, dt } = await manover("trav", seg);
  const g = granser(seg, dt);
  const grader = (spar[g[3] - 1].rikt - spar[g[1]].rikt) * 180 / Math.PI;
  rad("hörn in/ut (trav, 0,75 i 2,5 s)", {
    in90: restid(spar, dt, g[1], g[2], 0.90),
    ut90: restid(spar, dt, g[2], g[3], 0.90),
    kappa: Math.abs(spar[g[2] - 1].kappa),
    kprickIn: max(derivera(spar.slice(g[1], g[2]), dt)),
    kprickUt: max(derivera(spar.slice(g[2], g[3]), dt)),
    kursbyte: Math.abs(grader),
    gangart: spar[g[2] - 1].gangart,
  });
}

/* ── 4. 20 m VOLT ─────────────────────────────────────────────────
   Söker det styrutslag som ger ~20 m ridd diameter i trav, och mäter
   sedan hur rund bågen faktiskt är. Utslaget SÖKS: gissar man det
   mäter man en annan volt än den man skrev i rubriken. */
{
  let bast = null;
  for (let st = 0.05; st <= 1.0001; st += 0.05) {
    const { spar } = await manover("trav", [[6, st]]);
    const k = Math.abs(spar[spar.length - 1].kappa);
    if (k < 1e-4) continue;
    const diam = 2 / k;
    if (!bast || Math.abs(diam - 20) < Math.abs(bast.diam - 20)) bast = { st, diam, k };
  }
  const seg = [[6, bast.st], [14, bast.st]];
  const { spar, dt } = await manover("trav", seg);
  const g = granser(seg, dt);
  const p = spar.slice(g[1]).map(s => [s.px, s.py]);
  /* Cirkelanpassning: minsta kvadrat på (x²+y²) = 2ax + 2by + c. */
  let Sx = 0, Sy = 0, Sxx = 0, Syy = 0, Sxy = 0, Sz = 0, Szx = 0, Szy = 0, n = p.length;
  for (const [x, y] of p) { const z = x * x + y * y;
    Sx += x; Sy += y; Sxx += x * x; Syy += y * y; Sxy += x * y; Sz += z; Szx += z * x; Szy += z * y; }
  const A = [[2 * Sxx, 2 * Sxy, Sx], [2 * Sxy, 2 * Syy, Sy], [2 * Sx, 2 * Sy, n]];
  const B = [Szx, Szy, Sz];
  for (let i = 0; i < 3; i++) {
    let piv = i; for (let r = i + 1; r < 3; r++) if (Math.abs(A[r][i]) > Math.abs(A[piv][i])) piv = r;
    [A[i], A[piv]] = [A[piv], A[i]]; [B[i], B[piv]] = [B[piv], B[i]];
    for (let r = 0; r < 3; r++) { if (r === i) continue;
      const f = A[r][i] / A[i][i];
      for (let c = i; c < 3; c++) A[r][c] -= f * A[i][c];
      B[r] -= f * B[i]; }
  }
  const cx = B[0] / A[0][0], cy = B[1] / A[1][1], cc = B[2] / A[2][2];
  const r = Math.sqrt(cc + cx * cx + cy * cy);
  let avv = 0; for (const [x, y] of p) avv = Math.max(avv, Math.abs(Math.hypot(x - cx, y - cy) - r));
  rad("volt ~20 m (trav, sökt utslag)", {
    styrutslag: bast.st, diameter: 2 * r, kappa: Math.abs(spar[spar.length - 1].kappa),
    rundhet: avv, gangart: spar[spar.length - 1].gangart,
  });
}

console.log("");
console.log("STYRNINGENS MÄTVÄRDEN — byggd sida, fast dt 1/60 s, κ i 1/m");
console.log("");
const kol = [
  ["manöver", "namn", 34], ["gångart", "gangart", 8],
  ["lägg-in 90%", "in90", 11], ["räta-ut 90%", "ut90", 11],
  ["genom rakt", "genomRakt", 10], ["κ", "kappa", 7],
  ["överslag %", "overslag", 10], ["max κ̇ in", "kprickIn", 9], ["max κ̇ ut", "kprickUt", 9],
  ["kursbyte °", "kursbyte", 10], ["utslag", "styrutslag", 7],
  ["diameter m", "diameter", 10], ["rundhet m", "rundhet", 9],
];
const brukas = kol.filter(([, k]) => k === "namn" || rader.some(r => r[k] !== undefined && r[k] !== null));
console.log(brukas.map(([t, , w]) => t.padEnd(w)).join("  "));
console.log(brukas.map(([, , w]) => "─".repeat(w)).join("  "));
for (const r of rader) console.log(brukas.map(([, k, w]) => n2(r[k]).padEnd(w)).join("  "));
console.log("");
console.log("κ̇ = kurvaturens ändringstakt i 1/(m·s). Det är DEN som rycker;");
console.log("κ i sig kan vara hur snäv som helst utan att kännas hackig.");
console.log("tider i sekunder · överslag i % av slutvärdet · rundhet = största");
console.log("avvikelse från anpassad cirkel");

await browser.close(); srv.close();
