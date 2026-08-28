# ASSETS.md — modeller, texturer och referenser

Varje fil som används i spelet ska stå här med källa och licens. Inget
byggs in utan en rad i den här filen.

## Status: filerna är inventerade men inte hämtade

Paketet ligger i Drive-mappen *UBRF → Models*. Jag kunde **läsa** mappen via
Drive-connectorn och har hela fillistan och licensen nedan, men jag kunde inte
**hämta** filerna. Se «Vad som blockerar» sist i dokumentet.

---

## Quaternius — Ultimate Animated Animal Pack

**Källa:** LowPoly Models by @Quaternius · <https://www.patreon.com/quaternius>
**Licens:** CC0 1.0 Universal (Public Domain Dedication) ·
<https://creativecommons.org/publicdomain/zero/1.0/>
(ordagrant ur paketets `License.txt`, läst 2026-08-28)

CC0 betyder fri användning utan villkor, även kommersiellt, utan
attributionskrav. Vi anger källan ändå.

### Modeller — samma tolv djur i fyra format

| Modell | glTF | FBX | OBJ + MTL | Blend | Till vad |
|---|--:|--:|--:|--:|---|
| **Horse** | 3,61 MB | 3,77 MB | 103 kB | 2,85 MB | **spelarens och lektionshästarnas grundmodell** |
| **Horse_White** | 3,61 MB | 3,77 MB | 103 kB | 2,85 MB | **skimmel — Husky, Kennedy** |
| Donkey | 3,56 MB | 3,77 MB | 94 kB | 2,86 MB | ev. ponny med kortare ben |
| Alpaca | 1,44 MB | 3,41 MB | 97 kB | 2,56 MB | — |
| Bull | 3,11 MB | 3,00 MB | 116 kB | 2,53 MB | — |
| Cow | 3,11 MB | 3,00 MB | 118 kB | 2,53 MB | — |
| Deer | 3,29 MB | 3,41 MB | 99 kB | 2,60 MB | ev. i skogen längs stigen |
| Stag | 3,22 MB | 2,92 MB | 180 kB | 2,32 MB | ev. i skogen längs stigen |
| Fox | 3,16 MB | 3,50 MB | 87 kB | 2,59 MB | — |
| Wolf | 3,18 MB | 3,50 MB | 92 kB | 2,57 MB | — |
| Husky | 3,06 MB | 3,36 MB | 90 kB | 2,51 MB | stallhund på gården |
| ShibaInu | 2,89 MB | 3,15 MB | 92 kB | 2,37 MB | stallhund på gården |

Dessutom: `License.txt` (364 B), `Preview.jpg` (409 kB), `Preview.mp4` (18,5 MB).

**Totalt ≈ 127 MB** fördelat på 48 filer. Ingen enskild fil är över 50 MB, så
Git LFS behövs inte — men FBX, OBJ och Blend är samma modeller i format som
webbversionen aldrig läser. Rekommendation: committa `glTF/`, `License.txt` och
`Preview.jpg` (≈ 38 MB) och lämna resten utanför repot.

### Animationer — ej bekräftade

`Horse.gltf` ska enligt paketets namn vara animerad, men **jag har inte läst
animationsnamnen ur filen** och skriver inte upp dem ur minnet. Så fort filen
ligger i `assets/models/gltf/` läser jag ut dem ur glTF-JSON:ens
`animations[].name` och fyller i tabellen här — särskilt vilka som motsvarar
**stå, skritt, trav och galopp**, som är de fyra spelet behöver.

## Texturer

Inga hämtade. Poly Haven och ambientCG är blockerade härifrån (se nedan).

## Referenser

`references/` är tom. Behövs:

- **Formfacit:** foton på UBRF:s stall och ridhus. De 103 fotona ligger i
  Drive-mappen som `.HEIC` — de behöver konverteras till JPG/PNG för att kunna
  läsas här.
- **Stilfacit:** skärmbilderna från Horse Riding Tales. Jag har sett dem i
  chatten men de finns inte som filer i projektet.

---

## Vad som blockerar

Nätverket i den här miljön går genom en proxy med en tillåtelselista.
Uppmätt 2026-08-28:

| Värd | Utfall |
|---|---|
| `drive.google.com` | **blockerad** — `curl: (56) CONNECT tunnel failed, response 403`; proxyloggen: `connect_rejected: gateway answered 403 to CONNECT (policy denial or upstream failure)` |
| `quaternius.com`, `poly.pizza` | blockerade (ingen anslutning) |
| `polyhaven.com`, `dl.polyhaven.org`, `ambientcg.com` | blockerade |
| `kenney.nl`, `cdn.jsdelivr.net` | blockerade |
| `github.com`, `raw.githubusercontent.com` | **öppna** |

`gdown` finns inte installerat, och skulle ändå fastna på samma 403 — det är
vanlig HTTPS mot `drive.google.com`.

Drive-**connectorn** (MCP) går utanför proxyn och fungerar: den kunde lista
mappen, läsa metadata och hämta `License.txt`. Men den returnerar filinnehåll
som base64 rakt in i konversationen, vilket gör den obrukbar för binärer i den
här storleken — en enda `Horse.gltf` på 3,6 MB blir ~4,8 MB text.

### Två vägar som fungerar

1. **Lägg filerna i repot.** Pusha dem till grenen
   `claude/ridspel-stall-omnejd-zo2zce`, eller lägg dem i arbetskatalogen så
   committar jag. Minst krångel.
2. **Lägg dem på GitHub.** `raw.githubusercontent.com` är öppet härifrån, så
   ett repo eller en release-fil går att hämta direkt med `curl`.

Säg vilken du väljer, så fortsätter jag med inventeringen av animationerna och
går vidare till steg 3.
