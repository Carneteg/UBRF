#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../src/ryttare.js", import.meta.url), "utf8");

function ladda(saved) {
  let lagrat = saved == null ? null : JSON.stringify(saved);
  const context = {
    console,
    G: {},
    localStorage: {
      getItem() { return lagrat; },
      setItem(_key, value) { lagrat = value; },
      removeItem() { lagrat = null; },
    },
  };
  vm.createContext(context);
  vm.runInContext(source, context, { filename: "src/ryttare.js" });
  const json = vm.runInContext("JSON.stringify(SPAR)", context);
  return JSON.parse(json);
}

const gamla = ladda({
  grupp: "grupp3",
  poang: 1,
  pass: 12,
  fortroende: {
    lady: { rang: 0.91, pass: 4, rehab: true },
    chip: { rang: 0.72, pass: 2 },
    air: { rang: 0.63, pass: 3 },
  },
  historik: [
    { hast: "lady", snitt: 0.8 },
    { hast: "air", snitt: 0.7 },
  ],
  rosetter: [
    { hast: "kennedy", plac: 1 },
    { hast: "air", plac: 2 },
  ],
  fardighet: { sits: 0.77 },
  jag: { skapad: true, namn: "Test" },
});

assert.equal(gamla.hastkanonVersion, "2026-09-01");
assert.equal(gamla.grupp, "grupp3");
assert.equal(gamla.poang, 1);
assert.equal(gamla.pass, 12);
assert.equal(gamla.fardighet.sits, 0.77);
assert.equal(gamla.jag.namn, "Test");
assert.equal(gamla.fortroende.lady, undefined);
assert.equal(gamla.fortroende.chip, undefined);
assert.deepEqual(gamla.fortroende.air, { rang: 0.63, pass: 3 });
assert.deepEqual(gamla.historik.map(r => r.hast), ["air"]);
assert.deepEqual(gamla.rosetter.map(r => r.hast), ["air"]);

const redanMigrerad = ladda({
  grupp: "grupp1",
  poang: 0,
  pass: 5,
  hastkanonVersion: "2026-09-01",
  fortroende: {
    lady: { rang: 0.58, pass: 1 },
    air: { rang: 0.61, pass: 2 },
  },
  historik: [{ hast: "lady", snitt: 0.6 }],
  rosetter: [{ hast: "lady", plac: 3 }],
});

assert.equal(redanMigrerad.hastkanonVersion, "2026-09-01");
assert.deepEqual(redanMigrerad.fortroende.lady, { rang: 0.58, pass: 1 });
assert.deepEqual(redanMigrerad.historik.map(r => r.hast), ["lady"]);
assert.deepEqual(redanMigrerad.rosetter.map(r => r.hast), ["lady"]);

const ny = ladda(null);
assert.equal(ny.hastkanonVersion, "2026-09-01");
assert.deepEqual(ny.fortroende, {});

console.log("OK   hästkanon-save migrerar gamla identiteter exakt en gång");
