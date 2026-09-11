#!/usr/bin/env python3
"""Fogar ihop en körbar testfil av stubbar + produktionskod.

luau-CLI:t sandboxar varje modul: globaler som sätts i en fil syns inte i en
require:ad fil. Roblox-stubbarna måste alltså ligga i samma miljö som koden de
stubbar. Lösningen är densamma som tools/build.py använder för JS-spåret —
foga ihop till en fil — med skillnaden att produktionskoden inlinas ORDAGRANT.
Varje modul blir en `local X = (function() ... end)()` och dess require-rader
byts mot namnen på de moduler som redan laddats.

Kör: python3 roblox/tests/build.py && luau roblox/tests/.build/movement.luau
"""
import re, sys, pathlib

ROT = pathlib.Path(__file__).resolve().parent.parent      # roblox/
UT = ROT / "tests" / ".build"

# Ordningen är beroendeordningen: en modul får bara referera det som står över.
#
# Geometrispecen mäter en annan del av spåret — anläggningen, inte hästen — och
# behöver därför inte hästsystemets moduler. Den får sin egen lista; att foga
# ihop hela hästsystemet för att kontrollera var en dörr sitter vore bara
# långsamt och skulle koppla ihop två spår som inte har med varandra att göra.
GEOMETRI = [
    ("Geometri",    "buildings/Geometri.luau"),
    ("UBRFKomplex", "buildings/UBRFKomplex.luau"),
]

# Byggbänken kör själva byggskriptet. Anlaggningen.luau är inte en modul utan
# ett skript som körs för sin verkan, så det inlinas sist och returnerar inget.
BYGGE = GEOMETRI + [
    ("BuildKit",     "buildings/BuildKit.luau"),
    ("Anlaggningen", "buildings/Anlaggningen.luau"),
]

#[[ Spelbarhetsbanken: varlden, dorrtjansten OCH speldatan, sa att den
#   gangbara kedjan spawn -> dorr -> Jacks box kan matas i EN korning.
#   Det ar den grind som saknades nar Tobias fick hitta felen fysiskt. ]]
SPELBARHET = None  # satts efter SPEL, se nedan

#[[ First Playable-bänken: varlden PLUS dorrtjansten, sa att spawn- och
#   dorrkontraktet ur #162 kan matas i samma korning som bygget. Det ar
#   den enda vagen att fa evidens for att dorren oppnas utan Studio. ]]
FORSTAPLAYABLE = BYGGE + [
    #[[ Sprakuppslaget: DorrService laser promptens svenska standardtext ur
    #   katalogen sa att texten och nyckeln inte kan glida isar. Bada maste
    #   darfor ligga FORE tjansten i bunten. ]]
    ("UBRFSprak",   "game/UBRFSprak.luau"),
    ("Sprak",       "src/shared/HorseCore/Sprak.luau"),
    ("DorrService", "src/server/DorrService.luau"),
]

# Speldatan: hästdata och skötseldata genereras var för sig. UBRFSpel är den
# tunna runtime-fasaden som fogar ihop dem innan Stallet läser kontraktet.
SPEL = GEOMETRI + [
    # RidKanon ar ren data utan beroenden och ligger med sa att
    # spelkanon.spec kan korsprova hastarnas `profil` mot de profiler som
    # faktiskt finns (G02-B punkt 3). Ett profilnamn i hastdatan som inte
    # finns i kanonen ar en tyst degradering till utgangslaget.
    ("RidKanon",     "src/shared/HorseCore/RidKanon.luau"),
    ("UBRFSpelData", "game/UBRFSpelData.luau"),
    ("UBRFSkotsel",  "game/UBRFSkotsel.luau"),
    ("UBRFSpel",     "game/UBRFSpel.luau"),
    ("Stallet",      "game/Stallet.luau"),
    #[[ SPRAKET (#162): den genererade texttabellen och uppslaget. Ligger i
    #   SPEL sa att varje bank som ritar nagot spelaren LASER far dem med;
    #   Sprak.luau require:ar UBRFSprak och maste darfor sta efter den. ]]
    ("UBRFSprak",    "game/UBRFSprak.luau"),
    ("Sprak",        "src/shared/HorseCore/Sprak.luau"),
]

SPELBARHET = BYGGE + [
    ("RidKanon",     "src/shared/HorseCore/RidKanon.luau"),
    ("UBRFSpelData", "game/UBRFSpelData.luau"),
    ("UBRFSkotsel",  "game/UBRFSkotsel.luau"),
    ("UBRFSpel",     "game/UBRFSpel.luau"),
    ("Stallet",      "game/Stallet.luau"),
    ("UBRFSprak",    "game/UBRFSprak.luau"),
    ("Sprak",        "src/shared/HorseCore/Sprak.luau"),
    ("DorrService",  "src/server/DorrService.luau"),
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("HastRigg",     "src/server/HastRigg.luau"),
    #[[ TESTMODUL, inte produktionskod: avatarens matt och
    #   konfigurationsrymden pa ETT stalle. Tva specar mater samma spelare
    #   och far inte ha var sin kopia av hennes matt. ]]
    ("Varldsmatning", "tests/varldsmatning.luau"),
    #[[ Preflighten matas pa den BYGGDA varlden: en ren UBRF ska passera
    #   markplansgrinden, och en kvarglomd baseplate ska falla den. Utan
    #   varlden hade specen bara kunnat prova den tomma vagen. ]]
    ("Preflight",    "src/server/Preflight.luau"),
]

