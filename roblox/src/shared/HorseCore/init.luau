--!strict
--[[
	HorseCore — samlad ingång till de delade modulerna.

	    local Horse = require(ReplicatedStorage.HorseCore)
	    local gait = Horse.Gaits.forSpeed(speed, current)
]]

--[[ Types ligger medvetet utanför tabellen: modulen returnerar nil och
     finns bara för typkontrollen. Requira den direkt där typerna behövs. ]]
return {
	Config = require(script.Config),
	Gaits = require(script.Gaits),
	StateMachine = require(script.StateMachine),
	RigAdapter = require(script.RigAdapter),
	Networking = require(script.Networking),
	Telemetri = require(script.Telemetri),
	RidKanon = require(script.RidKanon),
	Hjalper = require(script.Hjalper),
	Svar = require(script.Svar),
}
