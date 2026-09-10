# Enhetstest First Playable — Roblox Studio och fysisk iPad

Skrivet på arbetsordern i **#161 punkt 5**, och det är den punkten som är
grinden: *"När kandidaten är automatiskt grön: leverera ett testpaket för
Roblox Studio + fysisk iPad."* Kandidaten är automatiskt grön. Ingenting i
den här filen ändrar kod.

Systerdokument: `ENHETSTEST-G02-D.md` provade ridkärnan och replayen. Det
här provar **hela första dagen, skötseln, persistensen och hjälpen** — det
som #161 byggde och det som CI per definition inte kan nå.

## Innan du börjar

| Fält | Fyll i |
|---|---|
| Build-SHA | `b812f1e302f5ec34a28090dbb1de76b1d640f85d` (eller senare — skriv den du faktiskt testade) |
| Yta | Roblox Studio · Roblox på iPad · Roblox med handkontroll · webb på iPad |
| Enhet och OS | t.ex. iPad Air 5, iPadOS 18.2 |
| Viewport / orientering | t.ex. 1180×820 landscape |
| Inmatning | finger · finger + tangentbord · gamepad (skriv modell) |
| Studio-build | **place-filen** i `roblox/releases/first-playable-place-*/UBRF-FirstPlayable.rbxlx` — öppna och tryck Play |
| Preflight i outputen | `FIRST_PLAYABLE_PREFLIGHT: PASS` + `FIRST_PLAYABLE_SHA=…` (står det `FAIL`: **STOPP**, rapportera raderna) |
| Webbpreview | Vercel-projektet `ubrf`, länken i #162 |

### Vilken build du ska testa — läs det här först

**Blockerare i #162, hittad av Tobias fysiskt i Studio:** protokollet pekade
tidigare ut `roblox/buildings/.studio/UBRF-klistra-in.luau` som Studio-paket.
Den filen bygger **anläggningen och QA-panelen och ingenting annat** — ingen
spawn, ingen dörrinteraktion, ingen häst, ingen persistens. Avsnitt B nedan
provar persistens och gameplay, och gick alltså inte att prova med det
paketet. Symptomen blev fel spawn och en gul dörrmarkör som inte gjorde
något.

Använd därför **place-filen**: öppna `UBRF-FirstPlayable.rbxlx` i Studio och
tryck **Play**. Världen byggs av servern vid start, och det första som skrivs
i Output är vilken build du kör och om den är komplett:

```
FIRST_PLAYABLE_SHA=<exakt sha>
FIRST_PLAYABLE_PREFLIGHT: PASS
```

Står det `FIRST_PLAYABLE_PREFLIGHT: FAIL` — **fortsätt inte**. Då saknas
något i builden, och raderna ovanför säger vad. Rapportera dem i stället för
att kryssa i matrisen.

### DataStore i Studio — läs det här först

Persistensdelen (avsnitt B) **kräver att Studio får skriva till DataStore**:
`Game Settings → Security → Enable Studio Access to API Services`. Utan den
faller läsningen, och då är beteendet med flit ett annat: spelaren får en
sessionsave, kan spela, men sparar inte. Det är korrekt beteende — men det
provar inte persistensen. Ser du `[Spar] Inget datalager tillgängligt` i
outputen är API-åtkomsten av.

## Vad som INTE är bevisat, och alltså är hela poängen

Luau-bänken kör mot en **stubbad** `DataStoreService`. Den bevisar att
reglerna håller; den säger ingenting om Roblox riktiga kvoter, throttling,
trådschemaläggning eller `PlayerAdded`-timing. Hela avsnitt B är därför
`NOT_TESTED IN LIVE DATASTORE/STUDIO` fram till att någon fyller i det här.

Bänken kör heller ingen fysik, och en emulerad pekhändelse är inte ett
finger. Att `DPadDown` fyrar på en riktig handkontroll är inte provat alls.

## Så här rapporterar du

En rad per steg. `PASS` · `FEL` · `NOT_TESTED`. Skriv hellre "fungerade men
kändes trögt" än att kryssa PASS — game feel är din bedömning, inte provets.

```
B3  FEL  iPad Air 5, Roblox-appen, 2a8938e
         Lämnade mitt i ryktningen, gick in igen → skötseln började om
         från hälsningen MEN passnumret stod på 2.
         Repro: 2 av 3 försök.
```

Vid avvikelse: stegnummer, vad du gjorde, vad som hände i stället, om det
går att upprepa. Det räcker — jag rotorsakar.

