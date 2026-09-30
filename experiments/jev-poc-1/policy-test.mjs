// JEV-POC-1 — policyprov utan nätverk. En falsk Jev försöker bryta reglerna.
import assert from "node:assert/strict";
import { decideCoaching, deterministicFocus } from "./policy.mjs";
import { SCENARIOS, stateFor } from "./scenarios.mjs";

const base = stateFor(SCENARIOS.find((s) => s.id === "S07")); // linje dålig, klar övning
const game = { ...base, physics: { speed: 3.2 }, score: 12, progression: { lesson: "volt", done: false }, competition: null };
const snapshot = JSON.stringify(game);
let pass = 0;
const t = async (name, fn) => { await fn(); pass++; console.log("ok  " + name); };

await t("godtar tillåtet val över tröskeln", async () => {
  const d = await decideCoaching(game, async () => ({ choice: "line", confidence: 0.8 }), { threshold: 0.5 });
  assert.deepEqual([d.focus, d.source], ["line", "jev"]);
});
await t("under tröskeln -> deterministisk Ugneta", async () => {
  const d = await decideCoaching(game, async () => ({ choice: "praise", confidence: 0.2 }), { threshold: 0.5 });
  assert.deepEqual([d.focus, d.source], [deterministicFocus(base), "fallback_low_confidence"]);
});
await t("val utanför listan avvisas", async () => {
  for (const bad of ["grant_rosette", "set_score", "", null, 42, "PRAISE"]) {
    const d = await decideCoaching(game, async () => ({ choice: bad, confidence: 0.99 }), { threshold: 0.5 });
    assert.equal(d.source, "fallback_invalid");
  }
});
await t("NaN/saknad confidence -> fallback", async () => {
  for (const c of [NaN, undefined, "0.9", Infinity * 0]) {
    const d = await decideCoaching(game, async () => ({ choice: "line", confidence: c }), { threshold: 0.5 });
    assert.equal(d.source, "fallback_low_confidence");
  }
});
await t("API-fel -> fallback", async () => {
  const d = await decideCoaching(game, async () => { throw new Error("401 unauthorized"); }, { threshold: 0.5 });
  assert.deepEqual([d.focus, d.source], ["line", "fallback_error"]);
});
await t("timeout -> fallback", async () => {
  const d = await decideCoaching(game, () => new Promise(() => {}), { threshold: 0.5, timeoutMs: 50 });
  assert.equal(d.source, "fallback_error");
});
await t("Jev kan inte mutera spelets tillstånd", async () => {
  await decideCoaching(game, async (st) => {
    try { st.score = 999; } catch {}
    try { st.physics.speed = 0; } catch {}
    try { st.progression.done = true; } catch {}
    try { st.competition = { placing: 1 }; } catch {}
    return { choice: "line", confidence: 0.9 };
  }, { threshold: 0.5 });
  assert.equal(JSON.stringify(game), snapshot);
});
await t("utdata är fryst och bär bara fokus", async () => {
  const d = await decideCoaching(game, async () => ({ choice: "line", confidence: 0.9, score: 100 }), { threshold: 0.5 });
  assert.ok(Object.isFrozen(d));
  assert.deepEqual(Object.keys(d).sort(), ["confidence", "focus", "source"]);
});
await t("hårda grindar anropar aldrig Jev", async () => {
  for (const id of ["S24", "S27", "S28", "S29"]) {
    let called = false;
    const d = await decideCoaching(stateFor(SCENARIOS.find((s) => s.id === id)),
      async () => { called = true; return { choice: "praise", confidence: 1 }; }, { threshold: 0 });
    assert.equal(called, false, id);
    assert.deepEqual([d.focus, d.source], ["no_comment", "hard_gate"], id);
  }
});
console.log(`policy: ${pass}/9 gröna`);
setTimeout(() => process.exit(0), 0);
