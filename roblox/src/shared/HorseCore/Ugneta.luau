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
	if fore then
		local bast, bastD = nil, 0.045
		for _, k in dims do
			local d = (nu[k] or 0) - (fore[k] or 0)
			if d >= bastD then bast, bastD = k, d end
		end
		if bast then table.insert(ut, { dim = bast, sort = "battre", varde = nu[bast] or 0 }) end
		local svag, svagV = nil, 0.68
		for _, k in dims do
			local v = nu[k] or 0
			if k ~= bast and v < svagV then svag, svagV = k, v end
		end
		if svag then table.insert(ut, { dim = svag, sort = "kvar", varde = nu[svag] or 0 }) end
	else
		local bast, bastV = nil, 0.55
		for _, k in dims do
			local v = nu[k] or 0
			if v >= bastV then bast, bastV = k, v end
		end
		if bast then table.insert(ut, { dim = bast, sort = "bra", varde = nu[bast] or 0 }) end
		local svag, svagV = nil, math.huge
		for _, k in dims do
			local v = nu[k] or 0
			if k ~= bast and v < svagV then svag, svagV = k, v end
		end
		if svag then table.insert(ut, { dim = svag, sort = "forbattra", varde = nu[svag] or 0 }) end
	end
	while #ut > Ugneta.MAX_OBSERVATIONER do table.remove(ut) end
	return ut
end

return Ugneta
