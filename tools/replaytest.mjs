#!/usr/bin/env node
/* G02-D — SPELAS RITTEN IN GENOM PRODUKTIONSFLÖDET?
 *
 * `tools/inspelningstest.mjs` provar modulen isolerat. Det säger ingenting
 * om att spelet faktiskt ANVÄNDER den — samma lärdom som läktaren (#114)
 * och som klient.spec på Roblox-sidan: en grön hjälpfunktion bevisar inte
 * att spelaren får något.
 *
 * Därför kör det här provet det byggda spelet i Chromium och låter
 * lektionsloopen (lararSteg → ugnetaForsokSteg → stegaLektion) driva två
 * riktiga försök. Ingen rad anropar Inspelning själv.
 *
 * Kör: python3 tools/build.py && node tools/replaytest.mjs */
import { chromium } from "playwright";
import http from "node:http";
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const PORT = +(process.env.PORT || 8836);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css",
  ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };
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
page.on("pageerror", e => console.log("PAGEERROR", e.message, "\n", (e.stack || "").split("\n").slice(0, 4).join("\n")));
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(900);
const ev = (f, a) => page.evaluate(f, a);
/* Samma sak, men ett fel i sidan blir ett RÖTT PROV i stället för en
   kraschad process. Mutationen "pausen gör ingenting" lät lektionen rida
   vidare bakom replayen och byta ut hela overlayen; nästa klick tog då
   på null och provet dog innan det hann säga varför. */
const evSafe = async (f, a) => { try { return await ev(f, a); }
  catch (e) { return { fel: String(e.message).split("\n")[0] }; } };

const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push(ok);
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };

/* Rider ett pass genom spelets egen loop och lämnar tillbaka det som
   gick att observera utifrån. Samma uppställning som ugneta-forsok-test:
   inget stubbas bort, bara det spelet självt sätter före lektionen. */
const kor = () => ev(() => {
  if (typeof SPAR !== "undefined" && SPAR) SPAR.pass = Math.max(1, SPAR.pass || 0);
  G.hastId = G.hastId || Object.keys(HORSES)[0];
  G.hastPlats = "box"; G.npcs = [];
  G.dagsform = 0.72; G.sadellage = 0.8;
  G.ride = nyState(G.dagsform, hastminne(G.hastId).rang, G.sadellage);
  G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
  if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
  lararNollstall();
  startaLektion();

  /* Momentet ska vara en övning som HAR en versionerad definition —
     annars spelas den med flit inte in. Lektionens första G02-övning är
     halt_skritt, som inte har någon ännu. */
  const ix = G.lektion.findIndex(m => {
    const o = ugnetaOvningFor(m);
    return o && typeof ovningsDef === "function" && ovningsDef(o.id);
  });
  if (ix < 0) return { fel: "ingen definierad G02-D-övning i lektionen" };
  G.momentIx = ix; G.moment = G.lektion[ix]; G.momentForsok = 1;
  G.momentT = 0; G.momentHall = 0; G.momentKlart = false;
  const ovning = ugnetaOvningFor(G.moment).id, momentId = G.moment.id;

  /* En RIKTIG ritt: spelets eget inputlager och stegaRitt, precis som
     ridtest kör den. Utan det stegas bara lektionens klocka och hästen
     står still — då hade provet mätt en inspelning av ingenting. */
  /* Momentet avslutas av lifecyclen vid moment.tid * 2.2 — för storvolten
     32 s, alltså 70,4 s. Loopen måste alltså rida LÄNGRE än så för att
     försöket ska hinna avslutas och posten hamna i historiken. 30 Hz i
     2700 varv = 90 s.

     G02-D rider TVÅ försök genom samma loop, med valpanelen emellan.
     Två gånger 70,4 s i 30 Hz är 4224 varv; taket är 5200 så att
     slutpanelen hinner visas. Mätt, inte gissat: med 2700 tog varven
     slut mitt i försök 2, och provet såg grönt ut på ett moment som
     aldrig avslutades. */
  const dt = 1 / 30;
  const vag = [];
  /* G02-D: valpanelen står mellan försöken. Provet svarar som spelaren —
     "Prova igen" en gång, och sedan stannar det vid slutpanelen så att
     replay-UI:t kan granskas där det faktiskt visas. Loopen stegar inte
     ritten vidare medan panelen är uppe; det är hela poängen med G.paus. */
  let paneler = 0, igenKlick = 0, slutpanel = false, forsokVidKlick = null;
  for (let i = 0; i < 5200; i++) {
    if (G.paus) {
      paneler++;
      const igen = document.getElementById("valIgen");
      if (igen) {
        /* Vilket försök stod vi på NÄR klicket gjordes? Utan den siffran
           går det inte att skilja "spelaren startade försök 2" från
           "lifecyclen red om av sig själv och panelen dök upp först
           efteråt". */
        if (forsokVidKlick === null) forsokVidKlick = G.momentForsok;
        igenKlick++; igen.click();
      }
      else { slutpanel = true; break; }
      continue;
    }
    RIDIN.skankel = 0.55; RIDIN.tygel = 0.34; RIDIN.sits = 0.2; RIDIN.styr = 0.42;
    stegaRitt(dt);
    lararSteg(dt);
    G.momentT += dt;
    stegaLektion(dt);
    vag.push([G.px, G.py]);
    if (!G.moment || G.moment.id !== momentId) break;
  }
  const hist = ugnetaForsokHistorik(ovning) || [];
  const post = ugnetaForsokPost(ovning, 1);
  return {
    ovning, forsok: hist.length, paneler, igenKlick, forsokVidKlick, slutpanel,
    seKnapp: !!document.getElementById("valSe"),
    igenKnapp: !!document.getElementById("valIgen"),
    bedomda: G.bedomda || 0,
    vagLangd: vag.length,
    post: post ? {
      schema: post.schema, ovning: post.ovning, ovningVersion: post.ovningVersion,
      hast: post.hast, profil: post.profil, klocka: post.klocka, ram: post.ram,
      sampel: post.sampel.length, sekunder: post.sekunder, trunkerad: post.trunkerad,
    } : null,
    lasbar: post ? inspelningLasbar(post) : null,
  };
});

