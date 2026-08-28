# Vad hästmodellen måste innehålla

Systemet bygger aldrig en häst. Det tar emot en färdig riggad modell och kör den.
Det här dokumentet är kontraktet mellan modellen och koden.

En sak att förstå först, för den avgör hur mycket arbete resten är:

> **Benens namn spelar nästan ingen roll.** Ett skinnat nät animeras av klipp som
> är gjorda mot exakt den riggen. Roblox matchar ben mot klipp internt — koden
> läser aldrig ett bennamn för att spela en gångart. Bennamnen nedan behövs bara
> för de *procedurella* påbyggnaderna (halsen som leder svängen, svansen som
> följer farten, öronen som rör sig). Saknas de tappar du polish, inte spel.

Det som däremot måste stämma är **hierarkin, kollisionen och attachment-punkterna**.
Där är koden strikt, för det är där spelet lever.

---

## Hierarki

```
Horse                          ← Model, taggad "Horse" med CollectionService
│
├── BodyCollider               ← BasePart. Osynlig. DEN HÄR är hästen fysiskt.
│   └── RootJoint              ← Motor6D till Visual. Bär lutning och nickning.
│
├── Humanoid                   ← se "Humanoid eller AnimationController" nedan
│   └── Animator
│
├── Visual                     ← Model eller Folder. Ingen kollision alls.
│   ├── HorseMesh              ← MeshPart, skinnat, med benhierarkin i sig
│   ├── Mane                   ← valfritt, separat nät eller del av HorseMesh
│   ├── Tail                   ← valfritt
│   └── Tack                   ← sadel, träns, valfritt
│
├── Attachments                ← Folder (eller direkt på BodyCollider)
│   ├── SaddleAttachment
│   ├── LeftReinAttachment
│   ├── RightReinAttachment
│   ├── LeftStirrupAttachment
│   └── RightStirrupAttachment
│
├── RiderSeat                  ← Seat. Osynlig, massless, CanCollide false.
│
├── HoofDust                   ← ParticleEmitter, valfritt. Enabled = false.
│
├── HorseStats                 ← Configuration
├── GaitConfig                 ← Configuration
├── AnimationConfig            ← Configuration
└── Sounds                     ← Configuration, valfritt
```

`HorseController`, `HorseMovement` och de andra körtidsmodulerna ligger **inte**
i modellen. De ligger i ReplicatedStorage och ServerScriptService och slås på av
taggen. En modell med skript i sig blir omöjlig att uppdatera när du har trettio
hästar i världen.

---

## Kollision — den viktigaste regeln

**Låt aldrig det skinnade nätet vara hästens kollision.**

Ett skinnat näts hitbox följer med animationen. När benen rör sig ändras höljet,
och hästen börjar studsa mot marken i takt med gångarten. Det ser ut som en bugg
för att det *är* en bugg.

Så här:

| Del | CanCollide | CanQuery | Massless | Transparency |
|---|---|---|---|---|
| `BodyCollider` | **true** | true | false | 1 |
| `HorseMesh` och allt under `Visual` | **false** | false | **true** | 0 |
| `RiderSeat` | false | true | true | 1 |

`BodyCollider` ska vara ett enkelt block, ungefär bålens mått — cirka
`6 × 4 × 2.5` studs för en varmblodshäst. Gör den inte hästformad. En enkel låda
glider mjukare längs väggar och trappor, och ingen ser den ändå.

`GroundProbe` behövs inte som del. Systemet skjuter en stråle rakt ned från
`BodyCollider` en gång per bildruta, vilket är billigare och mer förutsägbart än
en extra fysisk del.

---

## Humanoid eller AnimationController

Din skiss har båda. Tekniskt använder man **en av dem** — de är två sätt att äga
en `Animator`.

**Använd Humanoid.** Skälet är inte animationer utan mark: Humanoid löser
sluttningar, kanter, trappor och hopp åt dig, robust och gratis. Det finns inget
i Humanoid som gör en häst fordonsaktig — fordonskänslan kommer från styrmodellen,
och den äger vi själva. Systemet sätter `AutoRotate = false`-beteendet genom att
mata Humanoid vår egen riktning i stället för spelarens råa input, så hästen
vrider sig i vår svängtakt och aldrig snärtigt.

Ställ in på Humanoid:

| Egenskap | Värde | Varför |
|---|---|---|
| `HipHeight` | mankhöjd i studs minus `BodyCollider.Size.Y/2` | annars svävar eller sjunker hästen |
| `RequiresNeck` | `false` | hästen har ingen Roblox-hals |
| `BreakJointsOnDeath` | `false` | annars faller modellen isär |
| `MaxSlopeAngle` | `55` | hästar tar brantare backar än avatarer |

`AnimationController` fungerar för animationer men ger dig ingen fysik alls, och
det här systemet levererar inte egen markhantering. Väljer du den vägen får du
skriva markhållningen själv — säg till, så bygger jag den, men gör det inte i tron
att den redan finns.

---

## Attachment-punkter

Fem punkter, alla `Attachment`. Positionerna sätts i Studio genom att titta på
modellen, inte genom att räkna.

| Namn | Var | Används till |
|---|---|---|
| `SaddleAttachment` | mitt i sadeln, där ryttarens höft ska sitta | ryttarens position |
| `LeftReinAttachment` | vid bettet, vänster sida | ryttarens vänsterhand via IK |
| `RightReinAttachment` | vid bettet, höger sida | högerhand |
| `LeftStirrupAttachment` | i stigbygeln, vänster | vänsterfot |
| `RightStirrupAttachment` | höger stigbygel | högerfot |

Sätt tygelpunkterna **på huvudets ben**, inte på `BodyCollider`. Då följer
händerna med när hästen sänker huvudet, vilket är hela poängen med tyglar.

