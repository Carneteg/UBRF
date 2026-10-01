# SIMPLIFY #273 — audit + acceptance contract (care guidance and riding controls)

Status: **audit and contract, written before code**, 2026-10-01. Writer: Claude.
Order: #273 (Tobias' binding decision) and its `START AUTHORIZED` comment (2026-09-30T19:13Z).
Base: `1281bd9` (P3 delivery on `codex/circle-lesson-20260926`; P3 is still awaiting ChatGPT review). Branch: `claude/simplify-273`.
Rule: **FUN FIRST · RIDE FIRST · LEARN NATURALLY**. Safety and welfare are never simplified away.

**Evidence level.** Everything in §1–§3 is read from source at `1281bd9`, with file references. **Nothing was run** — not Studio, not the web build. Where a statement depends on runtime behaviour it is marked `[NOT RUN]`. No production code has changed.

Classification used throughout: **KEEP CORE** · **CONTEXTUAL** · **OPTIONAL/ADVANCED** · **REMOVE FROM MAIN FLOW**.

---

## 1. Headline findings

| # | Finding | Platform | Why it matters for #273 |
|---|---|---|---|
| H1 | The **full control list opens by itself at the first mount**: 9 rows on a Roblox keyboard (incl. rein, half-halt, seat, jump), 12 rows on web (plus rising trot, diagonal, whip, view). | both | "Spelet ska inte visa många samtidiga keybinds." This is the screen that does it. `init.client.luau:506` → `KontrollHjalp.vidUppsittning`; `src/tavling.js:130` → `kontrollHjalpVidUppsittning`. `[NOT RUN]` on Roblox: `MINIMAL_UI` only sets the initial `Enabled`; `visa()` sets it true (`KontrollHjalp.luau:562-567`). |
| H2 | **Web cannot slow down with one control.** `S` alone never requests a lower gait; a down-cue needs rein (`Space`), half-halt (`F`) or deep seat (`Ctrl`) (`src/model.js:416-421`). The core row says so: «Bromsa — mindre skänkel, mer tygel  [S / ↓ + Mellanslag]». | web | "Minska fart / stanna" must be one of four things the player needs to understand. Roblox already has it: `S` / BROMS = one step down (`Input.luau:249-251`). |
| H3 | **Web touch shows 8 buttons plus the stick while riding**: VY, LÄTTR., DIAG, SITT AV, LÄTT, DJUP, HALVHALT, TYGEL (`src/mobil.js:102-116`). Roblox touch shows stick + DRIV, BROMS, SITT AV. | web | Touch must follow the same simple model, not a more complicated one. |
| H4 | **The advanced aids penalise a player who never uses them.** Balance drops in a turn without outside-rein support and without a deeper seat (`BALANS_YTTER`, `BALANS_VIKT`, `src/riding/svar.js:78,102`), and low balance makes the horse fall in — the arc becomes tighter than asked (`MovementController.luau:645-657`, `Svar.infall`). On Roblox touch there is no control for either aid. | both | An advanced aid that is not shown must not be silently required. Size of the effect is **not measured** — see U2. |
| H5 | The **manual care path is 23 panel clicks on Roblox (≈27 inputs on web) before leading**, and 19 of the 23 change nothing but a tick after the player has read a sentence. All hoof / mouth-corner / girth detail sits here. | both | These are exactly the "information box" instructions Tobias named. |
| H6 | **«Rida nu» is already clean**: 3 guide cards (go to horse → choose → mount), no care text. A brand-new player (First Ride) meets zero care instructions. | both | The Ride First path needs no change. The problem is the manual path and what comes after the ride. |
| H7 | **Aftercare on Roblox is five click-to-acknowledge steps on every path**, and the session is not counted until all five are done (`Pass.farAvsluta`, `Pass.luau:272-287`). Three of the five do nothing physical. **Web has no aftercare at all** (deferred to "P4"), yet a clear-round line promises it (`src/spel/sprak.js:691`). | both, drifted | Mandatory manual execution after the ride conflicts with "manuellt utförande är frivilligt"; and the two platforms differ. Needs a Tobias decision (T1). |
| H8 | **Web still reaches the old care system from the result screen.** «Samma häst igen» opens the legacy minigame overlay (`src/scenes.js:614-628`), which has the densest hoof and mouth-corner text and **punishes skipping** (risks, verdict table, next-day injury — `src/model.js:795-821`, `src/ryttare.js:237-245`). «Rid igen — ny häst» leads to the legacy assignment overlay with stale texts. | web | Contradicts "bonus, inte barriär" and is the second pass of every web player. |
| H9 | Lesson texts do not require any advanced aid by name. The lessons can be ridden with steer / faster / slower. | both | No lesson rewrite is needed for the control simplification. |

