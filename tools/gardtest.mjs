#!/usr/bin/env node
/* GÅRDSTEST — de fyra blockerarna ur Tobias produkttest 2026-09-06.

   Kör webbversionen i Chromium och GÅR med spelets riktiga kollision
   (world.js, GA.radie 0,35 m). Ingen av mätningarna nedan är ett
   punktprov mot datan: varje rad håller en tangent och läser var
   figuren faktiskt hamnade, för det var precis skillnaden mellan "grönt
   test" och "går inte att spela" i den här rundan.

   Kör: python3 tools/build.py && node tools/gardtest.mjs
   Kräver Playwright + Chromium (samma harness som gangtest.mjs). */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const PORT = 8793;
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
await page.evaluate(() => { startaVandring(); });
await page.waitForTimeout(500);
/* 2D-vyn: tangenterna är absoluta (W norr, S söder, A väster, D öster),
   oberoende av kameran. Kollisionen är densamma i båda vyerna. */
await page.evaluate(() => { G.vy = "2d"; });

const TANGENT = { N: "w", S: "s", O: "d", V: "a" };
async function ga(scen, x, y, hall, ms) {
  await page.evaluate(({ scen, x, y }) => gaTill(scen, { x, y, rikt: 0 }), { scen, x, y });
  await page.waitForTimeout(250);
  for (const h of hall) await page.keyboard.down(TANGENT[h]);
  await page.waitForTimeout(ms);
  for (const h of hall) await page.keyboard.up(TANGENT[h]);
  await page.waitForTimeout(150);
  return page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2) }));
}
const resultat = [];
function prova(namn, ok, detalj) {
  resultat.push({ namn, ok });
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj);
}

/* ══ 1. HAGGRINDEN GÅR ATT GÅ IGENOM ═══════════════════════════════
   Staketen var slutna polygoner medan grinden bara var en markör.
   Provet går UTIFRÅN in i hagen och sedan UT igen, tvärs den sida
   grinden sitter på. */
{
  const g = await page.evaluate(() => {
    const st = ANL.staket.find(s => s.grindar && s.grindar.length);
    return { grind: st.grindar[0].p, bredd: st.grindar[0].bredd,
      hage: ANL.hagar[0].rekt, markor: ANL.hamtHage.grind };
  });
  const [gx, gy] = g.grind;
  prova("grinden står på kanonmarkören — ingen ny plats påhittad",
    Math.hypot(gx - g.markor[0], gy - g.markor[1]) < 0.01,
    `grind [${gx}, ${gy}] mot markör [${g.markor}]`);

  /* Utifrån (4 m väster om grinden) rakt österut in i hagen. */
  let p = await ga("gard", gx - 4, gy, ["O"], 4000);
  prova("in i hagen genom grinden (utifrån, österut)", p.x > gx + 1.0,
    `hamnade x ${p.x} (grinden x ${gx}, hagen börjar ${g.hage.x})`);

  /* Och ut igen samma väg. */
  p = await ga("gard", gx + 4, gy, ["V"], 4000);
  prova("ut ur hagen genom grinden (inifrån, västerut)", p.x < gx - 1.0,
    `hamnade x ${p.x} (grinden x ${gx})`);

  /* NEGATIV KONTROLL: staketet ska fortfarande vara tätt bredvid
     grinden. Utan den här raden hade "grinden funkar" också blivit
     grönt av att hela staketet slutat kollidera. */
  p = await ga("gard", gx - 4, gy + 6, ["O"], 4000);
  prova("staketet är TÄTT 6 m norr om grinden (negativ kontroll)", p.x < gx - 0.2,
    `hamnade x ${p.x}, stoppad före staketlinjen x ${gx}`);
}

/* ══ 2. HÄSTEN BÖRJAR I BOXEN ══════════════════════════════════════
   Vägen ut till hagen var hela onboardingen innan man fick rida. */
{
  const s = await page.evaluate(() => {
    startaVandring();
    return { plats: G.hastPlats, leder: G.leder, hamtad: G.hamtad };
  });
  prova("dagen börjar med hästen i boxen", s.plats === "box",
    `hastPlats "${s.plats}"`);
  prova("och de härledda vyerna följer med — ingen andra platssanning",
    s.hamtad === true && s.leder === false,
    `hamtad ${s.hamtad}, leder ${s.leder}`);
  /* Läget ska gå att sätta till hagen igen — hagflödet är kvar. */
  const h = await page.evaluate(() => { G.hastPlats = "hage"; return { hamtad: G.hamtad, leder: G.leder }; });
  prova("hagflödet finns kvar: läget går att ställa tillbaka",
    h.hamtad === false && h.leder === false, `hamtad ${h.hamtad}, leder ${h.leder}`);
  await page.evaluate(() => { startaVandring(); G.vy = "2d"; });
}

