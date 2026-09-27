# Ground pole in walk (jumping, first stage)

Status: BUILT_NOT_VERIFIED, 2026-09-27. Contract written before code.
Order: [GROUND_POLE_BUILD_ONLY_20260927](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855957392),
base 267ab77. Build now, test last
([5855114357](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)).
Claude writes; Codex reviews source; Tobias playtests the whole at the end.

This is ONLY the first stage of the catalogue area "hoppning":
- a guided approach in walk;
- an observed passage over the plane of the EXISTING ground pole;
- a short walk on.

It does NOT assess jumping, hoof clearance or contact, knockdowns, rhythm,
balance or landing. Higher obstacles, lines and a course are not built. The
pole has `CanCollide = false`; the passage is the horse ROOT crossing the
pole's plane. It is NOT verified foot placement. FloorMaterial and
client-owned physics remain unverified.

## The existing pole (read from source, not an engine observation)

- `src/site.js` `RIDHUSINNE.hinder`: `{ id = "ridhus_hinder_rod_50", x = 9.0,
  y = 50, b = 3.0, h = 0 }` in the arena's own system.
- `Anlaggningen.luau` builds it:
  - lower face at `max(0.02, h)` = 0.02 m;
  - 3.0 × 0.09 × 0.09 m;
  - `CanCollide = false`;
  - attribute `HinderId`.
- The other two poles are raised (0.68 m and 0.52 m) and are **never** used by
  this lesson.
- `HinderObservation` registers the built part (width = its longest axis; axis
  and normal from its own CFrame) and observes per ride:
  - an attempt opens on entering the zone (|u| ≤ width/2 + 1.5 studs,
    |v| ≤ 6 studs) or on a plane crossing near it;
  - `passage` needs confirmed sides with |v| > `SID_TOL` (0.25 studs) and the
    LAST observed plane crossing inside the width;
  - `riktning` is `fram` (−v → +v) or `bak`;
  - the attempt closes on leaving the zone;
  - a break closes it as `brott`, and removal closes it as
    `hinder_borttaget` / `hinder_ogiltigt`.
- Attempts carry `nr` (per pole) and `tIn` / `tUt` in ride time, which is the
  same domain as RidObservation `tid`.

## Narrow registry additions (additive, lifecycle unchanged)

`HinderObservation.register()` entries gain two fields:
- **`generation`:** a per-id counter bumped on every registration change (a
  part added, removed or re-proved; a whole id removed). A replacement with
  identical geometry therefore still has a new generation.
- **`flyttad` (R1: the WHOLE geometry, fail-closed):** true when the live
  part no longer matches the registered geometry. This is computed with the
  same `geometri()` as registration, and covers:
  - position (0.01 studs);
  - the width axis including its sign, since a rotated pole flips the normal
    (1e-4 per component);
  - width, thickness and top (0.01 studs).

  A missing part, no parent, invalid or non-finite live geometry, or an error
  while reading counts as changed. The registry does not re-read geometry on a
  change, so it would otherwise keep the old geometry. `tjocklek` is also
  exposed.
- **Guide identity (R1):**
  - The lesson's reference carries the pole key: generation, position, axis,
    width, top and thickness.
  - The reference is removed (nil) whenever the pole is unusable.
  - A changed key bumps the revision, so the change reaches the client even
    when state and tip are unchanged.
  - The client guide is cached on that key too; other lessons have no key, so
    their behaviour is unchanged. Unchanged samples do not rebuild the guide.

No rule for duplicates, removal, attempts or passages changes.

## Geometry (resolved frame, metres)

At every baseline the lesson reads the registry entry for
`ridhus_hinder_rod_50` and converts it with `Ridhusplats.tillLokal`:
- **c:** the centre (u, v) of the pole in the frame;
- **A:** the width axis in the frame;
- **W:** the intended crossing direction, defined as the normal pointing
  **towards C** (+v in the frame), so it is mirror-safe;
- **the registry direction** matching W: `fram` if the registry normal points
  towards C, otherwise `bak`;
- **the width:** the registered width / 3.

Pole-local coordinates are `a` (along A) and `w` (along W), with w = 0 on the
plane.

The pole must be valid, not rejected, not moved, and a GROUND pole (the top
≤ 0.25 m above the arena floor). Otherwise Start is refused with `pole` and no
other obstacle is selected.

| Name | Value |
|---|---|
| Corridor | \|a\| ≤ width/2 + 0.5 m (2.0 m for this pole), −10 ≤ w ≤ 10 |
| Fresh approach | ≥ 4.0 m of credited walk towards the pole, while w < −0.5 |
| Exit | ≥ 1.0 m of credited walk beyond the point where the passage closed |
| Backwards | w more than 1.0 m behind the credited frontier: reverse |
| Deadline | 150 s; timeout ends incomplete |

## Evidence and phases

1. **`approach`**
   - A step credits approach only when all of these hold:
     - the accepted gait is walk, not reversing;
     - there is no gait event in the step;
     - it is a valid observed segment with both endpoints in the corridor
       and w < −0.5.
   - The frontier is the furthest w reached; credit is the growth of the
     frontier since arming. The first such step arms, and gives no credit.
   - Back-and-forth adds nothing; going back more than 1 m resets.
   - Halt, trot, canter, reversing or a gait event in the step resets the
     approach to 0. Halt and gait-change travel is therefore never banked.
   - At arming the lesson records `nrBas` (the highest attempt `nr` at this
     pole so far, including any open attempt) and `tBas` (the ride time).
