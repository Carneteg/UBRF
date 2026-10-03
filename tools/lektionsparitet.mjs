/* LEKTIONSPARITETEN — webbens lektioner mot Roblox källa (P3 § 8).

   ROBLOX ÄR FACIT. Grinden läser Luau-källan direkt och faller om webben
   avviker. Ingen avskrift av talen här: båda sidorna parsas.

     1. KONSTANTERNA. Varje `local NAMN = tal` i roblox/src/server/*Lektion.luau
        (och observationerna) ska finnas med samma värde i webbens modul
        (src/lektioner/*.js). Undantagen står uppräknade med skäl: M (studs
        per meter) och MAX_REQUESTS (serverns dublettskydd) har ingen
        webbmotsvarighet; hinderobservationens zoner är studs i Roblox och
        meter på webben (delat med 3).
     2. IDENTITETEN. OVNING och VERSION per lektion — samma sträng, för
        lektionsminnets nycklar `lektion:<typ>:<VERSION>`.
     3. MENYN. Varje sida i VoltLektionController.panel (topp, gangart,
        overgangar, vagar, bojda, linjer) med sina knappar i ordning, samt
        MINNE_ORDNING, MINNE_GRUPP och MINNE_UNDERGRUPP.
     4. TEXTNYCKLARNA. För varje lektionstyp och varje sidnyckel ger webbens
        Lektionsmeny.nyckel samma språknyckel som Roblox `text(key)`.
     5. KATALOGEN. Varje språknyckel webbens lektionssidor kan visa finns på
        svenska och engelska.
     6. RAMEN. u = 10 − x, v = y mot den delade bokstavstabellen: diagonalen
        börjar vid F och slutar vid H, halvvolten rider K–E–H-sidans spår.

   Kör: node tools/lektionsparitet.mjs */
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
/* CRLF i en Windows-utcheckning (core.autocrlf) ska inte ändra svaret. */
const las = p => fs.readFileSync(path.join(ROT, p), "utf8").replace(/\r\n/g, "\n");
let fel = 0, prov = 0;
const prova = (namn, ok, detalj = "") => {
  prov++;
  if (!ok) { fel++; console.log(`  FEL  ${namn}${detalj ? " — " + detalj : ""}`); }
};

/* ── Webbens moduler i en egen kontext (samma ordning som index.html) ── */
const ctx = vm.createContext({ console, Math, JSON, Object, Array, Number, String, Map, Set, isFinite });
vm.runInContext("var window = undefined;", ctx);
const WEBB = ["src/spel/sprak.js", "src/spel/skotsel.js", "src/lektioner/motor.js", "src/lektioner/observation.js",
  "src/lektioner/hinder.js", "src/lektioner/volt.js", "src/lektioner/halt.js", "src/lektioner/tempo.js",
  "src/lektioner/overgang.js", "src/lektioner/galopp.js", "src/lektioner/serpentin.js", "src/lektioner/vag.js",
  "src/lektioner/halvvolt.js", "src/lektioner/hornet.js", "src/lektioner/markbom.js", "src/lektioner/clearround.js",
  "src/lektioner/aterkoppling.js", "src/lararinstallning.js", "src/lektionsmeny.js"];
for (const f of WEBB) {
  let kod = las(f);
  if (f === "src/spel/sprak.js") kod += "\nvar tSpr = (k, ...a) => sprakText(k, 'sv', ...a);";
  vm.runInContext(kod, ctx, { filename: f });
}
const W = expr => vm.runInContext(expr, ctx);

