# Stallhuset — Interior Spatial Model v0.3

Status: **DRAFT FOR TOBIAS REVIEW**  
Implementation: **PAUSED** until this model is approved.

This is the spatial/topology model for Stallhuset. It deliberately separates verified room existence, source-backed circulation, unresolved room adjacency and implementation placeholders.

## Source-isolation rule

Interior evidence may not migrate between buildings just because the rooms look similar.

The extracted `IMG_0268`, `IMG_0282` and `IMG_0283` clubhouse sequences are catalogued under the Ridhus/clubhouse source set and describe the ridhus-side club/changing facilities. They are **not Stallhuset room-order evidence**.

For Stallhuset club topology, use only Stallhuset sources: Plan 1, Stallhuset photos `IMG_0132–0144` / their repo derivatives, Stallhuset-specific video/keyframes where available, and Tobias corrections.

---

## Hard correction after Ridhus stair review

The stair visible in PR #73 / the preview is **not a Stallhuset ground-floor stair**. Tobias identified it as a real stair reached through **Ridhusets läktare**, and the Ridhus source set confirms the C-short-end stair system from bleacher level to the upper glazed/café corridor.

That correction does **not** prove that Stallhuset has no internal straight stair.

Plan 1 contains a straight-stair symbol in the Stallhuset club end. The symbol is retained as **evidence**, but its identity, start level, destination and visual form are not yet cross-confirmed by Stallhuset photo/video.

Canonical rule:

`Plan 1 straight-stair symbol = EVIDENCE_ONLY / REFERENCE GAP for connection`

It must not be instantiated by copying or reusing the Ridhus café stair.

The exterior **spiral stair on Stallhuset's club gable is a separate verified object** and remains part of the locked exterior baseline.

---

# S0 — Plan 1: club end

## Public/club entrance

`VERIFIED / PRODUCT BASELINE`:
- the club entrance belongs to the club end of Stallhuset;
- source imagery shows the ochre/yellow entrance door and round windows associated with the club section;
- Plan 1 places `Här är du` at this end.

Canonical edge:

`exterior club entrance → Stallhuset club circulation zone`

The exact first named room after crossing the threshold is not yet proven.

## Macro circulation to the box hall

The club end is **not a disconnected destination**. Plan 1 is an evacuation/circulation source for one building, the club section occupies one end of the same Plan 1 shell, and the box hall occupies the longitudinal body beyond it. The existing fidelity work also identified the old implementation defect where a tiny gap at the club/box-hall boundary made a person entering the club end unable to continue into the stall aisle.

What may now be promoted:

`club entrance → club circulation zone → box-hall access → longitudinal stall aisles`

Classification: **`DERIVED_PLAN_CIRCULATION`**.

This is a topology edge, not a measured corridor shape. It does **not** authorize:
- choosing which named club room one walks through;
- inventing a central hallway width;
- placing doors by symmetry;
- using current `src/site.js` rectangles as the source.

The exact doorway/opening between the club circulation zone and each stall aisle remains a geometry gap unless Plan 1 or cross-confirmed imagery gives it directly.

## Verified rooms in club section

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

## Club-end envelope constraints

1. **Uppehållsrum is exterior-facing** — it has both arched and round windows. `VERIFIED`.
2. **Pentry is exterior-facing** — it has arched and round windows. `VERIFIED`.
3. **Teorisal is exterior-facing** — it has round windows. `VERIFIED`.
4. The round-window motif belongs to the Stallhuset club end, not the box hall. `VERIFIED`.
5. No equivalent exterior-window evidence is currently strong enough to force sadelkammaren or the toilets onto a particular facade.

At least the three windowed rooms must therefore touch a real exterior wall of the club-end envelope. Which wall and in what order remains open.

## What the IMG_0132–0144 sequence does and does not prove

The Stallhuset source sequence establishes a coherent **club-end family of spaces**: entrance condition, uppehållsrum, pentry, sadelkammare, teorisal and two toilet rooms are all documented in the same Stallhuset source run.

However, sequential filenames are not by themselves proof of direct door adjacency. Unless a pair of images shows the same threshold/opening from both sides or a continuous Stallhuset video crosses it, the named-room edge remains `REFERENCE GAP`.

