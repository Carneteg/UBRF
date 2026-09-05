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
vm.runInContext(las("src/model.js") + "\n" + las("src/riding/telemetri.js"), ctx);
const { Gait, RID_ORDNING } = vm.runInContext("({Gait, RID_ORDNING})", ctx);

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
  return { falt: Object.keys(tm).filter(k => k !== "_harledda").sort(), harledda: tm._harledda.slice().sort() };
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

const { falt, harledda } = telemetriFalt();
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
console.log(`${utfil}: ${RID_ORDNING.length} gångarter, ${trosklar.length} trösklar, ${falt.length} telemetrifält`);
