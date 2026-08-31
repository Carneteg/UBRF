# F02 — Ruminventering: vad källorna visar mot vad som är byggt

Datum: 2026-08-31 · Steg 0 i `docs/GATE-F02-INTERIOR-FIDELITY.md`.
**Ingenting byggs ur det här dokumentet förrän Tobias sett listan.**

Källor, i gällande ordning: `references/plans/` (topologi) → foton →
`KORT.md`/`INTERIOR-MATRIS.md` → befintlig implementation. Mätningarna nedan
är de redan dokumenterade i `PLAN1-OMMATNING-2026-08-30.md` och
`RIDHUS-PLANMATNING-2026-08-30.md` — inga nya avläsningar har lagts till här.

## Vad de fotograferade planerna kan och inte kan

Båda utrymningsplanerna är **fotografier av anslagna planer**. De löser
**struktur**: väggar, rumsindelning, trappor, utrymningsvägar, korridorer.
De löser **inte rumsetiketter**: ingen text i planerna är läsbar. En rättelse
till en tidigare formulering — det stod att ingen rumsetikett alls är läsbar i
något foto, och det är fel. `stall-entre-13.jpg` visar en dörrskylt med texten
`Stall`. Den namnger dock rummet **bakom** dörren, alltså en passage, och ger
inget av de 27 planrummen ett namn. Se `docs/F02-BEVISINDEX.md`.
Ett rums *existens* kan alltså vara `PLAN` medan dess *funktion* är
`FOTO`, `DERIVED` eller `REFERENCE GAP`. Den skillnaden bärs genom hela
inventeringen.

---

## STALLET — plan 1

### Boxhallen — `PLAN`, dubbelt avläst · byggd ✔

Sex band tvärs huset: **boxrad · gång A · boxrad · boxrad · gång B · boxrad**,
med de två mittraderna rygg mot rygg och dörrsvängar ut i egen gång. Läst i två
oberoende bilder av samma plan; gångarna ≈ ⅔ av boxdjupet. Bygget följer det
(`STALLINNE.rader/gangar` ur `STALL_BAND`). **Ingen åtgärd.**

### Klubbänden, norr — struktur `PLAN`, funktioner blandade · delvis byggd

Planen visar vid norra gaveln: entrézon, **rak trappa** (skrafferad),
brandlarmscentral, och **flera små rum** vars gränser syns men vars funktioner
inte går att läsa. "Här är du"-punkten sitter vid västra entrén — förstukvisten.

Byggt i dag: `uppehallsrum`, `teorisal` (TEORISAL · WC), `sadelkammare`.

| Post | Klass | Kommentar |
|---|---|---|
| att klubbdelen är rumsindelad | `PLAN` | väggtäthet vid norra änden |
| den raka trappan i klubbdelen | `PLAN` + `FILM` | syns **underifrån** i `stall-entre-07…09` / `IMG_0248.mov`. **Inte byggd** — bara spiraltrappan utanpå finns |
| de tre byggda rummens gränser | `DERIVED` | satta före F02; ska kvitteras mot planens rumsgränser i granskningsläget |
| rummens funktioner (teorisal, WC, sadelkammare) | `INTERIOR-MATRIS`/foto där täckt, annars `ASSUMPTION` | etiketter går inte att läsa i planen |
| ytterligare rum planen antyder utöver de tre | `REFERENCE GAP` | räknas först i granskningsläget mot planbilden, inte ur minnet |

### Plan 2 — övervåningen: `PLAN`, **inte byggd alls**

Planfotot visar en **Plan 2**: korridor, flera rum, rak trappa och
spiraltrappan vid gaveln. I spelet finns bara utsidans balkong, balkongdörr
och spiraltrappa. Hela övervåningens interiör är **obyggd** — största enskilda
gapet i stallet. Funktioner: `REFERENCE GAP` rakt igenom.

### Tvärkorridorer — delvis öppen fråga

Byggt: **en** tvärkorridor, den som hästgången mynnar i (mitt på huset,
`PLAN`-stödd av den utskjutande gröna utrymningsvägen västerut mitt på
planen). Planen ser dessutom ut att visa tvärpassager **nedanför klubbdelen**
och **vid servicedelen** — men det är min läsning av ett foto, inte en
mätning. `REFERENCE GAP` tills de mätts i planbilden på samma sätt som
banden mättes.

### Servicedelen, syd — struktur `PLAN`, innehåll delvis foto

Planen visar flera små rum vid södra änden plus en utbyggnad österut och en
gavelutgång (cirkelsymbolen utanför gaveln stämmer med silon i
`stall-gavel-06-silon.jpg`).

Byggt: `spolspilta` och `spanforrad`, båda öppna mot gången — fotostödda
(`stall-gang-*`, `INTERIOR-MATRIS`). Rummen därutöver: gränser `PLAN`,
funktioner `REFERENCE GAP`.

---

## RIDHUSET — entréplan

### Banan och det redan F01-accepterade — byggt ✔

20 × 60-banan (`VERIFIED`, Tobias), sarg, läktare längs ena långsidan
(planens band 0–14,5 % av bredden, mätt), kortändan med trappstegsblock,
glasband, klocka och kompassros, domarbåset vid E, sponsorväggen, takstommen.
Inget av detta öppnas om i F02 utan konkret fel.