Stale texts found on the way (web): menu «Du styr inte hästen. Du styr fyra hjälper — skänkel, tygel, sits och styrning» (`src/scenes.js:25-26`); «…rädd för spö… Låt bli F-tangenten» (`src/scenes.js:151`) although `F` is now the half-halt and `G` the whip; `src/intro.js:44,53` lists `E` = half-halt and `F` = whip (legacy path, competition day only).

---

## 2. Audit A — care instructions

Both platforms read the same canon (`src/spel/skotsel.js`, exported to `roblox/game/UBRFSkotsel.luau`) and the same language table, so texts are identical unless noted. Surface on both: the left panel / step card with Ugneta's box, a heading, up to four buttons. Nothing is modal; "blocks" below means the server will not advance until that button is clicked.

### 2.1 Before the ride

| Step | Text the player reads (sv) | Player action today | Consequence | Class | Proposed |
|---|---|---|---|---|---|
| Horse marker «DIN HÄST · {namn}» | — | none | — | **KEEP CORE** | unchanged |
| «Öppna stalldörren» / «Gå till {namn}» · «Följ den gyllene pilen till boxen.» | one line | walk | 12-stud / 2,4 m reach gate | **KEEP CORE** | unchanged |
| «Välj hur du börjar» — «Rida nu — {namn}» / «Gör i ordning {namn} själv» | one sentence | one click | the path | **KEEP CORE** — the one meaningful choice | unchanged |
| Hälsa, 3 steps: «Gå fram från sidan vid bogen…», «Säg hennes namn…», «Lägg nu handen lugnt på hennes hals.» | 3 bodies + 3 confirmations | 3 clicks, fixed order, no wrong option | none (tick only) | **REMOVE FROM MAIN FLOW** as three reads | one action «Hälsa på {namn}» |
| Visitera, 5 points: «Ögon och nos», **«Mungiporna»**, «Sadelläget», «Gjordläget», «Benen» — body is the all-fine result («Mungiporna är hela.» …) | 5 bodies | 5 clicks, no decision | none unless a finding exists | **REMOVE FROM MAIN FLOW** as five reads | one action «Kolla {namn}»; result is «Allt ser bra ut» or the finding |
| **Finding** «Du hittade något» + one of five sentences; answers «Säg till ridläraren» / «Det går nog bra idag» / «Lös det själv och sadla» | one sentence | must answer; wrong answers are refused | welfare stop, horse rests (Roblox 2 sessions) | **KEEP CORE** — welfare, a real decision, both paths | unchanged, incl. in «Rida nu» |
| Rykta, 6 steps (tool — zone): «Cirklar på musklerna. Inte på ben eller huvud.» etc. | 3 distinct bodies | 6 clicks, tool order enforced | none | **REMOVE FROM MAIN FLOW** as six reads | one action «Rykta {namn}» |
| **Kratsa hovarna**, 4 steps: «Stå vänd bakåt. Stryk ner längs benet och be om foten.», «Håll handen på höften hela vägen ner.», «Gå runt framför henne…», «Sista hoven. Leta efter sten…» | 4 bodies | 4 clicks; no stone is ever found | none | **REMOVE FROM MAIN FLOW** as four reads | one action «Kratsa hovarna» |
| «Hämta sadeln» / «Hämta tränset» at the box front | one line each | real world action (prompt) | wrong horse's tack is refused with a reason | **KEEP CORE** — an action in the world, something can be discovered | unchanged |
| Utrustning 1–2: pad, saddle | «Lägg underlägget högt på manken…», «Lägg sadeln för långt fram. Skjut den bakåt, bakom bogbladet.» | 2 clicks; each builds a physical part | mount gate reads the physical tack | **KEEP CORE** as an action, **REMOVE** the two reads | one action «Sadla {namn}» (the hold-F prompt already does pad + saddle in one press, `GameplayService.sadla`) |
| Utrustning 3–4: «Lyft upp underlägget i bommen. Manken ska vara fri.», **«Dra gjorden i tre tag, med paus emellan.»** | 2 bodies | 2 clicks, nothing physical (`TackService.luau:56-61`) | none | **REMOVE FROM MAIN FLOW** | folded into «Sadla» |
| Utrustning 5: **«Träns på sist. Tummen i mungipan — vänta tills hon öppnar.»** | 1 body | 1 click, builds bridle | mount gate | **KEEP CORE** as an action, **REMOVE** the read | one action «Tränsa {namn}» |
| «Led {namn} till ridhuset» | one line | hold prompt, walk | physical arrival ticks the phase | **KEEP CORE** | unchanged |
| «Sitt upp på {namn}» | one line | hold prompt | full mount gate | **KEEP CORE** | unchanged |

