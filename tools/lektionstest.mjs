/* LEKTIONSPROVET — alla tolv lektioner ridna syntetiskt på webben (P3 § 8).

   Varje ritt går genom den RIKTIGA produktionsvägen: RittLektion (webbens
   HorseService-del) samplar läget i serverns takt, gångartshändelserna
   kommer ur hjälpen (en ny `cueTid` med en ny `beddGangart`, precis som
   src/model.js skriver dem), och lektionen stegas efter varje
   observationssteg med LektionMotor.begar/steg — samma anrop som
   Lektionsmenyn gör. Inga lektionsfält sätts för hand.

   Fallen speglar Roblox egna specar (roblox/tests/*lektion.spec.luau):
   en ren ritt fullföljer, och en ritt som fäller i Roblox fäller här med
   samma tips — en volt med en punkt 4,1 m från linjen nollställs med
   «line»/«ut», ett halt utanför 1,5 m från X är inte godkänt, en travhjälp
   före T1-ringen ger `trot_outside` med sidan «fore», diagonalen börjar
   vid F, en bom som rids förbi på sidan ger `beside_pole`, fel hinder
   först i clear round ger uteslutning för fel väg …

   Kör: node tools/lektionstest.mjs */
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
let fel = 0, prov = 0;
const prova = (namn, ok, detalj = "") => {
  prov++;
  console.log(`  ${ok ? "OK  " : "FEL "} ${namn}${detalj ? " — " + detalj : ""}`);
  if (!ok) fel++;
};

function nyVarld() {
  const ctx = vm.createContext({ console, Math, JSON, Object, Array, Number, String, Map, Set, isFinite });
  vm.runInContext("var window = undefined;", ctx);
  for (const f of ["src/spel/sprak.js", "src/spel/skotsel.js", "src/site.js", "src/lektioner/motor.js",
    "src/lektioner/observation.js", "src/lektioner/hinder.js", "src/lektioner/volt.js", "src/lektioner/halt.js",
    "src/lektioner/tempo.js", "src/lektioner/overgang.js", "src/lektioner/galopp.js", "src/lektioner/serpentin.js",
    "src/lektioner/vag.js", "src/lektioner/halvvolt.js", "src/lektioner/hornet.js", "src/lektioner/markbom.js",
    "src/lektioner/clearround.js", "src/lektioner/aterkoppling.js", "src/lektioner/koppling.js",
    "src/lararinstallning.js"]) {
    let kod = fs.readFileSync(path.join(ROT, f), "utf8");
    if (f === "src/spel/sprak.js") kod += "\nvar tSpr = (k, ...a) => sprakText(k, 'sv', ...a);";
    try { vm.runInContext(kod, ctx, { filename: f }); }
    catch (e) { if (f !== "src/site.js") throw e; }
  }
  return ctx;
}

