# P3: riding panel + lesson menu — the web rides like Roblox

Status: contract written before code, 2026-09-30. Writer: Claude.
Order: #266 [5882885526](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5882885526) § 3, [5882981472](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5882981472) § 3, Tobias 2026-09-30 (P3 on base `a483a79`). ACK [5903721298](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5903721298).
Audit: `docs/WEB-ROBLOX-PARITY-AUDIT.md`, P3 rows. QA: Kimi Q4 and Q6 ([5874805658](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5874805658)).
Base: `a483a793712308ffa0a1640381864c0538f396c7` (P2 + UI-2 + UI-3, production).

**Roblox is the source of truth.** Its current riding UI, lesson menu, lessons and after-attempt choices are the product. This package changes the **web** to match. Roblox changes only where a shared source changes (language catalogue, exports), plus the gates that prove parity. Rendering and input stay platform-specific; hierarchy, texts, rules, thresholds and outcomes are shared.

## 0. What Roblox does today (read before this contract)

| Area | Roblox source | What the player gets |
|---|---|---|
| Riding panel | `Naromrade.luau` riding branch (1973–2060), `KontrollHjalp.ridrader` | One panel, bottom-left, top to bottom: **Ugneta · Ridinstruktör** box (title, **Text**, language flag, one message) → header `{häst}  ·  {gångart}  ·  {sits/galopp}` + `?` → the four core key lines → ≤ 4 choice buttons. `?` expands all control rows. |
| Ugneta while riding | `UgnetaController.lararMeddelande` (1303–1340), `UgnetaRad.steg` | ONE message by priority: lesson live chip → coach banner text → the lesson's current task → ride line outside a lesson (praise or «be om trav med …» naming the player's own control). |
| Text setting | `LararInstallning.luau`, `UgnetaController` 410–530 | *Kommentarer under ritten*: Normalt / Färre / Inga. *Text efter övningen*: Detaljerad / Kort. Session only. Inga blocks optional comments; Färre drops every second; required text never hidden. Kort swaps the end text to the `.kort` variant (never for clear round). |
| First controls | `KontrollHjalp.vidUppsittning` | The full control list opens once per session at the first mount; H closes/opens it. |
| Lesson menu | `VoltLektionController.panel` (926–1010) | Top: **Träna volt · Gångarter och fart · Ridvägar · Förslag/Öva igen**. Sub-pages: Gångarter → Träna start och halt, Rid i jämn fart, Övergångar (→ Träna övergångar, Galoppfattning). Ridvägar → Böjda vägar (Serpentin, Halvvolt, Genom hörnet), Raka linjer och markbom (Mittlinjen, Diagonalen, Bom på marken), Clear round (träning). Every sub-page has **Tillbaka**. After a finished lesson the top adds **Fri träning med återspelning**. Nothing is unlock-gated. Lesson memory adds « · klarad», « · förslag». |
| Lessons | `server/*Lektion.luau` + `RidForsok`, `RidPlatsObservation`, `RidObservation`, `RidLogg` | 12: volt, halt, tempo, overgang, galopp, serpentin, vag_mitt, vag_diag, halvvolt, hornet, markbom, clearround. Intro → Start (on the dressage arena) → live tips + progress → complete / timeout → feedback text (`LektionsAterkoppling`). |
| After a lesson attempt | VLC 1125–1180 | **Prova igen** (clear round: **Omstart** only if allowed), **Avsluta {lektionen}**, and after the lesson is done once: **Rid utan streck / Mindre stöd** ↔ **Visa vägen** (vag, hornet, halvvolt, markbom). |
| Free practice pass | `HorseCore/Lektion.luau`, `LektionController.luau` | Runs from the mount unless a lesson is chosen: the six Ugneta exercises in canon order, 22 s rounds, two attempts each. After a round: **Prova igen** (attempt 1) / **Nästa övning** (attempt 2), **Se ritten** (only if recorded), **Gå vidare** (after attempt 1). A card never freezes the horse; an aid answers it. Only the replay pauses the ride. |
| Dismount | `E` / `SITT AV` | Ends the ride. What follows (summary, aftercare, «Passet är klart») is **P4**. |

