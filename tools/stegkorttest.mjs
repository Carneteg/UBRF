/* STEGKORTET — webbens stallflöde som i Roblox, spelat i webbläsaren.

   docs/WEB-P1A-STABLE-FLOW-CONTRACT.md, acceptans 2. Mot dist/ (bygg med
   `python tools/build.py`). Provet sätter bara förutsättningar en spelare
   når på riktigt — en tilldelad häst, ett passnummer, var spelaren står —
   och trycker sedan på panelens egna knappar. Det skriver aldrig i
   förberedelsens tillstånd.

     A. startvalet: exakt två knappar, E = «Rida nu», ingen vänsterruta
     B. «själv»: hela kedjan manuellt till «Sitt upp», dagsform 0,76
     C. «Rida nu»: i ridhuset vid sargporten, dagsform 0,70, E sitter upp
     D. fynddag: frågan, fel svar står kvar, rätt svar stoppar ritten
     E. engelska: ingen svenska i panelen genom hela kedjan
     F. layout: skrivbord 1600×900 och iPad liggande 1180×820

   Körs: node tools/stegkorttest.mjs  (skärmbilder till $STEGKORT_BILDER) */
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8897;
const BILDER = process.env.STEGKORT_BILDER || "";

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
  headless: true,
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

async function oppna(vp = { width: 1600, height: 900 }) {
  const page = await browser.newPage({ viewport: vp });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(600);
  return page;
}

/* En ny dag vid hästens box: passnummer, språk, tilldelning, position.
   Stallflödet (P1a) gäller en ÅTERVÄNDANDE spelare — på pass 0 tar First
   Ride (P1b) över. Utan angivet pass väljs därför det första passet ≥ 1
   där hästen inte har något fynd, ur samma regel som Roblox. */
async function vidBoxen(page, { pass = null, sprak = "sv" } = {}) {
  return page.evaluate(({ pass, sprak }) => {
    window.SPRAKET = sprak;
    const id = valbaraHastar().includes("troy") ? "troy" : valbaraHastar()[0];
    let p = pass;
    if (p === null) { p = 1; while (Forb.fyndFor(id, p + 1)) p++; }
    SPAR.pass = p;
    startaVandring();
    sattAktivHast(id);
    const b = hittaBox(id);
    gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1], rikt: 0 });
    /* Vänta på två riktiga bildrutor: stegkortet ritas i spelloopen, och
       första rutan i en ny scen bygger 3D-världen — med mjukvarurendering
       över en sekund. En fast väntan läste kortet innan det fanns
       (avsnitt A rött 3 av 4 på 39d8919). */
    return new Promise(klar => requestAnimationFrame(() => requestAnimationFrame(
      () => klar({ id, namn: HORSES[id].namn }))));
  }, { pass, sprak });
}
const vanta = page => page.waitForTimeout(250);
const kort = page => page.evaluate(() => {
  const el = document.getElementById("stegkort");
  const knappar = [...el.querySelectorAll(".skV button")].map(b => ({
    id: b.dataset.id, text: b.textContent.trim(), primar: b.classList.contains("primar") }));
  const rader = [...el.querySelectorAll(".skRader button")].map(b => ({ id: b.dataset.id, text: b.textContent.trim() }));
  const tl = document.getElementById("moment").closest(".hudh");
  return { synlig: !el.hidden, id: el.dataset.kort, text: el.innerText, knappar, rader,
    vagvisare: typeof uppdragVagvisare === "function" ? !!uppdragVagvisare() : null,
    fler: !!el.querySelector("button[data-fler]"),
    rubrik: (el.querySelector(".skR") || {}).textContent || "",
    aterkoppling: (el.querySelector(".skA") || {}).textContent || "",
    vansterruta: tl ? getComputedStyle(tl).display !== "none" : false,
    prompt: VD.prompt ? VD.prompt.text : null, scen: G.scen, plats: G.hastPlats,
    dagsform: G.dagsform, redo: G.forb ? Forb.redo(G.forb) : null };
});
async function klicka(page, id) {
  const ok = await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort button")].find(x => x.dataset.id === id);
    if (b) b.click();
    return !!b;
  }, id);
  await vanta(page);
  return ok;
}
/* En promptrad HÅLLS som en Roblox-prompt: pekaren nere i `ms`. */
async function halla(page, id, ms = 500) {
  const ok = await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort .skRader button")].find(x => x.dataset.id === id);
    if (b) b.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));
    return !!b;
  }, id);
  await page.waitForTimeout(ms);
  await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort .skRader button")].find(x => x.dataset.id === id);
    if (b) b.dispatchEvent(new PointerEvent("pointerup", { bubbles: true }));
  }, id);
  await vanta(page);
  return ok;
}
async function tangent(page, kod, ms) {
  await page.keyboard.down(kod); await page.waitForTimeout(ms); await page.keyboard.up(kod);
  await page.waitForTimeout(250);
}
/* Spelaren gör resten själv: den primära knappen, kort för kort, tills
   kortet är `stopp` (ledningen). Hälsningen väljs med första rätta. */
