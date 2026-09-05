--!strict
--[[
	Inmatningen — tangenter, gamepad och peksk��rm till en Intent.

	Ingen spellogik här. Modulen översätter knappar till avsikt och inget
	annat, så att styrningen går att binda om utan att rörelsen rörs.

	W  framåt          S  ned i gångart, sedan stopp, sedan backa
	A/D styr           Shift  upp en gångart     Ctrl  ned en gångart
	Space hoppa        E  sitt upp/av
]]

local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Types = require(game:GetService("ReplicatedStorage").HorseCore.Types)

local Input = {}

--[[ Tangenterna och pekskärmen har varsitt axelpar, av samma skäl som
     gamepaden har sitt: skriver de i samma fält slår de ut varandra. En
     spelare som håller D och samtidigt drar spaken åt vänster ska få
     summan, inte den som råkade skriva sist. ]]
local state = {
	forward = 0,
	steer = 0,
	touchForward = 0,
	touchSteer = 0,
	gaitUp = false,
	gaitDown = false,
	jump = false,
	--[[ G02-B: TYGELN och PARADEN. `rein` är kontakten (Q eller höger
	     avtryckare — den senare analog, så halvt utslag ger halv
	     kontakt); `paradEdge` är halvhaltens flank. Pekskärmen skriver i
	     touchRein/touchParad vid sidan av, av samma skäl som forward och
	     steer har varsitt par: skriver de i samma fält slår de ut
	     varandra. ]]
	rein = 0,
	touchRein = 0,
	paradHeld = false,
	_paradEdge = false,
	touchParad = false,
	_upEdge = false,
	_downEdge = false,
}

local bound = false

local KEY_ACTIONS = {
	[Enum.KeyCode.W] = function(v) state.forward = if v then 1 else (if state.forward > 0 then 0 else state.forward) end,
	[Enum.KeyCode.S] = function(v) state.forward = if v then -1 else (if state.forward < 0 then 0 else state.forward) end,
	[Enum.KeyCode.A] = function(v) state.steer = if v then -1 else (if state.steer < 0 then 0 else state.steer) end,
	[Enum.KeyCode.D] = function(v) state.steer = if v then 1 else (if state.steer > 0 then 0 else state.steer) end,
}

local function onInput(_, inputState: Enum.UserInputState, obj: InputObject)
	local pressed = inputState == Enum.UserInputState.Begin
	local action = KEY_ACTIONS[obj.KeyCode]
	if action then
		action(pressed)
		return Enum.ContextActionResult.Sink
	end
	if obj.KeyCode == Enum.KeyCode.LeftShift or obj.KeyCode == Enum.KeyCode.ButtonR1 then
		if pressed and not state.gaitUp then state._upEdge = true end
		state.gaitUp = pressed
	elseif obj.KeyCode == Enum.KeyCode.LeftControl or obj.KeyCode == Enum.KeyCode.ButtonL1 then
		if pressed and not state.gaitDown then state._downEdge = true end
		state.gaitDown = pressed
	elseif obj.KeyCode == Enum.KeyCode.Space or obj.KeyCode == Enum.KeyCode.ButtonA then
		state.jump = pressed
	elseif obj.KeyCode == Enum.KeyCode.Q then
		--[[ Tangenten är av eller på; avtryckaren nedan är analog och
		     läggs till i consume(). Den som har gamepad doserar alltså
		     kontakten, den som har tangentbord får hel eller ingen —
		     samma förhållande som webbens Space mot pekskärmens spak. ]]
		state.rein = if pressed then 1 else 0
	elseif obj.KeyCode == Enum.KeyCode.F or obj.KeyCode == Enum.KeyCode.ButtonB then
		if pressed and not state.paradHeld then state._paradEdge = true end
		state.paradHeld = pressed
	end
	return Enum.ContextActionResult.Sink
end

function Input.bind()
	if bound then return end
	bound = true
	ContextActionService:BindAction("HorseControl", onInput, false,
		Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
		Enum.KeyCode.Space, Enum.KeyCode.LeftShift, Enum.KeyCode.LeftControl,
		Enum.KeyCode.Q, Enum.KeyCode.F,
		Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonR1, Enum.KeyCode.ButtonL1,
		Enum.KeyCode.ButtonB)
end

function Input.unbind()
	if not bound then return end
	bound = false
	ContextActionService:UnbindAction("HorseControl")
	state.forward, state.steer = 0, 0
	state.touchForward, state.touchSteer = 0, 0
	state.rein, state.touchRein = 0, 0
	state.paradHeld, state._paradEdge, state.touchParad = false, false, false
	state.gaitUp, state.gaitDown, state.jump = false, false, false
end

--[[ Gamepadens vänsterspak går in vid sidan av tangenterna, så att båda
     fungerar samtidigt utan att slå ut varandra. ]]
local function stick(): (number, number)
	for _, obj in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
		if obj.KeyCode == Enum.KeyCode.Thumbstick1 then
			local v = obj.Position
			local dead = 0.18
			local x = if math.abs(v.X) > dead then v.X else 0
			local y = if math.abs(v.Y) > dead then v.Y else 0
			return y, x
		end
	end
	return 0, 0
end

--[[ Höger avtryckare som ANALOG tygel. Den är en axel och inte en knapp
     på gamepaden, och det är hela poängen: kontakten ska gå att dosera,
     för det är den som avgör om yttertygeln bär svängen. Dödzonen är
     densamma som spakens. ]]
local function trigger(): number
	for _, obj in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
		if obj.KeyCode == Enum.KeyCode.ButtonR2 then
			local v = obj.Position.Z
			return if v > 0.10 then math.clamp(v, 0, 1) else 0
		end
	end
	return 0
end

--[[ Läser av och nollställer flankerna. Anropas exakt en gång per bildruta
     av klientens loop — kallas den två gånger tappas ett gångartsbyte. ]]
function Input.consume(): Types.Intent
	local padForward, padSteer = stick()
	local intent: Types.Intent = {
		forward = math.clamp(state.forward + padForward + state.touchForward, -1, 1),
		steer = math.clamp(state.steer + padSteer + state.touchSteer, -1, 1),
		gaitUp = state._upEdge,
		gaitDown = state._downEdge,
		jump = state.jump,
		rein = math.clamp(state.rein + trigger() + state.touchRein, 0, 1),
		parad = if (state._paradEdge or state.touchParad) then 1 else 0,
	}
	state._upEdge, state._downEdge = false, false
	state._paradEdge, state.touchParad = false, false
	return intent
end

--[[ För pekskärm: `TouchControls` kallar de här i stället för tangenter.
     Värdena är normaliserade avsikter i −1..1, precis som tangenternas och
     spakens, och läggs till dem i `consume` i stället för att ersätta dem. ]]
function Input.setTouch(forward: number, steer: number)
	state.touchForward = math.clamp(forward, -1, 1)
	state.touchSteer = math.clamp(steer, -1, 1)
end
function Input.setTouchRein(rein: number)
	state.touchRein = math.clamp(rein, 0, 1)
end
function Input.touchParad()
	state.touchParad = true
end
function Input.touchGait(up: boolean)
	if up then state._upEdge = true else state._downEdge = true end
end
function Input.touchJump()
	state.jump = true
	task.delay(0.15, function() state.jump = false end)
end

return Input
