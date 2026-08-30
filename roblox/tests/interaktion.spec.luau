--!nostrict
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

local jag = __lokalSpelare
local min, annans = hast("Toblerone"), hast("Cosmo M Z")
__tagged.Horse = { min, annans }

local function promptFor(model)
	for _, b in ipairs(model.Children) do
		if b.ClassName == "ProximityPrompt" then return b end
	end
	return nil
end

print("\n── G01: join-racet visar aldrig en falsk Sitt upp-knapp ──")
InteractionController.start(function() end)
local pMin, pAnnans = promptFor(min), promptFor(annans)
check("varje rigg fick en intern mount-prompt", pMin ~= nil and pAnnans ~= nil)
check("prompterna är dolda innan G01Enabled replikerats",
	pMin and pMin.Enabled == false and pAnnans and pAnnans.Enabled == false,
	"min=" .. tostring(pMin and pMin.Enabled) .. " annans=" .. tostring(pAnnans and pAnnans.Enabled))

print("\n── G01: förberedelse döljer mount ──")
jag:SetAttribute("G01Enabled", true)
jag:SetAttribute("G01Phase", "approach")
min:SetAttribute("AssignedUserId", jag.UserId)
check("approach: dold", promptFor(min).Enabled == false)
for _, fas in ipairs({ "check", "groom", "tack", "waiting_model" }) do
	jag:SetAttribute("G01Phase", fas)
	check(fas .. ": dold", promptFor(min).Enabled == false)
end

print("\n── G01: bara egen färdig häst erbjuder mount ──")
jag:SetAttribute("G01Phase", "ready_to_mount")
check("egen häst visar Sitt upp", promptFor(min).Enabled == true)
check("annan häst är dold", promptFor(annans).Enabled == false)
annans:SetAttribute("AssignedUserId", 999)
check("häst tilldelad annan är dold", promptFor(annans).Enabled == false)

print("\n── G01: mounted och global interaktionsspärr ──")
jag:SetAttribute("G01Phase", "mounted")
check("mount prompt dold medan man rider", promptFor(min).Enabled == false)
jag:SetAttribute("G01Phase", "ready_to_mount")
check("prompt återkommer efter avsittning", promptFor(min).Enabled == true)
InteractionController.setEnabled(false)
check("setEnabled(false) döljer allt", promptFor(min).Enabled == false)
InteractionController.setEnabled(true)
check("setEnabled(true) respekterar G01-regeln", promptFor(min).Enabled == true)

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("interaktion.spec: " .. fails .. " fel")
end
print("\nG01 interaktion: alla gröna")
