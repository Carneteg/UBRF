--!strict
--[[
	Serverns start. Håll den tom på logik — den ska bara starta tjänsterna
	i rätt ordning, så att det syns var något går fel.
]]

local SparService = require(script.SparService)
local HorseService = require(script.HorseService)
local StallService = require(script.StallService)
local GameplayService = require(script.GameplayService)

--[[ Ordningen är ett beroende, inte en smaksak: GameplayService registrerar
     sin uppsittningsgrind i HorseService och läser tilldelad HorseId ur
     StallService, så båda måste vara igång först.

     SparService ligger FÖRST sedan #161, och det är också ett beroende:
     StallService.tilldela frågar efter spelarens hästminnen för att inte
     dela ut en häst som vilar för en skada, och GameplayService läser
     passnumret för att veta om det är första dagen. Startar den efter dem
     får den första spelaren i servern en tom välfärdsmängd och kunde
     tilldelas en skadad häst. ]]
SparService.start()
HorseService.start()
StallService.start()
GameplayService.start()
print("[Horse] Servern igång")
