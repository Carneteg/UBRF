# Två frågor planerna reser som jag inte får avgöra själv

Båda kommer ur mätningar i `references/plans/`, och båda motsäger något som står
som givet i briefen eller i byggnadskorten. **Fråga 1 är besvarad av Tobias
2026-08-30 och står kvar som dokumentation av beslutet; fråga 2 är öppen.** Gate F01 säger uttryckligen: *"Om plan
och foto verkar krocka, hitta inte på en kompromiss."* Därför står de här i stället
för att lösas.

---

## 1 · Situationsplanen visar husen som SKILDA volymer — AVGJORD 2026-08-30

**Tobias svar:** *"husen är sammanbyggda, jag har varit där"* och *"det är
hästgång mellan byggnaderna"*.

Alternativ 2 nedan gäller alltså: det finns en förbindelse som situationsplanen
inte visar, och den är en **hästgång** — man leder hästen inomhus mellan stallet
och ridhuset i stället för att gå ut över gården. Product Owner på plats väger
tyngre än en schematisk situationsplan i frimärksstorlek, och en låg förbindelse
behöver inte vara ritad som egen volym om den inte är en egen brandcell.

Frågan om **att** husen sitter ihop är därmed stängd. Frågan om **var** gången
går är det inte — se rutan sist i avsnittet.

### Vad planerna faktiskt visar (står kvar som källa)

Båda utrymningsplanerna bär samma SITUATIONSPLAN, och den ritar två separata
volymer med vit yta emellan, längs hela deras längd:

- I **ridhusets** plan är ridhuset orange (den plan skylten gäller) och stallet grått.
- I **stallets** plan är stallet orange och ridhuset grått.

Färgerna byter plats, formerna gör det inte. Ingen förbindande volym är ritad i
någondera. Se `derivat-situationsplan-ridhus.jpg`.

Husen står parallellt, förskjutna i längdled, med ridhuset i väster och stallet i
öster.

Detta är alltså en **CONTRADICTION** mellan situationsplanen och Product Owner,
avgjord till Product Owners fördel enligt konflikthierarkin i `CLAUDE.md`
(punkt 1 slår punkt 3). Den skrivs inte om till att planen "egentligen" visar en
förbindelse — den gör den inte.

### Vad spelet bygger

Byggnaden `hastgang` i `src/site.js`, 11 × 6 m mellan ridhusets östvägg
(x = 143) och stallets västvägg (x = 154), med scenövergång åt båda hållen.
Fasadöppningarna mot grannhuset är märkta `intern` och STALLINNE-dörren `inne`,
så att förbindelsen inte får någon markör ute på gården — den finns inte där.

`[ASSUMPTION]` **Läget är härlett, inte hämtat ur en källa.** Hästgången ligger
där den ligger därför att det är det enda stället där båda husen har gångbar
insida mot varandra: ridhusets läktare upptar hela östväggen mellan y 53 och
103, och stallets boxlängor upptar y 71–108. Kvar blir y 108–115, alltså
stallets klubbdel mot ridhusets entréhall.

`[REFERENCE GAP]` **Frågan till Tobias:** var går hästgången i verkligheten?
Vid norra änden (klubbdelen mot entréhallen, som spelet nu gissar), på mitten,
eller i söder? Och kommer man ut i ridhusets hall eller direkt i ridbanan? Ett
foto inifrån gången, eller bara "den ligger i norra/södra änden", räcker för att
byta ut antagandet mot verklighet.

---

## 2 · Planen motsäger stallets antagna mått

Stallets Plan 1 går att mäta i proportion men inte i meter — den saknar skalstock.
Två oberoende vägar till skalan ger svar som inte går ihop.

**Planens egen proportion:** byggnaden mäter 2869 × 807 px, alltså **3,56:1**.
Ridhusets plan ger 3,06:1 mot kortets 25 × 75 m (3,00:1), så metoden håller inom
två procent på den byggnad där svaret är känt.

| Om … | då blir … | rimligt? |
|---|---|---|
| längden 54 m (satellit) | bredden **15,2 m**, gångarna **1,9 m** | Nej — en gång på 1,9 m går inte att leda hästar i |
| boxfacket 3,5 m (huvrad/fönsterrytm) | längden **~83 m**, bredden **23,3 m** | Nej — då vore stallet längre än ridhuset, vilket satelliten motsäger |
| bredden 21 m (spelets antagande) | gångarna 2,6 m, boxdjup 3,7–4,4 m, längden 75 m | Måtten inne är rimliga, längden är det inte |

Ungefär **13 boxfack per länga** går att räkna i planen. Vid 54 m längd blir facket
2,3 m — för smalt för en häst. Vid 3,5 m fack blir huset 83 m.

**Något av följande är fel, och planen ensam kan inte säga vilket:**

- satellitavläsningen 236 px vid 4,4 px/m → 54 m,
- huvarnas och fönstrens 3,5 m-rytm, som är läst ur ett foto vars skala kommer ur
  entrédörrens antagna 2,05 m,
- min egen avläsning av planens proportion.

### Vad som gäller i spelet tills vidare

- **Bandens inbördes andelar** är mätta i planen och används rakt av. De är
  skaloberoende och lika i tre snitt. `VERIFIED`
- **Totalbredden 21 m** är ett `ASSUMPTION` i mitten av intervallet 15–23 m. Den
  ligger på ett enda ställe i koden (`STALLINNE.bredd`); ändras den följer allt
  annat med.
- **Längden 54 m** står kvar oförändrad. `ASSUMPTION`

`[REFERENCE GAP]` Det som stänger frågan på en minut: **ett mått**. En skalstock i
ritningen, ett måttsatt rum, eller ett uppmätt avstånd på plats — till exempel
gångens bredd mellan två boxfronter, eller byggnadens längd stegad utvändigt.
