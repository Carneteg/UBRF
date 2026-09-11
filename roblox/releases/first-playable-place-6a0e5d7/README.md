# First Playable — place byggd ur `6a0e5d7`

| Fält | Värde |
|---|---|
| **Källkod (source SHA)** | `6a0e5d72e6ec6b6bdfa51ac2363df743b7a8e422` |
| **Fil** | `UBRFFirstPlayable.rbxlx` |
| **SHA256** | `5595d6ed6696e5cc8e377c8ea7fe637b0523c7410fbdb65cb5995ff9fe1febdd` |
| **Storlek** | 827 690 byte · 62 instanser |
| **Build-identitet i placen** | `ReplicatedStorage.UBRFBuild.sha = 6a0e5d72e6ec6b6bdfa51ac2363df743b7a8e422` |
| **Status** | maskin­grindarna gröna · **ingen produktacceptans** |

> **Release-commit-SHA står i `LATEST-FIRST-PLAYABLE.md`.** Den är en ANNAN
> commit än källan: `.rbxlx`-filen läggs in i commiten EFTER den kod den
> byggdes ur. Canonical länk måste peka på commiten som **innehåller**
> filen.

## Varför just den här filen finns

**Föregångaren `6039d6b` är spegelvänd.** Tobias fysiska Studio-test sa att
interiörerna såg spegelvända ut. De var det — och mer än så: hela världen
var det.

`src/site.js` rad 3 är en KARTA (origo i sydväst, +x öster, +y norr).
Roblox är högerhänt med Y uppåt. Mappar man site-y rakt på +Z vänder man
kartan, och då har den som ser söderut ÖSTER till höger i stället för
väster. Ingen rotation lagar det; bara en reflektion vänder handighet.
Världen vänds därför en gång, på den färdigbyggda modellen, till norr = −Z.

Ingen av de tidigare grindarna kunde se det: varje koordinatprov överlever
en spegling (datan ÄR rätt), och paritetsproven jämför webben med Roblox —
är båda ytorna speglade likadant är de överens om att ha fel. Webben visade
sig aldrig ha varit speglad; `GL.kamera` kompenserar redan.

Den här filen är den första som byggts efter vändningen.

## Maskingrindar — utfall på källheaden

| Grind | Utfall |
|---|---|
| `FIRST_PLAYABLE_PREFLIGHT` (pakethalvan) | **PASS** — 54 moduler jämförda ordagrant mot disk |
| `handighet.spec` (ny) | **PASS** — kompassen, ankomstvyn, 3 ankare per hus |
| `mark.spec` | **PASS** |
| `END_TO_END_PLAYABILITY_GATE` | **PASS** — alla gröna |
| First Playable-kontrakten | **PASS** — alla gröna |
| Siktgrinden | **PASS** |
| Hela sviten | **25/25 specar** |
| `handighetsgrind.mjs` (webbens halva) | **PASS** |

## Falsifiering

Med speglingen bortkopplad ur `Anlaggningen.luau` faller 5 mätningar i
`handighet.spec`: kompassens båda regler, ankomstvyn och båda husens tre
ankare. Grinden mäter alltså handighet och inte sig själv — den läser
mappningen UR den byggda världen (åtta hus med känd mittpunkt på kartan
och mätbar mittpunkt i världen bestämmer den affina avbildningen) i
stället för att räkna om med produktionens egen funktion.

## Så här öppnar du den

**File → Open from File…** — skriv inte sökvägen för hand.

Ladda ner med **högerklick → Spara länk som…**; GitHub serverar rå-URL:en
som `text/plain` och en vanlig klickning VISAR filen i stället för att
spara den. Det var orsaken till "filen är inte format som Roblox känner
igen" förra gången — bytena var rätt, leveransen fel.

Första raderna i Output ska vara `FIRST_PLAYABLE_SHA`,
`FIRST_PLAYABLE_MILJO_SHA`, raden
`OK  Världen vänd till högerhänt (norr = −Z): 3325 delar speglade`
och sist `FIRST_PLAYABLE_PREFLIGHT: PASS`. Står det **FAIL** — fortsätt
inte. **Frånvaro av ett PASS är inte ett PASS.**

## Det här är vad som ska granskas med ögonen

Vändningen är mätt, inte sedd. Den enda som kan avgöra om anläggningen nu
känns igen är någon som varit på UBRF:

1. **Ankomsten.** Står du på grusplanen vid husens norra gavlar ska
   ridhuset ligga till HÖGER och stallet till VÄNSTER
   (`references/SITEPLAN.md` rad 22–23).
2. **Stallgången.** Boxraderna, servicedelen och fönstren ska ligga åt
   samma håll som på IMG_0159–0162.
3. **Ridhuset inifrån.** Läktaren, panelen och domarbåset ska ligga där de
   ligger i verkligheten — det var den spegelvändningen du såg.

## Not tested — läs innan du dömer bygget

**Ingenting i den här filen är provat i Studio.** Ingen agent i sessionen
har Studio- eller runtime-åtkomst.

Särskilt oprovat:

- **att preflightens RUNTIME-halva passerar.** Ingen testbank require:ar
  `Preflight.luau`; den körs bara i Studio.
- att `.rbxlx` faktiskt **öppnar**,
- **hur vändningen SER ut.** Grinden mäter vänster/höger mot siteplanen.
  Att varje takfall, dörrblad och möbel hamnade rätt efter reflektionen är
  mätt i geometri (32 gavelkilar kontrollerade: de 16 med nock i nord–syd
  byter sida, de 16 med nock i öst–väst står still) men inte SETT.
- att man fysiskt går igenom dörröppningen utan att fastna,
- fysik, animationer, kamerakänsla, performance, spelkänsla,
- hela first-day-flödet med fysisk input och riktigt DataStore,
- att den engelska texten ser rätt ut i en riktig HUD. Översättningarna är
  dessutom Claudes och oreviewade av någon som kan hästkunskap.

Protokollet är `docs/ENHETSTEST-FIRST-PLAYABLE.md`. Tom ruta betyder inte
PASS.
