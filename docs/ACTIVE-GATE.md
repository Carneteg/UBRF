# Active Gate

Current gate: **Gate 01 — Riding Feel**

Canonical implementation brief:

- `docs/GATE-01-RIDING-FEEL.md`
- `docs/GATE-01-PLATFORM-ADDENDUM.md` — overrides any older wording that made Gate 01 web-only.

## Claude

Before making gameplay/movement/camera/input changes, read:

1. `CLAUDE.md`
2. `docs/PRODUCT-CANON.md`
3. `docs/ASSET-SOURCE-OF-TRUTH.md`
4. `docs/AI-COLLABORATION.md`
5. `docs/GATE-01-RIDING-FEEL.md`
6. `docs/GATE-01-PLATFORM-ADDENDUM.md`

Do not expand scope beyond Gate 01 while it is active unless Tobias explicitly requests it.

**Platform rule for this gate:** Roblox is the primary gameplay implementation and subjective playtest. HTML/web is also a real playable distribution and must retain the equivalent core riding behavior. Do not treat Roblox as a later port and do not let web become a non-playable demo.

After implementation, create:

`audits/GATE-01-RIDING-FEEL-RESULT.md`

It must include separate Roblox Studio evidence, HTML/browser evidence, a parity table, tested commit SHAs and intentional platform differences. Then hand the result to ChatGPT for review. Claude does not mark the gate closed.

## ChatGPT

Review the implementation as Senior Game Developer / Game Systems Architect. Verify the actual diff and audit evidence, with priority on player feel, frame independence, input parity, platform parity, scope and UBRF product canon. Do not approve a change merely because it compiles or a checklist is filled in.

## Tobias

Product Owner. Final decision on whether the gate is accepted or sent back for another iteration.