/* ── Ryttaren: en väg av punkter i lektionsramen (u, v) ─────────────── */
const DT = 0.05;
class Ritt {
  constructor(typ, start, gang = "skritt") {
    this.w = nyVarld();
    this.W = e => vm.runInContext(e, this.w);
    this.typ = typ;
    this.id = this.W("RittLektion.start('prov')");
    this.ride = { gangart: gang, beddGangart: gang, cueTid: 0, cue: null };
    this.u = start[0]; this.v = start[1]; this.t = 0;
    this.s = this.W(`LektionMotor.ny(${JSON.stringify(typ)}, 'prov', null)`);
    this.w.__s = this.s; this.w.__ride = this.ride;
    this.tips = new Set();
    this.bildruta(0.3);
  }
  get x() { return 10 - this.u; }
  get y() { return this.v; }
  bildruta(sek) {
    const n = Math.max(1, Math.round(sek / DT));
    for (let i = 0; i < n; i++) this.steg(DT, this.u, this.v);
  }
  steg(dt, u, v) {
    this.u = u; this.v = v; this.t += dt;
    this.w.__lage = { x: 10 - u, y: v, gangart: this.ride.gangart, ridhus: true };
    this.w.__now = this.t;
    this.W("RittLektion.steg(" + dt + ", __lage, __ride, __now, X => LektionMotor.steg(__s, X))");
    const b = this.bild();
    this.tips.add(b.lage + ":" + b.tips);
  }
  bild() { return this.W("LektionMotor.bild(__s)"); }
  begar(op) {
    this.w.__op = op;
    const [ok, fel] = this.W("LektionMotor.begar(__s, __op, RittLektion.kontext(__now, RittLektion.tillRoblox(__ride.gangart)))");
    return { ok, fel };
  }
  /* Ryttarens hjälp: en ny begärd gångart. Hästen svarar direkt i provet. */
  hjalp(gang) {
    this.ride.cueTid += 1; this.ride.beddGangart = gang; this.ride.gangart = gang; this.ride.cue = "prov";
  }
  /* Rid rakt till (u, v) i fart m/s. */
  till(u, v, fart) {
    const L = Math.hypot(u - this.u, v - this.v);
    const n = Math.max(1, Math.ceil(L / (fart * DT)));
    const u0 = this.u, v0 = this.v;
    for (let i = 1; i <= n; i++) this.steg(DT, u0 + (u - u0) * i / n, v0 + (v - v0) * i / n);
  }
  /* Rid en båge kring (cu, cv) med radie r från vinkel a0 till a1 (rad). */
  bage(cu, cv, r, a0, a1, fart) {
    const L = Math.abs(a1 - a0) * r;
    const n = Math.max(1, Math.ceil(L / (fart * DT)));
    for (let i = 1; i <= n; i++) {
      const a = a0 + (a1 - a0) * i / n;
      this.steg(DT, cu + r * Math.cos(a), cv + r * Math.sin(a));
    }
  }
  sta(sek) { this.bildruta(sek); }
  text() { return this.W(`LektionAterkoppling.text(LektionMotor.bild(__s), { typ: ${JSON.stringify(this.typ === "vag_mitt" || this.typ === "vag_diag" ? this.typ : this.typ)}, ritt: 'prov' })`); }
}
const sag = (namn, r, lage, tips) => {
  const b = r.bild();
  prova(namn, b.lage === lage && (tips == null || b.tips === tips), `läge ${b.lage}, tips ${b.tips}, ${b.progress}%`);
};
const sett = (namn, r, nyckel) => prova(namn, r.tips.has(nyckel), [...r.tips].slice(-6).join(" "));

/* ── VOLT ─────────────────────────────────────────────────────────── */
{
  console.log("volt");
  const r = new Ritt("volt", [10, 30], "trav");
  prova("volt: start", r.begar("start").ok);
  r.bage(0, 30, 10, 0, 2 * Math.PI + 0.6, 3);
  sag("volt: ett rent 20 m-varv fullföljs", r, "complete", "complete");
  const t = r.text();
  prova("volt: återkopplingen bär varvet och radien", /1 varv/.test(t) && /20 m/.test(t) || /Snyggt|Bra/.test(t), t);
  const r2 = new Ritt("volt", [10, 30], "trav");
  r2.begar("start");
  r2.bage(0, 30, 10, 0, Math.PI / 2, 3);
  r2.till(0, 44.1, 3); r2.sta(0.5);
  sett("volt: en punkt 4,1 m utanför nollställer med «line»", r2, "approach:line");
  prova("volt: linjeSida «ut» visas", r2.bild().linjeSida === "ut", String(r2.bild().linjeSida));
}

