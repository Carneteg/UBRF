#!/usr/bin/env node
/* ══════════════════════════════════════════════════════════════════
   Skriver roblox/game/UBRFSpel.luau ur src/spel/hastar.js.

   Verklighetsfakta i spelkanonen måste samtidigt motsvara den
   versionssparade snapshoten references/data/ubrf-hastar-2026-09-01.json.
   Snapshoten är hämtad från Supabase public.hastar (upstream ubrf.se).
   Supabase är upstream för fakta; JS-filen är spelets kanoniska data.
   ══════════════════════════════════════════════════════════════════ */
const fs = require("fs");
const path = require("path");
const vm = require("vm");

const ROT = path.resolve(__dirname, "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");
const MAL = path.join(ROT, "roblox/game/UBRFSpel.luau");
const SNAPSHOT = "references/data/ubrf-hastar-2026-09-01.json";

const ctx = { console, Math, JSON, Object, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/spel/hastar.js"), ctx);
const { HORSES, FODERSCHEMA, KRAFTVAL } =
  vm.runInContext("({HORSES, FODERSCHEMA, KRAFTVAL})", ctx);

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

kontrolleraFakta();

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
   Standardvärden serialiseras en gång och varje häst bär bara avvikelser.
   Det håller den genererade modulen liten utan att skapa en andra sanning. */
const BAS_RUNTIME = {
  kanslighet: .50, framatbjudning: .50, forlatande: .60, skygghet: .20,
  hoppkapacitet: .60, hopplust: .60, tyngd: .40, utbildning: .60, maxhojd: .80,
  farg: "#72533B", man: "#2F2118",
};
const FAKTA_RUNTIME = ["namn","typ","fodd","ras","mankhojd","import","kategori","besk"];
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
  if (f.ho !== 2 || f.kraft !== "inget") foderOverrides[id] = {ho:f.ho,kraft:f.kraft};
}
const foderNotis = "Övningsvärde i spelet — verklig UBRF-giva är inte verifierad.";

const ut = `--!strict
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

if (process.argv.includes("--kontrollera")) {
  const fanns = fs.existsSync(MAL) ? fs.readFileSync(MAL, "utf8") : "";
  if (fanns !== ut) {
    console.error("FEL  UBRFSpel.luau är UR SYNK med src/spel/hastar.js");
    console.error("     kör: node tools/exportera-spel.js");
    process.exit(1);
  }
  console.log(`OK   UBRFSpel.luau är i synk; ${ordning.length} hästar matchar snapshot`);
  process.exit(0);
}

fs.mkdirSync(path.dirname(MAL), { recursive: true });
fs.writeFileSync(MAL, ut);
console.log(`roblox/game/UBRFSpel.luau: ${ordning.length} hästar, ${ut.split("\n").length} rader`);
