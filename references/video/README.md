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

## Så plockas bildrutorna ut

Första omgången tog sex bildrutor per film, en var 1,6:e sekund, och missade
därmed det mesta — bland annat den enda vinkel som visar ridhusets nock och båda
takfallen. Ta rikligt och gallra i efterhand i stället:

```bash
ffmpeg -i references/video/IMG_0246.mov -vf "fps=3,scale=1400:-2" -q:v 3 ut/%03d.jpg
```

Vid tre bilder i sekunden ger de fem filmerna 83 bildrutor. Gallra dem sedan på
likhet — en medelvärdeshash per bild, och behåll bara de som skiljer sig mer än
åtta bitar från alla tidigare behållna **inom samma film**. Det ger 66 distinkta
vinklar. Jämför aldrig över filmerna: två filmer av samma vägg är två tillfällen,
och panoreringen i en film ändrar sig gradvis så tröskeln måste vara låg.

Filmerna väger 50 MB tillsammans. Växer samlingen bör de flyttas till Git LFS.
