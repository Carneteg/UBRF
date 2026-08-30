--!nostrict
--[[
	G01.1 — falsifierbara regler för förberedelsen före uppsittning.

	Den här specen testar produktionsmodulen direkt: ordningen får inte gå att
	hoppa över, fel action får inte flytta fasen, och uppsittning låses först
	när de fyra momenten faktiskt är klara.
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

print("\n── G01.1: uppsittning är låst före förberedelse ──")
for _, phase in ipairs({ "waiting_horse", "approach", "check", "groom", "tack" }) do
	check("ingen mount i " .. phase, not Preparation.mountUnlocked(phase))
end
check("mount låses upp vid ready_to_mount", Preparation.mountUnlocked("ready_to_mount"))
check("mounted räknas som redan upplåst", Preparation.mountUnlocked("mounted"))

print("\n── G01.1: momenten måste göras i rätt ordning ──")
local phase = "approach"
local sequence = {
	{ action = "approach", want = "check" },
	{ action = "check", want = "groom" },
	{ action = "groom", want = "tack" },
	{ action = "tack", want = "ready_to_mount" },
}

for _, step in ipairs(sequence) do
	local ok, nextPhase, feedback = Preparation.advance(phase, step.action)
	check(step.action .. " godkänns i " .. phase, ok == true)
	check(step.action .. " går till " .. step.want, nextPhase == step.want,
		string.format("(fick %s)", tostring(nextPhase)))
	check(step.action .. " ger pedagogisk feedback", type(feedback) == "string" and #feedback > 12)
	phase = nextPhase
end
check("hela sekvensen låser upp mount", Preparation.mountUnlocked(phase))

print("\n── G01.1: fel moment får inte hoppa progression ──")
do
	local ok, nextPhase = Preparation.advance("approach", "tack")
	check("tack kan inte hoppa över visitering/rykt", ok == false)
	check("fasen står kvar efter hoppförsök", nextPhase == "approach")
end

do
	local ok, nextPhase = Preparation.advance("check", "groom")
	check("groom kan inte hoppa över check", ok == false)
	check("check står kvar efter fel action", nextPhase == "check")
end

do
	local ok, nextPhase = Preparation.advance("ready_to_mount", "tack")
	check("inga extra prep-actions efter klar", ok == false)
	check("ready_to_mount står kvar", nextPhase == "ready_to_mount")
end

print("\n── G01.1: klienttexterna täcker varje spelbart steg ──")
for _, phaseName in ipairs({ "approach", "check", "groom", "tack", "ready_to_mount" }) do
	check("objective finns för " .. phaseName,
		type(Preparation.OBJECTIVE[phaseName]) == "string" and #Preparation.OBJECTIVE[phaseName] > 10)
end
for _, phaseName in ipairs({ "approach", "check", "groom", "tack" }) do
	check("actiontext finns för " .. phaseName,
		type(Preparation.ACTION_TEXT[phaseName]) == "string" and #Preparation.ACTION_TEXT[phaseName] > 2)
end

if fails > 0 then
	error(string.format("%d G01.1-mätningar föll", fails))
end
print("\nG01.1 preparation: alla gröna")
