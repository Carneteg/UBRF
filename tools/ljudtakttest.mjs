#!/usr/bin/env node
/* ══════════════════════════════════════════════════════════════════
   LJUDTAKTTESTET — hörs hovarna i gångartens takt?

   Ljud-grind 0.6 (F1, se docs/ACTIVE-GATE.md). Hovslagen delade förut
   fasen jämnt: skritten fick två slag per cykel (den har fyra) och
   galoppen tre lika långa (den har tre slag och en paus). Nu läser
   ljudet samma rad i GANGFAS som benen.

   ── VAD SOM MÄTS ───────────────────────────────────────────────────

   Produktionskällan (src/riding/gangfas.js, src/ljud.js) körs i en
   vm-kontext med en ATTRAPP av ljudklockan: varje oscillator som startas
   sparar sin starttid. En häst "rids" med jämn fas vid 30, 60 och 120
   bilder per sekund, och provet läser NÄR slagen lades på klockan.

   FACIT STÅR HÄR, INTE I TABELLEN: skritt är fyra jämna slag, trav två,
   galopp tre slag följda av ett svävmoment (ridlärans takt).

   Det här provet hör ingenting. Klang, styrka och hur takten låter på en
   riktig enhet kan bara en människa avgöra.

   ── FALSIFIERING ───────────────────────────────────────────────────
     --muter-takt    flyttar galoppens tredje slag i en KOPIA av tabellen
     --muter-klocka  spelar slagen "nu" i stället för på ljudklockan

   Kör: node tools/ljudtakttest.mjs            (exit 1 vid avvikelse) */
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const las = (f) => fs.readFileSync(path.join(ROT, f), "utf8");
const ARG = new Set(process.argv.slice(2));
function mutera(kod, fran, till, vad) {
  if (!kod.includes(fran)) throw new Error(`mutationsankaret för ${vad} hittades inte — provet kan inte falsifieras`);
  return kod.replace(fran, till);
}

function byggKontext() {
  let fasKod = las("src/riding/gangfas.js"), ljudKod = las("src/ljud.js");
  if (ARG.has("--muter-takt"))
    fasKod = mutera(fasKod, "RF: ben(0.50, 0.25) }", "RF: ben(0.66, 0.25) }", "galoppens tredje slag");
  if (ARG.has("--muter-klocka"))
    ljudKod = mutera(ljudKod, "nu+ruta*(sl.lage-fran)/steg", "nu", "ljudklockan");
  const starter = [];
  const param = () => ({ value: 0, setValueAtTime() {}, exponentialRampToValueAtTime() {}, linearRampToValueAtTime() {} });
  const nod = () => ({ connect() {}, start() {}, stop() {}, frequency: param(), gain: param(), Q: param(), playbackRate: param(), buffer: null, type: "" });
  const ljudctx = { currentTime: 0, state: "running",
    createOscillator() { const n = nod(); n.start = (t) => starter.push(t); return n; },
    createGain: nod, createBiquadFilter: nod, createBufferSource: nod };
  const ctx = { console, Math, window: {}, addEventListener() {}, document: { addEventListener() {} } };
  vm.createContext(ctx);
  vm.runInContext(fasKod + "\n" + ljudKod + "\nthis.X={LJUD,ljudRittSteg,gangSlag,gangPasserade,GANGFAS};", ctx);
  ctx.X.LJUD.ctx = ljudctx; ctx.X.LJUD.master = nod(); ctx.X.LJUD.brus = {}; ctx.X.LJUD.pa = true;
  return { X: ctx.X, ljudctx, starter };
}

let fel = 0, antal = 0;
function prova(namn, ok, detalj) {
  antal++; if (!ok) fel++;
  console.log(`${ok ? "PASS" : "FAIL"}  ${namn}${detalj ? " — " + detalj : ""}`);
}

/* Rider `cykler` hela cykler med cykeltiden `Tc` vid `fps`; ger slagens
   tider på ljudklockan. `byt` kan byta gångart mitt i. */
