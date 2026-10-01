/* VÄLFÄRDSGRINDEN — en skadad häst ska inte arbeta.

   `docs/PRODUCT-CANON.md`: ansvaret och plikterna kring hästen ÄR
   gameplay. Då är det inte en detalj om spelet delar ut en halt häst när
   poolen tar slut; det är kärnan som går sönder. Kontraktet som mäts:

     1. En häst som vilar för skada får aldrig tilldelas — inte heller
        när alla gruppens hästar vilar. Slut på friska hästar är ett
        VÄNTELÄGE, inte en tilldelning av en skadad häst.
     2. Första dagens Jack är en tilldelning, inte en pool — men den får
        inte heller sätta en skadad häst i arbete.
     3. En genomförd ritt får inte radera en skada. Skador läker på vila,
        ett pass i taget, aldrig på att hästen arbetar.

     4. (#274) Hästbytet hos ridläraren sätter ingen vilande häst i
        arbete — två oberoende lås: listan och `sattAktivHast`.
     5. (#274) Rätt svar på ett fynd sparar vilan FÖRST och räknar sedan
        dagen en gång, som Roblox `svara`. Nästa session ger en annan häst.

   Provet SÄTTER upp ett sparläge (skadade hästar) — det är en
   förutsättning en spelare når på riktigt, inte ett hoppat spelarsteg.
   Därefter läses spelets egna funktioner utan att skrivas i.
*/
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8896;   /* fri port: 8873 lastlagetest, 8894 inputsemantik */

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
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(700);
const ev = (f, a) => page.evaluate(f, a);

/* ── 1. ALLA GRUPPENS HÄSTAR VILAR ─────────────────────────────── */
console.log("\n── Alla hästar i gruppen vilar för skada ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    /* Ledlektionens pool är toblerone + lydia. Båda skadas. */
    SPAR.fortroende.toblerone = { rang: .5, pass: 4, skada: { namn: "sten i hoven", passKvar: 2 } };
    SPAR.fortroende.lydia     = { rang: .5, pass: 4, skada: { namn: "skav", passKvar: 2 } };
    G.seed = 1;
    const borta = dagensHandelser();
    const pool = hastpool("ledlektion");
    return { pool, bortaToblerone: !!borta.toblerone, bortaLydia: !!borta.lydia,
      skadade: pool.filter(id => { const m = hastminne(id);
        return !!(m.skada && m.skada.passKvar > 0); }) };
  });
  prova("spelet vet att båda vilar", d.bortaToblerone && d.bortaLydia,
    `toblerone ${d.bortaToblerone} · lydia ${d.bortaLydia}`);
  prova("poolen innehåller INGEN häst som vilar för skada",
    d.skadade.length === 0,
    `pool [${d.pool.join(", ")}] · skadade i poolen [${d.skadade.join(", ")}]`);
}

/* ── 1b. SCHEMA ÄR INTE SAMMA SAK SOM SKADA ────────────────────
   En häst hos hovslagaren är frisk, bara upptagen. Att låta en
   schemakrock låsa ute spelaren vore en ny bugg i stället för den
   gamla — så den vikningen ska finnas kvar. Skadan viker sig aldrig. */
console.log("\n── Schema viker sig, skadan gör det inte ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    /* Ingen skada alls — men leta upp ett frö där BÅDA ledlektionens
       hästar är bokade, och kontrollera att spelaren ändå får rida. */
    let hittat = null;
    for (let s = 0; s < 400; s++) {
      G.seed = s; const b = dagensHandelser();
      if (b.toblerone && b.lydia) { hittat = { seed: s, pool: hastpool("ledlektion") }; break; }
    }
    /* Och samma sak med skada i stället för bokning. */
    SPAR.fortroende.toblerone = { rang: .5, pass: 4, skada: { namn: "sten", passKvar: 2 } };
    SPAR.fortroende.lydia     = { rang: .5, pass: 4, skada: { namn: "skav", passKvar: 2 } };
    G.seed = 1;
    return { hittat, skadadPool: hastpool("ledlektion") };
  });
  if (d.hittat) prova("båda bokade hos hovslagare/veterinär → spelaren får ändå en häst",
    d.hittat.pool.length > 0, `frö ${d.hittat.seed} · pool [${d.hittat.pool.join(", ")}]`);
  else console.log("  NOT  inget frö gav båda bokade — mätningen kunde inte utföras");
  prova("men båda SKADADE → ingen häst, inget undantag",
    d.skadadPool.length === 0, `pool [${d.skadadPool.join(", ")}]`);
}

