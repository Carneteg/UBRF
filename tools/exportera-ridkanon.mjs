#!/usr/bin/env node
/* Exporterar RIDNINGENS KANON ur webbens ridmodell till en Luau-modul som
   Roblox-sidan kan mäta sig mot.

   Poängen är densamma som i tools/exportera-geometri.js: det ska bara finnas
   EN sanning om gångartsbanden, hysteresen och telemetrins fält. Webbens
   src/model.js och src/riding/telemetri.js är den sanningen; den här filen
   kopierar inga siffror för hand utan räknar ut dem ur samma kod som
   webbspelet kör.

       node tools/exportera-ridkanon.mjs               skriver om modulen
       node tools/exportera-ridkanon.mjs --kontrollera faller om den är osynk

   VIKTIGT — filen ändrar INGEN ridkänsla. Den läser Gate 01:s intrimmade
   värden och skriver ned dem. Roblox-sidans egna värden rörs inte heller:
   paritetsspecen (roblox/tests/paritet.spec.luau) JÄMFÖR mot den här
   modulen och listar de avvikelser som faktiskt finns, i stället för att
   tysta harmonisera bort dem. Att ändra ett gångartsband är ett
   produktbeslut, inte en exportbiverkning. */

import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");

const ctx = { console, Math, JSON, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/model.js") + "\n" + las("src/riding/hjalper.js")
  + "\n" + las("src/riding/svar.js") + "\n" + las("src/riding/telemetri.js")
  /* G02-D: övningsdefinitionen. Måste laddas FÖRE src/larare.js, precis
     som i index.html — larare.js bygger UGNETA_OVNING_DIM ur den. */
  + "\n" + las("src/riding/ovningsdef.js")
  /* Hästdatan med — scenariot nedan ska rida VERKLIGA UBRF-hästar
     ur samma tabell som spelet och Roblox Stallet läser, inte en
     handskriven kopia av deras siffror. */
  + "\n" + las("src/spel/hastar.js")
  /* G02-C: Ugnetas bedömningskontrakt exporteras ur SAMMA fil som
     webben kör (src/larare.js). Roblox ska inte ha en handskriven kopia
     av vilka dimensioner en 20 m volt bedöms på — då skulle de två
     ytorna kunna glida isär utan att något blir rött. */
  + "\n" + las("src/larare.js"), ctx);
const { Gait, RID_ORDNING, K, HJALP_KANON, HJALP_FALT, HJALP_HARLEDDA, SVAR_KANON,
  SKOLHAST_PROFILER, SVAR_START, UGNETA_OVNING_DIM, UGNETA_DIM_LABEL,
  UGNETA_LIVE, UGNETA_DIM_CUE, UGNETA_KVALITET, UGNETA_PLATS, UGNETA_OVNINGAR, UGNETA_LIVE_CD } =
  vm.runInContext("({Gait, RID_ORDNING, K, HJALP_KANON, "
  + "HJALP_FALT, HJALP_HARLEDDA, SVAR_KANON, SKOLHAST_PROFILER, SVAR_START, "
  + "UGNETA_OVNING_DIM, UGNETA_DIM_LABEL, UGNETA_LIVE, UGNETA_DIM_CUE, "
  + "UGNETA_KVALITET, UGNETA_PLATS, UGNETA_OVNINGAR, UGNETA_LIVE_CD})", ctx);

/* Trösklarna står som literaler inne i Gait.forTempo — de går inte att läsa
   ut ur tabellen. I stället för att skriva av dem MÄTER vi dem: kör
   forTempo utan tidigare gångart (då gäller inte hysteresen) och notera var
   svaret byter. Då kan trösklarna aldrig hamna i osynk med koden. */
function mataTrosklar() {
  const ut = [];
  /* Grovsvep för att hitta VAR ett byte sker, sedan halvering för att hitta
     EXAKT var. Utan halveringen blir tröskeln beroende av svepets steglängd
     (0,0005 gav 2,2005 i stället för 2,20) och exporten slutar vara
     deterministisk mot koden den påstår sig mäta. */
  let forra = Gait.forTempo(0, null);
  for (let i = 1; i <= 24000; i++) {
    const t = i * 0.0005, g = Gait.forTempo(t, null);
    if (g === forra) continue;
    let lo = t - 0.0005, hi = t;
    for (let k = 0; k < 60; k++) {
      const m = (lo + hi) / 2;
      if (Gait.forTempo(m, null) === forra) lo = m; else hi = m;
    }
    ut.push({ under: Math.round(hi * 1e6) / 1e6, gangart: g });
    forra = g;
  }
  return ut;
}

/* Telemetrins fältnamn läses ur ett riktigt anrop, inte ur en handskriven
   lista — då kan ett fält aldrig försvinna ur kontraktet obemärkt. */
function telemetriFalt() {
  const ride = vm.runInContext("nyState(0.7,0.5,0.8)", ctx);
  ride.gangart = "trav"; ride.tempo = 3.2; ride.steglangd = 2.2;
  const tm = ctx.ridTelemetri(ride, { skankel: 0.5, tygel: 0.4, sits: 0.5, styrning: 0 },
    { kappa: 0.1, fas: 0.25 });
  return { falt: Object.keys(tm)
             .filter(k => !k.startsWith("_") && k !== "hjalpHarledda").sort(),
           harledda: tm._harledda.slice().sort(),
           /* Hjälpernas fältnamn läses ur SAMMA anrop, inte ur listan de
              påstår sig följa — då kan HJALP_FALT inte hamna i osynk med
              det hjalpSemantik faktiskt returnerar. */
           hjalpFalt: Object.keys(tm.hjalper).sort(),
           /* Indelningen hjälp/svar läses ur samma anrop som fälten. */
           svarFalt: tm._svarFalt.slice().sort() };
}

const tal = v => {
  if (!Number.isFinite(v)) return "math.huge";
  const r = Math.round(v * 1e6) / 1e6;
  return Object.is(r, -0) ? "0" : String(r);
};
const str = s => '"' + String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';

/* STYRKANONEN läses ur `RID_KANON` i src/riding/telemetri.js — objektet
   som src/game.js själv konsulterar. Förut skrapades literalerna ur
   game.js med regex; nu finns de på ett ställe som går att KÖRA, så
   exporten och spelet kan inte längre läsa olika saker.

   Hette `RID_AB.A` medan review-lägets A/B levde. Efter PO-beslutet
   2026-09-05 finns bara en uppsättning, och namnet säger det.

   Tidskonstanterna står fortfarande som literaler inne i stegaRitt() och
   läses som text. Mönstret är avsiktligt strikt och exporten FALLER om
   det försvinner: en tyst nolla vore värre än ett stopp, eftersom
   paritetsspecen då skulle jämföra mot ingenting och bli grön. */
