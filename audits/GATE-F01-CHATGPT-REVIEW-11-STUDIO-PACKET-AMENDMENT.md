# Gate F01 — ChatGPT Review 11 Studio Packet Amendment

Status: **CODE GATE PASSED / STUDIO PACKET CHANGES REQUIRED BEFORE MANUAL VISUAL ACCEPTANCE**

Review 11's code conclusion remains valid: the current implementation is ready to be taken into Roblox Studio for visual verification. During preparation of the manual step, however, the Studio packet itself was found to contain stale instructions from Review 03 and is therefore not safe to use unchanged.

## Findings

### 1. `roblox/buildings/STUDIO-KONTROLL.md` is stale

It still says or implies several facts that have since been superseded:

- it frames the process around Review 03 rather than the current Review 11 baseline;
- it says the complex should show the building gables "i liv", while current canon explicitly says the buildings are **not** aligned and the stable is currently modelled north of the riding hall, with the exact offset still a `REFERENCE GAP`;
- it carries old literal horse-passage / spectator-gap / gate dimensions that must not be presented as current truth unless they are read from the current shared data and correctly classified;
- its expected static object-count example predates many later interior additions and must not be used as a hard pass/fail value unless generated dynamically from the current build;
- it does not include the current Review 11 ridhus-specific checklist as the authoritative interior visual checklist.

### 2. `tools/studio-paket.py` points to the stale checklist

The generated header tells the tester to use `roblox/buildings/STUDIO-KONTROLL.md`. The packet must point to the current manual verification documents and must not encode a stale review number as the governing baseline.

### 3. Five generic camera views are insufficient for the current ridhus interior gate

`Vyer.luau` still reflects the old five-view Review 03 acceptance flow. One generic `ridhuset` camera cannot visually verify all current player-visible identity features.

Before manual acceptance, the Studio packet must expose dedicated, data-derived camera views for at least:

- ridhus C-end: stepped spectator block, two stairs, segmented glazing, white wall, round clock, compass rose;
- sponsor/panel long side: partial one-side maroon panel, white horizontal battens, sponsor signs, window band;
- E-side judge booth: raised dark booth, pitched roof, stair, rails, exit sign;
- roof: dark grey-brown timber, steel profiles, cable ladders with rungs, large ventilation ducts;
- arena surface/sarg: dull brown-grey sand, cream/white kickboard, dark base strip, required openings;
- stable aisle/service view from the previously rejected camera direction, so the corrected open service bays and box-front identity are confirmed in Studio.

The existing overview/site views may remain, but they do not replace these interior views.

## Required Claude pass — packet only, no fidelity redesign

Do **not** reopen site geometry, footprints, building orientation, horse-passage dimensions, training surfaces, or speculative source gaps.

1. Rewrite `roblox/buildings/STUDIO-KONTROLL.md` to current Review 11 facts only. Remove stale claims and literal dimensions that are no longer canonical. Link/coordinate it with `roblox/docs/RIDHUS-STUDIO-CHECKLISTA.md`.
2. Update `tools/studio-paket.py` header/instructions to reference the current Studio checklist set and current review baseline. Keep the generated Studio bundle deterministic and uncommitted.
3. Extend `roblox/buildings/Vyer.luau` with the dedicated interior verification cameras listed above. Camera positions must derive from `UBRFKomplex` data; do not introduce a second geometry truth.
4. Do not hard-code a stale expected object count in the manual checklist. The actual build must finish without runtime error; exact object-count assertions belong in tests/current build output, not a copied historic number.
5. Run export sync, all six Luau specs, and `tools/webbkoll.mjs` after the packet changes.
6. Return with implementation SHA and the exact ordered Studio commands the Product Owner should execute.

## Gate status

No further fidelity implementation is authorized before this packet pass unless the packet work itself exposes a real code defect.

After the packet is corrected, the next required step is **manual Roblox Studio visual verification**. PR #22 is still not approved for merge until that visual step is completed.
