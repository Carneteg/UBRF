/* Enhetstest för lektionslogiken (stegaLektion) i src/game.js.

   Körs utan Playwright och DOM, direkt i Node-VM.

   Kör: node tools/test-lektion.mjs */

import fs from "node:fs";
import path from "node:path";
import vm from "node:vm";

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");

const ctx = vm.createContext({
  console,
  Math,
  JSON,
  document: {
    getElementById: () => ({ textContent: '', classList: { add: () => {}, remove: () => {}, toggle: () => {} }, appendChild: () => {} }),
    querySelector: () => ({ style: { width: '' }, classList: { toggle: () => {} } }),
    querySelectorAll: () => [],
    createElement: () => ({ classList: { add: () => {} }, dataset: {}, style: {} }),
    body: { appendChild: () => {} }
  },
  window: {},
  requestAnimationFrame: () => {},
  addEventListener: () => {},
  performance: { now: () => Date.now() },
  saga: () => {},
  startaBana: () => {},
  stegaBana: () => {},
  ritaIntroTangenter: () => {},
  lararSteg: () => {},
  passSlut: () => {},
  avslutaBana: () => {},
  registreraPass: () => {},
  visaTavlingsResultat: () => {},
  visaResultat: () => {},
  GRUPPNAMN: { "grupp2": "Märke 2" },
  MOMENT_OVNING: {}
});

const files = [
  "src/data.js",
  "src/model.js",
  "src/framsteg.js",
  "src/game.js"
];

for (const f of files) {
  vm.runInContext(fs.readFileSync(path.join(ROT, f), "utf8"), ctx, { filename: f });
}

let fel = 0;
function prova(namn, ok, detalj) {
  console.log(ok ? "  OK  " : "  FEL ", namn, "—", detalj);
  if (!ok) fel++;
}

const res = vm.runInContext(`
  // --- MOCK OVERRIDES ---
  saga = function() {};

  const resultat = [];
  const min_prova = (namn, ok, detalj) => { resultat.push({ namn, ok, detalj }); };

  const dt = 1 / 60;

  function setUp(grupp = "grupp2") {
    G.scen = "lektion";
    G.grupp = grupp;
    G.hastId = "bandit";
    G.ride = nyState(0.7, 0.5, 0.8);
    G.aids = { tygel: 0.5 }; // kontakt

    G.momentIx = 0;
    G.lektion = [
      { id: "test_moment1", tid: 10, bedoms: true, gangart: "halt" },
      { id: "test_moment2", tid: 10, bedoms: true, gangart: "halt" }
    ];
    G.moment = G.lektion[G.momentIx];
    G.momentT = 0;
    G.momentHall = 0;
    G.momentKlart = false;
    G.hoppaMoment = false;
    G.betyg = {};
  }

  // TEST 1: momentHall stiger när kvalitet, tempo och kontakt hålls
  setUp();
  G.ride.skala = { takt: 1.0, losgjordhet: 1.0, kontakt: 1.0, schvung: 1.0, rakriktning: 1.0, samling: 1.0 };
  let mal = momentMal(G.moment, G.grupp);

  stegaLektion(1.0); // stega 1 sekund
  min_prova("momentHall stiger vid rätt inverkan", G.momentHall > 0.99, "momentHall=" + G.momentHall);

  // TEST 2: momentHall sjunker vid släppt kontakt
  let fore_slapp = G.momentHall;
  G.aids.tygel = 0.0; // släppt kontakt
  stegaLektion(1.0);
  min_prova("momentHall sjunker vid slak tygel (bruten kontakt)", G.momentHall < fore_slapp, "fore=" + fore_slapp + " efter=" + G.momentHall);

  // TEST 3: momentHall minskar vid fel tempo
  setUp();
  G.ride.skala = { takt: 1.0, losgjordhet: 1.0, kontakt: 1.0, schvung: 1.0, rakriktning: 1.0, samling: 1.0 };
  G.moment = { id: "test_moment3", tid: 10, bedoms: true, gangart: "trav" };
  G.lektion = [G.moment];
  // tempo i trav är runt 3.2 m/s, vi sätter skrittfart 1.5
  G.ride.tempo = 1.5;
  G.ride.gangart = "skritt";

  stegaLektion(1.0);
  min_prova("momentHall minskar (går ej upp) när tempot är fel", G.momentHall <= 0, "momentHall=" + G.momentHall);

  // TEST 4: Momentet slutförs och man går vidare när momentHall = mal.hall
  setUp();
  G.ride.skala = { takt: 1.0, losgjordhet: 1.0, kontakt: 1.0, schvung: 1.0, rakriktning: 1.0, samling: 1.0 };
  mal = momentMal(G.moment, G.grupp);

  // Kör fram tills vi ska vara klara
  let passed_klart = false;
  for(let i=0; i < (mal.hall / dt) + 10; i++) {
     stegaLektion(dt);
     // Om det bytt moment, så hade det precis blivit klart
     if (G.momentIx === 1) {
         passed_klart = true;
         break;
     }
  }
  min_prova("momentKlart sätts och momentet avslutas när hall-kravet är nått", passed_klart === true, "passed_klart=" + passed_klart);

  // TEST 5: Taket slår in - om man är usel så går lektionen vidare ändå
  setUp();
  // usel = noll poäng
  G.ride.skala = { takt: 0, losgjordhet: 0, kontakt: 0, schvung: 0, rakriktning: 0, samling: 0 };

  stegaLektion(G.moment.tid * 2.2); // max taket är tid * 2.2
  min_prova("momentet avslutas ändå när max-tiden löper ut (tid*2.2)", G.momentIx === 1, "momentIx=" + G.momentIx);

  resultat;
`, ctx);

for (const r of res) {
  prova(r.namn, r.ok, r.detalj);
}
console.log(fel ? `${fel} FEL` : "ALLA OK");
process.exit(fel ? 1 : 0);
