#!/usr/bin/env node
/* UPPDRAGSTEST — PO-ordern 2026-09-06 (acceptance A–F).

   Provar objective/navigation-systemet och att uppsittningen går att nå
   genom HELA produktionsvägen. Vandringen sker med spelets egen
   vägsökning (gå-hit) och interaktionerna med E — inga genvägar förbi
   kollisionen, för det var precis där felet satt: uppsittningen var
   aldrig trasig, spelaren kom bara aldrig fram till den.

   Kör: python3 tools/build.py && node tools/uppdragstest.mjs */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const PORT = +(process.env.PORT || 8794);
const MIME = { ".html":"text/html", ".js":"text/javascript", ".css":"text/css",
  ".png":"image/png", ".jpg":"image/jpeg", ".json":"application/json" };
const srv = http.createServer((req, res) => {
  const p = path.join(DIST, decodeURIComponent(req.url.split("?")[0] === "/" ? "/index.html" : req.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" }); res.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on("pageerror", e => console.log("PAGEERROR", e.message));
await page.goto(`http://localhost:${PORT}/ridskolan.html`, { waitUntil: "load" });
await page.waitForTimeout(1500);
const ev = (f, a) => page.evaluate(f, a);
const resultat = [];
function prova(namn, ok, detalj) { resultat.push({ namn, ok });
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); }

await ev(() => { startaVandring(); G.vy = "2d"; });
await page.waitForTimeout(400);

/* ══ A. PLATS OCH PRONOMEN UR RUNTIME-DATAN ════════════════════════ */
{
  const a = await ev(() => {
    startaVandring(); visaTilldelning(); overlay(false);
    const h = HORSES[G.hastId];
    const u = uppdragText();
    const anv = hastAnvisning();
    /* Varje yta som säger något om var hästen står. */
    const ytor = [u.rubrik, ...u.punkter, anv.vart, anv.hur, anv.kort];
    return { plats: G.hastPlats, namn: h.namn, ytor,
      pronomen: h.pronomen, hanKalla: HORSES.toblerone.pronomen,
      pron: { subj: hastPron(G.hastId, "subj"), obj: hastPron(G.hastId, "obj"),
        poss: hastPron(G.hastId, "poss") },
      tobl: { subj: hastPron("toblerone", "subj"), obj: hastPron("toblerone", "obj") } };
  });
  prova("hastPlats=box och ingen yta säger hagen",
    a.plats === "box" && !a.ytor.some(t => /hage/i.test(t || "")),
    `${a.ytor.map(t => JSON.stringify(t)).join(" · ")}`);

  /* Lydias kön står INTE i källtexten. Då får inget pronomen hittas på —
     namnet bär meningen i stället. Det var "honom" om Lydia som föll i
     produkttestet. */
  const pronOrd = /\b(han|hon|honom|henne|hans|hennes)\b/i;
  prova("ingen text om hästen använder ett gissat pronomen",
    a.pronomen.kalla === "REFERENCE_GAP" && !a.ytor.some(t => pronOrd.test(t || "")),
    `${a.namn}: pronomenkälla ${a.pronomen.kalla} · hastPron ger "${a.pron.subj}" / "${a.pron.obj}"`);

  /* Och där källan FAKTISKT säger det används pronomenet — annars vore
     regeln bara "skriv aldrig han", inte "läs ur datan". */
  prova("men där källtexten säger det används pronomenet ur datan",
    a.tobl.subj === "han" && a.tobl.obj === "honom" && a.hanKalla.kalla === "besk",
    `Toblerone (valack i källtexten): "${a.tobl.subj}" / "${a.tobl.obj}"`);

  const w = await ev(() => {
    const b = hittaBox(G.hastId);
    gaTill("stallinne", { x: b.dorr[0], y: Math.max(2, b.dorr[1] - 10), rikt: 0 });
    const v = uppdragVagvisare();
    return { v, box: b.dorr, avv: v ? Math.hypot(v.pos[0]-b.dorr[0], v.pos[1]-b.dorr[1]) : null };
  });
  prova("vägvisaren pekar på RÄTT box, inte på en egen punkt",
    !!w.v && w.v.iScen === true && w.avv < 0.01,
    `vägvisare [${w.v.pos.map(n=>n.toFixed(2))}] mot boxdörren [${w.box.map(n=>n.toFixed(2))}]`);
}

/* ══ A2. RUTNÄTET SLÄPPER IGENOM STALLETS DÖRRÖPPNINGAR ════════════
   Mätt DIREKT på vägsökningen, inte via en vandring. Falsifieringen
   "rutnätets gamla provradie" gav noll röda när provet bara gick
   sträckan: raka linjen plus glidningen längs väggen tog sig fram ändå
   den gången. Ett prov som inte kan se skillnad på "det finns en väg"
   och "figuren råkade glida rätt" bevisar ingenting om vägsökningen.
   Här frågas navVag rakt ut, och rutorna i öppningarna räknas. */
{
  const n = await ev(() => {
    gaTill("stallinne", { x: 5, y: 30, rikt: 0 });
    navRedo();
    const ut = STALLINNE.dorrar.find(d => d.mot === "gard").pos;
    const vag = navVag(5, 30, ut[0], ut[1]);
    /* Fria rutor i de två öppningarna i genomgående väggen (y 57,45). */
    const vagg = STALLINNE.klubb.vaggar.find(v => v.id === "genomgaende");
    const oppningar = vagg.oppningar.map(o => {
      let fria = 0;
      for (let x = o.x0; x <= o.x1; x += 0.05) {
        const [i, j] = navIx(x, vagg.y);
        if (NAV.fri[j * NAV.nx + i]) { fria++; }
      }
      return { id: o.id, bredd: +(o.x1 - o.x0).toFixed(2), fria };
    });
    return { harVag: !!vag, punkter: vag ? vag.length : 0, oppningar };
  });
  prova("rutnätet har en väg från stallgången ut genom klubbdelen",
    n.harVag === true,
    `navVag ${n.harVag ? `gav ${n.punkter} punkter` : "gav NULL — ingen väg alls"}`);
  prova("och båda dörröppningarna i genomgående väggen har fria rutor",
    n.oppningar.every(o => o.fria > 0),
    n.oppningar.map(o => `${o.id} ${o.bredd} m → ${o.fria > 0 ? "fri" : "SPÄRRAD"}`).join(" · "));
}

/* ══ B–C. KEDJAN GÅR VIDARE AV SIG SJÄLV ═══════════════════════════ */
{
  const kedja = await ev(() => {
    const steg = [];
    startaVandring(); visaTilldelning(); overlay(false);
    const b = hittaBox(G.hastId);
    gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1] - 10, rikt: 0 });
    steg.push({ id: uppdragMal().id, mal: uppdragMal().mal.pos.slice() });
    /* 1. Spelaren går fram till boxen — mötet är att STÅ där. */
    VD.px = b.dorr[0]; VD.py = b.dorr[1] - 1.5; interagera();
    steg.push({ id: uppdragMal().id, mal: uppdragMal().mal.pos.slice() });
    /* 2. Utrustningen hämtas. */
    G.utrustning = true;
    steg.push({ id: uppdragMal().id, mal: uppdragMal().mal.pos.slice() });
    /* 3. Skötseln klar och hästen leds. */
    G.skotselRes = { dagsform: 0.7 }; G.hastPlats = "leds";
    steg.push({ id: uppdragMal().id, mal: uppdragMal().mal.pos.slice() });
    const sk = (STALLINNE.info || []).find(i => i.sadelkammare);
    const sp = SPELABSTRAKTIONER.ridhus.sargport;
    return { steg, box: b.dorr, sadelkammare: sk.pos,
      sarg: [(sp.x0+sp.x1)/2, RIDHUSINNE.bana.y + RIDHUSINNE.bana.h] };
  });
  const [s0, s1, s2, s3] = kedja.steg;
  prova("kedjan: hitta hästen → hämta utrustning → tillbaka till hästen → sitt upp",
    s0.id === "hitta_hast" && s1.id === "utrustning" && s2.id === "skotsel" && s3.id === "sitt_upp",
    kedja.steg.map(s => s.id).join(" → "));
  prova("och varje steg pekar på den VERIFIERADE punkten, inte på en påhittad",
    Math.hypot(s0.mal[0]-kedja.box[0], s0.mal[1]-kedja.box[1]) < 0.01 &&
    Math.hypot(s1.mal[0]-kedja.sadelkammare[0], s1.mal[1]-kedja.sadelkammare[1]) < 0.01 &&
    Math.hypot(s2.mal[0]-kedja.box[0], s2.mal[1]-kedja.box[1]) < 0.01 &&
    Math.hypot(s3.mal[0]-kedja.sarg[0], s3.mal[1]-kedja.sarg[1]) < 0.01,
    `box [${kedja.box.map(n=>n.toFixed(1))}] · sadelkammaren [${kedja.sadelkammare.map(n=>n.toFixed(1))}] · sargporten [${kedja.sarg.map(n=>n.toFixed(1))}]`);
}

