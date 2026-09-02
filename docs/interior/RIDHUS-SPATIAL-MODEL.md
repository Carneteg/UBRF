# Ridhuset — Interior Spatial Model v0.2

Status: **DRAFT FOR TOBIAS REVIEW**  
Implementation: **PAUSED** until this model is approved.

This file is the readable spatial model for Ridhuset. Machine-readable contract: `references/interior/ridhus-spatial-canon.json`.

## Rule

This model records **connections**, not plausible room arrangements. Repeated furniture, similar doors or a single plan symbol may not be used to invent adjacency.

Classes: `VERIFIED`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP`, `CONTRADICTION`.

---

## Level R0 — arena / ground system

### Arena
- 20 × 60 m — `VERIFIED`.
- White sarg around arena — `VERIFIED`.
- Stallhuset horse passage connects into the arena system at the shared middle — `VERIFIED` topology; exact width remains open.

### Public entrance / club volume
- A real entrance/room volume exists at the café/parking gable — plan-supported.
- Entering from outside must **not** place the player directly on the riding surface.
- Exact sequence `exterior entrance → hall → bleacher access / other rooms` is still `REFERENCE GAP`.

### Forbidden
- No freestanding café stair may be placed on Stallhuset ground floor.
- No public entrance may be simplified to `outside → arena` unless new evidence proves it.

---

## Level R1 — spectator / bleacher system

### Bleachers
`VERIFIED` from multiple photos/video frames:
- stepped timber seating;
- not a single flat platform;
- walkable upper edge;
- a separate narrow walkway behind/along the seating with plywood floor and railing toward arena;
- a stair/stepped access connects ground/arena system to spectator level;
- judge booth stands on the spectator structure;
- H dressage letter is on the sarg by this long side.

Open geometry:
- exact row count;
- exact full longitudinal extent;
- exact dimensions of walkway and access stair.

### Horse-passage break
The Stallhuset-to-Ridhuset horse connection requires a break through the spectator-side system. Exact gap width remains `ASSUMPTION`; the existence of a traversable break is topology, not decoration.

---

## Level R2 — C short-end upper glazed system

### C block
`VERIFIED`:
- spectator seating below;
- glazed room band above;
- **two** straight dark-timber stairs rising from spectator level;
- rails on both sides of stair;
- white central wall between the pair;
- round white clock between stairs;
- thin eight-point line star left of left stair;
- glazed band is segmented by timber posts and broken by the stair structures.

### Canonical vertical circulation

`R1 spectator/bleacher level → C left/right stair → R2 upper corridor`

This is the correction that invalidates the white freestanding `STALLINNE.trappa` introduced in PR #73.

### Upper corridor
`VERIFIED`:
- runs directly alongside arena;
- arena side is open/railed, not a full wall;
- glazed internal partitions are on the room side;
- a white door is visibly adjacent, but its destination is unknown;
- a dark-timber stair descends from this corridor.

### Café Krubban
`VERIFIED`:
- accessed from upper corridor through glazed partitions;
- visible café furniture;
- pentry with light cupboards/worktop/fridge;
- arched window;
- boards with `Krubban` / `Välkomna till Ca…` evidence.

Canonical chain:

`Ridhus system → spectator level → C stair → upper corridor → Café Krubban`

### H-corner stair
A separate stair/glazed element exists at H — `VERIFIED` existence. Its destination and whether it joins the C upper circulation are `REFERENCE GAP`.

---

## Club / changing cluster — existence and proven edges

The source set proves a substantial club/changing complex, but it does **not** prove a neat ordered floor plan. We therefore model nodes and only proven edges.

### Locker corridor
`VERIFIED`:
- one long locker/changing corridor is seen from both directions;
- locker rows and recurring red chairs identify the same corridor;
- internal glazed partitions run along it;
- the corridor terminates at a **glazed entrance partition with sidelights and exit sign**.

Proven edge:

`locker corridor → glazed entrance partition`

Also proven:

`locker corridor ↔ unknown glazed room suite`

The identity of the rooms behind those glass panels is not fixed.

### Separate narrow three-door corridor
`VERIFIED` existence:
- three white inner doors;
- a glass double-door at the end.

**Do not merge this with the locker corridor.** Similar glass doors are not evidence that they are the same corridor. Their relationship is `REFERENCE GAP`.

### Changing / locker rooms
At least these distinct spaces exist:
- changing room with arched window — `VERIFIED`;
- changing room with structural pillar and lockers — `VERIFIED`;
- changing room with armchairs/sofa and colored lockers — `VERIFIED`;
- green-locker zone — `VERIFIED` existence, room membership unresolved.

Proven local edges only:
- arched-window changing room has an open connection to an adjacent room containing red patterned chairs; destination identity unresolved;
- pillar changing room has a door to a smaller inner room; function unresolved.

**No source proves the order of these changing rooms along a corridor.**

### Hygiene rooms
Existence is photo-supported for at least:
- large WC;
- small WC;
- shower/WC.

Their room-to-room adjacency is `REFERENCE GAP`.

### Black exit-door zones
Two source views show black exit doors in materially different surroundings.

Status:
- door zone A — `VERIFIED`;
- door zone B — `VERIFIED`;
- whether they are the same physical door — `CONTRADICTION / unresolved`.

Claude must not collapse them into one door without new connecting evidence.

---

## Upper descending stair / obstacle storage

Photo sequence supports:
- a dark-timber stair descending from the upper corridor — `VERIFIED`;
- obstacle storage exists with concrete floor, poles and standards — photo-supported.

The source review itself did not fully human-verify that these two observations are one exact continuous chain. Therefore:

`upper corridor → descending stair` = `VERIFIED`  
`descending stair → obstacle storage` = `REFERENCE GAP` pending stronger continuity proof.

Do not hard-code the second edge yet.

---

## Known graph v0.2

```text
STALLHUSET
   │
   └── horse passage ──> RIDHUS ARENA SYSTEM
                            │
                            ├──> spectator / bleacher access
                            │        │
                            │        ├── stepped seating
                            │        ├── behind-bleacher walkway
                            │        ├── judge booth
                            │        │
                            │        ├── C stair LEFT ──┐
                            │        └── C stair RIGHT ─┤
                            │                           v
                            │                    UPPER CORRIDOR
                            │                       │   │   │
                            │                       │   │   └── descending stair → ?
                            │                       │   └── white door → ?
                            │                       └── Café Krubban
                            │
                            └── public entrance/club volume
                                  └── exact route to spectator system = GAP

