# JEV-POC-2 — Roblox shadow for Ugneta (A') — Acceptance Contract

Issue #270 · base `origin/main` 7922d70 · branch `claude/jev-ugneta-shadow-poc`
Builder: Claude (sole writer) · Reviewer: ChatGPT · Product acceptance: Tobias
Decisions: ChatGPT A' #5916461758 · TOBIAS_DECISION A' #5916479865 (2026-09-30 17:38Z)
Status: **CONTRACT A'. Implementation starts after this commit is pushed.**

## 1. Goal

An experiment that is off by default. For each completed Ugneta lesson attempt on Roblox, the
server records Jev's coaching-focus choice beside the focus the **existing
shared Ugneta rule** gives for the same attempt. It has zero effect on what the player sees or on game
state. It is an experiment, not an activation.

## 2. Architecture A' (binding)

```
client  LektionController, after UgnetaController.efterForsok (unchanged)
   │  flag active → JevSkugga:FireServer({ ovningId, forsokNr, nu, fore })  (fire-and-forget)
   ▼
server  JevShadow
   1. strict validation (§4)  — failure → invalid_input, no request
   2. hard gate (§5)          — failure → hard_gate, no request
   3. comparator = HorseCore/Ugneta.observationer(ovningId, nu, fore)   (existing rule)
   4. task.spawn: RequestAsync → TypeSafe systemone (timeout, no retry)
   5. ring buffer: sanitized sample (§7)
```

- The client sends only the **attempt evidence that `Ugneta.observationer`
  already takes as input**, i.e. the output of `Lektion.avslutaForsok`:
  `ovningId`, `forsokNr`, `nu`, `fore`. It **never sends Ugneta's choice**.
- The server recomputes the comparator itself.
- All client evidence is **untrusted shadow input**. It never reaches gameplay,
  visible coaching, score, physics, progression, persistence or competition.
- **The client-derived evidence is an explicit A' amendment** to the
  "server-derived only" line in #270. It holds only for this PoC.

### 2.1 Server-side reuse of Ugneta — semantic check (PASS, verified at 3407f96)

| Question | Answer |
|---|---|
| Is the rule pure? | Yes. `Ugneta.observationer` (`shared/HorseCore/Ugneta.luau:40`) reads only its arguments and `RidKanon.UGNETA`. It has no services, `RunService`, clock, randomness or state. |
| Are its dependencies reachable on the server? | Yes. `RidKanon.luau` has no `require` and is a pure table. Both are in `ReplicatedStorage.HorseCore`, which the server already requires (`HorseService`, etc.). |
| Is it the same input as on the client? | Yes. On the client, `efterForsok(h.ovningId, h.nu, h.fore, …)` → `Ugneta.observationer(ovningId, nu, fore)` (`UgnetaController.luau:909`). The mirror carries exactly `h.ovningId, h.nu, h.fore` (plus `forsokNr` for the sample label). |
| Does anything change in Ugneta? | No. It is called as-is, and no line in `Ugneta.luau`, `UgnetaTema.luau` or `Lektion.luau` changes. |

**Conclusion: no semantic drift, so the stop condition in A' is not triggered.**

Limitation (stated, not hidden): the comparator is the **after-attempt card**
(`observationer`), which is the only Ugneta decision computed from a closed
attempt. The **live cues** (`UgnetaTema.steg`, per frame, stateful across the
pass) are **not** compared. Reproducing them would mean mirroring frame-level
telemetry, which is outside A's "minimum lesson-attempt evidence".

### 2.2 The compared quantity: "focus"

`observationer` returns at most 2 items `{dim, sort}`. Ugneta's **focus** is
the dimension she tells the rider to work on:

- `dim` of the item with `sort ∈ {forbattra, kvar}`, or
- `ingen` if there is no such item (she only praises, or has nothing to say).

This is a projection of her output, not a new rule. Jev gets the same
question, and its allowed answers are `RidKanon.UGNETA.OVNING[ovningId]` ∪ `{ingen}`.
The allowed answers are built per sample. The full list (`dim`, `sort` × 2) is also stored in the sample, so a
disagreement can be read against what she actually said.

## 3. Source of truth

- TypeSafe (verified in SDK `@typesafe-ai/sdk@0.6.0` `dist/index.mjs`):
  - `POST https://api.typesafe.ai/v1/systemone`
  - Headers: `Authorization: Bearer <key>`, `Content-Type: application/json`, `Accept: application/json`
  - Body: `{ state, questions: { focus: { type: "choice", instructions, criteria: {label: description} } }, model: "jev-latest" }`
  - Response: `{ model, answers: { focus: { type: "choice", choice, confidence, probabilities } }, usage }`
  - Errors: 400/401/403/404/422/429/5xx. **This adapter does not retry.**
