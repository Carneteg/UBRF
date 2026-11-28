/* AVSITTNING BARA FRÅN HALT — Batch 0.11 (E2).

   Man sitter av en häst som står. Provet mäter regeln på två nivåer:

   DEL 1 — regeln själv (src/riding/avsittning.js), utan webbläsare.
     Samma tre funktioner finns i Roblox (roblox/src/client/Avsittning.luau)
     och mäts där av roblox/tests/klient-sittav-halt.spec.luau.
       · står hästen → «nu»; rör hon sig → «vantar»,
       · etiketten «halt» räcker inte när hon fortfarande rullar,
       · steget svarar «bromsa» tills hon står och sedan «sitt_av»,
       · nödutgången löser ut efter NODUTGANG_S sekunder, lika vid 30,
         60 och 120 bilder i sekunden,
       · ett andra tryck startar inte om klockan.

   DEL 2 — spelet, i en riktig webbläsare mot dist/.
       · E vid halt sitter av direkt, som förut,
       · E i trav/galopp sitter INTE av: hästen tas ner, en rad säger
         vad som händer, och avsittningen kommer när hon står,
       · en hållen W-tangent driver inte emot,
       · ett andra E sitter inte av i förtid,
       · pekknappen SITT AV går samma väg,
       · KONTROLLMÄTNING: den gamla regeln (avsittning direkt) sitter av
         i full fart — provet kan alltså se skillnaden.

   FALSIFIERING (måste bli rött, annars bevisar provet inget):
     --muter-halt     «står» är alltid sant → avsittning i galopp
     --muter-nod      ingen nödutgång
     --muter-omstart  ett andra tryck startar om klockan

   Kör: python3 tools/build.py && node tools/avsittningtest.mjs
        node tools/avsittningtest.mjs --bara-regeln   (utan webbläsare) */
import fs from "node:fs";
import http from "node:http";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const arg = new Set(process.argv.slice(2));
let fel = 0;
const prova = (namn, ok, detalj = "") => {
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};
const las = rel => fs.readFileSync(path.join(ROT, rel), "utf8");

/* ── Mutationerna görs i en KOPIA av källan, aldrig i filen. ─────── */
function regelKalla() {
  let s = las("src/riding/avsittning.js");
  const byt = (fran, till) => {
    if (!s.includes(fran)) { console.error("FEL  mutationen hittar inte sin rad: " + fran); process.exit(2); }
    s = s.replace(fran, till);
  };
  if (arg.has("--muter-halt"))
    byt('return gangart === "halt" && Math.abs(fart || 0) <= K().STILLA;', "return true;");
  if (arg.has("--muter-nod"))
    byt("|| A.tid >= K().NODUTGANG_S", "");
  if (arg.has("--muter-omstart"))
    byt("if (!A.vantar) { A.vantar = true; A.tid = 0; }", "A.vantar = true; A.tid = 0;");
  return s;
}