The web today has none of the menu, none of the 12 lessons, no Text setting, a four-corner HUD (Gångart / Utbildningsskalan / Hjälper / Moment) and an automatic moment series (`byggLektion`) the player cannot choose.

## 1. Player outcome on the web (the acceptance target)

1. **Mounted, the web shows one riding panel with Roblox's hierarchy** (bottom-left, dark, same visual language as the P2 on-foot card):
   1. the **Ugneta · Ridinstruktör** box on top: title, **Text** button, language flag, and exactly one message chosen by Roblox's priority;
   2. the header `{häst}  ·  {gångart}  ·  {lättridning / galopp side}` with a `?` button;
   3. **four core key lines** (see § 3), then `?` expands the full list;
   4. ≤ 4 choice buttons: the lesson menu, the lesson's own buttons, or the free pass's buttons, exactly as Roblox composes them.
2. The old corner HUD leaves the main riding path: `#moment`, `#gait`, `#pyr` (Utbildningsskalan) and `#aids` (Hjälper) are hidden while riding in the main path. **The four aid meters stay reachable** under `?` because the web's input *is* the four aids (§ 3). The training scale stays in the training book. Nothing is deleted; competitions (a side activity) keep their own HUD.
3. **Choosing, riding and repeating a lesson works as in Roblox**: the same menu tree, labels, suggestion, markings, intro, Start, place check, live tips, progress, completion/timeout, feedback text, Prova igen / Avsluta / less-guidance toggle, and the lesson memory.
4. **The free pass works as in Roblox**: it starts at mount under the menu, 22 s rounds, two attempts, Prova igen / Nästa övning / Se ritten / Gå vidare; choosing a lesson hides it; after a finished lesson «Fri träning med återspelning» restarts it.
5. **Text / comment level exists on the web** with the same two settings and effects (closes the P2 platform note: Text arrives with P3).
6. **Language**: every visible string in the riding panel, menu, lessons, feedback, replay and controls help goes through `tSpr`. Swedish selected → no English; English selected → no Swedish. The P2 flag also sits in the riding panel's Ugneta box.
7. **First controls (Q6)**: at the first mount of the session the full controls list opens by itself, localized; the four core lines are always visible in the panel; H toggles the list.
8. **Camera (Q4)**: after any teleport (Rida nu, First Ride, a door), a mount, or closing any panel/modal, the view is the 3D view the player had chosen — never a top-down view the player did not ask for (§ 7).
9. **Q5 unchanged**: the horse marker still points straight at the horse.
10. **Dismount** (`E`, touch `SITT AV`) ends the ride and hands over to the existing end-of-ride path (P4 replaces it; § 9).

## 2. Riding panel (web) — `src/ridpanel.js` (new), `src/ui.css`, `index.html`

- **One DOM component `#ridpanel`**, bottom-left, the same width rule as `#stegkort` (≤ 34 % width, iPad landscape 1180×820 and 1366×768 must fit), growing upward, never under the touch stick.
- **Block order is Naromrade's LayoutOrder**: 0 Ugneta box → 1 header row + `?` → 2 body (core lines; `?` adds the full list and the aid meters) → 3 choice buttons.
- **Ugneta box**: shares the P2 component (`.skU` in `stegkort.js`) — factored out so that on foot and mounted use one implementation: title `ugneta.titel`, Text `installning.knapp`, flag `sprak.nuvarande`. The settings sheet (§ 5) opens inside the box.
- **Message priority (port of `lararMeddelande`)**: (1) lesson live chip / greeting / tempo coaching → (2) coach line → (3) the running lesson's task text (`<typ>.<tips>` + progress %) → (4) the ride line outside a lesson (`UgnetaRad` port: `ugneta.rad.*`, with the player's own control in `%s`). One message only.
- **Header**: `rubrikFor` port — `gangart.{halt,walk,trot,canter,gallop}`, `gangart.byte` during a transition, `sits.lattridning` in rising trot, `galopp.vanster/hoger` in canter; fallback `hud.du_rider`. Separator `"  ·  "`.
- **Choice buttons**: `UgnetaController.panel(MAX_VAL=4)` port — the free-pass card buttons first, then lesson choices; if they do not fit, the compact «Välj övning» entry (`lektionsval.oppna`) → page `topp`. A page marked `ersatt` replaces the card buttons.
- The P2 on-foot card (`#stegkort`) is not shown while mounted (unchanged: `stegkortKort` returns null in the lesson scene).