/* ── HALT ─────────────────────────────────────────────────────────── */
{
  console.log("halt");
  const r = new Ritt("halt", [0, 20], "halt");
  prova("halt: start", r.begar("start").ok);
  r.sta(1.5);
  sett("halt: första haltet klart → skritt", r, "walk:walk_on");
  r.hjalp("skritt"); r.till(0, 29.5, 1.4);
  r.hjalp("halt"); r.sta(2.6);
  sag("halt: skritt på hjälp och halt vid X fullföljs", r, "complete", "complete");
  const r2 = new Ritt("halt", [0, 20], "halt");
  r2.begar("start"); r2.sta(1.5); r2.hjalp("skritt"); r2.till(0, 26, 1.4); r2.hjalp("halt"); r2.sta(1.0);
  sag("halt: halt 4 m före X är «halt_outside»", r2, "walk", "halt_outside");
}

/* ── TEMPO ────────────────────────────────────────────────────────── */
{
  console.log("tempo");
  const r = new Ritt("tempo", [5, 10], "skritt");
  prova("tempo: start", r.begar("start").ok);
  r.till(5, 40, 1.5);
  sag("tempo: jämn skritt 1,5 m/s fullföljs", r, "complete", "complete");
  const r2 = new Ritt("tempo", [5, 10], "skritt");
  r2.begar("start"); r2.till(5, 30, 2.6);
  sett("tempo: 2,6 m/s är för fort", r2, "steady:too_fast");
}

/* ── ÖVERGÅNGAR ───────────────────────────────────────────────────── */
{
  console.log("overgang");
  const r = new Ritt("overgang", [0, 8], "skritt");
  prova("overgang: start", r.begar("start").ok);
  r.till(0, 17.5, 1.4);
  r.hjalp("trav"); r.till(0, 41.5, 3);
  r.hjalp("skritt"); r.till(0, 45, 1.4);
  sag("overgang: trav vid T1 och skritt vid T2 fullföljs", r, "complete", "complete");
  const r2 = new Ritt("overgang", [0, 5], "skritt");
  r2.begar("start"); r2.till(0, 11, 1.4); r2.hjalp("trav"); r2.till(0, 12, 3);
  sag("overgang: travhjälp före T1 är «trot_outside»", r2, "walk1", "trot_outside");
  prova("overgang: sidan är «fore» (trot_early)", r2.bild().malSida === "fore", String(r2.bild().malSida));
}

/* ── GALOPP ───────────────────────────────────────────────────────── */
{
  console.log("galopp");
  const r = new Ritt("galopp", [0, 10], "trav");
  prova("galopp: start", r.begar("start").ok);
  r.till(0, 29.5, 3);
  r.hjalp("galopp"); r.till(0, 38, 4.5);
  sag("galopp: galopp i galoppringen efter trav fullföljs", r, "complete", "complete");
  const r2 = new Ritt("galopp", [0, 10], "trav");
  r2.begar("start"); r2.till(0, 14, 3); r2.hjalp("galopp"); r2.till(0, 15, 4.5);
  sag("galopp: galopp före 8 m trav är «trot_first»", r2, "trot", "trot_first");
}

/* ── SERPENTIN ────────────────────────────────────────────────────── */
{
  console.log("serpentin");
  const r = new Ritt("serpentin", [0, 4], "trav");
  prova("serpentin: start", r.begar("start").ok);
  r.till(0, 6, 3);
  const R = 8, V0 = 6;
  /* Tre bågar, sidorna +, −, + : båge k kring (0, V0 + R + (k−1)·2R). */
  r.bage(0, V0 + R, R, -Math.PI / 2, Math.PI / 2 * -1 + Math.PI, 3);
  r.bage(0, V0 + 3 * R, R, -Math.PI / 2, -Math.PI / 2 - Math.PI, 3);
  r.bage(0, V0 + 5 * R, R, -Math.PI / 2, Math.PI / 2, 3);
  r.till(0, V0 + 6 * R + 0.5, 3);
  sag("serpentin: tre bågar fullföljs", r, "complete", "complete");
  const r2 = new Ritt("serpentin", [0, 4], "trav");
  r2.begar("start"); r2.till(0, 6, 3); r2.bage(0, V0 + R, R, -Math.PI / 2, 0, 3);
  r2.hjalp("galopp"); r2.bage(0, V0 + R, R, 0, 0.4, 4.5);
  sett("serpentin: galopp ger «walk_or_trot»", r2, "to_start:walk_or_trot");
}

