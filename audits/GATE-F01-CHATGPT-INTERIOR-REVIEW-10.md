# Gate F01 — ChatGPT Senior Interior Fidelity Review 10

**Reviewed head:** `0805e5d58eaab868e8af759f58333f5fa2021970`

**Status:** `CHANGES REQUIRED`

Review 09's requested Roblox parity work is materially improved and most of it is accepted. However the current Roblox-primary build still contains two player-visible ridhus interior truths that do not follow the new shared source-backed data. Studio should not be used as final acceptance until these are fixed, because the checklist would currently ask Tobias to judge surfaces that the Roblox builder is still rendering from stale literals or not building at all.

## Accepted from Review 09

### 1. Partial maroon panel
Accepted. Roblox now reads `ovreVagg.sida`, `y0`, `y1` and the shared measured panel/list colors. It no longer paints both long sides for almost the full hall length.

### 2. Sponsor wall
Accepted. Roblox now builds the sponsor boards from shared `R.skyltar`, on the configured panel side and panel-relative positions.

### 3. C-end identity
Accepted structurally. Roblox now builds the stepped block, two stairs, segmented glazing, explicit white wall zone, round clock between the stairs and the line-drawn compass rose.

### 4. Test philosophy
Accepted. The replacement tests now assert source/shared-data relationships rather than preserving the previous incorrect implementation. The falsification work described in `9da75d7` is the right method.

### 5. Current shared color data
Accepted as the current source-backed baseline: `R.hallvagg`, `R.takfarg.balk`, `R.takfarg.plat`, `R.sandFarg`, and the C-end bench colors are now exported into `UBRFKomplex.luau` from `src/site.js`.

---

## P0 BLOCKER A — Roblox arena sand still ignores shared `R.sandFarg`

The generated shared data contains:

- `R.sandFarg = Color3.fromRGB(111, 93, 77)` (`#6F5D4D`), the dull brown-grey value now used by the web/source-backed interior.

But `roblox/buildings/Anlaggningen.luau::byggRidhusInre` still builds the 20×60 arena with:

```luau
..., INRE.sand, Enum.Material.Sand)
```

and `INRE.sand` is still the old light beige `Color3.fromRGB(206, 186, 148)`.

This directly contradicts both the shared data and the Studio checklist, which correctly says the arena must read dull brown-grey rather than orange/beige.

### Required
- Make the Roblox arena consume `R.sandFarg` (with a fallback only if needed).
- Do not introduce another Roblox-only copied RGB.
- Add a build/parity assertion that the produced `Ridbanan 20x60` color equals `UBRFKomplex.ridhus.sandFarg`.
- Falsify that test once by reintroducing `INRE.sand`.

---

## P0 BLOCKER B — Roblox roof is still not parity with the new ridhus roof baseline

Claude's `0805e5d` correctly established that the ridhus roof is **not** the warm stable roof:

- roof framing / beams: dark grey-brown, near neutral (`R.takfarg.balk = #5C4C45`),
- underside sheet/ceiling: neutral grey (`R.takfarg.plat = #5E5B5E`).

The web renderer consumes `R.takfarg.plat` and `R.takfarg.balk`.

The current Roblox builder does **not** consume `R.takfarg` anywhere. `Anlaggningen.luau` builds the exterior `gableRoof`, plus the steel profiles, cable ladders and ventilation, but the source-backed interior roof framing/underside colors added in `0805e5d` are not used by the Roblox renderer.

This also exposes a deeper checklist problem: the Studio checklist asks Tobias to verify the roof timber/framing, while the current Roblox identity function only explicitly builds steel profiles, cable ladders and ventilation. If source-backed roof framing, underside and fixture geometry are not actually present in the Studio build, the checklist cannot call them pass/fail items.

### Required
1. Audit exactly what Roblox produces for the ridhus roof from inside the arena.
2. Make the Roblox roof consume shared exported roof facts rather than its exterior roof color or local literals.
3. If the roof framing / underside / lighting geometry exists only in `varld3d.js`, move the needed **source-backed data** into the shared/exported model and let both renderers consume it. Do **not** create a second hand-maintained geometry truth in `Anlaggningen.luau`.
4. Minimum Roblox parity before Studio:
   - source-backed roof framing visible,
   - underside/ceiling surface uses `R.takfarg.plat`,
   - framing uses `R.takfarg.balk`,
   - steel profiles,
   - cable ladders with rungs,
   - large ventilation ducts,
   - source-backed light fixtures if they are part of the current interior baseline.
5. Add build/parity tests that at least prove the produced framing/underside read the shared colors and that the required roof identity object families are actually produced.

Do not tune arbitrary counts or spacing where the source is still `REFERENCE GAP`.

---

## P1 — Studio checklist is stale after `0805e5d`

`roblox/docs/RIDHUS-STUDIO-CHECKLISTA.md` currently says:

> `Limträbalkar i varmt trä.`

That now contradicts Claude's own measured conclusion in `0805e5d`: the ridhus roof framing reads dark grey-brown / nearly neutral and is explicitly **not** warm like the stable's limträ.

### Required
Rewrite the roof checklist to match the current reference matrix and shared values. The checklist must not tell Tobias to reject the correct darker/neutral ridhus roof.

Also include the actual visible roof-lighting requirement only if Roblox now builds it. If it is not built, that is an implementation gap, not something to omit from the checklist.

---

## P1 — finish current-state document cleanup

`INTERIOR-MATRIS.md` is much cleaner, but section 2 still carries the historical heading `KNOWN MISMATCH A, rättad` while the document claims to describe only current state. Change it to a current status (`RESOLVED`, or equivalent) and leave history in audits/reviews.

---

## Do not do

- Do not reopen site layout, footprints, training areas or building offsets.
- Do not guess the unresolved absolute east/west spectator orientation.
- Do not resolve the open sarg-vs-läktarfront contradiction by inventing a compromise.
- Do not hand-copy roof geometry numbers into Roblox if those facts belong in the shared exported model.

## Required handoff for Review 11

Return with:
1. implementation SHA(s),
2. proof that `Ridbanan 20x60` reads shared `R.sandFarg`,
3. explicit inventory of the Roblox ridhus roof objects actually produced,
4. shared/export path for any newly ported roof facts,
5. falsified parity tests for sand and roof data consumption,
6. corrected `RIDHUS-STUDIO-CHECKLISTA.md`,
7. final current-state `INTERIOR-MATRIS.md`,
8. six specs green + export check + `webbkoll` green.

If those pass, **Review 11 should be the code gate to Studio**, not another broad geometry pass.

**Merge:** blocked.