Saknas en punkt hoppas den IK-kedjan över. Ryttaren sitter fortfarande rätt.

### Byter du namn — döp inte om modellen

Har du köpt en modell med egna namn: sätt attribut på `Horse`-modellen i stället.

```
Map_BodyCollider          = "Torso"
Map_SaddleAttachment      = "SeatPoint"
Map_Head                  = "Bone_Head"
```

Adaptern läser `Map_<nyckel>` före standardnamnet. Det är billigare och säkrare
än att döpa om ben i en modell du inte har källfilen till.

---

## Skelettet

För **animationerna** krävs bara att klippen är gjorda mot samma rigg som nätet.
För **de procedurella påbyggnaderna** letar koden efter dessa, alla frivilliga:

| Ben | Används till |
|---|---|
| `Neck01`, `Head` | halsen leder svängen; huvudet vrids något mot riktningen |
| `TailBase` | svansen svänger, snabbare i högre fart |
| `LeftEar`, `RightEar` | öronen rör sig oberoende av varandra |

Bygger du riggen själv i Blender är det här en fungerande uppsättning, och den
motsvarar den du skissade:

```
Root
└── Pelvis
    ├── Spine01 → Spine02 → Chest
    │   ├── Neck01 → Neck02 → Head → Jaw
    │   ├── FrontLeftUpper  → FrontLeftLower  → FrontLeftFetlock  → FrontLeftHoof
    │   └── FrontRightUpper → FrontRightLower → FrontRightFetlock → FrontRightHoof
    ├── TailBase → Tail01 → Tail02 → Tail03
    ├── BackLeftUpper  → BackLeftLower  → BackLeftFetlock  → BackLeftHoof
    └── BackRightUpper → BackRightLower → BackRightFetlock → BackRightHoof
```

Tre saker som spräcker en hästrigg oftare än något annat:

1. **Rotbenet måste ligga i origo och peka framåt längs +Z.** Roblox importerar
   modellen med rotbenets orientering som modellens; ligger det snett lutar hela
   hästen i spelet och ingen justering i Studio rättar det snyggt.
2. **Kotan (fetlock) är en egen led.** Utan den ser skritt och trav stelt ut i
   just det ögonblick blicken dras till — nedslaget.
3. **Skala i Blender innan export, inte i Studio.** En skalad `MeshPart` får sina
   ben skalade separat, och tyglarnas fästpunkter hamnar fel.

---

## Animationer

Klippen laddas via id som sätts som **attribut på `AnimationConfig`**, inte i kod.
Det är därför en ras kan ha egna klipp utan att någonting skrivs om.

Obligatoriska, i den meningen att tillståndet blir stelt utan dem:

| Attribut | Loopar | Gjord för |
|---|---|---|
| `Idle` | ja | stillastående |
| `Walk` | ja | **1,45 m/s** |
| `Trot` | ja | **3,20 m/s** |
| `Canter` | ja | **5,60 m/s** |
| `Gallop` | ja | **8,60 m/s** |
| `JumpAir` | ja | i luften |
| `JumpLand` | nej | nedslag |
| `Stop` | nej | inbromsning |
| `BackUp` | ja | backning |
| `TurnLeft`, `TurnRight` | ja | vändning på stället |

Frivilliga men det är de som gör hästen levande:
`IdleLookAround`, `IdleTailSwish`, `IdleEarFlick`, `IdlePawGround`, `Rear`, `Graze`.

Plus `RiderSeated` — ryttarens pose, spelad på spelarens egen `Animator`.

### Farten i tabellen är inte dekoration

Systemet skalar uppspelningshastigheten med `fart / gångartens norm-tempo`, och
klampar den till **±30 %**. Är ditt trav-klipp gjort för 2 m/s kommer det att
spelas 60 % för snabbt vid 3,2 m/s, slå i klampen och hovarna glider.

Gör klippet för tempot i tabellen, eller ändra `norm` i `Gaits.luau` till det
klippet faktiskt är gjort för. Det ena eller det andra — inte varken eller.

---

## Configuration-blocken

`HorseStats` — sätt `Breed` först, resten fylls från rastabellen och kan skrivas
över per individ:

```
HorseName = "Fjodor"     Breed = "Warmblood"     Level = 3
Speed = 0.58   Acceleration = 0.55   Agility = 0.58
Endurance = 0.62   JumpStrength = 0.72
Temperament = "Calm"     MaxStamina = 100     BondLevel = 0
```

`GaitConfig` — avvikelser från standard. Lämna tom om hästen ska bete sig normalt;
allt som saknas hämtas från `Config.MOVEMENT`. Nyttiga att skruva per modell:
`HipHeight`, `LeanMax`, `JumpPower`, `MountRange`.

`AnimationConfig` — id per nyckel ovan, som sträng.

`Sounds` — `Hoof_Grass`, `Hoof_Dirt`, `Hoof_Stone`, `Hoof_Sand`, `Hoof_Wood`,
`Snort`, `Breath`, `Neigh`.

---

## Kom igång

1. Lägg modellen i `Workspace` och döp den till hästens namn.
2. Sätt taggen `Horse` på den (Studio: Tag Editor).
3. Kontrollera kollisionstabellen ovan. Det här steget hoppas över oftast och
   orsakar flest fel.
4. Kör spelet. Konsolen skriver vad adaptern hittade.
5. Tryck **F8** för felsökningsrutan: gångart, fart, mark, och en rad som listar
   exakt vilka attachments och ben som hittades.

Saknas något obligatoriskt registreras hästen inte, och orsaken skrivs med namn i
konsolen. Systemet halvfungerar aldrig tyst.
