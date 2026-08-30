--!strict
--[[
	Preparation — motoroberoende regler för G01.1.

	Modulen innehåller ingen UI, fysik eller Roblox-världslogik. Servern äger
	progressionen, medan klienten bara visar samma ordning och mål.
]]

local Preparation = {}

local ORDER: { string } = {
	"approach",
	"check",
	"groom",
	"tack",
	"ready_to_mount",
}

local ACTION_FOR_PHASE: { [string]: string } = {
	approach = "approach",
	check = "check",
	groom = "groom",
	tack = "tack",
}

local NEXT_PHASE: { [string]: string } = {
	approach = "check",
	check = "groom",
	groom = "tack",
	tack = "ready_to_mount",
}

local ACTION_TEXT: { [string]: string } = {
	approach = "Hälsa lugnt",
	check = "Visitera",
	groom = "Rykta",
	tack = "Gör i ordning",
}

local OBJECTIVE: { [string]: string } = {
	waiting_horse = "Väntar på en ledig häst.",
	waiting_model = "Din häst är tilldelad, men hennes ridmodell finns inte i världen ännu.",
	approach = "Gå fram lugnt till din häst. Låt hästen se och höra dig.",
	check = "Gör en snabb visitering: titta på ben, kropp och hur hästen verkar må.",
	groom = "Rykta hästen och få bort smuts, särskilt där sadel och gjord ska ligga.",
	tack = "Gör i ordning hästen med rätt utrustning innan ridningen.",
	ready_to_mount = "Hästen är förberedd. Nu kan du sitta upp när du är på rätt plats.",
	mounted = "Bra förberett. Rid mjukt och känn skillnaden mellan gångarterna.",
}

local FEEDBACK: { [string]: string } = {
	approach = "Bra. En häst ska inte överraskas från en blind vinkel.",
	check = "Bra. En snabb kontroll före ridning kan upptäcka att något inte känns som vanligt.",
	groom = "Bra. Smuts under sadel eller gjord kan skava och göra hästen obekväm.",
	tack = "Klart. Rätt utrustning och en väl förberedd häst hör ihop med bra ridning.",
}

Preparation.ORDER = ORDER
Preparation.ACTION_FOR_PHASE = ACTION_FOR_PHASE
Preparation.NEXT_PHASE = NEXT_PHASE
Preparation.ACTION_TEXT = ACTION_TEXT
Preparation.OBJECTIVE = OBJECTIVE
Preparation.FEEDBACK = FEEDBACK

function Preparation.expectedAction(phase: string): string?
	return ACTION_FOR_PHASE[phase]
end

function Preparation.advance(phase: string, action: string): (boolean, string, string?)
	local expected = Preparation.expectedAction(phase)
	if not expected then
		return false, phase, "Det finns inget förberedelsemoment i det här läget."
	end
	if action ~= expected then
		return false, phase, "Gör momenten i ordning."
	end
	return true, NEXT_PHASE[phase], FEEDBACK[action]
end

function Preparation.mountUnlocked(phase: string): boolean
	return phase == "ready_to_mount" or phase == "mounted"
end

return Preparation
