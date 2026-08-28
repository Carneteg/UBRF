# Build prompt — "Ridskolan" (riding-school game)

Copy everything below the line into Lovable as one prompt. It describes the
complete game. If it is too long for a single message, send section 0–4 first,
then paste the remaining sections one at a time as follow-ups.

---

Build a browser game called **Ridskolan**. It is a riding-school simulator set at
a real Swedish riding club, Upplands-Bro Ryttarförening (UBRF), Husbyvägen 1A in
Bro. The player is a riding-school student who performs *every* part of the day —
fetching the horse from the paddock, mucking out, feeding, grooming, tacking up,
riding the lesson, and competing — and climbs from the bottom of the ladder to the
top. All user-facing text is in **Swedish**. All the domain terms below are Swedish
and must be kept as-is in the UI.

## 0. Tech and shape

- React + TypeScript + Vite + Tailwind. Zustand (or a single reducer) for game state.
- The riding scene is real-time 3D — use `@react-three/fiber` + `@react-three/drei`.
  Everything is procedural geometry and colour; no downloaded 3D models or textures.
- Progress persists in `localStorage` under the key `ridskolan-v1`. If storage is
  blocked the game must still be fully playable from zero — never make saving a
  requirement.
- Must work on phones: on-screen joystick (left) and action buttons (right) that
  dispatch the same input as the keyboard, so no game logic is duplicated.
- 60 fps target. The whole game is one app; no backend required.

## 1. The core idea — this is what makes the game

**You do not steer the horse. You give four aids, and the aids move the horse's
state along a training scale. The state decides what the horse does. There is no
jump button.**

### Utbildningsskalan (the training scale)

Six values in `0..1`, in this strict order — this is a real dressage concept and
the order matters:

`takt → lösgjordhet → kontakt → schvung → rakriktning → samling`

**Floor rule:** a level can never exceed the lowest level beneath it by more than
a tolerance (`TOL = 0.12`). If `lösgjordhet` is 0.30, then `kontakt` is capped at
0.42 no matter how well you ride. The HUD must draw this cap as a visible marker
on each bar, so the player can see *which* rung is holding the pyramid down. This
is the central teaching mechanic of the whole game.

`inverkan` = the weighted average of the six, and it is what gets graded.

### The four aids (hjälper)

| Aid | Range | Keyboard |
|---|---|---|
| `skänkel` (leg) | 0..1 | W = more, S = less |
| `tygel` (rein) | 0..1 | Space (hold) |
| `sits` (seat) | −1..1 | Shift = light seat (forward), Ctrl = deep seat |
| `styrning` (steering) | −1..1 | A / D |

Plus: `R` toggles rising trot (lättridning), `Q` changes diagonal, `E` is a
half-halt (halvhalt), `F` uses the whip (spö).

**Rein must be held inside a green band (roughly 0.22–0.58).** Zero rein means no
contact; hard rein (>0.72) makes the horse tense. The HUD draws the band.

**Halvhalt (E)** is a three-beat gesture: seat + leg + rein rise together, then
the rein *yields*. Only a yielded half-halt counts, and it is the only thing that
builds `samling`. A half-halt that never releases makes things worse.

### The step function (call it every frame)

```
stepRide(state, aids, horse, context, dt)
```

- **Mjukhet (smoothness):** track a moving average of the aids. The more the aids
  jump around relative to that average, the lower `mjukhet`. Rough hands ruin
  everything downstream.
