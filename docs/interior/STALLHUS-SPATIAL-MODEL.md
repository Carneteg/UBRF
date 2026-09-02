# Stallhuset — Interior Spatial Model v0.1

Status: **DRAFT FOR TOBIAS REVIEW**  
Implementation: **PAUSED** until this model is approved.

This is the spatial/topology model for Stallhuset. It deliberately separates verified room existence from unverified room order.

## Hard correction after Ridhus stair review

The straight stair symbol previously read from the Stallhuset Plan 1 must **not** be instantiated as a freestanding interior Stallhuset stair merely from the plan symbol.

Tobias has corrected the visible stair in the preview: that real stair is reached via **Ridhusets läktare**. Therefore any Stallhuset straight-stair interpretation is now `REFERENCE GAP / possible source conflation` until photo/video proves an independent Stallhuset interior stair.

The exterior **spiral stair on Stallhuset's club gable is a separate verified object** and is not the Ridhus café stair.

---

## S0 — Plan 1: club end

### Public/club entrance
`VERIFIED / PRODUCT BASELINE`:
- club entrance belongs to the club end of Stallhuset;
- source imagery shows ochre/yellow entrance door and round windows associated with the club section;
- evacuation plan places `Här är du` at this end.

Canonical edge:

`exterior club entrance → Stallhuset club volume`

Exact first room/hall after crossing the threshold is not yet locked room-by-room.

### Verified rooms in club section
The following spaces **exist** in Stallhuset and are photo-verified:
- uppehållsrum;
- pentry;
- sadelkammare;
- teorisal;
- at least two toilets, one accessibility-adapted.

Distinct photo facts:
- uppehållsrum: white panel, black leather sofas, arched + round windows;
- pentry: arched + round windows, microwave, fridge, table;
- sadelkammare: boot shelving and hanging blankets/equipment;
- teorisal: long table, whiteboard, anatomy/teaching posters, round windows.

### What is NOT proven
- exact order of these rooms;
- which room is directly adjacent to the entrance;
- exact internal door graph;
- exact dimensions;
- whether pentry is a separate room or directly attached to another club room in the plan.

These stay `REFERENCE GAP`. Claude may create walls/doors only after a source-backed adjacency is added to this canon.

---

## S0 — box hall

### Core plan topology
`VERIFIED` from Plan 1:

Cross-section from one long side to the other:

`outer box row → aisle A → inner box row ↔ inner box row → aisle B → outer box row`

The two inner rows are back-to-back around a shared central spine.

### Box rows
- four longitudinal box rows — `VERIFIED`;
- two longitudinal aisles — `VERIFIED`;
- 12 boxes per row — `MEASURED` in current plan analysis;
- box width 3.5 m — `DERIVED`, not independent surveyed truth;
- whole-building width 21 m — `REFERENCE GAP` working value.

### Stall aisle identity
`VERIFIED` from many photo/video frames:
- center walking strip of paving/marksten;
- bedding/shavings strip along box fronts;
- dark anthracite lower box panels;
- galvanized upper framing/rails;
- visible timber/laminated roof structure and corrugated metal roof underside.

These are material/fidelity facts, not permission to alter topology.

### Cross corridor
A transverse corridor crosses the box hall around the middle section — `MEASURED/PLAN`.

Canonical relation:

`aisle A + central box system + aisle B ↔ transverse corridor`

The exact opening widths remain open where not measured.

---

## S0 — connection to Ridhuset

The facility contains a real indoor horse connection between Stallhuset and Ridhuset — `VERIFIED` topology.

Canonical edge:

`Stallhuset transverse/middle circulation → horse passage → Ridhuset arena system`

Important guard:
- `stall-inne-08-breda-gangen.jpg` shows a wide high indoor corridor with a barred/gated end.
- That corridor **may not automatically be called the horse passage**, because the image does not prove its destination.

Therefore:
- existence of horse passage = `VERIFIED`;
- exact visual identity of `stall-inne-08` as that passage = `REFERENCE GAP`.

Claude must not merge those facts without connecting evidence.

---

## S0 — service end

The end opposite the club section is a service/circulation zone.