async function gorSjalv(page, stopp = "leda", texter = []) {
  for (let i = 0; i < 60; i++) {
    const k = await kort(page);
    texter.push(k.text);
    if (k.id === stopp || !k.synlig) return k;
    // Hälsningen är handlingar i ordning (UI-2): den primära är nästa, som överallt.
    const val = k.knappar.find(b => b.primar);
    if (val) { await klicka(page, val.id); continue; }
    /* Kort utan momentknapp (hämta sadel/träns): kortets egen prompt. */
    const rad = k.rader.find(r => r.id !== "rad:rida_nu");
    if (!rad) return k;
    await halla(page, rad.id);
  }
  return kort(page);
}

/* ── A + B ───────────────────────────────────────────────────────── */
console.log("\n── A. Startvalet vid hästen ──");
{
  const page = await oppna();
  const h = await vidBoxen(page);
  await vanta(page);
  let k = await kort(page);
  prova("panelen syns vid hästen", k.synlig && k.id === "valj", `kort ${k.id}`);
  prova("rubriken är «Välj hur du börjar»", k.rubrik === "Välj hur du börjar", k.rubrik);
  prova("exakt två knappar: Rida nu / Gör i ordning själv",
    k.knappar.length === 2 && k.knappar[0].text === `Rida nu — ${h.namn}` && k.knappar[1].text === `Gör i ordning ${h.namn} själv`,
    k.knappar.map(b => b.text).join(" / "));
  prova("bara «Rida nu» är primär", k.knappar[0].primar && !k.knappar[1].primar);
  prova("inget «Fler handlingar» på startvalet", !k.fler);
  prova("ingen hälsningsfråga på startvalet", !/bakifrån|Framifrån/.test(k.text));
  prova("E vid hästen är «Rida nu»", k.prompt === `Rida nu — ${h.namn}`, String(k.prompt));
  prova("den gamla vänsterrutan syns inte till fots", !k.vansterruta);
  if (BILDER) await page.screenshot({ path: path.join(BILDER, "startval-1600x900.png") });

  console.log("\n── B. «Gör i ordning … själv» ──");
  await klicka(page, "start:sjalv");
  k = await kort(page);
  /* #273 S2 (T2): EN handling per fas — «Hälsa», inte tre knappar. */
  prova("själv → «Hälsa på …» med EN handling, och den är primär (#273 S2)", k.id === "halsa"
    && k.rubrik === `Hälsa på ${h.namn}` && k.knappar.length === 1 && k.knappar[0].primar
    && k.knappar[0].id === "handling:halsa" && k.knappar[0].text === "Hälsa",
    `${k.rubrik} · ${k.knappar.map(b => b.text).join(" / ")}`);
  prova("boxen finns under «Fler handlingar»", k.fler);
  prova("R1: «Rida nu» står som prompt med «[Håll inne R]», som i Roblox",
    k.rader.some(r => r.id === "rad:rida_nu" && r.text.includes("[Håll inne R]")), k.rader.map(r => r.text).join(" / "));
  /* Ordningsregeln finns kvar i regelmodulen — handen före namnet nekas —
     men den är inte längre tre läs-och-klicka-stopp. Kortet bär EN kort
     rad; de tre detaljmeningarna står ordagrant i kunskapslagret. */
  const regel = await page.evaluate(() => ({
    nej: Forb.provaMoment(G.forb, "halsa", "halsa3", G.hastId),
    detalj: HALSNING.map(x => x.text) }));
  prova("handen före namnet: regeln nekar fortfarande med «fel tur» (#273 S2)",
    regel.nej[0] === false && regel.nej[1] === "forb.fel_tur", JSON.stringify(regel.nej));
  prova("kortet: EN kort rad, ingen av hälsningens tre detaljmeningar (#273 S2)",
    k.text.includes("Hon ska se och höra dig innan du rör henne.") && !regel.detalj.some(t => k.text.includes(t)),
    k.text.replace(/\n/g, " ¦ ").slice(0, 160));
  await page.evaluate(() => document.querySelector("#stegkort button[data-kunskap]").click());
  await vanta(page);
  k = await kort(page);
  prova("«Så gör man» öppnar kunskapslagret med de tre meningarna ordagrant (#273 S2)",
    regel.detalj.length === 3 && regel.detalj.every(t => k.text.includes(t)), k.text.replace(/\n/g, " ¦ ").slice(0, 200));
  await klicka(page, "handling:halsa");
  k = await kort(page);
  const efterHalsa = await page.evaluate(() => ({ ...G.forb.gjorda.halsa }));
  prova("ETT tryck gör hälsningens tre moment som spelarens egna, och kvitterar (#273 S2)",
    efterHalsa.halsa1 === true && efterHalsa.halsa2 === true && efterHalsa.halsa3 === true
      && k.aterkoppling === "✓  Nu vet hon att du är där.", `${JSON.stringify(efterHalsa)} · ${k.aterkoppling}`);
  const foreE = await kort(page);
  await tangent(page, "KeyE", 550);
  const efterE = await kort(page);
  prova("R1: E gör inget skötselmoment — momenten är panelknappar, som i Roblox",
    foreE.id === "visitera" && efterE.id === "visitera" && efterE.rubrik === foreE.rubrik, `${foreE.rubrik} → ${efterE.rubrik}`);
  const texter = [];
  const fore = await page.evaluate(() => ({ kolla: VISITPUNKT.map(p => p.ok), hov: HOVAR.map(x => x.text),
    rykt: RYKTREDSKAP.map(x => x.text), sadel: SADELFAS.map(x => x.t) }));
  k = await gorSjalv(page, "leda", texter);
  const sagda = texter.join("\n");
  /* #273 S2: sex handlingar och två hämtningar fram till ledningen — och
     checklistan är densamma som de 23 klicken gav: varje moment gjort av
     spelaren själv. */
  const lista = await page.evaluate(() => {
    const ut = { egna: 0, totalt: 0, auto: 0 };
    for (const f of Forb.stegFaser()) { if (f.id === "leda") continue;
      for (const m of Forb.moment(f.id)) { if (m.fel) continue; ut.totalt++;
        const g = (G.forb.gjorda[f.id] || {})[m.id];
        if (g === true) ut.egna++; else if (g === "auto") ut.auto++; } }
    return ut; });
  prova("hälsa → kolla → rykta → kratsa → sadla → tränsa: 23 moment gjorda, alla spelarens egna (#273 S2)",
    lista.totalt === 23 && lista.egna === 23 && lista.auto === 0, JSON.stringify(lista));
  /* Hälsningen är redan gjord ovan: kvar är kolla, rykta, kratsa, hämta
     sadeln, sadla, hämta tränset och tränsa — sju kort, sedan ledningen. */
  prova("efter hälsningen: fem handlingar och två hämtningar, sju kort före ledningen (#273 S2)",
    texter.length === 8, `${texter.length - 1} kort före ledningen`);
  prova("inget kort i huvudflödet bär en detaljmening om hovar, mungipor eller gjord (#273 S2)",
    ![...fore.kolla, ...fore.hov, ...fore.rykt, ...fore.sadel].some(t => sagda.includes(t)),
    [...fore.kolla, ...fore.hov, ...fore.rykt, ...fore.sadel].filter(t => sagda.includes(t)).join(" ¦ ") || "inga");
  prova("kedjan går genom alla Roblox-kort i ordning",
    ["Kolla ", "Rykta ", "Kratsa hovarna", "Hämta sadeln", "Lägg på sadeln", "Hämta tränset", "Sätt på tränset", "Led "]
      .every((t, i, a) => sagda.indexOf(t) >= 0 && (i === 0 || sagda.indexOf(t) > sagda.indexOf(a[i - 1]))),
    `sista kortet ${k.id}`);
  prova("uppsittning nekas innan hon är ledd", !k.redo);
  prova("R1: ledningen är en prompt «[Håll inne L]»", k.rader.some(r => r.id === "leda" && r.text.includes("[Håll inne L]")),
    k.rader.map(r => r.text).join(" / "));
  await halla(page, "leda", 400);
  k = await kort(page);
  prova("«Led …» → hon leds, kortet säger vart", k.plats === "leds" && k.id === "leder", `${k.plats} · ${k.id}`);
  prova("R1: ingen vägvisare när hon leds (Roblox har ingen)", k.vagvisare === false, String(k.vagvisare));
  const ut = await page.evaluate(() => {
    const [x, y] = skSargport(); gaTill("ridhusinne", { x, y: y + 1.2, rikt: 0 });
    VD.hastX = x + 1; VD.hastY = y + 1.6; return true; });
  await vanta(page);
  k = await kort(page);
  prova("framme i ridhuset: ledningen kvitteras, «Sitt upp på …»",
    ut && k.redo && k.id === "sittupp" && k.rubrik === `Sitt upp på ${h.namn}`, `${k.id} · ${k.rubrik}`);
  prova("allt själv: dagsform 0,76 (0,70 + 0,06)", Math.abs(k.dagsform - 0.76) < 1e-9, String(k.dagsform));
  await page.close();
}

