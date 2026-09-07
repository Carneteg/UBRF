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
  fs.readFileSync("src/riding/inspelning.js", "utf8") + "\n" +
  fs.readFileSync("src/riding/ridanalys.js", "utf8"), ctx);
const {
  Inspelning, Uppspelning, INSPELNING_HZ, INSPELNING_MAX_SAMPEL,
  INSPELNING_SCHEMA, INSPELNING_FALT, inspelningLasbar, ovningsDef,
  ovningsMatt, ovningsGeometri, OVNING_GILTIG, OVNINGAR_DEF,
  analysVolt, analysOvergang, jamforRitter, voltIOrd, anpassaCirkel,
} = vm.runInContext(
  "({Inspelning,Uppspelning,INSPELNING_HZ,INSPELNING_MAX_SAMPEL," +
  "INSPELNING_SCHEMA,INSPELNING_FALT,inspelningLasbar,ovningsDef," +
  "ovningsMatt,ovningsGeometri,OVNING_GILTIG,OVNINGAR_DEF," +
  "analysVolt,analysOvergang,jamforRitter,voltIOrd,anpassaCirkel})", ctx);

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


console.log("\n── RIDANALYSEN: VAD VOLTEN FAKTISKT BLEV ──");
{
  /* En perfekt cirkel med känd radie — analysen ska hitta tillbaka till
     den. Utan det här provet vore varje senare siffra obevisad. */
  const { post } = ridCirkel({ sek: 20, radie: 10, fart: 3.2 });
  const a = analysVolt(post);
  prova("volten går att analysera", a.ok, a.ok ? `${a.punkter} punkter` : a.skal);
  prova("den anpassade radien hittar tillbaka till den ridna",
    a.ok && Math.abs(a.radie - 10) < 0.05,
    a.ok ? `${a.radie.toFixed(3)} m mot ridd 10 m` : a.skal);
  prova("och mitten hamnar där cirkeln faktiskt låg",
    a.ok && Math.hypot(a.mitt.x, a.mitt.y) < 0.05,
    a.ok ? `(${a.mitt.x.toFixed(3)}, ${a.mitt.y.toFixed(3)}) mot (0, 0)` : a.skal);
  prova("avvikelsen från cirkeln är nära noll för en perfekt cirkel",
    a.ok && a.avvikelse.rms < 0.02,
    a.ok ? `rms ${(a.avvikelse.rms * 100).toFixed(2)} cm` : a.skal);
  /* 20 s i 3,2 m/s = 64 m. En cirkel med radie 10 är 62,8 m runt, alltså
     drygt ett varv. Talet ska falla ur sträckan, inte ur en gissning. */
  prova("varvräkningen faller ur den ridna sträckan",
    a.ok && Math.abs(a.varv - a.stracka / (2 * Math.PI * a.radie)) < 1e-9
        && a.varv > 1 && a.varv < 1.1,
    a.ok ? `${a.varv.toFixed(3)} varv på ${a.stracka.toFixed(1)} m` : a.skal);

  /* En MINDRE volt ska ge en mindre radie — annars mäter analysen inte
     det den påstår. */
  const liten = analysVolt(ridCirkel({ sek: 20, radie: 6, fart: 3.2 }).post);
  prova("en snävare volt ger en mindre uppmätt radie",
    liten.ok && Math.abs(liten.radie - 6) < 0.05 && liten.radie < a.radie,
    liten.ok ? `${liten.radie.toFixed(2)} m mot ${a.radie.toFixed(2)} m` : liten.skal);
}

console.log("\n── ANALYSEN VÄGRAR SVARA NÄR DEN INTE VET ──");
{
  const rak = new Inspelning();
  rak.starta("storvolt", "h", "p", {}, 1);
  for (let i = 0; i < 40; i++) rak.sampla(0.06, { x: i * 0.5, y: 0, gangart: "trav" });
  const r = analysVolt(rak.avsluta());
  prova("en rak linje ger ingen cirkel — och påstår ingen", !r.ok, r.skal);

  const tom = analysVolt({ sampel: [] });
  prova("en tom post ger inget svar", !tom.ok, tom.skal);
  prova("och ingen post alls kraschar inte", !analysVolt(null).ok, analysVolt(null).skal);

  const hal = new Inspelning();
  hal.starta("storvolt", "h", "p", {}, 1);
  for (let i = 0; i < 30; i++) hal.sampla(0.06, { gangart: "trav" });   // ingen position alls
  const h = analysVolt(hal.avsluta());
  prova("sampel utan position räknas inte som punkter", !h.ok && h.punkter === 0,
    `${h.punkter} punkter · ${h.skal}`);
}

