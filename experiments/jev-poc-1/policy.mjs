// JEV-POC-1 — säkerhetspolicy runt Jev. Koden äger allt; Jev väljer bara
// ett fokus ur en tillåten lista.
//
//  1. Hårda grindar (övning ej klar, välfärdsstopp, nyss sagt något) avgörs
//     deterministiskt och Jev anropas inte alls.
//  2. Jevs svar godtas bara om det finns i FOCI och confidence >= tröskel.
//  3. Annars, eller vid API-fel/timeout: deterministisk Ugneta-logik.
//  4. Spelets tillstånd skickas som fryst kopia; utdata är bara {focus, source}.

import { FOCI } from "./scenarios.mjs";

export const COOLDOWN_S = 10;

const KEY_METRIC = {
  tempo: "tempo_variation",
  volt: "line_error", serpentin: "line_error", vag_mitt: "line_error", vag_diag: "line_error",
  markbom: "line_error", hornet: "line_error", halvvolt: "line_error",
  halt: "transition_timing", overgang: "transition_timing", galopp: "transition_timing",
};
const FOCUS_OF = {
  tempo_variation: "tempo", line_error: "line", transition_timing: "transition_timing", rein_pressure: "rein_pressure",
};
const BAD = new Set(["high", "late", "early", "heavy"]);
const MILD = new Set(["medium", "borderline_late", "uneven"]);

// Hård grind: returnerar "no_comment" om coaching inte får ske alls, annars null.
export function hardGate(state) {
  if (state.exercise_state !== "complete") return "no_comment";
  const s = state.seconds_since_last_advice;
  if (typeof s === "number" && s < COOLDOWN_S) return "no_comment";
  return null;
}

// Deterministisk Ugneta — samma form som dagens återkoppling: bevis först,
// jämförelse med förra försöket, sedan övningens huvudmått.
export function deterministicFocus(state) {
  const g = hardGate(state);
  if (g) return g;
  const o = state.observations;
  const key = KEY_METRIC[state.lesson];
  const known = Object.entries(o).filter(([, v]) => v !== "unknown" && v !== "not_applicable");
  if (known.length === 0) return "no_comment";
  if (key && o[key] === "unknown") return "no_comment";
  if (!key && state.lesson !== "clearround") return "no_comment";

  if (key && BAD.has(o[key])) return FOCUS_OF[key];
  for (const m of ["tempo_variation", "transition_timing", "line_error", "rein_pressure"]) {
    if (BAD.has(o[m])) return FOCUS_OF[m];
  }
  const improved = typeof state.history?.improved_since_previous === "string"
    && state.history.improved_since_previous.startsWith("yes");
  if (improved) return "praise";
  if (key && MILD.has(o[key])) return FOCUS_OF[key];
  return "praise";
}

export const QUESTION_TEXT = {
  question: "As Ugneta, the riding instructor, which single coaching focus is most useful to give the rider after this exercise?",
  guidance: [
    "Use only the evidence in `observations`, `notes` and `history`.",
    "When several problems exist, prefer the one most likely to be the underlying cause or the one the lesson is about.",
    "Praise good work, and praise clear improvement on the thing that was advised last time.",
    "If the same advice has not helped after repeated attempts, consider whether another focus addresses the cause.",
    "Stay silent when the evidence is missing or unreliable, the exercise did not finish, or advice was just given.",
  ],
};
export const CRITERIA = {
  praise: "Performance was good, or clearly improved on what was advised last time; encourage the rider.",
  tempo: "Unstable or uneven tempo/rhythm, or the horse breaking gait; focus on an even tempo.",
  transition_timing: "A transition or halt came too early or too late relative to its marker.",
  line: "The horse did not follow the intended line or figure (circle size, diagonal, centre line, approach to a pole).",
  rein_pressure: "The rein contact is heavy or uneven and is likely disturbing the horse.",
  no_comment: "Say nothing now: evidence is missing or unreliable, the exercise did not finish, advice was just given, or it is not a coaching moment.",
};

export function deepFreeze(o) {
  if (o && typeof o === "object" && !Object.isFrozen(o)) {
    Object.freeze(o);
    for (const v of Object.values(o)) deepFreeze(v);
  }
  return o;
}

// askJev(state) -> { choice, confidence, probabilities } | kastar
export async function decideCoaching(gameState, askJev, { threshold, timeoutMs = 3000 } = {}) {
  const state = deepFreeze(structuredClone(gameState));
  const g = hardGate(state);
  if (g) return Object.freeze({ focus: g, source: "hard_gate" });
  let ans;
  try {
    ans = await Promise.race([
      askJev(state),
      new Promise((_, rej) => setTimeout(() => rej(new Error("jev_timeout")), timeoutMs)),
    ]);
  } catch (e) {
    return Object.freeze({ focus: deterministicFocus(state), source: "fallback_error", error: String(e?.message ?? e) });
  }
  const choice = ans?.choice;
  const conf = ans?.confidence;
  if (typeof choice !== "string" || !FOCI.includes(choice)) {
    return Object.freeze({ focus: deterministicFocus(state), source: "fallback_invalid" });
  }
  if (!(typeof conf === "number" && Number.isFinite(conf)) || conf < threshold) {
    return Object.freeze({ focus: deterministicFocus(state), source: "fallback_low_confidence", jev: choice, confidence: conf });
  }
  return Object.freeze({ focus: choice, source: "jev", confidence: conf });
}
