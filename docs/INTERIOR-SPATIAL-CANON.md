# UBRF Interior Spatial Canon

Status: **DRAFT FOR PRODUCT OWNER REVIEW**  
Owner: Tobias / Product Owner  
Architecture review: ChatGPT  
Implementation: Claude **only after this canon is approved**

This document defines the interior spatial truth Claude must implement. It is deliberately separate from implementation code.

## Hard rule

No agent may infer a room, stair, corridor, connection or floor transition from a single plan symbol when photo/video evidence gives a clearer circulation chain.

Source order for interior topology:
1. Tobias explicit correction
2. Cross-confirmed photo/video circulation
3. Evacuation plan topology
4. Building cards / matrices as evidence index
5. Existing implementation only as something to compare against

Classification: `VERIFIED`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP`, `CONTRADICTION`.

A `REFERENCE GAP` is not permission to invent geometry.

---

# Ridhuset — Spatial Canon v0.1

## 1. Core spatial reading

Ridhuset is not a single arena volume with a staircase placed directly on the arena floor. It is a layered building with arena level, spectator/bleacher level and an upper glazed club/café level.

The key circulation correction from Tobias is binding:

> The staircase shown in the current preview exists in reality, but it is reached **via the ridhus bleachers**, not as a freestanding ground-level stair in Stallhuset.

This is supported by the repository photo/video inventory:
- `ridhus-inne-08-laktartrappan.jpg`: camera is in the stair between bleachers and glazed rooms; straight dark-timber stair with rails on both sides.
- `ridhus-inne-09-laktartrappan-underifran.jpg`: same stair from below; terminates at glazed area / white door.
- `ridhus-klubb-10-overvaningens-gang.jpg`: camera on upper corridor, arena open to the side, dark timber stair descending.
- `ridhus-inne-01-glasrummen.jpg` + film keyframes `IMG_0192-f01/f02`: C short-end block with **two** stairs, glazed rooms above and bleacher seating below.

Therefore the standalone `STALLINNE.trappa` introduced in PR #73 is **not canon**.

## 2. Spatial layers

### R0 — arena / ground level

**Verified / stable**
- Arena is 20 × 60 m (`VERIFIED`, Product Owner + plan).
- White kickboard/sarg surrounds arena (`VERIFIED`).
- Long-side spectator structure exists along one side (`VERIFIED`).
- Horse passage from Stallhuset enters through the shared mid-building connection and creates a break in the spectator structure (`VERIFIED` topology; exact gap width remains `ASSUMPTION`).
- Entrance/club volume occupies the café/parking gable and is materially deeper than a 3 m overlay (`PLAN`). Exact room subdivision remains partly unresolved.

**Do not infer**
- Do not place a new stair on open arena/ground floor merely because a plan contains a stair symbol.
- Do not make the public entrance discharge directly onto the arena; plan evidence says there is an entrance/room volume first.

### R1 — bleacher / spectator level

This is an elevated circulation layer, not merely furniture.

**Verified**
- Bleachers are stepped timber seating, not one flat deck.
- A walkable upper edge / walkway exists.
- A separate narrow walkway behind/alongside the bleacher rows exists, with plywood floor and railing toward the arena.
- There is a stair connection between arena/entrance level and the bleacher seating level.
- A judge booth/tower is located on the bleacher structure.
- Dressage letter H is on the sarg by the bleacher long side.

**Reference gaps**
- Exact number of seating rows.
- Exact full longitudinal extent of the bleachers.
- Exact dimensions of the behind-bleacher walkway.

### R2 — C short-end glazed level / café corridor

**Verified topology**
- The C short end has a spectator block below and glazed rooms above.
- **Two straight dark-timber stairs** rise from the bleacher/spectator level to the glazed upper level.
- The two stairs flank a white central wall.
- One white round clock is on the central wall between the two stairs.
- A thin line-drawn eight-point star/compass motif sits left of the left stair.
- The glazed band is segmented by dark/brown timber posts and is interrupted by the stair structures; it is not one uninterrupted dark strip.
- The upper corridor runs immediately beside the arena, with a railing/open edge toward the arena.
- Café Krubban is accessed from this upper corridor through glazed partitions.
- Café function is `VERIFIED` by Tobias and reinforced by photos showing café furniture, pentry and "Krubban" / "Välkomna till Ca…" boards.

**Canonical circulation chain**

`Ridhus entrance / arena system → bleacher access → bleacher level → C-block stair → upper glazed corridor → Café Krubban`

The exact route from the public exterior entrance to the bleacher-access stair is not yet fully geometrically fixed. That segment remains a `REFERENCE GAP`; the rest of the chain above is stable.

### R2-H — separate H-corner stair / glazed part

A third stair/glazed element exists by the H corner, separate from the C short-end pair (`VERIFIED`).

What it serves exactly and how it connects to the upper club circulation is not yet proven. Keep as `REFERENCE GAP` for destination/topology beyond the visible stair itself.

## 3. Club / changing-room cluster

Photo/video evidence verifies that the ridhus contains a substantial club section, not generic filler rooms.

Verified components include:
- a long locker/changing corridor, seen from both directions;
- glazed internal partitions along that corridor;
- at least three physically distinct changing/locker spaces;
- at least three toilet/hygiene rooms shown in source imagery;
- at least two black emergency-exit doors in the club section;
- an upper glazed café corridor adjacent to the arena;
- café room with pentry, tables, chairs, sofa and glazed wall;
- obstacle storage / equipment areas are photo-supported, but the exact stair-to-storage adjacency is not yet promoted to full canon.

**Important:** existence is verified more strongly than exact room-to-room topology. Claude must not arrange these rooms merely to make a plausible clubhouse. Their adjacency map must be established before coding them.

## 4. Known connections

| From | To | Connection | Class | Build status |
|---|---|---|---|---|
| Stallhuset | Ridhuset arena system | horse passage at shared middle | `VERIFIED` topology | allowed |
| Arena/entrance level | bleacher level | stair / stepped access | `VERIFIED` | allowed, exact dimensions open |
| Bleacher level | C upper level | two dark timber straight stairs | `VERIFIED` | allowed |
| C upper level | upper corridor | direct landing | `VERIFIED` | allowed |
| Upper corridor | Café Krubban | glazed internal access | `VERIFIED` | allowed |
| Upper corridor | arena view | open/railed edge | `VERIFIED` | allowed |
| Bleacher long side | judge booth | booth stands on spectator deck | `VERIFIED` | allowed |
| H-corner stair | unknown upper destination | visible stair/glazing | `REFERENCE GAP` | defer destination |
| Upper stair / storage relation | obstacle storage | photo-supported but not fully human-verified as one exact chain | `REFERENCE GAP` | defer exact adjacency |

## 5. Forbidden interpretations

Until Tobias changes this canon, Claude must **not**:
- reintroduce a separate `STALLINNE.trappa` to represent the stair shown in the preview;
- connect the visible café/upper-level stair directly from Stallhuset ground level;
- collapse the two C stairs into one generic stair;
- turn the stepped bleachers into a flat platform;
- place Café Krubban as an isolated room without the upper corridor and glazed relationship to the arena;
- invent exact layout for the six/club rooms whose adjacency is not yet proven;
- use existing implementation coordinates as evidence for missing topology.

## 6. Current implementation comparison

Current `main` already contains an important part of the correct Ridhus model in `RIDHUSINNE.kortanda.trappor`: the C short-end pair is represented as two stairs. Web and Roblox consumers also contain builders for those shared values.

PR #73 introduced a second, unrelated `STALLINNE.trappa`. That addition is a source-reading error and must be removed before F02-A can pass.

## 7. Next canon work before Claude resumes

1. Lock a room/adjacency model for the ridhus entrance + locker/changing cluster.
2. Lock Stallhuset Plan 1 as its own spatial graph, explicitly separating it from Ridhus circulation.
3. Resolve what can be said about Stallhuset Plan 2 without inventing geometry.
4. Only then issue an implementation brief to Claude.

No furniture phase (F02-B) begins before these spatial graphs are approved.
