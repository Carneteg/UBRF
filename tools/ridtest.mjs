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
/* Formatterare som TÅL ett saknat fält.

   Ett prov ska bli RÖTT när ett kontraktsfält försvinner — inte krascha
   hela sviten på `undefined.toFixed()` innan de senare proven ens körts.
   Uppmätt under falsifieringen 2026-09-05: att ta bort `svarstid` ur
   telemetrin stoppade körningen vid prov 43 av 62, och de nitton därefter
   sa ingenting alls. Rött blev det, men av fel skäl och utan att peka på
   vad som saknades. */
const nf = (v, d = 3) => (typeof v === "number" && Number.isFinite(v)) ? v.toFixed(d) : "—";

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

  /* b2) Och samma hjälp i två minuter — G02-B:s första fråga. */
  nyRitt(); kor({ skankel: 1 }, 120);
  const langtHall = G.ride.gangart, langtFart = G.ride.tempo;

  /* c) Tre tryck med släpp emellan, sedan parad ned. */
  nyRitt(); sedda.length = 0; sedda.push(G.ride.gangart);
  for (let n = 0; n < 3; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
  const topp = G.ride.gangart, toppFart = G.ride.tempo;

  /* c2) Och FLER impulser än det finns gångarter. Webben har fyra och
     ska stanna på galopp; Roblox har en femte i tabellen som efter
     senior review 2026-09-05 inte är spelbar. Taket ska vara samma
     gångart på båda ytorna, och det här är webbens halva av beviset. */
  nyRitt();
  for (let n = 0; n < 8; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
  const spam = G.ride.gangart, spamFart = G.ride.tempo;
  kor({ skankel: -1, tygel: 1, sits: 1 }, 25);
  return { stilla, kvarliggande, hallenW, hallenFart, langtHall, langtFart, topp, toppFart, spam, spamFart,
    slut: G.ride.gangart, sedda, glapp: RID_TILLSTAND.glapp };
});
prova("genom inputlagret: uppsittning utan hjälp startar INTE hästen",
  via.stilla === "halt",
  `förra passet lämnade skänkeln på ${via.kvarliggande.toFixed(2)}; ` +
  `fem sekunder utan tangent → ${via.stilla}`);
prova("genom inputlagret: hållen W ger ETT steg upp, inte fler",
  via.hallenW === "skritt",
  `W i botten i 12 s → ${via.hallenW} (${via.hallenFart.toFixed(2)} m/s)`);
/* G02-B: FYNDET FRÅN ISSUE #83 ÄR STÄNGT — och det här provet är vad som
   håller det stängt.

   Mätningen 2026-09-05 08:36 svepte skänkeln i 40 steg och fann att INGEN
   konstant insats landade i skrittbandet: ekipaget hamnade i halt eller
   trav. Den mätningen gjordes före G02-A:s cue-modell. Samma svep mot
   main efter #86 ger 17 av 40 i skritt, och det rätta provet — en impuls
   och sedan hjälpen kvar — ger skritt på varje nivå från 0,60 till 1,00.

   Tolv sekunder räckte inte som bevis. Skritt är den gångart en elev
   tillbringar mest tid i, och frågan var uttryckligen om den går att
   HÅLLA. Två minuter, genom inputlagret, är det som svarar på det.

   Tempot får röra sig inom bandet — hästen andas, och hjälpens styrka
   nyanserar samlad mot utsträckt skritt. Vad som inte får hända är att
   gångarten byter. */
prova("genom inputlagret: skritten går att HÅLLA — två minuter med W nere",
  via.langtHall === "skritt" && via.langtFart >= 0.90 && via.langtFart <= 2.00,
  `W i botten i 120 s → ${via.langtHall} ${via.langtFart?.toFixed(2)} m/s ` +
  `(skrittbandet 0,90–2,00)`);
prova("genom inputlagret: tre tryck tar ekipaget till galopp",
  via.topp === "galopp", `nådde ${via.topp} vid ${via.toppFart.toFixed(2)} m/s`);
prova("genom inputlagret: fler impulser tar inte ekipaget förbi galopp",
  via.spam === "galopp",
  `åtta framåtimpulser gav ${via.spam} (${via.spamFart?.toFixed(2)} m/s)`);
prova("genom inputlagret: parad tar ned till halt utan överhoppade gångarter",
  via.slut === "halt" && via.glapp === 0,
  `${via.sedda.join(" → ")}, ${via.glapp} olagliga byten`);

/* ══════════════════════════════════════════════════════════════════
   G02-B PUNKT 1 — HJÄLPERNA SOM SEMANTIK (issue #83)

   Ordern är uttrycklig: "Acceptance ska bevisas med faktisk inputväg,
   inte bara direktanrop av modellen." Allt nedan går därför genom
   RIDIN → stegaInput → stegaRitt, samma väg som ett tangenttryck.

   Två påståenden provas, och båda är sådana som kan bli röda:

     PARADEN ÄR EN EGEN SIGNAL. Den ska nå modellen på egen kanal, den
     ska INTE knuffa skänkel, tygel och sits på vägen, och hästen ska
     läsa hur väl samordnad den var.

     YTTERTYGELN BÄR SVÄNGEN. Att svänga med släppt tygel ska ge mätbart
     sämre rakriktning än samma sväng med kontakten kvar.
   ══════════════════════════════════════════════════════════════════ */
const hj = await page.evaluate(() => {
  G.hastId = G.hastId || Object.keys(HORSES)[0]; G.hamtad = true; G.npcs = [];
  const dt = 1 / 60;
  const nyRitt = () => { G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0; ridNollstallHjalp(); };
  const kor = (o, sek) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0; RIDIN.sits = o.sits ?? 0;
    RIDIN.styr = o.styr ?? 0; RIDIN.parad = o.parad ?? 0; stegaRitt(dt); } };
  const ut = {};

  /* a) KANALEN. Paraden ges mitt i en lugn skritt. Efteråt ska `parad`
     ha gått upp OCH de tre axlarna stå exakt där de stod. Före G02-B
     knuffade envelopen dem 0,26–0,28 var. */
  nyRitt(); kor({ skankel: 1 }, 1.2); kor({ skankel: 0.55 }, 2.0);
  const fore = { ...G.aids };
  kor({ skankel: 0.55, parad: 1 }, 0.2);
  ut.kanal = { parad: G.aids.parad,
    dSk: G.aids.skankel - fore.skankel, dTy: G.aids.tygel - fore.tygel,
    dSi: G.aids.sits - fore.sits };

  /* b) VERKAN. En parad ur trav ska ta ned ett steg, läst som halvhalt. */
  nyRitt(); for (let n = 0; n < 2; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
  const foreG = G.ride.gangart;
  kor({ parad: 1 }, 0.3); kor({}, 3.0);
  ut.verkan = { fore: foreG, efter: G.ride.gangart, cue: G.ride.cue };

  /* c) KVALITETEN. Samma tangent, två ryttare: en med skänkeln på och
     handen i kontaktbandet, en utan skänkel och med handen utanför.
     Båda ska få sin övergång — en halvhalt är inte en knapp som nekas —
     men hästen ska läsa dem olika. */
  const enParad = (skankel, tygel) => { nyRitt();
    kor({ tygel }, 2.0);
    kor({ skankel: 1, tygel }, 1.5); kor({ skankel, tygel }, 1.0);
    kor({ skankel: 1, tygel }, 1.5); kor({ skankel, tygel }, 2.0);
    const f = G.ride.gangart, iF = ["halt","skritt","trav","galopp"].indexOf(f);
    kor({ skankel, tygel, parad: 1 }, 0.3); kor({ skankel, tygel }, 2.0);
    const iE = ["halt","skritt","trav","galopp"].indexOf(G.ride.gangart);
    return { fore: f, efter: G.ride.gangart, steg: iE - iF, cue: G.ride.cue,
      kval: G.ride.paradKval, aSk: G.aids.skankel, aTy: G.aids.tygel }; };
  ut.bra = enParad(0.7, 0.15);
  ut.slarv = enParad(-1, 0.35);

  /* d) YTTERTYGELN. Samma volt, samma skänkel, samma styrutslag — bara
     kontakten skiljer. Kontakten tas FÖRST och får lägga sig, annars är
     själva tygeltagningen en nedåtgående hjälp och de två ritterna
     hamnar i olika gångart, vilket vore ett annat prov än det här. */
  const volt = (tygel) => { nyRitt();
    kor({ tygel }, 2.0); kor({ skankel: 1, tygel }, 1.2); kor({ skankel: 0.55, tygel }, 1.5);
    kor({ skankel: 0.55, tygel, styr: 1 }, 40);
    return { rak: G.ride.skala.rakriktning, schvung: G.ride.skala.schvung,
      kontakt: G.ride.skala.kontakt, gangart: G.ride.gangart,
      stod: G.telemetri.hjalper.ytterstod,
      inner: G.telemetri.hjalper.innerTygel, ytter: G.telemetri.hjalper.ytterTygel }; };
  ut.los = volt(0);
  ut.buren = volt(0.5);

  ut.dublett = { kanon: HJALP_KANON.TYGEL_NEUTRAL, modell: K.TYGEL_NEUTRAL,
    styr: HJALP_KANON.STYR_FULLT, styrMal: (() => { RIDIN.styr = 1; ridAvsiktTillHjalp();
      const v = IN.kan.styrning.mal; RIDIN.styr = 0; ridAvsiktTillHjalp(); return v; })() };
  return ut;
});
prova("paraden är en EGEN kanal — tangenten knuffar inte skänkel, tygel och sits",
  hj.kanal.parad > 0.9 && Math.abs(hj.kanal.dSk) < 1e-9 &&
  Math.abs(hj.kanal.dTy) < 1e-9 && Math.abs(hj.kanal.dSi) < 1e-9,
  `parad ${hj.kanal.parad.toFixed(2)}, axlarna rörde sig ` +
  `${hj.kanal.dSk.toFixed(3)} / ${hj.kanal.dTy.toFixed(3)} / ${hj.kanal.dSi.toFixed(3)}`);
