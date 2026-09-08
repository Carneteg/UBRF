#!/usr/bin/env node
/* LÅSTA LÄGEN — vad spelaren SER när hon inte kan sitta upp
 *
 * P0-stoppet på #135 lyder: Tobias kunde inte sitta upp, och "ingen
 * E-interaktion visades". tools/forstadagentest.mjs visar att den
 * normala kedjan går hela vägen till sadeln. Det som återstår att mäta
 * är alltså inte den lyckade vägen utan de LÅSTA lägena: när spelaren
 * står vid sargporten UTAN att villkoren är uppfyllda.
 *
 * Kravet som provas här är inte "det ska gå att sitta upp". Det är:
 *
 *   1. Prompten får aldrig vara tyst. Står spelaren vid sargporten ska
 *      det ALLTID stå något — även när uppsittningen är låst. En tom
 *      ruta är samma upplevelse som ett trasigt spel.
 *   2. Uppgiftspanelen får aldrig motsäga sargporten. Säger panelen
 *      "Sitt upp" måste sargporten erbjuda uppsittning. Annars letar
 *      spelaren efter en knapp som spelet självt har stängt.
 *   3. Trasiga data får inte tysta HELA interaktionslistan.
 *      `interaktioner()` körs varje bildruta inifrån `stegaVandring()`,
 *      och den anropas inte i någon try/catch. Kastar den, dör
 *      bildrutan innan `requestAnimationFrame` hinner köas igen — och
 *      då stannar spelet helt, inte bara en prompt.
 *   4. Två tryck ska inte ge två uppsittningar.
 *
 * ── VARFÖR DET HÄR PROVET SÄTTER TILLSTÅND FÖR HAND ────────────────
 * forstadagentest.mjs får uttryckligen INTE sätta G.hastPlats,
 * G.skotselRes eller G.scen — det provet ska bevisa att spelaren kan
 * ta sig fram på egen hand. Det här provet har motsatt uppgift: det ska
 * ställa spelet i lägen som spelaren kan HAMNA i och mäta vad hon då
 * ser. Tillstånden sätts därför direkt, och varje sådant läge redovisas
 * med om det är nåbart i normalt spel eller bara en robusthetsvakt.
 *
 * Kör: python3 tools/build.py && node tools/lastlagetest.mjs
 */
import { chromium } from "playwright";
import http from "node:http"; import fs from "node:fs"; import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, process.env.ROT_SERVE || "dist");
const START = process.env.ROT_SERVE ? "/index.html" : "/ridskolan.html";
const PORT = +(process.env.PORT || 8874);
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
const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
const sidfel = [];
page.on("pageerror", e => sidfel.push(e.message));
await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
await page.waitForTimeout(1500);
const ev = (f, a) => page.evaluate(f, a);

const resultat = [];
const prova = (namn, ok, detalj) => { resultat.push(ok);
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj); };

async function vantaPa(fn, arg, ok, maxMs = 15000) {
  const t0 = Date.now(); let v = await ev(fn, arg);
  while (!ok(v) && Date.now() - t0 < maxMs) { await page.waitForTimeout(500); v = await ev(fn, arg); }
  return v;
}
const klicka = async (id) => {
  const finns = await vantaPa(i => !!document.getElementById(i), id, v => v === true, 8000);
  if (!finns) return false;
  await page.click("#" + id); await page.waitForTimeout(700); return true;
};

/* ── Ett FÄRSKT spel före varje läge ───────────────────────────────
   Första rundan av det här provet mätte fel på grund av sig självt: när
   läget med okänd häst dödade spelloopen (se nedan) stod alla följande
   mätningar kvar på ett fruset spel, och rapporterade "E gör ingenting"
   och "tom prompt" som om det vore produktfel. Det var det inte — det
   var mitt eget prov som mätte vidare på en död sida.

   Varje läge startar därför om sidan och går igenom gästvägen på nytt. */
async function starta() {
  /* about:blank först: den gamla sidan ligger annars kvar i sin
     requestAnimationFrame-slinga under mjukvarurendering, och en
     omladdning rakt ovanpå den nådde inte "load" inom trettio sekunder.
     Det var provets navigering som stannade, inte spelet. */
  await page.goto("about:blank", { waitUntil: "load" });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load", timeout: 90000 });
  await page.waitForTimeout(1200);
  await klicka("bSkapHoppa");
  await klicka("bStart");
  return vantaPa(() => ({ scen: G.scen, ov: !document.getElementById("ov").classList.contains("hide") }),
    null, v => v.scen === "gard" && !v.ov, 15000);
}

/* ── Ställ spelet i ett läge och gå till sargporten ────────────────
   Placeringen sker med spelets egen `gaTill`, en meter innanför
   sargportens interaktionspunkt — inte i en fasad, och inte närmare än
   `interagera()`s egen räckvidd på 2,4 m kräver. */