## 3. Controls: the key lines (web input is platform-specific)

The web rides with the four aids (`src/riding/hjalper.js`, `svar.js`); Roblox steps gaits with W/S. That difference is the audit's declared **true platform difference** and stays. What must match is the *hierarchy* (four core lines, `?` for the rest) and that every line names a real binding on the player's current input — never a Roblox key the web does not have.

| # | Roblox core line | Web core line (keyboard) | Web touch |
|---|---|---|---|
| 1 | `hjalp.hogre_gangart` [W / ↑] | `hjalp.webb.driv` «Driv på — skänkel» [W / ↑] | stick forward |
| 2 | `hjalp.lagre_gangart` [S / ↓] | `hjalp.webb.bromsa` «Bromsa — skänkel bak och tygel» [S / ↓ + Mellanslag] | stick back + TYGEL |
| 3 | `hjalp.styr` [A / D] | `hjalp.styr` [A / D] | stick |
| 4 | `hjalp.sitt_upp_av` [E] | `hjalp.sitt_upp_av` [E] | `touch.sitt_av` SITT AV |

(Final Swedish/English wording is set in the catalogue in the implementation commit, verified against what `svar.js` actually does with S and the rein; the table fixes the structure, not the prose.)

**Binding changes on the web, in the saddle only** (on foot nothing changes):
- `E` = **sitt av** (Roblox: E = dismount). Today web `E` in the saddle is the half-halt.
- `F` = **halvhalt** (Roblox: F = half-halt). Today web `F` is the whip.
- `G` = **spö** (web-only aid; Roblox has none). Listed under `?` only.
- `↑` / `↓` added as aliases for W / S (Roblox binds both).
- Touch: a **SITT AV** button is added to the riding touch set (`touch.sitt_av`); the existing web aid buttons stay (they are the web's input), relabelled through `tSpr`.

No riding physics, aid semantics or thresholds change; only which key feeds which existing channel. Tests that drive `E` as the half-halt in the saddle are updated to `F`, not deleted.

`?` (label `panel.hjalp`) expands the full list — port of `KontrollHjalp.rader` for the web's own bindings (tygel, halvhalt, sits lätt/djup, lättridning R, diagonal Q, spö G, vy V, hjälp H), plus the four aid meters. Rows with no binding on the current input are dropped (Roblox rule).

## 4. Lesson menu (web) — `src/lektionsmeny.js` (new)

- **Exact port of `V.panel`**: the pages `topp`, `gangart`, `overgangar`, `vagar`, `bojda`, `linjer`; the same keys (`voltlektion.choose`, `lektionsval.*`, `<typ>.choose`, `clearround.choose`, `lektionsval.tillbaka`), the same order, the same `ersatt` rule, the same page text (`lektionsval.valj` + suggestion line).
- **Top state machine** `valt / fri` as in Roblox: before any lesson — Volt, Gångarter, Ridvägar, Förslag; after a finished lesson — Volt, Gångarter, Ridvägar, «Fri träning med återspelning».
- **Suggestion**: `MINNE_ORDNING` (halt, tempo, volt, overgang, vag_mitt, vag_diag, serpentin, halvvolt, hornet, markbom, galopp) → first not done; all done → «Öva igen: halt»; history unknown → none.
- **Markings**: « · klarad», « · klarad nu», « · förslag» on the lesson and on the groups leading to it; `lektionsminne.okand` / `vantar_info` page text.
- **Lesson memory (web)**: port of `LektionsMinne` semantics — «done at least once» per `lektion:<typ>:<VERSION>`, versions equal to Roblox's server module `VERSION` strings, clear round not saved. Stored in the web save (localStorage, the same save object as the rest of the web profile). The web cannot read the Roblox DataStore and vice versa; that is the existing declared save difference.

## 5. Text / comment level (web) — `src/lararinstallning.js` (new)

Port of `LararInstallning.luau`: `kommentarer` ∈ {normal, farre, inga}, `detalj` ∈ {detaljerad, kort}, session only (not saved, as Roblox). The same UI keys (`installning.*`). Effects exactly as Roblox:
- `valfriKommentar()`: inga → false; farre → every second call false; normal → true.
- Gates the live chip, the start greeting (`halsning.<typ>`, 6 s) and tempo coaching; choosing «Inga» hides one already showing.
- Never gates the task text, tips or progress.
- `detalj = kort` → `aterkoppling.<typ>.kort` / `aterkoppling.timeout_kort`; clear round never shortened.

## 6. The lessons (web) — `src/lektioner/` (new)

**Port of intent, rules, parameters and acceptance — not line by line** (`CLAUDE.md` platform contract).

- **Frame**: Roblox judges in the dressage frame `(u, v)` in metres, origin at A, `v` towards C, `u = (motC × up)`, i.e. positive towards the K–E–H side. The web rides in the 20 × 60 arena with A at (10, 0), C at (10, 60), K–E–H at x = 0. Mapping: **`v = y`, `u = 10 − x`**. The mapping is asserted in a test against the shared letter table (`DRESSYRBOKSTAVER`): the diagonal starts by F and ends by H on both platforms.
- **Engine** `src/lektioner/motor.js`: one lesson object per choice with Roblox's life cycle — `ready → (to_start) → active states → complete | timeout`, `revision`, `progress` (0–99), `tips`, `delmal`, `resultat`, `referens`. The web has no server; the object lives on the client, but it keeps Roblox's rules: one active attempt, a new attempt resets the measurement, a dismount mid-attempt ends it (clear round: «avbruten»).
- **Observation** `src/lektioner/observation.js`: per frame `(t, u, v, heading, speed, gait, requested gait, aid edge)` from the web ride state. «On the aid» = the frame the player's own aid changed the requested gait (the web's `ride.cue` / `cueTid`), mirroring Roblox's RidLogg gait-request events. A teleport, a pause (replay) or a dt gap breaks continuity exactly where Roblox counts `teleporter / luckor / ogiltigaDt`.
- **One module per lesson**, every constant copied from the Roblox module with the Roblox file named in a comment: `volt`, `halt`, `tempo`, `overgang`, `galopp`, `serpentin`, `vag` (mitt/diag), `halvvolt`, `hornet`, `markbom`, `clearround`. Deadlines, corridors, zones, rings, speed bands, sample minimums, advice keys (`line_ut`, `*_early/_late`, `too_slow/too_fast/steadier`, …) and the less-guidance switch as in Roblox.
- **Ground pole**: the web arena gets the pole `ridhus_hinder_rod_50` from the shared `src/site.js` (`h: 0`), which Roblox already builds. Missing pole → `fel = "pole"` as Roblox.
- **Clear round**: the course blue → C, red → C, blue → A, red → C over the shared `site.js` fences `ridhus_hinder_bla_24` / `ridhus_hinder_rod_38`; Anmäl dig → startlista → Gå banan (course sketch) → Start → start line within 45 s → course → finish line; allowed time 180 s; faults by a port of `Klassprofil.clearRound`; knockdowns not judged («inga observerade fel», never «felfri», no rosette) — identical simplification. **Clothes**: Roblox offers competition clothes (D5, avatar assets). The web avatar has no clothing assets → the web offers «Egna kläder» only. **Platform exception requested (§ 11)**; the rest of the flow is identical.
- **Guides**: the green reference lines Roblox draws from `referens` are drawn on the web in the 3D riding view and the 2D arena plan from the same `referens` numbers, hidden when less guidance is on.
- **Feedback** `src/lektioner/aterkoppling.js`: port of `LektionsAterkoppling.text` — `aterkoppling.<typ>.klar` with the frozen numbers, `.nasta`, the volt/halt «närmare» comparison with the previous run, tempo `tempocoach.*`, timeout, `okant`, clear round result keys, `kort` variants.