function styrkanon() {
  const AB = vm.runInContext("(typeof RID_KANON!=='undefined')?{A:RID_KANON}:null", ctx);
  if (!AB || !AB.A) {
    console.error("FEL  hittar inte RID_KANON i src/riding/telemetri.js");
    console.error("     styrkanonen kan inte exporteras");
    process.exit(1);
  }
  /* Mönstret tål nu att uttrycket är inklamrat och skalas per gångart
     (G02-A.1 P3: `(...?0.13:0.19)*svangTau`). Baskonstanterna är vad som
     exporteras; gångartsfaktorn ligger i SVANGTAU och speglas separat. */
  const tm = las("src/game.js").match(/const kappaTau=\(?[^?]*\?\s*([0-9.]+)\s*:\s*([0-9.]+)\)?/);
  if (!tm) {
    console.error("FEL  hittar inte kappaTau i src/game.js");
    console.error("     rätta mönstret i den här filen");
    process.exit(1);
  }
  return { svang: AB.A.GANGSVANG, kappaMax: AB.A.KAPPA_MAX, svangTau: AB.A.SVANGTAU,
    ratTid: AB.A.KAPPA_RAT_TID,
    tauPress: Number(tm[1]), tauRelease: Number(tm[2]) };
}

/* Kameraläget per gångart ur src/scen3d.js (G02-A.1 P6). Läses som
   text: scen3d.js drar in hela renderaren om den körs, och det enda som
   behövs är tabellen. Mönstret är strikt och exporten faller om det
   inte träffar — en tyst tom tabell hade gjort paritetsspecen grön mot
   ingenting. */
function kameralagen() {
  const m = las("src/scen3d.js").match(/const KAM_GANG=\{([\s\S]*?)\};/);
  if (!m) {
    console.error("FEL  hittar inte KAM_GANG i src/scen3d.js");
    console.error("     rätta mönstret i den här filen");
    process.exit(1);
  }
  const ut = {};
  for (const rad of m[1].matchAll(/(\w+)\s*:\{bak:([0-9.]+),\s*hojd:([0-9.]+),\s*fov:([0-9.]+)\}/g)) {
    ut[rad[1]] = { bak: Number(rad[2]), hojd: Number(rad[3]), fov: Number(rad[4]) };
  }
  for (const namn of RID_ORDNING) if (!ut[namn]) {
    console.error(`FEL  KAM_GANG saknar ${namn}`);
    process.exit(1);
  }
  return ut;
}

/* ══════════════════════════════════════════════════════════════════
   CONTEXTKÄLLORNA (senior re-review av #87, blocker 2)

   Reviewen: "Om vissa externa contextkällor medvetet saknas på Roblox
   ska de deklareras separat och får inte samtidigt passera som `inga
   svarsluckor`." Det var precis vad som hände — Svar.SAKNAS var tom
   och ett test krävde att den skulle vara det, medan fem ingångar i
   själva verket anropades med sina neutrala element.

   Listan nedan skrivs INTE för hand. Den MÄTS: stepRide körs med
   `a`, `s` och `ctx` bakom en Proxy som noterar varje läsning. Sveper
   över de grenar som bara nås av vissa hjälper, så att en källa som
   bara läses vid hård tygel eller i galopp också kommer med.

   Poängen är gaten: lägger webben till en contextkälla dyker den upp
   här, och Roblox-specen blir röd tills källan antingen har ett hem på
   Roblox eller står i Svar.KONTEXT_SAKNAS. En lucka kan inte längre
   uppstå tyst. */
function kontextKallor() {
  const sedda = new Set();
  const spar = (prefix, obj) => new Proxy(obj, {
    get(t, k) {
      if (typeof k === "string") sedda.add(prefix + "." + k);
      const v = t[k];
      /* Nästlade contextobjekt följs med — `ctx.fard.lugn` är en egen
         källa och inte samma sak som att `ctx.fard` finns. */
      return (v && typeof v === "object" && !Array.isArray(v)) ? spar(prefix + "." + k, v) : v;
    },
  });
  /* Sveper de grenar som bara nås av vissa hjälper eller gångarter. */
  const hjalpSvep = [
    { skankel: 0.50, tygel: 0.40, sits: 0.30, styrning: 0.0, spo: false },
    { skankel: 0.95, tygel: 0.80, sits: 0.90, styrning: 0.9, spo: true },
    { skankel: 0.10, tygel: 0.10, sits: 0.10, styrning: -0.5, spo: false },
  ];
  const hast = { kanslighet: 0.6, forlatande: 0.6, skygghet: 0.3, tyngd: 0.4,
    framatbjudning: 0.6, utbildning: 0.7, kategori: "hast", profil: "skolhast",
    flaggor: { radd_for_spo: true } };
  for (const a of hjalpSvep) {
    for (const gangart of RID_ORDNING) {
      const st = vm.runInContext("nyState()", ctx);
      st.gangart = gangart;
      st.tempo = Gait.G[gangart].norm;
      const c = { svangradie: 12, underlag: 0.9, stallro: 0.9, utomhus: true,
        fard: { tygelband: 0.05, skygghet: 0.1, lugn: 0.05, halla: 0.3 }, avdrift: 0.02 };
      ctx.stepRide(spar("s", st), spar("a", a), hast, spar("ctx", c), 1 / 60);
    }
  }
  /* Bara CONTEXT och HJÄLP intresserar kontraktet — ridtillståndets egna
     fält (tempo, gångart, skalan …) ägs av modellen på båda ytorna och
     står redan i telemetrikontraktet. Kvar blir de ingångar som kommer
     UTIFRÅN: ryttarens hjälper, världen och hästens dag. */
  const STAT_CONTEXT = new Set(["s.sadellage", "s.dagsform", "s.rang"]);
  return [...sedda].filter(n => n.startsWith("ctx.") || n.startsWith("a.")
      || STAT_CONTEXT.has(n))
    /* `ctx.fard` som helhet är behållaren, inte en källa. */
    .filter(n => n !== "ctx.fard")
    .sort();
}

const { falt, harledda, hjalpFalt, svarFalt } = telemetriFalt();
const kontext = kontextKallor();

/* ══════════════════════════════════════════════════════════════════
   CROSS-PLATFORM-SCENARIOT (senior re-review av #87, blocker 2)

   Reviewen: "formelparitet är grön men runtimeparitet är inte samma
   produktbeteende". Golden-raderna bevisade att funktionerna räknar
   lika på givna tal. De bevisade INTE att en ritt utvecklar sig lika,
   för utgångsläget skilde sig och ingen körning jämfördes.

   Här körs en RITT. Webbens riktiga stepRide, bildruta för bildruta,
   med samma häst, samma utgångsläge och samma context som Roblox har.
   Roblox-specen kör samma ritt genom en riktig MovementController och
   jämför fem storheter i sex mätpunkter.

   VAR GRÄNSEN GÅR, uttryckligen: jämförelsen börjar vid SEMANTISKA
   HJÄLPER per bildruta, inte vid tangenttryck. Inputlagren får skilja
   sig — det är paritetsregelns "rendering, UI och inputadapter får vara
   plattformsspecifika". Att hjälpen leder till samma svar är det som
   ska vara lika, och det är det som mäts.

   GÅNGARTSBEGÄRAN mäts, den skrivs inte. Webbens cue faller ur
   hjälpens impuls över ett fönster; Roblox har tangentflanker. Vilka
   bildrutor webben faktiskt bad om nästa gångart på noteras här, och
   Roblox sätter sin flank på exakt de bildrutorna. Annars hade
   scenariot jämfört två olika ritter.

   CONTEXTEN ÄR ROBLOX. De nio källor som saknas där (se
   Svar.KONTEXT_SAKNAS) körs på sina neutrala element också på webben,
   så att det som mäts är modellen och inte den kända luckan. Vad
   luckan är VÄRD mäts separat, i SCENARIO.WEBB_CONTEXT. */
