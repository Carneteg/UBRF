#!/usr/bin/env node
/* ══════════════════════════════════════════════════════════════════
   Skriver roblox/game/UBRFSpel.luau ur src/spel/*.js.

   Samma mönster som tools/exportera-geometri.js, av samma skäl: hästarna
   ska inte finnas i två versioner. Roblox hade tidigare ingen roster alls
   och webben hade allt, vilket i praktiken betydde att Roblox-spelaren mötte
   "Namnlös" av rasen "Warmblood".

   Kör:  node tools/exportera-spel.js
         node tools/exportera-spel.js --kontrollera   (fäller om ur synk)

   Två fällor som redan slagit till i det här repot och som är tätade här:

   1. Luau-identifierare och Roblox-attributnamn tål bara [A-Za-z0-9_].
      Nycklar som inte är rena ASCII-identifierare skrivs i hakparentes.
      Svenska i STRÄNGVÄRDEN är helt i sin ordning — beskrivningarna ska
      vara ordagranna.

   2. Färger kändes förut igen på NYCKELNS namn, ur en handskriven lista.
      Varje ny färgnyckel exporterades då tyst som en sträng och Roblox fick
      ingen färg. Här känns de igen på VÄRDET.
   ══════════════════════════════════════════════════════════════════ */
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const ROT = path.resolve(__dirname, "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");
const MAL = path.join(ROT, "roblox/game/UBRFSpel.luau");

const ctx = { console, Math, JSON, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/spel/hastar.js") + "\n" + las("src/spel/skotsel.js"), ctx);
const { HORSES, FODERSCHEMA, KRAFTVAL,
        RYKTZON, RYKTREDSKAP, RYKTKRAV, SADELFAS,
        VISITPUNKT, VISITFYND, VISITSVAR } =
  vm.runInContext("({HORSES, FODERSCHEMA, KRAFTVAL, RYKTZON, RYKTREDSKAP,"
                + " RYKTKRAV, SADELFAS, VISITPUNKT, VISITFYND, VISITSVAR})", ctx);

const IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;
const ARFARG = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/;

function tal(v) {
  const r = Math.round(v * 1e6) / 1e6;
  return Object.is(r, -0) ? "0" : String(r);
}
function strang(s) {
  return '"' + s.replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, "\\n") + '"';
}
function farg(hex) {
  const h = hex.replace("#", "");
  const n = parseInt(h.length === 3 ? h.split("").map(c => c + c).join("") : h, 16);
  return `Color3.fromRGB(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255})`;
}

function luau(v, indent) {
  const pad = "\t".repeat(indent);
  const padIn = "\t".repeat(indent + 1);
  if (v === null || v === undefined) return "nil";
  if (typeof v === "number") return tal(v);
  if (typeof v === "boolean") return String(v);
  if (typeof v === "string") return ARFARG.test(v) ? farg(v) : strang(v);
  if (Array.isArray(v)) {
    if (v.length === 0) return "{}";
    return "{\n" + v.map(x => padIn + luau(x, indent + 1)).join(",\n") + ",\n" + pad + "}";
  }
  const nycklar = Object.keys(v);
  if (nycklar.length === 0) return "{}";
  const rader = nycklar.map(k => {
    const namn = IDENT.test(k) ? k : "[" + strang(k) + "]";
    return padIn + namn + " = " + luau(v[k], indent + 1);
  });
  return "{\n" + rader.join(",\n") + ",\n" + pad + "}";
}

/* Hästarnas id blir Roblox-attribut och måste alltså vara rena. Faller
   exporten här är det för att någon döpt en häst till något med å/ä/ö —
   säg det HÖGT i stället för att tyst skriva något Roblox inte kan läsa. */
for (const id of Object.keys(HORSES)) {
  if (!IDENT.test(id)) {
    console.error(`Hästens id "${id}" duger inte som Roblox-attribut ([A-Za-z0-9_]).`);
    process.exit(2);
  }
}

/* Foder och häst ska vara samma mängd. Ett glapp här betyder att någon lagt
   till en häst utan giva, och det märks annars först som en tom krubba. */
const utanFoder = Object.keys(HORSES).filter(k => !FODERSCHEMA[k]);
const utanHast = Object.keys(FODERSCHEMA).filter(k => !HORSES[k]);
if (utanFoder.length || utanHast.length) {
  console.error("Foderschemat och hästarna går isär.");
  if (utanFoder.length) console.error("  häst utan foder: " + utanFoder.join(", "));
  if (utanHast.length) console.error("  foder utan häst: " + utanHast.join(", "));
  process.exit(2);
}

