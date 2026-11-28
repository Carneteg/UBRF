#!/usr/bin/env node
/* ══════════════════════════════════════════════════════════════════
   KULLNINGSGRINDEN — pekar nätens ljusnormaler verkligen UTÅT?

   Motor-engineering 0.1 / A1 (se docs/ACTIVE-GATE.md). Mäter två
   funktioner i produktionskällan, inte en omskriven kopia:

     - s3Svep (src/scen3d.js) — bygger hästens kropp, hals och huvud
       (och people-torson/jeans/hand i src/varld3d.js) som ett slutet
       svept rörnät. Normalen räknades tidigare ut som tangent × sido-
       vektor i FEL ordning och pekade exakt inåt (dot -1 mot den sanna
       utåtriktningen i varje testad punkt).
     - glPlatta (src/gl.js) — fasetterar om ett näts normaler per
       triangel, för spelets standardläge STIL="kloss". Den räknade om
       normalen direkt ur triangelns EGNA hörnordning, som av en annan,
       helt avsiktlig anledning är "inåt sedd" (se kommentaren vid
       M4.skala(-1,1,1) i GL.kamera, och GEO.ladas handskrivna, äkta
       utåtnormaler som är frikopplade från sin egen vindning). Det
       gjorde att glPlatta skrev över GEO.ladas rätta normaler med
       vända.

   I BÅDA fallen är själva triangelvarvet/kulningen RÄTT redan innan
   fixen — det är bara den lagrade ljusnormalen som var vänd. Grinden
   mäter därför bara normalriktningen, inte vindningen (den mäts redan
   av tools/handighetsgrind.mjs, som är en annan mekanism).

   ── HUR DET MÄTS ───────────────────────────────────────────────────

   s3Svep: bygger ett rör (f(t,u) = (t, cos 2πu, sin 2πu)) där den sanna
   utåtnormalen i varje punkt är känd analytiskt: (0, cos 2πu, sin 2πu).
   Varje vertexnormal s3Svep faktiskt lagrar jämförs mot den.

   glPlatta: bygger en riktig GEO.lada-låda (vars sex handskrivna
   normaler per konstruktion är sant utåtriktade), sparar dess
   ursprungliga per-vertex-normaler, köttar genom glPlatta, och
   jämför den omräknade per-triangel-normalen mot lådans egen,
   ursprungliga, rätta normal för samma triangel.

   Godkänt = varje jämförd normal pekar inom 90° av den sanna
   riktningen (dot > 0); en vänd normal ger dot ≈ -1.

   ── FALSIFIERING ───────────────────────────────────────────────────

   Körs grinden med --muter-trasigt återinförs de två exakta rader som
   orsakade buggen (textersättning mot den körda källtexten, inte en
   egen kopia). Det MÅSTE göra grinden röd — annars mäter den ingenting.

   Kör: node tools/kullningsgrind.mjs            (exit 1 vid avvikelse)
        node tools/kullningsgrind.mjs --muter-trasigt   (måste bli röd) */
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const las = (f) => fs.readFileSync(path.join(ROT, f), "utf8");

const MUTERA = process.argv.includes("--muter-trasigt");

function byggKontext(muteraBuggen) {
  let glKod = las("src/gl.js");
  let scenKod = las("src/scen3d.js");
  if (muteraBuggen) {
    const g0 = glKod;
    glKod = glKod.replace(
      "let nx=e2[1]*e1[2]-e2[2]*e1[1],\n        ny=e2[2]*e1[0]-e2[0]*e1[2],\n        nz=e2[0]*e1[1]-e2[1]*e1[0];",
      "let nx=e1[1]*e2[2]-e1[2]*e2[1],\n        ny=e1[2]*e2[0]-e1[0]*e2[2],\n        nz=e1[0]*e2[1]-e1[1]*e2[0];",
    );
    if (g0 === glKod) throw new Error("mutationsankaret för glPlatta hittades inte i src/gl.js — grinden kan inte falsifieras");
    const s0 = scenKod;
    scenKod = scenKod.replace(
      "let n=[w[1]*t[2]-w[2]*t[1], w[2]*t[0]-w[0]*t[2], w[0]*t[1]-w[1]*t[0]];",
      "let n=[t[1]*w[2]-t[2]*w[1], t[2]*w[0]-t[0]*w[2], t[0]*w[1]-t[1]*w[0]];",
    );
    if (s0 === scenKod) throw new Error("mutationsankaret för s3Svep hittades inte i src/scen3d.js — grinden kan inte falsifieras");
  }
  const ctx = { console, Math, JSON, Float32Array, Uint8Array, Int32Array, window: {} };
  vm.createContext(ctx);
  vm.runInContext(glKod + "\n" + scenKod, ctx);
  return ctx;
}

