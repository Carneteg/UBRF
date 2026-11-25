#!/usr/bin/env node
/* ══════════════════════════════════════════════════════════════════
   GÅNGPOSETESTET — går hästen i en riktig gångart?

   Rörelse-grind 0.4 (C1–C3, se docs/ACTIVE-GATE.md). Webbens häst hade
   en egen benföljdstabell, och den var inte förenklad utan fel: skritten
   satte i vf → hb → vb → hf, galoppen slog i fel ordning utan sväv och
   utan fattning, lättridningen reste sig två gånger per steg och
   språnget tippade nosen i backen i avstampet.

   ── VAD SOM MÄTS, OCH MOT VAD ──────────────────────────────────────

   Provet läser PRODUKTIONSKÄLLAN (src/riding/gangfas.js, src/gl.js,
   src/scen3d.js) i en vm-kontext och kör de riktiga funktionerna. Där
   en bild avgör — var hoven, stöveln och huvudet faktiskt hamnar —
   fångas matriserna ur den riktiga ritvägen: `GL.rita` byts mot en
   attrapp som sparar varje nät och dess matris, och `s3RitaHast` körs
   som i spelet.

   FACIT STÅR HÄR, INTE I TABELLEN. Benföljderna nedan är ridlärans
   (Svenska Ridsportförbundets dressyrbilaga, samma källa som tabellens
   huvud): skritt är fyrtakt i lateral följd, trav tvåtakt i diagonala
   par med svävmoment, galopp tretakt — yttre bakben, diagonalen, inre
   framben — med svävmoment. Provet räknar inte ut svaret ur GANGFAS och
   jämför sedan GANGFAS med sig själv.

   16 faser per cykel räcker för att skilja varje slag från nästa, och
   de finare måtten (ordning, sväv, uppresningar) mäts på 240 faser.

   ── FALSIFIERING ───────────────────────────────────────────────────

   Varje del måste kunna bli röd, annars mäter den ingenting:

     --muter-fas   byter två bens isättning i en KOPIA av tabellen
                   (källtexten i minnet, aldrig filen)
     --muter-latt  återinför `sin(4π·fas)` i lättridningen
     --muter-hopp  återinför `lut-=` i språnget

   Kör: node tools/gangposetest.mjs                 (exit 1 vid avvikelse)
        node tools/gangposetest.mjs --muter-fas     (måste bli röd) */
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
  let fasKod = las("src/riding/gangfas.js");
  let scenKod = las("src/scen3d.js");
  if (ARG.has("--muter-fas"))
    fasKod = mutera(fasKod,
      "LF: ben(0.25, 0.65), RH: ben(0.50, 0.65), RF: ben(0.75, 0.65)",
      "LF: ben(0.75, 0.65), RH: ben(0.50, 0.65), RF: ben(0.25, 0.65)", "skrittens benföljd");
  if (ARG.has("--muter-latt"))
    scenKod = mutera(scenKod,
      "LATTRIDNING.hojd_m*gangLattridning(GANGFAS.trav,o.fas||0,lattBen)",
      "LATTRIDNING.hojd_m*Math.max(0,Math.sin(4*Math.PI*o.fas))", "lättridningen");
  if (ARG.has("--muter-hopp"))
    scenKod = mutera(scenKod, "lut+=0.52*Math.cos(Math.PI*u);", "lut-=0.52*Math.cos(Math.PI*u);", "språngets lutning");
  const ctx = { console, Math, JSON, Float32Array, Uint8Array, Int32Array, window: {},
    clamp: (v, a, b) => (v < a ? a : v > b ? b : v) };
  vm.createContext(ctx);
  vm.runInContext(fasKod + "\n" + las("src/gl.js") + "\n" + scenKod + `
    /* Ritvägen fångas: varje nät blir sitt eget namn, och GL.rita sparar
       namn + matris i stället för att rita. */
    S3.del = new Proxy({}, { get: (_, k) => (k === "jag" ? null : { namn: String(k) }) });
    this.RITAT = [];
    GL.rita = (nat, mat) => { this.RITAT.push({ namn: nat && nat.namn, m: Array.from(mat) }); };
    this.X = { s3Ben, s3HastKropp, s3HastBas, s3HuvudLokal, s3HuvudPunkt, s3Sits, s3RitaHast,
      M4, GANGFAS, GANGBEN, gangBen, gangMonsterNamn, gangVarv, gangYttreFram, gangLattridning, LATTRIDNING };
  `, ctx);
  return ctx;
}

