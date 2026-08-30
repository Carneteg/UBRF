# Gate F01 — Roblox Studio acceptance

Date: **2026-08-30**  
Gate: **F01 — UBRF Fidelity**  
Human result: **ACCEPTED**

## Acceptance result

The Product Owner completed the canonical Roblox Studio QA flow from
`roblox/docs/STUDIO-QA.md` using the corrected Studio package from PR #26.

- **11 / 11 canonical views: PASS**
- **walk path: PASS**
  - `ankomsten → stallet → hästgången → ridhuset → banan`
- **blocking visual/navigation defects: 0 reported**

## Observation

> Lite mörkt i stallet.

Classification: **non-blocking lighting/polish observation**.

The QA contract explicitly does not treat advanced lighting or cosmetic polish
as a fidelity-gate blocker. This observation may be addressed later as a small,
contained lighting/game-feel pass. It must not reopen broad environment
reconstruction while Gate G01 is active.

## Studio runtime defect encountered and resolved during acceptance

The first Studio run exposed an invalid Roblox material enum in the generated
package. `Enum.Material.CorrugatedMetal` was not valid and aborted the build.
PR #26 corrected the two source occurrences to `Enum.Material.Metal`, regenerated
the package, and added a strict material allowlist + scanner so unsupported
materials fail before a future package reaches Studio.

After that correction the QA package ran and the human review above was
completed.

## Remaining reference gaps

Acceptance does not convert unresolved real-world details into facts. These
remain explicitly open:

- hall orientation
- exact size of the gable offset
- documented contradiction between arena board and spectator-front references

Do not invent them. F01 acceptance means the current environment is an accepted
baseline for gameplay development, not a claim of literal 100% proven identity
for every unresolved detail.