console.log("\n── RITTEN SPELAS IN AV SPELET SJÄLVT ──");
const r = await kor();
prova("lektionsloopen producerar en inspelning utan att provet ber om det",
  !r.fel && !!r.post, r.fel || (r.post ? `${r.post.sampel} sampel på ${Number(r.post.sekunder).toFixed(1)} s` : "ingen post"));
prova("posten hör till den övning som faktiskt reds",
  !!r.post && r.post.ovning === r.ovning, r.post ? `${r.post.ovning} mot ${r.ovning}` : "—");
prova("och bär övningens version, hästen och profilen",
  !!r.post && r.post.ovningVersion !== null && !!r.post.hast,
  r.post ? `v${r.post.ovningVersion} · ${r.post.hast} · ${r.post.profil}` : "—");
prova("tiden är simklockan, inte väggklockan",
  !!r.post && r.post.klocka === "sim", r.post ? r.post.klocka : "—");
prova("posten är läsbar av den kod som kör nu",
  !!r.lasbar && r.lasbar.lage === "ok", r.lasbar ? `${r.lasbar.lage} ${r.lasbar.skal}` : "—");
prova("inspelningen ryms i taket — ingen trunkering på ett normalt pass",
  !!r.post && r.post.trunkerad === false, r.post ? String(r.post.trunkerad) : "—");

/* Sampeltakten mot loopen: 900 anrop à 0,1 s = 90 s ritt, men momentet
   avslutas långt innan. Det som ska stämma är FÖRHÅLLANDET — 20 Hz mot
   en loop som stegar 10 Hz betyder ett sampel per varv, inte fler. */
prova("takten följer loopen i stället för att skriva flera sampel per varv",
  !!r.post && r.post.sampel <= r.vagLangd,
  r.post ? `${r.post.sampel} sampel på ${r.vagLangd} loopvarv` : "—");

console.log("\n── VALET EFTER FÖRSÖKET ──");
prova("lifecyclen stannar och frågar i stället för att rida om automatiskt",
  !r.fel && r.paneler === 2 && r.igenKlick === 1 && r.forsokVidKlick === 1 && r.forsok === 2,
  r.fel || `${r.paneler} paneler · ${r.igenKlick} klick på Prova igen vid försök ${r.forsokVidKlick} · ${r.forsok} ridna försök`);