/* ── C ───────────────────────────────────────────────────────────── */
console.log("\n── C. «Rida nu» ──");
{
  const page = await oppna();
  const h = await vidBoxen(page);
  await vanta(page);
  await tangent(page, "KeyR", 100);
  let k = await kort(page);
  prova("R1: ett kort tryck på R är INTE «Rida nu» (hålltid 0,35 s)", k.id === "valj" && k.scen === "stallinne", `${k.id} · ${k.scen}`);
  await tangent(page, "KeyR", 550);
  await page.waitForTimeout(300);
  k = await kort(page);
  prova("R hållen: «Rida nu» — stallet leder henne till ridhuset", k.scen === "ridhusinne" && k.plats === "leds", `${k.scen} · ${k.plats}`);
  prova("hon är redo: «Sitt upp på …»", k.redo && k.id === "sittupp", k.id);
  prova("stallets hand ger ingen omsorgsbonus: dagsform 0,70", k.dagsform === 0.7, String(k.dagsform));
  prova("E vid sargporten är uppsittningen", /Sitt upp/.test(String(k.prompt)), String(k.prompt));
  const promptRad = await page.evaluate(() => document.getElementById("approach").textContent);
  prova("R1: prompten säger «Håll inne E»", promptRad.startsWith("Håll inne E — "), promptRad);
  await tangent(page, "KeyE", 100);
  prova("R1: ett kort tryck på E sitter inte upp", (await page.evaluate(() => G.scen)) === "ridhusinne");
  await tangent(page, "KeyE", 550);
  await page.waitForTimeout(300);
  const scen = await page.evaluate(() => G.scen);
  prova("E hållen sitter upp och lektionen börjar", scen === "lektion", scen);
  await page.close();
}

