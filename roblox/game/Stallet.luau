--!strict
--[[ STALLET — vilken häst som är din, och var hon står.

	Ren logik, inga Roblox-anrop. Det är med flit: det här är regler, och
	regler ska gå att prova utan Studio. StallService gör instanserna.

	Boxarnas LÄGEN kommer ur UBRFKomplex.stall — samma mätta data som
	byggnaden byggs av. Ingen koordinat är skriven här.

	VILKEN häst som står i VILKEN box är däremot [antagande]. Det finns inget
	verifierat underlag för UBRF:s faktiska boxfördelning, och jag hittar inte
	på en. Fördelningen här är spelmekanik: stabil, jämnt spridd över
	stallets fyra rader, och utbytbar den dag verkligheten säger något annat.
]]

local Stallet = {}

local RS = game:GetService("ReplicatedStorage")
local Spel = require(RS.UBRFSpel)
local G = require(RS.UBRFKomplex)

local S = G.stall

--[[ Boxrutnätet härleds ur stalldatan i stället för att räknas upp:
	fyra rader × antalBoxar per rad. Ändras stallet följer boxarna med. ]]
function Stallet.boxantal(): number
	return #S.rader * S.antalBoxar
end

--[[ Box nummer n (1-baserat) → rad, plats i raden, och mittpunkt i
	VÄRLDSKOORDINATER. Ordningen är rad för rad, norrut i varje rad. ]]
function Stallet.box(n: number)
	local antal = Stallet.boxantal()
	if n < 1 or n > antal then return nil end

	local radIndex = math.floor((n - 1) / S.antalBoxar) + 1
	local plats = (n - 1) % S.antalBoxar + 1
	local rad = S.rader[radIndex]

	--[[ Boxens djup mäts från radens x0 och åt det håll raden vetter.
		vetter = 1 betyder att boxen ligger i positiv x från x0. ]]
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

--[[ Hästarnas boxar sprids över raderna i stället för att fylla en rad i
	taget. Annars står alla sjutton i rad W och stallets andra halva är tom,
	vilket ser ut som ett fel även om det inte är ett. ]]
function Stallet.boxNummerFor(hastId: string): number?
	local index = nil
	for k, id in ipairs(Spel.ordning) do
		if id == hastId then index = k break end
	end
	if not index then return nil end

	local rader = #S.rader
	local rad = (index - 1) % rader                    -- 0-baserad rad
	local plats = math.floor((index - 1) / rader)      -- 0-baserad plats
	if plats >= S.antalBoxar then return nil end
	return rad * S.antalBoxar + plats + 1
end

function Stallet.boxFor(hastId: string)
	local n = Stallet.boxNummerFor(hastId)
	return n and Stallet.box(n) or nil
end

--[[ Tilldelningen ska vara STABIL: samma spelare ska möta samma häst när hon
	kommer tillbaka, annars finns det inget förhållande att bygga. Den ska
	också vara förutsägbar i prov, alltså ingen slump.

	Här stod först math.abs(userId), med kommentaren att det skyddade mot de
	negativa UserId Studio ger i Play Solo. Falsifieringen visade att provet
	INTE föll när abs togs bort: Luas modulo följer divisorns tecken, så
	-12345 % 17 är 14, inte -14. Skyddet var alltså dött och kommentaren
	påstod något den inte gjorde. Provet står kvar — att negativa id fungerar
	är fortfarande värt att hålla fast — men koden låtsas inte längre. ]]
function Stallet.tilldela(userId: number): string
	local n = #Spel.ordning
	return Spel.ordning[(userId % n) + 1]
end

--[[ Tilldelning när någon annan redan står i boxen.

	`tilldela` ovan är ren modulo, och med 33 hästar betyder det att spelare
	vars UserId skiljer sig med 33 får SAMMA häst. På en ensam server syns
	det aldrig; med två spelare inne blir samma individ ledd ut ur boxen
	två gånger. G01-S2b:s acceptanskrav 3 förbjuder det.

	Regeln: börja på den häst spelaren skulle fått ändå och gå framåt tills
	en är ledig. Det bevarar stabiliteten — är din häst inte upptagen får du
	henne, varje gång — och ger ett förutsägbart andrahandsval i stället för
	slump.

	Är hela stallet upptaget returneras nil. Det är MENINGEN: hellre "vänta,
	det finns ingen häst åt dig just nu" än två ryttare på samma häst. ]]
function Stallet.tilldelaLedig(userId: number, upptagna: { [string]: boolean }?): string?
	local n = #Spel.ordning
	if n == 0 then return nil end
	local taget = upptagna or {}
	local start = userId % n
	for steg = 0, n - 1 do
		local id = Spel.ordning[(start + steg) % n + 1]
		if not taget[id] then return id end
	end
	return nil
end

--[[ Allt en spelare behöver veta vid ankomsten, i ett svar. ]]
function Stallet.dagensHast(userId: number, upptagna: { [string]: boolean }?)
	local id = Stallet.tilldelaLedig(userId, upptagna)
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

return Stallet
