/* EN LEKTION RIDEN HELA VÄGEN — P3-basens produktionskedja i en riktig
   webbläsare mot dist/ (granskning #273 5928307604, blockerare 4).

   `lektionstest.mjs` matar lektionerna med syntetiska observationer i en
   VM, och `ridpaneltest.mjs` bygger själv ett «klar»-läge för att pröva
   knapparna. Inget av dem visar att kedjan

       riktig tangent → webbens ridtillstånd (svar.js) → kopplingen och
       observationerna (koppling.js, observation.js) → lektionen
       (lektioner/halt.js) → slut → ridpanelen och lektionsminnet

   hänger ihop. Det här provet rider den. Haltlektionen är vald som
   representant: den kräver halt, skritt PÅ RYTTARENS HJÄLP, en plats på
   banan (X) och en hålltid — alltså gångart, hjälphändelse, läge och tid
   genom hela kedjan.

   VAD PROVET GÖR OCH INTE GÖR
     · Uppsittningen är samma genväg som ridpaneltest (First Ride, pass 0,
       `startaVandring`). Den ingår inte i det som mäts.
     · EFTER uppsittningen ändrar provet inget speltillstånd. Det trycker
       riktiga tangenter, klickar panelens egna knappar och LÄSER.
     · Hästens läge läses för att veta NÄR bromsen ska läggas — det en
       spelare ser på skärmen.

     A. klar: halt → skritt på hjälp → halt i ringen vid X → hållen tid,
     B. halt UTANFÖR ringen: lektionen blir aldrig klar, panelen säger
        varför, minnet rörs inte — och avsittningen stänger försöket.

   Tidsgränsen (120 s) rids inte här; den prövas syntetiskt i lektionstest.

   Kör: python3 tools/build.py && node tools/lektion-e2e-test.mjs */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DIST = path.join(ROT, "dist");
const PORT = 8934;
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};
const srv = http.createServer((q, s) => {
  const f = q.url === "/" ? "ridskolan.html" : q.url.slice(1).split("?")[0];
  const abs = path.join(DIST, f);
  if (!abs.startsWith(DIST) || !fs.existsSync(abs)) { s.writeHead(404); s.end(); return; }
  s.writeHead(200, { "content-type": f.endsWith(".html") ? "text/html" : "application/octet-stream" });
  s.end(fs.readFileSync(abs));
});
await new Promise(r => srv.listen(PORT, r));
const exe = process.env.CHROMIUM || "/opt/pw-browsers/chromium-1194/chrome-linux/chrome";
const browser = await chromium.launch({
  headless: true, executablePath: fs.existsSync(exe) ? exe : undefined,
  args: ["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"],
});

const MINNESNYCKEL = "lektion:halt:server-halt-1";
const X = { x: 10, y: 30 };            // dressyrbanans mitt i webbens meter
const ZON = 1.5;                       // HaltLektion ZON_R

async function sittUpp() {
  const ctx = await browser.newContext({ viewport: { width: 1366, height: 768 }, locale: "sv-SE" });
  const page = await ctx.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(700);
  await page.evaluate(() => {
    overlay(false); window.SPRAKET = "sv";
    SPAR.pass = 0; SPAR_BETRODD = true; startaVandring();
  });
  /* Panelen ritas i spelloopen. Väntan får INTE sväljas här: utan panel
     finns ingen kedja att rida, och provet ska då falla på den raden. */
  await page.waitForFunction(() => { const el = document.getElementById("ridpanel"); return !!el && !el.hidden; },
    null, { timeout: 30000 });
  return page;
}
/* Allt nedan LÄSER. Inget skrivs till spelet. */
const las = page => page.evaluate(nyckel => {
  const el = document.getElementById("ridpanel");
  const s = Lektionsmeny._S.lektioner && Lektionsmeny._S.lektioner.halt;
  const O = s ? RittLektion.kontext(G.t, null) : null;
  const handelser = O ? O.logg.handelser.filter(h => h.typ === "gangart").map(h => ({ till: h.data.till, orsak: h.data.orsak })) : [];
  return {
    scen: G.scen, x: G.px, y: G.py, gang: G.ride ? G.ride.gangart : null,
    medd: (el && el.querySelector(".skUi") || {}).textContent || "",
    knappar: el ? [...el.querySelectorAll(".skV button")].map(b => b.textContent) : [],
    lekt: s ? { lage: s.lage, tips: s.tips, progress: s.progress, skritt: s.skritt, haltTid: s.haltTid,
      resultat: s.resultat ? { skrittMeter: s.resultat.skrittMeter, haltSekunder: s.resultat.haltSekunder,
        slutpunkt: s.resultat.slutpunkt } : null } : null,
    handelser,
    minne: !!(SPAR.lektionsminne && SPAR.lektionsminne[nyckel] === true),
    sparat: (() => { try { for (let i = 0; i < localStorage.length; i++) {
      const v = localStorage.getItem(localStorage.key(i)); if (v && v.includes(nyckel)) return true; } } catch (e) {} return false; })(),
  };
}, MINNESNYCKEL);
const klick = (page, borjar) => page.evaluate(t => {
  const b = [...document.querySelectorAll("#ridpanel .skV button")].find(x => x.textContent.startsWith(t));
  if (b) b.click();
  return !!b;
}, borjar);
const tills = (page, villkor, arg, ms) => page.waitForFunction(villkor, arg, { timeout: ms, polling: 30 })
  .then(() => true, () => false);

