#!/usr/bin/env node
/* LÄKTARGRINDEN — P0 #81/#114.

   Gångtestet visade redan att en VÄG upp på läktaren finns. Den vägen var
   grön medan spelaren ändå upplevde läktaren som trasig, och det är hela
   poängen med den här filen: gångtestet mäter tillstånd, det här mäter
   vad spelaren SER.

   Postmortem på #114 namngav fyra fel. Tre av dem är rena renderingsfel
   som inget vägtest kan fånga:

     1. figuren ritades på Y=0 medan kollisionen och kameran steg,
     2. den gula genomskinliga SPELABSTRAKTION-markören låg i spelarvyn
        och lästes som ett genomskinligt block i trappan,
     3. läktarens cutaway tonade bort golvet spelaren själv stod på,

   och det fjärde — sen runtime-mutation av geometrin — gjorde att
   rendering och kollision kunde läsa olika trappor.

   Provet går den RIKTIGA spelarvägen med spelets egen kollision, i 3D-vyn
   där figuren faktiskt ritas, och läser tre saker som måste stämma
   samtidigt: nivåregelns z, den höjd figuren ritades på, och att inget
   abstraktionsnät finns i scenen.

   Kör: python3 tools/build.py && node tools/laktartest.mjs */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const PORT = 8796;
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };
const srv = http.createServer((req, res) => {
  const p = path.join(DIST, decodeURIComponent(req.url.split("?")[0] === "/" ? "/index.html" : req.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { res.writeHead(404); res.end(); return; } res.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" }); res.end(d); });
});
await new Promise(r => srv.listen(PORT, r));

const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on("pageerror", e => console.log("PAGEERROR", e.message));
await page.goto(`http://localhost:${PORT}/ridskolan.html`, { waitUntil: "load" });
await page.waitForTimeout(1500);
await page.evaluate(() => { try { startaVandring(); } catch (e) { console.log("startaVandring:", e.message); } });
await page.waitForTimeout(600);

const resultat = [];
function prova(namn, ok, detalj) {
  resultat.push({ namn, ok });
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj);
}
const ev = (f, a) => page.evaluate(f, a);

const L = await ev(() => {
  const R = RIDHUSINNE, l = R.laktare, ls = SPELABSTRAKTIONER.ridhus.laktarSteg;
  return { x0: l.x0, dackDjup: l.dackDjup, dackZ: l.dackZ, y0: l.y0, y1: l.y1,
    gang: l.gangbrada.djup, steg: ls, domarbas: R.domarbas };
});
const bankant = L.x0 + L.dackDjup;
const gangMitt = bankant - L.gang / 2;          // mitt på gångbrädan

/* ══ 1. GEOMETRIN ÄR KANONISK, INTE SENT PATCHAD ═══════════════════
   Trappan ska ha sina mått direkt när sidan laddat. Ett värde som sätts
   av en sen `load`-hook hinner inte med när 3D-scenen byggs. */
prova("läktarstegen har kanoniska mått redan vid sidladdning",
  L.steg.x1 > L.steg.x0 && L.steg.y1 > L.steg.y0 && L.steg.z1 === L.dackZ,
  `x ${L.steg.x0.toFixed(2)}–${L.steg.x1.toFixed(2)} · y ${L.steg.y0.toFixed(2)}–${L.steg.y1.toFixed(2)} · z ${L.steg.z0}→${L.steg.z1}`);

/* Loppet ska vara en trappa att gå uppför, inte en ramp: minst fyra steg
   och en lutning under 30°. */
const lutning = Math.atan2(L.steg.z1 - L.steg.z0, L.steg.y1 - L.steg.y0) * 180 / Math.PI;
prova("trappan är fysiskt läsbar (flera steg, under 30°)",
  lutning < 30 && Math.ceil(L.steg.z1 / L.steg.stegMax) >= 4,
  `${lutning.toFixed(1)}° · ${Math.ceil(L.steg.z1 / L.steg.stegMax)} steg`);

/* ══ 2. GÅNGBRÄDAN ÄR FRI ══════════════════════════════════════════ */
const gang0 = bankant - L.gang;
prova("domarbåset blockerar inte gångbrädan",
  L.domarbas.x + L.domarbas.b / 2 <= gang0,
  `båset till x ${(L.domarbas.x + L.domarbas.b / 2).toFixed(2)} · gångbrädan börjar ${gang0.toFixed(2)}`);

/* ══ 3. INGEN DEBUGGEOMETRI I SPELARVYN ════════════════════════════
   Markörerna är granskningsmarkering. I produktvyn får de inte finnas —
   inte filtreras bort efteråt, utan aldrig byggas. */
/* Scenen måste vara BYGGD i 3D för att det ska gå att mäta vad som
   ritades. `ritaVandring3D` är spelets egen bildruta för gå-läget — inte
   en testhjälpare som bygger något eget. */
await ev(() => { gaTill("ridhusinne", { x: 6, y: 60, rikt: 0, z: 0 }); G.vy = "3d"; ritaVandring3D(); });
await page.waitForTimeout(900);
await ev(() => ritaVandring3D());
let abstr = await ev(() => ({
  antal: (S3.statiskt || []).filter(s => s && s.abstraktion).length,
  glas: (S3.statiskt || []).filter(s => s && s.glas === true && s.alfa === 0.35).length,
  flagga: typeof v3dAbstraktionSynlig === "function" ? v3dAbstraktionSynlig() : null,
}));
prova("inga SPELABSTRAKTION-markörer i produktvyn",
  abstr.antal === 0 && abstr.flagga === false,
  `${abstr.antal} markörer · flagga ${abstr.flagga}`);

/* …men de ska gå att slå PÅ för granskning, annars är regeln oprövbar. */
const abstrPa = await ev(() => {
  V3D.visaAbstraktion = true;
  V3D.plats = null;                        // tvinga ombyggnad av scenen
  ritaVandring3D();
  const n = (S3.statiskt || []).filter(s => s && s.abstraktion).length;
  V3D.visaAbstraktion = false; V3D.plats = null;
  ritaVandring3D();
  return n;
});
prova("men de går att slå på för granskning", abstrPa > 0, `${abstrPa} markörer i abstraktionsläget`);

/* ══ 4. AVATARENS HÖJD FÖLJER GOLVET ═══════════════════════════════
   Kärnan i P0:n. Går man upp för trappan ska nivåregeln OCH den ritade
   figuren stiga tillsammans. En av dem räcker inte: förra försöket hade
   nivån rätt och kroppen kvar på marken. */
async function gaTill3D(x, y, z, hall, klar, maxMs = 25000) {
  await ev(({ x, y, z }) => { if (G.vy !== "2d") vaxlaVy(); gaTill("ridhusinne", { x, y, rikt: 0, z }); }, { x, y, z });
  await page.waitForTimeout(300);
  const TANGENT = { N: "KeyW", S: "KeyS", O: "KeyD", V: "KeyA" };
  const keys = [...hall].map(h => TANGENT[h]);
  for (const k of keys) await page.keyboard.down(k);
  const t0 = Date.now();
  let p;
  do {
    await page.waitForTimeout(200);
    p = await ev(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), z: +(VD.pz || 0).toFixed(2) }));
  } while (!klar(p) && Date.now() - t0 < maxMs);
  for (const k of keys) await page.keyboard.up(k);
  await page.waitForTimeout(150);
  return p;
}

