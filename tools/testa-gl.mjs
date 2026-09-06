#!/usr/bin/env node
import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

const source = fs.readFileSync(new URL("../src/gl.js", import.meta.url), "utf8");
const context = {
  console,
  Math,
  Float32Array,
  parseInt,
  Array
};
vm.createContext(context);
vm.runInContext(source, context, { filename: "src/gl.js" });

// We need to serialize to cross the vm context boundary safely for deepEqual
const glFarg = (h) => JSON.parse(vm.runInContext(`JSON.stringify(glFarg(${JSON.stringify(h)}))`, context));

function runTests() {
  console.log("Kör tester för glFarg...");

  // Array passthrough
  assert.deepEqual(glFarg([1, 0.5, 0]), [1, 0.5, 0], "Array ska skickas igenom oförändrad");

  // 6-digit hex
  assert.deepEqual(glFarg("#FF0000"), [1, 0, 0], "Röd 6-siffrig hex ska bli [1, 0, 0]");
  assert.deepEqual(glFarg("#00FF00"), [0, 1, 0], "Grön 6-siffrig hex ska bli [0, 1, 0]");
  assert.deepEqual(glFarg("#0000FF"), [0, 0, 1], "Blå 6-siffrig hex ska bli [0, 0, 1]");

  // 3-digit hex
  assert.deepEqual(glFarg("#F00"), [1, 0, 0], "Röd 3-siffrig hex ska bli [1, 0, 0]");
  assert.deepEqual(glFarg("#0F0"), [0, 1, 0], "Grön 3-siffrig hex ska bli [0, 1, 0]");
  assert.deepEqual(glFarg("#00F"), [0, 0, 1], "Blå 3-siffrig hex ska bli [0, 0, 1]");

  // Mixed case
  assert.deepEqual(glFarg("#fF0000"), [1, 0, 0], "Blandade gemener och versaler 6-siffrig hex");
  assert.deepEqual(glFarg("#f00"), [1, 0, 0], "Gemener 3-siffrig hex");

  console.log("OK   glFarg hanterar edge cases korrekt");
}

runTests();
