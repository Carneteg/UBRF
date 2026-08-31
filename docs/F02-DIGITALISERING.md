# F02 — digitaliseringsprotokoll

Hur planrummen i `roblox/buildings/Planrum.luau` togs fram, vad som är mätt och
vad som inte är det. Skrivet för att någon annan ska kunna göra om det och få
samma svar — eller visa att jag har fel.

## Varför koordinaterna är normaliserade

`references/plans/PLAN1-OMMATNING-2026-08-30.md` säger uttryckligen:

> Den här bilden har lika lite skalstock som den förra. Stallets totalbredd är
> fortfarande ett arbetsantagande i intervallet 15–23 m, och
> `references/plans/OAVGJORT.md` fråga 2 står öppen.

Meterrektanglar räknade på 21 m hade gjort det arbetsvärdet till kanon
bakvägen, genom rumsgeometri. Det är samma mönster som redan fällt färgexporten
och objektantalet i det här projektet: ett provisoriskt tal som blir sanning
för att något annat råkade läsa det.

Därför är `nrekt` **andelar 0–1** av husets bredd och längd, och `Planrum.meter()`
räknar om dem med en skala som är märkt **`ASSUMED_SCALE`**. Klassen följer med
hela vägen ut i QA-texten, så att den som granskar ser skillnaden mellan

- **planens proportioner** — `PLAN`, belagda
- **planens meterskala** — `ASSUMED_SCALE`, inte belagd

## Rektifiering av ridhusplanen — försökt, mätt, misslyckad

Invändningen att "perspektivfoto" inte räcker som skäl att sluta är riktig: ett
foto av ett plant dokument är en projektiv avbildning och går att invertera om
fyra kontrollpunkter finns. `tools/rektifiera-plan.py` gör det — gul planyta
tröskas fram, största sammanhängande klumpen behålls, homografin löses som ett
8×8-system, bilden varpas.

Verktyget mäter dessutom **sitt eget residual på ett sätt som inte kan bli noll
av konstruktion.** Fyra punkter mappas exakt av en homografi, så ett residual
på hörnen hade bevisat ingenting. I stället samplas planytans **kanter** i den
rätade bilden — hundratals punkter som transformen aldrig fick se — och
avvikelsen från den ideala rektangeln redovisas.

### Utfall

| Kontrollpunkter | Vänsterkant | Högerkant | Krav |
|---|---|---|---|
| automatiska, extrempunkter i gul yta | **8,11 %** | 1,56 % | < 3 % |
| anpassade väggliner, y 948–2824 | **4,89 %** | 2,00 % | < 3 % |
| dokumentets tryck, tredje försöket | **14,31 %** | — | < 3 % |

**Ingen av dem konvergerar.** Och den rätade bilden visar varför: entrézonen
hamnar utanför utsnittet. Kontrollpunkterna omsluter alltså inte byggnadens
fyra hörn.

### Andra försöket: flyktpunkter ur parallella väggriktningar

Invändningen att man ska pröva **parallella väggriktningar** i stället för hörn
är riktig — en plan yta går att räta ur två flyktpunkter utan att ett enda hörn
behöver hittas. `tools/analysera-planlinjer.py` gör det: Sobel-kanter inne i
planytan (ramen och legenden får inte rösta), Hough, och toppar sökta i två
skilda vinkelband — annars äter långsidorna hela listan, de är tre gånger så
långa som tvärväggarna.

| Familj | Linjer | Flyktpunkt (px) | **Medelresidual** |
|---|---|---|---|
| långsidor | 14 | (118, −2368) | **178 px** |
| tvärväggar | 14 | (2712, 870) | **382 px** |

Bilden är 900 × 2502 px. Konvergerar en familj mot en äkta flyktpunkt ligger
residualen nära noll; 178 och 382 px betyder att familjerna **inte** skär i en
punkt. De är förorenade — läktarbanden har egen lutning, tvärväggarna är korta
segment, och symboler röstar med.