### Entrédelen — **planens tydligaste obyggda zon**

`RIDHUS-PLANMATNING` mäter entrédelens djup till **15,1 % av längden**
(≈ 11,7 m av 77,18; bygget reserverar 13 m — `DERIVED`, i samma härad).
Planen visar zonen **full av rum**: det är så mätningen alls kunde göras,
väggtätheten skiljer zonen från banan. Minst två trappor syns (skrafferade).

Byggt i dag: **ingenting**. Zonen är reserverad men tom — man kliver i
praktiken från entrén till banan. Det är precis det direktivet förbjuder som
slutläge, och ridhusets största gap.

| Post | Klass |
|---|---|
| att entrédelen är rumsindelad, med korridor och trappor | `PLAN` |
| enskilda rums gränser | `PLAN` — avläsbara i granskningsläget mot bilden |
| rummens funktioner (kontor? omklädning? WC?) | `REFERENCE GAP` — ingen etikett läsbar |
| Café Krubban som tvåvåningsannex med egen övervåning | `FOTO`/`KORT` (gaveln, valvfönstren, trappan, skylten) |
| caféets interiör | `REFERENCE GAP` |

### Rättelse mot tidigare rapportering

En tidigare PR-kommentar (2026-08-31) räknade "tre namngivna rum" till
ridhuset. **Fel:** `uppehallsrum`, `teorisal` och `sadelkammare` ligger i
**stallets** klubbände (`STALLINNE.rum`). Ridhusets entrédel har **noll**
byggda rum. Gapet är alltså större än rapporterat, inte mindre.

---

---

## Digitaliseringen — `roblox/buildings/Planrum.luau`

Efter första granskningsomgången: de grova zonerna räckte inte. En hel våning
som en enda röd platta går bara att underkänna i klump. Varje rums-, korridor-
och trappgräns som går att läsa ur planen är därför nu ett eget rum med eget
`RoomId`.

| Plan | Rum totalt | Ritade | Endast poster |
|---|---|---|---|
| Ridhusets entréplan | 12 | 6 | 6 |
| Stallets plan 1 (klubbdelen) | 7 | 7 | 0 |
| Stallets plan 2 | 8 | 7 | 1 |
| **Summa** | **27** | **20** | **7** |

**Toleranser, öppet redovisade.** Stallets plan är fotad rakt framifrån och
läses med ~±0,5 m. Ridhusets är ett perspektivfoto: tvärled håller ±0,5 m, men
**djupled trycks ihop mot bildens överkant**. Rummen i ridhusets mittblock har
därför läge men inte mått — de står som poster **utan rektangel**, för en fel
rektangel är värre än ingen. Det som låser upp dem är en rektifierad bild av
ridhusplanen, motsvarande stallets `-rak`, eller mått på plats.

**Inga påhittade funktioner.** Ingen rumsetikett namnger något av planrummen —
den enda läsbara skylten, `Stall` på branddörren i `stall-entre-13.jpg`, pekar
ut en passage, inte ett rum — så alla id:n är neutrala — `rum`, `korridor`, `trapphus`, `schakt`. Aldrig
`wc` eller `kontor` förrän en källa säger det. Provet faller om någon smyger
in ett semantiskt namn.

**Ett fynd på vägen:** planen visar utrymningspilar genom **båda** långsidorna
vid klubbgränsen — en tvärpassage som inte fanns i modellen alls. Den ligger
nu som `s_tvarpassage_klubb`.

## Vad Fas 1-granskningsmodellen ska visa

Ur inventeringen följer granskningslägets innehåll — **skal och gränser, inga
möbler**:

1. **Dollhouse per hus:** tak av, väggar valbart genomskinliga, top-down —
   plus ögonhöjd.
2. **Zonerna ovan som markerade ytor** med `RoomId` och källklass synlig i
   vyn: byggda rum i en färg, `PLAN`-belagda men obyggda rum i en annan,
   `REFERENCE GAP` i en tredje. Ett tomt rum som ÄR tomt i källorna ska se
   avsiktligt tomt ut, inte glömt.
3. **F02-QA-panel** per rum/zon: namn/id, källklass, referensfiler,
   föregående/nästa, PASS/FEL, kameraåterställning, sammanfattning — byggd på
   F01-panelens fail-closed-navigering.
4. **Det Tobias avgör i Fas 1:** rumsgränser, cirkulation, dörrlägen,
   trapplägen, WC-lägen, öppningar. Ingenting möbleras före det beskedet.

## Efter råfilmspasset

`docs/F02-BEVISINDEX.md` prövar varje zon mot alla fem filmerna. Tre gap står
kvar **efter uttömt bevis** — ingen av filmerna går in i dem alls:

- stallets plan 2 invändigt,
- ridhusets entréblock invändigt (samma sex rum som saknar mått),
- Café Krubban invändigt.

De är alltså gap om anläggningen, inte om urvalet.

## Öppna frågor som INTE får lösas av mig

- rumsetiketterna i båda planernas rumszoner — kräver foto på plats eller besked
- tvärpassagerna utöver hästgångens — kräver mätning i planbilden
- stallets totalbredd (OAVGJORT fråga 2, 15–23 m) — kräver mått på plats
- allt innehåll i stallets Plan 2 och i Café Krubban
