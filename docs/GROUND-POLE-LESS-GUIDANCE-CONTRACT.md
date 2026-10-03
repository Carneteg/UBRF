# Ground pole: less guidance by the player's choice (C3, option A pattern)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code (ACK [#5865101589](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865101589)).
Order: [CHATGPT_REVIEW_C3_HALF_CIRCLE_LESS_GUIDANCE_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865074684).
Semantics as in [ROUTE-LESS-GUIDANCE-CONTRACT.md](ROUTE-LESS-GUIDANCE-CONTRACT.md) (Tobias' option A).
Base `0d5ff83`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

## The five remaining candidates, from source

For every candidate the server assessment is independent of the guide: the guide is drawn only into the local `Voltguide` model, and the server lesson never reads it.

| Lesson | What the client guide draws (`visaGuide` / `markbomGuide`) | What could be removed with the task still unambiguous | Clean? |
|---|---|---|---|
| `volt` | one dashed ring, 72 dashes, the allowed inner band | nothing can be removed; only "thinner dashes" would be possible, and that is a new density decision, not removing a part | no |
| `halt` | one ring (16 dashes) = the zone at X | it is the only mark; without it, X is not visible | no |
| `overgang` | two rings, T1 and T2, on the centre line | the only marks; training targets, not physical letters | no |
| `galopp` | one ring at K | the only mark | no |
| `markbom` | corridor edges on the approach, chevrons towards the pole, one mark beside each pole end, and exit-lane edges | the approach edges, the chevrons and the exit lanes; **the pole itself is a physical object** | **yes** |

## The exact reduction (`markbomGuide`, client only)

**Removed:**
- the approach corridor edges;
- the approach chevrons;
- the exit-lane edges.

**Kept:** the **two marks beside the pole ends** (never on the pole), and of course the physical pole.

**Why the task stays unambiguous from source:**
- **The corridor.** It is `|a| ≤ bredd/2 + 0.5 m` around the pole's normal through its middle. The pole's own length and the two end marks show it: ride straight at the pole, between the marks.
- **The direction.** It is towards C, which the lesson's own texts state. Riding the wrong way is already its own tip (`wrong_direction`).
- **The approach.** It needs 4 m of straight walking inside the corridor, anywhere within 10 m before the pole. If the rider starts too late, the lesson already says so (`approach_longer`: "Börja lite längre bak så att ni hinner skritta rakt fram").
- **The exit.** It is straight on, the same line, which is not a new choice.

**Honest limit:** without the edge dashes, the 10 m approach depth is not drawn. It is covered by the existing tip, not by a mark. Visual sufficiency from the saddle is not claimed.

## Semantics (option A)

**Eligibility.** Only when `klarad("markbom")` holds (LektionsMinne `sparad`/`vantar`), and only on the ground pole page.

**Label.** The ground pole's own truthful text, because the pole-end marks remain:
- `markbomlektion.mindre_stod`: "Rid bara efter bommen och märkena" / "Ride by the pole and its marks only".
- "Visa vägen" (`vaglektion.visa_vagen`) restores the full guide.

**Lifetime.** The same session-local flag. It resets on a type switch, a cancel or reattach, and a new ride. It is never saved, never automatic, and sends no server request.

**Unchanged:** the server task, corridor, approach, pole observation, exit, thresholds, feedback and memory; every other guide.

## Acceptance (written as tests; engine and physical play deferred)

The tests are in `markbomlektion.spec`, through the real `VoltLektionController` and the real `Voltguide` parts.

**How the parts are classified.** The pole-end marks have width `0.3·spm × 0.65`; everything else in this guide has width `0.35·spm × 0.65`.

**Checks:**
1. Not completed: no choice; the full guide has other parts > 0 and exactly 2 pole-end marks.
2. Completed: its own label.
3. Pressing it sends no request.
4. After pressing: other = 0, pole marks = 2. The button reads "Visa vägen".
5. The approach and passage complete as before with less guidance on.
6. "Visa vägen" gives the full counts again.
7. A type switch, cancel plus reattach, and a new ride reset it.
8. Another type is counted and shows no choice.
9. SV/EN.
10. The route, corner and half-circle specs stay green.

**Falsification:**
- the approach edges still drawn;
- the exit lanes still drawn;
- the chevrons still drawn;
- the pole marks dropped;
- the choice without completion;
- another lesson's label used;
- no reset.

**Full suite once.**

**Not tested:**
- Studio, runtime and touch;
- whether the pole and its marks are enough from the saddle;
- fun.

## After this

No clean candidate remains for the less-guidance pattern: volt, halt, transitions and canter have only their single target mark, and serpentine has only curves. C3 less-guidance stops here, and the remaining C3 gaps (difficulty steps, a saved "less support", the general rehearsal) are summarised in the report.
