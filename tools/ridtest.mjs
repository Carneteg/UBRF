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

/* 7. LIVE I SPELET: kopplingen ska vara verklig, inte ett bibliotek ingen
   anropar. Startar en riktig ritt och läser tillstånd + telemetri ur den
   körande loopen. */
const live = await page.evaluate(async () => {
  /* Sätt uppsutten FÖRST, annars kan avsittningssteget aldrig bli rött:
     ett tillstånd som redan är false bevisar inget om startaVandring(). */
  ridSittUpp("bandit", "ridhus");
  const forevandring = RID_TILLSTAND.uppsutten;           // ska vara true
  startaVandring();
  await new Promise(r => setTimeout(r, 400));
  const eftervandring = RID_TILLSTAND.uppsutten;          // ska vara false
  /* Förutsättningarna som skötselflödet normalt sätter innan man rider:
     vald häst och ett RideModel-tillstånd. Det som TESTAS är att den
     körande ridloopen följer gångarten och fyller G.telemetri. */
  G.hastId = G.hastId || Object.keys(HORSES)[0];
  G.hamtad = true;
  G.ride = nyState(G.dagsform, 0.5, G.sadellage);
  sittUpp("ridhus");
  await new Promise(r => setTimeout(r, 1200));
  return { forevandring, eftervandring, uppsutten: RID_TILLSTAND.uppsutten, hast: RID_TILLSTAND.hast,
    telemetri: G.telemetri ? { gangart: G.telemetri.gangart, fart: G.telemetri.fart,
      harledda: G.telemetri._harledda, harHjalper: !!G.telemetri.hjalper } : null };
});
prova("live i spelet: vandring ⇒ avsutten, uppsittning ⇒ uppsutten med häst",
  live.forevandring === true && live.eftervandring === false && live.uppsutten === true && !!live.hast,
  `före ${live.forevandring} → vandring ${live.eftervandring} → ritt ${live.uppsutten}/${live.hast}`);
prova("live i spelet: G.telemetri fylls av den körande ridloopen",
  !!live.telemetri && typeof live.telemetri.fart === "number" && live.telemetri.harHjalper,
  live.telemetri ? `gångart ${live.telemetri.gangart}, fart ${live.telemetri.fart.toFixed(2)}, härledda ${JSON.stringify(live.telemetri.harledda)}` : "G.telemetri saknas");

/* 7a. PRODUKTIONEN KÖR A. Review-only-lagret får inte ändra något utan
   att någon uttryckligen ber om det, så det här fallet kontrollerar att
   sidan utan `?ridab` har exakt Gate 01:s värden — och att B verkligen
   ändrar dem när den väljs, annars vore A/B-underlaget en attrapp. */
const abLage = await page.evaluate(() => {
  const fore = { aktiv: ridAB().namn, kappa: ridAB().KAPPA_MAX,
    galoppSvang: ridAB().GANGSVANG.galopp, galoppMax: Gait.G.galopp.max,
    cykelTrav: Gait.steglangd("hast", "trav", 0.5, 0.15) };
  ridSattAB("B");
  const b = { kappa: ridAB().KAPPA_MAX, galoppSvang: ridAB().GANGSVANG.galopp,
    galoppMax: Gait.G.galopp.max, cykelTrav: Gait.steglangd("hast", "trav", 0.5, 0.15) };
  ridSattAB("A");
  const ater = { kappa: ridAB().KAPPA_MAX, galoppMax: Gait.G.galopp.max,
    cykelTrav: Gait.steglangd("hast", "trav", 0.5, 0.15) };
  return { fore, b, ater };
});
prova("produktionen kör A: Gate 01:s värden gäller utan review-läge",
  abLage.fore.kappa === 0.42 && abLage.fore.galoppSvang === 0.52 && abLage.fore.galoppMax === 8.00,
  `${abLage.fore.aktiv}: κ-tak ${abLage.fore.kappa}, galoppsväng ${abLage.fore.galoppSvang}, galoppband ${abLage.fore.galoppMax}`);
prova("B ändrar faktiskt alla fyra blockerande parametrarna",
  abLage.b.kappa === 0.30 && abLage.b.galoppSvang === 0.62 && abLage.b.galoppMax === 7.00
    && Math.abs(abLage.b.cykelTrav - abLage.fore.cykelTrav) > 0.01,
  `κ-tak ${abLage.b.kappa}, galoppsväng ${abLage.b.galoppSvang}, galoppband ${abLage.b.galoppMax}, cykel trav ${abLage.fore.cykelTrav.toFixed(2)} → ${abLage.b.cykelTrav.toFixed(2)} m`);
prova("A/B är reversibelt: tillbaka till A ger Gate 01:s värden igen",
  abLage.ater.kappa === 0.42 && abLage.ater.galoppMax === 8.00
    && Math.abs(abLage.ater.cykelTrav - abLage.fore.cykelTrav) < 1e-9,
  `κ-tak ${abLage.ater.kappa}, galoppband ${abLage.ater.galoppMax}, cykel trav ${abLage.ater.cykelTrav.toFixed(3)} m`);

