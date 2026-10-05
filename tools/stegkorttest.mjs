/* STEGKORTET — webbens stallflöde som i Roblox, spelat i webbläsaren.

   docs/WEB-P1A-STABLE-FLOW-CONTRACT.md, acceptans 2. Mot dist/ (bygg med
   `python tools/build.py`). Provet sätter bara förutsättningar en spelare
   når på riktigt — en tilldelad häst, ett passnummer, var spelaren står —
   och trycker sedan på panelens egna knappar. Det skriver aldrig i
   förberedelsens tillstånd.

     A. startvalet: exakt ETT val, E = «Rida nu», ingen vänsterruta
     B. ingen manuell skötsel och ingen ledning (beslut 2026-10-04)
     C. «Rida nu»: i ridhuset vid sargporten, hon står kvar, E sitter upp
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
/* ── A + B ───────────────────────────────────────────────────────── */
console.log("\n── A. Startvalet vid hästen ──");
{
  const page = await oppna();
  const h = await vidBoxen(page);
  await vanta(page);
  let k = await kort(page);
  prova("panelen syns vid hästen", k.synlig && k.id === "valj", `kort ${k.id}`);
  /* #297: ett enval-kort ber aldrig spelaren «välja», och det säger att stallet gör hästen redo. */
  prova("rubriken är «Dags att rida» — inget «Välj» när det bara finns en väg",
    k.rubrik === "Dags att rida" && !/välj|choose/i.test(k.rubrik), k.rubrik);
  prova("kortet säger att stallet gör hästen redo och att spelaren inte behöver sadla själv",
    /stallet gör .+ redo/.test(k.text) && /inte sadla eller tränsa själv/.test(k.text), k.text.replace(/\s+/g, " "));
  prova("exakt EN knapp: Rida nu — inget «Gör i ordning … själv»",
    k.knappar.length === 1 && k.knappar[0].text === `Rida nu — ${h.namn}`,
    k.knappar.map(b => b.text).join(" / "));
  prova("«Rida nu» är primär", k.knappar[0].primar);
  prova("inget «Fler handlingar» på startvalet", !k.fler);
  prova("ingen hälsningsfråga på startvalet", !/bakifrån|Framifrån/.test(k.text));
  prova("E vid hästen är «Rida nu»", k.prompt === `Rida nu — ${h.namn}`, String(k.prompt));
  prova("den gamla vänsterrutan syns inte till fots", !k.vansterruta);
  if (BILDER) await page.screenshot({ path: path.join(BILDER, "startval-1600x900.png") });

  console.log("\n── B. Ingen manuell skötsel och ingen ledning ──");
  const finns = await klicka(page, "start:sjalv");
  prova("knappen «Gör i ordning … själv» finns inte och går inte att trycka", finns === false);
  k = await kort(page);
  prova("kortet står kvar på startvalet", k.id === "valj", k.id);
  const ingen = await page.evaluate(() => ({
    gjorda: Object.keys(G.forb.gjorda).filter(f => Object.keys(G.forb.gjorda[f]).length > 0),
    hand: { ...G.forb.hand },
    knappar: [...document.querySelectorAll("#stegkort button")].map(b => b.dataset.id || "") }));
  const FORBJUDET = /^(handling:|tack:|rad:sadla|rad:transa|leda$|start:sjalv)/;
  prova("ingen skötselknapp, hämtprompt eller ledprompt någonstans i panelen",
    !ingen.knappar.some(id => FORBJUDET.test(id)), ingen.knappar.join(","));
  prova("inget skötselmoment är gjort, inte ens av stallet, före «Rida nu»",
    ingen.gjorda.length === 0 && !ingen.hand.sadel && !ingen.hand.trans, JSON.stringify(ingen));
  const foreE = await kort(page);
  await tangent(page, "KeyE", 550);
  const efterE = await kort(page);
  prova("E vid boxen gör inget skötselmoment och leder ingen",
    foreE.id === "valj" && efterE.id === "valj" && efterE.plats === "box", `${foreE.id} → ${efterE.id} · ${efterE.plats}`);
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
  prova("R hållen: «Rida nu» — stallet ställer henne i ridhuset", k.scen === "ridhusinne" && k.plats === "leds", `${k.scen} · ${k.plats}`);
  const hast0 = await page.evaluate(() => [VD.hastX, VD.hastY]);
  await page.evaluate(() => { VD.px += 4; VD.py -= 3; VD.spår.push([VD.px, VD.py]); });
  await page.waitForTimeout(400);
  const hast1 = await page.evaluate(() => [VD.hastX, VD.hastY]);
  prova("hästen står kvar när spelaren går — hon följer inte efter (ingen ledning)",
    hast0[0] === hast1[0] && hast0[1] === hast1[1], `${hast0} → ${hast1}`);
  await page.evaluate(() => { VD.px -= 4; VD.py += 3; });
  await page.waitForTimeout(300);
  prova("hon är redo: «Sitt upp på …»", k.redo && k.id === "sittupp", k.id);
  prova("efter «Rida nu» säger kortet att hon väntar i ridhuset och pekar på «Sitt upp» (inget skötselsteg)",
    /väntar i ridhuset/.test(k.text) && /Sitt upp/.test(k.text) && !/rykta|hovar|sadeln|tränset|led /i.test(k.text),
    k.text.replace(/\s+/g, " "));
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
  prova("Time to ride / Ride now (ett enda val, ingen «Choose»)",
    k.rubrik === "Time to ride" && !/choose/i.test(k.rubrik) && k.knappar.length === 1
      && k.knappar[0].text === `Ride now — ${h.namn}`,
    k.rubrik + " | " + k.knappar.map(b => b.text).join(" / "));
  prova("engelska kortet säger att stallet gör hästen redo",
    /the stable gets .+ ready/.test(k.text) && /do not need to saddle or bridle yourself/.test(k.text),
    k.text.replace(/\s+/g, " "));
  const texter = [k.text];
  await klicka(page, "start:rida_nu");
  texter.push((await kort(page)).text);
  const SVENSKA = /[åäöÅÄÖ]|\b(och|Välj|Rida|Gör|Hälsa|Rykta|Kratsa|sadeln|tränset|hästen|henne|Sitt upp)\b/;
  const blandat = texter.filter(t => SVENSKA.test(t.replace(h.namn, "")));
  prova("ingen svenska i panelen genom startvalet och uppsittningskortet", blandat.length === 0,
    blandat.length ? blandat[0].replace(/\n/g, " ¦ ").slice(0, 140) : `${texter.length} kort`);
  await page.close();
}