prova("genom inputlagret: en parad tar ned ett steg och läses som halvhalt",
  hj.verkan.fore === "trav" && hj.verkan.efter === "skritt" && hj.verkan.cue === "halvhalt",
  `${hj.verkan.fore} → ${hj.verkan.efter}, cue ${hj.verkan.cue}`);
prova("genom inputlagret: hästen läser HUR paraden reds, inte bara ATT den gavs",
  hj.bra.kval >= 0.90 && hj.slarv.kval <= 0.55 &&
  hj.bra.steg === -1 && hj.slarv.steg === -1 &&
  hj.bra.cue === "halvhalt" && hj.slarv.cue === "halvhalt",
  `samordnad (skänkel ${hj.bra.aSk.toFixed(2)}, tygel ${hj.bra.aTy.toFixed(2)}) ` +
  `kvalitet ${hj.bra.kval.toFixed(2)} · slarvig (skänkel ${hj.slarv.aSk.toFixed(2)}, ` +
  `tygel ${hj.slarv.aTy.toFixed(2)}) kvalitet ${hj.slarv.kval.toFixed(2)} — båda tog ned ett steg`);
prova("telemetrin visar yttertygelstödet i den körande ritten",
  hj.los.stod <= 0.45 && hj.buren.stod >= 0.60 && hj.los.inner > hj.los.ytter,
  `volt på lös tygel: stöd ${hj.los.stod.toFixed(2)} (inner ${hj.los.inner.toFixed(2)} / ` +
  `ytter ${hj.los.ytter.toFixed(2)}) · med kontakten kvar: stöd ${hj.buren.stod.toFixed(2)}`);
/* Den här raden är den som säger att semantiken inte är dekoration.
   Den burna volten har LÄGRE schvung och LÄGRE kontakt än den lösa —
   tygeln kostar på båda de skalorna — och ändå högre rakriktning.
   Tas yttertygelstödet ur mal.rakriktning vänder ordningen. */
prova("yttertygeln bär svängen: buren volt ger bättre rakriktning än lös",
  hj.buren.rak > hj.los.rak && hj.buren.schvung < hj.los.schvung &&
  hj.buren.kontakt < hj.los.kontakt && hj.buren.gangart === hj.los.gangart,
  `rakriktning ${hj.los.rak.toFixed(3)} → ${hj.buren.rak.toFixed(3)} ` +
  `(+${((hj.buren.rak / hj.los.rak - 1) * 100).toFixed(1)} %) trots schvung ` +
  `${hj.los.schvung.toFixed(3)} → ${hj.buren.schvung.toFixed(3)} och kontakt ` +
  `${hj.los.kontakt.toFixed(3)} → ${hj.buren.kontakt.toFixed(3)}, båda i ${hj.buren.gangart}`);
prova("hjälpkanonen och modellen delar tal i stället för att spegla dem",
  hj.dublett.kanon === hj.dublett.modell &&
  Math.abs(hj.dublett.styr - hj.dublett.styrMal) < 1e-9,
  `tygelns neutralläge ${hj.dublett.kanon} på båda ställena; fullt styrutslag ` +
  `${hj.dublett.styr} ur kanonen ger ${hj.dublett.styrMal} i inputlagret`);

/* ══════════════════════════════════════════════════════════════════
   G02-B PUNKT 2 — HÄSTENS SVAR (issue #83)

   Fördröjning, känslighet, balans, fokus, spänning och energi. Proven
   går genom inputlagret av samma skäl som punkt 1:s, och tre av dem är
   direkt riktade mot risken i den här punkten — att en häst som "svarar
   som en individ" i praktiken blir en häst som inte lyder.

   KONTROLL FÖRST är inte en formulering här utan ett prov: tolv hjälper
   i rad ska ge tolv svar. Fördröjningen skjuter svaret i tid; den får
   aldrig tappa bort det.
   ══════════════════════════════════════════════════════════════════ */
const { SVAR_KANON_MIN, SVAR_KANON_MAX } = await page.evaluate(
  () => ({ SVAR_KANON_MIN: SVAR_KANON.SVAR_MIN, SVAR_KANON_MAX: SVAR_KANON.SVAR_MAX }));