/* ── 2. TILLDELNINGEN SJÄLV ────────────────────────────────────── */
console.log("\n── Ridläraren tilldelar inte en häst som vilar ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    SPAR.fortroende.toblerone = { rang: .5, pass: 4, skada: { namn: "sten i hoven", passKvar: 2 } };
    SPAR.fortroende.lydia     = { rang: .5, pass: 4, skada: { namn: "skav", passKvar: 2 } };
    G.grupp = "ledlektion"; G.tavling = false; G.seed = 1;
    const utfall = [];
    /* Varje frö ska ge samma svar: ingen skadad häst i arbete. */
    for (let s = 0; s < 8; s++) {
      G.seed = s;
      let tilldelad = null;
      try { visaTilldelning(); tilldelad = G.hastId; } catch (e) { tilldelad = "KAST:" + e.message; }
      const m = tilldelad && hastminne(tilldelad);
      utfall.push({ seed: s, hast: tilldelad,
        skadad: !!(m && m.skada && m.skada.passKvar > 0) });
    }
    return { utfall, antalSkadade: utfall.filter(u => u.skadad).length };
  });
  prova("ingen av åtta tilldelningar sätter en vilande häst i arbete",
    d.antalSkadade === 0,
    `${d.antalSkadade} av 8 — ${d.utfall.filter(u => u.skadad).map(u => `frö ${u.seed}: ${u.hast}`).join(", ") || "inga"}`);
}

/* ── 3. FÖRSTA DAGENS JACK ─────────────────────────────────────── */
console.log("\n── Första dagen: Jack får inte heller arbeta skadad ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 0;
    SPAR.fortroende.blackrock_jack = { rang: .5, pass: 2,
      skada: { namn: "känning efter sten i hoven", passKvar: 2 } };
    G.grupp = "ledlektion"; G.tavling = false; G.seed = 1;
    let tilldelad = null;
    try { visaTilldelning(); tilldelad = G.hastId; } catch (e) { tilldelad = "KAST:" + e.message; }
    const m = tilldelad && hastminne(tilldelad);
    return { tilldelad, skadad: !!(m && m.skada && m.skada.passKvar > 0) };
  });
  prova("första dagen tilldelar ingen häst som vilar",
    !d.skadad, `fick ${d.tilldelad}`);
}

/* ── 4. EN RITT FÅR INTE TVÄTTA BORT SKADAN ────────────────────── */
console.log("\n── Skadan överlever ett genomfört pass ──");
{
  const d = await ev(() => {
    SPAR = nyProfil(); SPAR.grupp = "ledlektion"; SPAR.pass = 3;
    SPAR.fortroende.toblerone = { rang: .5, pass: 4,
      skada: { namn: "sten i hoven", passKvar: 2 } };
    G.hastId = "toblerone"; G.grupp = "ledlektion";
    G.betyg = { a: .8 }; G.bedomda = 1; G.klarade = 1;
    G.dagsform = .7; G.skotselRes = { risker: [] };
    const fore = JSON.parse(JSON.stringify(SPAR.fortroende.toblerone.skada));
    registreraPass({ totalfel: 0, utesluten: false });
    const efter = SPAR.fortroende.toblerone.skada || null;
    return { fore, efter };
  });
  prova("skadan finns kvar efter passet",
    !!d.efter, d.efter ? `${d.efter.namn}, ${d.efter.passKvar} pass kvar`
      : `RADERAD (var: ${d.fore.namn}, ${d.fore.passKvar} pass kvar)`);
  prova("och den läks inte snabbare än vilan medger",
    !!d.efter && d.efter.passKvar >= d.fore.passKvar - 1,
    d.efter ? `${d.fore.passKvar} → ${d.efter.passKvar}` : "n/a");
}

/* ══ #274 — SPELARENS VÄG, i egna webbläsarkontexter ══════════════
   Varje fall startar genom menyns egen knapp med ett sparläge en spelare
   når på riktigt (en vilande häst = en sparad skada) och går sedan genom
   spelets egna knappar och E-prompten. Molnet avbryts innan det lämnar
   maskinen. Varje localStorage-skrivning av profilen loggas, så att
   ORDNINGEN mellan vilan och passet går att läsa. */
