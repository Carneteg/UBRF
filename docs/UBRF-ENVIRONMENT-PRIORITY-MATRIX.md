# UBRF — prioriterad anläggningsmatris

Status: arbetsmatris för miljöbyggaren, inte produktacceptans.

Prioritering väger samman källstyrka, spelvärde och känd avvikelse. En hög
prioritet är inte tillstånd att gissa. `REFERENCE GAP` blockerar permanent
geometri tills en entydig källa och rätt review finns.

| Prio | Område | Källstyrka | Spelvärde | Aktuell avvikelse/gap | Nästa tillåtna miljöpass |
| --- | --- | --- | --- | --- | --- |
| P0 | Teorisalen | V1/R1: `IMG_0140`–`0143`; äldre `stall-inne-04` | Hög: namngivet besöksrum och tydlig igenkänning | Material och detaljer förenklade; topologi låst | Avgränsad material-/detaljrättning, fasta kameror, webb/Roblox-paritet |
| P0 | Uppehållsrummets hela cirka 10 m och öppna L-form | V1/R1 visar bara små delvyer | Hög: navigation och central klubbyta | `MISMATCH / REFERENCE GAP`; full utsträckning och soffrelation ej bevisade | Ingen geometri; sök panorama/plan och verifiera gångväg |
| P0 | Figur, navigation och skymning | Renderpaket visar fasta vyer, inte fri rutt | Mycket hög: spelbarhet | Manuell webb-/Studio-runda saknas | QA efter varje miljöpass; ändra inte gameplay/kamera för att maskera fel |
| P0 | Ridhusets A-kortsida/dörrkonfiguration | Foto finns; vinkel/OpeningId ej avgjorda | Hög: orientering och utrymning | Renderad enkel dörr/öppning avviker från central dubbelkonfiguration | Separat spatial review; ingen kosmetisk fejkad dörr |
| P0 | Ridhusets entréplan | Manifestpost finns, binär saknas | Hög: reception, entré och öppningar | `MISSING BINARY / REFERENCE GAP` | Återfinn originalplan; ingen geometri från manifestmetadata |
| P0 | Servicedel efter pausrum | Delbilder/äldre sammanfogning, gräns ej visad | Hög: stallflöde | `CONFLICT / REFERENCE GAP` | Klassificera hela gränsen innan vägg eller öppning ändras |
| P0 | Hästpassage | V1/R1 visar bred öppning/grind men inte läge/mått | Hög: hästflöde och collision | `PARTIAL / REFERENCE GAP` | Bind original till planläge; ingen passage/collision på antagande |
| P1 | Ridhusets skåp/receptionskorridor | Flera verifierade foton + `IMG_0268.MOV` | Medel/hög: ankomst och identitet | Skåpen förbättrade; finish/ljus förenklade | Materialpass utan nya rader, antal eller ändrad öppenhet |
| P1 | Sadelkammaren | Flera V1/R1-bilder och filmer | Medel: igenkänning och rumsföljd | Dörrtyp belagd, planläge/öppningsbredd i konflikt | Rekvisitadetaljer endast; ingen ny öppning |
| P1 | Gård, parkering, vägar och veranda | V1/R1 `IMG_0210`–`0214`, `IMG_0303`–`0305` | Hög: första intryck och navigation | Nivåer och exakta gränser ej fullständigt bundna | Inventera yttyper/ankare; bygg bara entydiga befintliga drag |
| P1 | Utebanor och marknivåer | Foton/filmer och befintlig kanon, nivåskillnad olöst | Hög: ridmiljö | Höjdrelation ej mätbar | Behåll nuvarande nivåer tills plan/mätning finns |
| P2 | Fasader, tak, fönster och verkliga skyltar | Många GitHub/Drive-original | Medel/hög: anläggningsidentitet | Varierande källtäckning; skylttext får inte rekonstrueras | Källa-för-källa-pass med byggnadsidentitet och rättighetskontroll |

## Hårda ägar- och leveransgränser

- Replit bygger miljön från befintlig kanon; inget separat spel eller parallell
  världskälla.
- Claude äger gameplay och teknisk integration. Ridning, input, kamerastate,
  lektioner och Ugneta ändras inte i ett miljöpass.
- En nödvändig ändring i gemensam kärnfil stoppas för samordnad
  ägaröverlämning innan edit.
- ChatGPT granskar diff, källor, tester och faktisk runtime-evidens.
- Tobias ger slutligt PASS. Matrisen sätter aldrig `PRODUCT_ACCEPTED`.