/* ══ DEL 1: REGELN ═══════════════════════════════════════════════════ */
console.log("1  regeln (src/riding/avsittning.js)");
const ctx = vm.createContext({ console, Math });
{
  /* Bara kanonens tal behövs; hela telemetri.js drar med sig ridmodellen. */
  const t = las("src/riding/telemetri.js");
  const m = t.match(/AVSITTNING:\s*\{\s*STILLA:\s*([0-9.]+),\s*NODUTGANG_S:\s*([0-9.]+)\s*\}/);
  if (!m) { console.error("FEL  hittar inte RID_KANON.AVSITTNING i src/riding/telemetri.js"); process.exit(2); }
  vm.runInContext(`var RID_KANON={AVSITTNING:{STILLA:${m[1]},NODUTGANG_S:${m[2]}}};`, ctx);
  vm.runInContext(regelKalla() + "\n;globalThis.Avsittning=Avsittning;", ctx);
}
const A = ctx.Avsittning, KAN = ctx.RID_KANON.AVSITTNING;
prova("kanonens tal finns och är rimliga", KAN.STILLA > 0 && KAN.STILLA <= 0.1 && KAN.NODUTGANG_S >= 3 && KAN.NODUTGANG_S <= 8,
  `STILLA ${KAN.STILLA} m/s, NODUTGANG_S ${KAN.NODUTGANG_S} s`);
{
  const a = A.ny();
  prova("står hästen (halt, 0 m/s) sker avsittningen NU", A.begar(a, "halt", 0) === "nu" && a.vantar === false);
  prova("utan begäran gör steget ingenting", A.steg(A.ny(), "galopp", 5, 1 / 60) === null);
  for (const [g, v] of [["skritt", 1.6], ["trav", 3.2], ["galopp", 5.5]]) {
    const b = A.ny();
    prova(`i ${g} (${v} m/s) blir det en BEGÄRAN, ingen avsittning`, A.begar(b, g, v) === "vantar" && b.vantar === true);
  }
  const c = A.ny();
  prova("etiketten «halt» räcker inte medan hon rullar (0,40 m/s)", A.begar(c, "halt", 0.40) === "vantar");
  const d = A.ny();
  prova("och farten 0 räcker inte i en annan gångart än halt", A.begar(d, "trav", 0) === "vantar");
}
{
  /* En nedtagning: galopp → trav → skritt → halt, 0,8 s per pinne. */
  const a = A.ny(); A.begar(a, "galopp", 5.5);
  const dt = 1 / 60; let t = 0, svar = [], satAv = null;
  const lage = tid => tid < 0.8 ? ["galopp", 5.5] : tid < 1.6 ? ["trav", 3.2] : tid < 2.4 ? ["skritt", 1.5]
    : tid < 2.9 ? ["halt", 0.3] : ["halt", 0];
  while (t < 6 && satAv === null) {
    const [g, v] = lage(t); const s = A.steg(a, g, v, dt); t += dt;
    svar.push(s); if (s === "sitt_av") satAv = { t, g, v };
  }
  prova("steget svarar «bromsa» hela vägen ner", svar.slice(0, -1).every(s => s === "bromsa"), `${svar.length - 1} bildrutor`);
  prova("och «sitt_av» först när hon STÅR", satAv && satAv.g === "halt" && satAv.v <= KAN.STILLA && satAv.t > 2.85 && satAv.t < 3.0,
    satAv ? `t=${satAv.t.toFixed(2)} s, ${satAv.g} ${satAv.v} m/s` : "aldrig");
  prova("efteråt finns ingen begäran kvar", a.vantar === false && A.steg(a, "halt", 0, dt) === null);
}
{
  /* Nödutgången: en häst som aldrig kommer till halt. */
  const tider = [30, 60, 120].map(fps => {
    const a = A.ny(); A.begar(a, "galopp", 5.5);
    let t = 0; const dt = 1 / fps;
    while (t < 20) { t += dt; if (A.steg(a, "galopp", 5.5, dt) === "sitt_av") return t; }
    return Infinity;
  });
  prova("nödutgången löser ut efter NODUTGANG_S — lika vid 30, 60 och 120 bilder/s",
    tider.every(t => Math.abs(t - KAN.NODUTGANG_S) <= 1 / 30 + 1e-9), tider.map(t => t.toFixed(3)).join(" · ") + " s");
}
{
  const a = A.ny(); A.begar(a, "trav", 3);
  const dt = 1 / 60; let t = 0, ut = null;
  while (t < 20 && ut === null) {
    t += dt;
    if (Math.abs(t - 3) < dt / 2) A.begar(a, "trav", 3);          // andra trycket, 3 s in
    if (A.steg(a, "trav", 3, dt) === "sitt_av") ut = t;
  }
  prova("ett andra tryck startar INTE om klockan", ut !== null && Math.abs(ut - KAN.NODUTGANG_S) <= 1 / 30, `${ut === null ? "aldrig" : ut.toFixed(2)} s`);
  const b = A.ny(); A.begar(b, "trav", 3);
  prova("och sitter inte av i förtid", A.begar(b, "trav", 3) === "vantar" && b.vantar === true);
}