/* Välj lektionen med panelens egna knappar, från halt, och starta den. */
async function valjOchStarta(page) {
  const steg = [];
  for (const t of ["Välj övning", "Gångarter och fart", "Träna start och halt", "Starta övningen"]) {
    steg.push(await klick(page, t));
    await page.waitForTimeout(200);
  }
  return steg;
}
const drivPa = async page => { await page.keyboard.down("KeyW"); await page.waitForTimeout(350); await page.keyboard.up("KeyW"); };
const bromsaNed = async page => { await page.keyboard.down("KeyS"); await page.keyboard.down("Space"); };
const bromsaUpp = async page => { await page.keyboard.up("KeyS"); await page.keyboard.up("Space"); };

/* ── A: klar ───────────────────────────────────────────────────────── */
{
  console.log("A  haltlektionen riden till «klar» med riktiga tangenter");
  const page = await sittUpp();
  const start = await las(page);
  prova("uppsutten i ridhuset, i halt, före X på mittlinjen", start.scen === "lektion" && start.gang === "halt"
    && Math.abs(start.x - X.x) < 0.5 && start.y > X.y + 10, `(${start.x.toFixed(2)} · ${start.y.toFixed(2)}) ${start.gang}`);
  prova("minnet är tomt före ritten", start.minne === false && start.sparat === false);

  const val = await valjOchStarta(page);
  prova("lektionen valdes och startades med panelens knappar", val.every(Boolean), val.join(","));
  /* 1. Stå still: lektionen går själv från halt1 till walk efter 1 s. */
  const stod = await tills(page, () => { const s = Lektionsmeny._S.lektioner.halt; return s && s.lage === "walk" && s.tips === "walk_on"; }, null, 15000);
  const efterStilla = await las(page);
  prova("stilla i halt → lektionen ber om skritt", stod && /skritt/i.test(efterStilla.medd), efterStilla.medd);
  prova("ingen gångartshändelse ännu — ryttaren har inte bett om något", efterStilla.handelser.length === 0,
    JSON.stringify(efterStilla.handelser));

  /* 2. Skritt på ryttarens hjälp, och fram mot X. */
  await drivPa(page);
  const gar = await tills(page, () => G.ride.gangart === "skritt", null, 10000);
  prova("W gav skritt", gar);
  /* Bromsen läggs en dryg meter före X: uppmätt bromssträcka ur skritt är
     ungefär 1,0–1,1 m. Ringen är ±1,5 m. */
  const framme = await tills(page, y => G.py <= y, X.y + 1.05, 60000);
  await bromsaNed(page);
  const vidBroms = await las(page);
  prova("fram till X i skritt", framme && vidBroms.gang === "skritt", `y ${vidBroms.y.toFixed(2)}`);
  prova("skritten räknades som ryttarens: minst 4 m på hjälp", vidBroms.lekt.skritt >= 4, `${vidBroms.lekt.skritt.toFixed(2)} m`);

  /* 3. Halt i ringen, hållen. Bromsen hålls: se rapportens iakttagelse om
     vad som händer när den släpps. */
  const klar = await tills(page, () => Lektionsmeny._S.lektioner.halt.lage === "complete", null, 20000);
  const slut = await las(page);
  await bromsaUpp(page);
  prova("lektionen blev klar", klar && slut.lekt.lage === "complete" && slut.lekt.progress === 100,
    `${slut.lekt.lage} ${slut.lekt.progress}% · tips ${slut.lekt.tips}`);
  const avst = Math.hypot(slut.x - X.x, slut.y - X.y);
  prova("hästen står i ringen vid X", avst <= ZON, `${avst.toFixed(2)} m från X`);
  prova("resultatet bär det som faktiskt reds", !!slut.lekt.resultat && slut.lekt.resultat.skrittMeter >= 4
    && slut.lekt.resultat.haltSekunder >= 2 && !!slut.lekt.resultat.slutpunkt,
    JSON.stringify(slut.lekt.resultat));
  prova("loggen bär ryttarens två hjälper: skritt, sedan halt",
    slut.handelser.length === 2 && slut.handelser[0].till === "walk" && slut.handelser[0].orsak === "hjalp"
    && slut.handelser[1].till === "halt" && slut.handelser[1].orsak === "hjalp", JSON.stringify(slut.handelser));
  /* Panelen: återkopplingen ur de frysta talen, och valen efter ett försök. */
  await page.waitForTimeout(400);
  const p = await las(page);
  const m = /Du skrittade ([\d,.]+) m och stod stilla ([\d,.]+) s vid X/.exec(p.medd);
  prova("panelen visar återkopplingen med rittens egna tal", !!m, p.medd);
  prova("valen efter försöket: Prova igen och Avsluta", p.knappar.some(k => k.startsWith("Prova igen"))
    && p.knappar.some(k => k.startsWith("Avsluta")), p.knappar.join(" | "));
  prova("lektionsminnet: första klarade halt sparad — i minnet och i sparfilen", p.minne === true && p.sparat === true,
    `${p.minne} ${p.sparat}`);
  await page.context().close();
}

