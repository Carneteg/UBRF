--!strict
--[[
	Tillståndsmaskinen.

	Skild från rörelsen med flit: den här modulen räknar aldrig fysik och
	rör aldrig en Instance. Den tar tempo, mark och avsikt in, och ger ett
	tillstånd ut. Det gör den testbar utan att spelet körs, och det gör att
	animationslagret kan lita på ett enda fält i stället för att gissa ur
	hastighetsvektorer.
]]

local Gaits = require(script.Parent.Gaits)

local StateMachine = {}
StateMachine.__index = StateMachine

export type State =
	"Idle" | "Walk" | "Trot" | "Canter" | "Gallop"
	| "Jump" | "Landing" | "Stopping" | "BackingUp" | "TurningInPlace"

local GAIT_STATE: { [string]: State } = {
	halt = "Idle", walk = "Walk", trot = "Trot",
	canter = "Canter", gallop = "Gallop",
}

--[[ Hur länge ett övergångstillstånd hålls kvar även om villkoret släpper.
     Utan dem blinkar Landing förbi på en bildruta och syns aldrig. ]]
local MIN_HOLD: { [string]: number } = {
	Jump = 0.10, Landing = 0.28, Stopping = 0.35, TurningInPlace = 0.20,
}

function StateMachine.new()
	return setmetatable({
		state = "Idle" :: State,
		gait = "halt",
		_held = 0,
		_wasAirborne = false,
	}, StateMachine)
end

export type Input = {
	speed: number,        -- m/s framåt, negativ vid backning
	turnRate: number,     -- rad/s
	airborne: boolean,
	braking: boolean,     -- ryttaren begär stopp
	jumpFired: boolean,
}

function StateMachine:step(input: Input, dt: number): State
	self._held = math.max(0, self._held - dt)

	local landed = self._wasAirborne and not input.airborne
	self._wasAirborne = input.airborne

	-- Gångarten följer tempot oavsett tillstånd, så animationslagret vet
	-- vad den ska landa tillbaka i efter ett hopp.
	self.gait = Gaits.forSpeed(math.abs(input.speed), self.gait)

	local next: State? = nil

	if input.jumpFired or input.airborne then
		next = "Jump"
	elseif landed then
		next = "Landing"
	elseif input.speed < -0.15 then
		next = "BackingUp"
	elseif input.braking and math.abs(input.speed) > 0.6 then
		next = "Stopping"
	elseif math.abs(input.speed) < 0.25 then
		next = if math.abs(input.turnRate) > 0.25 then "TurningInPlace" else "Idle"
	else
		next = GAIT_STATE[self.gait] or "Idle"
	end

	-- Ett tillstånd med minimitid får inte avbrytas i förtid, utom av hopp.
	if self._held > 0 and next ~= "Jump" then
		return self.state
	end

	if next ~= self.state then
		self.state = next :: State
		self._held = MIN_HOLD[next] or 0
	end
	return self.state
end

return StateMachine
