--!strict
--[[
	Serverns start. Håll den tom på logik — den ska bara starta tjänsterna
	i rätt ordning, så att ägarskapet mellan systemen är tydligt.
]]

local HorseService = require(script.HorseService)
local StallService = require(script.StallService)
local GameplayService = require(script.GameplayService)

-- Ridmotorn skapar HorseRemotes och registrerar fysiska riggar först.
HorseService.start()
-- Stallet väljer därefter den kanoniska UBRF-hästidentiteten för spelaren.
StallService.start()
-- Gameplay binder identiteten till rätt rigg och lägger prep-gaten ovanpå.
GameplayService.start(HorseService, StallService)

print("[Horse] Servern igång")
