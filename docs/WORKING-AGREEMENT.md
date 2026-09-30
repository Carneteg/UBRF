# Current working agreement

Current authority: Tobias' decisions and confirmed handover on 2026-09-26.
This is the single operational source for roles, permissions and test policy.
Product requirements remain in [PRODUCT-CANON](PRODUCT-CANON.md); evidence
rules remain in [DELIVERY-PROTOCOL](DELIVERY-PROTOCOL.md).
New explicit Tobias decisions take precedence and must be recorded here.

## Latest product priority

Tobias approved acting on the project assessment at 18:01 UTC on 2026-09-26,
including the next end-to-end circle lesson. Existing infrastructure is frozen
before this playable slice; no new INFRA package or rule-profile foundation.
Use VOLT1/FORSOK1: Ugneta requests a circle, the player rides it, receives
positive useful feedback and a visible outcome. Codex defines the bounded
contract before code. No new reward/persistence promises bypass D4-RATT.

Small playable deliveries, reduced acknowledgement ritual and bounded engine
checks replace more foundational work as the immediate next priority.

**Tobias 2026-09-30 (P3):** continue P3 from `36d832e` with Claude as writer;
the pre-existing `src/lektioner/` work is reviewed against Roblox before use;
Q4 is reproduced before any fix; push only a coherent, tested P3 delivery; no
production promotion without Tobias' approval; `src/varld3d.js` is not edited
in P3. **P3 § 11.1 APPROVED:** the web's clear round offers «Egna kläder»
only (the web avatar has no competition-clothing assets) — a declared
platform difference; the rest of the clear-round flow follows Roblox.
§ 11.2 (web aid input wording) and § 11.3 (where the group ladder is offered)
remain open; the P3 defaults apply until decided.
Recurring player sessions, a machine-readable coordination channel and an
HRAG deadline/alternative need concrete proposals; they are not permission
for costs, replacement assets, publication or unscheduled data-bearing tests.
The full catalogue remains; this is a priority amendment, not abandonment.

## Roles

**CODEX BUILDS -> CLAUDE REVIEWS -> TOBIAS ACCEPTS**

- Codex is the sole production implementer, including coordination, contracts,
  integration, tests and corrections.
- Claude is the independent design/code reviewer. Production writing remains
  stopped. Reviewer counterexamples belong in an isolated copy, not the
  candidate or shared repository.
- Tobias owns scope, costs, permissions and human/product acceptance.
- **Package exception, 2026-09-27 07:40 UTC**
  ([order](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5853887111)):
  Tobias asked that the next build step go to Claude. For the bounded
  circle-lesson finish package on codex/circle-lesson-20260926 only, Claude
  (3695fbae) is the sole writer and Codex has production STOP and reviews
  independently. The roles above apply again after that package's review.
- No parallel writer, new/resumed/forked implementer, extra agent or model cost
  is authorized by the handover. Preserve other writers' existing work.
  Historical Replit assignments do not authorize overwriting its files.

## Delivery

Define the contract before code: invariant, positive case, boundary failures,
ownership and start/end/session scope. Test real production paths; perform
falsification only in isolated copies with exact mutation anchors.
Use focused checks while working, the full relevant chain before delivery,
then independent review of the exact candidate. Consolidate confirmed fixes.
Report severity, reopened findings, correction rounds and actual elapsed time.

Builder status ends at READY_FOR_REVIEW. Reviewer results are
CODE_REVIEW_PASS or CHANGES_REQUIRED. Historical READY_FOR_CHATGPT_REVIEW and
CHATGPT_VISUAL_PASS are legacy markers, not permission for Codex to approve
its own implementation. Any required visual review must remain independent.
Only Tobias grants PRODUCT_ACCEPTED; a technical pass or merge is not acceptance.
See [LOCAL-DELIVERY-CHECKS](LOCAL-DELIVERY-CHECKS.md) for executable checks,
limitations and reproducible environment requirements.

## Permission boundaries

Never commit or print secrets, API keys or `.env` files.

PR #264's push/merge and existing automatic web and Roblox CI-place runs were
explicitly authorized and are complete. That exception is not blanket
permission for future push, PR-triggered publication, merge or CI reruns.
New publication, installations outside approved isolated environments, costs,
data loss, security/gate/permission/variable changes and real datastore
mutations require separate authorization. No force-push or check bypass.

Preserve canonical UBRF-PLAYTEST.rbxlx, original startplace, main/release/backup,
prior work, other writer's src/varld3d.js and .claude settings. No Rojo,
asset upload, branch deletion, stash/reset or automatic cleanup of evidence.
A code/doc cleanup request does not authorize deleting retained artifacts.

## Tests and product gates

**Latest testing policy, 2026-09-27 10:40 UTC**
([decision](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855114357)):
Tobias playtests the whole at the end. Until then build without running tests:
no automated suites, mutations, full chain, engine probes or manual gameplay.
Write regression specs for later; never delete or weaken tests or CI gates.
Deliveries are BUILT_NOT_VERIFIED / TESTS_DEFERRED with a deferred-check list,
never a technical, engine or product PASS. Codex reviews source only. Claude
is the implementation writer for the build-now packages (circle finish,
[Start/Halt](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5855148032)).
The rules below apply when the deferred verification is run.

Small engine checks at risky component boundaries are allowed only with a
written hypothesis, exact candidate, scope and pass/fail criteria before the
run. Use an isolated copy with no real data mutation. Stop if isolation cannot
be demonstrated. This does not authorize publishing, Rojo, asset uploads,
new publishing CI dispatches, costs or changing permissions.

The complete player journey and final gameplay test remain LAST, after all
approved components are integrated/reviewed, on a frozen candidate and with
separate explicit Tobias approval. BANK_ONLY, WINDOWS_LOCAL_ISOLATED,
Linux CI, engine, visual and physical mobile evidence are distinct.
Physical iPad/iPhone remain deferred, not passed.

## Decision evidence

- [Completion-first catalogue](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5843082008).
- [Scoped closeout authorization](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5847449571).
- [Quality workflow decision](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5847556946).
- [Claude handover and production STOP](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5847647796).
- [Confirmed ownership switch](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5847665585).
- [Playable-slice decision](https://github.com/Carneteg/UBRF/pull/264#issuecomment-5848553215),
  corroborated by Tobias' direct session response at 18:01:13 UTC.

Current work is indexed in [ACTIVE-GATE](ACTIVE-GATE.md). Dated snapshots under
history are evidence, never new execution orders. Do not silently reinterpret
old mandatory push, old roles or old immediate gameplay orders as current.
