#!/usr/bin/env node
/* UTRUSTNINGSTEST — EQUIPMENT & RIDER GEAR GATE (#165), webbens halva.
   Hjälmen är spelarens utrustning (`G.hjalmPa`): den krävs för att sitta
   upp, följer med sadel och träns från sadelkammaren, och går att ta av
   och på i boxmenyn. Provet går genom spelets riktiga knappar och
   `sittUpp()` — inte genom att sätta `G.ride` för hand.
   Kör: python3 tools/build.py && node tools/utrustningstest.mjs
   Kräver Playwright + Chromium (samma harness som gangtest.mjs). */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = +(process.env.PORT || 8797);
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

let fel = 0;
function prova(vad, ok, extra) {
  console.log(`${ok ? "  OK  " : "  FEL "} ${vad}${extra ? "  " + extra : ""}`);
  if (!ok) fel++;
}
const ev = (fn) => page.evaluate(fn);

/* Startläge: vandringen igång, en tilldelad häst, skötseln gjord — allt
   utom hjälmen. Ett rent genvägsläge för sittUpp(); det är hjälmregeln
   som mäts, inte vägen dit (den mäts av uppdragstest). */
await ev(() => { startaVandring(); });
await page.waitForTimeout(400);
await ev(() => {
  G.hastId = G.hastId || Object.keys(HORSES)[0];
  G.hastMott = true; G.utrustning = true; G.skotselRes = { dagsform: 0.7 };
  G.hastPlats = "leds"; G.scen = "ridhusinne"; G.hjalmPa = false;
});

/* 1. Utan hjälm: sittUpp nekar, scenen står kvar, texten är kanonens. */
const utan = await ev(() => {
  const fore = G.scen; sittUpp("ridhus");
  const el = document.getElementById("saga") || document.querySelector(".saga");
  return { scen: G.scen, ride: !!G.ride, fore, text: el ? el.textContent : "" };
});
prova("utan hjälm nekar sittUpp() — scenen står kvar och ingen ritt startas",
  utan.scen === utan.fore && !utan.ride, JSON.stringify(utan));
prova("och nejet är kanonens: tack.saknar_hjalm",
  /hjälmen på innan du sitter upp/i.test(utan.text) || /helmet on before/i.test(utan.text), JSON.stringify(utan.text));

/* 2. Boxmenyn: en riktig knapp tar på hjälmen, och tar av den igen. */
const knapp = await ev(() => {
  visaBoxmeny();
  const b = document.getElementById("bHjalm");
  const fore = b ? b.textContent : "";
  if (b) b.click();
  const efter = G.hjalmPa;
  const b2 = document.getElementById("bHjalm");
  const text2 = b2 ? b2.textContent : "";
  if (b2) b2.click();
  const av = G.hjalmPa;
  const b3 = document.getElementById("bHjalm");
  if (b3) b3.click();
  overlay(false);
  return { fore, efter, text2, av, slut: G.hjalmPa };
});
prova("boxmenyn har en hjälmknapp som säger 'Ta på hjälmen' när den är av",
  /ta på hjälmen/i.test(knapp.fore), JSON.stringify(knapp.fore));
prova("ett tryck tar på hjälmen", knapp.efter === true);
prova("knappen byter till 'Ta av hjälmen' och ett tryck tar av den — ångra utan omstart",
  /ta av hjälmen/i.test(knapp.text2) && knapp.av === false, JSON.stringify(knapp.text2));
prova("och på igen", knapp.slut === true);

/* 3. Med hjälmen på går uppsittningen igenom (utan tävling → lektion). */
const med = await ev(() => { G.tavling = null; const fore = G.scen; sittUpp("ridhus"); return { fore, scen: G.scen }; });
prova("med hjälmen på startar sittUpp() ritten — scenen blir lektion", med.scen === "lektion", JSON.stringify(med));

/* 4. Sadelkammaren: utrustningen från den egna bygeln tar hjälmen med sig. */
await page.reload({ waitUntil: "load" });
await page.waitForTimeout(1200);
const pickup = await ev(() => {
  startaVandring();
  G.hastId = G.hastId || Object.keys(HORSES)[0]; G.hastMott = true; G.hjalmPa = false;
  visaSadelkammare();
  const h = G.hastId;
  const sadel = document.querySelector(`.sk-val[data-typ="sadel"][data-id="${h}"]`);
  const trans = document.querySelector(`.sk-val[data-typ="trans"][data-id="${h}"]`);
  if (sadel) sadel.click(); if (trans) trans.click();
  const klar = document.getElementById("bSkKlar");
  if (klar) klar.click();
  return { utrustning: G.utrustning, hjalm: G.hjalmPa, hittade: !!(sadel && trans && klar) };
});
if (pickup.hittade) {
  prova("sadelkammarens 'Ta med utrustningen' tar hjälmen med sig", pickup.utrustning === true && pickup.hjalm === true, JSON.stringify(pickup));
} else {
  console.log("  --   sadelkammarens val hittades inte via data-attribut; pickup-vägen mäts av forstadagentest/lastlagetest", JSON.stringify(pickup));
}

/* 5. Dagsstarten nollar hjälmen (`startaVandring` är dagens början):
   hjälmen på igen innan ritt, varje dag. */
const nyDag = await ev(() => { G.hjalmPa = true; startaVandring(); return G.hjalmPa; });
prova("en ny dag börjar utan hjälmen på", nyDag === false);

await browser.close(); srv.close();
if (fel > 0) { console.log(`\n${fel} mätning(ar) föll.`); process.exit(1); }
console.log("\nALLA OK (utrustningstest)");
