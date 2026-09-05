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
/* Mätvärde utan krav. Används där talet ska SYNAS i en körning men var
   gränsen går är game feel och alltså Tobias sak, inte mitt. */
const mat = (namn, detalj) => console.log("  mät ", namn, "—", detalj);

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

/* 3. RIDKÄRNAN KÖRD, efter PO-beslutet 2026-09-05: grundhjälpen är en CUE,
   inte en gaspedal. Provet mätte förut att en HÅLLEN full skänkel klättrade
   hela vägen till galopp — och det var precis den gaspedalen beslutet tog
   bort. Kontraktet är nu ett annat, och strängare på den punkt som betyder
   något för känslan:

     · varje framåtdrivande IMPULS ber om nästa gångart, en i taget,
     · hästen BÄR gångarten vidare utan att hjälpen hålls på ett exakt
       värde, och klättrar inte vidare av sig själv,
     · nedåtgående hjälp tar henne ned igen,
     · ingen gångart hoppas över åt något håll.

   Den mittersta raden är den nya garantin, och den provas uttryckligen
   nedan: efter sista impulsen hålls hjälpen konstant i 20 s och gångarten
   ska ligga still. Kör stepRide med fast dt — samma modell som spelet. */
const loop = await page.evaluate(() => {
  const h = { kanslighet: 0.5, framatbjudning: 0.6, forlatande: 0.6, tyngd: 0.4, skygghet: 0.2, flaggor: {} };
  const s = nyState(0.7, 0.5, 0.8);
  const ctx = { svangradie: 1000, underlag: 0.92, stallro: 0.9, utomhus: false, fard: {}, avdrift: { glid: 0, ryck: 0, tröghet: 1 } };
  const sedda = []; ridSittUpp("test", "ridhus");
  const kor = (aids, sek) => { for (let i = 0; i < sek * 60; i++) {
    stepRide(s, aids, h, ctx, 1 / 60); ridFoljGangart(s.gangart);
    if (sedda[sedda.length - 1] !== s.gangart) sedda.push(s.gangart); } };
  /* Tre impulser upp — GIVNA, inte hållna. Skänkeln läggs på, tas av och
     läggs på igen, som en ryttare gör. Mellan impulserna ligger hjälpen
     på neutral, och det är där hästen ska bära gångarten själv.

     Stegen såg förut ut som en trappa av allt högre HÅLLNA nivåer
     (0,35 → 0,60 → 0,85), och den började dessutom UNDER neutralläget
     0,42 — första steget var alltså ingen framåtimpuls utan en lättnad.
     Det gick igenom så länge cue:n mättes per bildruta från en nolla.
     Med fönstermätningen i P4 mäts resan från det ryttaren faktiskt
     bär, och en trappa av nivåer är inte längre tre impulser. Att ge
     samma impuls tre gånger är både det som fungerar och det som en
     ryttare faktiskt gör.

     Hållet efter stegen är den viktiga delen: samma hjälp i tjugo
     sekunder ska inte ta ett enda steg till. */
  const impulser = [];
  kor({ skankel: 0.42, tygel: 0.20, sits: 0.2, styrning: 0 }, 1);   // neutral först
  for (let n = 0; n < 3; n++) {
    kor({ skankel: 0.66, tygel: 0.20, sits: 0.2, styrning: 0 }, 3);
    impulser.push({ bad: s.malGangart, gick: s.gangart, overgang: +s.senasteOvergang.toFixed(2) });
    if (n < 2) kor({ skankel: 0.42, tygel: 0.20, sits: 0.2, styrning: 0 }, 1);
  }
  const topp = s.gangart, toppFart = s.tempo;
  /* HÅLL. Samma hjälp, tjugo sekunder. Gångarten ska ligga still. */
  const foreHall = s.gangart;
  kor({ skankel: 0.66, tygel: 0.20, sits: 0.2, styrning: 0 }, 20);
  const efterHall = s.gangart, hallFart = s.tempo;
  kor({ skankel: 0.05, tygel: 0.80, sits: 0.85, styrning: 0 }, 25);  // parera ned
  return { sedda, topp, toppFart, impulser, foreHall, efterHall, hallFart,
    slut: s.gangart, glapp: RID_TILLSTAND.glapp };
});
prova("ridkärnan: tre framåtimpulser tar ekipaget upp till galopp",
  loop.topp === "galopp", `nådde ${loop.topp} vid ${loop.toppFart.toFixed(2)} m/s` +
  ` — impulserna bad om ${loop.impulser.map(i => i.bad).join(" → ")}`);