async function stallIn(lage) {
  await starta();
  await ev(l => {
    G.hastId = l.hastId === undefined ? G.hastId : l.hastId;
    if (l.hastPlats !== undefined) G.hastPlats = l.hastPlats;
    if (l.skotsel !== undefined) G.skotselRes = l.skotsel ? { dagsform: 0.6, sadellage: 0.6, risker: [], omdome: "prov" } : null;
    if (l.utrustning !== undefined) G.utrustning = l.utrustning;
    if (l.hastMott !== undefined) G.hastMott = l.hastMott;
    const sp = SPELABSTRAKTIONER.ridhus.sargport, R = RIDHUSINNE;
    gaTill("ridhusinne", { x: (sp.x0 + sp.x1) / 2, y: R.bana.y + R.bana.h + 1.0, rikt: -Math.PI / 2 });
  }, lage);
  /* Vänta tills spelet räknat om sin prompt minst en gång.

     Inte på en fast paus: 2,5 s är noll till en bildruta här, och en
     mätning som läste #approach direkt efteråt rapporterade "TOM" i en
     körning och rätt text i nästa. Det var provets klocka som var för
     snabb, inte spelet som tappade prompten. Spelaren står en meter
     från sargporten, och sargporten finns i ALLA lägen — så
     `VD.prompt` ska bli satt, och det är den händelsen vi väntar på. */
  await vantaPa(() => G.scen, null, v => v === "ridhusinne", 10000);
  await vantaPa(() => VD.prompt !== null, null, v => v === true, 30000);
  return ev(() => {
    let kastade = null, sarg = null;
    try {
      const L = interaktioner();
      const sp = SPELABSTRAKTIONER.ridhus.sargport, px = (sp.x0 + sp.x1) / 2;
      const i = L.find(x => Math.abs(x.pos[0] - px) < 0.6
        && Math.abs(x.pos[1] - (RIDHUSINNE.bana.y + RIDHUSINNE.bana.h)) < 0.6);
      sarg = i ? i.text : null;
    } catch (e) { kastade = String(e && e.message || e); }
    let mal = null;
    try { const u = (typeof uppdragText === "function") ? uppdragText() : null; mal = u ? u.rubrik : null; }
    catch (e) { mal = "KASTADE: " + String(e && e.message || e); }
    return { kastade, sarg, mal, scen: G.scen,
      prompt: VD.prompt ? VD.prompt.text : null,
      dom: ((document.getElementById("approach") || {}).textContent || "").trim(),
      t: G.t };
  });
}

/* Lever spelloopen fortfarande? En kastad `interaktioner()` tar med sig
   hela bildrutan, och då köas aldrig nästa requestAnimationFrame.

   TRE prov, inte två: `G.t` räknas upp HÖGST UPP i loopen, före
   `stegaVandring()`. En bildruta som kastar hinner alltså öka klockan
   innan den dör, och ett prov på "b > a" blev grönt på en död loop —
   G.t 3,08 → 3,13, exakt ett dt. Kravet är att klockan går VIDARE,
   alltså två steg i rad. Fönstren är tilltagna: gå-scenen
   går i ~5 bilder/s på en tyst maskin, långsammare under last. */
async function loopenLever() {
  const a = await ev(() => G.t);
  await page.waitForTimeout(7000);
  const b = await ev(() => G.t);
  await page.waitForTimeout(7000);
  const c = await ev(() => G.t);
  return { lever: b > a && c > b, a: +a.toFixed(2), b: +b.toFixed(2), c: +c.toFixed(2) };
}

async function tryckE() {
  await page.keyboard.down("KeyE"); await page.waitForTimeout(4000);
  await page.keyboard.up("KeyE"); await page.waitForTimeout(2000);
}

console.log("\n── LÅSTA LÄGEN VID SARGPORTEN ──");

/* ══ 1. INGEN HÄST ═════════════════════════════════════════════════
   Nåbart: ja — spelaren kan gå raka vägen in i ridhuset utan att ha
   pratat med ridläraren. */
let r = await stallIn({ hastId: null, hastPlats: "box", skotsel: false, utrustning: false, hastMott: false });
prova("utan häst: sargporten säger ändå något", !!r.sarg, `"${r.sarg}" · uppgift: "${r.mal}"`);
prova("utan häst: uppgiften pekar inte på uppsittning",
  !/sitt upp/i.test(r.mal || ""), `uppgift: "${r.mal}"`);
prova("utan häst: interaktionslistan kastar inte", r.kastade === null, r.kastade || "inget kast");

/* ══ 2. HÄST I BOXEN, INGEN SKÖTSEL ════════════════════════════════
   Nåbart: ja — direkt efter tilldelningen. */
