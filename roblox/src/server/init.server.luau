--!strict
--[[
	Serverns start. Håll den tom på logik — den ska bara starta tjänsterna
	i rätt ordning, så att det syns var något går fel.
]]

local HorseService = require(script.HorseService)

HorseService.start()
print("[Horse] Servern igång")
