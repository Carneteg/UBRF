# Situationsplan – UBRF, Husbyvägen 1A, Bro

Underlaget är satellitvy och Street View över Husbyvägen 1A (Google Maps), lästa
tillsammans med fotona i `buildings/`. **Bilderna sparas inte i repot** — de är
Googles, och det är måtten vi behöver, inte bilderna. Det som är läst ur dem står
här nedan med metoden angiven.

Koordinatsystem: spelets eget, i meter. Anläggningen ligger i `ANL` i `src/site.js`;
`x` ökar österut och `y` norrut, samma tal i kartvyn som i 3D-världen. Ingen omräkning
behövs — skriv meter här och meter i koden.

## Så ser tomten ut i verkligheten

Två långa byggnader **parallellt intill varandra**, med en smal gräsgård emellan.
Stallet ligger på ridhusets nordöstra sida. Båda löper **nordväst–sydost**, ungefär
**40° vridet från norr**.

- **Grusplanen — parkeringen** ligger vid husens **nordvästra gavlar**, mot
  Björklidsvägen. Utrymningsplanerna pekar dit ("parkeringen mot Björklidsvägen"
  är återsamlingsplats), och det är därifrån gavelfotona i `buildings/ridhus/`
  och `buildings/stall/` är tagna. **Står man på grusplanen har man ridhuset
  till höger och stallet till vänster**, med förbindelselängan synlig mellan
  gavlarna längre bort — det är ankomstvyn, och den spelet ska träffa.
- **Björklidsvägen** kommer in från nordväst, till grusplanen.
- **Enköpingsvägen** går längs ridhusets sydvästra långsida. Det är den sidan som
  bär UBRF-skylten och den långa entrékvisten — och kvisten sitter närmast
  **caféets gavel i nordväst** (Street View).
- **Husbyvägen** går i öster/sydost; därifrån går en grusväg in till gårdsplanen
  vid stallets sydöstra gavel. Den gaveln (Street View) har två entrédörrar
  under vita skärmtak och en rak ståltrappa till övervåningen; strax intill
  står fodersilon (satellit).
- **Hagarna** ligger direkt öster om stallet, med trästaket.
- **Utebanorna** ligger norr och nordost om hagarna: en stor sandbana och en
  mindre paddock.
- Aspviks koloniträdgårdsförening ligger sydost om anläggningen.

### Skala i satellitbilden
Ridhuset mäter 330 bildpunkter på längden. Med byggnadens 75 m (uträknat ur
utrymningsplanen, se ridhuskortet) blir det **4,4 bildpunkter per meter**. Stallets
236 bildpunkter ger då **54 m** — exakt det stallkortet antar ur boxantalet. Två
oberoende vägar till samma tal.

## Placeringen i spelet

| Byggnad/yta | Position (m, X/Y) | Rotation | Fotavtryck (m) | Kommentar |
|---|---|---|---|---|
| Ridhuset | 118 / 44 (sydvästra hörnet) | nock nord–syd, cafégaveln mot grusplanen i **norr** | 25 × 75 | Byggd efter `buildings/ridhus/KORT.md`. Takfot 6,2 m, nock 9,2 m, 13° resning. |
| Stallet | 154 / 46 (sydvästra hörnet) | nock nord–syd, klubbgaveln (spiraltrappan) mot grusplanen i **norr** | 15 × 54 | Byggd efter `buildings/stall/KORT.md`. Takfot 4,4 m, nock 8,4 m, 28° resning. |
| Gräsgården mellan husen | 144–154 | — | 10 × 48 | Smal, precis som i satellitbilden; stängd i söder av längan |
| Grusplanen / parkeringen | 106 / 121 | — | 48 × 34 | Vid norra gavlarna, mot Björklidsvägen. Hit kommer man. |
| Gårdsplanen i sydost | 144 / 18 | — | 40 × 26 | Vid stallets södra gavel; infart från Husbyvägen |
| Grusvägen längs ridhuset | 112 / 20 | — | 6 × 101 | Mot åkern i väster |
| Hage Ö1 | 176 / 44 | — | 30 × 28 | Direkt öster om stallet |
| Hage Ö2 | 176 / 76 | — | 30 × 24 | |
| Uteridbanan (dressyr) | 176 / 106 | långsidan nord–syd | 20 × 40 | Norr om hagarna |
| Paddocken bredvid | 156 / 118 | — | 20 × 28 | Norr om stallet, bortom grusremsan |
| Domarkuren | 184 / 148 | — | 4,5 × 3,5 | Vid banans norra kortsida |
| Fodersilon | 166 / 40 | — | — | Vid stallets **södra** gavel, syns i satellitbilden |

Marknivå: plant över hela anläggningen. Den slänt upp mot banorna som fanns i den
första versionen är borttagen — satellitbilden visar ingen höjdskillnad.

Väderstreck i spelet: solens riktning ligger i `LJUS.dag.sol` i `src/ljus.js`.

## Medvetna avvikelser

1. **Rotationen.** Verkligheten är vriden ~40° från norr. `ANL` är byggd av
   axelriktade rektanglar, så spelets rutnät är i stället lagt **längs byggnaderna**:
   spelets norr är verklighetens nordväst. Inbördes placering, avstånd och vilken
   sida som vetter åt vad stämmer; kompassriktningen gör det inte. Att vrida hela
   anläggningen skulle kräva att varje rektangel blev en polygon.
2. **Gavlarna rättade 2026-08-29.** Spelet lade tidigare grusplanen, entréerna
   och silon vid fel gavlar — hela ankomsten blev spegelvänd (ridhuset till
   vänster i stället för till höger). Nu ligger ankomsten vid spel-norr
   (verklighetens nordväst): satellitbilden, Street View-bilderna och
   utrymningsplanernas återsamlingsplats pekar alla på samma sak. Kvar som
   avvikelse: Björklidsvägen och Husbyvägen är förenklade till raka
   kantvägar. `[avvikelse]`
3. **Skogsstigen** i norr är påhittad. Det finns skog runt anläggningen, men
   sträckningen är inte läst ur någon bild. `[antagande]`
4. **Åkern i väster** är en förenkling av markerna och koloniområdet.

## Utrymningsplanerna

Det finns uppsatta utrymningsplaner (Presto AB, 2025-10-11) i båda husen, och de är
det bästa underlaget som finns för insidorna — bättre än varje foto. De är
fotograferade snett och sitter i reflekterande ramar, så måtten går inte att läsa ur
dem, men planformen gör det. Vad de säger står i respektive byggnadskort under
"Invändigt".

Kort: **stallet är ett dubbelstall** med fyra boxlängor och två gångar, och
**ridhuset har en djup entré- och trapphusdel i gaveln** med två trapphus och en
hiss.

Ridhuset är ombyggt efter sin plan. Ritningen saknar skalstock, men Tobias har
bekräftat att banan är **20×60**, och två kända mått räcker för att räkna bort
perspektivet: byggnaden är **25 × 75 m**, inte 26 × 66 som gissades förut.
`STALLINNE` står kvar som känt fel tills det finns en rak bild på stallets plan.

## Kvar att kontrollera på plats

- Stallets längd. 54 m är räknat baklänges ur boxantalet och stämmer grovt med
  satellitbilden, men är inte mätt.
- Avståndet mellan husen. 10 m i spelet, ser ut som 10–14 m i satellitbilden.
- Var exakt hagarnas grindar sitter.
