#!/usr/bin/env node
/* UGNETA — FÖRSÖK 1 → FÖRSÖK 2 GENOM PRODUKTIONSFLÖDET.

   PO-direktiv 2026-09-06 på #119: samma övning ska ridas två verkliga
   försök genom ordinarie moment/lifecycle, mätas ur `G.telemetri` och
   ge högst två konkreta observationer efter försök 2.

   Provet kör det BYGGDA spelet i Chromium och låter spelets egen
   lektionsloop (stegaLektion i src/game.js) driva försöken — inte en
   isolerad hjälpfunktion. Läktarlärdomen (#114): en grön hjälpfunktion
   säger ingenting om vad spelaren faktiskt får.

   Kör: python3 tools/build.py && node tools/ugneta-forsok-test.mjs */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const PORT = +(process.env.PORT || 8833);
const MIME = { ".html":"text/html", ".js":"text/javascript", ".css":"text/css",
  ".png":"image/png", ".jpg":"image/jpeg", ".json":"application/json" };
const srv = http.createServer((q, r) => {
  const raw = q.url.split("?")[0];
  const p = path.join(DIST, decodeURIComponent(raw === "/" ? "/ridskolan.html" : raw));
  fs.readFile(p, (e, d) => { if (e) { r.writeHead(404); r.end(); return; }
    r.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" }); r.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ headless: true,
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
page.on("pageerror", e => console.log("PAGEERROR", e.message, "\n", (e.stack||"").split("\n").slice(0,4).join("\n")));
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(900);
const ev = (f, a) => page.evaluate(f, a);

const resultat = [];
function prova(namn, ok, detalj) { resultat.push({ namn, ok });
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); }

/* ══ 1. LIFECYCLE: SAMMA ÖVNING RIDS TVÅ FÖRSÖK ═══════════════════ */
{
  const r = await ev(() => {
    /* Ett riktigt pass, ett moment som ÄR en G02-C-övning.

       Två saker sätts som spelet självt sätter dem före lektionen, och
       de är inte kosmetik: `G.ride` byggs av nyState() i skötseln (utan
       den finns ingen ridmodell att mäta), och `SPAR.pass` gör att det
       inte är allra första passet — annars håller den ledda
       genomgången (introRittSteg) momentets klocka stilla, precis som
       den ska för en nybörjare. Ingen av dem stubbar bort logiken som
       provas: lifecycle, mätning och feedback körs skarpt. */
    if (typeof SPAR !== "undefined" && SPAR) SPAR.pass = Math.max(1, SPAR.pass || 0);
    G.dagsform = 0.72; G.sadellage = 0.8;
    G.ride = nyState(G.dagsform, hastminne(G.hastId).rang, G.sadellage);
    startaLektion();
    const ix = G.lektion.findIndex(m => !!ugnetaOvningFor(m));
    if (ix < 0) return { fel: "ingen G02-C-övning i lektionen" };
    G.momentIx = ix; G.moment = G.lektion[ix]; G.momentForsok = 1;
    G.momentT = 0; G.momentHall = 0; G.momentKlart = false;
    const ovning = ugnetaOvningFor(G.moment).id, momentId = G.moment.id;
    const logg = [];
    /* Låt spelets egen loop driva. Momentet avslutas av lifecycle när
       taket m.tid*2.2 passeras — samma väg som i spelet. */
    /* G02-D: lifecyclen stannar numera och FRÅGAR om omridningen. Provet
       svarar som en spelare gör — genom att trycka på knappen i panelen.
       Räknas panelklicken behövs de: utan dem stannar lektionen, och det
       är precis vad som ska hända när ingen svarar. */
    let klick = { igen: 0, vidare: 0 }, pausSedd = false;
    for (let i = 0; i < 900; i++) {
      lararSteg(0.1);
      G.momentT += 0.1;
      stegaLektion(0.1);
      if (G.paus) {
        pausSedd = true;
        const igen = document.getElementById("valIgen");
        const vidare = document.getElementById("valVidare");
        if (igen) { klick.igen++; igen.click(); }
        else if (vidare) { klick.vidare++; vidare.click(); }
        else return { fel: "pausad utan knappar i panelen" };
      }
      logg.push({ ix: G.momentIx, forsok: G.momentForsok, id: G.moment ? G.moment.id : null });
      if (!G.moment || G.moment.id !== momentId) break;
    }
    const sedda = [...new Set(logg.map(l => l.forsok))];
    return { ovning, momentId, sedda, klick, pausSedd, paus: !!G.paus,
      historik: (ugnetaForsokHistorik(ovning) || []).length,
      bedomda: G.bedomda || 0 };
  });
  prova("samma övning rids två försök genom ordinarie lifecycle",
    !r.fel && r.sedda.includes(1) && r.sedda.includes(2),
    r.fel || `övning "${r.ovning}" · sedda försök ${JSON.stringify(r.sedda)}`);
  prova("och båda försöken mättes var för sig",
    !r.fel && r.historik >= 2,
    r.fel || `${r.historik} mätta försök i historiken`);
  /* G02-D: omridningen är ett BESLUT. Provet ska visa att lifecyclen
     stannade och att det var klicket som startade försök 2 — inte att
     panelen råkade ligga där medan spelet red vidare av sig självt. */
  prova("omridningen skedde för att spelaren valde den",
    !r.fel && r.pausSedd === true && r.klick.igen >= 1,
    r.fel || `paus sedd: ${r.pausSedd} · klick ${JSON.stringify(r.klick)}`);
  prova("och lektionen lämnas inte pausad efter valet",
    !r.fel && r.paus === false, r.fel || `G.paus: ${r.paus}`);
  prova("momentet betygsätts en gång, inte en gång per försök",
    !r.fel && r.bedomda <= 1,
    r.fel || `bedomda ${r.bedomda}`);
}

/* ══ 2. FEEDBACKEN KOMMER UR TELEMETRIN, INTE UR SLUMP ════════════ */
{
  const r = await ev(() => {
    /* Två försök med KÄND skillnad: linjen blir bättre, balansen sämre.
       Feedbacken ska peka ut linjen — annars läser den inte datan. */
    LARARE.forsok = Object.create(null);
    LARARE.forsok.storvolt = [
      { linje: 0.50, rytm: 0.60, balans: 0.70, timing: 0.5, mjukhet: 0.5, respons: 0.5, tempo: 0.5 },
    ];
    const nu = { linje: 0.74, rytm: 0.61, balans: 0.52, timing: 0.5, mjukhet: 0.5, respons: 0.5, tempo: 0.5 };
    LARARE.forsok.storvolt.push(nu);
    const j = ugnetaJamfor("storvolt", LARARE.forsok.storvolt[0], nu, 2);
    /* Och samma jämförelse med linjen OFÖRÄNDRAD ska INTE påstå att
       linjen blev bättre. */
    const oforandrad = ugnetaJamfor("storvolt",
      { linje: 0.50, rytm: 0.60, balans: 0.70 },
      { linje: 0.50, rytm: 0.60, balans: 0.70 }, 2);
    return { punkter: j.punkter, rubrik: j.rubrik, oforandrad: oforandrad.punkter };
  });
  prova("försök 2 pekar ut den dimension som faktiskt förbättrades",
    r.punkter.length <= 2 && r.punkter.some(p => /linjen/i.test(p)),
    `${r.rubrik}: ${JSON.stringify(r.punkter)}`);
  prova("och påstår ingen förbättring när ingenting förbättrades",
    !r.oforandrad.some(p => /Bättre/i.test(p)),
    JSON.stringify(r.oforandrad));
}

/* ══ 2b. MÄTNINGEN LÄSER FAKTISKT TELEMETRIN ══════════════════════
   Falsifieringen "mätningen läser inte G.telemetri" gav först noll
   röda: `ugnetaKvalitet()` faller tillbaka på `G.ride` när telemetrin
   är tom, så en bruten mätning såg likadan ut. Ett prov som inte kan
   skilja "läser telemetrin" från "läser något annat" bevisar ingenting
   om mätningen. Här hålls `G.ride` STILLA medan bara telemetrin ändras
   — då måste kvaliteten röra sig, annars kommer den inte därifrån. */
{
  const r = await ev(() => {
    /* Literalen är avsiktlig — den ÄR falsifieringen. Men den saknar
       ridkärnans interna fält, och spelloopen stegar G.ride varje
       bildruta. Förut lämnades den kvar och nästa rAF-tick kastade i
       stepRide. Hela mätningen ligger därför i EN evaluate, och det
       riktiga tillståndet läggs tillbaka innan bildrutan är slut. */
    const forra = G.ride;
    const ride = { tempo: 3.0, balans: 0.50, mjukhet: 0.50, fokus: 0.50, spanning: 0.50,
      skala: { rakriktning: 0.60, takt: 0.60, schvung: 0.60, kontakt: 0.60, samling: 0.50 } };
    G.ride = JSON.parse(JSON.stringify(ride));
    G.aids = { tygel: 0.4 }; G.grupp = "grupp2"; G.dagsform = 0.8;
    const mat = tm => { G.telemetri = tm; return ugnetaKvalitet(); };
    const lag = mat({ svangradie: 10, balans: 0.20, mjukhet: 0.20, fokus: 0.20,
      spanning: 0.80, svarstid: 0.50, etableringstid: 2.4, paradKvalitet: 0.2,
      fart: 3.0, onskadFart: 3.0 });
    const hog = mat({ svangradie: 10, balans: 0.95, mjukhet: 0.95, fokus: 0.95,
      spanning: 0.05, svarstid: 0.08, etableringstid: 0.5, paradKvalitet: 0.95,
      fart: 3.0, onskadFart: 3.0 });
    const ut = { lag, hog, rideOrord: JSON.stringify(G.ride) === JSON.stringify(ride) };
    G.ride = forra;
    return ut;
  });
  prova("balans, mjukhet och respons följer telemetrin — inte något annat",
    r.hog.balans - r.lag.balans > 0.5 && r.hog.mjukhet - r.lag.mjukhet > 0.5 &&
    r.hog.respons - r.lag.respons > 0.25,
    `balans ${r.lag.balans.toFixed(2)}→${r.hog.balans.toFixed(2)} · mjukhet ${r.lag.mjukhet.toFixed(2)}→${r.hog.mjukhet.toFixed(2)} · respons ${r.lag.respons.toFixed(2)}→${r.hog.respons.toFixed(2)}`);
  prova("och timingen följer svarstid och etableringstid ur telemetrin",
    r.hog.timing - r.lag.timing > 0.4 && r.rideOrord === true,
    `timing ${r.lag.timing.toFixed(2)}→${r.hog.timing.toFixed(2)} · G.ride orörd ${r.rideOrord}`);
}

/* ══ 3. FÖRSÖK 1: EN BRA, EN ATT FÖRBÄTTRA, OCH PROVA IGEN ════════ */
{
  const r = await ev(() => {
    const m = ugnetaForstaForsok("storvolt",
      { linje: 0.78, rytm: 0.60, balans: 0.41, timing: 0.5, mjukhet: 0.5, respons: 0.5 });
    return m;
  });
  prova("efter försök 1: högst en bra + en att förbättra",
    r.punkter.length === 2 && /Bra/i.test(r.punkter[0]) && /Jobba på/i.test(r.punkter[1]),
    JSON.stringify(r.punkter));
  prova("och ett tydligt Prova igen",
    r.knapp === "Prova igen" && r.rubrik === "Prova igen",
    `rubrik "${r.rubrik}" · knapp "${r.knapp}"`);
}

/* ══ 4. LIVE-REGISTRET: KORT CUE, INGET KORT ══════════════════════ */
{
  const r = await ev(() => {
    /* Spelets egen rAF-loop kör vidare i sidan. Sätts scenen till
       "lektion" utan häst plockar loopen HORSES[null] och kastar — det
       är provets eget halvtillstånd, inte en produktbugg. Därför
       återställs ett sammanhängande läge först. */
    if (!G.hastId) G.hastId = Object.keys(HORSES)[0];
    G.scen = "lektion"; G.tavling = null;
    G.moment = G.lektion ? G.lektion[0] : { id: "x", namn: "x", tid: 30 };
    ugnetaLive("Mjukare hand", false);
    const live = document.getElementById("ugnetaLive");
    const kort = document.getElementById("saga");
    return { text: live ? live.textContent : null,
      synlig: live ? live.classList.contains("pa") : false,
      ord: live ? live.textContent.trim().split(/\s+/).length : 0,
      kortAktivt: kort ? kort.classList.contains("ugneta-kort") : false,
      rutor: live ? live.getBoundingClientRect().height : 0 };
  });
  prova("live-feedbacken är några ord, inte ett kort",
    r.synlig === true && r.ord <= 3 && r.kortAktivt === false,
    `"${r.text}" · ${r.ord} ord · lärarkort aktivt: ${r.kortAktivt}`);
  prova("och den tar liten plats på skärmen",
    r.rutor > 0 && r.rutor <= 46,
    `${Math.round(r.rutor)} px hög`);
}

/* ══ 5. SÄKERHET VINNER, OCH SLÄCKER LIVE-CHIPET ══════════════════ */
{
  const r = await ev(() => {
    ugnetaLive("Bra rytm", true);
    const foreT = document.getElementById("ugnetaLive").classList.contains("pa");
    /* Ett vanligt säkerhetsrop går genom saga() utan Ugneta-metadata. */
    saga("Se upp — håll avstånd!", 4);
    const live = document.getElementById("ugnetaLive");
    const s = document.getElementById("saga");
    return { foreT, efter: live.classList.contains("pa"),
      sagaText: s.textContent, ugnetaKort: s.classList.contains("ugneta-kort") };
  });
  prova("ett säkerhetsrop släcker live-chipet",
    r.foreT === true && r.efter === false,
    `före ${r.foreT} → efter ${r.efter}`);
  prova("och säkerhetsmeddelandet visas som vanligt UI, inte som Ugneta",
    /Se upp/.test(r.sagaText) && r.ugnetaKort === false,
    `"${r.sagaText}" · ugneta-kort ${r.ugnetaKort}`);
}

/* ══ 6. UGNETA STÅR VID SARGEN — SAMMA PUNKT FÖR ALLA YTOR ════════ */
{
  const r = await ev(() => {
    const KB = ridKanon();
    if (!G.hastId) G.hastId = Object.keys(HORSES)[0];
    G.scen = "lektion"; G.tavling = null; G.moment = G.lektion ? G.lektion[0] : { id: "x" };
    const p = ugnetaPlats();
    const narv = ugnetaNarvarande();
    G.tavling = { typ: "hoppning" };
    const underTavling = ugnetaNarvarande();
    G.tavling = null;
    return { p, narv, underTavling, bredd: KB.BANA_BREDD, langd: KB.BANA_LANGD };
  });
  /* Vid C, bortom dressyrlayoutens kortsida — alltså utanför ridvägen och
     på en yta som finns i den VERIFIERADE byggnaden. Vid A finns den inte:
     där ligger banan 0,15 m från gavelväggen. Se motiveringen i
     src/larare.js. */
  prova("Ugneta står vid kortsidan, utanför ridvägen",
    !!r.p && Math.abs(r.p.x - r.bredd / 2) < 0.01 && r.p.y > r.langd,
    `[${r.p.x}, ${r.p.y}] · bana ${r.bredd}×${r.langd}`);
  /* IGENKÄNNBAR, inte en anonym figur (ChatGPT senior review, blocker 2).
     Meshen ska bära grått hår och glasögon, och ritas UTAN ton — uTon
     multiplicerar vertexfärgen, så en tonad figur grumlar båda. */
  await ev(() => { G.vy = "3d"; if (typeof draw3D === "function") draw3D(G); });
  await page.waitForTimeout(500);
  const f = await ev(() => {
    const D = (typeof S3 !== "undefined" && S3.del) ? S3.del : {};
    return { harMesh: !!D.ugneta, harPerson: !!D.person };
  });
  /* Meshen byggs när 3D-scenen ritas första gången — provet går därför
     genom en riktig 3D-bildruta i stället för att anropa byggfunktionen.
     En figur som bara finns om man kallar på byggaren är inte en figur
     spelaren ser (läktarlärdomen, #114). */
  prova("Ugneta har en EGEN mesh efter en riktig 3D-bildruta",
    f.harMesh === true && f.harPerson === true,
    `S3.del.ugneta ${f.harMesh} · publikens person ${f.harPerson}`);

  prova("hon är närvarande på lektionen men inte under tävling",
    r.narv === true && r.underTavling === false,
    `lektion ${r.narv} · tävling ${r.underTavling}`);
}

console.log("");
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : `ALLA OK (${resultat.length} mätningar)`);
await browser.close(); srv.close();
process.exit(fel ? 1 : 0);
