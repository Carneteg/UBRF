# LOCAL STUDIO-MCP RUNTIME QA — körlista för PR #162

> **Den här filen är HANDOFF-paketet.** Den finns för att runtime-QA:n ska
> kunna jämföra Studio mot **mätta förväntningar** i stället för att titta sig
> omkring. Varje tal nedan är hämtat ur `qa/pre-tobias/WORLD_MANIFEST.json`,
> som i sin tur är mätt ur den byggda världen — inte skrivet för hand.

> Molnsessionen kan inte köra det här: den har ingen `robloxstudio` MCP och
> inget Windows-filsystem (mätt tre gånger). Den lokala Claude Code-sessionen
> på Tobias Windows-maskin kör det.

## 0. Identitet — kontrollera FÖRE allt annat

| | |
|---|---|
| head | `93d596f55b86de06c9de2d188753cb7b141712ad` |
| gren | `claude/first-playable-20260910`, bas `main` |
| fil | `roblox/releases/first-playable-place-0a1b032/UBRFFirstPlayable.rbxlx` |
| SHA256 | `574d613abedc6dd84bf7a4d85cf39209819d378a0143278c9ddfd4bbe2f15bec` |
| storlek | 850 282 byte, 62 instanser |

```powershell
cd "C:\Users\Tobias Carneteg\Desktop\UBRF"
git fetch origin
git checkout claude/first-playable-20260910
git reset --hard 93d596f5
claude mcp list                      # MÅSTE visa robloxstudio
certutil -hashfile roblox\releases\first-playable-place-0a1b032\UBRFFirstPlayable.rbxlx SHA256
```

Stämmer inte SHA256 är det **fel fil** — stoppa där. Saknas `robloxstudio` i
`claude mcp list` är det **fel klient**: MCP:n är registrerad för Claude Code,
inte för Claude Desktop.

## 1. Startup och preflight

Studios Output ska bära, i den här ordningen:

```
FIRST_PLAYABLE_SHA=93d596f55b86de06c9de2d188753cb7b141712ad
FIRST_PLAYABLE_PREFLIGHT: PASS
OK UBRF byggd: 8 byggnader, 12 dörrar, 4 boxrader, 7 gångytor, 3305 objekt
OK  Världen vänd till högerhänt (norr = −Z): 3313 delar speglade
[Rigg] 33 av 33 hästar står i sina boxar
[Dörr] 13 dörrar fick interaktion
```

`FIRST_PLAYABLE_PREFLIGHT: FAIL` är fail-closed och ska stoppa körningen.

## 2. Spawn och mark — inget void

| Mätning | Förväntat |
|---|---|
| spawnläge (tomtkoordinat) | (161.6, 126.4) |
| spawnen vetter mot | `stall N dorrgul` |
| fall till mark | 0,10 m — inte mer |
| takfrihet | ≥ 1,75 m |
| marken under | kolliderande (`Förstukvist golv`) |

**Falsifiering:** gå fram till kanten av verandan. Faller avataren igenom
någon yta som ser ut som mark är det `NO_VOID`-brott och ett stopp.

## 3. Portaler — 13 st, var och en med sina två zoner

Varje rad ska gå att **gå igenom i båda riktningar**. Zonparet är mätt i
källdatan; runtime ska landa i samma zon.

