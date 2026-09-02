# UBRF — Facility Interior Spatial Overview v0.1

Status: **DRAFT FOR TOBIAS REVIEW**  
Implementation: **PAUSED** until Product Owner approval.  
Scope: Stallhuset + Ridhuset + shared circulation interfaces.

This document is the facility-level pre-code topology map. It does not replace the building-specific models; it composes only relationships already supported by them and prevents Claude from solving local gaps by inventing cross-building geometry.

Authoritative readable sources on this branch:
- `docs/interior/STALLHUS-SPATIAL-MODEL.md`
- `docs/interior/RIDHUS-SPATIAL-MODEL.md`
- `docs/interior/FACILITY-SPATIAL-INTERFACES.md`

Machine-readable contracts:
- `references/interior/stallhus-spatial-canon.json`
- `references/interior/ridhus-spatial-canon.json`
- `references/interior/facility-spatial-interfaces.json`
- `references/interior/facility-spatial-overview.json`

---

## 1. Facility rule

The facility is one spatial system. A building-local model may not independently create a second version of a shared corridor, entrance, stair or horse passage.

Evidence remains isolated by building unless a source explicitly crosses the boundary. Similar furniture, doors, windows or room functions are not enough to move evidence from Ridhuset to Stallhuset or vice versa.

The accepted exterior is locked and is not re-derived by this interior model.

---

## 2. Shared cross-building interface

### STALL_TO_RIDHUS_HORSE_PASSAGE

Classification: `VERIFIED_TOPOLOGY`  
Exact opening geometry / full visual identity: `PARTIAL_REFERENCE_GAP`

Canonical identity:

`stallhus:horse_passage ↔ ridhus:horse_passage`

This is one continuous horse-walkable facility connection.

Allowed topology:

`Stallhuset transverse/middle circulation → shared horse passage → Ridhuset arena system`

Not allowed:
- a second hidden corridor added for pathfinding;
- naming `stall-inne-08-breda-gangen.jpg` as this exact passage without connecting evidence;
- separate handwritten Web and Roblox passage coordinates;
- deriving missing dimensions from current implementation.

---

## 3. Stallhuset — safe movement graph

### Club side

`EXTERIOR → club entrance → club circulation zone → box-hall access → aisle A / aisle B`

Confidence:
- exterior → entrance: `VERIFIED / PRODUCT BASELINE`;
- entrance → club circulation zone: `VERIFIED_PLAN_PHOTO`;
- club circulation zone → box-hall access → stall aisles: `DERIVED_PLAN_CIRCULATION`.

This proves continuity through the Stallhuset shell. It does **not** prove the exact room one crosses or exact door widths.

Known club-room nodes:
- uppehållsrum — `VERIFIED`, exterior-facing;
- pentry — `VERIFIED`, exterior-facing;
- teorisal — `VERIFIED`, exterior-facing;
- sadelkammare — `VERIFIED` existence;
- toilets x2+ — `VERIFIED` existence.

All exact named-room order and door adjacency remains `REFERENCE_GAP`.

### Box hall

Hard topology:

`outer row → aisle A → inner row || inner row → aisle B → outer row`

The two inner rows are back-to-back on a central spine. A transverse/middle circulation crosses the system.

Safe continuation:

`aisle A / aisle B ↔ transverse corridor → shared horse passage → Ridhuset`

### Service end

Safe chain:

`box hall → service opening → open service/through zone → service gable exit → exterior`

Known local nodes include spolspilta and bedding/shavings open bay. Exact spolspilta boundary remains partly open.

### Deferred Stallhuset relations

Do not build as factual geometry yet:
- named club-room order;
- exact club-room door graph;
- Plan 1 straight-stair access/destination/visual identity;
- Plan 2 room graph and internal access;
- identity/destination of the wide high gated corridor;
- exact visual identity and width of the shared horse passage.

---

## 4. Ridhuset — safe movement graph

### Arena / ground system

Shared horse route:

`Stallhuset shared horse passage → Ridhuset horse_passage → arena system`

Public route:

`EXTERIOR → public entrance / club volume → ? → spectator/other internal system`

The public entrance exists, but the exact internal route from it remains `REFERENCE_GAP`. It must not be simplified to `outside → riding surface`.

### Spectator system

Safe chain:

`arena system → stepped spectator/bleacher access → bleacher level`

Known R1 relations:
- stepped timber seating;
- behind-bleacher walkway;
- judge booth;
- C-left stair and C-right stair both begin from the spectator system.

### C short-end upper system

Canonical vertical chain:

`bleacher level → C-left stair / C-right stair → upper corridor → Café Krubban`

The two C stairs are real, separate and dark timber. They are not Stallhuset stairs.

Upper corridor also has:
- white door → destination `REFERENCE_GAP`;
- descending dark-timber stair → destination after stair `REFERENCE_GAP`;
- arena-facing open/railed edge.

### Club/changing cluster

Safe local edges only:

`locker corridor → glazed entrance partition`

`locker corridor ↔ unknown glazed room suite`

`arched-window changing room → adjacent red-chair room [identity GAP]`

`pillar changing room → small inner room [function GAP]`

