#!/usr/bin/env node
/* G02-D — inspelningen och uppspelningen.
 *
 * Provar de två nya modulerna isolerat, utan webbläsare: de är
 * motoroberoende med flit, och då ska de gå att mäta utan en renderare.
 *
 * Tyngdpunkten ligger på NEGATIVTESTERNA som docs/RIDANALYS.md räknar upp:
 * saknad telemetri, noll mot saknat, NaN/oändlighet, för få sampel,
 * trunkerade poster, versionskrock och saknad referens. En inspelning som
 * tyst gör om ett hål till en nolla är värre än ingen inspelning alls —
 * då bygger Ugnetas beröm på ett tal ingen har mätt.
 *
 * Kör: node tools/inspelningstest.mjs */
import fs from "node:fs";
import vm from "node:vm";

const ctx = { console, Math, JSON, Number, String, Object, Array };
vm.createContext(ctx);
vm.runInContext(
  fs.readFileSync("src/riding/ovningsdef.js", "utf8") + "\n" +
  fs.readFileSync("src/riding/inspelning.js", "utf8"), ctx);
const {
  Inspelning, Uppspelning, INSPELNING_HZ, INSPELNING_MAX_SAMPEL,
  INSPELNING_SCHEMA, INSPELNING_FALT, inspelningLasbar, ovningsDef,
  ovningsMatt, ovningsGeometri, OVNING_GILTIG, OVNINGAR_DEF,
} = vm.runInContext(
  "({Inspelning,Uppspelning,INSPELNING_HZ,INSPELNING_MAX_SAMPEL," +
  "INSPELNING_SCHEMA,INSPELNING_FALT,inspelningLasbar,ovningsDef," +
  "ovningsMatt,ovningsGeometri,OVNING_GILTIG,OVNINGAR_DEF})", ctx);

let fel = 0, n = 0;
const prova = (namn, ok, detalj) => {
  n++; if (!ok) fel++;
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj === undefined ? "" : detalj);
};

/* Rider en cirkel och spelar in den. Samma hjälpare används av flera prov
   nedan så att de mäter olika saker om SAMMA ritt. */
function ridCirkel({ dt = 1 / 60, sek = 8, radie = 10, fart = 3.2, gangart = "trav" } = {}) {
  const ins = new Inspelning();
  ins.starta("storvolt", "lydia", "skolhast",
    { gangart, fart, x: radie, y: 0 }, ovningsDef("storvolt").version);
  const omkrets = 2 * Math.PI * radie;
  let s = 0;
  for (let t = 0; t < sek; t += dt) {
    s += fart * dt;
    const v = (s / omkrets) * 2 * Math.PI;
    ins.sampla(dt, {
      x: radie * Math.cos(v), y: radie * Math.sin(v),
      kurs: v + Math.PI / 2, gangart, fas: (s / 2.15) % 1,
      fart, kurvatur: 1 / radie, balans: 0.8,
      hjalper: { skankel: 0.5, tygel: 0.34, sits: 0.2, styrning: 0.4 },
    });
  }
  return { ins, post: ins.avsluta(), radie, fart };
}

console.log("\n── DEFINITIONEN ──");
{
  const d = ovningsDef("storvolt");
  prova("20 m volten har en versionerad definition", !!d && d.version >= 1,
    d ? `id ${d.id} v${d.version}` : "saknas");
  prova("och övergången likaså", !!ovningsDef("trav_skritt"),
    ovningsDef("trav_skritt") ? "trav_skritt" : "saknas");
  prova("okänd övning ger null — ingen defaultövning hittas på",
    ovningsDef("finns_inte") === null, String(ovningsDef("finns_inte")));
  prova("men mätlistan har en fallback så okända övningar inte kraschar",
    ovningsMatt("finns_inte").length === 3, ovningsMatt("finns_inte").join("/"));
  prova("definitionen säger uttryckligen vad den INTE bedömer",
    d.bedomerInte.includes("position på banan"), d.bedomerInte.join(", "));
  prova("geometrin läses ur EN källa och dupliceras inte",
    ovningsGeometri("storvolt") === null || ovningsGeometri("storvolt").ram === "ridhus.dressyr",
    JSON.stringify(ovningsGeometri("storvolt")));
  prova("giltighetskravet är sekunder OCH sampel, inte bildrutor",
    OVNING_GILTIG.MIN_SEK === 1.0 && OVNING_GILTIG.MIN_MATNINGAR === 2,
    `${OVNING_GILTIG.MIN_MATNINGAR} sampel · ${OVNING_GILTIG.MIN_SEK} s`);
}