const ctx = byggKontext();
const X = ctx.X;
let fel = 0, antal = 0;
function prova(namn, ok, detalj) {
  antal++;
  if (!ok) fel++;
  console.log(`${ok ? "PASS" : "FAIL"}  ${namn}${detalj ? " — " + detalj : ""}`);
}

const HAST = { typ: "hast", farg: "#7A5230", man: "#2B1E15" };
const BEN = ["LF", "RF", "LH", "RH"];
/* Ett ekipage ritat genom produktionsvägen; ger tillbaka det som ritades. */
function rita(o) {
  ctx.RITAT.length = 0;
  X.s3RitaHast({ hast: HAST, x: 0, z: 0, rikt: 0, sadel: true, ...o });
  return ctx.RITAT.slice();
}
const natAv = (ritat, namn) => ritat.filter((r) => r.namn === namn);

/* ── 0. Vänster och höger — uppmätt, inte antaget ─────────────────── */
{
  /* Hon går NORRUT (rikt π/2: +y på kartan = världens Z). Kartans regel
     är öster (+x) till höger, alltså ska VÄNSTER sida ligga i −x. */
  const r = rita({ gangart: "halt", fas: 0, rikt: Math.PI / 2 });
  const hov = natAv(r, "hov");
  prova("fyra hovar ritas", hov.length === 4, `${hov.length} st`);
  prova("ben 0 och 2 (LF, LH) står på hästens VÄNSTRA sida",
    hov[0].m[12] < -0.05 && hov[2].m[12] < -0.05 && hov[1].m[12] > 0.05 && hov[3].m[12] > 0.05,
    `x: ${hov.map((h) => h.m[12].toFixed(2)).join(" ")} (norrut ⇒ vänster = −x)`);
  prova("ben 0 och 1 är FRAMBEN", hov[0].m[14] > hov[2].m[14] && hov[1].m[14] > hov[3].m[14],
    `z fram ${hov[0].m[14].toFixed(2)} mot bak ${hov[2].m[14].toFixed(2)}`);
}

/* ── 1. Benföljden ────────────────────────────────────────────────── */
/* Stöd eller sväng läses ur s3Ben som den ritas: i stödet förs benet
   BAKÅT (vinkeln minskar med fasen), i svängen förs det fram. */
const iStod = (gangart, fattning, i, fas) =>
  X.s3Ben(fas + 1e-4, gangart, i, fattning).t1 < X.s3Ben(fas, gangart, i, fattning).t1;
function isattningar(gangart, fattning) {
  /* Fasen där varje ben går från sväng till stöd, på 240 steg. */
  const N = 240, ut = {};
  for (let i = 0; i < 4; i++)
    for (let k = 0; k < N; k++) {
      const a = iStod(gangart, fattning, i, ((k - 1 + N) % N) / N + 1e-6);
      const b = iStod(gangart, fattning, i, k / N + 1e-6);
      if (!a && b) ut[BEN[i]] = k / N;
    }
  return ut;
}
function slagordning(td) {
  /* Skilda isättningar i fasordning; ben som slår samtidigt blir ETT slag. */
  const per = new Map();
  for (const [ben, f] of Object.entries(td)) {
    const k = f.toFixed(2);
    if (!per.has(k)) per.set(k, []);
    per.get(k).push(ben);
  }
  return [...per.entries()].sort((a, b) => a[0] - b[0]).map(([, b]) => b.sort().join("+"));
}
/* Ordningen jämförs som en RING: var cykeln börjar räknas är ett val. */
function sammaRing(a, b) {
  if (a.length !== b.length) return false;
  for (let s = 0; s < a.length; s++)
    if (a.every((v, i) => v === b[(i + s) % b.length])) return true;
  return false;
}
function barande(gangart, fattning, N = 16) {
  const ut = [];
  for (let k = 0; k < N; k++) {
    let n = 0;
    for (let i = 0; i < 4; i++) if (iStod(gangart, fattning, i, k / N + 1e-6)) n++;
    ut.push(n);
  }
  return ut;
}