Where the removed sentences go: **OPTIONAL/ADVANCED** — the existing «Hjälp» list in the panel and the web training book, one short line per phase, read only by the player who opens it. No sentence is rewritten: a text is either shown as today or moved; the game does not start teaching a different handling.

Count for the manual path, before leading: Roblox 23 panel clicks + 2 fetches → **6 actions + 2 fetches** (hälsa, kolla, rykta, kratsa, sadla, tränsa). Web the same.

### 2.2 After the ride

| Step | Today | Class | Proposed |
|---|---|---|---|
| Roblox post-ride summary «Efter ritten» + «Klar» | 1–3 lines, one click | **CONTEXTUAL** | unchanged |
| Roblox aftercare ×5: «Lossa gjorden…», «Ta av sadel och underlägg. Känn efter ömma fläckar.», «Grimma på först, sedan tränset av.», «Känn igenom benen nu…», «Ge hö och rent vatten…» | 5 clicks in strict order, required for the session to count; only saddle-off and bridle-off are physical; no headcollar object exists | **KEEP CORE** for untacking (physical truth), **REMOVE FROM MAIN FLOW** for the three acknowledge-only reads | **Needs Tobias — T1** |
| Web aftercare | does not exist; result overlay follows the dismount | — | follows T1, same outcome as Roblox |
| Web «Samma häst igen» → legacy minigame overlay | hoof/mouth-corner hints, penalties, verdict table, injuries | **REMOVE FROM MAIN FLOW** | route to the step-card flow at the box (same choice card as the first time) |
| Web «Rid igen — ny häst» → legacy assignment overlay | stat row, quirk notes naming mechanics that only exist in the legacy minigame | **REMOVE FROM MAIN FLOW** | assign and go to the step-card flow; keep the horse's real description |

### 2.3 Hard gates — all stay, unchanged, on both paths

Welfare stop and open finding; finding cannot be waved through; mount gate (right horse, no stop, checklist complete or done by the stable, **physical** tack on the model); reach gate for every care action; phase order; tack must be fetched and must be the right horse's; tack order (pad → saddle → bridle; saddle off before bridle); no tacking a led or ridden horse; leading and physical arrival; injured horse never assigned. Sources: `Preparation.luau:594-605,756-796`, `GameplayService.luau:271-288,332-339,390-393,1508-1599`, `TackService.luau:122-126,221-247,369-371`, `src/forberedelse.js:128-203`, `src/tavling.js:89-101`.

There is no helmet gate and no girth-tightness state on either platform; none is added.

### 2.4 Quiz and memorisation

Main flow: none except the finding (kept). Order knowledge is enforced by the server but the step on turn is highlighted; after §2.1 it disappears inside the phase action. Optional side activities on web (theory room, feeding, tack room pick) are untouched and stay optional.

---

## 3. Audit B — riding controls in the first ride

### 3.1 What is shown

