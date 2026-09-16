# First Playable — bevarad evidensartefakt

Det här är **historisk evidens**, inte en aktuell release. Den ligger här för
att den `PRODUCT_ACCEPTED`-kandidat som First Playable-acceptansen vilar på
ska gå att återfinna och verifiera efter att PR #162 stängts som obsolet.

| | |
|---|---|
| källans head | `91914a73f4257d7a90f925347a473e98fbc9e04f` |
| fil | `UBRFFirstPlayable.rbxlx` |
| storlek | 1 183 445 byte |
| SHA256 | `4771a340b69a3a986bf56c84ecdcd3edbf208be8add73d8742c2d59195cc115c` |
| bevarad från | PR #162, gren `claude/first-playable-20260910` |
| bevarad i | #218, ovanpå `main` `d9a1774a5126286c3d34a6c83a5ebc2ab78d5c55` |

Det mänskliga QA-protokollet för just den här kandidaten ligger i
[`docs/HUMAN-QA-FIRST-PLAYABLE.md`](../../../docs/HUMAN-QA-FIRST-PLAYABLE.md).

## Vad som INTE följde med

Bara de två evidensfilerna är kopierade. Ingen kod, inga prov, inga manifest,
inga konfigurationer och ingen grenhistorik från #162 — den grenens
gameplay-delta är superseded av #200, #202, #203/#205, #206/#208, #210 och
#212/#213, och dess utrustningskatalog motsäger de besluten. Underlaget för
den bedömningen ligger i reconciliation-rapporten på PR #162.

## Verifiera hashen

```
git show HEAD:roblox/releases/first-playable-place-91914a7/UBRFFirstPlayable.rbxlx \
  | sha256sum
```

Filen kopierades **som git-objekt** (`update-index --cacheinfo`), inte genom
arbetsträdet, så inga radslutsfilter har kunnat röra den. Byt aldrig ut den på
plats: en ny kandidat hör hemma i en ny mapp med ny hash.

Tills `*.rbxlx binary` finns i `.gitattributes` (#219) kan en Windows-checkout
skriva om radsluten i arbetsträdet. Det påverkar inte objektet i git, men
hasha alltid via `git show`, inte via filen på disk.
