# Web ↔ Roblox parity audit (2026-09-28)

Order: OWNER DIRECTIVE #264 [5872806726](https://github.com/Carneteg/UBRF/issues/264#issuecomment-5872806726) and NEXT TASK [5872897649](https://github.com/Carneteg/UBRF/issues/264#issuecomment-5872897649). **Roblox is the source of truth. Where they disagree, the web changes.**
Base `61e4ae7`. Audit written before code. It replaces `docs/UI1-WEB-START-CHOICE-CONTRACT.md` (superseded).
Status: audit + delta. **No production code has been changed.**

## Summary
The web today is **a different, older product**:
- **Onboarding:** a menu → walk to the instructor → the assignment screen → the saddle room with tack matching → the box menu (rug / mucking / feeding) → the care canvas with a greeting quiz → an evaluation table of 13 rows → lead out → mount.
- **Localization:** the web has **no** Rida nu start choice, **no** Ugneta strip, **no** aftercare, and **no** lesson menu. `tSpr` is **never called**; the whole interface is hard-coded Swedish.

Roblox:
- **Onboarding:** "Gå till {horse}" with a gold ▼ → **Välj hur du börjar** (Rida nu / Gör i ordning själv) → a step card per phase (greet, check, groom, hooves, fetch saddle/bridle from the box front, saddle, bridle, lead) → Sitt upp → lesson menu at Ugneta → aftercare → "Passet är klart".

This is **not a UI patch**. It means rebuilding the web's stable and riding flow on the shared rules (`src/spel/skotsel.js`, `src/spel/sprak.js`, `src/riding/svar.js`), with the web's own rendering.

## Parity delta (P = priority order for implementation)

| # | Area | Roblox (truth) | Web today | Change on the web |
|---|---|---|---|---|
| **P1** | Start / first ride | First session: the server prepares the horse physically and puts the player **mounted in the arena** (`ForstaRitten.luau`) | Menu → "Rid nu" = only walking into the yard (`world.js:1062`) | The first session starts mounted in the arena with a prepared horse |
| **P1** | Horse assignment | Automatic (Jack on the first day, otherwise rotation, `Stallet.luau:199`). No assignment screen | Talk to the instructor → `visaTilldelning` (`scenes.js:74`) with stats, "Fråga om en annan häst" | The horse is assigned automatically by the same rule; the assignment screen leaves the flow |
| **P1** | Horse guidance | Gold "DIN HÄST / {name} / ▼" above the horse, hidden within 12 studs; cards "Öppna stalldörren" / "Gå till {horse}" | Waypoint `#ubrfVagvisare` + the "Uppgift" box at top-left (`uppdrag.js`) | Same marker and texts; **the old left box goes** |
| **P1** | Action panel | Näromrade panel at bottom-left (300px, dark): header, instruction, ≤4 choices, ≤3 rows, "Fler", feedback | Overlay modals + `#moment` at top-left + `Tryck E — …` | A new web panel with the same hierarchy and the same keys (`guide.*`, `hud.*`) |
| **P1** | Start choice | Exactly "Rida nu — {horse}" / "Gör i ordning {horse} själv" | None | As in Roblox |
| **P1** | Rida nu | Stable prep through the real moves, own tack pair, horse + player **at the arena**; day form 0.7 + 0.06 × own share | None | As in Roblox (the shared `START.DAGSFORM`, the same 0.06) |
| **P1** | Manual preparation | Phases `halsa` → `visitera` (5 points) → `rykta` (tool order) → `iordning` (hooves, fetch saddle/bridle **from the box front**, `utr:1-5`) → `leda`, from `skotsel.js` | Box menu + care canvas (4 steps, drag interaction), saddle room with 8+8 tack items, evaluation table | The step card per phase from the same `skotsel.js` tables; tack at the box front |
| **P1** | Welfare finding | "Du hittade något" + 3 answers; the right one → **the instructor takes over, no ride** | The finding only gives +0.05 / a risk; **the horse is ridden anyway** | As in Roblox (the welfare stop) |
| **P2** | Ugneta strip | Top-right: "Ugneta · Ridinstruktör", `Text` (Kommentarer / Text efter övningen), flag + "Svenska"/"English" | Ugneta card only in lessons, a live chip at top-centre | The same strip; **a language choice on the web** (today only `navigator.language`) |
| **P2** | Localization | Everything through `Sprak` | Hard-coded Swedish everywhere, `beskEn` mixed in (`scenes.js:164`) | Everything in the parity flow goes through `tSpr`; the language gate covers the web's views |
| **P3** | Riding panel | Header "{häst} · Trav · …", key lines `[W/↑]` `[S/↓]` `[A/D]` `[E]`, touch DRIV / BROMS / SITT AV | HUD with Gångart / Utbildningsskalan / Hjälper boxes, a controls panel on the left, touch VY/LÄTTR/… | The same panel and key lines. **Input is platform-specific** (the web has its four aids; see the platform differences below) |
| **P3** | Lesson menu | At Ugneta: "Träna volt", "Gångarter och fart", "Ridvägar" (+ Clear round training), "Tillbaka", free training | No choice: `byggLektion` runs a fixed series by group | The same menu and lessons (the shared lesson rules must be ported: the largest single item) |
| **P3** | After an attempt | Prova igen / Se ritten / Gå vidare (+ Nästa övning) | Same buttons (`replayvy.js`) | Texts through `tSpr` |
| **P4** | After the ride | "Efter ritten" summary → aftercare "Ta hand om henne" (5 moves in order) → "Passet är klart och sparat"; a second ride the same day is refused | `visaResultat` with the score, promotion x/2, "Rid igen — ny häst" | As in Roblox (`EFTERVARD` already exists in `skotsel.js`) |

