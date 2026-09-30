# JEV-POC-2 — Roblox server-side shadow for Ugneta — Acceptance Contract

Issue #270 · base `origin/main` 7922d70 · branch `claude/jev-ugneta-shadow-poc`
Builder: Claude · Reviewer: ChatGPT · Product acceptance: Tobias
Status: **CONTRACT — BLOCKED ON ONE DECISION (§2.1). No implementation before it is resolved.**

## 1. Goal

A server-side experiment that is off by default. For each eligible Ugneta
coaching moment, it records Jev's coaching-focus choice alongside Ugneta's
deterministic choice, using real Roblox runtime data. It must have zero effect
on what the player sees or on game state. It is an experiment, not an
activation.

## 2. Observed state on `main` 7922d70 (verified)

| Fact | Evidence |
|---|---|
| Ugneta's live focus is chosen **on the client** | `client/LektionController.luau:466` calls `UgnetaTema.steg`. There is no server caller; the server files only mention it in comments (`HorseService.luau:507`, `VoltObservation.luau:7`). |
| Ugneta's attempt card and after-ride summary are also client-side | `client/UgnetaController.luau:909` `Ugneta.observationer`, `client/LektionController.luau:551` `Ugneta.efterrittFor` |
| No remote carries the exercise, phase, attempt or chosen focus to the server | `shared/HorseCore/Networking.luau:23–80`. The riding remotes are only `StateSync`, `RidingIntent`, `Mount*` and `RidaNu`. |
| Ugneta's inputs are client telemetry | `Lektion.kvalitet(tm)` reads `svarstid, etableringstid, paradKvalitet, fokus, spanning, fart, onskadFart, balans, mjukhet, svangradie` from `Telemetri.las` (client) |
| What the server does own | Gait ladder (`halt/walk/trot/canter`, back-up), `energi` 0–1, `Dagsform`, `RidObservation` (distance, speeds, turning, tempo `{gangart, n, medelFart, stdFart, variation}`, validity), `RidPlatsObservation` (arena position/status), `VoltObservation` (deviation vs. 10 m radius, laps, return), `RidLogg` (gait changes) |
| Exercises on Roblox | 6: `halt_skritt, skritt_trav, storvolt, horn, trav_skritt, galoppfattning` (`RidKanon.UGNETA.ORDNING`); 2 attempts of 22 s each |
| Ugneta's decision space | Dimensions `linje, rytm, balans, timing, mjukhet, respons, tempo` → cues `vagen, framat, sits, hand, lugn, timing` (`RidKanon` l.692–709), plus `hast` (the horse's own tension) and silence. `rytm` is never measured on Roblox. |
| HttpService | Not used anywhere in `roblox/` today |
| PII near the data | `userId` is inside every observation snapshot; `player.Name` appears in `ForstaRitten` prints. The shadow must never forward snapshots as-is. |

### 2.1 BLOCKER — what to compare against does not exist on the server

#270 asks the server to compare Jev against "Ugneta's existing deterministic
choice using real server telemetry" and "only server-derived signals". On
`main` the server has neither Ugneta's choice nor the exercise or phase it
belongs to, and Ugneta decides from client telemetry that the server never
receives. This can't be built literally without one of these:

| Option | What it means | Trade-off |
|---|---|---|
| **A (recommended)** Label mirror | Behind the dev flag, the client sends the server a small **enum-only** copy of the decision it already made (`ovningId`, `forsok` 1/2, `kalla`, `dim`, `cue`, `sort`). No text, no numbers, no player data. The server validates it against allow-lists. **Jev receives only server-derived telemetry** plus the exercise id. | Compares against the *real* player-visible Ugneta. The label is client-reported, but it is only used for shadow comparison, is validated, and can't affect anything. This needs one new remote and a small client hook, but player output doesn't change. Jev and Ugneta see different evidence; that gap *is* evaluation question 4. |
| B Server re-derives a "Ugneta" | The server computes its own deterministic focus from server telemetry. | Not the existing Ugneta; it invents a new baseline. **Not recommended.** |
| C Send client quality scores to Jev as well | Jev sees the same inputs as Ugneta. | Breaks the "server-derived only" constraint. **Not recommended** without an explicit override. |

**Decision needed from Tobias (ChatGPT review welcome): A, B or C.**
Everything below assumes **A**.

## 3. Source of truth

- #270 body plus the Tobias decision comment (2026-09-30 17:31Z); ChatGPT review #269 comment 5916342511
- TypeSafe SDK `@typesafe-ai/sdk@0.6.0`, `dist/index.mjs` (verified in `UBRF-jev-poc/experiments/jev-poc-1/node_modules`):
  - `POST https://api.typesafe.ai/v1/systemone`
  - Headers: `Authorization: Bearer <key>`, `Content-Type: application/json`, `Accept: application/json`
  - Body `{ state: <JSON|string>, questions: { focus: { type: "choice", instructions, criteria: {label: description} } }, model }` (the SDK default model is `jev-latest`; POC-1 got `jev-1.13.0`)
  - Response body is returned unchanged: `{ model, answers: { focus: { type: "choice", choice, confidence, probabilities: {label: p} } }, usage }`
  - Errors: 400/401/403/404/422/429/5xx; request id in `x-typesafe-request-id`. The SDK retries by default; **this adapter will not retry.**
