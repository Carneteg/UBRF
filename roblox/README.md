# UBRF — hästsystem för Roblox

Ett ridsystem för Roblox Studio, byggt för riggade skinnade hästmodeller. Systemet
bygger aldrig en häst av delar; det tar emot en färdig modell och kör den.

**Det här är ett eget spår.** Resten av repot är ett HTML5-spel i JavaScript och
delar ingen kod med den här mappen. Det som *är* gemensamt är siffrorna: gångarternas
tempoband är portade rakt av från `src/model.js`, som i sin tur var en port från
Luau. Samma häst, samma takt, två motorer.

`roblox/buildings/` är ett tredje, fristående spår: byggstenar för att bygga
anläggningens hus i Studio. Det delar ingen kod med hästsystemet.

## Installation

Med [Rojo](https://rojo.space):

```bash
rojo serve roblox/default.project.json
```

Utan Rojo: kopiera in för hand enligt trädet i `default.project.json` —
`src/shared/HorseCore` till ReplicatedStorage, `src/server` till
ServerScriptService, `src/client` till StarterPlayer/StarterPlayerScripts.

Sedan: lägg in en hästmodell, sätt taggen `Horse` på den, kör.
`docs/HORSE-MODEL-SPEC.md` är kontraktet för vad modellen måste innehålla.

## Styrning

| Tangent | Gör |
|---|---|
| `W` | framåt — ur halt startar skritt |
| `S` | ned en gångart, sedan stopp, sedan backa |
| `A` `D` | styr |
| `Shift` | upp en gångart |
| `Ctrl` | ned en gångart |
| `Space` | hoppa |
| `E` | sitt av |
| `F8` | felsökningsrutan |

Gamepad: vänsterspak styr, `R1`/`L1` byter gångart, `A` hoppar.

Spelaren väljer **gångart**, aldrig ett exakt tempo. Det är skillnaden mot en
gaspedal, och det är den enskilt viktigaste orsaken till att hästen känns som en
häst i stället för som ett fordon.

## Arkitektur

```
ReplicatedStorage/HorseCore     delat, ingen sidoeffekt
  Types          typerna alla talar i
  Config         statistik, raser, lynnen, animationsnycklar
  Gaits          gångarternas band, takt och kamera
  StateMachine   fart och mark in, tillstånd ut. Rör aldrig en Instance.
  RigAdapter     enda stället som vet hur en hästmodell ser ut inuti
  Networking     fjärrobjekten

ServerScriptService/Horse       auktoritet
  HorseService   ägarskap, uppsittning, uthållighet, validering

StarterPlayerScripts/Horse      responsivitet
  init.client    EN uppdateringsloop, i bestämd ordning
  Input          knappar → avsikt
  Movement       avsikt → fart, sväng, lutning, tillstånd
  Animation      tillstånd → spår, övertoning, procedurell påbyggnad
  Rider          IK för händer och fötter
  Camera, Sound, Effects, Debug
```

Två regler bär hela uppdelningen:

1. **Ingen modul utanför `RigAdapter` rör en MeshPart, ett Bone eller ett
   AnimationTrack.** Därför går hästmodellen att byta utan att ridlogiken skrivs om.
2. **`StateMachine` och `Gaits` har inga sidoeffekter.** De går att testa utan att
   spelet körs.

## Auktoritet

Servern äger: vem som rider vad, om uppsittning får ske, uthålligheten, hästarnas
beständiga statistik. Klienten äger: kamera, inmatning, animation, och — via
nätverksägarskap — sin egen hästs rörelse.

Det sista är ett medvetet val. Simuleras rörelsen på servern ligger latensen i
varje styrutslag och hästen känns som en båt. Klienten skickar tio tillstånds-
uppdateringar i sekunden; servern klampar gångarten mot uthållighetstaket och
avvisar orimliga värden.

## Vad som är byggt, och vad som inte är det

Byggt och kompilerar (`luau-compile` rent på alla filer):

- Gångartsmaskin med hysteres, tio tillstånd, minimitider mot flimmer
- Rörelse: accelerationskurvor, momentum, fartberoende svarvhet, lutning, backning
- Mark via Humanoid, med utjämnad sluttningsnickning
- Hopp med minimifart, nedkylning och uthållighetskostnad
- Animation: övertoning, fartföljande uppspelning, slumpade idle-varianter,
  procedurell hals, svans och öron
- Uppsittning via ProximityPrompt och Seat, IK för händer och fötter
- Kamera som ändras med gångarten, med väggkontroll
- Hovljud i gångartens takt, med underlagsdetektering
- Damm i trav och uppåt, bara på mark som dammar
- Uthållighet som sänker gångartstaket i stället för att tvinga fram stopp
- Raser och lynnen som ren data
- Felsökningsruta på F8
- Mätbänk för rörelse och kamera utanför Studio (`tests/`), som kör
  produktionskoden mot stubbade Roblox-globaler

Inte byggt, medvetet:

- **Beständig hästdata.** `BondLevel` och statistiken finns som fält men sparas
  inte mellan sessioner. Det kräver DataStore och en profilmodul, och att bygga
  det halvvägs är värre än att inte bygga det.
- **Hästvård** (borstning, hovar, fodring). Arkitekturen står redo — statistiken
  finns, lynnet finns — men ingen kod är skriven.
- **NPC-hästar och avståndsoptimering.** Serverloopen är redan centraliserad och
  klarar många hästar; en LOD-nivå för hästar långt bort finns inte.
- **Tyglar som syns.** Attachment-punkterna finns och händerna hittar dem. Ingen
  Beam eller RopeConstraint är dragen mellan dem.
- **Egen fysik för AnimationController-riggar.** Systemet kräver Humanoid.

Ingen av de här sakerna finns som tom stomme som ser färdig ut. Saknas något
säger konsolen det med namn.