if (arg.has("--bara-regeln")) {
  console.log(fel ? `\nAVSITTNINGTEST: ${fel} FEL` : "\nAVSITTNINGTEST (regeln): alla gröna");
  process.exit(fel ? 1 : 0);
}

/* ══ DEL 2: SPELET ═══════════════════════════════════════════════════ */
const { chromium } = await import("playwright");
const DIST = path.join(ROT, "dist");
const PORT = 8937;
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
const muter = [...arg].filter(a => a.startsWith("--muter-"));

async function sittUpp(opt = {}) {
  const ctxB = await browser.newContext({ viewport: { width: 1366, height: 768 }, hasTouch: !!opt.pek });
  const page = await ctxB.newPage();
  page.on("pageerror", e => { console.error("PAGEERROR", e.message); fel++; });
  if (process.env.UBRF_CPU_BROMS) {
    const cdp = await ctxB.newCDPSession(page);
    await cdp.send("Emulation.setCPUThrottlingRate", { rate: Number(process.env.UBRF_CPU_BROMS) });
  }
  await page.goto(`http://localhost:${PORT}/`, { waitUntil: "load" });
  await page.waitForTimeout(700);
  /* Mutationen byter regeln i den LADDADE sidan — dist rörs inte. */
  /* `Avsittning` är en `const` i spelets eget skript; en ny `const` i en
     eval hamnar i evalens egen räckvidd och spelet hade fortsatt läsa
     originalet. Därför byts funktionerna PÅ det objekt spelet håller. */
  if (muter.length) await page.evaluate(src => {
    Object.assign(Avsittning, new Function(src + "\n;return Avsittning;")());
  }, regelKalla());
  await page.evaluate(sprak => {
    overlay(false); window.SPRAKET = sprak || "sv";
    SPAR.pass = 0; SPAR_BETRODD = true; startaVandring();
  }, opt.sprak);
  await page.waitForFunction(() => typeof G !== "undefined" && G.scen === "lektion" && G.p3 === true
    && !!document.getElementById("ridpanel") && !document.getElementById("ridpanel").hidden,
    null, { timeout: 30000 }).catch(() => {});
  return page;
}
/* ALLA VÄNTETIDER ÄR SPELTID, INTE VÄGGKLOCKA. CI ritar med
   mjukvarurendering och hinner bara några bildrutor i sekunden; spelet
   stegar då högst 0,05 s per ruta, så en väggklocksekund kan vara 0,2 s
   i spelet. Första versionen av provet väntade 450 ms väggklocka mellan
   två DRIV — i CI överlappade pulserna (en puls är 0,24 s speltid), det
   blev aldrig en NY impuls, och hästen kom inte förbi skritt (rött på
   41a72e1, grönt lokalt). Återskapas lokalt med UBRF_CPU_BROMS=20. */
const speltid = (page, s) => page.evaluate(s => new Promise(klar => {
  const t0 = G.t;
  (function v() { if (G.t - t0 >= s) klar(); else requestAnimationFrame(v); })();
}), s);
const lage = page => page.evaluate(() => ({
  scen: G.scen, p3: G.p3, gangart: G.ride && G.ride.gangart, fart: G.ride ? G.ride.tempo : null,
  vantar: !!(G.avsitt && G.avsitt.vantar), t: G.t, bromsN: IN.bromsN,
  medd: ((document.querySelector("#ridpanel .skUi") || {}).textContent || "").trim(),
}));
/* Rid upp till minst `mal` genom spelets egen DRIV-impuls, en pinne i taget. */
async function ridTill(page, mal) {
  const ORD = ["halt", "skritt", "trav", "galopp"];
  for (let i = 0; i < 60; i++) {
    const g = await page.evaluate(() => G.ride.gangart);
    if (ORD.indexOf(g) >= ORD.indexOf(mal)) break;
    await page.evaluate(() => ridDriv());
    await speltid(page, 1.2);            // pulsen (0,24 s) och modellens spärr (0,9 s) hinner gå ut
  }
  /* Låt övergången bli KLAR: en drivande hjälp som just getts fullföljs
     av modellen, och provet ska mäta nedtagningen från en etablerad
     gångart (fallet «DRIV strax före» mäts för sig, i del 4b). */
  await speltid(page, 2.0);
  return lage(page);
}
/* Följ en väntande avsittning bildruta för bildruta, i spelets egen tid. */
const folj = (page, maxS) => page.evaluate(maxS => new Promise(klar => {
  const t0 = G.t, prov = [];
  (function ruta() {
    const iSadel = G.scen === "lektion" && G.p3;
    prov.push({ t: G.t - t0, fart: G.ride ? G.ride.tempo : 0, g: G.ride ? G.ride.gangart : null, iSadel });
    if (!iSadel || G.t - t0 > maxS) return klar(prov);
    requestAnimationFrame(ruta);
  })();
}), maxS);

