# Gate F01 — UBRF Fidelity: resultat

Struktur enligt `docs/GATE-F01-UBRF-FIDELITY.md`.

Datum: 2026-08-30
Implementation: Claude Code
Status: **lämnas till ChatGPT för Senior Fidelity Review 01.**

Gaten stängs inte av mig, och UBRF kallas inte "100 % identiskt": båda byggnaderna
har kvarvarande `ASSUMPTION` och `REFERENCE GAP` som är listade nedan. Väntat
utfall om alla kända motsägelser är lösta men luckor kvarstår är
`FIDELITY READY WITH DOCUMENTED GAPS`, inte `IDENTICAL`.

---

## 1 · Commits

| Commit | Vad | Zon |
|---|---|---|
| `e23b5fb` | Stallet blir ett dubbelstall: 21 m bredd, fyra boxlängor, två gångar, tvärkorridor | Stall inne + ute |
| `424018c` | Ridhusets fem interiörmotsägelser, och bokstäverna flyttade så att A står vid sargporten | Ridhus inne |

Föregående gate (`aec77cd`, mergad) rörde ridkänslan, inte miljön.

---

## 2 · Källinventering — vad som faktiskt användes

| Källa | I repot? | Använd till |
|---|---|---|
| `references/buildings/stall/*.jpg` — 5 fasad, 14 entré, 22 stallgång | ✅ | Stallets bredd, takgeometri, fönsterrytm, huvrad, förstukvist, gångens tak/golv/boxfronter |
| `references/buildings/ridhus/ridhus-gavel-0{1,2,3}.jpg` | ✅ | Ridhusets gavel, tak, café, färg |
| `references/video/IMG_024{6..9}.mov`, `IMG_0250.mov` | ✅ | Källfilmerna stillbilderna är tagna ur |
| Utrymningsplan, stallet (Presto AB 2025-10-11) | Refererad i `KORT.md`, bilden ej i repot | Planformen: fyra boxlängor, två gångar, klubbdel, servicedel, utrymningsvägar |
| Utrymningsplan, ridhuset (Presto AB 2025-10-11) | Refererad i `KORT.md`, bilden ej i repot | 25 × 75 m, läktaren längs ena långsidan, djup gaveldel |
| `references/DRIVE-SOURCE-INDEX.md` (ChatGPT-verifierat 2026-08-29) | ✅ | Ridhusets fem interiörmotsägelser |
| `IMG_0179`, `IMG_0183`, `IMG_0198`, `IMG_0191.MOV` — Drive-original | ❌ **Ej i repot** | Bara via indexet ovan. Jag har inte sett dem |
| Satellit- och Street View-avläsningar | ❌ Ej sparade | Citerade tal i `SITEPLAN.md`; kan inte kontrolleras om |

**Det viktigaste i tabellen är sista raden med ❌.** Ridhusets fem motsägelser är
byggda från en verifierad textbeskrivning av bilder jag inte har. Det är ett led
längre från verkligheten än stallet, där jag har fotona.

---

## 3 · Fidelity Matrix

`V` = VERIFIED · `D` = DERIVED · `A` = ASSUMPTION · `G` = REFERENCE GAP · `C` = CONTRADICTION

### Stall — exteriör

| Komponent | Status | Källa |
|---|---|---|
| Liggande träpanel, mörk falurött (80,35,47) | **V** | Median av tre fasadbilder |
| Blågrått bandtäckt plåttak (103,112,121) | **V** | Median av bild 03 och 05 |
| Huvrad på nocken, en per box, börjar efter förstukvisten | **V** | Bild 03, 04 |
| Valvfönsterrytm, ett per box, 3,5 m | **V** | Bild 03, 04 |
| Förstukvist: vitt ribbräcke, ockragul dörr, två runda fönster | **V** | Bild 01, 03, 06 |
| Snörasskydd, hängränna, vit fascia och undertak | **V** | Bild 03, 04 |
| Spiraltrappa och balkong på norra gaveln | **V** | Bild 04, 05 |
| Takfot 4,4 m | **D** | Entrédörrens 2,05 m i bild 04 |
| Nock 10,0 m | **D** | Takfot + 28° över 21 m; direkt mätning ger 9,8 m |
| **Bredd 21 m** | **D** | Tre oberoende vägar, se § 6 |
| Längd 54 m | **D** | Satellit 236 px vid 4,4 px/m; stämmer med boxantalet |
| Taklutning 28° | **A** | Flackaste rimliga avläsning; gaveln står vriden i båda bilderna |
| Södra gavelns dörrar och trappa | **A** | Street View på avstånd |
| Östra långsidan | **A** | Speglad från västra; Street View på avstånd |
| Takytan uppifrån | **G** | Inget foto |

