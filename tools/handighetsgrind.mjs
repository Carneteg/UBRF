#!/usr/bin/env node
/* ══════════════════════════════════════════════════════════════════
   HANDIGHETEN PÅ WEBBEN — ser spelaren UBRF eller dess spegelbild?

   Systergrind till roblox/tests/handighet.spec.luau. Den mäter Roblox;
   den här mäter webben, och båda mäter mot SAMMA ankare ur
   references/SITEPLAN.md och src/site.js rad 15–19:

       "Grusplanen ... ligger vid husens NORRA gavlar ... Därifrån ser
        man ridhuset till höger och stallet till vänster, precis som i
        verkligheten."

   ── VARFÖR GRINDEN BEHÖVS ──────────────────────────────────────────

   src/site.js är en KARTA: origo i sydväst, +x öster, +y norr. I 3D
   blir de X och Z med Y uppåt, och den kombinationen är VÄNSTERHÄNT.
   En vanlig lookAt hade därför visat spelaren en spegelbild — öster
   till vänster när man ser norrut.

   Webben kompenserar redan, i GL.kamera: vyn multipliceras med
   M4.skala(-1,1,1). Det är en reflektion, och en reflektion är precis
   vad som krävs — ingen rotation vänder handighet. Raden ser ut som
   en egendomlighet och är lätt att "städa bort". Gör man det blir
   hela anläggningen spegelvänd utan att ett enda annat prov blir rött,
   för varje koordinatprov överlever en spegling: DATAN är rätt, det
   är vad man SER som blir fel.

   Precis det hände på Roblox-sidan, och Tobias fick hitta det med
   ögonen i Studio. Den här grinden gör att det inte kan hända här.

   ── HUR DET MÄTS ───────────────────────────────────────────────────

   Inte genom att läsa koden, utan genom att KÖRA den: GL.kamera anropas
   med en attrapp-gl som bara sväljer uniformanropen, och de matriser
   produktionen faktiskt sätter (GL.proj, GL.vy) används för att
   projicera husens mittpunkter till skärmen. Vänster/höger avgörs av
   tecknet på skärmens x — samma sak spelaren ser.

   Varje ankare provas dessutom UTAN speglingen. Vänder det inte då
   mäter regeln ingenting, och grinden säger till.

   Kör: node tools/handighetsgrind.mjs        (exit 1 vid avvikelse) */
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const las = f => fs.readFileSync(path.join(ROT, f), "utf8");

const ctx = { console, Math, JSON, Float32Array, Uint8Array, window: {} };
vm.createContext(ctx);
vm.runInContext(las("src/gl.js") + "\n" + las("src/model.js") + "\n" + las("src/site.js"), ctx);

const GL = vm.runInContext("GL", ctx);
const M4 = vm.runInContext("M4", ctx);
const ANL = vm.runInContext("ANL", ctx);

/* Attrapp-gl: GL.kamera sätter GL.proj och GL.vy och skickar dem sedan
   vidare till drivrutinen. Vi behöver bara att det andra steget inte
   kastar. `u` svarar på vilket uniformnamn som helst. */
GL.bredd = 1600; GL.hojd = 900;
GL.u = new Proxy({}, { get: () => ({}) });
GL.gl = { uniformMatrix4fv() {}, uniform3f() {} };

/* Skärmens x för en världspunkt, genom produktionens egna matriser.
   `speglad = false` kopplar bort GL.kameras reflektion och används bara
   för falsifieringen. */
function skarmX(oga, mal, p, speglad = true) {
  GL.kamera(oga, mal, 1.02);
  const vy = speglad ? GL.vy : M4.mul(M4.skala(-1, 1, 1), GL.vy);
  const mv = M4.mul(GL.proj, vy);
  const x = mv[0] * p[0] + mv[4] * p[1] + mv[8] * p[2] + mv[12];
  const w = mv[3] * p[0] + mv[7] * p[1] + mv[11] * p[2] + mv[15];
  return x / w;
}

const hus = id => {
  const b = ANL.byggnader.find(b => b.id === id);
  if (!b) throw new Error("hittar inte byggnaden " + id);
  return [b.rekt.x + b.rekt.w / 2, 1.7, b.rekt.y + b.rekt.h / 2];
};

/* Blicken går söderut från grusplanen norr om gavlarna. Punkten räknas
   ur husens egna rektanglar; ett handskrivet tal här hade blivit en
   andra sanning som kan glida. */
const ridhus = ANL.byggnader.find(b => b.id === "ridhus").rekt;
const stall = ANL.byggnader.find(b => b.id === "stall").rekt;
const gardX = (ridhus.x + ridhus.w + stall.x) / 2;
const norrOmGavlarna = Math.max(ridhus.y + ridhus.h, stall.y + stall.h) + 7;

const ANKARE = [
  {
    namn: "ANKOMSTVYN: ridhuset till HÖGER och stallet till VÄNSTER",
    kalla: "references/SITEPLAN.md rad 22–23 · src/site.js rad 15–19",
    oga: [gardX, 1.7, norrOmGavlarna],
    mal: [gardX, 1.7, norrOmGavlarna - 30],
    a: hus("ridhus"), b: hus("stall"), aTillHoger: true,
  },
  {
    namn: "den som ser SÖDERUT har VÄSTER till höger (kartans regel)",
    kalla: "src/site.js rad 3: origo i sydväst, +x öster, +y norr",
    oga: [gardX, 1.7, norrOmGavlarna],
    mal: [gardX, 1.7, norrOmGavlarna - 30],
    a: [gardX - 20, 1.7, norrOmGavlarna - 30],
    b: [gardX + 20, 1.7, norrOmGavlarna - 30],
    aTillHoger: true,
  },
  {
    namn: "och den som ser NORRUT har ÖSTER till höger",
    kalla: "samma regel, andra hållet",
    oga: [gardX, 1.7, ridhus.y - 7],
    mal: [gardX, 1.7, ridhus.y + 23],
    a: [gardX + 20, 1.7, ridhus.y + 23],
    b: [gardX - 20, 1.7, ridhus.y + 23],
    aTillHoger: true,
  },
];

let fel = 0;
const check = (namn, villkor, detalj) => {
  if (!villkor) fel++;
  console.log(`  ${villkor ? "OK  " : "FEL "} ${namn}${detalj ? "  " + detalj : ""}`);
};

console.log("Handigheten på webben — mätt genom GL.kameras egna matriser\n");

for (const k of ANKARE) {
  const xa = skarmX(k.oga, k.mal, k.a);
  const xb = skarmX(k.oga, k.mal, k.b);
  const hoger = xa > xb;
  check(k.namn, hoger === k.aTillHoger,
    `skärm-x ${xa.toFixed(3)} mot ${xb.toFixed(3)} — ${hoger ? "höger" : "vänster"} · ${k.kalla}`);

  /* Falsifieringen: samma mätning utan reflektionen måste vända
     ankaret. Gör den inte det mäter regeln inte handighet. */
  const ua = skarmX(k.oga, k.mal, k.a, false);
  const ub = skarmX(k.oga, k.mal, k.b, false);
  check("   ↳ och utan GL.kameras spegling vänder ankaret", (ua > ub) !== hoger,
    `utan spegling: ${ua > ub ? "höger" : "vänster"}`);
}

if (fel > 0) {
  console.log(`\n${fel} mätning(ar) föll.`);
  console.log("HANDIGHET (webb): spelaren ser en SPEGELBILD av UBRF.");
  process.exit(1);
}
console.log("\nhandighetsgrind: alla gröna — webben visar UBRF rättvänt");
