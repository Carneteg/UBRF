# End-of-exercise feedback (C1 concrete advice)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
R1 ([LESSON_FEEDBACK_SOURCE_R1](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856590077)):
leading context binding, strict evidence validation, panel-level cases.
Order: [LESSON_FEEDBACK_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856514742),
base c13add1. Build now, test last. Claude writes; Codex reviews source;
Tobias playtests the whole at the end.

This is the concrete-advice part of C1. It covers one shared end-of-exercise
feedback flow for the ten mounted lesson types and the on-foot leading lesson.
It adds no new measurement, no score, no persistent skill memory, no rewards,
no comparison ("improved"/"mastered") and no audio.

## What each lesson already freezes (read in source; the only facts used)

R1: every field is validated BEFORE any arithmetic or formatting. "Finite"
means a number that is not NaN or ±inf; metres and seconds must also be
≥ 0. A missing, wrong-typed or non-finite field is NOT an observed zero, so
the text becomes the honest "no details". Identity must equal the producer's
constant.

| Type | Identity (must equal) | Required evidence | Valid zero | Wording |
|---|---|---|---|---|
| `volt` | — (the snapshot type is nil) | `avsnitt.varv` integer ≥ 1, `avsnitt.referens.radie` > 0, `avsnitt.medelAvvikelse` ≥ 0, `avsnitt.tid` ≥ 0 | — | circles, radius (m), mean distance from the line (m), seconds |
| `halt` | `mal = "X"` | `skrittMeter`, `haltSekunder` | — | walked metres, seconds standing at X |
| `overgang` | `mal = "T1->T2"` | `travMeter`, `skrittMeter` | — | trot metres, calm walk after |
| `serpentin` | `rutt = "serpentin-3"` | `meter`; `korsningar` is a table | empty list = 0 crossings | metres, crossings |
| `tempo` | `ovning = "jamn_skritt"`, `enhet = "m/s"` | `meter`, `sekunder`; `medelFart` > 0; `spridning` ≥ 0 | spread 0 | "steady walk", m/s, spread % — never rhythm |
| `vag_mitt` / `vag_diag` | `figur` = the selected type | `meter`; `langd` > 0 | — | metres of the line |
| `halvvolt` | `figur = "halvvolt"` | `meter`; `skarvar` is a table; `skuld` finite | 0 joins, 0 debt | credited metres; debt > 0.05 m said honestly |
| `galopp` | `ovning = "galoppfattning"`, `galoppsida = "ej_bedomd"` | `travMeter`, `galoppMeter` | — | the lead is NOT judged |
| `markbom` | `ovning = "markbom"`, `passage = "rotplan"` | `inridningM`, `utridningM` | — | hoof distance is NOT measured |
| `leda` | see the binding below | `meter`, `sekunder` | — | metres and seconds led |

Timeout uses the server's `progress` only when it is finite (clamped to
0–99); otherwise it shows 0.

## Behaviour

- **Complete.** The panel's text becomes ONE short positive summary built only
  from that attempt's frozen result, plus ONE next practice step for that
  exercise. It is shown only when the result belongs to the displayed attempt:
  - mounted lessons: `resultat.forsokId == bild.forsokId`,
    `resultat.rittId == bild.rittId == current ride`, and the type matches;
  - leading: `resultat.forsokNr == bild.forsokNr`, the same user, AND (R1)
    `resultat.kontextNr == bild.kontextNr`.
    - `kontextNr` is an additive field that `LedLektion` freezes at
      completion.
    - The producer advances the snapshot's `kontextNr` whenever the bound
      MODEL instance or the Character changes, including while the lesson is
      in `complete`. This covers:
      - another horse;
      - a replacement with the same HorseId;
      - a new Character.
    - When the attempt and user match but the epoch differs, the text is the
      neutral `aterkoppling.leda.annan`: "that exercise was done with another
      horse or before a character change; lead again with the horse you have
      now". The frozen result itself is kept unchanged.

  If the result is missing, invalid or mismatched, the text is an honest "the
  exercise is complete, but I have no details to show". Nothing is invented.
- **Timeout.** The existing neutral timeout text, the server's own progress
  percentage, and ONE concrete retry hint for the exercise. There is no
  congratulation, no borrowed earlier result and no invented reason.
- **Closed.** The existing text only. An old result is never shown.
- **Controls and lifetime.**
  - The existing Retry, Finish and Back controls and free riding are unchanged.
  - The text stays until the player acts; there is no timer, no modal and no
    acknowledgement step.
  - Advice never starts a lesson or awards anything.
- **Rendering.** The text is computed on every panel poll from the current
  snapshot and the current locale, and is never stored. Duplicate syncs,
  redraws and locale switches therefore cannot duplicate a summary or keep an
  old one. The existing snapshot guards still decide which snapshot is
  current: mounted snapshots by type and revision, leading snapshots by
  attempt and revision. Retry clears `resultat` server-side, so a new attempt
  never shows the previous one.
- **Implementation.** One small client helper, `LektionsAterkoppling`,
  formats all eleven types, so there is no duplicated wording logic. It adds
  no framework.

## Deferred verification (written, NOT run)

`roblox/tests/lektionsaterkoppling.spec.luau` calls the helper with results
shaped by each producer (field names taken from the producers above).

**Complete, for every type:**
- a matching result gives a summary containing its facts and a next step;
- galopp says the lead is not judged, and markbom says hoof distance is not
  measured.

**Mismatch:**
- a mismatched attempt, ride or type, or a missing result, gives the honest
  "no details" text.

**Timeout and closed:**
- timeout gives the neutral text, the server progress and a retry hint, with
  no summary;
- closed gives no summary.

**Locale:**
- switching the locale changes the words, not the facts.

**R1, helper level** (`lektionsaterkoppling.spec`):
- missing, malformed, non-finite and wrong-identity inputs for each type, run
  under `pcall` (nothing may throw);
- the valid zeros listed in the table above;
- the leading context epoch.

**R1, panel level** (real producer → sync → `panel()`), written, NOT run:
- `haltlektion.spec`, through the actual `VoltLektionController.panel` call
  site and Ugneta's composed page:
  - current completion;
  - the composed page with 0 and with 3 legacy card buttons, within
    capacity 4 and with Retry kept;
  - duplicate snapshot and locale redraw;
  - Retry;
  - timeout after a success;
  - a delayed older snapshot after the timeout;
  - closed after a success;
  - another ride.
- `ledlektion.spec`, through the actual `LedLektionController.panel` call
  site and the real sync path:
  - unchanged context;
  - A → B;
  - a delayed older snapshot;
  - returning to A (a new epoch);
  - same-HorseId replacement;
  - Character replacement;
  - Retry in the current context;
  - Back.

**Planned, not written:**
- panel-level chains for the other nine mounted types (ten mounted types minus the halt example). They share the call
  site and the formatter, and their producers already have per-type specs.
- rendered layout, text length on touch.