| Surface | Roblox | Web | Class | Proposed |
|---|---|---|---|---|
| Core rows in the riding panel | 4: one step up `W/↑`, one step down `S/↓`, steer `A/D`, mount/dismount `E` (`KontrollHjalp.RIDKARNA`) | 4: «Driv på — skänkel» `W/↑`, «Bromsa — mindre skänkel, mer tygel» `S/↓ + Mellanslag`, steer, mount/dismount (`KONTROLL_KARNA`) | **KEEP CORE** | Roblox unchanged; web rows 1–2 say the same two things as Roblox with one key each (after B2) |
| Full list auto-opened at first mount | 9 rows keyboard, 6 touch | 12 rows keyboard, 11 touch | **REMOVE FROM MAIN FLOW** | never opens by itself; stays behind `H` / `?` |
| Full list behind `H` / `?` | all bound controls | all bound controls + four aid meters | **OPTIONAL/ADVANCED** | core first, the rest under a heading «Avancerat» |
| Ugneta's ride line («Börja i skritt. Tryck på {reglage} en gång.», «Be om trav…») | names the player's own control, one at a time | same | **KEEP CORE** | unchanged |
| Touch while riding | stick + DRIV, BROMS, SITT AV | stick + VY, LÄTTR., DIAG, SITT AV, LÄTT, DJUP, HALVHALT, TYGEL | Roblox **KEEP CORE**; web six aid buttons **OPTIONAL/ADVANCED** | web: stick + DRIV, BROMS, SITT AV (+ the small VY) — see T3 |

### 3.2 What is bound, and what it does

| Control | Roblox | Web | Needed for a first ride? | Class |
|---|---|---|---|---|
| Steer | `A/D`, left stick, stick | `A/D`, stick | yes | **KEEP CORE** |
| Faster | `W/↑` (`Shift`), `R1`, DRIV — one step up per press | `W/↑`, stick forward — a new leg impulse steps up | yes | **KEEP CORE** |
| Slower / stop | `S/↓` (`Ctrl`), `L1`, BROMS — one step down | **no single control** (H2) | yes | **KEEP CORE** — web must get it (B2) |
| Mount / dismount | `E`, D-pad down, SITT AV | `E`, SITT AV | yes | **KEEP CORE** |
| Rein contact | `Q`, `R2`, no touch | `Space`, TYGEL | no; feeds balance and contact | **OPTIONAL/ADVANCED** |
| Half-halt | `F`, `B`, no touch — also one step down | `F`, HALVHALT — also one step down | no; duplicates "slower" | **OPTIONAL/ADVANCED** |
| Seat light / deep | `Z/C`, `L2`, no touch | `Shift/Ctrl`, LÄTT / DJUP | no | **OPTIONAL/ADVANCED** |
| Rising / sitting trot, diagonal | automatic («lättridning (assisterad)») | `R`, `Q`, LÄTTR., DIAG; defaults are already the unpenalised ones (`src/game.js:49`, `src/model.js:682`) | no | **OPTIONAL/ADVANCED** |
| Whip | does not exist | `G` | no | **OPTIONAL/ADVANCED** |
| Jump | `Space`, `A`, no touch | automatic over a fence in the main path (`src/game.js:948-956`) | not in the first ride | **CONTEXTUAL** — see U3 |
| Lesson next / replay / view / help | `R`, `T`, `G`, `H` | panel buttons, `V`, `H`, `T`, `M` | shown as panel buttons when relevant | **CONTEXTUAL** |

No binding is deleted on keyboard or gamepad. Advanced aids keep working for the player who looks them up; they stop being shown by default and stop being silently required.

---

## 4. Acceptance contract

### 4.1 Goal
A new player reaches the horse, prepares or skips preparation, mounts and rides a first lesson understanding only **steer · faster · slower/stop · interact/dismount**, reading only instructions that lead to an action or a choice — on PC and touch, on Roblox and web, with every safety and welfare gate intact.

### 4.2 Observed state
§1 H1–H8.

### 4.3 Source of truth
Tobias' decision #273; `CLAUDE.md` (FUN FIRST · RIDE FIRST · LEARN NATURALLY, parity rule, scope guardrail, riding as release blocker); `docs/PRODUCT-CANON.md`; the care canon `src/spel/skotsel.js` and language table `src/spel/sprak.js` (shared with Roblox through the exports); Roblox as the reference where the platforms have drifted.

### 4.4 Required change — minimum implementation, three packages