### Verified spatial character
- it reads as an **open through-passage/service room**, not a set of invented closed rooms;
- an opening connects it back into the box hall;
- a gable exit leads directly outside and has daylight + green exit sign;
- concrete/light service floor around wash/service hardware, with paving continuing in circulation strip;
- visible pipework and wall equipment;
- freestanding galvanized wash/tie bars;
- stacked bedding/shavings bags in an open bay.

### Spolspilta
A real wash stall / spolspilta exists — `VERIFIED`.

Photo evidence shows:
- raised/ridged floor with drainage fall;
- hot-water/heater and pipes;
- hose fittings.

Its exact boundary inside the full service-end plan remains partially open.

### Canonical service chain

`box hall → service opening → open service/through zone → south/service gable exit → exterior`

This is stronger than treating the service end as generic rooms.

---

## Unknown wide corridor

`stall-inne-08-breda-gangen.jpg` / related frames prove a broad tall corridor with a barred/gated section.

Node status: `VERIFIED EXISTENCE`.

Destination/status: `REFERENCE GAP`.

Forbidden interpretation:
- do not label it `horse passage to Ridhuset` merely because it is horse-sized.

---

## S1 — Plan 2 / upper club level

### What is proven
- Stallhuset has an upper club-end level / upper door presence — exterior imagery and the exterior spiral stair support this;
- the exterior spiral stair on Stallhuset club gable is real and separate from Ridhus stairs.

### What is not proven enough to build
- complete Plan 2 room graph;
- internal stairs serving Plan 2;
- room names/order/dimensions;
- whether any straight stair symbol in Plan 1 belongs to an independent Stallhuset internal circulation chain.

Therefore S1 stays a **reference-gap shell** until Plan 2 or cross-confirmed interior photo/video closes it.

No internal staircase may be invented to make S1 accessible.

---

## Stallhuset graph v0.1

```text
EXTERIOR CLUB SIDE
      │
      v
CLUB ENTRANCE
      │
      v
CLUB VOLUME
  ├── uppehållsrum       [exists; exact edge/order GAP]
  ├── pentry              [exists; exact edge/order GAP]
  ├── sadelkammare        [exists; exact edge/order GAP]
  ├── teorisal            [exists; exact edge/order GAP]
  └── toilets x2+         [exists; exact edge/order GAP]

                  BOX HALL
 OUTER ROW ─ AISLE A ─ INNER ROW || INNER ROW ─ AISLE B ─ OUTER ROW
                         │
                         └── TRANSVERSE/MIDDLE CIRCULATION
                                  │
                                  ├── HORSE PASSAGE ──> RIDHUS ARENA SYSTEM
                                  │
                                  └── exact visual identity = partially open

BOX HALL
   │
   v
SERVICE OPENING
   │
   v
OPEN SERVICE / THROUGH ZONE
   ├── wash/service equipment
   ├── spolspilta [boundary partly open]
   ├── bedding/shavings open bay
   └── GABLE EXIT ──> EXTERIOR

WIDE HIGH GATED CORRIDOR
   └── destination = GAP (do not auto-name horse passage)

PLAN 2 / UPPER CLUB LEVEL
   └── existence partly supported; room graph and internal access = GAP
```

---

## Hard invariants

1. Four box rows + two longitudinal aisles.
2. Two inner rows are back-to-back on a central spine.
3. A transverse/middle circulation exists through the box system.
4. Indoor horse connection to Ridhuset exists.
5. The wide gated corridor is **not** automatically that horse connection.
6. Service end is an open circulation/service zone, not generic closed rooms.
7. Service gable exit remains part of the circulation chain.
8. Club rooms listed above exist, but their order is not yet proven.
9. Pentry existence is verified even if its plan position remains open.
10. No freestanding `STALLINNE.trappa` may be created from the disputed straight-stair symbol.
11. Exterior spiral stair on Stallhuset is separate and remains exterior baseline.
12. Plan 2 may not be invented.
13. Exterior remains locked.

---

## Next evidence needed

Before implementation of unresolved Stallhuset club topology:
- cross-confirm Plan 1 club-room adjacency using the straight evacuation plan plus the actual club-room image sequence;
- inspect any relevant raw `.mov` / extracted keyframes that traverse from entrance through club rooms if present;
- obtain/identify Plan 2 evidence already in repo, otherwise keep it as `REFERENCE GAP`.

Claude must implement only the graph edges promoted above, not the unlabeled gaps.