console.log("\n── INSPELNINGEN ──");
{
  const { post } = ridCirkel({ sek: 8 });
  prova("posten bär alla fält schemat kräver",
    INSPELNING_FALT.every(f => f in post), INSPELNING_FALT.filter(f => !(f in post)).join(",") || "alla");
  prova("tidpolicyn är simklockan, inte väggklockan", post.klocka === "sim", post.klocka);
  prova("sampeltakten hålls — 8 s ger ~20 Hz, inte 60",
    Math.abs(post.sampel.length - 8 * INSPELNING_HZ) <= 2,
    `${post.sampel.length} sampel på ${post.sekunder.toFixed(2)} s`);
  prova("posten vet vilken övningsversion den spelades mot",
    post.ovningVersion === ovningsDef("storvolt").version, String(post.ovningVersion));
  prova("och vilken häst och profil", post.hast === "lydia" && post.profil === "skolhast",
    `${post.hast}/${post.profil}`);
}

console.log("\n── DT SOM INTE GÅR ATT LITA PÅ ──");
{
  const ins = new Inspelning();
  ins.starta("storvolt", "lydia", "skolhast", {}, 1);
  const prov = [["noll", 0], ["negativt", -0.016], ["NaN", NaN], ["oändligt", Infinity],
    ["odefinierat", undefined], ["text", "0.016"], ["pausad flik (4,2 s)", 4.2]];
  const skrev = [];
  for (const [namn, d] of prov) if (ins.sampla(d, { x: 1, y: 1 })) skrev.push(namn);
  prova("inget av de omöjliga dt:na skrev ett sampel", skrev.length === 0,
    skrev.length ? "skrev: " + skrev.join(", ") : "0 sampel");
  const p = ins.avsluta();
  prova("posten är alltså tom efter dem", p.sampel.length === 0, `${p.sampel.length} sampel`);
}

console.log("\n── SAKNAT ÄR INTE NOLL ──");
{
  const ins = new Inspelning();
  ins.starta("storvolt", "lydia", "skolhast", {}, 1);
  ins.sampla(0.1, { x: 5, y: 0, gangart: "trav" });   // balans/fart/kurs saknas helt
  const p = ins.avsluta();
  const s = p.sampel[0];
  prova("ett omätt fält blir null i posten, inte 0",
    s.balans === null && s.fart === null && s.kurs === null,
    `balans ${s.balans} · fart ${s.fart} · kurs ${s.kurs}`);
  prova("och ett fält som ÄR uppmätt som noll blir 0", (() => {
    const i2 = new Inspelning(); i2.starta("storvolt", "h", "p", {}, 1);
    i2.sampla(0.1, { x: 0, y: 0, balans: 0, fart: 0 });
    const q = i2.avsluta().sampel[0];
    return q.balans === 0 && q.fart === 0;
  })(), "0 skrivs som 0");
  prova("NaN och oändlighet blir null, aldrig ett tal", (() => {
    const i3 = new Inspelning(); i3.starta("storvolt", "h", "p", {}, 1);
    i3.sampla(0.1, { x: NaN, y: Infinity, balans: -Infinity, fart: 0 / 0 });
    const q = i3.avsluta().sampel[0];
    return q.x === null && q.y === null && q.balans === null && q.fart === null;
  })(), "fyra fält null");
}

console.log("\n── GRÄNSER ──");
{
  const ins = new Inspelning();
  ins.starta("storvolt", "lydia", "skolhast", {}, 1);
  for (let i = 0; i < INSPELNING_MAX_SAMPEL + 200; i++) ins.sampla(0.05, { x: i, y: 0 });
  const p = ins.post || ins.avsluta();
  const post = p.sampel ? p : ins.avsluta();
  prova("posten växer inte förbi taket", post.sampel.length <= INSPELNING_MAX_SAMPEL,
    `${post.sampel.length} av max ${INSPELNING_MAX_SAMPEL}`);
  prova("och den märks trunkerad i stället för att tyst kapas",
    post.trunkerad === true, String(post.trunkerad));
  prova("det som hann spelas in finns kvar", post.sampel.length > 0,
    `${post.sampel.length} sampel bevarade`);
}