console.log("\n── ÖVERGÅNGEN I POSTEN ──");
{
  const i = new Inspelning();
  i.starta("trav_skritt", "h", "p", {}, 1);
  for (let k = 0; k < 20; k++) i.sampla(0.06, { x: k, y: 0, gangart: "trav", fart: 3.2 });
  for (let k = 0; k < 20; k++) i.sampla(0.06, { x: 20 + k, y: 0, gangart: "skritt", fart: 1.4 });
  const o = analysOvergang(i.avsluta());
  prova("gångartsbytet hittas i posten", o.ok && o.antal === 1,
    o.ok ? `${o.forsta.fran} → ${o.forsta.till} vid ${o.forsta.t.toFixed(2)} s` : o.skal);
  prova("och farten före och efter finns med",
    o.ok && o.forsta.fartFore > o.forsta.fartEfter,
    o.ok ? `${o.forsta.fartFore} → ${o.forsta.fartEfter} m/s` : o.skal);

  const utan = new Inspelning();
  utan.starta("trav_skritt", "h", "p", {}, 1);
  for (let k = 0; k < 20; k++) utan.sampla(0.06, { x: k, y: 0, gangart: "trav" });
  const u = analysOvergang(utan.avsluta());
  prova("en ritt utan gångartsändring beskrivs inte som en övergång", !u.ok, u.skal);
}

console.log("\n── JÄMFÖRELSEN MELLAN TVÅ RITTER ──");
{
  const f1 = ridCirkel({ sek: 20, radie: 8, fart: 3.2 }).post;
  const f2 = ridCirkel({ sek: 20, radie: 10, fart: 3.2 }).post;
  const j = jamforRitter(f1, f2);
  prova("jämförelsen beskriver skillnaden i radie", j.ok && j.radie.diff > 1.9 && j.radie.diff < 2.1,
    j.ok ? `${j.radie.fore.toFixed(1)} → ${j.radie.nu.toFixed(1)} m (${j.radie.diff.toFixed(2)})` : j.skal);
  prova("och sätter inget betyg — bara tal",
    j.ok && !("poang" in j) && !("battre" in j) && !("ton" in j),
    Object.keys(j).join(", "));
  const trasig = jamforRitter({ sampel: [] }, f2);
  prova("en oanalyserbar ritt jämförs inte", !trasig.ok, trasig.skal);
}

console.log("\n── ANALYSEN I ORD ──");
{
  /* Målradien skickas in. Modulen har med flit inget dolt beroende till
     src/larare.js — den laddas senare i sidan och finns inte alls här. */
  const a = analysVolt(ridCirkel({ sek: 20, radie: 10, fart: 3.2 }).post, 10);
  const txt = voltIOrd(a);
  prova("raden nämner den uppmätta radien", /10\.0 m/.test(txt), txt);
  prova("och att den ligger nära målet", /nära/.test(txt), txt);
  const liten = voltIOrd(analysVolt(ridCirkel({ sek: 20, radie: 6, fart: 3.2 }).post, 10));
  prova("en tydligt mindre volt beskrivs som mindre", /mindre/.test(liten), liten);
  prova("ingen analys ger ingen text", voltIOrd(null) === null, String(voltIOrd(null)));
  const utanMal = voltIOrd(analysVolt(ridCirkel({ sek: 20, radie: 6, fart: 3.2 }).post));
  prova("utan mål jämförs ingenting — volten beskrivs bara",
    !/mindre|större|nära/.test(utanMal), utanMal);
}

console.log(fel === 0 ? `\nALLA OK (${n} mätningar)` : `\n${fel} FEL av ${n}`);
process.exit(fel === 0 ? 0 : 1);