const svar = await page.evaluate(() => {
  G.hastId = G.hastId || Object.keys(HORSES)[0]; G.hamtad = true; G.npcs = [];
  const dt = 1 / 60;
  const nyRitt = () => { G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0; ridNollstallHjalp(); };
  const kor = (o, sek) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0; RIDIN.sits = o.sits ?? 0;
    RIDIN.styr = o.styr ?? 0; RIDIN.parad = o.parad ?? 0; stegaRitt(dt); } };
  const ut = {};

  /* a) HJÄLPEN TAPPAS ALDRIG BORT. Tolv hjälper upp och ned om vartannat.
     Varje gång ryttaren ber ska `beddGangart` byta, och varje sådan
     begäran ska sluta med att `malGangart` kommit ifatt. En hjälp som
     försvinner under fördröjningen är den värsta buggen den här punkten
     kan införa, och det här provet är vad som fångar den. */
  nyRitt();
  let bad = 0, svarade = 0, maxVantan = 0, minVantan = 9;
  /* Bildruta för bildruta, för väntan är kortare än ett vanligt
     testintervall. Kördes den i 0,35-sekundersklumpar var fönstret redan
     passerat när provet tittade, och band-kontrollen blev sann av att
     ingenting hade mätts — grön utan att ha sett efter. */
  let sågVantan = 0;
  const enHjalp = (o, sek) => {
    const foreBedd = G.ride.beddGangart;
    let hittad = false;
    for (let i = 0; i < sek * 60; i++) {
      RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0; RIDIN.sits = o.sits ?? 0;
      RIDIN.styr = o.styr ?? 0; RIDIN.parad = o.parad ?? 0;
      stegaRitt(dt);
      if (!hittad && G.ride.beddGangart !== foreBedd) {
        hittad = true; bad++;
        /* Samma bildruta som hon hörde: hon har ännu inte börjat. */
        if (G.ride._vantar && G.ride.malGangart !== G.ride.beddGangart) {
          sågVantan++;
          maxVantan = Math.max(maxVantan, G.ride.svarstid);
          minVantan = Math.min(minVantan, G.ride.svarstid);
        }
      }
    }
    if (hittad && G.ride.malGangart === G.ride.beddGangart) svarade++;
  };
  for (let n = 0; n < 3; n++) { enHjalp({ skankel: 1 }, 1.4); enHjalp({}, 1.2); }
  for (let n = 0; n < 3; n++) { enHjalp({ parad: 1 }, 1.6); enHjalp({}, 1.0); }
  ut.aldrigTappad = { bad, svarade, maxVantan, minVantan, sagVantan: sågVantan };

  /* b) SVARSTIDEN, klockad utifrån: från att `beddGangart` byter till att
     `malGangart` gör det. Ska stämma med det modellen själv redovisar. */
  nyRitt(); kor({}, 1.0);
  let t0 = null, klockad = null;
  for (let i = 0; i < 240; i++) {
    RIDIN.skankel = 1; stegaRitt(dt);
    if (t0 === null && G.ride.beddGangart !== "halt") t0 = G.ride._tid;
    if (t0 !== null && klockad === null && G.ride.malGangart !== "halt")
      klockad = G.ride._tid - t0;
  }
  ut.klocka = { redovisad: G.ride.svarstid, klockad,
    telemetri: G.telemetri ? G.telemetri.svarstid : null };

  /* c) SAMORDNINGEN GER SNABBARE SVAR. Två parader ur samma trav: en
     välriden och en slarvig. Båda ska tas emot; den välridna ska svaras
     på snabbare. */
  const paradSvar = (skankel, tygel) => { nyRitt();
    kor({ tygel }, 2.0);
    kor({ skankel: 1, tygel }, 1.5); kor({ skankel, tygel }, 1.0);
    kor({ skankel: 1, tygel }, 1.5); kor({ skankel, tygel }, 2.5);
    kor({ skankel, tygel, parad: 1 }, 0.3); kor({ skankel, tygel }, 2.0);
    return { svarstid: G.ride.svarstid, kval: G.ride.paradKval,
      gang: G.ride.gangart }; };
  ut.bra = paradSvar(0.7, 0.15);
  ut.slarv = paradSvar(-1, 0.35);

  /* d) ENERGIN. Tio minuter sammanhängande trav. Hjälpen ligger på
     NEUTRAL hela hållet — höjs den ens en gång är det en ny impuls och
     provet mäter något annat än det påstår (samma fällа som checkpoint
     0 gick i). */
  nyRitt(); for (let n = 0; n < 2; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
  const e0 = G.ride.energi, g0 = G.ride.gangart, f0 = G.ride.tempo;
  kor({}, 600);
  const h = HORSES[G.hastId];
  ut.energi = { fore: e0, efter: G.ride.energi, gangFore: g0, gangEfter: G.ride.gangart,
    fartFore: f0, fartEfter: G.ride.tempo,
    svarPigg: svarSvarstid(h, G.ride.fokus, e0, 0.6),
    svarTrott: svarSvarstid(h, G.ride.fokus, G.ride.energi, 0.6) };
  /* Och att halten ger tillbaka. */
  kor({ tygel: 1, sits: 1 }, 6); kor({}, 300);
  ut.energi.efterVila = G.ride.energi;
  ut.energi.gangVila = G.ride.gangart;

  /* e) FOKUS. En välriden halvhalt är en uppmärksamhetssignal. */
  nyRitt(); kor({ skankel: 1 }, 1.5); kor({}, 1.0); kor({}, 8.0);
  const fokFore = G.ride.fokus;
  kor({ skankel: 0.7, tygel: 0.15, parad: 1 }, 0.3);
  kor({ skankel: 0.7, tygel: 0.15 }, 0.5);
  ut.fokus = { fore: fokFore, efter: G.ride.fokus, kval: G.ride.paradKval };

  /* f) BALANSEN OCH INFALLET. Samma volt, samma skänkel, samma
     styrutslag — bara kontakten skiljer. Den ostödda hästen ska tappa
     balansen och FALLA IN: bågen blir snävare än den ryttaren bad om. */
  const volt = (tygel) => { nyRitt();
    kor({ tygel }, 2.0); kor({ skankel: 1, tygel }, 1.2); kor({ skankel: 0.55, tygel }, 1.5);
    kor({ skankel: 0.55, tygel, styr: 1 }, 40);
    const iSvang = { balans: G.ride.balans, kappa: Math.abs(G.kappa),
      radie: Math.abs(G.kappa) > 0.002 ? 1 / Math.abs(G.kappa) : null };
    /* Rakt spår igen — balansen ska hämta sig. */
    kor({ skankel: 0.55, tygel }, 12);
    iSvang.efterRakt = G.ride.balans;
    return iSvang; };
  ut.los = volt(0);
  ut.buren = volt(0.5);
  return ut;
});
prova("kontroll först: fördröjningen skjuter svaret i tid, den tappar aldrig bort det",
  svar.aldrigTappad.bad >= 6 && svar.aldrigTappad.svarade === svar.aldrigTappad.bad &&
  svar.aldrigTappad.sagVantan === svar.aldrigTappad.bad &&
  svar.aldrigTappad.maxVantan <= SVAR_KANON_MAX && svar.aldrigTappad.minVantan >= SVAR_KANON_MIN,
  `${svar.aldrigTappad.bad} hjälper, ${svar.aldrigTappad.svarade} svar, ` +
  `${svar.aldrigTappad.sagVantan} väntefönster sedda, svarstid ` +
  `${svar.aldrigTappad.minVantan.toFixed(3)}–${svar.aldrigTappad.maxVantan.toFixed(3)} s ` +
  `(spelbart band ${SVAR_KANON_MIN}–${SVAR_KANON_MAX})`);
prova("fördröjningen är verklig och mäts utifrån: bedd gångart före buren",
  svar.klocka.klockad !== null && Math.abs(svar.klocka.klockad - svar.klocka.redovisad) < 0.02 &&
  svar.klocka.telemetri === svar.klocka.redovisad,
  `klockad ${nf(svar.klocka.klockad)} s mot redovisad ${nf(svar.klocka.redovisad)} s, ` +
  `telemetrin visar ${nf(svar.klocka.telemetri)} s`);
prova("en välriden parad får snabbare svar än en slarvig",
  svar.bra.svarstid < svar.slarv.svarstid - 0.02 &&
  svar.bra.kval > svar.slarv.kval,
  `välriden: kvalitet ${svar.bra.kval.toFixed(2)} → svar ${svar.bra.svarstid.toFixed(3)} s · ` +
  `slarvig: kvalitet ${svar.slarv.kval.toFixed(2)} → svar ${svar.slarv.svarstid.toFixed(3)} s`);
prova("energin tär av arbete och kommer tillbaka i halt — och trött häst svarar segare",
  svar.energi.efter < svar.energi.fore - 0.20 &&
  svar.energi.gangEfter === svar.energi.gangFore &&
  svar.energi.efterVila > svar.energi.efter + 0.05 &&
  svar.energi.svarTrott > svar.energi.svarPigg,
  `tio minuter ${svar.energi.gangFore}: energi ${svar.energi.fore.toFixed(3)} → ` +
  `${svar.energi.efter.toFixed(3)}, fem minuter halt → ${svar.energi.efterVila.toFixed(3)} · ` +
  `svarstid ${svar.energi.svarPigg.toFixed(3)} → ${svar.energi.svarTrott.toFixed(3)} s · ` +
  `gångarten stod still (${svar.energi.gangFore} → ${svar.energi.gangEfter})`);
prova("en välriden halvhalt lyfter fokus — den är en uppmärksamhetssignal",
  svar.fokus.efter > svar.fokus.fore + 0.03 && svar.fokus.kval > 0.8,
  `fokus ${svar.fokus.fore.toFixed(3)} → ${svar.fokus.efter.toFixed(3)} ` +
  `(+${((svar.fokus.efter / svar.fokus.fore - 1) * 100).toFixed(1)} %) på en parad med kvalitet ` +
  `${svar.fokus.kval.toFixed(2)}`);
