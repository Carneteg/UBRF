#!/usr/bin/env node
/* G02-E DEL 1 — RYTTARVYN, MÄTT PÅ DET SOM FAKTISKT RENDERAS (#150).

   `kameralagetest.mjs` mäter tillståndsmaskinen. Den kan vara helt grön
   medan bilden fortfarande visar den gamla tredjepersonskameran — det är
   precis det felet som fälldes i korrigeringen av min första ACK: ett
   läge som HETER `ryttare` men behåller bommen 4 m bakom hästen. Ett
   tillståndstest hade inte sett skillnaden.

   Den här filen mäter därför vad som går IN I RENDERAREN. Den lägger en
   spion på `GL.kamera` — den enda vägen till projektionen — kör spelets
   egen bildruta `rita3D()` i en riktig webbläsare med riktig WebGL, och
   läser de argument bilden faktiskt ritades med.

   Fem saker måste stämma samtidigt:

     1. ögat ligger i ryttarens ögonpunkt ur riggen,
     2. ögat ligger INTE på den gamla bommen,
     3. hästens hals ligger i synfältet — man sitter på henne, hon är
        inte bortklippt,
     4. ditt eget huvud ritas inte ovanpå objektivet,
     5. blicken pekar dit hästen går.

   Sist körs två FALSIFIERINGAR i den riktiga sidan: fel standardvy och
   utebliven återgång. Båda ska fälla sin mätning.

   Kör: python3 tools/build.py && node tools/ryttarvytest.mjs */
import { oppnaWebb } from "./qa-webb.mjs";

const webb = await oppnaWebb({ port: 8798 });
const { page } = webb;
const ev = (f, a) => page.evaluate(f, a);

let fel = 0, matt = 0;
function prova(namn, ok, detalj) {
  matt++;
  if (!ok) fel++;
  console.log(ok ? "  OK  " : "  FEL ", namn, detalj === undefined ? "" : `— ${detalj}`);
}
const avst = (a, b) => Math.hypot(a[0] - b[0], a[1] - b[1], a[2] - b[2]);

/* ══ PRODUKTIONSVÄGEN IN I EN LEKTION ══════════════════════════════
   Ridläraren delar ut en häst ur den RIKTIGA poolen, skötseln bygger
   ridtillståndet, ryttaren sitter upp och lektionen startar — samma
   anrop i samma ordning som spelet gör dem. Ingen handbyggd G. */
const boot = await ev(() => {
  try {
    const pool = hastpool(G.grupp);
    sattAktivHast(pool[0]);
    G.hastMott = true; G.utrustning = true; G.hastPlats = "leds";
    visaSkotsel();                 // sätter G.ride = nyState(...)
    overlay(false);
    ridSittUpp(G.hastId, "ridhus");
    startaLektion();               // sätter G.scen och nollar kameraläget
    G.plats = "ridhus";
    return { ok: true, hast: G.hastId, scen: G.scen, harRide: !!G.ride,
      uppsutten: ridTelemetri().uppsutten };
  } catch (e) { return { ok: false, fel: e.message }; }
});
prova("produktionsvägen ger en riktig, uppsutten ritt",
  boot.ok && boot.harRide && boot.uppsutten && (boot.scen === "lektion" || boot.scen === "bana"),
  boot.ok ? `${boot.hast} · scen ${boot.scen}` : boot.fel);
if (!boot.ok) { await webb.stang(); process.exit(1); }

/* Spionen på GL.kamera. Allt som ritas passerar här; det finns ingen
   annan väg till projektionsmatrisen. */
await ev(() => {
  window.__spion = [];
  const orig = GL.kamera.bind(GL);
  GL.kamera = (oga, mal, fov) => {
    window.__spion.push({ oga: [oga[0], oga[1], oga[2]], mal: [mal[0], mal[1], mal[2]], fov });
    return orig(oga, mal, fov);
  };
});

/* Spelets egen bildruta, flera gånger med riktig tid emellan så att
   utjämningen hinner sätta sig. */
async function bildrutor(n = 12, ms = 32) {
  for (let i = 0; i < n; i++) {
    await ev(() => { try { rita3D(G); } catch (e) { window.__ritfel = e.message; } });
    await page.waitForTimeout(ms);
  }
}
await bildrutor();

const ritfel = await ev(() => window.__ritfel || null);
prova("3D-bildrutan ritas utan fel", ritfel === null, ritfel || "inga undantag");

