# B4b: refusal and run-out per fence attempt — only what the server observes

Status: contract written before code, 2026-09-28. **R1 (below) SUPERSEDES the classifier section:** `HinderObservation` emits neutral evidence only; a verdict belongs to the course-aware consumer.
Order: [CHATGPT_REVIEW_B4A_ACCEPTED](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5869108172) and
[CHATGPT_B4B_EXECUTE_NOW](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5869238281). Base `7d51edf`.
**No change to D2 judging, no rosette.** Physical test last.

## Source (added first)

**SvRF TR III Hoppning 2025, moment 385, pp. 90–93.** It is quoted verbatim in `references/rules/TR-III-2025-hoppning-A-clear-round.md`.
- It comes from the **same PDF** as D1 (SHA-256 `01f0268e…70b37`).
- **Checked 2026-09-28:** SvRF's TR III page lists 2025 as the edition in force, with no 2026 edition. The TR is valid for two years, starting in odd years.

The key definitions:
- **Refusal, 3.1:** "stannar framför ett hinder, som ska hoppas … och därefter blir otvetydigt stående, träder bakåt om också ett enda steg, eller vänder".
- **3.5:** "Det räknas inte som vägran om hästen stannar tätt intill hindret och – utan att … träda tillbaka – omedelbart hoppar hindret från stället."
- **Run-out, 4.1:** "När hästen passerar vid sidan av ett hinder som ska hoppas."
- **Circle, 1.3:** crossing its own track between consecutive fences.
- **1.4:** moves after a disobedience, without a renewed approach, are not a new disobedience.
- **Balking, 5.1:** a stop at any time.

## Audit: what `HinderObservation` observes today

| Signal | What it means | Source |
|---|---|---|
| `utfall = sidan_om` | the plane was crossed **outside** the fence width, within the zone's side margin | observed segment geometry |
| `utfall = ingen_passage` | the zone was left **without** crossing | observed |
| `utfall = passage`, `riktning` | crossed within the width, with confirmed sides | observed |
| the entry side (`_sida` at the first sample) | the side the attempt began from | observed, **not exposed today** |
| speed | **not computed today**, but every segment carries a position and ride time, and the ride observation produces segments even at zero speed (checked in your B4a review) | derivable |
| heading/turn | **not in the segments** | not observable here |
| the course order ("ska hoppas"), a track crossing between fences | **not in `HinderObservation`** (it knows no course); the track is not stored | D2 / later |

## Classifier (per attempt, in `HinderObservation`)

**New fields:**
- `olydnad` = `"vagran"` | `"utbrytning"` | `"ingen"` | `"okand"`;
- `olydnadGrund`;
- `tStopp`;
- `inSida` = `"fram"` | `"bak"` | nil. This is the side entered from, with the same sign as `riktning`. It is what lets D2 later check the approach direction.

**A stop** = a segment **in the zone, on the entry side, before any crossing** where the planar speed is at most `STOPP_FART`.
- The speed is (planar distance) ÷ (the ride-time delta from the previous segment).
- `STOPP_FART` = 0.3 studs/s is a `[antagande]`: TR gives no speed limit.
- The ride's first segment gives no speed.

**Moved back** = after the stop, |v| grows by more than `BAKAT_TOL` = 1.0 stud (`[antagande]`, about a step), still on the entry side and before any crossing.

| Observed (in priority order) | `olydnad` | `olydnadGrund` | TR |
|---|---|---|---|
| validity ≠ `fullstandig` (break, ride end, fence invalid or removed) | `okand` | `ofullstandigt` | — |
| a stop, then moved back, before any crossing | `vagran` | `stopp_och_bakat` | 3.1 (steps back / turns) |
| `sidan_om` (and not the above) | `utbrytning` | `sidan_om` | 4.1 |
| a stop, then a crossing within the width without moving back | `okand` | `stopp_sedan_passage` | 3.1 "otvetydigt stående" vs 3.5 "omedelbart": no time given, so **not decidable** |
| `passage` with no observed stop | `ingen` | `passage_utan_stopp` | — |
| `ingen_passage` with no observed stop | `okand` | `ingen_passage` | a brief stop between samples cannot be ruled out (the approach might be a refusal) |
| `ingen_passage` with a stop but no move back (standing still until the zone is left) | `okand` | `stopp_utan_bakat` | — |

**Principles:**
- **A stop alone never gives a refusal.**
- **Nothing is inferred from speed variations without a stop.**
- Anything ambiguous gives `okand`.
- **One classification per attempt** (in line with 1.4: moves within the same zone presence are not a new disobedience).

## Not in B4b (observation or product gaps)

- **Circle (1.3):** needs the track between consecutive **course** fences. Neither `HinderObservation` nor the track store has that; the course order lives in D2.
- **Balking (5.1):** "a stop at any time" would count every stop on the course, including deliberate ones (5.2). That needs its own observation outside the zones **and** a product decision (FUN FIRST).
- **Wrong course / "ska hoppas":** whether the fence was the next one and was approached in the right direction is D2's (the consumer's) business, through `inSida` and the course order.

## Consumers later (not built now)

