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
     passnumret för att veta om det är första dagen.

     MEN ORDNINGEN HÄR ÄR INTE EN BARRIÄR, och sedan #162 blockerare 1
     låtsas den inte vara det. Den bestämmer bara i vilken ordning
     anslutningarna görs. `SparService.ladda` yieldar i sitt `GetAsync`,
     och Roblox kör varje `PlayerAdded`-anslutning på egen tråd — så en
     tjänst som kopplade signalen själv startade mitt i läsningen, hur
     sent den än startades.

     Därför finns nu exakt EN `PlayerAdded`-lyssnare i servern, i
     SparService, och StallService/GameplayService hänger på
     `SparService.efterLaddning`. Startordningen nedan avgör i vilken
     ordning de hookarna körs, och det beroendet gäller fortfarande. ]]
SparService.start()
HorseService.start()
StallService.start()
GameplayService.start()
print("[Horse] Servern igång")