/* ── D ───────────────────────────────────────────────────────────── */
console.log("\n── D. En dag med fynd ──");
{
  const page = await oppna();
  /* Första passet med fynd för hästen, ur samma regel som Roblox. */
  const pass = await page.evaluate(() => {
    const id = valbaraHastar().includes("troy") ? "troy" : valbaraHastar()[0];
    for (let p = 2; p < 40; p++) if (Forb.fyndFor(id, p)) return p - 1;
    return -1;
  });
  await vidBoxen(page, { pass });
  await vanta(page);
  await klicka(page, "start:rida_nu");
  let k = await kort(page);
  prova("«Rida nu» stannar vid fyndet: «Du hittade något»", k.id === "fynd" && k.rubrik === "Du hittade något", `${k.id} · ${k.rubrik}`);
  prova("tre svar i kanonens ordning, inget framhävt",
    k.knappar.length === 3 && k.knappar.every(b => !b.primar) && k.knappar[0].text === "Säg till ridläraren",
    k.knappar.map(b => b.text).join(" / "));
  prova("hon är inte flyttad", k.scen === "stallinne" && k.plats === "box", `${k.scen} · ${k.plats}`);
  await klicka(page, "svar:2");
  k = await kort(page);
  prova("fel svar: «inte ditt beslut», frågan står kvar",
    k.id === "fynd" && k.aterkoppling === "Det är inte ditt beslut att ta. Säg till ridläraren.", k.aterkoppling);
  await klicka(page, "svar:1");
  k = await kort(page);
  prova("rätt svar: «Ridläraren tar över»", k.id === "stopp" && k.rubrik === "Ridläraren tar över", k.rubrik);
  const efter = await page.evaluate(() => { sittUpp("ridhus"); return G.scen; });
  prova("välfärdsstoppet: uppsittning nekas", efter !== "lektion", efter);
  await page.close();
}