- **D2 `ClearRoundLektion`:** `olydnader` counts `vagran`/`utbrytning` on **the next fence**, with `inSida` in the course direction. `okand` on the next fence gives a result that cannot be established (as `utesluten_ej_faststalld`). Today only `sidan_om` counts.
- **D1:** `runda.olydnader`.

## Acceptance (`hinderolydnad.spec`, a module contract with only `HinderObservation`)

1. **Run-out:** a crossing outside the width gives `utbrytning`/`sidan_om`, with `inSida`.
2. **Refusal:** a stop in front of the fence, then moving back more than the tolerance, then leaving the zone on the entry side, gives `vagran`/`stopp_och_bakat` and `tStopp`.
3. **Refusal then a jump in the same attempt** (stop, back, forward, crossing) gives `vagran`, while `utfall` stays `passage`.
4. **A stop, then a jump without moving back** gives `okand`/`stopp_sedan_passage`.
5. **A passage with no stop** gives `ingen`.
6. **`ingen_passage` with no stop** gives `okand`. **With a stop and no move back** gives `okand`/`stopp_utan_bakat`.
7. **Slowing down (above `STOPP_FART`) and then moving back** gives **no** refusal.
8. **A move back below the tolerance** gives no refusal.
9. **A stop after the crossing** (on the far side) does not count.
10. **A break mid-attempt** gives `okand`/`ofullstandigt`.
11. **Existing fields unchanged:** `utfall`, `riktning`, `nedslag` and all existing specs are unchanged and green.
12. **Falsification:**
    - a stop alone counts as a refusal;
    - no speed requirement;
    - no back tolerance;
    - an ambiguous stop-then-jump counts as a refusal;
    - `ingen_passage` counts as `ingen`.

**Full suite; re-lock** (`HinderObservation` is mapped).

**Not tested:**
- real stop and speed profiles in Studio;
- calibration of `STOPP_FART`/`BAKAT_TOL`;
- network jitter at low speed.

All of this is PHYSICAL TEST LAST.

## R1: observation, not judging (CHATGPT_REVIEW_B4B_CHANGES_REQUESTED_OBSERVATION_VS_JUDGING, #5869638876)

**The problem:** TR 385 defines refusal (3.1) and run-out (4.1) relative to **"ett hinder som ska hoppas"**. `HinderObservation` knows neither the course order, nor which fence is next, nor whether an approach is renewed after an earlier disobedience. So it must not issue a sporting verdict.

**Changes (only `HinderObservation`):**
- **The `olydnad` and `olydnadGrund` fields are removed.** Neither `"vagran"`, `"utbrytning"` nor `"ingen"` exists in the observation layer.
- **Neutral evidence per attempt instead:**

| Field | Meaning |
|---|---|
| `stoppObserverat` | `true`/`false`: a segment in the zone, on the entry side, **before any crossing**, with planar speed ≤ `STOPP_FART` |
| `tStopp` | the ride time of the first such segment, or nil |
| `bakatEfterStopp` | `true`/`false`: after the stop, before any crossing and still on the entry side, \|v\| grew by more than `BAKAT_TOL` |
| `sidanOm` | `true`/`false`: the plane was crossed **outside** the width during the attempt (even when `utfall` later becomes `passage`) |
| `inSida` | `"fram"`/`"bak"`/nil: the entry side (the same sign as `riktning`) |
| `evidensGrund` | why the evidence is incomplete: `"ofullstandigt"` when the validity ≠ `fullstandig`, and otherwise nil |

- `STOPP_FART` (0.3 studs/s) and `BAKAT_TOL` (1.0 stud) are **calibration assumptions for candidate evidence**, not a rule.
- **`utfall`, `riktning`, `nedslag` and everything else are unchanged.**

**First allowed verdict layer: the course-aware consumer (D2, not built now).** Only it knows "ska hoppas" and the expected direction. The mapping the consumer is expected to use later, which must never live in `HinderObservation`, applies **only** to the next course fence with `inSida` in the course direction:

| The observation for the next fence | Verdict (the consumer) |
|---|---|
| incomplete | unknown |
| `stoppObserverat` and `bakatEfterStopp` | refusal (3.1) |
| `sidanOm` | run-out (4.1) |
| a stop and then `passage` without moving back | unknown (3.1 vs 3.5) |
| `passage` with no stop | no disobedience |
| `ingen_passage` (with or without a stop, without moving back) | unknown |

A stop alone never counts. The thresholds do not create a verdict on their own before calibration in Studio.

**R1 acceptance (`hinderolydnad.spec`):**
1. The same movement patterns as before give **only neutral evidence**, with the values in the table above.
2. **No field named `olydnad`/`olydnadGrund` exists, and no value `vagran`/`utbrytning` appears anywhere in the snapshot.**
3. `utfall` is unchanged.
4. **Falsification:** reintroducing an `olydnad` verdict makes the tests red. So does removing the speed requirement, the back tolerance, the "before any crossing" condition, or the `sidanOm` evidence.
5. The full suite is green, the identity re-locked, then `HANDOFF_READY_FOR_CHATGPT`. **No change to D2 and no rosette.**

