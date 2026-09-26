--!strict
--[[ RIDPLATSOBSERVATIONEN — serverns observerade ridläge i ridhusets
	platsram (#264 INFRA-OBS-PLATS1).

	En brygga, inte en ny mätning. `HorseService` matar den i samma
	uthållighetssteg som ridobservationen, med ridobservationens eget besked
	(`RidObservation.sampla` → status och föregående giltiga läge), och den
	löser läget mot `Ridhusplats`. Ingen andra koordinatkanon och ingen
	andra rörelsesampling: rotens läge, stegets tid och kontinuiteten är
	ridobservationens.

	── VAD EN BILD SÄGER ─────────────────────────────────────────────
	Per ritt, det AKTUELLA: `punkt` (u, h, v) i meter i ridhusets lokala
	ram (u tvärs, h över sandens överkant, v från A mot C), `iBana` och
	`iDressyr` (PLANÄRT medlemskap — säger ingenting om att hästen står på
	golvet; `h` bär höjden), plats- och ram-id, ritt/häst/ryttare, tid och
	status. BARA för ett giltigt sammanhängande segment i samma ram finns
	`segment` med båda lokala ändpunkterna. Ingen historik: bara det senaste.

	Status:
	  · "segment"      giltigt segment i samma ram; `segment` finns,
	  · "baslinje"     första giltiga läget i ett avsnitt; ingen `segment`,
	  · "brott"        ridobservationen bröt avsnittet (lucka, saknat läge,
	                   teleport, ogiltigt dt); ingen `segment`,
	  · "ram_ny"       ridobservationen såg ett segment, men ramen har bytts
	                   sedan förra läget — inget segment mellan två ramar,
	  · "ingen_plats"  platsen går inte att lösa (`skal` bär varför),
	  · "stangd"       ritten är avslutad.

	── RAMEN ─────────────────────────────────────────────────────────
	Ridhusets modell hittas en gång vid start (delen med `PlatsId =
	"ridhus_bana"`), och platsen hålls i cache. Den löses om ENDAST när den
	är smutsig: ett barn har lagts till i eller tagits bort ur ridhusets
	modell, eller en av de två cachade delarnas avtryck (läge, axlar, mått)
	har ändrats — det senare kontrolleras per steg på två delar, inget
	svep. En ny eller ändrad ram får ett NYTT ram-id och bryter
	kontinuiteten; en oförändrad ram behåller sitt id. Är platsen ogiltig
	prövas den om högst var FORSOK_VANTA:e steg.

	Inget här är poäng, lektion, fuskskydd eller persistens. ]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ridhusplats = require(ReplicatedStorage.HorseCore.Ridhusplats)

local RidPlatsObservation = {}

RidPlatsObservation.VERSION = 1
RidPlatsObservation.PLATS_ID = "ridhus"
RidPlatsObservation.MAX_AVSLUTADE = 32
RidPlatsObservation.FORSOK_VANTA = 4
RidPlatsObservation.HOJD = "h = höjd över sandens överkant i meter; iBana/iDressyr är planärt medlemskap, inte markkontakt"

type Ritt = {
	rittId: string, hastId: string, userId: number,
	oppen: boolean, bild: any,
	sistaLage: Vector3?, sistaRam: number?,
}

local rot: Instance? = nil
local ram = {
	modell = nil :: Instance?,
	plats = nil :: any,
	delar = nil :: any,
	avtryck = nil :: string?,
	skal = "ingen_byggnad" :: string?,
	id = 0,
	smutsig = true,
	vanta = 0,
}
local ritter: { [string]: Ritt } = {}
local avslutade: { string } = {}

local function andligt(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function vektorOk(p: any): boolean
	if p == nil then return false end
	local ok, x, y, z = pcall(function() return p.X, p.Y, p.Z end)
	return ok and andligt(x) and andligt(y) and andligt(z)
end

--[[ En dels avtryck: läge, de tre axlarna och måtten. Samma avtryck =
	samma geometri; ett annat = ramen är smutsig. ]]
local function avtryck(del: any): string
	local ok, ut = pcall(function()
		local cf, s = del.CFrame, del.Size
		local p = cf.Position
		local ax = (cf * CFrame.new(1, 0, 0)).Position - p
		local az = (cf * CFrame.new(0, 0, 1)).Position - p
		return string.format("%.6f,%.6f,%.6f|%.6f,%.6f,%.6f|%.6f,%.6f,%.6f|%.6f,%.6f,%.6f",
			p.X, p.Y, p.Z, ax.X, ax.Y, ax.Z, az.X, az.Y, az.Z, s.X, s.Y, s.Z)
	end)
	return if ok then ut else "?"
end

local function avtryckFor(delar: any): string
	return avtryck(delar.bana) .. "#" .. avtryck(delar.dressyr)
end

--[[ Den aktuella ramen: (plats, ramId) eller (nil, nil, skäl). ]]
local function aktuellRam(): (any, number?, string?)
	if ram.delar and not ram.smutsig then
		local d = ram.delar
		if d.bana.Parent ~= ram.modell or d.dressyr.Parent ~= ram.modell
			or avtryckFor(d) ~= ram.avtryck then
			ram.smutsig = true
		end
	end
	if not ram.plats and not ram.smutsig then
		--[[ Ogiltig plats: pröva om, men inte varje steg. ]]
		ram.vanta -= 1
		if ram.vanta <= 0 then ram.smutsig = true end
	end
	if ram.smutsig then
		ram.smutsig = false
		local plats, skal, delar = Ridhusplats.los(ram.modell)
		if not plats then
			ram.plats, ram.delar, ram.avtryck = nil, nil, nil
			ram.skal = skal or "ingen_byggnad"
			ram.vanta = RidPlatsObservation.FORSOK_VANTA
		else
			local nytt = avtryckFor(delar)
			local samma = ram.plats ~= nil and ram.delar ~= nil
				and ram.delar.bana == delar.bana and ram.delar.dressyr == delar.dressyr
				and ram.avtryck == nytt
			if not samma then ram.id += 1 end
			ram.plats, ram.delar, ram.avtryck, ram.skal = plats, delar, nytt, nil
		end
	end
	if ram.plats then return ram.plats, ram.id, nil end
	return nil, nil, ram.skal
end

function RidPlatsObservation.start(r: Instance)
	rot = r
	for _, d in ipairs(r:GetDescendants()) do
		local ok, id = pcall(function() return d:GetAttribute("PlatsId") end)
		if ok and id == Ridhusplats.ID.bana then
			ram.modell = d.Parent
			break
		end
	end
	ram.smutsig = true
	--[[ Barn som läggs till i eller tas bort ur ridhusets modell gör ramen
		smutsig. Bara en jämförelse per händelse; inget svep. ]]
	r.DescendantAdded:Connect(function(d)
		if ram.modell ~= nil and d.Parent == ram.modell then
			ram.smutsig = true
		elseif ram.modell == nil then
			local ok, id = pcall(function() return d:GetAttribute("PlatsId") end)
			if ok and id == Ridhusplats.ID.bana then
				ram.modell = d.Parent
				ram.smutsig = true
			end
		end
	end)
	r.DescendantRemoving:Connect(function(d)
		if ram.modell == nil then return end
		if d == ram.modell then
			ram.modell = nil
			ram.smutsig = true
		elseif d.Parent == ram.modell then
			ram.smutsig = true
		end
	end)
end

--[[ Sätter ridhusets modell uttryckligen (för den som vill peka ut en annan
	byggnad). Gör ramen smutsig. ]]
function RidPlatsObservation.satModell(modell: Instance?)
	ram.modell = modell
	ram.smutsig = true
end

function RidPlatsObservation.starta(rittId: string, hastId: string, userId: number): boolean
	if type(rittId) ~= "string" or rittId == "" or ritter[rittId] then return false end
	ritter[rittId] = {
		rittId = rittId, hastId = tostring(hastId), userId = tonumber(userId) or 0,
		oppen = true, bild = nil, sistaLage = nil, sistaRam = nil,
	}
	ritter[rittId].bild = table.freeze({
		v = RidPlatsObservation.VERSION, platsId = RidPlatsObservation.PLATS_ID,
		rittId = rittId, hastId = tostring(hastId), userId = tonumber(userId) or 0,
		status = "ingen_observation", hojd = RidPlatsObservation.HOJD,
	})
	return true
end

local function lokal(plats: any, p: Vector3): any
	local l = Ridhusplats.tillLokal(plats, p)
	return table.freeze({ u = l.X, h = l.Y, v = l.Z })
end

--[[ Ett uthållighetssteg: ridobservationens status, föregående giltiga
	läge (`fran`, bara vid "segment"), rotens läge och ritt-tiden. ]]
function RidPlatsObservation.sampla(rittId: string?, status: string?, fran: Vector3?,
	pos: Vector3?, t: number?): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	local plats, ramId, skal = aktuellRam()
	local posOk = vektorOk(pos)
	local b: { [string]: any } = {
		v = RidPlatsObservation.VERSION, platsId = RidPlatsObservation.PLATS_ID,
		rittId = r.rittId, hastId = r.hastId, userId = r.userId,
		t = if andligt(t) then t else nil,
		ramId = ramId, hojd = RidPlatsObservation.HOJD,
	}
	if not plats then
		b.status = "ingen_plats"
		b.skal = skal
		r.sistaLage, r.sistaRam = nil, nil
	else
		if posOk then
			b.punkt = lokal(plats, pos :: Vector3)
			b.iBana = Ridhusplats.inom(plats, "bana", pos :: Vector3)
			b.iDressyr = Ridhusplats.inom(plats, "dressyr", pos :: Vector3)
		end
		--[[ Ett segment kräver ALLT: ridobservationens "segment", att dess
			föregående läge är exakt det läge bryggan senast registrerade,
			och att ramen är densamma. Annars inget segment. ]]
		local sl = r.sistaLage
		local sammaStart = fran ~= nil and sl ~= nil and fran.X == sl.X and fran.Y == sl.Y and fran.Z == sl.Z
		if status == "segment" and posOk and sammaStart and r.sistaRam == ramId then
			b.status = "segment"
			b.segment = table.freeze({ fran = lokal(plats, fran :: Vector3), till = b.punkt })
		elseif status == "segment" then
			b.status = "ram_ny"
		elseif status == "baslinje" or status == "brott" then
			b.status = status
		else
			b.status = tostring(status or "okand")
		end
		if posOk then
			r.sistaLage, r.sistaRam = pos, ramId
		else
			r.sistaLage, r.sistaRam = nil, nil
		end
	end
	r.bild = table.freeze(b)
	return true
end

function RidPlatsObservation.avsluta(rittId: string?, satt: string): boolean
	local r = rittId and ritter[rittId]
	if not r or not r.oppen then return false end
	r.oppen = false
	r.sistaLage, r.sistaRam = nil, nil
	r.bild = table.freeze({
		v = RidPlatsObservation.VERSION, platsId = RidPlatsObservation.PLATS_ID,
		rittId = r.rittId, hastId = r.hastId, userId = r.userId,
		status = "stangd", satt = satt, hojd = RidPlatsObservation.HOJD,
	})
	table.insert(avslutade, r.rittId)
	while #avslutade > RidPlatsObservation.MAX_AVSLUTADE do
		ritter[table.remove(avslutade, 1)] = nil
	end
	return true
end

--[[ Den aktuella bilden för en ritt (fryst), eller nil. ]]
function RidPlatsObservation.ogonblick(rittId: string?): any
	local r = rittId and ritter[rittId]
	return if r then r.bild else nil
end

--[[ Provkrokar. ]]
function RidPlatsObservation._antalRitterForProv(): number
	local n = 0
	for _ in pairs(ritter) do n += 1 end
	return n
end

function RidPlatsObservation._ramForProv(): (number, boolean)
	return ram.id, ram.plats ~= nil
end

function RidPlatsObservation._glomRitterForProv()
	ritter = {}
	avslutade = {}
end

return RidPlatsObservation
