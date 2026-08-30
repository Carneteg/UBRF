#!/usr/bin/env node
/* Exporterar anläggningens geometri ur src/site.js till en Luau-modul som
   Roblox-bygget läser.

   Poängen är att det bara finns EN sanning om UBRF:s geometri. src/site.js är
   den; den här filen kopierar inte måtten utan räknar ut dem ur samma kod som
   webbspelet kör. Skriv aldrig ett mått för hand i den genererade filen — kör
   om exporten i stället:

       node tools/exportera-geometri.js

   Exporten är deterministisk: samma src/site.js ger samma byte, utan datum
   eller versionsnummer i utdata. Därför går det att kontrollera att modulen är
   i synk med ett vanligt `git diff --exit-code` efter en körning, och det är så
   regressionstestet gör det.

   Måtten är i METER, precis som i src/site.js och i byggnadskorten. BuildKit
   räknar om till studs. Koordinatsystemet är detsamma: origo i sydväst,
   +x öster, +y norr — i Roblox blir spelets y byggnadens z. */

const fs = require("fs");
const vm = require("vm");
const path = require("path");

const ROT = path.resolve(__dirname, "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");

/* model.js först: site.js använder clamp därifrån. */
const ctx = { console, Math, JSON, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/model.js") + "\n" + las("src/site.js"), ctx);
const { ANL, STALLINNE, RIDHUSINNE, STALL_BAND } =
  vm.runInContext("({ANL, STALLINNE, RIDHUSINNE, STALL_BAND})", ctx);

/* ── Luau-serialisering ────────────────────────────────────────────────
   Två fällor som redan slagit till i det här repot (roblox/buildings/README):
   Luau-identifierare får inte innehålla å, ä eller ö, och Roblox tillåter bara
   [A-Za-z0-9_] i attributnamn. Nycklar som inte är rena ASCII-identifierare
   skrivs därför i hakparentes som strängar. Svenska i strängvärden är fine. */
const IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;

function tal(v) {
  /* Sex decimaler: nog för att döda flyttalsbruset (STALL_BAND:s andelar ger
     annars 3.6959999999999997) utan att runda bort precisionen i vinklar,
     som står i radianer. */
  const r = Math.round(v * 1e6) / 1e6;
  return Object.is(r, -0) ? "0" : String(r);
}

function strang(s) {
  return '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n") + '"';
}

/* "#7C2A24" → Color3.fromRGB(124, 42, 36). Färgerna finns bara som hex i
   webbkoden; Roblox vill ha RGB, och omräkningen hör hemma här och inte i
   någons huvud. */
function farg(hex) {
  const h = hex.replace("#", "");
  const n = parseInt(h.length === 3 ? h.split("").map(c => c + c).join("") : h, 16);
  return `Color3.fromRGB(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255})`;
}

const ARFARG = new Set(["fargV", "fargT", "svart", "plat", "list", "farg", "vagg", "golv",
                        "gangGolv", "tak", "sandFarg", "gangFarg", "panel", "panelList"]);

function luau(v, indent, nyckel) {
  const pad = "\t".repeat(indent);
  if (v === null || v === undefined) return "nil";
  if (typeof v === "number") return tal(v);
  if (typeof v === "boolean") return v ? "true" : "false";
  if (typeof v === "string") {
    return ARFARG.has(nyckel) && /^#[0-9A-Fa-f]{3,6}$/.test(v) ? farg(v) : strang(v);
  }
  if (Array.isArray(v)) {
    if (v.length === 0) return "{}";
    const rader = v.map(x => pad + "\t" + luau(x, indent + 1, nyckel) + ",");
    return "{\n" + rader.join("\n") + "\n" + pad + "}";
  }
  const poster = Object.entries(v).filter(([, x]) => typeof x !== "function");
  if (poster.length === 0) return "{}";
  const rader = poster.map(([k, x]) => {
    const namn = IDENT.test(k) ? k + " = " : "[" + strang(k) + "] = ";
    return pad + "\t" + namn + luau(x, indent + 1, k) + ",";
  });
  return "{\n" + rader.join("\n") + "\n" + pad + "}";
}

/* ── Vad som exporteras ───────────────────────────────────────────────
   Byggnadsmassan, marken under den, dörrarna som binder ihop husen, och
   INSIDORNAS strukturella fakta — planformen, gångarna, de namngivna rummen,
   ridbanan, läktaren. Alltså det Gate F01 handlar om.

   Möblering, hästar, staket, träd, ljus och sprites stannar i webbkoden. De är
   inte fidelity-fakta om anläggningen, och en generad fil som tar med allt blir
   omöjlig att läsa.

   Review 02 var tydlig med varför insidorna måste med: att datan finns i en
   generad modul räcker inte om primärplattformens byggare struntar i den. Fyra
   boxrader och två gångar ska gå att SE i Roblox, inte bara stå i en tabell. */
const ut = {
  bredd: ANL.bredd,
  djup: ANL.djup,
  mark: ANL.mark,
  byggnader: ANL.byggnader,
  dorrar: ANL.dorrar,
  stall: {
    bredd: STALLINNE.bredd, langd: STALLINNE.langd, tak: STALLINNE.tak,
    boxB: STALLINNE.boxB, antalBoxar: STALLINNE.antalBoxar,
    boxStartY: STALLINNE.boxStartY, klubbY: STALLINNE.klubbY,
    tvarGang: STALLINNE.tvarGang,
    band: STALL_BAND, rader: STALLINNE.rader, gangar: STALLINNE.gangar,
    gangytor: STALLINNE.gangytor,
    rum: STALLINNE.rum, service: STALLINNE.service,
    tvarvaggar: STALLINNE.tvarvaggar,
    dorrar: STALLINNE.dorrar,
  },
  ridhus: {
    bredd: RIDHUSINNE.bredd, langd: RIDHUSINNE.langd, tak: RIDHUSINNE.tak,
    entre: RIDHUSINNE.entre, bana: RIDHUSINNE.bana, sargH: RIDHUSINNE.sargH,
    port: RIDHUSINNE.port, sargGrind: RIDHUSINNE.sargGrind,
    laktare: RIDHUSINNE.laktare, glasrum: RIDHUSINNE.glasrum,
    domarbas: RIDHUSINNE.domarbas, trappa: RIDHUSINNE.trappa,
    klocka: RIDHUSINNE.klocka,
    dorrar: RIDHUSINNE.dorrar,
  },
};

const huvud = `--!strict
-- GENERERAD FIL — ÄNDRA INTE FÖR HAND.
--
-- Källa: src/site.js. Kör om med:  node tools/exportera-geometri.js
--
-- Anläggningens geometri, i METER. Origo i sydväst, +x öster, +y norr.
-- I Roblox blir spelets y byggnadens z; BuildKit.M räknar om meter till studs.
--
-- Det här är samma tal som webbspelet bygger sin värld av, uträknade ur samma
-- kod — inte avskrivna. Roblox och webben kan därför inte glida isär om
-- byggnadernas mått, färger, öppningar eller om vilka hus som sitter ihop.
--
-- Fidelity-klasserna hör till byggnadskorten och audits/, inte hit. Den här
-- filen säger vad som byggs, inte hur säkert det är. Läs
-- references/buildings/*/KORT.md och references/plans/OAVGJORT.md innan du
-- litar på ett enskilt mått.

return `;

/* Insidornas lokalkoordinater sitter ihop med byggnadens fotavtryck: origo för
   en interiör är husets sydvästra hörn, ingen vridning. Webbkoden visar det
   genom att en dörr på lokala (5,6 · 1,6) i stallet spawnar på (159,6 · 63,4) i
   världen, och 154 + 5,6 = 159,6. Relationen skrivs ut här i stället för att
   Roblox-sidan ska räkna ut den på nytt — hårdkodar man den på två ställen
   glider de isär den dag ett hus flyttas. */
for (const [nyckel, husId] of [["stall", "stall"], ["ridhus", "ridhus"]]) {
  const hus = ut.byggnader.find(b => b.id === husId);
  if (!hus) throw new Error("hittar inte byggnaden " + husId);
  ut[nyckel].origo = { x: hus.rekt.x, y: hus.rekt.y };
  /* Interiörens mått ska stämma med fotavtrycket. Gör de inte det är någon av
     dem ändrad utan den andra, och då bygger Roblox en insida som inte får
     plats i sitt eget hus. */
  const dx = Math.abs(ut[nyckel].bredd - hus.rekt.w);
  const dy = Math.abs(ut[nyckel].langd - hus.rekt.h);
  if (dx > 0.001 || dy > 0.001) {
    throw new Error(`${husId}: interiören ${ut[nyckel].bredd}×${ut[nyckel].langd} ` +
                    `matchar inte fotavtrycket ${hus.rekt.w}×${hus.rekt.h}`);
  }
}

const MAL = path.join(ROT, "roblox/buildings/UBRFKomplex.luau");
const innehall = huvud + luau(ut, 0, null) + "\n";

/* --kontrollera skriver ingenting, den bara faller om filen på disk inte är
   det exporten skulle ha gett. Det är den kontrollen som gör att Roblox-sidan
   inte kan bli en andra, handunderhållen sanning: glömmer någon köra om
   exporten efter en ändring i src/site.js, säger den ifrån. */
if (process.argv.includes("--kontrollera")) {
  const pa_disk = fs.existsSync(MAL) ? fs.readFileSync(MAL, "utf8") : "";
  if (pa_disk !== innehall) {
    console.error("FEL  roblox/buildings/UBRFKomplex.luau är inte i synk med src/site.js.");
    console.error("     Kör: node tools/exportera-geometri.js");
    process.exit(1);
  }
  console.log("OK   UBRFKomplex.luau är i synk med src/site.js");
  process.exit(0);
}

fs.writeFileSync(MAL, innehall, "utf8");

console.log("roblox/buildings/UBRFKomplex.luau:",
            ut.byggnader.length, "byggnader,", ut.dorrar.length, "dörrar,",
            ut.mark.length, "markytor");
