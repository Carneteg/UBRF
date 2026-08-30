# Mätlista — vad som ska mätas på satellitbilden

Datum: 2026-08-30
Status: **PÅGÅR — två giltiga längdmått mottagna**

Tobias har visat att han kan dra mätlinjer i Google Maps och läsa av meter.
Det är rätt verktyg för de planmått som är blockerade, men varje mått får bara
användas om linjens ändpunkter faktiskt ligger på det objekt/dimension som mäts.

## Så identifieras husen entydigt

- **STALLET** = huset med **raden av takhuvar längs nocken**.
- **RIDHUSET** = det andra, större huset med **slätt tak utan huvrad**.

## Regeln som gäller för varje linje

`references/site/SATELLIT-MATNING-2026-08-30.md` slår fast att en
måttetikett bara får användas om **linjens båda ändar ligger på det som
mäts**. En linje som börjar i öppen mark och slutar vid ett hörn säger inget
om husets mått.

För byggnader ska linjen följa den byggnadsdimension som mäts och starta/sluta
på byggnadens ytterkontur. Mät inte diagonalt om det är bredd eller längd som
ska fastställas.

## Mottagna mätningar 2026-08-30

### GILTIG — stallets längd: **69,95 m**

Mätlinjen följer stallets långsida parallellt med nocken från den ena
yttergaveln till den andra. Båda ändpunkterna ligger på samma byggnads
ytterkontur.

Klassning: **VERIFIED — Product Owner satellite measurement**

Konsekvens:
- tidigare spelvärde **54 m** är nu `KNOWN MISMATCH / SUPERSEDED`;
- stallets plan, fasadrytm, box-/rumsfördelning och anslutningar måste
  omauditeras mot 69,95 m;
- implementeringen får inte bara sträckas blint. Brand-/utrymningsplanens
  relativa rums- och korridorrelationer ska bevaras när längdskalan rättas.

### GILTIG — ridhusets längd: **77,18 m**

Mätlinjen följer ridhusets långsida parallellt med nocken mellan motsvarande
yttre hörn/gavlar.

Klassning: **VERIFIED — Product Owner satellite measurement**

Konsekvens:
- tidigare 75 m var ett `ASSUMPTION`;
- 75 m är nära men ersätts av **77,18 m** som bättre direktkälla;
- ridhusets arena 20 × 60 m ska fortfarande behandlas som en separat intern
  dimension och får inte automatiskt skalas med ytterbyggnaden.

### EJ ANVÄNDBAR SOM BYGGNADSMÅTT — **60,48 m**

Linjen går diagonalt mellan olika byggnader/objekt och mäter därför varken
stallbredd, stallängd, ridhusbredd eller ridhuslängd.

Klassning: **DO NOT USE FOR GEOMETRY**.

### EJ ANVÄNDBAR SOM DEFINIERAT HUVUDMÅTT — **21,98 m**

Linjen binder inte två tydliga ändpunkter på samma efterfrågade byggnads- eller
ban-dimension. Den får inte användas som stallbredd, ridhusbredd eller
byggnadsavstånd utan en ny linje med definierade ändpunkter.

Klassning: **DO NOT USE FOR GEOMETRY**.

## Återstående mätgrupper, i fallande ordning av värde

### 1. Stallets bredd — högst kvarvarande värde

Mät **tvärs nocken över EN OCH SAMMA gavel**: från ytterhörnet där den ena
långsidan möter gaveln till ytterhörnet där den andra långsidan möter samma
gavel. Detta är stallets kortsida/bredd.

**Mät INTE från den ena gaveln till den andra** — det är stallets längd och
är nu verifierad till **69,95 m**.

Stänger: `STALLINNE.bredd` är i dag **21 m som `[ASSUMPTION]`**. Hela
stallets innerplan — fyra boxrader och två gångar — skalas ur den siffran.

### 2. Ridhusets bredd

Mät över samma gavel, från långsidehörn till långsidehörn, tvärs nocken.
Ridhusets längd är nu verifierad till **77,18 m**.

### 3. Avståndet mellan husen

Mät den **kortaste vinkelräta sträckan** från stallets långsida över den öppna
gårdsytan till ridhusets långsida, på ett ställe som inte korsar hästgångens
byggnadsvolym. Spelet har **11 m**.

### 4. Hästgångens läge

Mät från stallets **norra yttergavel** längs stallets långsida fram till
**mittlinjen** på den lägre byggnadskropp som binder ihop stall och ridhus.
Mätlinjen ska följa byggnadens längdriktning, inte gå diagonalt över gården.

### 5. Uteridbanan

Tre separata mått:
- banans kortsida,
- banans långsida,
- kortaste avståndet från stallets östra långsida till banans närmaste hörn.

Stänger: banans mått (spelet har 20 × 40) och dess läge relativt husen,
som fortfarande är en stor `REFERENCE GAP` i tomtplaceringen.

## Vad satellit INTE kan svara på

**Marknivåskillnaden upp till uteridbanan.** En ovanifrånbild kan inte mäta
höjd. Den frågan behöver ett mått taget på plats, eller ett foto med något av
känd höjd bredvid slänten.
