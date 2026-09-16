--!strict
--[[ GENERERAD av tools/bygg-identitet.py — andra inte har.

	Buildens identitet, last av Preflight punkt 9. `kallhash` ar den
	som galler: en SHA-256 over innehallet i de filer
	`default.project.json` mappar in i placen. Den gar att rakna om
	och jamfora exakt.

	`sha` ar UPPLYSNING, inte grind. En committad fil kan inte kanna
	sitt eget commit-SHA, sa det faltet ligger alltid minst ett steg
	efter. Gata aldrig pa det. ]]
return {
	kallhash = "94a0c91ca1fb92a84f996c821c734a1dd3f01f94a6037fd069de847f84f2e2c1",
	lage = "rojo",
	kallor = 67,
	sha = "cb3342e7d3727bd25efc91d925984f65a3bb4d9a",
	miljo_sha = "cb3342e7d3727bd25efc91d925984f65a3bb4d9a",
	genererad = "2026-09-16T05:02:31Z",
	vag = "tools/bygg-identitet.py ur roblox/default.project.json",

	--[[ Vad Rojo AGER per tjanst. Integritet.luau skiljer kallstyrt
		fran runtime-skapat och frammande med den har listan. ]]
	rojo = {
		ReplicatedStorage = { "HorseCore", "Stallet", "UBRFBuild", "UBRFKomplex", "UBRFSkotsel", "UBRFSpel", "UBRFSpelData", "UBRFSprak" },
		ServerScriptService = { "Horse", "Varld" },
		StarterPlayer = { "StarterPlayerScripts" },
	},
}
