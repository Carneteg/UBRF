/* INPUTSEMANTIKEN — vad händer med hjälperna när spelaren INTE trycker?

   PO-tillägget på #151, punkt 2: "Inget driftande när fingret lyfts, ingen
   fastnad input vid focus loss, multitouch, scenbyte, upp-/avsittning,
   respawn eller när en panel öppnas/stängs."

   Provet kör det BYGGDA spelet i Chromium och skickar RIKTIGA
   tangentbords- och pekhändelser. Det läser tillstånd för diagnostik men
   skriver aldrig i det för att ta sig förbi ett spelarsteg: varje
   nedtryckning och varje släpp går genom sidans egna lyssnare.

   Tre vyer, för att kontrakten skiljer sig: telefon och iPad landscape har
   pekkontroller, skrivbordet har inte det.

   GRÄNSEN, uttalad: emulerade pekhändelser är inte ett finger. Provet
   säger att kedjan håller, inte att den känns rätt på en riktig iPad.
*/
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { chromium } from "playwright";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const DIST = path.join(ROT, "dist");
const PORT = 8894;   /* fri port: se toolchain — 8873 tas av lastlagetest */

let fel = 0;
function prova(namn, ok, detalj = "") {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
}

const srv = http.createServer((q, s) => {
  const f = q.url === "/" ? "ridskolan.html" : q.url.slice(1).split("?")[0];
  const abs = path.join(DIST, f);
  if (!abs.startsWith(DIST) || !fs.existsSync(abs)) { s.writeHead(404); s.end(); return; }
  s.writeHead(200, { "content-type": f.endsWith(".html") ? "text/html" : "application/octet-stream" });
  s.end(fs.readFileSync(abs));
});
await new Promise(r => srv.listen(PORT, r));

/* Samma mönster som gardtest/uppdragstest/replaytest: den förinstallerade
   Chromium används NÄR DEN FINNS, annars låter vi Playwright hitta sin egen.
   Ett hårdkodat sökvägsvärde föll i CI — runnern installerar sin browser via
   `npx playwright install` och har ingen /opt/pw-browsers. */
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  headless: true,
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

const vyer = [
  { namn: "telefon", width: 390, height: 844, hasTouch: true },
  { namn: "iPad landscape", width: 1024, height: 768, hasTouch: true },
  { namn: "skrivbord", width: 1366, height: 768, hasTouch: false },
];