prova("balansen tappas i en ostödd volt, hästen FALLER IN, och den hämtar sig på rakt spår",
  svar.los.balans < svar.buren.balans - 0.05 &&
  svar.los.radie < svar.buren.radie &&
  svar.los.efterRakt > svar.los.balans + 0.05,
  `lös tygel: balans ${svar.los.balans.toFixed(3)}, ridd radie ${svar.los.radie.toFixed(2)} m · ` +
  `kontakten kvar: balans ${svar.buren.balans.toFixed(3)}, radie ${svar.buren.radie.toFixed(2)} m ` +
  `(${((1 - svar.los.radie / svar.buren.radie) * 100).toFixed(1)} % snävare än bett) · ` +
  `tolv sekunder rakt efteråt: balans ${svar.los.efterRakt.toFixed(3)}`);

/* ══════════════════════════════════════════════════════════════════
   G02-B PUNKT 3 — SKOLHÄSTPROFILERNA (issue #83)

   "Minst tre datadrivna skolhästprofiler — mätbart olika utan separata
   controllers." Tre påståenden, tre prov:

     PROFILEN ÄR DATA. Samma häst, samma ritt, bara profilnamnet skiljer
     — och svaret blir mätbart annorlunda. Går det, är profilen data och
     inte en kodväg.
     HÄSTARNA ÄR OLIKA SOM HELHETER. Tre riktiga UBRF-hästar med var sin
     profil, ridna likadant, ska skilja sig.
     TILLDELNINGEN HAR KÄLLA. Varje häst med en annan profil än
     utgångsläget ska ha en mening ur ridskolans egen beskrivning bakom
     sig, och varje häst utan sådan evidens ska ligga kvar på
     utgångsläget. Annars är profilen påhittad, och det är precis vad
     CLAUDE.md förbjuder.
   ══════════════════════════════════════════════════════════════════ */
const prof = await page.evaluate(() => {
  const dt = 1 / 60;
  const nyRitt = () => { G.ride = nyState(0.7, 0.5, 0.8);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0; ridNollstallHjalp(); };
  const kor = (o, sek) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0; RIDIN.sits = o.sits ?? 0;
    RIDIN.styr = o.styr ?? 0; RIDIN.parad = o.parad ?? 0; stegaRitt(dt); } };
  G.hamtad = true; G.npcs = [];

  /* Ett PASS som varje häst rids likadant: två impulser upp i trav, en
     ostödd volt, en parad, och sedan tio minuters arbete. */
  const pass = (id) => { G.hastId = id; nyRitt();
    kor({ skankel: 1 }, 1.5); kor({}, 1.0); kor({ skankel: 1 }, 1.5); kor({}, 2.0);
    const svarUpp = G.ride.svarstid;
    kor({ skankel: 0.55, styr: 1 }, 25);
    const balansIVolt = G.ride.balans, radie = Math.abs(G.kappa) > 0.002 ? 1 / Math.abs(G.kappa) : null;
    kor({ skankel: 0.55 }, 6);
    kor({ skankel: 0.7, tygel: 0.15, parad: 1 }, 0.3); kor({ skankel: 0.7, tygel: 0.15 }, 1.0);
    const svarParad = G.ride.svarstid, fokus = G.ride.fokus;
    const e0 = G.ride.energi;
    kor({}, 480);
    return { svarUpp, svarParad, balansIVolt, radie, fokus,
      energiFore: e0, energiEfter: G.ride.energi, gang: G.ride.gangart }; };

  /* a) SAMMA HÄST, olika profil. Kloner av en riktig häst där ENDA
     skillnaden är profilnamnet — då kan skillnaden i utfall inte komma
     från känslighet, tyngd eller utbildning. */
  const bas = HORSES.cosmo;
  const namn = Object.keys(SKOLHAST_PROFILER);
  const klon = {};
  for (const pnamn of namn) {
    HORSES["__prov_" + pnamn] = { ...bas, id: "__prov_" + pnamn, profil: pnamn };
    klon[pnamn] = pass("__prov_" + pnamn);
    delete HORSES["__prov_" + pnamn];
  }

  /* b) TRE RIKTIGA HÄSTAR, var sin profil, samma pass. */
  const riktiga = { crokino: pass("crokino"), curiretto: pass("curiretto"),
    hjartat: pass("hjartat"), cosmo: pass("cosmo") };

  /* c) STRUKTUR: alla profiler har SAMMA fält, utgångsläget är 1,00 rakt
     igenom, och inget fält är något annat än ett tal eller en text.
     En profil med ett eget fält vore början på en egen kodväg. */
  const talFalt = (o) => Object.keys(o).filter(k => typeof o[k] === "number").sort();
  const nyckelSet = namn.map(n => talFalt(SKOLHAST_PROFILER[n]).join(","));
  const skolhastEtt = talFalt(SKOLHAST_PROFILER.skolhast)
    .every(k => SKOLHAST_PROFILER.skolhast[k] === 1);
  const baraDataTyper = namn.every(n => Object.keys(SKOLHAST_PROFILER[n])
    .every(k => ["number", "string"].includes(typeof SKOLHAST_PROFILER[n][k])));

  /* d) KÄLLKEDJAN för tilldelningen. */
  let medKalla = 0, utanKalla = 0, fel = [];
  for (const [id, h] of Object.entries(HORSES)) {
    if (h.profilStatus === "KALLTEXT") { medKalla++;
      if (!h.besk || h.besk.length < 10) fel.push(id + ": profil utan beskrivning"); }
    else { utanKalla++;
      if (h.profil !== "skolhast") fel.push(id + ": profil utan källa"); }
  }
  return { klon, riktiga, namn, nyckelSet, skolhastEtt, baraDataTyper,
    medKalla, utanKalla, fel,
    anvanda: [...new Set(Object.values(HORSES).map(h => h.profil))].sort() };
});
{
  const k = prof.klon;
  const snabbast = k.kanslig.svarUpp, tregast = k.tung.svarUpp;
  prova("profilen är DATA: samma häst, bara profilnamnet bytt, ger mätbart olika svar",
    tregast > snabbast * 1.25 &&
    k.kanslig.balansIVolt < k.tung.balansIVolt - 0.03 &&
    k.arbetsvillig.energiEfter > k.tung.energiEfter + 0.05 &&
    k.skolhast.svarUpp > snabbast && k.skolhast.svarUpp < tregast,
    prof.namn.map(n => `${n}: svar ${k[n].svarUpp.toFixed(3)} s, balans ` +
      `${k[n].balansIVolt.toFixed(3)}, energi efter 8 min ${k[n].energiEfter.toFixed(3)}`).join(" · "));
  const r = prof.riktiga;
  prova("tre riktiga UBRF-hästar med var sin profil svarar olika på samma ritt",
    r.crokino.svarUpp < r.cosmo.svarUpp && r.cosmo.svarUpp < r.curiretto.svarUpp &&
    r.hjartat.energiEfter > r.curiretto.energiEfter,
    `Crokino (känslig) ${r.crokino.svarUpp.toFixed(3)} s · Cosmo (skolhäst) ` +
    `${r.cosmo.svarUpp.toFixed(3)} s · Curre (tyngre) ${r.curiretto.svarUpp.toFixed(3)} s · ` +
    `energi efter 8 min: Hjärtat ${r.hjartat.energiEfter.toFixed(3)} mot Curre ` +
    `${r.curiretto.energiEfter.toFixed(3)}`);
  prova("profilerna är en uppsättning tal, inte fyra kodvägar",
    prof.namn.length >= 3 && new Set(prof.nyckelSet).size === 1 &&
    prof.skolhastEtt && prof.baraDataTyper,
    `${prof.namn.length} profiler med identiska fält (${prof.nyckelSet[0]}), ` +
    `utgångsläget skolhast är 1,00 rakt igenom`);
  prova("varje tilldelad profil har en mening ur ridskolans egen beskrivning bakom sig",
    prof.fel.length === 0 && prof.medKalla >= 3 && prof.utanKalla >= 1 &&
    prof.anvanda.length >= 3,
    `${prof.medKalla} hästar med källtext, ${prof.utanKalla} utan (och de ligger kvar på ` +
    `utgångsläget), profiler i bruk: ${prof.anvanda.join(", ")}`);
}