const NYCKEL = "ubrf-ridskolan-v1";
async function medProfil(profil) {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 720 }, locale: "sv-SE" });
  await ctx.route(/supabase\.co/, r => r.abort());
  await ctx.addInitScript(([v, nyckel]) => {
    try { if (!sessionStorage.getItem("valfard274")) {
      localStorage.setItem(nyckel, v); sessionStorage.setItem("valfard274", "1"); } } catch (_) {}
    window.__skriv = [];
    const orig = Storage.prototype.setItem;
    Storage.prototype.setItem = function (k, v) {
      if (k === nyckel) window.__skriv.push(v);
      return orig.call(this, k, v);
    };
  }, [JSON.stringify(profil), NYCKEL]);
  const p = await ctx.newPage();
  p.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await p.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await p.waitForTimeout(600);
  await starta(p);
  return { ctx, p };
}
async function starta(p) {
  await p.evaluate(() => { const b = document.getElementById("bSkapHoppa"); if (b) b.click(); });
  await p.waitForTimeout(400);
  await p.evaluate(() => { const b = document.getElementById("bStart"); if (b) b.click(); });
  await p.waitForTimeout(900);
}
const ramar = p => p.evaluate(() => new Promise(k => requestAnimationFrame(() => requestAnimationFrame(k))));
async function tillRidlararen(p) {
  await p.evaluate(() => { const r = STALLINNE.ridlarare.pos; gaTill("stallinne", { x: r[0], y: r[1] + 1.0, rikt: -Math.PI / 2 }); });
  await ramar(p); await p.waitForTimeout(300);
  await p.keyboard.down("KeyE"); await p.waitForTimeout(120); await p.keyboard.up("KeyE");
  await p.waitForTimeout(400);
}
async function tillBoxen(p) {
  await p.evaluate(() => { const b = hittaBox(G.hastId); gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1], rikt: 0 }); });
  await ramar(p); await p.waitForTimeout(300);
}
async function kortKlick(p, id) {
  const ok = await p.evaluate(id => { const b = [...document.querySelectorAll("#stegkort button")].find(x => x.dataset.id === id);
    if (b) b.click(); return !!b; }, id);
  await p.waitForTimeout(300);
  return ok;
}
const bytesLista = p => p.evaluate(() => [...document.querySelectorAll(".hb-val")].map(b => b.dataset.id));
const bas274 = { grupp: "ledlektion", pass: 3, spelarId: 12345, fortroende: {}, historik: [], rosetter: [], jag: { namn: "Prov" } };

/* Hästen rotationen ger den här profilen — den som sedan får vila. */
let vilande;
{
  const { ctx, p } = await medProfil(bas274);
  vilande = await p.evaluate(() => G.hastId);
  await ctx.close();
}
const medVila = { ...bas274, fortroende: { [vilande]: { rang: .5, pass: 2, skada: { namn: "känning efter sten i hoven", passKvar: 2 } } } };