prova("slutpanelen erbjuder replayen men inte ett tredje försök",
  !r.fel && r.slutpanel === true && r.seKnapp === true && r.igenKnapp === false,
  r.fel || `slutpanel ${r.slutpanel} · Se ritten ${r.seKnapp} · Prova igen ${r.igenKnapp}`);
prova("två försök och två paneler ger ETT betyg, inte flera",
  !r.fel && r.bedomda === 1, r.fel || `bedomda ${r.bedomda}`);

console.log("\n── REPLAYEN SOM SPELAREN FAKTISKT ÖPPNAR ──");
{
  /* Här klickas det på riktigt i den byggda sidan. Ett prov som anropar
     visaReplay() direkt hade inte sagt något om att knappen finns, att
     den sitter i panelen eller att den gör något. */
  const oppna = await ev(() => {
    const b = document.getElementById("valSe");
    if (!b) return { fel: "ingen Se ritten-knapp i panelen" };
    b.click();
    return { fel: null,
      canvas: !!document.getElementById("replayBana"),
      spela: !!document.getElementById("replaySpela"),
      langsam: !!document.getElementById("replayLangsam"),
      skjut: !!document.getElementById("replaySkjut"),
      ghostKnapp: !!document.getElementById("replayGhost"),
      ghost: !!(REPLAY.ghost && REPLAY.ghost.sampel && REPLAY.ghost.sampel.length),
      spelar: !!(REPLAY.up && REPLAY.up.spelar),
      langd: REPLAY.up ? REPLAY.up.langd() : 0 };
  });
  prova("knappen öppnar en replay med bana och kontroller",
    !oppna.fel && oppna.canvas && oppna.spela && oppna.langsam && oppna.skjut,
    oppna.fel || `bana ${oppna.canvas} · spela ${oppna.spela} · fart ${oppna.langsam} · skjut ${oppna.skjut}`);
  prova("den jämför mot spelarens EGET förra försök, inte mot en mall",
    !oppna.fel && oppna.ghost === true && oppna.ghostKnapp === true,
    oppna.fel || `ghost ${oppna.ghost} · knapp ${oppna.ghostKnapp}`);
  prova("och det finns något att spela upp",
    !oppna.fel && oppna.langd > 1, oppna.fel || `${Number(oppna.langd).toFixed(1)} s`);

  /* Spelar den? Mätt på LÄGET, inte på flaggan `spelar` — en flagga som
     står på medan ingenting rör sig är precis felet provet ska hitta.

     Väntan är en poll med tak, inte en fast paus: headless Chromium
     ritar spelets 3D-scen i mjukvara och hinner bara några bildrutor i
     sekunden. En fast paus på 500 ms fångade första rAF-varvet, där dt
     är noll, och provet blev rött på en replay som faktiskt spelade. */
  const las = () => ev(() => REPLAY.up ? REPLAY.up.lage : -1);
  /* Öppnades replayen FAKTISKT? Knappen kan finnas utan att vyn kom upp
     — det var precis vad mutationen "försök 2 spelas inte in" gav, och
     då kraschade resten av avsnittet i stället för att rapportera. */
  const stangt = !!oppna.fel || !oppna.canvas;
  if (stangt) prova("resten av replay-avsnittet kunde köras", false,
    oppna.fel || "replayvyn öppnades inte");
  const fore = stangt ? 0 : await las();
  let efter = fore;
  for (let i = 0; i < 40 && efter <= fore; i++) { await page.waitForTimeout(200); efter = await las(); }
  prova("uppspelningen går framåt av sig själv",
    efter > fore, `${fore.toFixed(2)} → ${efter.toFixed(2)} s`);

  const p1 = stangt ? { spelar: null, lage: 0, etikett: "—" } : await evSafe(() => { document.getElementById("replaySpela").click();
    return { spelar: REPLAY.up.spelar, lage: REPLAY.up.lage,
      etikett: document.getElementById("replaySpela").textContent }; });
  await page.waitForTimeout(800);
  const p2raw = stangt ? 0 : await evSafe(() => REPLAY.up.lage);
  const p2 = typeof p2raw === "number" ? p2raw : NaN;
  prova("Pausa stoppar den — läget står stilla",
    p1.spelar === false && Number.isFinite(p2) && Math.abs(p2 - p1.lage) < 1e-9,
    `${p1.fel || p1.etikett} · ${p1.lage.toFixed(2)} → ${p2.toFixed(2)} s`);

  const halv = stangt ? { fart: null, etikett: "—" } : await evSafe(() => { const b = document.getElementById("replayLangsam");
    b.click(); return { fart: REPLAY.up.fart, etikett: b.textContent }; });
  prova("halv fart går att välja och syns på knappen",
    halv.fart === 0.5 && /Normal/i.test(halv.etikett), `${halv.fel || ""} ${halv.fart} · "${halv.etikett}"`);

  const skrubb = stangt ? { lage: 0, langd: 99, spelar: null } : await evSafe(() => {
    const s = document.getElementById("replaySkjut");
    s.value = "500"; s.dispatchEvent(new Event("input"));
    return { lage: REPLAY.up.lage, langd: REPLAY.up.langd(), spelar: REPLAY.up.spelar };
  });
  prova("spolningen sätter läget till ungefär mitten och pausar",
    Math.abs(skrubb.lage - skrubb.langd / 2) < 0.2 && skrubb.spelar === false,
    `${skrubb.fel || ""} ${Number(skrubb.lage).toFixed(2)} av ${Number(skrubb.langd).toFixed(2)} s`);

  const gh = stangt ? { av: null, pa: null, e1: "—", e2: "—" } : await evSafe(() => { const b = document.getElementById("replayGhost");
    b.click(); const av = REPLAY.ghostSyns; const e1 = b.textContent;
    b.click(); return { av, pa: REPLAY.ghostSyns, e1, e2: b.textContent }; });
  prova("förra försöket går att dölja och visa igen",
    gh.av === false && gh.pa === true && /Visa/i.test(gh.e1) && /Dölj/i.test(gh.e2),
    `${gh.fel || ""} ${gh.e1} → ${gh.e2}`);

  /* Reduced-motion-alternativet: samma uppgifter i läsbar form. */
  const txt = stangt ? { text: "", siffror: 0, tabell: false } : await evSafe(() => {
    const ruta = document.getElementById("replayRutnat");
    const t = ruta ? ruta.textContent : "";
    return { text: t, siffror: (t.match(/\d+,\d+/g) || []).length,
      tabell: !!(ruta && ruta.querySelector("table")) };
  });
  prova("mätvärdena finns som läsbar text bredvid banan, inte bara som bild",
    txt.tabell === true && txt.siffror >= 3,
    `${txt.fel || ""} tabell ${txt.tabell} · ${txt.siffror} mätvärden`);

  /* Read-only genom UI:t, inte bara genom modulen. */
  const ro = stangt ? { px: 0, py: 0, rikt: 0, forsok: -1 } : await evSafe(() => {
    const f = { px: G.px, py: G.py, rikt: G.rikt,
      gangart: G.ride && G.ride.gangart, tempo: G.ride && G.ride.tempo,
      forsok: (ugnetaForsokHistorik(REPLAY.ovningId) || []).length };
    document.getElementById("replaySpela").click();   // spela igen
    return f;
  });
  await page.waitForTimeout(800);
  const ro2 = stangt ? { orort: null, forsok: -2, paus: null } : await evSafe(f => ({
    orort: G.px === f.px && G.py === f.py && G.rikt === f.rikt
      && (G.ride && G.ride.gangart) === f.gangart && (G.ride && G.ride.tempo) === f.tempo,
    forsok: (ugnetaForsokHistorik(REPLAY.ovningId) || []).length,
    paus: !!G.paus }), ro);
  prova("en spelande replay rör varken hästen, ritten eller historiken",
    ro2.orort === true && ro2.forsok === ro.forsok,
    `${ro2.fel || ""} orört ${ro2.orort} · ${ro.forsok} → ${ro2.forsok} försök i historiken`);
  prova("och lektionen står kvar pausad bakom replayen",
    ro2.paus === true, `${ro2.fel || ""} G.paus ${ro2.paus}`);

  const ut = stangt ? { fel: "ingen replay öppnades" } : await evSafe(() => { const b = document.getElementById("replayTillbaka");
    if (!b) return { fel: "ingen Tillbaka-knapp" };
    b.click();
    return { fel: null, replayKvar: !!document.getElementById("replayBana"),
      valTillbaka: !!document.getElementById("valVidare"), raf: REPLAY.raf,
      paus: !!G.paus };
  });
  prova("Tillbaka stänger replayen och lämnar spelaren i valet, inte i tomma intet",
    !ut.fel && ut.replayKvar === false && ut.valTillbaka === true && ut.raf === 0,
    ut.fel || `replay kvar ${ut.replayKvar} · val ${ut.valTillbaka} · raf ${ut.raf}`);

  const slut = stangt ? { paus: null, bedomda: -1, ov: null } : await evSafe(() => { document.getElementById("valVidare").click();
    return { paus: !!G.paus, bedomda: G.bedomda || 0,
      ov: document.getElementById("ov").classList.contains("hide") }; });
  prova("Gå vidare släpper pausen utan att betygsätta momentet en gång till",
    slut.paus === false && slut.bedomda === 1 && slut.ov === true,
    `${slut.fel || ""} paus ${slut.paus} · bedomda ${slut.bedomda} · overlay dold ${slut.ov}`);
}

