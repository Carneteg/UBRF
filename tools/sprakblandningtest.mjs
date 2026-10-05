/* UI-2 + UI-3 PÅ WEBBEN — docs/P2-UGNETA-INSTRUCTION-CONTRACT.md §§ 1, 2, 4, 5.

   Samma krav som roblox/tests/klient-blandning.spec.luau, på webbens
   stegkort (#stegkort): Ugneta överst med sin instruktion, handlingarna
   under, och EN språk synligt åt gången.

   Hela kedjan till fots körs två varv i en riktig webbläsare mot dist/:
   på svenska, och på engelska efter att UGNETAS FLAGGA tryckts — samma
   knapp som spelaren trycker. Varje synlig rad i kortet prövas mot det
   andra språket (katalogens texter som skiljer sig, å/ä/ö, och
   funktionsord). Hästens egennamn undantas.

   Kör: python3 tools/build.py && node tools/sprakblandningtest.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8899;
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
  headless: true, executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

/* ── DETEKTORN ─────────────────────────────────────────────────────── */
const ORD = {
  sv: ["och", "inte", "med", "till", "hennes", "hon", "din", "sidan", "fram", "att", "eller", "sedan", "innan"],
  en: ["the", "your", "you", "and", "with", "her", "from", "she", "now", "get", "ready", "myself", "put", "say",
    "walk", "greet", "check", "lead", "never", "before"],
};
const bitar = t => String(t).split(/%[sd]/).map(b => b.trim()).filter(b => b.length >= 8);
function detektor(katalog, egennamn) {
  const bara = { sv: [], en: [] };
  for (const { sv, en } of katalog) {
    if (typeof sv !== "string" || typeof en !== "string" || sv === en) continue;
    for (const b of bitar(sv)) if (!en.includes(b)) bara.sv.push(b);
    for (const b of bitar(en)) if (!sv.includes(b)) bara.en.push(b);
  }
  const ord = (t, lista) => lista.find(o => new RegExp(`(^|[^\\p{L}])${o}([^\\p{L}]|$)`, "iu").test(t));
  return (text, lage) => {
    let t = String(text);
    for (const n of egennamn) t = t.split(n).join(" ");
    if (lage === "en") {
      const m = t.match(/[åäöÅÄÖ]/);
      if (m) return `svensk bokstav ${m[0]}`;
      const b = bara.sv.find(x => t.includes(x));
      if (b) return `svensk katalogtext «${b}»`;
      const o = ord(t, ORD.sv);
      if (o) return `svenskt ord «${o}»`;
    } else {
      const b = bara.en.find(x => t.includes(x));
      if (b) return `engelsk katalogtext «${b}»`;
      const o = ord(t, ORD.en);
      if (o) return `engelskt ord «${o}»`;
    }
    return null;
  };
}

/* ── SIDAN ─────────────────────────────────────────────────────────── */
async function oppna() {
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, locale: "sv-SE" });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(600);
  const h = await page.evaluate(() => {
    const id = valbaraHastar().includes("troy") ? "troy" : valbaraHastar()[0];
    let p = 1; while (Forb.fyndFor(id, p + 1)) p++;
    SPAR.pass = p;
    startaVandring();
    sattAktivHast(id);
    const b = hittaBox(id);
    gaTill("stallinne", { x: b.dorr[0], y: b.dorr[1], rikt: 0 });
    return new Promise(klar => requestAnimationFrame(() => requestAnimationFrame(() => klar({
      id, namn: HORSES[id].namn,
      katalog: Object.values(SPRAK).map(p => ({ sv: p.sv, en: p.en })),
      namn2: Object.values(HORSES).map(x => x.namn),
    }))));
  });
  return { page, h };
}
const vanta = page => page.waitForTimeout(250);
const kort = page => page.evaluate(() => {
  const el = document.getElementById("stegkort");
  const u = el.querySelector(".skU");
  return {
    synlig: !el.hidden, id: el.dataset.kort,
    rader: el.innerText.split("\n").map(s => s.trim()).filter(Boolean),
    ugnetaForst: !!u && el.firstElementChild === u,
    titel: (el.querySelector(".skUt") || {}).textContent || "",
    flagga: (el.querySelector("button[data-sprak]") || {}).textContent || "",
    instr: (el.querySelector(".skUi") || {}).textContent || "",
    dubbel: !!el.querySelector(".skT"),
    knappar: [...el.querySelectorAll(".skV button")].map(b => ({ id: b.dataset.id, text: b.textContent.trim(),
      primar: b.classList.contains("primar") })),
    prompt: [...el.querySelectorAll(".skRader button")].map(b => ({ id: b.dataset.id })),
    ater: (el.querySelector(".skA") || {}).textContent || "",
    sprak: SPRAKET,
  };
});
async function klicka(page, sel) {
  const ok = await page.evaluate(s => { const b = document.querySelector(s); if (b) b.click(); return !!b; }, sel);
  await vanta(page);
  return ok;
}
async function halla(page, id, ms = 500) {
  await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort .skRader button")].find(x => x.dataset.id === id);
    if (b) b.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true }));
  }, id);
  await page.waitForTimeout(ms);
  await page.evaluate(id => {
    const b = [...document.querySelectorAll("#stegkort .skRader button")].find(x => x.dataset.id === id);
    if (b) b.dispatchEvent(new PointerEvent("pointerup", { bubbles: true }));
  }, id);
  await vanta(page);
}
/* Kedjan efter beslutet 2026-10-04: startvalet (ett val) och, efter «Rida nu»,
   uppsittningskortet. Det finns ingen skötsel- eller ledkedja att gå. */
