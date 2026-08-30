# Gate G01 — First Playable Horse Loop

Status: **ACTIVE**

Primary platform: **Roblox**  
Parallel playable platform: **HTML/web**

## Product outcome

UBRF must become a playable horse game, not only a reconstruction of the facility.

The first complete loop is:

**arrive at UBRF → get/select an assigned horse → approach safely → prepare the horse → lead out → enter the riding hall → mount → complete one simple riding exercise → dismount → return the horse → perform basic aftercare → receive feedback.**

The player should understand through play that horse life is both enjoyable and a responsibility.

## Design rules

1. Fun first, but never empty. Every responsibility mechanic must either create a meaningful choice, feedback, consequence, mastery or connection to the horse.
2. Learning by doing. Prefer action and horse/world feedback over quizzes and long text.
3. Roblox is the primary game target. Web remains a real playable parallel implementation and must not be allowed to decay into a non-playable mockup.
4. Reuse the existing HorseCore/riding stack. Do not build a second riding engine for G01.
5. Do not invent UBRF-specific facts. Unknown facility details remain `REFERENCE GAP`.
6. Build vertically. Each implementation slice must leave the game runnable.

## Existing systems to reuse

### Roblox

- `HorseCore/Config.luau` — horse/movement configuration.
- `HorseCore/Gaits.luau` — halt, walk, trot, gallop definitions and transitions.
- `HorseCore/StateMachine.luau` — locomotion states.
- `HorseCore/RigAdapter.luau` — horse rig abstraction.
- `HorseService.luau` — server-authoritative horse registration, mount ownership, stamina and state validation.
- `MovementController.luau` — riding movement and turning.
- `RiderController.luau` — rider motion/balance.
- `CameraController.luau`, `AnimationController.luau`, sound/effects and touch controls.
- `InteractionController.luau` — proximity-based mounting.

### HTML/web

The web implementation already contains richer loop concepts that can be used as product reference rather than copied blindly:

- horse assignment/selection and horse personalities;
- stable chores;
- tack-room selection;
- grooming and washing;
- exercises and riding feedback;
- aftercare/progression.

### Data

- Supabase migrations already contain riding-school and horse data structures.
- GitHub remains the implementation source of truth. Google Drive is not a build dependency.

## Missing systems for a complete G01

1. A server-authoritative player/horse session and assignment flow.
2. A pre-ride preparation state that gates mounting.
3. Ground handling / leading.
4. Location-aware transition from stable to riding hall.
5. One simple riding exercise with measurable completion.
6. Dismount/return flow.
7. Basic aftercare.
8. End-of-loop feedback connecting care, horse state and riding result.
9. Cross-platform acceptance tests for the same learning/gameplay rules.

## Slice G01.1 — Assigned horse + preparation gate

This is the first implementation slice.

Flow:

**horse assigned → approach calmly → basic check/visitation → groom → prepare correct tack → mount unlocks.**

### Why this slice first

- It turns existing riding tech into an actual game objective.
- It makes responsibility a gameplay prerequisite instead of decoration.
- It reuses the existing mount and riding systems.
- It can run even before leading, lesson scoring and aftercare exist.
- It has a clean server-authoritative boundary.

### G01.1 acceptance

- A player is assigned at most one tagged horse.
- A horse is assigned to at most one player.
- If no horse exists, the game reports that state; it does not invent/spawn a fake production horse.
- The player sees a clear current objective.
- Preparation actions only work on the player's assigned horse and only at close range.
- Preparation order is enforced server-side.
- The mount prompt is not offered as the primary action before preparation is complete.
- The server refuses mounting before the assigned horse is ready.
- On completion, the existing riding stack is used unchanged for actual riding feel.
- Desktop/gamepad/touch architecture remains compatible.

## Later slices

### G01.2 — Lead the horse
Ground handling, safe leading position, follow behaviour and stable → horse passage → riding hall traversal.

### G01.3 — First lesson
Mount in the riding hall and complete one beginner exercise, initially walk-based and forgiving.

### G01.4 — Return + aftercare
Dismount, lead back, basic post-ride care and equipment return.

### G01.5 — Learning result
A short result that explains what the player did well, what the horse communicated, and one thing to improve next time.

## Gate completion

G01 is not complete until Tobias can play the entire loop in Roblox Studio/Roblox and the corresponding core loop remains playable on the web.