console.log("\n── ETT AVBRUTET MOMENT LÄMNAR INTE RITTEN OSTÄNGD ──");
{
  /* N hoppar över momentet (src/game.js, KeyN). Då blir varken
     G.momentKlart sant eller taket nått, så ugnetaForsokSteg upptäcker
     aldrig slutet — försöket hade blivit liggande öppet och den ridna
     ritten aldrig hamnat i historiken. Det är den vägen
     ugnetaStangForsok() finns för. Provet trycker på tangenten, det
     anropar ingen funktion. */
  const d = await ev(async () => {
    if (typeof SPAR !== "undefined" && SPAR) SPAR.pass = Math.max(1, SPAR.pass || 0);
    G.hastId = G.hastId || Object.keys(HORSES)[0];
    G.hastPlats = "box"; G.npcs = []; G.paus = false;
    G.dagsform = 0.72; G.sadellage = 0.8;
    G.ride = nyState(G.dagsform, hastminne(G.hastId).rang, G.sadellage);
    G.px = 10; G.py = 30; G.rikt = 0; G.kappa = 0;
    if (typeof ridNollstallHjalp === "function") ridNollstallHjalp();
    lararNollstall(); startaLektion();
    const ix = G.lektion.findIndex(m => { const o = ugnetaOvningFor(m);
      return o && typeof ovningsDef === "function" && ovningsDef(o.id); });
    if (ix < 0) return { fel: "ingen definierad övning" };
    G.momentIx = ix; G.moment = G.lektion[ix]; G.momentForsok = 1;
    G.momentT = 0; G.momentHall = 0; G.momentKlart = false;
    const ovning = ugnetaOvningFor(G.moment).id;
    const dt = 1 / 30;
    /* Bara spelets egen väg: stegaLektion räknar momentT och kallar
       lararSteg själv. Ett extra lararSteg(dt) här hade dubblerat både
       klockan och sampeltakten, och provet hade mätt sin egen loop. */
    for (let i = 0; i < 600; i++) {              // 20 s ritt, långt under taket 70,4 s
      RIDIN.skankel = 0.55; RIDIN.tygel = 0.34; RIDIN.sits = 0.2; RIDIN.styr = 0.42;
      stegaRitt(dt); stegaLektion(dt);
    }
    const fore = (ugnetaForsokHistorik(ovning) || []).length;
    const ridenT = G.momentT;
    window.dispatchEvent(new KeyboardEvent("keydown", { code: "KeyN", bubbles: true }));
    document.dispatchEvent(new KeyboardEvent("keydown", { code: "KeyN", bubbles: true }));
    const hoppFlagga = !!G.hoppaMoment;
    stegaLektion(dt);
    const hist = ugnetaForsokHistorik(ovning) || [];
    const post = ugnetaForsokPost(ovning, 1);
    return { fel: null, ovning, fore, efter: hist.length, hoppFlagga, ridenT,
      sekunder: post ? post.sekunder : null,
      insAktiv: !!(LARARE.inspelare && LARARE.inspelare.aktiv),
      paus: !!G.paus, seKnapp: !!document.getElementById("valSe") };
  });
  prova("tangenten N når spelet — det är produktvägen som provas",
    !d.fel && d.hoppFlagga === true, d.fel || `G.hoppaMoment ${d.hoppFlagga}`);
  prova("den avbrutna ritten stängs och hamnar i historiken",
    !d.fel && d.fore === 0 && d.efter === 1,
    d.fel || `${d.fore} → ${d.efter} försök`);
  /* Posten ska vara den PÅBÖRJADE ritten — kortare än momentet, längre
     än noll. Ugneta börjar mäta först efter sex sekunder (stegaLektion),
     så den täcker inte hela momentklockan och ska inte påstå det. */
  prova("och posten är den påbörjade ritten, inte ett helt moment",
    !d.fel && d.sekunder !== null && d.sekunder > 1 && d.sekunder < d.ridenT,
    d.fel || `${d.sekunder === null ? "ingen post" : d.sekunder.toFixed(1) + " s"} av ${Number(d.ridenT).toFixed(1)} s moment`);
  prova("inspelaren lämnas inte öppen efter avbrottet",
    !d.fel && d.insAktiv === false, d.fel || `aktiv ${d.insAktiv}`);
  await ev(() => { if (typeof valStang === "function") valStang(); G.paus = false; });
}

