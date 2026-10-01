# Circle: confirmation of a measured improvement (C1)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code.
Order: [CHATGPT_REVIEW_R1_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5863314184),
base `81f7b79`, branch `codex/circle-lesson-20260926`. Build now, physical test last.
Claude writes; ChatGPT reviews source; Tobias playtests the whole at the end.

This is the "confirmation of improvement" part of #266 C1 for ONE lesson: the
server-observed circle (`VoltLektion`, type `volt`). It reuses the pattern
already reviewed for tempo coaching (`TEMPO-COACHING-CONTRACT.md`, "The
comparison with the previous completed attempt"). It adds no new measurement,
no score, no persistence, no reward, no audio and no other lesson type.

## The one fact compared

`resultat.avsnitt.medelAvvikelse`: the completed circle's mean distance from
the reference line in metres. `VoltObservation` already measures it, and
`LektionsAterkoppling` already shows it. Smaller is closer to the line.

It is compared as the player sees it, rounded to 0.1 m.

**What is NOT compared:**
- direction (clockwise or anticlockwise; the next step asks for the other way) [antagande: the same figure and radius are comparable in either direction];
- time;
- the number of circles;
- rhythm;
- bend and contact.

## Server (`VoltLektion`)

**The baseline.** A valid completion becomes the baseline `s.forraKlar`.
- Valid means `medelAvvikelse` is finite and ≥ 0, and `referens.radie` is finite and > 0.
- It lives in the lesson object: the same ride, user, horse and `VoltObservation.VERSION`.
- It survives Retry. Only a later valid completion replaces it.

**The comparison.** At completion the server freezes
`s.jamforelse = {forsokId, forraForsokId, forraAvvikelse, avvikelse}`, but only when all of these hold:
- a baseline exists, with another `forsokId`;
- the same ride, user and horse;
- the same version;
- the same reference radius;
- both deviations are finite and ≥ 0.

**Where it appears.** The snapshot carries `jamforelse` only in `complete`, and only for the same `forsokId`.

**Clearing and reset:**
- start and retry clear `jamforelse` but keep the baseline;
- timeout, closed and finish never compare, and never overwrite the baseline;
- a new lesson object (a new ride, or a type switch that replaces it) starts without a baseline, so A-B-A gives no comparison.

## Client (`LektionsAterkoppling`)

The comparison is used only when all of these hold:
- the frozen summary itself is valid and bound to the displayed attempt (the existing rules);
- `j.forsokId == b.forsokId` and `j.forraForsokId ~= b.forsokId`;
- both numbers are finite and ≥ 0.

**DETAILED mode:**
- **Rounded now < rounded before:** "Closer to the line than your previous circle: on average X m, now Y m."
- **Otherwise:** "Previous circle: on average X m from the line, now Y m." This is neutral: no criticism and no invented reason.

**CONCISE mode:**
- only "Closer to the line than last time." when that holds;
- otherwise nothing.

**What stays the same:** the frozen summary and the ONE next step. The text is computed on every poll and never stored.

**It never claims:**
- mastery;
- cause;
- that advice worked;
- that the horse or rider was better or worse.

## Acceptance (written as tests; engine and physical play deferred)

**Server, `voltlektion.spec`, on a fresh ride:**
- the first completion has no comparison;
- a closer second circle compares against the first;
- an equal third circle compares neutrally;
- a timeout gives no comparison and keeps the baseline;
- the next completion compares against the last completion, not the timeout;
- closed or finish carries no comparison;
- a retry snapshot carries no comparison;
- a new ride has no baseline.

**Client, `lektionsaterkoppling.spec`:**
- closer, equal and worse;
- CONCISE closer and CONCISE not closer;
- rounding: 0.54 → 0.46 m is NOT closer (both show 0.5), while 0.56 → 0.44 m is (0.6 → 0.4);
- mismatched or equal `forsokId`, non-finite or negative values, and a missing table give no comparison and never throw;
- a locale switch changes the words, not the facts;
- an invalid frozen summary never gets a comparison appended.

**Falsification:** each central guard is mutated and must turn a test red:
- the rounding direction;
- the `forsokId` binding;
- the radius check;
- timeout overwriting the baseline;
- retry keeping a stale `jamforelse`.

**Not tested here:**
- Studio, runtime and touch;
- rendered text length on a phone;
- whether players find the confirmation motivating. That is Tobias' call.
