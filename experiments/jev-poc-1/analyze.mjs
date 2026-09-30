// JEV-POC-1 — analys av results.json: rå Jev, deterministisk baslinje och
// policy (grind -> Jev över tröskel -> fallback) för en tröskelsvep.
import { readFileSync, writeFileSync } from "node:fs";
import { SCENARIOS as CORE, STRESS, stateFor } from "./scenarios.mjs";
const SET = process.env.SET ?? "core";
const SCENARIOS = SET === "stress" ? STRESS : CORE;
import { deterministicFocus, hardGate } from "./policy.mjs";

const R = JSON.parse(readFileSync(new URL(`./results-${SET}.json`, import.meta.url)));
const byId = Object.fromEntries(SCENARIOS.map((s) => [s.id, s]));
const ok = (id, f) => byId[id].accept.includes(f);
const pct = (a, b) => `${a}/${b} (${Math.round((100 * a) / b)} %)`;
const rows = R.filter((r) => !r.error);

// 1. rå Jev
const rawOk = rows.filter((r) => ok(r.id, r.choice)).length;
// stabilitet mellan repetitioner
const reps = {};
for (const r of rows) (reps[r.id] ??= []).push(r);
const unstable = Object.entries(reps).filter(([, v]) => new Set(v.map((x) => x.choice)).size > 1).map(([k]) => k);
// deterministisk baslinje
const det = SCENARIOS.map((s) => ({ id: s.id, f: deterministicFocus(stateFor(s)) }));
const detOk = det.filter((d) => ok(d.id, d.f)).length;

// policy per tröskel
const sweep = [];
for (const T of [0, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]) {
  let good = 0, jevUsed = 0, jevUsedOk = 0;
  for (const r of rows) {
    const st = stateFor(byId[r.id]);
    let f;
    if (hardGate(st)) f = "no_comment";
    else if (r.confidence >= T) { f = r.choice; jevUsed++; if (ok(r.id, f)) jevUsedOk++; }
    else f = deterministicFocus(st);
    if (ok(r.id, f)) good++;
  }
  sweep.push({ T, good, n: rows.length, jevUsed, jevUsedOk });
}

// kategorier
const cats = {};
for (const r of rows) {
  const c = (cats[byId[r.id].cat] ??= { n: 0, ok: 0 });
  c.n++; if (ok(r.id, r.choice)) c.ok++;
}
// konfidens hos rätt/fel
const confOk = rows.filter((r) => ok(r.id, r.choice)).map((r) => r.confidence);
const confBad = rows.filter((r) => !ok(r.id, r.choice)).map((r) => r.confidence);
const mean = (a) => (a.length ? (a.reduce((x, y) => x + y, 0) / a.length).toFixed(2) : "–");
const ms = rows.map((r) => r.ms).sort((a, b) => a - b);

// Negativ kontroll: kan bedömningen alls falla?
const FOCI = ["praise", "tempo", "transition_timing", "line", "rein_pressure", "no_comment"];
const constRates = FOCI.map((f) => `${f} ${SCENARIOS.filter((s) => s.accept.includes(f)).length}/${SCENARIOS.length}`).join(" · ");
let shufOk = 0, shufN = 0;
for (let k = 0; k < 200; k++) {
  const ch = rows.map((r) => r.choice).sort(() => Math.random() - 0.5);
  rows.forEach((r, j) => { shufN++; if (ok(r.id, ch[j])) shufOk++; });
}
const control = `Negativ kontroll — konstant svar: ${constRates} · Jevs svar blandade mellan scenarier: ${Math.round(100 * shufOk / shufN)} %`;
console.log(control);
let md = `${control}

` + `# JEV-POC-1 — rådata\n\nModell: ${rows[0]?.model} · anrop: ${R.length} · fel: ${R.length - rows.length} · latens median ${ms[ms.length >> 1]} ms, max ${ms.at(-1)} ms\n\n`;
md += `Rå Jev godtagbart: ${pct(rawOk, rows.length)} · deterministisk Ugneta: ${pct(detOk, SCENARIOS.length)} · instabila scenarier: ${unstable.join(", ") || "inga"}\n\n`;
md += `Medelkonfidens godtagbara ${mean(confOk)} · ej godtagbara ${mean(confBad)}\n\n`;
md += `## Tröskelsvep (policy)\n\n| T | policy godtagbar | Jev använd | Jev godtagbar när använd |\n|---|---|---|---|\n`;
for (const s of sweep) md += `| ${s.T} | ${pct(s.good, s.n)} | ${s.jevUsed} | ${s.jevUsed ? pct(s.jevUsedOk, s.jevUsed) : "–"} |\n`;
md += `\n## Per kategori (rå Jev)\n\n| kategori | godtagbar |\n|---|---|\n`;
for (const [k, v] of Object.entries(cats)) md += `| ${k} | ${pct(v.ok, v.n)} |\n`;
md += `\n## Per scenario\n\n| id | kat | lektion | observationer | godtagbart | Jev (rep) | conf | sannolikheter | ok | determ. |\n|---|---|---|---|---|---|---|---|---|---|\n`;
for (const s of SCENARIOS) {
  const o = Object.entries(s.obs).filter(([, v]) => !["low", "soft", "not_applicable", "good"].includes(v)).map(([k, v]) => `${k}=${v}`).join(", ") || "allt bra";
  const extra = [s.exerciseState, s.history?.previous_advice && `förra=${s.history.previous_advice}`, s.history?.improved_since_previous && `förbättr=${s.history.improved_since_previous}`].filter(Boolean).join(", ");
  for (const r of reps[s.id] ?? []) {
    const p = Object.entries(r.probabilities).sort((a, b) => b[1] - a[1]).slice(0, 3).map(([k, v]) => `${k} ${v.toFixed(2)}`).join(", ");
    const d = det.find((x) => x.id === s.id).f;
    md += `| ${s.id} | ${s.cat} | ${s.lesson} | ${o}${extra ? "; " + extra : ""} | ${s.accept.join("/")} | ${r.choice} (${r.rep}) | ${r.confidence.toFixed(2)} | ${p} | ${ok(s.id, r.choice) ? "✓" : "✗"} | ${d}${ok(s.id, d) ? "" : " ✗"} |\n`;
  }
}
writeFileSync(new URL(`./report-data-${SET}.md`, import.meta.url), md);
console.log(md.split("## Per scenario")[0]);
console.log("MISSAR:");
for (const r of rows.filter((r) => !ok(r.id, r.choice))) console.log(r.id, byId[r.id].cat, "->", r.choice, r.confidence, JSON.stringify(r.probabilities));
console.log("DETERMINISTISKA MISSAR:", det.filter((d) => !ok(d.id, d.f)).map((d) => `${d.id}->${d.f}`).join(" "));