console.log("\n── MINDRE RÖRELSE: INNEHÅLLET FINNS ÄNDÅ ──");
{
  await page.emulateMedia({ reducedMotion: "reduce" });
  const d = await ev(() => {
    /* Vilken inspelning som helst som finns just nu — provet handlar om
       rörelsen, inte om vilken övning det var. Att låsa det till
       "storvolt, försök 2" gjorde avsnittet beroende av att ett tidigare
       avsnitt inte hade nollställt lektionen. */
    const id = Object.keys(LARARE.forsok || {}).find(k => replayFinns(k));
    if (!id) return { fel: "ingen post att visa" };
    const ok = visaReplay(id);
    const ruta = document.getElementById("replayRutnat");
    return { fel: ok ? null : "visaReplay nekade",
      spelar: !!(REPLAY.up && REPLAY.up.spelar),
      text: ruta ? ruta.textContent : "",
      tabell: !!(ruta && ruta.querySelector("table")) };
  });
  prova("uppspelningen startar inte av sig själv när mindre rörelse är begärt",
    !d.fel && d.spelar === false, d.fel || `spelar ${d.spelar}`);
  prova("men samma mätvärden står där i text",
    !d.fel && d.tabell === true && /mindre rörelse/i.test(d.text),
    d.fel || `tabell ${d.tabell}`);
  await ev(() => { stangReplay(); if (typeof valStang === "function") valStang(); });
  await page.emulateMedia({ reducedMotion: "no-preference" });
}

