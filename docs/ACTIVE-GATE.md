# Active Gate

Current gate: **Gate F02 — UBRF Interior Fidelity** (not yet opened; see the
locked order below). **G01 is PAUSED after slice S1.**

## Locked order — Product Owner decision 2026-08-31

```
PR #32 PASS + merge  →  interior fidelity PR  →  Studio fidelity acceptance  →  G01 resumes
```

The horse loop is to be built and validated **inside the real UBRF interior**,
not against a provisional one whose rooms, doors, toilets, furniture,
circulation and interaction anchors will later move. Building G01 S3 on top of
a facility that is about to change would mean anchoring gameplay to positions
that do not survive the fidelity pass.

This reverses the previous instruction that no broad building work happens
while G01 is active. That line stood until 2026-08-31 and is superseded here,
not forgotten: it existed to stop fidelity work from sprawling, and the same
discipline now applies to the interior pass — evidence first, gaps marked, no
invented rooms.

**Do not resume G01 — S3 or ground handling — until the interior pass has been
accepted in Studio.**

### Source priority for the interior pass

1. reference photos in `references/buildings/`
2. evacuation/floor plans in `references/plans/`
3. `KORT.md` building cards
4. existing implementation
5. `[ASSUMPTION]` only where the evidence is genuinely absent

Google Drive is not a dependency. The plans needed are already in the
repository: `ridhus-entreplan-utrymning.jpg`, `stall-plan1-utrymning.jpg` and
the measurements beside them.

### Architecture requirement carried into the pass

Fidelity data stays separate from runtime behaviour. Door mechanics, horse
systems and interaction code consume canonical spatial ids — `BuildingId` +
`OpeningId` / room id — never nearest-object guesses. Moving a verified room
later must not require rewriting game logic.

That contract is already met for openings: `Anlaggningen` stamps the identity
when the panel is built, and `WorldBuild` derives the closed transform from the
owning opening (PR #32, `db5642a`).

## Gate G01 — First Playable Horse Loop: `PAUSED`

`docs/GATE-G01-FIRST-PLAYABLE.md`. Slice S1 is delivered. S2 and later wait for
the interior pass.

## Gate F01 — UBRF Fidelity: `ACCEPTED_IN_ROBLOX_STUDIO`

Human Roblox Studio acceptance completed **2026-08-30** against the corrected
Studio package from PR #26.

Result:

- **11 / 11 canonical QA views: PASS**
- **walk path `ankomsten → stallet → hästgången → ridhuset → banan`: PASS**
- non-blocking observation: **the stable interior feels a little dark**

The lighting note is polish, not a fidelity blocker. It must not reopen broad
environment work while G01 is active. A future lighting pass may address it as
long as visibility and game feel improve without inventing unsupported UBRF
facts.

The real Studio run also exposed the invalid `Enum.Material` defect in the old
package. PR #26 corrected it and added a strict material allowlist/regression
gate so the same class of error cannot silently pass the Linux harness again.

Open `REFERENCE GAP` items remain open and must not be invented:

- hall orientation
- exact size of the gable offset
- documented contradiction between arena board and spectator-front references

F01 acceptance means the current environment is an accepted gameplay baseline;
it does **not** claim every unresolved real-world detail is proven or that the
site is literally 100% identical.

---

## Gate G01 focus

UBRF must now become a playable horse game. Build vertically around:

`arrival → stable → assigned horse → preparation → lead out → riding hall → mount → simple exercise → return → aftercare → feedback`

Roblox is the primary game platform. HTML/web remains a real playable parallel
implementation. GitHub + Supabase are the development source chain; Google
Drive must not be required by implementation agents.

## Roles

### Claude

Lead implementation engineer. Before G01 work, read `CLAUDE.md`, product canon,
AI collaboration rules, the active G01 gate, existing HorseCore/riding code and
relevant web gameplay modules. Reuse existing systems; do not create a second
riding engine or a second competing horse-assignment authority.

### ChatGPT

Senior Game Developer / Game Architect / Reviewer. Keep the slices vertical,
server-authoritative and testable, and reconcile overlapping branches before
merging them.

### Product Owner

Final Roblox Studio visual/play acceptance and product decisions.