## 7. Kimi Q4 — camera top-down after teleport / panel close (web)

Roblox has no top-down camera path (read: `CameraController.luau` writes CameraType only in create/release). The web has one: `G.vy === "2d"`.

**Hypothesis (to reproduce at runtime before fixing):**
- **H1** — `V` toggles the view with no guard (`game.js` keydown). Typing a name with «v» in a modal (`#skapNamnFalt`, `#synkNamn`, `#synkEpost`) flips the view behind the modal; the player sees top-down when the panel closes.
- **H2** — `G.vy` survives every teleport (Rida nu, First Ride, doors, `gaTill`) and every mount, so a map opened on foot carries into the ride.
- **H3** — the near-wall walking camera lifts to a steep look-down after an indoor teleport (`varld3d.js` 2597–2605). Candidate only; `varld3d.js` belongs to another writer and is **not edited** in P3 — reported if it reproduces.

**Fix scope (only for what reproduces):** `V` and the view buttons ignore input while an overlay/modal or a text field has focus; a teleport or mount restores the 3D view unless the player chose the map *in that scene*; the view toggle's initial `on` state matches `G.vy`. Evidence: a runtime reproduction before and after (Playwright), recorded in the handoff.

## 8. Shared sources and Roblox

- **`src/spel/sprak.js`** gains the new web keys (`hjalp.webb.*` and any missing lesson/replay/controls keys). The catalogue is exported to `roblox/game/UBRFSprak.luau` (`tools/exportera-spel.js --kontrollera` green). Roblox behaviour does not change; the export stays in sync.
- **Parity gates (new)**:
  - `tools/lektionsparitet.mjs`: reads every Roblox lesson module's numeric constants (deadlines, corridors, zones, bands, minimums, figures) straight from `roblox/src/server/*Lektion.luau` and fails if the web module's value differs. Also: the menu tree, keys and `MINNE_ORDNING` against `VoltLektionController.luau`, and the `VERSION` strings against the web memory keys.
  - `tools/lektionstest.mjs`: per lesson, synthetic rides in the `(u, v)` frame mirroring the Roblox specs' pass and fail cases (e.g. a clean 20 m circle completes; a point 4.1 m off resets; halt outside 1.5 m of X is not accepted; a trot aid outside T1 gives `trot_early/late`; the diagonal starts by F).
  - `tools/ridpaneltest.mjs`: the panel hierarchy (Ugneta box on top, header, four core lines, ≤ 4 buttons), the menu pages and Tillbaka, Text effects, the dismount key, first-mount controls.
  - `tools/sprakblandningtest.mjs` (P2) extended to the riding panel, menu, lesson texts, feedback and replay on sv and en.
  - `tools/kameratest.mjs` (Q4): the reproduction as a regression.