/* ── H. #297: förstagångsspelare på touch — båda stegen går att TRYCKA ──
   iPad liggande, bara pekskärm: ingen tangent trycks. Startkortet och
   uppsittningskortet bär varsin synlig knapp, och inga skötsel- eller
   ledknappar syns någonstans på vägen. */
console.log("\n── H. Touch: Rida nu och Sitt upp utan tangent (#297) ──");
{
  const ctx = await browser.newContext({ viewport: { width: 1180, height: 820 }, hasTouch: true, locale: "sv-SE" });
  await ctx.route(/supabase\.co/, r => r.abort());
  const page = await ctx.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(600);
  const h = await vidBoxen(page);
  await vanta(page);
  const FORBJUDET = /^(handling:|tack:|rad:sadla|rad:transa|leda$|start:sjalv)/;
  const alla = [];
  let k = await kort(page);
  alla.push(...k.knappar.map(b => b.id), ...k.rader.map(b => b.id));
  prova("startkortet: exakt en primär knapp, «Rida nu — häst», och inget «Välj»",
    k.id === "valj" && k.knappar.length === 1 && k.knappar[0].primar && k.knappar[0].id === "start:rida_nu"
      && k.knappar[0].text === `Rida nu — ${h.namn}` && !/välj/i.test(k.rubrik), k.knappar.map(b => b.text).join(" / "));
  const tryck = async id => {
    const ruta = await page.evaluate(id => {
      const b = [...document.querySelectorAll("#stegkort button")].find(x => x.dataset.id === id);
      if (!b) return null;
      const r = b.getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2, h: r.height, v: r.width };
    }, id);
    if (!ruta) return null;
    await page.touchscreen.tap(ruta.x, ruta.y);
    await page.waitForTimeout(700);
    return ruta;
  };
  const r1 = await tryck("start:rida_nu");
  prova("knappen går att trycka med fingret (minst 44 px hög)", !!r1 && r1.h >= 44, r1 ? `${Math.round(r1.h)} × ${Math.round(r1.v)} px` : "saknas");
  k = await kort(page);
  alla.push(...k.knappar.map(b => b.id), ...k.rader.map(b => b.id));
  prova("efter tryck: hon står i ridhuset och kortet är uppsittningskortet", k.scen === "ridhusinne" && k.id === "sittupp", `${k.scen} · ${k.id}`);
  prova("nästa instruktion är uppsittning, inte skötsel: «väntar i ridhuset» + «Sitt upp»",
    /väntar i ridhuset/.test(k.text) && /Sitt upp/.test(k.text) && !/rykta|hovar|sadeln|tränset|led /i.test(k.text),
    k.text.replace(/\s+/g, " "));
  prova("uppsittningskortet har exakt en synlig, primär «Sitt upp»-knapp (ingen hålltangent krävs)",
    k.knappar.length === 1 && k.knappar[0].primar && k.knappar[0].id === "sittupp:sitt_upp"
      && k.knappar[0].text === `Sitt upp på ${h.namn}`, k.knappar.map(b => b.text).join(" / "));
  const r2 = await tryck("sittupp:sitt_upp");
  prova("knappen går att trycka med fingret (minst 44 px hög)", !!r2 && r2.h >= 44, r2 ? `${Math.round(r2.h)} px` : "saknas");
  const scen = await page.evaluate(() => G.scen);
  prova("tryck på «Sitt upp» sitter upp och ritten börjar — utan en enda tangent", scen === "lektion", scen);
  prova("ingen skötsel- eller ledknapp syntes på vägen", !alla.some(id => FORBJUDET.test(id)), alla.join(","));
  await ctx.close();
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
  const r = await page.evaluate(() => {
    const b = document.getElementById("stegkort").getBoundingClientRect();
    return { x: b.x, y: b.y, w: b.width, h: b.height, vw: innerWidth, vh: innerHeight };
  });
  prova(`${vp.namn}: panelen helt synlig och ≤ 34 % av bredden`,
    r.x >= 0 && r.y >= 0 && r.x + r.w <= r.vw && r.y + r.h <= r.vh && r.w <= 0.34 * r.vw,
    `${Math.round(r.w)}×${Math.round(r.h)} vid ${Math.round(r.x)},${Math.round(r.y)} av ${r.vw}×${r.vh}`);
  if (BILDER) await page.screenshot({ path: path.join(BILDER, `startval-${vp.width}x${vp.height}.png`) });
  await page.close();
}