prova("ridkärnan: hästen BÄR gångarten — hållen hjälp klättrar inte vidare",
  loop.foreHall === loop.efterHall,
  `${loop.foreHall} före hållet, ${loop.efterHall} efter 20 s konstant hjälp (fart ${loop.hallFart.toFixed(2)} m/s)`);
prova("ridkärnan: parering tar ekipaget ned till halt igen",
  loop.slut === "halt", `slutgångart ${loop.slut}`);
prova("ridkärnan: inga överhoppade gångarter i någon riktning",
  loop.glapp === 0, `${loop.glapp} olagliga byten, sekvens ${loop.sedda.join(" → ")}`);

/* 3b. SAMMA STEGE, MEN GENOM SPELETS EGET INPUTLAGER.

   Det här provet finns därför att allt ovanför det kan vara grönt medan
   spelet är ospelbart, och var det.

   Proven i 3 anropar stepRide() direkt med hjälper som hoppar färdigt på
   en bildruta. Ingen spelare gör det. I spelet går tangenten eller
   spaken via RIDIN → ridAvsiktTillHjalp() → en ramp med STIG = 0,28 s,
   och först därefter in i modellen. Uppmätt på byggd sida före
   G02-A.1 P4:

     W i botten från stillastående, sex sekunder → hästen stannade i
     skritt. Rampens ändring per bildruta är 0,0595 och tröskeln för en
     framåtimpuls 0,16, så begäran om trav kunde aldrig uppstå.
     Gångartsstegen var onåbar för en spelare, på alla ytor, medan
     ridtest var grönt.

   Därför körs stegen här genom stegaRitt() och RIDIN — samma väg som
   ett tangenttryck. Blir det här provet rött är spelet trasigt även om
   modellproven är gröna. */
const via = await page.evaluate(() => {
  G.hastId = G.hastId || Object.keys(HORSES)[0];
  G.hamtad = true;
  G.npcs = [];
  const dt = 1 / 60;
  const nyRitt = () => { G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp(); };
  const sedda = [];
  const kor = (o, sek) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0;
    RIDIN.sits = o.sits ?? 0; RIDIN.styr = o.styr ?? 0;
    stegaRitt(dt);
    if (sedda[sedda.length - 1] !== G.ride.gangart) sedda.push(G.ride.gangart); } };

  /* a) Sitt upp och gör INGENTING. Filtret bär först ett kraftigt
     BAKÅT-utslag från ett tidigare pass — det är det farliga fallet:
     när ritten börjar rampar hjälpen tillbaka UPP mot neutral av sig
     själv, och den resan läses som en framåtimpuls om ingen nollställer
     filtret först. */
  RIDIN.skankel = -1; for (let i = 0; i < 120; i++) { ridAvsiktTillHjalp(); stegaInput(1 / 60); }
  const kvarliggande = IN.kan.skankel.v;
  nyRitt(); kor({}, 5);
  const stilla = G.ride.gangart;

  /* b) W i botten, hållet. Ett steg upp — inte noll, inte tre. */
  nyRitt(); kor({ skankel: 1 }, 12);
  const hallenW = G.ride.gangart, hallenFart = G.ride.tempo;

  /* c) Tre tryck med släpp emellan, sedan parad ned. */
  nyRitt(); sedda.length = 0; sedda.push(G.ride.gangart);
  for (let n = 0; n < 3; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
  const topp = G.ride.gangart, toppFart = G.ride.tempo;
  kor({ skankel: -1, tygel: 1, sits: 1 }, 25);
  return { stilla, kvarliggande, hallenW, hallenFart, topp, toppFart,
    slut: G.ride.gangart, sedda, glapp: RID_TILLSTAND.glapp };
});
prova("genom inputlagret: uppsittning utan hjälp startar INTE hästen",
  via.stilla === "halt",
  `förra passet lämnade skänkeln på ${via.kvarliggande.toFixed(2)}; ` +
  `fem sekunder utan tangent → ${via.stilla}`);