/* ══════════════════════════════════════════════════════════════════
   G02-B PUNKT 5 — KONTRAKTET G02-C LÄSER (issue #83)

   "Telemetri som exponerar både hjälp och respons." Att fälten finns
   räcker inte: en läsare måste kunna se VILKA fält som är vad, annars
   får den gissa, och en gissning i ett kontrakt är en bugg som väntar.

   Provet läser den LEVANDE ritten — samma telemetri spelet självt
   skriver varje bildruta — och kräver att både hjälpen och svaret finns
   där med riktiga värden, inte bara som nycklar.
   ══════════════════════════════════════════════════════════════════ */
const kontraktG02C = await page.evaluate(() => {
  G.hastId = G.hastId || Object.keys(HORSES)[0]; G.hamtad = true; G.npcs = [];
  const dt = 1 / 60;
  G.ride = nyState(G.dagsform, 0.5, G.sadellage);
  G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0; ridNollstallHjalp();
  const kor = (o, sek) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0; RIDIN.sits = o.sits ?? 0;
    RIDIN.styr = o.styr ?? 0; RIDIN.parad = o.parad ?? 0; stegaRitt(dt); } };
  /* En riktig liten ritt: upp i trav, en parad, och en volt med kontakt —
     så att varje fält har hunnit få ett värde av något som hänt. */
  kor({ skankel: 1 }, 1.5); kor({}, 1.0); kor({ skankel: 1 }, 1.5); kor({}, 1.5);
  kor({ skankel: 0.7, tygel: 0.25, parad: 1 }, 0.3);
  kor({ skankel: 0.7, tygel: 0.25 }, 1.5);
  kor({ skankel: 0.6, tygel: 0.4, styr: 0.8 }, 6);
  const tm = G.telemetri;
  const hjalpFalt = tm._hjalpFalt, svarFalt = tm._svarFalt;
  /* Överlapp: ett fält som är både hjälp och svar betyder att någon av de
     två är felmärkt, och då kan G02-C inte läsa "vad bad ryttaren om" mot
     "vad gjorde hon av det". */
  const dubbla = hjalpFalt.filter(n => svarFalt.includes(n));
  const svarUtanVarde = svarFalt.filter(n => tm[n] === undefined);
  const hjalpUtanVarde = hjalpFalt.filter(n => !tm.hjalper || tm.hjalper[n] === undefined);
  return { hjalpFalt, svarFalt, dubbla, svarUtanVarde, hjalpUtanVarde,
    harledda: tm._harledda,
    prov: { bedd: tm.beddGangart, gangart: tm.gangart, cue: tm.cue,
      stod: tm.hjalper.ytterstod, balans: tm.balans, fokus: tm.fokus,
      energi: tm.energi, svarstid: tm.svarstid, paradKval: tm.paradKvalitet } };
});
prova("telemetrin skiljer på HJÄLPEN och SVARET, och båda har riktiga värden",
  kontraktG02C.dubbla.length === 0 &&
  kontraktG02C.svarUtanVarde.length === 0 &&
  kontraktG02C.hjalpUtanVarde.length === 0 &&
  kontraktG02C.hjalpFalt.length >= 8 && kontraktG02C.svarFalt.length >= 6,
  `${kontraktG02C.hjalpFalt.length} hjälpfält och ${kontraktG02C.svarFalt.length} ` +
  `svarsfält` +
  (kontraktG02C.dubbla.length ? `, ÖVERLAPP: ${kontraktG02C.dubbla.join(", ")}` : ", inget överlapp") +
  (kontraktG02C.svarUtanVarde.length ? `, SVAR UTAN VÄRDE: ${kontraktG02C.svarUtanVarde.join(", ")}` : "") +
  (kontraktG02C.hjalpUtanVarde.length ? `, HJÄLP UTAN VÄRDE: ${kontraktG02C.hjalpUtanVarde.join(", ")}` : "") +
  (kontraktG02C.dubbla.length + kontraktG02C.svarUtanVarde.length
    + kontraktG02C.hjalpUtanVarde.length === 0 ? ", alla ifyllda ur den levande ritten" : ""));
prova("och kontraktet räcker för att läsa en hjälp mot dess svar",
  kontraktG02C.prov.bedd !== undefined && kontraktG02C.prov.cue !== null &&
  kontraktG02C.prov.stod < 1 && kontraktG02C.prov.balans < 1 &&
  kontraktG02C.prov.svarstid > 0 && kontraktG02C.prov.paradKval > 0 &&
  kontraktG02C.prov.fokus !== undefined && kontraktG02C.prov.energi !== undefined &&
  kontraktG02C.harledda.length === 0,
  `bad ${kontraktG02C.prov.bedd} · går ${kontraktG02C.prov.gangart} · cue ` +
  `${kontraktG02C.prov.cue} · yttertygelstöd ${nf(kontraktG02C.prov.stod, 2)} → ` +
  `balans ${nf(kontraktG02C.prov.balans)} · svarstid ` +
  `${nf(kontraktG02C.prov.svarstid)} s · paradkvalitet ` +
  `${nf(kontraktG02C.prov.paradKval, 2)} · fokus ${nf(kontraktG02C.prov.fokus)} · ` +
  `energi ${nf(kontraktG02C.prov.energi)} · härledda ${JSON.stringify(kontraktG02C.harledda)}`);

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
  const mitt = { skankel: IN.kan.skankel.mal, tygel: IN.kan.tygel.mal, sits: IN.kan.sits.mal };
  RIDIN.tygel = 1; RIDIN.sits = 1; ridAvsiktTillHjalp();
  const tak = { tygel: IN.kan.tygel.mal, sits: IN.kan.sits.mal };
  RIDIN.tygel = 0; RIDIN.sits = 0; ridAvsiktTillHjalp();
  return { spel: mitt, tak,
    modell: { skankel: K.SKANKEL_NEUTRAL, tygel: K.TYGEL_NEUTRAL, sits: K.SITS_NEUTRAL },
    modellTak: { tygel: K.TYGEL_MAX, sits: K.SITS_MAX } };
});
{
  const d = k => Math.abs(neutral.spel[k] - neutral.modell[k]);
  prova("neutralläget är samma tal i modellen och i spelets inputlager",
    d("skankel") < 1e-9 && d("tygel") < 1e-9 && d("sits") < 1e-9,
    `skänkel ${neutral.spel.skankel} = ${neutral.modell.skankel}, ` +
    `tygel ${neutral.spel.tygel} = ${neutral.modell.tygel}, ` +
    `sits ${neutral.spel.sits} = ${neutral.modell.sits}`);
  /* Och taket. Paradens bestämdhet mäts mot det ryttaren FAKTISKT kan
     lägga på; räknas den mot 1,0 går den aldrig att be om helt. */
  const t = k => Math.abs(neutral.tak[k] - neutral.modellTak[k]);
  prova("hjälpens tak är samma tal i modellen och i spelets inputlager",
    t("tygel") < 1e-9 && t("sits") < 1e-9,
    `tygel ${neutral.tak.tygel} = ${neutral.modellTak.tygel}, ` +
    `sits ${neutral.tak.sits} = ${neutral.modellTak.sits}`);
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
  const t = ridTelemetri(s, aids, { kappa: 0.1, fas: 0.25, onskadFart: 3.2 });
  t._modell = { balans: s.balans, fokus: s.fokus, energi: s.energi };
  return t;
});
const tmRide = tm._modell;
const kravda = ["uppsutten", "gangart", "fart", "onskadFart", "kurvatur", "svangradie",
  "vridhastighet", "rytm", "spanning", "balans", "fokus", "hjalper"];
const saknas = kravda.filter(k => tm[k] === undefined);
prova("telemetrin exponerar gångart, fart/önskad fart, kurvatur, rytm, balans, fokus och hjälper",
  saknas.length === 0, saknas.length ? "saknas: " + saknas.join(", ") : `gångart ${tm.gangart}, fart ${tm.fart.toFixed(2)}, radie ${tm.svangradie.toFixed(1)} m`);
prova("telemetrin: vridhastighet = kurvatur × tempo (Gate 01:s formulering)",
  Math.abs(tm.vridhastighet - 0.1 * tm.fart) < 1e-9, `${tm.vridhastighet.toFixed(3)} rad/s`);
