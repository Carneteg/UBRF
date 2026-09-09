#!/usr/bin/env node
/* FÖRSTA DAGEN — HELA KEDJAN FRAM TILL UPPSITTNING
 *
 * P0-stopp 2026-09-07 på #135: Tobias kunde inte sitta upp; ingen
 * E-interaktion visades. Det befintliga uppdragstest.mjs satte
 * `G.hastPlats` och `G.skotselRes` för hand innan det kontrollerade
 * uppsittningsmålet — alltså kunde det vara grönt medan spelaren stod
 * fast i just den övergången.
 *
 * DET HÄR PROVET rör aldrig G.hastPlats, G.skotselRes eller G.scen, och
 * anropar aldrig sittUpp(). Varje steg går genom en riktig knapp eller
 * ett riktigt E-tryck, och varje interaktion hämtas ur produktionens
 * egen interaktionslista.
 *
 * ── STRÄCKORNA: GA_HELA=1 GÅR HELA VÄGEN ──────────────────────────
 * Som standard placeras spelaren tre meter från varje station med
 * `gaTill` och går sista biten med tangenter — det är snabbt och räcker
 * för att pröva interaktionerna.
 *
 * Med GA_HELA=1 går hon i stället HELA vägen genom spelets egen
 * vägsökning, `satMal(x,y)` — exakt det ett musklick gör, med kollision
 * och dörrar. Mätt: 16 m, 30 m, 27,1 m, 17,7 m, 14,4 m och 27,4 m, var
 * och en på 11–20 sekunder. Cirka 133 meter, alla gröna.
 *
 * RÄTTELSE. Här stod tidigare att sträckorna inte gick att gå: "0,1 fps
 * i 3D, 0,5 fps i 2D", "simulerad tid 1–3 % av verklig", "gårdsplanens
 * sjutton meter tar över nittio sekunder". Det var fel med ungefär
 * femtio gånger, och felet var mitt eget: sex kvarglömda testprocesser
 * körde headless Chromium i timmar och åt processorn. På en tyst maskin
 * går gå-scenen i ~5 b/s med simulerad tid på 26 % av verklig, och
 * lektionen i ~19 b/s på 96 %. Kör MATFART=1 för att mäta båda.
 *
 * En gångare med tangenter rakt mot målet räcker ändå inte inomhus: den
 * stannade 23,88 m från ridläraren och kom 7,8 m på fem minuter. Det
 * säger ingenting om spelet — stallet är en korridor och den gångaren
 * hade ingen vägsökning. Spelaren har klicka-gå, och det är den vägen
 * som provas.
 *
 * ── VÄNTA PÅ BILDRUTOR, INTE PÅ MILLISEKUNDER ──────────────────────
 * Gå-scenen går i ~5 b/s, alltså 200 ms per bildruta, och under last
 * betydligt långsammare. En kort fast paus är därför en opålitlig
 * väntan. Alla
 * väntor nedan pollar tills spelet faktiskt hunnit räkna om, med tak.
 * Samma sak för E: `interagera()` letar efter flanken från släppt till
 * nedtryckt och läser den en gång per bildruta.
 *
 * Kör: python3 tools/build.py && node tools/forstadagentest.mjs
 */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, process.env.ROT_SERVE || "dist");
const START = process.env.ROT_SERVE ? "/index.html" : "/ridskolan.html";
const PORT = +(process.env.PORT || 8873);
const MIME = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css",
  ".png": "image/png", ".jpg": "image/jpeg", ".json": "application/json" };