/* ── RIDVÄGAR ─────────────────────────────────────────────────────── */
{
  console.log("vag");
  const r = new Ritt("vag_mitt", [0, 3], "skritt");
  prova("vag_mitt: start", r.begar("start").ok);
  r.till(0, 55, 1.5);
  sag("vag_mitt: mittlinjen fullföljs", r, "complete", "complete");
  const r2 = new Ritt("vag_diag", [-7, 5], "skritt");
  prova("vag_diag: start", r2.begar("start").ok);
  r2.till(-7, 8, 1.5); r2.till(7, 52, 1.5); r2.till(7.2, 52.6, 1.5);
  sag("vag_diag: diagonalen F → H fullföljs", r2, "complete", "complete");
  const r3 = new Ritt("vag_mitt", [0, 3], "skritt");
  r3.begar("start"); r3.till(0, 20, 1.5); r3.till(3, 22, 1.5);
  sett("vag_mitt: utanför korridoren är «off_route»", r3, "to_start:off_route");
}

/* ── HALVVOLT ─────────────────────────────────────────────────────── */
{
  console.log("halvvolt");
  const r = new Ritt("halvvolt", [8.5, 13], "skritt");
  prova("halvvolt: start", r.begar("start").ok);
  r.till(8.5, 26, 1.5);
  r.bage(3.5, 26, 5, 0, Math.PI, 1.5);
  r.till(8.5, 8, 1.5);
  sag("halvvolt: spåret, halvvolten och tillbaka fullföljs", r, "complete", "complete");
  const r2 = new Ritt("halvvolt", [8.5, 13], "skritt");
  r2.begar("start"); r2.till(8.5, 20, 1.5); r2.till(4, 22, 1.5);
  sett("halvvolt: ur korridoren är «off_route»", r2, "to_start:off_route");
}

/* ── GENOM HÖRNET ─────────────────────────────────────────────────── */
{
  console.log("hornet");
  const r = new Ritt("hornet", [8.5, 41], "skritt");
  prova("hornet: start", r.begar("start").ok);
  r.till(8.5, 53.5, 1.5);
  r.bage(3.5, 53.5, 5, 0, Math.PI / 2, 1.5);
  r.till(-3, 58.5, 1.5);
  sag("hornet: in, kvartsvolt och ut fullföljs", r, "complete", "complete");
  prova("hornet: kontrollpunkten mitt i bågen är nådd", r.bild().resultat && r.bild().resultat.mitt === true);
}

/* ── MARKBOM ──────────────────────────────────────────────────────── */
{
  console.log("markbom");
  const r = new Ritt("markbom", [1, 36], "skritt");
  const st = r.begar("start");
  prova("markbom: start (bommen finns i site.js)", st.ok, String(st.fel));
  r.till(1, 55, 1.3);
  sag("markbom: inridning, passage och utridning fullföljs", r, "complete", "complete");
  const r2 = new Ritt("markbom", [2.8, 36], "skritt");
  r2.begar("start"); r2.till(2.8, 53, 1.3);
  sett("markbom: förbi bommens ände är «beside_pole»", r2, "approach:beside_pole");
}

