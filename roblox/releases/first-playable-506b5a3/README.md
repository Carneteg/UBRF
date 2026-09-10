# Miljö- och QA-paket — fast kopia av `506b5a3`

> ## ⚠️ DET HÄR ÄR INTE FIRST PLAYABLE
>
> Filen i den här mappen bygger **anläggningen och QA-panelen**. Den
> innehåller **ingen rad gameplay** — ingen spawn, ingen dörrinteraktion,
> ingen häst, ingen persistens. Den heter så här sedan Tobias upptäckte
> problemet fysiskt i Studio (#162): han spawnade fel och kom inte in genom
> den vita dörren, eftersom det inte fanns någon gameplay i paketet han
> hade fått.
>
> **För den fysiska First Playable-genomgången: använd place-filen** under
> `roblox/releases/first-playable-place-*/`, inte den här. Den här filen är
> kvar för den *visuella* granskningen, som är vad den alltid var bra på.


Den här mappen finns för att den visuella granskningen ska kunna hämta rätt
miljöpaket utan terminal, utan Git och utan risk att råka öppna en gammal
lokal kopia.

`UBRF-klistra-in.luau` här är en **ordagrann, versionerad kopia** av det paket
som `tools/studio-paket.py` genererar. Paketet självt är `.gitignore`-at
(`roblox/buildings/.studio/`) just för att det är en hopfogning av filer som
redan ligger i repot — men då finns det heller ingen fil att ladda ner. Den här
kopian löser precis det, och bara det.

## Vad filen är genererad ur

| | |
|---|---|
| Källkommit (godkänd head) | `506b5a3e42f2364c26a36d6c480af87c65f4bb78` |
| Genereringskommando | `python3 tools/studio-paket.py` |
| SHA256 på filen | `59af183132407f6bbce48ff78673bee4e06940dd3714840a302dd12ffdbe624c` |
| Storlek | 8 269 rader, 244 KB |

`506b5a3` är den head ChatGPT gav `CHATGPT_VISUAL_PASS` på för de tre
ridhusvyerna (issue #162, runda 7). Kopian är pinnad till den — **regenerera
inte filen på plats**. Ska ett nytt läge ut till Studio läggs det i en ny mapp
med den nya SHA:n i namnet, så att en gammal och en ny fil aldrig kan förväxlas.

### Att kopian verkligen motsvarar `506b5a3`

Paketet fogas ihop ur `roblox/buildings/{BuildKit,Geometri,UBRFKomplex,Vyer,QAPanel,Anlaggningen}.luau`
och ingenting annat. Mellan `506b5a3` och den head kopian committades på skiljer
sig bara `qa/visual-gate/kameror.json`, som generatorn inte läser. Kontrollerat
genom att generera paketet i en ren checkout av `506b5a3` och jämföra: samma
SHA256, byte för byte identiska filer.

Vill du kontrollera själv:

```
sha256sum UBRF-klistra-in.luau
# ska ge 59af183132407f6bbce48ff78673bee4e06940dd3714840a302dd12ffdbe624c
```

## Hämta och kör — tre steg

Direktlänkarna (pinnade till committen som la in filen, `44ccf04` — de slutar
aldrig fungera och kan inte peka på en nyare eller äldre version):

- **Raw, klicka och kopiera allt:**
  <https://raw.githubusercontent.com/Carneteg/UBRF/44ccf047de36b950aa787818f08e8e25f94296f6/roblox/releases/first-playable-506b5a3/UBRF-klistra-in.luau>
- Filen i GitHubs vanliga vy:
  <https://github.com/Carneteg/UBRF/blob/44ccf047de36b950aa787818f08e8e25f94296f6/roblox/releases/first-playable-506b5a3/UBRF-klistra-in.luau>

**404 betyder nästan alltid `main`.** Filen ligger bara på branchen
`claude/first-playable-20260910` tills PR #162 är mergad. En URL med `/main/` i
sig ger 404 — använd länkarna ovan, som pekar på en commit och inte på en
gren.

1. **Öppna Raw-länken.** (Raw-vyn är ren text utan radnummer.)
2. **Markera allt och kopiera** — `Ctrl/Cmd + A`, `Ctrl/Cmd + C`.
3. **Klistra in i Roblox Studio och kör en gång.**

Om steg 3: filen är 244 KB, och Studios **Command Bar** är ett enradsfält som
inte tar emot så mycket text. Den väg som repots egen dokumentation anger
(`roblox/buildings/STUDIO-KONTROLL.md`) och som gäller här är:

- skapa en **Script** i `ServerScriptService`, klistra in hela filen, tryck
  **Run** — kör en gång, ta sedan bort scriptet.

Command Bar används däremot för `UBRFQA()`, som öppnar QA-panelen igen om du
stängt den.

> **Not tested:** ingen agent i den här sessionen har Studio-åtkomst, så
> inklistringen och Run-steget är inte provkörda i Studio. Vad som *är* provat
> är att paketet kör igenom utan runtime-fel headless mot byggbänkens stubbar
> (`python3 tools/kor-paket.py` → *"Paketet kör utan runtime-fel"*) och att
> geometri- och materialgrindarna i generatorn passerar.

## Vad som händer när den körts

QA-panelen öppnar sig själv i Studio: **Nästa → titta → PASS eller FEL**.
Kvitteringen sker i `roblox/docs/STUDIO-QA.md`, som är den kanoniska QA-listan.

De fyra ridhusvyerna arbetsordern pekar ut finns i paketet med runda 7:s
korrigerade lägen:

| Vy | Kameraläge (lokala meter i ridhuset) |
|---|---|
| `RIDHUS-ENTRE` | från 3,9 / 68,9 h 1,65 → mot 2,4 / 74,2 |
| `RIDHUS-RECEPTION` | från 3,95 / 70,6 h 1,6 → mot 2,5 / 74,6 |
| `RIDHUS-SKAPKORRIDOR` | från 3,3 / 71,8 h 1,65 → mot 3,2 / 77,0 |
| `RIDHUS-KLUBBGANG` | från 3,35 / 76,3 h 1,6 → mot 3,3 / 70,5 |

Motiveringen till varje läge — de mätta vinklarna mot receptionens glasfront —
står i `qa/visual-gate/kameror.json` och i kommentarerna i
`roblox/buildings/Vyer.luau`.
