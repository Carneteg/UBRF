#!/usr/bin/env node
/* Spatial anchor checks (issue #78 § 4): EN lista med verifierade ankarmått
   och relationer — references/spatial/UBRF-SPATIAL-ANCHORS.json — provas
   mot den delade spatialdatan i src/site.js. Roblox läser samma data via
   tools/exportera-geometri.js (--kontrollera i CI), så ett grönt ankare
   här gäller båda ytorna.

   Värden i listan får bara komma från plan, verifierat underlag eller
   Tobias. Blir ett ankare rött rättas datan eller källan — inte ankaret.

   Kör: node tools/kolla-ankare.mjs        (exit 1 vid avvikelse) */
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");
const ctx = { console, Math, JSON, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/model.js") + "\n" + las("src/site.js"), ctx);

const lista = JSON.parse(las("references/spatial/UBRF-SPATIAL-ANCHORS.json"));
const TILLATNA = new Set(["MEASURED", "MEASURED_LOCAL", "VERIFIED", "VERIFIED_PLAN_OR_PHOTO", "VERIFIED_PROPORTION", "PRODUCT_OWNER_VERIFIED", "RELATION", "DERIVED"]);
let fel = 0;
for (const a of lista.ankare) {
  if (!a.kalla || !TILLATNA.has(a.konfidens)) { fel++; console.log(`  FEL  ${a.id}: saknar källa eller har okänd konfidens (${a.konfidens})`); continue; }
  if (a.konfidens === "DERIVED" && typeof a.varde === "number") { fel++; console.log(`  FEL  ${a.id}: ett härlett tal får inte vara ett ankarvärde`); continue; }
  let v;
  try { v = vm.runInContext(a.prov, ctx); } catch (e) { fel++; console.log(`  FEL  ${a.id}: provet kastade — ${e.message}`); continue; }
  let ok, detalj;
  if (typeof a.varde === "number") { ok = typeof v === "number" && Math.abs(v - a.varde) <= (a.tolerans ?? 0); detalj = `${typeof v === "number" ? v.toFixed(3) : v} mot ${a.varde} ±${a.tolerans ?? 0} ${a.enhet || ""}`; }
  else { ok = v === true; detalj = String(v); }
  if (!ok) fel++;
  console.log(`  ${ok ? "OK  " : "FEL "} ${a.id.padEnd(28)} ${a.vad}  [${a.konfidens}]  ${detalj}`);
}
console.log(fel ? `\n${fel} ankare avviker — rätta datan eller källan, aldrig ankaret.` : `\nAlla ${lista.ankare.length} ankare stämmer.`);
process.exit(fel ? 1 : 0);