/* Varje ryktzons TYP måste ha ett redskapskrav, annars går zonen inte att
   rykta färdigt och spelaren fastnar utan att förstå varför. Samma sak för
   visitpunkterna: en punkt utan fynd kan aldrig ge något att rapportera. */
const zonTyper = [...new Set(RYKTZON.map(z => z.typ))];
const utanKrav = zonTyper.filter(t => !RYKTKRAV[t]);
const utanFynd = VISITPUNKT.map(v => v.id).filter(id => !VISITFYND[id]);
if (utanKrav.length || utanFynd.length) {
  console.error("Skötselreglerna hänger inte ihop.");
  if (utanKrav.length) console.error("  zontyp utan redskapskrav: " + utanKrav.join(", "));
  if (utanFynd.length) console.error("  visitpunkt utan fynd: " + utanFynd.join(", "));
  process.exit(2);
}

/* Redskapen i kraven måste finnas bland redskapen. Ett stavfel här ger en
   zon som aldrig blir ren, oavsett vad spelaren gör. */
const redskapsId = new Set(RYKTREDSKAP.map(r => r.id));
const okantRedskap = Object.entries(RYKTKRAV)
  .flatMap(([typ, lista]) => lista.filter(r => !redskapsId.has(r)).map(r => typ + "=" + r));
if (okantRedskap.length) {
  console.error("Okänt redskap i RYKTKRAV: " + okantRedskap.join(", "));
  process.exit(2);
}

/* Exakt ETT rätt svar vid ett fynd. Poängen är att eleven RAPPORTERAR i
   stället för att diagnostisera; två rätta svar upphäver den lärdomen. */
const rattaSvar = VISITSVAR.filter(s => s.ratt).length;
if (rattaSvar !== 1) {
  console.error(`VISITSVAR har ${rattaSvar} rätta svar, ska ha exakt 1.`);
  process.exit(2);
}

const ordning = Object.keys(HORSES);

const ut = `--!strict
--[[ GENERERAD av tools/exportera-spel.js ur src/spel/hastar.js.
     Ändra inte här — ändra i källan och kör om exporten.

     Beskrivningarna är ordagranna från ubrf.se/hastar.

     ordning[] finns för att pairs() i Lua inte har någon ordning. Vill man
     visa hästarna i en lista ska den se likadan ut varje gång och likadant
     ut som på webben. ]]

return {
	hastar = ${luau(HORSES, 1)},
	foder = ${luau(FODERSCHEMA, 1)},
	kraftval = ${luau(KRAFTVAL, 1)},
	ordning = ${luau(ordning, 1)},

	--[[ Skötseln. Reglerna är hästkunskap, inte spelbalans: huvudet tål bara
	     den mjuka borsten, gjorden dras i tre tag med paus, och eleven
	     RAPPORTERAR ett fynd i stället för att diagnostisera det. ]]
	rykt = {
		zoner = ${luau(RYKTZON, 2)},
		redskap = ${luau(RYKTREDSKAP, 2)},
		krav = ${luau(RYKTKRAV, 2)},
	},
	sadelfaser = ${luau(SADELFAS, 1)},
	visitation = {
		punkter = ${luau(VISITPUNKT, 2)},
		fynd = ${luau(VISITFYND, 2)},
		svar = ${luau(VISITSVAR, 2)},
	},
}
`;

if (process.argv.includes("--kontrollera")) {
  const fanns = fs.existsSync(MAL) ? fs.readFileSync(MAL, "utf8") : "";
  if (fanns !== ut) {
    console.error("FEL  UBRFSpel.luau är UR SYNK med src/spel/");
    console.error("     kör: node tools/exportera-spel.js");
    process.exit(1);
  }
  console.log("OK   UBRFSpel.luau är i synk med src/spel/");
  process.exit(0);
}

fs.mkdirSync(path.dirname(MAL), { recursive: true });
fs.writeFileSync(MAL, ut);
console.log(`roblox/game/UBRFSpel.luau: ${ordning.length} hästar, `
  + `${RYKTZON.length} ryktzoner, ${VISITPUNKT.length} visitpunkter, `
  + `${ut.split("\n").length} rader`);
