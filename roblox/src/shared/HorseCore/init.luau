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
	--[[ Vad en viss hästmodell kallar sina kroppsdelar. Delad därför att
	     servern monterar nätet och klienten animerar benen. ]]
	Riggprofiler = require(script.Riggprofiler),
	Networking = require(script.Networking),
	Telemetri = require(script.Telemetri),
	RidKanon = require(script.RidKanon),
	Hjalper = require(script.Hjalper),
	Svar = require(script.Svar),
	Kameralage = require(script.Kameralage),
	--[[ #161. Preparation ligger MEDVETET utanför: den require:as direkt
	     som `HorseCore.Preparation` av både server och klient, och att
	     lägga den här hade gjort require-ordningen cirkulär i bänkbygget.
	     Pass och Sparning är rena datamoduler utan sådana beroenden. ]]
	Pass = require(script.Pass),
	Sparning = require(script.Sparning),
}