/* ══ MÄTNINGEN ═════════════════════════════════════════════════════ */
async function mat() {
  return ev(() => {
    const s = window.__spion[window.__spion.length - 1];
    if (!s) return null;
    const oga = s3MinOgonpunkt(), hals = s3MinHalsPunkt();
    /* Den gamla bomvyn, räknad ur SAMMA kanon som förut — så att
       "kameran står inte där längre" mäts mot det verkliga talet och
       inte mot en siffra jag skrivit i testet. */
    const KG = KAM_GANG[(G.ride && G.ride.gangart) || "halt"] || KAM_GANG.skritt;
    const b = [Math.cos(S3.kam.yaw), 0, Math.sin(S3.kam.yaw)];
    const bom = [G.px - b[0] * KG.bak, KG.hojd, G.py - b[2] * KG.bak];
    return {
      kamera: s.oga, mal: s.mal, fov: s.fov,
      oga: oga ? [oga.x, oga.y, oga.z] : null,
      hals: hals ? [hals.x, hals.y, hals.z] : null,
      bom, bak: KG.bak,
      hast: [G.px, G.py], rikt: G.rikt, gangart: (G.ride && G.ride.gangart) || "halt",
      lage: S3.kam.lage, vikt: S3.kam.vikt, vinkel: S3.kam.vinkel,
      egetHuvud: S3.kam.egetHuvud,
      sadelFov: KAM_SADEL.FOV, bomFov: 1.02 + KG.fov,
    };
  });
}
const m = await mat();
prova("kameran ritades minst en gång", m !== null);

/* 1. ÖGAT ÄR RYTTARENS. Toleransen är utjämningens eget spelrum i
      höjdled (TAK_Y) plus en marginal — inte ett tal valt för att
      passa. */
{
  const d = avst(m.kamera, m.oga);
  prova("renderaren fick ryttarens ögonpunkt, inte något annat", d < 0.25,
    `${d.toFixed(3)} m från ögat (${m.oga.map(n => n.toFixed(2)).join(", ")})`);
}

/* 2. ÖGAT ÄR INTE BOMMEN. Det här är provet som skulle ha fällt min
      första ACK. */
{
  const d = avst(m.kamera, m.bom);
  prova("kameran står INTE på den gamla bommen bakom hästen", d > 2.5,
    `${d.toFixed(2)} m från bompunkten (bommen är ${m.bak.toFixed(2)} m bak)`);
  const platt = Math.hypot(m.kamera[0] - m.hast[0], m.kamera[2] - m.hast[1]);
  prova("kameran sitter på hästen, inte bakom henne", platt < 0.7,
    `${platt.toFixed(3)} m från hästens mitt i planet`);
  prova("ögat är i ryttarhöjd över marken", m.kamera[1] > 1.9 && m.kamera[1] < 2.8,
    `${m.kamera[1].toFixed(2)} m`);
}

/* 3. HÄSTEN SYNS. Halsen ska ligga i synfältet och framför kameran —
      annars är det ingen ryttarvy, det är en svävande kamera. */
{
  const f = [m.mal[0] - m.kamera[0], m.mal[1] - m.kamera[1], m.mal[2] - m.kamera[2]];
  const fl = Math.hypot(...f); const fn = f.map(x => x / fl);
  const h = [m.hals[0] - m.kamera[0], m.hals[1] - m.kamera[1], m.hals[2] - m.kamera[2]];
  const hl = Math.hypot(...h); const hn = h.map(x => x / hl);
  const vinkel = Math.acos(Math.max(-1, Math.min(1, fn[0] * hn[0] + fn[1] * hn[1] + fn[2] * hn[2])));
  const halvFov = m.fov / 2;
  prova("hästens hals ligger i synfältet under blicken",
    vinkel < halvFov && hl > 0.12,
    `${(vinkel * 180 / Math.PI).toFixed(1)}° från blickmitten, halva synfältet ${(halvFov * 180 / Math.PI).toFixed(1)}° · avstånd ${hl.toFixed(2)} m`);
  prova("halsen ligger utanför närplanet (0,12 m) och klipps inte", hl > 0.12,
    `${hl.toFixed(2)} m`);
}

/* 4. DITT EGET HUVUD RITAS INTE ÖVER OBJEKTIVET. */
prova("eget huvud, hår och hjälm är bortkopplade i sadeln", m.egetHuvud === 0,
  `alfa ${m.egetHuvud}`);

/* 5. BLICKEN PEKAR DIT HÄSTEN GÅR, något nedåt. */
{
  const f = [m.mal[0] - m.kamera[0], m.mal[1] - m.kamera[1], m.mal[2] - m.kamera[2]];
  const platt = Math.hypot(f[0], f[2]);
  const kurs = [Math.cos(m.rikt), Math.sin(m.rikt)];
  const dot = (f[0] / platt) * kurs[0] + (f[2] / platt) * kurs[1];
  prova("blicken följer färdriktningen", dot > 0.96, `cos ${dot.toFixed(4)}`);
  const ned = -Math.atan2(f[1], platt) * 180 / Math.PI;
  prova("blicken lutar svagt nedåt så att vägen framför syns",
    ned > 0.5 && ned < 9, `${ned.toFixed(2)}° under horisonten`);
}

