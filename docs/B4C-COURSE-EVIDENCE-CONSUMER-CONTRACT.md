# B4c: course-aware consumer skeleton — a shadow judgment of the clear round, never official

Status: contract written before code, 2026-09-28.
Order: [CHATGPT_REVIEW_B4B_R1_ACCEPTED](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5869766684). Base `1a85e2f`.
**No change to the official D2 result, no rosette, no persistence.** Physical test last.

## Candidate comparison

| | **B4c consumer skeleton** | **D4 prize/trophy persistence** |
|---|---|---|
| Modules | `HinderObservation` (B4a `nedslag`, B4b evidence) and `ClearRoundLektion` (the course, `nrBas`, the course pointer, `geo.hinder[i].riktning`); a new pure module `ClearRoundUnderlag.luau` | `Sparning`/`SparService` (the save file, schema, `registreraPass`-style idempotency), `Klassprofil` (the rosette), plus a new prize model and a trophy-cabinet UI |
| Product decision | **No.** The verdict table is already in the B4b R1 contract (TR 385); the result is never shown and never official | **Yes:** which prizes exist (only a clear-round rosette? colour?), what the cabinet looks like, where it is shown, and whether a "training course" can give a prize at all (UBRF's real prize practice is a `[REFERENCE GAP]`) |
| Persistence | none | **yes**: a new schema version and migration |
| Source-testable now | fully, as a pure function plus the real lesson in the bench | the data model yes; UX and real awarding no |
| Needs Studio | calibration (the thresholds) and physical poles, before the shadow can **ever** become official | DataStore in a real place, the UI |

**Recommendation: B4c.** It is the smallest, needs no Tobias decision, and adds no persistence. D4 waits for a product decision. **There is no smaller prerequisite:** D2's course pointer already exists and is reused as it is.

## What is built

**A new server module `ClearRoundUnderlag.luau` (pure: no instances, no time, no network):**
`ClearRoundUnderlag.bygg(banHinder, forsok, nrBas)` → a frozen `underlag`.
- `banHinder` = the course in order, `{ id, riktning }`, from D2's `geo.hinder`.
- `forsok` = the ride's attempts from `HinderObservation.ogonblick`.
- `nrBas` = the attempt numbers at the start line.

**The walk (the same as D2's):** the attempts after the start line, **closed**, in `tUt` order. The pointer is on the next course fence. An attempt on **that** fence is judged by the table below. A `passage` in the course direction moves the pointer forward, carrying that attempt's `nedslag`.

**The verdict table** (from the B4b R1 contract), **only** for attempts on the next fence:

| Evidence | Verdict |
|---|---|
| `evidensGrund = ofullstandigt` | `okand` |
| `inSida ≠` the course direction (approached from the wrong side) | `okand`, reason `fel_sida` |
| `stoppObserverat` and `bakatEfterStopp` | `vagran` (3.1) |
| `sidanOm` | `utbrytning` (4.1) |
| `passage` after `stoppObserverat` without moving back | `okand` (3.1 vs 3.5) |
| `passage` with no stop | `ingen` |
| `ingen_passage` (without moving back) | `okand` |

**Knockdown per course step:** the `nedslag` of the passing attempt. **`vantar` counts as `okand`**, since the window may still be open when the lesson reads it.

**The output:**

```
{ version = 1, officiell = false,
  steg = { { nr, hinderId, passerad = bool, nedslag = "ja|nej|okand"|nil,
             handelser = { { forsokNr, dom = "vagran|utbrytning|ingen|okand", grund } } } },
  summa = { olydnader = n, olydnaderOkanda = n, nedslag = n, nedslagOkanda = n,
            fullstandigt = bool } }
```

- `fullstandigt` = every step is passed, with no `okand` event and no `okand` knockdown.
- **`officiell` is always `false`**: the constant `OFFICIELL = false` until physics and calibration are verified and there is a new decision.

**`ClearRoundLektion`:**
- when the result is set (`avsluta`, and at a ride end), `s.underlag = ClearRoundUnderlag.bygg(...)` is built;
- it is readable through `ClearRoundLektion.underlag(s)`;
- **it is not in the snapshot or the result**, and the client never sees it;
- **the official fields are unchanged:** `olydnader` (still `sidan_om`), `nedslag = "bedoms_inte"`, `bedomning = "forenklad"`, no rosette.

## Acceptance

**`clearroundunderlag.spec`** (pure, synthetic attempt lists):
1. **A clean course, with non-physical poles:** 4 steps passed, knockdowns `okand`, 0 disobediences, `fullstandigt = false`, `officiell = false`.
2. **With physical `nej` on every step and no stop:** `fullstandigt = true`, **`officiell` still `false`**.
3. **Evidence on the next fence:**
   - stop plus back gives `vagran`;
   - `sidanOm` gives `utbrytning`;
   - a stop then a passage gives `okand`;
   - `ingen_passage` gives `okand`;
   - an incomplete attempt gives `okand`;
   - the wrong side gives `okand`/`fel_sida`.
4. **An attempt on another fence** gives no event.
5. `vantar` gives `okand`; `ja` is counted.
6. **Attempts before the start line** (`nr ≤ nrBas`) and still-open attempts are ignored.

**`clearroundlektion.spec`:**
1. After a full course, `underlag` exists (4 steps, `officiell = false`).
2. The **official result is unchanged**.
3. **No `underlag` in the snapshot.**
4. A run-out on the course gives an `utbrytning` event on step 1.

**Falsification:**
- `officiell` becomes true;
- `vantar` counts as `nej`;
- a stop alone gives `vagran`;
- an attempt on the wrong fence is judged;
- `underlag` leaks into the snapshot.

**Full suite; re-lock.**

**Not tested:** everything physical (the thresholds, falling poles). The shadow judgment cannot become official before that.