/* ── 5. #274: HÄSTBYTET HOS RIDLÄRAREN ─────────────────────────── */
console.log("\n── #274: hästbytet sätter ingen vilande häst i arbete ──");
{
  const { ctx, p } = await medProfil(medVila);
  const start = await p.evaluate(() => G.hastId);
  prova("normal tilldelning går förbi den vilande hästen (oförändrat)", !!start && start !== vilande, `${vilande} vilar → ${start}`);
  await tillRidlararen(p);
  const lista = await bytesLista(p);
  prova("bytet listar INTE den vilande hästen (lås 1, valbaraHastar)", lista.length > 0 && !lista.includes(vilande),
    `${lista.length} hästar · ${vilande} listad: ${lista.includes(vilande)}`);
  /* Lås 2, oberoende av listan: anroparen går förbi den. */
  const direkt = await p.evaluate(id => { const f = G.hastId; const r = sattAktivHast(id); return { r, f, e: G.hastId }; }, vilande);
  prova("sattAktivHast(vilande) nekar och lämnar hästen orörd (lås 2)", direkt.r === false && direkt.e === direkt.f,
    `svar ${direkt.r} · ${direkt.f} → ${direkt.e}`);
  /* Lås 2 i spelarens väg: en knapp som ritades innan vilan kom. */
  await p.evaluate(() => overlay(false));
  const unna = await p.evaluate(id => { const v = SPAR.fortroende[id]; const sk = v.skada; delete v.skada; return sk; }, vilande);
  await tillRidlararen(p);
  const fanns = (await bytesLista(p)).includes(vilande);
  await p.evaluate(([id, sk]) => { SPAR.fortroende[id].skada = sk; }, [vilande, unna]);
  await p.evaluate(id => { const b = [...document.querySelectorAll(".hb-val")].find(x => x.dataset.id === id); if (b) b.click(); }, vilande);
  await p.waitForTimeout(400);
  const efterKlick = await p.evaluate(() => G.hastId);
  prova("en gammal knapp i bytet ger inte heller den vilande hästen", fanns && efterKlick === start, `knapp fanns ${fanns} · aktiv ${efterKlick}`);
  /* Och spelaren når ingen ritt med henne: «Rida nu» och E på «Sitt upp». */
  await tillBoxen(p);
  await kortKlick(p, "start:rida_nu");
  await p.keyboard.down("KeyE"); await p.waitForTimeout(900); await p.keyboard.up("KeyE");
  await p.waitForTimeout(600);
  const ritt = await p.evaluate(() => ({ scen: G.scen, hast: G.hastId }));
  prova("ingen ritt på den vilande hästen genom bytesvägen", !(ritt.scen === "lektion" && ritt.hast === vilande), `${ritt.scen} · ${ritt.hast}`);
  await ctx.close();
}
{
  /* Ett friskt byte fungerar som förut. */
  const { ctx, p } = await medProfil(bas274);
  const fore = await p.evaluate(() => G.hastId);
  await tillRidlararen(p);
  const lista = await bytesLista(p);
  const ny = lista.find(id => id !== fore);
  await p.evaluate(id => { const b = [...document.querySelectorAll(".hb-val")].find(x => x.dataset.id === id); if (b) b.click(); }, ny);
  await p.waitForTimeout(400);
  await tillBoxen(p);
  const k = await p.evaluate(() => ({ hast: G.hastId, kort: document.getElementById("stegkort").dataset.kort,
    knappar: [...document.querySelectorAll("#stegkort button")].map(b => b.dataset.id) }));
  prova("friskt byte: den nya hästen blir spelarens, med «Rida nu»", k.hast === ny && k.knappar.includes("start:rida_nu"),
    `${fore} → ${k.hast} · ${k.kort}`);
  await ctx.close();
}

