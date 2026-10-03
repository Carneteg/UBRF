--!nostrict
--[[
	#274 — STOPPKORTET ÄR INGEN ÅTERVÄNDSGRÄND, PÅ KLIENTEN.

	Servern pekar ut en frisk häst när hästen är stoppad (`vy.ersattare`).
	Klienten ska då visa EN knapp, «Fortsätt med <namn>», som skickar
	`FortsattHast` utan argument — klienten väljer aldrig häst. Finns ingen
	ersättare står beskedet i klartext och ingen tom knapp ritas.

	Knappen är inget moment vid hästen utan ett byte AV henne, så den får
	inte hänga på räckvidden: spelaren som gått ifrån den stoppade hästen
	ska ändå se den.

	NOT TESTED: hur det ser ut och känns på en riktig skärm (Tobias speltest).

	Kör: python3 roblox/tests/build.py tests/klient-fortsatt.spec.luau
	     && luau roblox/tests/.build/klient-fortsatt.spec.luau
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

local rev = 0
--[[ En stoppad vy, byggd av samma regel som servern. `ersattare` sätts av
	servern efter `Preparation.vy` — så gör provet också. ]]
local function stoppadVy(ersattare)
	local s = Preparation.nyState(HAST_ID, 1)
	s.fynd = "mun"
	s.fyndSett = true
	local okSvar = Preparation.svaraFynd(s, (function()
		for _, v in ipairs(Preparation.fyndSvar()) do if not v.fel then return v.id end end
	end)())
	prova("förutsättning: rätt svar stoppar hästen", okSvar == true and s.stoppad ~= nil)
	rev += 1
	local v = Preparation.vy(s, Preparation.STATUS.STOPPAD, rev, "Trixie")
	if ersattare then v.ersattare = ersattare end
	return v, s
end

--[[ ══ 1. MED ERSÄTTARE: EN KNAPP MED HENNES NAMN ═══════════════════════ ]]
print("\n── 1. Stopp med frisk ersättare: «Fortsätt med Replay» ──")
do
	PC.tillampa(stoppadVy("Replay"))
	PC.uppdateraKontext()
	local synliga = PC._synligaMoment()
	prova("EXAKT en rad i panelen, och det är vägen vidare",
		#synliga == 1 and synliga[1] == "fortsatt", table.concat(synliga, ", "))
	local data = PC.panel() or {}
	local val = (data.val or {})[1]
	prova("knappen bär den friska hästens namn",
		val ~= nil and val.text == Sprak.t("hud.fortsatt_med", "Replay"), val and val.text)
	prova("och den är lyft som det enda att trycka på", val ~= nil and val.paTur == true)
	prova("rubriken är fortfarande «Ridläraren tar över»",
		PC._ytor().rubrik.Text == Sprak.t("hud.lararen_tar_over"), PC._ytor().rubrik.Text)
	prova("panelen visas", PC._ytor().interaktion.Visible == true)

	--[[ Spelaren har gått ifrån den stoppade hästen. ]]
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position + Vector3.new(80, 0, 0))
	PC.uppdateraKontext()
	prova("utom räckhåll för den stoppade hästen: knappen finns kvar",
		PC._ytor().interaktion.Visible == true and PC._synligaMoment()[1] == "fortsatt",
		tostring(PC._synligaMoment()[1]))
	local d2 = (PC.panel() or {}).val
	prova("och den är inte en död knapp", d2 ~= nil and d2[1] ~= nil and d2[1].aktiv == true)

	local remote = Net.get("FortsattHast")
	local fore = remote.InvokeServer
	local anrop = {}
	remote.InvokeServer = function(_, ...)
		table.insert(anrop, select("#", ...))
		return true, nil, "replay"
	end
	if d2 and d2[1] and d2[1].skicka then d2[1].skicka() end
	if type(__senasteDelay) == "function" then __senasteDelay() end
	prova("ett tryck skickar FortsattHast EN gång, utan argument — klienten väljer inte häst",
		#anrop == 1 and anrop[1] == 0, #anrop .. " anrop")
	remote.InvokeServer = fore
	kropp.CFrame = CFrame.new(hastRot.CFrame.Position)
end

--[[ ══ 2. UTAN ERSÄTTARE: ETT BESKED, INGEN TOM KNAPP ═══════════════════ ]]
print("\n── 2. Stopp utan frisk häst: besked i klartext ──")
do
	local vyUtan, sUtan = stoppadVy(nil)
	PC.tillampa(vyUtan)
	PC.uppdateraKontext()
	local synliga = PC._synligaMoment()
	prova("inga rader — ingen tom knapp", #synliga == 0, table.concat(synliga, ", "))
	local text = PC._ytor().instruktion.Text
	prova("beskedet säger att ingen frisk häst finns just nu",
		string.find(text, Sprak.t("forb.stopp_ingen_frisk"), 1, true) ~= nil, text)
	prova("och fyndet står kvar i texten, så spelaren ser varför",
		string.find(text, sUtan.stoppad, 1, true) ~= nil, text)
end

--[[ ══ 3. KNAPPEN FÖLJER MED NÄSTA VY ═══════════════════════════════════ ]]
print("\n── 3. Efter bytet: knappen ligger inte kvar ──")
do
	local s = Preparation.nyState("replay", 2)
	rev += 1
	PC.tillampa(Preparation.vy(s, Preparation.STATUS.FORBEREDER, rev, "Replay"))
	PC.uppdateraKontext()
	local synliga = PC._synligaMoment()
	local kvar = false
	for _, id in ipairs(synliga) do if id == "fortsatt" then kvar = true end end
	prova("vanlig vy för den friska hästen: ingen «fortsatt»-rad", not kvar, table.concat(synliga, ", "))
end

print("")
if fel > 0 then
	print(("%d mätningar föll."):format(fel))
	error(("%d fel"):format(fel))
end
print(("klient-fortsatt.spec: %d prov, alla gröna"):format(antal))