function rid(gangart, fattning, Tc, fps, cykler, extra = {}) {
  const { X, ljudctx, starter } = byggKontext();
  const dt = 1 / fps;
  let fas = 0.013;                                   // inte på ett slag, inte på en bildrutegräns
  X.ljudRittSteg(fas, gangart, "fiber", fattning, dt);          // seed
  const n = Math.round(cykler * Tc * fps);
  const perRuta = [];
  for (let i = 0; i < n; i++) {
    ljudctx.currentTime += dt;
    if (!extra.stilla) fas = (fas + dt / Tc) % 1;
    let g = gangart, f = fattning;
    if (extra.bytVid !== undefined && i >= extra.bytVid) { g = extra.bytTill; f = extra.bytFattning || null; }
    const fore = starter.length;
    X.ljudRittSteg(fas, g, "fiber", f, dt);
    perRuta.push(starter.length - fore);
  }
  return { tider: starter.slice(), perRuta };
}
const mellanrum = (t, Tc) => t.slice(1).map((v, i) => (v - t[i]) / Tc);
/* Jämför en följd av mellanrum mot ett cykliskt facit, var det än börjar. */
function foljer(m, facit, tol) {
  for (let s = 0; s < facit.length; s++)
    if (m.every((v, i) => Math.abs(v - facit[(i + s) % facit.length]) < tol)) return true;
  return false;
}

const FACIT = [
  ["skritt", null, 1.11, [0.25, 0.25, 0.25, 0.25], "fyra jämna slag"],
  ["trav", null, 0.69, [0.5, 0.5], "två jämna slag"],
  ["galopp", "hoger", 0.625, [0.25, 0.25, 0.5], "tre slag och en paus"],
  ["galopp", "vanster", 0.625, [0.25, 0.25, 0.5], "tre slag och en paus"],
];
for (const [gangart, fattning, Tc, facit, ord] of FACIT) {
  const etikett = gangart + (fattning ? " " + fattning : "");
  let storstFel = 0, antalOk = true, text = [];
  for (const fps of [30, 60, 120]) {
    const r = rid(gangart, fattning, Tc, fps, 8);
    const m = mellanrum(r.tider, Tc);
    const perCykel = r.tider.length / 8;
    if (Math.abs(perCykel - facit.length) > 0.2) antalOk = false;
    /* Avvikelsen mot facit i SEKUNDER — det är den som hörs. */
    let basta = Infinity;
    for (let s = 0; s < facit.length; s++)
      basta = Math.min(basta, Math.max(...m.map((v, i) => Math.abs(v - facit[(i + s) % facit.length]) * Tc)));
    storstFel = Math.max(storstFel, basta);
    text.push(`${fps} b/s: ${r.tider.length} slag, fel ${(basta * 1000).toFixed(2)} ms`);
  }
  prova(`${etikett}: ${ord} per cykel`, antalOk, text.join(" · "));
  prova(`${etikett}: slagen ligger rätt på ljudklockan vid 30, 60 och 120 bilder/s (under 1 ms fel)`,
    storstFel < 0.001, `största fel ${(storstFel * 1000).toFixed(3)} ms`);
}
{
  const r = rid("trav", null, 0.69, 60, 3, { stilla: true });
  prova("står hon still hörs inga hovslag", r.tider.length === 0, `${r.tider.length} slag`);
  const h = rid("halt", null, 0.69, 60, 3);
  prova("halt (och språng) är tyst", h.tider.length === 0, `${h.tider.length} slag`);
}
{
  /* Taktbytet får inte ge ett extra slag: i bildrutan där raden byts
     seedas läget om utan att slå. */
  const r = rid("trav", null, 0.69, 60, 4, { bytVid: 77, bytTill: "galopp", bytFattning: "hoger" });
  prova("gångartsbytet ger inget extra slag i bytesbildrutan", r.perRuta[77] === 0, `${r.perRuta[77]} slag`);
  prova("aldrig mer än ett slag i samma bildruta vid 60 bilder/s", Math.max(...r.perRuta) <= 1,
    `mest ${Math.max(...r.perRuta)}`);
}
{
  /* En lång bildruta (5 bilder/s) tappar inga slag: de räknas i ordning. */
  const r = rid("galopp", "hoger", 0.625, 5, 8);
  prova("låg bildfrekvens tappar inga slag (galopp vid 5 bilder/s)", Math.abs(r.tider.length / 8 - 3) < 0.4,
    `${r.tider.length} slag på 8 cykler`);
  const { X } = byggKontext();
  const p = X.gangPasserade(X.GANGFAS.skritt, 0.25, 0.5);
  prova("ett slag exakt på en bildrutegräns hörs EN gång (från räknas inte, till gör det)",
    p.length === 1 && p[0].fas === 0.5, JSON.stringify(p.map((v) => v.fas)));
  prova("en orimlig lucka ger ingen ljudsalva (tak på sex slag)", X.gangPasserade(X.GANGFAS.skritt, 0, 50).length === 6);
}

console.log(fel === 0 ? `ljudtakttest: alla ${antal} gröna — hovslagen följer gångartens takt`
  : `ljudtakttest: ${fel} av ${antal} RÖDA`);
process.exit(fel === 0 ? 0 : 1);
