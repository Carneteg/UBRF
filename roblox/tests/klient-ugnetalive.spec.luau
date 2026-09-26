--!nostrict
--[[
	UGNETAS LIVE-COACHNING PÅ SPELARENS SPRÅK (#264 GAIT_UGNETA_REVIEW_R1,
	fynd 1).

	Reviewn reproducerade: på engelska gav temat `Titta dit du ska`, och
	Ugnetas yta visade den svenska kanonen. Temat lämnar kanonens svenska
	text; lektionen skickade den vidare oförändrad.

	Provet går genom LEKTIONENS väg: `LektionController.start`, kortet
	kvitteras med `fortsatt`, och `LektionController.steg` får en telemetri
	där ryttaren är tydligt svag, tills temat säger något. Det som läses är
	Ugnetas yta (`_larare`) — det spelaren ser. Ingen text tolkas för att
	hitta betydelsen; nyckeln och kanonen jämförs.

	BÄNKGRÄNS: telemetrin är syntetisk, inte en riden häst.

	Kör: python3 roblox/tests/build.py tests/klient-ugnetalive.spec.luau
	     && luau roblox/tests/.build/klient-ugnetalive.spec.luau
]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local LC, UC = LektionController, UgnetaController
local KANON = RidKanon.UGNETA.LIVE

--[[ Svag ryttare: sen, spänd, ojämn. Temat hittar något att säga. ]]
local TM = { uppsutten = true, svarstid = 4, etableringstid = 6, paradKvalitet = 0.1,
	fokus = 0.1, spanning = 0.1, fart = 0.2, onskadFart = 2, svangradie = math.huge }

--[[ Alla live-texter på ett språk, ur katalogen. ]]
local function liveTexter(sprak)
	local ut = {}
	for id, r in pairs(UC.LIVE_NYCKEL) do
		ut[Sprak.iSprak(sprak, r.fel)] = id .. ".fel"
		ut[Sprak.iSprak(sprak, r.bra)] = id .. ".bra"
	end
	return ut
end
local SV, EN = liveTexter("sv"), liveTexter("en")

--[[ Stega lektionen tills Ugnetas yta visar en live-text, eller ge upp. ]]
local function tillsLive(sek, tm)
	for _ = 1, math.floor(sek * 60) do
		--[[ Ett slutfört försök väntar på spelarens val; hon går vidare,
		     precis som med knappen. ]]
		if UC.vantar() then UC.fortsatt() end
		LC.steg(1 / 60, tm or TM, nil)
		local t = UC._larare().text
		if SV[t] or EN[t] then return t end
	end
	return nil
end

print("\n── Katalogen: svenska ÄR kanonen, engelska finns ──")
do
	local fel_ = {}
	for id, r in pairs(KANON) do
		local n = UC.LIVE_NYCKEL[id]
		if not n then
			table.insert(fel_, id .. " saknar nyckel")
		else
			if Sprak.iSprak("sv", n.fel) ~= r.fel then table.insert(fel_, n.fel .. " ≠ kanon") end
			if Sprak.iSprak("sv", n.bra) ~= r.bra then table.insert(fel_, n.bra .. " ≠ kanon") end
			if Sprak.iSprak("en", n.fel) == r.fel then table.insert(fel_, n.fel .. " utan engelska") end
			if Sprak.iSprak("en", n.bra) == r.bra and r.bra ~= "OK" then
				table.insert(fel_, n.bra .. " utan engelska")
			end
		end
	end
	prova("varje live-signal har nyckel, svensk text = kanon, och engelsk text",
		#fel_ == 0, table.concat(fel_, " | "))
end

print("\n── På engelska: live-coachningen är engelsk ──")
do
	Sprak.satLocale("en-us")
	LC.start(nil, nil)
	LC.steg(1 / 60, TM, nil)
	UC.fortsatt()
	local t = tillsLive(12)
	prova("en live-signal kom genom lektionens väg", t ~= nil, tostring(t))
	prova("PÅ ENGELSKA — inte kanonens svenska", t ~= nil and EN[t] ~= nil and SV[t] == nil,
		("%q"):format(tostring(t)))
	LC.avbryt()
end

print("\n── SV → EN → SV mitt i övningen, och en färsk signal efter bytet ──")
do
	Sprak.satLocale("sv-se")
	Sprak.satVal(nil)
	LC.start(nil, nil)
	LC.steg(1 / 60, TM, nil)
	UC.fortsatt()
	local svT = tillsLive(12)
	prova("på svenska: svensk signal", svT ~= nil and SV[svT] ~= nil, ("%q"):format(tostring(svT)))
	local ovningSv = select(2, CoachBanner.text())
	UC._vaxlaSprak()
	local ovningEn = select(2, CoachBanner.text())
	prova("bytet mitt i övningen översätter övningen på plats",
		ovningSv ~= "" and ovningEn ~= ovningSv, ("%q → %q"):format(ovningSv, ovningEn))
	prova("och den gamla signalen står inte kvar på svenska",
		UC._larare().text ~= svT, ("%q"):format(UC._larare().text))
	--[[ Temat säger aldrig samma ord två gånger i rad, så en färsk signal
	     kräver ett nytt läge: nu rider hon bra, och berömmet kommer. ]]
	local BRA = { uppsutten = true, svarstid = 0.2, etableringstid = 0.3, paradKvalitet = 0.95,
		fokus = 0.95, spanning = 0.05, fart = 2, onskadFart = 2, svangradie = math.huge }
	local enT = tillsLive(20, BRA)
	prova("NÄSTA signal efter bytet är engelsk", enT ~= nil and EN[enT] ~= nil and SV[enT] == nil,
		("%q"):format(tostring(enT)))
	UC._vaxlaSprak()
	local tillbaka = tillsLive(25, TM)
	prova("och tillbaka på svenska blir den svensk igen",
		tillbaka ~= nil and SV[tillbaka] ~= nil, ("%q"):format(tostring(tillbaka)))
	LC.avbryt()
end

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	error("klient-ugnetalive.spec: " .. fel .. " fel")
end
print("\nklient-ugnetalive.spec: alla gröna")
