// JEV-POC-1 — skickar varje scenario RÅTT till Jev (utan grindar) så att
// själva modellen mäts; policyn räknas sedan offline i analyze.mjs.
// Skriver aldrig ut nyckeln.
import { writeFileSync } from "node:fs";
import { SCENARIOS as CORE, STRESS, stateFor } from "./scenarios.mjs";
const SET = process.env.SET ?? "core";
const SCENARIOS = SET === "stress" ? STRESS : CORE;
import { QUESTION_TEXT, CRITERIA } from "./policy.mjs";

import { choice, TypeSafeClient } from "@typesafe-ai/sdk";
const client = new TypeSafeClient();
const REPS = Number(process.env.REPS ?? 2);
const redact = (m) => String(m).replaceAll(process.env.TYPESAFE_API_KEY ?? "\u0000", "[REDACTED]");

async function ask(state) {
  const t0 = performance.now();
  const res = await client.systemOne({
    state,
    questions: { focus: choice(QUESTION_TEXT, CRITERIA) },
  });
  const a = res.answers.focus;
  return { choice: a.choice, confidence: a.confidence, probabilities: a.probabilities, model: res.model, ms: Math.round(performance.now() - t0) };
}

const jobs = [];
for (let r = 0; r < REPS; r++) for (const s of SCENARIOS) jobs.push({ s, r });
const out = [];
let i = 0;
async function worker() {
  while (i < jobs.length) {
    const { s, r } = jobs[i++];
    try { out.push({ id: s.id, rep: r, ...(await ask(stateFor(s))) }); }
    catch (e) { out.push({ id: s.id, rep: r, error: redact(e?.message ?? e), status: e?.status }); }
  }
}
await Promise.all([worker(), worker(), worker(), worker()]);
out.sort((a, b) => a.id.localeCompare(b.id) || a.rep - b.rep);
writeFileSync(new URL(`./results-${SET}.json`, import.meta.url), JSON.stringify(out, null, 2));
console.log(`calls=${out.length} errors=${out.filter((o) => o.error).length}`);
