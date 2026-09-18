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
	kallhash = "c84ce0e32b9a3888f780829e62806f80ed72381cf217a17117d69691abe877af",
	lage = "rojo",
	kallor = 69,
	sha = "b7d35dc3d2ada58a4e4900c00f452123ce726bf1",
	miljo_sha = "b7d35dc3d2ada58a4e4900c00f452123ce726bf1",
	genererad = "2026-09-18T05:12:30Z",
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