- **Roblox regression**: `bash roblox/tests/kor.sh` green; build identity re-locked if any mapped Roblox source changes (expected: only `UBRFSprak.luau` through the export).

## 9. Boundaries (what P3 does not do)

- **After the ride is P4.** Dismount hands over to the web's existing end path. P3 only makes sure that path does not show a failing score for moments that no longer exist (no moments graded → no average row). The summary, ordered aftercare and «Passet är klart» come in P4.
- **The web-only group ladder** (`byggLektion` moment series, promotion x/2) is no longer the main riding path. It is **not deleted**: the code stays, competitions keep using their programme, and the ladder's saved state is untouched. Where (or whether) the ladder is offered as a side activity is a **Tobias decision** (§ 11); until then it is not reachable from the main riding path, per the 2026-09-28 rule that side activities never replace a main-path step.
- No riding physics, aid semantics, gait canon or thresholds in `model.js` / `svar.js` / `hjalper.js` change.
- No change to Q5, the on-foot flow (P1/P2), `src/varld3d.js`, Roblox gameplay, or production.

## 10. Acceptance

1. **Panel**: mounted on the web, the panel shows Ugneta box → header → four core lines → buttons; `?` expands the list and aid meters; iPad landscape and 1366×768 fit; nothing under the stick.
2. **Menu**: every page, label, order and Tillbaka equal Roblox (gate); suggestion and markings follow memory; «Fri träning med återspelning» appears after a finished lesson.
3. **Lessons**: all 12 selectable and completable on the web by a synthetic ride that completes the Roblox version, and failing where Roblox fails (gate); constants equal Roblox (gate).
4. **After an attempt**: Prova igen / Omstart rule / Avsluta / less-guidance toggle for lessons; Prova igen / Nästa övning / Se ritten / Gå vidare for the free pass, with Roblox's conditions.
5. **Text**: Inga silences optional comments but never the task; Kort shortens the end text except clear round.
6. **Language**: the mixed-language gate is green on sv and en for the riding panel, menu, lessons, feedback and replay, and shown red on an injected string.
7. **Controls**: first mount opens the localized controls list once per session; E dismounts, F half-halts, G is the whip; H toggles.
8. **Q4**: reproduced (or recorded as not reproducing) with the exact steps; after the fix, the teleport/panel-close sequence ends in the 3D view (regression test).
9. **Roblox**: `kor.sh` green, export in sync, identity relocked if needed.
10. **Full web suite** green: build, the CI web jobs, `MOBIL=1` where relevant, the P0 QA runner modes.