| # | Byggnad | Sida | Typ | Bredd | Läge (x, y) |
|---|---|---|---|---|---|
| 1 | ridhus | N | `dorrvit` | 1.80 m | (139.0, 119.0) |
| 2 | ridhus | N | `dorr` | 1.10 m | (134.3, 119.0) |
| 3 | ridhus | W | `dorrvit` | 2.00 m | (118.0, 109.0) |
| 4 | ridhus | E | `portplat` | 3.40 m | (143.0, 48.5) |
| 5 | ridhus | E | `portbla` | 2.40 m | (143.0, 84.6) |
| 6 | ridhus | S | `portsilver` | 4.00 m | (128.0, 41.8) |
| 7 | stall | W | `dorrgul` | 1.15 m | (151.1, 118.8) |
| 8 | stall | W | `portbla` | 2.40 m | (151.1, 84.6) |
| 9 | stall | N | `dorrgul` | 1.15 m | (161.6, 125.0) |
| 10 | stall | E | `portbla` | 3.60 m | (172.1, 91.2) |
| 11 | stall | S | `dorrvit` | 1.15 m | (157.3, 55.0) |
| 12 | stall | S | `dorrvit` | 1.15 m | (164.2, 55.0) |
| 13 | langa | N | `dorrmork` | 1.10 m | (149.1, 40.0) |

### Deklarerade ICKE-passager — ska vara BLOCKERADE

- `ridhus W dorr` — [REFERENCE GAP] Öppningen ligger bakom läktarens bänkrader. Att såga hål i läktaren för att dörren ska gå att använda vore påhittad geometri. VILKEN långsida läktaren ligger på är ännu inte avgjord (se noten i buildings/Vyer.luau); visar sig den ligga på östra sidan blir den här dörren fri och raden ska bort.

Går den igenom är kontraktet brutet åt andra hållet: grinden räknar
`#blad + #deklarerade == genomgående`, så en icke-passage som *går* att
passera är lika fel som en dörr som inte gör det.

## 4. P0-1 — identifiera objektet, gissa inte

Tobias bild 2 visar en grind som verkligheten saknar. Två kandidater, och de
kräver **motsatta** åtgärder:

| Kandidat | Var | Status i källan | Om det är denna |
|---|---|---|---|
| `SPELABSTRAKTION sargport` | ridhusets norra kortsida | ingen bild visar en grind där; bredden vald | **ta bort ur världen** |
| `sargGrind` | ridhusets östra långsida mot hästgången | läget härlett, bredden `[ASSUMPTION]` | **behåll och märk rätt** |

**Så här avgörs det — inte genom att fråga Tobias igen:**

1. Hitta objektet i runtime. Läs `Name`, `Position`, och attributen
   `Oppningstyp`, `Etikett`, `Mot`, `Langs`, `Utat` om de finns.
2. Räkna om `Position` till tomtkoordinat med `BuildKit.tomtkoord` och jämför
   mot de två kandidaternas läge.
3. Ställ avataren framför den och gå. Notera vilken zon hon hamnar i.
4. Gör samma sak för BÅDA — ordern kräver att båda verifieras oavsett vilken
   bilden visar.

Redovisa per passage: runtime-objekt + sökväg, position, `fromZone -> toZone`,
om den ska vara passage enligt kanon, faktisk avatar-traversal, och vad som
blockerade i den tidigare builden om den föll.

## 5. Hästarna — 33/33 fysiskt närvarande, var och en i SIN box

Manifestet: **33 av 33**. Ingen får stå i en gång.

| Häst | Box | Läge (x, y) |
|---|---|---|
| `air` | 1 | (153.29, 63.60) |
| `allan` | 14 | (159.96, 63.60) |
| `berra` | 27 | (163.68, 63.60) |
| `bing` | 40 | (170.10, 63.60) |
| `blackrock_jack` | 31 | (163.68, 77.60) |
| `conor` | 2 | (153.29, 67.10) |
| `cosmo` | 15 | (159.96, 67.10) |
| `crokino` | 28 | (163.68, 67.10) |
| `curiretto` | 41 | (170.10, 67.10) |
| `dante` | 6 | (153.29, 81.10) |
| `dexter` | 19 | (159.96, 81.10) |
| `fay` | 3 | (153.29, 70.60) |
| `garnit` | 32 | (163.68, 81.10) |
| `hamilton` | 29 | (163.68, 70.60) |
| `hjartat` | 16 | (159.96, 70.60) |
| `jessy` | 45 | (170.10, 81.10) |
| `kay_z` | 42 | (170.10, 70.60) |
| `kennedy` | 7 | (153.29, 88.10) |
| `lady` | 20 | (159.96, 84.60) |
| `larry` | 4 | (153.29, 74.10) |
| `lothar` | 17 | (159.96, 74.10) |
| `lydia` | 44 | (170.10, 77.60) |
| `mac_kenzie` | 33 | (163.68, 84.60) |
| `marabou` | 46 | (170.10, 84.60) |
| `oska` | 30 | (163.68, 74.10) |
| `puma` | 43 | (170.10, 74.10) |
| `replay` | 8 | (153.29, 91.60) |
| `sune` | 5 | (153.29, 77.60) |
| `tess` | 18 | (159.96, 77.60) |
| `toblerone` | 21 | (159.96, 88.10) |
| `trixie` | 34 | (163.68, 88.10) |
| `troy` | 47 | (170.10, 95.10) |
| `westside` | 9 | (153.29, 95.10) |

