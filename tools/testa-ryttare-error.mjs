#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../src/ryttare.js", import.meta.url), "utf8");

function testLaddaError(throws) {
  let context = {
    console,
    G: {},
    localStorage: {
      getItem() { if (throws) throw new Error("Storage blocked"); return null; },
      setItem() {},
      removeItem() {},
    },
  };
  vm.createContext(context);
  vm.runInContext(source, context, { filename: "src/ryttare.js" });
  const json = vm.runInContext("JSON.stringify(SPAR)", context);
  return JSON.parse(json);
}

const noll = testLaddaError(true);
assert.equal(noll.grupp, "ledlektion");
assert.equal(noll.poang, 0);
assert.equal(noll.pass, 0);
assert.deepEqual(noll.fortroende, {});

console.log("OK   laddaRyttare hanterar localStorage-fel mjukt");
