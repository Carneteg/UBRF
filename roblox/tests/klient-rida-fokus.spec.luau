--!nostrict
--[[
	#274 — «RIDA NU» ÄR INGEN HANDLING MEDAN VÄLFÄRDSFRÅGAN ÄGER FOKUS.

	Tobias speltest i Studio på #274-linjen: «Rida nu» stod kvar som en
	vanlig handling medan stallets fynd väntade på sitt svar, och varje
	tryck nekades av servern med `forb.oppet_fynd`. Servern hade rätt; det
	var visningen som var fel. Samma sak efter rätt svar: hästen är stoppad,
	«Rida nu — Troy» låg kvar bredvid «Fortsätt med …», och servern nekade
	med `forb.lararen_tar_over`.

	Det dolda offret var dörren. «Rida nu» tog panelens enda prompt-plats
	(1 av 7 i räckhåll) och trängde «Öppna dörren» till överflödessidan.

	Specen kör `init.client.luau` på riktigt (KLIENT-bänken), matar SERVERNS
	vy byggd av den riktiga `Preparation` och läser prompterna ur världen.

	  1  vanlig förberedelse: «Rida nu» finns
	  2  öppet fynd: «Rida nu» finns INTE, svaren äger panelen, och det
	     är samma tillstånd där servern nekar med `forb.oppet_fynd`
	  3  stopp: «Rida nu» finns INTE, «Fortsätt med …» är det enda valet,
	     och servern nekar med `forb.lararen_tar_over`
	  4  efter bytet till en frisk häst: «Rida nu» kommer tillbaka
	  5  dörren: med «Rida nu» borta tar dörren prompt-platsen
	  6  ledsteget med sadel och träns buret: dörren är första handlingen
	     på sida 1, före «Led» — ingen bläddring

	NOT TESTED: hur det ser ut och känns på en riktig skärm (Tobias speltest).

	Kör: python3 roblox/tests/build.py tests/klient-rida-fokus.spec.luau
	     && luau roblox/tests/.build/klient-rida-fokus.spec.luau
]]

local fel = 0
local antal = 0
local function prova(vad, ok, detalj)
	antal += 1
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. tostring(detalj) else ""))
	end
end

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RSt = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local Net = Networking
local PC = PreparationController
local IC = InteractionController
local N = Naromrade

Sprak.satLocale("sv-se")

RunService._server = true
Net.get("MountRequest")
Net.get("LedBorja")
Net.get("LedSlapp")
Net.get("LedSync")
Net.get("RidaNu")
Net.get("PreparationHandling")
Net.get("PassHandling")
Net.get("FortsattHast")
RunService._server = false
RSt:SetAttribute("G01Enabled", true)

local HAST_ID = "trixie"
local hast = __makeHastModell("Trixie")
hast:SetAttribute("HorseId", HAST_ID)
hast:SetAttribute("HorseName", "Trixie")
hast.Parent = workspace
Taggar:AddTag(hast, "Horse")
local hastRot = hast:FindFirstChild("HumanoidRootPart")

local karaktar = Instance.new("Model")
karaktar.Name = "Spelare"
local kropp = Instance.new("Part")
kropp.Name = "HumanoidRootPart"
kropp.Size = Vector3.new(2, 2, 1)
kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
kropp.Parent = karaktar
karaktar.Parent = workspace
player.Character = karaktar

--[[ En stängd stalldörr bredvid spelaren, som i klient-guide.spec. ]]
local dorrDel = Instance.new("Part")
dorrDel.Name = "Dorrblad"
dorrDel.CFrame = CFrame.new(hastRot.CFrame.Position + Vector3.new(0, 0, 3))
dorrDel:SetAttribute("UBRFDorr", "stall N dorrgul")
dorrDel.Parent = workspace
local dorr = Instance.new("ProximityPrompt")
dorr.Name = "DorrPrompt"
dorr.ActionText = "Öppna"
dorr.ObjectText = "Dörr"
dorr:SetAttribute("SprakNyckel", "dorr.oppna")
dorr.MaxActivationDistance = 10
dorr.Parent = dorrDel

