# PR #162 — avbruten laddning och rena reviewbilder

Tobias godkände denna avgränsade rättelse i chatten 2026-09-10. ChatGPT
implementerar rättelsen; den innebär inte oberoende slutreview eller produktacceptans.

- Goal: en spelare som lämnat får inte återaktiveras av ett sent laddningssvar.
- Observed: på `164c6be` återreserverades Jack efter PlayerRemoving medan GetAsync väntade.
- Source: SparService, StallService, GameplayService och VISUAL-FIDELITY-GATE.
- Required: ogiltigförklara laddningen vid utloggning före eventuell sparning;
  ignorera sena resultat och hooks; dölj uppdragsmarkören endast i bildverktyget.
- Out of scope: sparschema, hästregler, geometri, gameplay-HUD och main-merge.
- Acceptance: yieldande läsning → utloggning → sent svar får varken publicera
  save/redo eller reservera häst; ny spelare kan få Jack. Befintliga 17 specar
  ska fortsätta passera. Screenshot-paketet kontrollerar dold HUD per kamera.
- Human gate: oberoende review, rena bilder och tidigare Studio/enhetsprov kvarstår.
- Uncertainty: deterministisk Luau-bänk; ingen live DataStore/Studio-verifiering.

## Lokal evidens

- `bash roblox/tests/kor.sh`: 17/17 gröna, före och efter falsifiering.
- Mutation i genererad testkopia: sessionskontrollen returnerar alltid true.
  Fyra röda kontroller, exit 1: save, redo, reservation och nästa spelares Jack.
  Produktionskoden muterades inte; testkopian regenererades därefter.
- `python3 tools/build.py` och `git diff --check`: exit 0.
- Screenshot-verktyget döljer `#ubrfVagvisare` med övrig HUD och stoppar
  om någon av dessa ytor fortfarande syns vid en reviewkamera.
- Inget live DataStore-, Studio-, fysisk touch- eller game-feel-PASS.
- Status: IMPLEMENTED; oberoende review och exakt-head bildpaket kvarstår.