CLUB/CHANGING GRAPH — exact placement in the building remains partly open

GLAZED ENTRANCE <── LOCKER CORRIDOR ──> UNKNOWN GLAZED ROOM SUITE

NARROW THREE-DOOR CORRIDOR   [relation to locker corridor = GAP]

ARCHED-WINDOW CHANGING ROOM ──> adjacent red-chair room [?]
PILLAR CHANGING ROOM ──> small inner room [?]
ARMCHAIR CHANGING ROOM         [adjacency = GAP]
GREEN LOCKER ZONE              [room membership = GAP]
LARGE WC / SMALL WC / SHOWER-WC [adjacency = GAP]
```

---

## Hard invariants for implementation

1. C short end has **two stairs**, not one.
2. Those stairs start from **Ridhus spectator level**, never Stallhuset ground floor.
3. Bleachers are stepped.
4. Upper corridor is physically related to the arena by an open/railed edge.
5. Café Krubban is accessed from the upper corridor through glazing.
6. H-corner stair is a separate stair until proven otherwise.
7. Locker corridor terminates at a glazed entrance partition.
8. Similar doors, furniture or corridors are **not** proof of identity or adjacency.
9. Existence of rooms does not grant permission to invent their order.
10. Exterior remains locked.

---

## What Tobias still needs to approve

For v0.2, review the **relationships**, not dimensions:
- Is the C-stair / spectator / café chain described correctly?
- Is the long locker corridor the right conceptual anchor for the club/changing section?
- Do you recognize any relationship among the changing rooms / toilets that the photos do not prove?

Until such a correction is supplied, every unresolved relationship stays a gap and Claude may not fill it.
