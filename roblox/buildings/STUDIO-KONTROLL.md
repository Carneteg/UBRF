# Studio-kontrollen — det enda som återstår för Gate F01

Senior Fidelity Review 03 gav **PASS FOR IMPLEMENTATION REVIEW** med nästa steg
`PRODUCT OWNER STUDIO VISUAL ACCEPTANCE`. Allt som går att mäta utan Studio är
mätt; det som återstår kan bara en människa avgöra: **känns komplexet igen som
UBRF?**

Reviewen var uttrycklig: *"Do not start another speculative geometry pass before
that visual acceptance."* Så inget mer byggs innan den här kontrollen är gjord.

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

Utskriften ska sluta så här:

```
OK UBRF byggd: 8 byggnader, 11 dörrar, 4 boxrader, 6 gångytor, 404 objekt
```

Blir det färre objekt, eller ett fel, är något ur synk — kör om exporten.

## De fem vyerna

Skriptet listar dem själv när det körts. Ställ kameran med `Vyer.ga(id)` och ta
en skärmdump från var och en.

| # | `Vyer.ga(…)` | Vad du ska titta efter |
|---|---|---|
| 1 | `"oversikt"` | Två parallella huvudvolymer, **en** tvärgående förbindelse, mellanrummet delat i **två** gårdsytor. Jämför med satellitbilden |
| 2 | `"ankomsten"` | Ridhuset till höger, stallet till vänster. Husen ska läsa som **ett komplex**, inte som två fristående lador |
| 3 | `"gardarna"` | Gården ska **stängas** av hästgången. Ser du rakt igenom till nästa gårdsyta är förbindelsen fel byggd |
| 4 | `"stallgangen"` | Boxar på båda sidor, och tvärkorridoren ska synas **hela vägen tvärs huset** |
| 5 | `"ridhuset"` | Läktaren ska ha ett **gap** rakt fram, och sargen en **grind** i gapet |

## Gå igenom hästgången

Utöver vyerna: gå sträckan **stall → hästgång → ridhus → banan**, och tillbaka.

Det är mätt i webbversionen (vägsökning hittar fram åt båda håll, två steg), men
i Studio ska det också gå att **gå** där — inget osynligt hinder, ingen del som
sticker in i passagen.

## Det visuella är också ditt att bedöma

Gate F01:s källhierarki säger att **foton och film är facit för visuella och
interiöra detaljer** — material, färger, konstruktion, öppningar, skyltar.
Struktur och utseende hör alltså båda till den här kontrollen.

En tidigare version av den här checklistan sade att du inte skulle bedöma
materialkänsla. **Det var fel**, och det är rättat.

### Byggt i Roblox — bedöm i Studio

| Var | Vad |
|---|---|
| Ridhuset ute | Vinröd korrugerad fasad, svart list, takfärg, café-/annexgaveln, de kända öppningarna |
| Stallet ute | Mörkröd liggande panel, blågrått tak, **valvfönstrens rytm**, den ockragula entrédörren, portarna |
| Ridhuset inne | Banan 20 × 60, sargen med porten vid A och grinden mot hästgången, läktaren, **de glasade rummen**, **domarbåset vid E med exit-skylten**, **klockan** |
| Stallet inne | Dubbelstallet — fyra boxrader, två gångar, tvärkorridoren tvärs huset — boxfronternas identitet, gångytornas läsbarhet, de namngivna rummen |
| Komplexet | Hästgången, de två gårdsytorna, gavlarna i liv |

### Igenkänningsdragen byggs nu också i Roblox

Review 03:s tillägg öppnade en **visual parity blocker**: flera verifierade
identitetsdrag fanns bara i webbens renderare, så primärplattformen saknade just
det som avgör om någon känner igen UBRF. Det är åtgärdat — måtten ligger i
`IDENTITET` i `src/site.js`, webben läser dem, exporten bär dem och
`Anlaggningen.luau` bygger dem.

Bedöm alltså även dessa i Studio:

| Var | Vad |
|---|---|
| Stallet ute | **Takhuvarna** på nocken (en per box), **snörasskyddet** på båda takfallen, **förstukvisten** med ribbräcke och öppning mitt för dörren, **balkongen** och **spiraltrappan** på klubbgaveln |
| Ridhuset inne | Den **mörkröda övre långväggen** med vita läkt, takets **stålprofiler**, **kabelstegar med stegpinnar** och **ventilationskanaler med don** |

Måtten på dem är avlästa ur foton eller valda så att formen blir rätt — det
**verifierade är att dragen finns**, inte deras exakta centimetrar. Ser något av
dem uppenbart fel ut i proportion räcker ett besked, så rättas det på ett ställe
och följer med till båda ytorna.

### Vad som fortfarande INTE är ett fynd

Osourcad möblering, kosmetisk polish och avancerad ljussättning. Att
stallgången saknar spånremsa, att det inte finns namnskyltar på boxarna eller
att ljuset är platt — inget av det är vad gaten mäter.

## Om något ser fel ut

Skriv vad du ser och var. Enligt reviewen öppnas då **en riktad fix**, inte ett
nytt geometripass.

Tre saker är kända antaganden och kommer att se ut som *någon* har valt dem,
för det har jag:

- **hästgångens mått** — 11 × 3,5 m, takfot 3,2, nock 4,0
- **läktargapet** — 5,0 m
- **sargens grind** — 3,2 m

Satellitbilden verifierar att gången finns och var den ligger, inte hur bred den
är. Ser något av de tre uppenbart fel ut på plats räcker ett besked, så rättas
det på ett ställe.

## Om allt är grönt

Då kan Gate F01 stängas som **FIDELITY READY WITH DOCUMENTED GAPS** — aldrig som
`100 % IDENTICAL`, så länge de dokumenterade luckorna finns kvar. De står i
`audits/GATE-F01-UBRF-FIDELITY-RESULT.md` § 12 och § 13.
