--!strict
--[[
	INSPELNINGEN — spelarens faktiska ritt, en gång.

	G02-D (#137): "Record the player's actual ride once and reuse it for
	playback, comparison and assessment. Do not create a separate scoring
	model for replay."

	Därför gör den här modulen EN sak: den skriver ned vad som hände. Den
	bedömer ingenting. Betygen kommer ur HorseCore/Lektion och
	HorseCore/Ugneta som förut, ur samma telemetri som matar inspelningen.
	Det finns ingen andra bedömningsväg och ska inte finnas.

	MOTOROBEROENDE. Ingen Instance, ingen RunService, ingen GUI. Modulen
	tar emot dt, ett telemetriobjekt och en pose, och lämnar ifrån sig en
	post. Den speglar src/riding/inspelning.js på webben fält för fält.

	TIDPOLICY: `sim`. Tiden är ACKUMULERAD dt ur klientens RenderStepped,
	inte os.clock(). En ritt inspelad på 30 fps och en på 120 fps ska
	beskriva samma ritt, och en klient som tappar en bildruta ska inte
	spela in ett hål.

	TALEN KOMMER UR KANONEN. Sampeltakt, tak och varje övnings
	definitionsversion läses ur RidKanon.INSPELNING, som
	tools/exportera-ridkanon.mjs skriver ur src/riding/ovningsdef.js och
	src/riding/inspelning.js. En handskriven kopia här hade kunnat glida
	ifrån webben utan att någon grind blev röd.

	PRESTANDA: `sampla` anropas varje bildruta men skriver bara var 1/20 s.
	Övriga anrop faller på en jämförelse och returnerar. Ingenting skrivs
	till DataStore under ritten.
]]

local RidKanon = require(game:GetService("ReplicatedStorage").HorseCore.RidKanon)

local Inspelning = {}

local KANON = RidKanon.INSPELNING
Inspelning.SCHEMA = KANON.SCHEMA
Inspelning.HZ = KANON.HZ
Inspelning.MAX_SEK = KANON.MAX_SEK
Inspelning.MAX_SAMPEL = KANON.MAX_SEK * KANON.HZ
Inspelning.MAX_HANDELSER = 200

local DT = 1 / KANON.HZ

export type Sampel = {
	t: number,
	x: number?, z: number?, yaw: number?,
	gangart: string?,
	fart: number?, balans: number?, kurvatur: number?,
}

export type Handelse = { t: number, typ: string, data: any }

export type Post = {
	schema: number,
	ovning: string,
	ovningVersion: number,
	ram: string?,
	hast: string?,
	klocka: string,
	hz: number,
	sekunder: number,
	trunkerad: boolean,
	sampel: { Sampel },
	handelser: { Handelse },
}

export type Recorder = { post: Post, aktiv: boolean, t: number, nasta: number }

--[[ Ett tal som får skrivas ned. Samma disciplin som HorseCore/Lektion.tal
     och webbens insTal: saknat, NaN och oändlighet är INTE noll. Ett fält
     som inte gick att mäta blir nil i posten, och den som läser posten får
     veta att det saknades i stället för att tro på en nolla. ]]
local function tal(v: any): number?
	if type(v) ~= "number" then return nil end
	if v ~= v then return nil end                      -- NaN
	if v == math.huge or v == -math.huge then return nil end
	return v
end

--[[ Spelas den här övningen in?

     G02-D:s leverans är de TVÅ övningar som faktiskt har en definition med
     version och mätlista i kanonen. Att spela in en övning utan definition
     hade gett en post som ingen kan säga vad den betyder — och att hitta på
     en version åt den vore precis den påhittade referens beställningen
     förbjuder. Listan kommer ur kanonen, inte ur en if-sats här. ]]
function Inspelning.spelasIn(ovning: string?): boolean
	if type(ovning) ~= "string" then return false end
	return KANON.OVNING[ovning] ~= nil
end

function Inspelning.version(ovning: string): number?
	local d = KANON.OVNING[ovning]
	return d and d.version or nil
end

--[[ Kan den här posten läsas av koden som kör nu?

     Tre svar, aldrig ett tyst ja — samma tre som webbens inspelningLasbar:
     "ok" när schema och övningsversion stämmer, "gammal" när posten är
     läsbar men äldre än definitionen (en jämförelse mot den ska MÄRKAS),
     och "nej" med skäl när den inte får tolkas alls. ]]
function Inspelning.lasbar(post: any): { ok: boolean, lage: string, skal: string }
	if type(post) ~= "table" then
		return { ok = false, lage = "nej", skal = "ingen post" }
	end
	if post.schema ~= Inspelning.SCHEMA then
		return { ok = false, lage = "nej",
			skal = `schema {tostring(post.schema)} mot {Inspelning.SCHEMA}` }
	end
	local d = if type(post.ovning) == "string" then KANON.OVNING[post.ovning] else nil
	if not d then
		return { ok = false, lage = "nej", skal = `okänd övning {tostring(post.ovning)}` }
	end
	if post.ovningVersion ~= d.version then
		return { ok = true, lage = "gammal",
			skal = `övningsversion {tostring(post.ovningVersion)} mot {d.version}` }
	end
	return { ok = true, lage = "ok", skal = "" }
end

--[[ Startar en inspelning. Returnerar nil för en övning utan definition —
     hellre ingen post än en post utan betydelse. ]]
function Inspelning.ny(ovning: string, hast: string?): Recorder?
	local d = if type(ovning) == "string" then KANON.OVNING[ovning] else nil
	if not d then return nil end
	return {
		aktiv = true, t = 0, nasta = 0,
		post = {
			schema = Inspelning.SCHEMA,
			ovning = ovning,
			ovningVersion = d.version,
			ram = d.ram,
			hast = hast,
			klocka = "sim",
			hz = Inspelning.HZ,
			sekunder = 0,
			trunkerad = false,
			sampel = {},
			handelser = {},
		},
	}
end

--[[ POSEN, VALIDERAD FÄLT FÖR FÄLT.

     Det här är rättelsen som beställningen ber om uttryckligen: en pose
     där x eller z är trasig men yaw är ett riktigt tal ska behålla YAW.
     Ett tidigare utkast kastade hela posen så fort ett fält inte höll —
     och då förlorade uppspelningen hästens riktning i varje bildruta där
     positionen råkade vara omätbar, trots att riktningen var mätt.

     Motsatsen vore lika fel: att fylla i noll för det som saknas. Noll är
     ett läge och en riktning, inte "vet inte". Fältet blir nil. ]]
local function pose(p: any): (number?, number?, number?)
	if type(p) ~= "table" then return nil, nil, nil end
	return tal(p.x), tal(p.z), tal(p.yaw)
end

--[[ Ett steg ur ridloopen. Anropas varje bildruta; skriver var 1/20 s.

     `dt` måste vara ett riktigt positivt tal inom rimliga gränser. En
     klient som återvänder från bakgrunden med dt = 4,2 s ska inte skriva
     ett sampel som påstår att hästen teleporterade. ]]
function Inspelning.sampla(r: Recorder?, dt: any, tm: { [string]: any }?, p: any): boolean
	if not r or not r.aktiv then return false end
	local d = tal(dt)
	if d == nil or d <= 0 or d > 0.5 then return false end

	r.t += d
	if r.t < r.nasta then return false end
	--[[ Nästa sampel schemaläggs från FÖRRA MÅLET, inte från nu. Skrevs
	     `r.nasta = r.t + DT` blev intervallet en bildruta för långt varje
	     gång och takten drev. Har vi hamnat efter — en lång bildruta —
	     resynkas i stället för att skriva en skur av sampel i kapp. ]]
	r.nasta += DT
	if r.nasta <= r.t then r.nasta = r.t + DT end

	if #r.post.sampel >= Inspelning.MAX_SAMPEL then
		r.post.trunkerad = true
		r.aktiv = false
		return false
	end

	local x, z, yaw = pose(p)
	local t = if type(tm) == "table" then tm else {}
	table.insert(r.post.sampel, {
		t = math.floor(r.t * 1000 + 0.5) / 1000,
		x = x, z = z, yaw = yaw,
		gangart = if type(t.gangart) == "string" then t.gangart else nil,
		fart = tal(t.fart),
		balans = tal(t.balans),
		kurvatur = tal(t.kurvatur),
	})
	r.post.sekunder = r.post.sampel[#r.post.sampel].t
	return true
end

--[[ En diskret händelse — gångartsbyte, avbrott, avsittning. Samma
     simklocka som samplen, så att de går att lägga bredvid varandra. ]]
function Inspelning.handelse(r: Recorder?, typ: string?, data: any): boolean
	if not r or not r.aktiv or type(typ) ~= "string" or typ == "" then return false end
	if #r.post.handelser >= Inspelning.MAX_HANDELSER then return false end
	table.insert(r.post.handelser, {
		t = math.floor(r.t * 1000 + 0.5) / 1000, typ = typ, data = data,
	})
	return true
end

--[[ Avslutar och lämnar posten. Efter det här är inspelaren stängd: ett
     sent `sampla` från en bildruta som redan var i luften kan inte skriva
     in sig i en avslutad ritt. ]]
function Inspelning.avsluta(r: Recorder?): Post?
	if not r then return nil end
	r.aktiv = false
	return r.post
end

--[[ ── UPPSPELNINGEN ────────────────────────────────────────────────
     Läser en post. Ändrar den ALDRIG, och rör ingenting levande: ingen
     häst, ingen progression, inget serverauktoritativt tillstånd.

     Interpolationen vägrar interpolera mellan sampel den inte litar på:
     saknas ett tal i något av de två grannsamplen blir svaret nil för just
     det fältet, i stället för ett halvvägs-tal mellan ett mätvärde och
     ingenting. ]]
local function lerp(a: number?, b: number?, k: number): number?
	if a == nil or b == nil then return nil end
	return a + (b - a) * k
end

--[[ Vinklar interpoleras kortaste vägen — annars snurrar hästen ett helt
     varv när yaw passerar π. ]]
local function lerpVinkel(a: number?, b: number?, k: number): number?
	if a == nil or b == nil then return nil end
	local d = b - a
	while d > math.pi do d -= 2 * math.pi end
	while d < -math.pi do d += 2 * math.pi end
	return a + d * k
end

--[[ Tillståndet vid en tidpunkt. nil när posten är tom — en uppspelning
     utan sampel ska inte låtsas ha ett läge. ]]
function Inspelning.vid(post: Post?, tid: any): Sampel?
	if type(post) ~= "table" then return nil end
	local S = post.sampel
	if type(S) ~= "table" or #S == 0 then return nil end
	local n = tal(tid) or 0
	local t = math.max(0, math.min(post.sekunder, n))

	--[[ Binärsökning: en uppspelning ska inte bli långsammare ju längre
	     ritten var. ]]
	local lo, hi = 1, #S
	while lo < hi - 1 do
		local m = (lo + hi) // 2
		if S[m].t <= t then lo = m else hi = m end
	end
	local a, b = S[lo], S[hi]
	if a == b or b.t <= a.t then return a end
	local k = math.max(0, math.min(1, (t - a.t) / (b.t - a.t)))
	return {
		t = t,
		x = lerp(a.x, b.x, k),
		z = lerp(a.z, b.z, k),
		yaw = lerpVinkel(a.yaw, b.yaw, k),
		--[[ Gångarten är DISKRET. Halvvägs mellan trav och skritt finns
		     ingen gångart; närmaste sampel gäller. ]]
		gangart = if k < 0.5 then a.gangart else b.gangart,
		fart = lerp(a.fart, b.fart, k),
		balans = lerp(a.balans, b.balans, k),
		kurvatur = lerp(a.kurvatur, b.kurvatur, k),
	}
end

return Inspelning