async function kedja(page, lage, granska) {
  const k0 = await kort(page);
  granska(k0, lage);
  await klicka(page, `#stegkort .skV button[data-id="start:rida_nu"]`);
  const k1 = await kort(page);
  if (k1.synlig) granska(k1, lage);
  return k1;
}

console.log("\n── A. Ugneta överst, startvalet med ett val ──");
{
  const { page, h } = await oppna();
  let k = await kort(page);
  prova("Ugnetas ruta är kortets första block", k.ugnetaForst, k.id);
  prova("titeln är «Ugneta · Ridinstruktör» och flaggan «Svenska»", k.titel === "Ugneta · Ridinstruktör" && k.flagga === "Svenska",
    `${k.titel} · ${k.flagga}`);
  prova("startkortet: ETT val, «Rida nu», och det är primärt",
    k.id === "valj" && k.knappar.length === 1 && k.knappar[0].primar && /^RIDA NU/.test(k.knappar[0].text),
    k.knappar.map(b => b.text + (b.primar ? "*" : "")).join(" / "));
  prova("Ugneta säger kortets rad; instruktionen står EN gång", /^.+ är din häst idag. Du behöver inte sadla eller tränsa själv — stallet gör .+ redo.$/.test(k.instr) && !k.dubbel, k.instr);
  prova("ingen «Gör i ordning själv», ingen hälsning, ingen frågesport",
    !k.knappar.some(b => /själv|Hälsa|bakifrån|Framifrån/.test(b.text)));
  await page.close();
}

console.log("\n── B. Startvalet och uppsittningen på svenska, sedan på engelska via Ugnetas flagga ──");
for (const lage of ["sv", "en"]) {
  const { page, h } = await oppna();
  const arBlandat = detektor(h.katalog, h.namn2);
  const blandat = [];
  let sedda = 0;
  const granska = (k, l) => {
    for (const rad of k.rader) {
      sedda++;
      const varfor = arBlandat(rad, l);
      if (varfor) blandat.push(`${k.id}: «${rad}» (${varfor})`);
    }
  };
  if (lage === "en") {
    await klicka(page, "#stegkort button[data-sprak]");
    const k = await kort(page);
    prova("flaggan byter till engelska: «English» och titeln «Ugneta · Riding instructor»",
      k.sprak === "en" && k.flagga === "English" && k.titel === "Ugneta · Riding instructor", `${k.flagga} · ${k.titel}`);
  }
  granska(await kort(page), lage);
  const slut = await kedja(page, lage, granska);
  prova(`${lage}: «Rida nu» ger uppsittningskortet`, slut.id === "sittupp", slut.id);
  prova(`${lage}: inget av andra språket i ${sedda} synliga rader`, blandat.length === 0 && sedda >= 4,
    blandat.slice(0, 6).join(" ‖ "));
  if (lage === "en") {
    await klicka(page, "#stegkort button[data-sprak]");
    const k = await kort(page);
    prova("flaggan tillbaka: «Svenska»", k.sprak === "sv" && k.flagga === "Svenska", k.flagga);
  }
  await page.close();
}

/* ── D. P3: I SADELN ───────────────────────────────────────────────────
   docs/P3-RIDING-PANEL-LESSON-MENU-CONTRACT.md § 1.6: varje synlig sträng
   i ridpanelen, menyn, lektionerna, återkopplingen, återspelningen och
   reglagelistan går genom tSpr. Svenska valt → ingen engelska; engelska
   valt (via ridpanelens EGEN flagga) → ingen svenska. Samma detektor. */