local function ridaNuPrompt()
	for _, d in ipairs(hast:GetDescendants()) do
		if d.Name == "RidaNuPrompt" then return d end
	end
	return nil
end
local function ridaNuIPanelen()
	for _, p in ipairs(N._prompter()) do
		if p.Name == "RidaNuPrompt" then return true end
	end
	return false
end
local function valtexter()
	local t = {}
	for _, v in ipairs(N._val()) do table.insert(t, tostring(v.text)) end
	return table.concat(t, " / ")
end

local rev = 0
local function visa(vy)
	PC.tillampa(vy)
	PC.uppdateraKontext()
	IC.uppdatera()
	N.satRider(false)
end

--[[ ══ 1. VANLIG FÖRBEREDELSE: «RIDA NU» FINNS ═════════════════════════ ]]
print("\n── 1. Ingen fråga öppen, ingen stopp: «Rida nu» finns ──")
do
	local s = Preparation.nyState(HAST_ID, 1)
	rev += 1
	visa(Preparation.vy(s, Preparation.STATUS.FORBEREDER, rev, "Trixie"))
	prova("förutsättning: ingen valfärdsfokus", PC.valfardAgerFokus() == false)
	prova("«Rida nu» finns på hästen", ridaNuPrompt() ~= nil)
end

--[[ ══ 2. ÖPPET FYND ═════════════════════════════════════════════════════ ]]
print("\n── 2. Öppet fynd: svaren äger fokus, «Rida nu» är borta ──")
do
	local s = Preparation.nyState(HAST_ID, 1)
	s.fynd = "mun"
	s.fyndSett = true
	rev += 1
	local vy = Preparation.vy(s, Preparation.STATUS.FORBEREDER, rev, "Trixie")
	visa(vy)
	prova("förutsättning: vyn bär ett öppet fynd med svar",
		type(vy.svar) == "table" and #vy.svar > 0, type(vy.svar) == "table" and #vy.svar or "ingen")
	prova("valfärdsfokus är på", PC.valfardAgerFokus() == true)

	--[[ SAMMA TILLSTÅND som servern nekar i: det är kopplingen provet
		finns för. Visas «Rida nu» här, så är det en knapp som alltid nej:ar. ]]
	local far, skal = Preparation.provaHandling(s, "rykta", HAST_ID)
	prova("servern nekar ridhandlingar i det här läget: forb.oppet_fynd",
		far == false and skal == "forb.oppet_fynd", tostring(skal))
	prova("«Rida nu» finns INTE på hästen", ridaNuPrompt() == nil)
	prova("och står inte i panelens prompter", ridaNuIPanelen() == false)
	prova("fyndets svar står i panelen", #N._val() >= 2, valtexter())
end

--[[ ══ 3. STOPP ═════════════════════════════════════════════════════════ ]]
print("\n── 3. Stoppad häst: «Fortsätt med …», inte «Rida nu» ──")
do
	local s = Preparation.nyState(HAST_ID, 1)
	s.fynd = "mun"
	s.fyndSett = true
	for _, v in ipairs(Preparation.fyndSvar()) do
		if not v.fel then Preparation.svaraFynd(s, v.id) break end
	end
	prova("förutsättning: rätt svar stoppar hästen", s.stoppad ~= nil)
	rev += 1
	local vy = Preparation.vy(s, Preparation.STATUS.STOPPAD, rev, "Trixie")
	vy.ersattare = "Replay"
	visa(vy)
	local far, skal = Preparation.provaHandling(s, "rykta", HAST_ID)
	prova("servern nekar i det här läget: forb.lararen_tar_over",
		far == false and skal == "forb.lararen_tar_over", tostring(skal))
	prova("«Rida nu» finns INTE på den stoppade hästen", ridaNuPrompt() == nil)
	local synliga = PC._synligaMoment()
	prova("«Fortsätt» är det enda valet", #synliga == 1 and synliga[1] == "fortsatt", table.concat(synliga, ", "))
end

--[[ ══ 4. EFTER BYTET ═══════════════════════════════════════════════════ ]]
print("\n── 4. Frisk häst efter bytet: «Rida nu» kommer tillbaka ──")
do
	local s = Preparation.nyState(HAST_ID, 2)
	rev += 1
	visa(Preparation.vy(s, Preparation.STATUS.FORBEREDER, rev, "Trixie"))
	prova("valfärdsfokus är av", PC.valfardAgerFokus() == false)
	prova("«Rida nu» finns igen", ridaNuPrompt() ~= nil)
end

--[[ ══ 5. DÖRREN ════════════════════════════════════════════════════════ ]]
print("\n── 5. Dörren får inte trängas ut av en död «Rida nu» ──")
do
	local s = Preparation.nyState(HAST_ID, 1)
	s.fynd = "mun"
	s.fyndSett = true
	rev += 1
	visa(Preparation.vy(s, Preparation.STATUS.FORBEREDER, rev, "Trixie"))
	local namn = {}
	for _, p in ipairs(N._prompter()) do table.insert(namn, p.Name) end
	local forst = N._prompter()[1]
	prova("«Rida nu» tar inte prompt-platsen medan fyndet är öppet",
		forst == nil or forst.Name ~= "RidaNuPrompt", table.concat(namn, ", "))
end

--[[ ══ 6. LEDSTEGET I DEN TRÅNGA BOXEN: DÖRREN SYNS UTAN ATT BLÄDDRA ═══ ]]
print("\n── 6. Ledsteget med sadel och träns buret: «Öppna — Dörr» står på första sidan ──")
do
	--[[ Tobias fynd i Studio: dörren försvann i boxen. Mätt på exakt-head: i
		ledsteget är dörren rad 1 på första sidan och X öppnar den. Provet
		kräver det UTTRYCKLIGEN, i det trängsta läget — sadel och träns buret,
		så att `SadlaPrompt` och `TransaPrompt` också finns på hästen. ]]
	local s = Preparation.nyState(HAST_ID, 1)
	for _, f in ipairs(Preparation.stegFaser()) do
		if f.id ~= "leda" then
			while true do
				local m = Preparation.nastaMoment(s, f.id)
				if not m then break end
				if not Preparation.utforMoment(s, f.id, m.id, HAST_ID) then break end
			end
		end
	end
	local nasta = Preparation.nasta(s)
	prova("förutsättning: ledsteget står på tur", nasta ~= nil and nasta.id == "leda", nasta and nasta.id)
	dorr:SetAttribute("SprakNyckel", "dorr.oppna")
	rev += 1
	local buren = { hastId = HAST_ID, hastnamn = "Trixie", delar = { "sadel", "trans" } }
	visa(Preparation.vy(s, Preparation.STATUS.FORBEREDER, rev, "Trixie", buren))

	local relevanta = {}
	for _, p in ipairs(N._relevanta()) do relevanta[p.Name] = true end
	prova("sadel- och tränsknapparna finns inte längre på hästen (stallet gör det)",
		relevanta.SadlaPrompt == nil and relevanta.TransaPrompt == nil,
		(function() local t = {} for n in pairs(relevanta) do table.insert(t, n) end table.sort(t) return table.concat(t, ",") end)())

	local forst = N._prompter()
	local namn = {}
	for _, p in ipairs(forst) do table.insert(namn, p.Name) end
	prova("dörren är den FÖRSTA handlingen på skärmen", forst[1] ~= nil and forst[1].Name == "DorrPrompt",
		table.concat(namn, ","))
	local sida = N._sida()
	prova("och den står på sida 1 — ingen bläddring", sida == 1, tostring(sida))
	prova("ingen sadla/tränsa/led-prompt trängs in efter dörren",
		forst[1] ~= nil and forst[1].Name == "DorrPrompt"
			and (forst[2] == nil or forst[2].Name == "RidaNuPrompt"),
		table.concat(namn, ","))
	local rader = N._rader()
	local harDorr = false
	for _, t in ipairs(rader) do if string.find(t, "Dörr", 1, true) or string.find(t, "Öppna", 1, true) then harDorr = true end end
	prova("och raden «Öppna — Dörr» ritas i panelen", harDorr, table.concat(rader, " | "))
end

print("")
if fel > 0 then
	print(("%d mätningar föll."):format(fel))
	error(("%d fel"):format(fel))
end
print(("klient-rida-fokus.spec: %d prov, alla gröna"):format(antal))