function scenario() {
  const HZ = 60, dt = 1 / HZ;
  const HORSES = vm.runInContext("HORSES", ctx);
  /* TVÅ VERKLIGA UBRF-HÄSTAR med var sin profil, ur src/spel/hastar.js —
     samma tabell Roblox Stallet läser. Att det är två och inte en är
     inte pynt: `kanslig` ligger i svarstidens golv medan `tung` ligger
     mitt i bandet, så en mätpunkt som bara visade golvet inte kan
     passera som bevis för att svarstiden räknas alls. */
  const HAST_ID = ["crokino", "mac_kenzie"];

  /* VARJE HJÄLPVÄRDE ÄR NÅBART PÅ BÅDA YTORNA. Roblox inputlager
     bygger skänkel, tygel och sits kring RidKanon.KONTAKT:s neutrallägen
     och når som mest SKANKEL 0,78 / TYGEL_MAX / SITS_MAX. Ett scenario
     med tygel 0,30 hade varit omöjligt att rida på Roblox — där klampas
     tygeln vid neutralläget 0,34 — och jämförelsen hade då mätt
     inputlagrens spann i stället för hästens svar. Baslinjen är därför
     exakt neutralläget, och utslagen ligger inom spannen.

     STYRNINGEN ÄR NOLL HELA RITTEN, med avsikt. Böjkrav och svängens
     fartkrav läser hästens FART, och farten kommer ur gångartstabellen
     — webbens BAND och Roblox Gaits är två intrimmade tabeller med
     kända, listade avvikelser (se paritetsspecen). En sväng hade mätt
     den skillnaden och inte svarsmodellen. Kurvaturpariteten har egna
     kontroller: paritetsspecens kurvaturtak och webbens 20 m-volt. */
  const KN = { skankel: K.SKANKEL_NEUTRAL, tygel: K.TYGEL_NEUTRAL,
    sits: K.SITS_NEUTRAL, top: 0.78, sitsMax: K.SITS_MAX };
  function hjalp(t) {
    const bas = { skankel: KN.skankel, tygel: KN.tygel, sits: KN.sits,
      styrning: 0, parad: 0, spo: false };
    /* Impulserna: en ramp på 0,10 s upp och kvar. Samma form som
       src/game.js ger en tangent, mätt över samma fönster. */
    const puls = (t0, topp, fran) => {
      if (t < t0) return fran;
      if (t < t0 + 0.10) return fran + (topp - fran) * ((t - t0) / 0.10);
      if (t < t0 + 0.45) return topp;
      return fran;
    };
    if (t >= 1.00 && t < 1.60) bas.skankel = puls(1.00, KN.top, KN.skankel);
    if (t >= 3.00 && t < 3.60) bas.skankel = puls(3.00, KN.top, KN.skankel);
    /* OSTADIG HAND, 5,0–6,5 s. Handen puttrar med 3 Hz UPPÅT ur
       neutralläget: mjukheten faller, spänningen stiger, fokus följer
       med ned och svaret blir segare. Det är kedjan G02-B påstår finns,
       körd skarpt. Uppåt och inte kring — under neutralläget finns
       ingen Roblox-input, och en oåtkomlig hjälp bevisar ingenting.
       Toppen är TYGEL_MAX 0,80, hela vägen genom kontaktbandet och över
       hård hand (0,72), för att spänningen ska HÄNDA: en lugnare hand
       ger de här hästarna inomhus ingen spänning alls, och en mätpunkt
       som bara visar noll bevisar ingenting om modellen. */
    if (t >= 5.00 && t < 6.50)
      bas.tygel = KN.tygel + 0.46 * (0.5 - 0.5 * Math.cos((t - 5.00) * 2 * Math.PI * 3));
    /* 6,5–8,5 s: handen tillbaka i neutralläget. Spänningen ska FALLA
       igen — att den kan gå ned är lika mycket modell som att den kan
       gå upp, och en ritt som bara stiger bevisar bara halva kurvan. */
    if (t >= 8.50 && t < 9.10) bas.skankel = puls(8.50, KN.top, KN.skankel);
    /* PARADEN, 10,0 s: sits och tygel tillsammans, skänkeln kvar. */
    if (t >= 10.00 && t < 10.20) { bas.sits = KN.sitsMax; bas.tygel = 0.52; bas.parad = 1; }
    return bas;
  }

  /* 0,05 och 0,30 s ligger med för att UTGÅNGSLÄGET ska mätas och inte
     bara påstås. Spänningen startar på 0,15 och faller mot noll på under
     en sekund för en lugn häst inomhus — en första mätpunkt vid 1,0 s
     hade sett noll oavsett vad ritten började på, och en Roblox som
     startade på 0 hade passerat. Uppmätt: den mutationen gav noll röda
     innan de här två raderna fanns. */
  const MATPUNKTER = [0.05, 0.30, 1.0, 2.5, 4.5, 6.0, 8.0, 9.5, 11.0, 12.0];
  const TOT = Math.round(12.0 * HZ);

  /* Hjälperna en gång — de är hästoberoende. Glest: en rad först när
     något faktiskt ändras, och Roblox håller kvar förra raden. En tät
     tabell hade varit 720 rader i åtta testbyggen utan att säga mer. */
  const steg = [];
  {
    let forra = null;
    for (let i = 0; i < TOT; i++) {
      const a = hjalp(i * dt);
      const nyckel = [a.skankel, a.tygel, a.sits, a.styrning, a.parad].join(",");
      if (nyckel !== forra) {
        steg.push({ i, skankel: a.skankel, tygel: a.tygel, sits: a.sits,
          styrning: a.styrning, parad: a.parad });
        forra = nyckel;
      }
    }
  }

  /* En ritt per häst och context. `ctxNamn` "roblox" = de nio saknade
     källorna på sina neutrala element (det Roblox faktiskt kör),
     "webb" = webbens egna. Skillnaden mellan de två ÄR den deklarerade
     luckans värde, i siffror. */
  function rid(hast, ctxNamn) {
    const st = vm.runInContext("nyState()", ctx);
    const c = ctxNamn === "roblox"
      ? { svangradie: 1000, underlag: 1, stallro: 1, utomhus: false, fard: {}, avdrift: 0 }
      : { svangradie: 1000, underlag: 0.92, stallro: 0.9, utomhus: false,
          fard: { tygelband: 0.05, skygghet: 0.10, lugn: 0.05 }, avdrift: 0.02 };
    const bedd = [], matt = [];
    let n = 0, tid = 0, forraBedd = st.beddGangart;
    for (let i = 0; i < TOT; i++) {
      ctx.stepRide(st, hjalp(tid), hast, c, dt);
      /* Vilken gångart ryttaren BAD om, och på vilken bildruta — MÄTT,
         inte skrivet. Webbens cue faller ur hjälpens impuls över ett
         fönster; Roblox har tangentflanker. Roblox-specen sätter sin
         flank på exakt de här bildrutorna, annars hade scenariot
         jämfört två olika ritter. */
      /* `beddGangart` och inte `malGangart`: det förra är vad ryttaren
         BAD om, det senare vad hästen hunnit svara på. De skiljer sig med
         hela svarstiden, och att läsa fel av de två la Roblox flank fyra
         bildrutor efter webbens — mitt i en oscillerande tygel blev
         hjälpens tydlighet då en annan, och svarstiderna drev isär. */
      if (st.beddGangart !== forraBedd) {
        bedd.push({ i, gangart: st.beddGangart });
        forraBedd = st.beddGangart;
      }
      tid += dt;
      while (n < MATPUNKTER.length && tid >= MATPUNKTER[n] - dt / 2) {
        matt.push({ t: MATPUNKTER[n], i, gangart: st.gangart,
          svarstid: st.svarstid, balans: st.balans, fokus: st.fokus,
          spanning: st.spanning, energi: st.energi });
        n++;
      }
    }
    return { bedd, matt };
  }

  const hastar = HAST_ID.map(id => {
    const h = HORSES[id];
    const r = rid(h, "roblox");
    return { id, profil: h.profil, kanslighet: h.kanslighet,
      forlatande: h.forlatande, skygghet: h.skygghet, utbildning: h.utbildning,
      tyngd: h.tyngd, bedd: r.bedd, matt: r.matt, webb: rid(h, "webb").matt };
  });
  return { HZ, TOT, MATPUNKTER, steg, hastar };
}