r = await stallIn({ hastId: "blackrock_jack", hastPlats: "box", skotsel: false, utrustning: false, hastMott: true });
prova("häst i boxen: sargporten säger ändå något", !!r.sarg, `"${r.sarg}" · uppgift: "${r.mal}"`);
prova("häst i boxen: uppgiften pekar inte på uppsittning",
  !/sitt upp/i.test(r.mal || ""), `uppgift: "${r.mal}"`);

/* ══ 3. SKÖTT MEN INTE UTLEDD ══════════════════════════════════════
   DET HÄR ÄR DET LÄGE SOM MOTSVARAR SYMPTOMET: uppgiftspanelen säger
   "Sitt upp", men hästen står kvar i boxen, och sargporten kan då inte
   erbjuda uppsittning. Nåbart i dagens kod: inte funnet — boxmenyns
   resultatruta har bara knappen "Led ut till lektionen" och ingen väg
   förbi den. Provet står kvar som vakt: skulle en väg förbi den
   knappen någonsin uppstå är det den här raden som blir röd, inte en
   spelare som står vid en tyst port. */
r = await stallIn({ hastId: "blackrock_jack", hastPlats: "box", skotsel: true, utrustning: true, hastMott: true });
prova("skött men i boxen: sargporten säger ändå något", !!r.sarg, `"${r.sarg}"`);
/* NOTERAT, inte provat som fel. `uppdragMal()` går till "Sitt upp" så
   snart G.skotselRes finns, utan att läsa G.hastPlats — så i det här
   läget säger panelen "Sitt upp" medan sargporten bara säger
   "Sargporten". Det ÄR symptomets form, men läget är inte nåbart i
   dagens kod: boxmenyns resultatruta har bara knappen "Led ut till
   lektionen", och det finns varken Escape-hanterare eller klick-utanför
   som tar spelaren förbi den.
   Att härda uppgiftspanelen för ett onåbart läge vore att bygga
   vägledning mot en box som inte längre har någon interaktion — ett
   produktbeslut, inte en P0-rättelse. Raden skrivs ut så att fyndet
   inte försvinner, och avgörandet ligger hos review. */
console.log("  NOT  uppgiftspanelen läser inte G.hastPlats —",
  `uppgift "${r.mal}" mot sargport "${r.sarg}" (läget inte nåbart i dag)`);

/* ══ 4. TRASIGA DATA — okänd häst ══════════════════════════════════
   Nåbart i normalt spel: nej. `G.hastId` sätts bara ur HORSES av
   tilldelningen och sparas inte mellan pass. Det här är en
   robusthetsvakt: `interaktioner()` läser `HORSES[G.hastId].namn` utan
   vakt på flera ställen, och kastet skulle inte ge "ingen prompt" utan
   ett spel som slutar rita. */
r = await stallIn({ hastId: "hast_som_inte_finns", hastPlats: "leds", skotsel: true, utrustning: true });
prova("okänd häst: interaktionslistan kastar inte", r.kastade === null, r.kastade || "inget kast");
let l = await loopenLever();
prova("okänd häst: spelloopen lever vidare", l.lever, `G.t ${l.a} → ${l.b}`);

/* ══ 5. NORMALLÄGET — och två tryck ════════════════════════════════ */
r = await stallIn({ hastId: "blackrock_jack", hastPlats: "leds", skotsel: true, utrustning: true, hastMott: true });
prova("med hästen vid handen: sargporten erbjuder uppsittning",
  /sitt upp/i.test(r.sarg || ""), `"${r.sarg}"`);
prova("och uppgiften säger samma sak", /sitt upp/i.test(r.mal || ""), `uppgift: "${r.mal}"`);
prova("spelets egen DOM-prompt står också där",
  /sitt upp/i.test(r.dom || ""), `"${r.dom || "TOM"}"`);

/* Uppsittningen och dubbeltrycket provas INTE här. Ett försök gjordes,
   och det mätte fel: ett läge satt för hand har inget `G.ride` — den
   byggs av skötseln — så sittUpp() startade lektionen och sprack sedan
   på `null.gangart`. Det säger något om mitt konstruerade tillstånd,
   inte om spelet. Uppsittningen och det andra trycket hör hemma där
   tillståndet är på riktigt: tools/forstadagentest.mjs. */

/* ══ 6. FEL HÄST ═══════════════════════════════════════════════════
   Ordern bad om "fel häst" som negativprov. Två frågor: kan spelaren ta
   någon annans utrustning, och vad händer vid en box som inte är hennes?

   Sadelkammaren öppnas genom `visaSadelkammare()` — samma anrop som
   interaktionens `gor()` gör. Det som provas är vad panelen SVARAR, inte
   hur man kom in i den.

   GRANNEN HÄMTAS UR PANELEN, inte ur HORSES. Sadelkammaren visar åtta
   byglar runt din egen häst, inte hela stallet; ett godtyckligt annat
   häst-id ("air") fanns inte på väggen och provet letade efter en knapp
   som aldrig ritats. Det såg ut som att fel utrustning inte gick att
   välja — men ingen hade valt något alls. */
