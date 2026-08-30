# Gate F01 — ChatGPT Senior Fidelity Review 02

Status: **CHANGES REQUIRED — TWO BLOCKERS REMAIN**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `ba0243ebe0755deafe71b82a12451e1d6f36ec6b`

## Executive verdict

Review 01 produced real improvement. The connected complex is now represented as `RIDHUS ↔ HÄSTGÅNG ↔ STALL`; the evacuation plans are build-accessible in the repository; the stable's six transverse bands are measured from the plan instead of assumed equal; the exact stable width is correctly downgraded to `ASSUMPTION`; and Roblox now has a deterministic geometry export generated from the same `src/site.js` source used by the web version.

Those are substantive passes.

Gate F01 still does **not** pass, because the repository now contains two remaining forms of split truth:

1. canonical reference documents still preserve the rejected 21 m proof as if it were a corrected fact, alongside the newer `ASSUMPTION` classification; and
2. Roblox consumes the shared exterior/connection shell geometry but does not yet build the corrected stable/riding-hall interior geometry that Gate F01 is explicitly about.

Do not merge PR #22 yet.

---

## REVIEW 01 BLOCKER A — Connected complex

**PASS, with documented reference gap.**

The implementation now contains a physical `hastgang` volume touching both principal buildings:

- riding hall east edge: `x = 143`,
- horse corridor: `x = 143..154`,
- stable west edge: `x = 154`.

The web implementation has internal transitions in both directions, and the generated Roblox geometry includes the same volume and internal facade openings. `geometri.spec.luau` explicitly checks that the corridor touches both buildings and that the principal buildings do not touch directly.

The exact location, dimensions, roof and landing points of the horse corridor remain `ASSUMPTION`. That is acceptable for this stage because Tobias has verified the existence/function of the connection while the repository still lacks a direct visual source for its exact geometry.

The important distinction is now correctly documented: **existence/function verified; exact shape/location not verified.**

---

## REVIEW 01 BLOCKER B — Direct fire/evacuation-plan source

**PASS.**

The repository now contains the plan sources/derivatives under `references/plans/`, and the stable transverse proportions are measured directly from the plan rather than inherited from prose.

The plan confirms the structural ordering:

`box row — aisle A — box row — box row — aisle B — box row`

and the implementation now uses the measured scale-independent proportions.

---

## REVIEW 01 BLOCKER C — Stable width over-locked

**IMPLEMENTATION PASS, DOCUMENTATION BLOCKER REMAINS.**

The implementation/audit now correctly classifies the stable's 21 m width as `ASSUMPTION`, with the plan's transverse *proportions* treated as verified.

However the canonical reference chain still contradicts itself.

### `references/buildings/stall/KORT.md`

The current file first says:

- `21 × 54 m` is an `ASSUMPTION`,
- width is not established,
- the old longitudinal 3.5 m rhythm cannot prove transverse dimensions.

Then, in the same file, it still contains the old heading:

> `### Bredden — rättad 2026-08-30, från 15 m till 21 m`

and repeats the rejected argument:

> `sex band à 3,5 m exakt 21,0 m`

followed by language such as:

> `Nockmätningen ... Den var inte för hög — bredden var för smal.`

That section is superseded reasoning and must not remain as active canon beside the corrected section.

### `references/SITEPLAN.md`

The site plan still describes the stable row as **21 × 54** with language that the width was "rättad" and that double-stable + roof geometry gives 20–22 m. A later paragraph still repeats the invalid longitudinal-rhythm route.

This is not merely editorial. These documents are source material Claude and future agents are instructed to read before implementation. A future pass can therefore re-lock the same rejected conclusion.

### Required fix

- Remove or clearly move the rejected 21 m proof into a superseded/history block that cannot be read as current truth.
- `KORT.md`, `SITEPLAN.md`, the audit, and code comments must agree on one statement:
  - six-band ordering/proportions = `VERIFIED`,
  - total stable width = current implementation assumption, approximately bounded but **not verified**,
  - 21 m = current working value only.
- Do not describe 21 m as "rättad", "fastställd", or as a conclusion of the 3.5 m window/hood rhythm.

---

## REVIEW 01 BLOCKER D — Roblox parity

**PARTIAL PASS — actual environment parity still blocked.**

The deterministic export architecture is good and should be retained:

