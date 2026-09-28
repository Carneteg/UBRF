# B4a: the knockdown event on the server — truthful "unknown" today, real events once the poles are physical

Status: contract written before code, 2026-09-28.
Order: [CHATGPT_REVIEW_D5_R1_ACCEPTED](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5868811989) and
[CHATGPT_B4_EXECUTE_NOW](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5868851094). Base `dab83b2`.
**No change to D2 judging, no rosette, no physical evidence.** Physical test last.

## 1. What can be observed deterministically today (source/bench)

These come from `HinderObservation` (verified in the code):
- per attempt:
  - the outcome: `passage` / `sidan_om` / `ingen_passage`, and the validity;
  - the direction;
  - the air phase and landing (from `FloorMaterial`);
  - `overlapp`: the root box against the pole box, **geometric only**;
  - `bom = ligger|flyttad` at close;
- in the registry, each fence's registered position and the live `flyttad`.

**What cannot be observed today:**
- **Contact:** the pole has `CanCollide = false`, so `kontakt = "otillganglig"`.
- **A knockdown:** a pole that is anchored and non-colliding cannot fall. `rivning` is always `false`.
- **The legs/hooves:** the server has only the root box, and `HastGang` drives the legs procedurally on the client.

**So overlap is not a knockdown.** It is still not a basis for judging in B4a.

## 2. What needs real Roblox physics/Studio

These are Replit's environment, `roblox/buildings/Anlaggningen.luau`, and **not touched here**:
- poles that can fall (unanchored, `CanCollide = true`, resting in cups);
- whether a horse's (client-owned) contact actually moves the pole;
- how the pole's position replicates to the server;
- calibrating the threshold and time window below;
- touch/feel.

## 3. The server-side representation (built in B4a)

**Per attempt in `HinderObservation`, new fields** (frozen in `ogonblick`, private fields as today):

| Field | Values |
|---|---|
| `nedslag` | `"ja"` \| `"nej"` \| `"okand"` \| `"vantar"` (only while the window is open) |
| `nedslagGrund` | `"bom_foll"` · `"bom_ligger"` · `"bom_ej_fysisk"` · `"bom_ej_uppsatt"` · `"hinder_saknas"` · `"ej_fullstandigt"` · `"ritten_slut"` |
| `tNedslag` | ride time when the fall was observed, or nil |

**The rules (fail closed):**
1. **A physical pole** is `Anchored == false` **and** `CanCollide == true`, read **when the attempt starts**. Everything else gives `okand`/`bom_ej_fysisk`, **never "nej"**. That is every pole today.
2. **Set up:** when the attempt starts, the pole top is within `NEDSLAG_FALL` of the **registered** position. Otherwise `okand`/`bom_ej_uppsatt` (the fence was already down).
3. **A fall:** the pole top has dropped more than `NEDSLAG_FALL` (the pole thickness, `[antagande]`, calibrated in Studio) since the attempt started, **while the attempt is open, or within `NEDSLAG_FONSTER` (2.0 s of ride time, `[antagande]`) after it closed**. That gives `ja`/`bom_foll`, with `tNedslag`.
4. **When a fully observed attempt on a physical pole closes without a fall:** `vantar`. It becomes `nej`/`bom_ligger` **only once the window has passed**, judged against the ride's later segments. A fall inside the window gives `ja`.
5. **Validity:**
   - `brott`, `hinder_ogiltigt` or `hinder_borttaget` gives `okand`/`ej_fullstandigt`;
   - a ride end while `vantar` gives `okand`/`ritten_slut`;
   - a missing pole part gives `okand`/`hinder_saknas`.
6. **A pole that falls without an attempt on the fence is attributed to nothing.**

**Registry:** `HinderObservation.register()` gets `fysisk = true|false` per fence, so a future consumer can see whether the course can be judged.

**Unchanged:**
- `rivning` (still `false`), `overlapp`, `bom`, `kontakt`;
- all existing outcomes;
- `ClearRoundLektion` and its `nedslag = "bedoms_inte"`, `bedomning = "forenklad"`, and no rosette.

## 4. Refusals/run-outs: not in B4a

- `sidan_om` (run-out) and `ingen_passage` (the zone left without crossing) are observed today. D2a counts only `sidan_om` as a disobedience; `ingen_passage` is not judged.
- **TR's definitions of a refusal and a circle** (the olydnad moments before 381) are **not in** `references/rules/TR-III-2025-hoppning-A-clear-round.md`. That is a `[REFERENCE GAP]`.
- The next refusal slice starts by adding that excerpt from the source. After that, a stop or turn before the fence can be classified from the existing segments (position and time) without inventing a signal. **Nothing about refusals is built in B4a.**

## 5. Who consumes the event later (not built now)

- **D1 `Klassprofil.clearRound(runda)`:** `runda.nedslag` = the number of this round's course attempts with `nedslag == "ja"`. 4 faults each (TR 381).
- **D2 `ClearRoundLektion` result:**
  - `nedslag`: an integer **only when** every course attempt in the round has `nedslag ∈ {ja, nej}`, and otherwise `"bedoms_inte"` as today;
  - `bedomning`: `"forenklad"` becomes `"fullstandig"` only then;
  - `felfri`/`rosett`: via the D1 profile, only for attempt 1 and only when fully judged.
- **D3/D4:** protocol and prize persistence build on the same.

## Acceptance (`hindernedslag.spec`, the same bench as `hinderobservation.spec`)

1. **Today's poles** (anchored or non-colliding): every attempt gives `okand`/`bom_ej_fysisk`, and **never "nej"**. `register()` has `fysisk = false`.
2. **A physical pole left standing:** `vantar` at close, `nej`/`bom_ligger` once the window has passed, and `fysisk = true`.
3. **A physical pole that falls during the attempt:** `ja`/`bom_foll` with `tNedslag`.
4. **Falls after close:** inside the window gives `ja`; after the window, the verdict stays `nej` and is attributed to nothing.
5. **A pole already down at the start** gives `okand`/`bom_ej_uppsatt`.
6. **Other validity:** a break or ride end while the window is open gives `okand`. A pole moved **less** than the threshold gives no `ja`.
7. **Two fences:** a fall on one is never attributed to the other.
8. **Existing fields unchanged:** `hinderobservation.spec`, `clearroundlektion.spec` and all of D2 are unchanged and green.
9. **Falsification:**
   - a non-physical pole gives "nej";
   - no window (judged at close);
   - the threshold is ignored;
   - the already-down baseline is ignored;
   - a ride end while `vantar` gives "nej".

**Full suite; re-lock.** `HinderObservation` is a mapped source.

**Not tested:**
- physical poles;
- real contact;
- replication;
- the calibration of `NEDSLAG_FALL`/`NEDSLAG_FONSTER`.

All of this is Studio, PHYSICAL TEST LAST, and poles that can fall need coordination with Replit.