/* ── 1 + 2. Konstanterna och identiteten ───────────────────────────── */
function luaKonst(kod) {
  const ut = {};
  for (const m of kod.matchAll(/^local ([A-Z][A-Z0-9_]*(?:\s*,\s*[A-Z][A-Z0-9_]*)*)\s*=\s*([-0-9.]+(?:\s*,\s*[-0-9.]+)*)\s*(?:--.*)?$/gm)) {
    const namn = m[1].split(",").map(s => s.trim()), var_ = m[2].split(",").map(s => Number(s.trim()));
    namn.forEach((n, i) => { if (Number.isFinite(var_[i])) ut[n] = var_[i]; });
  }
  for (const m of kod.matchAll(/^[A-Za-z]+\.([A-Z][A-Z0-9_]*)\s*=\s*([-0-9.]+)\s*(?:--.*)?$/gm)) ut[m[1]] = Number(m[2]);
  return ut;
}
function luaStr(kod, falt) {
  const m = kod.match(new RegExp(`^[A-Za-z]+\\.${falt}\\s*=\\s*"([^"]+)"`, "m"));
  return m ? m[1] : null;
}
function jsKonst(kod) {
  const ut = {};
  for (const m of kod.matchAll(/const ([A-Z][A-Z0-9_]*\s*=\s*[^;]+);/g)) {
    for (const del of m[1].split(/,(?![^(]*\))/)) {
      const d = del.match(/^\s*([A-Z][A-Z0-9_]*)\s*=\s*([-0-9.]+)\s*$/);
      if (d) ut[d[1]] = Number(d[2]);
    }
  }
  return ut;
}
const UNDANTAG = { M: "studs per meter — webbens ritt mäts redan i meter (MPS = 1)",
  MAX_REQUESTS: "serverns dublettskydd för nätverksbegäran — webben har ingen transport",
  MAX_AVSLUTADE: "serverns ring av avslutade ritter — webben har en ritt åt gången",
  VERSION: "numerisk observationsversion, inte lektionens identitet" };
const PAR = [
  ["roblox/src/server/HaltLektion.luau", "src/lektioner/halt.js", "halt"],
  ["roblox/src/server/TempoLektion.luau", "src/lektioner/tempo.js", "tempo"],
  ["roblox/src/server/OvergangLektion.luau", "src/lektioner/overgang.js", "overgang"],
  ["roblox/src/server/GaloppLektion.luau", "src/lektioner/galopp.js", "galopp"],
  ["roblox/src/server/SerpentinLektion.luau", "src/lektioner/serpentin.js", "serpentin"],
  ["roblox/src/server/VagLektion.luau", "src/lektioner/vag.js", "vag"],
  ["roblox/src/server/HalvvoltLektion.luau", "src/lektioner/halvvolt.js", "halvvolt"],
  ["roblox/src/server/HornLektion.luau", "src/lektioner/hornet.js", "hornet"],
  ["roblox/src/server/MarkbomLektion.luau", "src/lektioner/markbom.js", "markbom"],
  ["roblox/src/server/ClearRoundLektion.luau", "src/lektioner/clearround.js", "clearround"],
  ["roblox/src/server/VoltLektion.luau", "src/lektioner/volt.js", "volt"],
];
for (const [lua, js, typ] of PAR) {
  const L = las(lua), J = las(js);
  const lk = luaKonst(L), jk = jsKonst(J);
  for (const n in lk) {
    if (UNDANTAG[n]) continue;
    prova(`${typ}: ${n}`, jk[n] === lk[n], `Roblox ${lk[n]}, webben ${jk[n]}`);
  }
  const T = W(`LEKTION_TYPER[${JSON.stringify(typ)}]`);
  const ov = luaStr(L, "OVNING"), ve = luaStr(L, "VERSION");
  if (typ === "volt") {
    const O = las("roblox/src/server/VoltObservation.luau");
    prova("volt: OVNING", T.OVNING === luaStr(O, "OVNING"), `${T.OVNING}`);
    prova("volt: VERSION", T.VERSION === luaStr(O, "VERSION"), `${T.VERSION}`);
  } else {
    prova(`${typ}: OVNING`, T && T.OVNING === ov, `Roblox ${ov}, webben ${T && T.OVNING}`);
    prova(`${typ}: VERSION`, T && T.VERSION === ve, `Roblox ${ve}, webben ${T && T.VERSION}`);
  }
}
/* VagLektion.FIGURER — figurerna är tabeller, inte skalärer. */
{
  const L = las("roblox/src/server/VagLektion.luau");
  const F = W("LEKTION_TYPER.vag.FIGURER");
  for (const namn of ["vag_mitt", "vag_diag"]) {
    const m = L.match(new RegExp(`${namn} = table\\.freeze\\(\\{ ([^}]+) \\}\\)`));
    const lua = Object.fromEntries(m[1].split(",").map(p => p.split("=").map(s => s.trim())).map(([k, v]) => [k, Number(v)]));
    for (const k in lua) prova(`vag: FIGURER.${namn}.${k}`, F[namn][k] === lua[k], `Roblox ${lua[k]}, webben ${F[namn][k]}`);
  }
  const S = las("roblox/src/server/SerpentinLektion.luau").match(/local SIDOR = \{ ([^}]+) \}/)[1];
  prova("serpentin: SIDOR", las("src/lektioner/serpentin.js").includes(`const SIDOR = [${S.split(",").map(s => s.trim()).join(", ")}];`), S);
  const O = las("roblox/src/server/OvergangLektion.luau").match(/local T1_V, T2_V = (\d+), (\d+)/);
  prova("overgang: T1_V, T2_V", las("src/lektioner/overgang.js").includes(`const T1_V = ${O[1]}, T2_V = ${O[2]};`), O[0]);
  const H = las("roblox/src/server/HalvvoltLektion.luau").match(/local P0_V, T1_V = (\d+), (\d+)/);
  prova("halvvolt: P0_V, T1_V", las("src/lektioner/halvvolt.js").includes(`const P0_V = ${H[1]}, T1_V = ${H[2]};`), H[0]);
  const C = las("roblox/src/server/ClearRoundLektion.luau");
  const banaL = [...C.matchAll(/\{ id = "([^"]+)", mot = "([AC])", farg = "([a-z]+)" \}/g)].map(m => m.slice(1).join("/"));
  const banaW = W("LEKTION_TYPER.clearround.BANA").map(b => [b.id, b.mot, b.farg].join("/"));
  prova("clearround: BANA", JSON.stringify(banaL) === JSON.stringify(banaW), banaL.join(" "));
}
/* Observationerna. */
{
  const V = luaKonst(las("roblox/src/server/VoltObservation.luau"));
  for (const n of ["R_MIN", "MIN_TID", "MIN_SEGMENT", "MIN_STRACKA", "TOL_VARV", "MAX_AVSNITT"])
    prova(`VoltObservation.${n}`, W(`VoltObs.${n}`) === V[n] || jsKonst(las("src/lektioner/volt.js"))[n] === V[n], `Roblox ${V[n]}`);
  prova("VoltObservation.RADIE (RidKanon VOLT_RADIE)", W("VoltObs.RADIE") === 10);
  const R = luaKonst(las("roblox/src/server/RidObservation.luau"));
  prova("RidObservation.MAX_DT", W("LektionObs.MAX_DT") === R.MAX_DT, `Roblox ${R.MAX_DT}`);
  prova("RidObservation.FONSTER", jsKonst(las("src/lektioner/observation.js")).FONSTER === R.FONSTER, `Roblox ${R.FONSTER}`);
  const HO = luaKonst(las("roblox/src/server/HinderObservation.luau"));
  const SPM = 3;
  for (const n of ["ZON_SIDA", "ZON_DJUP", "SID_TOL", "STOPP_FART", "BAKAT_TOL"])
    prova(`HinderObservation.${n} (studs → m)`, Math.abs(W(`HinderObs.${n}`) - HO[n] / SPM) < 1e-12, `Roblox ${HO[n]} studs`);
  prova("HinderObservation.MAX_FORSOK", jsKonst(las("src/lektioner/hinder.js")).MAX_FORSOK === HO.MAX_FORSOK);
  const MB = las("roblox/src/server/MarkbomLektion.luau").match(/HINDER_ID = "([^"]+)"/);
  prova("markbom: HINDER_ID", W("LEKTION_TYPER.markbom.HINDER_ID") === (MB && MB[1]), MB && MB[1]);
}

