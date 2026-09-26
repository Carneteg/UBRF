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
	--[[ Trappan Rygga ↔ Halt ↔ Skritt ↔ Trav ↔ Galopp. Delad därför att
	     servern äger stegen och klienten predikterar dem — samma trappa
	     på båda sidor, annars är prediktionen en andra sanning. ]]
	Ridtrappa = require(script.Ridtrappa),
	StateMachine = require(script.StateMachine),
	RigAdapter = require(script.RigAdapter),
	--[[ Vad en viss hästmodell kallar sina kroppsdelar. Delad därför att
	     servern monterar nätet och klienten animerar benen. ]]
	Riggprofiler = require(script.Riggprofiler),
	Networking = require(script.Networking),
	Telemetri = require(script.Telemetri),
	RidKanon = require(script.RidKanon),
	--[[ #264: benföljden per gångart. Ben, hovslag och lättridning läser
	     samma rad och samma fas. ]]
	Gangfas = require(script.Gangfas),
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
