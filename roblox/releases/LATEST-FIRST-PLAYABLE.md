# Vilken fil ska testas? — canonical pekare

## ✅ Filen att öppna

```
roblox/releases/first-playable-place-6039d6b/UBRFFirstPlayable.rbxlx
```

<https://github.com/Carneteg/UBRF/raw/13157377e772484325246885197f038d7463d4a8/roblox/releases/first-playable-place-6039d6b/UBRFFirstPlayable.rbxlx>

| Fält | Värde |
|---|---|
| **Källkod (source SHA)** | `6039d6b15db7ef4aa2ca4264c2f24ca707caf980` |
| **Commit som INNEHÅLLER filen (release commit SHA)** | `13157377e772484325246885197f038d7463d4a8` |
| **SHA256** | `bfd69eb1528e2daa90bba84a90b5c3267f21488430dbe96387258c80a5aa8703` |
| **Storlek** | 817 235 byte · 62 instanser |
| **Build-identitet i placen** | `UBRFBuild.sha = 6039d6b…` |
| **Nedladdning kontrollerad** | `HTTP 200`, 817 235 byte, SHA256 stämmer mot filen i repot |

> ### ⚠️ Det här är INTE produktacceptans
>
> **Maskingrindarna är gröna. Ingenting i filen är öppnat i Studio.**
>
> Claude får inte sätta `PRODUCT_ACCEPTED` — bara Tobias, efter fysisk
> genomgång enligt `docs/ENHETSTEST-FIRST-PLAYABLE.md`. Pekaren säger
> vilken fil som är **rätt fil att prova**, ingenting om att den är
> godkänd. **Tom ruta betyder inte PASS.**

## Vad maskinen faktiskt mätte

| Grind | Utfall |
|---|---|
| `FIRST_PLAYABLE_PREFLIGHT` — **pakethalvan** | PASS |
| `FIRST_PLAYABLE_PREFLIGHT` — **runtime-halvan** | **EJ PROVAD utanför Studio** (se nedan) |
| `END_TO_END_PLAYABILITY_GATE` | PASS, alla gröna |
| First Playable-kontrakten | PASS, alla gröna |
| Roster | PASS — 33 av 33 riggade, ridna och unika |
| Lokalisering `sv-SE` + `en-US` | PASS — 33 vyer och 16 nej-vägar på engelska |
| Hela Luau-sviten | 23/23 specar |
| Nyttolasten i den genererade XML:en | 25 moduler: värld, server, klient, delat, data, `UBRFSprak`, `Sprak`, `Prompttext`, identitet |

## Den viktigaste kvarvarande luckan

**Preflightens runtime-halva har ingen spec.** Ingen testbank require:ar
`Preflight.luau`; den körs bara när placen startar i Studio.

Det är inte en formalitet. I den förra kandidaten (`190c54c`) saknades
texttabellen `UBRFSprak` i placen — och `Preflight.luau`, den fail-closade
grind som ska stoppa precis sådant, rapporterade **PASS**. Felet hittades
av en kontroll av den genererade filen, inte av grinden.

Läs alltså Output i Studio själv. Första raderna ska vara
`FIRST_PLAYABLE_SHA`, `FIRST_PLAYABLE_MILJO_SHA` och sist
`FIRST_PLAYABLE_PREFLIGHT: PASS`. Står det **FAIL** — fortsätt inte.

## Så här öppnar du filen

**File → Open from File…** — skriv inte sökvägen för hand. Det var det som
gav `Cannot open place file for reading`.

## Länkregeln som orsakade 404:an

Canonical länk pekar på commiten som **innehåller** filen, inte på
källcommitten. `.rbxlx` läggs in i commiten EFTER den kod den byggdes ur,
så en länk till källcommitten kan aldrig fungera:

```
raw/46231de…/roblox/releases/first-playable-place-46231de/UBRFFirstPlayable.rbxlx
→ 404: filen finns inte i den committen
```

Det var den verkliga orsaken till att Tobias inte kom åt filen tidigare.
Förklaringen som gavs då — inloggning eller `main` — var fel.

## Historik — bevarade, men `DO_NOT_TEST`

| Mapp | Vad som gick fel |
|---|---|
| `first-playable-506b5a3` | miljö-/QA-paket utan gameplay: ingen spawn, ingen dörrinteraktion, ingen häst |
| `first-playable-place-94ce4c9` | `iostream stream error` — saknade `<External>`-rader och `Workspace` |
| `first-playable-place-2af5de2` | spawnen låg 3,2 m ut över tomrummet: spelaren föll och dog |
| `first-playable-place-b1e2a83` | världsmodulen returnerade inget värde — `require()` kastade, frusen himmel utan avatar |
| `first-playable-place-14a0a6e` | returvärdet rättat, men levererad innan spelbarheten mättes |
| `first-playable-place-46231de` | sanktionen **återtagen**: placen saknade hästmodell |
| `first-playable-place-e9a37ff` | provbygge med hästen — men byggt FÖRE lokaliseringen, och utan texttabellen i nyttolasten |

Ingen mapp regenereras på plats. Var och en är pinnad till sin source-SHA
så att det går att se exakt vad som levererades när.