prova("genom inputlagret: hållen W ger ETT steg upp, inte fler",
  via.hallenW === "skritt",
  `W i botten i 12 s → ${via.hallenW} (${via.hallenFart.toFixed(2)} m/s)`);
prova("genom inputlagret: tre tryck tar ekipaget till galopp",
  via.topp === "galopp", `nådde ${via.topp} vid ${via.toppFart.toFixed(2)} m/s`);
prova("genom inputlagret: parad tar ned till halt utan överhoppade gångarter",
  via.slut === "halt" && via.glapp === 0,
  `${via.sedda.join(" → ")}, ${via.glapp} olagliga byten`);

/* Och att nollställningen verkligen är inkopplad där ritten börjar.
   Provet ovan anropar ridNollstallHjalp() själv och kan därför inte se
   om produktionen glömmer den; det här läser funktionskroppen i den
   körande sidan i stället. Ett grovt prov, men det pinnar just den
   kopplingen — och kopplingen var precis vad som saknades. */
{
  const kopplad = await page.evaluate(() =>
    typeof avslutaSkotsel === "function"
    && /ridNollstallHjalp/.test(avslutaSkotsel.toString()));
  prova("nollställningen är inkopplad där ritten börjar (avslutaSkotsel)",
    kopplad, kopplad ? "avslutaSkotsel anropar ridNollstallHjalp()"
      : "avslutaSkotsel saknar anropet — filtret bär med sig förra passet");
}

/* 3c. NEUTRALLÄGET FINNS PÅ TVÅ STÄLLEN och måste vara samma tal.

   Modellen sår sitt cue-fönster med K.SKANKEL_NEUTRAL/TYGEL/SITS;
   spelet sätter hjälpen ur ridAvsiktTillHjalp(). Modellen kan inte läsa
   spelets inputlager, så kopplingen är ett antagande — och ett antagande
   som glider isär gör exakt det som 3b just beskrev: neutral hjälp läses
   som en impuls, eller en verklig impuls läses som neutral. */
const neutral = await page.evaluate(() => {
  RIDIN.skankel = 0; RIDIN.tygel = 0; RIDIN.sits = 0; RIDIN.styr = 0;
  ridAvsiktTillHjalp();
  return { spel: { skankel: IN.kan.skankel.mal, tygel: IN.kan.tygel.mal, sits: IN.kan.sits.mal },
    modell: { skankel: K.SKANKEL_NEUTRAL, tygel: K.TYGEL_NEUTRAL, sits: K.SITS_NEUTRAL } };
});
{
  const d = k => Math.abs(neutral.spel[k] - neutral.modell[k]);
  prova("neutralläget är samma tal i modellen och i spelets inputlager",
    d("skankel") < 1e-9 && d("tygel") < 1e-9 && d("sits") < 1e-9,
    `skänkel ${neutral.spel.skankel} = ${neutral.modell.skankel}, ` +
    `tygel ${neutral.spel.tygel} = ${neutral.modell.tygel}, ` +
    `sits ${neutral.spel.sits} = ${neutral.modell.sits}`);
}

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

/* 7a. KANONEN ÄR EN, OCH DET GÅR INTE ATT BYTA FYSIK I EN BYGGD SIDA.
   PO-beslutet 2026-09-05 gjorde A till kanon och mergevillkoret i
   docs/G02-A-AB-BESLUTSUNDERLAG.md sa att review-lagret skulle bort.
   Fallet bevakar båda halvorna: värdena är Gate 01:s, OCH switchen är
   verkligen borta — annars kunde en dold alternativ fysik följa med. */
