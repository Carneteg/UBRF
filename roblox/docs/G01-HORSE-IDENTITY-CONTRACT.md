# G01 — Horse identity ↔ Roblox rig contract

Gate G01 separates **who the horse is** from **how the horse is rendered**.

> **Status: target contract, not full current behaviour.** The canonical identity
> data described below is implemented by G01 S2c. The rig-binding rules are not:
> `GameplayService` does not exist yet, and `HorseService` still binds on
> proximity rather than on identity. The gap section remains authoritative for
> what is not yet implemented.

## Canonical identity

`src/spel/hastar.js` is the gameplay-data source. It contains the **33 active
UBRF horses/ponies** in the versioned source snapshot
`references/data/ubrf-hastar-2026-09-01.json`, taken from `public.hastar`
(upstream `ubrf.se/hastar`). The factual fields are checked against that snapshot
by `node tools/exportera-spel.js --kontrollera`.

Roblox receives the same ids through generated `roblox/game/UBRFSpelData.luau`.
`roblox/game/UBRFSkotsel.luau` carries the separately generated care canon, and
the thin `roblox/game/UBRFSpel.luau` wrapper exposes both through the existing
`ReplicatedStorage.UBRFSpel` contract. CI fails if either generated module drifts
from its JS source.

Examples:

- `toblerone` → Toblerone
- `cosmo` → Cosmo M Z
- `air` → Air Italia
- `bing` → Bing

The id is the stable machine key. `kallaId` links a gameplay id to the source
snapshot id. Display names may contain spaces or punctuation; ids must not
silently change with formatting.

Real-world fields and gameplay fields are deliberately separate. Name, type,
birth year, breed, height/import where present, source pony category and
source description are source-backed. 0–1 riding parameters, visual colours and
unverified individual feeding values are gameplay/presentation values and must
not be presented as measured facts. Dante's source pony category is missing, so
the current size category is explicitly an `ASSUMPTION`, not verified UBRF data.

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
model for the same player. **Such a path still exists in the current runtime** —
see the gap section.

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

## Current implementation state after S2c

| claim | state |
|---|---|
| `src/spel/hastar.js` defines the active roster | **yes — 33 active horses/ponies** |
| source-backed factual fields are versioned and checked | **yes — against `references/data/ubrf-hastar-2026-09-01.json`** |
| Roblox exposes the same roster via `UBRFSpel` | **yes — generated `UBRFSpelData` + thin wrapper** |
| care data remains available through the same `UBRFSpel` facade | **yes — generated `UBRFSkotsel` + wrapper** |
| `roblox/docs/HORSE-MODEL-SPEC.md` exists | **yes** |
| `CollectionService` tag `Horse` is in real use | **yes — `HorseService`, `InteractionController`** |
| `StallService` assigns a horse per player | **yes — `Stallet.tilldela`** |
| `HorseService` owns mount/dismount | **yes** |
| `GameplayService` exists | **no — named only in docs until later G01 slice** |
| runtime enforces the `HorseId` assignment | **no** |
| `G01Phase` / `waiting_model` exists | **no** |

### The gap that matters

`HorseService.tryMount(player, model)` accepts any model tagged `Horse` within
`MountRange` and does not yet consult the identity assignment from `Stallet`.
The attributes it reads concern riding state, not canonical identity.

So the second code path this contract forbids is still possible until the later
binding slice: a player assigned one horse identity could mount another tagged
horse model by proximity. S2c fixes **who the horses are**; it does not pretend
to have implemented the later rig arbitration.

### What this contract does not settle

The contract fixes **the key**, not the **arbitration**. Two questions remain for
when `GameplayService` is implemented:

1. **Shared rigs.** If two players are assigned the same horse identity in one
   server and only one matching rig exists, the implementation needs an explicit
   arbitration rule: per-player instances, queue, or a waiting state.
2. **Mounting someone else's horse.** Identity binding does not alone define
   whether a player may mount a rig already bound to another player. That is a
   separate product/gameplay decision and must not be smuggled in as a data
   assumption.