/* ── B: halt utanför ringen ───────────────────────────────────────── */
{
  console.log("B  halt UTANFÖR ringen blir aldrig klar");
  const page = await sittUpp();
  await valjOchStarta(page);
  await tills(page, () => { const s = Lektionsmeny._S.lektioner.halt; return s && s.lage === "walk"; }, null, 15000);
  await drivPa(page);
  /* Minst 4 m skritt, sedan halt långt före X. */
  const langt = await tills(page, () => Lektionsmeny._S.lektioner.halt.skritt >= 5, null, 30000);
  await bromsaNed(page);
  await tills(page, () => G.ride.gangart === "halt", null, 10000);
  await page.waitForTimeout(3200);          // längre än hålltiden på 2 s
  const s = await las(page);
  await bromsaUpp(page);
  const avst = Math.hypot(s.x - X.x, s.y - X.y);
  prova("hon står i halt, utanför ringen", langt && s.gang === "halt" && avst > ZON, `${avst.toFixed(2)} m från X`);
  prova("lektionen är INTE klar och ingen hålltid räknas", s.lekt.lage === "walk" && s.lekt.haltTid === 0 && !s.lekt.resultat,
    `${s.lekt.lage} · tips ${s.lekt.tips} · ${s.lekt.haltTid} s`);
  prova("lektionen säger varför: halt utanför", s.lekt.tips === "halt_outside", s.lekt.tips);
  prova("panelen bär den raden, med framstegen under 100 %", /\d+%$/.test(s.medd) && !/100%$/.test(s.medd), s.medd);
  prova("minnet är orört", s.minne === false && s.sparat === false);
  /* Avsittningen stänger försöket — aldrig som framgång. */
  await page.keyboard.press("KeyE"); await page.waitForTimeout(700);
  const av = await page.evaluate(nyckel => ({ scen: G.scen, p3: G.p3,
    minne: !!(SPAR.lektionsminne && SPAR.lektionsminne[nyckel] === true) }), MINNESNYCKEL);
  prova("E sitter av: ritten slutar, och lektionen blev aldrig klarad", av.scen === "resultat" && av.p3 === false && av.minne === false,
    JSON.stringify(av));
  await page.context().close();
}

await browser.close(); srv.close();
console.log(fel ? `LEKTION E2E: ${fel} FEL` : "LEKTION E2E: alla gröna");
process.exit(fel ? 1 : 0);
