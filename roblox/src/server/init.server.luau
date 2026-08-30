--!strict
--[[
	Serverns start. Håll den tom på logik — den ska bara starta tjänsterna
	i rätt ordning, så att det syns var något går fel.
]]

local HorseService = require(script.HorseService)
local GameplayService = require(script.GameplayService)

HorseService.start()
GameplayService.start(HorseService)
print("[Horse] Servern igång")