---

## A. Hela första dagen, i ordning

Produktkravet är kedjan, inte de enskilda momenten.

1. Starta som **helt ny spelare** (Studio: ny `UserId`, eller rensa nyckeln `spelare_<id>` i butiken `UBRF_Spelare_v1`).
2. **Förväntat: du får Blackrock Jack.** Inte "en häst" — Jack. Det var blockerare 3 och är nu en produktionsregel.
3. Hälsa på och visitera hästen.
4. Rykta. **Förväntat:** rätt zon krävs, och steget blir klart av att du gör det — inte av att du står nära.
5. Hovvård.
6. Utrustning.
7. Led hästen till ridhuset.
8. Sitt upp. **Förväntat:** går INTE innan momenten ovan är klara (fail-closed).
9. Rid lektionen. Gångartsbyten.
10. Hoppa, om det är upplåst.
11. Se ritten (Ugneta/replay).
12. Sitt av.
13. Eftervård. **Förväntat:** passet kan inte avslutas innan den är gjord.
14. Passet sparas. **Förväntat:** feedback i skrift.
15. Läs panelen INNAN du lämnar boxen. **Förväntat:** den säger att dagens
    pass är klart och sparat, och den bjuder INTE in till uppsittning. Står
    det "Klar — du kan sitta upp" är det omreviewens fynd 3 tillbaka: servern
    nekar dig, och panelen ska aldrig be om något servern nekar.
16. Försök sitta upp igen samma dag. **Förväntat:** nekas, med besked — och
    panelen ska inte ha lovat något annat i steg 15.
17. Nytt pass (nästa dag). **Förväntat:** nu är du INTE låst till Jack längre.

### Negativa steg — de här ska falla

18. Försök godkänna ett skötselmoment på **fel häst**.
19. Försök göra momenten i **fel ordning**.
20. **Dubbeltryck** på samma moment.
21. Försök godkänna ett moment **på för långt avstånd**.
22. Sitt upp **innan** momenten är klara.

Faller något av 18–22 igenom är det en release blocker, inte en nit.

## B. Persistensen — `NOT_TESTED IN LIVE DATASTORE/STUDIO`

Kräver API-åtkomst enligt rutan högst upp.

1. Ny spelare → första dagen → **delvis** progress → lämna → gå in igen.
   **Förväntat:** rätt läge tillbaka. Ingen gratis avbockning.
2. Avbrott **mitt i** skötseln, inte mellan moment.
3. Slutfört pass → lämna → gå in igen. **Förväntat:** passet och relationen finns kvar.
4. En häst med **aktiv skada/vila** → lämna → gå in igen. **Förväntat:** skadan finns kvar, och en ritt tvättar inte bort den.
5. Två spelare samtidigt: kan de få **samma** häst? Ska inte gå.
6. Stäng servern mitt i ett pass (Studio: stoppa körningen). **Förväntat:** ingen krasch, inget dubbelräknat pass.
7. **Slå AV** API-åtkomsten och gå in. **Förväntat:** spelbart, men sparar inte, och den befintliga sparfilen skrivs inte över.

8. **Vilan ska räknas NER, inte bara finnas.** Ge en häst en skada, spela
   färdigt ett pass, lämna, gå in igen, spela färdigt nästa pass — och
   fortsätt tills vilan är slut. **Förväntat:** talet sjunker mellan
   sessionerna och skadan försvinner till slut. Står talet still är
   omreviewens fynd 1 tillbaka, och hästen vilar för evigt.
9. **En nyare sparfil får inte skrivas över.** Höj `v` i spelarens rad i
   butiken till ett tal spelet inte känner (t.ex. `v = 99`) och gå in.
   **Förväntat:** spelbart, men sessionen sparar INTE, och raden ligger
   orörd kvar när du lämnar — kontrollera att `v` fortfarande är 99 och att
   fältet du la dit finns kvar. Skrivs raden om är omreviewens fynd 2
   tillbaka.

Det som INTE går att prova här: revisionskonflikten, alltså två servrar som
skriver samma spelare. Den kräver en riktig kollision och provas bara i
bänken. Ser du däremot en `[Spar] ... basar om på den färska raden` i
utskriften under vanligt spel är det värt att rapportera — då kolliderar
något som inte borde kollidera.

Steg 7 är det viktigaste i hela avsnittet: det är fail-safe-vägen, och den
ska vara spelbar utan att förstöra något. Steg 9 är samma sak sett från
lagret: en gammal server ska hellre avstå än gissa.

