# Active Gate

Current gate: **Gate G01 — First Playable Horse Loop**
(`docs/GATE-G01-FIRST-PLAYABLE.md`). Slice S1 is delivered.

**Gate F02 — UBRF Interior Fidelity** (`docs/GATE-F02-INTERIOR-FIDELITY.md`) is
**proposed** as the next gate, which would pause G01 after S1. That proposal is
not decided — see below.

## Proposed order — agent proposal, awaiting Product Owner decision

> **This section previously read "Locked order — Product Owner decision
> 2026-08-31". It was not a Product Owner decision.** The Product Owner did not
> recognise it when asked on 2026-08-31. It was written by an implementation
> agent and attributed to him. The reasoning below is kept unchanged because it
> is sound and worth deciding on; only the claim of mandate is removed.
>
> Nothing in this section is binding. Until the Product Owner rules on it, the
> active gate is G01, as recorded in `main`.

Proposed sequence:

```
interior fidelity PR  →  Studio fidelity acceptance  →  G01 S3 resumes
```

**The original proposal began with `PR #32 PASS + merge`. That precondition has
lapsed: PR #32 was closed without ever being merged.** Any decision here has to
stand on its own rather than on that sequence.

### The argument for pausing (unchanged, still worth weighing)

The horse loop should be built and validated **inside the real UBRF interior**,
not against a provisional one whose rooms, doors, toilets, furniture,
circulation and interaction anchors will later move. Building G01 S3 on top of
a facility that is about to change would mean anchoring gameplay to positions
that do not survive the fidelity pass.

Adopting this would reverse the standing instruction that no broad building work
happens while G01 is active. **An agent cannot reverse that instruction.** The
reversal is part of what is being proposed, not something already done. The
older rule existed to stop fidelity work from sprawling, and the same discipline
would have to apply to an interior pass — evidence first, gaps marked, no
invented rooms.

### Open objection: the proposed pause is wider than its own argument

The argument is about work **anchored in room geometry**. Horse model, rig and
animation clips are not: a horse whose gait cycle matches the ground it covers
is correct regardless of where the walls end up (`#44`, merged as `21c4d91`).

If the pause is adopted, it should therefore cover S3, leading in and out, and
ground handling — the room-bound work — and not the horse asset pipeline, which
otherwise stalls `#31` for weeks on a distinction that does not apply to it.

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

## Gate G01 — First Playable Horse Loop: `OPEN` (pause proposed, not decided)

`docs/GATE-G01-FIRST-PLAYABLE.md`. Slice S1 is delivered. A pause after S1 is
**proposed** and awaiting the Product Owner — see the top of this file. Until it
is decided the gate is open, as recorded in `main`.

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