console.log("2  spelet: vid halt");
{
  const page = await sittUpp();
  const fore = await lage(page);
  prova("KONTROLL: uppsutten och hon står", fore.scen === "lektion" && fore.p3 === true && fore.gangart === "halt" && fore.fart <= 0.05,
    JSON.stringify(fore).slice(0, 110));
  await page.keyboard.press("KeyE"); await page.waitForTimeout(400);
  const e = await lage(page);
  prova("E vid halt sitter av DIREKT, som förut", e.scen === "resultat" && e.p3 === false && e.vantar === false, `scen ${e.scen}`);
  await page.context().close();
}

console.log("3  spelet: i rörelse");
let nedtagning = null;
{
  const page = await sittUpp();
  const fore = await ridTill(page, "galopp");
  prova("KONTROLL: hon rör sig i trav eller galopp", ["trav", "galopp"].includes(fore.gangart) && fore.fart > 2,
    `${fore.gangart} ${fore.fart.toFixed(2)} m/s`);
  await page.keyboard.down("KeyW");                       // spelaren håller dessutom skänkeln på
  await speltid(page, 0.12);
  const bromsFore = (await lage(page)).bromsN;
  const spar = folj(page, 8);
  await page.keyboard.press("KeyE");
  await speltid(page, 0.15);
  const strax = await lage(page);
  prova("E i rörelse sitter INTE av", strax.scen === "lektion" && strax.p3 === true,
    `scen ${strax.scen}, ${strax.gangart} ${strax.fart === null ? "-" : strax.fart.toFixed(2)} m/s`);
  prova("utan en begäran som väntar på halt", strax.vantar === true);
  prova("en rad säger vad som händer", strax.medd.includes("Vi stannar först"), `«${strax.medd}»`);
  await page.keyboard.press("KeyE");                      // otålig: ett tryck till
  await speltid(page, 0.12);
  const otalig = await lage(page);
  prova("ett andra E sitter inte av i förtid", otalig.scen === "lektion" && otalig.vantar === true,
    `scen ${otalig.scen}, ${otalig.fart === null ? "-" : otalig.fart.toFixed(2)} m/s`);
  const prov = await spar;
  await page.keyboard.up("KeyW");
  const sist = prov.filter(p => p.iSadel).pop(), slut = prov[prov.length - 1];
  nedtagning = sist ? sist.t : null;
  prova("avsittningen KOM", slut.iSadel === false, `efter ${slut.t.toFixed(2)} s`);
  prova("och hon STOD då (halt, under 0,05 m/s)", !!sist && sist.g === "halt" && sist.fart <= KAN.STILLA + 1e-9,
    sist ? `${sist.g} ${sist.fart.toFixed(3)} m/s` : "-");
  prova("inom nödutgångens tid — den ska inte vara det normala", nedtagning !== null && nedtagning < KAN.NODUTGANG_S - 0.25,
    `${nedtagning === null ? "-" : nedtagning.toFixed(2)} s av ${KAN.NODUTGANG_S}`);
  /* Farten ska gå NEDÅT: en hållen W får inte driva emot stallets broms. */
  let okning = 0;
  for (let i = 1; i < prov.length; i++) if (prov[i].iSadel) okning = Math.max(okning, prov[i].fart - prov[i - 1].fart);
  prova("farten ökar aldrig under nedtagningen, trots hållen W", okning <= 0.02, `största ökning ${okning.toFixed(3)} m/s per bildruta`);
  const efter = await lage(page);
  prova("stallets broms räknas inte som spelarens tryck", efter.bromsN === bromsFore, `${bromsFore} → ${efter.bromsN}`);
  prova("efteråt väntar vägen efter ritten", efter.scen === "resultat" && efter.p3 === false && efter.vantar === false, `scen ${efter.scen}`);
  await page.context().close();
}