/* ══ 3. STALLDÖRREN ════════════════════════════════════════════════
   "Dörren man går ut genom ligger nästan i en vägg." Uppmätt fri yta
   runt den gamla innerpunkten: 0,3 m öster och 0,3 m norr. */
{
  const d = await page.evaluate(() => {
    const dd = STALLINNE.dorrar.find(x => x.id === "ut_n");
    gaTill("stallinne", { x: dd.pos[0], y: dd.pos[1], rikt: 0 });
    const fri = (dx, dy) => { let s = 0;
      for (; s < 4; s += 0.1) {
        const [kx, ky] = vandringKollision(dd.pos[0] + dx * s, dd.pos[1] + dy * s, GA.radie, dd.pos[0], dd.pos[1]);
        if (Math.hypot(kx - (dd.pos[0] + dx * s), ky - (dd.pos[1] + dy * s)) > 0.02) break;
      } return +s.toFixed(1); };
    /* Dörrbladets läge ur FASADEN — det ska inte ha flyttat sig. */
    const o = ANL.byggnader.find(b => b.id === "stall").oppningar.find(o => o.sida === "N" && o.typ === "dorrgul");
    return { pos: dd.pos.map(v => +v.toFixed(2)),
      dorrX: +(STALL_BREDD - o.u - o.b / 2).toFixed(2),
      fri: { V: fri(-1, 0), O: fri(1, 0), S: fri(0, -1), N: fri(0, 1) } };
  });
  prova("ankomstpunkten står fritt, inte i ett hörn",
    d.fri.O >= 0.8 && d.fri.N >= 0.8 && d.fri.V >= 0.8 && d.fri.S >= 0.8,
    `fritt V ${d.fri.V} · Ö ${d.fri.O} · S ${d.fri.S} · N ${d.fri.N} m`);
  prova("och dörrbladet sitter kvar där fasaden säger — geometrin är orörd",
    Math.abs(d.dorrX - 10.5) < 0.01 && Math.abs(d.pos[0] - d.dorrX) <= 1.65,
    `dörr x ${d.dorrX}, ankomst x ${d.pos[0]}`);

  /* GENOM DÖRREN, med riktig rörelse: från ankomstpunkten västerut och
     sedan söderut genom inre entréns öppning ned i tvärgången. */
  let p = await ga("stallinne", d.pos[0], d.pos[1], ["V"], 3000);
  const efterV = p.x;
  for (const k of ["s"]) await page.keyboard.down(k);
  await page.waitForTimeout(9000);
  for (const k of ["s"]) await page.keyboard.up(k);
  await page.waitForTimeout(150);
  p = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2) }));
  prova("från dörren in i stallet: förbi klubbdelens tvärvägg (y 57,45)",
    p.y < 57.0, `väster till x ${efterV}, sedan söderut till y ${p.y}`);

  /* Och tillbaka ut: norrut från tvärgången upp till dörrens rum. */
  p = await ga("stallinne", 4.6, 55.5, ["N"], 9000);
  prova("och tillbaka ut igen: norrut genom samma öppning",
    p.y > 60.0, `hamnade y ${p.y}`);
}

/* ══ 4. INGEN KONTINUERLIG BRUSAMBIENS ═════════════════════════════ */
{
  const l = await page.evaluate(() => {
    ljudInit();
    if (typeof ljudPuls === "function") ljudPuls(1 / 60);
    return { flagga: LJUD.ambiens, typ: LJUD.ambTyp, kalla: !!LJUD.ambKalla, pa: LJUD.pa };
  });
  prova("brusambiensen är av som default", l.flagga === false,
    `LJUD.ambiens ${l.flagga}`);
  prova("och ingen loopad brusbädd startas av pulsen",
    l.typ === null && l.kalla === false,
    `ambTyp ${l.typ}, källa ${l.kalla}`);
  prova("men ljudet i övrigt är fortfarande på (M styr det)", l.pa === true,
    `LJUD.pa ${l.pa}`);
}

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `\n${fel} FEL` : `\nALLA OK (${resultat.length} mätningar)`);
process.exit(fel ? 1 : 0);
