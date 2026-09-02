--!strict
--[[
	Serverns start. Håll den tom på logik — den ska bara starta tjänsterna
	i rätt ordning, så att det syns var något går fel.
]]

local WorldService = require(script.WorldService)
local HorseService = require(script.HorseService)
local StallService = require(script.StallService)
local GameplayService = require(script.GameplayService)

WorldService.start()

--[[ Ordningen är ett beroende, inte en smaksak: GameplayService registrerar
     sin uppsittningsgrind i HorseService och läser tilldelad HorseId ur
     StallService, så båda måste vara igång först. ]]
HorseService.start()
StallService.start()
GameplayService.start()
print("[Horse] Servern igång")