## C. Handkontrollen — blockerare 2, aldrig provad fysiskt

1. Anslut handkontroll. Sitt upp via prompten.
2. **Sitt av med styrkors ned (`DPadDown`).** Det här var omöjligt före `2a8938e`: `E` är en tangent, och det fanns ingen gamepadväg ned.
3. Öppna hjälpen med styrkors upp (`DPadUp`). Stäng den. **Öppna den igen.**
4. Läs hjälpraden "Sitt upp / sitt av". **Förväntat:** den säger styrkors ned, inte `E`.
5. Kontrollera att inget annat ändrats: hopp (A), halvhalt (B), gångart upp/ner (R1/L1), tygel (R2), sits (L2), lektionen vidare (Y), se ritten (X).
6. **Hotplug:** dra ur kontrollen mitt i ritten, sätt i igen.

## D. Hjälpen på pekskärm

1. Stäng hjälpen. **Förväntat:** `?`-knappen finns kvar och går att träffa.
2. Träffa den med tummen. 44 px är ett mått, inte ett bevis — känns den för liten, skriv det.
3. **Förväntat:** hjälpen skymmer inte ridkontrollerna eller replayen.

## E. Touch- och inputlivscykel

1. **Två tummar samtidigt** — spak och en knapp.
2. Dra fingret **ut ur** en knapp innan du släpper.
3. `touchcancel`: ett samtal eller notis mitt i ritten.
4. **Focus loss:** växla app mitt i ritten. **Förväntat:** hjälperna släpps, hästen går inte vidare.
5. **Rotation** porträtt ↔ landscape mitt i ritten.
6. **Safe areas** på en telefon med hak.
7. **Textskalning** i OS, största steget.
8. Zoom.
9. Ingen kvarhängande gångart eller hjälp efter avsittning eller respawn.

## F. Kamera, kropp och rörelse

1. Kameran gör inte styrningen trög.
2. Huvud, öron och man ser rätt ut i sadelkameran.
3. Ingen clipping genom väggar, boxfronter eller hästen.
4. Hoppets takeoff och landning.
5. **Reduced motion** påslaget i OS.

## G. Känslan — din bedömning, ingen annans

1. Är det **roligt** att göra skötseln, eller är det en checklista?
2. Känns ansvaret för hästen som gameplay?
3. Känns hästen som en häst, eller som ett fordon med hästmodell?
4. Skulle en tioåring förstå vad hon ska göra, utan att bli tillsagd?
5. Känner du igen UBRF?

Punkt 1 och 2 är produktkärnan i `CLAUDE.md`. Faller de är kandidaten inte
klar hur grön CI än är.

---

## Vad blockerarna kräver för att räknas som bevisade i drift

| # | Bevisat i bänken | Kräver för live-PASS |
|---|---|---|
| 1 DataStore-racet | ja, mot stubb med yieldande `GetAsync` | B1–B4 och B7 ifyllda i Studio med API-åtkomst |
| 2 Gamepadavsittning | ja, genom klientens egen lyssnare | C2 på en fysisk handkontroll |
| 3 Jack första dagen | ja, från tom save genom tjänsterna | A2 och A17 |

Omreviewens runda 3 lade till tre:

| # | Bevisat i bänken | Kräver för live-PASS |
|---|---|---|
| Vilan räknas ner | ja, minnet äger vilan och skrivningen avbryts vid konflikt | B8 över minst två sessioner |
| Nyare sparfil skrivs inte över | ja, mot stubbad `UpdateAsync` som avbryter som Roblox | B9 med en handredigerad rad i butiken |
| Revisionskonflikt låser inte sessionen | ja, ombaseringen provas i bänken | **kan inte provas för hand** — kräver två servrar som skriver samma nyckel. Förblir `NOT_TESTED IN LIVE DATASTORE`. |
| Räknat pass ber inte om uppsittning | ja, serverns egna vyer genom klientens riktiga lyssnare | A15 och A16 |

## Vad som händer sedan

Fyll i, lägg resultatet i **#161**. Avvikelser rotorsakas och rättas på
samma gren; PR:n är kvar som draft. `CHATGPT_VISUAL_PASS` sätts av ChatGPT
efter side-by-side-review av screenshot-packet, `PRODUCT_ACCEPTED` bara av
Tobias. **Grön CI är inte produktacceptans, och det här dokumentet ifyllt
av mig hade inte varit ett enhetstest.**
