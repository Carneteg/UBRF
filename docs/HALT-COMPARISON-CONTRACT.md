# Halt at X: confirmation of a measured improvement (C1)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code.
Order: [CHATGPT_REVIEW_C1_CIRCLE_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5863527113),
base `4a6f9e5`, branch `codex/circle-lesson-20260926`. Build now, physical test last.
Claude writes; ChatGPT reviews source; Tobias playtests the whole at the end.

This is the second lesson in #266 C1 "confirmation of improvement". It is the
start/halt lesson (`HaltLektion`, type `halt`), and it follows the circle
package exactly (`CIRCLE-COMPARISON-CONTRACT.md`). It adds:
- no new observation;
- no score;
- no persistence;
- no reward;
- no audio;
- no other lesson type.

## The one fact compared

**How close the completing halt stood to X, in metres.** This is the plane
distance from the frozen halt point `resultat.slutpunkt` (u, v) to the
lesson's X, `referens` (u, v).
- Both are already measured and used: the zone check `≤ ZON_R` (1.5 m) decides
  completion.
- Smaller is closer to X.
- It is compared as the player sees it, rounded to 0.1 m.

[antagande] The horse's root position stands for "at X". That proxy is the same
one the zone check already uses. It is not the rider's position at the letter,
and it says nothing about squareness or a correct halt.

**Not compared:**
- walked metres;
- seconds standing;
- straightness;
- the quality of the transition.

## Server (`HaltLektion`)

**At completion** the server computes the distance, but only when all of these hold:
- `slutpunkt` and `referens` are tables;
- all four coordinates are finite.

**Baseline.** A valid completion becomes the baseline
`s.forraKlar = {forsokId, rittId, userId, hastId, version, ramId, u, v, avstand}`.
- It lives in the lesson object.
- It survives Retry.
- Only a later valid completion replaces it.

**Comparison.** `s.jamforelse = {forsokId, forraForsokId, forraAvvikelse, avvikelse}` is frozen only when all of these hold:
- a baseline exists, with another `forsokId`;
- it has the same ride, user, horse, `HaltLektion.VERSION`, frame (`ramId`) and X (u, v);
- both distances are finite and ≥ 0.

The field names are the circle's, so the client reads both types with one rule.

**Snapshot.** It carries `jamforelse` only in `complete`, and only for the same `forsokId`.

**What clears or never compares:**
- start and retry clear it;
- timeout, closed and finish never compare and never overwrite the baseline;
- a new ride or a type switch means a new lesson object, and therefore no baseline.

**The frozen `resultat` is not changed.** It gets no new field, so LektionsMinne
and the existing summary are untouched.

## Client (`LektionsAterkoppling`)

The same rule as the circle, now table-driven for `volt` and `halt`, with each
type's own literal keys.
- It applies only after the valid frozen summary bound to the displayed attempt.
- It needs `j.forsokId == b.forsokId` and `j.forraForsokId ~= b.forsokId`.
- Both values must be finite and ≥ 0.

**DETAILED mode:**
- **Rounded now < rounded before:** "Closer to X than your previous halt: X m from X, now Y m."
- **Otherwise:** "Previous halt: X m from X, now Y m."

**CONCISE mode:**
- only "Closer to X than last time." when that holds;
- otherwise nothing.

It never claims:
- a correct or square halt;
- cause;
- mastery.

## Acceptance (written as tests; engine and physical play deferred)

**Server (`haltlektion.spec`), on a fresh ride through the real HorseService, RidingIntent and observations:**
- the first completion has no comparison, and a retry snapshot has none;
- a halt nearer X compares with the first;
- the third completion compares with the second;
- an equal halt is neutral;
- a timeout carries no comparison and keeps the baseline;
- the next completion compares with the last completion;
- a KONTROLL-injected baseline with another X, frame, version or horse is never compared;
- closed carries none;
- a new ride has no baseline.

**Client (`lektionsaterkoppling.spec`):**
- closer, equal and worse;
- number order;
- rounding;
- binding;
- non-finite values;
- CONCISE mode;
- locale;
- the halt never reads with the circle's keys, and vice versa;
- the circle cases remain green unchanged.

**Falsification.** Each of these guards is mutated and must turn a test red:
- the X/frame check;
- the rounding direction;
- the attempt binding;
- the timeout baseline;
- the order of the numbers.

**Not tested here:**
- Studio, runtime and touch;
- the rendered text length;
- motivational value, which is Tobias' call.