/* 7b. ORDNINGEN: tillståndet ska stå INNAN lektionen startar.
   Senior review av #86, blocker C. Startar lektionen först finns ett
   första-bildrutefönster där den körande ridloopen kan läsa uppsutten=false
   och rapportera en avsutten ryttare mitt i en ritt. Testet spionerar på
   startaLektion och läser tillståndet i det ögonblick den anropas — inte
   efteråt, då hade båda ordningarna sett likadana ut. */
const ordning = await page.evaluate(() => {
  ridSittAv();
  G.hastId = G.hastId || Object.keys(HORSES)[0];
  G.hamtad = true;
  G.ride = nyState(G.dagsform, 0.5, G.sadellage);
  const original = window.startaLektion;
  let uppsuttenVidStart = null, hastVidStart = null;
  window.startaLektion = function (...a) {
    uppsuttenVidStart = RID_TILLSTAND.uppsutten;
    hastVidStart = RID_TILLSTAND.hast;
    return original.apply(this, a);
  };
  try { sittUpp("ridhus"); } finally { window.startaLektion = original; }
  return { uppsuttenVidStart, hastVidStart };
});
prova("uppsittningen är etablerad INNAN lektionen startar (inget första-bildrutefönster)",
  ordning.uppsuttenVidStart === true && !!ordning.hastVidStart,
  `vid startaLektion: uppsutten ${ordning.uppsuttenVidStart}, häst ${ordning.hastVidStart}`);

/* 8. VOLTEN — Gate 01:s styrutslag mätt som en RIKTIG BANA, inte som en
   formel. Testet håller ett fast styrutslag och samplar hästens verkliga
   läge (G.px/G.py) ur den körande ridloopen, precis som en ryttare rider
   en volt. Cirkeln anpassas sedan minsta-kvadrat till punkterna.

   Poängen är att stänga hålet #81 blottade: en formel som stämmer bevisar
   inte att banan blir den. Här mäts banan. */

/* Minsta-kvadrat-cirkel (Kåsa): linjär i (a, b, c) för x² + y² + ax + by + c = 0. */
function cirkel(p) {
  let Sx = 0, Sy = 0, Sxx = 0, Syy = 0, Sxy = 0, Sz = 0, Szx = 0, Szy = 0;
  for (const [x, y] of p) {
    const z = x * x + y * y;
    Sx += x; Sy += y; Sxx += x * x; Syy += y * y; Sxy += x * y; Sz += z; Szx += z * x; Szy += z * y;
  }
  const n = p.length;
  const M = [[Sxx, Sxy, Sx], [Sxy, Syy, Sy], [Sx, Sy, n]];
  const v = [-Szx, -Szy, -Sz];
  for (let i = 0; i < 3; i++) {                       // Gauss med pivotering
    let bast = i;
    for (let k = i + 1; k < 3; k++) if (Math.abs(M[k][i]) > Math.abs(M[bast][i])) bast = k;
    [M[i], M[bast]] = [M[bast], M[i]]; [v[i], v[bast]] = [v[bast], v[i]];
    for (let k = i + 1; k < 3; k++) {
      const f = M[k][i] / M[i][i];
      for (let j = i; j < 3; j++) M[k][j] -= f * M[i][j];
      v[k] -= f * v[i];
    }
  }
  const x3 = v[2] / M[2][2];
  const x2 = (v[1] - M[1][2] * x3) / M[1][1];
  const x1 = (v[0] - M[0][1] * x2 - M[0][2] * x3) / M[0][0];
  const cx = -x1 / 2, cy = -x2 / 2;
  const r = Math.sqrt(cx * cx + cy * cy - x3);
  let max = 0;
  for (const [x, y] of p) max = Math.max(max, Math.abs(Math.hypot(x - cx, y - cy) - r));
  return { cx, cy, r, max };
}

/* Rider en volt med givet styrutslag och skänkel. Lägger volten
   koncentriskt med ridhuset innan mätningen — under uppläggningen driver
   ekipaget iväg, och en volt som inte ligger mitt i banan tar i sargen.
   Sargen är kvar och gör fortfarande sitt; testet ser bara till att volten
   får plats. Punkter närmare sargen än `marginal` lämnas utanför
   anpassningen, så att det som mäts är styrningen och inte sargglidningen. */
