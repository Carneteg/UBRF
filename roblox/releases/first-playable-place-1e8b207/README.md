# First Playable-place — källhead `1e8b207`

> ## ⛔ INTE SANKTIONERAD FÖR TOBIAS
>
> Filen är **byggd och mätt**, inte godkänd. Runtime-QA i Roblox Studio är
> inte körd på den här kandidaten, och den miljö som byggde den kan inte
> köra den: ingen `robloxstudio` MCP, inget Windows-filsystem.
>
> | | Krav | Läge |
> |---|---|---|
> | Studio-MCP runtime-QA | `docs/STUDIO-RUNTIME-QA.md` §0–§10 på exakt den här filen | **inte gjord** |
> | § 6 utrustningen (NY) | sadeln och tränset hämtade fysiskt, alla fem nejen | **inte gjord** |
> | § 9 `ride` | kvitterat kort → verklig förflyttning | **inte gjord på den här filen** |
>
> `LATEST-FIRST-PLAYABLE.md` är därför **orörd**. Den här mappen är ett
> mätunderlag för `PRE_TOBIAS_FIRST_PLAYABLE_GATE --place`, ingenting annat.

## Identitet

| | |
|---|---|
| källhead (source SHA) | `1e8b20755d2d543dad2433fbb105f3dd4b236585` |
| gren | `claude/first-playable-20260910`, bas `main` |
| fil | `UBRFFirstPlayable.rbxlx` |
| SHA256 | `db3d7577e0880d2824b699b25874a0cc99690f29a2a28d3eb9f0d2f525082381` |
| storlek | 902 019 byte |
| instanser | 64 |
| bakad `ReplicatedStorage/UBRFBuild.sha` | `1e8b20755d2d543dad2433fbb105f3dd4b236585` |

**Källheaden är den commit som BYGGDE filen** — inte den som mätte den, och
inte grenens spets. Det är den SHA Studio skriver i Output som
`FIRST_PLAYABLE_SHA`.

Determinism: ombyggd ur samma källa, **byte-identisk**.

`PRE_TOBIAS_FIRST_PLAYABLE_GATE --place` mot exakt den här filen: **PASS**,
tio undergrindar, världsmanifestet oförändrat mot föregående artefakt
(3317 delar, 13 portaler, 33 hästar).

> `qa/pre-tobias/RAPPORT.md` skriver `source SHA: e907e3ce…`. Det är headen
> som **mätte** filen, inte den som byggde den — rapporten stämplar sitt eget
> körläge. Talet som ska matcha Studios `FIRST_PLAYABLE_SHA` är `1e8b2075…`
> i tabellen ovan.

## Varför den här finns — den blockerande produktluckan 16:21

Utrustningssteget var ett **abstrakt tillståndsbyte**. `GameplayService.
moment` prövade att spelaren stod vid rätt häst, men ingenting krävde att
hon hade hämtat en sadel — och det fanns ingen sadel att hämta. Man tryckte
på en HUD-rad och var sadlad. Ansvaret kring hästen var dekoration, inte
gameplay.

Två nya instanser i placen (62 → 64) bär hela ändringen:
`src/server/UtrustningRigg.luau` och `src/client/UtrustningController.luau`.

| Ordens punkt | Hur den är byggd |
|---|---|
| 1. HUD:en ska peka | hjälpraden byter till *"Sadeln hänger på boxfronten där … står — hämta den."* så fort fasen kräver saken, och redovisar vad spelaren redan bär |
| 2. finnas fysiskt på källstyrd plats | 66 modeller i `workspace.Utrustning`, en sadel med underlägg och ett träns per häst, på hennes egen boxfront |
| 3. gå att hämta och bära tillbaka | prompt **Ta med dig**, saken sitter synligt på avataren tills den är på hästen |
| 4. inte kunna kvitteras med en knapp | sadelstegen kräver att sadeln bärs, ledandet att tränset bärs — prövat av `Preparation`, inte av HUD:en |
| 5. negativa fall | fel häst, inte hämtad, bara sadel utan träns, för långt bort, dubbel interaktion, fel sorts föremål — alla mätta i `roblox/tests/utrustning.spec.luau` |
| 6. runtime-QA utan utvecklarkunskap | körlistan står i `docs/STUDIO-RUNTIME-QA.md` § 6 |
| 7. ny källhead, ny mapp, ny SHA256 | den här mappen; `…-9b5a570` ligger kvar orörd |

## PLATSEN ÄR BOXFRONTEN, INTE SADELKAMMAREN — och det är ett källbeslut

Ordern pekade mot sadelkammaren. Den enda verifierade platsen i UBRF där
sadlar och träns finns är en annan:

> `references/buildings/stall/KORT.md` § Boxarna från gången:
> *"På fronterna hänger sadlar med underlag, täcken, grimmor, träns och
> benskydd — mycket saker, tätt."* `[ej byggt i spelet ännu]`

Sadelkammarens egen bild (`stall-inne-03-sadelkammaren.jpg`) visar
uttryckligen **inga sadelbockar** — säkerhetsvästar på krokrader och en
hylla med ridstövlar — och `docs/F02-B-INREDNINGSMATRIS.md` har redan fällt
sadlar där som `REFERENCE GAP`: *"sadlar, träns och övrig utrustning … syns
inte i bilden och byggs inte"*.

Att ställa sadelbockar i sadelkammaren hade alltså varit att hitta på en
UBRF-detalj för att fylla ett hål, vilket ordern själv förbjuder
(*"Inga påhittade placeringar som bryter UBRF-fidelity; använd befintlig
källstyrd utrustningsplats"*). Boxfronten ÄR den källstyrda platsen.
Sadelkammarens inredning står kvar oförändrad.

**Om Tobias vill ha sadelkammaren i stället** är det ett produktbeslut som
kräver ny referensevidens för hur UBRF förvarar sadlar där — inte en
kodändring.

## Tidigare artefakter i kedjan

`…-9b5a570` (SHA256 `9f308f7a…`) bar den förklarande CTA:n efter
produktbeslutet 13:29 och väntade på lokal runtime. `…-efa341e` föll i §9,
`…-67e7716` i §1, `…-0a1b032` gav de tre fynden §2/§7/§8. Alla ligger kvar
orörda som historik.

## `.gitattributes` — läs det här före nedladdning

Repot märker nu `*.rbxlx` som binärfil. Utan det konverterar
`core.autocrlf=true` radsluten i arbetsträdet på Windows, och då stämmer
inte SHA256 mot den här filen — filen blir inte trasig, men **hashen går
inte att verifiera**, och det var precis vad 13:57-noten varnade för.

Har du redan en utcheckning med `core.autocrlf=true`: kör
`git rm --cached -r . && git reset --hard` eller klona om, annars ligger de
CRLF-konverterade kopiorna kvar tills filerna ändras.
