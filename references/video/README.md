# Filmer från anläggningen

Källfilmer från Husbyvägen, som stillbilderna i `references/buildings/` är
utplockade ur. Filmerna ligger kvar som facit — en stillbild kan alltid tas om,
med en annan bildruta eller en annan beskärning.

| Fil | Längd | Visar | Stillbilder |
|---|---|---|---|
| `IMG_0246.mov` | 4,4 s | Ridhusets gavel från parkeringen | `buildings/ridhus/ridhus-gavel-*.jpg` |
| `IMG_0247.mov` | 2,0 s | Verandan, entrédörren, det runda fönstret | `buildings/stall/stall-entre-*.jpg` |
| `IMG_0248.mov` | 2,6 s | Verandan, fortsättning | `buildings/stall/stall-entre-*.jpg` |
| `IMG_0249.mov` | 13,3 s | Stallgången, norrut | `buildings/stall/stall-gang-*.jpg` |
| `IMG_0250.mov` | 5,2 s | Stallgången, motsatt håll | `buildings/stall/stall-gang-*.jpg` |

Plocka ut fler bildrutor så här:

```bash
ffmpeg -i references/video/IMG_0249.mov -vf "fps=1/1.6,scale=1400:-2" \
       references/buildings/stall/stall-gang-%02d.jpg
```

Filmerna väger 50 MB tillsammans. Växer samlingen bör de flyttas till Git LFS.