**Package S1 — controls (both platforms).**
- **B1** The control list never opens by itself. `H` / `?` and the panel `?` are the only ways in. The list shows the four core rows first, the rest under «Avancerat».
- **B2** Web: `S` / `↓` requests **one gait step down per press**, through the existing half-halt channel in the input layer — no change to the riding model, no new mechanic. Core rows 1–2 on web then read like Roblox, one key each.
- **B3** Web touch: the six aid buttons leave the default riding layout; DRIV and BROMS buttons send the same two actions (T3).
- **B4** Advanced aids are not silently required: with no rein/seat input the outside-rein and seat-support terms are neutral. **Measure first** (U2); implement only if the measured effect is material, and only as an input-layer default, in the shared canon so both platforms get it.
- **B5** Web texts that contradict the model: the "fyra hjälper" menu line and the «Låt bli F-tangenten» note.

**Package S2 — care before the ride (both platforms).**
- **A1** In the manual path each phase without a decision is **one player action**: hälsa, kolla, rykta, kratsa, sadla, tränsa. The server performs the phase's existing moments in order with the player as performer — the checklist, order rule, own-share bonus, care memory and every gate keep their current data model. The inspection action stops at a finding exactly as «Rida nu» does today.
- **A2** One short line per card. The detailed sentences move to the optional help list / training book, verbatim.
- **A3** Web: «Samma häst igen» and «Rid igen — ny häst» lead to the step-card flow; the legacy minigame overlay and its penalties leave the main flow.

**Package S3 — after the ride (both platforms).** Per T1.

Order: S1 → S2 → S3. Each package is delivered on Roblox and web together with its own handoff.

### 4.5 Out of scope
No removal or weakening of any gate in §2.3. No new horse physics, no new control mechanic, no rebinding of existing keys. No change to lessons, judging, observation or scoring. No UI redesign beyond removing rows and buttons. No Jev coupling. Optional web side activities (theory room, feeding, mucking, tack room) stay as they are. Deleting the legacy web code is not part of this — it only leaves the main flow.

### 4.6 Acceptance tests
Automatic, both platforms, each with a falsification (mutation committed-copy first, restored after):
1. First mount: the control list is **not** visible; the panel shows exactly four core rows; `H` / `?` opens the full list with core first.
2. Web: from canter, three presses of `S` with no other input reach halt, one step per press; the same through the touch BROMS button; `W` still steps up.
3. Web touch riding layout contains stick, DRIV, BROMS, SITT AV (and VY) and none of TYGEL, HALVHALT, LÄTT, DJUP, LÄTTR., DIAG.
4. Manual path: six phase actions + two fetches reach "ready to lead"; the checklist state afterwards equals today's state after 23 clicks (same moments, performer = player, same own-share and day form).
5. A finding stops the inspection action, blocks every other step, refuses the two wrong answers, and stops «Rida nu» — unchanged texts.
6. Mount gate: every refusal in §2.3 still refuses with the same text (wrong horse, welfare stop, phase remaining, tack physically missing).
7. No main-flow card before the ride contains the hoof, mouth-corner or girth-stage sentences; the same sentences are present in the help list.
8. Web: «Samma häst igen» and «Rid igen — ny häst» never open `visaSkotsel` / `visaTilldelning` in the main path.
9. Language parity gate: every changed key has sv + en, and Roblox and web read the same keys.
10. Existing suites stay green on both platforms (riding parity, lesson, panel, camera, Ugneta, runtime gate).

### 4.7 Human gate
Tobias judges simplicity and game feel in a real playtest: PC, physical iPad, physical iPhone, Roblox and web. Automatic tests and source review do not mark those rows PASS. B4 changes riding feel and is not promoted without his judgment.

### 4.8 Known uncertainty
- **U1 `[NOT RUN]`** Whether the Roblox control list is actually visible at first mount in the current build (source says yes; `MINIMAL_UI` suggests the intent was no). To be confirmed in Studio before B1 is written.
- **U2 `[NOT MEASURED]`** How much a default rider (no rein, no seat) loses in balance and how far the horse falls in on a 20 m circle. B4 is conditional on this number.
- **U3 `[NOT DETERMINED]`** Whether Roblox fence lessons (ground pole, clear round) physically require the jump key. If they do, a touch player cannot complete them today; that is its own finding and would be handled as a contextual control, not in the first-ride scope.
- **U4 `[ASSUMPTION]`** B2 assumes a half-halt pulse given with `S` held is read as a down-cue at every gait; `src/model.js:382-383` says a weak half-halt still counts. To be proven by test 2 before anything else in S1.
- **U5** P3 (`1281bd9`) is not yet reviewed. If P3 review changes the web riding panel, S1 rebases on the result.

