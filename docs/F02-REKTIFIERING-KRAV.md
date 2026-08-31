# F02 — förhandsdeklarerat krav för det sista rektifieringsförsöket

**Skrivet och committat INNAN försöket kördes.** Det är hela poängen med
dokumentet: ett krav som formuleras efter att man sett utfallet är inget krav,
det är en efterhandsmotivering. Git-historiken är beviset på ordningen.

Senior review 2026-08-31 beslutade ett sista beräkningsförsök att räta
`references/plans/ridhus-entreplan-utrymning.jpg`, med **uttryckligt angivna**
fyra kontrollpunkter på planbladets egen rektangel i stället för automatiska
extrempunkter i den gula ytan.

## Kontrollpunkter

Fyra pixlar i källbilden anges för hand till `tools/rektifiera-plan.py --horn`.
För varje punkt ska det stå **varför den är ett äkta hörn på ett plant
dokument** — inte "ungefär där uppe till vänster".

Duger inte planbladets fyra hörn ska en annan **försvarbar** fyrhörning
användas, och valet motiveras. En fyrhörning som inte omsluter planytan
duger inte: homografin får då extrapolera, och extrapolation är precis det
som gör en rätning fel utan att säga ifrån.

## Validering — på annat än det som anpassats

Fyra punkter mappas exakt av en homografi. Ett residual räknat på dem är noll
av konstruktion och bevisar ingenting. Valideringen sker därför på drag som
**inte ingick i anpassningen**:

| Mått | Krav | Varför just det talet |
|---|---|---|
| **Kantresidual** — planytans kanter i den rätade bilden, max avvikelse från den ideala räta linjen | **≤ 3 % av bredden** | samma tal som de två tidigare försöken mättes mot (8,11 % och 4,89 %). Att ändra det nu hade gjort utfallen ojämförbara |
| **Ortogonalitet** — vinkeln mellan de två väggfamiljerna | **≤ 1,0° från 90°** | ridhuset är 77 m långt. 1° snedhet flyttar den bortre änden 1,3 m — mer än en väggtjocklek, alltså mer än vad en rumsgräns tål |
| **Parallellitet** — spridningen inom varje väggfamilj | **≤ 1,0°** | samma resonemang: en familj som spretar mer än så är inte en familj |

## Vad som händer vid utfall över kravet

**Stopp.** Kravet sänks inte i efterhand, och de sex rummen hittas inte på.
De står kvar som `REFERENCE GAP` och kräver ett rakare källfoto eller ett mått
på plats.

Det här är det sista beräkningsförsöket på den här källan om inte genuint ny
evidens dyker upp.

## Vad som krävs för att ett rum ska få mått

Ett av de sex rummen får en rektangel endast om **alla fyra** av dess gränser
går att spåra till drag i den rätade bilden. Tre lästa kanter och en
extrapolerad fjärde räknas inte — det är en gissning med tre bevis runt sig.


---

## Utfall 2026-08-31 — försöket kört, kravet faller

`tools/dokumentlinjer.py` + `tools/rektifiera-slutforsok.py`, exit 1.

### Kontrollpunkterna: två av bladets hörn fotograferades aldrig

Skylten är **beskuren i överkant**. Bladets två övre hörn ligger utanför
bilden och går inte att peka ut. Hörnen räknades därför fram som skärningar
mellan fyra fotograferade kanter — fyra kanter på ett plant dokument skär
varandra i rektangelns hörn vare sig kameran fick med dem eller inte.

### Linjerna som anpassningen vilar på

Bara dokumentets tryck. Ingen byggnadsvägg.

| Linje | Familj | Varför den är en äkta kant på ett plant dokument | RMS |
|---|---|---|---|
| `A_ram_vanster` | A | aluminiumramens innerkant, rak i verkligheten | 3,36 px |
| `A_gron_vanster` | A | gröna titelbandets vänsterkant, tryckt linje | 3,50 px |
| `A_gron_hoger` | A | gröna titelbandets högerkant, tryckt linje | 3,37 px |
| `A_blad_hoger` | A | bladets högerkant mot ramen | 3,31 px |
| `B_blad_botten` | B | bladets nederkant mot ramens bottenlist | 3,49 px |
| `B_legend_topp` | B | legendrutans överkant, tryckt linje | **0,39 px** |

**Spridningen är kvittot, och den underkänner fem av sex linjer.** En verkligt
tryckt, skarp kant ger 0,39 px. De övriga ligger på 3,3–3,5 px — det är inte
en kant, det är sökfönstret som vandrar. Ramen är rundad och speglande, bandets
kanter ligger snett, och bladets nederkant är delvis utanför bilden.

Familj B har alltså **en** pålitlig linje och **en** opålitlig. Två linjer skär
varandra exakt, så familjen kan inte kontrolleras mot sig själv — och ett litet
vinkelfel i ett nästan parallellt par kastar flyktpunkten hur långt som helst.
Bladets överkant, som hade varit den självklara långa partnern till nederkanten,
är bortklippt.

### Valideringen — byggnadens väggar, som inte ingick i anpassningen

| Mått | Utfall | Krav | |
|---|---|---|---|
| kantresidual, gula ytan | **14,31 %** | ≤ 3 % | **FALLER** |
| parallellitet, långsidor | **5,25°** | ≤ 1,0° | **FALLER** |
| parallellitet, tvärväggar | **5,25°** | ≤ 1,0° | **FALLER** |
| ortogonalitet mellan familjerna | 0,06° | ≤ 1,0° | OK — **men se nedan** |

**Ortogonaliteten räknas inte som ett godkänt mått.** Den affina delen av
transformen skickar de två anpassade riktningarna till vinkelräta axlar. Väggar
som ligger nära de riktningarna blir då vinkelräta av konstruktion. Måttet
mäter alltså delvis sin egen anpassning, och ett prov som bekräftar sig självt
är inget prov. Det redovisas för fullständighetens skull, inte som stöd.

De två mått som verkligen är oberoende — den gula ytans kantrakhet och
spridningen inom varje väggfamilj — faller båda, och kantresidualen på 14,31 %
är **sämre** än båda de tidigare försöken (8,11 % och 4,89 %). Den rätade
bilden är dessutom synligt skev för blotta ögat.

### Beslut

**Stopp.** Kravet sänks inte. De sex rummen står kvar som `REFERENCE GAP` och
kräver ett rakare källfoto — där hela planbladet ryms i bild — eller ett mått
på plats.

Tre metoder är nu prövade och mätta: hörn på den gula ytan, flyktpunkter ur
byggnadens väggar, och flyktpunkter ur dokumentets tryck. Verktygen ligger kvar
i repot så att ett fjärde försök på en **ny** källa börjar där det här slutade.
