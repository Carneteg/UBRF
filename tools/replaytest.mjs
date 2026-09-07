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
     2700 varv = 90 s. */
  const dt = 1 / 30;
  const vag = [];
  for (let i = 0; i < 2700; i++) {
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
    ovning, forsok: hist.length,
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