/* ── E ───────────────────────────────────────────────────────────── */
console.log("\n── E. Engelska ──");
{
  const page = await oppna();
  const h = await vidBoxen(page, { sprak: "en" });
  await vanta(page);
  let k = await kort(page);
  prova("Choose how to start / Ride now / Get … ready myself",
    k.rubrik === "Choose how to start" && k.knappar[0].text === `Ride now — ${h.namn}` && k.knappar[1].text === `Get ${h.namn} ready myself`,
    k.knappar.map(b => b.text).join(" / "));
  const texter = [k.text];
  await klicka(page, "start:sjalv");
  k = await gorSjalv(page, "leda", texter);
  await halla(page, "leda", 400);
  texter.push((await kort(page)).text);
  const SVENSKA = /[åäöÅÄÖ]|\b(och|Välj|Rida|Gör|Hälsa|Rykta|Kratsa|sadeln|tränset|hästen|henne|Sitt upp)\b/;
  const blandat = texter.filter(t => SVENSKA.test(t.replace(h.namn, "")));
  prova("ingen svenska i panelen genom hela kedjan", blandat.length === 0,
    blandat.length ? blandat[0].replace(/\n/g, " ¦ ").slice(0, 140) : `${texter.length} kort`);
  await page.close();
}

/* ── G. P1b: automatisk tilldelning och First Ride ─────────────────
   Varje fall startar i en EGEN webbläsarkontext med ett förinställt
   sparläge — en förutsättning en spelare når på riktigt — och går sedan
   genom menyns egen knapp. Provet skriver aldrig i spelets tillstånd. */