const kanon = await page.evaluate(() => ({
  namn: (typeof ridKanon === "function") ? ridKanon().namn : null,
  kappa: (typeof ridKanon === "function") ? ridKanon().KAPPA_MAX : null,
  galoppSvang: (typeof ridKanon === "function") ? ridKanon().GANGSVANG.galopp : null,
  galoppMax: Gait.G.galopp.max,
  cykelTrav: Gait.steglangd("hast", "trav", 0.5, 0.15),
  switchKvar: typeof ridSattAB !== "undefined" || typeof RID_AB !== "undefined"
    || typeof ridAB !== "undefined",
}));
prova("styrkanonen är Gate 01:s värden, som en enda uppsättning",
  kanon.kappa === 0.42 && kanon.galoppSvang === 0.52 && kanon.galoppMax === 8.00,
  `${kanon.namn}: κ-tak ${kanon.kappa}, galoppsväng ${kanon.galoppSvang}, galoppband ${kanon.galoppMax}, cykel trav ${kanon.cykelTrav.toFixed(2)} m`);
prova("A/B-switchen är borta ur den byggda sidan (mergevillkoret)",
  kanon.switchKvar === false,
  kanon.switchKvar ? "ridAB/ridSattAB/RID_AB finns kvar — dold alternativ fysik" : "varken ridAB, ridSattAB eller RID_AB finns");

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

/* ── DEN VERTIKALA SLICEN (PO 2026-09-05) ──────────────────────────
   Hela kedjan i EN körning, som en lektion: sitt upp → halt → skritt →
   trav → galopp → övergångar → volt → bromsa → halt → sitt av.

   Poängen är inte att varje del fungerar var för sig — det provas ovan —
   utan att de fungerar EFTER VARANDRA, med samma häst och samma
   tillstånd. Det är där en modell brukar spricka: tillstånd som bara
   stämmer när provet börjar om.

   Övergångstiderna redovisas som mätvärden, inte som krav. Vad som är en
   MJUK övergång är game feel och avgörs av Tobias, inte av ett tal jag
   hittar på. Det som grindas är att kedjan går att rida igenom och att
   ingen gångart hoppas över. */
/* 8d. STYRNINGENS KARAKTÄR PER GÅNGART — G02-A.1 P4, genom inputlagret.

   Mätvärdena bor i tools/styrkansla.mjs; kraven bor här. Två egenskaper
   som är lätta att förlora och svåra att upptäcka:

   1. Galoppen ska lägga sig i bågen TRÖGARE än skritten. Det är
      SVANGTAU, och det är halva skillnaden mellan gångarterna i
      styrningen — den andra halvan, hur snävt de alls kan svänga, är
      GANGSVANG och provas i volten ovan. Roblox har samma prov i
      movement.spec; utan det här kan webbens sida kopplas ur medan
      paritetsspecen fortsätter jämföra två tabeller som stämmer.

   2. Kurvaturen ska SÄTTA SIG, inte skjuta över. En båge som svänger
      förbi sitt mål och tillbaka känns som en bil som fiskar.

   Mätt i den byggda sidan, genom RIDIN och stegaRitt — samma väg som
   ett tangenttryck. */
