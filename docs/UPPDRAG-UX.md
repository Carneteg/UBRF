# UPPDRAG — UBRF:s objective/navigation-regel

Status: `READY_FOR_CHATGPT_REVIEW`
Ursprung: PO-order 2026-09-06 på PR #87 efter Tobias produkttest.
Implementation: `src/uppdrag.js`, prov: `tools/uppdragstest.mjs`.

## Regeln

Spelaren ska när som helst kunna svara på tre frågor inom 1–2 sekunder:

1. **Vad ska jag göra?**  → uppdragets rubrik
2. **Var är det?**        → uppdragets punkt i världen
3. **Hur tar jag mig dit?** → vägvisaren, och dörren dit när målet ligger
   i en annan byggnad

Allt tre kommer ur **ett** objekt. Ingen yta får ha en egen uppfattning.

## Varför systemet finns

Före den här rundan ägde varje yta sin egen kedja av if-satser:
uppgiftspanelen en, ridlärarens replik en annan, whiteboarden en tredje
och markören en fjärde. De kunde säga emot varandra, och de gjorde det —
i produkttestet stod hästen i boxen medan en av texterna fortfarande
skickade spelaren till hagen. Ett fel som rättas på fyra ställen är fyra
fel som väntar.

Nu finns kedjan en gång:

```
prata med ridläraren → hitta hästen → hämta sadel + träns
                     → tillbaka till hästen (sköt om och sadla) → sitt upp
```

## Kontraktet

`uppdragMal()` ger `{id, rubrik, punkter[], mal:{scen,pos,var}, hastId?}`.

- `rubrik` — högst ~40 tecken. Vad, inte varför.
- `punkter` — 1–3 punkter, högst ~60 tecken styck. Ingen pedagogik här;
  den hör hemma där den behövs, inte samtidigt med navigationen.
- `mal` — en punkt som finns i data. Uppfinn aldrig en plats för att
  fylla ett hål.
- `hastId` — sätts bara när målet ÄR hästen. Det är den markören på den
  tilldelade hästen frågar efter.

`uppdragVagvisare()` översätter målet till den scen spelaren står i: är
målet i en annan byggnad pekas dörren ut, för det är svaret på "hur tar
jag mig dit". Nära målet (2,4 m — samma räckvidd som E) tonas vägvisaren
bort och den lokala markören över själva objektet tar över.

`uppdragGallerFor(hastId)` är renderarnas predikat. Ritkoden avgör inte
själv vilken häst som ska märkas — annars går det inte att prova, och en
mutation som märkte alla hästar gav noll röda prov när testet bara läste
tillståndet.

## Aktiv häst — och byte av den

`G.hastId` **är** den aktiva hästen. `sattAktivHast(id)` är enda stället
som får ändra den, och både tilldelningen och ett byte går genom den —
annars vore "en sanning" bara en avsikt. Funktionen nollar allt som
hänger på hästen: plats, möte, utrustning (och felräknaren), skötsel,
sysslor, täcke, lera och spåret efter den förra. Ett missat fält blir
ett spöke: den förra hästens sadel i handen medan uppdraget pekar på en
annan box.

Bytet ligger hos ridläraren — samma person som delade ut hästen — så att
det går att hitta utan att man vet att det finns. `valbaraHastar()` ger
bara hästar som faktiskt står uppstallade i en box; utan box finns ingen
punkt att peka på, och då kan vägledningen inte svara på "var är det".
Ingen häst hittas på.

Efter ett byte följer hela kedjan med av sig själv: objective, namn,
pronomen, box-waypoint, markör, minikarta, utrustningsmål, återvägen och
uppsittningen. Det finns ingen separat "byteskod" som måste hållas i
synk — allt läser den aktiva hästen.

## Vad som INTE får hittas på

- **Boxnummer.** Repot har ingen verifierad boxnumrering. Uppdraget säger
  därför "boxen i stallet — namnskylten på dörren" och pekar på dörren.
  `[REFERENCE GAP]`: boxnummer per häst.
- **Pronomen.** `HORSES[id].pronomen` har tre möjliga källor, i den
  ordning `CLAUDE.md` sätter:

  1. **`PRODUKTBESLUT`** — en människa har sagt hur det är. Tobias om
     Bränntomts Lydia 2026-09-06: "henne", och "honom" är fel. Ett
     produktbeslut med känd upphovsman står över härledd källtext, och
     listan `PRONOMEN_BESLUT` är avsiktligt kort och namngiven.
  2. **`besk`** — källtexten säger valack/han eller sto/hon. 12 hästar
     läser han här, 3 läser hon.
  3. **`REFERENCE_GAP`** — källan tiger och ingen har beslutat. Då
     används namnet. 17 hästar. Ingen gissning ur namnet: "Lady" och
     "Trixie" råkar stämma, men det är ingen metod.

  Fältet exporteras till Roblox (`FAKTA_RUNTIME`), eftersom ett
  produktbeslut inte står i `besk` och därför inte går att härleda där.

## Roblox-paritet

Kedjan, texterna och punkterna är **regler och data**, inte JS. En
Roblox-implementation ska läsa samma steg, samma ordning och samma
"peka på dörren när målet är i ett annat rum"-regel. Vad som ritas —
en billboard, en pil i världen, en markör på minikartan — är
plattformsspecifikt. Det som inte får skilja sig är vilket mål som är
aktivt, var det ligger och när vägvisaren tonas bort.

Pronomenet följer med som data till Roblox (`pronomen` i
`FAKTA_RUNTIME`). Det mesta går att härleda ur `besk` på båda
plattformarna, men ett produktbeslut står inte i källtexten — utan
fältet skulle Roblox säga "honom" om en häst webben kallar "henne".
