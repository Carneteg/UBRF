# Vilken fil ska testas? — canonical pekare

## ✅ Filen att öppna

```
roblox/releases/first-playable-place-6a0e5d7/UBRFFirstPlayable.rbxlx
```

<https://github.com/Carneteg/UBRF/raw/21ae96a8c5faa46a419a33cfe75e77885a171b92/roblox/releases/first-playable-place-6a0e5d7/UBRFFirstPlayable.rbxlx>

> **Ladda ner med högerklick → "Spara länk som…".** GitHub serverar rå-URL:en
> som `text/plain` utan `Content-Disposition`, så en vanlig klickning VISAR
> filen i webbläsaren i stället för att spara den. Sparar du den sidan får du
> inte en `.rbxlx` — och det är då Studio säger att formatet inte känns igen.

| Fält | Värde |
|---|---|
| **Källkod (source SHA)** | `6a0e5d72e6ec6b6bdfa51ac2363df743b7a8e422` |
| **Commit som INNEHÅLLER filen (release commit SHA)** | `21ae96a8c5faa46a419a33cfe75e77885a171b92` |
| **SHA256** | `5595d6ed6696e5cc8e377c8ea7fe637b0523c7410fbdb65cb5995ff9fe1febdd` |
| **Storlek** | 827 690 byte · 62 instanser |
| **Build-identitet i placen** | `UBRFBuild.sha = 6a0e5d7…` |

> ### ⚠️ Det här är INTE produktacceptans
>
> **Maskingrindarna är gröna. Ingenting i filen är öppnat i Studio.**
>
> Claude får inte sätta `PRODUCT_ACCEPTED` — bara Tobias, efter fysisk
> genomgång enligt `docs/ENHETSTEST-FIRST-PLAYABLE.md`. Pekaren säger
> vilken fil som är **rätt fil att prova**, ingenting om att den är
> godkänd. **Tom ruta betyder inte PASS.**

## Varför pekaren flyttades hit

Föregångaren `6039d6b` är **spegelvänd**, precis som Tobias fysiska
Studio-test sa. Inte bara interiörerna — hela världen. `src/site.js` är en
KARTA (+x öster, +y norr); Roblox är högerhänt med Y uppåt, och mappar man
site-y rakt på +Z vänder man kartan. Världen vänds nu en gång till
norr = −Z.

Ingen befintlig grind kunde se det: ett koordinatprov överlever en
spegling (datan ÄR rätt), och paritetsproven jämför webben med Roblox —
är båda speglade likadant är de överens om att ha fel. Webben visade sig
aldrig ha varit speglad, så avvikelsen fanns bara på Roblox-sidan.
`roblox/tests/handighet.spec.luau` och `tools/handighetsgrind.mjs` mäter
nu handigheten på var sin yta.

## Vad maskinen faktiskt mätte

| Grind | Utfall |
|---|---|
| `FIRST_PLAYABLE_PREFLIGHT` — **pakethalvan** | PASS — 54 moduler jämförda ordagrant mot disk |
| `FIRST_PLAYABLE_PREFLIGHT` — **runtime-halvan** | **EJ PROVAD utanför Studio** (se nedan) |
| `handighet.spec` (Roblox) | PASS — kompassen, ankomstvyn, 3 ankare per hus |
| `handighetsgrind.mjs` (webb) | PASS — samma ankare, andra ytan |
| `mark.spec` | PASS |
| `END_TO_END_PLAYABILITY_GATE` | PASS, alla gröna |
| First Playable-kontrakten | PASS, alla gröna |
| Siktgrinden | PASS |
| Roster | PASS — 33 av 33 riggade, ridna och unika |
| Lokalisering `sv-SE` + `en-US` | PASS — 33 vyer och 16 nej-vägar på engelska |
| Hela Luau-sviten | **25/25 specar** |

## Det här ska granskas med ögonen

Vändningen är mätt, inte sedd:

1. **Ankomsten.** Från grusplanen vid husens norra gavlar ska ridhuset
   ligga till HÖGER och stallet till VÄNSTER (`references/SITEPLAN.md`
   rad 22–23).
2. **Stallgången** mot IMG_0159–0162.
3. **Ridhuset inifrån** — läktaren, panelen och domarbåset. Det var den
   spegelvändningen du såg.

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
| `first-playable-place-6039d6b` | lokaliseringen och marken lagade — men **hela världen spegelvänd** (norr låg på +Z) |

Ingen mapp regenereras på plats. Var och en är pinnad till sin source-SHA
så att det går att se exakt vad som levererades när.
