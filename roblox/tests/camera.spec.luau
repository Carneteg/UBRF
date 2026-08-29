--!nostrict
--[[
	Mätningar på ridkameran.

	Kameran har en egen kurs som följer hästens med kort fördröjning. Två
	saker kan gå fel med det, och båda går att mäta: fördröjningen kan bli
	så lång att man tappar känslan av att styra, och vinkelutjämningen kan
	ta den långa vägen runt cirkeln när hästens kurs passerar noll — då
	snurrar bilden ett helt varv.

	Kör: python3 roblox/tests/build.py tests/camera.spec.luau
	     && luau roblox/tests/.build/camera.luau
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

local function newCam()
	return CameraController.new(__makeRig())
end

--[[ Ett locomotion-tillstånd att mata kameran med. ]]
local function loco(o)
	o = o or {}
	return {
		speed = o.speed or 0, heading = o.heading or 0,
		turnRate = o.turnRate or 0, lean = 0,
		gait = o.gait or "walk", targetGait = o.gait or "walk",
		state = "Walk", phase = 0, airborne = false, grounded = true,
		slope = Vector3.yAxis, stamina = 100,
	}
end

print("\n── Kameran hinner ifatt, men inte direkt ──")
do
	local cam = newCam()
	local dt = 1 / 60
	--[[ Hästen svänger till 1,0 rad och står kvar där. Kameran ska ligga
	     efter i början och vara framme efter en halv sekund. ]]
	cam:step(loco({ heading = 1.0, turnRate = 1.0 }), dt)
	local efterEn = math.abs(1.0 - cam.yaw)
	for _ = 1, 30 do cam:step(loco({ heading = 1.0 }), dt) end
	local efterHalv = math.abs(1.0 - cam.yaw)
	print(string.format("  kvar efter en bildruta: %.3f rad", efterEn))
	print(string.format("  kvar efter 0,5 s:       %.4f rad", efterHalv))
	check("kameran ligger efter i första bildrutan", efterEn > 0.5,
		string.format("(%.3f rad kvar, kräver > 0,5)", efterEn))
	check("kameran är ifatt inom en halv sekund", efterHalv < 0.05,
		string.format("(%.4f rad kvar, kräver < 0,05)", efterHalv))
end

print("\n── Nollpassage: kameran tar den korta vägen ──")
do
	local cam = newCam()
	local dt = 1 / 60
	--[[ Hästen står strax under 2π och svänger förbi noll. Tar kameran
	     den långa vägen syns det som en hastig helvarvssnurr. ]]
	cam.yaw = 6.20                                   -- knappt 2π
	local mest = 0
	local forra = cam.yaw
	for i = 1, 40 do
		local h = (6.20 + i * 0.02) % (2 * math.pi)   -- passerar noll
		cam:step(loco({ heading = h }), dt)
		local steg = math.abs((cam.yaw - forra + math.pi) % (2 * math.pi) - math.pi)
		mest = math.max(mest, steg)
		forra = cam.yaw
	end
	print(string.format("  största kurssteg per bildruta: %.4f rad", mest))
	check("ingen helvarvssnurr vid nollpassagen", mest < 0.15,
		string.format("(%.4f rad, ett varv vore ~6,28)", mest))
end

print("\n── Gångartsbytet syns i bilden ──")
do
	local cam = newCam()
	local dt = 1 / 60
	for _ = 1, 120 do cam:step(loco({ gait = "walk" }), dt) end
	local naraDist, naraFov = cam.dist, cam.fov
	for _ = 1, 180 do cam:step(loco({ gait = "gallop", speed = 8.6 }), dt) end
	local fjarrDist, fjarrFov = cam.dist, cam.fov
	print(string.format("  skritt:    avstånd %.1f, fov %.1f", naraDist, naraFov))
	print(string.format("  fyrsprång: avstånd %.1f, fov %.1f", fjarrDist, fjarrFov))
	check("kameran backar undan i fyrsprång", fjarrDist > naraDist + 4,
		string.format("(%.1f → %.1f studs)", naraDist, fjarrDist))
	check("synfältet öppnar sig i fart", fjarrFov > naraFov + 3,
		string.format("(%.1f → %.1f grader)", naraFov, fjarrFov))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