console.log("\n── G. Tilldelning och First Ride (P1b) ──");
async function medProfil(profil, konto) {
  /* Språket låses: utan locale följer webbläsaren maskinens språk, och på
     en engelsk Windows blev beskeden engelska och provet rött. */
  const ctx = await browser.newContext({ viewport: { width: 1600, height: 900 }, locale: "sv-SE" });
  /* Provet pratar aldrig med den riktiga molnlagringen: en inloggning här
     är en sparad session i localStorage, och varje anrop mot Supabase
     avbryts innan det lämnar maskinen. */
  await ctx.route(/supabase\.co/, r => r.abort());
  if (profil !== undefined)
    await ctx.addInitScript(v => { try { localStorage.setItem("ubrf-ridskolan-v1", v); } catch (_) {} },
      typeof profil === "string" ? profil : JSON.stringify(profil));
  if (konto)
    await ctx.addInitScript(id => { try { localStorage.setItem("ubrf-synk-session-v1",
      JSON.stringify({ access_token: "prov", refresh_token: "prov", user: { id } })); } catch (_) {} }, konto);
  const page = await ctx.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(600);
  await page.evaluate(() => { const b = document.getElementById("bSkapHoppa"); if (b) b.click(); });
  await page.waitForTimeout(400);
  const knapp = await page.evaluate(() => { const b = document.getElementById("bStart"); const t = b && b.textContent.trim(); if (b) b.click(); return t; });
  await page.waitForTimeout(900);
  const l = await page.evaluate(() => ({
    scen: G.scen, hastId: G.hastId, dagsform: G.dagsform, betrodd: SPAR_BETRODD, pass: SPAR.pass, spelarId: SPAR.spelarId,
    forbOrord: G.forb ? Object.keys(G.forb.gjorda).length === 0 && Object.keys(G.forb.klara).length === 0 : null,
    forstaRitten: !!(G.skotselRes && G.skotselRes.forstaRitten),
    modal: !document.getElementById("ov").classList.contains("hide"),
    kort: (document.getElementById("stegkort") || {}).dataset ? document.getElementById("stegkort").dataset.kort : null,
    saga: (document.getElementById("saga") || {}).textContent || "",
    tid: tilldelningsId(),
    vantat: (() => { const vil = {}; for (const id of Object.keys(HORSES)) if (hastVilarForSkada(id)) vil[id] = true;
      return tilldelaLedig(tilldelningsId(), {}, vil, SPAR.pass === 0 ? "blackrock_jack" : null); })(),
  }));
  return { ctx, page, knapp, l };
}
{
  const { ctx, knapp, l } = await medProfil();
  prova("ny spelare: «Rid nu» → First Ride, uppsutten i ridhuset", knapp === "Rid nu" && l.scen === "lektion" && l.forstaRitten,
    `«${knapp}» → ${l.scen}`);
  prova("First Ride på Blackrock Jack (första dagens häst i Roblox)", l.hastId === "blackrock_jack", l.hastId);
  prova("First Ride markerar ingen skötsel — inte ens som stallets", l.forbOrord === true, String(l.forbOrord));
  prova("First Ride: dagsform 0,70 (egen andel 0)", l.dagsform === 0.7, String(l.dagsform));
  prova("ingen tilldelningsmodal på vägen", !l.modal);
  await ctx.close();
}
{
  const profil = { grupp: "ledlektion", pass: 3, spelarId: 12345, fortroende: {}, historik: [], rosetter: [], jag: { namn: "Prov" } };
  const { ctx, knapp, l } = await medProfil(profil);
  prova("återvändande spelare: ingen First Ride — gården", l.scen === "gard" && !l.forstaRitten, `«${knapp}» → ${l.scen}`);
  prova("hästen delas ut automatiskt, utan ridläraren", !!l.hastId && !l.modal, `${l.hastId} · modal ${l.modal}`);
  prova("samma häst som Roblox rotation ger för spelarens nummer", l.hastId === l.vantat && l.spelarId === 12345,
    `${l.hastId} · väntat ${l.vantat} · spelarId ${l.spelarId}`);
  prova("stegkortet säger «Gå till …»", l.kort === "ga_till", String(l.kort));
  await ctx.close();
}
{
  const { ctx, l } = await medProfil("{trasig sparning");
  prova("otillförlitlig läsning: ingen First Ride (fail closed, som Roblox)", l.betrodd === false && l.scen !== "lektion" && !l.forstaRitten,
    `betrodd ${l.betrodd} · ${l.scen}`);
  await ctx.close();
}
{
  const profil = { grupp: "ledlektion", pass: 0, spelarId: 7, historik: [], rosetter: [],
    fortroende: { blackrock_jack: { rang: 0.5, pass: 1, skada: { namn: "sten i hoven", passKvar: 2 } } } };
  const { ctx, l } = await medProfil(profil);
  prova("Jack vilar dag 1: ingen häst — ingen ersättare bakom välfärdsregeln", l.hastId === null && l.scen === "gard", `${l.hastId} · ${l.scen}`);
  prova("och spelaren får Roblox besked, ingen modal", l.saga.includes("Du har ingen tilldelad häst") && !l.modal, l.saga.slice(0, 80));
  await ctx.close();
}

