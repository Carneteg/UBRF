--!strict
--[[
	UGNETA — G02-C:s bedömningskontrakt på Roblox-sidan.

	Ingen egen sanning. Dimensionerna per övning, listan över dimensioner
	och taket för antal observationer läses ur RidKanon.UGNETA, som
	genereras ur webbens src/larare.js av tools/exportera-ridkanon.mjs.
	Skulle webben ändra vad en 20 m volt bedöms på följer Roblox med i
	samma commit, och paritetsspecen blir röd om filen inte regenererats.

	Kvalitetsmåtten kommer ur samma telemetri som webben läser
	(HorseCore/Telemetri) — den här modulen räknar inte om något själv,
	den väljer bara ut och rangordnar.
]]

local RidKanon = require(script.Parent.RidKanon)

local Ugneta = {}

Ugneta.MAX_OBSERVATIONER = RidKanon.UGNETA.MAX_OBSERVATIONER
Ugneta.DIMENSIONER = RidKanon.UGNETA.DIMENSIONER

--[[ Trösklarna som avgör VAD hon säger. De stod förut som literaler här
     — avskrivna ur webbens ugnetaJamfor/ugnetaForstaForsok, alltså en
     andra sanning som kunde glida utan att något blev rött. Nu kommer de
     ur samma kanon som allt annat i den här modulen. ]]
local KV = RidKanon.UGNETA.KVALITET

--[[ Vilka dimensioner bedöms den här övningen på? Okänd övning ger
     samma reserv som webben: rytm, balans och mjukhet. ]]
function Ugneta.dimensionerFor(ovningId: string): { string }
	local d = RidKanon.UGNETA.OVNING[ovningId]
	if d then return d end
	return { "rytm", "balans", "mjukhet" }
end

--[[ Efter ett försök: högst MAX_OBSERVATIONER prioriterade observationer.
     `fore` är nil på första försöket. Samma ordning som webben:
     förbättringen först, därefter det som är svagast kvar. ]]
function Ugneta.observationer(ovningId: string,
	nu: { [string]: number }, fore: { [string]: number }?): { { dim: string, sort: string, varde: number } }
	local dims = Ugneta.dimensionerFor(ovningId)
	local ut = {}
	--[[ EN OMÄTT DIMENSION ÄR INTE EN DÅLIG DIMENSION. `nu[k]` som är nil
	     betyder att ytan saknar källa för den (HorseCore/Lektion.SAKNAS:
	     Roblox har ingen utbildningsskala och mäter därför ingen rytm).
	     Tidigare lästes den som 0, och då blev den automatiskt svagast i
	     varje 20 m volt — Ugneta hade tjatat om en takt hon aldrig sett.
	     Den hoppas nu över, och det syns i observationerna att den inte
	     bedömdes i stället för att den bedömdes till noll. ]]
	if fore then
		local bast, bastD = nil, KV.BATTRE
		for _, k in dims do
			if nu[k] ~= nil and fore[k] ~= nil then
				local d = nu[k] - fore[k]
				if d >= bastD then bast, bastD = k, d end
			end
		end
		if bast then table.insert(ut, { dim = bast, sort = "battre", varde = nu[bast] }) end
		local svag, svagV = nil, KV.SVAG
		for _, k in dims do
			local v = nu[k]
			if v ~= nil and k ~= bast and v < svagV then svag, svagV = k, v end
		end
		if svag then table.insert(ut, { dim = svag, sort = "kvar", varde = nu[svag] }) end
	else
		local bast, bastV = nil, KV.BRA
		for _, k in dims do
			local v = nu[k]
			if v ~= nil and v >= bastV then bast, bastV = k, v end
		end
		if bast then table.insert(ut, { dim = bast, sort = "bra", varde = nu[bast] }) end
		local svag, svagV = nil, math.huge
		for _, k in dims do
			local v = nu[k]
			if v ~= nil and k ~= bast and v < svagV then svag, svagV = k, v end
		end
		if svag then table.insert(ut, { dim = svag, sort = "forbattra", varde = nu[svag] }) end
	end
	--[[ Taket är ett skyddsnät, inte det som håller regeln i dag: varje
	     gren lägger till högst en förbättring och en kvarvarande, alltså
	     högst två. En falsifiering som tar bort raden ändrar därför
	     ingenting — det är inte en lucka i provet utan en mutation utan
	     verkan. Raden står kvar för den dag en gren till läggs till. ]]
	while #ut > Ugneta.MAX_OBSERVATIONER do table.remove(ut) end
	return ut
end

return Ugneta