async function ridVolt(styrutslag, skankel, marginal) {
  return await page.evaluate(async ([styrutslag, skankel, marginal]) => {
    G.hastId = G.hastId || Object.keys(HORSES)[0];
    G.hamtad = true;
    G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.npcs = [];                                   // volten mäter styrning, inte trängsel
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    const h = HORSES[G.hastId];
    const dt = 1 / 60;                             // fast dt: mätningen ska inte bero på SwiftShader
    const satt = () => { RIDIN.skankel = skankel; RIDIN.styr = styrutslag; RIDIN.tygel = 0; RIDIN.sits = 0.5; };

    /* Upp i gångart och låt kurvaturen lägga sig — den tar tag med
       tidskonstant 0,13 s, så en tidig sampling mäter uppläggningen. */
    for (let i = 0; i < 60 * 12; i++) { satt(); stegaRitt(dt); }
    const gangart = G.ride.gangart, tempo = G.ride.tempo, kappa = G.kappa;

    /* Medelpunkten ligger r åt sidan om kursen; G.rikt -= κ·v·dt vrider
       medurs i det här koordinatsystemet. Prova båda tecknen och behåll
       det som ger en medelpunkt mitt i banan. */
    const r = 1 / Math.abs(kappa);
    for (const sida of [1, -1]) {
      const px = 10 - sida * r * Math.sin(G.rikt), py = 30 + sida * r * Math.cos(G.rikt);
      const cx = px + r * Math.sin(G.rikt) * sida, cy = py - r * Math.cos(G.rikt) * sida;
      if (Math.abs(cx - 10) < 0.01 && Math.abs(cy - 30) < 0.01) { G.px = px; G.py = py; break; }
    }

    const alla = [], fria = [];
    for (let i = 0; i < 60 * 24; i++) {
      satt(); stegaRitt(dt);
      if (i % 6) continue;
      alla.push([G.px, G.py]);
      if (G.px > 0.8 + marginal && G.px < 19.2 - marginal
        && G.py > 0.8 + marginal && G.py < 59.2 - marginal) fria.push([G.px, G.py]);
    }
    return { gangart, tempo, kappa, alla, fria,
      kanslighet: h.kanslighet, styrning: G.aids.styrning };
  }, [styrutslag, skankel, marginal]);
}

/* 8a. CIRKELLAGEN, mätt där volten har gott om plats. Full styrning i trav
   ger en liten volt som ryms i ridhuset med marginal, så det som mäts är
   ren styrning. */
{
  const v = await ridVolt(1.0, 0.35, 0.3);
  const c = cirkel(v.fria);
  const vantad = 1 / Math.abs(v.kappa);
  prova("volten: full styrning ger en verklig cirkelbana, inte en ungefärlig båge",
    v.fria.length > 100 && c.max < 0.10,
    `diameter ${(2 * c.r).toFixed(2)} m, största avvikelse ${(c.max * 100).toFixed(1)} cm (${v.fria.length} punkter, ${v.gangart} ${v.tempo.toFixed(2)} m/s)`);
  prova("volten: den RIDNA radien är 1/kurvatur — Gate 01:s formulering, mätt på banan",
    Math.abs(c.r - vantad) / vantad < 0.03,
    `ridd ${c.r.toFixed(2)} m mot 1/κ = ${vantad.toFixed(2)} m (κ ${Math.abs(v.kappa).toFixed(4)} 1/m)`);
}

/* 8b. 0,45 STYRUTSLAG — det utslag Gate 01 mätte. Volten blir här nästan
   exakt ridhusets bredd, så bara den del av bågen som går fri från sargen
   används till anpassningen. Att den inte ryms är ett MÄTRESULTAT och
   rapporteras som ett: en 18-metersvolt i en 18,4 m bred hall rider på
   sargen, precis som den skulle göra i verkligheten. */
{
  const v = await ridVolt(0.45, 0.35, 0.6);
  const c = cirkel(v.fria);
  const vantad = 1 / Math.abs(v.kappa);
  const gv = { halt: 1.00, skritt: 1.00, trav: 0.82, galopp: 0.52 }[v.gangart] || 1.00;
  const tak = 0.42 * gv * (0.78 + 0.44 * Math.min(Math.max(v.kanslighet, 0), 1));

  prova("volten vid 0,45 styrutslag: fri båge följer samma cirkellag",
    v.fria.length > 40 && Math.abs(c.r - vantad) / vantad < 0.05,
    `ridd ${c.r.toFixed(2)} m mot 1/κ = ${vantad.toFixed(2)} m — diameter ${(2 * vantad).toFixed(1)} m i en 18,4 m bred hall (${v.fria.length} fria av ${v.alla.length} punkter)`);

  /* Kurvaturtaket är samma siffror som Roblox turn-faktorer. Att räkna om
     det här är ingen dubblering utan en OBEROENDE kontroll: går taket isär
     från den ridna banan har styrningen slutat följa sin egen design. */
  prova("volten: kurvaturen är styrutslaget × gångartens tak, inte något annat",
    Math.abs(Math.abs(v.kappa) - v.styrning * tak) < 5e-3,
    `κ ${Math.abs(v.kappa).toFixed(4)} ≈ ${v.styrning.toFixed(3)} × ${tak.toFixed(4)} = ${(v.styrning * tak).toFixed(4)} 1/m (${v.gangart})`);
}

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