### 4.9 Needs Tobias
- **T1 — aftercare.** Recommended: after dismount one card with the same choice as before the ride — **«Stallet tar hand om henne»** (the stable untacks correctly, the session counts) or **«Ta hand om henne själv»** (two physical actions: saddle off, bridle off; then «Vatten och hö» as one action; a small positive relation effect, no penalty for the other choice). Web gets the same card, replacing the missing aftercare. Alternative: keep five mandatory steps on Roblox and add them to web. The current rule "the session does not count without manual aftercare" is the part that conflicts with the Ride First decision.
- **T2 — manual path granularity.** Recommended: A1 (one action per phase). Alternative: keep every click and only shorten the texts.
- **T3 — web touch.** Recommended: DRIV and BROMS buttons like Roblox. Alternative: stick only (forward = faster, back = slower).
- **T4 — B4.** Whether advanced aids may be neutral by default if U2 shows a material penalty.

### 4.10 Found, outside this scope
Web, read from source, not run: after a welfare stop the card offers no next action, and the manual horse swap (`visaHastbyte` → `valbaraHastar`, `src/uppdrag.js:132-139`) has no rest filter, so it appears able to select a resting horse. Reported separately.

---

`READY_FOR_CHATGPT_REVIEW` — audit and contract only. No production code changed. *(State at `aa85be0`. The implementation follows in §5.)*

---

## 5. Implementation record — S1, S2, S3 (2026-10-01)

Writer: Claude. Order: Tobias, 2026-10-01 — audit direction approved at `aa85be0`, decisions T1–T4 below, «implement the minimum change per S1, S2 and S3, Roblox and web together». Nothing merged to `main`. No new gameplay.

### 5.1 Tobias' decisions

| | Decision | Implemented as |
|---|---|---|
| **T1** aftercare | After dismount a simple choice: «Stallet tar hand om henne» → session counts, no penalty. «Ta hand om henne själv» → voluntary, small positive effect. The five mandatory click-through steps leave the main flow. Same model on both platforms. | S3 |
| **T2** manual care | One meaningful player action per phase: hälsa → kontrollera → rykta → kratsa → sadla → tränsa → leda → sitt upp. Detail texts are not mandatory stops. Real safety/welfare gates stay. Detailed horse knowledge may move to a voluntary layer. | S2 |
| **T3** web touch | Same mental model as Roblox: joystick + DRIV + BROMS + SITT AV. The six advanced buttons are not shown in the standard flow. | S1 |
| **T4** advanced aids | Neutral / default-optional in the first ride and basic riding. No hidden balance or steering penalty for not using half-halt, outside rein, deep seat, whip. May return contextually when an exercise needs them. | S1 |

### 5.2 U1–U4, checked before implementation (small targeted checks only)

| | Result | How |
|---|---|---|
| **U1** | **Confirmed.** The Roblox list did open at the first mount: `vidUppsittning()` → `visa()` sets `Enabled = true` regardless of `MINIMAL_UI`. | Source, and the client bench: `klient-hjalpknapp.spec` already closed it after mounting («Första uppsittningen visar hjälpen av sig själv»). **Not run in Studio.** |
| **U2** | **Material.** Steering only (no rein, neutral seat), full turn: balance fell to **0,49** in walk and trot and **0,42** in canter on web; **0,46** on Roblox (walk). The horse fell in: the ridden radius was about **14–15 % tighter** than asked (Roblox 2,05 m against 2,38 m). | One-off probe through the web input layer; the Roblox figure is printed by `movement.spec` with the requirement switched on. |
| **U3** | **Confirmed, not changed.** On Roblox a jump needs `intent.jump` (`Space` / `ButtonA`, `MovementController.luau:773`); there is no touch control for it. A fence lesson on a pure touch device cannot produce a jump. Outside the first-ride scope — reported, not fixed here. | Source. |
| **U4** | **Holds.** A half-halt pulse steps down one gait at every gait: canter → trot → walk → halt in three pulses. | Probe through the input layer; now `simplifytest` A. |
| *found on the way* | On web, `S` alone followed by release stepped **up**: trot, `S` for 0,6 s, release → canter. The leg returning from «none» to neutral was read as a forward impulse. | Same probe. Fixed by B2. |