{
  const ordn = slagordning(isattningar("skritt"));
  prova("skritt: fyra slag i lateral följd, vb → vf → hb → hf",
    sammaRing(ordn, ["LH", "LF", "RH", "RF"]), ordn.join(" → "));
  const b = barande("skritt");
  prova("skritt: aldrig färre än två bärande ben i någon av 16 faser, inget sväv",
    Math.min(...b) >= 2, b.join(""));
}
{
  const ordn = slagordning(isattningar("trav"));
  prova("trav: två slag, diagonala par (vb+hf, hb+vf)",
    sammaRing(ordn, ["LH+RF", "LF+RH"]), ordn.join(" → "));
  const b = barande("trav", null, 240);
  prova("trav: svävmoment mellan paren (faser utan bärande ben)",
    b.filter((n) => n === 0).length > 0 && Math.max(...b) === 2,
    `${b.filter((n) => n === 0).length} av 240 faser i sväv, mest ${Math.max(...b)} ben`);
}
for (const [fattning, facit, ledande] of [
  ["hoger", ["LH", "LF+RH", "RF"], "RF"],
  ["vanster", ["RH", "LH+RF", "LF"], "LF"],
]) {
  const td = isattningar("galopp", fattning);
  const ordn = slagordning(td);
  prova(`galopp ${fattning}: tre slag — yttre bakben, diagonalen, ledande framben (${ledande})`,
    sammaRing(ordn, facit), ordn.join(" → "));
  /* Svävet ska ligga EFTER det ledande frambenet och FÖRE yttre bakben. */
  const N = 240;
  let svavStart = null, svav = 0;
  for (let k = 0; k < N; k++) {
    let n = 0;
    for (let i = 0; i < 4; i++) if (iStod("galopp", fattning, i, k / N + 1e-6)) n++;
    if (n === 0) { svav++; if (svavStart === null) svavStart = k / N; }
  }
  const efterLedande = svavStart !== null && ((svavStart - td[ledande] + 1) % 1) < 0.5;
  prova(`galopp ${fattning}: svävmoment, och det kommer efter det ledande frambenet`,
    svav > 0 && efterLedande, `${svav} av 240 faser, börjar vid ${svavStart}`);
}
{
  /* Vänster fattning är höger fattning med sidorna bytta — i varje fas. */
  let storst = 0;
  const byt = [1, 0, 3, 2];
  for (let k = 0; k < 16; k++)
    for (let i = 0; i < 4; i++) {
      const a = X.s3Ben(k / 16, "galopp", i, "hoger"), b = X.s3Ben(k / 16, "galopp", byt[i], "vanster");
      storst = Math.max(storst, Math.abs(a.t1 - b.t1), Math.abs(a.t2 - b.t2));
    }
  prova("galopp: vänster fattning är spegelbilden av höger i alla 16 faser", storst < 1e-9,
    `största skillnad ${storst.toExponential(1)} rad`);
  const halt = [0, 1, 2, 3].map((i) => X.s3Ben(0.37, "halt", i).t2);
  prova("halt: alla fyra bär, ingen benföljd ritas", halt.every((t) => t < 0.1), halt.join(" "));
}

