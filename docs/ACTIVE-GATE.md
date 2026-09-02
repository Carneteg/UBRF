# Active Gate

Current gate: **Gate G01 — First Playable Horse Loop** (`docs/GATE-G01-FIRST-PLAYABLE.md`)

## Gate F01 — UBRF Fidelity: `TARGETED_CORRECTION_REQUIRED`

Human Roblox Studio acceptance was completed **2026-08-30** against the corrected
Studio package from PR #26, but Tobias has since supplied a new explicit visual
correction on **2026-09-02**. Per `CLAUDE.md`, Tobias's direct product decision
outranks the previously accepted baseline. F01 is therefore reopened **only for
this narrow facade correction**; broad environment rework remains out of scope.

### Mandatory facade correction — 2026-09-02

This is a **fidelity correction, not optional polish**.

On the red stable facade, the following two architectural groups are currently
in the wrong relative positions and **must swap places**:

1. the porch / roofed entrance structure,
2. the small roofed door together with the black spiral staircase and its upper
   landing/platform.

After the swap, the **spiral staircase must also sit visibly farther to the
left** than in the current implementation, with clearer lateral separation from
the small roofed door and landing composition.

Implementation requirements:

- Correct the **world geometry / authoritative building source**, not only a
  camera, screenshot, render, CSS transform, or view-specific offset.
- Apply the corrected architectural placement to both **Roblox** and the
  **HTML/web playable world** where this facade exists.
- Preserve the verified red siding, trim, windows, door style and overall UBRF
  building identity; do not redesign unrelated facade elements.
- Do not move unrelated doors/windows/buildings to make the correction easier.
- Re-render / re-capture the relevant canonical fidelity views after the change
  so the new positions can be compared against Tobias's reference.
- Claude may report at most `READY_FOR_CHATGPT_REVIEW` after implementation and
  evidence. Claude must **not** mark the correction accepted/done/final on its
  own.
- Final visual fidelity requires Tobias's explicit human PASS.

### Acceptance criteria for this targeted correction

The correction is ready for review only when all of the following are true:

- porch/roofed entrance and staircase-door-platform group have actually swapped
  their facade locations,
- spiral staircase is visibly farther left than before,
- Roblox source/build and HTML/web source/build both reflect the same intended
  real-world relationship,
- no unrelated facade regression has been introduced,
- before/after or equivalent view evidence is supplied from matching angles,
- any environment/runtime that Claude could not execute is listed under
  `Not tested` rather than claimed as PASS.

The previous F01 result remains useful baseline evidence:

- **11 / 11 canonical QA views: PASS** at the 2026-08-30 acceptance state,
- **walk path `ankomsten → stallet → hästgången → ridhuset → banan`: PASS**,
- non-blocking observation: **the stable interior feels a little dark**.

Those earlier PASS results do not override the new targeted correction above.
Once Tobias accepts this correction in the target experience, F01 may return to
`ACCEPTED_IN_ROBLOX_STUDIO`.

Open `REFERENCE GAP` items remain open and must not be invented:

- hall orientation
- exact size of the gable offset
- documented contradiction between arena board and spectator-front references

---

## Gate G01 focus

UBRF must now become a playable horse game. Build vertically around:

`arrival → stable → assigned horse → preparation → lead out → riding hall → mount → simple exercise → return → aftercare → feedback`

Roblox is the primary game platform. HTML/web remains a real playable parallel
implementation. GitHub + Supabase are the development source chain; Google
Drive must not be required by implementation agents.

The targeted F01 facade correction above is allowed to interrupt G01 only to the
extent needed to fix and verify that specific real-world fidelity defect. Do not
use it as permission for a broad environment rewrite.

## Roles

### Claude

Lead implementation engineer. Before G01 work, read `CLAUDE.md`, product canon,
AI collaboration rules, the active G01 gate, existing HorseCore/riding code and
relevant web gameplay modules. Reuse existing systems; do not create a second
riding engine or a second competing horse-assignment authority.

For the reopened targeted F01 correction, Claude must first inspect the current
authoritative building implementation and relevant repo references, then change
the underlying geometry and provide review evidence. A visually similar render
without a source-level correction is not completion.

### ChatGPT

Senior Game Developer / Game Architect / Reviewer. Keep the slices vertical,
server-authoritative and testable, reconcile overlapping branches before
merging them, and independently review the facade correction against the actual
diff and evidence.

### Product Owner

Final Roblox Studio visual/play acceptance and product decisions.
