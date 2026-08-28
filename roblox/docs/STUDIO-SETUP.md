# Koppla Claude Code till Roblox Studio

> **Läs först.** Det här är uppsättningsguiden som kom med paketet, bevarad för
> att MCP-delen är användbar. Mappträdet den beskriver stämmer inte med repot —
> filerna ligger nu i `roblox/buildings/`, `.claude/commands/` och `references/`.
> Fotostegen är dessutom lösta: `/fotoanalys` och `/bygg-byggnad` finns redan,
> anpassade till att JS-spelet inte är ett Roblox-projekt.


Målet: Claude Code ska **titta på fotona, skriva ner vad den ser, bygga efter det, och sedan jämföra sitt bygge med fotot** – inte gissa.
Det här paketet gör det till standardbeteende i projektet.

## 1. Lägg in filerna i ditt Claude Code-projekt (UBRF)

Kopiera in hela innehållet i projektmappen så att strukturen blir:

```
UBRF/
├── CLAUDE.md                      ← reglerna (slå ihop med din befintliga CLAUDE.md om du har en)
├── .claude/commands/
│   ├── fotoanalys.md              ← /fotoanalys <byggnad>
│   └── bygg-byggnad.md            ← /bygg-byggnad <byggnad>
├── references/
│   ├── SITEPLAN.md                ← situationsplan (du fyller i med Claude)
│   ├── renders/                   ← skärmdumpar från Studio hamnar här
│   └── buildings/
│       ├── _mall/KORT.md          ← mall för byggnadskort
│       ├── ridhus/                ← foton + KORT.md
│       ├── stall/
│       └── ...
├── src/
│   ├── BuildKit.lua               ← byggstenar (väggar, tak, fönster, staket, kamera)
│   └── buildings/_exempel.lua     ← mall för byggnadsskript
└── tools/convert-photos.sh        ← HEIC → JPG
```

Har du redan en CLAUDE.md: lägg avsnittet "Byggnader – den viktigaste regeln" överst i den.

## 2. Fotona: från Google Drive till repot

Claude Code kan **inte** öppna HEIC. Fotona i Drive-mappen `UBRF` (IMG_0065–IMG_0165) måste bli JPG.

1. Ladda ner Drive-mappen `UBRF` till datorn (högerklick → Ladda ned).
2. Sortera fotona i undermappar per byggnad och gärna per fasad, t.ex. `ridhus-syd/`, `ridhus-gavel/`, `stall-front/`.
   Det tar 10 minuter och är det enskilt viktigaste steget – Claude vet inte vilken byggnad ett foto visar.
3. Konvertera, en mapp i taget, från projektroten:
   ```
   chmod +x tools/convert-photos.sh
   tools/convert-photos.sh ~/Downloads/UBRF/ridhus-syd ridhus syd
   tools/convert-photos.sh ~/Downloads/UBRF/ridhus-gavel ridhus gavel
   tools/convert-photos.sh ~/Downloads/UBRF/stall-front stall front
   ```
   (Mac: fungerar direkt. Windows: installera ImageMagick först, `winget install ImageMagick.ImageMagick`, kör i Git Bash.)

Har du inte fotograferat alla sidor: `/fotoanalys` skriver en lista på vad som saknas. Bra att ha med nästa gång du är på Husbyvägen:
**varje byggnad rakt framifrån per sida, ett snett hörnfoto per hörn, ett från avstånd som visar hela taket, och närbilder på dörrar/skyltar.**

## 3. Koppla Claude Code till Roblox Studio (MCP)

Du behöver ett sätt för Claude Code att köra kod i Studio och helst ta skärmdumpar. Två alternativ:

**A. Inbyggd MCP i Roblox Studio (officiell, enklast att komma igång med).**
Uppdatera Studio → *Assistant Settings → MCP Servers* → slå på *Enable Studio as MCP server* → välj Claude Code i Quick connect,
eller kopiera den konfiguration Studio visar in i Claude Code (`claude mcp add ...`). Den kan köra Luau, skapa instanser och läsa datamodellen.

**B. Community-servern `robloxstudio-mcp` (har skärmdumpar, vilket jämförelsesteget vill ha).**
```
claude mcp add robloxstudio -- npx -y @chrrxs/robloxstudio-mcp@latest --auto-install-plugin
```
Stäng och öppna Studio; pluginen ska visa "Connected". Verktyget `capture_screenshot` gör att Claude själv kan jämföra bygget mot fotot.

Kör bara en av dem åt gången i samma projekt (`claude mcp list` visar vad som är aktivt). Saknas skärmdumpsverktyg är arbetsflödet
ändå byggt för att du klistrar in en skärmdump från Studio när Claude ber om det.

Lägg BuildKit i Studio en gång: skapa en `ModuleScript` i `ServerStorage` som heter `BuildKit` och klistra in `roblox/buildings/BuildKit.luau`,
eller låt Claude klistra in BuildKit överst i varje `run_code`-anrop (det gör mallen).

## 4. Arbetsflödet per byggnad

```
/fotoanalys ridhus        → Claude öppnar alla foton och fyller i references/buildings/ridhus/KORT.md. Du rättar mått som känns fel.
/bygg-byggnad ridhus      → Claude bygger via MCP, sätter kameran som fotot, tar/ber om skärmdump, listar avvikelser, rättar, upprepar.
```
Börja med ridhuset (störst, tydligast form), sedan stallet. Fyll i `references/SITEPLAN.md` med Claude innan stallet
så att avstånd och rotation mellan byggnaderna stämmer – satellitbilden på Google Maps är bästa källan för det.

## 5. Så får du Claude att verkligen hålla sig till fotona

Det som gör skillnad är inte att be "gör det verklighetstroget", utan tre saker som nu är inbyggda:

1. **Titta först** – kommandona tvingar Claude att öppna varje foto med Read innan den skriver kod.
2. **Skriv ner facit** – KORT.md gör observationerna till siffror (mått, RGB, antal fönster). Kod som avviker från kortet är fel, punkt.
3. **Jämför efteråt** – skärmdump från samma vinkel som fotot, avvikelselista med siffror, minst en rättningsrunda.

Tycker du att en byggnad ändå blivit fel: säg inte "gör den mer lik", säg *vad* som är fel ("taket är för brant", "fönstren sitter för högt")
eller be Claude göra om jämförelsesteget mot ett specifikt foto. Och uppdatera KORT.md – det är kortet Claude bygger efter nästa gång.
