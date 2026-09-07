#!/usr/bin/env node
/* BOOTKOLL — startar den OBUNDLADE distributionen, den som previewen serverar.

   Varför den behövs: regressionssviterna (ridtest, gardtest, laktartest,
   ugneta-*) bootar alla `dist/ridskolan.html`, alltså den BUNDLADE sidan som
   tools/build.py skriver. Vercel-previewen serverar något annat — repots
   `index.html` med 36 separata `<script src="src/...">`. Två distributioner
   av samma källor, och bara den ena var provad. Ett fel som bara syns i
   laddordningen mellan skripttaggarna hade alltså kunnat gå grönt genom hela
   CI och ändå möta spelaren i previewen.

   Provet är avsiktligt trubbigt. Det mäter inte spelkänsla — det mäter att
   sidan STARTAR: inga 404, inga pageerrors, inga console.error, spelets
   kärnobjekt finns och hästdatan är laddad.

   Kör: node tools/bootkoll.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const PORT = 8831;
const typ = f => f.endsWith(".js") ? "text/javascript"
  : f.endsWith(".css") ? "text/css"
  : f.endsWith(".json") ? "application/json" : "text/html";

const srv = http.createServer((q, s) => {
  const rel = decodeURIComponent(q.url.split("?")[0]);
  const p = path.join(ROT, rel === "/" ? "/index.html" : rel);
  if (!p.startsWith(ROT)) { s.writeHead(403); s.end(); return; }
  fs.readFile(p, (e, d) => {
    if (e) { s.writeHead(404); s.end(); return; }
    s.writeHead(200, { "content-type": typ(p) }); s.end(d);
  });
});
await new Promise(r => srv.listen(PORT, r));

const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage();

const pagefel = [], konsolfel = [], trasiga = [];
page.on("pageerror", e => pagefel.push(e.message));
page.on("console", m => { if (m.type() === "error") konsolfel.push(m.text()); });
page.on("response", r => { if (r.status() >= 400) trasiga.push(r.status() + " " + r.url()); });

await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(4000);

/* Läsningen får INTE kasta. Ett saknat globalt objekt ska bli ett rött prov
   som pekar på vad som saknas — inte en ReferenceError som dödar körningen
   innan de senare proven hunnit säga något. Mätt under falsifieringen: med
   src/model.js bortkopplad ur index.html dog ett tidigare utkast på
   "G is not defined" och rapporterade aldrig de 404 som var orsaken. */
const las = async uttryck => {
  try { return await page.evaluate(uttryck); } catch { return null; }
};
const ut = {
  titel:   await las(() => document.title),
  canvas:  await las(() => !!document.querySelector("canvas")),
  G:       await las(() => typeof G !== "undefined" ? "finns" : "saknas"),
  scen:    await las(() => typeof G !== "undefined" ? G.scen : null),
  hastar:  await las(() => typeof HORSES !== "undefined" ? Object.keys(HORSES).length : null),
  text:    await las(() => (document.body.innerText || "").replace(/\s+/g, " ").trim().slice(0, 100)),
};

const resultat = [];
const prova = (namn, ok, detalj) => {
  resultat.push(ok); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj);
};

prova("sidan svarar med rätt titel", ut.titel === "Ridskolan", String(ut.titel));
prova("inga 404/5xx bland de 36 skripttaggarna", trasiga.length === 0,
      trasiga.length ? trasiga.slice(0, 4).join(" · ") : "0 trasiga svar");
prova("inga pageerrors under starten", pagefel.length === 0,
      pagefel.length ? pagefel.slice(0, 3).join(" · ") : "0");
prova("inga console.error under starten", konsolfel.length === 0,
      konsolfel.length ? konsolfel.slice(0, 3).join(" · ") : "0");
prova("spelets kärnobjekt finns", ut.G === "finns", `G ${ut.G} · scen ${ut.scen}`);
prova("hästkanonen är laddad", ut.hastar === 33, `${ut.hastar} hästar`);
prova("en canvas att rita i", ut.canvas === true, String(ut.canvas));
prova("spelets egen text är utritad", typeof ut.text === "string" && /GÅNGART|BANA/.test(ut.text),
      JSON.stringify(ut.text));

await browser.close(); srv.close();
const fel = resultat.filter(r => !r).length;
console.log(fel === 0 ? `\nALLA OK (${resultat.length} mätningar)` : `\n${fel} FEL av ${resultat.length}`);
process.exit(fel === 0 ? 0 : 1);