/* G02-B punkt 2 gav balans och fokus riktiga källor i modellen, och la
   till energi. Listan över härledda fält är därför TOM — och kravet är
   nu det omvända: den ska stämma med verkligheten åt båda hållen. Ett
   fält som räknas fram ur andra publicerade fält ska stå i listan, och
   ett som har egen källa ska inte stå där.

   Provet kontrollerar därför att de tre svarsfälten finns, att de INTE
   är märkta som härledda, och att de faktiskt kommer ur modellens
   tillstånd och inte ur telemetrins egen aritmetik: telemetrin läses två
   gånger med samma hjälper men olika modelltillstånd, och svaren ska
   följa tillståndet. */
prova("balans, fokus och energi är mätta ur modellen, inte härledda i telemetrin",
  Array.isArray(tm._harledda) && tm._harledda.length === 0 &&
  tm.balans !== undefined && tm.fokus !== undefined && tm.energi !== undefined &&
  tm.balans === tmRide.balans && tm.fokus === tmRide.fokus && tm.energi === tmRide.energi,
  `härledda ${JSON.stringify(tm._harledda)} · balans ${tm.balans.toFixed(3)}, ` +
  `fokus ${tm.fokus.toFixed(3)}, energi ${tm.energi.toFixed(3)} — samma tal som i modellen`);

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

/* 8f. PARADEN — G02-A.1 P5, genom inputlagret.

   Uppmätt före: en normal parad (tygel 0,65) och en mycket stark
   (0,95 + full sits) stannade från galopp på 2,58 mot 2,57 s med samma
   toppinbromsning 5,1 m/s². Hjälpens styrka ändrade alltså ingenting,
   och varje halt var en nödbromsning. Arbetsordern säger raka motsatsen:
   halten får se ut som en nödbromsning bara när ryttaren ber bestämt.

   Provet rider upp i galopp och parerar ned på två sätt, med samma häst
   och samma startläge. Kravet är att den bestämda paraden bromsar
   HÅRDARE — inte hur mycket, för hur hårt som känns rätt är game feel
   och Tobias sak. Dessutom: ingen krypning efter halt, och ingen
   gångart som studsar tillbaka. */
const parad = await page.evaluate(() => {
  const dt = 1 / 60;
  const kor = (o, sek, ut) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0;
    RIDIN.sits = o.sits ?? 0; RIDIN.styr = 0;
    stegaRitt(dt); if (ut) ut(); } };
  const stopp = (aid) => {
    G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
    for (let n = 0; n < 3; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
    const fran = G.ride.tempo;
    let t = 0, strack = 0, ret = 0, forra = G.ride.tempo, klar = null;
    kor(aid, 12, () => {
      strack += G.ride.tempo * dt; t += dt;
      ret = Math.max(ret, (forra - G.ride.tempo) / dt); forra = G.ride.tempo;
      if (klar === null && G.ride.tempo < 0.02 && G.ride.gangart === "halt") klar = t;
    });
    /* Och stå kvar: samma hjälp åtta sekunder till. */
    let kryp = 0, studs = false;
    kor(aid, 8, () => { kryp += Math.abs(G.ride.tempo) * dt;
      if (G.ride.gangart !== "halt") studs = true; });
    return { fran, tid: klar, strack, ret, kryp, studs, slut: G.ride.gangart };
  };
  /* Och längden på SJÄLVA förloppet, mätt tills modellen släpper det.
     Arbetsorderns kuvert för nedåtgående övergångar är 0,6–1,2 s, och
     P5 rör just den siffran — båda ändarna måste rymmas. */
  const forlopp = (aid) => {
    G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
    for (let n = 0; n < 3; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
    /* FÖRSTA förloppet, galopp→trav.

       "Mät tills _ov är tom" fungerar inte: paraden ger tre steg med
       0,9 s mellan sig och förloppen är nästan exakt så långa, så
       nästa börjar innan förra hunnit släppa och _ov är i praktiken
       aldrig tom under en parad. Uppmätt: fyra sekunder utan ett enda
       tomt mellanrum.

       Förloppets klocka (_ov.t) NOLLSTÄLLS däremot vid varje nytt
       steg. Toppvärdet strax före nollställningen ÄR längden.

       SISTA förloppet mäts, inte första. Hjälpen rampar in på 0,28 s
       och cue:n hinner falla innan tygeln är hemma, så paradens första
       steg är alltid mjukare än ryttaren bad om — även när hon drar
       fullt. Det är korrekt beteende, men det är inte den hjälp man
       ville mäta. */
    const toppar = [];
    let forra = -1;
    kor(aid, 5, () => {
      const nu = G.ride._ov ? G.ride._ov.t : -1;
      if (nu < forra && forra > 0) toppar.push(forra);
      forra = nu;
    });
    return toppar.length ? toppar[toppar.length - 1] : null;
  };
  /* Kuvertet måste hålla för HELA stallet, inte för en häst. Tyngden
     och trögheten skalar förloppets längd, så den lättaste och den
     tyngsta hästen ligger längst ut åt var sitt håll. */
  const ider = Object.keys(HORSES);
  const tung = ider.reduce((b, i) => HORSES[i].tyngd > HORSES[b].tyngd ? i : b, ider[0]);
  const latt = ider.reduce((b, i) => HORSES[i].tyngd < HORSES[b].tyngd ? i : b, ider[0]);
  const forHast = (id) => { G.hastId = id;
    return { mjuk: forlopp({ tygel: 0.60 }), bestamd: forlopp({ tygel: 1, sits: 1 }),
      tyngd: HORSES[id].tyngd, namn: HORSES[id].namn || id }; };
  const kuvert = { tung: forHast(tung), latt: forHast(latt) };
  G.hastId = ider[0];
  /* Lätt men hållande tygel mot full tygel och full sits. */
  return { mjuk: stopp({ tygel: 0.60 }), bestamd: stopp({ tygel: 1, sits: 1 }),
    kuvert, hast: G.hastId };
});
prova("paraden: en bestämd hjälp bromsar hårdare än en mjuk",
  parad.bestamd.ret > parad.mjuk.ret * 1.10
  && parad.mjuk.tid !== null && parad.bestamd.tid !== null,
  `topp ${parad.bestamd.ret.toFixed(2)} mot ${parad.mjuk.ret.toFixed(2)} m/s², ` +
  `halt på ${parad.bestamd.tid?.toFixed(2)} mot ${parad.mjuk.tid?.toFixed(2)} s, ` +
  `${parad.bestamd.strack.toFixed(2)} mot ${parad.mjuk.strack.toFixed(2)} m`);
{
  const rader = [parad.kuvert.tung, parad.kuvert.latt];
  const inne = v => v !== null && v >= 0.6 - 1e-9 && v <= 1.2 + 1e-9;
  prova("paraden: kuvertet 0,60–1,20 s håller för både tyngsta och lättaste hästen",
    rader.every(r => inne(r.mjuk) && inne(r.bestamd)),
    rader.map(r => `${r.namn} (tyngd ${r.tyngd.toFixed(2)}): ` +
      `mjuk ${r.mjuk?.toFixed(2)}, bestämd ${r.bestamd?.toFixed(2)} s`).join(" · "));
}
prova("paraden: ingen krypning och ingen gångart som studsar efter halt",
  parad.mjuk.kryp < 0.05 && parad.bestamd.kryp < 0.05
  && !parad.mjuk.studs && !parad.bestamd.studs
  && parad.mjuk.slut === "halt" && parad.bestamd.slut === "halt",
  `krypning ${parad.mjuk.kryp.toFixed(4)} / ${parad.bestamd.kryp.toFixed(4)} m på 8 s, ` +
  `studs ${parad.mjuk.studs || parad.bestamd.studs ? "JA" : "nej"}`);

