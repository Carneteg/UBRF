--!strict
--[[ GENERERAD av tools/bygg-identitet.py — andra inte har.

	Buildens identitet, last av Preflight punkt 9. `kallhash` ar den
	som galler: en SHA-256 over innehallet i de filer
	`default.project.json` mappar in i placen. Den gar att rakna om
	och jamfora exakt.

	`sha` ar UPPLYSNING, inte grind. En committad fil kan inte kanna
	sitt eget commit-SHA, sa det faltet ligger alltid minst ett steg
	efter. Gata aldrig pa det.

	`kallor` ar antalet mappade kallfiler. Placen kan rakna om DET
	sjalv — instanser gar att rakna utan att lasa `Source`, vilket ett
	spelskript inte far. Se Integritet.kallantal och punkt 9e. ]]
return {
	kallhash = "a731c4b5ad9b3535cf99eef918fabfe14ce4bb6d4a98b2cef56b3fa4c5213895",
	lage = "rojo",
	kallor = 78,
	sha = "bd07094b67020e27b143d79ea088bebda07d75c7",
	miljo_sha = "bd07094b67020e27b143d79ea088bebda07d75c7",
	genererad = "2026-09-22T05:09:30Z",
	vag = "tools/bygg-identitet.py ur roblox/default.project.json",

	--[[ Vad Rojo AGER per tjanst. Integritet.luau skiljer kallstyrt
		fran runtime-skapat och frammande med den har listan. ]]
	rojo = {
		ReplicatedStorage = { "HorseCore", "Stallet", "UBRFBuild", "UBRFKomplex", "UBRFSkotsel", "UBRFSpel", "UBRFSpelData", "UBRFSprak" },
		ServerScriptService = { "Horse", "Varld" },
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
		"StarterPlayer.StarterPlayerScripts.Horse",
	},
}