/* MÄT VAD SPELETS EGEN LOOP RITADE.

   Provet ritar inte själv. Det byter till 3D med spelets vyväxlare och
   låter requestAnimationFrame-loopen köra ett antal riktiga bildrutor —
   sedan läses `V3D.figurGolv`, alltså den höjd figuren FAKTISKT ritades
   på i den sista av dem. Att anropa ritaVandring3D() för hand gav en
   bildruta utanför spelets ordning, och då mätte provet sin egen
   anropskedja i stället för spelarens vy. */
async function rita() {
  await ev(() => { if (G.vy === "2d") vaxlaVy(); V3D.figurGolv = null; });
  await page.waitForTimeout(900);
  return ev(() => ({ golv: V3D.figurGolv, pz: VD.pz || 0, vy: G.vy }));
}

/* Marknivå först: figuren ska ritas på 0 när hon står på golvet. */
const pMark = await gaTill3D((L.steg.x0 + L.steg.x1) / 2, L.steg.y1 + 0.8, 0, "S", p => p.y < L.steg.y1 + 0.4, 8000);
let ritad = await rita();
/* `figurGolv` nollställs till null före varje mätning (se rita), så ett
   kvarvarande värde från förra mätpunkten kan inte passera som färskt. */
prova("på hallgolvet ritas figuren på marknivå",
  ritad.golv !== null && Math.abs(ritad.golv) < 0.02 && Math.abs(ritad.pz) < 0.02,
  `ritad ${ritad.golv.toFixed(2)} · nivå ${ritad.pz.toFixed(2)}`);

/* …och uppe på däcket ska BÅDA vara däckhöjd. Gången mäts först, sedan
   ritningen — och de mäts var för sig, av det enkla skälet att de svarar
   på olika frågor. */