const styr = await page.evaluate(() => {
  G.hastId = G.hastId || Object.keys(HORSES)[0];
  G.hamtad = true; G.npcs = [];
  const dt = 1 / 60;
  /* Upp i gångart med samma tryck som en spelare ger, sedan fullt
     styrutslag från rakt. Mäter tiden till 90 % av slutkurvaturen och
     hur mycket kurvaturen någonsin skjuter förbi den. */
  const bage = (tryck) => {
    G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
    const kor = (sk, st, sek) => { for (let i = 0; i < sek * 60; i++) {
      RIDIN.skankel = sk; RIDIN.styr = st; RIDIN.tygel = 0; RIDIN.sits = 0;
      stegaRitt(dt); } };
    for (let n = 0; n < tryck; n++) { kor(1, 0, 1.5); kor(0, 0, 1.0); }
    kor(0, 0, 2);                                  // rakt, låt kurvaturen dö
    const spar = [];
    for (let i = 0; i < 60 * 5; i++) {
      RIDIN.skankel = 0; RIDIN.styr = 1; RIDIN.tygel = 0; RIDIN.sits = 0;
      stegaRitt(dt); spar.push(Math.abs(G.kappa));
    }
    const slut = spar[spar.length - 1];
    let t90 = null;
    for (let i = 0; i < spar.length; i++) if (spar[i] >= 0.9 * slut) { t90 = i / 60; break; }
    const topp = Math.max(...spar);
    return { t90, slut, over: (topp - slut) / slut * 100, gangart: G.ride.gangart };
  };
  return { skritt: bage(1), galopp: bage(3) };
});
prova("styrningen: galoppen lägger sig i bågen trögare än skritten",
  styr.galopp.t90 > styr.skritt.t90 * 1.15
  && styr.skritt.gangart === "skritt" && styr.galopp.gangart === "galopp",
  `${styr.galopp.gangart} ${styr.galopp.t90.toFixed(3)} s (κ ${styr.galopp.slut.toFixed(3)}) ` +
  `mot ${styr.skritt.gangart} ${styr.skritt.t90.toFixed(3)} s (κ ${styr.skritt.slut.toFixed(3)})`);
prova("styrningen: kurvaturen sätter sig utan att skjuta över",
  styr.skritt.over < 1.0 && styr.galopp.over < 1.0,
  `överslag skritt ${styr.skritt.over.toFixed(2)} %, galopp ${styr.galopp.over.toFixed(2)} %`);

/* 8e. BÅGEN ÄNDRAS ALDRIG FORTARE ÄN HÄSTEN LÄGGER SIG I EN.

   Det här är G02-A.1 P4:s egentliga krav, och det är självrefererande —
   inget tal ur luften. Kurvaturens ändringstakt vid ett RIKTNINGSBYTE
   jämförs med samma takt vid den hårdaste INSVÄNGNINGEN från rakt.
   Bytet får inte vara snabbare, för det är fysiskt samma rörelse: att
   lägga en båge i kroppen.

   Uppmätt före taket infördes: 1,43 gånger snabbare (skritt 1,75 mot
   1,23 1/(m·s)). Det är rycket man känner som skating.

   Marginalen 1,15 är taket självt: KAPPA_RAT_TID är satt med 7–25 %
   luft åt båda håll så att en vanlig insvängning aldrig bromsas.

   Dessutom att bytet passerar RAKT — byter kurvaturen tecken utan att
   vara nära noll har hästen vikt sig i stället för att svänga. */
const byte = await page.evaluate(() => {
  const dt = 1 / 60;
  const nyRitt = () => { G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp(); };
  const kor = (sk, st, sek, ut) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = sk; RIDIN.styr = st; RIDIN.tygel = 0; RIDIN.sits = 0;
    stegaRitt(dt); if (ut) ut.push(G.kappa); } };
  const takt = spar => { let m = 0;
    for (let i = 1; i < spar.length; i++) m = Math.max(m, Math.abs(spar[i] - spar[i - 1]) / dt);
    return m; };

  /* Hårdaste insvängningen från rakt: fullt utslag, ingen tidigare båge. */
  nyRitt(); kor(1, 0, 1.5); kor(0, 0, 1.0); kor(0, 0, 2);
  const in_ = []; kor(0, 1, 4, in_);

  /* Riktningsbytet: etablerad full vänster, sedan fullt höger. */
  nyRitt(); kor(1, 0, 1.5); kor(0, 0, 1.0);
  kor(0, -1, 4);
  const fore = G.kappa, spar = [];
  kor(0, 1, 4, spar);
  return { fore, efter: G.kappa, taktIn: takt(in_), taktByte: takt(spar),
    nara: spar.filter(k => Math.abs(k) < 0.02).length };
});
prova("styrningen: bågen ändras aldrig fortare vid ett byte än vid en insvängning",
  byte.taktByte <= byte.taktIn * 1.15,
  `byte ${byte.taktByte.toFixed(3)} mot insvängning ${byte.taktIn.toFixed(3)} 1/(m·s) ` +
  `= ${(byte.taktByte / byte.taktIn).toFixed(2)}×`);
