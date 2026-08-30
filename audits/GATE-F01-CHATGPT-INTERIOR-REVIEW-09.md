# Gate F01 — ChatGPT Senior Interior Fidelity Review 09

**Reviewed head:** `cfdb89a76a97493903743b595a14db055873213a`

**Status:** `CHANGES REQUIRED`

This review supersedes ridhus visual conclusions made from web evidence before commit `110bb52`, because Claude proved that a caught `ReferenceError` stopped most of `v3dRidhus` from building while previous QA still reported green.

## Accepted

### 1. Web regression root cause and QA fix

Accepted. `110bb52` identifies the real failure (`L is not defined` outside the old spectator-loop scope), fixes it by reading `R.laktare.dackZ`, regenerates the evidence images, and adds `tools/webbkoll.mjs` so caught warnings such as `3D-vandring misslyckades` cannot silently pass as green again.

This is a genuine methodology improvement. Older web screenshots from the broken period are not valid fidelity evidence.

### 2. Current web C-end correction

Accepted for progression, subject to final visual/Studio acceptance. Current shared/web data now represents:
- C-end stepped spectator block,
- two stairs,
- segmented glazing with posts,
- raised white wall zone between seating and glazing,
- round clock between the stairs,
- line-drawn compass rose,
- verified C bicycle / E elephant pictogram facts documented even though not drawn at current scale.

### 3. Orientation handling

Accepted. The unknown long-side orientation remains `REFERENCE GAP / working orientation`; no speculative mirror is required. The data architecture is now mirrorable through `RIDHUSINNE.sidor`, including arena position, spectator side, panel side, judge booth, mirrors, café clock and stair.

## P0 BLOCKER — Roblox still renders the old ridhus identity

The shared data is ahead of the Roblox builder. This means the current proof package demonstrates the web implementation, not the Roblox-primary player experience.

### A. Maroon upper wall is wrong in Roblox

`roblox/buildings/Anlaggningen.luau::byggRidhusIdentitet` still explicitly builds the maroon upper wall on **BOTH long sides**, for almost the **FULL hall length**:

- loops over both x sides,
- ignores `IDENTITET.ridhus.ovreVagg.sida`,
- ignores `ovreVagg.y0/y1`,
- builds `R.langd - 1` metres of panel and white battens.

This directly contradicts the current verified fact: maroon/rust panel exists on **PART of ONE long side**, with the rest of that wall light.

**Required:** make the Roblox renderer consume the same `ovreVagg.sida`, `y0`, `y1`, lists/battens and associated window-band relationship as the web implementation. No duplicate hard-coded layout.

### B. Sponsor signs are missing from Roblox rendering

The shared/exported data contains the sponsor-sign definitions and their panel-relative positions, but the Roblox builder does not render them. These signs are a verified high-recognition visual feature of the photographed long wall.

**Required:** render the sponsor boards on the panel side from exported shared data. Platform rendering may simplify typography/logos, but their number/order/placement relationship must follow the source-backed data and must not invent unsupported branding geometry.

### C. Current C-end correction is not complete in Roblox

The Roblox `byggRidhusInre` builds:
- stepped block,
- stairs,
- segmented glazing and posts.

But the latest verified/derived C-end details added in `cfdb89a` are not all rendered by the Roblox builder:
- the visible white wall zone introduced by `glasOver = 1.6` is not explicitly built as the correct interior surface,
- the C-end round clock is not built from `kortanda.klocka`,
- the line-drawn compass rose is not built from `kortanda.stjarna`.

Simply moving the glass upward is not parity if the resulting gap exposes the wrong shell material or remains visually empty.

**Required:** build the C-end wall/clock/compass-rose identity in Roblox from the exported `kortanda` data. Keep exact dimensions classified according to the matrix (`VERIFIED`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP`).

### D. Parity tests are too weak for the current problem

All six specs can be green while the Roblox builder still paints both long walls maroon and omits C-end identity details. Therefore the current tests do not falsify the player-visible parity errors above.

**Required tests should assert relationships, not copied literals:**
1. exactly one long side receives the maroon panel;
2. panel extent follows shared `ovreVagg.y0/y1`, not full hall length;
3. window band and sponsor boards resolve onto the same configured panel side/relationship;
4. C-end clock resolves between the two stairs;
5. C-end glass remains segmented by stair breaks;
6. if compass rose is rendered on Roblox, it resolves to the configured C-end wall zone;
7. mirror test (`E/W -> W/E`) still passes without stale Roblox-only geometry.

## P1 — clean stale documentation after the renderer is fixed

`references/buildings/ridhus/INTERIOR-MATRIS.md` still contains historical/stale wording in its current-state document, including:
- section heading `KNOWN MISMATCH B, delvis` even though the window band has been implemented,
- sponsor section says `kopplingen saknas` while a later paragraph says the coupling was fixed,
- a later `Känd lucka` says mirrors / `klocka.x` do not follow mirroring even though current `site.js` derives them through `RIDHUSINNE.sidor`.

After the Roblox fix, rewrite the matrix so each fact has one current status only. Keep historical mistakes in the audit/review history, not in the current-state matrix.

## Do not do

- Do not reopen site-layout or building-footprint work in this pass.
- Do not resolve the unknown east/west spectator orientation by guessing.
- Do not tune unsupported dimensions simply to make a screenshot look nicer.
- Do not call Gate F01 or the ridhus interior complete before Roblox Studio visual verification.

## Required handoff for Review 10

Claude should return with:
1. implementation SHAs,
2. diff summary for `Anlaggningen.luau` + exporter/shared data only where needed,
3. parity tests proving the rules above,
4. refreshed current-state `INTERIOR-MATRIS.md`,
5. new web evidence only if web changed,
6. a Roblox Studio-ready view/checklist that specifically checks:
   - partial maroon panel on one side only,
   - sponsor wall,
   - window band,
   - C-end seating/stairs/glazing/white wall/clock/compass rose,
   - E judge booth + stair/rails/exit,
   - roof timber/steel/cable ladders/ventilation.

**Next review:** ChatGPT Senior Interior Fidelity Review 10.

**Merge:** blocked.
