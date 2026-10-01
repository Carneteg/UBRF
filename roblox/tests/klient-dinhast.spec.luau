--!nostrict
--[[ VÄGVISAREN TILL DEN TILLDELADE HÄSTEN — docs/ASSIGNED-HORSE-GUIDE-CONTRACT.md.

	Tobias i Play (2026-09-28): det gick inte att se vilken häst han skulle
	gå till. Studio visade två fel: skylten var liten (160×44 px, ingen pil,
	120 studs) och FÖRSVANN för gott efter en respawn (`ResetOnSpawn`).

	Specen kör `init.client.luau` på riktigt och matar SERVERNS vy genom
	`PreparationController.tillampa`, som klient-burenstatus.spec. Hästar och
	karaktär är bänkinstanser; loopen är klientens egen Heartbeat.

	VAD BÄNKEN INTE KAN: om pilen SYNS tydligt för ett öga (storlek, färg,
	kontrast på PC/iPad/iPhone). Det står på Tobias checklista. ]]
local fel, total = 0, 0
local function prova(vad, ok, detalj)
	total += 1
	if not ok then fel += 1 end
	print((if ok then "  OK   " else "  FEL  ") .. vad .. (if detalj then "  " .. tostring(detalj) else ""))
end
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CS = game:GetService("CollectionService")
local p = Players.LocalPlayer
local gui = p:WaitForChild("PlayerGui")
Sprak.satLocale("sv-se")

local rev = 0
local function vy(id, namn)
	rev += 1
	return { status = "preparing", hastId = id, hastnamn = namn,
		steg = {}, nasta = nil, moment = {}, nastaMoment = nil,
		fynd = nil, svar = {}, stoppad = nil, redo = false, burenUtrustning = nil, rev = rev }
end
local function bildrutor(sek)
	local dt = 1 / 30
	for _ = 1, math.floor(sek / dt) do RunService.Heartbeat:Fire(dt) end
end
local function del(namn, pos, forlder)
	local d = Instance.new("Part")
	d.Name = namn
	d.CFrame = CFrame.new(pos)
	d.Parent = forlder
	return d
end
local rotK
local function karaktar(pos)
	local k = Instance.new("Model"); k.Name = "Spelare"
	rotK = del("HumanoidRootPart", pos, k)
	k.PrimaryPart = rotK
	k.Parent = workspace
	p.Character = k
	return k
end
local function flytta(pos) rotK.CFrame = CFrame.new(pos) end
local function hast(id, namn, pos)
	local m = Instance.new("Model"); m.Name = namn
	local r = del("HumanoidRootPart", pos, m)
	m.PrimaryPart = r
	m:SetAttribute("HorseId", id); m:SetAttribute("HorseName", namn)
	m.Parent = workspace
	CS:AddTag(m, "Horse")
	return m, r
end
local function skyltar()
	local ut = {}
	for _, b in ipairs(gui._barn or {}) do if b.Name == "DinHastSkylt" then table.insert(ut, b) end end
	return ut
end
local function skylten() return skyltar()[1] end

print("\nVÄGVISAREN TILL DEN TILLDELADE HÄSTEN\n")

print("── 1. Bara den tilldelade hästen, tydligt, från långt håll ──")
local trixie, trixieRot = hast("trixie", "Trixie", Vector3.new(100, 0, 0))
local _troy, troyRot = hast("troy", "Troy", Vector3.new(40, 0, 0))
karaktar(Vector3.new(0, 0, 0))
PreparationController.tillampa(vy("trixie", "Trixie"))
bildrutor(1)
do
	local b = skylten()
	prova("exakt EN skylt", #skyltar() == 1, #skyltar())
	prova("den sitter på den tilldelade hästen, inte på Troy", b and b.Adornee == trixieRot and b.Adornee ~= troyRot)
	prova("synlig på 100 studs", b and b.Enabled == true)
	local pil = b and b:FindFirstChild("Pil")
	prova("en stor pil ▼ finns", pil ~= nil and pil.Text == "▼" and pil.TextSize >= 40, pil and pil.TextSize)
	local ram = b and b:FindFirstChild("Ram")
	local namn = ram and ram:FindFirstChild("Namn")
	prova("namnet står på skylten", namn ~= nil and namn.Text == "Trixie", namn and namn.Text)
	prova("alltid överst, räckvidd över hela anläggningen, fast pixelstorlek",
		b and b.AlwaysOnTop == true and b.MaxDistance >= 1000 and b.Size.X.Offset >= 200 and b.Size.X.Scale == 0,
		b and (tostring(b.MaxDistance) .. " / " .. tostring(b.Size)))
	prova("överlever respawn: ResetOnSpawn = false", b and b.ResetOnSpawn == false)
end

print("\n── 2. Framme: släckt; längre bort igen: tänd ──")
do
	flytta(Vector3.new(95, 0, 0)); bildrutor(0.5)
	prova("5 studs från hästen: släckt", skylten() and skylten().Enabled == false)
	flytta(Vector3.new(0, 0, 0)); bildrutor(0.5)
	prova("100 studs bort igen: tänd", skylten() and skylten().Enabled == true)
end

print("\n── 3. Ledning och ritt: släckt, sedan tillbaka ──")
do
	DinHast.satLedstatus("Trixie"); bildrutor(0.5)
	prova("under ledningen: släckt", skylten().Enabled == false)
	DinHast.satLedstatus(nil); bildrutor(0.5)
	prova("kopplet släppt: tänd igen", skylten().Enabled == true)
	DinHast.satDold(true); bildrutor(0.5)
	prova("uppsutten (dold): släckt", skylten().Enabled == false)
	DinHast.satDold(false); bildrutor(0.5)
	prova("avsutten, långt bort: tänd igen", skylten().Enabled == true)
end

print("\n── 4. Respawn: skylten raderas — och byggs om ──")
do
	skylten():Destroy()
	prova("KONTROLL: skylten är borta ur PlayerGui", #skyltar() == 0)
	karaktar(Vector3.new(0, 0, 0))
	bildrutor(1.2)
	local b = skylten()
	prova("byggd igen inom en sekund, en enda, på rätt häst", #skyltar() == 1 and b.Adornee == trixieRot and b.Enabled == true)
end

print("\n── 5. Strömning: modellen ersätts; en ny tilldelning utan modell ──")
do
	trixie:Destroy()
	bildrutor(0.5)
	prova("modellen borta: skylten släckt (ingen gissning)", #skyltar() == 0 or skylten().Enabled == false)
	local _ny, nyRot = hast("trixie", "Trixie", Vector3.new(120, 0, 0))
	bildrutor(1)
	prova("ny modell med samma id: skylten följer den nya", #skyltar() == 1 and skylten().Adornee == nyRot
		and skylten().Enabled == true)
	PreparationController.tillampa(vy("cosmo", "Cosmo"))
	bildrutor(1)
	prova("ny tilldelning utan modell: ingen tänd skylt på den gamla hästen",
		#skyltar() == 0 or skylten().Enabled == false or skylten().Adornee ~= nyRot)
	local _c, cosmoRot = hast("cosmo", "Cosmo", Vector3.new(-80, 0, 0))
	bildrutor(1)
	prova("modellen strömmar in: skylten sitter på Cosmo", #skyltar() == 1 and skylten().Adornee == cosmoRot
		and skylten().Enabled == true)
	prova("och aldrig på Troy", skylten().Adornee ~= troyRot)
end

print("")
if fel > 0 then
	error(("%d mätning(ar) föll."):format(fel), 0)
end
print(("klient-dinhast.spec: %d prov, alla gröna"):format(total))