/* ── 2. Lättridningen ─────────────────────────────────────────────── */
{
  const aids = { sits: 0.5, tygel: 0.3, lattridning: true, diagonal: 1 };
  const N = 240;
  const hojd = [];
  for (let k = 0; k < N; k++) hojd.push(X.s3Sits({ gangart: "trav", fas: k / N, aids, varv: "hoger" }).latt);
  let uppresningar = 0;
  for (let k = 0; k < N; k++) if (hojd[(k - 1 + N) % N] <= 1e-9 && hojd[k] > 1e-9) uppresningar++;
  prova("lättridning: EN uppresning per travcykel", uppresningar === 1, `${uppresningar} st`);
  prova("lättridning: höjden är kanonens LATTRIDNING.hojd_m",
    Math.abs(Math.max(...hojd) - X.LATTRIDNING.hojd_m) < 0.002,
    `${Math.max(...hojd).toFixed(3)} m mot ${X.LATTRIDNING.hojd_m} m`);
  /* Höger varv: mitten till höger, alltså är VÄNSTER fram det yttre. Hon
     ska vara uppe när det benet förs fram och sitta när det bär. */
  let uppIStod = 0, uppISvang = 0;
  for (let k = 0; k < N; k++) {
    if (hojd[k] < 0.02) continue;
    if (iStod("trav", null, 0, k / N + 1e-6)) uppIStod++; else uppISvang++;
  }
  prova("lättridning: uppe medan YTTRE frambenet förs fram, sitter när det bär",
    uppISvang > 0 && uppIStod === 0, `uppe i sväng ${uppISvang} faser, uppe i stöd ${uppIStod}`);
  const fel0 = X.s3Sits({ gangart: "trav", fas: 0.7, aids: { ...aids, diagonal: 0 }, varv: "hoger" }).latt;
  const ratt0 = X.s3Sits({ gangart: "trav", fas: 0.7, aids, varv: "hoger" }).latt;
  prova("lättridning: fel diagonal (Q) syns — då reser hon sig med det inre frambenet",
    (fel0 > 0.02) !== (ratt0 > 0.02), `rätt ${ratt0.toFixed(3)} · fel ${fel0.toFixed(3)} vid fas 0,7`);
  /* Stöveln: mätt i ritvägen, mot sadeln som hänger på samma häst. */
  let lagst = Infinity, hogst = -Infinity, satLagst = Infinity, satHogst = -Infinity;
  for (let k = 0; k < 16; k++) {
    const r = rita({ gangart: "trav", fas: k / 16, ryttare: true, aids, varv: "hoger" });
    const d = natAv(r, "stovel")[0].m[13] - natAv(r, "sadel")[0].m[13];
    const b = natAv(r, "bal")[0].m[13] - natAv(r, "sadel")[0].m[13];
    lagst = Math.min(lagst, d); hogst = Math.max(hogst, d);
    satLagst = Math.min(satLagst, b); satHogst = Math.max(satHogst, b);
  }
  prova("lättridning: hälen stannar vid stigbygeln medan sätet reser sig",
    hogst - lagst < 0.005 && satHogst - satLagst > 0.08,
    `stöveln rör sig ${((hogst - lagst) * 1000).toFixed(1)} mm mot sadeln, sätet ${((satHogst - satLagst) * 100).toFixed(1)} cm`);
}

/* ── 3. Språnget ──────────────────────────────────────────────────── */
{
  const lutning = (u) => {
    const o = { hast: HAST, x: 0, z: 0, rikt: 0, gangart: "galopp", fas: 0.1, luft: 0.55 * (1 - u) };
    const bas = X.s3HastBas(o, X.s3HastKropp(o));
    const bog = X.M4.mul(bas, X.M4.translation(0.8, 1.3, 0)), kors = X.M4.mul(bas, X.M4.translation(-0.8, 1.3, 0));
    return bog[13] - kors[13];
  };
  const tidigt = lutning(0.1), sent = lutning(0.9);
  prova("språng: bogen stiger först (bog över kors i avstampet)", tidigt > 0.3, `${tidigt.toFixed(2)} m vid u 0,1`);
  prova("språng: bogen landar först (bog under kors i landningen)", sent < -0.3, `${sent.toFixed(2)} m vid u 0,9`);
}