function provaS3Svep(ctx) {
  const s3Svep = vm.runInContext("s3Svep", ctx);
  const Bygge = vm.runInContext("Bygge", ctx);
  const nt = 8, nu = 16;
  const f = (t, u) => {
    const vinkel = u * Math.PI * 2;
    return [t, Math.cos(vinkel), Math.sin(vinkel)];
  };
  const b = s3Svep(new Bygge(), "#ffffff", nt, nu, f);
  let varsta = 1, varstaPunkt = null;
  for (let i = 0; i <= nt; i++) for (let j = 0; j <= nu; j++) {
    const idx = i * (nu + 1) + j;
    const vinkel = (j / nu) * Math.PI * 2;
    const ut = [0, Math.cos(vinkel), Math.sin(vinkel)];
    const n = [b.n[idx * 3], b.n[idx * 3 + 1], b.n[idx * 3 + 2]];
    const dot = n[0] * ut[0] + n[1] * ut[1] + n[2] * ut[2];
    if (dot < varsta) { varsta = dot; varstaPunkt = { i, j }; }
  }
  return { namn: "s3Svep (hästkropp/hals/huvud — svept rörnät)", varsta, varstaPunkt };
}

function provaGlPlatta(ctx) {
  const Bygge = vm.runInContext("Bygge", ctx);
  const glPlatta = vm.runInContext("glPlatta", ctx);
  const b = new Bygge().lada(2, 2, 2, "#ffffff", null);
  const forreN = b.n.slice(), forreI = b.i.slice();
  glPlatta(b);
  let varsta = 1, varstaTri = null;
  const tri = forreI.length / 3;
  for (let t = 0; t < tri; t++) {
    const v0 = forreI[t * 3];
    const ratt = [forreN[v0 * 3], forreN[v0 * 3 + 1], forreN[v0 * 3 + 2]];
    const nb = t * 3;
    const ny = [b.n[nb * 3], b.n[nb * 3 + 1], b.n[nb * 3 + 2]];
    const dot = ratt[0] * ny[0] + ratt[1] * ny[1] + ratt[2] * ny[2];
    if (dot < varsta) { varsta = dot; varstaTri = t; }
  }
  return { namn: "glPlatta (klossläge, mätt mot GEO.ladas egna normaler)", varsta, varstaTri };
}

console.log(MUTERA
  ? "Kullningsgrinden — körs med --muter-trasigt (buggen återinförd, MÅSTE bli röd)\n"
  : "Kullningsgrinden — pekar nätens ljusnormaler utåt?\n");

const ctx = byggKontext(MUTERA);
const prov = [provaS3Svep(ctx), provaGlPlatta(ctx)];

let fel = 0;
for (const p of prov) {
  const ok = p.varsta > 0;
  if (!ok) fel++;
  console.log(`  ${ok ? "OK  " : "FEL "} ${p.namn}  sämsta dot=${p.varsta.toFixed(3)}`);
}

if (MUTERA) {
  if (fel === prov.length) {
    console.log("\nFalsifiering lyckades: den återinförda buggen gör grinden röd, som avsett.");
    process.exit(0);
  }
  console.log("\nFalsifiering MISSLYCKADES: grinden blev inte röd trots återinförd bugg — den mäter ingenting.");
  process.exit(1);
}

if (fel > 0) {
  console.log(`\n${fel} nät har minst en normal som pekar inåt i stället för utåt.`);
  process.exit(1);
}
console.log("\nkullningsgrind: alla gröna — ljusnormalerna pekar utåt");