console.log("\n── POSTEN BESKRIVER DEN VÄG SOM FAKTISKT REDS ──");
{
  const d = await ev(() => {
    const post = ugnetaForsokPost("storvolt", 1) || ugnetaForsokPost("trav_skritt", 1);
    if (!post || !post.sampel.length) return { fel: "ingen post" };
    const s = post.sampel;
    /* Rörde sig hästen alls? En post full av samma punkt vore lika
       värdelös som ingen post — och skulle se grön ut i ett prov som
       bara räknar sampel. */
    let sprid = 0;
    for (const p of s) sprid = Math.max(sprid, Math.hypot(p.x - s[0].x, p.y - s[0].y));
    const up = new Uppspelning(post);
    let varst = 0;
    for (const p of s) {
      const q = up.vid(p.t);
      varst = Math.max(varst, Math.hypot(q.x - p.x, q.y - p.y));
    }
    return { sprid, varst, n: s.length,
      gangarter: [...new Set(s.map(p => p.gangart))].filter(Boolean) };
  });
  prova("hästen rörde sig — posten är inte en enda punkt om och om igen",
    !d.fel && d.sprid > 1, d.fel || `${Number(d.sprid).toFixed(1)} m från startpunkten`);
  prova("uppspelningen återger varje inspelat sampel exakt",
    !d.fel && d.varst < 1e-6, d.fel || `största avvikelse ${Number(d.varst).toExponential(1)} m`);
  prova("gångarten finns med i posten", !d.fel && d.gangarter.length > 0,
    d.fel || d.gangarter.join(" → "));
}