/* 6. LÄGET SÄGER SADEL, OCH SYNFÄLTET ÄR SADELNS. */
prova("kameraläget rapporterar ryttarperspektiv med vikt 0",
  m.lage === "ryttare" && m.vikt === 0 && m.vinkel === null,
  `${m.lage} · vikt ${m.vikt}`);
prova("synfältet är sadelns, inte bommens",
  Math.abs(m.fov - m.sadelFov) < 0.02 && m.fov > m.bomFov,
  `${m.fov.toFixed(3)} rad (sadel ${m.sadelFov.toFixed(3)}, bom ${m.bomFov.toFixed(3)})`);

/* ══ FEEDBACKVYN: UT OCH TILLBAKA I DEN RIKTIGA KAMERAN ════════════
   Här stegas spelets egen `s3Kamera(dt)` med fast dt. Det är samma
   funktion bildrutan använder — bara med en klocka vi styr, så att
   mätningen blir deterministisk i stället för att jaga wall-clock. */
const cykel = await ev(() => {
  const ut = { top: 0, topAvstOga: 0, slutAvstOga: 0, ramar: 0, vikter: [] };
  Kameralage.nollstall(Kameralage.ritten, "test");
  S3.kam.satt = false;
  s3Kamera(1 / 60);
  Kameralage.begar(Kameralage.ritten, "utifran", "test");
  for (let i = 0; i < 60 * 8; i++) {
    const k = s3Kamera(1 / 60);
    const oga = s3MinOgonpunkt();
    const d = Math.hypot(k.x - oga.x, k.y - oga.y, k.z - oga.z);
    ut.vikter.push(k.vikt);
    if (k.vikt > ut.top) { ut.top = k.vikt; ut.topAvstOga = d; }
    ut.slutAvstOga = d;
    ut.ramar++;
    if (k.vikt === 0 && i > 30) { ut.klarVid = i / 60; break; }
  }
  ut.slutLage = S3.kam.lage; ut.slutVikt = S3.kam.vikt;
  ut.aktiv = Kameralage.aktiv(Kameralage.ritten);
  return ut;
});
prova("en begärd feedbackvinkel flyttar den RIKTIGA kameran bort från sadeln",
  cykel.top > 0.99 && cykel.topAvstOga > 2.5,
  `vikt ${cykel.top.toFixed(3)} · ${cykel.topAvstOga.toFixed(2)} m från ögat`);
prova("kameran återgår automatiskt till sadeln",
  cykel.slutVikt === 0 && cykel.slutLage === "ryttare" && !cykel.aktiv &&
  cykel.slutAvstOga < 0.25,
  `slutvikt ${cykel.slutVikt} · ${cykel.slutAvstOga.toFixed(3)} m från ögat`);
prova("återgången sker inom vinkelns egen tid",
  cykel.klarVid !== undefined && cykel.klarVid < 3.2,
  `${cykel.klarVid === undefined ? "aldrig" : cykel.klarVid.toFixed(2) + " s"}`);
{
  let hopp = 0;
  for (let i = 1; i < cykel.vikter.length; i++)
    hopp = Math.max(hopp, Math.abs(cykel.vikter[i] - cykel.vikter[i - 1]));
  prova("övergången är mjuk hela vägen, inget klipp", hopp < 0.08,
    `största viktsteg ${hopp.toFixed(4)}`);
}

/* ══ AVBROTTEN, GENOM SPELETS EGNA HÅL ═════════════════════════════ */
const avbrott = await ev(() => {
  const R = {};
  const uppe = () => { Kameralage.nollstall(Kameralage.ritten, "test");
    Kameralage.begar(Kameralage.ritten, "vagval", "test");
    for (let i = 0; i < 40; i++) s3Kamera(1 / 60);
    return Kameralage.aktiv(Kameralage.ritten) && S3.kam.vikt > 0; };

  R.uppeFore = uppe();
  overlay(true, "<p>test</p>"); overlay(false);
  R.efterOverlay = { aktiv: Kameralage.aktiv(Kameralage.ritten), vikt: S3.kam.vikt };

  uppe();
  gaTill("stallinne", { x: 7.5, y: 40, rikt: 0 });
  R.efterScenbyte = { aktiv: Kameralage.aktiv(Kameralage.ritten), vikt: S3.kam.vikt };

  uppe();
  startaVandring();              // avsittningen: ridSittAv + kameraNollstall
  R.efterAvsittning = { aktiv: Kameralage.aktiv(Kameralage.ritten), vikt: S3.kam.vikt,
    uppsutten: ridTelemetri().uppsutten };

  /* Inget får vakna senare. */
  for (let i = 0; i < 60 * 30; i++) Kameralage.stega(Kameralage.ritten, 1 / 60);
  R.senare = { aktiv: Kameralage.aktiv(Kameralage.ritten),
    vikt: Kameralage.las(Kameralage.ritten).vikt };
  return R;
});
prova("en feedbackvy gick att få upp inför avbrottsproven", avbrott.uppeFore === true);
prova("overlay avbryter feedbackvyn omedelbart",
  !avbrott.efterOverlay.aktiv && avbrott.efterOverlay.vikt === 0);
