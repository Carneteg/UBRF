--!nostrict
--[[
	RYGGNINGENS HOVTAKT — #233.

	OBSERVERAT UTGÅNGSLÄGE, uppmätt före rättelsen och inte antaget:
	ryggningen var TYST. Två oberoende orsaker, båda nödvändiga att
	åtgärda:

	  1. `Gaits.cycleLength("halt")` är 0, så `loco.phase` slutade växa
	     så fort hon backade. En fas som står still ger inga hovslag hur
	     ljudlagret än räknar.
	  2. `Gaits.get("halt").steps` är 0, så `SoundController` hoppade över
	     slaget även om fasen hade rört sig.

	Före #239 klampade hon i SKRITTENS takt medan hon backade — fel takt,
	men inte tyst. Rättelsen där flyttade etiketten till halt, och
	tystnaden följde med som en redovisad bieffekt. Det här är dess order.

	SPECEN GÅR GENOM `SoundController:step`. Det enda som byts ut är
	själva ljuduppspelningen — `_hoof` — eftersom bänken inte har en
	ljudmotor. Beslutet om NÄR ett slag faller ligger kvar i
	produktionskoden och är det som mäts.

	Kör: python3 roblox/tests/build.py tests/ljud.spec.luau
	     && luau roblox/tests/.build/ljud.spec.luau
]]

local fel = 0
local function check(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, detalj and ("  " .. detalj) or ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, detalj and ("  " .. detalj) or ""))
	end
end

local STATS = {
	Speed = 0.5, Acceleration = 0.5, Agility = 0.5, Endurance = 0.5,
	Temperament = "Calm", MaxStamina = 100,
}

--[[ En avsikt som inputlagret hade kunnat producera. ]]
local function intent(o)
	o = o or {}
	return { forward = o.forward or 0, steer = o.steer or 0, rein = 0, seat = 0,
		parad = 0, gaitUp = o.gaitUp or false, gaitDown = o.gaitDown or false,
		jump = false }
end

--[[ Ett ekipage med ljud. `_hoof` byts mot en räknare: bänken har ingen
     ljudmotor, och det är inte uppspelningen som är under prov utan
     BESLUTET om när ett slag faller. Allt i `step()` är produktionskod. ]]
local function nyttEkipage()
	local rig = __makeRig()
	--[[ `__makeRig` lämnar `model` som en enkel tabell — det räcker för
	     rörelsemodulerna, men `SoundController.new` letar efter en
	     `Sounds`-Configuration på modellen. Shimen ligger HÄR och inte i
	     stubbfilen: `__makeRig` delas av flera specar, och en ändring
	     där hade rört prov som inte har med ljudet att göra.

	     Utan ljud-id spelar `_hoof` ändå ingenting — och den är utbytt
	     nedan. Det som mäts är beslutet, inte uppspelningen. ]]
	rig.model.FindFirstChild = function() return nil end
	local mc = MovementController.new(rig, STATS)
	local sc = SoundController.new(rig, STATS)
	local slag = 0
	sc._hoof = function() slag += 1 end
	return mc, sc, function() return slag end, function() slag = 0 end
end

--[[ Samma integrering som `movement.spec` gör: riktningen och farten som
     koden själv skrev, integrerad med samma dt. Ingen fysik. Returnerar
     tillryggalagd sträcka i METER, utan tecken — precis som `moved` i
     `MovementController`. ]]