Therefore the source sequence may prove **membership in the club cluster**, but not an invented room order.

## Current implementation coordinates are NOT evidence

`src/site.js` currently contains rectangles for uppehållsrum, teorisal and sadelkammare. Those coordinates are implementation geometry, not an independent source.

The existing fidelity audit notes that these rooms were intentionally placed inside a coarse `club hall` walkable region and then collided separately. Their exact rectangles/order must **not** be promoted into canon merely because they already exist in code.

## Remaining club gaps

- exact order of uppehållsrum / pentry / sadelkammare / teorisal / toilets;
- which named room is directly adjacent to the entrance;
- exact internal door graph;
- exact dimensions;
- which exterior facade each windowed room occupies;
- exact shape/width of the club circulation zone;
- exact opening geometry from club zone to aisle A / aisle B;
- whether pentry is wholly separate or directly attached to another club room.

These remain `REFERENCE GAP`.

---

# Plan 1 straight-stair evidence node

Plan 1 contains a straight-stair symbol in the club-end topology. Preserve that fact without over-interpreting it.

**Known:**
- the symbol exists in Plan 1;
- it belongs to the Stallhuset club-end portion in the current plan reading;
- it is separate from the verified exterior spiral stair.

**Not yet known:**
- where a person physically approaches it from;
- whether it starts on S0 or another intermediate level;
- which Plan 2/upper space it reaches;
- its material, orientation and exact geometry;
- whether any existing Stallhuset interior photograph depicts it.

**Forbidden:**
- identifying it as the Ridhus C-block stair;
- building a generic white stair on Stallhuset ground level;
- using the PR #73 stair geometry as its implementation.

Status: `PLAN_EVIDENCE / CONNECTION_REFERENCE_GAP`.

---

# S0 — box hall

## Core plan topology

`VERIFIED` from Plan 1:

`outer box row → aisle A → inner box row ↔ inner box row → aisle B → outer box row`

The two inner rows are back-to-back around a shared central spine.

## Box rows

- four longitudinal box rows — `VERIFIED`;
- two longitudinal aisles — `VERIFIED`;
- 12 boxes per row — `MEASURED` in current plan analysis;
- box width 3.5 m — `DERIVED`, not independent surveyed truth;
- whole-building width 21 m — `REFERENCE GAP` working value.

## Stall aisle identity

`VERIFIED` from many Stallhuset photo/video frames:
- center walking strip of paving/marksten;
- bedding/shavings strip along box fronts;
- dark anthracite lower box panels;
- galvanized upper framing/rails;
- visible timber/laminated roof structure and corrugated metal roof underside.

## Cross corridor

A transverse corridor crosses the box hall around the middle section — `MEASURED/PLAN`.

Canonical relation:

`aisle A + central box system + aisle B ↔ transverse corridor`

Exact opening widths remain open where not measured.

---

# S0 — connection to Ridhuset

The facility contains a real indoor horse connection between Stallhuset and Ridhuset — `VERIFIED` topology.

Canonical edge:

`Stallhuset transverse/middle circulation → horse passage → Ridhuset arena system`

Important guard:
- `stall-inne-08-breda-gangen.jpg` shows a wide high indoor corridor with a barred/gated end;
- that corridor **may not automatically be called the horse passage**, because the image does not prove its destination.

Therefore:
- existence of horse passage = `VERIFIED`;
- exact visual identity of `stall-inne-08` as that passage = `REFERENCE GAP`.

---

# S0 — service end

The end opposite the club section is a service/circulation zone.

## Verified spatial character

- open through-passage/service room, not invented closed rooms;
- opening connects it back into the box hall;
- gable exit leads directly outside with daylight + green exit sign;
- concrete/light service floor around wash/service hardware, with paving continuing in circulation strip;
- visible pipework and wall equipment;
- freestanding galvanized wash/tie bars;
- stacked bedding/shavings bags in an open bay.

## Spolspilta

A real wash stall / spolspilta exists — `VERIFIED`.

Photo evidence shows raised/ridged floor with drainage fall, hot-water/heater and pipes, and hose fittings. Its exact boundary remains partially open.

Canonical service chain:

