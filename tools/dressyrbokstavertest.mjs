#!/usr/bin/env node
/* DRESSYRBOKSTÄVERNA — paritetsgrind (#289).

   En sanning: `DRESSYRBOKSTAVER` i src/data.js. Roblox läser den genom den
   GENERERADE roblox/buildings/UBRFKomplex.luau (tools/exportera-geometri.js).
   Provet fäller om
     · en bokstav saknas, dubbleras eller är okänd,
     · en bokstav hamnar på fel sarg (A syd, C norr, K V E S H väst, F P B R M öst),
     · ordningen längs en långsida är fel (y växer från A mot C),
     · Roblox-exporten avviker från data.js (annat id, annat läge, annan bild),
     · webbens `bokstavLage` ger en annan sarg än kanon.
   Kanontabellen nedan är skriven FÖR HAND och med flit: den ska fälla om
   data.js driver, inte bara om exporten avviker från data.js.

   Kör: node tools/dressyrbokstavertest.mjs */
import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");

let fel = 0;
const prova = (namn, villkor, detalj = "") => {
  if (villkor) console.log("  OK   " + namn + (detalj ? " — " + detalj : ""));
  else { fel++; console.log("  FEL  " + namn + (detalj ? " — " + detalj : "")); }
};

const KANON = { A: "S", C: "N", K: "W", V: "W", E: "W", S: "W", H: "W", F: "E", P: "E", B: "E", R: "E", M: "E" };
const VAST = ["K", "V", "E", "S", "H"], OST = ["F", "P", "B", "R", "M"];
const FOTO = new Set(["C", "F", "B", "M"]);

/* data.js + site.js i samma sandlåda som exporten. */
const ctx = { console, Math, JSON, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/model.js") + "\n" + las("src/data.js") + "\n" + las("src/site.js"), ctx);
const web = vm.runInContext("({DRESSYRBOKSTAVER, RIDHUSINNE})", ctx);
const lista = web.DRESSYRBOKSTAVER;
const R = web.RIDHUSINNE;

console.log("\n── A. Webbens lista mot kanon ──");
prova("exakt tolv poster", lista.length === 12, String(lista.length));
const ids = lista.map(b => b.b);
prova("ingen bokstav dubbleras", new Set(ids).size === ids.length, ids.join(""));
prova("exakt A C K V E S H F P B R M", Object.keys(KANON).every(i => ids.includes(i)) && ids.every(i => i in KANON), ids.join(""));

/* Webbens egen regel för sarg: samma funktion som ritar skylten. */
const src = las("src/world.js");
const m = src.match(/function bokstavLage\(R,B\)\{[\s\S]*?\n\}/);
prova("bokstavLage finns i world.js", !!m);
const bokstavLage = vm.runInNewContext("(" + m[0].replace(/^function bokstavLage/, "function") + ")");
const sida = {};
for (const b of lista) sida[b.b] = bokstavLage(R, b);
for (const [id, s] of Object.entries(KANON)) {
  prova(`${id} sitter på ${s}-sargen`, sida[id] && sida[id].sida === s, sida[id] ? `${sida[id].sida} (${sida[id].x}, ${sida[id].y})` : "saknas");
}
const stigande = (rad, namn) => {
  let ok = true, f = -Infinity;
  for (const id of rad) { const y = sida[id] && sida[id].y; if (!(y > f)) ok = false; f = y; }
  prova(namn, ok, rad.map(i => `${i}=${sida[i] && sida[i].y}`).join(" "));
};
stigande(VAST, "västra långsidan K → V → E → S → H, y växer från A mot C");
stigande(OST, "östra långsidan F → P → B → R → M, y växer från A mot C");
prova("A söder om C", sida.A.y < sida.C.y, `${sida.A.y} < ${sida.C.y}`);
prova("bildgåtans källa: foto bara för C, F, B, M",
  lista.every(b => (b.bildKalla === "foto") === FOTO.has(b.b) && ["foto", "antagande"].includes(b.bildKalla)),
  lista.map(b => b.b + ":" + b.bildKalla).join(" "));

console.log("\n── B. Roblox-exporten är webbens lista ──");
const luau = las("roblox/buildings/UBRFKomplex.luau");
const blk = luau.match(/dressyrBokstaver = \{([\s\S]*?)\n\t\t\},\n/);
prova("exporten har dressyrBokstaver", !!blk);
const poster = [];
if (blk) {
  for (const p of blk[1].matchAll(/\{\s*([\s\S]*?)\n\t\t\t\},?/g)) {
    const post = {};
    for (const f of p[1].matchAll(/(\w+) = ("[^"]*"|-?[\d.]+)/g)) {
      post[f[1]] = f[2].startsWith('"') ? f[2].slice(1, -1) : Number(f[2]);
    }
    poster.push(post);
  }
}
prova("exakt tolv poster i exporten", poster.length === 12, String(poster.length));
for (const b of lista) {
  const e = poster.find(x => x.b === b.b);
  const lika = e && e.x === b.x && e.y === b.y && e.bild === b.bild && e.bildKalla === b.bildKalla
    && (e.paSarg || null) === (b.paSarg || null);
  prova(`${b.b}: exporten = data.js (id, x, y, sarg, bild, källa)`, !!lika,
    e ? JSON.stringify(e) : "saknas i exporten");
}
prova("exporten har inga extra bokstäver", poster.every(e => lista.some(b => b.b === e.b)));

/* ── Galoppringen är ingen dressyrbokstav (rättningen efter #292) ──────────
   Ringen på mittlinjen hette «K», men K är västra sargens skylt. Spelartexten
   får inte säga «vid K» / «ringen K», och lektionens mål-id får inte vara en
   bokstav. Samma regel som roblox/tests/galopplektion-bokstaver.spec.luau. */
console.log("\n── D. Galoppringen är ingen bokstav ──");
const sprakKalla = las("src/spel/sprak.js");
const sprakCtx = { console, Math, JSON, window: {} };
vm.createContext(sprakCtx);
vm.runInContext(sprakKalla + "\n;this.__S = SPRAK;", sprakCtx);
const SPRAK = sprakCtx.__S;
const galoppNycklar = Object.keys(SPRAK).filter(n =>
  n.startsWith("galopplektion.") || n.startsWith("aterkoppling.galopp.") || n.startsWith("halsning.galopp"));
prova("galopptexterna hittades", galoppNycklar.length >= 10, String(galoppNycklar.length));
const fristaende = [];
for (const n of galoppNycklar) for (const sp of ["sv", "en"]) {
  if (typeof SPRAK[n][sp] === "string" && /(^|[^\p{L}\p{N}])K($|[^\p{L}\p{N}])/u.test(SPRAK[n][sp])) fristaende.push(n + "/" + sp);
}
prova("ingen galopptext säger «K»", fristaende.length === 0, fristaende.join(" "));
const galoppKalla = las("src/lektioner/galopp.js");
const mal = galoppKalla.match(/mal:\s*"([^"]+)"/);
prova("lektionens mål-id är satt", !!mal, mal ? mal[1] : "saknas");
prova("mål-id är ingen dressyrbokstav", !!mal && !(mal[1] in KANON), mal ? mal[1] : "");

console.log("");
if (fel) { console.log(`dressyrbokstavertest: ${fel} mätning(ar) föll`); process.exit(1); }
console.log("dressyrbokstavertest: alla gröna");