`src/site.js → tools/exportera-geometri.js → UBRFKomplex.luau → Anlaggningen.luau`

This solves the "second hand-maintained truth" problem for the data it exports.

But `Anlaggningen.luau` currently builds:

- ground surfaces,
- outer building boxes/walls,
- roof shells,
- facade openings,
- door markers.

It loops over `G.byggnader` and calls `byggHus`.

It **does not consume the exported stable interior structure** in `G.stall` to construct:

- four box rows,
- two aisles,
- the verified transverse proportions,
- transverse corridor,
- stable interior circulation/rooms.

It also **does not consume the riding-hall interior facts** required by this gate to construct the riding-hall interior, including the arena/interior layout and the verified identity features corrected in the web implementation.

So Roblox now has a shared-data **building shell**, not the corrected UBRF environment implementation.

This matters because Issue #21 requires both platforms to use the same real-world facts for planform, connected mass, doors, corridors, rooms, recognition features and named areas. Data being present in a generated module is not enough if the primary-platform builder ignores that data.

### Required fix

Keep the generator. Extend the Roblox building path only enough to consume the same structural facts needed for Gate F01:

#### Stable
- build four box rows and two aisles from the exported band proportions,
- build the transverse corridor / major circulation supported by the plan,
- preserve the currently documented uncertainty in absolute width and detailed room dimensions,
- do not invent extra room detail.

#### Riding hall
At minimum build the structural/interior fidelity facts that materially affect recognition and circulation:
- 20 × 60 arena within the building plan,
- entrance/hall relationship,
- spectator/side-space relationship where represented by current canonical data,
- the major interior identity features already treated as corrected Gate-F01 facts where the renderer supports them.

Do not attempt simulator-grade interior asset work. This is parity of the corrected UBRF facts, not a new art project.

### Studio verification

After that implementation, run the Roblox builder in Studio/device-compatible playtest. Compilation plus pure-Luau geometry tests are not sufficient proof that the generated environment actually builds correctly in Roblox.

Required evidence:

- model builds without runtime errors,
- riding hall, horse corridor and stable read as one complex,
- horse corridor physically joins both volumes,
- stable visibly has four rows / two aisles,
- major entrances/passages are usable,
- no overlapping solid geometry blocks the intended circulation,
- screenshots from at least two comparable exterior views and one stable interior view,
- if a riding-hall interior view is implemented, one comparable interior screenshot.

Until this is done, Gate F01 remains **not parity-ready**.

---

## Additional review note — good evidence discipline

Claude's latest audit correctly stopped calling the Drive-only riding-hall text-derivative checks "visual verification" and now labels them as implementation compared with a verified text derivative. Keep that wording.

Likewise, the horse-corridor location/shape is now honestly classified as an assumption rather than presented as visually verified. Keep that distinction.

---

## Review 02 status table

| Area | Result |
|---|---|
| Connected `RIDHUS ↔ HÄSTGÅNG ↔ STALL` topology | **PASS** |
| Direct evacuation-plan source in repo | **PASS** |
| Stable six-band proportions from plan | **PASS** |
| Exact stable width uncertainty handled in code/audit | **PASS** |
| Canonical docs agree on stable-width confidence | **BLOCKER** |
| Deterministic web → Roblox geometry export | **PASS** |
| Roblox exterior/connection shell geometry | **PASS** |
| Roblox stable/riding-hall interior fidelity implementation | **BLOCKER** |
| Roblox Studio runtime/visual verification | **BLOCKED by previous item** |
| Riding-hall Drive-only evidence labeling | **PASS** |

---

## Required Claude response

Implement only these two blockers:

1. **clean the canonical source chain** so the old 21 m proof is clearly superseded and cannot conflict with the current `ASSUMPTION` classification;
2. **make Roblox consume the corrected interior structural facts**, then verify the result in Studio.

Do not expand gameplay or add unrelated cosmetic work.

Then update `audits/GATE-F01-UBRF-FIDELITY-RESULT.md` and hand back for **Senior Fidelity Review 03**.

Expected next status if those pass and remaining uncertainty stays honestly documented:

**FIDELITY READY WITH DOCUMENTED GAPS — PRODUCT OWNER VISUAL ACCEPTANCE REQUIRED**

not `IDENTICAL`.