- Roblox Creator docs (read 2026-09-30):
  - `HttpService:GetSecret(key)` returns a `Secret`, and `Secret:AddPrefix("Bearer ")` is the documented pattern for an auth header.
  - `RequestAsync` accepts a `Secret` in `Headers` and a `Timeout` in seconds.
  - The limit is 500 external requests per minute.
  - Secrets are server-only and not available locally unless added as Studio local secrets.
  - **Direct Roblox → TypeSafe is therefore supported and safe. No proxy is needed.**

## 4. Required change (under option A)

All new code is Luau, under the dev flag. The flag defaults to off, so every
path is inert.

1. **Flag** — `ServerStorage` attribute `JevShadowEnabled == true` (server-only; clients can't read ServerStorage). A missing or non-true value means off: no remote listener, no HTTP call, no secret read.
2. **`shared/HorseCore/JevShadowPolicy.luau`** (pure, no services):
   - `validera(evidens)` checks known enums, types, finite numbers and allowed ranges, and reports missing required fields. It returns `ok` or `invalid_input` plus a reason.
   - `hardGate`: the attempt isn't closed, a welfare stop is active, or it's inside the cooldown.
   - `tolka(svar)`: the choice must be on the allow-list, and confidence must be a finite number in [0, 1].
   - A Jev-focus ↔ Ugneta-cue mapping, where the label set is Ugneta's own cues plus silence.
3. **`server/JevShadow.luau`**:
   - Builds sanitized evidence from server observations. It includes an explicit `absent` list, and never includes `userId`, `hastId`, names or text.
   - Anonymous `provId` = `HttpService:GenerateGUID(false)` per sample; `t` = seconds since the ride started.
   - Calls `RequestAsync` in a `task.spawn` wrapped in `pcall`, with `Timeout = 3` s and no retry.
   - Cooldown ≥ 10 s per ride; at most 1 request in flight per ride; a global cap of ≤ 20 per minute.
   - Records `jev | timeout | api_error | invalid_input | hard_gate` in an in-memory ring buffer (at most 200 entries). Readable from the server console / MCP; no DataStore.
   - Never prints the secret, headers or raw bodies. Errors are logged by status code only.
4. **Mirror remote** `JevShadowSpegel` (RemoteEvent, client → server): created only when the flag is on. The client hook sits behind `LektionController:466/499`, fires after Ugneta has already been shown, and is fire-and-forget. The server validates the payload and drops anything invalid as `invalid_input`.
5. **Specs** registered in `tests/kor.sh` and `tests/build.py`. Spec names avoid the substring `ugneta`, which would route them to the PARITET bundle.

## 5. Out of scope

- Any player-visible Jev output, text, UI or sound.
- Writes to physics, horse state, lesson state, score, progression, competition or persistence.
- A proxy or backend server; DataStore logging; production enablement.
- Web implementation. This is a server-side experiment with no player-visible change. The parity rule in `CLAUDE.md` covers changes that affect the playable experience, and this one doesn't. **Please confirm this reading explicitly**, since the rule has no "experiment" clause.
- Porting POC-1 files; only the policy concepts are re-implemented in Luau.
- Changing Ugneta's deterministic logic.
- The P3 branch.

## 6. Acceptance tests

Automated, in `kor.sh` and CI:

1. The validator accepts valid known telemetry.
2. A malformed enum, NaN, ±inf, an impossible range or a missing required field each gives `invalid_input` and **zero HTTP calls** (checked with a counting stub). This includes an X09-style case.
3. The allow-list rejects unknown and wrong-case Jev choices, as well as confidence that is NaN, missing or outside [0, 1].
4. A thrown `RequestAsync`, a non-2xx response, a timeout and an undecodable body are each recorded as `api_error` or `timeout` only. No error propagates.
5. Gameplay isolation: with the flag on vs. off, the deterministic Ugneta output and a snapshot of the session and attributes are identical, including when the stub throws.
6. The serialized request body contains no `userId`, name, `DisplayName` or GUID-with-braces; the key set equals the allow-list exactly.
7. A sentinel secret never appears in anything captured from `print`/`warn` or in the ring buffer.
8. Rate: N triggers within the cooldown give 1 request, and a burst above the global cap is refused.
9. Flag off means no remote, no `GetSecret` and no HTTP call.
10. **Falsification:** one deliberate break each in the validator, the allow-list and the isolation must turn a test red. Each is committed first and restored from a copy, never with `git checkout`.

Runtime (Studio, needs the human step in §7):

11. Real shadow samples from real riding in Studio, with sample count, agreement rate, a disagreement table, latency p50/p95/max and error rates reported as measured. No sufficiency claim.
12. Ride stability with the shadow on vs. off: FPS via RenderStepped and ride-loop hitches, measured in the same session.

## 7. Human gate

- **Tobias:** decide §2.1.
- **Tobias:** add the TypeSafe key as a Studio local secret (Game Settings → Security) and enable HTTP requests in Studio. Claude never sees or handles the key.
- **Tobias:** the later product decision on any player-visible Jev (not part of this package).
- No merge and no production enablement.

## 8. Known uncertainty

- `VERIFIED`: everything in §2 and §3.
- `ASSUMPTION`: Studio local secrets behave like published secrets for `RequestAsync`. This will be verified at runtime, and marked NOT_TESTED if it isn't.
- `ASSUMPTION`: `jev-latest` resolves to the same model as POC-1. The shadow records `model` from every response.
- Limitation: server telemetry is richest for `storvolt` (volt geometry). For the other 5 exercises it is only gait, tempo and position, so coverage per exercise will be uneven and will be reported that way.
- The mirror label is client-reported. That is fine for shadow comparison, but it is not tamper-proof.
