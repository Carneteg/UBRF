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
