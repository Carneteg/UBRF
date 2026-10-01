# P3 base candidate — review only

Status: prepared 2026-10-01 by Claude (author of P1a–P3, therefore **not** its reviewer).
Order: #273 [5928515733](https://github.com/Carneteg/UBRF/issues/273#issuecomment-5928515733), after the independent base review [5928307604](https://github.com/Carneteg/UBRF/issues/273#issuecomment-5928307604) (`BASE_CHANGES_REQUIRED`).

**This branch is a base/integration candidate for review. It is not a product delivery and is not for merge.** It contains no gameplay change and no production-code change.

## What it is

`claude/p3-base-candidate` = `codex/circle-lesson-20260926` @ `1281bd9a23e8dd31be42d4a125158d47da68ccb7` plus test-side work only:

| Change | Files | From |
|---|---|---|
| The riding-panel test waits for the panel instead of a fixed time | `tools/ridpaneltest.mjs` | `9c7e3d9` (#275), the `simplifytest` part left out |
| The Ugneta UI test states its locale (`sv-SE`) | `tools/ugneta-ui-test.mjs` | `9c7e3d9` |
| The yard test re-selects the map after a scene move | `tools/gardtest.mjs` | `8927a18` |
| The mission test re-selects the map on every leg | `tools/uppdragstest.mjs` | `5902f9a` |
| The mission-label test names the heading that wrapped (diagnostic only) | `tools/uppdragsetikett-test.mjs` | `ca7221c` |
| One lesson ridden end to end in a browser | `tools/lektion-e2e-test.mjs` (new), CI step in `grindar.yml`, registered in `tools/testa-grindar-workflow.py` | new |
| Reproducible falsification of the P3 gates | `tools/falsifiera-p3.py` (new) | new |

## What is deliberately not here

- **`7d81df2` is not applied.** It changed the mission-label gate from «a heading is never more than one line» to «a wrapped heading is a fault only if it would have fitted». The stricter rule stands. Whether a long assigned-horse heading may wrap is an open product decision (`[P1B-LANG-ETIKETT]`).
- No `simplifytest` change and nothing else from #273.
- No production file under `src/`, `roblox/src/`, `roblox/game/` or `index.html` differs from `1281bd9`.

## The end-to-end lesson test

`tools/lektion-e2e-test.mjs` rides the halt lesson («Träna start och halt») in headless Chromium against `dist/`:

real keys (`W`, `S` + `Space`, `E`) → the web ride state → `koppling.js` / `observation.js` → `lektioner/halt.js` → completion → the riding panel and the lesson memory.

- **A** — ridden to «complete»: still in halt, walk on the rider's aid, halt inside the ring at X, held 2 s. Asserts the gait log (two events, both `hjalp`), the result numbers, the feedback text in the panel, the after-attempt buttons, and the memory key in the save.
- **B** — a halt outside the ring is held for longer than the hold time: never complete, `halt_outside`, memory untouched; dismount closes the attempt without success.

After the mount the test changes no game state: it presses keys, clicks the panel's own buttons and reads. The mount itself is the same shortcut as `ridpaneltest` (`startaVandring`, session 0) and is not part of what is measured. The 120 s timeout is not ridden; it stays covered synthetically in `lektionstest.mjs`.

## Falsification

`python tools/falsifiera-p3.py` — nine mutations, each restored from memory in `finally`; the script rebuilds `dist/` and verifies the working tree is untouched.

| | Mutation | Gate that must go red |
|---|---|---|
| P1 | halt ring 1,6 m instead of Roblox 1,5 | `lektionsparitet` |
| P2 | halt `VERSION` differs from the server module | `lektionsparitet` |
| P3 | three core lines in the riding panel instead of four | `ridpaneltest` |
| P4 | `E` in the saddle no longer dismounts | `ridpaneltest` |
| P5 | a halt outside the ring counts | `lektionstest` **and** `lektion-e2e-test` |
| P6 | the rider's aid never reaches the lesson (`orsak` ≠ `hjalp`) | `lektion-e2e-test` |
| P7 | a completed lesson is not saved in the lesson memory | `lektion-e2e-test` |
| P8 | the riding panel title is a Swedish literal | `sprakblandningtest` |
| P9 | a riding text lacks English in the catalogue | `sprakgrind` |

Result on this branch: 10 of 10 gate runs red, working tree untouched.

## Observation made while writing the ride (not acted on)

After a halt made with `S` + `Space`, releasing both keys makes the horse walk on by itself within about 0,1 s: the leg input returns from −1 to 0 and the ride model reads the change as a forward impulse (`cue` becomes `framåt`). The lesson logs it as the rider's own aid. The end-to-end test therefore keeps the brake held through the hold time. Whether this is intended on the web, and whether it predates P3, is not determined here.
