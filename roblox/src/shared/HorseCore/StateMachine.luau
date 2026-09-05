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
	gait: string?,        -- den FAKTISKA gångarten, om anroparen vet den
}

function StateMachine:step(input: Input, dt: number): State
	self._held = math.max(0, self._held - dt)

	local landed = self._wasAirborne and not input.airborne
	self._wasAirborne = input.airborne

	--[[ GÅNGARTEN KOMMER UTIFRÅN NÄR ANROPAREN VET DEN.

	     Maskinen härledde den förut alltid ur tempot. Under ett
	     gångartsbyte är det fel källa: förloppet byter gångart vid
	     Transition.switchAt, alltså 55 % in, medan tempot passerar
	     bandgränsen tidigare. Maskinen satte då Trot medan resten av
	     spelet — kamera, telemetri, sväng — fortfarande sa skritt, och
	     travanimationen började för tidigt.

	     Uppmätt skillnad: bandet ~0,31 / 0,39 / 0,50 s mot förloppets
	     0,44 / 0,52 / 0,66 s. Det är en intern dubbel-sanning, och den
	     sortens sak är hela poängen med G02-A.

	     Tempot är kvar som källa när ingen gångart skickas in — då
	     gäller hysteresen i forSpeed, precis som förut. Tillstånden för
	     HÄNDELSER (Jump, Landing, Stopping, BackingUp, TurningInPlace)
	     rörs inte av det här: de avgörs nedan av mark, avsikt och tempo
	     och har företräde framför gångartstillståndet. ]]
	self.gait = input.gait or Gaits.forSpeed(math.abs(input.speed), self.gait)

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
