# AI collaboration

Read [WORKING-AGREEMENT](WORKING-AGREEMENT.md) for current roles and permissions.
[DELIVERY-PROTOCOL](DELIVERY-PROTOCOL.md) owns the evidence/acceptance contract.
This file describes coordination, not a second set of role assignments.

## One writer, independent review

The implementer reads the actual branch and relevant sources, defines the
contract, implements and falsifies it, and supplies the exact local SHA.
The reviewer reads the actual diff and tests, challenges the design and tries
independent counterexamples. In particular, review consumer interpretation,
state ownership and data crossing start/end/session/rider boundaries.
Reviewer tests run in an isolated copy. No competing production edits.

A summary is a handoff, not evidence. Inspect source fidelity, duplicate truths,
false precision, runtime wiring, regression surface and tests that only repeat
their implementation. Keep technical review separate from human acceptance.

## Review request and result

One scoped request includes exact base/head, goal, observed problem, sources,
invariants, positive and negative cases, production paths, test evidence,
falsification, gaps and STOP conditions. Do not ask a reviewer to implement.

The reviewer returns exact reviewed SHA, consolidated reproducible findings
with severity, tests, evidence limits and remaining risk, then stops.
CODE_REVIEW_PASS does not authorize publication or product acceptance.
A changed candidate needs review of the new diff and relevant regression.

## Delivery and acknowledgement

Use one scoped GitHub comment for a needed handoff and the configured one-shot
relay once with a unique message ID. Public comments contain repository SHAs,
relative paths and relevant results, not private machine paths or inventories.
A transport result is not an ACK. An ACK is not completed work. A busy/open
process is not evidence of reading or implementation.

When ACK is missing, inspect delivery and recipient evidence before at most
one bounded reminder. Never blindly retry an uncertain send or start a new,
resumed or forked implementation session. No old supervisor loops.
A completed review/status-only message does not need an idle reminder loop.

## Jev / TypeSafe

Jev följer den bindande policyn i `docs/JEV-USAGE-POLICY.md`. Kortversion:

- deterministisk kod äger regler, säkerhet, poäng, progression, fysik, persistence och tävlingsresultat;
- Jev används bara för ett begränsat val mellan säkra alternativ som är kontextberoende eller tvetydigt;
- input valideras deterministiskt före nätverksanrop, och runtime har alltid deterministisk fallback;
- secrets hålls server-/tool-side; spelardata och fri spelartext skickas inte utan uttryckligt beslut;
- ny användning går offline PoC, shadow, eventuell pilot, player-visible, aldrig direkt till spelaren;
- player-visible Jev kräver Tobias uttryckliga beslut och Roblox/webb-paritet; shadow får vara plattformsspecifik bara när den är avstängd som standard, osynlig för spelaren och uttryckligen godkänd.

Varje icke-trivialt jobb gör ett explicit `JEV_DECISION: <klassificering> — <kort motivering>` och upprepar det i handoff. Det är inte tillstånd att aktivera Jev.

## Additional agents

No extra agents or costs are automatically authorized. If separately authorized,
use them only for a narrow question, never a second lead implementer.
Before an extra task/branch/PR, inspect open issues/PRs and existing work for
overlapping files, cause and claims. Reuse an existing assignment when it
covers the same work; do not duplicate it. Do not wait on optional QA to
replace the required independent reviewer. Escalate a stale/conflicting
assignment without deleting, closing or cancelling someone else's work
without authorization.

## Fidelity and riding

Raw images, video and plans are specification. Separate structural evidence
from room function, proportions from measured dimensions, and technical
visibility from human visual acceptance. Preserve accepted geometry.

For riding, verify the relevant input -> intent -> motion -> observation ->
feedback path, including analog values on touch. Report missing engine,
game-feel and physical-device evidence honestly, under the working agreement's
staged test policy. Shared web/Roblox sources and existing regressions remain
protected; new web features are paused.
