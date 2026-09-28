# D1: rule profile for clear round (bedömning A: Clear Round, TR III 2025)

Status: BUILT, local tests green, 2026-09-28. Contract written before code (ACK [#5865492233](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865492233)).
Decision: [TOBIAS_DECISION_D1_CLEAR_ROUND_20260928](https://github.com/Carneteg/UBRF/issues/266#issuecomment-5865432545)
("1A"; UBRF's own conditions not stated, so TR only, with gaps marked).
Source: [`references/rules/TR-III-2025-hoppning-A-clear-round.md`](../references/rules/TR-III-2025-hoppning-A-clear-round.md).
Base `855051b`, branch `codex/circle-lesson-20260926`.

## Scope

A pure, versioned rule module that turns **one already decided round outcome** into a clear-round verdict.

**Not included:**
- UI;
- server state;
- a competition day (D2);
- fence detection (B4);
- rosette persistence (D4);
- placings (clear round has none);
- jump-off.

**Where it lives:** `roblox/regler/Klassprofil.luau`, which is **not Rojo-mapped**, together with its spec. The locked playtest candidate's build identity (`kallhash e23198df4614…`, #266 A2) therefore stays valid. D2 moves or maps it when the competition day consumes it.

## Profile `A_CLEAR_ROUND` · `TR III 2025`

**Input:** one round.

| Field | Meaning |
|---|---|
| `forsok` | 1 or 2 |
| `hojdM` | class height in metres, horse |
| `ponny` | boolean |
| `nedslag` | knockdowns, ≥ 0 |
| `olydnader` | disobediences, ≥ 0 |
| `avfallning` | fall or rider fall, boolean |
| `felVag` | uncorrected wrong course, boolean |
| `overMaxtidS` | seconds over maximum time, ≥ 0 |
| `overTillatenTid` | boolean |

**Validity:**
- **Horse:** `hojdM ≤ 0.90`; otherwise the result is `giltig = false`, reason `klass_over_090` (314.1.1).
- **Pony:** `giltig = false`, reason `ponny_klassordning_okand`. This is a `[REFERENCE GAP]`: the pony class order below Lätt D is not in the cited moments.
- **Malformed input:** a missing field, a negative or non-integer count, or a non-finite value gives `giltig = false`, reason `indata`. It never throws.

**Faults (381, basic round):**
- 4 per knockdown;
- first disobedience: 4;
- **second disobedience:** **not fault-free**, fault total `nil` (`[REFERENCE GAP]` on "8 fel"; since clear round is ≤ 0.90, it is never elimination here);
- time: `ceil(overMaxtidS / 4)` faults, as 1 per started 4-second interval.

**Elimination (381, 388.2):** any of
- a third disobedience;
- a fall;
- a wrong course (388.2.2);
- exceeding the allowed time (388.2.6);
- more than 16 obstacle faults (knockdowns and disobediences). With two disobediences the obstacle faults are an
  interval (4·knockdowns + 8 … 12): above 16 at both ends gives elimination, at or below 16 at both ends gives none, and
  the case in between gives `utesluten = nil` (not established; corrected while building, see the report).

**Verdict:**
- `utesluten` is a boolean.
- `felfri` is true only when not eliminated, the fault total is exactly 0, and there are no disobediences.
- `fel` is the fault total, or `nil` when eliminated or when the total is not verified.

**Prize:**
- `rosett = "clear_round"` only when `forsok == 1` and the round is `felfri` (314.1.1).
- Attempt 2 gives **no** rosette. This is a `[REFERENCE GAP]` until UBRF or SvRF says otherwise.

**Restart:**
- `omstartMojlig = true` only when `forsok == 1`, the round is valid, and it is not fault-free, which covers faults **or** elimination (314.1.1).
- `omstartRaknasSomStart = false` (301.3.1.2).

**Output always carries:** `profil = "A_CLEAR_ROUND"`, `regel = "SvRF TR III 2025"` and `moment` (the list of moments used). There are **no placings and no rosette colour**; the clear-round rosette is its own category, separate from placing rosettes (#266 §8).

## Acceptance

`regelprofil.spec`, registered in `kor.sh` with its own minimal bundle, checks manually computed reference cases.

**Fault-free and faults:**
- fault-free attempt 1 gives a rosette;
- the same outcome in attempt 2 gives no rosette;
- one knockdown gives 4 faults, not fault-free, and a restart is possible;
- 2 knockdowns + 1 disobedience give 12;
- 0.1 s over the maximum time gives 1, 4.0 s gives 1, and 4.1 s gives 2.

**Elimination:**
- one disobedience gives 4; two give not fault-free with `fel = nil`; three give elimination;
- a fall, a wrong course and the allowed time exceeded each give elimination, with a restart possible in attempt 1;
- 5 knockdowns (20 > 16) give elimination, and 4 knockdowns (16) do not.

**Validity:**
- 0.90 m is valid and 0.95 m is not;
- a pony gives the reference gap;
- malformed input never throws;
- the output identifies profile, rule and moments.

**Falsification:**
- the knockdown weight;
- the time rounding;
- the > 16 boundary;
- rosette in attempt 2;
- the 0.90 boundary;
- elimination on a fall.

**Plus:** the full local suite, and **the build identity unchanged** (`tools/bygg-identitet.py` gives `e23198df4614…`).

**Not tested:** everything runtime. There is no consumer yet.
