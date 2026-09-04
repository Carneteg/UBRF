# UBRF — Stall efter pausrummet — PO-referens v1

Status: **PO-approved sufficient implementation reference**
Datum: 2026-09-04
Scope: Stallhuset, zonen direkt efter pausrummet/uppehållsrummet och in i stallgången.

> Tobias: "Det får duga" om den sammanfogade konceptmodellen. Detta betyder att modellen är tillräcklig som arbetsunderlag för implementation, **inte** att fria mått eller nya rum får hittas på.

## Källa och prioritet

1. Tobias nya foton 2026-09-04 är visuell verklighetskälla.
2. Den här filen är den repo-tillgängliga spatiala sammanfogningen av fotona.
3. Befintliga planer/Spatial Canon gäller fortsatt för övergripande geometri och orientering.
4. Om exakt mått saknas: `REFERENCE GAP`. Gissa inte.

## Bindande topologi

Direkt efter pausrummet öppnar sig en praktisk stall-/servicezon som leder vidare till huvudstallgången. Zonen ska **inte** modelleras som en rad nya slutna rum.

Flöde:

`PAUSRUM -> ÖPPEN SERVICE/TVÄTT-ZON -> STALLGÅNG -> BOXFRONTER / VIDARE STALL`

Vid bortre änden finns en utgångszon med grå dubbeldörr och grön nödutgångsskylt. I samma bortre väggparti finns ett välvt/bågat fönster med metallgaller.

## Visuellt och fysiskt innehåll

### Vänster / vit servicevägg
- Vita väggar.
- Synlig kabel-/rördragning utanpå väggen.
- Grå industriell service-/teknikdörr med metallhandtag och kodlås/knappsats.
- Väggklocka ovanför/vid dörrzonen.
- Nöd-/säkerhetsutrustning i grönt/rött på väggen.
- Rostfri skölj-/tvättstation med vask.
- Väggmonterad hylla/korg för rengöringsartiklar.
- Krokar/redskap/handdukar runt tvättplatsen.
- Ytterligare grå dörr i anslutning till tvättzonen; exakt funktion ska inte namnges utan befintligt källstöd.

### Mittzon
- Låg mörkgrå metall-/stallavskärmning med galvaniserade rör/räcken.
- Liten öppen arbets-/förvaringshylla på golvet med plastbackar, flaskor och stallartiklar.
- Stor blå säck/bin i anslutning till hyllan.
- Låg svart/grå rull-/trappall.
- Allt ska stå så att gångstråket för spelaren förblir fritt.

### Stallgång
- Tydlig mörk, rektangulär gummi-/markstenslik gångyta genom stallet.
- Omgivande golv är ljusare betong.
- Gången ska läsa som den huvudsakliga rörelsen genom stallzonen.

### Höger / boxfronter
- Mörkgrå box-/stallfronter med galvaniserade metallramar.
- Övre öppna metallsektioner/räcken.
- Vita anslags-/informationstavlor monterade på boxfronterna.
- Brandsläckare monterad på front/ram mellan tavlor.
- Boxöppningar och hästar kan förekomma bakom fronter, men denna F02-referens gäller främst miljö/fysisk arkitektur.

### Bortre ände
- Grå dubbeldörr med grön nödutgångsskylt ovanför.
- Välvt/bågat fönster med metallgaller.
- Låg stallavskärmning/räcke framför/vid fönsterzonen.
- Öppen passagegeometri; inga extra väggar får byggas för att 'fylla ut'.

### Tak
- Högt stalltak.
- Korrugerad plåt.
- Synliga träbalkar.
- Galvaniserade stolpar/rör.
- Enkla industriella taklampor.

## Spatial regel

Det viktiga i denna zon är **öppenhet + passage + arbetsfunktion**. Fotona visar en sammanhängande stallmiljö med servicefunktioner i kanten, inte små separata rum.

Implementationen får därför inte skapa nya boxade volymer från etiketter som `tvätt`, `service`, `förvaring` osv.

Fysisk geometri ska fortsatt uttryckas med Spatial Canon-principerna:
- `WALL`
- `OPENING`
- `OPEN_AREA`
- `NO_WALL_ZONE`
- `GLASS` endast om källstöd finns

## Konceptuell plan, ej måttsatt

```text
┌──────────────────────────────────────────────────────────────────┐
│ VIT SERVICEVÄGG                                                  │
│ [grå dörr] [tvätt/vask + säkerhet]        [grå dörr]            │
│                                                                  │
│      låg metallavskärmning / arbetszon                           │
│      [hylla] [blå bin] [pall]                                    │
│                                                                  │
│ FRÅN PAUSRUM  ->  ÖPPEN ZON  ->  MÖRK STALLGÅNG  ->              │
│                                      │                           │
│                                      │  MÖRKGRÅ BOXFRONTER       │
│                                      │  anslagstavlor            │
│                                      │  brandsläckare            │
│                                      │                           │
│                         [välvt fönster] [grå dubbeldörr / ut]    │
└──────────────────────────────────────────────────────────────────┘
```

## Implementationskrav

- Integrera i samma kanoniska kedja som övrig F02:
  `src/site.js / kanondata -> exporter -> generated UBRFKomplex -> web + Roblox`.
- Ingen separat Roblox-speciallösning.
- Behåll fri spelbar passage från pausrummet till stallgången.
- Inredning får inte blockera dörrar eller huvudgång.
- Exteriör är fortsatt låst.
- Reception/ridhusfixar som PO redan godkänt får inte påverkas.
- Okända exakta mått = `REFERENCE GAP`, inte designfrihet.

## Reviewkameror som ska finnas efter implementation

Minst två nya fasta visuella views:
1. `STALL-EFTER-PAUSRUM-V1` — från pausrummets riktning ut mot servicezon + stallgång.
2. `STALL-EFTER-PAUSRUM-V2` — från stallgången tillbaka mot tvätt/servicevägg + utgångsrelation.

Syftet är side-by-side-kontroll mot den nya PO-fotouppsättningen.