prova("styrningen: riktningsbytet passerar rakt i stället för att hoppa över",
  byte.fore * byte.efter < 0 && byte.nara >= 1,
  `κ ${byte.fore.toFixed(3)} → ${byte.efter.toFixed(3)}, ` +
  `${byte.nara} bildrutor inom ±0,02 av rakt`);

const slice = await page.evaluate(() => {
  const h = { kanslighet: 0.5, framatbjudning: 0.6, forlatande: 0.6, tyngd: 0.4, skygghet: 0.2, flaggor: {} };
  const s = nyState(0.7, 0.5, 0.8);
  const ctx = { svangradie: 1000, underlag: 0.92, stallro: 0.9, utomhus: false, fard: {}, avdrift: { glid: 0, ryck: 0, tröghet: 1 } };
  const steg = [];
  ridSittUpp("bandit", "ridhus");
  const uppe = RID_TILLSTAND.uppsutten;
  const kor = (aids, sek) => { for (let i = 0; i < sek * 60; i++) {
    stepRide(s, aids, h, ctx, 1 / 60); ridFoljGangart(s.gangart); } };
  const notera = (vad) => steg.push({ vad, gangart: s.gangart, bad: s.malGangart,
    tempo: +s.tempo.toFixed(2), overgang: +s.senasteOvergang.toFixed(2) });

  kor({ skankel: 0, tygel: 0.15, sits: 0.2, styrning: 0 }, 2);   notera("halt");
  kor({ skankel: 0.35, tygel: 0.15, sits: 0.2, styrning: 0 }, 5); notera("skritt");
  kor({ skankel: 0.60, tygel: 0.15, sits: 0.2, styrning: 0 }, 5); notera("trav");
  kor({ skankel: 0.85, tygel: 0.15, sits: 0.2, styrning: 0 }, 5); notera("galopp");
  /* Volt i galopp: full styrning, och kurvaturen ska följa gångartens tak. */
  kor({ skankel: 0.85, tygel: 0.15, sits: 0.2, styrning: 1.0 }, 4);
  const voltKappa = 0.42 * 0.52 * (0.78 + 0.44 * 0.5);
  notera("volt");
  kor({ skankel: 0.85, tygel: 0.15, sits: 0.2, styrning: 0 }, 2);
  /* Bromsa: hållen parad tar henne hela vägen ned. */
  kor({ skankel: 0.05, tygel: 0.80, sits: 0.85, styrning: 0 }, 20); notera("halt igen");
  ridSittAv();
  return { uppe, av: RID_TILLSTAND.uppsutten, steg, glapp: RID_TILLSTAND.glapp, voltKappa };
});
{
  const g = slice.steg.map(r => r.gangart);
  const naddeAlla = g[0] === "halt" && g[1] === "skritt" && g[2] === "trav"
    && g[3] === "galopp" && g[g.length - 1] === "halt";
  prova("slicen: sitt upp → halt → skritt → trav → galopp → volt → broms → halt → sitt av",
    slice.uppe === true && slice.av === false && naddeAlla && slice.glapp === 0,
    `uppsutten ${slice.uppe} → ${slice.av}, kedja ${g.join(" → ")}, ${slice.glapp} olagliga byten`);
  const tider = slice.steg.filter(r => r.overgang > 0).map(r => `${r.vad} ${r.overgang}s`);
  mat("slicens övergångstider (mätvärden — vad som är MJUKT avgör Tobias)",
    tider.length ? tider.join(", ") : "inga övergångar registrerade");
  mat("slicens tempon per moment",
    slice.steg.map(r => `${r.vad} ${r.tempo} m/s`).join(", "));
}

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
