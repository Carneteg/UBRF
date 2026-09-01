--!strict
--[[
	TUNN INTEGRATIONSWRAPPER.

	Verklighets-/speldata för hästar genereras till UBRFSpelData.luau.
	Skötselkanonen genereras separat till UBRFSkotsel.luau.
	Den här modulen fogar bara ihop de två vid runtime så konsumenterna kan
	fortsätta läsa ett enda kontrakt: ReplicatedStorage.UBRFSpel.
]]

local RS = game:GetService("ReplicatedStorage")
local Data = require(RS.UBRFSpelData)
local Skotsel = require(RS.UBRFSkotsel)

Data.rykt = Skotsel.rykt
Data.sadelfaser = Skotsel.sadelfaser
Data.visitation = Skotsel.visitation

return Data
