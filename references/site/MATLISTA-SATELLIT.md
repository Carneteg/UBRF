# Mätlista — vad som ska mätas på satellitbilden

Datum: 2026-08-30
Status: **ÖPPEN — väntar på Tobias**

Tobias har visat att han kan dra mätlinjer i Google Maps och läsa av meter.
Det är precis rätt verktyg för det som är blockerat, och den här listan säger
exakt vilka linjer som behövs och vilken fråga var och en stänger.

## Så identifieras husen entydigt

- **STALLET** = huset med **raden av takhuvar längs nocken**. De syns tydligt
  ovanifrån som en prickrad längs hela ryggen.
- **RIDHUSET** = det andra, större huset med **slätt tak utan huvrad**.

## Regeln som gäller för varje linje

`references/site/SATELLIT-MATNING-2026-08-30.md` slår fast att en
måttetikett bara får användas om **linjens båda ändar ligger på det som
mäts**. En linje som börjar i öppen mark och slutar vid ett hörn säger inget
om husets mått.

För byggnader ska linjen följa den byggnadsdimension som mäts och starta/sluta
på byggnadens ytterkontur. Mät inte diagonalt om det är bredd eller längd som
ska fastställas.

## Mätgrupperna, i fallande ordning av värde

### 1. Stallets bredd — högst värde

Mät **tvärs nocken över EN OCH SAMMA gavel**: från ytterhörnet där den ena
långsidan möter gaveln till ytterhörnet där den andra långsidan möter samma
gavel. Detta är stallets kortsida/bredd.

**Mät INTE från den ena gaveln till den andra** — det är stallets längd.

Stänger: `STALLINNE.bredd` är i dag **21 m som `[ASSUMPTION]`** i ett
intervall källorna inte är eniga om (15–23 m). Hela stallets innerplan —
fyra boxrader och två gångar — skalas ur den siffran. Det här är det enskilt
mest värdefulla måttet i hela projektet just nu.

### 2. Stallets längd

Mät **parallellt med nocken**, från den ena yttergaveln till den andra,
helst mellan motsvarande ytterhörn längs samma långsida. Spelet har **54 m**.

### 3. Ridhusets bredd och längd

Två separata linjer:
- **bredd:** över samma gavel, från långsidehörn till långsidehörn,
- **längd:** parallellt med nocken, från yttergavel till yttergavel.

Spelet har **25 × 75 m**, vilket är `[ASSUMPTION]` — se
`SATELLIT-MATNING`, som uttryckligen säger att 25 × 75 inte är låst.

### 4. Avståndet mellan husen

Mät den **kortaste vinkelräta sträckan** från stallets långsida över den öppna
gårdsytan till ridhusets långsida, på ett ställe som inte korsar hästgångens
byggnadsvolym. Spelet har **11 m**.

### 5. Hästgångens läge

Mät från stallets **norra yttergavel** längs stallets långsida fram till
**mittlinjen** på den lägre byggnadskropp som binder ihop stall och ridhus.
Mätlinjen ska följa byggnadens längdriktning, inte gå diagonalt över gården.

Den kroppen syns i `references/omnejd/garden-01-mellan-husen-huvraden.jpg`
från marknivå, men den bilden avgör inte hur långt bort den står.

Stänger: hästgången ligger i dag på y = 89,3, avläst ur satellit utan
skalmått. Ett mätt avstånd gör den `VERIFIED` i stället för `DERIVED`.

### 6. Uteridbanan

Tre separata mått:
- banans kortsida,
- banans långsida,
- kortaste avståndet från stallets östra långsida till banans närmaste hörn.

Stänger: banans mått (spelet har 20 × 40) och dess läge relativt husen,
som i dag är den sista stora `[REFERENCE GAP]`:en i tomtplaceringen.

## Vad satellit INTE kan svara på

**Marknivåskillnaden upp till uteridbanan.** En ovanifrånbild kan inte mäta
höjd. Det var precis det felet som en gång tog bort slänten ur SITEPLAN med
motiveringen att "satellitbilden visar ingen höjdskillnad" — se
`references/SITEPLAN.md`. Den frågan behöver ett mått taget på plats, eller
ett foto med något av känd höjd bredvid slänten.

## Öppen fråga om den befintliga mätningen

Bilden som lämnades 2026-08-30 har en linje märkt **50,29 m** som går från
öppen mark norr om husen ner till stallets nordöstra hörn. Vad den spänner
över är oklart, och därför är den **inte inarbetad någonstans**. Om den var
menad som ett byggnadsmått behöver den dras om enligt instruktionerna ovan.
