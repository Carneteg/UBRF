# Gate F01 — ChatGPT Senior Site Fidelity Review 05

Status: **CHANGES REQUIRED**
Reviewer: ChatGPT — Senior Game Developer / Environment Fidelity Reviewer
Date: 2026-08-30
Reviewed PR: #22
Reviewed head: `958c32035becc2b5b274c7eb5353a119db3c500d`

## Executive verdict

Claude handled the Product Owner's measurement correction correctly at the implementation level: the retracted `29.28`, `26.57`, and `39.83` values are no longer used as verified geometry. The measured long-axis constraints `69.95` and `77.18` remain, and `8.10` is retained as a local-gap constraint with uncertainty northward.

However, Gate F01 is **not ready**. The current branch still violates the source contract and Issue #23 stop condition in four material ways: stale contradictory source text remains, the stable interior has not been re-audited against the correctly classified stable images, the riding-hall spectator geometry is only partially corrected, and the training-area mapping remains unresolved/provisional despite the Product Owner explicitly identifying its placement as wrong.

PR #22 must not be merged yet.

---

## What passes in this round

1. `29.28 m` is no longer treated as verified stable width. Stable width is back to a provisional `21 m [REFERENCE GAP]`.
2. `26.57 m` is no longer treated as verified riding-hall width. Riding-hall width is back to a provisional `25 m [REFERENCE GAP]`.
3. `39.83 m` is no longer treated as a measured horse-passage offset. The passage location is explicitly derived/reference-gap.
4. Stable long-axis extent `69.95 m` and riding-hall long-axis extent `77.18 m` remain measured constraints with map tolerance.
5. `8.10 m` is retained as a `MEASURED LOCAL GAP`, with the code explicitly acknowledging that constant spacing northward is an assumption.
6. Shared web→Roblox canonical export remains intact.
7. The riding-hall fixes for the solid dark spectator front, partial maroon wall and sponsor-sign grouping are meaningful improvements and should be kept.

---

## BLOCKER A — Source cleanup after the measurement retraction is incomplete

The code values were corrected, but the repository still contains text that states the retracted facts as if they were current truth.

### `src/site.js`

Inside `STALLINNE`, the comment still says:

- `VERIFIED 29,28 m` for the stable width, even though `STALL_BREDD` is correctly back at `21 [REFERENCE GAP]`.
- the box-grid comment still says the cross-corridor / passage location is "mätt (39,83 m från ridhusets södra gavel)", even though `39.83` has been explicitly retracted.

The file also contains older introductory dimensions such as `+x öster (bredd 15), +y norr (längd 52)`, which no longer describe the active stable model.

These comments are not harmless: `CLAUDE.md` makes repository source material part of the future agent source chain. A future implementation agent can re-lock the same false values from these stale comments.

### `references/SITEPLAN.md`

The current file still contains an obsolete scale argument saying approximately:

- riding hall `75 m` from pixel scale,
- stable `54 m` from the same pixel scale,
- "two independent routes to the same number".

That is superseded by the later Product Owner measurements `77.18` and `69.95`.

The placement table is also internally stale in several rows. Examples:

- `Gårdarna mellan husen` still says `143–154` / `11 m`, while the current model uses the local `8.10 m` separation and stall x≈151.10.
- `Gången öster om stallet` still uses the old coordinate `175` despite the current derived stall east edge being different.
- `Låga längan` still lists the old position `147 / 59`, while the code comment says it now sits around `y 43..49` as an unresolved assumption.

### Required change

Perform a repository-wide source cleanup for the retracted/superseded measurements. Search at minimum for:

`29.28`, `29,28`, `26.57`, `26,57`, `39.83`, `39,83`, `54 m`, `75 m`, `11 m`, old `143–154` yard coordinates, and comments that label those as verified/measured.

Keep historical discussion only inside clearly marked **SUPERSEDED / RETRACTED** sections. Active code comments, SITEPLAN tables, cards and audits must describe current truth consistently.

---

## BLOCKER B — Stable interior still fails Issue #23 stop condition

Issue #23 requires a stable-interior fidelity pass against the correctly classified stable image set:

- `IMG_0159`
- `IMG_0160`
- `IMG_0161`
- `IMG_0162`

