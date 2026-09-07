# F02-C — Interiörens källtrohet

Status: implementation in progress, not PRODUCT_ACCEPTED. Owner: ChatGPT, temporary delegation by Tobias on 2026-09-07. The accepted baseline is main `e65675dfe3584f5654aab3280d53692fe9b17f1a`.

## First implementation batch: finishes and lockers

The source images show two distinct interior floors. The stall clubhouse has a warm, smooth, matt concrete-like surface (`stall-inne-01-uppehallsrummet.jpg`, `stall-inne-04-teorisalen.jpg`). The riding-hall entrance and locker area has a darker neutral, smooth floor (`ridhus-klubb-20-grona-skapen.jpg`, `IMG_0268.MOV`). The previous web rendering applied a bright, square-jointed paving texture to the whole entrance. That was not the actual surface. Source-defined `INTERIORYTOR` now selects distinct finishes and colors on both platforms. The new colors are photographic estimates, not measured NCS values: camera exposure, white balance and game lighting prevent a precise color claim. The real paving in the stable corridors and the riding arena's sand remain untouched.

The existing sourced locker groups now carry shared material and front-detail metadata. The green group has four columns and two tiers, white profile frames, black legs, visible hardware and lower ventilation (`ridhus-klubb-20/-21`). The white two-tier group has five columns, hence ten doors (`ridhus-klubb-16`), replacing the previous three-by-two simplification. The high gray/dark group uses five columns (`-16/-18`). Long corridor rows preserve their previous count approximation because the exact full count is not securely established. The renderers add decorative panel seams, number labels, metal hardware and ventilation. The existing object footprint, position, orientation and collision body are unchanged. Small decorative dimensions are style approximations, not architectural measurements.

The lounge sofas use the source's black leather identity rather than Roblox Fabric. Roblox has no Leather material enum; SmoothPlastic is the supported approximation. No new sofa, room or pentry has been invented.

## Theory-room source-fidelity pass

The verified source remains `references/buildings/stall/stall-inne-04-teorisalen.jpg`.
The two existing whiteboard objects now carry shared frame/tray detail metadata,
and the web no longer draws a separate fallback board outside `INREDNING`.
The two existing framed anatomical posters remain exactly two sourced surfaces;
their renderers add only the horse silhouette visible in the source, without
invented labels or anatomical text. The existing ceiling duct carries shared
perforation metadata and is rendered with the visible perforation rows on both
platforms. Object footprints, positions, room boundaries and collision are
unchanged.

## Verification contract

`tools/interiortest.mjs` executes canonical data and the actual web furniture renderer with a recording mesh harness. It checks sources, finish differentiation, door counts, hardware, positive primitive dimensions, export values and negative mutations. `docs/INTERIOR-GEOMETRY-LOCK.json` records the accepted building/room/grandstand spatial snapshot and existing locker footprints. The test is deliberately independent of browser rendering and cannot by itself prove visual fidelity or game feel. Existing movement, visual, geometry and Roblox checks must also pass. A full browser and Roblox Studio test are separate evidence.

## Remaining work in this track

- A-gable panel finish, source-specific door/mirror composition and actual visibility.
- Clubhouse lounge and theory-room visual details, including source-backed wall art, equipment and furniture proportions.
- Reception/locker corridor finishes and door/glazing profiles where the current canonical data supports them.
- Source-by-source comparison for stable box hardware and riding-hall wall/roof details, avoiding changes that already passed prior audits.
- Resolve, not guess, the lounge/pentry window contradiction and the stall door/theory-room 13 cm conflict before any topology change.
- Review new web images side by side with originals and verify the Roblox build in Studio. No claim that source material alone proves the final visual result.

No new architectural geometry, invented rooms or independent platform truth is authorized by this document. The accepted grandstand movement is a hard regression lock. Vercel only; Tobias retains product acceptance.
