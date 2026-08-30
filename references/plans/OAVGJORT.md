# Två frågor planerna reser som jag inte får avgöra själv

Båda kommer ur mätningar i `references/plans/`, och båda motsäger något som står
som givet i briefen eller i byggnadskorten. Gate F01 säger uttryckligen: *"Om plan
och foto verkar krocka, hitta inte på en kompromiss."* Därför står de här i stället
för att lösas.

---

## 1 · Situationsplanen visar husen som SKILDA volymer

Issue #21 lade 2026-08-30 till en connected-complex-regel som P0:

> **The riding hall and stable are not two isolated buildings with empty space
> between them.** … forming one continuous UBRF building complex.

Regeln är villkorad i sin egen text:

> Do not leave a free-standing gap between riding hall and stable **if the
> authoritative plan shows connected building mass.**

**Den auktoritativa planen visar inte sammanhängande byggnadsmassa.**

Båda utrymningsplanerna bär samma SITUATIONSPLAN, och den ritar två separata
volymer med vit yta emellan, längs hela deras längd:

- I **ridhusets** plan är ridhuset orange (den plan skylten gäller) och stallet grått.
- I **stallets** plan är stallet orange och ridhuset grått.

Färgerna byter plats, formerna gör det inte. Ingen förbindande volym är ritad i
någondera. Se `derivat-situationsplan-ridhus.jpg`.

Husen står parallellt, förskjutna i längdled, med ridhuset i väster och stallet i
öster — precis som spelet redan bygger dem.

### Vad detta betyder

Enligt Gate F01:s egen källhierarki vinner planen för geometri. Då är den
nuvarande frilagda geometrin **inte** en P0-motsägelse, utan planenlig.

Men Tobias skrev regeln utifrån att han **varit på plats**, och en person på plats
väger tyngre än en schematisk situationsplan i frimärksstorlek. Det kan mycket väl
finnas en låg förbindande byggnad som situationsplanen utelämnar därför att den
inte är en egen brandcell.

**Detta är Tobias beslut, inte mitt.** Tre möjliga svar:

1. **Planen har rätt** — husen är fristående, connected-complex-regeln byggde på ett
   missminne, och regeln tas bort ur issue #21.
2. **Tobias har rätt** — det finns en förbindelse som planen inte visar. Då behövs
   ett foto av den, eller en beskrivning av var den sitter och hur man går igenom.
3. **Båda har rätt** — husen är fristående men en låg länga/skärmtak binder dem på
   ett ställe. Spelet har redan en "förbindelselänga" på 10 × 6 m vid södra änden;
   den kan vara just det, och behöver då bara byggas ihop ordentligt.

Tills svaret finns bygger spelet det planen visar: **skilda hus**. Det är inte ett
val — det är den enda källan i repot som visar båda husen samtidigt.

`[REFERENCE GAP]` Ett foto som visar utrymmet mellan gavlarna från marknivå.

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