Verified existence but unresolved ordering:
- separate narrow three-door corridor;
- armchair changing room;
- green locker zone;
- large WC;
- small WC;
- shower/WC;
- black exit-door zone A;
- black exit-door zone B.

Do not convert this list into a neat corridor sequence without new connecting evidence.

---

## 5. Facility movement map

```text
                           UBRF FACILITY INTERIOR

STALLHUSET

EXTERIOR CLUB SIDE
       │
       v
 CLUB ENTRANCE
       │
       v
 CLUB CIRCULATION ZONE
   ├── uppehållsrum [edge/order GAP]
   ├── pentry        [edge/order GAP]
   ├── teorisal      [edge/order GAP]
   ├── sadelkammare  [edge/order GAP]
   └── WC x2+        [edge/order GAP]
       │
       │ DERIVED_PLAN_CIRCULATION
       v
 BOX-HALL ACCESS
       │
       ├──────────── AISLE A ────────────┐
       │                                 │
       └──────────── AISLE B ────────────┤
                                         v
                              TRANSVERSE / MIDDLE
                                  CIRCULATION
                                         │
                                         v
                         SHARED HORSE PASSAGE
                           [ONE FACILITY INTERFACE]
                                         │
════════════════════ BUILDING BOUNDARY ══╪════════════════════
                                         │
                                         v
RIDHUSET                            HORSE_PASSAGE
                                         │
                                         v
                                   ARENA SYSTEM
                                    │         │
                                    │         └── PUBLIC ENTRANCE / CLUB VOLUME
                                    │                 └── route inward = GAP
                                    v
                              SPECTATOR ACCESS
                                    │
                                    v
                               BLEACHER LEVEL
                         ┌──────────┼──────────┐
                         │          │          │
                    judge booth   walkway   C stair pair
                                               │
                                  ┌────────────┴────────────┐
                                  v                         v
                              C LEFT                     C RIGHT
                                  └────────────┬────────────┘
                                               v
                                        UPPER CORRIDOR
                                     ┌─────────┼─────────┐
                                     │         │         │
                                     v         v         v
                              CAFÉ KRUBBAN  white door  down stair
                                             → GAP       → GAP

STALLHUSET SERVICE ROUTE

BOX HALL → SERVICE OPENING → OPEN SERVICE ZONE → SERVICE GABLE EXIT → EXTERIOR
                              ├── spolspilta [boundary partly GAP]
                              └── bedding open bay

RIDHUSET CLUB / CHANGING — LOCAL EDGES ONLY

GLAZED ENTRANCE ← LOCKER CORRIDOR ↔ UNKNOWN GLAZED ROOM SUITE

NARROW THREE-DOOR CORRIDOR                  [relation = GAP]
ARCHED-WINDOW CHANGING → RED-CHAIR ROOM     [identity = GAP]
PILLAR CHANGING → SMALL INNER ROOM           [function = GAP]
ARMCHAIR CHANGING                            [adjacency = GAP]
GREEN LOCKER ZONE                            [membership = GAP]
WC / WC / SHOWER-WC                          [order = GAP]
BLACK EXIT A vs BLACK EXIT B                 [identity = CONTRADICTION]
```

---

## 6. Implementation permission matrix

### ALLOWED in F02-A after Product Owner approval

Claude may encode shared topology for:
- Stallhuset club-zone continuity to box hall;
- four box rows / two aisles / central spine;
- transverse circulation;
- open service chain to gable exit;
- one shared Stallhuset↔Ridhuset horse passage interface;
- Ridhuset arena → spectator system;
- stepped bleachers and behind-bleacher walkway as structural nodes;
- C-left + C-right stair pair;
- upper corridor;
- Café Krubban access from upper corridor;
- verified local locker/changing edges explicitly listed above.

### DEFER

Claude must leave unresolved rather than invent:
- Stallhuset named club-room ordering and door placement;
- Stallhuset Plan 1 straight-stair implementation;
- Stallhuset Plan 2 room layout;
- exact wide-gated-corridor destination;
- Ridhuset public entrance inward route;
- order of Ridhuset changing/WC rooms;
- relationship between locker corridor and narrow three-door corridor;
- H-corner stair destination;
- descending upper stair destination beyond the proven stair itself;
- exact horse-passage width/material geometry;
- any furniture beyond F02-A topology scope.

---

## 7. Shared implementation rule

After approval, `src/site.js` remains the single spatial truth consumed by both Web and Roblox. Claude may extend the schema/exporter as needed, but may not create an independent handwritten Roblox room graph.

Required flow:

`source-backed canon → src/site.js → tools/exportera-geometri.js → generated UBRFKomplex.luau → Web + Roblox consumers/tests`

If a topology fact cannot be represented in this shared flow without inventing dimensions, preserve the node/edge as deferred metadata rather than fabricating geometry.

---

## 8. Product Owner review target

Review relationships, not centimeter measurements.

Approval means:
- this is the correct facility movement skeleton to start F02-A implementation from;
- unresolved edges stay unresolved;
- exterior remains locked;
- furniture remains F02-B.

Approval does **not** mean all interiors are visually finished or that every room has a final position.
