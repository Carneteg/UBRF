# D4a: the prize foundation — a durable, confirmed right and a read model for the trophy cabinet, inert

Status: contract written before code, 2026-09-28.
Order: [CHATGPT_REVIEW_B4C_ACCEPTED](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5869916359) (D4a). Base `56a1ecd`.
**No awarding trigger, no UI, no caller from ClearRound/D2, no rosette.** Physical test last.

## What already exists (verified in the code)

**Save schema v2 (`HorseCore/Sparning.luau`)** has `priser[id] = Pris { typ, resultatId?, farg?, nar }`:
- `typ` ∈ `placering | clear_round | deltagare`;
- `resultat[id]` is write-once;
- `karantan[id]` holds used ids that cannot be shown;
- the cap `MAX_PRISER` is 500;
- migration is v1 → v2, and a newer version is "framtida", so it is not written.

**`registreraPris`** is a **local preparation**: the id is the receipt, "finns"/"karantan" are refused, and a placement needs its result. **`SparService.skriv`** merges in `UpdateAsync` (what is in storage wins, the cap is checked against storage) and retries.

**The matrix gate D4-RÄTT** (`docs/LEVERANSMATRIS.md`): before any prize, a **server-validated right derived from a confirmed write** is required. It must handle ambiguous writes, retries and concurrent sessions. **No award may be made on the local answer.**

**So D4a builds exactly that missing piece. There is no new schema version:** v2 already separates type (`typ`), source (`resultatId` → `resultat`) and display (`farg`). A v3 would force a migration without new information.

## What is built

### 1. A deterministic receipt key (`Sparning.prisId`)
- `Sparning.prisId(typ, resultatId)` gives `"pris:" .. typ .. ":" .. resultatId`.
- It returns nil for an unknown type, an invalid `resultatId`, or a total length over `MAX_ID` (fail closed).
- **The same type and result always give the same id**, so a retry, a reconnect or a second session hits the same receipt, and `registreraPris` answers "finns".
- **One prize per result and type.**

### 2. A confirmed right (`SparService`)
`bekraftade[player]` = the prize map **as it lies in storage**:
- **on a successful read** (`ladda`): the loaded row's `priser`;
- **on a successful write** (`skriv` returns true with no conflict): the `priser` of the row the **committed** transform run returned. Roblox may run the transform again, so the last run is the one committed.
- **Unchanged:** after a write that failed, was refused (conflict, "full", a future save file) or was **ambiguous** (it landed, but the call threw). The prize then becomes confirmed at the next successful read or write that sees it in storage.
- **Never from `registreraPris`'s local answer.**
- `SparService.bekraftadePriser(player)` returns the cabinet read model (below) **only for confirmed prizes**.
- `bekraftade` is cleared with the session (`_glomForProv` and departure).

### 3. The cabinet read model (`Sparning.prisskap(priser, resultat)`, pure)
- It returns a frozen list, sorted by `nar` and then `id`, of:
  `{ id, typ, kalla = { resultatId, resultat = <a copy of the saved result or nil> }, visning = { farg }, nar }`.
- **Type, source and display are kept apart.**
- **Quarantined ids never appear**, since they are not in `priser`.
- **No performance numbers, bonuses or effects:** the record has no other fields, and a test checks the exact key set.

### 4. Migration and defaults
- **Unchanged.** A v1 save gives empty `priser`, so the cabinet is empty.
- A trashed prize entry goes to quarantine and is never listed.
- A future save file gives an empty confirmed set, and nothing is written.

### 5. Inert
**Nothing in `roblox/src` calls `registreraPris` or `bekraftadePriser` except `Sparning`/`SparService` themselves.** This is checked with grep in the report. A future award consumer must build on `bekraftadePriser`, **never** on the local answer.

## Product constraints (from #266; no new choice)
- Prizes are **memories/cosmetic only, never a bonus**.
- **A real Clear Round rosette only when the result can truly be established.** Today's simplified training course gives none.
- **No prize colour is invented:** `farg` stays as an optional display field. The placement colours in #266 §8 belong to D4b, and **the clear-round rosette's colour is a `[REFERENCE GAP]`** that is not needed now.

## Acceptance (`sparning-prisskap.spec`, the sparning bench and the real `SparService` against the datastore stub)
1. `prisId`: deterministic, the same for the same input, and nil for a bad type, a bad or empty `resultatId`, or excess length.
2. **Local registration is not confirmed:** `registreraPris` true, but `bekraftadePriser` is empty **before** the write.
3. **A successful write** confirms it: 1 entry, with type, source (with the result) and display separate, and the exact key set.
4. **Retry** (it landed, the answer was lost once): 1 prize in storage, and it is confirmed.
5. **An ambiguous write** (every attempt throws after landing, so `skriv` is false): the prize **is** in storage but **not** confirmed. A new `ladda` confirms it, **once**.
6. **The same id again** (after a reconnect, and in two concurrent sessions): still 1 in storage, and both sessions list the same single entry.
7. **A refused write** (a future save file in storage, or the cap exceeded): not confirmed.
8. **Migration:** a v1 save gives an empty cabinet; a trashed prize entry goes to quarantine and is not listed.
9. **Falsification:**
   - confirmation from the local answer;
   - confirmation after an ambiguous write;
   - a non-deterministic `prisId`;
   - quarantined entries listed;
   - an extra performance field in the record.

**Full suite; re-lock** (`Sparning`/`SparService` are mapped).

**Not tested:**
- a real DataStore in a published place;
- real network loss;
- two real servers at the same time.

All of this is PHYSICAL TEST LAST.
