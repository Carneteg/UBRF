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

- **Key:** `skotsel:<id>:<version>:<n>`, where the version comes from an
  explicit table (`SKOTSEL_VERSION`; `halsa` is `v2` since UI-2, the rest `v1`) and `n` is the number of
  qualifying moments in the current canon.
  - UI-2 (docs/P2-UGNETA-INSTRUCTION-CONTRACT.md): the greeting changed from a
    choice (one of two right answers) to three ordered actions that are all
    required, so `halsa` was bumped to `v2`. Choice vs checklist is derived
    from `Preparation.arVal`, not the phase name. Old `v1` markers are kept
    untouched and simply do not count toward `v2`.
  - Correction (leading package): the earlier claim that ANY changed canon
    changes the key was wrong. A change in the number of moments changes
    the key automatically. A change in the qualifying MEANING (reordering,
    replaced moments or new rules) REQUIRES the version to be bumped by
    hand. An unchanged definition keeps its key.
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

## Deferred verification (written, NOT run), corrected against the actual spec

`roblox/tests/skotselminne.spec.luau` (KOHERENS) uses integration-spec
sessions.

**SYNCHRONOUS cases, written:**
- the definitions;
- the greeting (a wrong and a right alternative);
- the visitation only at its last point;
- grooming;
- hooves before equipment;
- a duplicate;
- wrong order;
- a fully automatic `ridaNu` and a mixed day;
- a trusted reload (history does not complete today's work);
- a write failure, then recovery;
- a full `framsteg`;
- a read failure giving unknown history;
- the version policy: the same definition keeps its key, a revised one
  gets a new key.

**RULES LEVEL, written:** the welfare stop, run on a real `Preparation`
state with the hook called directly.

**CLIENT, written:**
- the server's own projection delivered through the client event: ordering,
  unknown history and SV/EN;
- the REAL LocalPlayer care view (section 12): the history in the help
  section next to a question and an equipment return. The question and the
  return come from a SYNTHETIC view through the PreparationSync listener.
  The four-row cap and SV/EN are also checked.

**GENUINELY DEFERRED, written:**
- section 9: the care marker's OWN write in flight, a visitation during it,
  a leave during it (the drain), then a trusted reload;
- section 11: a PASS-STYLE write in flight (`registreraPass` plus
  `SparService.skriv`, the persistence step of `avslutaPass` invoked
  directly, NOT the whole `avslutaPass` flow), with grooming completed
  during it. The marker stays pending and is confirmed by the memory's own
  attempt afterwards.

**PLANNED, not written:**
- wrong horse through a second player (the moment path refuses it before
  the hook; `integration.spec` covers that refusal);
- a future or corrupt save for care specifically (the lesson-memory spec
  covers the shared pipeline);
- a newer context in the host;
- a real mounted-memory completion during a care write;
- physical rendering;
- a real DataStore.