console.log("\n── UPPSPELNINGEN ──");
{
  const { post, radie } = ridCirkel({ sek: 8 });
  const up = new Uppspelning(post);
  prova("längden är sista samplets tid", Math.abs(up.langd() - post.sekunder) < 1e-9,
    `${up.langd().toFixed(2)} s`);

  /* Återger uppspelningen den inspelade vägen? Mät mot cirkeln ritten
     faktiskt red, i punkter MELLAN sampeln — annars provas bara att
     sampeln finns kvar, inte att interpolationen duger. */
  let varst = 0;
  for (let t = 0.05; t < up.langd(); t += 0.037) {
    const s = up.vid(t);
    const r = Math.hypot(s.x, s.y);
    varst = Math.max(varst, Math.abs(r - radie));
  }
  prova("uppspelningen följer den inspelade banan inom dokumenterad tolerans",
    varst < 0.05, `största avvikelse ${(varst * 100).toFixed(2)} cm (tolerans 5 cm)`);

  const fore = JSON.stringify(post);
  up.spela(); for (let i = 0; i < 400; i++) up.steg(1 / 60);
  up.hoppa(2); up.vid(2); up.sattFart(0.5); up.steg(0.1);
  prova("uppspelning ändrar ALDRIG posten den läser", JSON.stringify(post) === fore,
    "byte-identisk efter spela/scrub/hastighet");

  prova("scrub klampas till postens längd", up.hoppa(9999) === up.langd(),
    `${up.hoppa(9999).toFixed(2)} s`);
  prova("och till noll åt andra hållet", up.hoppa(-5) === 0, String(up.hoppa(-5)));
  prova("orimlig uppspelningshastighet avvisas", (() => {
    const f0 = up.sattFart(0.5); up.sattFart(0); up.sattFart(-1); up.sattFart(99);
    return up.fart === f0;
  })(), `fart ${up.fart}`);

  prova("gångarten interpoleras inte — den är diskret", (() => {
    const i = new Inspelning(); i.starta("trav_skritt", "h", "p", {}, 1);
    i.sampla(0.1, { gangart: "trav", x: 0, y: 0 });
    i.sampla(0.1, { gangart: "skritt", x: 1, y: 0 });
    const u = new Uppspelning(i.avsluta());
    const mitt = u.vid(0.15);
    return mitt.gangart === "trav" || mitt.gangart === "skritt";
  })(), "aldrig något däremellan");

  prova("kursen tar kortaste vägen förbi π", (() => {
    const i = new Inspelning(); i.starta("storvolt", "h", "p", {}, 1);
    i.sampla(0.1, { kurs: 3.0, x: 0, y: 0 });
    i.sampla(0.1, { kurs: -3.0, x: 0, y: 0 });
    const u = new Uppspelning(i.avsluta());
    const k = u.vid(0.15).kurs;
    /* Kortaste vägen går genom ±π, alltså |kurs| > 3,0 — inte genom 0. */
    return Math.abs(k) > 3.0;
  })(), "ingen helvarvssnurr");

  prova("interpolation vägrar blanda ett mätvärde med ett hål", (() => {
    const i = new Inspelning(); i.starta("storvolt", "h", "p", {}, 1);
    i.sampla(0.1, { x: 0, y: 0, balans: 0.9 });
    i.sampla(0.1, { x: 1, y: 0 });                 // balans saknas
    const u = new Uppspelning(i.avsluta());
    return u.vid(0.15).balans === null;
  })(), "balans null i stället för halvvägs");

  prova("en tom post ger inget läge alls", new Uppspelning({ sampel: [] }).vid(0) === null,
    "null");
  prova("och en post som inte finns kraschar inte", new Uppspelning(null).vid(0) === null,
    "null");
}

console.log("\n── VERSIONER OCH SAKNAD REFERENS ──");
{
  const { post } = ridCirkel({ sek: 3 });
  prova("en samtida post är läsbar", inspelningLasbar(post).lage === "ok",
    inspelningLasbar(post).lage);
  prova("fel schema avvisas med skäl, inte tyst",
    inspelningLasbar({ ...post, schema: 999 }).lage === "nej",
    inspelningLasbar({ ...post, schema: 999 }).skal);
  prova("äldre övningsversion är LÄSBAR men märkt gammal",
    inspelningLasbar({ ...post, ovningVersion: 0 }).lage === "gammal",
    inspelningLasbar({ ...post, ovningVersion: 0 }).skal);
  prova("okänd övning avvisas", inspelningLasbar({ ...post, ovning: "finns_inte" }).lage === "nej",
    inspelningLasbar({ ...post, ovning: "finns_inte" }).skal);
  prova("ingen post alls avvisas", inspelningLasbar(null).lage === "nej",
    inspelningLasbar(null).skal);
  prova("ingen övning har en referens ännu — och ingen påstås ha det",
    Object.values(OVNINGAR_DEF).every(d => d.referens === null),
    "referens: null i båda");
}

console.log("\n── FÖR LITE UNDERLAG ──");
{
  const { post } = ridCirkel({ sek: 0.5 });
  prova("en halvsekundsritt ger färre sampel än giltighetskravet",
    post.sampel.length < OVNING_GILTIG.MIN_SEK * INSPELNING_HZ,
    `${post.sampel.length} sampel på ${post.sekunder.toFixed(2)} s`);
  const ins = new Inspelning();
  ins.starta("storvolt", "h", "p", {}, 1);
  ins.sampla(0.1, { x: 0, y: 0 });
  const p = ins.avsluta();
  prova("ett enda sampel går att spela upp utan att interpolera mot sig självt",
    new Uppspelning(p).vid(0.05) !== null, "ett läge, inget NaN");
}

console.log(fel === 0 ? `\nALLA OK (${n} mätningar)` : `\n${fel} FEL av ${n}`);
process.exit(fel === 0 ? 0 : 1);