console.log("4  spelet: pekknappen och engelskan");
{
  const page = await sittUpp({ pek: true, sprak: "en" });
  const fore = await ridTill(page, "trav");
  const knapp = await page.evaluate(() => {
    const b = document.getElementById("pekSittAv");
    if (!b) return null;
    b.dispatchEvent(new PointerEvent("pointerdown", { bubbles: true, cancelable: true, pointerType: "touch" }));
    b.dispatchEvent(new PointerEvent("pointerup", { bubbles: true, pointerType: "touch" }));
    return b.dataset.tap;
  });
  await speltid(page, 0.15);
  const strax = await lage(page);
  prova("pekknappen SITT AV går samma väg", knapp === "KeyE" && fore.fart > 1 && strax.scen === "lektion" && strax.vantar === true,
    `${fore.gangart} ${fore.fart.toFixed(2)} m/s → scen ${strax.scen}, väntar ${strax.vantar}`);
  prova("raden står på engelska när språket är engelska", strax.medd.includes("We stop first"), `«${strax.medd}»`);
  const prov = await folj(page, 8);
  const sist = prov.filter(p => p.iSadel).pop();
  prova("och sitter av när hon står", prov[prov.length - 1].iSadel === false && !!sist && sist.fart <= KAN.STILLA + 1e-9,
    sist ? `${sist.g} ${sist.fart.toFixed(3)} m/s efter ${sist.t.toFixed(2)} s` : "-");
  await page.context().close();
}

console.log("4b spelet: en drivande hjälp strax före SITT AV (värsta fallet)");
{
  const page = await sittUpp();
  const fore = await ridTill(page, "trav");
  if (fore.gangart === "trav") {
    await page.evaluate(() => ridDriv());
    await speltid(page, 0.3);
    const spar = folj(page, 9);
    await page.keyboard.press("KeyE");
    const prov = await spar;
    const sist = prov.filter(p => p.iSadel).pop(), topp = Math.max(...prov.map(p => p.fart));
    prova("hon tas ner till halt även då — nödutgången behövs inte",
      prov[prov.length - 1].iSadel === false && !!sist && sist.g === "halt" && sist.fart <= KAN.STILLA + 1e-9 && sist.t < KAN.NODUTGANG_S - 0.25,
      sist ? `${sist.g} ${sist.fart.toFixed(3)} m/s efter ${sist.t.toFixed(2)} s av ${KAN.NODUTGANG_S} (toppfart ${topp.toFixed(2)} m/s)` : "-");
  } else prova("KONTROLL: provet kom till trav", false, `${fore.gangart}`);
  await page.context().close();
}

console.log("5  KONTROLLMÄTNING: den gamla regeln");
{
  const page = await sittUpp();
  const fore = await ridTill(page, "galopp");
  const gammal = await page.evaluate(() => { const v = G.ride.tempo, g = G.ride.gangart; ridAvsittningNu(); return { v, g, scen: G.scen }; });
  prova("avsittning direkt (som före Batch 0.11) sitter av i full fart — provet ser skillnaden",
    fore.fart > 2 && gammal.scen === "resultat" && gammal.v > 2, `${gammal.g} ${gammal.v.toFixed(2)} m/s → ${gammal.scen}`);
  await page.context().close();
}

await browser.close(); srv.close();
if (nedtagning !== null) console.log(`\n  uppmätt nedtagning till halt: ${nedtagning.toFixed(2)} s`);
console.log(fel ? `\nAVSITTNINGTEST: ${fel} FEL` : "\nAVSITTNINGTEST: alla gröna");
process.exit(fel ? 1 : 0);