/* ── G2. P1b R1: kontot styr rotationen (M1), First Ride-grinden (L1) ── */
console.log("\n── G2. Kontot och First Ride-grinden (P1b R1) ──");
{
  /* Samma konto, två «enheter» med var sin profil och var sitt spelarId —
     precis läget där hästen förut skilde sig mellan iPad och dator. */
  const konto = "3f1c2a9e-6b1d-4c7a-9f0e-2d5b8a1c4e77";
  const bas = { grupp: "ledlektion", pass: 3, fortroende: {}, historik: [], rosetter: [], jag: { namn: "Prov" } };
  const a = await medProfil({ ...bas, spelarId: 11 }, konto);
  const b = await medProfil({ ...bas, spelarId: 4000000000 }, konto);
  prova("M1: samma konto på två enheter får samma häst", !!a.l.hastId && a.l.hastId === b.l.hastId && a.l.tid === b.l.tid,
    `${a.l.hastId} · ${b.l.hastId}`);
  prova("M1: hästen är rotationens för kontots nummer, inte enhetens", a.l.hastId === a.l.vantat && a.l.tid !== 11,
    `${a.l.hastId} · väntat ${a.l.vantat} · nummer ${a.l.tid}`);
  await a.ctx.close(); await b.ctx.close();
  const c = await medProfil({ ...bas, spelarId: 11 });
  prova("M1: utloggad spelare behåller profilens nummer", c.l.tid === 11 && c.l.hastId === c.l.vantat, `${c.l.tid} · ${c.l.hastId}`);
  await c.ctx.close();
}
{
  /* L1: grinden själv, på ett riktigt First Ride-läge. Varje fall ändrar
     ETT villkor på en kopia och frågar grinden — ingen uppsittning sker. */
  const { ctx, page } = await medProfil();
  const r = await page.evaluate(() => {
    const spara = { forb: G.forb, hastId: G.hastId, utr: G.utrustning };
    const fraga = () => forstaRittenKanSittaUpp()[0];
    const ut = { redo: fraga() };
    G.forb = { ...spara.forb, stoppad: "halta" }; ut.stoppad = fraga(); G.forb = spara.forb;
    G.forb = { ...spara.forb, hastId: "troy" }; ut.fel = fraga(); G.forb = spara.forb;
    G.utrustning = false; ut.utanUtr = fraga(); G.utrustning = spara.utr;
    ut.checklista = Object.keys(G.forb.klara).length === 0;
    return ut;
  });
  prova("L1: First Ride-läget går igenom grinden trots ogjord checklista", r.redo && r.checklista);
  prova("L1: välfärdsstopp stoppar First Ride", r.stoppad === false);
  prova("L1: fel häst stoppar First Ride", r.fel === false);
  prova("L1: utan utrustning ingen First Ride", r.utanUtr === false);
  await ctx.close();
}

/* ── F ───────────────────────────────────────────────────────────── */
console.log("\n── F. Layout ──");
for (const vp of [{ width: 1600, height: 900, namn: "skrivbord" }, { width: 1180, height: 820, namn: "iPad liggande" }]) {
  const page = await oppna(vp);
  await vidBoxen(page);
  await vanta(page);
  await klicka(page, "start:sjalv");
  const r = await page.evaluate(() => {
    const b = document.getElementById("stegkort").getBoundingClientRect();
    return { x: b.x, y: b.y, w: b.width, h: b.height, vw: innerWidth, vh: innerHeight };
  });
  prova(`${vp.namn}: panelen helt synlig och ≤ 34 % av bredden`,
    r.x >= 0 && r.y >= 0 && r.x + r.w <= r.vw && r.y + r.h <= r.vh && r.w <= 0.34 * r.vw,
    `${Math.round(r.w)}×${Math.round(r.h)} vid ${Math.round(r.x)},${Math.round(r.y)} av ${r.vw}×${r.vh}`);
  if (BILDER) await page.screenshot({ path: path.join(BILDER, `halsa-${vp.width}x${vp.height}.png`) });
  await page.close();
}

await browser.close();
srv.close();
console.log(fel ? `\n${fel} fel.` : "\nalla gröna");
process.exit(fel ? 1 : 0);
