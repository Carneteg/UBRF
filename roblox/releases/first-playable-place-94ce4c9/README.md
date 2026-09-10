> # ⛔ DO_NOT_TEST / SUPERSEDED
>
> **Testa inte den här filen.** Den är ersatt, och den bevarade kopian finns
> kvar bara som spårbarhet för vad som levererades och vad som gick fel.
>
> Rätt fil pekas ut av **`roblox/releases/LATEST-FIRST-PLAYABLE.md`** — och
> bara när `END_TO_END_PLAYABILITY_GATE` är PASS på den buildens SHA.
>
> Bakgrund: ChatGPT:s processreview 2026-09-10 16:31, efter att Tobias
> manuellt hittat tre grundläggande Studio-fel i buildar som presenterats
> som redo. Ingen fil går ut till fysisk test förrän spelbarheten är mätt
> maskinellt.

# First Playable — Studio-place, pinnad till `94ce4c9`

**Det här är builden för den fysiska genomgången.** Öppna filen i Roblox
Studio och tryck **Play**. Ingen terminal, ingen Rojo, ingen inklistring av
moduler.

| | |
|---|---|
| Filen | `UBRF-FirstPlayable.rbxlx` |
| Källkommit | `94ce4c9dde316a33a87270d9de9ee316768c1e4d` |
| Release-SHA (committen som innehåller filen) | `7587b5f0d1feb172d018905e18f91413deb79e25` |
| Genereringskommando | `python3 tools/bygg-place.py` |
| SHA256 | `f8fbb68a44d2c354655c3378eab77234e0b964570535e202ae1169a42a2771a7` |
| Storlek | 57 instanser, 728 KB |

## Varför den finns

Blockeraren i #162: Tobias testade i Studio, spawnade för långt från starten
och kom inte in genom den vita dörren. Orsaken var att Roblox-sidan hade
**två halvor som aldrig möttes**:

| Väg | Byggde världen? | Innehöll gameplay? |
|---|---|---|
| `UBRF-klistra-in.luau` (miljö-/QA-paketet) | ja | **nej** |
| Rojo-synk på `default.project.json` | **nej** | ja |

Den här placen är den enda vägen där båda finns. Miljö-/QA-paketet under
`roblox/releases/first-playable-506b5a3/` är kvar för den **visuella**
granskningen och ska inte användas för gameplaytest.

## Hämta och kör — tre steg

Direktlänk, pinnad till committen som la in filen (den slutar aldrig
fungera och kan inte peka på en nyare eller äldre version):

<https://github.com/Carneteg/UBRF/raw/7587b5f0d1feb172d018905e18f91413deb79e25/roblox/releases/first-playable-place-94ce4c9/UBRF-FirstPlayable.rbxlx>

**404 betyder nästan alltid `main`.** Filen ligger bara på branchen
`claude/first-playable-20260910` tills PR #162 är mergad; länken ovan pekar
på en commit och inte på en gren.

1. **Ladda ner** `UBRF-FirstPlayable.rbxlx` (länken ovan, eller GitHub →
   **Download raw file**).
2. **Öppna den i Roblox Studio** — File → Open from File, eller dubbelklick.
3. **Tryck Play.** Servern bygger anläggningen vid start.

### Kontrollera att du kör rätt build

Det första som skrivs i **Output** är:

```
FIRST_PLAYABLE_SHA=94ce4c9dde316a33a87270d9de9ee316768c1e4d
FIRST_PLAYABLE_MILJO_SHA=94ce4c9dde316a33a87270d9de9ee316768c1e4d
...
FIRST_PLAYABLE_PREFLIGHT: PASS
```

Står det **`FIRST_PLAYABLE_PREFLIGHT: FAIL`** — **fortsätt inte med
acceptansmatrisen.** Raderna ovanför säger vad som saknas. Rapportera dem i
stället för att kryssa i något. Frånvaro av ett PASS är inte ett PASS.

### För avsnitt B (persistens)

Persistensdelen kräver att Studio får skriva till DataStore:
**Game Settings → Security → Enable Studio Access to API Services**. Utan den
får spelaren en sessionsave, kan spela men sparar inte — det är korrekt
beteende, men det provar inte persistensen. Ser du
`[Spar] Inget datalager tillgängligt` i outputen är åtkomsten av.

## Vad som är provat, och vad som inte är det

**Provat maskinellt** (`bash roblox/tests/kor.sh`, 18/18 gröna, och
`python3 tools/kolla-place.py`):

- fasaden är sluten utom i sina dörrar, mätt som murlängd per sida
- varje genomgående fasadöppning har ett uppmärkt dörrblad; inget fönster har
  blivit en dörr
- exakt en First Playable-spawn, på ankomstpunkten, 6,0 m från dörren
- varje dörrblad får en prompt, slutar kollidera när det öppnas och går
  tillbaka till exakt sitt stängda läge
- placen innehåller server-runtime, client-runtime, den delade koden,
  speldatan och världsbyggaren — och grinden **faller** om någon del saknas

**`Not tested` — ingen agent i sessionen har Studio-åtkomst:**

- att `.rbxlx` faktiskt öppnar i Studio
- att prompten syns för en riktig avatar och att man fysiskt går igenom
  dörröppningen utan att fastna
- spawnriktningen upplevd i förstapersonsvy
- hela first-day-flödet med fysisk input, DataStore, performance och
  spelkänsla

Det är precis det den fysiska genomgången ska mäta. Protokollet är
`docs/ENHETSTEST-FIRST-PLAYABLE.md`. **Tom ruta betyder inte PASS.**

## Om något inte stämmer

Skriv vad du **såg** och **var** — inte gissad orsak. En rad per steg,
`PASS` · `FEL` · `NOT_TESTED`, och gärna med `FIRST_PLAYABLE_SHA` ur Output
så att felet hör till en känd build.
