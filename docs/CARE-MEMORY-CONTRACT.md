# Care memory: the player's own first completion of four care milestones

Status: BUILT_NOT_VERIFIED, 2026-09-27. This contract was written BEFORE the
production edits for this slice.
Order: [CARE_MEMORY_BUILD](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5857324396),
base ff17d40. Build now, test last. Claude writes; Codex reviews source;
Tobias plays the whole candidate at the end.

This slice remembers whether the PLAYER has, by their own hand, completed
each of four care milestones at least once, and shows that history in the
existing care surface.

It does NOT cover, and does not change:
- all care, aftercare, equipment, leading or full skill memory;
- a score, count, quality, mastery, reward, unlock or relation effect;
- any equipment penalty;
- the care bonus, first day, Pass or award semantics;
- Ride First.

## Source (read before the edits)

- **The moments come from the canon.** `Preparation.moment(fasId)` derives
  them from `UBRFSkotsel` (generated from `src/spel/skotsel.js`); this
  contract never copies the list:
  - `halsa`: three alternatives, of which two are right (`fel` marks the
    wrong one). The phase is a CHOICE: one correct choice completes it.
  - `visitera`: the visitation points, in a strict order (`vis:<id>`).
  - `rykta`: tool by zone (`rykt:<tool>:<zone>`), with the tool order as the
    step.
  - `iordning`: the four hooves (`hov:vf`, `hov:vb`, `hov:hb`, `hov:hf`),
    then the equipment (`utr:n`). The HOOF SUBSET is its own milestone.
- **Who did the work.** `Preparation.utforMoment` records the player's work
  as literal `true` and stable-assisted work as `"auto"`, and never
  downgrades an existing `true`.
  - The client remote `PreparationMoment` passes only `(fasId, momentId)`,
    so the performer is ALWAYS the player.
  - `GameplayService.ridaNu` passes `"auto"` through the same
    `GameplayService.moment`.
  - `klara`, `fasKlar`, `ready_to_mount`, `egenAndel` and a pass receipt
    are therefore NOT proof that the player did a milestone.
- **Welfare.** A finding on the visitation blocks work until it is
  reported. The right report stops the work (`stoppad`). `klara.visitera`
  is never set while a finding is open, so a visitation with a finding
  never becomes complete that day.

## The four milestones (definition version v1)

| Id | Qualifying moments (from the canon) | Complete when |
|---|---|---|
| `halsa` | the non-wrong alternatives of `halsa` | the player picked a correct alternative BY HAND (`true`) |
| `visitera` | every `vis:*` moment | all are `true`, AND `klara.visitera` was just set, AND there is no welfare stop (a healthy, completed visitation) |
| `rykta` | every `rykt:*` moment | all are `true` |
| `hovar` | the `hov:*` moments of `iordning` | all four are `true`; equipment is not required |

- **Manual only.** Every qualifying moment must be literal `true`.
  - A single `"auto"` moment makes the milestone ineligible that day. A
    later manual action cannot "complete" an assisted milestone, because
    the already-done guard refuses a repeat anyway.
  - Old automatic work is never promoted.
- **Where the marker is born.** In `GameplayService.moment`, right after a
  SUCCESSFUL `Preparation.utforMoment` and BEFORE the view is sent. The
  check runs only when the final qualifying action was recorded, the actor
  is the performer and the performer is not `"auto"`.
- **Evidence.** Everything comes from the server state: the actor, the
  assigned horse (already checked by `provaSteg`) and that day's
  `Preparation` state. The client never supplies completion, save or
  performer flags.
- **What never awards a completion:**
  - a denied, duplicate, wrong-order, wrong-horse or distant action (these
    never reach a successful `utforMoment`);
  - a historical sync, a stalled load (no loaded save) or a model bind.
- **History never completes today.** It never auto-completes today's care,
  equipment, leading or eligibility. The existing retention across an
  ordinary respawn is unchanged.

## Storage (the existing v2 `framsteg`, no schema change)

- **Key:** `skotsel:<id>:v1:<n>`, where `n` is the number of qualifying
  moments in the current canon. A changed canon therefore changes the key,
  and an old marker never counts for a new definition.
- **Separate namespace.** The key never collides with `lektion:*`, and the
  lesson keys, producers and attempt validation are untouched. No RidForsok
  ride is invented for care.
- **Value:** `{1, 1, nil, 0}`, meaning ONLY "done at least once, by
  yourself". It is set once and never counted up.
- **Handling.** The EXISTING `LektionsMinne` pipeline handles it:
  - one writer per player;
  - the same pending, confirmed and unknown states;
  - `foreSkrivning` in every transform run;
  - confirmation only on this module's own `skriv` returning true;
  - bounded follow-ups;
  - the leave drain through SparService's `foreAvfard` → `stangningFor` →
    `efterAvfard`;
  - the token dying with the session.
- **Coexistence.** Care and lesson markers travel in the same pending set,
  so a care completion during a lesson-memory or pass write in flight
  follows the same rules. No second writer exists, and no platform was
  added.
- **Not claimed.** General D3/D4 is not solved.

## Projection and the care surface

- **The server projection** (`LektionsMinneSync` / `LektionsMinne` sync)
  gains `skotsel = { halsa, visitera, rykta, hovar }`. Each value is one of
  `sparad`, `vantar`, `ej_klarad` or `okand`, carrying the SAME
  `session`/`rev` stamps.
- **The client.**
  - `PreparationController` listens (one connection) and asks once at
    `start`.
  - It uses the same ordering rule: a newer session, or the same session
    with `rev` at least as large. An older or reversed reply never replaces
    newer facts.
  - History is player-owned and survives changes of horse and task.
- **The surface.** The existing care panel's help area in Naromrade (the
  "?" button, which already lists today's steps) gets a SEPARATE section
  after today's steps, headed "What you have done yourself":
  - per milestone: "done", "done now – not saved yet" or "not yet";
  - with unknown history, one neutral line: "I can't read your care history
    right now."
- **What the section is not.** It is not a new row, a modal, an
  acknowledgement or an auto-advance.
  - Safety and finding questions, pending and error text, the current task
    text, equipment return and leading keep their priority, because the
    section lives only in the optional help list.
  - It is mandatory guidance for nothing, so the comment settings don't
    affect it.
  - It shows only facts: no improvement and no praise.
- **Language.** SV/EN comes from language keys, drawn at render time.

## Deferred verification (written, NOT run)

`roblox/tests/skotselminne.spec.luau` (KOHERENS) builds on the fixture of
the preparation and memory specs:
- real `GameplayService.moment` (the `PreparationMoment` path) with the
  canon's moments;
- real SparService on the stubbed DataStore;
- the real `PreparationController` and Naromrade help text.

**SYNCHRONOUS cases:**
- each milestone's final manual action;
- the greeting choice (right and wrong alternative);
- hooves before equipment;
- duplicate, denied, wrong order and wrong horse;
- a fully automatic `ridaNu` and a mixed day;
- a welfare stop;
- a new assignment (new state);
- repeating a milestone, then a trusted reload;
- a failed write, then recovery;
- future, corrupt and unavailable history;
- a full `framsteg`;
- reversed replies and a newer context in the client;
- SV/EN in the help section;
- the four-row composition with a care question.

**GENUINELY DEFERRED cases** (scheduler):
- a care completion while a lesson-memory write is in flight;
- a leave during that write (the bounded drain).

**Planned, not written:**
- physical rendering;
- a real DataStore;
- a respawn on a device.
