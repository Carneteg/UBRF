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
     --muter-takt     flyttar galoppens tredje slag i en KOPIA av tabellen
     --muter-klocka   spelar slagen "nu" i stället för på ljudklockan
     --muter-vack     väcker ljudet bara på pointerdown/keydown, som förut
     --muter-avbrott  återupptar bara `suspended`, inte iOS `interrupted`
     --muter-ton      låter ljudTon vara en brusstöt igen

     --muter-yta      låter alla underlag låta som grus igen
     --muter-senare   låter FÖRSTA markytan vinna i stället för den senaste
     --muter-puls     knyter engångsljuden till brusbädden igen
     --muter-kalla    låter stallet fnysa utan häst

     --muter-rum      stänger efterklangens sändning i varje rum
     --muter-pan      vänder höger och vänster
     --muter-ui       skickar gränssnittets toner genom rummet

   Sedan ljud-grind 0.7 (F2) mäter provet också upplåsningen på telefon,
   återupptagandet efter ett avbrott och att gränssnittets toner är toner.
   Sedan 0.8 (F3) också att underlaget under spelaren läses ur markdatan,
   att varje underlag har sin egen klang och att engångsljuden går att nå.
   Sedan 0.9 (F4) också rummet: vilken efterklang som väljs var, att varje
   ljud går genom den, och att höger är höger.

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

