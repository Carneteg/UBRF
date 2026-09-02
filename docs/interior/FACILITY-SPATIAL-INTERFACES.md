# UBRF — Shared Interior Spatial Interfaces

Status: **DRAFT FOR TOBIAS REVIEW**  
Implementation: **PAUSED** until the Interior Spatial Canon is approved.

This file defines connections that cross building-model boundaries. A connection must not be independently re-invented inside each building.

## STALL_TO_RIDHUS_HORSE_PASSAGE

Classification: `VERIFIED_TOPOLOGY`  
Exact geometry/material identity: `PARTIAL_REFERENCE_GAP`

The real facility has an indoor horse-walkable connection between Stallhuset and Ridhuset.

Canonical endpoints:

`stallhus:horse_passage ↔ ridhus:horse_passage`

This is **one shared facility interface**. It is not two approximate corridors that happen to meet.

### Known

- Stallhuset has an indoor connection to Ridhuset.
- Stallhuset middle/transverse circulation participates in reaching that connection.
- On the Ridhus side the connection enters the arena/spectator system.
- The connection must be usable as a continuous horse-walkable route.

### Still open

- exact local geometry and opening width;
- exact material/visual identity of the full passage;
- whether `stall-inne-08-breda-gangen.jpg` depicts this exact connection.

### Hard rules for implementation

- Web and Roblox must consume the same interface ID and geometry source.
- Do not create a second passage to repair pathfinding.
- Do not identify the wide gated Stallhuset corridor as this passage without connecting evidence.
- Do not derive the missing measurements from current implementation coordinates.

The interface contract is machine-readable in `references/interior/facility-spatial-interfaces.json`.
