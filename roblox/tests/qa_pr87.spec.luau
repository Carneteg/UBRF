--!nostrict
--[[
	Adversarial / Falsification regression tests for PR #87 issues.
]]

local STATS = {
	Speed = 0.5, Acceleration = 0.5, Agility = 0.5, Stamina = 0.5,
	MaxStamina = 100, Temperament = "Calm",
}

local function intent(o)
	o = o or {}
	return { forward = o.forward or 0, steer = o.steer or 0,
		gaitUp = o.gaitUp or false, gaitDown = o.gaitDown or false,
		jump = o.jump or false,
		rein = o.rein or 0, parad = o.parad or 0, seat = o.seat or 0 }
end

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

print("\n── QA Defect 1: MovementController.new initial hjalper initialization ──")
do
	local mc = MovementController.new(__makeRig(), STATS)
	check("MovementController.new populates hjalper before step() is called",
		mc.hjalper ~= nil and mc.hjalper.skankel ~= nil,
		string.format("(mc.hjalper is %s)", tostring(mc.hjalper)))
end

print("\n── QA Defect 2: Input.luau Z and C keyboard key holding state ──")
do
	Input.unbind()
	__setStick(nil)
	Input.bind()

	-- Simulate Z key down (Light seat = -1)
	__key(Enum.KeyCode.Z, true)
	local intentZ = Input.consume()
	check("Holding Z key sets seat to -1", intentZ.seat == -1, string.format("(seat was %d)", intentZ.seat))

	-- Now simulate C key down while Z is still held
	__key(Enum.KeyCode.C, true)
	local intentZC = Input.consume()
	check("Pressing C while Z is held sets seat to 1", intentZC.seat == 1, string.format("(seat was %d)", intentZC.seat))

	-- Now release Z while C is still held
	__key(Enum.KeyCode.Z, false)
	local intentC = Input.consume()

	check("Releasing Z while holding C restores seat to 1 (C state) instead of 0",
		intentC.seat == 1,
		string.format("(seat was %d, expected 1)", intentC.seat))

	__key(Enum.KeyCode.C, false)
	Input.unbind()
end

print("\n── QA Defect 3: MovementController.luau dt=0 division safety ──")
do
	local mc = MovementController.new(__makeRig(), STATS)
	mc:step(intent({ forward = 1 }), 0)
	check("dt=0 step does not produce NaN mjukhet or phase",
		mc.loco.mjukhet == mc.loco.mjukhet and mc.loco.phase == mc.loco.phase,
		string.format("(mjukhet: %f, phase: %f)", mc.loco.mjukhet or -1, mc.loco.phase or -1))
end

if fails > 0 then
	print(string.format("\n%d QA test(s) failed.", fails))
else
	print("\nAll QA regression tests passed.")
end