/* ══ E. ETT MÅL, OCH VÄGVISAREN TONAS BORT NÄRA ════════════════════ */
{
  const e = await ev(() => {
    startaVandring(); visaTilldelning(); overlay(false);
    const b = hittaBox(G.hastId);
    const las = dy => { gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1] - dy, rikt: 0 });
      const v = uppdragVagvisare(); const mk = uppgiftsMarkor();
      return { alfa: +v.alfa.toFixed(2), nara: v.nara, markor: mk ? mk.nara : null }; };
    const langt = las(9), mitten = las(5), nara = las(1.2);
    gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1] - 9, rikt: 0 });
    const andra = Object.keys(HORSES).filter(id => id !== G.hastId).slice(0, 6);
    return { langt, mitten, nara, min: markorGallerFor(G.hastId),
      andra: andra.map(id => markorGallerFor(id)), tom: markorGallerFor(null) };
  });
  prova("vägvisaren tonas bort när man är framme — då tar den lokala markören över",
    e.langt.alfa === 1 && e.mitten.alfa > 0 && e.mitten.alfa < 1 &&
    e.nara.alfa === 0 && e.nara.nara === true && e.nara.markor === true,
    `9 m → ${e.langt.alfa} · 5 m → ${e.mitten.alfa} · 1,2 m → ${e.nara.alfa} (nära ${e.nara.nara}, lokal markör ${e.nara.markor})`);
  prova("bara ETT mål är markerat — inte flera konkurrerande hästar",
    e.min === true && e.andra.every(v => v === false) && e.tom === false,
    `min ${e.min} · sex andra ${JSON.stringify(e.andra)} · tom ${e.tom}`);
}

