# Instructor text controls (C2, amount of commentary and text detail)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [INSTRUCTOR_TEXT_CONTROLS_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5856670133),
base 58dd56a. Build now, test last. Claude writes; Codex reviews source;
Tobias playtests the whole at the end.

This is the written-commentary part of C2 (`docs/LEVERANSMATRIS.md`, #266).
It has no voice, recording, TTS, audio asset or volume control; the
no-teacher-voice decision in `docs/G02-C-UGNETA.md` stands. C2 stays partial.

## Where commentary comes from (read in source)

- **Optional live comments.** `LektionController` asks `UgnetaTema.steg` for
  a cue. That function owns the theme choice, the pattern rules, the
  canonical cooldown (`LIVE_CD`) and "never the same word twice".
  - A non-empty cue goes to `UgnetaController.live`, the ONLY call site.
  - `live` shows the chip.
  - The chip's text is mirrored in the teacher surface (`lararMeddelande`)
    and in the panel's feedback field (`UgnetaController.panel`); both read
    the visible chip.
- **Mandatory text.** None of it passes through `live`:
  - safety takeover (`sakerhetTarOver`);
  - lesson tasks and choices (the banner, `visa`, `efterForsok`,
    `efterritt`);
  - lesson pending, error and recovery text, and Retry/Finish/Back;
  - care questions and equipment guidance (`PreparationController`);
  - the ride row (`ridrad`).
- **End-of-exercise text.** `LektionsAterkoppling.text`, for the ten mounted
  types and the leading lesson. It is read by the two lesson panels on every
  poll.

## Preferences and exactly what they affect

| Preference | Value | Effect | Never affected |
|---|---|---|---|
| Live comments | **Normal** (default) | Every cue that reaches `live` is shown, as before. | — |
| | **Fewer** | Of the cues that reach `live`, the 1st, 3rd, 5th … are shown and the 2nd, 4th … are dropped. That is ⌈n/2⌉ of n. The counter restarts only when the COMMENT preference changes; a detail change does not touch it (R1). | evidence, theme choice, cooldown, "never twice", lesson timing, attempts, results, progression |
| | **None** | No optional live comment is shown. A chip already visible is hidden immediately, together with its mirrored teacher and panel text. | safety, tasks and choices, pending/error/recovery, care, equipment, results, Retry/Finish/Back/free actions, the ride row |
| End-of-exercise text | **Detailed** (default) | Today's summary: the supported facts plus one next step. | — |
| | **Concise** | The same validated frozen evidence, identity and context checks. A short status line without numbers, plus the same next step. Canter keeps "the lead was not judged". The ground pole keeps "hoof distance is not measured". Timeout says "Time ran out" plus the retry hint, without the percentage. "No details" and the leading stale-context text are identical in both modes. | validation, attempt binding, the leading context epoch, Retry/Finish/Back |

- **Dropped cues are not queued.** `live` returns without touching the
  chip. Switching back to Normal replays nothing; only a fresh cue that
  `UgnetaTema` produces later is shown.
- **Redraw on change.** A preference or language change redraws in place:
  - the teacher surface is redrawn;
  - the host panel is redrawn through `vard`;
  - the completion text is recomputed from the current snapshot.

  Nothing is dismissed, no attempt starts, no result is revived, progress
  is not reset and nothing asks for a new acknowledgement.
- **Concise is written wording**, never a truncation of the detailed text.

## Player flow

1. The teacher surface (top right, visible while the panel hosts it) has a
   compact **Text** button in its header, next to the language flag. The
   flag is unchanged.
   - Pointing at or selecting the button shows a one-line hint, the same
     pattern as the flag.
   - R1: the hint line belongs to the control that showed it (`tipsKalla`).
     Redraws, settings changes and language changes rewrite that control's
     text. Leaving a control hides the line only while that control still
     owns it.
2. Pressing it opens an inline settings area inside the same surface, under
   the message. It is not another HUD and not a panel row; the panel's four
   rows and its capacity are untouched. The area has two groups of native
   buttons:
   - "Comments while riding": Normal / Fewer / None;
   - "Text after the exercise": Detailed / Concise.

   The selected option is filled gold. Every button is at least 44 px tall
   and `Selectable` for gamepad and keyboard.
3. Choosing applies at once and redraws. **Done**, or the Text button
   again, closes the area. The lesson carries on where it was.

## Lifetime

- **Where it lives.** The preference sits in client memory (the
  `LararInstallning` module) for this player's session. It survives:
  - a GUI rebuild (the ScreenGui has `ResetOnSpawn = false`);
  - respawn;
  - a lesson or horse change.
- **What it holds.** Only the two choices; no result identity.
- **Not persisted.** No DataStore write, attribute or server call, so there
  is no cross-login persistence. That remains separate catalogue scope.
- **Listeners.** The module's change subscription is held as one disconnect
  function in `UgnetaController`, which disconnects before reconnecting in
  the same way as the language subscription. A repeated build therefore
  never accumulates listeners.

## Deferred verification (written, NOT run)

`roblox/tests/klient-lararinstallning.spec.luau` (KLIENT) contains:
- live cues at each setting through the real `UgnetaController.live` → chip →
  `_larare().text` → `panel().text` path;
- Fewer shows ⌈n/2⌉ of n;
- None hides a visible chip together with its mirrors;
- a dropped cue never reappears after switching back to Normal;
- safety takeover and banner/choices under None;
- a completion summary in the helper in both modes and both languages, for
  all eleven types, with the canter and ground-pole limitations kept;
- concise timeout;
- "no details" and stale context unchanged;
- the settings area opens and closes from the header button, the flag
  stays, and the selected state is visible;
- no duplicate listeners after a second `start`.

Additions to existing specs:
- `haltlektion.spec`: the real `VoltLektionController.panel` redrawn in
  concise mode and after Retry;
- `ledlektion.spec`: the real `LedLektionController.panel` in concise mode,
  and the stale-context text in both modes.

R1 additions, written, NOT run:
- `klient-lararinstallning.spec`:
  - the real Text/flag MouseEnter/Leave and SelectionGained/Lost events,
    with repeated redraws, a settings change and SV/EN;
  - the real `LektionController` path (start, acknowledge, steg with weak
    and good riding alternating), counted in the teacher surface and the
    host at Normal / Fewer / None;
  - the "Fewer" counter is not reset by a detail change.
- `klient-uikontext.spec`: a real care question (through
  `PreparationController.tillampa`) with 0..3 legacy controls. The panel
  rows are identical with the settings open and closed, there are at most
  four, and the question options are kept.

Planned, not written:
- a GUI rebuild after a real ScreenGui loss (a repeated `start` is not proof
  of rebuild) and a real respawn;
- panel-level chains for the other nine mounted types;
- rendered layout, physical touch and runtime.
