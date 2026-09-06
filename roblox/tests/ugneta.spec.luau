--!nostrict
--[[
	UGNETAS LÄRAR-UX PÅ ROBLOX (G02-C, UX-variant 1 + 3).

	ChatGPT senior review 2026-09-06 på #119, blocker 1: Roblox är primär
	plattform, och kontraktsparitet räcker inte — spelaren ska få samma
	upplevelse. Den här specen mäter att UgnetaController faktiskt bygger
	den, med samma regler som webben:

	  - live under ridning är NÅGRA ORD, inte ett kort,
	  - kortet visas mellan försöken, med högst två observationer,
	  - efter försök 1 finns "Prova igen",
	  - säkerhet vinner: live-chipet släcks och kortet stängs,
	  - bedömningen kommer ur HorseCore/Ugneta, inte ur egna formler.

	Kör: python3 roblox/tests/build.py tests/ugneta.spec.luau
	     && luau roblox/tests/.build/ugneta.luau
]]

local fails = 0
local function check(namn, ok, detalj)
	if ok then
		print(string.format("  OK   %s%s", namn, if detalj then " " .. detalj else ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, if detalj then " " .. detalj else ""))
	end
end

print("")
print("UGNETA — LÄRAR-UX PÅ ROBLOX")
print("")

UgnetaController.start()

local gui = game:GetService("Players").LocalPlayer._gui
local function hitta(namn)
	local function sok(nod)
		if type(nod) ~= "table" then return nil end
		if nod.Name == namn then return nod end
		for _, b in ipairs(nod._barn or {}) do
			local t = sok(b)
			if t then return t end
		end
		return nil
	end
	return sok(gui)
end

--[[ ── LIVE-REGISTRET ─────────────────────────────────────────── ]]
do
	local txt = UgnetaController.liveText("hand", false)
	check("live-cuen för handen är några ord", txt == "Mjukare hand",
		string.format('("%s")', txt))
	local bra = UgnetaController.liveText("timing", true)
	check("och beröm är lika kort", bra == "Precis så", string.format('("%s")', bra))

	local ord = 0
	for _, id in { "hand", "framat", "sits", "lugn", "timing", "vagen" } do
		for _, b in { true, false } do
			local t = UgnetaController.liveText(id, b)
			local n = 0
			for _ in string.gmatch(t, "%S+") do n += 1 end
			if n > ord then ord = n end
		end
	end
	--[[ Taket är fyra ord, inte tre: webbens egen längsta cue är
	     "Titta dit du ska". Regeln är "några ord, inte en mening" —
	     att korta ned den hade ändrat webbens pedagogik utan att någon
	     bett om det. ]]
	check("ingen live-cue är längre än fyra ord", ord <= 4,
		string.format("(längsta %d ord)", ord))

	UgnetaController.live("Mjukare hand", false)
	local chip = hitta("Live")
	check("live-chipet syns och bär texten",
		chip ~= nil and chip.Visible == true and chip.Text == "Mjukare hand",
		string.format('(Visible %s, "%s")', tostring(chip and chip.Visible),
			tostring(chip and chip.Text)))

	local kort = hitta("Kort")
	check("och kortet är INTE uppe under live-feedback",
		kort ~= nil and kort.Visible == false,
		string.format("(kortets Visible %s)", tostring(kort and kort.Visible)))

	UgnetaController.steg(3.0)
	check("live-chipet tonar ut av sig självt",
		chip.Visible == false, string.format("(Visible %s)", tostring(chip.Visible)))
end

--[[ ── MELLAN FÖRSÖKEN ────────────────────────────────────────── ]]
do
	local nu = { linje = 0.78, rytm = 0.60, balans = 0.41,
		timing = 0.5, mjukhet = 0.5, respons = 0.5, tempo = 0.5 }
	local punkter = UgnetaController.efterForsok("storvolt", nu, nil, 1)
	local kort = hitta("Kort")
	local rubrik = hitta("Rubrik")
	local knapp = hitta("Knapp")
	check("efter försök 1 visas kortet", kort ~= nil and kort.Visible == true,
		string.format("(Visible %s)", tostring(kort and kort.Visible)))
	check("med en sak som var bra och en att förbättra",
		#punkter == 2 and string.find(punkter[1], "Bra") ~= nil
		and string.find(punkter[2], "Jobba på") ~= nil,
		string.format('("%s" / "%s")', punkter[1] or "-", punkter[2] or "-"))
	check("rubriken och knappen säger Prova igen",
		rubrik ~= nil and rubrik.Text == "Prova igen"
		and knapp ~= nil and knapp.Visible == true,
		string.format('(rubrik "%s", knapp %s)', tostring(rubrik and rubrik.Text),
			tostring(knapp and knapp.Visible)))

	local fore = { linje = 0.40, rytm = 0.50, balans = 0.60 }
	local nu2 = { linje = 0.62, rytm = 0.52, balans = 0.45 }
	local p2 = UgnetaController.efterForsok("storvolt", nu2, fore, 2)
	check("efter försök 2 jämförs det mot försök 1",
		#p2 <= 2 and string.find(p2[1], "Bättre") ~= nil
		and string.find(p2[1], "linjen") ~= nil,
		string.format('("%s")', p2[1] or "-"))
	check("och aldrig fler än kontraktets tak",
		#p2 <= Ugneta.MAX_OBSERVATIONER,
		string.format("(%d av högst %d)", #p2, Ugneta.MAX_OBSERVATIONER))

	local knapp2 = hitta("Knapp")
	check("men Prova igen visas inte efter sista försöket",
		knapp2 ~= nil and knapp2.Visible == false,
		string.format("(Visible %s)", tostring(knapp2 and knapp2.Visible)))
end

--[[ ── SÄKERHET VINNER ────────────────────────────────────────── ]]
do
	UgnetaController.live("Bra rytm", true)
	local chip = hitta("Live")
	local fore = chip.Visible
	UgnetaController.sakerhetTarOver()
	local kort = hitta("Kort")
	check("ett säkerhetsmeddelande släcker live-chipet",
		fore == true and chip.Visible == false,
		string.format("(före %s → efter %s)", tostring(fore), tostring(chip.Visible)))
	check("och stänger lärarkortet",
		kort ~= nil and kort.Visible == false,
		string.format("(Visible %s)", tostring(kort and kort.Visible)))
end

--[[ ── INGEN PARALLELL SANNING ────────────────────────────────── ]]
do
	--[[ Kontraktet ska STYRA texten. Byts dimensionerna för en övning
	     ska Ugnetas ord följa med — annars har controllern en egen
	     uppfattning vid sidan av kanonen. ]]
	local nu = { linje = 0.20, rytm = 0.90, balans = 0.30,
		timing = 0.90, mjukhet = 0.20, respons = 0.30 }
	local volt = UgnetaController.efterForsok("storvolt", nu, nil, 1)
	local overgang = UgnetaController.efterForsok("halt_skritt", nu, nil, 1)
	check("volten berömmer rytmen, övergången berömmer timingen",
		string.find(volt[1] or "", "rytmen") ~= nil
		and string.find(overgang[1] or "", "timingen") ~= nil,
		string.format('(volt "%s" · övergång "%s")', volt[1] or "-", overgang[1] or "-"))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
