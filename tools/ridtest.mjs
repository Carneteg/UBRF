#!/usr/bin/env node
/* G02-A — regressionstest för ridkärnan (issue #82).

   Kör den KANONISKA ridkärnan (Gait + stepRide ur src/model.js) i den
   byggda sidan och låser Gate 01:s uppmätta känsla, så att G02-A:s
   konsolidering inte råkar ändra ridningen. Testar dessutom det nya
   tillstånds-/telemetrikontraktet i src/riding/telemetri.js.

   Kör: python3 tools/build.py && node tools/ridtest.mjs */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";
const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist"), PORT = 8820;
const srv = http.createServer((q, s) => {
  const p = path.join(DIST, decodeURIComponent(q.url.split("?")[0] === "/" ? "/ridskolan.html" : q.url.split("?")[0]));
  fs.readFile(p, (e, d) => { if (e) { s.writeHead(404); s.end(); return; } s.writeHead(200, { "content-type": "text/html" }); s.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--use-angle=swiftshader", "--no-sandbox", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage();
page.on("pageerror", e => console.log("PAGEERROR", e.message));
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(1500);
const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push({ namn, ok }); console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };

/* 1. GATE 01-BASELINE: gångarternas normtempon och band får inte glida.
   Siffrorna står i audits/GATE-01-RIDING-FEEL-RESULT.md. */
const g = await page.evaluate(() => ({ G: Gait.G, hyst: Gait.HYST, sprang: Gait.SPRANG }));
prova("Gate 01: normtempon oförändrade (skritt 1,45 · trav 3,20 · galopp 5,60 m/s)",
  g.G.skritt.norm === 1.45 && g.G.trav.norm === 3.20 && g.G.galopp.norm === 5.60,
  `${g.G.skritt.norm} / ${g.G.trav.norm} / ${g.G.galopp.norm}`);
prova("Gate 01: gångartsbanden och hysteresen oförändrade",
  g.G.skritt.min === 0.90 && g.G.trav.max === 4.30 && g.hyst === 0.35,
  `skritt.min ${g.G.skritt.min}, trav.max ${g.G.trav.max}, hyst ${g.hyst}`);

/* 2. GÅNGARTSTRAPPAN ur tempo, med hysteres — kärnans egen state machine. */
const trappa = await page.evaluate(() => {
  const ut = []; let nuv = "halt";
  for (const t of [0, 1.4, 3.2, 5.6, 3.2, 1.4, 0]) { nuv = Gait.forTempo(t, nuv); ut.push(nuv); }
  return ut;
});
prova("halt → skritt → trav → galopp → trav → skritt → halt ur tempo",
  JSON.stringify(trappa) === JSON.stringify(["halt", "skritt", "trav", "galopp", "trav", "skritt", "halt"]),
  trappa.join(" → "));

/* 3. RIDKÄRNAN KÖRD: full skänkel från halt ska ta ekipaget genom
   gångarterna utan att hoppa över någon, och sedan ned igen. Kör
   stepRide med fast dt — samma modell som spelet, utan UI. */
const loop = await page.evaluate(() => {
  const h = { kanslighet: 0.5, framatbjudning: 0.6, forlatande: 0.6, tyngd: 0.4, skygghet: 0.2, flaggor: {} };
  const s = nyState(0.7, 0.5, 0.8);
  const ctx = { svangradie: 1000, underlag: 0.92, stallro: 0.9, utomhus: false, fard: {}, avdrift: { glid: 0, ryck: 0, tröghet: 1 } };
  const sedda = []; ridSittUpp("test", "ridhus");
  const kor = (aids, sek) => { for (let i = 0; i < sek * 60; i++) {
    stepRide(s, aids, h, ctx, 1 / 60); ridFoljGangart(s.gangart);
    if (sedda[sedda.length - 1] !== s.gangart) sedda.push(s.gangart); } };
  kor({ skankel: 0.78, tygel: 0.34, sits: 0.2, styrning: 0 }, 25);   // be om framåt
  const topp = s.gangart, toppFart = s.tempo;
  kor({ skankel: 0.05, tygel: 0.80, sits: 0.85, styrning: 0 }, 25);  // parera ned
  return { sedda, topp, toppFart, slut: s.gangart, glapp: RID_TILLSTAND.glapp };
});
prova("ridkärnan: full skänkel tar ekipaget upp till galopp",
  loop.topp === "galopp", `nådde ${loop.topp} vid ${loop.toppFart.toFixed(2)} m/s`);
prova("ridkärnan: parering tar ekipaget ned till halt igen",
  loop.slut === "halt", `slutgångart ${loop.slut}`);
prova("ridkärnan: inga överhoppade gångarter i någon riktning",
  loop.glapp === 0, `${loop.glapp} olagliga byten, sekvens ${loop.sedda.join(" → ")}`);

/* 4. ÖVERGÅNGSKONTRAKTET dömer rätt. */
const kontrakt = await page.evaluate(() => ({
  grann: ridLagligtByte("skritt", "trav"),
  stanna: ridLagligtByte("galopp", "halt"),
  hopp: ridLagligtByte("halt", "galopp"),
  upp2: ridLagligtByte("skritt", "galopp"),
}));
prova("övergångskontraktet: grannbyten och stopp lagliga, hopp uppåt inte",
  kontrakt.grann && kontrakt.stanna && !kontrakt.hopp && !kontrakt.upp2,
  JSON.stringify(kontrakt));

/* 5. TELEMETRIN har de fält G02-B/C ska bedöma på, och härledda fält är märkta. */
const tm = await page.evaluate(() => {
  const h = { kanslighet: 0.5, framatbjudning: 0.6, forlatande: 0.6, tyngd: 0.4, skygghet: 0.2, flaggor: {} };
  const s = nyState(0.7, 0.5, 0.8);
  const ctx = { svangradie: 1000, underlag: 0.92, stallro: 0.9, utomhus: false, fard: {}, avdrift: { glid: 0, ryck: 0, tröghet: 1 } };
  const aids = { skankel: 0.78, tygel: 0.34, sits: 0.2, styrning: 0.45 };
  for (let i = 0; i < 600; i++) stepRide(s, aids, h, ctx, 1 / 60);
  ridSittUpp("test", "ridhus"); ridFoljGangart(s.gangart);
  return ridTelemetri(s, aids, { kappa: 0.1, fas: 0.25, onskadFart: 3.2 });
});
const kravda = ["uppsutten", "gangart", "fart", "onskadFart", "kurvatur", "svangradie",
  "vridhastighet", "rytm", "spanning", "balans", "fokus", "hjalper"];
const saknas = kravda.filter(k => tm[k] === undefined);
prova("telemetrin exponerar gångart, fart/önskad fart, kurvatur, rytm, balans, fokus och hjälper",
  saknas.length === 0, saknas.length ? "saknas: " + saknas.join(", ") : `gångart ${tm.gangart}, fart ${tm.fart.toFixed(2)}, radie ${tm.svangradie.toFixed(1)} m`);
prova("telemetrin: vridhastighet = kurvatur × tempo (Gate 01:s formulering)",
  Math.abs(tm.vridhastighet - 0.1 * tm.fart) < 1e-9, `${tm.vridhastighet.toFixed(3)} rad/s`);
prova("telemetrin märker härledda fält i stället för att låtsas att de är mätta",
  Array.isArray(tm._harledda) && tm._harledda.includes("balans") && tm._harledda.includes("fokus"),
  JSON.stringify(tm._harledda));

/* 6. UPPSITTNING/AVSITTNING som riktigt tillstånd. */
const mount = await page.evaluate(() => { ridSittUpp("bandit", "ridhus");
  const a = { ...RID_TILLSTAND }; ridSittAv(); return { a, b: { ...RID_TILLSTAND } }; });
prova("uppsittning/avsittning är ett tillstånd, inte bara en scen",
  mount.a.uppsutten === true && mount.a.hast === "bandit" && mount.b.uppsutten === false,
  `upp: ${mount.a.uppsutten}/${mount.a.hast} → av: ${mount.b.uppsutten}`);

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