En homografi byggd på de punkterna hade rätat bilden **fel utan att någonting
sagt ifrån**. Därför används den inte.

### Tredje försöket: flyktpunkter ur dokumentets eget tryck

Senior review bad om ett sista försök på **planbladets fyra hörn** i stället
för den gula ytan. Två av bladets hörn visade sig aldrig ha fotograferats —
skylten är beskuren i överkant — så hörnen räknades i stället fram som
skärningar mellan fyra fotograferade kanter (`tools/dokumentlinjer.py`).

Anpassningen använde bara dokumentets tryck; valideringen skedde på byggnadens
väggar, som inte ingick i anpassningen.

| Mått | Utfall | Krav |
|---|---|---|
| kantresidual, gula ytan | **14,31 %** | ≤ 3 % |
| parallellitet, långsidor | **5,25°** | ≤ 1,0° |
| parallellitet, tvärväggar | **5,25°** | ≤ 1,0° |

Kravet var **förhandsdeklarerat och committat innan försöket kördes** —
`docs/F02-REKTIFIERING-KRAV.md`, commit `483ce4e`. Utfallet är sämre än båda de
tidigare försöken. Orsaken är mätt: av sex anpassade linjer är bara en en
verklig skarp kant (0,39 px spridning); de övriga ligger på 3,3–3,5 px, vilket
är sökfönstret som vandrar snarare än en kant. Familj B har därmed en pålitlig
linje och en opålitlig, och kan inte kontrolleras mot sig själv.

**Stopp.** Det var det sista beräkningsförsöket på den här källan.

### Vilka kontrollpunkter som saknas, konkret

Den gula planytan går **inte** att använda som fyrhörning i den här bilden:

- **caféannexet skjuter ut** utanför huvudrektangeln och kapar extrempunkten
  i övre högra hörnet,
- **entrézonens rum bryter den gula ytan i strimlor** — en radvis mätning ger
  4–6 segment där, så ytterkanten är inte ytans kant,
- **de gröna utrymningsbanden** ligger delvis utanför husväggen.

Det som skulle låsa upp de sex rummen:

1. **fyra hörn på själva planbladet** (det vita dokumentet i ramen) i stället
   för på den gula ytan — kräver en kantdetektor som verktyget inte har, eller
   fyra punkter pekade för hand och inskrivna i det här dokumentet, eller
2. **ett omfotograferat plan rakt framifrån**, som stallets `-rak`, eller
3. **ett mått på plats** i entrédelen.

Tills dess står de sex rummen utan `nrekt`. Verktyget och siffrorna finns kvar
i repot så att nästa försök börjar där det här slutade, inte om från noll.

## Räkning per plan

| Plan | Rum | Ritbara | Väggsegment | Trappor | Olösta |
|---|---|---|---|---|---|
| ridhusets entréplan | 12 | 6 | 24 | 2 | **6** |
| stallets plan 1 | 7 | 7 | 28 | 1 | 0 |
| stallets plan 2 | 8 | 7 | 28 | 1 | **1** |
| **planrum totalt** | **27** | **20** | **80** | **4** | **7** |

Granskningsläget ritar utöver planrummen även de befintliga byggda zonerna:
**34 zonplattor**, **136 väggsegment**, **3 trappmarkeringar**, **91 vyer**
(två per zon plus tre våningsöversikter).

## Öppningarna

Fyra ytterdörrar är digitaliserade ur stallplanen, två av dem med läge.

Källan är **de gröna utrymningsbanden**: där ett band korsar ytterväggen finns
en dörr. Det är den enda dörrmarkeringen i planen som går att läsa utan att
gissa — väggluckorna inne i huset är för många och för lika ritbrus.
`tools/planoppningar.py` tröskar fram den gula husytan och de gröna banden och
rapporterar vilka band som rör huset. Fyra gör det.