/* 8g. KAMERA OCH KROPP — G02-A.1 P6.

   Arbetsordern är tydlig med ordningen: kameran tunas EFTER att
   rörelsen är rätt, och ingen visuell utjämning får dölja dålig fysik.
   Två saker provas därför, och de drar åt olika håll med flit.

   Att kameran ANDAS med gångarten: boomen längre, ögat högre och
   synfältet vidare ju snabbare hon går. Utan det ser galoppen ut precis
   som skritten, bara med marken rullande fortare förbi.

   Att den ändå inte SLÄPAR: kameran har en egen kurs som hinner ifatt
   hästens, och hinner den inte det går styrfelet inte att se — vilket
   är precis det arbetsordern förbjuder.

   Och att kroppens lutning kommer ur SIMULERINGEN och inte ur
   styrspaken: en häst som står still lutar inte hur mycket man än drar
   i tygeln. Lutningen är centripetalen κ·v², och v² är noll i halt. */
const kam = await page.evaluate(() => {
  const dt = 1 / 60;
  G.vy = "3d";
  const kor = (o, sek) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0;
    RIDIN.sits = o.sits ?? 0; RIDIN.styr = o.styr ?? 0;
    stegaRitt(dt); s3Kamera(dt); } };
  const nyRitt = () => { G.ride = nyState(G.dagsform, 0.5, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0; G.npcs = [];
    S3.kam.satt = false; S3.kam.yaw = undefined;
    S3.kam.bak = undefined; S3.kam.fov = undefined;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp(); };

  /* a) Läget per gångart, avläst när kameran hunnit sätta sig. */
  const lagen = {};
  for (const [namn, tryck] of [["halt", 0], ["skritt", 1], ["trav", 2], ["galopp", 3]]) {
    nyRitt();
    for (let n = 0; n < tryck; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
    kor({}, 3);
    lagen[namn] = { bak: S3.kam.bak, hojd: S3.kam.y, fov: S3.kam.fov,
      gangart: G.ride.gangart };
  }

  /* b) Kamerans eftersläpning.

     Första versionen mätte "tid till 90 % av kursändringen". Det går
     inte: under en pågående sväng ÄNDRAS kursen hela tiden, så målet
     flyttar sig och kameran når det aldrig. Den mätningen sa 1,87 s och
     betydde ingenting.

     Det man känner är i stället det STÅENDE vinkelavståndet mitt i en
     sväng — hur långt bakom hästens kurs bilden ligger — och hur fort
     det stängs när man slutar svänga. Det förra är eftersläpningen,
     det senare att den inte fastnar. */
  const slap = {};
  for (const [namn, tryck] of [["skritt", 1], ["galopp", 3]]) {
    nyRitt();
    for (let n = 0; n < tryck; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
    kor({}, 2);
    kor({ styr: 1 }, 4);                     // etablerad sväng
    const diff = () => { let d = G.rikt - S3.kam.yaw;
      while (d > Math.PI) d -= 2 * Math.PI; while (d < -Math.PI) d += 2 * Math.PI; return d; };
    const staende = Math.abs(diff());
    /* Släpp styrningen. Två tider mäts, och skillnaden mellan dem är
       kamerans egen andel: när HÄSTEN är rak, och när KAMERAN har
       hunnit ifatt. Mäter man bara det senare mäter man mest hästens
       urläggning — galoppen tar 0,70 s på sig att räta ut sig, och det
       är inte kamerans fel. */
    let t = 0, rak = null, stangd = null;
    for (let i = 0; i < 60 * 3; i++) {
      RIDIN.skankel = 0; RIDIN.styr = 0; RIDIN.tygel = 0; RIDIN.sits = 0;
      stegaRitt(dt); s3Kamera(dt); t += dt;
      if (rak === null && Math.abs(G.kappa) < 0.02) rak = t;
      if (stangd === null && Math.abs(diff()) < 0.02) stangd = t;
    }
    slap[namn] = { staende, rak, stangd, egen: (stangd !== null && rak !== null) ? stangd - rak : null,
      gangart: G.ride.gangart };
  }

  /* c) Lutningen ur simuleringen: full styrning i HALT ska ge noll. */
  nyRitt(); kor({ styr: 1 }, 4);
  const lutHalt = G.banLut, gangHalt = G.ride.gangart;
  nyRitt();
  for (let n = 0; n < 3; n++) { kor({ skankel: 1 }, 1.5); kor({}, 1.0); }
  kor({ styr: 1 }, 4);
  const lutGalopp = G.banLut, gangGalopp = G.ride.gangart;

  return { lagen, slap, lutHalt, gangHalt, lutGalopp, gangGalopp };
});
{
  const L = kam.lagen;
  const stiger = (f) => L.halt[f] < L.skritt[f] && L.skritt[f] < L.trav[f] && L.trav[f] < L.galopp[f];
  const ratt = ["halt", "skritt", "trav", "galopp"].every(g => L[g].gangart === g);
  prova("kameran: boom, öga och synfält växer med gångarten",
    ratt && stiger("bak") && L.halt.hojd < L.galopp.hojd && L.skritt.fov < L.galopp.fov,
    ["halt", "skritt", "trav", "galopp"].map(g =>
      `${g} ${L[g].bak.toFixed(2)} m / ${L[g].hojd.toFixed(2)} m / ${L[g].fov.toFixed(3)} rad`).join(" · "));
}
{
  const g = ["skritt", "galopp"].map(n => kam.slap[n]);
  prova("kameran: hinner ifatt hästens kurs — utjämningen döljer inte styrningen",
    g.every(r => r.staende < 0.26 && r.egen !== null && r.egen < 0.30),
    ["skritt", "galopp"].map(n => { const r = kam.slap[n];
      return `${n}: ${(r.staende * 180 / Math.PI).toFixed(1)}° bakom mitt i svängen, ` +
        `hästen rak på ${r.rak?.toFixed(2)} s och kameran ifatt ${r.egen?.toFixed(2)} s senare`;
    }).join(" · "));
}
prova("kroppen: lutningen kommer ur farten, inte ur styrspaken",
  Math.abs(kam.lutHalt) < 1e-3 && Math.abs(kam.lutGalopp) > 0.02
  && kam.gangHalt === "halt" && kam.gangGalopp === "galopp",
  `full styrning i halt ger ${kam.lutHalt.toFixed(5)} rad, ` +
  `i galopp ${kam.lutGalopp.toFixed(4)} rad`);

/* 8h. ÖVERGÅNGSTIDERNA MOT KANON — senior review 2026-09-05.

   Roblox körde tidigare linjär approach() mot den nya gångartens norm
   medan webben körde en mjukstegskurva över en bestämd längd. Tabellerna
   hade paritet men känslan hade det inte: ett byte tog olika lång tid
   och hade olika form på de två ytorna.

   Nu kör båda samma kurva över samma längd, och BÅDA klockar den.
   Roblox har samma prov i movement.spec med samma tolerans, ±0,08 s,
   mätt på en neutral häst. Talen ska alltså stå bredvid varandra i
   reviewen utan omräkning.

   Mätt i modellen och inte genom inputlagret: rampen där lägger till sin
   egen fördröjning innan cue:n faller, och den fördröjningen hör inte
   till förloppets längd. Roblox-provet mäter på samma nivå. */
const overgang = await page.evaluate(() => {
  const h = { kanslighet: 0.5, framatbjudning: 0.6, forlatande: 0.6, tyngd: 0.40,
    skygghet: 0.2, flaggor: {} };
  const ctx = { svangradie: 1000, underlag: 0.92, stallro: 0.9, utomhus: false,
    fard: {}, avdrift: { glid: 0, ryck: 0, "tröghet": 1 } };
  const dt = 1 / 240;
  const A = o => ({ skankel: 0, tygel: 0, sits: 0, styrning: 0,
    spo: false, lattridning: false, diagonal: 0, ...o });
  const NEUTRAL = { skankel: 0.42, tygel: 0.34, sits: 0.20 };
  const klocka = (tryck, ned) => {
    const s = nyState(0.7, 0.5, 0.8);
    const kor = (aid, sek) => { for (let i = 0; i < sek / dt; i++) stepRide(s, A(aid), h, ctx, dt); };
    for (let n = 0; n < tryck; n++) {
      kor({ ...NEUTRAL, skankel: 0.66 }, 2.0);
      kor(NEUTRAL, 1.2);
    }
    /* Cue:n, och sedan klockan över FÖRLOPPET.
       Klockan startar när förloppet startar, inte när hjälpen ges.
       G02-B punkt 2 la in hästens svarstid mellan de två, och den hör
       inte till förloppets längd — den mäts för sig i svarsprovet
       nedan. Roblox-provet klockar samma sträcka: Roblox har ingen
       svarstid ännu, så där sammanfaller de två. Blandades de ihop
       skulle det här provet mäta två saker och kunna bli grönt av att
       den ena växer medan den andra krymper. */
    const aid = ned ? { skankel: 0.05, tygel: 0.80, sits: 0.85 } : { ...NEUTRAL, skankel: 0.66 };
    let t = null, sett = null, vantan = 0;
    for (let i = 0; i < 4.0 / dt; i++) {
      stepRide(s, A(aid), h, ctx, dt);
      if (s._ov) { if (t === null) t = 0; sett = s._ov.langd; t += dt; }
      else if (t === null) vantan += dt;
      else return { t, langd: sett, vantan };
    }
    return { t: null, langd: sett, vantan };
  };
  return { hs: klocka(0, false), st: klocka(1, false),
    tg: klocka(2, false), ned: klocka(3, true),
    kanon: { hs: K.OVERGANG.upp.skritt, st: K.OVERGANG.upp.trav,
      tg: K.OVERGANG.upp.galopp, ned: K.OVERGANG.nerHart } };
});
{
  const rader = [["halt→skritt", "hs"], ["skritt→trav", "st"],
    ["trav→galopp", "tg"], ["galopp→trav (bestämt)", "ned"]];
  let varst = 0;
  const text = rader.map(([namn, k]) => {
    const m = overgang[k].t, kanon = overgang.kanon[k];
    varst = Math.max(varst, m === null ? 99 : Math.abs(m - kanon));
    return `${namn} ${m === null ? "—" : m.toFixed(2)}/${kanon.toFixed(2)}`;
  }).join(" · ");
  prova("övergångarna: uppmätt längd ligger inom ±0,08 s av kanon",
    varst <= 0.08, `(största avvikelse ${varst.toFixed(3)} s) ${text}`);
}

/* 9. DEN VERTIKALA SLICEN/* 9. DEN VERTIKALA SLICEN — G02-A.1 P7.

   Ett obrutet pass, i SPELETS runtime och genom RIDIN:

     sitt upp → halt → skritt → HÅLL skritt → trav → volt → galopp
     → sväng → trav → skritt → halt → sitt av

   Delarna provas var för sig ovanför. Det nya är att de körs efter
   varandra med samma häst och samma tillstånd — det är där en modell
   brukar spricka, på tillstånd som bara stämmer när provet börjar om.

   Slicen låg förut på stepRide() direkt. Den flyttades hit efter P4:
   ett pass som inte går genom inputlagret kan vara grönt medan spelet
   är ospelbart, och det VAR det. Nu ger provet samma tangenttryck som
   en spelare.

   Telemetrin läses i varje moment: cue, begärd gångart, verklig
   gångart, tempo, kurvatur och övergångstid. Arbetsordern kräver att
   de syns, inte bara att de finns. */
const slice = await page.evaluate(() => {
  const dt = 1 / 60;
  G.hastId = G.hastId || Object.keys(HORSES)[0];
  G.hamtad = true; G.npcs = []; G.vy = "3d";
  G.ride = nyState(G.dagsform, 0.5, G.sadellage);
  G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
  if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
  ridSittUpp("bandit", "ridhus");
  const uppe = RID_TILLSTAND.uppsutten;

  const sedda = [G.ride.gangart], steg = [];
  const kor = (o, sek) => { for (let i = 0; i < sek * 60; i++) {
    RIDIN.skankel = o.skankel ?? 0; RIDIN.tygel = o.tygel ?? 0;
    RIDIN.sits = o.sits ?? 0; RIDIN.styr = o.styr ?? 0;
    stegaRitt(dt); s3Kamera(dt);
    if (sedda[sedda.length - 1] !== G.ride.gangart) sedda.push(G.ride.gangart); } };
  /* En framåtimpuls: lägg på skänkeln, ta av den igen. */
  const impuls = () => { kor({ skankel: 1 }, 1.5); kor({}, 1.0); };
  const notera = (vad) => { const t = G.telemetri || {};
    steg.push({ vad, gangart: G.ride.gangart, bad: G.ride.malGangart,
      cue: G.ride.cue, tempo: +G.ride.tempo.toFixed(2),
      kappa: +G.kappa.toFixed(4), overgang: +(G.ride.senasteOvergang || 0).toFixed(2),
      iOvergang: !!t.iOvergang, telFart: t.fart === undefined ? null : +t.fart.toFixed(2) }); };

  kor({}, 2);                       notera("halt");
  impuls();                         notera("skritt");
  kor({}, 6);                       notera("håll skritt");   // hästen bär gångarten
  impuls();                         notera("trav");
  /* Volt i trav. En 20 m volt får inte plats i ett 20 × 60 m ridhus
     (se P4), så här rids den största som gör det — utslaget söks, och
     den ridna radien jämförs mot 1/κ. */
  let bastSt = 0.85, bastDiam = 0;
  kor({ styr: 0.85 }, 4);
  const voltKappa = Math.abs(G.kappa), voltDiam = voltKappa > 1e-4 ? 2 / voltKappa : 0;
  bastDiam = voltDiam;
  notera("volt");
  kor({}, 2);
  impuls();                         notera("galopp");
  kor({ styr: 0.6 }, 3);            notera("sväng");
  kor({}, 2);
  /* Ned igen, ett steg i taget med en hållen parad. */
  kor({ tygel: 1, sits: 1 }, 20);   notera("halt igen");
  ridSittAv();
  return { uppe, av: RID_TILLSTAND.uppsutten, steg, sedda,
    glapp: RID_TILLSTAND.glapp, voltDiam: bastDiam, voltSt: bastSt };
});
{
  const g = slice.steg.map(r => r.gangart);
  const vantad = ["halt", "skritt", "skritt", "trav", "trav", "galopp", "galopp", "halt"];
  const rattKedja = g.length === vantad.length && g.every((v, i) => v === vantad[i]);
  prova("slicen: sitt upp → halt → skritt → håll → trav → volt → galopp → sväng → halt → sitt av",
    slice.uppe === true && slice.av === false && rattKedja && slice.glapp === 0,
    `uppsutten ${slice.uppe} → ${slice.av}, moment ${g.join(" → ")}, ` +
    `sedda gångarter ${slice.sedda.join(" → ")}, ${slice.glapp} olagliga byten`);
  /* Hållet mitt i slicen är det PO-beslutet handlade om: sex sekunder
     med hjälpen av ska inte flytta henne ur skritten. */
  const hall = slice.steg.find(r => r.vad === "håll skritt");
  const skritt = slice.steg.find(r => r.vad === "skritt");
  prova("slicen: hästen BÄR skritten genom hela hållet",
    hall && skritt && hall.gangart === "skritt" && skritt.gangart === "skritt",
    `efter impulsen ${skritt?.gangart} ${skritt?.tempo} m/s, ` +
    `sex sekunder senare ${hall?.gangart} ${hall?.tempo} m/s`);
  /* Telemetrin ska följa med hela vägen — arbetsordern räknar upp
     precis vilka fält som ska synas. */
  const telOk = slice.steg.every(r => r.telFart !== null);
  prova("slicen: telemetrin följer med genom hela passet",
    telOk, slice.steg.map(r => `${r.vad}: ${r.gangart}/${r.telFart}`).join(", "));
  mat("slicens moment — begärd gångart, cue, tempo, kurvatur, övergångstid",
    slice.steg.map(r => `${r.vad} [bad ${r.bad}, cue ${r.cue}, ${r.tempo} m/s, ` +
      `κ ${r.kappa}, ${r.overgang}s]`).join(" · "));
  mat("slicens volt i trav (20 m ryms inte i hallen — se P4)",
    `styrutslag ${slice.voltSt} gav ${slice.voltDiam.toFixed(1)} m diameter`);
}

await browser.close(); srv.close();
const fel = resultat.filter(r => !r.ok).length;
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
