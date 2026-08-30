# Gate F01 — ChatGPT Senior Site Fidelity Review 08

Status: **CHANGES REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `1375ede225e12f1809b131e91cdf2c77b8207cd6`
Reviewed implementation commit: `c247dc018fac67ea1dc55dba892b25dd27ea8c50`

## Executive verdict

Claude fixed the main Review 07 error correctly: the stable is now longitudinally staggered **northward** relative to the riding hall, not southward. The 6 m magnitude remains honestly classified as an assumption/reference gap, the generated Roblox geometry reflects the changed canonical data, and the PR body now states the current sign and uncertainty.

However the sign change was **not propagated through all dependent site truth**. There are still stale coordinates and at least one real visual geometry regression around the stable's southern gable. The source comments also contain mutually contradictory horse-passage positions.

PR #22 must therefore still **not be merged**.

---

## PASS 1 — Stagger direction is now correct

Active geometry now does:

```js
const RIDHUS_NORR = 119;
const GAVELFORSKJUTNING = 6; // stallet NORRUT relativt ridhuset
const STALL_NORR = RIDHUS_NORR + GAVELFORSKJUTNING; // 125
const STALL_Y = STALL_NORR - STALL_LANGD; // 55.05
```

That is the correct sign for the project's coordinate convention, where game-north corresponds to real-world north-west.

The Product Owner supplied satellite crop visible in this review also supports the topology: the vent-hood stable extends farther toward the NW end, while the riding hall extends farther toward the opposite SE end.

`6 m` remains **not measured**. Keeping it as `ASSUMPTION` / `REFERENCE GAP` is correct.

---

## PASS 2 — Training-surface method remains honest

The reality-first inventory remains the right abstraction:

- `NO_STOR`
- `NO_LITEN`

and the clean `33.57 m` measurement remains attached to the physical `NO_STOR` surface rather than being allowed to invent a gameplay identity.

Current code also explicitly says that both world positions and unresolved dimensions are working values. That is correct evidence discipline.

This means the training-surface **method passes**, but their real site placement is still an open Gate F01 gap rather than a solved fidelity claim.

---

## PASS 3 — PR body and web→Roblox canonical export are materially improved

The PR body now states:

- stable north of riding hall;
- magnitude unresolved;
- neutral training-surface IDs;
- training positions unresolved;
- Studio not visually verified.

The generated Roblox canonical file exists at the current head and reflects the changed web canonical geometry. That is the correct parity mechanism.

---

# BLOCKER A — The 6 m move did not propagate to all southern-gable geometry

The stable's active southern gable moved from `y = 49.05` to:

```text
STALL_Y = 55.05
```

But several pieces of site geometry still encode the **old 49.05-era relationship**.

### Verified example: fodder silo

The code comment correctly documents the intended source relationship:

- `stall-gavel-06-silon.jpg` shows the silo **tight against the stable gable**;
- the old placement used `pos y = 47.5` with radius `1.5`, placing its edge at about `49.0`, almost touching the old gable at `49.05`.

The active prop is still:

```js
{typ:"silo", pos:[164.6,47.5]}
```

After the stable moved north, the southern gable is now at `55.05`.

So the silo's northern edge is still about `49.0`, leaving roughly **6.05 m of empty space** to a feature whose source relationship is documented as tight to the gable.

That is a real fidelity regression introduced by the stagger correction.

### Other old-gable anchors that must be audited, not blindly moved

The same section still contains old-state geometry/comments such as:

- southeast gravel yard at `y = 40, h = 9`, with a comment saying the house reaches `49.05`;
- `bod` at `y = 44`, described as being by the southern gable;
- hay/bale props moved alongside the old silo relationship;
- other service-yard props whose relation to the stable was derived before the 6 m shift.

Do **not** automatically add 6 m to every object. Review each one against its source relationship:

- if source says it is attached/tight to the gable, derive it from `STALL_Y`;
- if its world position is independently sourced, keep it;
- if neither is known, mark it `REFERENCE GAP` instead of preserving an obsolete coordinate.

At minimum the silo must be corrected because its source relationship is already documented.

---

# BLOCKER B — SITEPLAN still does not match the actual horse-passage geometry

The active code now computes:

```js
STALL_Y = 55.05
GANG_FASTE = STALL_Y + 27.8
```

Therefore the actual horse-passage start is:

```text
GANG_FASTE = 82.85
```

with the current 3.5 m depth giving approximately:

```text
82.85 → 86.35
```

But `references/SITEPLAN.md` still states:

```text
Hästgången: y = 76.85
```

and the two yard ranges are still written around the old passage position:

```text
55.05–76.85
80.35–119
```

Those are not the numbers actually built anymore.

If the current derived passage position is retained, SITEPLAN must be recalculated from the active constants rather than patched from the previous state.

---

# BLOCKER C — `src/site.js` itself contains contradictory current-state prose

Review 07 explicitly required code comments to match current truth. They still do not.

Examples at the current head:

### 1. Flush-gable prose still exists

Above the active stagger constants the file still says, in substance:

> both northern gables remain at y = 119

The active code directly below says riding hall `119`, stable `125`.

### 2. `GANG_FASTE` numeric comment is stale

The expression now evaluates to `82.85`, but the inline comment still says:

```js
const GANG_FASTE = STALL_Y + 27.8; // 76,85
```

### 3. The horse-passage source block contains several mutually incompatible histories as if they were current truth

One paragraph says the placement is **VERIFIED** from a central overlap around `y 89.3–92.8`.

A later paragraph says the measured-length correction moved it to `76.85–80.35`.

The actual current generated geometry is now based on about `82.85–86.35`.

This is exactly the failure mode the audit-cleanup work was intended to eliminate: a future agent cannot tell which statement is current without recomputing the code.

## Required correction

Rewrite this block as one current-state statement:

- existence and central/tvärgående topology: `VERIFIED`;
- exact metres: unresolved;
- current `82.85` position: `DERIVED` from stable plan proportions + current stable length/position, if that derivation is still intended;
- old `89.3` and `76.85` positions: `SUPERSEDED`, moved to a short history note or git history.

The source-of-truth comment must not claim an obsolete coordinate is current.

---

# BLOCKER D — Training-surface placement remains an external source gap

Current working geometry is approximately:

```js
NO_STOR  = {x:173, y:126, w:33.57, h:40}
NO_LITEN = {x:150, y:132, w:18, h:24}
```

Only `33.57` is measured. Claude correctly labels the rest as working/reference-gap values.

Therefore this is **not a new implementation failure**, but it remains a Gate F01 blocker for claiming the full site layout correct.

The satellite crop available in this review shows the building complex and horse passage, but it does **not** include the training-area environment far enough out to close these positions.

Do not pretend this is solved until the relevant overhead/site source is build-accessible and can anchor the surfaces relative to the buildings/roads.

---

# BLOCKER E — Roblox Studio visual verification remains mandatory

No change.

Structural export and tests are useful, but the gate still requires Roblox Studio visual inspection after source/geometry truth is coherent.

---

## Required handoff for Review 09

Claude should make one narrow cleanup pass only:

1. audit every site object whose location depended on the stable's old southern gable and fix/classify it; **the silo is a confirmed mismatch**;
2. recalculate SITEPLAN horse-passage and yard ranges from the active geometry;
3. remove stale `49.05`, `76.85`, `89.3–92.8`, and flush-gable prose wherever it is being presented as current truth;
4. keep historical values only as explicitly `SUPERSEDED` history;
5. regenerate Roblox export;
6. run the existing tests/export check;
7. leave training-surface world positions as explicit `REFERENCE GAP` until a source can anchor them;
8. do not claim Gate F01 complete or merge PR #22.

Then hand back for **ChatGPT Senior Site Fidelity Review 09**.