`box hall → service opening → open service/through zone → service gable exit → exterior`

---

# Unknown wide corridor

`stall-inne-08-breda-gangen.jpg` / related frames prove a broad tall corridor with a barred/gated section.

Node status: `VERIFIED EXISTENCE`.  
Destination: `REFERENCE GAP`.

Do not label it `horse passage to Ridhuset` merely because it is horse-sized.

---

# S1 — Plan 2 / upper club level

## Proven

- Stallhuset has an upper club-end condition / upper door presence supported by exterior imagery;
- exterior spiral stair on Stallhuset club gable is real and separate from Ridhus stairs;
- Plan 1 contains a straight-stair symbol that may participate in internal vertical circulation, but that relation is unresolved.

## Not proven enough to build

- complete Plan 2 room graph;
- room names/order/dimensions on S1;
- exact internal access from S0 to S1;
- whether the Plan 1 straight-stair symbol reaches S1, an intermediate landing or another zone.

S1 remains a `REFERENCE GAP` shell.

---

# Stallhuset graph v0.3

```text
EXTERIOR CLUB SIDE
      │
      v
CLUB ENTRANCE                         [VERIFIED / PO baseline]
      │
      v
CLUB CIRCULATION ZONE                 [PLAN + photo cluster]
  ├── uppehållsrum                    [exists; exterior-facing; exact edge GAP]
  ├── pentry                           [exists; exterior-facing; exact edge GAP]
  ├── teorisal                         [exists; exterior-facing; exact edge GAP]
  ├── sadelkammare                     [exists; exact edge GAP]
  └── toilets x2+                      [exist; exact edge GAP]
      │
      │ DERIVED_PLAN_CIRCULATION
      v
BOX-HALL ACCESS
      │
      ├── AISLE A
      └── AISLE B

PLAN 1 STRAIGHT-STAIR SYMBOL
  └── plan evidence only
      ├── start/access = GAP
      ├── destination = GAP
      └── MUST NOT reuse Ridhus C-stair implementation

                  BOX HALL
 OUTER ROW ─ AISLE A ─ INNER ROW || INNER ROW ─ AISLE B ─ OUTER ROW
                         │
                         └── TRANSVERSE/MIDDLE CIRCULATION
                                  │
                                  └── HORSE PASSAGE ──> RIDHUS ARENA SYSTEM

BOX HALL
   │
   v
SERVICE OPENING
   │
   v
OPEN SERVICE / THROUGH ZONE
   ├── spolspilta [boundary partly open]
   ├── bedding/shavings open bay
   └── GABLE EXIT ──> EXTERIOR

WIDE HIGH GATED CORRIDOR
   └── destination = GAP

PLAN 2 / UPPER CLUB LEVEL
   └── room graph and internal access = GAP

EXTERIOR SPIRAL STAIR
   └── verified exterior object; separate from Ridhus stairs
```

---

# Hard invariants

1. Four box rows + two longitudinal aisles.
2. Two inner rows are back-to-back on a central spine.
3. A transverse/middle circulation exists through the box system.
4. The public club entrance must not terminate in a disconnected club island: a walkable club-to-boxhall connection exists at macro topology level.
5. The exact named-room order inside that club circulation is **not** proven and must not be invented.
6. Indoor horse connection to Ridhuset exists.
7. The wide gated corridor is **not** automatically that horse connection.
8. Service end is an open circulation/service zone, not generic closed rooms.
9. Service gable exit remains part of the circulation chain.
10. Uppehållsrum, pentry and teorisal remain exterior-facing because their photos show exterior windows.
11. Existing `src/site.js` club-room rectangles are implementation placeholders, not source evidence.
12. The Plan 1 straight-stair symbol remains an unresolved evidence node; it is not permission to build a generic stair.
13. Ridhus C-stairs must never be reclassified as a Stallhuset stair.
14. Ridhus/clubhouse `IMG_0268/0282/0283` sequences must not be used to infer Stallhuset room order.
15. Exterior spiral stair on Stallhuset is separate and remains exterior baseline.
16. Plan 2 may not be invented.
17. Exterior remains locked.

Claude must implement only graph edges promoted above, not unlabeled gaps.