2. **`crossing`** (approach ≥ 4 m)
   - The same walk and corridor rule applies to every step.
   - The lesson looks for an attempt at THIS pole with `nr > nrBas` and
     `tIn > tBas`. Attempts opened before arming, and old completed ones,
     can never count.
   - While that attempt is open (`pagar`), the lesson waits.
   - When it closes with `giltighet = fullstandig`, `utfall = passage` and the
     intended `riktning`, the lesson goes to `exit`.
   - `sidan_om` gives `beside_pole` and `ingen_passage` gives `no_passage`;
     each resets.
   - The other direction gives `wrong_direction`. That guard is defensive:
     arming needs walk on the approach side, and an attempt opened before
     arming is excluded. A crossing towards A therefore never arms a
     countable attempt.
   - Reaching the plane and turning back normally trips `reverse` (more than
     1 m back) before the registry closes it as `ingen_passage`.
   - `brott`, `hinder_*` or `ritten_slut` gives `unknown` and a reset.
3. **`exit`**
   - Credited walk frontier ≥ 1.0 m beyond the w at which the passage closed,
     inside the corridor.
   - Then the attempt is **complete**.

**The HinderObservation snapshot overflowing** (`overflode`) makes the evidence
unknown: reset. The attempt list is bounded (64); after overflow no new attempt
is recorded, so the lesson cannot complete in that ride. That is honest, and it
is reported as `unknown`.

**Physical vs credited:** only credited walk moves any frontier. A reset
(re-arm) clears approach, crossing and exit together, with no debt.

## Breaks and identity

The following reset the evidence to `approach`, with the SAME deadline:
- observation breaks (gap, missing root, teleport, invalid dt);
- frame change or loss;
- an invalid ridplats image;
- RidLogg overflow;
- stale owner, ride or horse;
- a pole change: missing, duplicate, invalid, moved, raised or a new
  `generation`.

The break checks run BEFORE the time equality. While the pole is unusable the
tip is `pole_missing` and nothing is credited. When it becomes usable again
the geometry is re-read, and a fresh approach is needed.

## Lifecycle and requests

- **Attempt:** FORSOK1 `ovning = markbom`, definition `server-markbom-1`.
- **Type:** `typ = "markbom"` in the ride-scoped, type-aware request ledger, with
  the usual rules for late or duplicate requests, switches and Finish.
- **Frozen result:**
  - identities;
  - the pole id and its generation;
  - the registry direction;
  - the observation attempt `nr`;
  - approach metres and exit metres;
  - `passage = "rotplan"`, `kontakt = "otillganglig"` and `rivning = false`;
  - the start.

## Guide

The guide is local, non-colliding, and in the same coordinates as the server:
- dashed lines along both corridor edges of the approach (w −10 … −0.6);
- chevrons towards the pole on a = 0;
- two dash marks beside the pole ends, not on the pole;
- an exit lane (w 0.6 … 3).

The current part is solid.

## Menu

The subgroup under "Riding paths" becomes "Straight lines and ground pole":
centre line, diagonal, ground pole and Back (to Riding paths). That is four
rows, and all other pages are unchanged.

## Deferred verification (written, NOT run)

`roblox/tests/markbomlektion.spec.luau` contains these written cases.

**Full sequence:**
- approach, crossing towards C, exit; the result is frozen and shows no
  contact claim.

**Freshness:**
- a passage completed before Start does not count;
- an attempt already open at Start (armed inside the zone) does not count
  when it closes later.

**Wrong routes:**
- crossing in the other direction (from the C side) never arms a countable
  attempt and never completes;
- beside the pole gives `beside_pole`;
- the raised pole `ridhus_hinder_bla_24` is never used.

**Boundaries:**
- stopping on the plane and turning back resets and never completes;
- a literal on-plane sample (w = 0) and samples within `SID_TOL` confirm no
  side.

**Movement and gait:**
- standing still at the approach adds nothing;
- jitter adds nothing;
- trot in the approach resets;
- a halt in the approach resets, and nothing halted is banked;
- a canter over the pole resets.

**Breaks:**
- a teleport, then fresh recovery completes;
- the pole moved (the live part moved), then `pole_missing`;
- the pole removed and re-added with identical geometry gives a new
  generation, and a reset.

**Lifecycle and requests:**
- deadline;
- Retry;
- late requests and the same sequence with another type;
- all ten lesson types start and finish;
- owner events only to the owner;
- no persistent writes.

**Menu:** every one of the ten leaves and each Back is reachable within four
rows beside 0..3 cards.

**R1, written:**
- a pole rotated in place is unusable and its reference is nil; once
  restored, the evidence is fresh;
- a pole resized in height or in width in place is unusable;
- the client guide:
  - is drawn;
  - is not rebuilt by an unchanged sample;
  - is removed when the pole is missing;
  - is refreshed when a changed valid pole appears in the same frame and the
    same phase;
- arming is asserted on ONE sample, and forward walk then earns progress.

**Planned, not written:**
- a duplicate `HinderId` (the registry rejects both; the lesson reads a
  missing entry, the same path as removal);
- HinderObservation overflow (64 attempts);
- frame change and invalid dt;
- rendered layout, touch and SV/EN;
- whether FloorMaterial or client physics differ in the engine.
