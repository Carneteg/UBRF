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
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
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
/* Går tills något AVGÖR vandringen, inte i ett fast antal sekunder.

   Huvudloopen klampar dt till 0,05 s (game.js), så under 20 bilder/s
   går spelet i slow motion. En sträcka mätt per vägguret blir därför
   ett mått på maskinens bildfrekvens — CI:s swiftshader hann kortare
   än den lokala körningen och rundade av grinden till FEL på 0,5 m.
   Provet ska mäta GEOMETRIN: gick figuren igenom, eller stod den
   still mot en solid linje? Därför hålls tangenten tills målet är
   nått eller tills figuren har stått stilla i 0,6 s. */
async function ga(scen, x, y, hall, framme, maxMs = 20000) {
  await page.evaluate(({ scen, x, y }) => gaTill(scen, { x, y, rikt: 0 }), { scen, x, y });
  await page.waitForTimeout(250);
  for (const h of hall) await page.keyboard.down(TANGENT[h]);
  const las = () => page.evaluate(() => ({ x: +VD.px.toFixed(2), y: +VD.py.toFixed(2) }));
  /* UPPSTARTEN RÄKNAS INTE SOM STILLASTÅENDE. Räknaren startade förut
     direkt, så en figur som ännu inte hunnit börja gå — tangenten
     registrerad men ingen bildruta körd — såg ut att stå mot något
     solitt efter 0,6 s. Det gav ett falskt rött på "in i hagen genom
     grinden" med figuren kvar på startpunkten: den hade inte blockerats,
     den hade inte börjat. Provet ska mäta geometrin, inte starten.
     Uppstartsfönstret är ändå ändligt: har inget hänt på 2 s räknas
     stillastående även utan att figuren rört sig, så en verkligt
     blockerad figur avgörs snabbt. */
  let p = await las(), stilla = 0, t = 0, nadde = false, rort = false;
  while (t < maxMs) {
    await page.waitForTimeout(200); t += 200;
    const q = await las();
    const flyttad = Math.hypot(q.x - p.x, q.y - p.y) >= 0.02;
    if (flyttad) rort = true;
    if (!flyttad && (rort || t >= 2000)) stilla += 200; else stilla = 0;
    p = q;
    if (framme(p)) { nadde = true; break; }
    if (stilla >= 600) break;          /* står mot något solitt */
  }
  for (const h of hall) await page.keyboard.up(TANGENT[h]);
  await page.waitForTimeout(150);
  return Object.assign(await las(), { nadde, stod: stilla >= 600, sek: +(t / 1000).toFixed(1) });
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
  let p = await ga("gard", gx - 4, gy, ["O"], q => q.x > gx + 1.0);
  prova("in i hagen genom grinden (utifrån, österut)", p.x > gx + 1.0,
    `hamnade x ${p.x} efter ${p.sek} s (grinden x ${gx}, hagen börjar ${g.hage.x})`);

  /* Och ut igen samma väg. */
  p = await ga("gard", gx + 4, gy, ["V"], q => q.x < gx - 1.0);
  prova("ut ur hagen genom grinden (inifrån, västerut)", p.x < gx - 1.0,
    `hamnade x ${p.x} efter ${p.sek} s (grinden x ${gx})`);

  /* NEGATIV KONTROLL: staketet ska fortfarande vara tätt bredvid
     grinden. Utan den här raden hade "grinden funkar" också blivit
     grönt av att hela staketet slutat kollidera. Här är det STOPPET
     som är beviset — figuren ska stå still mot linjen, inte bara ha
     hunnit kort. */
  p = await ga("gard", gx - 4, gy + 6, ["O"], q => q.x > gx + 1.0);
  prova("staketet är TÄTT 6 m norr om grinden (negativ kontroll)",
    p.stod && !p.nadde && p.x < gx - 0.2,
    `stod stilla ${p.stod} på x ${p.x}, stoppad före staketlinjen x ${gx}`);
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

  /* ── END-TO-END: NY SESSION → TILLDELNING → UPPGIFTSTEXT → HÄSTEN ──
     Tobias produkttest 2026-09-06, blocker 2: han fick fortfarande
     "Hämta Bränntomts Lydia i hagen". Att sätta hastPlats="box" vid
     dagens start räckte inte — `tilldelaHast()` i scenes.js satte
     `G.hamtad=false` direkt efteråt, och den gamla skrivvyn översatte
     det till "hage". Provet går hela vägen: ny session, riktig
     tilldelning, och LÄSER uppgiftstexten produktionen renderar. */
  const e2e = await page.evaluate(() => {
    startaVandring();
    /* Samma väg som ridläraren: den riktiga tilldelningsfunktionen. */
    visaTilldelning();
    if (typeof overlay === "function") overlay(false);
    const namn = G.hastId ? HORSES[G.hastId].namn : null;
    /* Uppgiftstexten ur produktionen, inte ur en kopia av villkoret. */
    ritaVandring();
    const rubrik = document.getElementById("momentNamn");
    const under = document.getElementById("momentText");
    return { plats: G.hastPlats, hastId: G.hastId, namn,
      rubrik: rubrik ? rubrik.textContent : null,
      under: under ? under.textContent : null,
      /* Står hon samtidigt i hagen? Det ritade läget ska följa platsen. */
      iHage: ANL.hagar.some(hg => hg.hastar.includes(G.hastId)) && G.hastPlats === "hage" };
  });
  prova("efter tilldelning står hästen fortfarande i boxen",
    e2e.plats === "box", `hastPlats "${e2e.plats}" (${e2e.namn})`);
  prova("uppgiftstexten säger INTE hagen",
    !!e2e.rubrik && !/hagen/i.test(e2e.rubrik) && !/hagens|grinden/i.test(e2e.under || ""),
    `"${e2e.rubrik}" · "${e2e.under}"`);
  prova("och hästen är inte samtidigt utritad i hagen",
    e2e.iHage === false, `iHage ${e2e.iHage}`);

  /* De gamla namnen går inte längre att SKRIVA — det var så hageflödet
     kunde väljas bakvägen. */
  const skydd = await page.evaluate(() => {
    const ut = {};
    for (const namn of ["hamtad", "leder"]) {
      try { G[namn] = false; ut[namn] = "skrev utan fel"; }
      catch (e) { ut[namn] = "kastade"; }
    }
    return { ...ut, plats: G.hastPlats };
  });
  prova("gamla booleanerna går inte att skriva förbi platssanningen",
    skydd.hamtad === "kastade" && skydd.leder === "kastade" && skydd.plats === "box",
    `hamtad: ${skydd.hamtad} · leder: ${skydd.leder} · hastPlats "${skydd.plats}"`);

  /* ── FÖRSTA ORDINARIE DAGEN ÄR JACKS ─────────────────────────────
     Produktbeslut 2026-09-07, docs/FIRST-DAY-HORSE.md. Provet går genom
     den riktiga `visaTilldelning()`, inte genom en kopia av villkoret,
     och kontrollerar BÅDA halvorna: första ordinarie passet ger Jack,
     senare ordinarie pass ger rotationen tillbaka. Ett prov som bara
     provade den första halvan hade varit grönt även om villkoret
     tillämpades på varenda dag. */
  const jack = await page.evaluate(() => {
    SPAR.pass = 0; G.tavling = null; G.seed = 1;
    startaVandring(); visaTilldelning();
    const forsta = G.hastId;
    const motiv = (document.getElementById("sheet") || {}).textContent || "";
    overlay(false);

    /* Samma dag, men spelaren ber om en annan häst: valet är ett
       produktbeslut, inte en slump som får rullas bort. */
    G.seed++; visaTilldelning(); overlay(false);
    const efterAnnan = G.hastId;

    /* Ett SENARE ordinarie pass — rotationen ska vara tillbaka. Vilken
       häst det blir är rotationens sak; provet kräver bara att den inte
       är låst och att hästen kommer ur poolen. */
    SPAR.pass = 3; G.seed = 1;
    startaVandring(); visaTilldelning(); overlay(false);
    const senare = G.hastId;
    const pool = hastpool(G.grupp);

    /* Tävlingsdag styrs av tävlingslogiken, även på pass 0. */
    SPAR.pass = 0; G.tavling = { typ: "hoppning", klass: { namn: "test" } };
    G.seed = 1; visaTilldelning(); overlay(false);
    const tavling = G.hastId;
    G.tavling = null; SPAR.pass = 0;
    return { forsta, efterAnnan, senare, tavling,
      iPool: pool.includes(senare), jackIPool: pool.includes("blackrock_jack"),
      motivOk: /f\u00f6rsta dag/i.test(motiv) };
  });
  prova("första ordinarie dagen tilldelas Blackrock Jack",
    jack.forsta === "blackrock_jack", `fick "${jack.forsta}"`);
  prova("och den står fast när spelaren ber om en annan häst",
    jack.efterAnnan === "blackrock_jack", `fick "${jack.efterAnnan}"`);
  prova("ett senare ordinarie pass går tillbaka till rotationen",
    jack.senare !== "blackrock_jack" && jack.iPool === true,
    `fick "${jack.senare}" · ur poolen ${jack.iPool}`);
  prova("Jack ligger utanför gruppoolen — rotationen är oförändrad",
    jack.jackIPool === false, `jack i poolen: ${jack.jackIPool}`);
  prova("tävlingsdagen styrs fortfarande av tävlingslogiken",
    jack.tavling !== "blackrock_jack", `fick "${jack.tavling}"`);
  prova("ridläraren säger inte 'rid som du red senast' på dag ett",
    jack.motivOk === true, `första-dags-motivering hittad: ${jack.motivOk}`);

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

/* ══ 2b. INSTRUKTIONEN OCH MARKÖREN (PO-order 2026-09-06) ══════════
   "Nästa handling ska vara självklar utan att spelaren behöver gissa.
   Objekt/NPC/häst som en aktiv uppgift syftar på ska kunna identifieras
   visuellt, och texten ska alltid spegla faktisk runtime-state." */
{
  /* 1. INGEN hageinstruktion när hästen står i boxen — och provet läser
        ALLA texter, inte bara uppgiftspanelen. Det var ridlärarens
        dialogruta som fortfarande skickade Tobias till hagen. */
  const t = await page.evaluate(() => {
    startaVandring(); visaTilldelning(); overlay(false);
    const a = hastAnvisning();
    ritaVandring();
    const rubrik = document.getElementById("momentNamn").textContent;
    const under = document.getElementById("momentText").textContent;
    /* Ridlärarens knapp och whiteboardens rad, ur produktionen. */
    visaTilldelning();
    const knapp = document.getElementById("bGroom");
    const knapptext = knapp ? knapp.textContent : null;
    overlay(false);
    return { plats: G.hastPlats, anvisning: a, rubrik, under, knapptext };
  });
  const allaTexter = [t.rubrik, t.under, t.knapptext,
    t.anvisning.vart, t.anvisning.hur, t.anvisning.kort].join(" | ");
  prova("hastPlats=box ger ingen hageinstruktion någonstans",
    t.plats === "box" && !/hage|grind/i.test(allaTexter), allaTexter);
  prova("och instruktionen pekar uttryckligen på boxen",
    /box|stallet/i.test(t.anvisning.vart + t.anvisning.hur),
    `"${t.anvisning.vart}" · "${t.anvisning.hur}"`);

  /* 2. Markören sitter på RÄTT häst — och bara på den. */
  const m = await page.evaluate(() => {
    startaVandring(); visaTilldelning(); overlay(false);
    const b = hittaBox(G.hastId);
    /* Ställ spelaren långt från boxen så markören är på full styrka. */
    gaTill("stallinne", { x: b.dorr[0], y: Math.max(2, b.dorr[1] - 12), rikt: 0 });
    const mk = uppgiftsMarkor();
    /* En ANNAN häst i rostern ska inte ha markören. */
    const annan = Object.keys(HORSES).find(id => id !== G.hastId);
    return { min: G.hastId, mk, annan, sammaSomMin: mk && mk.hastId === G.hastId,
      annanFar: mk && mk.hastId === annan };
  });
  prova("markören sitter på den tilldelade hästen",
    !!m.mk && m.sammaSomMin === true && m.mk.synlig === true,
    `${m.min} · alfa ${m.mk && m.mk.alfa.toFixed(2)} på ${m.mk && m.mk.avstand.toFixed(1)} m`);
  prova("och inte på någon annan häst",
    m.annanFar === false, `annan häst i rostern: ${m.annan}`);

  /* RENDERARENS EGET BESLUT, inte bara tillståndet. Provet ovan läste
     `uppgiftsMarkor()`; mutationen "markören sätts på alla hästar"
     ändrade renderarens jämförelse och gav då NOLL röda. Nu frågas
     samma predikat som ritkoden frågar. */
  const r = await page.evaluate(() => {
    const b = hittaBox(G.hastId);
    gaTill("stallinne", { x: b.dorr[0], y: Math.max(2, b.dorr[1] - 12), rikt: 0 });
    const andra = Object.keys(HORSES).filter(id => id !== G.hastId).slice(0, 6);
    return { min: markorGallerFor(G.hastId),
      andra: andra.map(id => markorGallerFor(id)),
      tom: markorGallerFor(null) };
  });
  prova("renderarens predikat gäller BARA den tilldelade hästen",
    r.min === true && r.andra.every(v => v === false) && r.tom === false,
    `min ${r.min} · sex andra ${JSON.stringify(r.andra)} · tom ${r.tom}`);

  /* 3. Markören tonas ned när spelaren kommit fram. */
  const f = await page.evaluate(() => {
    const b = hittaBox(G.hastId);
    const las = (dy) => { gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1] - dy, rikt: 0 });
      const mk = uppgiftsMarkor(); return mk ? +mk.alfa.toFixed(2) : null; };
    return { langt: las(8), mitten: las(4), nara: las(1.0) };
  });
  prova("markören tonas ned ju närmare spelaren kommer",
    f.langt === 1 && f.mitten > 0 && f.mitten < 1 && f.nara === 0,
    `8 m → ${f.langt} · 4 m → ${f.mitten} · 1 m → ${f.nara}`);

  /* 4. Och den försvinner när uppgiften gått vidare — hjälpen ska vara
        kontextuell, inte ett konstant tutorialskelett. */
  /* Utgångsläget sätts UTTRYCKLIGEN: markören hör till uppdragssteget
     "hitta hästen", inte till hästens plats. Provet läste förut bara
     `uppgiftsMarkor()` med det tillstånd som råkade ligga kvar från
     vandringarna ovan — och när uppdraget hunnit vidare till
     sadelkammaren var markören (helt riktigt) borta, vilket såg ut som
     ett fel i markören. Varje rad nedan säger nu vilket steg den mäter. */
  const v = await page.evaluate(() => {
    G.hastMott = false; G.skotselRes = null; G.hastPlats = "box";
    const utan = !!uppgiftsMarkor();                    // steg: hitta hästen
    G.hastMott = true;  const utrustning = !!uppgiftsMarkor(); // steg: hämta sadel
    G.hastMott = false; G.hastPlats = "leds";
    const leds = !!uppgiftsMarkor();
    G.hastPlats = "box"; G.skotselRes = { klart: true };
    const skott = !!uppgiftsMarkor();
    G.skotselRes = null; G.hastMott = false;
    return { utan, utrustning, leds, skott };
  });
  prova("markören sitter på hästen bara när uppgiften ÄR hästen",
    v.utan === true && v.utrustning === false && v.leds === false && v.skott === false,
    `hitta hästen ${v.utan} · hämta sadel ${v.utrustning} · leds ${v.leds} · skött ${v.skott}`);
  await page.evaluate(() => { startaVandring(); G.vy = "2d"; });
}