const scen = scenario();


const styr = styrkanon();
const kam = kameralagen();
const trosklar = mataTrosklar();

const rader = [];
rader.push("--!strict");
rader.push("--[[");
rader.push("\tGENERERAD FIL — handredigera inte.");
rader.push("");
rader.push("\tSkrivs av tools/exportera-ridkanon.mjs ur webbens src/model.js och");
rader.push("\tsrc/riding/telemetri.js. Det här är WEBBENS ridkanon, exporterad så att");
rader.push("\tRoblox-sidan har något exakt att mäta sig mot i stället för att två");
rader.push("\tuppsättningar siffror driver isär i tysthet.");
rader.push("");
rader.push("\tModulen STYR ingenting i Roblox — Gaits.luau är fortfarande Roblox");
rader.push("\tegna, intrimmade tabell. Den här filen används av");
rader.push("\troblox/tests/paritet.spec.luau för att jämföra, och för att lista de");
rader.push("\tavvikelser som faktiskt finns. Att jämna ut en avvikelse är ett");
rader.push("\tproduktbeslut och ändrar ridkänslan; det görs aldrig av en export.");
rader.push("");
rader.push("\tKör om med:  node tools/exportera-ridkanon.mjs");
rader.push("]]");
rader.push("");
rader.push("local RidKanon = {}");
rader.push("");
rader.push("--[[ Webbens gångartsordning. Roblox har en gångart till (fyrsprång);");
rader.push("     paritetsspecen kräver att den här är ett PREFIX av Roblox ordning. ]]");
rader.push("RidKanon.ORDNING = { " + RID_ORDNING.map(str).join(", ") + " }");
rader.push("");
rader.push("--[[ Vilken Roblox-gångart varje webbgångart motsvarar. ]]");
rader.push("RidKanon.MOTSVARIGHET = {");
for (const [w, r] of [["halt", "halt"], ["skritt", "walk"], ["trav", "trot"], ["galopp", "canter"]]) {
  rader.push(`\t${w} = ${str(r)},`);
}
rader.push("}");
rader.push("");
rader.push("--[[ Gångartsbanden ur src/model.js (Gait.G). min/max i m/s, norm är");
rader.push("     gångartens normaltempo, steg är webbens steglängdsfaktor.");
rader.push("");
rader.push("     upp/ner är G02-A.1 P3: hur många m/s² hon tar respektive släpper");
rader.push("     INOM gångarten. De är Roblox egna accel/retard, portade till");
rader.push("     webben — inte en andra uppsättning tal. Paritetsspecen kräver");
rader.push("     att de fortfarande är identiska, och att de skiljer sig åt");
rader.push("     mellan gångarterna: en gemensam siffra vore just den vikt per");
rader.push("     gångart som P3 införde. ]]");
rader.push("RidKanon.BAND = {");
for (const namn of RID_ORDNING) {
  const g = Gait.G[namn];
  rader.push(`\t${namn} = { min = ${tal(g.min)}, max = ${tal(g.max)}, norm = ${tal(g.norm)}, steg = ${tal(g.steg)}, upp = ${tal(g.upp)}, ner = ${tal(g.ner)} },`);
}
rader.push("}");
rader.push("");
rader.push("--[[ ÖVERGÅNGSFÖRLOPPET (G02-A.1 P2/P5, harmoniserat efter senior");
rader.push("     review 2026-09-05). Sekunder för en NEUTRAL häst; hästens egen");
rader.push("     tyngd respektive acceleration skalar därifrån med 1,0 i mitten.");
rader.push("");
rader.push("     upp     per gångart man går TILL");
rader.push("     nerMjuk längden när ryttaren bara håller emot");
rader.push("     nerHart  längden vid full parad — bestämdheten interpolerar");
rader.push("     bytpunkt hur långt in i förloppet gångartsETIKETTEN byter");
rader.push("");
rader.push("     Kurvan är samma på båda ytorna: mjukstegskurvan u²(3−2u),");
rader.push("     som börjar och slutar med noll lutning. Roblox har talen i");
rader.push("     Config.MOVEMENT.Transition och paritetsspecen jämför dem. ]]");
rader.push("RidKanon.OVERGANG = {");
rader.push("\tupp = {");
for (const namn of RID_ORDNING) {
  const v = K.OVERGANG.upp[namn];
  if (v !== undefined) rader.push(`\t\t${namn} = ${tal(v)},`);
}
rader.push("\t},");
rader.push(`\tnerMjuk = ${tal(K.OVERGANG.nerMjuk)},`);
rader.push(`\tnerHart = ${tal(K.OVERGANG.nerHart)},`);
rader.push(`\tbytpunkt = ${tal(K.OVERGANG.BYTPUNKT)},`);
rader.push("}");
rader.push("");
rader.push("--[[ Hysteres: hur långt utanför sitt band en gångart får leva kvar. ]]");
rader.push(`RidKanon.HYSTERES = ${tal(Gait.HYST)}`);
rader.push("");
rader.push("--[[ Trösklarna, MÄTTA ur Gait.forTempo — inte avskrivna. ]]");
rader.push("RidKanon.TROSKLAR = {");
for (const t of trosklar) rader.push(`\t{ under = ${tal(t.under)}, gangart = ${str(t.gangart)} },`);
rader.push("}");
rader.push("");
rader.push("--[[ STYRKANONEN ur stegaRitt() i src/game.js. Kurvaturtaket i 1/m vid");
rader.push("     full styrning, gångarternas svängfaktorer, och tidskonstanterna för");
rader.push("     att lägga sig i respektive räta upp sig ur en båge. ]]");
rader.push(`RidKanon.KAPPA_MAX = ${tal(styr.kappaMax)}`);
rader.push(`RidKanon.KAPPA_TAU_LAGG = ${tal(styr.tauPress)}`);
rader.push(`RidKanon.KAPPA_TAU_RATA = ${tal(styr.tauRelease)}`);
rader.push("RidKanon.SVANGFAKTOR = {");
for (const namn of RID_ORDNING) rader.push(`\t${namn} = ${tal(styr.svang[namn])},`);
rader.push("}");
rader.push("");
rader.push("--[[ Gångartens TRÖGHET i styrningen (G02-A.1 P3). Multiplikator på");
rader.push("     KAPPA_TAU_LAGG/RATA. SVANGFAKTOR säger hur snävt hon KAN svänga,");
rader.push("     den här hur snabbt bågen ändras. Speglas i Gaits.svangTau. ]]");
rader.push("RidKanon.SVANGTAU = {");
for (const namn of RID_ORDNING) rader.push(`\t${namn} = ${tal(styr.svangTau[namn])},`);
rader.push("}");
rader.push("");
rader.push("--[[ Sekunder från rakt till full båge (G02-A.1 P4). Kurvaturen får");
rader.push("     inte ändras fortare än gångartens kurvaturtak delat med den här");
rader.push("     tiden. Speglas i Config.MOVEMENT.CurvatureRateTime. ]]");
rader.push(`RidKanon.KAPPA_RAT_TID = ${tal(styr.ratTid)}`);
rader.push("");
rader.push("--[[ Kameraläget per gångart ur src/scen3d.js (G02-A.1 P6). bak i");
rader.push("     meter bakom hästen, hojd i meter, fov som tillägg i radianer.");
rader.push("");
rader.push("     ABSOLUTA tal ska INTE vara lika på de två ytorna — rendering får");
rader.push("     vara plattformsspecifik. FÖRHÅLLANDET mellan gångarterna ska det,");
rader.push("     för det är förhållandet man känner. Paritetsspecen jämför därför");
rader.push("     kvoter mot skritt, inte tal mot tal. ]]");
rader.push("RidKanon.KAMERA = {");
for (const namn of RID_ORDNING) {
  const c = kam[namn];
  rader.push(`\t${namn} = { bak = ${tal(c.bak)}, hojd = ${tal(c.hojd)}, fov = ${tal(c.fov)} },`);
}
rader.push("}");
rader.push("");
rader.push("--[[ Telemetrins fältnamn, lästa ur ett riktigt anrop av ridTelemetri. ]]");
rader.push("RidKanon.TELEMETRI_FALT = { " + falt.map(str).join(", ") + " }");
rader.push("");
rader.push("--[[ Fält som är HÄRLEDDA, inte mätta. Ärlig märkning för G02-B. ]]");
rader.push("RidKanon.HARLEDDA = { " + harledda.map(str).join(", ") + " }");
rader.push("");
rader.push("--[[ HJÄLPERNAS SEMANTIK (G02-B punkt 1, src/riding/hjalper.js).");
rader.push("");
rader.push("     Webbens ridning har fyra AXLAR — skänkel, styrning, tygel, sits —");
rader.push("     och ovanpå dem ridningens ord: innertygel, yttertygel, yttertygel-");
rader.push("     stöd, böjsida, vikt och paraden som en EGEN signal. Inner och");
rader.push("     ytter härleds ur styr- och tygelaxeln, så ingen ny kontroll behövs");
rader.push("     på någon yta; talen nedan är översättningen.");
rader.push("");
rader.push("     Roblox rörelsekärna har ännu inget hjälplager alls (se");
rader.push("     Telemetri.SAKNAS). Kanonen exporteras hit FÖRE implementationen");
rader.push("     med flit: när Roblox-sidan bygger sina hjälper ska den läsa de här");
rader.push("     talen, inte skriva av dem. ]]");
rader.push("RidKanon.HJALP = {");
for (const namn of Object.keys(HJALP_KANON)) rader.push(`\t${namn} = ${tal(HJALP_KANON[namn])},`);
rader.push("}");
rader.push("");
rader.push("--[[ Hjälpernas fältnamn, lästa ur ett riktigt anrop av ridTelemetri. ]]");
rader.push("RidKanon.HJALP_FALT = { " + hjalpFalt.map(str).join(", ") + " }");
rader.push("");
rader.push("--[[ Hjälpfält som är HÄRLEDDA ur axlarna, inte egna kontroller. ]]");
rader.push("RidKanon.HJALP_HARLEDDA = { " + HJALP_HARLEDDA.slice().sort().map(str).join(", ") + " }");
rader.push("");
rader.push("--[[ KONTRAKTET G02-C LÄSER (G02-B punkt 5).");
rader.push("");
rader.push("     Telemetrin ska exponera BÅDE hjälpen och responsen, och en");
rader.push("     läsare måste kunna se vilka fält som är vad. HJALP_FALT är vad");
rader.push("     ryttaren gör, SVAR_FALT vad hästen svarar. Listorna kommer ur");
rader.push("     webbens moduler, inte ur en handskriven uppräkning. ]]");
rader.push("RidKanon.SVAR_FALT = { " + svarFalt.map(str).join(", ") + " }");
rader.push("");
rader.push("--[[ HÄSTENS SVAR (G02-B punkt 2, src/riding/svar.js).");
rader.push("");
rader.push("     Fördröjning, fokus, balans och energi som riktiga storheter. Webben");
rader.push("     har dem i modellen; Roblox har dem inte alls ännu, och det står som");
rader.push("     LUCKA i paritetsspecen i stället för att fyllas med gissningar.");
rader.push("");
rader.push("     ENERGI_TAPP/ENERGI_ATER är per sekund och per gångart, med webbens");
rader.push("     namn. Roblox gångartsnamn översätts av RidKanon.MOTSVARIGHET. ]]");
rader.push("--[[ KONTAKTEN — modellens K-konstanter som hjälpsemantiken behöver.");
rader.push("");
rader.push("     Skänkelns tröskel och tygelns kontaktband ÄGS av src/model.js och");
rader.push("     läses härifrån av Roblox-sidan i stället för att skrivas av. Det är");
rader.push("     samma tal som avgör om en halvhalt är välriden på webben. ]]");
rader.push("RidKanon.KONTAKT = {");
for (const namn of ["SKANKEL_TROSKEL", "SKANKEL_FOR_MYCKET", "SKANKEL_NEUTRAL",
                    "TYGEL_BAND_MIN", "TYGEL_BAND_MAX", "TYGEL_NEUTRAL", "TYGEL_MAX",
                    "TYGEL_HART", "SITS_NEUTRAL", "SITS_PARAD", "SITS_MAX",
                    /* Mjukheten och spänningen: konstanterna Roblox behöver för
                       att räkna dem med webbens formler i stället för egna. */
                    "AIDS_TAU", "AMPLITUD_SKALA", "MJUKHET_EMA",
                    "SPANNING_STIGNING", "SPANNING_FALL"]) {
  rader.push(`\t${namn} = ${tal(K[namn])},`);
}
rader.push("}");
rader.push("");
rader.push("--[[ SKOLHÄSTPROFILERNA (G02-B punkt 3). Multiplikatorer på SVAR");
rader.push("     ovan — INTE egna kodvägar. `skolhast` är 1,00 rakt igenom och");
rader.push("     därmed modellens utgångsläge; varje annan profil mäts mot den.");
rader.push("");
rader.push("     Vilken häst som har vilken profil ligger i UBRFSpelData");
rader.push("     (fältet `profil`), tilldelad ur ridskolans egna beskrivningar.");
rader.push("     Se src/spel/hastar.js för citaten. ]]");
rader.push("RidKanon.PROFILER = {");
for (const namn of Object.keys(SKOLHAST_PROFILER)) {
  const pr = SKOLHAST_PROFILER[namn];
  const tal2 = Object.keys(pr).filter(k => typeof pr[k] === "number")
    .map(k => `${k} = ${tal(pr[k])}`).join(", ");
  rader.push(`\t${namn} = { namn = ${str(pr.namn)}, kort = ${str(pr.kort)}, ${tal2} },`);
}
rader.push("}");
rader.push("");
rader.push("RidKanon.SVAR = {");
for (const namn of Object.keys(SVAR_KANON)) {
  const v = SVAR_KANON[namn];
  if (typeof v === "number") { rader.push(`\t${namn} = ${tal(v)},`); continue; }
  rader.push(`\t${namn} = {`);
  for (const g of RID_ORDNING) if (v[g] !== undefined) rader.push(`\t\t${g} = ${tal(v[g])},`);
  rader.push("\t},");
}
rader.push("}");
rader.push("");
/* ── GOLDEN-RADER: webbens EGNA svar på ett par bestämda indata ──────
   Paritet mellan två implementationer bevisas inte av att konstanterna är
   lika — det bevisas av att formlerna ger samma tal. Raderna nedan RÄKNAS
   av webbens moduler här och nu, och Roblox-specen kör sin egen kod på
   samma indata och jämför. Skulle någon av de två driva iväg blir specen
   röd, även om varenda konstant fortfarande stämmer. */