### Stall — interiör

| Komponent | Status | Källa |
|---|---|---|
| **Planform: boxrad–gång–boxrad–boxrad–gång–boxrad** | **V** | Utrymningsplanen |
| Klubbdel i ena änden, servicedel i den andra | **V** | Utrymningsplanen + fasadfoton |
| Utrymningsvägar på båda långsidorna och en korridor mitt på | **V** | Utrymningsplanen |
| Sadeltak med galvad korrugerad undersida | **V** | 22 bildrutor ur gången |
| Tegelröda tvärbalkar, snedstag, nockbalk | **V** | Samma |
| Galvade dragstag ner till boxarnas överkant | **V** | Samma |
| Takfönster i rad, runda pendelarmaturer | **V** | Samma |
| Markstensgång med ljus spånremsa längs fronterna | **V** | Samma |
| Boxfronter: mörkgrå komposit nedtill, galvad ram och galler upptill | **V** | Samma |
| Grå port med rund klocka i fonden | **V** | Samma — `[ej byggt]` |
| Fördelning box/gång, 3,5 / 3,5 m | **A** | Residual ur bredden; filmen antyder bredare gång |
| Nio boxar per länga (36 totalt) | **A** | Planen antyder "ett tiotal per länga" |
| Vilken gång filmerna visar | **A** | Spelet lägger den som den västra |
| Sakerna på boxfronterna (sadlar, täcken, grimmor) | **G** | Syns i film, `[ej byggt]` |
| Exakta boxmått och rumsindelning i klubb-/servicedelen | **G** | Planbilden för sned |

### Ridhus — exteriör

| Komponent | Status | Källa |
|---|---|---|
| Vinröd vertikalt korrugerad plåt (97,45,57) | **V** | Median av tre gavelbilder |
| Svart list, vindskivor, takfot, beslag | **V** | Bild 01–03 |
| Vitt skärmtak över svarta dörren | **V** | Bild 01 |
| Caféannex: fyra valvfönster, balkong, ståltrappa | **V** | Bild 03 |
| Runt ventilationsgaller på gaveln | **V** | Bild 01 |
| Fotavtryck 25 × 75 m | **D** | Utrymningsplanen med banans 20×60 som skala |
| Takfot 6,2 m | **A** | Ingen bild visar var taket möter långsidan |
| Taklutning 13° | **A** | Mätspann 11–17° ur bild 03 |
| Takyta och täckning | **G** | Inget foto |
| Långsidorna på nära håll, östra gaveln | **G** | Bara Street View på avstånd |
| Om svarta listen går runt hela huset | **G** | Street Views upplösning räcker inte |

### Ridhus — interiör

| Komponent | Status | Källa |
|---|---|---|
| Vit sarg med svart sockel | **V** | Interiörfoton + indexet |
| Brun ridbaneyta | **V** | Samma |
| Sponsorplåtar på långsidan ovanför sargen | **V** | Samma |
| Höga smala translucenta fönsterband nära taknivå | **V** | Indexet (`IMG_0183`) |
| Läktare i trästomme med nivåer | **V** | Interiörfoton |
| **Mörkröd/maroon övre långsida med horisontella detaljer** | **V** | Indexet (`IMG_0183`) |
| **Stål-/metallprofiler, kabelstegar, ventilation i taket** | **V** | Indexet (`IMG_0179`, `IMG_0183`) |
| **Klocka vid central passage/trappa** | **V** | Indexet (`IMG_0179`) |
| **Trappa med träräcken upp till mörkt träbås med exit-skylt vid E** | **V** | Indexet (`IMG_0198`) |
| **Glasade rum/fönsterpartier bakom sargen** | **V** | Indexet (`IMG_0179`) |
| A vid sargporten ⇒ K-V-E-S-H mot läktaren | **D** | Dressyrkonvention + portens läge + `IMG_0198` |
| Antal och mått på glasade rum, takinstallationer, klockan, båset | **A** | Indexet säger att de finns, inte hur stora |
| Entréhallens möbler och rumsindelning | **A** | Planen visar rum, inte möbler |
| Bildgåtorna vid åtta av tolv bokstäver | **A** | Fyra läsbara i foto, åtta konstruerade |
| Allt som bara finns i Drive-originalen | **G** | Jag har inte sett bilderna |

