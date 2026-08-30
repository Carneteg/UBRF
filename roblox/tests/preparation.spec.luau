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

print("\n── G01: mount är låst före förberedelse ──")
for _, phase in ipairs({ "waiting_horse", "waiting_model", "approach", "check", "groom", "tack" }) do
	check("ingen mount i " .. phase, not Preparation.mountUnlocked(phase))
end
check("mount låses upp vid ready_to_mount", Preparation.mountUnlocked("ready_to_mount"))
check("mounted räknas som upplåst", Preparation.mountUnlocked("mounted"))

print("\n── G01: momenten måste göras i rätt ordning ──")
local phase = "approach"
for _, step in ipairs({
	{ action = "approach", want = "check" },
	{ action = "check", want = "groom" },
	{ action = "groom", want = "tack" },
	{ action = "tack", want = "ready_to_mount" },
}) do
	local ok, nextPhase, feedback = Preparation.advance(phase, step.action)
	check(step.action .. " godkänns i " .. phase, ok == true)
	check(step.action .. " går till " .. step.want, nextPhase == step.want,
		string.format("(fick %s)", tostring(nextPhase)))
	check(step.action .. " ger pedagogisk feedback", type(feedback) == "string" and #feedback > 12)
	phase = nextPhase
end
check("hela sekvensen låser upp mount", Preparation.mountUnlocked(phase))

print("\n── G01: fel moment får inte hoppa progression ──")
do
	local ok, nextPhase = Preparation.advance("approach", "tack")
	check("tack kan inte hoppa över visitering/rykt", ok == false)
	check("fasen står kvar", nextPhase == "approach")
end
do
	local ok, nextPhase = Preparation.advance("check", "groom")
	check("groom kan inte hoppa över check", ok == false)
	check("check står kvar", nextPhase == "check")
end
do
	local ok, nextPhase = Preparation.advance("ready_to_mount", "tack")
	check("inga extra prep-actions efter klar", ok == false)
	check("ready_to_mount står kvar", nextPhase == "ready_to_mount")
end

print("\n── G01: texterna täcker alla spelbara/väntande lägen ──")
for _, phaseName in ipairs({ "waiting_horse", "waiting_model", "approach", "check", "groom", "tack", "ready_to_mount" }) do
	check("objective finns för " .. phaseName,
		type(Preparation.OBJECTIVE[phaseName]) == "string" and #Preparation.OBJECTIVE[phaseName] > 10)
end
for _, phaseName in ipairs({ "approach", "check", "groom", "tack" }) do
	check("actiontext finns för " .. phaseName,
		type(Preparation.ACTION_TEXT[phaseName]) == "string" and #Preparation.ACTION_TEXT[phaseName] > 2)
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("preparation.spec: " .. fails .. " fel")
end
print("\nG01 preparation: alla gröna")
