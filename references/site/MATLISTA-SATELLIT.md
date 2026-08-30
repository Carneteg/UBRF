# Mätlista — vad som ska mätas på satellitbilden

Datum: 2026-08-30
Status: **STÄNGD — drivs inte vidare**

> Tobias avgjorde 2026-08-30 att den här mätningen inte ska drivas.
> Listan står kvar som en förteckning över vad som ÄR omätt, så att ingen
> senare tar de siffrorna för verifierade. Måtten nedan är alltså inte
> uppgifter någon väntar på — de är en karta över kvarvarande osäkerhet.

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
om husets mått. Dra därför varje linje **hörn till hörn** på samma byggnad,
eller vägg till vägg.

## Linjerna, i fallande ordning av värde

### 1. Stallets bredd — högst värde

Kortsidan, gavel till gavel, tvärs nocken.

Stänger: `STALLINNE.bredd` är i dag **21 m som `[ASSUMPTION]`** i ett
intervall källorna inte är eniga om (15–23 m). Hela stallets innerplan —
fyra boxrader och två gångar — skalas ur den siffran. Det här är det enskilt
mest värdefulla måttet i hela projektet just nu.

### 2. Stallets längd

Längs nocken, gavel till gavel. Spelet har **54 m**.

### 3. Ridhusets bredd och längd

Två linjer. Spelet har **25 × 75 m**, vilket är `[ASSUMPTION]` — se
`SATELLIT-MATNING`, som uttryckligen säger att 25 × 75 inte är låst.

### 4. Avståndet mellan husen

Från stallets långsida rakt över gräsgården till ridhusets långsida.
Spelet har **11 m**.

### 5. Hästgångens läge

Från stallets **norra gavel** längs långsidan fram till mitten av den lägre
byggnadskropp som binder ihop husen. Den kroppen syns i
`references/omnejd/garden-01-mellan-husen-huvraden.jpg` från marknivå, men
den bilden avgör inte hur långt bort den står.

Stänger: hästgången ligger i dag på y = 89,3, avläst ur satellit utan
skalmått. Ett mätt avstånd gör den `VERIFIED` i stället för `DERIVED`.

### 6. Uteridbanan

Två linjer: banans kortsida och långsida. Plus en linje från stallets
östra långsida ut till banans närmaste hörn.

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
menad som ett byggnadsmått behöver den dras om hörn till hörn.
