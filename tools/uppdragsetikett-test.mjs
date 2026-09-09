/* UPPDRAGSETIKETTEN HELT INNANFÖR SKÄRMEN (#153 fix 4).

   Vägvisarens `.pin` är centrerad (`translate(-50%,…)`), så etiketten
   sticker ut halva sin bredd åt vardera hållet från ankaret. Klampningen
   höll bara ANKARET innanför 44 px, aldrig etikettens rektangel, och en
   normal svensk rubrik hamnade därför utanför kanten.

   Provet SVÄNGER med riktiga tangenttryck — det spelaren gör hela tiden
   — och mäter etikettens `getBoundingClientRect()` mot fönstret hela
   varvet. Det skriver aldrig i speltillståndet.
*/
import http from "node:http";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8897;   /* fri port: 8873 lastlage, 8894 inputsemantik, 8896 välfärd */

let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};

const srv = http.createServer((q, s) => {
  const f = q.url === "/" ? "ridskolan.html" : q.url.slice(1).split("?")[0];
  const abs = path.join(DIST, f);
  if (!abs.startsWith(DIST) || !fs.existsSync(abs)) { s.writeHead(404); s.end(); return; }
  s.writeHead(200, { "content-type": "text/html" });
  s.end(fs.readFileSync(abs));
});
await new Promise(r => srv.listen(PORT, r));

const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  headless: true,
  executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

const vyer = [
  { namn: "iPhone SE 320", width: 320, height: 568, hasTouch: true },
  { namn: "telefon 390", width: 390, height: 844, hasTouch: true },
  { namn: "iPad landscape", width: 1024, height: 768, hasTouch: true },
  { namn: "skrivbord 1366", width: 1366, height: 768, hasTouch: false },
];

for (const vy of vyer) {
  console.log(`\n── ${vy.namn} (${vy.width}×${vy.height}) ──`);
  const page = await browser.newPage({
    viewport: { width: vy.width, height: vy.height }, hasTouch: vy.hasTouch,
  });
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(700);
  if (await page.evaluate(() => !!document.getElementById("bSkapHoppa"))) {
    await page.click("#bSkapHoppa"); await page.waitForTimeout(300);
  }
  await page.click("#bStart");
  await page.waitForTimeout(2500);

  /* Ett helt varv med A intryckt. Etiketten mäts varje steg. */
  let synliga = 0, varsta = null, bredast = 0, flest = 0;
  await page.keyboard.down("KeyA");
  for (let i = 0; i < 32; i++) {
    await page.waitForTimeout(250);
    const m = await page.evaluate(() => {
      const rot = document.getElementById("ubrfVagvisare");
      if (!rot || rot.style.display === "none") return null;
      const e = rot.querySelector(".etikett");
      if (!e) return null;
      const r = e.getBoundingClientRect();
      if (r.width === 0) return null;
      /* Radantalet, så att provet kan skilja "ryms för att den klampas
         rätt" från "ryms för att den brutits till en smal klump". */
      const cs = getComputedStyle(e);
      const rad = parseFloat(cs.lineHeight) || parseFloat(cs.fontSize) * 1.2;
      const inre = r.height - parseFloat(cs.paddingTop) - parseFloat(cs.paddingBottom)
        - parseFloat(cs.borderTopWidth) - parseFloat(cs.borderBottomWidth);
      return { l: Math.round(r.left), r: Math.round(r.right), w: Math.round(r.width),
        t: Math.round(r.top), b: Math.round(r.bottom), txt: (e.textContent || "").trim(),
        rader: Math.max(1, Math.round(inre / rad)) };
    });
    if (!m) continue;
    synliga++;
    bredast = Math.max(bredast, m.w);
    flest = Math.max(flest, m.rader);
    const ut = Math.max(0, -m.l, m.r - vy.width, -m.t, m.b - vy.height);
    if (ut > 0 && (!varsta || ut > varsta.ut)) varsta = { ...m, ut };
  }
  await page.keyboard.up("KeyA");

  prova(`${vy.namn}: vägvisaren syns under svängen`,
    synliga > 0, `${synliga} av 32 mätningar`);
  prova(`${vy.namn}: etiketten ligger helt innanför skärmen`,
    varsta === null,
    varsta ? `"${varsta.txt}" ${varsta.w} px · v ${varsta.l} h ${varsta.r} · ${varsta.ut} px utanför`
      : `${synliga} mätningar, bredaste etikett ${bredast} px`);
  /* Kontrollmätning: taket i CSS ska hindra att etiketten någonsin blir
     bredare än fönstret. Utan den kunde kravet ovan bli grönt bara för
     att rubriken råkade vara kort. */
  prova(`${vy.namn}: etiketten är aldrig bredare än fönstret`,
    bredast > 0 && bredast <= vy.width,
    `bredast ${bredast} px av ${vy.width} px`);
  /* Ryms rubriken på en rad ska den STÅ på en rad. Utan det kravet
     kunde "innanför skärmen" bli grönt genom att etiketten bröts till
     en smal klump i stället för att klampas rätt — vilket ett tidigare
     utkast av rättelsen faktiskt gjorde (98 px i stället för 231). */
  if (vy.width >= 420) prova(`${vy.namn}: rubriken bryts inte i onödan`,
    flest === 1, `flest ${flest} rader, bredast ${bredast} px`);

  await page.close();
}

console.log(fel ? `\n${fel} FEL` : "\nALLA UPPDRAGSETIKETTKONTROLLER OK");
await browser.close(); srv.close();
process.exit(fel ? 1 : 0);
