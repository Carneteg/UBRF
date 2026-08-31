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

**Ingen av dem konvergerar.** Och den rätade bilden visar varför: entrézonen
hamnar utanför utsnittet. Kontrollpunkterna omsluter alltså inte byggnadens
fyra hörn.

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

## Avläsningens osäkerhet, per källa

| Källa | Bild | Osäkerhet |
|---|---|---|
| stallets plan 1 och 2 | `stall-plan1-utrymning-rak.jpg` | proportion **±0,7 % av husbredden**. Inte "±0,5 m" — den siffran förutsatte en bredd som inte är fastställd |
| ridhusets entréplan, tvärled | `ridhus-entreplan-utrymning.jpg` | läsbart |
| ridhusets entréplan, djupled | samma | **olöst** — rektifieringen konvergerade inte |

## Rummen

Se `docs/F02-RUMSINVENTERING.md` för listan och `roblox/buildings/Planrum.luau`
för koordinaterna. Varje post bär `kalla` med vad i planen den lästes ur.

Id:na är **neutrala** — `rum`, `korridor`, `trapphus`, `schakt`. Ingen
rumsetikett är läsbar i något av fotona, så funktionen är `REFERENCE GAP` även
där gränsen är `PLAN`. `granskning.spec` faller om någon smyger in ett
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