- Roblox Creator docs (read 2026-09-30):
  - `HttpService:GetSecret(k)` → `Secret:AddPrefix("Bearer ")` in the `Headers` of `RequestAsync`
  - `RequestAsync` takes a `Timeout` in seconds
  - The limit is 500 req/min
  - Secrets are server-only; in Studio they are local secrets
  - HTTP must be enabled

## 4. Validation (server, before anything else)

The payload is rejected with `invalid_input` and **no request** if any of these
is true:

- It isn't a table, or it has any key outside `{ovningId, forsokNr, nu, fore}`.
- `ovningId` isn't a string in `RidKanon.UGNETA.ORDNING` (6 exercises, exact case).
- `forsokNr` isn't the integer 1 or 2.
- `nu` isn't a non-empty table.
- Any key in `nu` isn't in `UGNETA.DIMENSIONER` minus `Lektion.SAKNAS`. `rytm` is never measured on Roblox, so a `rytm` key is invalid.
- Any value in `nu` isn't a number, or is NaN or ±inf, or is outside [0, 1]. Every dimension is `klamp`-ed in `Lektion.kvalitet`, so a mean is always in [0, 1].
- `nu` has more than 6 keys.
- `fore` is present and not `nil`, and fails the same rules as `nu`.
- Any key isn't a string, or any value is a nested table (except `nu`/`fore` at top level), a string, a boolean or an Instance.

`fore` is optional for either `forsokNr`, because a first attempt without data
gives a second attempt with `fore = nil` (`Lektion.avslutaForsok`). The X09 pattern
from POC-1 is rejected three times over: an unknown key (`line_error`,
`rein_pressure`), a string value (`"???"`) and 42 > 1.

## 5. Hard gate (after validation, before the network)

The sample is recorded as `hard_gate` with **no request** if any of these holds:

- The player isn't mounted according to the server: `HorseService.horseOf(player) == nil` (`HorseService.luau:1827`).
- The same player sent a sample less than 10 s ago (per-player cooldown). An attempt is 22 s, so 10 s never blocks a real attempt.
- A request is already in flight for the player.
- The global cap of 20 requests in the last 60 s is reached.
- The secret can't be read (not configured) — `hard_gate`/`reason=no_secret`.

## 6. The request to Jev

- `state` contains exactly:
  - `ovning`, `forsok`, `nu`, `fore`: the validated copy, with keys re-sorted
  - `dimensioner`: the exercise's dimensions
  - `saknas`: an explicit list of absent fields: `rytm`, `rein_pressure`, `rider_body`, `free_text`
- There is no `userId`, name, `DisplayName`, `hastId`, text or GUID. Keys are allow-listed, and the body is built only from the validated copy.
- `questions.focus.criteria`: one entry per dimension of the exercise, plus `ingen`. Descriptions are fixed Swedish constants in the code.
- `task.spawn` + `pcall(RequestAsync)`, `Timeout = 4` s, **0 retries**.
- Answer: `choice` must be on the per-sample allow-list, and `confidence` must be a finite number in [0, 1]. Anything else gives `api_error` / `reason=bad_answer`.

## 7. Sample (sanitized evidence)

`{ id, t, ovningId, forsokNr, nu, fore, ugneta = {fokus, obs}, jev = {fokus, confidence, model}?, agree?, latensMs?, kalla, reason? }`

- `id`: a per-server counter (`s1`, `s2`, …), not linked to the player.
- `t`: seconds since the server started (`os.clock`), not wall-clock time.
- `kalla ∈ jev | timeout | api_error | invalid_input | hard_gate`.
  - `timeout`: `RequestAsync` threw with a timeout message, or took ≥ the timeout.
  - `api_error`: a non-2xx response, a decode error, or a bad answer. Only the HTTP status code is kept.
- The buffer is in-memory, with at most 200 entries (FIFO).
  - `JevShadow.prov()` returns a copy.
  - `JevShadow.sammanfattning()` returns count, agreement, the source distribution and latency p50/p95/max.
  - It can be read via MCP/the server console. There is no DataStore and no auto-print.
- Logging: one line per sample at most, with `kalla` and the status code. **Never the secret, headers, body or raw response.**

## 8. Flag and remote

- **Flag:** the `ServerStorage` attribute `JevShadowEnabled == true`. Anything else means off. It is read once at `JevShadow.start()`.
  - Off: no listener, no `GetSecret`, no HTTP call, no attribute.
- **Remote:** `JevSkugga` (RemoteEvent) is registered in `Networking.DEFINITIONS`. The integrity gate (`Integritet.luau`) fails on unknown remotes, so it has to be registered.
  - It is **always** present but inert.
  - Only when the flag is on does the server set `JevSkugga:SetAttribute("Aktiv", true)` and connect its listener.