/* ── 4. Hals och huvud ────────────────────────────────────────────── */
{
  const toppar = (gangart) => {
    const N = 240, y = [];
    for (let k = 0; k < N; k++) y.push(X.s3HuvudLokal({ gangart, fas: k / N }).huvud.y);
    let n = 0;
    for (let k = 0; k < N; k++) if (y[k] > y[(k - 1 + N) % N] && y[k] >= y[(k + 1) % N]) n++;
    return { n, utslag: Math.max(...y) - Math.min(...y) };
  };
  const sk = toppar("skritt"), ga = toppar("galopp"), tr = toppar("trav"), ha = toppar("halt");
  prova("skritt: huvudet nickar två gånger per cykel", sk.n === 2 && sk.utslag > 0.02,
    `${sk.n} toppar, ${(sk.utslag * 100).toFixed(1)} cm`);
  prova("galopp: halsen gungar en gång per cykel", ga.n === 1 && ga.utslag > 0.02,
    `${ga.n} topp, ${(ga.utslag * 100).toFixed(1)} cm`);
  prova("trav: huvudet är nästan stilla, klart lugnare än i skritt", tr.utslag < sk.utslag * 0.5,
    `${(tr.utslag * 100).toFixed(1)} cm mot ${(sk.utslag * 100).toFixed(1)} cm`);
  prova("halt: huvudet står stilla", ha.utslag < 1e-9, `${ha.utslag}`);
  /* Giren: spelet räknar `G.rikt-=omega*dt`, så POSITIV krökning är en
     HÖGERSVÄNG. Hon går norrut; svängens mitt ligger då i öster (+x). */
  for (const [kappa, sida] of [[0.2, 1], [-0.2, -1]]) {
    const rak = X.s3HuvudPunkt({ hast: HAST, x: 0, z: 0, rikt: Math.PI / 2, gangart: "skritt", fas: 0 });
    const bojd = X.s3HuvudPunkt({ hast: HAST, x: 0, z: 0, rikt: Math.PI / 2, gangart: "skritt", fas: 0, bojning: kappa });
    const dx = (bojd.x - rak.x) * sida;
    prova(`halsen ställs INÅT i en ${sida > 0 ? "höger" : "vänster"}sväng`, dx > 0.03 && dx < 0.25,
      `huvudet ${(dx * 100).toFixed(1)} cm mot svängens mitt`);
  }
  /* Ritvägen och mätpunkten ska vara SAMMA huvud: kameraprovet läser
     s3HuvudPunkt, och det nät som ritas ska sitta där. */
  const o = { gangart: "galopp", fas: 0.3, bojning: 0.25, rikt: 0.7, fattning: "hoger" };
  const r = natAv(rita(o), "huvud")[0].m;
  const p = X.s3HuvudPunkt({ hast: HAST, x: 0, z: 0, ...o });
  const d = Math.hypot(r[12] - p.x, r[13] - p.y, r[14] - p.z);
  prova("det ritade huvudet sitter i samma punkt som kameran mäter", d < 1e-6, `${d.toExponential(1)} m isär`);
}

/* ── 5. Varvet ────────────────────────────────────────────────────── */
{
  /* Banan 20 × 60, mitt (10, 30). Vid västra långsidan med kurs norrut
     ligger mitten i öster = till höger: höger varv, vänster fram yttre. */
  prova("varv: västra långsidan norrut är HÖGER varv", X.gangVarv(1, 30, Math.PI / 2, 10, 30) === "hoger");
  prova("varv: samma spår söderut är VÄNSTER varv", X.gangVarv(1, 30, -Math.PI / 2, 10, 30) === "vanster");
  prova("varv: rakt mot mitten finns inget svar", X.gangVarv(1, 30, 0, 10, 30) === null);
  prova("varv: yttre framben är vänster på höger varv och tvärtom",
    X.gangYttreFram("hoger") === "LF" && X.gangYttreFram("vanster") === "RF" && X.gangYttreFram(null) === null);
}

console.log(fel === 0
  ? `gangposetest: alla ${antal} gröna — benföljd, lättridning, språng och hals följer ridläran`
  : `gangposetest: ${fel} av ${antal} RÖDA`);
process.exit(fel === 0 ? 0 : 1);