/* ── CLEAR ROUND ──────────────────────────────────────────────────── */
{
  console.log("clearround");
  /* Hindren: blå (u 3,5, v 24), röd (u −3,5, v 38). Banan blå → C, röd → C,
     blå → A, röd → C. Startlinjen 8 m före blå, mållinjen 8 m efter röd. */
  const r = new Ritt("clearround", [3.5, 8], "trav");
  prova("clearround: anmälan", r.begar("anmal").ok);
  prova("clearround: gå banan", r.begar("ga_banan").ok);
  prova("clearround: start", r.begar("start").ok);
  r.till(3.5, 30, 3);                // startlinjen v 16, blå v 24 mot C
  r.till(-3.5, 32, 3); r.till(-3.5, 44, 3);   // röd v 38 mot C
  r.till(-8, 47, 3); r.till(-8, 32, 3); r.till(3.5, 30, 3); r.till(3.5, 18, 3);  // blå mot A
  r.till(-3.5, 28, 3); r.till(-3.5, 48, 3);   // röd mot C, mållinjen v 46
  const b = r.bild();
  prova("clearround: fyra hopp i ordning ger «inga observerade fel»", b.lage === "complete" && b.resultat && b.resultat.utfall === "inga_observerade_fel",
    `${b.lage} ${b.tips} ${b.resultat && b.resultat.utfall}`);
  prova("clearround: aldrig «felfri», ingen rosett", b.resultat && !("rosett" in b.resultat) && b.resultat.nedslag === "bedoms_inte");
  const r2 = new Ritt("clearround", [-3.5, 8], "trav");
  r2.begar("anmal"); r2.begar("ga_banan"); r2.begar("start");
  r2.till(3.5, 14, 3); r2.till(3.5, 17, 3); r2.till(-3.5, 30, 3); r2.till(-3.5, 42, 3);
  const b2 = r2.bild();
  prova("clearround: röd först är fel väg — utesluten", b2.resultat && b2.resultat.utfall === "utesluten" && b2.resultat.orsak === "fel_vag",
    `${b2.lage} ${b2.resultat && b2.resultat.utfall} ${b2.resultat && b2.resultat.orsak}`);
  const r3 = new Ritt("clearround", [3.5, 8], "trav");
  r3.begar("anmal"); r3.begar("ga_banan"); r3.begar("start"); r3.till(3.5, 20, 3);
  r3.W("LektionMotor.avbryt(__s, RittLektion.kontext(__now, 'trot'))");
  const b3 = r3.bild();
  prova("clearround: avsittning mitt i banan ger «avbruten»", b3.resultat && b3.resultat.utfall === "avbruten", `${b3.lage} ${b3.tips}`);
}

/* ── BROTT OCH PLATS ──────────────────────────────────────────────── */
{
  console.log("gemensamt");
  const r = new Ritt("halt", [0, 20], "halt");
  r.begar("start"); r.sta(1.5); r.hjalp("skritt"); r.till(0, 25, 1.4);
  r.W("RittLektion.teleport()"); r.till(0, 25.2, 1.4);
  sett("teleport mitt i försöket nollställer till «unknown»", r, "halt1:unknown");
  const w = nyVarld();
  vm.runInContext("RittLektion.start('ute'); var s = LektionMotor.ny('halt', 'ute', null);", w);
  vm.runInContext("RittLektion.steg(0.3, { x: 10, y: 20, gangart: 'halt', ridhus: false }, { gangart: 'halt', beddGangart: 'halt', cueTid: 0 }, 0.3, null)", w);
  const [ok, felx] = vm.runInContext("LektionMotor.begar(s, 'start', RittLektion.kontext(0.3, 'halt'))", w);
  prova("utanför ridhuset: start nekas med «place»", !ok && felx === "place", String(felx));
  const r2 = new Ritt("halt", [0, 20], "halt");
  r2.begar("start");
  r2.W("LektionMotor.avbryt(__s, RittLektion.kontext(__now, 'halt'))");
  prova("avsittning stänger ett aktivt försök", !r2.W("LektionMotor.aktiv(__s)"));
}

console.log(fel ? `LEKTIONSPROV: ${fel} av ${prov} FEL` : `LEKTIONSPROV: alla ${prov} gröna`);
process.exit(fel ? 1 : 0);
