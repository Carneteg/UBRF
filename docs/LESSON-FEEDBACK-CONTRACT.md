# End-of-exercise feedback (C1 concrete advice)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [LESSON_FEEDBACK_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856514742),
base c13add1. Build now, test last. Claude writes; Codex reviews source;
Tobias playtests the whole at the end.

This is the concrete-advice part of C1. It covers one shared end-of-exercise
feedback flow for the ten mounted lesson types and the on-foot leading lesson.
It adds no new measurement, no score, no persistent skill memory, no rewards,
no comparison ("improved"/"mastered") and no audio.

## What each lesson already freezes (read in source; the only facts used)

| Type | Frozen result fields used | Wording |
|---|---|---|
| `volt` | `avsnitt.varv`, `avsnitt.referens.radie`, `avsnitt.medelAvvikelse`, `avsnitt.tid` | circles, radius, mean distance from the line, seconds |
| `halt` | `skrittMeter`, `haltSekunder` | walked metres, seconds standing at X |
| `overgang` | `travMeter`, `skrittMeter` | trot metres between T1 and T2, calm walk after |
| `serpentin` | `meter`, `#korsningar` | metres of route, centre-line crossings |
| `tempo` | `meter`, `sekunder`, `medelFart`, `spridning` | metres, seconds, mean m/s, spread % ("steady speed", never rhythm) |
| `vag_mitt` / `vag_diag` | `figur`, `meter`, `langd` | metres of the line |
| `halvvolt` | `meter`, `#skarvar`, `skuld` | credited metres; uncredited halt drift said honestly |
| `galopp` | `travMeter`, `galoppMeter`, `galoppsida = "ej_bedomd"` | trot before, canter after; the lead is NOT judged |
| `markbom` | `inridningM`, `utridningM`, `passage = "rotplan"` | walk in and out; hoof distance is NOT measured |
| `leda` | `meter`, `sekunder` | metres and seconds led |

## Behaviour

- **Complete.** The panel's text becomes ONE short positive summary built only
  from that attempt's frozen result, plus ONE next practice step for that
  exercise. It is shown only when the result belongs to the displayed attempt:
  - mounted lessons: `resultat.forsokId == bild.forsokId`,
    `resultat.rittId == bild.rittId == current ride`, and the type matches;
  - leading: `resultat.forsokNr == bild.forsokNr` and the same user.

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

**Planned, not written:**
- the full server → snapshot → panel chain for each type (the per-type lesson
  specs already produce real results; one end-to-end check per type is
  planned);
- rendered layout and touch.