console.log("\n── D. P3: ridpanelen, menyn, lektionerna, återkopplingen, reglagen, återspelningen ──");
for (const lage of ["sv", "en"]) {
  const page = await browser.newPage({ viewport: { width: 1600, height: 900 }, locale: "sv-SE" });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(600);
  const h = await page.evaluate(() => { overlay(false); window.SPRAKET = "sv"; SPAR.pass = 0; SPAR_BETRODD = true;
    startaVandring();
    return { katalog: Object.values(SPRAK).map(p => ({ sv: p.sv, en: p.en })), namn2: Object.values(HORSES).map(x => x.namn) }; });
  await page.waitForTimeout(600);
  const arBlandat = detektor(h.katalog, h.namn2);
  const blandat = [], ytor = new Set();
  let sedda = 0;
  const las = async (yta, sel) => {
    /* Synlig = ritad (getClientRects), inte offsetParent — panelerna är
       position:fixed och har ingen offsetParent. */
    const rader = await page.evaluate(s => { const el = document.querySelector(s);
      return el && !el.hidden && el.getClientRects().length && getComputedStyle(el).display !== "none"
        ? el.innerText.split("\n").map(x => x.trim()).filter(Boolean) : []; }, sel);
    for (const rad of rader) {
      sedda++; ytor.add(yta);
      const varfor = arBlandat(rad, lage);
      if (varfor) blandat.push(`${yta}: «${rad}» (${varfor})`);
    }
  };
  const knapp = async borjar => page.evaluate(t => { const b = [...document.querySelectorAll("#ridpanel .skV button")]
    .find(x => x.textContent.startsWith(t)); if (b) b.click(); return !!b; }, borjar);
  if (lage === "en") { await page.click("#ridpanel button[data-sprak]"); await vanta(page); }
  prova(`${lage}: språket är valt`, await page.evaluate(() => SPRAKET) === lage);
  /* #273 S1: listan öppnas inte av sig själv längre — provet öppnar den. */
  await page.evaluate(() => visaKontrollHjalp()); await vanta(page);
  await las("reglagelistan", "#kontrollhjalp");
  await page.evaluate(() => doljKontrollHjalp());
  await las("ridpanelen", "#ridpanel");
  await page.click("#ridpanel button[data-hjalp]"); await vanta(page); await las("ridpanelen ?", "#ridpanel");
  await page.click("#ridpanel button[data-hjalp]");
  await page.click("#ridpanel button[data-text]"); await vanta(page); await las("Text", "#ridpanel");
  await page.click("#ridpanel button[data-text]");
  await page.keyboard.down("KeyW"); await page.waitForTimeout(350); await page.keyboard.up("KeyW"); await page.waitForTimeout(500);
  await las("fri träning", "#ridpanel");
  /* Menyns alla sidor, med panelens egna knappar. */
  const grupper = lage === "sv" ? ["Gångarter", "Övergångar", "Tillbaka", "Tillbaka", "Ridvägar", "Böjda", "Tillbaka", "Raka", "Tillbaka", "Tillbaka"]
    : ["Gaits", "Transitions", "Back", "Back", "Riding paths", "Curved", "Back", "Straight", "Back", "Back"];
  for (const g of grupper) { await knapp(g); await vanta(page); await las("menyn", "#ridpanel"); }
  /* Varje lektion: sidan, Start, den levande sidan, Avsluta. */
  for (const typ of ["volt", "halt", "tempo", "overgang", "galopp", "serpentin", "vag_mitt", "vag_diag", "halvvolt", "hornet", "markbom", "clearround"]) {
    await page.evaluate(t => Lektionsmeny.valj(t), typ); await vanta(page); await las(`lektion ${typ}`, "#ridpanel");
    const start = typ === "clearround" ? ["anmal", "ga_banan", "start"] : ["start"];
    for (const op of start) { await page.evaluate(o => Lektionsmeny.skicka(o), op); await vanta(page); await las(`lektion ${typ}`, "#ridpanel"); }
    await page.evaluate(() => { const b = Lektionsmeny.panel().knappar; b[b.length - 1].gor(); }); await vanta(page);
    await las(`lektion ${typ} avslutad`, "#ridpanel");
  }
  /* Återkopplingen: varje typs slut-, kort- och tidsgränstext ur en fryst bild. */
  const at = await page.evaluate(() => {
    const R = { volt: { avsnitt: { varv: 1, referens: { radie: 10 }, medelAvvikelse: 0.8, tid: 21 } },
      halt: { mal: "X", skrittMeter: 4.4, haltSekunder: 2.1 }, overgang: { mal: "T1->T2", travMeter: 6.5, skrittMeter: 2.2 },
      serpentin: { rutt: "serpentin-3", meter: 75, korsningar: [1, 2] },
      tempo: { ovning: "jamn_skritt", enhet: "m/s", meter: 12, sekunder: 8, medelFart: 1.5, spridning: 0.12 },
      vag_mitt: { figur: "vag_mitt", meter: 48, langd: 48 }, vag_diag: { figur: "vag_diag", meter: 46, langd: 46.2 },
      halvvolt: { figur: "halvvolt", meter: 45, skarvar: [1, 2], skuld: 0.3 },
      galopp: { ovning: "galoppfattning", galoppsida: "ej_bedomd", travMeter: 9, galoppMeter: 6.2 },
      markbom: { ovning: "markbom", passage: "rotplan", inridningM: 4, utridningM: 1.2 },
      hornet: { figur: "hornet", mitt: true, meter: 23.5, langd: 23.9 },
      clearround: { ovning: "clearround", bedomning: "forenklad", forsokNr: 1, utfall: "observerade_fel", olydnader: 1, fel: 4, tid: 95, omstartMojlig: true } };
    const ut = [];
    for (const typ in R) for (const detalj of ["detaljerad", "kort"]) {
      LararInstallning.satDetalj(detalj);
      const b = { typ, rittId: "p", forsokId: "p:1", lage: "complete", resultat: { ...R[typ], forsokId: "p:1", rittId: "p" },
        eftervard: typ === "clearround" ? EFTERVARD.map(e => ({ namn: e.namn, namnEn: e.namnEn })) : null };
      ut.push(LektionAterkoppling.text(b, { typ, ritt: "p" }));
      ut.push(LektionAterkoppling.text({ typ, rittId: "p", forsokId: "p:1", lage: "timeout", progress: 40 }, { typ, ritt: "p" }));
    }
    LararInstallning.satDetalj("detaljerad");
    return ut;
  });
  for (const rad of at) { sedda++; const v = arBlandat(rad, lage); if (v) blandat.push(`återkopplingen: «${rad}» (${v})`); }
  ytor.add("återkopplingen");
  /* Återspelningen: en runda på 20 m-volten i fri träning, sedan «Se ritten». */
  const replay = await page.evaluate(() => {
    Lektionsmeny._S.valt = false; Lektionsmeny._S.fri = false; FriPass.nyttPass();
    const dt = 1 / 30;
    for (let i = 0; i < 9000; i++) {
      if (FriPass.lage() === "efter") { if (FriPass.ovningId() === "storvolt") return FriPass.seRitten(); if (!FriPass.gaVidare()) FriPass.fortsatt(); continue; }
      RIDIN.skankel = i % 120 < 20 ? 1 : 0; RIDIN.styr = i % 90 < 45 ? 0.6 : 0;
      stegaRitt(dt); stegaP3(dt);
    }
    return false;
  });
  prova(`${lage}: återspelningen gick att öppna ur fri träning`, replay === true);
  await las("återspelningen", "#ov");
  prova(`${lage}: ytorna prövades`, ["reglagelistan", "ridpanelen", "ridpanelen ?", "Text", "fri träning", "menyn",
    "lektion clearround", "återkopplingen", "återspelningen"].every(y => ytor.has(y)), [...ytor].join(", "));
  prova(`${lage}: inget av andra språket i ${sedda} synliga rader i sadeln`, blandat.length === 0 && sedda > 150,
    blandat.slice(0, 8).join(" ‖ "));
  await page.close();
}

console.log("\n── C. Detektorn själv ──");
{
  const d = detektor([{ sv: "Gå fram från sidan vid bogen", en: "Walk up from the side, at her shoulder" }], ["Troy"]);
  prova("svenska läget fångar en engelsk handling", d("Walk up from the side, at her shoulder", "sv") !== null);
  prova("engelska läget fångar en svensk handling", d("Gå fram från sidan vid bogen", "en") !== null);
  prova("engelska läget fångar svenska utan omljud", d("Kolla ben och hovar innan du rider", "en") !== null);
  prova("«get» i «Sadelläget» är inget engelskt ord", d("Sadelläget", "sv") === null);
  prova("hästens namn fälls inte", d("Greet Troy", "en") === null);
}

await browser.close();
srv.close();
console.log(fel ? `\n${fel} FEL` : "\nALLA OK");
process.exit(fel ? 1 : 0);