**Detta är fyndet som en tidigare grind missade:** den frågade "står hästen
nära `box.varld`?", vilket är att jämföra ett tal med sig självt. Sexton av
trettiotre stod i gången. Kontrollera därför i Studio att varje häst står
**innanför en boxfront**, inte bara på rätt koordinat.

## 6. Utrustning — sadel/tack ska finnas fysiskt

| Plats | Delar | Läge (x, y) |
|---|---|---|
| `sadel_dorr_teori` | 3 | (159.90, 119.34) |
| `sadel_stovelhylla` | 1 | (161.40, 117.25) |
| `sadel_vastkrokar` | 2 | (158.42, 117.25) |

Skötselsteget som kräver utrustning ska ha en fysisk källa att gå till.

## 7. Skyltar — kanoniska ankare

| Typ | Text | Läge (x, y) |
|---|---|---|
| `skylt` | **UPPLANDS-BRO RYTTARFÖRENING** | (118.0, 82.0) |
| `cafeskylt` | **CAFÉ KRUBBAN** | (124.4, 119.8) |

`UPPLANDS-BRO RYTTARFÖRENING` saknades i en tidigare build trots att den
finns i kanon och på webben. Den ska synas.

## 8. HUD-kontext och språk

- Vid hästen: momentet på tur går att trycka på.
- Fyra gånger räckvidden bort (räckvidd 12 studs): raden går **inte** att
  trycka på, och rubriken byts till "Gå tillbaka till <hästens namn>".
- Tillbaka vid hästen: HUD:en återgår.
- Ingen prompt får skriva datans interna typnamn (`dorrgul`, `portbla`, …).
- Byt locale till `en-us`: alla spelarvända fält på engelska, egennamn kvar.

## 9. Kärnloopen

`mount -> ride -> dismount -> death -> respawn -> remount -> aftercare -> save`

- Uppsittning ska nekas innan skötseln är gjord (`pass.aterstar`).
- Ett moment 40 studs bort ska nekas (`spel.for_langt`).
- Döden ska släppa sitsen och inte lämna en spökryttare.
- Efter respawn ska skötseln fortfarande räknas som gjord.
- Passet ska räknas **en** gång och finnas kvar efter omläsning.

## 10. Rapportformat

Posta först när allt ovan är kört:

```
LOCAL_STUDIO_QA_PASS — head 93d596f5 — rbxlx 574d613a… — MCP 3.1.3 — Studio runtime PASS
```

Faller något: rapportera `Observed | Root cause | Changed | Falsified |
Not tested`, och **bygg ingen ny `.rbxlx` förrän orsaken är rättad i källan**.
Blir P0-1 en geometriändring får nästa läge en **ny mapp med ny SHA** —
en pinnad release regenereras aldrig på plats.

---

Genererad ur `qa/pre-tobias/WORLD_MANIFEST.json`. Ändras världen ska
manifestet byggas om med `python3 tools/pre-tobias-grind.py --place <fil>`,
och då syns varje avvikelse mot den här listan som en diff.