- **Spänning (tension), 0..1:** driven up by hard rein, low `mjukhet`, too much leg,
  a deep seat in canter, the whip (×10 on a whip-shy horse), poor `stallro`,
  bad saddle placement, heavy going, and the horse's own `skygghet` (weighted 1.5×
  when outdoors). Driven down by `rang` (the horse's trust in you), the horse's
  `förlåtande`, `mjukhet`, and `dagsform`. Rises fast on a sensitive horse, falls
  fast on a forgiving one.
- **Tempo is negotiated, not commanded:** the horse has its own preferred speed
  (`gait.norm × (0.80 + 0.40 × framåtbjudning)`); your request is
  `(skänkel − tygel×0.9) × 3.2`; tension adds speed on a forward-going horse.
  A heavy horse (`tyngd`) accelerates and decelerates more slowly.
- **Gait follows tempo**, with hysteresis so it does not flicker at the boundaries:
  `halt` 0–0.5, `skritt` (walk) 0.5–2.2, `trav` (trot) 2.2–5.0, `galopp` (canter)
  5.0+ m/s.
- **Each scale level approaches its own target**, then the floor rule clamps it.
  Targets depend on tempo stability, turn radius (tight turns at speed cost
  `rakriktning`), rein inside the band, rising trot on the correct diagonal, and
  accumulated half-halt quality.
- **Rang** (the horse's opinion of you) drifts slowly up when you ride well and
  down when you ride badly, and it persists between sessions.

### Group expectations (used for grading)

```
ledlektion .25 · knatte .35 · minior .42 · grupp1 .52 · grupp2 .58
grupp3 .64 · grupp4 .70 · grupp5 .76 · hoppgrupp .72
```

## 2. The day, in order

This chain is the game. Each step gates the next.

1. **Arrive on foot** at the yard from Husbyvägen. Walk in third person (WASD,
   Shift to jog, E to interact, V toggles map view).
2. **Talk to the riding teacher** in the stable aisle. She *assigns* you a horse —
   you never choose. Being given a better horse is the reward.
3. **Fetch the horse from the paddock.** Put on the headcollar and lead it back;
   the horse follows your footprint trail 2.2 m behind. In rain or below 9 °C it
   wears a rug and comes in muddy.
4. **Wash box (spolspilta)** if the legs are muddy — drag the hose over the legs
   and belly. Mud left on costs `dagsform` and the teacher comments on it.
5. **Tack room (sadelkammare):** every horse has its own saddle on its own rack
   and its own bridle on its own hook, each with a name plate. Taking the wrong
   one is refused with a comment.
6. **At the box:** take off the rug, muck out, feed and water.
7. **Grooming (skötsel)** — four handgrips, see §5.
8. **Lead the horse** to the indoor school, the outdoor arena, or the forest trail.
9. **Mount at the gate. Ride the lesson.**
10. **Grade, feedback, progression.** Then walk off (skritta av) on a long rein.

There is a whiteboard in the service end with the day's schedule as a live
checklist of exactly these steps.

## 3. The horses — 17 individuals from the real club

Fields: `känslighet, framåtbjudning, förlåtande, skygghet, hoppkapacitet,
hopplust, tyngd, utbildning, maxhöjd` (metres), plus quirk flags.

| Name | Breed | Type | Born | känsl | framåt | förlåt | skygg | hoppkap | hopplust | tyngd | utb | maxhöjd | quirk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Toblerone | Fjordhäst | ponny C | 2007 | .35 | .42 | .95 | .05 | .72 | .78 | .62 | .90 | 0.75 | – |
| Cosmo M Z | Belgiskt varmblod | häst | 2012 | .42 | .50 | .80 | .15 | .72 | .75 | .42 | .68 | 0.90 | – |
| Air Italia | Danskt varmblod | häst | 2011 | .45 | .50 | .72 | .20 | .60 | .65 | .40 | .65 | 0.80 | – |
| Larry | Irländsk sporthäst | häst | 2016 | .55 | .58 | .70 | .18 | .80 | .80 | .35 | .72 | 0.95 | – |
| Hamilton | KWPN | häst | 2011 | .75 | .62 | .50 | .35 | .72 | .75 | .32 | .72 | 0.90 | – |
| Conor | Ungerskt halvblod | häst | 2016 | .88 | .55 | .32 | .28 | .70 | .70 | .22 | .70 | 0.85 | – |
| Crokino | KWPN | häst | 2011 | .78 | .52 | .55 | .42 | .68 | .62 | .38 | .72 | 0.85 | **rädd för spö** |
| Bränntomts Lydia | Connemara | ponny D | 2003 | .30 | .45 | .95 | .06 | .72 | .82 | .42 | .80 | 0.75 | – |
| Dexter | Import Polen | ponny D | 2015 | .60 | .90 | .52 | .22 | .88 | .90 | .18 | .62 | 1.00 | – |
| Lady | Welsh Cob | ponny C | 2009 | .32 | .40 | .92 | .08 | .58 | .60 | .55 | .72 | 0.70 | – |
| Chip | Gotlandsruss | ponny B | 2013 | .38 | .55 | .85 | .12 | .55 | .70 | .30 | .58 | 0.60 | – |
| Tina | New Forest | ponny D | 2010 | .48 | .46 | .74 | .15 | .62 | .66 | .38 | .66 | 0.75 | **kittlig** |
| Westside | Svenskt varmblod | häst | 2014 | .50 | .55 | .68 | .22 | .70 | .72 | .38 | .66 | 0.85 | – |
| Makadu | Import Irland | häst | 2012 | .44 | .48 | .75 | .16 | .66 | .70 | .45 | .64 | 0.80 | **blåser upp magen** |
| Mara | Hannoveranare | häst | 2013 | .58 | .52 | .62 | .25 | .68 | .64 | .36 | .68 | 0.85 | – |
| Husky | Import Polen | häst | 2015 | .46 | .60 | .66 | .30 | .72 | .74 | .34 | .60 | 0.85 | **svårfångad** |
| Kennedy | Svenskt varmblod | häst | 2016 | .70 | .58 | .45 | .38 | .75 | .78 | .30 | .55 | 0.90 | – |

**The quirks must actually change play:**

- *rädd för spö* — pressing F spikes tension. The horse list warns you; using the
  whip anyway is your fault.
- *kittlig* — during grooming, only slow strokes register. Fast ones do nothing.
- *blåser upp magen* — the girth silently loosens again over ~15 s. You must
  re-tighten right before mounting or the saddle slips.
- *svårfångad* — the first attempt to catch it in the paddock fails; stand still
  and approach again.

Each horse also has a coat colour, mane colour, blaze/socks markings, and whether
it has feathering, so it is visually recognisable.

**Horse memory:** per horse, persist `rang` (trust), number of lessons ridden
together, last `dagsform`, and any current injury/rehab. The horse remembers you.

**Horse pool by group** — sensitive horses are unlocked as a reward:

```
grupp 0 (ledlektion): Toblerone, Lydia, Lady
1: Chip · 2: Tina · 3: Cosmo, Air, Westside · 4: Husky, Mara
5: Larry, Dexter, Makadu · 6: Hamilton, Crokino · 7: Conor, Kennedy
```

## 4. Progression — "you start at the bottom and develop"

Ladder: `ledlektion → knatte → minior → grupp 1 → 2 → 3 → 4 → 5 → hoppgrupp`.

- After each lesson, average the per-exercise `inverkan` scores. If the average
  meets the group's expectation (§1) and you were not eliminated, the lesson counts
  as approved. **Two approved lessons in a row promote you.** An elimination costs
  one earned lesson.
- Jumping only exists in `hoppgrupp`. Outdoor lessons open from grupp 3; the forest
  hack from grupp 3.
- Keep the last 20 lessons as history and show it on the menu.

## 5. Grooming (skötsel) — the twenty minutes that decide the ride

One canvas with the horse in profile, four steps:

1. **Visitera** — click the corners of the mouth and the saddle area to check for
   rubs before putting anything on.
2. **Rykta** — drag across eight body zones, in the direction of the coat
   (front to back). Coverage is per zone.
3. **Kratsa hovar** — click a hoof to pick it up, then drag downwards to pick it
   out. All four.
4. **Sadla** — drag the saddle to the right place (just behind the withers) and
   drag the girth into the green band.

Outputs: `dagsform` (0..1) and `sadellage` (0..1), plus a list of `risker`.
**`dagsform` scales the entire jump-take-off quality, and `sadellage` caps
`lösgjordhet`.** That is *why* the twenty minutes exist. Skipped steps produce
risks (`sten_i_hoven`, `missat_skav`, `lera_kvar`) which become injuries the next
day, forcing rest and then a walk-and-trot-only rehab lesson.

Yesterday's `dagsform` carries into today. A horse that was ridden in the previous
session is not rested and loses 0.08.

## 6. The stable chores

- **Mocka** — seven droppings placed deterministically per horse; click each to
  fork it into the barrow, then spread fresh shavings.
- **Fodra** — read the feed chart on the box door, then choose hay (1/2/3 kg),
  hard feed (`inget / müsli / betfor / pellets`) and fill the water. Each horse has
  a specific correct answer and a one-line note in the stable's own voice, e.g.
  Toblerone: *"Lättfödd fjording — inget kraftfoder, han blir rund av luft."*
- Mucking and feeding set `stallro` (stable calm), which feeds into tension in §1.

## 7. Lessons, built from an exercise bank

11 knowledge chapters and 16 exercises, each exercise carrying its own weights
against the training scale, its purpose, three execution steps, and two common
faults. Examples:

- *Skritt på lång tygel* (walk, all groups) — weights takt .4, lösgjordhet .5, kontakt .1
- *Övergångar trav–skritt–trav* — takt .3, lösgjordhet .2, kontakt .2, schvung .3
- *Stora volten, 20 m* — takt .3, lösgjordhet .2, rakriktning .4, kontakt .1
- *Skänkelvikning på diagonalen* (grupp 2) — rakriktning .35, lösgjordhet .25, kontakt .2, takt .2
- *Framdelsvändning* (grupp 2) — rakriktning .3, kontakt .2, samling .3, lösgjordhet .2
- *Öppna längs långsidan* (grupp 3) — rakriktning .3, samling .25, lösgjordhet .25, schvung .2
- *Kontraböjning på spåret* (grupp 3) — rakriktning .4, kontakt .3, lösgjordhet .3
- *Galoppfattning i hörnet* (grupp 2) — schvung .35, takt .25, lösgjordhet .2, kontakt .2
- *Kontragalopp* (grupp 5) — rakriktning .3, samling .3, takt .2, schvung .2
- *Rid vägen — banan utan hinder* (hoppgrupp) — takt .3, rakriktning .3, schvung .2, samling .2

The teacher builds each lesson from the bank by group and by a daily seed, so two
lessons are never the same: always a walk on a long rein first, then a walk/halt
exercise, one or two trot exercises, a canter exercise, and either the jumping
course (hoppgrupp) or a walk-off. Draw the riding pattern for the current exercise
on the 20×60 arena diagram (circles, serpentines, diagonals, the leg-yield line).

There is also a theory room: three multiple-choice questions drawn from the
knowledge chapters, rotating with the day.

## 8. Jumping

Six fences at 0.60 m by default. There is no jump button — you ride the line, and
the take-off is computed from the approach:

- While you are pointed at the next fence, within 26 m and going forward, show a
  live line reading like `"3 helsteg — nära avstånd"` computed from the distance
  and the horse's current stride length.
- At the take-off zone, take-off quality = the approach solution × the training
  scale × `(1 − spänning)` × `dagsform`. The outcome is clear / knockdown / refusal,
  drawn against the horse's `hoppkapacitet`, `hopplust` and `maxhöjd`.
- Judge to the Swedish rules for a low class: 4 faults per knockdown, refusals
  accumulate, three refusals is elimination. Show a live protocol.

## 9. Competition

- **Påskhoppet** in the indoor school, three classes (0.60 / 0.75 / 0.85 m),
  hoppgrupp only. Full grandstand, secretariat, start order with you slotted in.
- **Dressyr LC** on the outdoor arena from grupp 3: enter at A, halt and salute at
  X, 20 m circle, three-loop serpentine, free walk on the diagonal, canter, closing
  halt and salute. Score in per cent; judge in the box at C.
- The rest of the field is the club's own combinations, simulated deterministically.
- **Rosettes** in the Swedish colour order — 1st blue-and-yellow, 2nd blue, 3rd red,
  4th white, 5th green. They are saved on the rosette wall in the club room and the
  horse's best one hangs on its box door. A competition never promotes you; the
  rosette is the pay.

## 10. The facility (build it to scale, ~150 × 150 m)

- **Ridhuset** — indoor school, 20 × 60 m arena inside a 30 × 72 m hall. White kick
  boards with a black plinth, dressage letters, sponsor banners and mirrors along
  the west wall, a three-step grandstand in the east with a judge's box, and
  Café Krubban on a mezzanine over the south end with a staircase up.
- **Stallet** — a centre aisle with boxes on both sides, composite fronts with
  galvanised bars and name plates, horses' heads over the doors. A club end
  (common room, tack room, theory room) and a service end (wash box with a hose
  reel, feed room, muck store).
- **Uteridbanan** — outdoor arena with a wooden fence.
- **Hagar** — paddocks with grazing horses, an outdoor arena for warm-up, a forest
  track around the property, a car park, a horsebox, a silo, bales, picnic tables,
  a flagpole and floodlight masts.
- Weather each day: sun / overcast / rain, 7–17 °C. Rain makes the going heavy
  (lower `schvung`), and cold or rain means the horses wear rugs in the paddock.

## 11. Look and feel

Warm, saturated autumn afternoon — golden low sun, orange and yellow trees, deep
green grass, warm sand. Stylised and soft rather than realistic: rounded
silhouettes, no hard black shadows, a warm rim light on the edges. Think a cosy
mobile horse game, not a simulator.

Horses must read as *animals*: one continuous body (chest deep and narrow, ribcage
widest at the girth, tucked flank, round quarters), a deep narrow neck, a head with
a broad forehead and a tapering muzzle, a flowing mane falling to one side and a
tail that narrows towards the ground. Riders are people: riding jacket, light
breeches, tall boots, a helmet sitting *above* the brow, hair with a ponytail, and
a face with eyes and a mouth. **Never build a character out of separate spheres with
visible ball joints — limbs should meet directly.**

UI: dark panels, a gold accent, a serif for headings and a mono for labels and
numbers. All in-game text is Swedish and written in the voice of a riding teacher —
short, concrete, never patronising.

## 12. Sound

Synthesise everything with the Web Audio API — no audio files. Hoof beats in the
rhythm of the gait with a different timbre per surface (fibre sand, gravel, wet),
footsteps, whinnies, snorts, stamping, stable ambience, wind and birds outdoors,
rain, and the competition bell. The riding teacher's calls use Swedish speech
synthesis (`sv-SE`), only while mounted. `M` mutes everything.

## 13. Definition of done

A player can walk in from the road, be given a horse, fetch it, wash its legs,
fetch the right saddle, muck out, feed it, groom it, tack up, lead it out, ride a
full lesson graded against the training scale, get feedback, be promoted after two
good lessons, and eventually ride Påskhoppet and hang a rosette on the box door —
and all of it is still there tomorrow.