/* ── 6. #274: VÄLFÄRDSSTOPPET RÄKNAR DAGEN, som Roblox `svara` ───── */
console.log("\n── #274: rätt svar sparar vilan först och räknar dagen en gång ──");
{
  /* En fynddag för den tilldelade hästen, ur samma regel som Roblox. En
     annan häst vilar redan (2 pass) — dagen ska räkna ned även hennes. */
  const probe = await medProfil(bas274);
  const fyndPass = await probe.p.evaluate(id => { for (let q = 2; q < 60; q++) if (Forb.fyndFor(id, q + 1)) return q; return -1; }, vilande);
  const annan = await probe.p.evaluate(id => valbaraHastar().find(x => x !== id), vilande);
  await probe.ctx.close();
  const profil = { ...bas274, pass: fyndPass,
    fortroende: { [annan]: { rang: .5, pass: 1, skada: { namn: "skav", passKvar: 2 } } } };
  const { ctx, p } = await medProfil(profil);
  const h = await p.evaluate(() => G.hastId);
  await tillBoxen(p);
  await kortKlick(p, "start:rida_nu");
  const fyndKort = await p.evaluate(() => document.getElementById("stegkort").dataset.kort);
  prova("förutsättning: fynddagen frågar", h === vilande && fyndKort === "fynd", `${h} · pass ${fyndPass} · ${fyndKort}`);
  const mark = await p.evaluate(() => window.__skriv.length);
  await kortKlick(p, "svar:1");
  const d = await p.evaluate(([mark, nyckel, h, annan]) => {
    const skr = window.__skriv.slice(mark).map(s => JSON.parse(s));
    const el = document.getElementById("stegkort");
    return {
      skr: skr.map(s => ({ pass: s.pass, kvar: s.fortroende[h] && s.fortroende[h].skada ? s.fortroende[h].skada.passKvar : null })),
      kort: el.dataset.kort,
      knappar: [...el.querySelectorAll("button")].map(b => b.dataset.id || b.textContent.trim()),
      pass: SPAR.pass, skada: SPAR.fortroende[h].skada || null,
      annan: SPAR.fortroende[annan].skada ? SPAR.fortroende[annan].skada.passKvar : 0,
      sparat: JSON.parse(localStorage.getItem(nyckel)), stoppad: G.forb ? G.forb.stoppad : null,
      igen: registreraValfardsstopp(G.forb), passIgen: SPAR.pass,
    };
  }, [mark, NYCKEL, h, annan]);
  prova("stoppkortet: «Ridläraren tar över», ingen ny handlingsknapp (paritet med Roblox)",
    d.kort === "stopp" && d.knappar.every(k => !/^(start|svar|rad|byt)/.test(k)), `${d.kort} · ${JSON.stringify(d.knappar)}`);
  prova("första skrivningen bär vilan, med passet orört (vilan sparas först)",
    d.skr.length >= 2 && d.skr[0].kvar === 2 && d.skr[0].pass === fyndPass, JSON.stringify(d.skr));
  prova("sista skrivningen har dagen räknad", d.skr.length >= 2 && d.skr[d.skr.length - 1].pass === fyndPass + 1, JSON.stringify(d.skr));
  prova("passet ökar exakt en gång, och ett andra anrop räknar inte igen",
    d.pass === fyndPass + 1 && d.igen === false && d.passIgen === fyndPass + 1, `${fyndPass} → ${d.pass} · igen ${d.igen} → ${d.passIgen}`);
  prova("hon vilar: 2 pass sparade, nedräknat ett av dagen (Roblox raknaNerVila), fyndet bokfört",
    !!d.skada && d.skada.passKvar === 1 && d.skada.vad === d.stoppad && typeof d.skada.namn === "string" && d.skada.namn.length > 0,
    `${JSON.stringify(d.skada)} · stoppad ${d.stoppad}`);
  prova("dagen räknar ned de andra hästarnas vila också", d.annan === 1, `${annan}: 2 → ${d.annan}`);
  prova("profilen är sparad med vila och räknat pass",
    d.sparat.pass === fyndPass + 1 && !!(d.sparat.fortroende[h].skada && d.sparat.fortroende[h].skada.passKvar === 1),
    `pass ${d.sparat.pass} · ${JSON.stringify(d.sparat.fortroende[h].skada)}`);
  /* Bytet tar inte tillbaka henne samma dag. */
  await tillRidlararen(p);
  const lista = await bytesLista(p);
  prova("samma dag: den stoppade hästen finns inte i bytet", lista.length > 0 && !lista.includes(h), `${lista.length} hästar`);
  await p.evaluate(() => overlay(false));
  /* Ny session: nästa häst, inte samma fynd igen. */
  await p.reload({ waitUntil: "load" }); await p.waitForTimeout(600);
  await starta(p);
  const n = await p.evaluate(h => ({ hast: G.hastId, pass: SPAR.pass, vilar: hastVilarForSkada(h),
    vald: G.hastId ? hastVilarForSkada(G.hastId) : null, direkt: sattAktivHast(h), efter: G.hastId }), h);
  prova("ny session: en annan, frisk häst — slingan är bruten",
    !!n.hast && n.hast !== h && n.vald === false && n.pass === fyndPass + 1, `${n.hast} · pass ${n.pass}`);
  prova("den stoppade hästen vilar fortfarande och kan inte sättas", n.vilar && n.direkt === false && n.efter === n.hast,
    `vilar ${n.vilar} · sattAktivHast ${n.direkt}`);
  /* Tills vilan är slut: ett ridet pass till räknar ned henne till noll. */
  const t = await p.evaluate(h => {
    G.betyg = { a: .8 }; G.bedomda = 1; G.klarade = 1; G.dagsform = .7; G.skotselRes = { risker: [] };
    registreraPass({ totalfel: 0, utesluten: false });
    return { vilar: hastVilarForSkada(h), listad: valbaraHastar().includes(h) };
  }, h);
  prova("när vilan är slut är hon valbar igen", !t.vilar && t.listad, `vilar ${t.vilar} · listad ${t.listad}`);
  await ctx.close();
}

console.log(fel ? `\n${fel} FEL` : "\nALLA VÄLFÄRDSKONTROLLER OK");
await browser.close(); srv.close();
process.exit(fel ? 1 : 0);