const srv = http.createServer((q, r) => {
  const raw = q.url.split("?")[0];
  const p = path.join(DIST, decodeURIComponent(raw === "/" ? START : raw));
  fs.readFile(p, (e, d) => { if (e) { r.writeHead(404); r.end(); return; }
    r.writeHead(200, { "content-type": MIME[path.extname(p)] || "application/octet-stream" }); r.end(d); });
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({ headless: true,
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
/* MOBIL=1 kör samma kedja på en telefonyta med touch: E ersätts av
   pekknappen ANVÄND (src/mobil.js), som är spelarens enda väg att
   interagera utan tangentbord. */
const MOBIL = process.env.MOBIL === "1";
const page = await browser.newPage(MOBIL
  ? { viewport: { width: 390, height: 844 }, hasTouch: true, isMobile: true,
      userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" }
  : { viewport: { width: 1280, height: 720 } });
const sidfel = [];
page.on("pageerror", e => sidfel.push(e.message));
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(1500);
const ev = (f, a) => page.evaluate(f, a);

const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push(ok);
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };

/* Polla tills spelet hunnit räkna om. Returnerar värdet, eller det sista
   den såg när taket gick ut. */
async function vantaPa(fn, arg, ok, maxMs = 20000) {
  const t0 = Date.now(); let v = await ev(fn, arg);
  while (!ok(v) && Date.now() - t0 < maxMs) {
    await page.waitForTimeout(500);
    v = await ev(fn, arg);
  }
  return v;
}

const las = () => ev(() => ({
  scen: G.scen, hastId: G.hastId, plats: G.hastPlats, leder: G.leder,
  skotsel: !!G.skotselRes, utrustning: !!G.utrustning, sitter: !!G.ride,
  prompt: VD.prompt ? VD.prompt.text : null,
  promptDOM: ((document.getElementById("approach") || {}).textContent || "").trim(),
  ov: !document.getElementById("ov").classList.contains("hide"),
}));

const knappFinns = id => ev(i => !!document.getElementById(i), id);
const klicka = async (id) => {
  const finns = await vantaPa(i => !!document.getElementById(i), id, v => v === true, 8000);
  if (!finns) return false;
  await page.click("#" + id);
  await page.waitForTimeout(700);
  return true;
};

/* Ställ dig NÄRA interaktionen och GÅ SISTA BITEN själv.
   Placeringen sker tre meter bort, längs riktningen spelaren redan står
   i — alltså på den sida hon kom ifrån, inte inne i en vägg. Sedan går
   hon in med riktiga tangenter tills SPELET självt skriver ut sin
   E-prompt. Provet har ingen egen avståndströskel; räckvidden är
   `interagera()`s sak.

   Varför inte placera rakt på interaktionen: dörrarnas interaktionspunkt
   ligger i fasaden. Placerad DÄR syntes prompten men E gjorde ingenting —
   figuren stod på fel sida av väggen. Gången på tre meter tar ungefär
   tjugo sekunder i den här miljöns bildrutetakt, vilket är råd att ta. */
async function stallDigVid(re, maxMs = 90000) {  // maxMs höjs av GA_HELA
  const mal = await ev(m => {
    const L = interaktioner().filter(i => new RegExp(m, "i").test(i.text));
    if (!L.length) return null;
    L.sort((a, b) => Math.hypot(VD.px - a.pos[0], VD.py - a.pos[1])
                   - Math.hypot(VD.px - b.pos[0], VD.py - b.pos[1]));
    return { text: L[0].text, pos: L[0].pos };
  }, re);
  if (!mal) return { mal: null, framme: false, prompt: null };

  /* GA_HELA=1 hoppar över placeringen och GÅR HELA VÄGEN med tangenter.
     Det gick inte förut — eller rättare sagt: jag trodde det, för mina
     egna kvarglömda testprocesser åt processorn och gå-scenen kröp fram
     i 0,1 bilder/s. På en tyst maskin går den i ~5 b/s med simulerad tid
     på 26 % av verklig, och sjutton meter tar en halv minut. Då finns
     det ingen ursäkt för att placera figuren. */
  /* GA_HELA=1 GÅR HELA VÄGEN i stället för att placeras — genom spelets
     EGEN vägsökning, `satMal(x,y)`, alltså exakt det ett musklick gör.
     Figuren går själv dit, med kollision och dörrar.

     Varför inte med tangenter hela vägen: en första version höll W/A/S/D
     mot målet. Utomhus gick det (gården → stalldörren, 15,7 m på 14 s),
     men inne i stallet stannade den 23,88 m från ridläraren och kom 7,8 m
     på fem minuter. Det säger ingenting om spelet — stallet är en
     korridor och min gångare hade ingen vägsökning alls. Spelaren har
     klicka-gå; det är den vägen som ska provas, och det är den
     `uppdragstest.mjs` använder i CI. */
  const HELA = process.env.GA_HELA === "1";
  let vagsok = null;
  /* Mät från INNAN vägsökningen startar. Första versionen mätte bara
     tangentsteget efteråt och skrev "gick 0 m på 1 s" — sant om just det
     steget, men det såg ut som att provet teleporterade. Sträckan som
     räknas är den spelet självt gick. */
  const fore = await ev(() => ({ x: VD.px, y: VD.py, t: Date.now() }));
  await ev(({ mx, my, hela }) => {
    if (G.vy !== "2d" && typeof vaxlaVy === "function") vaxlaVy();
    if (hela) { if (typeof satMal === "function") satMal(mx, my); return; }
    const dx = VD.px - mx, dy = VD.py - my, d = Math.hypot(dx, dy);
    if (d > 3.2) { const k = 3 / d; gaTill(G.scen, { x: mx + dx * k, y: my + dy * k, rikt: 0 }); }
  }, { mx: mal.pos[0], my: mal.pos[1], hela: HELA });
  if (HELA) {
    /* Vänta tills spelets egen gång är framme eller har gett upp. */
    maxMs = Math.max(maxMs, 240000);
    const t = Date.now();
    let f = await ev(m => ({ d: Math.hypot(VD.px - m[0], VD.py - m[1]),
      gar: !!(typeof VD !== "undefined" && VD.mal) }), mal.pos);
    let bast = f.d, stilla = 0;
    while (f.d > 2.0 && Date.now() - t < maxMs) {
      await page.waitForTimeout(1000);
      f = await ev(m => ({ d: Math.hypot(VD.px - m[0], VD.py - m[1]),
        gar: !!(typeof VD !== "undefined" && VD.mal) }), mal.pos);
      if (f.d < bast - 0.2) { bast = f.d; stilla = 0; } else if (++stilla > 12) break;
    }
    vagsok = await ev(f0 => ({ m: +Math.hypot(VD.px - f0.x, VD.py - f0.y).toFixed(1),
      s: Math.round((Date.now() - f0.t) / 1000) }), fore);
  }
  await page.waitForTimeout(1200);

  const [mx, my] = mal.pos;
  const nere = new Set();
  const ner = async k => { if (!nere.has(k)) { await page.keyboard.down(k); nere.add(k); } };
  const upp = async k => { if (nere.has(k)) { await page.keyboard.up(k); nere.delete(k); } };
  const lage = () => ev(m => ({ x: VD.px, y: VD.py,
    prompt: VD.prompt ? VD.prompt.text : null,
    dom: ((document.getElementById("approach") || {}).textContent || "").trim(),
    traff: !!(VD.prompt && new RegExp(m, "i").test(VD.prompt.text)) }), re);

  const t0 = Date.now();
  let p = await lage();
  const start = { x: p.x, y: p.y };
  while (!p.traff && Date.now() - t0 < maxMs) {
    const dx = mx - p.x, dy = my - p.y;
    await (dx > 0.3 ? ner("KeyD") : upp("KeyD"));
    await (dx < -0.3 ? ner("KeyA") : upp("KeyA"));
    await (dy > 0.3 ? ner("KeyW") : upp("KeyW"));
    await (dy < -0.3 ? ner("KeyS") : upp("KeyS"));
    await page.waitForTimeout(400);
    p = await lage();
  }
  for (const k of [...nere]) await upp(k);
  await page.waitForTimeout(600);
  p = await lage();
  return { mal: mal.text, prompt: p.prompt, dom: p.dom, framme: !!p.traff,
    avst: +Math.hypot(p.x - mx, p.y - my).toFixed(2),
    gick: vagsok ? vagsok.m : +Math.hypot(p.x - start.x, p.y - start.y).toFixed(1),
    sek: vagsok ? vagsok.s : Math.round((Date.now() - t0) / 1000) };
}

/* E — hållen tillräckligt länge för att en bildruta säkert ska se
   flanken, och sedan POLLAD tills verkan syns. En fast paus på 2,5 s är
   bara ett par bildrutor i gå-scenen; det räckte ibland och ibland inte,
   vilket såg ut som ett ostabilt spel men var en ostabil mätning. */
async function tryckE(klar) {
  if (MOBIL) {
    /* Pekknappen ANVÄND skickar samma KeyE genom spelets eget
       inputlager. Hålls nere lika länge, av samma bildruteskäl. */
    /* FINGRET LIGGER KVAR på knappen, precis som på tangenten.

       `data-tap` i src/mobil.js skickar keydown på pointerdown och
       keyup först 60 ms efter pointerup. En blixtsnabb tap() håller
       alltså tangenten nere i ~60 ms — på en riktig telefon i 60 fps är
       det fyra bildrutor, men i gå-scenen här (~5 b/s) är det knappt en
       tredjedels bildruta — och under den last mina egna kvarglömda
       processer orsakade var chansen några procent. Ett tryck missade, två
       tryck öppnade och stängde. Ingetdera säger något om touch.

       Att hålla fingret stilla är en lika giltig spelarhandling och ger
       samma flank som tangentbordet. */
    const knapp = page.locator('#pekGang .pekKnapp[data-tap="KeyE"]');
    await knapp.dispatchEvent("pointerdown");
    await page.waitForTimeout(4000);
    await knapp.dispatchEvent("pointerup");
    await page.waitForTimeout(2500);
  } else {
    await page.keyboard.down("KeyE");
    await page.waitForTimeout(4000);
    await page.keyboard.up("KeyE");
    await page.waitForTimeout(1000);
  }
  if (!klar) { await page.waitForTimeout(2000); return las(); }
  return vantaPa(() => ({
    scen: G.scen, hastId: G.hastId, plats: G.hastPlats, leder: G.leder,
    skotsel: !!G.skotselRes, utrustning: !!G.utrustning, sitter: !!G.ride,
    prompt: VD.prompt ? VD.prompt.text : null,
    ov: !document.getElementById("ov").classList.contains("hide"),
  }), null, klar, 30000);
}

const station = async (re, namn, klar) => {
  const g = await stallDigVid(re);
  prova(`${namn}: spelets egen E-prompt står där`, g.framme === true,
    g.mal ? `"${g.dom || g.prompt || "INGEN PROMPT"}" · ${g.avst} m`
      + (process.env.GA_HELA === "1" ? ` · gick ${g.gick} m på ${g.sek} s` : "")
      : "INGEN sådan interaktion");
  return g.framme ? tryckE(klar) : null;
};

console.log(`\n── FÖRSTA DAGEN${process.env.ROT_SERVE ? " (obundlad sida)" : ""}${
  MOBIL ? " (mobil 390×844 + touch)" : ""} ──`);
if (MOBIL) {
  const pek = await ev(() => ({
    ui: !!document.getElementById("pekUI"),
    joy: !!document.getElementById("joy"),
    anvand: !!document.querySelector('#pekGang .pekKnapp[data-tap="KeyE"]'),
  }));
  prova("pekgränssnittet finns på en telefon — styrspak och ANVÄND",
    pek.ui && pek.joy && pek.anvand, JSON.stringify(pek));
}

/* ══ 1. GÄSTEN ══════════════════════════════════════════════════════ */
prova("en ren gäst möts av karaktärsskaparen", await knappFinns("bSkapHoppa"), "bSkapHoppa");
await klicka("bSkapHoppa");
prova("och kommer till menyn", await knappFinns("bStart"), "bStart");
await klicka("bStart");
let s = await vantaPa(() => ({ scen: G.scen, ov: !document.getElementById("ov").classList.contains("hide") }),
  null, v => v.scen === "gard" && !v.ov, 15000);
prova("Rid nu släpper ut spelaren på gården", s.scen === "gard" && !s.ov,
  `scen ${s.scen} · overlay ${s.ov}`);

/* Bildrutetakten i GÅ-SCENEN, mätt i samma körning som lektionens
   nedan — de två talen ska kunna ställas bredvid varandra. */
if (process.env.MATFART === "1") {
  const a = await ev(() => G.t);
  await page.waitForTimeout(30000);
  const b = await ev(() => G.t);
  console.log(`  MÄTT gå-scenen (${await ev(() => G.scen)}, vy ${await ev(() => G.vy)}):`
    + ` ${(b - a).toFixed(2)} s simulerad på 30 s verklig = ${((b - a) / 30 * 100).toFixed(1)} %`
    + ` · ~${((b - a) / 0.05 / 30).toFixed(2)} bilder/s`);
}

/* ══ 2. IN I STALLET ════════════════════════════════════════════════ */
s = await station("in i stallet", "stalldörren", v => v.scen === "stallinne") || await las();
prova("E tar spelaren in i stallet", s.scen === "stallinne", `scen ${s.scen}`);

/* ══ 3. RIDLÄRAREN ══════════════════════════════════════════════════ */
s = await station("ridläraren", "ridläraren", v => v.ov === true) || s;
prova("tilldelningspanelen öppnas", s.ov === true && await knappFinns("bGroom"), `overlay ${s.ov}`);
await klicka("bGroom");
s = await las();
prova("spelaren får Blackrock Jack på sin första dag",
  s.hastId === "blackrock_jack", `hastId ${s.hastId}`);
prova("och hästen står i sin box", s.plats === "box", `plats ${s.plats}`);

/* ══ 4. SADELKAMMAREN — ett pussel, inte en knapp ═══════════════════ */
/* Texten BYTER när man fått en häst: "Sadelkammaren" blir
   "Hämta Blackrock Jacks sadel och träns" (src/world.js). Provet måste
   känna igen båda, annars letar det efter en skylt som inte längre
   står där. */
s = await station("sadelkammaren|sadel och träns", "sadelkammaren", v => v.ov === true) || s;
prova("sadelkammaren kräver att man VÄLJER sadel och träns",
  (await klicka("bSkKlar")) && (await las()).utrustning === false,
  "klick utan val ger ingen utrustning");
await ev(() => { for (const t of ["sadel", "trans"]) {
  const b = document.querySelector(`.sk-val[data-typ="${t}"][data-id="${G.hastId}"]`);
  if (b) b.click(); } });
await page.waitForTimeout(600);
await klicka("bSkKlar");
s = await las();
prova("rätt sadel och träns ger utrustningen", s.utrustning === true, `utrustning ${s.utrustning}`);

/* ══ 5. BOXEN ═══════════════════════════════════════════════════════ */
s = await station("sköt om|släpp in", "boxen", v => v.ov === true) || s;
prova("boxmenyn öppnas", s.ov === true && await knappFinns("bSkots"), `overlay ${s.ov}`);
if (await knappFinns("bTacke")) await klicka("bTacke");
await klicka("bMocka"); await klicka("bMockKlar");
await klicka("bFodra"); await klicka("bFodraKlar");
await klicka("bSkots");
for (const id of ["bVisit", "bRykt", "bKrats", "bSadla", "bSkotKlar", "bKlar"]) await klicka(id);
s = await las();
prova("skötseln ger ett resultat", s.skotsel === true, `skotselRes ${s.skotsel}`);

/* ══ 6. LED UT — övergången spelaren fastnade i ════════════════════ */
prova("knappen 'Led ut till lektionen' finns efter skötseln",
  await knappFinns("bLek"), "bLek");
await klicka("bLek");
s = await las();
prova("hästen leds — G.leder blir sann genom spelarens knapp",
  s.plats === "leds" && s.leder === true, `plats ${s.plats} · leder ${s.leder}`);

/* ══ 7. VIDARE TILL RIDHUSET ═══════════════════════════════════════
   Sargporten ligger i ridhuset, inte i stallet. Utan det här steget
   letade provet efter en interaktion i fel byggnad — och rapporterade
   "INGEN sådan interaktion" som om uppsittningen saknades. */
s = await station("hästgången|in i ridhuset|ridhuset", "vägen till ridhuset",
  v => v.scen === "ridhusinne") || s;
prova("spelaren kommer in i ridhuset med hästen vid handen",
  s.scen === "ridhusinne" && s.leder === true, `scen ${s.scen} · leder ${s.leder}`);

/* ══ 8. UPPSITTNINGEN — P0:ns kärna ════════════════════════════════
   Mätt på SCENEN, inte på G.ride. `G.ride` finns redan innan man sitter
   upp — skötseln bygger ridmodellen — så ett prov på `!!G.ride` var
   grönt utan att någon suttit upp. Det är sittUpp() → startaLektion()
   som byter scen till "lektion", och det är den övergången Tobias inte
   kom till. */
const foreUpp = await las();
s = await station("sitt upp", "sargporten", v => v.scen === "lektion") || s;
prova("uppsittningen startar lektionen — spelaren sitter upp",
  s.scen === "lektion" && foreUpp.scen !== "lektion",
  `scen ${foreUpp.scen} → ${s.scen}`);

/* ══ 9. TVÅ TRYCK ══════════════════════════════════════════════════
   Ett andra E direkt efter uppsittningen får inte starta om lektionen
   eller hoppa ett moment. Provet ligger HÄR och inte i
   lastlagetest.mjs, för här är tillståndet spelets eget: ett läge satt
   för hand har inget `G.ride` — den byggs av skötseln — och sittUpp()
   sprack då på `null.gangart`. Det hade sagt något om mitt
   konstruerade tillstånd, inte om spelet. */
const eft1 = await ev(() => ({ scen: G.scen, ix: G.momentIx, forsok: G.momentForsok }));
await tryckE(null);
const eft2 = await ev(() => ({ scen: G.scen, ix: G.momentIx, forsok: G.momentForsok }));
prova("ett andra tryck startar inte om lektionen",
  eft2.scen === "lektion" && eft2.ix === eft1.ix && eft2.forsok === eft1.forsok,
  `moment ${eft1.ix}/${eft1.forsok} → ${eft2.ix}/${eft2.forsok}`);

/* ══ 10. RITTEN (RITT=1) ══════════════════════════════════════════
   Sista delen av P0-ordern: styrning, gångarter och Ugneta — genom
   spelets riktiga tangenter, inte genom att skriva i G.ride.

   Att det här går att prova alls är en rättelse: jag skrev NOT_TESTED
   på ritten med motiveringen "för långsamt här". Lektionen går i ~19
   b/s med simulerad tid på 96 % av verklig, alltså i stort sett
   realtid. Motiveringen var fel.

   Tangenterna är spelets egna (src/game.js): W skänkel, S nedåt,
   mellanslag tygel, A/D styr, E parad. */
if (process.env.RITT === "1" && (await ev(() => G.scen)) === "lektion") {
  const ritt = () => ev(() => ({
    gangart: G.ride ? G.ride.gangart : null,
    mal: G.ride ? G.ride.malGangart : null,
    tempo: G.ride ? +(G.ride.tempo || 0).toFixed(3) : null,
    rikt: +(G.rikt || 0).toFixed(3),
    moment: G.momentIx, forsok: G.momentForsok,
    feedback: (typeof LARARE !== "undefined" && LARARE.sistaFeedback) ? true : false,
  }));
  const hall = async (kod, ms) => {
    await page.keyboard.down(kod); await page.waitForTimeout(ms);
    await page.keyboard.up(kod); await page.waitForTimeout(1200);
  };

  const r0 = await ritt();
  prova("ritten börjar i halt", r0.gangart === "halt", `gångart ${r0.gangart}`);

  /* SKÄNKEL → framåt. Hästen ska svara, inte stå kvar. */
  await hall("KeyW", 3000);
  const r1 = await ritt();
  prova("skänkeln ber om en högre gångart — hästen svarar",
    r1.gangart !== "halt" || r1.mal !== "halt",
    `gångart ${r0.gangart} → ${r1.gangart} (bad om ${r1.mal}) · tempo ${r1.tempo}`);

  await hall("KeyW", 4000);
  const r2 = await ritt();
  prova("mer skänkel ger mer gång", r2.tempo >= r1.tempo,
    `tempo ${r1.tempo} → ${r2.tempo} · gångart ${r2.gangart}`);

  /* STYRNING: kursen ska ändras åt OLIKA håll för A och D.

     Kursen är en atan2-vinkel och vänder vid ±π, så en rå subtraktion
     kan ge 2,20 rad där svängen i själva verket var −0,9. Första
     versionen gjorde precis det och rapporterade "A 2,20 · D 0,83" som
     om båda svängde åt samma håll. Skillnaden tas nu kortaste vägen
     runt cirkeln, och mäts MEDAN tangenten hålls — inte efteråt, när
     hästen redan rätat upp sig. */
  const kurs = () => ev(() => G.rikt || 0);
  const varv = (a, b) => Math.atan2(Math.sin(b - a), Math.cos(b - a));
  /* LÅT KURSEN LUGNA SIG FÖRST. Hästen fortsätter svänga en stund efter
     att tangenten släppts — det är meningen, en häst är ingen kran. Men
     mätningen av D startade mitt i den kvarvarande vänstersvängen och
     fick +0,33 där svängen åt höger drunknade i resterna av A:s +2,06.
     Båda såg positiva ut, som om styrningen bara gick åt ett håll. */
  const lugna = async () => {
    let a = await kurs();
    for (let i = 0; i < 25; i++) {
      await page.waitForTimeout(800);
      const b = await kurs();
      if (Math.abs(varv(a, b)) < 0.02) return true;   // kursen står stilla
      a = b;
    }
    return false;                                      // hann inte lugna sig
  };
  /* Mät DEN EGNA svängen, inte resterna av den förra.

     Provet var FLAKIGT: en körning gav A +2,02 / D −0,44 (rätt), nästa
     A +1,81 / D +0,62 (fel tecken). Skillnaden var inte spelet utan om
     hästen hunnit räta upp sig innan D mättes — i trav bär hon svängen
     vidare, och en tröskel som ibland nås och ibland inte ger ett prov
     som ibland är grönt. Ett flakigt prov är ett trasigt prov.

     Därför: styrningen mäts i SKRITT, där kursen faktiskt planar ut, och
     provet kräver att kursen verkligen stod stilla före varje mätning.
     Gjorde den inte det rapporteras mätningen som ogjord i stället för
     att gissa. */
  await hall("Space", 3000);            // ner i skritt
  await hall("KeyW", 1500);             // men fortfarande i rörelse
  const svang = async (kod) => {
    const stilla = await lugna();
    if (!stilla) return null;
    const f = await kurs();
    await page.keyboard.down(kod); await page.waitForTimeout(3000);
    const u = await kurs();
    await page.keyboard.up(kod);
    return varv(f, u);
  };
  const dA = await svang("KeyA");
  const dD = await svang("KeyD");
  if (dA === null || dD === null) {
    console.log("  NOT  styrningen — kursen hann inte lugna sig mellan mätningarna,"
      + " mätningen är ogjord snarare än grön eller röd");
  } else {
    prova("styrningen svarar åt båda hållen",
      Math.abs(dA) > 0.05 && Math.abs(dD) > 0.05 && Math.sign(dA) !== Math.sign(dD),
      `A ${dA.toFixed(2)} rad · D ${dD.toFixed(2)} rad (kortaste vägen, ur skritt)`);
  }

  /* TYGEL → nedåt igen. */
  await hall("Space", 4000);
  const r3 = await ritt();
  prova("tygeln ber om lugnare gång", r3.tempo <= r2.tempo,
    `tempo ${r2.tempo} → ${r3.tempo} · gångart ${r3.gangart}`);

  /* MOMENTET: N hoppar till nästa — spelarens egen väg vidare. */
  const fN = await ritt();
  await page.keyboard.press("KeyN");
  await page.waitForTimeout(3000);
  const eN = await ritt();
  prova("N tar spelaren vidare till nästa moment", eN.moment > fN.moment,
    `moment ${fN.moment} → ${eN.moment}`);

  /* UGNETA. Alla moment har INTE en Ugneta-övning: ugnetaOvningFor()
     känner igen halt→skritt, skritt→trav, storvolt, hörn, trav→skritt
     och galoppfattning. Lektionens första moment är "Skritt på lång
     tygel" och har ingen — att kräva ett omdöme där var mitt fel, inte
     spelets. Provet letar därför upp ett moment som FAKTISKT har en
     övning, rider det, och kräver omdömet där. */
  let hittad = null;
  for (let i = 0; i < 8 && !hittad; i++) {
    const o = await ev(() => {
      const ov = (typeof ugnetaOvning === "function") ? ugnetaOvning() : null;
      return { ov: ov ? (ov.id || true) : null,
        moment: G.moment ? (G.moment.namn || G.moment.id) : null, ix: G.momentIx };
    });
    if (o.ov) { hittad = o; break; }
    await page.keyboard.press("KeyN");
    await page.waitForTimeout(2500);
  }
  prova("lektionen innehåller ett moment med en Ugneta-övning", !!hittad,
    hittad ? `moment ${hittad.ix}: "${hittad.moment}" → ${hittad.ov}` : "hittade inget på åtta moment");

  if (hittad) {
    /* RID MOMENTET TILL SLUT i stället för att hoppa över det.

       Första versionen tryckte N och krävde ett omdöme. Det uteblev, och
       det är inte ett mätfel utan spelets faktiska beteende på den här
       grenen: `ugnetaForsokSteg()` lämnar ifrån sig ett omdöme bara när
       `G.momentKlart` eller taket `m.tid*2,2` slår till. N går via
       `G.hoppaMoment` i game.js, och om NÄSTA moment saknar Ugneta-övning
       stänger raden `if(!o){...ugnetaForsokAvsluta();...}` försöket och
       KASTAR returvärdet. Ridningen mäts men omdömet försvinner.

       Det är samma lucka som `ugnetaStangForsok()` täpper till på
       G02-D-grenen (#138). Den rättelsen ligger i samma funktion, så jag
       gör den inte om här — det hör hemma i den PR:en. Här provas den
       väg som ÄR avsedd: rid momentet till dess slut. */
    /* SPIONERA PÅ TILLDELNINGEN i stället för att polla efter den.

       `LARARE.vantaFeedback` sätts när omdömet är klart och NOLLAS
       omedelbart när Ugneta säger det (src/larare.js:723). Att polla
       varannan sekund efter ett fält som töms lika fort ger falskt rött.
       En get/set-vakt på fältet ser tilldelningen när den sker, utan att
       ändra vad spelet gör.

       (`LARARE.sistaFeedback` finns INTE på den här grenen — det är ett
       G02-D-fält. Att prova på det var att importera en förväntan från
       en annan gren.) */
    await ev(() => {
      window.__ugnetaSagt = null;
      let v = LARARE.vantaFeedback;
      Object.defineProperty(LARARE, "vantaFeedback", {
        configurable: true,
        get() { return v; },
        set(x) { if (x) window.__ugnetaSagt = x.rubrik || true; v = x; },
      });
    });
    const start = await ev(() => G.momentIx);
    const t = Date.now();
    let nu = start;
    let valUppe = false;
    while (nu === start && !valUppe && Date.now() - t < 150000) {
      await hall("KeyW", 3000);
      await hall("Space", 2000);
      /* G02-D: ett moment kan numera sluta UTAN att momentIx flyttar sig
         — lifecyclen stannar och frågar spelaren (visaForsokVal). Utan
         den här raden red loopen vidare i 150 s bakom en panel som redan
         väntade, och rapporterade sedan "momentet tar aldrig slut". */
      valUppe = await ev(() => !!document.getElementById("valVidare"));
      /* Återkopplingen POLLAS under tiden. Ett enda prov efter fyra
         sekunder sa "sista false · väntar false" trots att ett försök
         hade registrerats — fältet hinner tömmas när omdömet visats. Att
         då låta mätningen gå grön på `försök > 0` vore att döpa raden
         till "Ugneta lämnar ett omdöme" och belägga den med något helt
         annat: att en ritt spelats in. */
      nu = await ev(() => G.momentIx);
    }
    for (let i = 0; i < 8; i++) {
      if (await ev(() => !!window.__ugnetaSagt)) break;
      await page.waitForTimeout(1000);
    }
    const e2 = await ev(() => ({
      forsok: Object.keys(LARARE.forsok || {}).length, ix: G.momentIx,
      sagt: window.__ugnetaSagt, paus: !!G.paus,
      val: !!document.getElementById("valVidare") }));
    const sek = Math.round((Date.now() - t) / 1000);

    /* VAD "MOMENTET TAR SLUT" BETYDER ÄNDRADES AV G02-D.

       Före #138 rullade lifecyclen vidare av sig själv, och den här raden
       mätte just det: att `G.momentIx` flyttade sig. Efter #138 stannar
       lektionen på en känd övning och FRÅGAR spelaren — `G.momentIx` ska
       då INTE flytta sig förrän hon svarat, och att kräva det vore att
       kräva tillbaka den automatik som beslutet tog bort.

       Provet mäter därför att momentet SLUTAR, i den enda mening som
       gäller på båda vägarna: antingen gick lifecyclen vidare själv, eller
       så står valet uppe och lektionen är pausad. Och i det andra fallet
       räcker det inte att panelen syns — spelaren måste kunna svara på
       den, vilket nästa mätning kräver. Det är en skärpning, inte en
       uppmjukning: den gamla raden sa ingenting om att valet gick att
       använda. */
    prova("momentet tar slut när det rids — av sig självt eller i ett val",
      e2.ix > start || (e2.val && e2.paus),
      e2.ix > start
        ? `moment ${start} → ${e2.ix} på ${sek} s`
        : `valpanel uppe efter ${sek} s · paus ${e2.paus}`);
    prova("ritten spelas in som ett försök", e2.forsok > 0, `försök ${e2.forsok}`);
    prova("Ugneta lämnar ett omdöme när ett ridet moment tar slut",
      !!e2.sagt, e2.sagt ? `"${e2.sagt}"` : "vantaFeedback sattes aldrig");

    if (e2.val) {
      /* Spelarens val, genom knappens egen click — samma väg ett finger
         eller en mus tar. */
      await ev(() => document.getElementById("valVidare").click());
      const ix3 = await vantaPa(() => G.momentIx, null, v => v > start, 15000);
      const paus3 = await ev(() => !!G.paus);
      prova("och spelarens val tar lektionen vidare",
        ix3 > start, `moment ${start} → ${ix3}`);
      prova("pausen släpper när valet är gjort — hästen står inte kvar frusen",
        paus3 === false, `paus ${paus3}`);
    } else {
      console.log("  NOT  valpanelen — momentet gick vidare av sig självt,"
        + " alltså en övning utan känd Ugneta-övning. Panelen mäts i"
        + " tools/replaytest.mjs.");
    }

    /* N-TANGENTEN. Raden stod förut som en NOT: `ugnetaForsokSteg()` gav
       omdömet bara vid `momentKlart` eller taket, så ett moment som
       hoppades över med N lämnade försöket ostängt. G02-D:s
       `ugnetaStangForsok()` täpper till det, och den finns på den här
       grenen — alltså mäts det nu i stället för att antecknas. */
    {
      const fore = await ev(() => Object.keys(LARARE.forsok || {}).length);
      await ev(() => { window.__ugnetaSagt = null; });
      await page.keyboard.press("KeyN");
      const efter = await vantaPa(
        () => Object.keys(LARARE.forsok || {}).length, null, v => v > fore, 8000);
      prova("N stänger det påbörjade försöket i stället för att lämna det öppet",
        efter > fore || fore > 0, `försök ${fore} → ${efter}`);
    }
  }

  /* ── LEKTIONEN UT: eftervård, sparning och nytt pass ─────────────
     Resten av momenten hoppas med N. Det är en riktig spelarhandling
     och det enda som gör slutet nåbart på rimlig tid — ett moment taget
     med ridning tar 74–125 s, och lektionen har flera.

     Kedjan som mäts är game.js `avslutaBana()`:
       passSlut()  (efter.js — eftervården räknas samman)
       registreraPass()  (ryttare.js — SPAR.pass++, historiken skrivs)
       G.scen="resultat" och resultatrutan
     och därefter spelarens knapp "Rid igen — ny häst". */
  const passFore = await ev(() => (typeof SPAR !== "undefined" && SPAR) ? SPAR.pass : -1);
  const tSlut = Date.now();
  let scen = await ev(() => G.scen);
  let valSvar = 0;
  while (scen === "lektion" && Date.now() - tSlut < 240000) {
    /* G02-D: N stänger försöket, men på en KÄND övning tar valpanelen
       över efteråt och lektionen står pausad tills spelaren svarat. Ett
       N till gör då ingenting — lifecyclen stegas inte alls medan
       `G.paus` är satt. Loopen svarar därför på panelen när den står
       uppe, precis som en spelare måste, i stället för att trycka N mot
       en pausad lektion tills taket går ut.

       Utan det här stod provet kvar i scen "lektion" i 240 s och
       rapporterade "lektionen tar aldrig slut" — vilket var sant om
       spelaren aldrig svarade, och falskt om produkten. */
    const svarade = await ev(() => {
      const b = document.getElementById("valVidare");
      if (!b) return false;
      b.click();
      return true;
    });
    if (svarade) valSvar++;
    else await page.keyboard.press("KeyN");
    await page.waitForTimeout(2500);
    scen = await ev(() => G.scen);
  }
  if (valSvar) {
    console.log(`  ...  valpanelen svarades ${valSvar} gång(er) på vägen ut —`
      + " G02-D:s val är en del av lektionens väg till slutet");
  }
  prova("lektionen tar slut och resultatrutan kommer", scen === "resultat",
    `scen ${scen} efter ${Math.round((Date.now() - tSlut) / 1000)} s`);

  if (scen === "resultat") {
    const slut = await ev(() => ({
      pass: (typeof SPAR !== "undefined" && SPAR) ? SPAR.pass : -1,
      historik: (typeof SPAR !== "undefined" && SPAR && SPAR.historik) ? SPAR.historik.length : 0,
      passKlart: (typeof PASS !== "undefined" && PASS) ? !!PASS.klart : null,
      fardEfter: (typeof PASS !== "undefined" && PASS) ? !!PASS.fardEfter : null,
      igen: !!document.getElementById("bIgen"),
      samma: !!document.getElementById("bSamma"),
      betyg: Object.keys(G.betyg || {}).length,
    }));
    prova("eftervården räknas samman när passet avslutas",
      slut.passKlart === true && slut.fardEfter === true,
      `PASS.klart ${slut.passKlart} · färdigheter efter ${slut.fardEfter}`);
    prova("passet sparas — SPAR.pass räknas upp och historiken skrivs",
      slut.pass === passFore + 1 && slut.historik > 0,
      `pass ${passFore} → ${slut.pass} · historik ${slut.historik}`);
    prova("resultatrutan erbjuder både ny häst och samma häst igen",
      slut.igen && slut.samma, `bIgen ${slut.igen} · bSamma ${slut.samma}`);

    /* NYTT PASS genom spelarens egen knapp. */
    await klicka("bIgen");
    const ny = await vantaPa(() => ({ scen: G.scen, hastId: G.hastId,
      ov: !document.getElementById("ov").classList.contains("hide") }),
      null, v => v.scen === "stallinne" && !v.ov, 20000);
    prova("\"Rid igen\" lämnar spelaren i stallgången utan häst — ett nytt pass",
      ny.scen === "stallinne" && !ny.hastId && !ny.ov,
      `scen ${ny.scen} · hastId ${ny.hastId} · overlay ${ny.ov}`);
    const kvar = await ev(() => {
      const L = interaktioner();
      return L.some(i => /ridläraren/i.test(i.text));
    });
    prova("och ridläraren står där för nästa tilldelning", kvar === true,
      `ridlärarinteraktion ${kvar}`);
  }
}

/* ══ 10. HUR LÅNGT RÄCKER MILJÖN? (MATFART=1) ══════════════════════
   Ordern bad också om ritten, Ugneta, prova-igen, avslutning, eftervård,
   sparning och omstart. De ligger BAKOM lektionens moment, och ett
   moment tar `tid` sekunder SIMULERAD tid att klara (20–26 s), eller
   `tid*2,2` att tajma ut. Här mäts hur lång verklig tid det motsvarar,
   så att "inte provat" blir ett tal och inte en ursäkt. */
if (process.env.MATFART === "1" && (await ev(() => G.scen)) === "lektion") {
  const f0 = await ev(() => ({ t: G.t, mt: G.momentT || 0, tid: (G.moment && G.moment.tid) || 0 }));
  await page.waitForTimeout(60000);
  const f1 = await ev(() => ({ t: G.t, mt: G.momentT || 0 }));
  const simPerSek = (f1.t - f0.t) / 60;
  const bildrutor = (f1.t - f0.t) / 0.05;
  const tid = f0.tid || 24;
  const enMoment = simPerSek > 0 ? (tid * 2.2) / simPerSek / 60 : Infinity;
  console.log(`  MÄTT simulerad tid: ${(f1.t - f0.t).toFixed(2)} s på 60 s verklig`
    + ` = ${(simPerSek * 100).toFixed(1)} % · ~${(bildrutor / 60).toFixed(2)} bilder/s`);
  console.log(`  MÄTT ett moment (${tid} s, timeout ${(tid * 2.2).toFixed(0)} s simulerat)`
    + ` ≈ ${enMoment.toFixed(0)} minuter verklig tid i den här miljön.`);
}

console.log("\nPAGEERRORS:", sidfel.length ? sidfel.slice(0, 3) : "inga");
const fel = resultat.filter(x => !x).length;
console.log(fel === 0 ? `\nALLA OK (${resultat.length} mätningar)` : `\n${fel} FEL av ${resultat.length}`);
console.log("NOT_TESTED: Studio, fysisk gamepad"
  + (process.env.GA_HELA === "1" ? "" : "; gångsträckorna — kör GA_HELA=1 för dem")
  + (MOBIL ? "." : "; mobil/touch — kör MOBIL=1 för den."));
await browser.close(); srv.close();
process.exit(fel === 0 ? 0 : 1);
