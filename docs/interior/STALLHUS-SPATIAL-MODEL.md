# Stallhuset — Interior Spatial Model v0.2

Status: **DRAFT FOR TOBIAS REVIEW**  
Implementation: **PAUSED** until this model is approved.

This is the spatial/topology model for Stallhuset. It deliberately separates verified room existence, source-backed circulation and implementation placeholders.

## Hard correction after Ridhus stair review

The stair visible in PR #73 / the preview is **not a Stallhuset ground-floor stair**. Tobias identified it as a real stair reached through **Ridhusets läktare**, and the Ridhus source set confirms the C-short-end stair system from bleacher level to the upper glazed/café corridor.

That correction does **not** prove that Stallhuset has no internal straight stair.

Plan 1 contains a straight-stair symbol in the Stallhuset club end. The symbol is therefore retained as **evidence**, but its identity, start level, destination and visual form are not yet cross-confirmed by Stallhuset photo/video.

Canonical rule:

`Plan 1 straight-stair symbol = EVIDENCE_ONLY / REFERENCE GAP for connection`

It must not be instantiated by copying or reusing the Ridhus café stair.

The exterior **spiral stair on Stallhuset's club gable is a separate verified object** and remains part of the locked exterior baseline.

---

## S0 — Plan 1: club end

### Public/club entrance

`VERIFIED / PRODUCT BASELINE`:
- club entrance belongs to the club end of Stallhuset;
- source imagery shows the ochre/yellow entrance door and round windows associated with the club section;
- the evacuation plan places `Här är du` at this end.

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
- teorisal: long table, whiteboard, anatomy/teaching posters, round windows;
- toilets: two different rooms are shown, including one accessibility-adapted.

### Club-end envelope constraints

The photos allow a few topology constraints even though the room order is not proven:

1. **Uppehållsrum is exterior-facing** — it has both arched and round windows. `VERIFIED`.
2. **Pentry is exterior-facing** — it has arched and round windows. `VERIFIED`.
3. **Teorisal is exterior-facing** — it has round windows. `VERIFIED`.
4. The round-window motif belongs to the Stallhuset club end, not the box hall. `VERIFIED`.
5. No equivalent exterior-window evidence is currently strong enough to force sadelkammaren or the toilets onto a particular facade.

This means Claude may not put all club rooms into an arbitrary interior block: at least the three windowed rooms must touch a real exterior wall of the club-end envelope. Which wall and in what order remains open.

### Current implementation coordinates are NOT evidence

`src/site.js` currently contains rectangles for uppehållsrum, teorisal and sadelkammare. Those coordinates are implementation geometry, not an independent source.

The existing fidelity audit explicitly notes that these rooms were intentionally placed inside a coarse `club hall` walkable region and then collided separately. Therefore their exact rectangles/order must **not** be promoted into canon merely because they already exist in code.

Use current code only as a comparison target after the source graph is fixed.

### What is NOT proven

- exact order of uppehållsrum / pentry / sadelkammare / teorisal / toilets;
- which room is directly adjacent to the entrance;
- exact internal door graph;
- exact dimensions;
- which exterior facade each windowed room occupies;
- whether pentry is a wholly separate room or directly attached to another club room in the plan.

These remain `REFERENCE GAP`. Claude may create walls/doors only after a source-backed adjacency is promoted into this canon.

---

## Plan 1 straight-stair evidence node

Plan 1 contains a straight-stair symbol in the club-end topology. Preserve that fact without over-interpreting it.

**Known:**
- the symbol exists in Plan 1;
- it is in the Stallhuset club-end portion of the plan according to the plan reading;
- it is separate from the verified exterior spiral stair.

**Not yet known:**
- where a person physically approaches it from;
- whether it starts on S0 or another intermediate level;
- which Plan 2/upper space it reaches;
- its material, orientation and exact geometry;
- whether any existing interior photograph depicts it.

**Forbidden:**
- identifying it as the Ridhus C-block stair;
- building a generic white stair on Stallhuset ground level;
- using the PR #73 stair geometry as its implementation.

Status: `PLAN_EVIDENCE / CONNECTION_REFERENCE_GAP`.

---

## S0 — box hall

### Core plan topology

`VERIFIED` from Plan 1:

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

These are fidelity facts, not permission to alter topology.

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
- `stall-inne-08-breda-gangen.jpg` shows a wide high indoor corridor with a barred/gated end;
- that corridor **may not automatically be called the horse passage**, because the image does not prove its destination.

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

- Stallhuset has an upper club-end condition / upper door presence supported by exterior imagery;
- the exterior spiral stair on Stallhuset club gable is real and separate from Ridhus stairs;
- Plan 1 contains a straight-stair symbol that may participate in internal vertical circulation, but that relation is not yet proven.

### What is not proven enough to build

- complete Plan 2 room graph;
- room names/order/dimensions on S1;
- exact internal access from S0 to S1;
- whether the Plan 1 straight-stair symbol reaches S1, an intermediate landing or another zone.

Therefore S1 stays a **reference-gap shell** until Plan 2 or cross-confirmed interior photo/video closes it.

Do not invent an internal staircase to make S1 accessible. Preserve the Plan 1 symbol as an unresolved evidence node instead.

---

## Stallhuset graph v0.2

```text
EXTERIOR CLUB SIDE
      │
      v
CLUB ENTRANCE
      │
      v
CLUB VOLUME
  ├── uppehållsrum       [exists; exterior-facing; exact edge/order GAP]
  ├── pentry              [exists; exterior-facing; exact edge/order GAP]
  ├── teorisal            [exists; exterior-facing; exact edge/order GAP]
  ├── sadelkammare        [exists; exact edge/order GAP]
  └── toilets x2+         [exist; exact edge/order GAP]

PLAN 1 STRAIGHT-STAIR SYMBOL
  └── exists as plan evidence
      ├── start/access = GAP
      ├── destination = GAP
      └── MUST NOT reuse Ridhus C-stair implementation

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

EXTERIOR SPIRAL STAIR
   └── verified exterior access object; do not confuse with Ridhus stairs
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
8. Club rooms listed above exist, but their exact order is not yet proven.
9. Uppehållsrum, pentry and teorisal must remain exterior-facing because their photos show exterior windows.
10. Existing `src/site.js` club-room rectangles are implementation placeholders, not source evidence.
11. The Plan 1 straight-stair symbol remains in canon as an unresolved evidence node; it is not permission to build a generic stair.
12. The Ridhus C-stairs must never be reclassified as a Stallhuset stair.
13. Exterior spiral stair on Stallhuset is separate and remains exterior baseline.
14. Plan 2 may not be invented.
15. Exterior remains locked.

---

## Next evidence needed

Before implementation of unresolved Stallhuset club topology:
- cross-confirm Plan 1 club-room adjacency using the straight evacuation plan plus the actual club-room image sequence;
- inspect any relevant raw `.mov` / extracted keyframes that traverse from entrance through club rooms if present;
- identify whether any Stallhuset interior photo shows the Plan 1 straight stair or its landing;
- obtain/identify Plan 2 evidence already in repo, otherwise keep S1 as `REFERENCE GAP`.

Claude must implement only graph edges promoted above, not unlabeled gaps.