/* ══ F. TEXTEN ÄR SKANNBAR ═════════════════════════════════════════ */
{
  const f = await ev(() => {
    const lagen = [];
    const las = () => { const u = uppdragText();
      lagen.push({ id: u.id, rubrik: u.rubrik, punkter: u.punkter }); };
    startaVandring(); las();                                  // ridläraren
    visaTilldelning(); overlay(false);
    const b = hittaBox(G.hastId);
    gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1] - 8, rikt: 0 }); las();
    VD.px = b.dorr[0]; VD.py = b.dorr[1] - 1.5; interagera(); las();
    G.utrustning = true; las();
    G.skotselRes = { dagsform: 0.7 }; G.hastPlats = "leds"; las();
    return lagen;
  });
  const langst = f.reduce((m, l) => Math.max(m, l.rubrik.length), 0);
  const flest = f.reduce((m, l) => Math.max(m, l.punkter.length), 0);
  const langstPunkt = f.reduce((m, l) => Math.max(m, ...l.punkter.map(p => p.length)), 0);
  prova("uppgiftstexten är en kort rubrik och 1–3 punkter, aldrig ett stycke",
    langst <= 40 && flest >= 1 && flest <= 3 && langstPunkt <= 62,
    `${f.length} lägen · längsta rubrik ${langst} tkn · flest punkter ${flest} · längsta punkt ${langstPunkt} tkn`);
  prova("och varje läge har en egen rubrik — ingen står kvar från förra steget",
    new Set(f.map(l => l.id)).size === f.length,
    f.map(l => `${l.id}: "${l.rubrik}"`).join(" · "));
}