function byggKontext(arg) {
  let fasKod = las("src/riding/gangfas.js"), ljudKod = las("src/ljud.js");
  if (ARG.has("--muter-takt"))
    fasKod = mutera(fasKod, "RF: ben(0.50, 0.25) }", "RF: ben(0.66, 0.25) }", "galoppens tredje slag");
  if (ARG.has("--muter-klocka"))
    ljudKod = mutera(ljudKod, "nu+ruta*(sl.lage-fran)/steg", "nu", "ljudklockan");
  if (ARG.has("--muter-vack"))
    ljudKod = mutera(ljudKod, 'for(const typ of ["pointerdown","pointerup","touchend","click"])', 'for(const typ of ["pointerdown"])', "upplåsningens gester");
  if (ARG.has("--muter-avbrott"))
    ljudKod = mutera(ljudKod, 'c.state!=="running"&&c.state!=="closed"', 'c.state==="suspended"', "återupptagandet");
  if (ARG.has("--muter-ton"))
    ljudKod = mutera(ljudKod, 'const o=c.createOscillator();o.type="sine";\n  o.frequency.setValueAtTime(freq,t);\n  const g=c.createGain();\n  g.gain.setValueAtTime(0.0001,t);',
      'ljudStot(freq,"sine",tid,vol);return;\n  const o=c.createOscillator();o.type="sine";\n  o.frequency.setValueAtTime(freq,t);\n  const g=c.createGain();\n  g.gain.setValueAtTime(0.0001,t);', "ljudTon");
  if (ARG.has("--muter-yta")) {
    ljudKod = mutera(ljudKod, "const y=LJUD_YTA[underlag]||LJUD_YTA.okand;", "const y=LJUD_YTA.grus;", "hovens underlag");
    ljudKod = mutera(ljudKod, "const f=(LJUD_YTA[underlag]||LJUD_YTA.okand).fot;", "const f=LJUD_YTA.grus.fot;", "fotstegens underlag");
  }
  if (ARG.has("--muter-puls"))
    ljudKod = mutera(ljudKod, "if(!LJUD.pa||!plats)return;", "if(!LJUD.pa||!typ)return;", "engångsljudens villkor");
  if (ARG.has("--muter-kalla"))
    ljudKod = mutera(ljudKod, 'if(plats==="stall"&&hastar>0){', 'if(plats==="stall"){', "stalljudens källa");
  if (ARG.has("--muter-rum"))
    ljudKod = mutera(ljudKod, "mal=n===namn?LJUD_RUM[n].sand:0;", "mal=0;", "rummets sändning");
  if (ARG.has("--muter-pan"))
    ljudKod = mutera(ljudKod, "const hoger=(dx*Math.sin(rikt)-dy*Math.cos(rikt))", "const hoger=-(dx*Math.sin(rikt)-dy*Math.cos(rikt))", "panoreringens tecken");
  if (ARG.has("--muter-ui"))
    ljudKod = mutera(ljudKod, "o.connect(g);g.connect(LJUD.torr);", "o.connect(g);ljudUt(g);", "tonernas väg");
  const starter = [];
  const param = () => ({ value: 0, setValueAtTime() {}, exponentialRampToValueAtTime() {}, linearRampToValueAtTime() {} });
  /* Varje koppling sparas: provet läser ljudgrafen, inte bara att något
     skapades. */
  const kanter = [];
  const nod = (typ) => { const n = { typ: typ || "", start() {}, stop() {}, frequency: param(), gain: param(), Q: param(),
    playbackRate: param(), pan: param(), buffer: null, type: "" };
    n.gain.value = 1; n.connect = (m) => { kanter.push([n, m]); }; return n; };
  const ljudctx = { currentTime: 0, state: "running",
    createOscillator() { const n = nod(); n.start = (t) => starter.push(t); return n; },
    createGain: nod, createBiquadFilter: nod, createBufferSource: nod };
  /* Lyssnarna sparas, så att provet kan fyra de gester en telefon ger.
     AudioContext är en attrapp som räknar hur många som skapas och hur
     ofta de ombeds fortsätta. */
  const lyss = {}, dlyss = {}, logg = { skapade: 0, resume: 0, noder: [], kanter, eko: 0, panorer: [], utanPanorer: !!(arg && arg.utanPanorer) };
  const dokument = { visibilityState: "visible", addEventListener: (t, f) => { (dlyss[t] ??= []).push(f); } };
  class AC {
    constructor() { logg.skapade++; this.state = "suspended"; this.currentTime = 0; this.sampleRate = 50; this.destination = {}; }
    resume() { logg.resume++; this.state = "running"; return Promise.resolve(); }
    createGain() { logg.noder.push("gain"); return nod("gain"); }
    createBiquadFilter() { logg.noder.push("filter"); return nod("filter"); }
    createBufferSource() { logg.noder.push("brus"); return nod("brus"); }
    createOscillator() { const n = nod("osc"); logg.noder.push(n); return n; }
    createConvolver() { logg.eko++; return nod("eko"); }
    createBuffer(k, n) { const d = [new Float32Array(n), new Float32Array(n)]; return { length: n, getChannelData: (i) => d[i] }; }
  }
  /* Äldre Safari saknar StereoPannerNode. */
  if (!(arg && arg.utanPanorer))
    AC.prototype.createStereoPanner = function () { const n = nod("pan"); logg.panorer.push(n); return n; };
  /* setTimeout körs direkt: fördröjda delar av ett ljud (fnysets andra
     stöt) ska räknas, inte bli hängande efter provets slut. */
  const ctx = { console, Math, Float32Array, Promise, window: { AudioContext: AC }, setTimeout: (f) => { f(); return 0; },
    addEventListener: (t, f) => { (lyss[t] ??= []).push(f); }, document: dokument };
  vm.createContext(ctx);
  vm.runInContext(fasKod + "\n" + ljudKod + "\nthis.X={LJUD,LJUD_YTA,LJUD_RUM,ljudRittSteg,ljudTon,ljudHov,ljudFotsteg,ljudPuls,ljudRumFor,ljudPlacera,ljudGnagg,gangSlag,gangPasserade,GANGFAS};", ctx);
  const fyra = (t) => { for (const f of lyss[t] || []) f({}); };
  const fyraDok = (t) => { for (const f of dlyss[t] || []) f({}); };
  const telefon = { X: ctx.X, lyss, dlyss, logg, dokument, fyra, fyraDok, ctx };
  if (arg && arg.ravakt) return telefon;
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

/* ── Upplåsning, avbrott och toner (ljud-grind 0.7, F2) ───────────── */
{
  const T = byggKontext({ ravakt: true });
  prova("ljudet väcks av de gester en telefon ger: touchend, pointerup och click (och keydown)",
    ["touchend", "pointerup", "click", "keydown"].every((t) => (T.lyss[t] || []).length > 0),
    Object.keys(T.lyss).sort().join(", "));
  T.fyraDok("visibilitychange"); T.fyra("pageshow");
  prova("en sida som aldrig rörts börjar inte låta för att den blev synlig", T.X.LJUD.ctx === null && T.logg.skapade === 0,
    `${T.logg.skapade} ljudkontexter`);
  T.fyra("touchend");
  prova("första fingertrycket skapar ljudkontexten och ber den starta",
    T.logg.skapade === 1 && T.logg.resume === 1 && T.X.LJUD.ctx.state === "running",
    `${T.logg.skapade} kontext, ${T.logg.resume} resume`);
  T.fyra("click"); T.fyra("pointerup"); T.fyra("pointerdown"); T.fyra("keydown");
  prova("EN ljudkontext, hur många gester som än kommer", T.logg.skapade === 1, `${T.logg.skapade} skapade`);
  /* iOS: ett samtal eller ett låst lås ställer kontexten i `interrupted`. */
  T.X.LJUD.ctx.state = "interrupted";
  const fore = T.logg.resume;
  T.dokument.visibilityState = "hidden"; T.fyraDok("visibilitychange");
  const iBakgrunden = T.logg.resume - fore;
  T.dokument.visibilityState = "visible"; T.fyraDok("visibilitychange");
  prova("efter ett avbrott (iOS «interrupted») återupptas ljudet när sidan syns igen — inte i bakgrunden",
    iBakgrunden === 0 && T.logg.resume === fore + 1 && T.X.LJUD.ctx.state === "running",
    `i bakgrunden ${iBakgrunden}, synlig ${T.logg.resume - fore}`);
  T.X.LJUD.ctx.state = "suspended";
  T.fyra("pageshow");
  prova("en sida hämtad ur bakåt-cachen (pageshow) återupptar också", T.logg.resume === fore + 2);

  /* Tonerna: en ren sinus på rätt frekvens, inget brus. */
  T.X.LJUD.pa = true;
  T.logg.noder.length = 0;
  let frekvens = null;
  const orig = T.X.LJUD.ctx.createOscillator.bind(T.X.LJUD.ctx);
  T.X.LJUD.ctx.createOscillator = () => { const n = orig(); n.frequency.setValueAtTime = (f) => { frekvens = f; }; return n; };
  T.X.ljudTon(700, 0.10, 0.05);
  const osc = T.logg.noder.find((n) => typeof n === "object");
  prova("ljudTon är en ren sinuston på begärd frekvens, utan brus",
    !!osc && osc.type === "sine" && frekvens === 700 && !T.logg.noder.includes("brus") && !T.logg.noder.includes("filter"),
    `vågform ${osc && osc.type}, ${frekvens} Hz, noder: ${T.logg.noder.map((n) => (typeof n === "object" ? "oscillator" : n)).join("+")}`);
  /* Inget anrop i spelet får skicka en vågform som filtertyp igen. */
  const syndare = [];
  for (const f of fs.readdirSync(path.join(ROT, "src"), { recursive: true })) {
    if (!String(f).endsWith(".js")) continue;
    const kod = las(path.join("src", String(f)));
    for (const m of kod.matchAll(/ljudStot\([^)]*"(sine|square|sawtooth|triangle)"/g)) syndare.push(`${f}: ${m[0]}`);
  }
  prova("ingen ljudStot får en vågform som filtertyp (det var så tonerna blev brus)", syndare.length === 0,
    syndare.length ? syndare.join(" · ") : "0 träffar i src/");
}

/* ── Underlaget och engångsljuden (ljud-grind 0.8, F3) ────────────── */
{
  /* Markdatan läses som exportören gör det: model.js, data.js, site.js. */
  let siteKod = las("src/site.js");
  if (ARG.has("--muter-senare"))
    siteKod = mutera(siteKod, "if(r&&x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h)typ=m.typ;",
      "if(r&&x>=r.x&&x<=r.x+r.w&&y>=r.y&&y<=r.y+r.h){typ=m.typ;break;}", "markytornas ordning");
  const sc = { console, Math, JSON, window: {} };
  vm.createContext(sc);
  vm.runInContext(las("src/model.js") + "\n" + las("src/data.js") + "\n" + siteKod + "\n" + las("src/inredning.js")
    + "\nthis.S={ytaVid,ytaForRitt,ANL,STALLINNE,RIDHUSINNE};", sc);
  const { ytaVid, ytaForRitt, ANL, STALLINNE: ST, RIDHUSINNE: RH } = sc.S;

  /* FACIT ur kommentarerna i ANL.mark och ur INTERIOR-MATRIS, inte ur
     uppslagets egen kod. */
  const gA = (ST.gangar.A.x0 + ST.gangar.A.x1) / 2, boxX = ST.rader[0].x0 + ST.rader[0].djup / 2;
  const punkter = [
    ["gard", 120, 130, 0, "grus", "grusplanen vid norra gavlarna"],
    ["gard", 4, 80, 0, "asfalt", "Enköpingsvägen"],
    ["gard", 50, 60, 0, "aker", "åkrarna"],
    ["gard", 4, 148, 0, "grus", "Björklidsvägen korsar asfalten — den senare ytan vinner"],
    ["gard", 100, 131, 0, "sand", "lekhagen (rund yta)"],
    ["gard", 172, 102, 0, "betong", "betongplattan vid uppgången"],
    ["gard", -60, -60, 0, "gras", "omgivningen"],
    ["stallinne", gA, 30, 0, "gatsten", "markstenen i gång A"],
    ["stallinne", boxX, 30, 0, "span", "inne i en box"],
    ["stallinne", gA, ST.klubb.y0 + 2, 0, "betong", "klubbdelen"],
    ["stallinne", 1.0, 3, 0, "betong", "servicedelen, remsan längs ytterväggen"],
    ["stallinne", 10, 3, 0, "gatsten", "servicedelens genomgångsstråk"],
    ["stallinne", gA, ST.klubbY + 1, 0, "gatsten", "tvärkorridoren, markstensstråket"],
    ["stallinne", boxX, ST.klubbY + 1, 0, "betong", "tvärkorridoren, bredvid stråket"],
    ["ridhusinne", RH.bana.x + 10, RH.bana.y + 30, 0, "fiber", "ridbanan"],
    ["ridhusinne", RH.bana.x + 10, RH.bana.y + 30, 2.5, "okand", "ovanför marknivå (läktaren): inget belagt"],
    ["ridhusinne", RH.bana.x + RH.bana.w + 2, RH.bana.y + 30, 0, "okand", "utanför sargen: inget belagt"],
  ];
  const felaktiga = punkter.filter(([scen, x, y, z, vill]) => ytaVid(scen, x, y, z) !== vill)
    .map(([scen, x, y, z, vill, vad]) => `${vad}: ${ytaVid(scen, x, y, z)} (ska vara ${vill})`);
  prova(`underlaget läses ur markdatan på ${punkter.length} kända punkter (gård, stall, ridhus)`,
    felaktiga.length === 0, felaktiga.length ? felaktiga.join(" · ") : "alla rätt");
  prova("ritten: ridhuset är fiber, uteridbanan sand, skogsstigen obelagd",
    ytaForRitt("ridhus") === "fiber" && ytaForRitt("utebana") === "sand" && ytaForRitt("stig") === "okand");

  const T = byggKontext({ ravakt: true });
  /* Väcks på båda sätten, så att den här delen inte faller på upplåsningen
     (den mäts för sig ovan). */
  T.fyra("pointerdown"); T.fyra("touchend"); T.X.LJUD.pa = true;
  /* Varje ytnyckel som datan kan ge ska ha en klang. */
  const nycklar = new Set(["gatsten", "span", "betong", "fiber", "okand", "sand"]);
  for (const m of ANL.mark) nycklar.add(m.typ);
  for (const c of ANL.cirklar || []) nycklar.add(c.typ);
  const utan = [...nycklar].filter((k) => !(T.X.LJUD_YTA[k] && T.X.LJUD_YTA[k].hov && T.X.LJUD_YTA[k].fot));
  prova(`varje underlag i datan har en klang (${nycklar.size} nycklar)`, utan.length === 0,
    utan.length ? "saknas: " + utan.join(", ") : [...nycklar].sort().join(", "));

  /* Klangen läses ur det som faktiskt skickas till ljudgrafen. */
  const c = T.X.LJUD.ctx;
  const klang = (fn) => {
    const ut = { osc: [], filter: [] };
    const o0 = c.createOscillator.bind(c), f0 = c.createBiquadFilter.bind(c);
    c.createOscillator = () => { const n = o0(); n.frequency.setValueAtTime = (f) => { ut.osc.push(f); }; return n; };
    c.createBiquadFilter = () => { const n = f0(); ut.filter.push(n); return n; };
    fn();
    c.createOscillator = o0; c.createBiquadFilter = f0;
    return { osc: ut.osc, filter: ut.filter.map((n) => `${n.type}:${n.frequency.value}`) };
  };
  const steg = (yta) => klang(() => { T.X.LJUD.gangAvstand = 0; T.X.ljudFotsteg(1, yta); }).filter.join("|");
  const hov = (yta, vat) => klang(() => T.X.ljudHov(yta, false, undefined, vat));
  const olika = new Set(["gras", "grus", "asfalt", "sand", "gatsten", "span"].map(steg));
  prova("fotsteg: sex underlag ger sex olika klanger, och samma underlag samma klang",
    olika.size === 6 && steg("grus") === steg("grus"), [...olika].join("  "));
  prova("det som lät förut låter likadant: grusets och stallgångens fotsteg, fiberns och grusets hovslag",
    steg("grus") === "lowpass:500" && steg("gatsten") === "bandpass:1400" && steg("okand") === steg("grus") &&
    hov("fiber").osc[0] === 95 && hov("fiber").filter[0] === "lowpass:300" && hov("grus").osc[0] === 110,
    `grus ${steg("grus")} · stallgång ${steg("gatsten")} · fiber ${hov("fiber").osc[0]} Hz · grus ${hov("grus").osc[0]} Hz`);
  prova("hovslag: sand låter inte som grus, och asfalt inte som gräs",
    hov("sand").filter[0] !== hov("grus").filter[0] && hov("asfalt").filter[0] !== hov("gras").filter[0],
    `sand ${hov("sand").filter[0]} · grus ${hov("grus").filter[0]} · asfalt ${hov("asfalt").filter[0]} · gräs ${hov("gras").filter[0]}`);
  prova("regn: vått grus låter som förut, våt sand behåller sandens klang under plasket, och ridhuset är torrt",
    hov("grus", true).osc[0] === 75 && hov("sand", true).osc[0] === hov("sand").osc[0] &&
    hov("sand", true).filter.length === hov("sand").filter.length + 1 &&
    hov("fiber", true).filter.length === hov("fiber").filter.length,
    `vått grus ${hov("grus", true).osc[0]} Hz · våt sand ${hov("sand", true).filter.join("+")}`);

  /* Engångsljuden, med brusbädden AV (som i spelet). */
  const handelser = (G, varld, sek = 300) => {
    const P = byggKontext({ ravakt: true });
    P.fyra("pointerdown"); P.fyra("touchend"); P.X.LJUD.pa = true;
    Object.assign(P.ctx, { G, ...varld });
    P.logg.noder.length = 0;
    for (let i = 0; i < sek * 10; i++) P.X.ljudPuls(0.1);
    return { n: P.logg.noder.length, ambiens: P.X.LJUD.ambiens };
  };
  const boxHast = (id) => (id ? {} : null);
  const fullt = handelser({ scen: "stallinne" }, { STALLINNE: { boxar: { W: ["a", null, "b"] } }, boxHast });
  const tomt = handelser({ scen: "stallinne" }, { STALLINNE: { boxar: { W: [null, null] } }, boxHast });
  prova("stallet: med brusbädden AV hörs hästarna — när det står en häst i en box",
    fullt.ambiens === false && fullt.n > 0, `${fullt.n} ljudnoder på 300 s, brusbädd ${fullt.ambiens ? "PÅ" : "av"}`);
  prova("stallet: ett tomt stall fnyser inte (inget ljud utan synlig källa)", tomt.n === 0, `${tomt.n} ljudnoder`);
  const gardSol = handelser({ scen: "gard", vader: { typ: "sol" } }, { ANL: { hagar: [] } });
  const gardRegn = handelser({ scen: "gard", vader: { typ: "regn" } }, { ANL: { hagar: [] } });
  const gardHast = handelser({ scen: "gard", vader: { typ: "regn" } }, { ANL: { hagar: [{ hastar: ["a"] }] } });
  prova("gården: fågeln hörs i uppehåll men inte i regn, och gnägget kräver en häst i en hage",
    gardSol.n > 0 && gardRegn.n === 0 && gardHast.n > 0,
    `uppehåll ${gardSol.n} · regn utan hästar ${gardRegn.n} · regn med häst i hage ${gardHast.n}`);
  const hall = handelser({ scen: "ridhusinne" }, { STALLINNE: { boxar: { W: ["a"] } }, boxHast });
  prova("ridhusets inre har inga engångsljud (där står inga hästar som inte rids)", hall.n === 0, `${hall.n} ljudnoder`);
}

/* ── Rummet (ljud-grind 0.9, F4) ──────────────────────────────────── */
{
  const ny = (arg) => { const P = byggKontext({ ravakt: true, ...(arg || {}) });
    P.fyra("pointerdown"); P.fyra("touchend"); P.X.LJUD.pa = true; return P; };
  const T = ny();
  const L = T.X.LJUD;
  /* FACIT: var man är avgör rummet, inte koden. */
  const rumFacit = [["stallinne", null, "stall"], ["ridhusinne", null, "hall"], ["lektion", "ridhus", "hall"],
    ["bana", "ridhus", "hall"], ["lektion", "utebana", null], ["lektion", "stig", null], ["gard", null, null]];
  const felRum = rumFacit.filter(([s, p, vill]) => T.X.ljudRumFor(s, p) !== vill).map(([s, p]) => `${s}/${p}`);
  prova("rummet följer platsen: stallet, ridhuset (till fots och till häst) och torrt utomhus",
    felRum.length === 0, felRum.length ? "fel: " + felRum.join(", ") : `${rumFacit.length} platser`);

  const sandning = (G) => { Object.assign(T.ctx, { G }); T.X.ljudPuls(0.1);
    return Object.fromEntries(Object.entries(L.rumNod).map(([n, v]) => [n, v.sand.gain.value])); };
  const iStall = sandning({ scen: "stallinne" }), iHall = sandning({ scen: "lektion", plats: "ridhus" }),
    ute = sandning({ scen: "gard" });
  prova("efterklangen: bara det rum hon är i är öppet, och ute är helt torrt",
    iStall.stall > 0 && iStall.hall === 0 && iHall.hall > 0 && iHall.stall === 0 && ute.hall === 0 && ute.stall === 0,
    `stall ${JSON.stringify(iStall)} · ridhus ${JSON.stringify(iHall)} · gård ${JSON.stringify(ute)}`);
  const lHall = L.rumNod.hall.eko.buffer.length, lStall = L.rumNod.stall.eko.buffer.length;
  let energi = 0; for (const v of L.rumNod.hall.eko.buffer.getChannelData(0)) energi += v * v;
  prova("hallen klingar längre än stallet, och impulserna är inte tomma",
    lHall > lStall * 2 && lStall > 0 && energi > 0, `hall ${lHall} sampel · stall ${lStall} sampel`);

  /* Ljudgrafen: vart går ett ljud? */
  const mal = (n) => T.logg.kanter.filter(([a]) => a === n).map(([, b]) => b);
  const sista = (typ) => [...new Set(T.logg.kanter.map(([a]) => a))].filter((n) => n.typ === typ).pop();
  const sandNoder = Object.values(L.rumNod).map((v) => v.sand);
  T.logg.kanter.length = 0; T.logg.panorer.length = 0;
  L.kalla = null; T.X.ljudHov("fiber", false);
  const hovUt = T.logg.kanter.filter(([, b]) => b === L.torr).map(([a]) => a);
  prova("egna hovslag går torrt OCH till rummet, och ligger i mitten",
    hovUt.length > 0 && hovUt.every((n) => sandNoder.every((sn) => mal(n).includes(sn))) && T.logg.panorer.length === 0,
    `${hovUt.length} källor till den torra bussen, ${T.logg.panorer.length} panorerare`);
  T.logg.kanter.length = 0;
  L.kalla = { pan: 0.6, styrka: 0.4 }; T.X.ljudGnagg(); L.kalla = null;
  const p = T.logg.panorer[0];
  prova("ett ljud med en källa panoreras och dämpas, och går också genom rummet",
    !!p && Math.abs(p.pan.value - 0.6) < 1e-9 && mal(p).includes(L.torr) && sandNoder.every((sn) => mal(p).includes(sn)) &&
    T.logg.kanter.some(([a, b]) => b === p && Math.abs(a.gain.value - 0.4) < 1e-9),
    p ? `pan ${p.pan.value}, styrka in ${T.logg.kanter.find(([, b]) => b === p)[0].gain.value}` : "ingen panorerare");
  T.logg.kanter.length = 0;
  T.X.ljudTon(700, 0.1, 0.05);
  const tonUt = T.logg.kanter.filter(([a]) => a.typ === "gain").flatMap(([, b]) => [b]);
  prova("gränssnittets toner är torra: en knapp ekar inte",
    tonUt.includes(L.torr) && !tonUt.some((b) => sandNoder.includes(b)),
    `${tonUt.length} koppling(ar), varav till rummet ${tonUt.filter((b) => sandNoder.includes(b)).length}`);

  /* Höger är höger — åt fyra blickriktningar. Kartans regel: öster (+x)
     ligger till höger när man ser norrut (+y). */
  const N = Math.PI / 2;
  const hogerFall = [[N, 5, 0, "ser norrut, källan i öster"], [0, 0, -5, "ser österut, källan i söder"],
    [-N, -5, 0, "ser söderut, källan i väster"], [Math.PI, 0, 5, "ser västerut, källan i norr"]];
  const felPan = hogerFall.filter(([r, x, y]) => !(T.X.ljudPlacera(0, 0, r, x, y).pan > 0.3 && T.X.ljudPlacera(0, 0, r, -x, -y).pan < -0.3))
    .map(([, , , vad]) => vad);
  prova("panoreringen: en källa till höger hörs till höger och en till vänster till vänster, åt fyra håll",
    felPan.length === 0 && Math.abs(T.X.ljudPlacera(0, 0, N, 0, 8).pan) < 1e-9,
    felPan.length ? "fel: " + felPan.join(" · ") : `rakt fram ${T.X.ljudPlacera(0, 0, N, 0, 8).pan.toFixed(3)}`);
  const st = [2, 8, 30, 300].map((d) => T.X.ljudPlacera(0, 0, N, d, 0).styrka);
  prova("avståndet: längre bort är svagare, aldrig helt tyst, och nära inpå dras ljudet mot mitten",
    st[0] > st[1] && st[1] > st[2] && st[2] >= st[3] && st[3] >= 0.15 &&
    T.X.ljudPlacera(0, 0, N, 0.3, 0).pan < T.X.ljudPlacera(0, 0, N, 5, 0).pan,
    `styrka vid 2/8/30/300 m: ${st.map((v) => v.toFixed(2)).join(" / ")}`);

  /* Efter fem minuter i stallet: fortfarande en kontext och två ekon. */
  Object.assign(T.ctx, { G: { scen: "stallinne" }, STALLINNE: { boxar: { W: ["a", "b"] }, rader: [{ id: "W", x0: 0, djup: 4 }], boxStartY: 6.8, boxB: 3.5 },
    boxHast: (id) => (id ? {} : null), VD: { px: 8, py: 20, rikt: N } });
  T.logg.panorer.length = 0;
  for (let i = 0; i < 3000; i++) T.X.ljudPuls(0.1);
  prova("efterklangen byggs EN gång: en ljudkontext och ett eko per rum efter fem minuter i stallet",
    T.logg.skapade === 1 && T.logg.eko === Object.keys(T.X.LJUD_RUM).length, `${T.logg.skapade} kontext, ${T.logg.eko} ekon`);
  /* Boxraden W ligger väster om gången (x 0–4, hon står på x 8) och hon
     ser norrut: hästarna ska höras till VÄNSTER. */
  prova("stallets hästar hörs från sina boxar: väster om en lyssnare som ser norrut är till vänster",
    T.logg.panorer.length > 0 && T.logg.panorer.every((n) => n.pan.value < 0),
    `${T.logg.panorer.length} placerade ljud, pan ${Math.min(...T.logg.panorer.map((n) => n.pan.value)).toFixed(2)}…${Math.max(...T.logg.panorer.map((n) => n.pan.value)).toFixed(2)}`);

  /* Äldre Safari utan StereoPannerNode: ljudet spelas ändå. */
  const U = ny({ utanPanorer: true });
  U.logg.kanter.length = 0;
  U.X.LJUD.kalla = { pan: 0.6, styrka: 0.4 }; U.X.ljudGnagg(); U.X.LJUD.kalla = null;
  prova("utan StereoPannerNode spelas ljudet ändå, opanorerat men dämpat",
    U.logg.kanter.some(([a, b]) => b === U.X.LJUD.torr && Math.abs(a.gain.value - 0.4) < 1e-9));
  /* Strömbrytaren. */
  const A = ny(); A.X.LJUD.rum = false;
  Object.assign(A.ctx, { G: { scen: "stallinne" } }); A.X.ljudPuls(0.1);
  A.logg.kanter.length = 0; A.X.ljudHov("fiber", false);
  const aSand = Object.values(A.X.LJUD.rumNod).map((v) => v.sand);
  prova("strömbrytaren LJUD.rum stänger efterklangen helt (allt torrt, som förut)",
    aSand.every((sn) => sn.gain.value === 0) && !A.logg.kanter.some(([, b]) => aSand.includes(b)));

  /* Ingen ljudkälla får kopplas förbi rummet. */
  const direkt = las("src/ljud.js").split("\n").filter((r) => r.includes("connect(LJUD.master)")).map((r) => r.trim());
  prova("ingen ljudkälla kopplas rakt till huvudvolymen — bara bussarna gör det",
    direkt.length === 3 && direkt.every((r) => /ambGain|torr|eko/.test(r)), direkt.join(" | "));
}

console.log(fel === 0 ? `ljudtakttest: alla ${antal} gröna — hovslagen följer gångartens takt`
  : `ljudtakttest: ${fel} av ${antal} RÖDA`);
process.exit(fel === 0 ? 0 : 1);