---

## 4 · Före → efter: motsägelserna

| # | Zon | Motsägelsen | Före | Efter |
|---|---|---|---|---|
| 1 | Stall inne | Utrymningsplanen visar dubbelstall | En gång, två boxrader, 15 m bredd | Fyra längor, två gångar, tvärkorridor, 21 m |
| 2 | Ridhus inne | Långsidans övre yta är mörkröd | Brun panel, och bara i den enkla vandringsvyn | `#5E2C33` med vita läkt, byggd i 3D-interiören |
| 3 | Ridhus inne | Taket har stål, kabelstegar, ventilation | Bara limträbalkar och lysrör | Fyra stålprofiler, två kabelstegar, två ventilationskanaler |
| 4 | Ridhus inne | Klocka vid centrala trappan | Saknades | `klocka:{x:22, y:63.6, z:3.6}` |
| 5 | Ridhus inne | Bås vid E: mörkt trä, trappa med räcken, exit-skylt | Vitt bås på annan plats, ingen trappa, ingen skylt | Byggt vid E, på låg träläktarnivå, med räcken och grön skylt |
| 6 | Ridhus inne | Glasade rum bakom sargen | Bara läktarsteg | Tre partier med ram och mittpost |

**Fynd 7 — inte i briefen, hittat på vägen.** Bokstäverna låg på fel långsida, och
det fanns två sanningar om det: `v3dRidhus` vred hela ringen 180° i renderaren
medan tabellen i `src/data.js` inte var vriden och kartan i `src/render.js` läste
tabellen rått. **2D-kartan visade A i söder samtidigt som 3D-vyn visade A i norr.**
Vridningen ligger nu i tabellen; båda renderarna läser den som den är.

---

## 5 · Ridhus exteriör

Inte ändrat i den här gaten. Regressionstestat: fotavtryck 25 × 75, nock nord–syd,
vinröd korrugerad plåt, svarta listen vid 4,10 m, caféannexets fyra valvfönster på
norra gaveln, entrékvisten och den svarta dörren på västra långsidan. Sex
kontroller, alla gröna.

Kvarvarande `A`/`G` enligt matrisen ovan är oförändrade och fortfarande markerade.

---

## 6 · Stall exteriör — bredden

Kortet antog 15 m därför att `STALLINNE` hade en gång och två rader, och
`STALLINNE` byggdes ur de 15 metrarna. Cirkeln bröts av tre oberoende vägar:

**1 · Planformen.** Sex band tvärs huset. Vid 15 m blir varje band 2,50 m. En häst
kan inte stå i en box på 2,5 m djup, och två hästar kan inte mötas i en 2,5 m gång.
15 m är inte bara osäkert utan fysiskt omöjligt givet planformen.

**2 · Rytmen.** Huvarna på nocken sitter ~3,5 m isär, en per box, och valvfönstren
har samma delning — båda avlästa i bild 03 och 04. Sex band à 3,5 m = **21,0 m**.

**3 · Takgeometrin.** Takfot 4,4 m och nock 9,8 m, båda mätta mot entrédörrens
2,05 m i bild 04. Resningen 5,4 m ger:

| Lutning | Bredd |
|---|---|
| 26° | 22,1 m |
| 28° | **20,3 m** |
| 30° | 18,7 m |
| 36° | 14,9 m |

Gavelns takfall mäter 31° och 48°, båda för branta eftersom gaveln står vriden;
28° var den flackaste rimliga tolkningen. För 15 m krävs 35,8°.

**Nockmätningen 9,8 m avfärdades tidigare som "för hög". Den var inte för hög —
bredden var för smal.** Med 21 m blir nocken 10,0 m.

