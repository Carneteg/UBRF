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
 * ── VARFÖR PROVET INTE GÅR STRÄCKORNA ──────────────────────────────
 * Mätt i den här miljön: 0,1 fps i 3D-vyn, 0,5 fps i 2D. Spelloopen
 * klampar dt till 0,05 s per bildruta, så simulerad tid går med 1–3 % av
 * verklig tid. En figur som går 1,8 m/s kommer 0,03 m på tre sekunder,
 * och gårdsplanens sjutton meter tar över nittio sekunder. Att gå hela
 * anläggningen skulle ta timmar per körning.
 *
 * Därför placeras spelaren vid varje station med `gaTill` — spelets egen
 * placering, samma funktion dörrarna använder — och allt DÄREFTER är
 * spelets: `interagera()` avgör själv vad som är inom räckhåll (2,4 m),
 * skriver sin egen prompt, och E trycks på riktigt.
 *
 * SJÄLVA GÅENDET ÄR ALLTSÅ NOT_TESTED HÄR. Det står i rapporten, inte
 * gömt som grönt. Ett steg är dock provat på riktigt: gården →
 * stalldörren med tangenter tog 95 s och gav "Tryck E — Gå in i
 * stallet", så gåendet i sig fungerar — det är bara ohyggligt långsamt
 * i mjukvarurendering.
 *
 * ── VÄNTA PÅ BILDRUTOR, INTE PÅ MILLISEKUNDER ──────────────────────
 * Vid 0,5 fps är en paus på 700 ms ofta KORTARE ÄN EN BILDRUTA. Alla
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
async function stallDigVid(re, maxMs = 90000) {
  const mal = await ev(m => {
    const L = interaktioner().filter(i => new RegExp(m, "i").test(i.text));
    if (!L.length) return null;
    L.sort((a, b) => Math.hypot(VD.px - a.pos[0], VD.py - a.pos[1])
                   - Math.hypot(VD.px - b.pos[0], VD.py - b.pos[1]));
    return { text: L[0].text, pos: L[0].pos };
  }, re);
  if (!mal) return { mal: null, framme: false, prompt: null };

  await ev(({ mx, my }) => {
    if (G.vy !== "2d" && typeof vaxlaVy === "function") vaxlaVy();
    const dx = VD.px - mx, dy = VD.py - my, d = Math.hypot(dx, dy);
    if (d > 3.2) { const k = 3 / d; gaTill(G.scen, { x: mx + dx * k, y: my + dy * k, rikt: 0 }); }
  }, { mx: mal.pos[0], my: mal.pos[1] });
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
    avst: +Math.hypot(p.x - mx, p.y - my).toFixed(2) };
}

/* E — hållen tillräckligt länge för att en bildruta säkert ska se
   flanken, och sedan POLLAD tills verkan syns. En fast paus på 2,5 s är
   ungefär EN bildruta vid 0,5 fps; det räckte ibland och ibland inte,
   vilket såg ut som ett ostabilt spel men var en ostabil mätning. */
async function tryckE(klar) {
  if (MOBIL) {
    /* Pekknappen ANVÄND skickar samma KeyE genom spelets eget
       inputlager. Hålls nere lika länge, av samma bildruteskäl. */
    /* FINGRET LIGGER KVAR på knappen, precis som på tangenten.

       `data-tap` i src/mobil.js skickar keydown på pointerdown och
       keyup först 60 ms efter pointerup. En blixtsnabb tap() håller
       alltså tangenten nere i ~60 ms — på en riktig telefon i 60 fps är
       det fyra bildrutor, men här (0,5 fps) är sannolikheten att spelet
       råkar läsa just då omkring tre procent. Ett tryck missade, två
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
    g.mal ? `"${g.dom || g.prompt || "INGEN PROMPT"}" · ${g.avst} m` : "INGEN sådan interaktion");
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
console.log("NOT_TESTED: gångsträckorna mellan stationerna (se filhuvudet), Studio, fysisk gamepad"
  + (MOBIL ? "." : ", mobil/touch — kör MOBIL=1 för den."));
await browser.close(); srv.close();
process.exit(fel === 0 ? 0 : 1);