## Web features Roblox does not have — **Tobias decides**
Character creator, mucking out, feeding schedule, rug, saddle-room tack matching, hose-down stall and mud, whiteboard, theory room, club room and rosette wall, competitions (Påskhoppet, Dressyr LC), forest trail and outdoor arena, the group ladder with promotion, skills, horse memory and rehab, weather, training book, cloud sync.

"Do not leave older web flows in place" versus `CLAUDE.md` ("the pause is not permission to delete, wind down or degrade the web"). **TOBIAS DECISION 2026-09-28: "Keep them visible".** The Roblox flow is the web's **main path** (onboarding, the step card, Rida nu, lesson, aftercare). The extras are **kept visible as side activities**. They must never stand in the way of, or replace, a step in the main path: for example, mucking out is not a requirement before saddling, and the saddle room is not the way to get the tack. There is no flag and nothing is deleted.

## True platform differences (cannot be identical)
- **Input:** Roblox uses ProximityPrompts with a hold; the web uses E/click and touch buttons. The hierarchy and texts are the same.
- **Riding input:** the web uses the four aids and `src/riding/svar.js`, Roblox uses `RidKanon`. They are the same canon, exported; the input adapter differs.
- **3D:** Roblox is 3D; the web has a 2D top view + `varld3d.js`. Environment fidelity is Replit's area and outside this pass.
- **Save:** the Roblox DataStore versus the web's localStorage. The same save shape where the pass is counted.

## Not yet in Roblox either (UI-2 / UI-3)
- **Ugneta's instruction box above the action box**, and **guidance instead of the greeting quiz**, are ordered (#264 5872220574) but **not built in Roblox**.
- The web should mirror *current* Roblox; UI-2 is then built **on both at once**, on the same panel structure.

## Size and order
- **P1** is the full stable flow on the web: a new panel, a new flow controller, Rida nu, the welfare stop, and the first ride. It touches `scenes.js`, `sysslor.js`, `world.js`, `uppdrag.js`, `game.js` and `index.html`, and breaks the tests that drive `bGroom` / `bSkots` / `bKlar` / `bLek` (`forstadagentest`, `uppdragstest`, `p0-qa-runner`, `gardtest`). Those tests will be rewritten for the new flow, not deleted.
- **P2 → P4** follow.
- Each P is its own commit series with focused tests, falsification and `tools/build.py`, delivered as `HANDOFF_READY_FOR_CHATGPT` per P.
- **Vercel:** listing deployments on project `ubrf` gives 403. Claude cannot see which SHA is live. **Tobias deploys.**