Västra långsidan — den fotograferade — står kvar vid x = 154; huset växer österut
till x = 175. Gången öster om stallet smalnar 7 → 3 m och hagarna flyttas 2 m ut.
Norra gavlarna ligger fortfarande i liv med ridhusets, som i satellitbilden, och
gräsgården mellan husen är 11 m.

Tolv exteriörkontroller på stallet, alla gröna.

---

## 7 · Stall interiör

`STALLINNE` är omskriven från "gång i mitten, rad på var sida" till fyra längor med
var sin gång att vetta mot, plus en tvärkorridor mitt på som når båda långsidorna
— planen har utrymningsvägar där.

Kollisionen frågar nu en lista över gångytor i stället för att klämma spelaren in i
ett intervall; det gick inte att uttrycka med två gångar. Samma lista styr var
dörrar får sättas, så vägsökningen och gåendet läser fortfarande samma geometri —
två beskrivningar av samma hus blir förr eller senare oense.

Spelets sjutton hästar står i gång A, den man kommer in i från förstukvisten. Gång
B:s boxar ritas men får ingen häst: spelet har sjutton namn, och fler får inte
hittas på.

---

## 8 · Ridhus interiör

De fem motsägelserna i § 4. Bara det indexet uttryckligen beskriver är byggt.
Indexet säger själv "bygg inte osedda detaljer från denna text", så antal, mått och
placeringar som det inte anger är `ASSUMPTION` i byggnadskortet.

---

## 9 · Roblox / webb-paritet

**Roblox har ingen UBRF-geometri byggd.** `roblox/buildings/` innehåller
`BuildKit.luau`, `_exempel.luau` och en README — inga byggnadsskript. En sökning
efter `ridhus`/`stall` i `roblox/src` och `roblox/buildings` ger bara README:n och
exemplet.

Pariteten för den här gaten är därför att **fidelity-fakta ligger i de delade
källdokumenten**, inte i två implementationer:

| Fakta | Var det står | Läses av |
|---|---|---|
| Stallets planform och 21 m bredd | `references/buildings/stall/KORT.md` | Webben nu; Roblox när byggnaden byggs (issue #16) |
| Ridhusets fem interiördrag | `references/buildings/ridhus/KORT.md` | Samma |
| Placering, orientering, gavlar i liv | `references/SITEPLAN.md` | Samma |
| Namn på rum och områden | Byggnadskorten | Samma |

Det finns alltså **ingen risk att en rättad webb-UBRF står mot en gammal
motsägelsefull Roblox-UBRF**, eftersom Roblox-UBRF inte finns än. När den byggs ska
den läsa korten, inte spelets JS.

`[REFERENCE GAP i paritetsredovisningen]` Pariteten kan inte visas med två
skärmdumpar förrän Roblox-byggnaderna finns.

---

## 10 · Visuella jämförelser

| Vy | Mot vilken referens | Vad som stämmer |
|---|---|---|
| Stallet från grusplanen, snett framifrån | `stall-fasad-04.jpg` | Gaveln med spiraltrappa och balkong, förstukvisten med vitt ribbräcke och ockragul dörr, valvfönsterrytmen, huvraden som börjar efter förstukvisten, snörasskyddet, blågrått tak. Gaveln läser nu bredare och flackare, närmare fotot än den smala 15 m-gaveln |
| Gång A inifrån | `stall-gang-*.jpg` | Boxar på båda sidor, hästhuvuden över dörrarna, namnskyltar, galvade stolpar, spånremsa längs fronterna, marksten i mitten, tegelröda tvärbalkar, takfönster, pendelarmaturer |
| Tvärkorridoren, från västra långsidan | — | Man ser genom huset mellan boxlängorna; fyra rader läsbara |
| Vid E, mot båset | `IMG_0198` via indexet | Bokstaven E på sargen, mörkt träbås direkt bakom, grön exit-skylt över öppningen, låg upphöjd träläktarnivå, trappa med räcken |
| Från banan mot läktaren | `IMG_0179` via indexet | Läktarens nivåer och räcke, båset med skylten, mörkröd övre vägg, stålprofiler och ventilationskanaler i taket |
| Mot sponsorväggen | `IMG_0183` via indexet | Mörkröd övre yta med vita läkt, sponsorplåtar, speglarna, takets installationer |

---

## 11 · Regressionstester

| Svit | Kontroller | Resultat |
|---|---|---|
| Stallets planform | 9 | alla gröna |
| Ridhusets interiör och bokstäver | 10 | alla gröna |
| Exteriörerna (ridhus 6, stall 12) | 18 | alla gröna |
| Ridloopen (Gate 01) | 5 | alla gröna |
| Ryttarens sekundärrörelse | 7 | alla gröna |
| Fyra viewports, rörelse och touchmål | 4 | alla gröna |

Inga konsolfel i någon svit. Framkomlighet mätt: tvärs stallet 1,0 → 20,2 m av 21
genom tvärkorridoren, och längs gång A till y = 42,6, alltså hela boxlängan.

Inga nya gameplay-features. Ridkänslan är orörd.

---

## 12 · Kvarvarande ASSUMPTION

1. **Stallets fördelning mellan box och gång**, 3,5 / 3,5 m. Totalen 21 m stöds av
   takgeometrin oberoende av hur den delas; fördelningen är residualen. Filmerna
   antyder en bredare gång, vilket i så fall gör boxarna grundare.
2. **Nio boxar per länga**, 36 totalt.
3. **Vilken av de två gångarna filmerna visar.**
4. **Stallets taklutning 28°** och därmed nockhöjden.
5. **Södra gaveln och östra långsidan** på stallet.
6. **Ridhusets takfot 6,2 m och lutning 13°.**
7. **Antal och mått** på ridhusets glasade rum, takinstallationer, klocka och bås.
8. **Entréhallens möbler** i ridhuset.
9. **Åtta av tolv bildgåtor** vid dressyrbokstäverna.

## 13 · Kvarvarande REFERENCE GAP

1. **En rak bild på stallets "Plan 1"** — utan vinkel, utan reflex, helst med
   skalstock. Stänger punkt 1, 2 och 3 ovan på en gång.
2. **Samma på "Plan 2"** för övervåningen.
3. **En sparad satellitbeskärning** med byggnadernas längd OCH bredd i bildpunkter.
   Kortets invändning att 20–26 m är "oförenligt med hur smal byggnaden ser ut i
   satellitbilden" är inte kvantifierad, och bilden finns inte i repot.
4. **Ridhusets interiörbilder i repot.** `IMG_0179`, `IMG_0183`, `IMG_0198` och
   `IMG_0191.MOV` finns bara i Drive. Fem av sex motsägelser är byggda från en
   textbeskrivning av bilder jag inte har sett.
5. **Stallets takyta uppifrån** och en rak bild på långsidan.
6. **Ridhusets långsidor på nära håll, östra gaveln och takytan.**
7. **Ridhusets gavel rakt framifrån** — lutningsspannet 11–17° är för brett.

---

## 14 · Kända begränsningar

1. **Jag har inte sett Drive-bilderna.** Ridhusets interiör är byggd ur ChatGPTs
   verifierade index. Det är ett led längre från verkligheten än stallet, och en
   review bör granska just de raderna hårdast.
2. **Utrymningsplanerna finns inte i repot.** Både stallets och ridhusets mått
   vilar på avläsningar som inte går att kontrollera om.
3. **Roblox-pariteten är inte visad**, bara förberedd — se § 9.
4. **Interiörernas möblering är inte komplett.** Sakerna på boxfronterna och porten
   med klockan i stallgångens fond är kända men obyggda.
5. **Ingen mänsklig igenkänningskontroll.** Att någon som varit på UBRF känner igen
   sig kan bara Tobias avgöra.

---

## 15 · Överlämning

Enligt `docs/GATE-F01-UBRF-FIDELITY.md` stänger jag inte gaten och kallar inte
UBRF identiskt. Arbetet lämnas till ChatGPT för Senior Fidelity Review av faktisk
diff och källkedja, och till Tobias för avgörandet om igenkänningen räcker och om
nya foton behövs för att stänga luckorna ovan.

De två P0-punkterna i gatens acceptance — ridhusets fem interiörmotsägelser och
stallets felaktiga en-gångsplan — är åtgärdade. Punkt 3–8 (exteriörernas
regressionstest, den gemensamma matrisen, paritetsredovisningen, byggets
funktion och att inga nya features smugit in) är redovisade ovan.
