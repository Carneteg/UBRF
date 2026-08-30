# G01 — Horse identity ↔ Roblox rig contract

Gate G01 separates **who the horse is** from **how the horse is rendered**.

## Canonical identity

`src/spel/hastar.js` is the gameplay-data source and exports the same ids to
`roblox/game/UBRFSpel.luau`.

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

`GameplayService` uses **only `HorseId`** to bind the physical model to the
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
model for the same player.

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