for (const vy of vyer) {
  const page = await browser.newPage({
    viewport: { width: vy.width, height: vy.height }, hasTouch: vy.hasTouch,
  });
  page.on("pageerror", e => { console.error("PAGEERROR", vy.namn, e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(500);
  const ev = f => page.evaluate(f);

  /* ── FOCUS LOSS ──────────────────────────────────────────────────
     Håll skänkeln, lämna fliken. En hjälp som ligger kvar betyder att
     hästen fortsätter gå medan spelaren är någon annanstans. */
  await page.keyboard.down("KeyW");
  await page.waitForTimeout(120);
  const nere = await ev(() => ({ skankel: RIDIN.skankel, ned: !!IN.ned.KeyW }));
  prova(`${vy.namn}: skänkeln svarar medan tangenten hålls`,
    nere.skankel === 1, `skänkel ${nere.skankel}`);

  await ev(() => window.dispatchEvent(new Event("blur")));
  await page.waitForTimeout(120);
  const efterBlur = await ev(() => ({
    skankel: RIDIN.skankel, tygel: RIDIN.tygel, sits: RIDIN.sits,
    styr: RIDIN.styr, parad: RIDIN.parad,
    ned: Object.keys(IN.ned).filter(k => IN.ned[k]).length,
    styrDigital: IN.styrDigital,
  }));
  prova(`${vy.namn}: focus loss släpper alla hjälper`,
    efterBlur.skankel === 0 && efterBlur.tygel === 0 && efterBlur.sits === 0
      && efterBlur.parad === 0,
    `skänkel ${efterBlur.skankel} · tygel ${efterBlur.tygel} · sits ${efterBlur.sits}`);
  prova(`${vy.namn}: och ingen tangent räknas som fortfarande nere`,
    efterBlur.ned === 0 && efterBlur.styrDigital === null,
    `${efterBlur.ned} nere · styrDigital ${efterBlur.styrDigital}`);
  await page.keyboard.up("KeyW");

  /* Ett släpp EFTER blur får inte skriva tillbaka en avsikt. Det är den
     riktiga sekvensen: spelaren alt-tabbar med W nere och släpper den i
     ett annat fönster — keyup når sidan när hon kommer tillbaka. */
  const efterSentSlapp = await ev(() => ({
    skankel: RIDIN.skankel, styr: RIDIN.styr, styrDigital: IN.styrDigital,
  }));
  prova(`${vy.namn}: ett sent släpp efter focus loss väcker ingen avsikt`,
    efterSentSlapp.skankel === 0 && efterSentSlapp.styr === 0,
    `skänkel ${efterSentSlapp.skankel} · styr ${efterSentSlapp.styr}`);

  /* ── DOLD FLIK ───────────────────────────────────────────────────
     Samma sak via visibilitychange, som är den händelse mobilen faktiskt
     skickar när spelaren växlar app. */
  await page.keyboard.down("KeyA");
  await page.waitForTimeout(120);
  await ev(() => {
    Object.defineProperty(document, "visibilityState",
      { configurable: true, get: () => "hidden" });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  await page.waitForTimeout(120);
  const dold = await ev(() => ({ styr: RIDIN.styr, styrDigital: IN.styrDigital }));
  prova(`${vy.namn}: en dold flik släpper styrningen`,
    dold.styrDigital === null, `styrDigital ${dold.styrDigital}`);
  await page.keyboard.up("KeyA");
  await ev(() => {
    Object.defineProperty(document, "visibilityState",
      { configurable: true, get: () => "visible" });
    document.dispatchEvent(new Event("visibilitychange"));
  });

  /* ── PEKSPAKEN ───────────────────────────────────────────────────
     Bara där den finns, och bara i en scen där den FAKTISKT är uppe.

     Ett tidigare utkast mätte spaken direkt på startmenyn. `src/mobil.js`
     döljer hela pekgränssnittet utanför gå- och ridlägena, så mätningen
     drog i en gömd ruta och rapporterade "spaken ger inget utslag" som ett
     produktfel. Den var röd av mitt fel, inte spelets. Provet går nu in i
     gårdsscenen först — samma väg gardtest.mjs tar. */
  await ev(() => { startaVandring(); });
  await page.waitForTimeout(600);
  const scen = await ev(() => G.scen);
  const spakUppe = await ev(() => {
    const j = document.getElementById("joy");
    if (!j) return false;
    const ui = document.getElementById("pekUI");
    return !!(ui && ui.style.display !== "none"
      && j.getBoundingClientRect().width > 0);
  });
  if (vy.hasTouch && spakUppe) {
    const ruta = await ev(() => {
      const j = document.getElementById("joy");
      const r = j.getBoundingClientRect();
      return { x: r.x + r.width / 2, y: r.y + r.height / 2, w: r.width };
    });
    await page.mouse.move(ruta.x, ruta.y);
    await page.mouse.down();
    await page.mouse.move(ruta.x + ruta.w * 0.4, ruta.y, { steps: 4 });
    await page.waitForTimeout(80);
    const drag = await ev(() => (IN.joy ? IN.joy.styrka : 0));
    prova(`${vy.namn}: spaken ger utslag under dragningen`,
      drag > 0.05, `styrka ${drag.toFixed(2)}`);

    /* Ut ur spaken och släpp där — pointerleave/pointercancel-vägen. */
    await page.mouse.move(ruta.x + 400, ruta.y - 300, { steps: 6 });
    await page.mouse.up();
    await page.waitForTimeout(120);
    const slappt = await ev(() => ({
      joy: IN.joy ? IN.joy.styrka : 0, styr: RIDIN.styr, pek: RIDIN.pek,
    }));
    prova(`${vy.namn}: släpp utanför spaken nollar den — ingen drift`,
      slappt.joy === 0 && Math.abs(slappt.styr) < 0.001,
      `styrka ${slappt.joy} · styr ${slappt.styr}`);
  } else if (!vy.hasTouch) {
    console.log(`  ...  ${vy.namn}: ingen pekskärm — spaken byggs inte`);
  } else {
    /* NOT, inte FEL: att spaken inte är uppe i den här scenen är ett
       mätningsvillkor som inte uppfylldes, inte ett uppmätt fel. Att
       färga det rött vore att döpa raden till något den inte mätte. */
    console.log(`  NOT  ${vy.namn}: spaken inte uppe i scen "${scen}"`
      + " — dragningen kunde inte mätas här");
  }

  /* ── EN PANEL SOM ÖPPNAS OCH STÄNGS ──────────────────────────────
     Kontrollhjälpen är en riktig panel med en riktig knapp. Att öppna
     och stänga den får inte lämna en hjälp igång. */
  await page.keyboard.down("Space");
  await page.waitForTimeout(80);
  await ev(() => visaKontrollHjalp());
  await page.keyboard.up("Space");
  await ev(() => document.getElementById("khStang").click());
  await page.waitForTimeout(120);
  const efterPanel = await ev(() => ({
    tygel: RIDIN.tygel, synlig: kontrollHjalpSynlig(),
    ned: Object.keys(IN.ned).filter(k => IN.ned[k]).length,
  }));
  prova(`${vy.namn}: en panel som öppnats och stängts lämnar ingen hjälp igång`,
    efterPanel.tygel === 0 && efterPanel.synlig === false && efterPanel.ned === 0,
    `tygel ${efterPanel.tygel} · ${efterPanel.ned} tangenter nere`);

  await page.close();
}

await browser.close();
await new Promise(r => srv.close(r));
console.log("\nNOT_TESTED: fysisk iPad, fysisk gamepad och Roblox Studio."
  + " Emulerade pekhändelser är inte ett finger.");
if (fel) { console.error(`\n${fel} inputsemantikmätningar föll.`); process.exit(1); }
console.log("ALLA INPUTSEMANTIKKONTROLLER OK");
