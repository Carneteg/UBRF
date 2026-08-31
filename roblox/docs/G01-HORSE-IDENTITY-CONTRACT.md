# G01 — Horse identity ↔ Roblox rig contract

Gate G01 separates **who the horse is** from **how the horse is rendered**.

> **Status: target contract, not current behaviour.** Everything under
> "Canonical identity" is already true in `main`. The binding rules are not:
> `GameplayService` does not exist yet, and `HorseService` today binds on
> proximity rather than on identity. See "Current state in `main`" at the bottom
> for exactly what holds and what does not. The document is written as the
> contract implementations must satisfy, and the gap section is what makes it
> checkable.

## Canonical identity

`src/spel/hastar.js` is the gameplay-data source and exports the same ids to
`roblox/game/UBRFSpel.luau`. Seventeen horses are defined, and the id sets are
identical on both sides — enforced by `node tools/exportera-spel.js
--kontrollera`, which runs in CI and fails if the export drifts from the source.

Examples:

- `toblerone` → Toblerone
- `cosmo` → Cosmo M Z
- `air` → Air Italia

The id is the stable machine key. The display name may contain spaces or change
formatting; the id must not silently change with it.

## Required on every G01 production horse rig

The Roblox `Model` must already satisfy `roblox/docs/HORSE-MODEL-SPEC.md`, be
tagged `Horse` with `CollectionService`, and additionally carry:

```text
HorseId = "toblerone"    -- string attribute; must exist in UBRFSpel.hastar
```

`GameplayService` shall use **only `HorseId`** to bind the physical model to the
horse identity assigned by `StallService`.

`HorseName` is presentation. GameplayService sets it from canonical horse data
when the model is bound; it is not assignment authority.

`AssignedUserId` is runtime ownership/binding state. It is written by the game
and must not be authored as a persistent identity value in the asset.

## Authority boundary

```text
UBRFSpel / Stallet
      ↓
StallService            owns horse identity + box assignment
      ↓ HorseId
GameplayService         binds identity to a tagged physical rig + owns prep phase
      ↓
HorseService            owns mount/dismount/rider/riding state
```

There must never be a second code path that independently chooses another horse
model for the same player. **Such a path exists in `main` today** — see the gap
section.

## Missing rig behavior

If a player is assigned `air` but no tagged model with `HorseId = "air"` exists,
the correct state is:

```text
G01Phase = "waiting_model"
```

The game must **not** spawn a block horse and call it production, must not bind a
different horse, and must not lose the player's canonical horse identity.

A clearly marked development-only test rig may satisfy this contract for code
falsification. Human production play acceptance still requires a real rigged
horse asset that satisfies `HORSE-MODEL-SPEC.md`.

## Current state in `main`

Verified against `21c4d91` on 2026-08-31. This section exists so the contract can
be checked rather than assumed, and so nobody reads the present tense above as a
description of what the code does.

| claim | holds in `main`? |
|---|---|
| `src/spel/hastar.js` defines the ids | **yes** — 17 horses |
| `roblox/game/UBRFSpel.luau` exports the same ids | **yes** — id sets are identical, and `node tools/exportera-spel.js --kontrollera` gates it in CI |
| `roblox/docs/HORSE-MODEL-SPEC.md` exists | **yes** |
| `CollectionService` tag `Horse` is in real use | **yes** — `HorseService:38`, `InteractionController:57` |
| `StallService` assigns a horse per player | **yes** — `StallService.tilldela` |
| `HorseService` owns mount/dismount | **yes** |
| `GameplayService` exists | **no** — named only in docs |
| any code reads the `HorseId` attribute | **no** |
| `G01Phase` / `waiting_model` exists | **no** |

### The gap that matters

`HorseService.tryMount(player, model)` accepts **any** model tagged `Horse`
within `MountRange` (default 14) and checks only that the session exists, that
the horse is free, and that the player is not already riding. It never consults
the assignment made by `StallService`.

The attributes it does read are `Gait` and `GaitCeiling`. It reads no identity at
all.

So the "second code path" this contract forbids is not hypothetical: today a
player assigned `air` can mount `toblerone` by standing next to it. Nothing
breaks, because nothing yet connects assignment to rig — which is precisely why
the connection has to be specified before it is written rather than after.

### What this contract does not settle

The contract fixes **the key**, not the **arbitration**. Two questions are still
open and should be answered when `GameplayService` is implemented:

1. **Shared rigs.** If two players are assigned `air` in the same server and
   only one `HorseId = "air"` rig exists, who gets it? Options are per-player
   rig instances, a queue, or reporting `waiting_model` to the loser. The
   contract's `waiting_model` state describes a missing rig, not a contested
   one.
2. **Mounting someone else's horse.** Binding on identity does not by itself say
   whether `tryMount` should refuse a rig bound to another player. Refusing is
   the likely answer for a teaching game, but it is a design decision and is not
   implied by this document.
