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
/* Kedjan: den primära handlingen kort för kort, annars kortets egen prompt. */
async function kedja(page, lage, granska) {
  for (let i = 0; i < 80; i++) {
    const k = await kort(page);
    if (!k.synlig) return k;
    granska(k, lage);
    if (k.id === "leda") return k;
    const v = k.knappar.find(b => b.primar);
    if (v) { await klicka(page, `#stegkort .skV button[data-id="${v.id}"]`); continue; }
    const r = k.prompt.find(x => x.id !== "rad:rida_nu");
    if (!r) return k;
    await halla(page, r.id);
  }
  return kort(page);
}

console.log("\n── A. Ugneta överst, hälsningen som handlingar ──");
{
  const { page, h } = await oppna();
  let k = await kort(page);
  prova("Ugnetas ruta är kortets första block", k.ugnetaForst, k.id);
  prova("titeln är «Ugneta · Ridinstruktör» och flaggan «Svenska»", k.titel === "Ugneta · Ridinstruktör" && k.flagga === "Svenska",
    `${k.titel} · ${k.flagga}`);
  await klicka(page, `#stegkort .skV button[data-id="start:sjalv"]`);
  k = await kort(page);
  const forsta = await page.evaluate(() => { const m = Forb.nastaMoment(G.forb, "halsa"); return m && m.text; });
  prova("«Hälsa på …»: tre handlingar, bara den första primär",
    k.id === "halsa" && k.knappar.length === 3 && k.knappar[0].primar && !k.knappar[1].primar && !k.knappar[2].primar,
    k.knappar.map(b => b.text + (b.primar ? "*" : "")).join(" / "));
  prova("Ugneta säger den första handlingen; instruktionen står EN gång", k.instr === forsta && !k.dubbel, k.instr);
  prova("ingen frågesport: inget «bakifrån» bland handlingarna", !k.knappar.some(b => /bakifrån|Framifrån/.test(b.text)));
  await klicka(page, `#stegkort .skV button[data-id="halsa3"]`);
  k = await kort(page);
  prova("handen innan namnet: nej, och hälsningen står kvar", k.id === "halsa" && k.ater !== "" && k.knappar.length === 3,
    k.ater);
  await klicka(page, `#stegkort .skV button[data-id="halsa1"]`);
  k = await kort(page);
  prova("första handlingen gjord: kanonens kvittens, två kvar, «Säg hennes namn» primär",
    k.ater === "✓  Där ser hon dig komma." && k.knappar.length === 2 && k.knappar[0].primar
      && k.knappar[0].text === "Säg hennes namn", `${k.ater} · ${k.knappar.map(b => b.text).join(" / ")}`);
  await klicka(page, `#stegkort .skV button[data-id="halsa2"]`);
  await klicka(page, `#stegkort .skV button[data-id="halsa3"]`);
  k = await kort(page);
  prova("alla tre i ordning: nästa fas", k.id === "visitera", k.id);
  await page.close();
}

console.log("\n── B. Hela kedjan på svenska, sedan på engelska via Ugnetas flagga ──");
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
  await klicka(page, `#stegkort .skV button[data-id="start:sjalv"]`);
  const slut = await kedja(page, lage, granska);
  prova(`${lage}: kedjan når ledningen`, slut.id === "leda", slut.id);
  prova(`${lage}: inget av andra språket i ${sedda} synliga rader`, blandat.length === 0 && sedda > 30,
    blandat.slice(0, 6).join(" ‖ "));
  if (lage === "en") {
    await klicka(page, "#stegkort button[data-sprak]");
    const k = await kort(page);
    prova("flaggan tillbaka: «Svenska»", k.sprak === "sv" && k.flagga === "Svenska", k.flagga);
  }
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
