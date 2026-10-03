# Entrance visual correction

2026-09-27, base e2a800b772db2a2e12ebe4bb552b734f03112c0d.
Tobias authorized correction after Codex's isolated Studio test.

Observed: the north stable entrance opens physically, but its independently
built opaque inner face remains across the opening. Ordinary Humanoid movement
crossed the opening; this is a visual obstruction, not proven collision failure.

Before code, required behavior:
- Preserve the existing interior face, window detail, closed positions and color.
- Parent only those two moving decorations to their exact exterior door leaf.
  Keep the frame fixed. No extra prompt, collision or new door identity.
- DorrService snapshots explicitly tagged direct-child decoration transforms
  at initialization. Opening applies the same rigid transform as the leaf;
  closing restores original transforms. Repeated calls cannot accumulate drift.
- Unrelated doors, untagged children and fixed frames remain unchanged.
- Missing or ambiguous exterior identity must fail the build, not silently
  produce a detached visible panel or choose an arbitrary door.

Tests use the actual built world and door service: two linked decorations,
noncollision, orientation/position on opening, exact closing over repeated
cycles, fixed frame, untagged control and another door. Isolated mutations
disable decoration movement, detach the face and break restoration; controls
must pass and mutations fail. Run affected build/visibility/playability tests
and the full shared chain before exact-SHA independent review.

After code review, prepare a NEW unpublished local copy. In Studio verify
identity/build, closed appearance, visually open passage, and camera/player
visibility through it before resuming the circle lesson. Bank results are not
visual or product acceptance. No Rojo, publication, datastore/security changes,
canonical overwrite, geometry refactor or unrelated door redesign.