const hjalpProv = [
  { skankel: 0.42, tygel: 0.34, styrning: 0.00 },
  { skankel: 0.42, tygel: 0.34, styrning: 0.72 },
  { skankel: 0.62, tygel: 0.57, styrning: 0.72 },
  { skankel: 0.78, tygel: 0.80, styrning: 0.36 },
  { skankel: 0.05, tygel: 0.22, styrning: 0.72 },
];
const svarProv = [
  { profil: "skolhast", kanslighet: 0.50, fokus: 1.00, energi: 1.00, klarhet: 0.00 },
  { profil: "skolhast", kanslighet: 0.50, fokus: 1.00, energi: 0.60, klarhet: 0.75 },
  { profil: "kanslig",  kanslighet: 0.80, fokus: 1.00, energi: 1.00, klarhet: 0.40 },
  { profil: "tung",     kanslighet: 0.30, fokus: 1.00, energi: 0.50, klarhet: 0.20 },
  { profil: "arbetsvillig", kanslighet: 0.60, fokus: 1.00, energi: 0.90, klarhet: 1.00 },
];
const balansProv = [
  { profil: "skolhast", utbildning: 0.60, bojkrav: 0.00, ytterstod: 1.00, fartkrav: 0.00, iOvergang: false, sits: 0.20 },
  { profil: "skolhast", utbildning: 0.60, bojkrav: 1.00, ytterstod: 0.40, fartkrav: 0.00, iOvergang: false, sits: 0.20 },
  { profil: "kanslig",  utbildning: 0.72, bojkrav: 1.00, ytterstod: 0.67, fartkrav: 0.20, iOvergang: true,  sits: 0.55 },
  { profil: "tung",     utbildning: 0.90, bojkrav: 0.80, ytterstod: 0.30, fartkrav: 0.50, iOvergang: false, sits: 0.78 },
  /* Samma sväng, tre sitsdjup: den raden är vad som visar att sätet ÄR
     en balansmodifierare och inte en märkning. */
  { profil: "skolhast", utbildning: 0.60, bojkrav: 1.00, ytterstod: 0.67, fartkrav: 0.00, iOvergang: false, sits: 0.20 },
  { profil: "skolhast", utbildning: 0.60, bojkrav: 1.00, ytterstod: 0.67, fartkrav: 0.00, iOvergang: false, sits: 0.78 },
];
const spanningProv = [
  { tygel: 0.34, skankel: 0.42, sits: 0.20, mjukhet: 1.00, rang: 0.50, gangart: "skritt",
    kanslighet: 0.50, forlatande: 0.60, skygghet: 0.20, utomhus: false },
  { tygel: 0.78, skankel: 0.42, sits: 0.20, mjukhet: 0.60, rang: 0.50, gangart: "trav",
    kanslighet: 0.80, forlatande: 0.40, skygghet: 0.42, utomhus: false },
  { tygel: 0.62, skankel: 0.90, sits: 0.82, mjukhet: 0.30, rang: 0.30, gangart: "galopp",
    kanslighet: 0.35, forlatande: 0.95, skygghet: 0.05, utomhus: true },
];
const fokusProv = [
  { mjukhet: 1.00, spanning: 0.00, utomhus: false, parad: 0.00, profil: "skolhast" },
  { mjukhet: 1.00, spanning: 0.00, utomhus: false, parad: 0.93, profil: "skolhast" },
  { mjukhet: 0.50, spanning: 0.40, utomhus: true,  parad: 0.00, profil: "kanslig" },
  { mjukhet: 0.80, spanning: 0.10, utomhus: false, parad: 0.60, profil: "tung" },
];
const hjalpSemantik = ctx.hjalpSemantik, svarSvarstid = ctx.svarSvarstid,
  svarBalansMal = ctx.svarBalansMal, svarInfall = ctx.svarInfall,
  svarEnergiTakt = ctx.svarEnergiTakt;
