# Roblox Creator Store — fria modeller i UBRF

Registrerat 2026-09-14 (EQUIPMENT & RIDER GEAR GATE, #165). Alla poster
mättes mot Roblox egna API:er samma dag:

- `https://economy.roblox.com/v2/assets/<id>/details` → `IsPublicDomain`, `IsForSale`, skapare
- `https://apis.roblox.com/toolbox-service/v1/items/details?assetIds=…` → nät, skript, `fiatProduct.isFree`

Fria modeller i Creator Store får användas i egna Roblox-upplevelser enligt
Roblox Terms of Use / Creator Store-villkoren. Roblox kräver ingen
attribution; en skapare kan ändå be om kredit i titel eller beskrivning, och
då följer vi den.

| Asset | Namn | Skapare | Fri | Skript | Trianglar | Beslut i #165 | Kredit |
|---:|---|---|---|---:|---:|---|---|
| 9639407836 | Race horse saddle and Saddle pad | Josijosi00 | ja (IsPublicDomain) | 0 | 24 540 | antagen som runtime-kandidat (sadel) | — |
| 15966015286 | Horse bridle [ALWAYS CREDIT RHS FOR IT!] | corvyyn | ja | 0 | 1 794 | antagen som runtime-kandidat (träns) | **"Horse bridle" av corvyyn — credit RHS** (kravet står i titeln; beskrivningen är tom) |
| 123547958 | Moldenhauer Family Helmet | skitzochase | ja | **1** | 2 424 | **avvisad**: oinspekterbart skript (assetdelivery kräver inloggning) | — |
| 2780160044 | horse jump # | horsegirlltu | ja | 0 | 888 | rekommenderad för Studio-QA, inte integrerad | — |
| 2314446954 | (RC) Horse Jumps | sillyAuraa | ja | 0 | 792 | andrahandsval, inte integrerad | — |
| 174424237 | SAFE horse jumps | officialgrace | ja | 0 | 7 680 | avvisad tills vidare (tung) | — |
| 8941934960 | Horse Jump | Hoffroc | ja | 0 | — | avvisad tills vidare (ingen nätsummering) | — |

Krediten för tränset ska stå i spelets kreditlista. Källan i kod är
`roblox/src/shared/HorseCore/Utrustning.luau` (`Utrustning.attributioner()`).
Ändras ett beslut ändras det där och här, inte på ett tredje ställe.
