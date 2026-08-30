# Google Drive folder map — UBRF reference source

Date inventoried: 2026-08-30
Status: **UPSTREAM / PROVENANCE MAP — NOT A BUILD DEPENDENCY**

The Product Owner has reorganized the UBRF reference material in Google Drive into zone-specific folders. This is useful for locating source material, but the project rule remains unchanged: **implementation may not depend on Drive-only evidence**. Any image/video that becomes implementation-critical must first be represented in GitHub and/or Supabase as a build-accessible reference, derivative, frame set or verified source record.

## Root

UBRF Drive folder: `1MVAjXRn9OSdcQiuhejhPkVJRSurEFgRZ`

## Zone folders

### Ridhuset
Folder ID: `1N3umwQVcuZ69Xxh1Rv4flMAkpIRHVGmj`

Contains a large set of riding-hall stills and videos, including previously referenced source names such as:
- `IMG_0179.HEIC`
- `IMG_0183.HEIC`
- `IMG_0198.HEIC`
- `IMG_0191.MOV`
- plus multiple stills in the `IMG_0078–0125` and `IMG_0171–0199` ranges and several MOV files.

**Use for:** ridhus exterior, interior, wall/ceiling construction, arena-side details, glazed rooms, seating, booth/stairs, clock, ventilation/metal/cable structures, doors/openings and camera-angle comparison.

### Stallhuset
Folder ID: `1gzcJz-UB78POfvZOXvMP_KNdnfNFJgE0`

Contains stable-building stills, prominently in the `IMG_0132–0168` range.

**Use for:** stable exterior facades, gables, doors/windows, porch/entry details, roof identity, vent structures, railings/stairs/balcony where actually shown, and stable interior/box/aisle detail where visible.

### Byggnaden
Folder ID: `1cmyTQ_9AVjAaKlozWE2-lKsMxGRgVaPB`

Contains building/reference stills including `IMG_0064–0077` and `IMG_0126–0131`.

**Use for:** shared/adjacent building volumes, connecting structures, parts that are neither cleanly “ridhus” nor “stall”, and whole-building/context views. This folder is especially important for resolving previously assumed intermediate/connecting geometry.

### Omnejd
Folder ID: `1RInJ-zjFT9dbMdxzyZPj4TmXlzJ7xIv-`

Contains environment/context stills including `IMG_0163–0165`.

**Use for:** surroundings, approach, terrain/context, fencing, roads/paths, vegetation and external spatial reading around the facility.

## Important data-quality note

There are duplicate filenames/duplicate uploads in several folders (same image names and matching file sizes appear with different Drive IDs). When migrating evidence into GitHub/Supabase, deduplicate by file content/hash or at minimum by filename + byte size before creating new reference assets.

## Mandatory workflow for Claude

1. Use this folder map only to **locate upstream evidence**.
2. Before implementing from a Drive-only image/video, create a build-accessible representation in GitHub and/or Supabase.
3. Record exact provenance: Drive file ID + filename + destination reference path/asset ID.
4. Classify each implementation claim as `VERIFIED`, `DERIVED`, `ASSUMPTION`, `REFERENCE GAP` or `CONTRADICTION`.
5. Do not use a folder label as evidence by itself; inspect the actual image/video/frame.
6. For geometry/layout, fire/evacuation plans still outrank photos unless the Product Owner explicitly resolves a conflict.
7. For visible materials/details, photos/video are authoritative.

## Immediate Gate F01 relevance

The reorganized folders remove a major navigation problem. In particular:
- the ridhus images previously treated as hard-to-access Drive-only references are now grouped under `Ridhuset`;
- the stable facade mismatch can be rechecked against the `Stallhuset` folder instead of relying on mixed old indexes;
- `Byggnaden` should be reviewed before any further assumptions about intermediate/connecting volumes;
- `Omnejd` should drive later environment/context fidelity rather than invented landscaping.