- **Client:** one hook right after the existing `UgnetaController.efterForsok(...)` in `LektionController`.
  - It fires only if the remote has `Aktiv == true`.
  - `pcall`, no wait, no return value.
  - It sends a new table with the four fields; nothing else is touched.

## 9. Files

- New: `shared/HorseCore/JevShadowPolicy.luau`. It is pure: validation, focus projection, allowed labels, answer interpretation and body construction.
- New: `server/JevShadow.luau`. It holds the flag, remote listener, gate, HTTP, ring buffer and summary. HTTP and the clock are injectable for tests.
- Changed:
  - `shared/HorseCore/Networking.luau`: +1 definition
  - `server/init.server.luau`: `JevShadow.start()`
  - `client/LektionController.luau`: the hook, about 5 lines
- New specs: `jevskugga-policy.spec.luau` and `jevskugga-server.spec.luau`, registered in `kor.sh`.
  - The names avoid `ugneta`, which routes to PARITET.
  - Each spec ends with `alla gröna`.
- Unchanged: `Ugneta.luau`, `UgnetaTema.luau`, `Lektion.luau`, `UgnetaController.luau`, and everything on the web side.

## 10. Out of scope

- Any player-visible Jev output (text, UI, sound).
- Writes to physics, horse, lesson, score, progression, competition or persistence.
- A proxy/backend, DataStore logging, or production enablement.
- Comparing the live cues (`UgnetaTema`), see §2.1.
- **Web implementation.** TOBIAS_DECISION: parity is not required for this off-by-default, player-invisible experiment.
- Porting POC-1 files, the P3 branch, or merging.

## 11. Acceptance tests

Automated, in `kor.sh`/CI:

1. Validator: every real `avslutaForsok` output from the canon's 6 exercises is accepted, both with and without `fore`.
2. Validator: each rule in §4 has its own red case, plus X09. Each gives `invalid_input` and **0 HTTP calls** (counting stub).
3. Allow-list: an unknown label, the wrong case, a dimension from another exercise, and confidence that is NaN, missing, negative, > 1 or a string are all rejected.
4. The comparator equals `Ugneta.observationer` on the same input, as a golden table across all 6 exercises × first/second attempt. The policy may not have its own ranking; this is checked by comparing against a direct call.
5. `RequestAsync` that throws, a timeout, 4xx/5xx, and an undecodable body each give `timeout`/`api_error` only, and **no error propagates** to the caller.
6. Isolation:
   - With the flag on vs. off, `UgnetaController.efterForsok`'s return value and the lesson pass (`pass` deep copy) are identical, including when the stub throws.
   - The server handler writes no attribute on the player or horse.
7. The body's key set equals the allow-list exactly. No `userId`/`Name`/`DisplayName`/GUID appears in the JSON, even if they are sent in the payload.
8. A sentinel secret never appears in captured `print`/`warn` output, in the buffer, or in the summary.
9. Rate: 5 triggers within 10 s give 1 request. 25 players in 60 s give ≤ 20 requests, and the rest are `hard_gate`.
10. Flag off: no listener, `Aktiv ~= true`, 0 `GetSecret`, 0 HTTP, and the client hook does not fire.
11. **Falsification:** one deliberate break each in the validator, the allow-list and the isolation turns a test red. Each break is committed first, and restored from a copy, not with `git checkout`.

Runtime (Studio, needs §12):

12. Real samples from real riding. Report the count, agreement, a disagreement table against the attempt evidence, latency p50/p95/max, and error rates as measured. There is no claim that the sample size is sufficient.
13. Stability with the shadow on vs. off: FPS via RenderStepped, measured in the same session.

## 12. Human gate

- **Tobias:**
  - Add the TypeSafe key as a Studio local secret named `typesafe` (Game Settings → Security → Secrets).
  - Enable HTTP requests.
  - Set `ServerStorage` attribute `JevShadowEnabled = true` in the test place only.
  - Claude never sees or handles the key.
- Any player-visible Jev requires a later Tobias decision, including parity.
- No merge and no production enablement.

## 13. Known uncertainty

- `VERIFIED`: §2.1, §3 (SDK source + Creator docs), §4 ranges (`klamp` in `Lektion.kvalitet`).
- `ASSUMPTION`: a Studio local secret works with `AddPrefix` in `RequestAsync` the same way a published secret does. This is verified at runtime; otherwise it is marked NOT_TESTED.
- `ASSUMPTION`: `jev-latest` is stable during the measurement. `model` is logged per sample.
- **Limitation:** the evidence is client-derived and not tamper-proof. Spoofing can only affect a shadow sample.
- **Limitation:** Jev gets the same numbers as the rule. The PoC measures whether Jev reproduces or improves on a threshold rule given **current** telemetry. It does not measure richer signals.