/* ── 3. Menyn ──────────────────────────────────────────────────────── */
const VLC = las("roblox/src/client/VoltLektionController.luau");
const MENY = las("src/lektionsmeny.js");
function knappar(kod) {
  const ut = [];
  for (const m of kod.matchAll(/valLektion\("([a-z_]+)"\)|valGrupp\("([a-z_]+)"|val\("(back|choose_lesson|lessons)"/g))
    ut.push(m[1] ? "L:" + m[1] : m[2] ? "G:" + m[2] : m[3]);
  return ut;
}
function sidor(kod, luau) {
  const ut = {};
  const re = luau ? /meny == "([a-z]+)" then([\s\S]*?)(?=elseif meny == |\n\t\tend\n)/g
    : /S\.meny === "([a-z]+)"\)?([\s\S]*?)(?=if \(S\.meny === |const knappar = \[valLektion)/g;
  for (const m of kod.matchAll(re)) ut[m[1]] = knappar(m[2]);
  const topp = luau ? kod.match(/local knappar = \{ valLektion\("volt"\),[\s\S]*?\n\t\tif fri then([\s\S]*?)\n\t\telse/)
    : kod.match(/const knappar = \[valLektion\("volt"\),[\s\S]*?if \(S\.fri\) \{([\s\S]*?)\} else/);
  ut["(toppnivå)"] = topp ? knappar(topp[0]) : null;
  return ut;
}
{
  const L = sidor(VLC, true), J = sidor(MENY, false);
  for (const sida of ["gangart", "overgangar", "vagar", "bojda", "linjer", "topp", "(toppnivå)"]) {
    prova(`meny: sidan ${sida}`, !!L[sida] && JSON.stringify(L[sida]) === JSON.stringify(J[sida]),
      `Roblox ${JSON.stringify(L[sida])}, webben ${JSON.stringify(J[sida])}`);
  }
  const luaLista = namn => { const m = VLC.match(new RegExp(`local ${namn} = \\{([^}]+)\\}`)); return m ? m[1] : ""; };
  const ord = s => [...s.matchAll(/"([a-z_]+)"/g)].map(m => m[1]);
  prova("MINNE_ORDNING", JSON.stringify(ord(luaLista("MINNE_ORDNING"))) === JSON.stringify(W("Lektionsmeny.MINNE_ORDNING")),
    ord(luaLista("MINNE_ORDNING")).join(","));
  const par = s => Object.fromEntries([...s.matchAll(/([a-z_]+) = "([a-z_]+)"/g)].map(m => [m[1], m[2]]));
  prova("MINNE_GRUPP", JSON.stringify(par(luaLista("MINNE_GRUPP"))) === JSON.stringify(W("Lektionsmeny.MINNE_GRUPP")));
  prova("MINNE_UNDERGRUPP", JSON.stringify(par(luaLista("MINNE_UNDERGRUPP"))) === JSON.stringify(W("Lektionsmeny.MINNE_UNDERGRUPP")));
  const typer = ord(las("roblox/src/server/LektionsMinne.luau").match(/LektionsMinne\.TYPER = table\.freeze\(\{([^}]+)\}/)[1]);
  prova("MINNE_TYPER", JSON.stringify([...typer].sort()) === JSON.stringify(Object.keys(W("Lektionsmeny.MINNE_TYPER")).sort()));
  /* Lektionsminnets nycklar: `lektion:<typ>:<producentens VERSION>`. */
  const ver = { volt: luaStr(las("roblox/src/server/VoltObservation.luau"), "VERSION") };
  for (const [lua, , typ] of PAR) if (typ !== "volt") ver[typ] = luaStr(las(lua), "VERSION");
  for (const typ of typer) {
    const v = ver[typ === "vag_mitt" || typ === "vag_diag" ? "vag" : typ];
    prova(`minnesnyckel ${typ}`, W(`Lektionsmeny._minneNyckel(${JSON.stringify(typ)})`) === `lektion:${typ}:${v}`);
  }
}

/* ── 4. Textnycklarna (Roblox text(key)) ──────────────────────────── */
{
  const kedja = ["markbom", "galopp", "clearround", "horn", "halvvolt", "vag", "tempo", "serpentin", "overgang", "halt"];
  const TYP = { horn: "hornet", vag: null };
  const fn = {};
  for (const namn of kedja) {
    const m = VLC.match(new RegExp(`local function ${namn}Text\\(key\\): string\\?\\n([\\s\\S]*?)\\n\\treturn nil\\nend`));
    if (!m) { prova(`text: ${namn}Text hittas`, false); continue; }
    const [fore, efter] = m[1].split(/\n\tif (?:typ ~= "[a-z]+"|not vagTyp\(typ\)) then return nil end\n/);
    const par = s => Object.fromEntries([...(s || "").matchAll(/if key=="([a-z_0-9]+)" then return Sprak\.t\("([a-z_.0-9]+)"\) end/g)].map(x => [x[1], x[2]]));
    fn[namn] = { alla: par(fore), egna: par(efter) };
  }
  fn.vag.egna.intro = "INTRO_VAG";
  const generisk = {};
  const g = VLC.match(/if key=="choose" then return Sprak\.t\("voltlektion\.choose"\) end([\s\S]*?)return Sprak\.t\("voltlektion\.network"\)/);
  generisk.choose = "voltlektion.choose";
  for (const x of g[0].matchAll(/if key=="([a-z_]+)" then return Sprak\.t\("([a-z_.]+)"\) end/g)) generisk[x[1]] = x[2];
  const lua = (key, typ) => {
    for (const namn of kedja) {
      const f = fn[namn]; if (!f) continue;
      if (f.alla[key]) return f.alla[key];
      const egen = namn === "vag" ? (typ === "vag_mitt" || typ === "vag_diag") : (TYP[namn] || namn) === typ;
      if (egen && f.egna[key]) return f.egna[key] === "INTRO_VAG" ? (typ === "vag_diag" ? "vaglektion.intro_diag" : "vaglektion.intro_mitt") : f.egna[key];
    }
    return generisk[key] || "voltlektion.network";
  };
  const nycklar = new Set(Object.keys(generisk));
  for (const namn in fn) for (const k of [...Object.keys(fn[namn].alla), ...Object.keys(fn[namn].egna)]) nycklar.add(k);
  for (const k of ["startlista", "banskiss", "jump", "course", "pole", "network", "bogus"]) nycklar.add(k);
  const TYPER = ["volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt", "galopp", "markbom", "hornet", "clearround"];
  let n = 0;
  for (const typ of TYPER) for (const key of nycklar) {
    const w = W(`Lektionsmeny.nyckel(${JSON.stringify(key)}, ${JSON.stringify(typ)})`);
    const l = lua(key, typ);
    if (w !== l) prova(`text(${key}) i ${typ}`, false, `Roblox ${l}, webben ${w}`); else { prov++; n++; }
  }
  console.log(`  text: ${n} kombinationer av typ × nyckel lika`);

  /* ── 5. Katalogen ─────────────────────────────────────────────── */
  const SPRAK = W("SPRAK");
  const behov = new Set();
  for (const typ of TYPER) for (const key of nycklar) behov.add(W(`Lektionsmeny.nyckel(${JSON.stringify(key)}, ${JSON.stringify(typ)})`));
  for (const k of MENY.matchAll(/t\("([a-z_]+\.[a-z_.0-9]+)"/g)) behov.add(k[1]);
  for (const k of las("src/lektioner/aterkoppling.js").matchAll(/t\("([a-z_]+\.[a-z_.0-9]+)"/g)) behov.add(k[1]);
  for (const typ of ["volt", "halt", "overgang", "serpentin", "tempo", "vag_mitt", "vag_diag", "halvvolt", "galopp", "markbom", "hornet", "clearround"]) {
    for (const d of ["klar", "nasta", "igen"]) if (typ !== "clearround" || d === "nasta") behov.add(`aterkoppling.${typ}.${d}`);
    if (typ !== "clearround") behov.add(`aterkoppling.${typ}.kort`);
    if (typ !== "clearround") behov.add(`halsning.${typ}`);
  }
  for (const k of behov) prova(`katalog: ${k}`, !!SPRAK[k] && !!SPRAK[k].sv && !!SPRAK[k].en, "saknas eller saknar ett språk");
  console.log(`  katalog: ${behov.size} nycklar prövade`);
}

/* ── 6. Ramen ──────────────────────────────────────────────────────── */
{
  const B = {};
  const data = las("src/data.js").match(/const DRESSYRBOKSTAVER=\[([\s\S]*?)\];/)[1];
  for (const m of data.matchAll(/\{b:"([A-Z])",x:(\d+), ?y:(\d+)/g)) B[m[1]] = { x: +m[2], y: +m[3] };
  const tillU = W("LektionObs.tillU"), tillV = W("LektionObs.tillV");
  const F = W("LEKTION_TYPER.vag.FIGURER.vag_diag");
  const narmast = (u, v) => Object.entries(B).map(([b, p]) => [b, Math.hypot(tillU(p.x) - u, tillV(p.y) - v)]).sort((a, c) => a[1] - c[1])[0][0];
  prova("ramen: diagonalen börjar vid F", narmast(F.du0, F.v0) === "F", narmast(F.du0, F.v0));
  prova("ramen: diagonalen slutar vid H", narmast(F.du1, F.v1) === "H", narmast(F.du1, F.v1));
  prova("ramen: +u är K–E–H-sidan", tillU(B.E.x) > 0 && tillU(B.B.x) < 0);
  prova("ramen: A i v = 0, C i v = 60", tillV(B.A.y) === 0 && tillV(B.C.y) === 60);
}

console.log(fel ? `LEKTIONSPARITET: ${fel} av ${prov} prov FEL` : `LEKTIONSPARITET: alla ${prov} prov gröna`);
process.exit(fel ? 1 : 0);