/* ══ D. HELA PRODUKTIONSVÄGEN, GÅENDE, ÄNDA IN I RIDLÄGE ═══════════ */
{
  const TANGENT = { N:"w", S:"s", O:"d", V:"a" };
  async function gaHit(mal, namn, maxMs = 150000) {
    await ev(({ m }) => { satMal(m[0], m[1]); }, { m: mal });
    let p = await ev(() => ({ x: VD.px, y: VD.py })), stilla = 0, t = 0;
    while (t < maxMs) {
      await page.waitForTimeout(250); t += 250;
      const q = await ev(() => ({ x: VD.px, y: VD.py }));
      if (Math.hypot(q.x - p.x, q.y - p.y) < 0.03) stilla += 250; else stilla = 0;
      p = q;
      if (Math.hypot(p.x - mal[0], p.y - mal[1]) < 1.3) break;
      if (stilla >= 1200) break;
    }
    return { p, d: Math.hypot(p.x - mal[0], p.y - mal[1]) };
  }
  async function tryckE() { await page.keyboard.down("e"); await page.waitForTimeout(80);
    await page.keyboard.up("e"); await page.waitForTimeout(400); }
  const prompt = () => ev(() => { interagera(); return VD.prompt ? VD.prompt.text : null; });

  await ev(() => { startaVandring(); G.vy = "2d";
    const d = ANL.dorrar.find(d => d.mot === "stallinne"); gaTill("stallinne", d.spawn); });
  await page.waitForTimeout(400);

  const steg = [];
  await gaHit(await ev(() => STALLINNE.ridlarare.pos), "ridläraren");
  steg.push(["ridläraren", await prompt()]);
  await tryckE();
  await ev(() => { const b = document.getElementById("bGroom"); if (b) b.click(); });
  await page.waitForTimeout(300);

  const box = await ev(() => hittaBox(G.hastId).dorr);
  await gaHit(box, "boxen");
  steg.push(["boxen", await prompt()]);

  await gaHit(await ev(() => (STALLINNE.info || []).find(i => i.sadelkammare).pos), "sadelkammaren");
  steg.push(["sadelkammaren", await prompt()]);
  await tryckE();
  await ev(() => { const n = HORSES[G.hastId].namn;
    for (const b of document.querySelectorAll("button")) if (b.textContent.trim() === n) b.click(); });
  await page.waitForTimeout(150);
  await ev(() => { const b = document.getElementById("bSkKlar"); if (b) b.click(); });
  await page.waitForTimeout(300);

  await gaHit(box, "boxen igen");
  steg.push(["boxen igen", await prompt()]);
  await tryckE();
  await ev(() => { const b = document.getElementById("bSkots"); if (b) b.click(); });
  await page.waitForTimeout(700);
  await ev(() => { const b = document.getElementById("bKlar"); if (b) b.click(); });
  await page.waitForTimeout(1100);
  await ev(() => { const b = document.getElementById("bLek"); if (b) b.click(); });
  await page.waitForTimeout(400);

  await gaHit(await ev(() => STALLINNE.dorrar.find(d => d.mot === "gard").pos), "stallets utdörr");
  const utPrompt = await prompt();
  steg.push(["stallets utdörr", utPrompt]);
  if (utPrompt) await tryckE();
  prova("vägen UT ur stallet med hästen vid handen finns (root cause för uppsittningen)",
    await ev(() => G.scen === "gard"),
    `prompt vid utdörren: ${JSON.stringify(utPrompt)} · scen ${await ev(() => G.scen)}`);

  if (await ev(() => G.scen === "gard")) {
    await gaHit(await ev(() => ANL.dorrar.find(d => d.mot === "ridhusinne").pos), "ridhusdörren", 240000);
    steg.push(["ridhusdörren", await prompt()]);
    if (await prompt()) await tryckE();
  }
  let sittUppPrompt = null;
  if (await ev(() => G.scen === "ridhusinne")) {
    await gaHit(await ev(() => { const sp = SPELABSTRAKTIONER.ridhus.sargport;
      return [(sp.x0 + sp.x1) / 2, RIDHUSINNE.bana.y + RIDHUSINNE.bana.h]; }), "sargporten", 120000);
    sittUppPrompt = await prompt();
    steg.push(["sargporten", sittUppPrompt]);
    if (sittUppPrompt) await tryckE();
  }
  const slut = await ev(() => ({ scen: G.scen, uppsutten: typeof ridUppsutten === "function" ? ridUppsutten() : null }));
  prova("E vid sargporten monterar efter korrekt förberedelse — hela vägen in i ridläge",
    slut.scen === "lektion" && /sitt upp/i.test(sittUppPrompt || ""),
    `prompt ${JSON.stringify(sittUppPrompt)} → scen "${slut.scen}"`);
  prova("och varje steg på vägen hade en interaktion att trycka E på",
    steg.every(([, p]) => !!p),
    steg.map(([n, p]) => `${n}: ${p ? "ja" : "INGEN"}`).join(" · "));
}

console.log("");
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : `ALLA OK (${resultat.length} mätningar)`);
await browser.close(); srv.close();
process.exit(fel ? 1 : 0);
