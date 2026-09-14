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
	kallhash = "6a25cbeef6a78bddc67f11b34e346c5cdb457edc08943e6940ac986d0b175f16",
	lage = "rojo",
	kallor = 67,
	sha = "d4527b1c5e64063c5b82a15494054a3c609bab08",
	miljo_sha = "d4527b1c5e64063c5b82a15494054a3c609bab08",
	genererad = "2026-09-14T11:54:22Z",
	vag = "tools/bygg-identitet.py ur roblox/default.project.json",

	--[[ Vad Rojo AGER per tjanst. Integritet.luau skiljer kallstyrt
		fran runtime-skapat och frammande med den har listan. ]]
	rojo = {
		ReplicatedStorage = { "HorseCore", "Stallet", "UBRFBuild", "UBRFKomplex", "UBRFSkotsel", "UBRFSpel", "UBRFSpelData", "UBRFSprak" },
		ServerScriptService = { "Horse", "Varld" },
		StarterPlayer = { "StarterPlayerScripts" },
	},
}