const pDack = await gaTill3D((L.steg.x0 + L.steg.x1) / 2, L.steg.y1 + 0.6, 0,
  "S", p => p.z > L.dackZ - 0.02 && p.y < L.y1 - 0.3, 25000);
prova("spelaren går från golvet upp på däcket utan teleport",
  pDack.z >= L.dackZ - 0.02 && pDack.y < L.y1 - 0.3,
  `till (${pDack.x}, ${pDack.y}) z ${pDack.z} (däck ${L.dackZ})`);

/* RITNINGEN MÄTS I VILA, PÅ EN KÄND NIVÅ. Att läsa den direkt efter en
   gång gav ett ostadigt värde: figuren hinner ritas medan nivån ännu
   sätter sig, och provet mätte då sin egen tajmning i stället för
   kopplingen mellan nivå och kropp. Här ställs spelaren på en bestämd
   nivå, spelets egen loop får rita, och de två jämförs. */
async function ritadPa(x, y, z) {
  await ev(({ x, y, z }) => { if (G.vy === "2d") vaxlaVy();
    gaTill("ridhusinne", { x, y, rikt: 0, z }); V3D.figurGolv = null; }, { x, y, z });
  await page.waitForTimeout(900);
  return ev(() => ({ golv: V3D.figurGolv, pz: VD.pz || 0 }));
}
const paDack = await ritadPa(gangMitt, L.y1 - 3.0, L.dackZ);
prova("på däcket RITAS figuren på däckets höjd, inte på marken",
  paDack.golv !== null && Math.abs(paDack.golv - paDack.pz) < 0.02
    && paDack.golv > L.dackZ - 0.02,
  `ritad ${paDack.golv} · nivå ${paDack.pz} · däck ${L.dackZ}`);
const paRad = await ritadPa(gangMitt - 0.9, L.y1 - 3.0, L.dackZ + 0.3);
prova("och en rad högre följer kroppen med dit också",
  paRad.golv !== null && Math.abs(paRad.golv - paRad.pz) < 0.02
    && paRad.golv > L.dackZ + 0.2,
  `ritad ${paRad.golv} · nivå ${paRad.pz}`);

/* ══ 5. GOLVET UNDER FÖTTERNA TONAS INTE ═══════════════════════════ */
const tonad = await ev(() => {
  G.vy = "3d"; ritaVandring3D(); ritaVandring3D();
  const lak = (S3.statiskt || []).find(s => s && s.laktargolv);
  if (!lak) return { fanns: false, scen: G.scen, plats: V3D.plats,
    antal: (S3.statiskt || []).length, redo: S3.redo, trasig: S3.trasig };
  const k = V3D.kam;
  return { fanns: true, paLaktaren: v3dPaLaktaren(),
    tonas: v3dTonas(lak, k.x, k.z, VD.px, VD.py) };
});
prova("läktargolvet man står på tonas inte bort under fötterna",
  tonad.fanns === true && tonad.paLaktaren === true && tonad.tonas === false,
  `på läktaren ${tonad.paLaktaren} · tonas ${tonad.tonas} · ${JSON.stringify(tonad)}`);

/* …men från marknivå ska samma yta fortfarande kunna tonas, annars har
   siktregeln bara stängts av. */
const frånMark = await ev(({ y }) => {
  gaTill("ridhusinne", { x: 8, y, rikt: 0, z: 0 });
  const lak = (S3.statiskt || []).find(s => s && s.laktargolv);
  return { paLaktaren: v3dPaLaktaren(), harRegel: !!lak };
}, { y: L.y1 - 2 });
prova("från marknivå gäller cutawayregeln fortfarande",
  frånMark.harRegel === true && frånMark.paLaktaren === false,
  `på läktaren ${frånMark.paLaktaren}`);

/* ══ 6. TIO METER LÄNGS GÅNGEN ═════════════════════════════════════ */
const start = L.y1 - 2.0;
const pGang = await gaTill3D(gangMitt, start, L.dackZ, "S", p => p.y < start - 10.5, 60000);
prova("minst 10 m gång längs läktargången, kvar på däckhöjd",
  start - pGang.y >= 10.0 && pGang.z >= L.dackZ - 0.02,
  `${(start - pGang.y).toFixed(1)} m · z ${pGang.z}`);
ritad = await rita();
prova("och figuren följde med hela vägen",
  ritad.golv !== null && Math.abs(ritad.golv - ritad.pz) < 0.02 && ritad.golv > L.dackZ - 0.02,
  `ritad ${ritad.golv.toFixed(2)} · nivå ${ritad.pz.toFixed(2)}`);

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `\n${fel} FEL` : `\nALLA OK (${resultat.length} mätningar)`);
process.exit(fel ? 1 : 0);
