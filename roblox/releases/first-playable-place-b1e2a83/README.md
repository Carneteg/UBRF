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

# First Playable — Studio-place, pinnad till `b1e2a83`

**Det här är builden för den fysiska genomgången.** Öppna filen i Roblox
Studio och tryck **Play**. Ingen terminal, ingen Rojo, ingen inklistring av
moduler.

| | |
|---|---|
| Filen | `UBRFFirstPlayable.rbxlx` |
| Källkommit | `b1e2a836deb4c6c298b2ee4f26254a0d7018e00d` |
| Release-SHA (committen som innehåller filen) | `897b082d3cbabd19378c587011539088f319e5d6` |
| Genereringskommando | `python3 tools/bygg-place.py` |
| SHA256 | `d1ec6af69c65371597e1594d6d5dd8686f5315e3caad94c4a63fddefbe47386e` |
| Storlek | 58 instanser, 728 KB |

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

<https://github.com/Carneteg/UBRF/raw/897b082d3cbabd19378c587011539088f319e5d6/roblox/releases/first-playable-place-b1e2a83/UBRFFirstPlayable.rbxlx>

**404 betyder nästan alltid `main`.** Filen ligger bara på branchen
`claude/first-playable-20260910` tills PR #162 är mergad; länken ovan pekar
på en commit och inte på en gren.

1. **Ladda ner** `UBRFFirstPlayable.rbxlx` (länken ovan, eller GitHub →
   **Download raw file**).
2. **Öppna den i Roblox Studio** — File → Open from File, eller dubbelklick.
3. **Tryck Play.** Servern bygger anläggningen vid start.

### Kontrollera att du kör rätt build

Det första som skrivs i **Output** är:

```
FIRST_PLAYABLE_SHA=b1e2a836deb4c6c298b2ee4f26254a0d7018e00d
FIRST_PLAYABLE_MILJO_SHA=b1e2a836deb4c6c298b2ee4f26254a0d7018e00d
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

## Vad som skiljer den här från `first-playable-place-2af5de2`

Den förra place-filen **öppnade och gick att spela** — men spelaren
spawnade i luften, föll och dog.

Orsaken var spawnens läge. Den låg på `STALL-ANKOMST`:s **kameraläge**,
6,0 m norr om stallets nordfasad. Mätt i bänken når den nordligaste byggda
ytan vid dörrens x bara 2,80 m ut (förstukvistens golv) — spawnen låg
3,2 m ut över tomrummet, och plattan kolliderade inte heller. Att en
*kamera* står 6 m ut är riktigt; en kamera behöver ingen mark.

| Rättat | Hur |
|---|---|
| spawnen stod över tomrummet | härleds nu ur verandan (`forstukvist`): mitt på golvet, i räckets öppning mitt för dörren — 0,00 m i sidled från entrén, 1,40 m från den, 0,10 m ner till betongen |
| karaktären kunde laddas före världen | `CharacterAutoLoads = false` tills anläggningen står; i Play-läge hinner Studio annars ladda före ett bygge på 3300 delar |

Mätningen som saknades finns nu i `forstaplayable.spec`: **kolliderande
mark rakt under spawnen**, och högst 0,5 m fall dit. Läggs spawnen tillbaka
på 6,0 m blir fyra mätningar röda.
