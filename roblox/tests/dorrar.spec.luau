--!nostrict
--[[
	WorldService — dörrbindningen och busy-vakten.

	Ingenting körde den här tjänsten. Två punkter i falsifieringslistan gick
	därför inte att svara på: att en dörr utan CFrame-attribut ska VÄGRA
	bindas i stället för att låtsas fungera, och att två spelare som trycker
	samtidigt inte får två tweens på samma dörrblad.

	Kör: python3 roblox/tests/build.py tests/dorrar.spec.luau
	     && luau roblox/tests/.build/dorrar.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local hel = __dorr("Hel dorr")
local utanCFrame = __dorr("Dorr utan CFrame", false, true)
local utanPrompt = __dorr("Dorr utan prompt", true, false)

WorldService.start()

print("\n── 3: en ofullständig dörr binds inte ──")
do
	--[[ Den ska VÄGRA, inte binda och låtsas. En dörr som ser interaktiv ut
		men aldrig rör sig är värre än en som säger ifrån. ]]
	local p = utanCFrame:FindFirstChild("DoorPrompt")
	p.Triggered._fire()
	check("dörr utan CFrame-attribut rör sig inte",
		utanCFrame:GetAttribute("DoorOpen") ~= true,
		tostring(utanCFrame:GetAttribute("DoorOpen")))
	check("ingen tween startades för den", #__pagaende == 0, #__pagaende .. " st")

	check("dörr utan DoorPrompt kraschar inte bindningen",
		utanPrompt:GetAttribute("DoorOpen") ~= true)
end

print("\n── En hel dörr fungerar ──")
do
	local p = hel:FindFirstChild("DoorPrompt")
	check("prompten säger Öppna från början", p.ActionText == "Öppna", p.ActionText)

	p.Triggered._fire()
	check("ett tryck startar en tween", #__pagaende == 1, #__pagaende .. " st")
	check("dörren är genomsläpplig under rörelsen", hel.CanCollide == false)

	__slutforTweens()
	check("dörren står som öppen efteråt", hel:GetAttribute("DoorOpen") == true)
	check("prompten säger Stäng nu", p.ActionText == "Stäng", p.ActionText)
	check("dörren är fysisk igen i slutläget", hel.CanCollide == true)

	p.Triggered._fire()
	__slutforTweens()
	check("ett andra tryck stänger den", hel:GetAttribute("DoorOpen") == false)
	check("prompten är tillbaka på Öppna", p.ActionText == "Öppna", p.ActionText)
end

print("\n── 4: två spelare trycker samtidigt ──")
do
	local p = hel:FindFirstChild("DoorPrompt")

	--[[ Första trycket startar en tween som INTE är klar. Andra trycket
		kommer medan den pågår — precis vad två spelare vid samma dörr gör.
		Utan busy-vakten blir det två tweens på samma dörrblad, och slutläget
		beror på vilken som råkar sluta sist. ]]
	p.Triggered._fire()
	check("första trycket startade en tween", #__pagaende == 1, #__pagaende .. " st")

	p.Triggered._fire()
	check("andra trycket under rörelsen startar INGEN andra tween",
		#__pagaende == 1, #__pagaende .. " st")

	__slutforTweens()
	check("dörren hamnade i ett läge, inte i två", hel:GetAttribute("DoorOpen") == true,
		tostring(hel:GetAttribute("DoorOpen")))

	--[[ Och efter att rörelsen är klar ska dörren gå att använda igen —
		busy-flaggan får inte fastna. ]]
	p.Triggered._fire()
	check("dörren går att använda igen efteråt", #__pagaende == 1, #__pagaende .. " st")
	__slutforTweens()
	check("den stängdes", hel:GetAttribute("DoorOpen") == false)
end

print("\n── Startraden ska avslöja en trasig uppsättning ──")
do
	--[[ Tre dörrar skapades, men bara EN av dem är hel. Räknaren ska visa den
		bundna, inte de skapade — annars är den samma sorts lögn som
		WorldBuild:s gamla dörrsiffra, som räknade öppningar i datan i stället
		för dörrar som blev dörrar. ]]
	check("bara den hela dörren är bunden", WorldService.boundCount() == 1,
		WorldService.boundCount() .. " st")

	--[[ Utan Anläggning/UBRF i workspace finns ingenting att jämföra mot, och
		då ska den säga nil — inte gissa en nolla, som hade läst som "bygget
		gjorde noll dörrar" och skickat felsökningen åt fel håll. ]]
	check("byggda dörrar är okänt utan modellen", WorldService.builtCount() == nil,
		tostring(WorldService.builtCount()))

	local rad, varning = WorldService.startupReport(0, nil, false)
	check("noll bundna dörrar ger en varning", varning ~= nil)
	check("och raden säger att spawnen saknas",
		string.find(rad, "SAKNAS") ~= nil, rad)

	local _, varning2 = WorldService.startupReport(3, 17, true)
	check("färre bundna än byggda ger en varning", varning2 ~= nil)
	check("varningen namnger båda talen",
		varning2 ~= nil and string.find(varning2, "14 av 17") ~= nil,
		tostring(varning2))

	local rad3, varning3 = WorldService.startupReport(17, 17, true)
	check("allt stämmer ger INGEN varning", varning3 == nil, tostring(varning3))
	check("och raden säger att spawnen hittades",
		string.find(rad3, "hittad") ~= nil, rad3)
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("dorrar.spec: " .. fails .. " fel")
end
print("\ndörrarna: alla gröna")
