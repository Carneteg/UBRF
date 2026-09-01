# Arbetskön — tilldelning före arbete

Ägare av denna fil: **ChatGPT**. Ingen annan skriver i den.

Syftet är en enda sak: **en slice är fördelad innan någon börjar bygga.**

Roten till dubbelarbetet i #29 och #30 var inte otur. Båda agenterna fick G01 S2
och byggde skötselpedagogiken parallellt, varav bara den ena hade innehållet.
Fördelningen upptäcktes när koden redan fanns. Den här filen finns för att det
inte ska kunna hända igen.

Regler: `docs/INTEGRATION.md` § Tilldelning före arbete, § Kollisionsregeln,
§ En PR = ett gate-slice.

## Så skrivs en köpost

    ### <gate>-<slice> — <en rad om vad som ska bli sant>
    Ägare: Claude | ChatGPT | Tobias | Integrationsledare
    Äger filerna: <exakta sökvägar eller mappar>
    Beroende av: <slice eller PR som måste in först, eller "inget">
    Klar när: <mätbart, med kommando eller mänsklig gate>

**Äger filerna** är bindande. En PR som rör filer utanför sin köpost är inte
färdig — den är ofördelad, och integrationsledaren skickar tillbaka den.

Är en fil redan deklarerad i en annan öppen post eller PR gäller
kollisionsregeln: den öppna posten äger filen.

## Beslutade slices

Seedade av integrationsledaren 2026-08-31 ur Tobias beslut samma dag. Från och
med nästa slice är det ChatGPT som skriver här.

### F02-underlag — ridhusets referenser kompletta innan rumsgränser mäts

Ägare: Integrationsledaren
Äger filerna: `references/buildings/ridhus/`, `references/video/`,
`references/DRIVE-INVENTORY-2026-08-30.md`, `references/DRIVE-SOURCE-INDEX.md`
Beroende av: inget
Klar när: Drives 66 unika ridhusbilder finns i repot enligt
`tools/convert-photos.sh`-konventionen, nyckelbildrutor är dragna ur de åtta
filmerna, och varje ny fil har en rad i inventeringen med IMG-källa, Drive-id
och vad som faktiskt syns.

Beslut (Tobias, 2026-08-31): **hämta in de 66 först.** Ridhusets interiör mättes
på 13 bilder av 66 fotograferade. Två av tre rektifieringsförsök är redan körda
och underkända; en tredje mot samma tunna underlag beställer en fjärde.

`docs/DELIVERY-PROTOCOL.md` § 6: en detalj får inte klassas `REFERENCE GAP` bara
för att den saknas i redan extraherade JPG-bilder, om råfilm finns. Den fanns —
i Drive.

### G01-S2a — skötseln som delad kanonisk data

