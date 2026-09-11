# First Playable — place byggd ur `6039d6b`

| Fält | Värde |
|---|---|
| **Källkod (source SHA)** | `6039d6b15db7ef4aa2ca4264c2f24ca707caf980` |
| **Fil** | `UBRFFirstPlayable.rbxlx` |
| **SHA256** | `bfd69eb1528e2daa90bba84a90b5c3267f21488430dbe96387258c80a5aa8703` |
| **Storlek** | 817 235 byte · 62 instanser |
| **Build-identitet i placen** | `ReplicatedStorage.UBRFBuild.sha = 6039d6b15db7ef4aa2ca4264c2f24ca707caf980` |
| **Status** | maskin­grindarna gröna · **ingen produktacceptans** |

> **Release-commit-SHA står i `LATEST-FIRST-PLAYABLE.md`.** Den är en ANNAN
> commit än källan: `.rbxlx`-filen läggs in i commiten EFTER den kod den
> byggdes ur. Canonical länk måste peka på commiten som **innehåller**
> filen — de tidigare README:erna länkade till källcommitten, och länken
> kunde därför aldrig fungera. Det var den verkliga orsaken till 404:an.

## Varför just den här filen finns

Den förra kandidaten (`190c54c`) byggdes aldrig. Arbetsordern krävde att
den GENERERADE filen kontrollerades, inte bara källträdet — och då visade
det sig att `default.project.json` aldrig hade mappat texttabellen
`UBRFSprak`. Placen innehöll noll instanser av den, `Sprak.luau` require:ar
den, och fallbacken `WaitForChild` väntar utan timeout. Hela
lokaliseringen hade varit död i Studio.

Tre grindar var gröna medan det var trasigt: bänksviten (den fogar ihop
modulerna själv), `kolla-place.py` och `Preflight.luau`. Alla tre är
lagade i `6039d6b`, och den här filen är den första som byggts efter det.

## Maskingrindar — utfall på källheaden

| Grind | Utfall |
|---|---|
| `FIRST_PLAYABLE_PREFLIGHT` (pakethalvan) | **PASS** |
| `END_TO_END_PLAYABILITY_GATE` | **PASS** — alla gröna |
| First Playable-kontrakten | **PASS** — alla gröna |
| Roster | **PASS** — 33 av 33 riggade, ridna, unika |
| Lokalisering `sprak.spec` | **PASS** |
| Lokalisering `sprak-en.spec` | **PASS** — 33 vyer + 16 nej på en-US |
| Hela sviten | 23/23 specar |

## Nyttolasten — vad som ligger I filen

Kontrollerat i den genererade XML:en, inte i repot:

    värld       Anlaggningen · BuildKit · Geometri · UBRFKomplex
    server      HorseService · GameplayService · SparService · StallService
                DorrService · HastRigg · Preflight
    klient      PreparationController · KontrollHjalp · TouchControls · Input
                InteractionController · Prompttext
    delat       HorseCore · Sprak
    data        UBRFSpelData · UBRFSkotsel · UBRFSpel · Stallet · UBRFSprak
    identitet   UBRFBuild

## Så här öppnar du den

**File → Open from File…** — skriv inte sökvägen för hand. Det var det som
gav `Cannot open place file for reading` förra gången.

Första raderna i Output ska vara `FIRST_PLAYABLE_SHA`,
`FIRST_PLAYABLE_MILJO_SHA` och sist `FIRST_PLAYABLE_PREFLIGHT: PASS`. Står
det **FAIL** — fortsätt inte; raderna ovanför säger vad som saknas.
**Frånvaro av ett PASS är inte ett PASS.**

## Not tested — läs innan du dömer bygget

**Ingenting i den här filen är provat i Studio.** Ingen agent i sessionen
har Studio- eller runtime-åtkomst. Alla mätningar är gjorda i en bänk
utanför Roblox.

Särskilt oprovat:

- **att preflightens RUNTIME-halva passerar.** Ingen testbank require:ar
  `Preflight.luau`; den körs bara i Studio. Pakethalvans PASS säger att
  delarna ligger i filen — inte att de startar. Det var runtime-halvan som
  sa PASS medan texttabellen saknades.
- att `.rbxlx` faktiskt **öppnar** (XML:en är välformad och strukturellt
  kontrollerad mot projektfilen, vilket inte är samma sak),
- att man fysiskt går igenom dörröppningen utan att fastna,
- fysik, animationer, kamerakänsla, performance, spelkänsla — riggen är
  `HastRigg`s platshållarrigg, inte en modellerad häst,
- hela first-day-flödet med fysisk input och riktigt DataStore,
- **att den engelska texten ser rätt ut i en riktig HUD.** Grinden läser
  strängarna, inte radbrytningen i en 12 px-etikett. Översättningarna är
  dessutom Claudes och oreviewade av någon som kan hästkunskap.

Protokollet är `docs/ENHETSTEST-FIRST-PLAYABLE.md`. Tom ruta betyder inte
PASS.
