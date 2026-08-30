# Utrymningsplaner — auktoritativ källa för planform och layout

Fotograferade utrymningsplaner från anläggningen, **Presto AB, 2025-10-11**.

Enligt `docs/GATE-F01-UBRF-FIDELITY.md` och issue #21 är de här planerna
**auktoritativa för byggnadsmodell och rumslig layout**: fotavtryck, planform, hur
volymer sitter ihop, korridorer och gångar, entréer, trappor, rumssamband och
placering av funktionsytor. Fotona i `references/buildings/` är auktoritativa för
det visuella — material, färg, konstruktion, inredning, skyltar.

Vid konflikt: **planen vinner för geometri, fotot vinner för utseende.** Går det
inte att avgöra ur någondera blir det `REFERENCE GAP` — ingen kompromiss hittas på.

| Fil | Vad | Lagd i repot |
|---|---|---|
| `ridhus-entreplan-utrymning.jpg` | "Upplands-Bro kommun Ridhus, Husbyvägen 1, Bro — Entréplan" | 2026-08-30 |
| `stall-plan1-utrymning.jpg` | Stallet, "Plan 1" (och en bit av Plan 2) | 2026-08-30 |
| `derivat-situationsplan-ridhus.jpg` | Uppförstorad beskärning av ridhusplanens SITUATIONSPLAN | derivat |
| `derivat-stall-tvarsnitt.jpg` | Uppförstorat tvärsnitt genom stallets boxområde | derivat |

Före 2026-08-30 fanns planerna bara i Google Drive. Allt som byggdes mot dem
byggdes då mot prosa i byggnadskorten, inte mot planen själv — vilket ChatGPT:s
Senior Fidelity Review 01 med rätta underkände.

## Vad som är mätt i dem

### Stallet, Plan 1

Ett lodrätt tvärsnitt genom boxområdet vid tre olika x-lägen ger samma sex band i
samma ordning, med samma inbördes andelar:

| Band | px | Andel av bredden |
|---|---|---|
| boxrad (yttervägg V) | 169 | 20,9 % |
| **gång A** | 100 | 12,4 % |
| boxrad (mitt) | 144 | 17,8 % |
| boxrad (mitt) | 142 | 17,6 % |
| **gång B** | 99 | 12,3 % |
| boxrad (yttervägg Ö) | 153 | 19,0 % |

De två mittersta raderna står rygg mot rygg mot en gemensam spine, som bär
regelbundna ⊞-märken — vattenkoppar eller foderluckor.

**Andelarna är `VERIFIED`.** De är oberoende av skala och lika i alla tre snitten.
Det viktigaste de säger: **gångarna är smalare än boxarna är djupa, ungefär två
tredjedelar.** Spelet antog tidigare att alla sex banden var lika breda.

Boxarna: ungefär **13 fack per länga**, jämnt delade, med dörrslag ut mot
respektive gång.

### Ridhuset, Entréplan

Byggnaden mäter 2203 × ~720 px, alltså **3,06:1**. Kortets 25 × 75 m ger 3,00:1 —
planen bekräftar proportionen inom två procent.

### Situationsplanen

Båda planerna bär samma lilla SITUATIONSPLAN, och den är den enda källa i repot som
visar **båda byggnaderna i samma bild**. Se `REFERENCE-GAP.md` i den här mappen för
vad den säger och vad den inte kan avgöra.
