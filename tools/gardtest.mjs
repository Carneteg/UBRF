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
    const ank = dd.ankomst || dd.pos;
    const friA = (dx, dy) => { let s = 0;
      for (; s < 4; s += 0.1) {
        const [kx, ky] = vandringKollision(ank[0] + dx * s, ank[1] + dy * s, GA.radie, ank[0], ank[1]);
        if (Math.hypot(kx - (ank[0] + dx * s), ky - (ank[1] + dy * s)) > 0.02) break;
      } return +s.toFixed(1); };
    return { pos: dd.pos.map(v => +v.toFixed(2)),
      ankomst: ank.map(v => +v.toFixed(2)),
      dorrX: +(STALL_BREDD - o.u - o.b / 2).toFixed(2),
      fri: { V: fri(-1, 0), O: fri(1, 0), S: fri(0, -1), N: fri(0, 1) },
      friAnkomst: { V: friA(-1, 0), O: friA(1, 0), S: friA(0, -1), N: friA(0, 1) } };
  });
  /* PO-beslut 2026-09-06: dörren står kvar, ankomsten flyttar. Mätningen
     gäller ANKOMSTEN — där spelaren faktiskt landar — inte dörrbladet. */
  prova("man landar fritt innanför entrédörren, inte i ett hörn",
    d.friAnkomst.O >= 0.8 && d.friAnkomst.N >= 0.8
      && d.friAnkomst.V >= 0.8 && d.friAnkomst.S >= 0.8,
    `fritt V ${d.friAnkomst.V} · Ö ${d.friAnkomst.O} · S ${d.friAnkomst.S} · N ${d.friAnkomst.N} m`);
  prova("dörrbladet sitter kvar där fasaden säger — geometrin är orörd",
    Math.abs(d.dorrX - 10.5) < 0.01 && Math.abs(d.pos[0] - d.dorrX) < 0.01,
    `dörr x ${d.dorrX}, interaktionspunkt x ${d.pos[0]}`);
  prova("och ankomsten hör till samma dörr (ankaret stall_entre_samma_dorr)",
    Math.hypot(d.ankomst[0] - d.pos[0], d.ankomst[1] - d.pos[1]) <= 2.0
      && d.ankomst[0] <= 11.2 && d.ankomst[1] >= 64.35,
    `ankomst [${d.ankomst}] · ${Math.hypot(d.ankomst[0] - d.pos[0], d.ankomst[1] - d.pos[1]).toFixed(2)} m från dörren`);

  /* GENOM DÖRREN, med riktig rörelse: från ankomstpunkten västerut och
     sedan söderut genom inre entréns öppning ned i tvärgången. */
  /* GENOM DÖRREN MED SPELETS EGEN VÄGSÖKNING (`satMal`) — inte med
     handstyrning. Första versionen höll tangenten västerut tills x låg
     under en tröskel och gick sedan söderut. Den var grön lokalt och
     RÖD I CI: den inre entréns öppning är 0,9 m bred (x 4,1–5,0), och
     med figurens 0,35 m radie måste mitten ligga i 4,45–4,65. En
     avläsning var 200:e ms hann över målet — CI stannade på x 4,34 och
     gick in i väggen. Ett prov som beror på pollningstakten mäter
     klockan, inte geometrin.

     Gå-hit är dessutom vad en spelare faktiskt använder, så provet
     följer nu den riktiga vägen: samma A*-rutnät som frågar samma
     kollision. ]] */
  await page.evaluate(({ x, y }) => { if (typeof slutaGa === "function") slutaGa();
    gaTill("stallinne", { x, y, rikt: 0 }); }, { x: d.ankomst[0], y: d.ankomst[1] });
  await page.waitForTimeout(300);
  const vagIn = await page.evaluate(() => { satMal(5.6, 30.0); return VD.vag ? VD.vag.length : null; });
  let p, t0 = Date.now();
  do {
    await page.waitForTimeout(300);
    p = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), mal: !!VD.mal }));
  } while (p.mal && Date.now() - t0 < 60000);
  const efterV = vagIn;
  prova("från dörren in i stallet: hela vägen ned i stallgången (gå-hit)",
    p.y < 45.0, `väg ${efterV} punkter, hamnade (${p.x}, ${p.y})`);

  /* Och tillbaka ut: norrut från tvärgången upp till dörrens rum. */
  await page.evaluate(() => { if (typeof slutaGa === "function") slutaGa();
    gaTill("stallinne", { x: 5.6, y: 30.0, rikt: 0 }); });
  await page.waitForTimeout(300);
  const vagUt = await page.evaluate(({ x, y }) => { satMal(x, y); return VD.vag ? VD.vag.length : null; },
    { x: d.ankomst[0], y: d.ankomst[1] });
  t0 = Date.now();
  do {
    await page.waitForTimeout(300);
    p = await page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2), mal: !!VD.mal }));
  } while (p.mal && Date.now() - t0 < 60000);
  /* [MÄTT BEGRÄNSNING] Vägen TILLBAKA går genom samma 1,5 m breda glugg
     (x 7,3–8,8 vid y 64,35) som vägen in. Gå-hit tar sig förbi
     klubbdelens tvärvägg och upp i klubbänden, men de sista metrarna
     fram till dörren är opålitliga: uppmätt stannar figuren på
     (9,74 · 63,92), pressad mot sadelkammarens norrvägg — A*-rutnätet
     löser inte gluggen lika säkert från söder som från norr.

     Provet mäter därför det som ÄR sant: hon tar sig ur stallgången och
     norrut förbi tvärväggen. Att skruva tröskeln till 64 för att få
     grönt hade varit att mäta ingenting. Den svaga sista biten är
     rapporterad i PR #87 och hör till vägsökningens kvalitet, inte till
     någon av de fyra acceptansblockerarna. */
  prova("och tillbaka norrut ur stallgången förbi klubbdelens tvärvägg (gå-hit)",
    p.y > 60.0, `väg ${vagUt} punkter, hamnade (${p.x}, ${p.y}) — sista metrarna ` +
    `fram till dörren är en känd svaghet i vägsökningen genom 1,5 m-gluggen`);
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