/* ══ 3b. DÖRRÖPPNING MOT SOLID INNERVÄGG ═══════════════════════════
   Tobias produkttest 2026-09-06: den renderade stalldörren sitter tätt
   mot en innervägg. Provet MÄTER det i geometrin i stället för att
   bedöma en skärmbild: för varje ytterdörr i stallets norra gavel, hur
   nära ligger närmaste solida innervägg dörröppningens kant?

   Raden är avsiktligt en MÄTNING med en deklarerad känd avvikelse och
   inte ett tyst godkännande: entrédörren ligger 0,13 m från teorisalens
   västvägg, och vilken av de två källorna som är fel är ett
   produktbeslut (se PR #87). Blir avståndet MINDRE — alltså överlapp —
   ska provet falla. */
{
  const g = await page.evaluate(() => {
    const hus = ANL.byggnader.find(b => b.id === "stall");
    const S = STALLINNE;
    const ut = [];
    for (const o of hus.oppningar.filter(o => o.sida === "N" && /^dorr/.test(o.typ))) {
      const x0 = S.bredd - o.u - o.b, x1 = S.bredd - o.u;
      let narmast = Infinity, vem = null;
      for (const v of S.klubb.vaggar) {
        if (v.typ !== "langs") continue;
        /* Bara väggar som faktiskt möter norra gaveln. */
        if (v.y1 < S.langd - 0.2) continue;
        const d = v.x >= x1 ? v.x - x1 : (v.x <= x0 ? x0 - v.x : -1);
        if (d < narmast) { narmast = d; vem = v.id; }
      }
      ut.push({ typ: o.typ, x0: +x0.toFixed(2), x1: +x1.toFixed(2),
        avstand: +narmast.toFixed(2), vagg: vem });
    }
    return ut;
  });
  for (const d of g) {
    prova(`dörröppningen ${d.typ} överlappar ingen solid innervägg`,
      d.avstand >= 0, `x ${d.x0}–${d.x1}, närmast ${d.vagg} på ${d.avstand} m`);
  }
  const entre = g.find(d => d.typ === "dorrgul");
  prova("[KÄND KÄLLMOTSÄGELSE, PO-FRÅGA] entrédörren står 0,13 m från teorisalens västvägg",
    !!entre && Math.abs(entre.avstand - 0.13) < 0.02,
    `fasadens dorrgul x ${entre && entre.x0}–${entre && entre.x1} mot ` +
    `PLAN:stall-plan1-utrymning-rak.jpg#linje-x11.2 — se PR #87`);
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
