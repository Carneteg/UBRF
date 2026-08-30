--!nostrict
--[[
	InteractionController — när "Sitt upp" får synas.

	Servern NEKAR alltid en otillåten uppsittning; det provas i
	gameplay.spec. Det här provar den andra halvan: att prompten inte ens
	ERBJUDS när den inte är relevant. En knapp som syns och sedan nekar är
	ett sämre spel än en knapp som håller sig borta.

	Kör: python3 roblox/tests/build.py tests/interaktion.spec.luau
	     && luau roblox/tests/.build/interaktion.spec.luau
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

local function hast(namn)
	local m = __medAttributsignal(__instans("Model", namn))
	m.Parent = { Name = "Workspace" }
	m:SetAttribute("HorseName", namn)
	m:SetAttribute("AssignedUserId", 0)
	return m
end

--[[ LocalPlayer kommer ur stubben: klientmodulen läser den vid laddning. ]]
local jag = __lokalSpelare

local min, annans = hast("Alfa"), hast("Beta")
__tagged.Horse = { min, annans }

local function promptFor(model)
	--[[ Prompten hänger på riggens root, som i stubben ÄR modellen. ]]
	for _, b in ipairs(model.Children) do
		if b.ClassName == "ProximityPrompt" then return b end
	end
	return nil
end

print("\n── 7 & 8: prompten innan vi vet något ──")
--[[ Servern har inte hunnit replikera G01Enabled ännu. Det är det verkliga
	läget de första bildrutorna efter join. ]]
InteractionController.start(function() end)

local pMin, pAnnans = promptFor(min), promptFor(annans)
check("varje häst fick en prompt", pMin ~= nil and pAnnans ~= nil)
check("ingen prompt erbjuds innan serverns läge är känt",
	pMin and pMin.Enabled == false and pAnnans and pAnnans.Enabled == false,
	"min=" .. tostring(pMin and pMin.Enabled) .. " annans=" .. tostring(pAnnans and pAnnans.Enabled))

print("\n── 7: prompten är dold under förberedelsen ──")
jag:SetAttribute("G01Enabled", true)
jag:SetAttribute("G01Phase", "approach")
min:SetAttribute("AssignedUserId", jag.UserId)
check("min häst visar inte Sitt upp i approach", promptFor(min).Enabled == false)
for _, fas in ipairs({ "check", "groom", "tack" }) do
	jag:SetAttribute("G01Phase", fas)
	check("min häst visar inte Sitt upp i " .. fas, promptFor(min).Enabled == false)
end

print("\n── 7: prompten visas när förberedelsen är klar ──")
jag:SetAttribute("G01Phase", "ready_to_mount")
check("min häst visar Sitt upp i ready_to_mount", promptFor(min).Enabled == true)

print("\n── 8: andra hästar erbjuder aldrig uppsittning ──")
check("annans häst är dold i ready_to_mount", promptFor(annans).Enabled == false)
annans:SetAttribute("AssignedUserId", 999)
check("häst tilldelad någon annan är dold", promptFor(annans).Enabled == false)

print("\n── 10: efter avsittning går det att sitta upp igen ──")
jag:SetAttribute("G01Phase", "mounted")
check("prompten är dold medan man rider", promptFor(min).Enabled == false)
jag:SetAttribute("G01Phase", "ready_to_mount")
check("prompten kommer tillbaka efter avsittning", promptFor(min).Enabled == true)

print("\n── setEnabled stänger av allt ──")
InteractionController.setEnabled(false)
check("min häst döljs när interaktion stängs av", promptFor(min).Enabled == false)
InteractionController.setEnabled(true)
check("och kommer tillbaka när den slås på", promptFor(min).Enabled == true)

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("interaktion.spec: " .. fails .. " fel")
end
print("\nG01.1 interaktion: alla gröna")
