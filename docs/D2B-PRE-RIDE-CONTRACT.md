# D2b: before the ride — entry, start list, course plan card (clear round, UBRF training)

Status: contract written before code, 2026-09-28. **BUILT, LOCAL SUITE GREEN, NOT PHYSICALLY VERIFIED** — READY_FOR_CHATGPT_REVIEW.
Decision: [TOBIAS_DECISION_D2B_1A_2A_3C_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5866670184)
(1a solo start list · 2a course plan card · 3c no warm-up), after
[CHATGPT_D2B_SOURCE_CORRECTION_WARMUP](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5866662019).
Base `71bd614`, branch `codex/circle-lesson-20260926`. Build now, physical test last.

## State flow (server-authoritative, inside the existing `clearround` lesson)

| From | Op | To | Guard | Server records (snapshot) |
|---|---|---|---|---|
| `ready` / `closed` | **`anmal`** (new) | **`startlista`** | mounted in the arena (`p.iBana`), both course fences registered, no active attempt | `anmalan = {startnummer = 1, anmalda = 1, klass = "clearround_traning", hojdM = 0.68, hastId}`; the course geometry (`referens`: fences with order, colour and direction, start and finish lines) |
| `startlista` | **`ga_banan`** (new) | **`banskiss`** | — | — |
| `banskiss` | `start` (the start signal) | `to_start` | as today (place, course); **`start` is refused in every other state** | today's `Forsok.starta`; from here D2a is unchanged |
| `complete` (with a restart allowed) | `retry` | `to_start` | as today | attempt 2; the entry stays |
| `startlista` / `banskiss` | `finish` | `closed` | — | the entry is withdrawn; **no attempt was ever opened** |

**Other details:**
- The pre-ride states have **no timers** and no observation guards. Nothing is judged before the start signal.
- The **start list is solo:** start number 1, 1 entered. There are **no invented riders or results** (1a).
- **No warm-up (3c).** UBRF's real warm-up (the indoor arena and "Lilla utebanan", then the competition arena) is not mapped to the game's areas while `references/site/BANIDENTITET.md` is unresolved. Nothing claims a warm-up took place.
- The notice about the previous aborted ride (D2a R2) is cleared when a **new entry** is made, and also on start.
- The op whitelist in `HorseService.voltLektionsBegaran` gets `anmal` and `ga_banan`. The other lesson modules already answer `unknown` to unknown ops.

## Client (presentation only; decides nothing)

- **Buttons:**
  - `ready`/`closed`: **"Anmäl dig"**;
  - `startlista`: **"Gå banan"**;
  - `banskiss`: **"Starta ritten"**;
  - Finish always.
- **Start list text:** "Anmäld: Clear round (UBRF-träning), 0,68 m. Startlista: startnummer 1 · 1 anmäld."
- **Course plan card**, built from the server's `referens.hinder`: "Banskiss (förenkling – i verkligheten går man banan till fots): 1 blått mot C · 2 rött mot C · 3 blått mot A · 4 rött mot C. Startlinjen före hinder 1, mållinjen efter hinder 4." The guide's start and finish lines are shown from the course plan state onwards.
- All texts in SV and EN.

## Persistence

**Session-only**, on the lesson object and in the snapshot. No entry, start list or result is written. Persistent results, the prize cabinet, prize-giving and the real clear-round rosette stay **blocked on B4/D4**. Aftercare is a later slice.

## Acceptance (`clearroundlektion.spec`, the real HorseService, arena and client)

1. `anmal` from `ready` gives `startlista` with `anmalan` (number 1, 1 entered, height, horse) and the course geometry. **No attempt** is opened (`RidForsok.aktivt == nil`).
2. `anmal` outside the arena gives `place`, and nothing is recorded.
3. `start` in `ready`, `startlista` or `closed` is **refused**. In `banskiss` it gives `to_start`.
4. `ga_banan` gives `banskiss`. The snapshot carries the fences in course order, with direction and colour, and the lines.
5. `finish` in `startlista` or `banskiss` gives `closed`, no attempt, and the entry is gone.
6. `retry` after faults goes straight to `to_start` without a new entry.
7. The whole flow runs `anmal → ga_banan → start →` the course `→` the result, and D2a is unchanged. The D2a cases use the entry flow.
8. **Client:** the buttons per state; the start list text; the course plan card lists 1–4 with colour and direction, and says "förenkling"; SV/EN.
9. **Falsification:**
   - start allowed before the course plan;
   - an attempt opened at entry;
   - the entry surviving finish;
   - the course plan card direction taken from the client instead of the server;
   - the start list showing more than 1 entered.

**Full suite once; re-lock the identity.**

**Not tested:** Studio, runtime, touch, and the readability of the card on a phone.