# QA-panelen provas ovanpa hela bygget: den behover en fardigbyggd anlaggning
# att stalla kameran mot, och Vyer for att veta vilka vyerna ar.
QA = BYGGE + [
    ("Vyer",    "buildings/Vyer.luau"),
    ("QAPanel", "buildings/QAPanel.luau"),
]

# Siktgrinden (issue #78) provar de fasta reviewkamerorna i Vyer mot det
# byggda och behover klientens Genomsikt-regel for att veta vad som tonas.
SIKT = QA + [
    ("Genomsikt", "src/client/Genomsikt.luau"),
]

# Forberedelsen provas ovanpa speldatan: reglerna laser fasordningen ur den
# exporterade skotseln, och reservationen ligger i Stallet. Hastsystemets
# rorelsemoduler behovs inte -- Preparation ror dem inte.
# HorseService ar med for att uppsittningsgrindens INKOPPLING ska ga att prova,
# inte bara dess regel: specen registrerar en grind och kor riktiga tryMount.
# Config/Gaits/RigAdapter maste ligga fore, de fylls in i __Core i den ordningen.
FORBEREDELSE = SPEL + [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    # HorseService rakner numera energin med G02-B:s kanon (blocker 3),
    # och laser den tilldelade hastens profil (blocker 1).
    ("Hjalper",      "src/shared/HorseCore/Hjalper.luau"),
    ("Svar",         "src/shared/HorseCore/Svar.luau"),
    ("Preparation",  "src/shared/HorseCore/Preparation.luau"),
    # #161: skotselns moment, passets eftervard och sparschemat. Rena
    # datamoduler; de ligger fore tjansterna for att SparService require:ar
    # Sparning och GameplayService require:ar bada.
    ("Pass",         "src/shared/HorseCore/Pass.luau"),
    ("Sparning",     "src/shared/HorseCore/Sparning.luau"),
    ("Networking",   "src/shared/HorseCore/Networking.luau"),
    ("HorseService", "src/server/HorseService.luau"),
    # SparService FORE StallService: StallService.hastminnen laser saven ur
    # den. Ordningen ar samma som init.server.luau har.
    ("SparService",  "src/server/SparService.luau"),
    ("StallService", "src/server/StallService.luau"),
    # Klientsidan: prompt-beslutet (krav 8) provas har, inte i en lokal funktion.
    ("InteractionController", "src/client/InteractionController.luau"),
    ("PreparationController", "src/client/PreparationController.luau"),
    # StateMachine + MovementController ligger med sedan blocker 2 i senior
    # re-review av #87: cross-platform-scenariot spelas upp genom en RIKTIG
    # controller med den hast Stallet faktiskt delar ut, inte genom
    # direktanrop av svarsmodellen.
    ("Telemetri",    "src/shared/HorseCore/Telemetri.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    ("MovementController", "src/client/MovementController.luau"),
    # GameplayService laddas SIST och ar poangen med hela listan: utan den
    # bevisade specen bara att HorseService-kroken fungerar, inte att
    # produktionen faktiskt registrerar GameplayService.farSittaUpp i den.
    #[[ LedService laddas FORE GameplayService: den senare require:ar
    #   den, och grinden pa "leda" ar hela poangen med blockerare 2. ]]
    ("LedService",     "src/server/LedService.luau"),
    ("GameplayService", "src/server/GameplayService.luau"),
]

#[[ INTEGRATIONSBANKEN (#162, END_TO_END punkt 7-11).
#
#   Skillnaden mot FORBEREDELSE ar VAD kedjan mats MOT: har byggs den
#   RIKTIGA riggen ur HastRigg, med en riktig Seat, och skotseln,
#   uppsittningen, doden, respawnen och passet gar genom tjansterna mot
#   just den modellen. Forberedelsebanken matte reglerna; den har mater
#   att spelaren kan ga igenom dagen. ]]
INTEGRATION = FORBEREDELSE + [
    ("HastRigg",        "src/server/HastRigg.luau"),
    #[[ Sadeln och transet pa boxfronten: samma byggare produktionen
    #   startar, sa attributen i provet ar produktionens attribut. ]]
    ("UtrustningRigg",  "src/server/UtrustningRigg.luau"),
    ("RiderController", "src/client/RiderController.luau"),
]

# QA-panelen provas ovanpa hela bygget: den behover en fardigbyggd anlaggning
# att stalla kameran mot, och Vyer for att veta vilka vyerna ar.
QA = BYGGE + [
    ("Vyer",    "buildings/Vyer.luau"),
    ("QAPanel", "buildings/QAPanel.luau"),
]

# Siktgrinden (issue #78) provar de fasta reviewkamerorna i Vyer mot det
# byggda och behover klientens Genomsikt-regel for att veta vad som tonas.
SIKT = QA + [
    ("Genomsikt", "src/client/Genomsikt.luau"),
]

# Forberedelsen provas ovanpa speldatan: reglerna laser fasordningen ur den
# exporterade skotseln, och reservationen ligger i Stallet. Hastsystemets
# rorelsemoduler behovs inte -- Preparation ror dem inte.
# HorseService ar med for att uppsittningsgrindens INKOPPLING ska ga att prova,
# inte bara dess regel: specen registrerar en grind och kor riktiga tryMount.
# Config/Gaits/RigAdapter maste ligga fore, de fylls in i __Core i den ordningen.
FORBEREDELSE = SPEL + [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    # HorseService rakner numera energin med G02-B:s kanon (blocker 3),
    # och laser den tilldelade hastens profil (blocker 1).
    ("Hjalper",      "src/shared/HorseCore/Hjalper.luau"),
    ("Svar",         "src/shared/HorseCore/Svar.luau"),
    ("Preparation",  "src/shared/HorseCore/Preparation.luau"),
    # #161: skotselns moment, passets eftervard och sparschemat. Rena
    # datamoduler; de ligger fore tjansterna for att SparService require:ar
    # Sparning och GameplayService require:ar bada.
    ("Pass",         "src/shared/HorseCore/Pass.luau"),
    ("Sparning",     "src/shared/HorseCore/Sparning.luau"),
    ("Networking",   "src/shared/HorseCore/Networking.luau"),
    ("HorseService", "src/server/HorseService.luau"),
    # SparService FORE StallService: StallService.hastminnen laser saven ur
    # den. Ordningen ar samma som init.server.luau har.
    ("SparService",  "src/server/SparService.luau"),
    ("StallService", "src/server/StallService.luau"),
    # Klientsidan: prompt-beslutet (krav 8) provas har, inte i en lokal funktion.
    ("InteractionController", "src/client/InteractionController.luau"),
    ("PreparationController", "src/client/PreparationController.luau"),
    # StateMachine + MovementController ligger med sedan blocker 2 i senior
    # re-review av #87: cross-platform-scenariot spelas upp genom en RIKTIG
    # controller med den hast Stallet faktiskt delar ut, inte genom
    # direktanrop av svarsmodellen.
    ("Telemetri",    "src/shared/HorseCore/Telemetri.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    ("MovementController", "src/client/MovementController.luau"),
    # GameplayService laddas SIST och ar poangen med hela listan: utan den
    # bevisade specen bara att HorseService-kroken fungerar, inte att
    # produktionen faktiskt registrerar GameplayService.farSittaUpp i den.
    #[[ LedService laddas FORE GameplayService: den senare require:ar
    #   den, och grinden pa "leda" ar hela poangen med blockerare 2. ]]
    ("LedService",     "src/server/LedService.luau"),
    ("GameplayService", "src/server/GameplayService.luau"),
]

#[[ INTEGRATIONSBANKEN (#162, END_TO_END punkt 7-11).
#
#   Skillnaden mot FORBEREDELSE ar VAD kedjan mats MOT: har byggs den
#   RIKTIGA riggen ur HastRigg, med en riktig Seat, och skotseln,
#   uppsittningen, doden, respawnen och passet gar genom tjansterna mot
#   just den modellen. Forberedelsebanken matte reglerna; den har mater
#   att spelaren kan ga igenom dagen. ]]
INTEGRATION = FORBEREDELSE + [
    ("HastRigg",        "src/server/HastRigg.luau"),
    #[[ Sadeln och transet pa boxfronten: samma byggare produktionen
    #   startar, sa attributen i provet ar produktionens attribut. ]]
    ("UtrustningRigg",  "src/server/UtrustningRigg.luau"),
    ("RiderController", "src/client/RiderController.luau"),
]


# QA-panelen provas ovanpa hela bygget: den behover en fardigbyggd anlaggning
# att stalla kameran mot, och Vyer for att veta vilka vyerna ar.
QA = BYGGE + [
    ("Vyer",    "buildings/Vyer.luau"),
    ("QAPanel", "buildings/QAPanel.luau"),
]

# Siktgrinden (issue #78) provar de fasta reviewkamerorna i Vyer mot det
# byggda och behover klientens Genomsikt-regel for att veta vad som tonas.
SIKT = QA + [
    ("Genomsikt", "src/client/Genomsikt.luau"),
]

# Forberedelsen provas ovanpa speldatan: reglerna laser fasordningen ur den
# exporterade skotseln, och reservationen ligger i Stallet. Hastsystemets
# rorelsemoduler behovs inte -- Preparation ror dem inte.
# HorseService ar med for att uppsittningsgrindens INKOPPLING ska ga att prova,
# inte bara dess regel: specen registrerar en grind och kor riktiga tryMount.
# Config/Gaits/RigAdapter maste ligga fore, de fylls in i __Core i den ordningen.
FORBEREDELSE = SPEL + [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    # HorseService rakner numera energin med G02-B:s kanon (blocker 3),
    # och laser den tilldelade hastens profil (blocker 1).
    ("Hjalper",      "src/shared/HorseCore/Hjalper.luau"),
    ("Svar",         "src/shared/HorseCore/Svar.luau"),
    ("Preparation",  "src/shared/HorseCore/Preparation.luau"),
    # #161: skotselns moment, passets eftervard och sparschemat. Rena
    # datamoduler; de ligger fore tjansterna for att SparService require:ar
    # Sparning och GameplayService require:ar bada.
    ("Pass",         "src/shared/HorseCore/Pass.luau"),
    ("Sparning",     "src/shared/HorseCore/Sparning.luau"),
    ("Networking",   "src/shared/HorseCore/Networking.luau"),
    ("HorseService", "src/server/HorseService.luau"),
    # SparService FORE StallService: StallService.hastminnen laser saven ur
    # den. Ordningen ar samma som init.server.luau har.
    ("SparService",  "src/server/SparService.luau"),
    ("StallService", "src/server/StallService.luau"),
    # Klientsidan: prompt-beslutet (krav 8) provas har, inte i en lokal funktion.
    ("InteractionController", "src/client/InteractionController.luau"),
    ("PreparationController", "src/client/PreparationController.luau"),
    # StateMachine + MovementController ligger med sedan blocker 2 i senior
    # re-review av #87: cross-platform-scenariot spelas upp genom en RIKTIG
    # controller med den hast Stallet faktiskt delar ut, inte genom
    # direktanrop av svarsmodellen.
    ("Telemetri",    "src/shared/HorseCore/Telemetri.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    ("MovementController", "src/client/MovementController.luau"),
    # GameplayService laddas SIST och ar poangen med hela listan: utan den
    # bevisade specen bara att HorseService-kroken fungerar, inte att
    # produktionen faktiskt registrerar GameplayService.farSittaUpp i den.
    #[[ LedService laddas FORE GameplayService: den senare require:ar
    #   den, och grinden pa "leda" ar hela poangen med blockerare 2. ]]
    ("LedService",     "src/server/LedService.luau"),
    ("GameplayService", "src/server/GameplayService.luau"),
]

#[[ INTEGRATIONSBANKEN (#162, END_TO_END punkt 7-11).
#
#   Skillnaden mot FORBEREDELSE ar VAD kedjan mats MOT: har byggs den
#   RIKTIGA riggen ur HastRigg, med en riktig Seat, och skotseln,
#   uppsittningen, doden, respawnen och passet gar genom tjansterna mot
#   just den modellen. Forberedelsebanken matte reglerna; den har mater
#   att spelaren kan ga igenom dagen. ]]
INTEGRATION = FORBEREDELSE + [
    ("HastRigg",        "src/server/HastRigg.luau"),
    #[[ Sadeln och transet pa boxfronten: samma byggare produktionen
    #   startar, sa attributen i provet ar produktionens attribut. ]]
    ("UtrustningRigg",  "src/server/UtrustningRigg.luau"),
    ("RiderController", "src/client/RiderController.luau"),
]


# Paritetsspecen jamfor Roblox gangarter och telemetri mot webbens
# exporterade ridkanon. Den behover ingen rorelsemodul: den mater kontrakt,
# inte fysik.
PARITET = [
    #[[ SPRAKET forst: UgnetaController ritar lararkortets text och laser
    #   Sprak, som i sin tur require:ar den genererade texttabellen. ]]
    ("UBRFSprak",  "game/UBRFSprak.luau"),
    ("Sprak",      "src/shared/HorseCore/Sprak.luau"),
    ("Types",      "src/shared/HorseCore/Types.luau"),
    ("Config",     "src/shared/HorseCore/Config.luau"),
    ("Gaits",      "src/shared/HorseCore/Gaits.luau"),
    ("RidKanon",   "src/shared/HorseCore/RidKanon.luau"),
    ("Hjalper",    "src/shared/HorseCore/Hjalper.luau"),
    ("Svar",       "src/shared/HorseCore/Svar.luau"),
    ("Telemetri",  "src/shared/HorseCore/Telemetri.luau"),
    # G02-C: Ugnetas bedomningskontrakt lases ur RidKanon.UGNETA.
    ("Ugneta",     "src/shared/HorseCore/Ugneta.luau"),
    # Lektionens lifecycle: mater, avgor forsok 1 -> 2, valjer live-cue.
    ("Lektion",    "src/shared/HorseCore/Lektion.luau"),
    # G02-D: inspelningen och analysen. BADA maste ligga fore
    # LektionController -- den require:ar dem bagge. Ligger de bara i EN av
    # listorna blir require:t nil i den andra bunten, och det syns forst som
    # "attempt to index nil with 'aktiv'" ur RenderStepped-loopen, alltsa
    # langt ifran orsaken. Precis sa foll klient-specen i CI (run 34186458506);
    # darfor star de nu i BADA listorna, i beroendeordning.
    ("Inspelning",       "src/shared/HorseCore/Inspelning.luau"),
    # ... och larar-UX:en pa Roblox provas mot samma kontrakt.
    ("UgnetaController", "src/client/UgnetaController.luau"),
    ("UgnetaGestalt",    "src/client/UgnetaGestalt.luau"),
    ("ReplayController", "src/client/ReplayController.luau"),
    # Kedjan som binder ihop dem. Utan den var HUD:en bara anropbar.
    ("LektionController", "src/client/LektionController.luau"),
]

# Ugnetas GESTALT provas ovanpa det FARDIGBYGGDA huset: hon placeras genom att
# mata mellan "Ridbanan" och "Sarg syd", alltsa mot delar som faktiskt star i
# workspace. Ett prov mot handskrivna koordinater hade mott en andra modell av
# huset, vilket ar precis det placeringen undviker.
GESTALT = BYGGE + [
    ("RidKanon",      "src/shared/HorseCore/RidKanon.luau"),
    ("UgnetaGestalt", "src/client/UgnetaGestalt.luau"),
]

# KLIENTBANKEN kor init.client.luau pa riktigt. Det ar skillnaden mellan att
# prova att en modul GAR att anropa och att prova att spelaren far det den gor:
# lektionen stegas av klientens enda RenderStepped-loop, och en spec som anropar
# LektionController sjalv hade aldrig sett om den loopen anropar den.
# init.client.luau ar ett skript, inte en modul -- det inlinas sist och
# returnerar ingenting, precis som Anlaggningen.luau i BYGGE.
# Speldatan ligger under: Preparation laser faserna ur UBRFSkotsel, precis som
# i produktionen.
KLIENT = SPEL + [
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    ("Hjalper",      "src/shared/HorseCore/Hjalper.luau"),
    ("Svar",         "src/shared/HorseCore/Svar.luau"),
    ("Telemetri",    "src/shared/HorseCore/Telemetri.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    ("Preparation",  "src/shared/HorseCore/Preparation.luau"),
    # #161: klientbanken kor init.client.luau, och PreparationController
    # ritar numera bade skotselmoment och passets eftervard.
    ("Pass",         "src/shared/HorseCore/Pass.luau"),
    ("Sparning",     "src/shared/HorseCore/Sparning.luau"),
    ("Networking",   "src/shared/HorseCore/Networking.luau"),
    ("Ugneta",       "src/shared/HorseCore/Ugneta.luau"),
    ("Lektion",      "src/shared/HorseCore/Lektion.luau"),
    # G02-D: samma tva moduler som i PARITET, av samma skal. Se noten dar.
    ("Inspelning",   "src/shared/HorseCore/Inspelning.luau"),
    # G02-E del 1 (#150): CameraController.new() lasare Core.Kameralage
    # direkt - saknas den kraschar klientbanken redan vid uppsittning.
    ("Kameralage",   "src/shared/HorseCore/Kameralage.luau"),
    ("MovementController",  "src/client/MovementController.luau"),
    ("AnimationController", "src/client/AnimationController.luau"),
    ("CameraController",    "src/client/CameraController.luau"),
    ("SoundController",     "src/client/SoundController.luau"),
    ("EffectsController",   "src/client/EffectsController.luau"),
    ("RiderController",     "src/client/RiderController.luau"),
    ("Input",               "src/client/Input.luau"),
    ("TouchControls",       "src/client/TouchControls.luau"),
    ("InteractionController", "src/client/InteractionController.luau"),
    ("PreparationController", "src/client/PreparationController.luau"),
    #[[ Sadeln och transet pa boxfronten. Bara init.client require:ar den. ]]
    ("UtrustningController", "src/client/UtrustningController.luau"),
    ("UgnetaController",    "src/client/UgnetaController.luau"),
    ("UgnetaGestalt",       "src/client/UgnetaGestalt.luau"),
    ("ReplayController",    "src/client/ReplayController.luau"),
    ("LektionController",   "src/client/LektionController.luau"),
    # Kontrollhjalpen: bara init.client.luau require:ar den, sa den behovs
    # bara i KLIENT. Star har och inte i PARITET av det skalet -- inte av
    # forbiseende. Jamfor noten vid Inspelning/ReplayController ovan.
    ("KontrollHjalp",       "src/client/KontrollHjalp.luau"),
    #[[ #162: prompttexten pa klienten. Bara init.client require:ar den. ]]
    ("Prompttext",          "src/client/Prompttext.luau"),
    ("Debug",               "src/client/Debug.luau"),
    ("Genomsikt",           "src/client/Genomsikt.luau"),
    ("Init",                "src/client/init.client.luau"),
]

#[[ KOHERENSBANKEN (#162 PHYSICAL_WORLD_COHERENCE punkt 1, 3 och 6).
#
#   Skillnaden mot alla andra bankar: har finns BADE den byggda varlden,
#   HELA serverstacken och KLIENTENS init.client.luau i samma korning. Det
#   ar vad ordern menar med "actual place": HUD:ens kontext ska matas mot
#   spelarens lage i en riktig varld, genom den loop produktionen faktiskt
#   kopplar — inte genom ett direktanrop av den funktion loopen borde ha
#   anropat.
#
#   Varlden ligger FORST, av samma skal som i init.server.luau: tjansterna
#   satter markorer i den och letar dorrblad i den. `Init` ligger SIST och
#   returnerar ingenting, precis som Anlaggningen. ]]
def _utan(lista, namn):
    return [m for m in lista if m[0] not in namn]

_KLIENTDELEN = _utan(KLIENT, {"Geometri", "UBRFKomplex", "Init"})
KOHERENS = GEOMETRI + [
    ("BuildKit",     "buildings/BuildKit.luau"),
    ("Anlaggningen", "buildings/Anlaggningen.luau"),
] + _KLIENTDELEN + _utan([
    ("RigAdapter",      "src/shared/HorseCore/RigAdapter.luau"),
    ("HorseService",    "src/server/HorseService.luau"),
    ("SparService",     "src/server/SparService.luau"),
    ("StallService",    "src/server/StallService.luau"),
    #[[ LedService laddas FORE GameplayService: den senare require:ar
    #   den, och grinden pa "leda" ar hela poangen med blockerare 2. ]]
    ("LedService",     "src/server/LedService.luau"),
    ("GameplayService", "src/server/GameplayService.luau"),
    ("DorrService",     "src/server/DorrService.luau"),
    ("HastRigg",        "src/server/HastRigg.luau"),
    #[[ Sadeln och transet pa boxfronten: samma byggare produktionen
    #   startar, sa attributen i provet ar produktionens attribut. ]]
    ("UtrustningRigg",  "src/server/UtrustningRigg.luau"),
], {m[0] for m in _KLIENTDELEN}) + [
    ("Init",            "src/client/init.client.luau"),
]

MODULER = [
    #[[ Samma skal som i PARITET: TouchControls och InteractionController
    #   ritar spelartext. ]]
    ("UBRFSprak",    "game/UBRFSprak.luau"),
    ("Sprak",        "src/shared/HorseCore/Sprak.luau"),
    ("Types",        "src/shared/HorseCore/Types.luau"),
    ("RigAdapter",   "src/shared/HorseCore/RigAdapter.luau"),
    ("Config",       "src/shared/HorseCore/Config.luau"),
    ("Gaits",        "src/shared/HorseCore/Gaits.luau"),
    # RidKanon och Telemetri ligger fore MovementController: movement.spec
    # provar att en RIKTIG controller-frame producerar underlaget till
    # telemetrin (G02-A, senior review blocker B).
    ("RidKanon",     "src/shared/HorseCore/RidKanon.luau"),
    ("Hjalper",      "src/shared/HorseCore/Hjalper.luau"),
    ("Svar",         "src/shared/HorseCore/Svar.luau"),
    ("Telemetri",    "src/shared/HorseCore/Telemetri.luau"),
    ("StateMachine", "src/shared/HorseCore/StateMachine.luau"),
    # G02-E del 1 (#150): kameralaget. Rent tillstand utan beroenden - maste
    # bara ligga FORE CameraController, som lasare Core.Kameralage.
    ("Kameralage",   "src/shared/HorseCore/Kameralage.luau"),
    ("MovementController", "src/client/MovementController.luau"),
    ("AnimationController", "src/client/AnimationController.luau"),
    ("CameraController",   "src/client/CameraController.luau"),
    ("RiderController",    "src/client/RiderController.luau"),
    ("Input",              "src/client/Input.luau"),
    ("TouchControls",      "src/client/TouchControls.luau"),
    ("Genomsikt",          "src/client/Genomsikt.luau"),
]

# require-formerna som förekommer i koden, till modulnamn.
# HorseCore star kvar sarskilt: utan barn blir det __Core, tabellen stubbfilen
# bygger. Sista alternativet tar de ovriga ReplicatedStorage-modulerna
# (UBRFSpelData, UBRFSkotsel, UBRFSpel, Stallet, UBRFKomplex).
# Lokalnamnet for ReplicatedStorage varierar i repot: `RS` i vissa filer,
# `ReplicatedStorage` i andra (StallService, GameplayService). Bada maste
# kannas igen -- annars lamnas require:t orort och luau far en nil-sokvag.
REQUIRE = re.compile(
    r'require\(\s*(?:script\.Parent\.(\w+)'
    r'|script\.(\w+)'
    r'|(?:game:GetService\("ReplicatedStorage"\)|RS|ReplicatedStorage)\.HorseCore(?:\.(\w+))?'
    r'|(?:game:GetService\("ReplicatedStorage"\)|RS|ReplicatedStorage)\.(\w+))\s*\)')

MATERIALLISTA = ROT / "tests" / "roblox-material.txt"


def material() -> list:
    """De Enum.Material-namn UBRF far anvanda, ur EN fil.

    Stubbarnas Enum.Material svarade forr pa vilket namn som helst, sa
    Enum.Material.CorrugatedMetal passerade hela sviten och sprack forst i
    Studio. Listan injiceras nu i stubbarna i stallet for att skrivas av."""
    rader = MATERIALLISTA.read_text(encoding="utf-8").splitlines()
    return [r.strip() for r in rader if r.strip() and not r.startswith("#")]


def las(rel: str) -> str:
    return (ROT / rel).read_text(encoding="utf-8")
def inlina(kalla: str) -> str:
    """Byter require-anrop mot modulnamn. HorseCore utan barn blir __Core,
    tabellen som stubbfilen bygger av de redan laddade modulerna."""
    def byt(m):
        for g in m.groups():
            if g:
                return g
        return "__Core"
    return REQUIRE.sub(byt, kalla)

def bygg(spec_rel: str) -> pathlib.Path:
    # Ordningen ar viktig: "forberedelse" far inte falla igenom till MODULER,
    # dar varken UBRFSkotsel eller Stallet finns. Testas forst av det skalet.
    # #161: skotselpass.spec provar skotselns moment, passets eftervard och
    # DataStore-lagret. Den behover HELA FORBEREDELSE-bunten, och maste
    # testas FORE "spel" — filnamnet innehaller inte "spel", men den ska
    # heller inte falla igenom till MODULER dar varken UBRFSkotsel,
    # Sparning eller SparService finns.
    #[[ FORST av alla: "integration" ska inte kunna falla igenom till nagon
    #   annan bunt. Den behover BADE tjanstestacken och riggen. ]]
    #[[ Sprakgrinden kor pa KLIENTBANKEN: den mater att HUD:en, hjalpen,
    #   pekknapparna och prompterna FAKTISKT ritas om, alltsa mot samma
    #   controllers som init.client startar. ]]
    #[[ FORE "sprak": nej-vagssvepet behover TJANSTERNA och klientens
    #   rendering i samma korning, alltsa integrationsbanken. Ligger den
    #   efter faller den igenom till KLIENT dar GameplayService inte finns. ]]
    #[[ Ledningsspecen behover tjanstestacken: LedService och
    #   GameplayService. Samma bunt som integration. ]]
    if "ledning" in spec_rel:
        moduler, stubbar = INTEGRATION, "tests/stubs.luau"
    elif "sprak-en" in spec_rel:
        moduler, stubbar = INTEGRATION, "tests/stubs.luau"
    elif "sprak" in spec_rel:
        moduler, stubbar = KLIENT, "tests/stubs.luau"
    elif "integration" in spec_rel or "roster" in spec_rel:
        moduler, stubbar = INTEGRATION, "tests/stubs.luau"
    #[[ Utrustningsgrinden (16:21-ordern): sadeln och transet som fysiska
    #   saker. Behover tjanstestacken OCH riggen, alltsa samma bank som
    #   integrationen. Ligger FORE "spel"-grenen av samma skal som
    #   "spelbarhet": strangen far inte falla igenom till speldatans bank. ]]
    elif "utrustning" in spec_rel:
        moduler, stubbar = INTEGRATION, "tests/stubs.luau"
    elif "skotselpass" in spec_rel:
        moduler, stubbar = FORBEREDELSE, "tests/stubs.luau"
    elif "klient" in spec_rel:
        moduler, stubbar = KLIENT, "tests/stubs.luau"
    elif "gestalt" in spec_rel:
        moduler, stubbar = GESTALT, "tests/stubs-bygge.luau"
    elif "paritet" in spec_rel or "ugneta" in spec_rel:
        # ugneta.spec provar larar-UX:en ovanpa samma moduler som
        # paritetsspecen: RidKanon, Ugneta och UgnetaController.
        moduler, stubbar = PARITET, "tests/stubs.luau"
    elif "forberedelse" in spec_rel:
        moduler, stubbar = FORBEREDELSE, "tests/stubs.luau"
    #[[ FORE "spel": strangen "spelbarhet" INNEHALLER "spel", sa den hamnar
    #   annars i speldatans bank utan BuildKit och Anlaggningen — samma
    #   genomfallning som kommentaren om "forberedelse" varnar for. Den
    #   traffade mig direkt: forsta korningen dog pa `BuildKit.M` som nil. ]]
    #[[ PHYSICAL_WORLD_COHERENCE_GATE: varlden PLUS tjansterna. Den behover
    #   samma bank som spelbarheten -- byggd varld, DorrService, Stallet och
    #   HastRigg -- och star fore "spel" av samma skal som spelbarheten. ]]
    #[[ Topologigrinden mater ZONER i den byggda varlden och behover samma
    #   bank som spelbarheten. ]]
    #[[ Manifestet behover varlden, tjansterna och speldatan — samma bank
    #   som spelbarheten. ]]
    elif "varldsmanifest" in spec_rel:
        moduler, stubbar = SPELBARHET, "tests/stubs-bygge.luau"
    elif "preflight" in spec_rel:
        moduler, stubbar = SPELBARHET, "tests/stubs-bygge.luau"
    elif "topologi" in spec_rel:
        moduler, stubbar = SPELBARHET, "tests/stubs-bygge.luau"
    elif "varldskoherens" in spec_rel:
        moduler, stubbar = SPELBARHET, "tests/stubs-bygge.luau"
    #[[ HUD-koherensen (PHYSICAL_WORLD_COHERENCE punkt 1, 3 och 6) behover
    #   BADE den byggda varlden och klientens HUD. Den bunten ar
    #   integrationsbanken PLUS varlden, och den kor pa de RIKA stubbarna
    #   eftersom PreparationController ritar GUI. ]]
    elif "varldshud" in spec_rel:
        moduler, stubbar = KOHERENS, "tests/stubs.luau"
    elif "spelbarhet" in spec_rel:
        moduler, stubbar = SPELBARHET, "tests/stubs-bygge.luau"
    elif "spel" in spec_rel:
        moduler, stubbar = SPEL, "tests/stubs.luau"
    elif pathlib.Path(spec_rel).name == "sikt.spec.luau":
        moduler, stubbar = SIKT, "tests/stubs-bygge.luau"
    elif "qa" in spec_rel:
        moduler, stubbar = QA, "tests/stubs-bygge.luau"
    #[[ Markgrinden (P0 efter det fysiska testet): varlden och inget mer.
    #   Den mater STOD over hela tomten, inte gangbarhet mellan vaggar, och
    #   behover darfor varken speldata eller tjanster. Ingen annan spec har
    #   "mark" i namnet, sa grenen kan sta har. ]]
    #[[ Handighetsgrinden: samma bank som markgrinden — den byggda varlden
    #   och inget mer. Ingen annan spec har "handighet" i namnet. ]]
    elif "handighet" in spec_rel:
        moduler, stubbar = BYGGE, "tests/stubs-bygge.luau"
    elif "mark" in spec_rel:
        moduler, stubbar = BYGGE, "tests/stubs-bygge.luau"
    elif "forstaplayable" in spec_rel:
        moduler, stubbar = FORSTAPLAYABLE, "tests/stubs-bygge.luau"
    elif "bygge" in spec_rel:
        moduler, stubbar = BYGGE, "tests/stubs-bygge.luau"
    elif "geometri" in spec_rel:
        moduler, stubbar = GEOMETRI, "tests/stubs.luau"
    else:
        moduler, stubbar = MODULER, "tests/stubs.luau"
    stubbtext = las(stubbar).replace(
        "local __MATERIAL = {}",
        "local __MATERIAL = { " + ", ".join(f'"{m}"' for m in material()) + " }",
        1)
    har_core = "__Core" in stubbtext
    delar = [stubbtext]
    #[[ Bankens varld ar QA-varlden: bygge.spec raknar de gula dorrmarkorerna
    #   mot antalet dorrar i datan. Sedan #162 byggs de bara nar flaggan ar
    #   satt, sa banken satter den. En spelbuild gor det inte. ]]
    delar.append("local UBRF_QA_MARKORER = true\n")
    for namn, rel in moduler:
        kropp = inlina(las(rel))
        delar.append(f"--[[ ══ {rel} ══ ]]\nlocal {namn} = (function()\n{kropp}\nend)()\n")
        # Hjalper/Svar/RidKanon ligger med sedan G02-B: MovementController
        # laser dem ur Core, precis som produktionen gor.
        # ...men bara nar stubbfilen faktiskt bygger ett __Core. Byggstubbarna
        # (stubs-bygge.luau) gor inte det: de stubbar huset, inte hastsystemet.
        if har_core and namn in ("Config", "Gaits", "StateMachine", "RigAdapter",
                    "Networking", "RidKanon", "Hjalper", "Svar", "Telemetri",
                    "Inspelning", "Kameralage", "Pass", "Sparning"):
            delar.append(f"__Core.{namn} = {namn}\n")
    delar.append(f"--[[ ══ {spec_rel} ══ ]]\n{las(spec_rel)}\n")
    UT.mkdir(parents=True, exist_ok=True)
    mal = UT / (pathlib.Path(spec_rel).stem + ".luau")
    mal.write_text("\n".join(delar), encoding="utf-8")
    return mal

if __name__ == "__main__":
    specar = sys.argv[1:] or ["tests/movement.spec.luau"]
    for s in specar:
        p = bygg(s)
        # encoding="utf-8" ar inte kosmetiskt: specarna innehaller a, a och
        # o, och pa en Windows-varddator dar Python defaultar till cp1252
        # kastade den har raden UnicodeDecodeError och FALLDE HELA BYGGET
        # innan en enda spec kordes. Samma klass av portabilitetsfel som
        # #159 rattade for sokvagarna.
        print(f"{p.relative_to(ROT.parent)}: {len(p.read_text(encoding='utf-8'))} tecken")