/* Telefon: kortet täcker nästan hela bredden, så 34 %-kravet gäller inte —
   men med 44 px knappar ska det fortfarande ligga helt inom skärmen. */
for (const vp of [{ width: 390, height: 844, namn: "telefon stående" }, { width: 844, height: 390, namn: "telefon liggande" }]) {
  const page = await oppna(vp);
  await vidBoxen(page);
  await vanta(page);
  const r = await page.evaluate(() => {
    const b = document.getElementById("stegkort").getBoundingClientRect();
    const k = [...document.querySelectorAll("#stegkort button:not(.skSprak)")].map((e) => e.getBoundingClientRect());
    return { x: b.x, y: b.y, w: b.width, h: b.height, vw: innerWidth, vh: innerHeight,
      minKnapp: k.length ? Math.min(...k.map((q) => q.height)) : 0, ut: k.some((q) => q.bottom > b.bottom + 0.5 || q.right > b.right + 0.5) };
  });
  prova(`${vp.namn}: panelen helt synlig, handlingsknapparna ≥ 44 px och inom kortet`,
    r.x >= 0 && r.y >= 0 && r.x + r.w <= r.vw && r.y + r.h <= r.vh && r.minKnapp >= 44 && !r.ut,
    `${Math.round(r.w)}×${Math.round(r.h)} vid ${Math.round(r.x)},${Math.round(r.y)} av ${r.vw}×${r.vh} · minsta knapp ${Math.round(r.minKnapp)} px`);
  await page.close();
}

await browser.close();
srv.close();
console.log(fel ? `\n${fel} fel.` : "\nalla gröna");
process.exit(fel ? 1 : 0);
