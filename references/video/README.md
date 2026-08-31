# Filmer från anläggningen

Källfilmer från Husbyvägen, som stillbilderna i `references/buildings/` är
utplockade ur. Filmerna ligger kvar som facit — en stillbild kan alltid tas om,
med en annan bildruta eller en annan beskärning.

| Fil | Längd | Visar | Stillbilder |
|---|---|---|---|
| `IMG_0246.mov` | 4,4 s | Ridhusets gavel från parkeringen | `buildings/ridhus/ridhus-gavel-*.jpg` |
| `IMG_0247.mov` | 2,0 s | Verandan, entrédörren, det runda fönstret | `buildings/stall/stall-entre-*.jpg` |
| `IMG_0248.mov` | 2,6 s | **Inne i klubbänden** — vestibulen innanför entrén: raka trappans undersida, dörrparet, branddörren märkt `Stall` | `buildings/stall/stall-entre-07…14.jpg` |
| `IMG_0249.mov` | 13,3 s | Stallgången, norrut | `buildings/stall/stall-gang-*.jpg` |
| `IMG_0250.mov` | 5,2 s | Stallgången, motsatt håll, och **sidoöppningen mot servicedelen** | `buildings/stall/stall-gang-*.jpg` |

## Så plockas bildrutorna ut

Använd `tools/videobevis.py`. Gissa ingen cadence — filmerna är korta nog att
packa upp **helt**, 825 bildrutor vid 30 fps:

```bash
python3 tools/videobevis.py --ut ut/
```

Gallringen är en medelvärdeshash per bild med tröskel 8 inom samma film.
Jämför aldrig över filmerna: två filmer av samma vägg är två tillfällen.

**Hashen ensam räcker inte.** En långsam panorering ändrar bilden gradvis, så
varje bildruta liknar den förra och hela filmen kan kollapsa. Tröskel 8 behöll
**3 av 132** bildrutor ur `IMG_0246.mov`. Skriptet behåller därför en bildruta
också när luckan blivit för lång (`--lucka`, standard 15 bildrutor = 0,5 s),
oavsett hash. Det ger 106 bildrutor totalt, varav **32 enbart tack vare
luckregeln**.

### Rotationen — läs det här innan du sparar en bildruta

`IMG_0248.mov` renderas av ffmpeg **upp och ner**. Åtta bildrutor sparades en
gång i det läget som `stall-entre-07…14.jpg`, och en läsbar dörrskylt blev
därmed oläslig i dokumentationen. Kontrollera alltid orienteringen
mot något som har en självklar upp-och-ner — golv, tak, en text — innan en
bildruta läggs i `references/buildings/`. Se `docs/F02-BEVISINDEX.md`.

Filmerna väger 50 MB tillsammans. Växer samlingen bör de flyttas till Git LFS.
sha256 för varje film står i `references/CHECKSUMS.sha256`.
