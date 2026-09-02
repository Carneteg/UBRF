#!/usr/bin/env node
/* ══════════════════════════════════════════════════════════════════
   Exporterar spelkanonen till Roblox utan dubbel sanning.

   - src/spel/hastar.js  → roblox/game/UBRFSpelData.luau
   - src/spel/skotsel.js → roblox/game/UBRFSkotsel.luau
   - roblox/game/UBRFSpel.luau är en tunn, handskriven integrationswrapper.

   Verklighetsfakta i hästkanonen måste samtidigt motsvara den
   versionssparade snapshoten references/data/ubrf-hastar-2026-09-01.json.
   Snapshoten är hämtad från Supabase public.hastar (upstream ubrf.se).
   Supabase är upstream för fakta; JS-filen är spelets kanoniska data.
   ══════════════════════════════════════════════════════════════════ */
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const ROT = path.resolve(__dirname, "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");
const DATA_MAL = path.join(ROT, "roblox/game/UBRFSpelData.luau");
const SKOTSEL_MAL = path.join(ROT, "roblox/game/UBRFSkotsel.luau");
const SNAPSHOT = "references/data/ubrf-hastar-2026-09-01.json";

const ctx = { console, Math, JSON, Object, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/spel/hastar.js") + "\n" + las("src/spel/skotsel.js"), ctx);
const {
  HORSES, FODERSCHEMA, KRAFTVAL,
  RYKTZON, RYKTREDSKAP, RYKTKRAV, SADELFAS,
  VISITPUNKT, VISITFYND, VISITSVAR, FASER,
} = vm.runInContext(
  "({HORSES, FODERSCHEMA, KRAFTVAL, RYKTZON, RYKTREDSKAP, RYKTKRAV, " +
  "SADELFAS, VISITPUNKT, VISITFYND, VISITSVAR, FASER})",
  ctx,
);

const IDENT = /^[A-Za-z_][A-Za-z0-9_]*$/;
const ARFARG = /^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$/;

function lika(a, b) {
  return a === b || (a == null && b == null);
}

function kontrolleraFakta() {
  const snap = JSON.parse(las(SNAPSHOT));
  if (snap.active_count !== snap.rows.length) {
    console.error(`FEL  snapshot active_count ${snap.active_count} men ${snap.rows.length} rader`);
    process.exit(2);
  }
  const ix = Object.fromEntries(snap.fields.map((f, i) => [f, i]));
  const radPerId = new Map(snap.rows.map(r => [r[ix.id], r]));
  const kallaIdn = Object.values(HORSES).map(h => h.kallaId);
  const dubbla = kallaIdn.filter((id, i) => kallaIdn.indexOf(id) !== i);
  if (dubbla.length) {
    console.error("FEL  dubbla kallaId: " + [...new Set(dubbla)].join(", "));
    process.exit(2);
  }
  const saknas = [...radPerId.keys()].filter(id => !kallaIdn.includes(id));
  const extra = kallaIdn.filter(id => !radPerId.has(id));
  if (saknas.length || extra.length || Object.keys(HORSES).length !== snap.active_count) {
    console.error(`FEL  hästkanonen avviker från snapshoten (${Object.keys(HORSES).length}/${snap.active_count})`);
    if (saknas.length) console.error("  saknas i spelet: " + saknas.join(", "));
    if (extra.length) console.error("  saknas i snapshot: " + extra.join(", "));
    process.exit(2);
  }

  const falt = [
    ["namn", "namn"],
    ["fodd", "fodd"],
    ["ras", "ras"],
    ["mankhojd", "mankhojd"],
    ["import", "import"],
    ["kategoriKalla", "kategori"],
    ["besk", "beskrivning"],
  ];
  const fel = [];
  for (const [gameId, h] of Object.entries(HORSES)) {
    const r = radPerId.get(h.kallaId);
    const sourceTyp = r[ix.typ] === "häst" ? "hast" : r[ix.typ];
    if (!lika(h.typ, sourceTyp)) fel.push(`${gameId}.typ`);
    for (const [hk, sk] of falt) {
      if (!lika(h[hk], r[ix[sk]])) fel.push(`${gameId}.${hk}`);
    }
    if (h.typ === "ponny" && h.kategoriKalla == null && h.kategoriStatus !== "ASSUMPTION") {
      fel.push(`${gameId}.kategoriStatus`);
    }
  }
  if (fel.length) {
    console.error("FEL  verklighetsfakta avviker från snapshot: " + fel.join(", "));
    process.exit(2);
  }
}

function kontrolleraSkotsel() {
  const zonTyper = [...new Set(RYKTZON.map(z => z.typ))];
  const utanKrav = zonTyper.filter(t => !RYKTKRAV[t]);
  const utanFynd = VISITPUNKT.map(v => v.id).filter(id => !VISITFYND[id]);
  if (utanKrav.length || utanFynd.length) {
    console.error("FEL  skötselreglerna hänger inte ihop.");
    if (utanKrav.length) console.error("  zontyp utan redskapskrav: " + utanKrav.join(", "));
    if (utanFynd.length) console.error("  visitpunkt utan fynd: " + utanFynd.join(", "));
    process.exit(2);
  }

  const redskapsId = new Set(RYKTREDSKAP.map(r => r.id));
  const okantRedskap = Object.entries(RYKTKRAV)
    .flatMap(([typ, lista]) => lista.filter(r => !redskapsId.has(r)).map(r => typ + "=" + r));
  if (okantRedskap.length) {
    console.error("FEL  okänt redskap i RYKTKRAV: " + okantRedskap.join(", "));
    process.exit(2);
  }

  const huvudKrav = RYKTKRAV.huvud;
  if (!Array.isArray(huvudKrav) || huvudKrav.length !== 1 || huvudKrav[0] !== "mjuk") {
    console.error("FEL  RYKTKRAV.huvud måste vara exakt [mjuk].");
    process.exit(2);
  }
  const benKrav = RYKTKRAV.ben;
  if (!Array.isArray(benKrav) || benKrav.includes("skrapa")) {
    console.error("FEL  RYKTKRAV.ben får inte innehålla skrapa.");
    process.exit(2);
  }

  const rattaSvar = VISITSVAR.filter(s => s.ratt).length;
  if (rattaSvar !== 1) {
    console.error(`FEL  VISITSVAR har ${rattaSvar} rätta svar, ska ha exakt 1.`);
    process.exit(2);
  }
  if (SADELFAS.length < 4) {
    console.error(`FEL  SADELFAS har bara ${SADELFAS.length} faser.`);
    process.exit(2);
  }

  /* Fasordningen är pedagogik, inte layout. Grinden vaktar de tre saker som
     tyst skulle förstöra den: att uppsittningen glider någon annanstans än
     sist, att visitationen hamnar efter ryktningen (då upptäcks ett fynd
     först när gruset redan är inarbetat), och att fler än en fas märks som
     den avslutande. Ingen av dem syns som ett fel när spelet körs — loopen
     går igenom, den lär bara ut fel sak. */
  const fasId = FASER.map(f => f.id);
  const sittFaser = FASER.filter(f => f.sitt);
  if (sittFaser.length !== 1) {
    console.error(`FEL  FASER har ${sittFaser.length} faser märkta sitt, ska ha exakt 1.`);
    process.exit(2);
  }
  if (FASER[FASER.length - 1] !== sittFaser[0]) {
    console.error("FEL  den sitt-märkta fasen måste ligga SIST i FASER.");
    process.exit(2);
  }
  if (fasId.indexOf("visitera") > fasId.indexOf("rykta")) {
    console.error("FEL  visitationen måste komma före ryktningen.");
    process.exit(2);
  }
  if (new Set(fasId).size !== fasId.length) {
    console.error("FEL  FASER har dubbla id: " + fasId.join(", "));
    process.exit(2);
  }
}

/* Lektionsrotationen låg kvar på den gamla 17-hästarslistan när S2c bytte
   kanon till 33. Då kunde webben välja t.ex. `chip` trots att HORSES.chip
   inte längre finns. Grinden läser den lilla gameplaytabellen statiskt:
   varje id måste finnas i kanonen och vara medvetet tunat. UNTUNED hästar
   får finnas i kanonen men kommer inte in i lektion förrän de har en egen
   tuning-slice. */
function kontrolleraRotation() {
  const src = las("src/ryttare.js");
  const block = src.match(/const\s+HAST_MINGRUPP\s*=\s*\{([\s\S]*?)\};/);
  if (!block) {
    console.error("FEL  hittar inte HAST_MINGRUPP i src/ryttare.js");
    process.exit(2);
  }
  const par = [...block[1].matchAll(/([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(\d+)/g)]
    .map(m => ({id: m[1], steg: Number(m[2])}));
  if (!par.length) {
    console.error("FEL  HAST_MINGRUPP är tom eller kunde inte tolkas");
    process.exit(2);
  }
  const ids = par.map(p => p.id);
  const dubbla = ids.filter((id, i) => ids.indexOf(id) !== i);
  const okanda = par.filter(p => !HORSES[p.id]).map(p => p.id);
  const otunade = par.filter(p => HORSES[p.id] && HORSES[p.id].gameplayStatus !== "LEGACY_TUNED")
    .map(p => p.id);
  const felSteg = par.filter(p => p.steg < 0 || p.steg > 8).map(p => `${p.id}=${p.steg}`);
  if (dubbla.length || okanda.length || otunade.length || felSteg.length) {
    console.error("FEL  lektionsrotationen avviker från hästkanonen");
    if (dubbla.length) console.error("  dubbla id: " + [...new Set(dubbla)].join(", "));
    if (okanda.length) console.error("  id som inte finns i HORSES: " + okanda.join(", "));
    if (otunade.length) console.error("  hästar utan avsiktlig tuning: " + otunade.join(", "));
    if (felSteg.length) console.error("  ogiltiga gruppsteg: " + felSteg.join(", "));
    process.exit(2);
  }
}

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
function luau(v) {
  if (v === null || v === undefined) return "nil";
  if (typeof v === "number") return tal(v);
  if (typeof v === "boolean") return String(v);
  if (typeof v === "string") return ARFARG.test(v) ? farg(v) : strang(v);
  if (Array.isArray(v)) return "{" + v.map(luau).join(",") + "}";
  const nycklar = Object.keys(v);
  return "{" + nycklar.map(k => {
    const namn = IDENT.test(k) ? k : "[" + strang(k) + "]";
    return namn + "=" + luau(v[k]);
  }).join(",") + "}";
}
function luauPretty(v, indent = 0) {
  const pad = "\t".repeat(indent);
  const padIn = "\t".repeat(indent + 1);
  if (v === null || v === undefined) return "nil";
  if (typeof v === "number") return tal(v);
  if (typeof v === "boolean") return String(v);
  if (typeof v === "string") return ARFARG.test(v) ? farg(v) : strang(v);
  if (Array.isArray(v)) {
    if (v.length === 0) return "{}";
    return "{\n" + v.map(x => padIn + luauPretty(x, indent + 1)).join(",\n") + ",\n" + pad + "}";
  }
  const nycklar = Object.keys(v);
  if (nycklar.length === 0) return "{}";
  return "{\n" + nycklar.map(k => {
    const namn = IDENT.test(k) ? k : "[" + strang(k) + "]";
    return padIn + namn + " = " + luauPretty(v[k], indent + 1);
  }).join(",\n") + ",\n" + pad + "}";
}

kontrolleraFakta();
kontrolleraSkotsel();
kontrolleraRotation();

for (const id of Object.keys(HORSES)) {
  if (!IDENT.test(id)) {
    console.error(`Hästens id "${id}" duger inte som Roblox-attribut ([A-Za-z0-9_]).`);
    process.exit(2);
  }
}

const utanFoder = Object.keys(HORSES).filter(k => !FODERSCHEMA[k]);
const utanHast = Object.keys(FODERSCHEMA).filter(k => !HORSES[k]);
const oklassatFoder = Object.entries(FODERSCHEMA)
  .filter(([, v]) => v.status !== "ASSUMPTION" && v.status !== "VERIFIED")
  .map(([k]) => k);
if (utanFoder.length || utanHast.length || oklassatFoder.length) {
  console.error("FEL  foderdatan och hästarna går isär eller saknar evidensklass.");
  if (utanFoder.length) console.error("  häst utan foder: " + utanFoder.join(", "));
  if (utanHast.length) console.error("  foder utan häst: " + utanHast.join(", "));
  if (oklassatFoder.length) console.error("  foder utan status: " + oklassatFoder.join(", "));
  process.exit(2);
}

const ordning = Object.keys(HORSES);

/* Roblox behöver faktan och spelvärdena, men inte build-evidensfälten.
   Standardvärden serialiseras en gång och varje häst bär bara avvikelser. */
const BAS_RUNTIME = {
  kanslighet: .50, framatbjudning: .50, forlatande: .60, skygghet: .20,
  hoppkapacitet: .60, hopplust: .60, tyngd: .40, utbildning: .60, maxhojd: .80,
  farg: "#72533B", man: "#2F2118",
};
const FAKTA_RUNTIME = ["namn", "typ", "fodd", "ras", "mankhojd", "import", "kategori", "besk"];
const GAME_RUNTIME = Object.keys(BAS_RUNTIME);
const sparseHorses = {};
for (const [id, h] of Object.entries(HORSES)) {
  const o = {};
  for (const k of FAKTA_RUNTIME) o[k] = h[k];
  for (const k of GAME_RUNTIME) if (h[k] !== BAS_RUNTIME[k]) o[k] = h[k];
  if (h.fjader !== undefined) o.fjader = h.fjader;
  if (h.tecken !== undefined) o.tecken = h.tecken;
  if (h.flaggor && Object.keys(h.flaggor).length) o.flaggor = h.flaggor;
  sparseHorses[id] = o;
}
const foderOverrides = {};
for (const [id, f] of Object.entries(FODERSCHEMA)) {
  if (f.ho !== 2 || f.kraft !== "inget") foderOverrides[id] = {ho: f.ho, kraft: f.kraft};
}
const foderNotis = "Övningsvärde i spelet — verklig UBRF-giva är inte verifierad.";

const dataUt = `--!strict
--[[ GENERERAD av tools/exportera-spel.js ur src/spel/hastar.js.
     Ändra inte här — ändra i källan och kör om exporten.
     Verklighetsfakta är grindade mot ${SNAPSHOT}. ]]

local bas = ${luau(BAS_RUNTIME)}
local raw = ${luau(sparseHorses)}
local hastar = {}
for id, h in pairs(raw) do
\tlocal v = {}
\tfor k, x in pairs(bas) do v[k] = x end
\tfor k, x in pairs(h) do v[k] = x end
\tif v.flaggor == nil then v.flaggor = {} end
\thastar[id] = v
end

local ordning = ${luau(ordning)}
local foder = {}
local foderOverrides = ${luau(foderOverrides)}
for _, id in ipairs(ordning) do
\tlocal o = foderOverrides[id]
\tfoder[id] = {
\t\tho = if o then o.ho else 2,
\t\tkraft = if o then o.kraft else "inget",
\t\tstatus = "ASSUMPTION",
\t\tnotis = ${strang(foderNotis)},
\t}
end

return {
\thastar = hastar,
\tfoder = foder,
\tkraftval = ${luau(KRAFTVAL)},
\tordning = ordning,
}
`;

const skotselRuntime = {
  rykt: {zoner: RYKTZON, redskap: RYKTREDSKAP, krav: RYKTKRAV},
  sadelfaser: SADELFAS,
  visitation: {punkter: VISITPUNKT, fynd: VISITFYND, svar: VISITSVAR},
  faser: FASER,
};
const skotselUt = `--!strict
--[[ GENERERAD av tools/exportera-spel.js ur src/spel/skotsel.js.
     Ändra inte här — ändra i källan och kör om exporten. ]]

return ${luauPretty(skotselRuntime, 0)}
`;

const kontrollerar = process.argv.includes("--kontrollera");
const mal = [
  [DATA_MAL, dataUt, "UBRFSpelData.luau"],
  [SKOTSEL_MAL, skotselUt, "UBRFSkotsel.luau"],
];

if (kontrollerar) {
  let fel = 0;
  for (const [fil, innehall, namn] of mal) {
    const fanns = fs.existsSync(fil) ? fs.readFileSync(fil, "utf8") : "";
    if (fanns !== innehall) {
      console.error(`FEL  ${namn} är UR SYNK med src/spel/`);
      fel = 1;
    }
  }
  if (fel) {
    console.error("     kör: node tools/exportera-spel.js");
    process.exit(1);
  }
  console.log(`OK   Roblox-speldatan är i synk; ${ordning.length} hästar matchar snapshot, skötselkanon och rotation`);
  process.exit(0);
}

for (const [fil, innehall] of mal) {
  fs.mkdirSync(path.dirname(fil), {recursive: true});
  fs.writeFileSync(fil, innehall);
}
console.log(`roblox/game: ${ordning.length} hästar, ${RYKTZON.length} ryktzoner, ${VISITPUNKT.length} visitpunkter`);