Ägare: ChatGPT **endast genom Product Owners uttryckliga undantag** (PR #52).
Normal ägare för implementation är Claude; separat extern review krävs eftersom
ChatGPT genomförde denna avgränsade städ-/synkslice.
Äger filerna: `index.html`, `src/moment.js`, `src/spel/skotsel.js`,
`tools/exportera-spel.js`, `roblox/game/UBRFSpel.luau`,
`roblox/tests/spel.spec.luau`
Beroende av: inget
Klar när: PR #52 är separat granskad, CI/grindar är gröna på exakt head och
`node tools/exportera-spel.js --kontrollera` exit 0. PR #52 är
`READY_FOR_EXTERNAL_REVIEW`, inte accepterad eller mergad.

Historik: gamla Claude-PR #29 är stängd och ersatt av den scope-renare #52.
Ingen får återuppliva #29 eller bygga vidare på dess gamla branch som om den vore
aktiv S2a.

### G01-S2b — Roblox preparation läser skötseln ur exporten

Ägare: Claude (PR #30 ska rebasas/omarbetas efter att S2a-källan är landad)
Äger filerna: `roblox/src/shared/HorseCore/Preparation.luau`,
`roblox/src/server/GameplayService*`, HUD- och controller-filerna i PR #30.
`docs/G01-HORSE-IDENTITY-CONTRACT.md` finns redan i `main` och får inte återinföras
som en konkurrerande kopia från den gamla PR-basen.
Beroende av: **G01-S2a / PR #52 måste in först.** Om S2c / PR #53 landar före
S2b ska S2b rebasas mot den nya separerade exportstrukturen (`UBRFSpelData` /
`UBRFSkotsel`) i stället för att återföra monolitisk genererad data.
Klar när: `Preparation.luau` hämtar faser, ordning och texter ur den exporterade
skötseldatan i stället för egna literaler, servern håller progressionen
authoritative, tilldelad `HorseId` är samma identitet som får bindas/mountas, och
`--kontrollera` fäller om Roblox-förberedelsen och `skotsel.js` inte har samma
faser. Alla relevanta specs och package/webb-grindar ska vara gröna på den
rebased PR-headen.

Beslut (Tobias, 2026-08-31): **JS är källan, Roblox läser.** Det omvända — att
göra `Preparation.luau` till källa och exportera till webben — är avvisat.
Webben har hela loopen och det pedagogiska innehållet ligger där.

Behåll server-auktoritativ progression, mount-gaten, HUD:en, hästidentitets-
kontraktet och de relevanta specarna. Arkitekturen är rätt; den gamla #30-basen
läser från fel källa och är inte mergebar mot nuvarande main.

### G01-S2c — hästkanon utökas till hela stallet

Ägare: ChatGPT **endast genom Product Owners uttryckliga undantag** (PR #53),
med separat extern review före merge.
Äger filerna: de filer som deklareras av PR #53:s acceptance contract, inklusive
`src/spel/hastar.js`, versionssnapshoten under `references/data/`, exportkedjan,
genererad Roblox-hästdata och berörda specs. `tools/hastar-till-sql.py` tas bort
för att gameplaymodellvärden inte ska kunna skrivas tillbaka som databasfakta.
Beroende av: **PR #52**; #53 är stackad ovanpå S2a.
Klar när: PR #53 är separat granskad; exakt 33 aktiva UBRF-hästar/ponnyer finns i
kanonen (18 hästar + 15 ponnyer), källfakta matchar snapshot/live-underlag,
`UNTUNED` används där spelprofil inte är beslutad, lektionsrotationen innehåller
bara giltiga tunade ids och alla deklarerade export-/Luau-/CI-grindar är gröna på
exakt head. PR #53 är `READY_FOR_EXTERNAL_REVIEW`, inte accepterad eller mergad.

Beslut (Tobias, 2026-08-31): **33, hemsidan stämmer.** Supabase `public.hastar`
har 33 aktiva — 18 hästar och 15 ponnyer. Databasen är **upstream, inte kanon**:
den får uppdatera JS-filen via verifierad snapshot/synk, men varken webben eller
Roblox läser den direkt som gameplay authority.

Spelparametrarna 0–1 är game feel och ska hållas skilda från verklighetsfakta.
Namn, ras, födelseår och beskrivning är verklighet och får inte skrivas om för
att låta bättre.

### G01-blockerare — hästriggen byggs

Ägare: Tobias (produktion), ChatGPT (kravspec)
Äger filerna: issue #31, `roblox/` riggmapp när den finns
Beroende av: inget — men allt i G01 efter S2 vilar på den
Klar när: en riggad hästmodell med gångarterna skritt, trav och galopp går att
importera i Studio och driva från befintlig movement-kod.

Beslut (Tobias, 2026-08-31): **vi bygger den.** Detta är den enda posten i
projektet som varken Claude eller integrationsledaren kan lösa — det är
3D-arbete. Kravspecen finns och ska följas före modellering/import, inte skrivas
i efterhand.

### SEC-01 — gästläget dokumenteras som avsiktligt

Ägare: Integrationsledaren
Äger filerna: `supabase/migrations/`, säkerhetsavsnitt i docs
Beroende av: inget
Klar när: `public.ny_ryttare()` har en dokumenterad motivering och en spärr mot
massanrop, och kvarstående advisor-varningar är kvitterade i text.

Beslut (Tobias, 2026-08-31): **avsiktligt just nu.** Funktionen är
`SECURITY DEFINER` körbar av `anon` därför att gästläget bygger på den.
Konsekvensen — att vem som helst kan skapa ryttare — accepteras tills vidare och
ska då stå skriven, inte upptäckas.

## Avvisat

Fört hit så att frågan inte kommer tillbaka var tredje vecka.

| Förslag | Avvisat därför att | När |
|---|---|---|
| `Preparation.luau` som källa, export till webben | webben har hela loopen och den pedagogiska texten; Roblox hade fyra fasetiketter utan innehåll | 2026-08-31 |
| Merga #32 "först för säkerhets skull" | #33 innehåller alla dess commits, bekräftat med `git merge-base --is-ancestor` | 2026-08-31 |
| Återuppliva #9 | 105 commits bakom `main`; temana levererades av Gate 01 | 2026-08-31 |
| Återuppliva #29 som S2a | ersatt av scope-ren PR #52 | 2026-09-01 |
| Kurerat urval hästar i stället för hela stallet | hemsidan stämmer — spelet ska visa det riktiga stallet | 2026-08-31 |
