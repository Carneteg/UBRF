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

Ägare: Claude (PR #29)
Äger filerna: `src/spel/skotsel.js`, `tools/exportera-spel.js`,
`roblox/game/UBRFSpel.luau`
Beroende av: inget
Klar när: `node tools/exportera-spel.js --kontrollera` exit 0 på en branch
rebasad mot `main`, och PR:n har ett acceptance contract enligt protokollet.

### G01-S2b — Roblox preparation läser skötseln ur exporten

Ägare: Claude (PR #30)
Äger filerna: `roblox/src/shared/HorseCore/Preparation.luau`,
`roblox/src/server/GameplayService*`, HUD- och controller-filerna i PR #30,
`docs/G01-HORSE-IDENTITY-CONTRACT.md`
Beroende av: **G01-S2a måste in först**
Klar när: `Preparation.luau` hämtar faser, ordning och texter ur den exporterade
skötseldatan i stället för egna literaler, och `--kontrollera` fäller om
Roblox-förberedelsen och `skotsel.js` inte har samma faser.

Beslut (Tobias, 2026-08-31): **JS är källan, Roblox läser.** Det omvända — att
göra `Preparation.luau` till källa och exportera till webben — är avvisat.
Webben har hela loopen och det pedagogiska innehållet ligger där.

Behåll server-auktoritativ progression, mount-gaten, HUD:en, hästidentitets-
kontraktet och de sex nya specarna. Arkitekturen är rätt; den läser från fel
källa.

### G01-S2c — hästkanon utökas till hela stallet

Ägare: Claude
Äger filerna: `src/spel/hastar.js`, `tools/hastar-till-sql.py`,
`supabase/migrations/`
Beroende av: G01-S2a (samma exportkedja)
Klar när: `src/spel/hastar.js` har alla aktiva UBRF-hästar med namn, ras,
födelseår och ordagrann beskrivning från `ubrf.se`, `--kontrollera` är i synk,
och specarna passerar med den större rostern.

Beslut (Tobias, 2026-08-31): **33, hemsidan stämmer.** Supabase `public.hastar`
har 33 aktiva — 18 hästar och 15 ponnyer — mot spelets 17. Databasen är
**upstream, inte kanon**: den får uppdatera JS-filen, men varken webben eller
Roblox läser den direkt.

Spelparametrarna 0–1 är game feel och sätts av den som bygger. Namn, ras,
födelseår och beskrivning är verklighet och får inte skrivas om för att låta
bättre.

### G01-blockerare — hästriggen byggs

Ägare: Tobias (produktion), ChatGPT (kravspec)
Äger filerna: issue #31, `roblox/` riggmapp när den finns
Beroende av: inget — men allt i G01 efter S2 vilar på den
Klar när: en riggad hästmodell med gångarterna skritt, trav och galopp går att
importera i Studio och driva från befintlig movement-kod.

Beslut (Tobias, 2026-08-31): **vi bygger den.** Detta är den enda posten i
projektet som varken Claude eller integrationsledaren kan lösa — det är
3D-arbete. Behöver en kravspec innan modellering börjar, inte efter.

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
| Kurerat urval hästar i stället för hela stallet | hemsidan stämmer — spelet ska visa det riktiga stallet | 2026-08-31 |