### 5.3 What changed

**S1 — controls**

- *Both:* the control list never opens by itself. `KontrollHjalp.vidUppsittning` / `kontrollHjalpVidUppsittning` are removed, not disabled. The list shows the core first and the aids under a heading «Avancerat» (`KontrollHjalp.listrader`, `kontrollListrader`). The four core rows are unchanged on Roblox.
- *Web:* `S` / `↓` in the saddle is **one step down per press** through the existing half-halt channel in the input layer (`ridBroms`, `src/game.js`). The riding model is untouched. The leg is no longer pushed to «none», which removes the step-up on release. Core rows 1–2 now read «Ett steg upp / ned i gångarterna» with one control each.
- *Web touch (T3):* stick + **DRIV** + **BROMS** + **SITT AV** (+ the small VY). DRIV is a leg impulse (`ridDriv`), BROMS the same half-halt as `S`. In the saddle the stick steers and nothing else.
- *Both (T4):* `SVAR_KANON.HJALP_KRAV = 0` (exported to `RidKanon.SVAR`). `svarBalansMal` / `Svar.balansMal` take an optional `krav` that scales the outside-rein and seat-support terms; the two riding call sites pass the canon value. Without the argument the formula is exactly as before — the parity golden rows are unchanged. Speed in the turn, transitions and tension count as before.
- *Web texts (B5):* the «fyra hjälper» menu line and «Låt bli F-tangenten».

**S2 — care before the ride**