rader.push("--[[ GOLDEN-RADER — webbens egna svar på bestämda indata.");
rader.push("");
rader.push("     Räknade av src/riding/hjalper.js och src/riding/svar.js när den");
rader.push("     här filen genererades. Roblox-specen kör SIN kod på samma indata");
rader.push("     och jämför: driver de två isär blir den röd, även om varenda");
rader.push("     konstant fortfarande stämmer. Att konstanterna är lika bevisar");
rader.push("     inte att formlerna är det. ]]");
rader.push("RidKanon.PROV = {");
rader.push("\thjalper = {");
for (const a of hjalpProv) {
  const r = hjalpSemantik(a);
  rader.push(`\t\t{ in_ = { skankel = ${tal(a.skankel)}, tygel = ${tal(a.tygel)}, `
    + `styrning = ${tal(a.styrning)} }, ut = { innerTygel = ${tal(r.innerTygel)}, `
    + `ytterTygel = ${tal(r.ytterTygel)}, ytterstod = ${tal(r.ytterstod)}, `
    + `bojSida = ${tal(r.bojSida)} } },`);
}
rader.push("\t},");
rader.push("\tparadKvalitet = {");
for (const a of hjalpProv) {
  rader.push(`\t\t{ in_ = { skankel = ${tal(a.skankel)}, tygel = ${tal(a.tygel)} }, `
    + `ut = ${tal(ctx.paradKvalitet(a))} },`);
}
rader.push("\t},");
rader.push("\tsvarstid = {");
for (const v of svarProv) {
  const t2 = svarSvarstid({ kanslighet: v.kanslighet, profil: v.profil },
    v.fokus, v.energi, v.klarhet);
  rader.push(`\t\t{ in_ = { profil = ${str(v.profil)}, kanslighet = ${tal(v.kanslighet)}, `
    + `fokus = ${tal(v.fokus)}, energi = ${tal(v.energi)}, klarhet = ${tal(v.klarhet)} }, `
    + `ut = ${tal(t2)} },`);
}
rader.push("\t},");
rader.push("\tbalans = {");
for (const v of balansProv) {
  const b = svarBalansMal({ spanning: 0 }, { utbildning: v.utbildning, profil: v.profil },
    v.bojkrav, v.ytterstod, v.fartkrav, v.iOvergang, v.sits);
  rader.push(`\t\t{ in_ = { profil = ${str(v.profil)}, utbildning = ${tal(v.utbildning)}, `
    + `bojkrav = ${tal(v.bojkrav)}, ytterstod = ${tal(v.ytterstod)}, `
    + `fartkrav = ${tal(v.fartkrav)}, iOvergang = ${v.iOvergang}, `
    + `sits = ${tal(v.sits)} }, ut = ${tal(b)} },`);
}
rader.push("\t},");
rader.push("\tspanning = {");
for (const v of spanningProv) {
  /* MÅLVÄRDET, direkt ur webbens svarSpanningMal — inte ett steg av
     approach(). Roblox Svar.spanningMal jämförs mot exakt samma tal.
     Neutrala ingångar där Roblox saknar källa: stallro/sadellage/
     underlag 1, dagsform 0, inget spö. */
  const st = { mjukhet: v.mjukhet, spanning: 0, gangart: v.gangart, rang: v.rang,
    sadellage: 1, dagsform: 0 };
  const hast = { kanslighet: v.kanslighet, forlatande: v.forlatande,
    skygghet: v.skygghet, flaggor: {} };
  const aid = { skankel: v.skankel, tygel: v.tygel, sits: v.sits, styrning: 0, spo: false };
  const c2 = { underlag: 1, stallro: 1, utomhus: v.utomhus, fard: {} };
  const sp = ctx.svarSpanningMal(aid, hast, st, c2);
  rader.push(`\t\t{ in_ = { tygel = ${tal(v.tygel)}, skankel = ${tal(v.skankel)}, `
    + `sits = ${tal(v.sits)}, mjukhet = ${tal(v.mjukhet)}, rang = ${tal(v.rang)}, `
    + `gangart = ${str(v.gangart)}, kanslighet = ${tal(v.kanslighet)}, `
    + `forlatande = ${tal(v.forlatande)}, skygghet = ${tal(v.skygghet)}, `
    + `utomhus = ${v.utomhus} }, ut = ${tal(sp)} },`);
}
rader.push("\t},");
rader.push("\tfokus = {");
for (const v of fokusProv) {
  const st = { mjukhet: v.mjukhet, spanning: v.spanning };
  const f = ctx.svarFokusMal(st, { utomhus: v.utomhus }, v.parad, { profil: v.profil });
  rader.push(`\t\t{ in_ = { mjukhet = ${tal(v.mjukhet)}, spanning = ${tal(v.spanning)}, `
    + `utomhus = ${v.utomhus}, parad = ${tal(v.parad)}, profil = ${str(v.profil)} }, `
    + `ut = ${tal(f)} },`);
}
rader.push("\t},");
rader.push("\tinfall = {");
for (const [b, k] of [[1.0, 1.0], [0.73, 1.0], [0.5, 0.5], [0.0, 1.0]]) {
  rader.push(`\t\t{ in_ = { balans = ${tal(b)}, bojkrav = ${tal(k)} }, `
    + `ut = ${tal(svarInfall(b, k))} },`);
}
rader.push("\t},");
rader.push("\tenergiTakt = {");
for (const g of RID_ORDNING) {
  for (const pn of Object.keys(SKOLHAST_PROFILER)) {
    rader.push(`\t\t{ in_ = { gangart = ${str(g)}, profil = ${str(pn)} }, `
      + `ut = ${tal(svarEnergiTakt(g, 0, { profil: pn }))} },`);
  }
}
rader.push("\t},");
rader.push("}");
rader.push("");