The current `audits/GATE-F01-INTERIOR-REAUDIT-2026-08-30.md` explicitly states:

> `Stallinteriören (issue #23 punkt 2) är inte heller omgranskad ännu mot IMG_0159–0162.`

Therefore this is not an inference: the required work is explicitly unfinished.

### Required change

Run the stable pass image-by-image and compare both web and exported Roblox geometry against at least:

- box-front material/design and lower solid panel vs galvanized upper rail/grille,
- aisle width/readability,
- four-row/two-aisle plan topology,
- cross-corridor relationship,
- exposed timber roof structure,
- ceiling/roof sheet character,
- lighting/overhead services,
- floor and lower-wall character,
- end-of-aisle/door relationships.

Do not mark the stable visually resolved from planform alone.

---

## BLOCKER C — Riding-hall spectator geometry is only partially corrected

Commit `9b8d2cd` correctly fixes three things:

- solid dark spectator front,
- maroon wall only on one partial long-wall zone,
- sponsor signs grouped on that zone.

But the same re-audit explicitly says the **spectator extent is not corrected** and the short-end stair block under the glazed rooms remains a reference gap.

The audit's own direct-image finding is stronger than "we do not know the exact metres": it says the implementation had light steps along a long side while `ridhus-inne-01` shows a spectator/stair environment at the short-end/glasrum relationship. Exact dimensions may remain uncertain, but the known topological relationship must not remain knowingly wrong.

### Required change

Separate:

- **known topology/placement** from the images — implement it,
- **unknown exact lengths/step counts** — keep those as `ASSUMPTION` / `REFERENCE GAP`.

Do not leave a known wrong long-side spectator layout merely because the exact metre extent is not measured.

Re-check the full Issue #23 riding-hall list after this change: arena/sarg, maroon wall, roof structure/services, glazed rooms, spectator environment, central stair/clock and booth/stair/exit at E.

---

## BLOCKER D — Training-area/site fidelity is still unresolved

The Product Owner explicitly identified training-area placement as wrong.

Current canonical geometry still retains:

`UTEBANA = {x:176, y:119, w:20, h:40}`

and correctly labels that geometry as unsupported/provisional. The `33.57 m` measured side is also correctly *not* forced onto this object because the mapping between the measured north-east surface and the game's `uteridbanan` has not been documented.

That classification is honest — but it means the site-layout blocker remains open.

Additionally, `SITEPLAN.md` still records the raised arena terrain/sloped access as a `KNOWN MISMATCH`; the game remains flat.

### Required change

Before Gate F01 can become site-fidelity ready:

1. identify which actual satellite surface maps to each gameplay training arena/paddock;
2. document the mapping from source image → canonical object id;
3. use the clean `33.57 m` side only on the correctly identified real surface;
4. keep unresolved long-side dimensions as gaps rather than inventing them;
5. re-anchor arena/paddock positions from the satellite layout once identity is established;
6. keep the known terrain/slope mismatch explicit until either measured/implemented or consciously accepted by the Product Owner as a documented gap.

A provisional `20 × 40` rectangle at the old coordinates is not a fidelity pass merely because it is now honestly labelled `ASSUMPTION`.

---

## BLOCKER E — PR/status documentation is stale

PR #22's description still presents older state, including `25 × 75` and statements that no longer match the latest measurement correction and current implementation.

Update the PR description only after the source cleanup and fidelity work above so it reports the actual latest state rather than a historical snapshot.

---

## Roblox Studio

Roblox Studio is still not visually verified. This does not block source cleanup or implementation work, but it **does** block final visual-ready/merge acceptance under Issue #23.

After A–E are complete:

1. regenerate Roblox from shared canonical data,
2. run build/geometry/gameflow tests,
3. run the Studio visual checklist against the same reference images,
4. then hand back for **ChatGPT Senior Site Fidelity Review 06 / Product Owner visual acceptance**.

## Final status

**CHANGES REQUIRED**

The latest measurement retraction is implemented correctly, but Gate F01 remains blocked by source inconsistency, unfinished stable interior review, incomplete riding-hall spectator placement, unresolved training-area mapping/site fidelity, and the required Roblox Studio visual pass.
