# First Playable — Studio-place, pinnad till `46231de`

**Det här är builden för den fysiska genomgången.** Öppna filen i Roblox
Studio och tryck **Play**. Ingen terminal, ingen Rojo, ingen inklistring av
moduler.

| | |
|---|---|
| Filen | `UBRFFirstPlayable.rbxlx` |
| Källkommit | `46231dee2957de9075ae596e3eba5c747b9a4162` |
| Release-SHA (committen som innehåller filen) | `c08bbcf608b7075ec5754d37af5d8ce99484efa4` |
| Genereringskommando | `python3 tools/bygg-place.py` |
| SHA256 | `aad3847880cf434a8cdf1f9d53d831e13fd22963bfb223d70c5cb84db0ff6bd7` |
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

<https://github.com/Carneteg/UBRF/raw/c08bbcf608b7075ec5754d37af5d8ce99484efa4/roblox/releases/first-playable-place-46231de/UBRFFirstPlayable.rbxlx>

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
FIRST_PLAYABLE_SHA=46231dee2957de9075ae596e3eba5c747b9a4162
FIRST_PLAYABLE_MILJO_SHA=46231dee2957de9075ae596e3eba5c747b9a4162
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

## END_TO_END_PLAYABILITY_GATE: PASS

Den här är den första filen där en maskin har mätt att kedjan är **gångbar**
och inte bara att delarna ligger rätt:

```
spawncellen har golv                          golv 0.14 m
fallet från spawn till golv är ofarligt       0.10 m
det går att gå från spawn fram till dörren    3 celler (0.8 m)
prompten går att nå från gångytan utanför     2.6 studs mot räckvidd 8
avataren kommer IGENOM öppningen              7 celler
hela kedjan spawn → in i stallet              10 celler (2.5 m)
det finns NÅDD gångyta vid Jacks box          närmast 2.30 m från boxens mitt
boxens prompt går att nå från gångytan        2.30 m mot räckvidd 2.67 m
HELA KEDJAN spawn → dörr → gången vid boxen   230 celler (57.5 m)
```

Mätt collision-aware över den faktiskt byggda geometrin med avatarens mått
(0,70 m bred, 1,75 m hög, 0,55 m steghöjd), i konfigurationsrymd — inte som
koordinatavstånd.

**Marginalen vid boxen är tunn: 2,30 m mot 2,67 m räckvidd, alltså 0,37 m.**
Ändras boxfronten eller gången blir prompten onåbar. Grinden mäter det nu,
men det är värt att veta.

## Fortfarande oprovat av en människa

Grinden säger att kedjan är gångbar. Den säger ingenting om hur det KÄNNS,
om kameran, om prompten syns där man tittar, eller om first-day-flödet
hänger ihop upplevelsemässigt. Orderns punkt 5 (hela first-day path smoke)
och punkt 6 (negativa gameplaytester i integrationsläge) är **inte** med i
grinden — de finns delvis i `skotselpass.spec` och `forberedelse.spec`, men
inte i samma integrationskörning.

## Vad som skiljer den här från
 `first-playable-place-b1e2a83`

Den förra filen öppnade, men gav en **frusen himmel utan avatar**. Output:

```
OK UBRF byggd: 8 byggnader, ... 3314 objekt   - Server - Anlaggningen:2386
Module code did not return exactly one value  - Server - Horse:80
```

Världen byggdes **färdigt** — sedan kastade `require()`, eftersom
världsbyggaren är ett skript som körs för sin verkan och inte returnerade
något. En ModuleScript måste returnera exakt ett värde. Serverskriptet dog
på nästa rad, så ingen tjänst startade, ingen dörr fick interaktion, och
`CharacterAutoLoads` stod kvar på `false`.

| Rättat | Hur |
|---|---|
| `require()` kastade efter bygget | världsbyggaren avslutas med `return true`; paketet lindar in filen i en funktion så raden är laglig i båda vägarna |
| en krasch lämnade spelaren utan kropp | `init.server` kör varje fas i egen `pcall` och **släpper alltid in spelaren**, även om något föll. Att stoppa hör till preflighten, som skriver `FAIL` — inte till en frusen skärm |
| ingen grind fångade det | `tools/kolla-place.py` kräver nu att världsmodulen slutar med `return`. Tas raden bort: `FIRST_PLAYABLE_PREFLIGHT: FAIL`, exit 1 |

**Om du får en frusen himmel igen:** titta i Output efter rader som börjar
med `[Horse] … föll:`. De säger nu vilken fas som gick sönder i stället för
att tiga.