**Förekomsten är säkrare än läget.** Att ett band ligger på västväggen är en
topologisk avläsning. Var på väggen det sitter beror på var husets gavlar
anses börja, och gavlarna är inte entydiga i fotot. Läget mättes därför med
**tre oberoende definitioner** av husets utsträckning, och spridningen mellan
dem avgör:

| Öppning | Vägg | Spridning | Utfall |
|---|---|---|---|
| `s_opp_ost_service` | öst | **0,62 %** | läge satt, `PLAN` |
| `s_opp_vast_mitt` | väst | **1,34 %** | läge satt, `PLAN` |
| `s_opp_vast_klubb` | väst | 2,08 % | **`REFERENCE GAP`** — bara sidan är läst |
| `s_opp_norr_gavel` | norr | 2,71 % | **`REFERENCE GAP`** — bara sidan är läst |

Gränsen 2 % sattes innan utfallet lästes. Att skriva ut ett läge för de två
sista hade låtit en avläsning som spretar 2,7 % se ut som ett mått.

**Ett avsteg att ta upp i Steg A:** planen lägger västöppningen på 50,2 % av
längden; modellens tvärkorridor ligger på 42,3 %. Skillnaden ≈ 5,5 m är
obedömd och ska tas upp, inte rättas i tysthet åt något håll.

**Ridhuset: noll öppningar.** Planen är inte rätbar, så ingen andel längs
någon vägg är mätbar. `REFERENCE GAP`.

**Innerdörrar: noll, som `REFERENCE GAP`** — inte som noll.

### De sex ridhusrummen efter rektifiering

**Inget av dem återvanns.** Tre metoder mätte sig själva och underkändes:
hörnmetoden på 4,89 % kantresidual mot kravet 3 %, väggflyktpunkterna på
178/382 px, och dokumentflyktpunkterna på 14,31 % med 5,25° spridning inom
väggfamiljerna. De sex står kvar utan mått.

Det var det **sista** beräkningsförsöket på den här källan. Det som återstår är
ett omfotograferat plan där hela bladet ryms i bild, eller ett mått på plats.

## Avläsningens osäkerhet, per källa

| Källa | Bild | Osäkerhet |
|---|---|---|
| stallets plan 1 och 2 | `stall-plan1-utrymning-rak.jpg` | proportion **±0,7 % av husbredden**. Inte "±0,5 m" — den siffran förutsatte en bredd som inte är fastställd |
| ridhusets entréplan, tvärled | `ridhus-entreplan-utrymning.jpg` | läsbart |
| ridhusets entréplan, djupled | samma | **olöst** — rektifieringen konvergerade inte |

## Rummen

Se `docs/F02-RUMSINVENTERING.md` för listan och `roblox/buildings/Planrum.luau`
för koordinaterna. Varje post bär `kalla` med vad i planen den lästes ur.

Id:na är **neutrala** — `rum`, `korridor`, `trapphus`, `schakt`. Ingen läsbar
skylt namnger något av planrummen, så funktionen är `REFERENCE GAP` även där
gränsen är `PLAN`. (Rättelse: här stod tidigare att ingen rumsetikett alls är
läsbar i något foto. `stall-entre-13.jpg` visar skylten `Stall` på en
branddörr — men den namnger passagen, inte ett planrum. `docs/F02-BEVISINDEX.md`.) `granskning.spec` faller om någon smyger in ett
semantiskt namn som `wc` eller `kontor`.

## Granskningsgeometrin

Zonplattorna visar var ett rum ligger men inte att det har väggar.
`Granskning.byggVaggar` ritar därför en tunn kontur runt varje ritbar zon,
plus en egen markering för trappor.

Allt hamnar i **`F02ReviewGeometry`**, allt är `CanCollide = false`, allt bär
attributet `F02Review`, och `UBRFVaggar(false)` gömmer det. Specen faller om
någon av dem börjar kollidera.

**Det är annotering, inte byggnad.** Ingenting befordras till spelgeometri
förrän Tobias accepterat topologin i Steg A.