/* ── UTGÅNGSLÄGET ────────────────────────────────────────────────── */
rader.push("--[[ UTGÅNGSLÄGET (senior re-review av #87, blocker 2).");
rader.push("");
rader.push("     Webben startade en ritt på spänning 0,15 och energi ≈ 0,835,");
rader.push("     Roblox på spänning 0 och energi 1. Formlerna var lika, ritten");
rader.push("     var det inte — och då är det inte samma produkt. Talen står nu");
rader.push("     i SVAR_START i src/riding/svar.js, exporteras hit, och BÅDA");
rader.push("     ytorna läser dem. Ingen siffra ändrades på webben.");
rader.push("");
rader.push("     ENERGI = ENERGI_BAS + ENERGI_DAG × dagsform. RANG_* är hur");
rader.push("     rangen växer under ritten; Roblox höll den låst på 0,5 och");
rader.push("     hade därmed en tyst skillnad i hela spänningsmodellen. ]]");
rader.push("RidKanon.START = {");
for (const namn of ["DAGSFORM", "SADELLAGE", "RANG", "SPANNING", "MJUKHET", "FOKUS",
                    "BALANS", "ENERGI_BAS", "ENERGI_DAG",
                    "RANG_PIVOT", "RANG_MJUK", "RANG_SPANN"]) {
  rader.push(`\t${namn} = ${tal(SVAR_START[namn])},`);
}
rader.push("}");
rader.push("");

/* ── CONTEXTKÄLLORNA ─────────────────────────────────────────────── */
rader.push("--[[ CONTEXTKÄLLORNA — allt som kommer UTIFRÅN in i ridmodellen.");
rader.push("");
rader.push("     MÄTT, inte skriven: stepRide körs med hjälperna, ridtillståndets");
rader.push("     contextfält och context-objektet bakom en Proxy som noterar varje");
rader.push("     läsning, över ett svep av hjälper och gångarter.");
rader.push("");
rader.push("     Roblox ska för var och en av de här ha ANTINGEN en källa i");
rader.push("     HorseCore.Svar.KONTEXT_HAR eller en deklarerad lucka i");
rader.push("     Svar.KONTEXT_SAKNAS. Paritetsspecen kräver att unionen är exakt");
rader.push("     den här listan. Lägger webben till en källa blir Roblox rött");
rader.push("     tills den fått ett hem — en lucka kan inte uppstå tyst, och");
rader.push("     `inga svarsluckor` kan inte längre gälla en yta som i själva");
rader.push("     verket kör nio ingångar på sina neutrala element. ]]");
rader.push("RidKanon.KONTEXT_KALLOR = { " + kontext.map(str).join(", ") + " }");
rader.push("");

