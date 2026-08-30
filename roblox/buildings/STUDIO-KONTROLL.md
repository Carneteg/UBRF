# Studio-kontrollen — komplexet, stallet och gångvägarna

Review 11 gav **CODE GATE PASSED** för ridhusets interiör och pekade ut Roblox
Studio som enda återstående steg före acceptans. Allt som går att mäta utan
Studio är mätt; det som återstår kan bara en människa avgöra: **känns
anläggningen igen som UBRF?**

Två checklistor delar på arbetet:

| Dokument | Täcker |
|---|---|
| `roblox/docs/RIDHUS-STUDIO-CHECKLISTA.md` | **Ridhusets interiör** — panelen, sponsorerna, fönsterbandet, kortändan vid C, båset vid E, takstommen, banan, samt överlapp/z-fighting/ljus |
| **den här filen** | Komplexet utifrån, stallets interiör, gångvägarna och hur du kör paketet |

Börja här, gå sedan till ridhus-checklistan för punkterna inne på banan.

## Så kör du det

```bash
python3 tools/studio-paket.py
```

Skriptet kontrollerar först att Roblox-geometrin är i synk med `src/site.js` och
avbryter annars. Sedan skriver det en enda fil:

```
roblox/buildings/.studio/UBRF-klistra-in.luau
```

Klistra in **hela filen** i Studio — i ett `run_code`-anrop eller i en Script —
och kör den **en gång**. Den river en eventuell tidigare modell och bygger om
från grunden.

Utskriften ska sluta med en rad i den här formen:

```
OK UBRF byggd: 8 byggnader, 12 dörrar, 4 boxrader, 6 gångytor, N objekt
```

De fyra första talen kommer ur datan och ska stämma exakt. **`N` är inte ett
godkännandekriterium** — objektantalet ändras varje gång en detalj byggs eller
slås ihop, och en siffra här hade bara blivit ännu en sanning att hålla i synk.
Blir det ett *fel*, eller stämmer inte de fyra första talen, är något ur synk:
kör om exporten.

Direkt efter bygget listar `Vyer.lista()` sig själv.

## Vyerna

Kamerorna räknas ut ur `UBRFKomplex` — inga nedskrivna koordinater. Flyttas ett
hus eller en läktare i `src/site.js` följer de med.

### Komplexet

| `Vyer.ga(…)` | Vad du ska titta efter |
|---|---|
| `"oversikt"` | Två parallella huvudvolymer, **en** tvärgående förbindelse, mellanrummet delat i **två** gårdsytor |
| `"ankomsten"` | Ridhuset till höger, stallet till vänster. Husen ska läsa som **ett komplex**, inte som två fristående lador |
| `"gardarna"` | Gården ska **stängas** av hästgången. Ser du rakt igenom till nästa gårdsyta är förbindelsen fel byggd |

### Ridhuset inne — kvittera mot `RIDHUS-STUDIO-CHECKLISTA.md`

| `Vyer.ga(…)` | Punkt i ridhus-checklistan |
|---|---|
| `"banan"` | 7 — sand, sarg, porten vid A |
| `"sponsorvaggen"` | 1, 2 och 3 — panelen, sponsorerna, fönsterbandet |
| `"kortandan"` | 4 — blocket, trapporna, glasbandet, klockan, kompassrosen |
| `"domarbaset"` | 5 — båset vid E |
| `"takstommen"` | 6 — balkar, stål, kabelstegar, ventilation |
| `"laktaren"` | gapet i läktaren och grinden i sargen |

### Stallet inne

| `Vyer.ga(…)` | Vad du ska titta efter |
|---|---|
| `"servicedelen"` | Båda serviceboxarna **öppna** mot gången, ljusare servicegolv, dager från gavelöppningen med exit-skylten ovanför |
| `"stallgangen"` | Boxar på båda sidor, boxfronterna **antracit med galvad ram och fem liggande reglar**, tvärkorridoren synlig hela vägen tvärs huset |

## Gå igenom hästgången

Utöver vyerna: gå sträckan **stall → hästgång → ridhus → banan**, och tillbaka.

Det är mätt i webbversionen (vägsökning hittar fram åt båda håll), men i Studio
ska det också gå att **gå** där — inget osynligt hinder, ingen del som sticker in
i passagen.

## Det visuella är också ditt att bedöma

Gate F01:s källhierarki säger att **foton och film är facit för visuella och
interiöra detaljer** — material, färger, konstruktion, öppningar, skyltar.
Struktur och utseende hör alltså båda till den här kontrollen.

### Byggt i Roblox — bedöm i Studio

| Var | Vad |
|---|---|
| Ridhuset ute | Vinröd korrugerad fasad, svart list, takfärg, café-/annexgaveln, de kända öppningarna |
| Stallet ute | Mörkröd liggande panel, blågrått tak, **valvfönstrens rytm**, den ockragula entrédörren, portarna, **takhuvarna** på nocken, **snörasskyddet** på båda takfallen, **förstukvisten**, **balkongen** och **spiraltrappan** på klubbgaveln |
| Stallet inne | Dubbelstallet — fyra boxrader, två gångar, tvärkorridoren tvärs huset — boxfronternas identitet, gångytornas läsbarhet, de namngivna rummen, servicedelen |
| Komplexet | Hästgången och de två gårdsytorna |

Ridhusets interiör står i sin egen checklista och räknas inte upp igen här.

Identitetsdragens mått är avlästa ur foton eller valda så att formen blir rätt —
det **verifierade är att dragen finns**, inte deras exakta centimetrar. Ser något
av dem uppenbart fel ut i proportion räcker ett besked, så rättas det på ett
ställe och följer med till båda ytorna.

### Vad som fortfarande INTE är ett fynd

Osourcad möblering, kosmetisk polish och avancerad ljussättning. Att
stallgången saknar spånremsa, att det inte finns namnskyltar på boxarna eller
att ljuset är platt — inget av det är vad gaten mäter.

## Om något ser fel ut

Skriv vad du ser och var. Då öppnas **en riktad fix**, inte ett nytt
geometripass.

Fyra saker kommer att se ut som att *någon* har valt dem, för det har någon:

| Drag | Läge nu | Klass |
|---|---|---|
| Hästgångens bredd | 8,10 m | härledd ur det **mätta** lokala gårdsgapet i södra tvärsnittet |
| Hästgångens djup och höjder | 3,5 m djup, takfot 3,2, nock 4,0 | `[antagande]` |
| Läktargapet | 8,70 m | `[antagande]` — gapet finns i fotot, bredden är vald |
| Sargens grind | 3,80 m | `[antagande]` |

Satellitbilden verifierar att gången finns och var den ligger, inte hur djup den
är. Ser något av dem uppenbart fel ut på plats räcker ett besked, så rättas det
på ett ställe.

**Gavlarna ligger inte i liv.** Stallets norra gavel skjuter fram förbi
ridhusets. Riktningen är avgjord mot `stall-gavel-06-silon.jpg`; **storleken på
förskjutningen är `REFERENCE GAP`** och står just nu på ett arbetsvärde. En
tidigare version av den här filen bad dig kvittera "gavlarna i liv" — det var ett
påstående modellen inte längre gör, och inte heller ett underlaget bär.

## Om allt är grönt

Då kan Gate F01 stängas som **FIDELITY READY WITH DOCUMENTED GAPS** — aldrig som
`100 % IDENTICAL`, så länge de dokumenterade luckorna finns kvar. De står i
`audits/GATE-F01-UBRF-FIDELITY-RESULT.md` § 12 och § 13, och de största är
**orienteringen** och **motsägelsen sarg kontra läktarfront**.
