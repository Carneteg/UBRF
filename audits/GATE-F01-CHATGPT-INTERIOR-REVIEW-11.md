# Gate F01 — ChatGPT Senior Interior Fidelity Review 11

**Status:** CODE GATE PASSED — ROBLOX STUDIO VISUAL VERIFICATION REQUIRED

**Reviewed head:** `205ddfb6aca9577c1c6c90d67ff5ae3c742415cb`

## Decision

Review 10 is accepted on code/evidence level. No further code blocker is identified in the narrow ridhus interior parity pass.

### Accepted

1. **Arena sand parity**
   - Roblox now builds `Ridbanan 20x60` from shared `R.sandFarg` (`#6F5D4D`) rather than the stale beige `INRE.sand`.
   - The parity assertion reads shared data and was falsified by restoring the old value.

2. **Ridhus roof parity**
   - Roof structure dimensions were moved out of web-only literals into shared `RIDHUSINNE.takstomme`.
   - `takfarg.balk` and `takfarg.plat` are exported to Roblox.
   - Roblox now builds the roof underside and roof structure from the same data used by web.
   - Structure dimensions remain correctly classified as `DERIVED` where not measured; colors are source-measured.

3. **Studio checklist corrected**
   - The stale instruction describing warm timber is removed.
   - Current checklist correctly expects dark grey-brown / near-neutral ridhus roof structure and dull brown-grey arena sand.

4. **Regression protection**
   - New assertions verify sand color, existence of roof structure/underside, shared roof colors, and beam count derived from shared spacing.
   - Existing export sync, six Luau specs and web scene check remain reported green.

## Remaining open facts — not code blockers

These stay open and must not be invented:

- Absolute long-side orientation: `REFERENCE GAP`.
- Sarg versus dark spectator-front relationship: documented source contradiction.
- Other previously documented site/reference gaps remain outside this interior code pass.

## Gate transition

The ridhus interior has reached the point where further source-independent coding would be lower value than visual verification on the primary platform.

**Next required step: Roblox Studio visual inspection using `roblox/docs/RIDHUS-STUDIO-CHECKLISTA.md`.**

The Studio pass must visually verify at minimum:
- partial one-side maroon panel and sponsor wall,
- window band,
- C-end stepped block, stairs, segmented glazing, white wall, clock and compass rose,
- E booth, roof, stairs, rails and exit sign,
- roof underside, dark grey-brown timber structure, steel profiles, cable ladders and ventilation,
- arena sand and sarg/openings,
- no obvious overlap, z-fighting, impossible clipping or lighting/material result that makes the implementation visibly contradict the references.

## Merge status

**PR #22 remains blocked from merge.**

Passing automated tests is not visual Studio evidence. If the Studio inspection passes, return the screenshots/observations for final Product Owner / Senior Fidelity acceptance. If it fails, reopen only the concrete visual mismatches found in Studio.