prova("scenbyte avbryter feedbackvyn omedelbart",
  !avbrott.efterScenbyte.aktiv && avbrott.efterScenbyte.vikt === 0);
prova("avsittning avbryter feedbackvyn omedelbart",
  !avbrott.efterAvsittning.aktiv && avbrott.efterAvsittning.vikt === 0 &&
  avbrott.efterAvsittning.uppsutten === false);
prova("ingen begäran vaknar 30 s senare",
  !avbrott.senare.aktiv && avbrott.senare.vikt === 0);

/* ══ FALSIFIERING I DEN RIKTIGA SIDAN ══════════════════════════════
   Två fel, båda mätta med samma påstående som ovan. Håller påståendet
   ändå skyddar det ingenting. */
console.log("\n── Falsifiering i den riktiga renderaren ──");

/* (a) FEL STANDARD: tvinga läget till full bomvikt och kör om
       ögonpunktsmätningen. Den ska falla. */
const falskA = await ev(() => {
  /* Tillbaka in i ritten först — avbrottsproven ovan lämnade oss avsutna. */
  const pool = hastpool(G.grupp); sattAktivHast(pool[0]);
  G.hastMott = true; G.utrustning = true;
  visaSkotsel(); overlay(false); ridSittUpp(G.hastId, "ridhus"); startaLektion();
  G.plats = "ridhus"; S3.kam.satt = false;
  /* Fel standard: bommen i stället för sadeln, utan att någon bett om det. */
  Kameralage.begar(Kameralage.ritten, "utifran", "falsifiering");
  for (let i = 0; i < 120; i++) s3Kamera(1 / 60);   // in i full vikt
  const k = S3.kam, oga = s3MinOgonpunkt();
  return { avst: Math.hypot(k.x - oga.x, k.y - oga.y, k.z - oga.z), vikt: k.vikt };
});
matt++;
if (falskA.vikt > 0.99 && falskA.avst < 0.25) {
  fel++;
  console.log("  FEL  mutationen fel standard — ögonpunktsprovet höll ändå");
} else {
  console.log("  OK   mutationen fel standard — provet föll som det ska",
    `(${falskA.avst.toFixed(2)} m från ögat vid vikt ${falskA.vikt.toFixed(2)})`);
}

/* (b) UTEBLIVEN ÅTERGÅNG: stega läget utan att låta det nå slutet, och
       kontrollera att återgångsprovet då faller. Vi simulerar det
       genom att hålla vyn vid liv med en ny begäran varje bildruta —
       samma sak som en trasig återgång ser ut som. */
const falskB = await ev(() => {
  Kameralage.nollstall(Kameralage.ritten, "test");
  for (let i = 0; i < 60 * 6; i++) {
    Kameralage.begar(Kameralage.ritten, "sits", "falsifiering");  // aldrig klar
    s3Kamera(1 / 60);
  }
  const oga = s3MinOgonpunkt();
  return { vikt: S3.kam.vikt, lage: S3.kam.lage,
    avst: Math.hypot(S3.kam.x - oga.x, S3.kam.y - oga.y, S3.kam.z - oga.z) };
});
matt++;
if (falskB.vikt === 0 && falskB.lage === "ryttare" && falskB.avst < 0.25) {
  fel++;
  console.log("  FEL  mutationen utebliven återgång — återgångsprovet höll ändå");
} else {
  console.log("  OK   mutationen utebliven återgång — provet föll som det ska",
    `(vikt ${falskB.vikt.toFixed(2)}, ${falskB.avst.toFixed(2)} m från ögat)`);
}

/* Sidfel som samlats under körningen är också evidens. */
if (webb.fel.length) {
  console.log("\n  sidfel:");
  for (const f of webb.fel.slice(0, 10)) console.log("   ", f);
}

await webb.stang();
console.log("");
if (fel > 0) { console.log(`${fel} av ${matt} mätningar föll.`); process.exit(1); }
console.log(`ALLA OK (${matt} mätningar)`);
