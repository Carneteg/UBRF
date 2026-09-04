#!/usr/bin/env node
/* Visuell grind — kontrakten runt reviewkamerorna (issue #78):

   1. qa/visual-gate/kameror.json är giltig: tolv kameror med unika ID,
      scen, läge och referenslista; granskningsstatus bara EJ_GRANSKAD,
      MISMATCH eller CHATGPT_VISUAL_PASS. VISUALLY_ACCEPTED finns inte —
      automation får aldrig sätta en visuell acceptans, och en människa
      sätter den i PR:n, inte i en JSON.
   2. Varje referens som pekas ut finns i repot (en referens som inte
      finns är ett hål i evidensen, inte ett stavfel).
   3. Roblox har samma vyer: varje kamera-ID finns som `id = "…"` i
      roblox/buildings/Vyer.luau (gruppen Visuell grind), så att Studio-QA
      och webbens screenshot-pack pratar om samma bild.

   Kör: node tools/kolla-visuell-grind.mjs   (exit 1 vid fel) */
import fs from "node:fs";
import path from "node:path";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const KRAVDA = ["STALL-ENTRE", "STALL-UPPEHALL", "STALL-TEORISAL", "STALL-SADELKAMMARE", "STALL-GANG-A", "HASTPASSAGE",
  "RIDHUS-ENTRE", "RIDHUS-SKAPKORRIDOR", "ARENA-A", "ARENA-C", "LAKTARE", "C-BLOCK-OVRE"];
const TILLATNA = new Set(["EJ_GRANSKAD", "MISMATCH", "CHATGPT_VISUAL_PASS"]);
let fel = 0;
const saga = (ok, t) => { if (!ok) fel++; console.log(`  ${ok ? "OK  " : "FEL "} ${t}`); };

const k = JSON.parse(fs.readFileSync(path.join(ROT, "qa/visual-gate/kameror.json"), "utf8"));
const ids = k.kameror.map(c => c.id);
saga(KRAVDA.every(id => ids.includes(id)) && ids.length === KRAVDA.length, `de tolv kamerorna i #78 finns, inga fler (${ids.length})`);
saga(new Set(ids).size === ids.length, "kamera-ID är unika");
for (const c of k.kameror) {
  saga(["stallinne", "ridhusinne"].includes(c.scen) && c.lage && c.lage.x !== undefined && c.lage.y !== undefined && c.lage.rikt !== undefined,
    `${c.id}: scen och läge (x, y, rikt)`);
  saga(TILLATNA.has(c.granskning && c.granskning.status), `${c.id}: granskning.status ${c.granskning && c.granskning.status} är tillåten`);
  saga(c.granskning.status === "EJ_GRANSKAD" || (c.granskning.av && c.granskning.head),
    `${c.id}: en satt status bär vem och vilken head`);
  for (const r of c.referenser || []) saga(fs.existsSync(path.join(ROT, r)), `${c.id}: referensen ${r} finns i repot`);
  saga(Array.isArray(c.gap), `${c.id}: gap är en lista (tom = inget känt REFERENCE GAP)`);
}
const vyer = fs.readFileSync(path.join(ROT, "roblox/buildings/Vyer.luau"), "utf8");
for (const id of ids) saga(vyer.includes(`"${id}"`), `Roblox Vyer.luau har vyn ${id}`);
saga(!k.kameror.some(c => JSON.stringify(c.granskning || {}).includes("VISUALLY_ACCEPTED")), "ingen kamera bär VISUALLY_ACCEPTED (statusen finns inte för automation)");
console.log(fel ? `\n${fel} fel.` : "\nVisuell grind: kameralistan och Roblox-vyerna stämmer.");
process.exit(fel ? 1 : 0);
