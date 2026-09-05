# G02-A — A/B-underlag för de fyra blockerande parametrarna

Status: `PRODUCT_DECISION_REQUIRED`. Underlaget mäter; det väljer inte.
Beslutet är Tobias.

Beställt i senior re-review av [PR #86](https://github.com/Carneteg/UBRF/pull/86):
G02-A fick `TECHNICAL_REVIEW_PASS`, men fyra skillnader i kärnrörelsen
påverkar faktisk känsla och måste avgöras innan något harmoniseras.

## Så här provar du själv

Previewn för PR #86, med en frågeparameter i adressfältet:

- **A** (dagens webb, Gate 01) — vanlig länk, eller `?ridab=A`
- **B** (Roblox värden) — `?ridab=B`

Parametern läses en gång vid sidladdning. **Utan den kör spelet alltid A.**
Ingen produktkanon är ändrad: `RID_AB.A` i `src/riding/telemetri.js` är
exakt de värden som legat i koden sedan `33559d9`, och ett regressionstest
i `tools/ridtest.mjs` faller om de rör sig.

Mätvärdena nedan kommer ur `node tools/abtest.mjs`, som kör samma manövrer
i båda uppsättningarna — samma häst, samma startläge, samma insatser.

## Vad som skiljer

| | A — webb (Gate 01) | B — Roblox |
| --- | --- | --- |
| Kurvaturtak | 0,42 1/m | 0,30 1/m |
| Galoppens svängfaktor | 0,52 | canter 0,62 |
| Galoppens övre band | 8,00 m/s | 7,00 m/s |
| Cykellängd (norm) | SPRANG × steg | norm ÷ cycles |

## Mätt utfall

Häst `air`, känslighet 0,45. Skänkeln söks upp per gångart under samma
styrutslag som mätningen använder, så att en rad aldrig är fel märkt.

| Manöver | A | B | skillnad |
| --- | --- | --- | --- |
| Trav — ridd volt vid full styrning | **4,12 m** | **5,77 m** | +1,65 m |
| Trav — vridhastighet | 57,2°/s | 40,9°/s | −16,3°/s |
| Trav — cykellängd | 2,14 m | 2,08 m | −0,07 m |
| Galopp — ridd volt vid full styrning | **6,50 m** | **7,64 m** | +1,13 m |
| Galopp — vridhastighet | 64,1°/s | 54,5°/s | −9,6°/s |
| Galopp — cykellängd | 3,51 m | 3,30 m | −0,21 m |
| 20 m volt — krävt styrutslag i trav | 0,30 av 0,72 | 0,42 av 0,72 | +0,12 |
| Snävast möjliga volt | 4,12 m | 5,77 m | +1,65 m |
| Trappan upp | halt → skritt → trav → galopp | samma | — |
| Trappan ned | galopp → trav → skritt → halt | samma | — |
| Topptempo, full skänkel | 6,90 m/s | 6,90 m/s | 0,01 m/s |

### Ett fynd på köpet, som inte var det jag letade efter

**Modellen håller inte skritt med konstanta hjälper.** Skänkeln söktes i
40 steg från 0,01 till 1,00 under full styrning, och ingen enda insats
landade i skrittbandet — ekipaget stannar i halt eller lägger sig i trav.
Det gäller **båda** uppsättningarna, så det är inte en A/B-skillnad utan
en egenskap i tempoförhandlingen. Skritt rids i praktiken genom att
parera, inte genom att lägga sig på en insats. Värt att veta för G02-B,
och värt att avgöra om det är avsett.

## Vad siffrorna betyder

Skillnaden sitter i **hur snävt ekipaget kan svänga**, och den är stor
nog att kännas: en volt i trav är 4,1 m i A och 5,8 m i B — fyrtio procent
vidare. Vridhastigheten skiljer 16°/s.

Övergångarna, trappan och topptempot är däremot **identiska**. Det som
står på spel är alltså svängkänslan, inte gångartssystemet.

Cykellängden skiljer bara 3–6 %. Den märks som hovtakt mot mark, inte som
styrning, och är den minst laddade av de fyra.

## Rekommendation

**Jag rekommenderar A som canonical, med B:s galoppsvängfaktor som enda
undantag att överväga.** Skälen, i ordning:

1. **A är den enda uppsättningen som har passerat en subjektiv gate.**
   Gate 01 stängdes på webbversionens känsla. B:s tal kom in vid
   porteringen `58a8030` och auditens paritetsrad godkändes uttryckligen
   på *formuleringen*, med noteringen att talen skiljer — de har alltså
   aldrig prövats mot ett känslobeslut.
2. **A ger mer kontroll i ett 20 × 60 m ridhus.** En volt på 4,1 m ryms
   var som helst i hallen; 5,8 m gör snäva vändningar vid kortsidan
   trängre. Kravlistan säger kontroll först, realism sist.
3. **B:s galoppsvängfaktor 0,62 mot A:s 0,52 går åt andra hållet** än de
   övriga: den gör galoppen *snävare* relativt sitt tempo. Att en snabb
   gångart svänger vidare är hela poängen med gångartsberoende
   svängbegränsning, och 0,52 uttrycker det tydligare. Men skillnaden är
   liten (galoppvolten 6,5 mot 7,6 m) och kan mycket väl vara den bättre
   kompromissen i praktiken — det är den enda av de fyra där jag inte har
   en stark uppfattning.

**Motargumentet du bör väga:** Roblox är primär spelplattform enligt
`docs/GATE-01-PLATFORM-ADDENDUM.md`. Väljer vi A måste Roblox-sidan
justeras, och den justeringen kräver en Studio-playtest som jag inte kan
köra. Väljer vi B ändras webbens känsla, som redan är accepterad.

Jag har inte ändrat något. Säg A, B eller en tredje trimning, så
implementerar jag den på båda ytorna och kör om paritetsspecen.

## Villkor för merge — A/B-lagret är temporär reviewkod

Fastställt i senior review av #86 (`A/B_REVIEW_PASS`):

> A/B-harnessen är **temporär review-kod**. När Tobias har valt canonical
> känsla ska `?ridab`, B-växlingen och den temporära dubbla
> feel-konfigurationen tas bort eller kollapsas till EN canonical
> uppsättning innan G02-A får mergeas. Vi ska inte lämna en dold
> alternativ produktfysik i produktion.

Alltså, när beslutet är fattat och innan merge:

1. den valda uppsättningens värden skrivs in som de enda i modellen,
2. `RID_AB`, `ridSattAB()`, `ridAB()` och `?ridab`-avläsningen tas bort,
3. `tools/abtest.mjs` tas bort eller görs om till ett rent mätverktyg utan
   växling,
4. `src/game.js` läser konstanterna direkt igen och
   `tools/exportera-ridkanon.mjs` pekas om,
5. de fyra `BLOCKERAR`-raderna i `roblox/tests/paritet.spec.luau` tas bort
   i takt med att avvikelserna försvinner,
6. produktionsvakten i `tools/ridtest.mjs` skrivs om till att låsa den nya
   canonical uppsättningen.

Ingen del av det görs innan valet är gjort.

## Kvarstående produktfråga, buren vidare till G02-B

**Modellen håller inte skritt med konstanta hjälper.** Uppmätt i båda
uppsättningarna: skänkeln söktes i 40 steg från 0,01 till 1,00 under full
styrning, och ingen insats landade i skrittbandet — ekipaget stannar i
halt eller lägger sig i trav.

Senior review av #86 bekräftar det som en **separat produktfråga inför
G02-B**, uttryckligen inte något som ska lösas tyst inom G02-A:

> Lös inte detta tyst i G02-A — logga det som nästa riding-feel
> blocker/tuningbeslut.

Skritt är den gångart en ridskoleelev tillbringar mest tid i. Att den
bara går att hålla genom att parera, inte genom att lägga sig på en
insats, är antingen ett medvetet val eller ett hål i tempoförhandlingen.
Det avgörs i G02-B, inte här.
