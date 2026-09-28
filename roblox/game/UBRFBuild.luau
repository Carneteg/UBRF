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
	kallhash = "5a7d81b058276a0a67d786af61677e198b1b8df308d65c6e7a9ca28aa911d34b",
	lage = "rojo",
	kallor = 105,
	modeller = 1,
	sha = "bb6505f3e86ba358e937d7004dd566bff0c26d8a",
	miljo_sha = "bb6505f3e86ba358e937d7004dd566bff0c26d8a",
	genererad = "2026-09-28T08:44:58Z",
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
