--!nostrict
--[[
	Mätningar på pekkontrakten.

	Gesterna går inte att köra utanför Studio, men allt under dem gör det:
	spakens kurva är en ren funktion, och `Input` är en ren tillståndsmaskin.
	Det som mäts här är alltså precis det review 02 kräver bevis för — att
	tre spaklägen ger tre skilda avsikter, att ett släpp nollar, och att
	tangent och gamepad inte regredierar.

	Kör: python3 roblox/tests/build.py tests/touch.spec.luau
	     && luau roblox/tests/.build/touch.spec.luau
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

local R = TouchControls.RADIE

--[[ Nollställ mellan mätningarna: Input är en modul med delat tillstånd. ]]
local function nollstall()
	Input.unbind()
	__setStick(nil)
	Input.bind()
end

print("\n── Spaken är analog, inte fyra knappar i en cirkel ──")
do
	--[[ Kravet ur reviewen: 25, 50 och 100 % vågrätt utslag ska ge tre
	     monotont skilda styrvärden. Samma tre nivåer webben mäter med
	     riktiga pekhändelser. ]]
	local rader = {}
	for _, andel in { 0.25, 0.50, 1.00 } do
		local _, steer = TouchControls.axis(R * andel, 0, R)
		table.insert(rader, { andel = andel, steer = steer })
	end
	print("  spakutslag   styravsikt")
	for _, r in rader do
		print(string.format("  %3d %%        %.4f", r.andel * 100, r.steer))
	end
	check("tre spaklägen ger tre monotont skilda avsikter",
		rader[1].steer < rader[2].steer and rader[2].steer < rader[3].steer,
		string.format("(%.4f < %.4f < %.4f)", rader[1].steer, rader[2].steer, rader[3].steer))
	check("fullt utslag ger full avsikt", math.abs(rader[3].steer - 1) < 1e-9,
		string.format("(%.6f)", rader[3].steer))
	--[[ Ett litet utslag ska vara litet. En kurva som ger 0,6 på 25 % är
	     en knapp med rundade hörn. ]]
	check("kvartsutslag är en linjekorrigering, inte en volt",
		rader[1].steer > 0.01 and rader[1].steer < 0.15,
		string.format("(%.4f)", rader[1].steer))
end

print("\n── Tecken, dödzon och diagonal ──")
do
	local _, hoger = TouchControls.axis(R, 0, R)
	local _, vanster = TouchControls.axis(-R, 0, R)
	check("höger är positivt, vänster negativt", hoger > 0 and vanster < 0,
		string.format("(%.3f / %.3f)", hoger, vanster))
	check("vänster speglar höger", math.abs(hoger + vanster) < 1e-9)

	local fram = select(1, TouchControls.axis(0, -R, R))
	local bak = select(1, TouchControls.axis(0, R, R))
	check("uppåt är framåt, nedåt är bakåt", fram > 0 and bak < 0,
		string.format("(%.3f / %.3f)", fram, bak))

	--[[ Dödzonen: tummen darrar, hästen ska inte svara. ]]
	local _, darr = TouchControls.axis(R * 0.05, 0, R)
	check("små darrningar inom dödzonen ger noll", darr == 0,
		string.format("(5 %% utslag → %.6f)", darr))

	--[[ Diagonalen får inte vara snabbare än rakt fram — samma fel som ett
	     oklampat WASD gör. ]]
	local dF, dS = TouchControls.axis(R, -R, R)
	local langd = math.sqrt(dF * dF + dS * dS)
	check("diagonalen är inte snabbare än rakt fram", langd <= 1 + 1e-9,
		string.format("(längd %.4f)", langd))

	check("spak utan radie ger noll i stället för att dela med noll",
		select(1, TouchControls.axis(10, 10, 0)) == 0)
end

print("\n── Släpp nollar båda axlarna på en gång ──")
do
	nollstall()
	Input.setTouch(TouchControls.axis(R * 0.8, -R * 0.8, R))
	local i1 = Input.consume()
	check("spaken når fram till avsikten", math.abs(i1.steer) > 0.1 and i1.forward > 0.1,
		string.format("(forward %.3f, steer %.3f)", i1.forward, i1.steer))
	Input.setTouch(0, 0)
	local i2 = Input.consume()
	check("släppet nollar båda axlarna direkt",
		i2.forward == 0 and i2.steer == 0,
		string.format("(forward %.6f, steer %.6f)", i2.forward, i2.steer))
end

print("\n── Gångart och hopp ──")
do
	nollstall()
	Input.touchGait(true)
	local a = Input.consume()
	local b = Input.consume()
	check("ett tryck uppåt ger exakt ett gångartsbyte",
		a.gaitUp and not b.gaitUp)
	Input.touchGait(false)
	local c = Input.consume()
	local d = Input.consume()
	check("ett tryck nedåt ger exakt ett gångartsbyte",
		c.gaitDown and not d.gaitDown)
	--[[ Ett tryck ska bäras av exakt en bildruta och sedan vara borta. Utan
	     flanktriggningen skulle en gångartsknapp rusa genom skritt–trav–
	     galopp så länge flaggan låg kvar. ]]
	Input.touchGait(true)
	local barande, efterat = 0, 0
	for i = 1, 31 do
		if Input.consume().gaitUp then
			if i == 1 then barande += 1 else efterat += 1 end
		end
	end
	check("ett tryck bärs av exakt en bildruta och sedan inga fler",
		barande == 1 and efterat == 0,
		string.format("(%d bärande, %d extra på 30 följande bildrutor)", barande, efterat))

	Input.touchJump()
	check("hoppknappen tänder hoppet", Input.consume().jump)
	if __senasteDelay then __senasteDelay() end
	check("och släpper det igen", not Input.consume().jump)

	--[[ G02-B: TYGELN OCH PARADEN på pekskärmen.

	     De två har olika natur med flit, och provet är vad som håller dem
	     isär: kontakten är ett TILLSTÅND som ligger kvar så länge fingret
	     ligger på, paraden är en IMPULS som bärs av exakt en bildruta.
	     Byter de plats får man en tygel man knäpper på och en halvhalt
	     man kan hålla inne, och ingetdera är ridning. ]]
	nollstall()
	Input.setTouchRein(1)
	local r1, r2 = Input.consume().rein, Input.consume().rein
	Input.setTouchRein(0)
	local r3 = Input.consume().rein
	check("tygeln HÅLLS: kontakten ligger kvar tills fingret lyfts",
		r1 == 1 and r2 == 1 and r3 == 0,
		string.format("(%.0f, %.0f, sedan %.0f)", r1, r2, r3))
	--[[ Och att den är ANALOG i kontraktet: halva utslaget ska nå fram
	     som halvt. Pekskärmens knapp ger 1, men gamepadens avtryckare är
	     en axel, och det är samma fält de skriver i. ]]
	Input.setTouchRein(0.45)
	check("tygeln är analog hela vägen genom kontraktet",
		math.abs(Input.consume().rein - 0.45) < 1e-6)
	Input.setTouchRein(0)

	Input.touchParad()
	local barandeP, efteratP = 0, 0
	for i = 1, 31 do
		if Input.consume().parad > 0 then
			if i == 1 then barandeP += 1 else efteratP += 1 end
		end
	end
	check("paraden är en IMPULS: ett tryck bärs av exakt en bildruta",
		barandeP == 1 and efteratP == 0,
		string.format("(%d bärande, %d extra på 30 följande bildrutor)", barandeP, efteratP))
end

print("\n── Ingen regression för tangent och gamepad ──")
do
	nollstall()
	__key(Enum.KeyCode.W, true)
	__key(Enum.KeyCode.D, true)
	local i = Input.consume()
	check("W och D fungerar som förut", i.forward == 1 and i.steer == 1,
		string.format("(forward %.1f, steer %.1f)", i.forward, i.steer))
	__key(Enum.KeyCode.W, false)
	__key(Enum.KeyCode.D, false)
	local sl = Input.consume()
	check("och släpper till noll", sl.forward == 0 and sl.steer == 0)

	nollstall()
	__setStick(0.5, 0.5)
	local p = Input.consume()
	check("gamepadens spak fungerar som förut",
		math.abs(p.steer - 0.5) < 1e-9 and math.abs(p.forward - 0.5) < 1e-9,
		string.format("(forward %.3f, steer %.3f)", p.forward, p.steer))

	--[[ Det gamla `setTouch` skrev i tangenternas egna fält. Höll man D och
	     drog spaken åt vänster slog de ut varandra beroende på ordning. Nu
	     summeras de som gamepaden gör. ]]
	nollstall()
	__key(Enum.KeyCode.D, true)
	Input.setTouch(0, -0.4)
	local blandat = Input.consume()
	check("tangent och pekskärm slår inte ut varandra",
		math.abs(blandat.steer - 0.6) < 1e-9,
		string.format("(D + spak −0,4 → %.3f)", blandat.steer))

	--[[ Summan får aldrig lämna −1..1: rörelsemodellen räknar med det. ]]
	nollstall()
	__key(Enum.KeyCode.D, true)
	__setStick(1, 0)
	Input.setTouch(0, 1)
	local mattad = Input.consume()
	check("summan klampas till kontraktets intervall",
		mattad.steer == 1, string.format("(%.3f)", mattad.steer))

	--[[ Och avsikter utanför intervallet klampas redan vid ingången. ]]
	nollstall()
	Input.setTouch(9, -9)
	local vild = Input.consume()
	check("orimliga pekvärden klampas vid ingången",
		vild.forward == 1 and vild.steer == -1,
		string.format("(%.1f / %.1f)", vild.forward, vild.steer))
end

print("\n── Avsittning lämnar ingenting kvar ──")
do
	nollstall()
	Input.setTouch(TouchControls.axis(R, -R, R))
	Input.touchGait(true)
	Input.unbind()
	local efter = Input.consume()
	check("unbind nollar pekaxlarna, inte bara tangenterna",
		efter.forward == 0 and efter.steer == 0,
		string.format("(forward %.3f, steer %.3f)", efter.forward, efter.steer))
	check("pekkontrollerna finns inte på en enhet utan pekskärm",
		not TouchControls.isActive())
	TouchControls.unmount()
	check("unmount är ofarlig även när inget är byggt", true)
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
