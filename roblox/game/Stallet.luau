--!strict
--[[ STALLET — vilken häst som är din, och var hon står.

	Ren logik, inga Roblox-anrop. Det är med flit: det här är regler, och
	regler ska gå att prova utan Studio. StallService gör instanserna.

	Boxarnas LÄGEN kommer ur UBRFKomplex.stall — samma mätta data som
	byggnaden byggs av. Ingen koordinat är skriven här.

	VILKEN häst som står i VILKEN box är däremot [antagande]. Det finns inget
	verifierat underlag för UBRF:s faktiska boxfördelning, och vi hittar inte
	på en. Fördelningen här är spelmekanik: stabil, jämnt spridd över stallets
	fyra rader, och utbytbar den dag verkligheten säger något annat.
]]

local Stallet = {}

local RS = game:GetService("ReplicatedStorage")
local Spel = require(RS.UBRFSpel)
local G = require(RS.UBRFKomplex)

local S = G.stall

function Stallet.boxantal(): number
	return #S.rader * S.antalBoxar
end

function Stallet.box(n: number)
	local antal = Stallet.boxantal()
	if n < 1 or n > antal then return nil end

	local radIndex = math.floor((n - 1) / S.antalBoxar) + 1
	local plats = (n - 1) % S.antalBoxar + 1
	local rad = S.rader[radIndex]
	local x0 = rad.x0
	local xMitt = x0 + rad.vetter * rad.djup / 2
	local yMitt = S.boxStartY + (plats - 0.5) * S.boxB

	return {
		nummer = n,
		rad = rad.id,
		plats = plats,
		gang = rad.gang,
		lokal = { x = xMitt, y = yMitt },
		varld = { x = S.origo.x + xMitt, y = S.origo.y + yMitt },
	}
end

function Stallet.boxNummerFor(hastId: string): number?
	local index = nil
	for k, id in ipairs(Spel.ordning) do
		if id == hastId then index = k break end
	end
	if not index then return nil end

	local rader = #S.rader
	local rad = (index - 1) % rader
	local plats = math.floor((index - 1) / rader)
	if plats >= S.antalBoxar then return nil end
	return rad * S.antalBoxar + plats + 1
end

function Stallet.boxFor(hastId: string)
	local n = Stallet.boxNummerFor(hastId)
	return n and Stallet.box(n) or nil
end

-- Stabil preferens för en spelare. Den här funktionen ensam garanterar inte
-- samtidighetsunikhet; StallService använder tilldelaLedig när flera spelare
-- finns i samma server.
function Stallet.tilldela(userId: number): string
	local n = #Spel.ordning
	assert(n > 0, "hästordningen är tom")
	return Spel.ordning[(userId % n) + 1]
end

--[[ Stabil preferens + serverunikhet.

	Spelarens normala häst provas först. Är hon redan upptagen i den aktuella
	servern går vi deterministiskt vidare genom rosterordningen tills en ledig
	häst hittas. När ingen är ledig returneras nil i stället för att två spelare
	får samma fysiska häst.

	`upptagna` är en mängd med häst-id som nycklar. Ren data in, ren data ut. ]]
function Stallet.tilldelaLedig(userId: number, upptagna: { [string]: any }): string?
	local n = #Spel.ordning
	if n == 0 then return nil end
	local start = (userId % n) + 1
	for steg = 0, n - 1 do
		local index = ((start - 1 + steg) % n) + 1
		local id = Spel.ordning[index]
		if not upptagna[id] then
			return id
		end
	end
	return nil
end

local function paket(id: string?)
	if not id then return nil end
	local hast = Spel.hastar[id]
	if not hast then return nil end
	return {
		id = id,
		namn = hast.namn,
		ras = hast.ras,
		typ = hast.typ,
		besk = hast.besk,
		foder = Spel.foder[id],
		box = Stallet.boxFor(id),
	}
end

function Stallet.hast(hastId: string)
	return paket(hastId)
end

function Stallet.dagensHast(userId: number, upptagna: { [string]: any }?)
	local id = if upptagna then Stallet.tilldelaLedig(userId, upptagna) else Stallet.tilldela(userId)
	return paket(id)
end

return Stallet
