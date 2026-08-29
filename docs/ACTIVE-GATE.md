# Active Gate

Current gate: **Gate 01 — Riding Feel**

Canonical implementation brief:

`docs/GATE-01-RIDING-FEEL.md`

## Claude

Before making gameplay/movement/camera/input changes, read:

1. `CLAUDE.md`
2. `docs/PRODUCT-CANON.md`
3. `docs/AI-COLLABORATION.md`
4. `docs/GATE-01-RIDING-FEEL.md`

Do not expand scope beyond Gate 01 while it is active unless Tobias explicitly requests it.

After implementation, create:

`audits/GATE-01-RIDING-FEEL-RESULT.md`

Include the tested commit SHA and all evidence requested by the Gate document, then hand the result to ChatGPT for review. Claude does not mark the gate closed.

## ChatGPT

Review the implementation as Senior Game Developer / Game Systems Architect. Verify the actual diff and audit evidence, with priority on player feel, frame independence, input parity and Roblox portability. Do not approve a change merely because it compiles or the checklist is filled in.

## Tobias

Product Owner. Final decision on whether the gate is accepted or sent back for another iteration.
