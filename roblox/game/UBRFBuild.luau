--!strict
--[[ GENERERAD av tools/bygg-identitet.py — andra inte har.

	Buildens identitet, last av Preflight punkt 9. `kallhash` ar den
	som galler: en SHA-256 over innehallet i de filer
	`default.project.json` mappar in i placen. Den gar att rakna om
	och jamfora exakt.

	`sha` ar UPPLYSNING, inte grind. En committad fil kan inte kanna
	sitt eget commit-SHA, sa det faltet ligger alltid minst ett steg
	efter. Gata aldrig pa det.

	`kallor` ar antalet mappade SKRIPTfiler. Placen kan rakna om DET
	sjalv — instanser gar att rakna utan att lasa `Source`, vilket ett
	spelskript inte far. Se Integritet.kallantal och punkt 9e.

	DET STOD 'kallfiler' HAR, OCH DET SLUTADE STAMMA (#264 R3). Nar
	hastmallen mappades in blev antalet 79 medan placen bar 78
	skriptobjekt, och punkt 9e foll i riktig motor: CRITICAL_STARTUP_
	GATE gav FAIL och ingen spelare slapptes in. Grinden hade ratt —
	talen gick isar — men den jamforde skript mot skript PLUS modell.

	`modeller` ar de mappade filer som INTE ar Luau. De raknas for
	sig, sa att en tappad modell fortfarande syns. Se punkt 9f. ]]
return {
	kallhash = "ece6df7387182b087fcf25a5053f8dfef493a8dac6d7953192adb3ab8c347049",
	lage = "rojo",
	kallor = 106,
	modeller = 1,
	sha = "ce4780f368c27cb25bf4d0e10c69ec8b6375c2be",
	miljo_sha = "ce4780f368c27cb25bf4d0e10c69ec8b6375c2be",
	genererad = "2026-09-28T16:13:57Z",
	vag = "tools/bygg-identitet.py ur roblox/default.project.json",

	--[[ Vad Rojo AGER per tjanst. Integritet.luau skiljer kallstyrt
		fran runtime-skapat och frammande med den har listan. ]]
	rojo = {
		ReplicatedStorage = { "HorseCore", "Stallet", "UBRFBuild", "UBRFKomplex", "UBRFSkotsel", "UBRFSpel", "UBRFSpelData", "UBRFSprak" },
		ServerScriptService = { "Horse", "Varld" },
		ServerStorage = { "HastVisualer" },
		StarterPlayer = { "StarterPlayerScripts" },
	},

	--[[ De exakta vagar Rojo FYLLER med kallfiler. Punkt 9e
		raknar skriptobjekt just har och ingen annanstans: en
		`$className`-behallare som `StarterPlayerScripts` delas
		med motorns egna skript, och de ar inte kallor. ]]
	kallrotter = {
		"ReplicatedStorage.HorseCore",
		"ReplicatedStorage.Stallet",
		"ReplicatedStorage.UBRFBuild",
		"ReplicatedStorage.UBRFKomplex",
		"ReplicatedStorage.UBRFSkotsel",
		"ReplicatedStorage.UBRFSpel",
		"ReplicatedStorage.UBRFSpelData",
		"ReplicatedStorage.UBRFSprak",
		"ServerScriptService.Horse",
		"ServerScriptService.Varld.Anlaggningen",
		"ServerScriptService.Varld.BuildKit",
		"ServerScriptService.Varld.Geometri",
		"ServerStorage.HastVisualer.k3",
		"StarterPlayer.StarterPlayerScripts.Horse",
	},
}