console.log("\n── UPPSPELNING RÖR INGENTING LEVANDE ──");
{
  const d = await ev(() => {
    const post = ugnetaForsokPost("storvolt", 1) || ugnetaForsokPost("trav_skritt", 1);
    if (!post) return { fel: "ingen post" };
    const fore = { px: G.px, py: G.py, rikt: G.rikt, scen: G.scen,
      gangart: G.ride && G.ride.gangart, tempo: G.ride && G.ride.tempo,
      post: JSON.stringify(post) };
    const up = new Uppspelning(post);
    up.spela(); for (let i = 0; i < 300; i++) up.steg(1 / 60);
    up.hoppa(post.sekunder / 2); up.sattFart(0.5); up.vid(up.lage); up.pausa();
    return { fel: null,
      levandeOrort: G.px === fore.px && G.py === fore.py && G.rikt === fore.rikt
        && G.scen === fore.scen && (G.ride && G.ride.gangart) === fore.gangart
        && (G.ride && G.ride.tempo) === fore.tempo,
      postOrord: JSON.stringify(post) === fore.post,
      lage: up.lage, langd: up.langd() };
  });
  prova("spelaren, hästen och scenen står orörda efter en uppspelning",
    !d.fel && d.levandeOrort, d.fel || "px/py/rikt/scen/gångart/tempo identiska");
  prova("och posten är byte-identisk efteråt", !d.fel && d.postOrord,
    d.fel || "oförändrad");
  prova("scrub landar i posten, inte utanför den",
    !d.fel && d.lage >= 0 && d.lage <= d.langd,
    d.fel || `${Number(d.lage).toFixed(2)} av ${Number(d.langd).toFixed(2)} s`);
}

console.log("\n── AVBROTT LÄMNAR INGEN HALV POST ──");
{
  const d = await ev(() => {
    G.ride = nyState(G.dagsform, hastminne(G.hastId).rang, G.sadellage);
    lararNollstall();
    startaLektion();
    /* Samma urval som ovan: bara en övning med definition spelas in. */
    const ix = G.lektion.findIndex(m => {
      const o = ugnetaOvningFor(m);
      return o && typeof ovningsDef === "function" && ovningsDef(o.id);
    });
    if (ix < 0) return { fel: "ingen definierad övning" };
    G.momentIx = ix; G.moment = G.lektion[ix]; G.momentForsok = 1;
    G.momentT = 0; G.momentKlart = false;
    for (let i = 0; i < 12; i++) { lararSteg(0.1); G.momentT += 0.1; }
    const mittI = !!(LARARE.inspelare && LARARE.inspelare.aktiv);
    lararNollstall();                       // avsittning/avbrott
    return { mittI, aktivEfter: !!(LARARE.inspelare && LARARE.inspelare.aktiv),
      historik: Object.keys(LARARE.forsok || {}).length };
  });
  prova("en påbörjad ritt spelas in", !d.fel && d.mittI, d.fel || String(d.mittI));
  prova("och ett avbrott stänger inspelaren i stället för att lämna den öppen",
    d.aktivEfter === false, `aktiv efter avbrott: ${d.aktivEfter}`);
  prova("den halva ritten hamnar inte i historiken", d.historik === 0,
    `${d.historik} övningar i historiken`);
}

const fel = resultat.filter(x => !x).length;
console.log(fel === 0 ? `\nALLA OK (${resultat.length} mätningar)` : `\n${fel} FEL av ${resultat.length}`);
await browser.close(); srv.close();
process.exit(fel === 0 ? 0 : 1);