## 11. Needs Tobias (platform exceptions / decisions)

1. **Clear round clothes**: web offers «Egna kläder» only (no web avatar clothing assets). Same player outcome otherwise. **APPROVED by Tobias 2026-09-30** («P3 §11 clear-round clothes exception APPROVED. På webben används endast `Egna kläder`, eftersom webbavataren saknar Roblox-versionens tävlingsklädassets. Dokumentera detta som en uttrycklig plattformsskillnad. Övrigt clear-round-flöde ska fortsätta följa Roblox.»). Declared platform difference; recorded in `docs/WORKING-AGREEMENT.md`.
2. **Web riding input**: the four aids stay (declared audit difference). Core line 1–2 therefore say «skänkel» instead of «ett steg upp / ned i gångarterna». *Exception requested (restating the audit's difference for the new panel).* Not yet decided — the implementation follows the default in § 3.
3. **The group ladder** (web-only side activity): not reachable from the main riding path after P3. *Decision: where to offer it, if at all.* Default until decided: code and save kept, not offered. Not yet decided — the implementation follows the default (`G.stege`, never set by the main path).

## 12. Verification plan

- Focused: the new gates in § 8, `stegkorttest`, `sprakgrind`, `sprakblandningtest`, `replaytest`, `replaylayouttest`, `ugnetatest`, `ugneta-ui-test`, `ugneta-forsok-test`, `inputsemantiktest`, `forstadagentest` (+ `MOBIL=1`), `kontrollhjalp` checks.
- Full: every web test the CI jobs run, `tools/build.py`, `p0-qa-runner` (three modes), `bash roblox/tests/kor.sh`, the export checks, `bygg-identitet`.
- Falsification: each new gate shown red on an exact mutation in an isolated copy (a lesson constant, a menu label, a mixed-language string, `V` in a text field, `E` back to half-halt).
- Runtime: a Playwright ride on the built `dist/` through mount → menu → one lesson of each family → dismount, with screenshots at 1180×820 and 1366×768, sv and en.
- Studio: no Roblox gameplay changes → no engine check planned; `NOT_TESTED` with that reason unless a mapped source changes.
- Push, then Vercel Preview on the exact final SHA; production only after Tobias approves.

## 13. Implementation record (writer: Claude, 2026-09-30)

Tobias 2026-09-30: continue P3 from `36d832e`; treat the existing `src/lektioner/` WIP as code to review against Roblox before use; reproduce Q4 before any fix; no production promotion without Tobias; `src/varld3d.js` not edited.

**Review of the 14 pre-existing lesson modules** (`src/lektioner/`) against `roblox/src/server/*.luau`: every module is a faithful port — same constants, states, tips, resets and end conditions. `tools/lektionsparitet.mjs` now proves the constants, identities, menu, text keys and frame mechanically. Accepted, documented differences: (a) `LektionMotor.andra` bumps `revision` only on a real change (Roblox VoltLektion bumps unconditionally) — client redraw only; (b) clear round's end-of-ride outcome runs after the motor closes the attempt instead of checking `aktiv` first — same outcome «avbruten»; (c) `hinder.js` ports the part of HinderObservation the lessons read (passage, beside, no passage, direction, stop/back evidence); knockdown/landing are not ported because the web poles cannot fall — `nedslag` is always «okänd», exactly as Roblox's lessons treat it today.

**New web files**: `src/lektioner/aterkoppling.js` (LektionsAterkoppling), `src/lektioner/koppling.js` (the web's HorseService feed: observations per ride at the server cadence, gait events from the rider's own aid), `src/lektioner/guide.js` (the guide dashes, drawn in 3D and on the 2D plan), `src/lektionsmeny.js` (VoltLektionController), `src/fripass.js` (LektionController + HorseCore/Lektion), `src/lararinstallning.js` (LararInstallning), `src/ridpanel.js` (Naromrade's mounted branch + UgnetaRad).

**Declared platform differences** (rendering/input/storage — same player outcome):
- Clear round clothes: «Egna kläder» only on the web (§ 11.1, APPROVED).
- Web input is the four aids (§ 3, § 11.2 pending): the core lines name the aids; E = sitt av, F = halvhalt, G = spö, ↑/↓ = W/S in the saddle only. A card is answered by an aid impulse (leg forward/back past half, a half-halt, or a new gait request), like Roblox `intent.gaitUp/gaitDown/parad`.
- Lesson memory lives in the web save (`SPAR.lektionsminne`, keys `lektion:<typ>:<VERSION>`); the web save is synchronous, so the «vantar» state never occurs. Untrusted save → unknown history, no suggestion.
- No NPC riders in the main path: Roblox rides alone with Ugneta, and a rider on the track would push the player out of the lessons' corridors. NPCs stay in competitions and the ladder.
- The controls list (H) moves beside the riding panel while riding (it would otherwise cover the panel's buttons); Roblox places it left-centre. Placement only.
- Jumping over the arena's standing fences is a visual hop (`G.luft`); judging is HinderObs, as in Roblox.
- Replay: the web replay view is now localized (`replay.*`). Roblox `ReplayController` still has Swedish literals — a pre-existing Roblox language gap outside this web-parity package, reported, not changed here.

**Kimi Q4, reproduced before the fix** (one-off `tools/_q4repro.mjs` on HEAD `36d832e`, removed once the regression existed): H1 reproduced (typing «Vera» in the name field switched to the map), H2 reproduced (the map survived teleport and mount), and the view toggle started with the map marked while the view was 3D. H3 (walking camera tilt indoors, `src/varld3d.js`) did not reproduce in the chain and is untouched. Fix: keys typed in a text field are text (`tangentIText`); V and the view buttons are ignored under a panel; a move to another scene restores 3D unless the map was chosen in that scene (`vyEfterFlytt`); the toggle marks `G.vy`. Regression: `tools/kameratest.mjs`.
