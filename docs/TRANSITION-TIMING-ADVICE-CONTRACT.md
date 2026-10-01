# Transitions: event-bound advice when a transition misses its ring (C1)

Status: BUILT, local tests green, NOT physically verified, 2026-09-28. Contract written before code.
Order: [CHATGPT_REVIEW_C1_CIRCLE_LINE_ADVICE_ACCEPTED_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5863825010),
base `8bebd6b`, branch `codex/circle-lesson-20260926`. Build now, physical test last.
Claude writes; ChatGPT reviews source; Tobias playtests the whole at the end.

## The already-distinguished failure state

`OvergangLektion` already gives two failure tips:
- `trot_outside`: the requested trot's observed interval is not inside T1;
- `walk_outside`: the requested walk's observed interval is not inside T2.

Both reset the attempt to walk1. The text stays until the player actually walks again.

The decision is `iMal`. It takes both end points of the observed segment
(`p.segment.fran`, `p.segment.till`) in which the transition first appears,
and checks them against the target ring:
- `|u − ref.u| ≤ ZON_HALV`, and
- `|v − malV| ≤ ZON_HALV`.

## The one fact used

From the **same two end points**, the server already knows two things:
- whether the transition happened on the centre line but short of the ring, or past it;
- in which direction the horse was travelling (`till.v − fran.v`).

**The signed offset.** For each end point, the offset along the direction of
travel is `(v − malV) · sign(till.v − fran.v)`:
- **`fore`** (before the ring): both end points are on the line, and both offsets are `< −ZON_HALV`. The horse had not reached the ring yet.
- **`efter`** (past the ring): both end points are on the line, and both offsets are `> +ZON_HALV`. The horse had already passed it.
- **No side** in every other case: beside the line, straddling the ring edge, no movement along v, or a non-table segment. The existing generic text stays.

This is not a new observation, a new threshold or a quality metric. It uses the
same segment and the same `ZON_HALV`, and only keeps the direction.

## Server (`OvergangLektion`)

**Setting it.** `tillSkritt(s, tips, sida)`:
- sets `s.malSida` to `"fore"` or `"efter"`, with `s.malForsok = s.forsokId`;
- only the `trot_outside` and `walk_outside` branches pass a side;
- every other call clears it (start, breaks, `walk_first`, `trot_longer`, `tired`, `walk_only`, `trot_only`, unknown).

**The snapshot** carries `malSida` only when all of these hold:
- `lage == "walk1"`;
- `tips` is `trot_outside` or `walk_outside`;
- `s.malForsok == s.forsokId`.

As soon as the tip changes (the player walks again), the side is gone.

**Unchanged:** the lifecycle, thresholds, result and completion.

## Client (`VoltLektionController`)

For type `overgang`, key `trot_outside` or `walk_outside`, and `b.malSida`
exactly `fore` or `efter`, the text is ONE literal key:
- `overganglektion.trot_early`: "Traven kom innan ni var framme vid första ringen. Skritta igen och be om trav först när ni är inne i ringen."
- `overganglektion.trot_late`: "Traven kom när ni redan hade passerat första ringen. Skritta igen och be om trav lite tidigare, när ni rider in i ringen."
- `overganglektion.walk_early`: "Skritten kom innan ni var framme vid andra ringen. Håll traven tills ni är inne i ringen. Vi börjar om från skritt."
- `overganglektion.walk_late`: "Skritten kom när ni redan hade passerat andra ringen. Be om skritt lite tidigare, när ni rider in i ringen. Vi börjar om från skritt."

All four have English. Otherwise the existing text is unchanged.

**It never claims:**
- a cause;
- the rider's body or aids ("be om trav" is the game's own request, as the existing texts already say);
- the quality of the transition.

## Acceptance (written as tests; engine and physical play deferred)

**Server and real client (`overganglektion.spec`), on a fresh ride:**
- trot requested at v 10→11 (T1 = 18) gives `trot_outside` + `fore` + the early text in the real panel;
- trot at 23→24 gives `efter` + the late text;
- walk at 30→31 (T2 = 42) gives `walk_outside` + `fore`, and walk at 46→47 gives `efter`;
- trot beside the line (u + 4) inside the ring's v band gives `trot_outside` with no side and the generic text;
- trot while riding towards A at 26→25 gives `fore` (not yet reached, in the travel direction);
- walking again removes the side (the tip changes);
- another failure (`walk_first`) carries no side;
- finish and start carry no side;
- a KONTROLL client snapshot with a side outside those keys is not shown;
- locale and keys.

**Falsification:** each of these is mutated and must turn a test red:
- the direction sign;
- the on-line check;
- `fore`/`efter` swapped;
- a side on another failure;
- the snapshot state guard;
- the client key guard.

**Not tested here:**
- Studio, runtime and touch;
- the rendered length;
- whether the advice improves the next transition.