r = await stallIn({ hastId: "blackrock_jack", hastPlats: "box", skotsel: false,
  utrustning: false, hastMott: true });

await ev(() => visaSadelkammare());
await page.waitForTimeout(800);
const val = await ev(() => {
  const knappar = [...document.querySelectorAll('.sk-val[data-typ="sadel"]')]
    .filter(b => b.dataset.id !== G.hastId);
  if (!knappar.length) return null;
  const id = knappar[0].dataset.id;
  const t = document.querySelector(`.sk-val[data-typ="trans"][data-id="${id}"]`);
  if (!t) return null;
  knappar[0].click(); t.click();
  return { id, namn: (HORSES[id] || {}).namn || id };
});
prova("sadelkammaren visar grannarnas byglar, inte bara din egen",
  !!val, val ? `granne ${val.namn}` : "ingen grannbygel ritad");
if (val) {
  await klicka("bSkKlar");
  const e = await ev(() => ({ utr: !!G.utrustning,
    not: ((document.getElementById("skStatus") || {}).className || ""),
    text: ((document.getElementById("skStatus") || {}).textContent || "").trim().slice(0, 90) }));
  prova("fel hästs sadel och träns ger INGEN utrustning", e.utr === false, `utrustning ${e.utr}`);
  prova("och spelaren får veta varför", /bad/.test(e.not), `"${e.text}"`);
}
await ev(() => overlay(false));
await page.waitForTimeout(400);

/* Boxarna ligger i STALLET. Första försöket frågade efter dem medan
   spelaren stod i ridhuset, där `interaktioner()` bygger ridhusets lista
   och inga boxar finns — "den egna boxen har en interaktion: null" sade
   alltså bara att jag mätte i fel byggnad. */
const boxar = await ev(() => {
  const S = STALLINNE;
  gaTill("stallinne", { x: S.ridlarare.pos[0], y: S.ridlarare.pos[1], rikt: 0 });
  const min = hittaBox(G.hastId);
  let kast = null, vidAnnan = null, vidMin = null;
  try {
    const L = interaktioner();
    const nara = (p) => L.find(i => Math.hypot(i.pos[0] - p[0], i.pos[1] - p[1]) < 0.6);
    vidMin = min ? ((nara(min.dorr) || {}).text || null) : "INGEN EGEN BOX";
    const andra = Object.keys(HORSES).map(id => hittaBox(id))
      .filter(b => b && (!min || b.dorr[0] !== min.dorr[0] || b.dorr[1] !== min.dorr[1]));
    vidAnnan = andra.length ? ((nara(andra[0].dorr) || {}).text || null) : "INGEN ANNAN BOX";
  } catch (e) { kast = String(e && e.message || e); }
  const u = (typeof uppdragMal === "function") ? uppdragMal() : null;
  return { kast, vidMin, vidAnnan, malVar: u && u.mal ? u.mal.var : null,
    malId: u ? u.id : null };
});
prova("i stallet har den egna boxen en interaktion",
  !!boxar.vidMin && boxar.vidMin !== "INGEN EGEN BOX", `"${boxar.vidMin}"`);
prova("en annan hästs box har ingen — den är inte spelarens att öppna",
  boxar.vidAnnan === null || boxar.vidAnnan === "INGEN ANNAN BOX", `"${boxar.vidAnnan}"`);
/* Utrustningen är fortfarande inte hämtad — då SKA vägvisaren peka på
   sadelkammaren, inte på boxen. Provet kräver rätt mål, inte bara att
   något mål finns: "finns ett mål" var grönt oavsett vad det pekade på. */
prova("och vägvisaren pekar på nästa riktiga steg — sadelkammaren",
  boxar.malId === "utrustning", `mål ${boxar.malId} · "${boxar.malVar}"`);

console.log("\nPAGEERRORS:", sidfel.length ? sidfel.slice(0, 3) : "inga");
const fel = resultat.filter(x => !x).length;
console.log(fel === 0 ? `\nALLA OK (${resultat.length} mätningar)` : `\n${fel} FEL av ${resultat.length}`);
console.log("NOT_TESTED: avsittning efter lektionen, eftervård och nytt pass — de kräver hela ritten"
  + " och ligger i nästa steg. Studio och fysisk gamepad som alltid.");
await browser.close(); srv.close();
process.exit(fel === 0 ? 0 : 1);