local function kor(mc, sc, sekunder, o, dt)
	dt = dt or 1 / 60
	local rig = mc.rig
	local gatt = 0
	for _ = 1, math.floor(sekunder / dt + 0.5) do
		mc:step(intent(o), dt)
		local hum = rig.humanoid
		local dir = hum._moves[#hum._moves]
		if dir then
			local steg = hum.WalkSpeed * dt
			local ny = rig.root.Position + dir * steg
			gatt += steg
			rig.root.Position = ny
			rig.root.CFrame = CFrame.new(ny) * CFrame.Angles(0, mc.loco.heading, 0)
		end
		sc:step(mc.loco, dt)
	end
	return gatt / Config.STUDS_PER_METRE
end

--[[ Stega ned i ryggningen genom trappan, precis som en BROMS gör. ]]
local function tillRygga(mc, sc)
	mc:step(intent({ gaitDown = true }), 1 / 60)
	sc:step(mc.loco, 1 / 60)
end

print("\n-- 1. Ryggningen ar inte tyst --")

do
	local mc, sc, slag, noll = nyttEkipage()
	tillRygga(mc, sc)
	check("hon ar i ryggningslaget", mc.ryggar == true and mc.loco.ryggar == true,
		("ryggar=%s loco.ryggar=%s"):format(tostring(mc.ryggar), tostring(mc.loco.ryggar)))
	check("och gangarten laser fortfarande halt - pinnen har ingen egen rad",
		mc.loco.gait == "halt", mc.loco.gait)

	noll()
	local m = kor(mc, sc, 4.0)
	check("1. ryggning producerar hovslag", slag() > 0,
		("%d slag pa %.2f m"):format(slag(), m))
	check("och hon rorde sig faktiskt bakat", mc.loco.speed < -0.5,
		("%.2f m/s"):format(mc.loco.speed))
end

print("\n-- 2. Takten ar ryggningens, inte skrittens --")

do
	local mc, sc, slag, noll = nyttEkipage()
	tillRygga(mc, sc)
	kor(mc, sc, 1.5)                      -- upp i backtempo forst
	noll()
	local m = kor(mc, sc, 8.0)
	local slagPerMeter = slag() / m

	local vantad = Config.RYGGNING.Steps / Config.RYGGNING.CycleLength
	local skritt = Gaits.get("walk").steps / Gaits.cycleLength("walk")

	print(("     uppmatt %.3f slag/m · ryggningskanon %.3f · skritt %.3f")
		:format(slagPerMeter, vantad, skritt))

	check("2. takten foljer ryggningens kanon",
		math.abs(slagPerMeter - vantad) / vantad < 0.06,
		("%.3f mot %.3f slag/m"):format(slagPerMeter, vantad))

	--[[ DEN SKARPA HALVAN. Regeln ar inte bara "nagon takt" utan
	     uttryckligen INTE skrittens - det var felet fore #239. ]]
	check("och den ar TYDLIGT langsammare an skrittens",
		slagPerMeter < skritt * 0.85,
		("%.3f mot skrittens %.3f slag/m"):format(slagPerMeter, skritt))

	--[[ Tvataktig diagonal, inte fyrtaktig. Det ar hastkunskap, inte
	     ljudsmak: en hast ryggar i diagonala par. ]]
	check("ryggningen ar tvataktig", Config.RYGGNING.Steps == 2,
		("%d slag per cykel"):format(Config.RYGGNING.Steps))
end

print("\n-- 3. Halt UTAN ryggning ar fortsatt tyst --")

do
	local mc, sc, slag, noll = nyttEkipage()
	noll()
	kor(mc, sc, 4.0)
	check("3. en hast som star i halt ger inga hovslag", slag() == 0,
		("%d slag"):format(slag()))
	check("och hon ryggar inte", mc.loco.ryggar == false,
		tostring(mc.loco.ryggar))
end

print("\n-- 4. Skritt, trav och galopp ar oforandrade --")

do
	local function taktFor(stegUpp)
		local mc, sc, slag, noll = nyttEkipage()
		for _ = 1, stegUpp do
			mc:step(intent({ gaitUp = true }), 1 / 60)
			kor(mc, sc, 2.5, { forward = 1 })
		end
		noll()
		local m = kor(mc, sc, 8.0, { forward = 1 })
		return mc.loco.gait, slag() / m
	end

	for _, steg in { 1, 2, 3 } do
		local gangart, uppmatt = taktFor(steg)
		local vantad = Gaits.get(gangart).steps / Gaits.cycleLength(gangart)
		check(("4. %s behaller sin takt"):format(gangart),
			math.abs(uppmatt - vantad) / vantad < 0.06,
			("%.3f mot %.3f slag/m"):format(uppmatt, vantad))
	end
end

print("\n-- 5. Overgangen startar och stoppar rent --")

do
	--[[ RYGGA -> HALT. Ljudet ska sluta, och det ska sluta HELT. ]]
	local mc, sc, slag, noll = nyttEkipage()
	tillRygga(mc, sc)
	kor(mc, sc, 3.0)
	check("hon ryggade och lat", slag() > 0, ("%d slag"):format(slag()))

	--[[ Ett DRIV tar henne ur rygga till halt. ]]
	mc:step(intent({ gaitUp = true }), 1 / 60)
	kor(mc, sc, 1.5)                      -- lat henne stanna
	check("hon ar ur ryggningen", mc.loco.ryggar == false,
		tostring(mc.loco.ryggar))

	noll()
	kor(mc, sc, 4.0)
	check("5. inget ljud hanger kvar efter atergang till halt", slag() == 0,
		("%d slag pa 4 s i halt"):format(slag()))
end

do
	--[[ TAKTBYTET FAR INTE GE ETT EXTRA SLAG.

	     `SoundController` jamforde forut forra bildrutans fas mot DAGENS
	     antal delningar. Nar takten byter - 2 slag i ryggning blir 4 i
	     skritt - matte den forra fasen mot en delning den aldrig levde i,
	     och kunde fyra ett slag ingen hast tog.

	     Matningen: rakna slagen over ETT taktbyte och jamfor med vad
	     stracka och kadens medger. Ett extra slag syns som ett overskott. ]]
	local mc, sc, slag, noll = nyttEkipage()
	tillRygga(mc, sc)
	kor(mc, sc, 2.0)

	noll()
	local m1 = kor(mc, sc, 1.0)                       -- sista biten ryggning
	mc:step(intent({ gaitUp = true }), 1 / 60)         -- ur rygga
	mc:step(intent({ gaitUp = true }), 1 / 60)         -- upp i skritt
	local m2 = kor(mc, sc, 3.0, { forward = 1 })

	--[[ Taket for hur manga slag strackan kan bara: bada kadenserna, var
	     for sig, plus ETT for delningen som kan ligga precis pa skarven. ]]
	local tak = m1 * (Config.RYGGNING.Steps / Config.RYGGNING.CycleLength)
		+ m2 * (Gaits.get("walk").steps / Gaits.cycleLength("walk")) + 1
	check("6. taktbytet ger inget overskott av hovslag",
		slag() <= math.ceil(tak),
		("%d slag, tak %d"):format(slag(), math.ceil(tak)))
	check("och ljudet fortsatte efter bytet - hon blev inte tyst",
		slag() > 0, ("%d slag"):format(slag()))
end

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätningar föll."):format(fel), 0)
else
	print("\nAlla mätningar gick igenom.")
end
