# G01.1 — implementation notes

## Architectural decision

Do not replace or duplicate the riding engine.

The existing Roblox stack already owns responsive mounted movement, gait transitions, rider motion, camera, touch controls, stamina and server-authoritative mount ownership. G01.1 wraps that system with a game-session layer that answers a different question: **what must the player do with the horse before riding is allowed?**

## New boundary

`GameplayService` owns:

- one assigned horse per player;
- one player per assigned horse;
- G01 preparation phase;
- validation that actions target the assigned horse at close range;
- the preparation gate around the existing `HorseService.tryMount`.

`HorseService` continues to own:

- horse rig registration;
- actual mount/dismount mechanics;
- mounted ownership;
- stamina;
- riding-state validation.

`GameplayController` owns presentation only:

- today's horse;
- current objective;
- contextual preparation prompt;
- educational feedback returned by the server.

`InteractionController` still owns the mount prompt, but in G01 it only exposes that prompt when the assigned horse has reached `ready_to_mount`.

## Shared rule module

`HorseCore/Preparation.luau` is deliberately independent from UI and world geometry. It defines the ordered learning/gameplay contract:

`approach → check → groom → tack → ready_to_mount`.

That contract can be mirrored by the web implementation without copying Roblox UI or physics code.

## Intentional simplifications in G01.1

The first slice compresses real preparation into four meaningful actions. It does not yet simulate every brush stroke, every part of a full visitation, saddle fit or bridling interaction. Those can deepen later after the complete loop exists.

The important truth retained now is:

**approach safely → check the horse → make the coat/contact areas clean → prepare correct equipment → only then ride.**

## Next slice

G01.2 should add leading/ground handling and connect the assigned horse physically through:

**stable → horse passage → riding hall**.

Do not start G01.2 until G01.1 passes the executable test handoff and a basic Roblox Studio play check.