- *Both:* `Preparation.handlingar` / `Forb.handlingar` group a phase's existing moments into **one action**: `halsa`, `kolla`, `rykta`, `kratsa`, `sadla`, `transa`. Performing an action runs its moments in canon order through the **existing** moment path (`GameplayService.moment`, `Forb.utforMoment`) with the player as performer. The checklist, order rule, own-share, day-form bonus, care memory and every gate keep their data model. `leda` has no action — it is acknowledged by the horse physically arriving.
- *Roblox:* new remote `PreparationHandling` → `GameplayService.handling`. The old `PreparationMoment` path is unchanged and still used for `leda`, by «Rida nu» and by the specs.
- *Both:* one short line per card (`handling.*_text`). The detailed sentences — hooves, mouth corners, girth in three stages — are **not rewritten**: they are shown verbatim in the voluntary layer («Så gör man»; on Roblox in the panel's Hjälp list).
- A finding stops the «kolla» action at the finding, exactly as the stable's preparation does. Nothing after it is performed; the decision is the player's.
- *Web (A3):* «Samma häst igen» and «Rid igen — ny häst» go to the step card at the box. `visaSkotsel` (the legacy minigame with penalties) and `visaTilldelning` are no longer reached from the main path. A resting horse is never handed out.

**S3 — after the ride (T1)**

- *Both:* `Pass.handlingar` / `Efter.handlingar`: `sadla_av` (girth + saddle), `transa_av` (bridle), `ta_hand` (legs + water and hay). The five canon moments and their order are unchanged; `gjorda[id]` is `true` (player) or `"auto"` (stable).
- «Stallet tar hand om henne»: the stable performs what remains, the session counts once, **no penalty**. On Roblox the tack is physically removed in canon order; presence is not required, but the player must have dismounted (`pass.sitt_av_forst`) and ridden (`pass.inte_dags`).
- «Ta hand om henne själv»: three actions, one at a time, the stable remains available as a way out. Small positive effect: relation **+0,02 × own share** on top of the unchanged +0,04 (Roblox `EGEN_EFTERVARD_BONUS`, web `Efter.BONUS` on the horse's `rang`).
- *Roblox:* new remote `PassHandling` (an action id, or `"stallet"`). `PassMoment` is unchanged.

### 5.4 Gates — verified intact

Welfare stop and open finding (blocks every action, both wrong answers refused, mount refused); mount gate (`pass.aterstar` while leading remains, physical tack read from the model); reach gate for every action (`spel.for_langt`) including own aftercare; phase order and order inside the phase (`forb.fel_tur`); tack must be fetched (`tack.hamta_forst`) and be the right horse's (`tack.fel_sadel`); bridle after saddle, saddle off before bridle; leading is physical and no action can acknowledge it; a resting horse is not assigned; the session cannot be counted without a ride. Measured in `integration-forenkling.spec` B, C, E, F and `simplifytest` F; the existing suites are green.

### 5.5 Platform differences — need Tobias' explicit approval as exceptions

1. **When the session is counted.** Web counts at dismount (`avslutaBana` → `registreraPass`), before the choice; Roblox counts when the choice is made. Same player outcome on both paths: the session counts, without penalty.
2. **The stick.** On Roblox the stick also nudges tempo inside the gait's band; on web touch it only steers. Roblox BROMS from halt is rein-back; web has no rein-back.
3. **Own aftercare on web is not physical.** Roblox removes the tack from the model; web has no tack model after the ride and shows the three actions in the result overlay.
4. **Where the knowledge layer sits.** Web: a «Så gör man» toggle in the step card. Roblox: inside the panel's Hjälp list.
5. **Competition day on web touch** keeps its old button set (stick gives leg; TYGEL, HALVHALT, LÄTT, DJUP, LÄTTR., DIAG, NÄSTA). The side activity's moment series judges contact and half-halt — T4's own «contextually when an exercise needs them». The main path never shows it.
6. **Web-only advanced aids** (rising trot, diagonal, whip) remain web-only, now under «Avancerat».

### 5.6 Not changed, and why

- `rakriktning` on the web training scale still reads outside-rein support (`src/model.js`). It is a quality score, not balance or steering; whether T4 should reach it is a question for review.
- The clear-round line «…sitt av – eftervården väntar: {moment}» still names the five canon moments. They still exist; they are now a choice.
- Legacy web code (`visaSkotsel`, `visaTilldelning`) is not deleted (contract §4.5). The ride teacher still opens `visaTilldelning` on competition day.
- #274 (rest filter in the manual horse swap; no way on after a welfare stop on web) is untouched.

### 5.7 Tests

New, on both platforms:

- `roblox/tests/integration-forenkling.spec.luau` — S2 and S3 through `GameplayService` against the real rig. Six actions give a checklist **identical** to the 23 moment calls (same moments, same performer, own share 1,0, day form 0,76).
- `roblox/tests/klient-forenkling.spec.luau` — S1 (first mount through `MountChanged`, list closed; core/advanced order; touch), S2 (one row per phase, short line, knowledge layer), S3 (the choice; own path; stable as way out).
- `tools/simplifytest.mjs` — S1 keyboard and touch, T4, S3 both paths, A3, S2 chain and the finding. In CI (`grindar.yml`, job `ridning`) and in the G8 inventory.
- `tools/falsifiera-forenkling.py` — 19 mutations (10 web, 9 Roblox).

Changed to follow the new contract, none removed: `forberedelse.spec`, `varldshud.spec`, `klient-uikontext.spec`, `klient-guide.spec`, `klient-blandning.spec`, `movement.spec`; `ridpaneltest`, `ridtest`, `sprakblandningtest`, `stegkorttest`, `ugneta-ui-test`, `p0-qa-runner`. The two mechanics T4 switches off by default (outside rein carries the turn; the seat is a balance modifier) are still measured, with the requirement switched on in the test.

Falsification found two redundant lines of my own, and both were resolved rather than counted away: a second copy of the aftercare order rule in `eftervardHandling` (removed — `Pass.farUtfora` owns it; the missing «already done» refusal was added and is now measured), and a test that could not tell «the check stopped at the finding» from «the rule refused the next moment» (sharpened).

### 5.8 Not tested

- **Roblox Studio runtime.** Nothing on this branch has run in the engine. Studio is connected, but Rojo serves another working tree. Bench specs only.
- **Game feel and simplicity** — Tobias' gate (§4.7): PC, physical iPad, physical iPhone, Roblox and web. B4 changes riding feel and is not promoted without his judgment.
- Gamepad on either platform beyond what the bench measures.
- English was checked by the language gates, not read by a person.

`READY_FOR_CHATGPT_REVIEW` — S1, S2, S3 implemented on Roblox and web.
