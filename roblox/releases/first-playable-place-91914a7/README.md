# First Playable — bevarad evidensartefakt (#218)

Den här mappen bevarar den kandidat som Tobias satte `PRODUCT_ACCEPTED` på
2026-09-14 03:38 i PR #162. Filen är kopierad byte för byte från #162:s
head; den är **inte** ombyggd, och källträdet `91914a7` finns inte på `main`
(#162 stängs som obsolet efter legacy-reconciliationen 2026-09-16).

| | |
|---|---|
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `4771a340b69a3a986bf56c84ecdcd3edbf208be8add73d8742c2d59195cc115c` |
| storlek | 1 183 445 byte |
| källhead (bakad `ReplicatedStorage/UBRFBuild.sha`) | `91914a73f4257d7a90f925347a473e98fbc9e04f` |
| produktstatus | `PRODUCT_ACCEPTED` av Tobias 2026-09-14 03:38 (PR #162) |
| kvarvarande mänsklig QA | `docs/HUMAN-QA-FIRST-PLAYABLE.md` (bevarad i samma PR) |

Historik, grindrapport och kommentarer ligger kvar på PR #162. Mappen är
evidens, inte en byggbar release: ingen pekare i `LATEST-FIRST-PLAYABLE.md`
ändras, och inget verktyg på `main` läser den.
