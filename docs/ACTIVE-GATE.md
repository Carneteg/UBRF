# Active Gate

Current gate: **Gate G01 — First Playable Horse Loop** (`docs/GATE-G01-FIRST-PLAYABLE.md`)

## Gate F01 — UBRF Fidelity: `HUMAN_STUDIO_ACCEPTED / CLOSED`

Human Roblox Studio acceptance completed **2026-08-30** against the corrected
Studio package from PR #26.

Result:

- **11 / 11 canonical QA views: PASS**
- **walk path `ankomsten → stallet → hästgången → ridhuset → banan`: PASS**
- non-blocking observation: **the stable interior feels a little dark**

The lighting note is polish, not a fidelity blocker. It must not reopen broad
environment work while G01 is active. A future lighting pass may address it —
**in the lighting, never by moving a measurement or repainting a measured
surface**, and without inventing unsupported UBRF facts.

The real Studio run also exposed the invalid `Enum.Material` defect in the old
package. PR #26 corrected it and added a strict material allowlist/regression
gate so the same class of error cannot silently pass the Linux harness again.

Open `REFERENCE GAP` items remain open and must not be invented:

- hall orientation
- exact size of the gable offset
- documented contradiction between arena board and spectator-front references

F01 acceptance means the current environment is an accepted gameplay baseline;
it does **not** claim every unresolved real-world detail is proven or that the
site is literally 100% identical. The decision is the Product Owner's, not the
implementation agent's — evidence in `audits/GATE-F01-UBRF-FIDELITY-RESULT.md`
and `audits/GATE-F01-STUDIO-ACCEPTANCE-2026-08-30.md`.

> Two names were briefly used for this state. `HUMAN_STUDIO_ACCEPTED / CLOSED`
> is the canonical one; `ACCEPTED_IN_ROBLOX_STUDIO` means the same thing and
> should not be reintroduced as a separate status.

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
