import fs from 'fs';
import vm from 'vm';
import path from 'path';

const ROT = path.resolve(new URL(".", import.meta.url).pathname, "..");
const srcPath = path.join(ROT, "src", "gl.js");

const code = fs.readFileSync(srcPath, 'utf8');
const ctx = {};
vm.runInNewContext(code, ctx);

let failed = false;

function test(name, fn) {
  try {
    fn();
    console.log(`✅ ${name}`);
  } catch (e) {
    console.error(`❌ ${name}`);
    console.error(e);
    failed = true;
  }
}

function assertArrayCloseTo(actual, expected, msg) {
  if (actual.length !== expected.length) throw new Error(`${msg}: length mismatch`);
  for (let i = 0; i < actual.length; i++) {
    if (Math.abs(actual[i] - expected[i]) > 0.001) {
      throw new Error(`${msg}: Expected [${expected}], got [${actual}]`);
    }
  }
}

console.log("Testing glFarg...");

test("glFarg: returns array unmodified", () => {
  const arr = [0.1, 0.2, 0.3];
  const res = ctx.glFarg(arr);
  if (res !== arr) throw new Error("Expected same array by reference");
});

test("glFarg: converts #FFFFFF (white)", () => {
  const res = ctx.glFarg("#FFFFFF");
  assertArrayCloseTo(res, [1.0, 1.0, 1.0], "White conversion failed");
});

test("glFarg: converts #000000 (black)", () => {
  const res = ctx.glFarg("#000000");
  assertArrayCloseTo(res, [0.0, 0.0, 0.0], "Black conversion failed");
});

test("glFarg: converts #FF8000 (orange)", () => {
  const res = ctx.glFarg("#FF8000");
  assertArrayCloseTo(res, [1.0, 128/255, 0.0], "Orange conversion failed");
});

test("glFarg: converts #00FF00 (green)", () => {
  const res = ctx.glFarg("#00FF00");
  assertArrayCloseTo(res, [0.0, 1.0, 0.0], "Green conversion failed");
});

test("glMorka: dims color by factor", () => {
  const res = ctx.glMorka("#FF8000", 0.5);
  assertArrayCloseTo(res, [0.5, 64/255, 0.0], "Dimming failed");
});

if (failed) {
  process.exit(1);
}