/* ── CROSS-PLATFORM-SCENARIOT ────────────────────────────────────── */
rader.push("--[[ CROSS-PLATFORM-SCENARIOT (senior re-review av #87, blocker 2).");
rader.push("");
rader.push("     En RITT, inte en formel. Webbens riktiga stepRide, bildruta för");
rader.push("     bildruta, med två verkliga UBRF-hästar ur src/spel/hastar.js och");
rader.push("     med den context Roblox faktiskt har. Roblox-specen kör samma");
rader.push("     ritt genom en riktig MovementController och jämför fem storheter");
rader.push("     i åtta mätpunkter.");
rader.push("");
rader.push("     GRÄNSEN, uttryckligen: jämförelsen börjar vid SEMANTISKA HJÄLPER");
rader.push("     per bildruta, inte vid tangenttryck. Inputadaptern får vara");
rader.push("     plattformsspecifik enligt paritetsregeln; att hjälpen leder till");
rader.push("     samma svar får den inte.");
rader.push("");
rader.push("     STEG är glest: en rad först när en hjälp ändras, håll kvar");
rader.push("     mellan raderna. BEDD är vilken gångart ryttaren bad om och på");
rader.push("     vilken bildruta — mätt ur webbens cue-modell, så att Roblox");
rader.push("     tangentflank hamnar på exakt samma bildruta.");
rader.push("");
rader.push("     MATT är facit med Roblox context. WEBB är samma ritt med webbens");
rader.push("     egen context; skillnaden mellan de två är vad de deklarerade");
rader.push("     luckorna är VÄRDA, i siffror, i stället för bara namngivna. ]]");
rader.push(`RidKanon.SCENARIO = {`);
rader.push(`\tHZ = ${tal(scen.HZ)},`);
rader.push(`\tRUTOR = ${tal(scen.TOT)},`);
rader.push("\tSTEG = {");
for (const g of scen.steg) {
  rader.push(`\t\t{ i = ${g.i}, skankel = ${tal(g.skankel)}, tygel = ${tal(g.tygel)}, `
    + `sits = ${tal(g.sits)}, styrning = ${tal(g.styrning)}, parad = ${tal(g.parad)} },`);
}
rader.push("\t},");
rader.push("\tHASTAR = {");
for (const h of scen.hastar) {
  rader.push(`\t\t{`);
  rader.push(`\t\t\tid = ${str(h.id)}, profil = ${str(h.profil)},`);
  rader.push(`\t\t\tBEDD = {`);
  for (const b of h.bedd) rader.push(`\t\t\t\t{ i = ${b.i}, gangart = ${str(b.gangart)} },`);
  rader.push(`\t\t\t},`);
  for (const [namn, rows] of [["MATT", h.matt], ["WEBB", h.webb]]) {
    rader.push(`\t\t\t${namn} = {`);
    for (const m of rows) {
      rader.push(`\t\t\t\t{ t = ${tal(m.t)}, i = ${m.i}, gangart = ${str(m.gangart)}, `
        + `svarstid = ${tal(m.svarstid)}, balans = ${tal(m.balans)}, `
        + `fokus = ${tal(m.fokus)}, spanning = ${tal(m.spanning)}, `
        + `energi = ${tal(m.energi)} },`);
    }
    rader.push(`\t\t\t},`);
  }
  rader.push(`\t\t},`);
}
rader.push("\t},");
rader.push("}");
rader.push("");
/* ── UGNETA: G02-C:s bedömningskontrakt ───────────────────────────
   Vilka dimensioner en övning faktiskt bedöms på, och högsta antal
   observationer Ugneta får ge efter ett försök. Roblox läser det här
   i stället för att bära en egen lista. */
rader.push("--[[ G02-C: Ugnetas bedömningskontrakt, ur src/larare.js. ]]");
rader.push("RidKanon.UGNETA = {");
rader.push("\tMAX_OBSERVATIONER = 2,");
rader.push("\tDIMENSIONER = { " + Object.keys(UGNETA_DIM_LABEL).map(str).join(", ") + " },");
rader.push("\tOVNING = {");
for (const id of Object.keys(UGNETA_OVNING_DIM).sort())
  rader.push(`\t\t${id} = { ` + UGNETA_OVNING_DIM[id].map(str).join(", ") + " },");
rader.push("\t},");
/* Övningarnas ordning och text. Roblox undervisar samma sex övningar i
   samma följd med samma ord — inte en avskrift som kan glida. */
rader.push("\tORDNING = { " + UGNETA_OVNINGAR.map(o => str(o.id)).join(", ") + " },");
rader.push("\tOVNINGAR = {");
for (const o of UGNETA_OVNINGAR) {
  rader.push(`\t\t${o.id} = {`);
  rader.push(`\t\t\trubrik = ${str(o.rubrik)},`);
  rader.push("\t\t\tpunkter = { " + o.punkter.map(str).join(", ") + " },");
  rader.push("\t\t},");
}
rader.push("\t},");
/* Live-registret: samma få ord på båda ytorna. */
rader.push("\tLIVE = {");
for (const id of Object.keys(UGNETA_LIVE).sort())
  rader.push(`\t\t${id} = { fel = ${str(UGNETA_LIVE[id].fel)}, bra = ${str(UGNETA_LIVE[id].bra)} },`);
rader.push("\t},");
rader.push("\tLIVE_CD = { bra = " + tal(UGNETA_LIVE_CD.bra)
  + ", fel = " + tal(UGNETA_LIVE_CD.fel)
  + ", visa = " + tal(UGNETA_LIVE_CD.visa) + " },");
rader.push("\tDIM_CUE = {");
for (const k of Object.keys(UGNETA_DIM_CUE).sort())
  rader.push(`\t\t${k} = ${str(UGNETA_DIM_CUE[k])},`);
rader.push("\t},");
/* Kvalitetens tal. Utan dem hade Roblox-modulen skrivit av formeln. */
rader.push("\tKVALITET = {");
for (const k of Object.keys(UGNETA_KVALITET))
  rader.push(`\t\t${k} = ${tal(UGNETA_KVALITET[k])},`);
rader.push("\t},");
/* Platsen vid sargen, uttryckt i banans egna mått så att båda ytorna
   kan lösa upp den mot SIN bana. */
{
  /* Banans mått följer med platsen: den som ska lösa upp punkten mot en
     byggd bana behöver veta vilken bana webben räknade den ur, och ska
     inte behöva leta upp talen i en annan del av kanonen. */
  const KB = vm.runInContext("RID_KANON", ctx);
  rader.push("\tPLATS = { u = " + tal(UGNETA_PLATS.u)
    + ", bortomC = " + tal(UGNETA_PLATS.bortomC)
    + ", bredd = " + tal(KB.BANA_BREDD)
    + ", langd = " + tal(KB.BANA_LANGD) + " },");
}
rader.push("}");
rader.push("");

rader.push("return RidKanon");
rader.push("");
const utfil = "roblox/src/shared/HorseCore/RidKanon.luau";
const ny = rader.join("\n");
const abs = path.join(ROT, utfil);

if (process.argv.includes("--kontrollera")) {
  const gammal = fs.existsSync(abs) ? fs.readFileSync(abs, "utf8") : "";
  if (gammal === ny) { console.log(`OK   ${utfil} i synk med webbens ridmodell`); process.exit(0); }
  console.error(`FEL  ${utfil} är osynk med src/model.js / src/riding/telemetri.js`);
  console.error("     kör: node tools/exportera-ridkanon.mjs");
  process.exit(1);
}
fs.writeFileSync(abs, ny);
console.log(`${utfil}: ${RID_ORDNING.length} gångarter, ${trosklar.length} trösklar, ${falt.length} telemetrifält, ${kontext.length} contextkällor, scenario ${scen.steg.length} steg × ${scen.hastar.length} hästar`);
