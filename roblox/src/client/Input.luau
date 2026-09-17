--!strict
--[[
	Inmatningen — tangenter, gamepad och pekskärm till en Intent.

	Ingen spellogik här. Modulen översätter knappar till avsikt och inget
	annat, så att styrningen går att binda om utan att rörelsen rörs.

	══ DRIV OCH BROMS ═══════════════════════════════════════════════════

	Arkitekturbeslut 2026-09-17: ridningen har TVÅ kontextuella handlingar
	och inga egna knappar. `ActionDriv` och `ActionBroms` binds i
	`ContextActionService` med `createTouchButton = true`, så att samma två
	handlingar är W/↑ vid tangentbordet, R1/L1 på handkontrollen och två av
	Roblox EGNA pekknappar på iPad. En egen `TextButton` i en egen
	`ScreenGui` är uttryckligen förbjuden — det var precis den panel som
	föll på fysisk QA.

	Båda är IMPULSER. Ett tryck är en hjälp, alltså ETT steg i trappan

	    Rygga ↔ Halt ↔ Skritt ↔ Trav ↔ Galopp

	— aldrig en gaspedal man håller inne. Hästen fortsätter i gångarten
	utan att spelaren rör något: `MovementController` håller gångartens
	hemtempo, och det gjorde den redan. Det är därför impulsmodellen
	fungerar utan att rörelsen skrivs om.

	W OCH S SKRIVER INTE LÄNGRE I `forward`. Framåtaxeln är kvar, men den
	är spakens och handkontrollens, och den flyttar tempot INOM gångartens
	band — den väljer ingen gångart längre. Att en tangent både valde
	gångart och sköt tempot var det som gjorde skrivbordet och pekytan
	till två olika spel.

	A/D styr          Space hoppa       Q tygel      F halvhalt
	Z/C sits          E sitt upp/av
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
	--[[ `gaitUp`/`gaitDown` som HÅLLNA tillstånd är borta. De fanns för
	     att Shift och Ctrl var knappar man kunde ligga kvar på; nu är
	     båda handlingarna impulser, och det enda som finns är flanken. ]]
	jump = false,
	--[[ G02-B: TYGELN och PARADEN. `rein` är kontakten (Q eller höger
	     avtryckare — den senare analog, så halvt utslag ger halv
	     kontakt); `paradEdge` är halvhaltens flank. Pekskärmen skriver i
	     touchRein/touchParad vid sidan av, av samma skäl som forward och
	     steer har varsitt par: skriver de i samma fält slår de ut
	     varandra. ]]
	rein = 0,
	touchRein = 0,
	--[[ G02-B, senior review #87: SITSEN som egen axel. −1 lätt (avlastad,
	     framåt), 0 normal, 1 djup. Z och C på tangentbord; vänster
	     avtryckare (analog) för den djupa sitsen på gamepad. Shift och
	     Ctrl är gångartsknappar sedan Gate 01 och rörs inte.

	     Sitsen är en balansmodifierare: sitter man ned i bågen bär man
	     hästen, sitter man lätt får hon bära den själv. Utan axeln kunde
	     Roblox inte ha den delen av modellen alls. ]]
	--[[ KNAPPSTATUS, INTE ETT DELAT AXELVÄRDE (Jules QA-fynd, #89).
	     Z och C skrev förut båda direkt i `seat`, och den som släpptes
	     sist bestämde. Håll Z (lätt) → tryck C (djup) → släpp C: axeln
	     gick till 0 fastän Z fortfarande var nedtryckt. Nu bokförs vilken
	     tangent som FAKTISKT är nere, och axeln HÄRLEDS ur det — samma
	     sak varje gång oavsett ordning.

	     Hålls båda vinner den djupa sitsen: det är den som gör något med
	     hästen (bär bågen), medan den lätta sitsen är att låta bli.

	     [KÄND, EJ ÅTGÄRDAD] W/S och A/D har kvar samma sist-skriven-
	     vinner-mönster i KEY_ACTIONS. Det är Gate 01:s inputlager och
	     ligger utanför G02-B:s scope; jag rapporterar det i stället för
	     att bredda den här PR:en på eget initiativ. ]]
	seatLight = false,
	seatDeep = false,
	touchSeat = 0,
	paradHeld = false,
	_paradEdge = false,
	touchParad = false,
	_upEdge = false,
	_downEdge = false,
	--[[ IMPULSSPÄRREN. Kontraktet kräver 0,5–0,8 s per handling, så att
	     den som hamrar på DRIV inte kan hoppa halt → galopp på tre
	     bildrutor. Spärren är PER HANDLING och inte gemensam: att bromsa
	     direkt efter ett driv är en riktig ridning — hon gav för mycket
	     och tar tillbaka — medan två driv i rad är att spamma.

	     `-math.huge` gör första trycket fritt oavsett när klockan står. ]]
	_drivSenast = -math.huge,
	_bromsSenast = -math.huge,
}

local bound = false

--[[ W OCH S ÄR BORTA HÄRIFRÅN MED FLIT. De är `ActionDriv` och
     `ActionBroms` nedan, alltså impulser i gångartstrappan. Låg de kvar
     här hade ett tryck gjort två saker samtidigt — bytt gångart OCH
     skjutit tempot — och det var precis vad som gjorde trappan omöjlig
     att stega ett steg i taget. ]]
local KEY_ACTIONS = {
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
	if obj.KeyCode == Enum.KeyCode.Space or obj.KeyCode == Enum.KeyCode.ButtonA then
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
	elseif obj.KeyCode == Enum.KeyCode.Z then
		state.seatLight = pressed
	elseif obj.KeyCode == Enum.KeyCode.C then
		state.seatDeep = pressed
	end
	return Enum.ContextActionResult.Sink
end

--[[ ══ DE TVÅ KONTEXTUELLA HANDLINGARNA ═══════════════════════════════

     Namnen är kontraktets, ordagrant, för att en grind ska kunna leta
     efter dem och för att `ContextActionService` ska kunna adressera dem
     utifrån — `SetTitle`, `SetPosition` och `GetButton` tar alla
     handlingens namn. ]]
Input.DRIV = "ActionDriv"
Input.BROMS = "ActionBroms"
--[[ Avsittningen är ingen ridhjälp och binds inte här — `init.client`
     äger den, för det är där `begarAvsittning` finns. Namnet står
     ändå hos de andra två, så att `TouchControls` kan klä knappen
     utan att känna till klientens huvudskript. ]]
Input.AVSITT = "ActionSittAv"

--[[ Spärren, i sekunder. Kontraktet ger spannet 0,5–0,8; 0,60 ligger i
     mitten. Lägre och hamrandet går igenom, högre och en ärlig
     nedstegring från galopp till halt börjar kännas som att knappen
     hänger sig. ]]
Input.IMPULS_SPARR = 0.60

--[[ Klockan är utbytbar, och det är enda skälet den har ett namn.

     Spärren är en TIDSREGEL. Ett prov som inte kan flytta tiden kan bara
     mäta halva den — att andra trycket stoppas — aldrig att det släpps
     igenom när tiden gått. Med den här raden kan provet mäta båda
     halvorna utan att sviten sover en sekund per mätning. ]]
Input._klocka = os.clock

--[[ En impuls i trappan, spärrad. Returnerar om den faktiskt gick in, så
     att både provet och ett framtida ljud-/haptiklager kan skilja "hon
     gav en hjälp" från "hon hamrade". ]]
local function impuls(upp: boolean): boolean
	local nu = Input._klocka()
	local senast = if upp then state._drivSenast else state._bromsSenast
	if nu - senast < Input.IMPULS_SPARR then
		return false
	end
	if upp then
		state._drivSenast = nu
		state._upEdge = true
	else
		state._bromsSenast = nu
		state._downEdge = true
	end
	return true
end

function Input.drivImpuls(): boolean
	return impuls(true)
end
function Input.bromsImpuls(): boolean
	return impuls(false)
end

--[[ Nollar spärren. Anropas vid av- och uppsittning: den som satt av mitt
     i en spärr ska inte sitta upp och få första hjälpen slukad. ]]
function Input.nollaImpulsSparr()
	state._drivSenast, state._bromsSenast = -math.huge, -math.huge
end

--[[ Handlingarna tar BARA `Begin`. Ett släpp är inte en hjälp, och
     `Change` finns inte på en tangent. Att svara `Sink` på alla tre är
     ändå rätt: handlingen äger knappen så länge den är bunden. ]]
local function onDriv(_, inputState: Enum.UserInputState, _obj: InputObject)
	if inputState == Enum.UserInputState.Begin then Input.drivImpuls() end
	return Enum.ContextActionResult.Sink
end
local function onBroms(_, inputState: Enum.UserInputState, _obj: InputObject)
	if inputState == Enum.UserInputState.Begin then Input.bromsImpuls() end
	return Enum.ContextActionResult.Sink
end

function Input.bind()
	if bound then return end
	bound = true
	--[[ SPÄRREN NOLLAS I `unbind`, INTE HÄR.

	     Ett anrop stod på den här raden också. Det gjorde ingenting:
	     avsittningen går alltid genom `unbind`, och en första uppsittning
	     möter `-math.huge`. Falsifieringen visade det — mutationen som tog
	     bort raden lämnade sviten grön, och en rad som inte går att göra
	     röd är antingen otäckt eller överflödig.

	     Här var den överflödig, och då är svaret att ta bort den, inte att
	     skriva ett prov som låtsas att den behövs. ]]
	--[[ W/S och ↑/↓ är kontraktets tangenter. Shift och Ctrl följer med
	     som SAMMA handling — de var gångartsstegen före det här beslutet,
	     och en spelare som lärt sig dem ska inte tappa dem för att
	     knappen bytt namn. De ritar ingen egen pekknapp; en handling ger
	     en knapp hur många tangenter den än lyssnar på. ]]
	ContextActionService:BindAction(Input.DRIV, onDriv, true,
		Enum.KeyCode.W, Enum.KeyCode.Up, Enum.KeyCode.LeftShift,
		Enum.KeyCode.ButtonR1)
	ContextActionService:BindAction(Input.BROMS, onBroms, true,
		Enum.KeyCode.S, Enum.KeyCode.Down, Enum.KeyCode.LeftControl,
		Enum.KeyCode.ButtonL1)
	--[[ Resten av ridningen: styrning, hopp och hjälperna. Ingen av dem
	     ritar en pekknapp (`false`), och det är avsiktligt — pekytan har
	     spaken för styrningen, och hjälperna är en öppen fråga till
	     produktägaren, inte något jag lägger tillbaka på eget initiativ. ]]
	ContextActionService:BindAction("HorseControl", onInput, false,
		Enum.KeyCode.A, Enum.KeyCode.D,
		Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.F,
		Enum.KeyCode.Z, Enum.KeyCode.C,
		Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB)
end

function Input.unbind()
	if not bound then return end
	bound = false
	ContextActionService:UnbindAction(Input.DRIV)
	ContextActionService:UnbindAction(Input.BROMS)
	ContextActionService:UnbindAction("HorseControl")
	Input.nollaImpulsSparr()
	state.forward, state.steer = 0, 0
	state.touchForward, state.touchSteer = 0, 0
	state.rein, state.touchRein = 0, 0
	state.seatLight, state.seatDeep, state.touchSeat = false, false, 0
	state.paradHeld, state._paradEdge, state.touchParad = false, false, false
	state.jump = false
	--[[ FLANKERNA MÅSTE MED. `gaitUp`/`gaitDown` är hållna tillstånd;
	     `_upEdge`/`_downEdge` är den OBEHANDLADE begäran, och den låg kvar
	     här. En spelare som tryckte Shift och sedan satt av innan
	     bildrutan hann konsumera flanken fick gångartsbytet på FÖRSTA
	     bildrutan efter nästa uppsittning — hästen bytte gångart av sig
	     själv innan ryttaren rört en tangent.

	     `_paradEdge` nollades redan; de här två glömdes. Mätt i
	     tests/touch.spec.luau: tre mätningar föll före den här raden. ]]
	state._upEdge, state._downEdge = false, false
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

--[[ Sitsaxeln HÄRLEDD ur knappstatus. Ren funktion av vad som är nere,
     så ordningen på tryck och släpp inte kan ge två olika svar på samma
     fysiska läge. Djup sits vinner när båda hålls. ]]
function Input.seatAxis(): number
	if state.seatDeep then return 1 end
	if state.seatLight then return -1 end
	return 0
end

--[[ Vänster avtryckare som ANALOG sits. Samma skäl som tygeln på höger:
     hur djupt man sitter är en dosering, inte ett av/på. ]]
local function seatTrigger(): number
	for _, obj in UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1) do
		if obj.KeyCode == Enum.KeyCode.ButtonL2 then
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
		seat = math.clamp(Input.seatAxis() + seatTrigger() + state.touchSeat, -1, 1),
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
function Input.setTouchSeat(seat: number)
	state.touchSeat = math.clamp(seat, -1, 1)
end
function Input.touchParad()
	state.touchParad = true
end
--[[ `touchGait` och `touchGaitTo` är borta. Pekytans namngivna
     gångartsknappar fanns bakom dem, och de knapparna finns inte längre:
     DRIV och BROMS är samma två handlingar på alla tre inmatningsslagen,
     och de går genom `drivImpuls`/`bromsImpuls` ovan — med spärren. En
     kvarlämnad ospärrad väg in i trappan hade varit en tyst väg runt
     hela beslutet. ]]
function Input.touchJump()
	state.jump = true
	task.delay(0.15, function() state.jump = false end)
end

return Input
