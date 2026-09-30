--!strict
--[[
	JEV-SKUGGAN PÅ SERVERN (JEV-POC-2, #270, arkitektur A').

	Ett experiment, avstängt som standard. Efter varje avslutat
	lektionsförsök speglar klienten försöksunderlaget hit. Servern validerar
	det, räknar om Ugnetas besked med den BEFINTLIGA regeln och frågar Jev
	samma sak i bakgrunden. Båda svaren hamnar i en ringbuffert i minnet.
	Ingenting annat händer.

	VAD SOM ALDRIG FÅR HÄNDA, och som modulen är byggd kring:

	- Jevs svar går ingenstans utom bufferten: ingen text till spelaren,
	  ingen skrivning i häst, lektion, poäng, progression, tävling eller
	  sparning. Handlaren läser `horseOf` och ingenting annat i spelet.
	- Ett fel i Jev-vägen syns inte: allt nätverk går i `task.spawn` +
	  `pcall`, utan omförsök, med en ändlig tidsgräns.
	- Hemligheten lämnar aldrig `RequestAsync`: den loggas inte, skrivs
	  inte till bufferten och tas aldrig till text.
	- Ingen spelaridentitet sparas eller skickas. Spelaren används bara
	  som nyckel för takten, i en svag tabell.

	Flaggan är `ServerStorage`-attributet `JevShadowEnabled == true`, läst
	en gång vid start. Kontraktet: docs/JEV-POC-2-SHADOW-CONTRACT.md.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JevShadowPolicy = require(ReplicatedStorage.HorseCore.JevShadowPolicy)
local Networking = require(ReplicatedStorage.HorseCore.Networking)

local JevShadow = {}

JevShadow.HEMLIGHET = "typesafe"
JevShadow.TIMEOUT_SEK = 4
JevShadow.COOLDOWN_SEK = 10
JevShadow.GLOBAL_PER_MIN = 20
JevShadow.MAX_PROV = 200

export type Deps = {
	remote: any,
	horseOf: (any) -> any,
	hamtaHemlighet: () -> any,
	begar: ({ [string]: any }) -> any,
	kodaJson: (any) -> string,
	avkodaJson: (string) -> any,
	klocka: () -> number,
	spawn: ((...any) -> ()) -> (),
	logg: (string) -> (),
}

local deps: Deps? = nil
local prov: { { [string]: any } } = {}
local raknare = 0
local senast: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local iLuften: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local globala: { number } = {}
local anslutning: any = nil

local function spara(post: { [string]: any })
	table.insert(prov, post)
	while #prov > JevShadow.MAX_PROV do table.remove(prov, 1) end
	local d = deps
	if d then
		d.logg(("[JevSkugga] %s kalla=%s%s"):format(post.id, post.kalla,
			if post.status then " status=" .. tostring(post.status)
				elseif post.reason then " skal=" .. post.reason else ""))
	end
end

local function nyPost(d: Deps, kalla: string): { [string]: any }
	raknare += 1
	return { id = "s" .. raknare, t = math.floor(d.klocka() * 1000) / 1000, kalla = kalla }
end

--[[ Takten: 10 s per spelare, en förfrågan i luften per spelare och högst
     20 per minut för hela servern. Ett försök är 22 s, så spärren per
     spelare stänger aldrig ute ett riktigt försök — bara en klient som
     skickar mer än ritten ger. ]]
local function takt(d: Deps, spelare: any): string?
	local nu = d.klocka()
	local s = senast[spelare]
	if s and nu - s < JevShadow.COOLDOWN_SEK then return "cooldown" end
	if iLuften[spelare] then return "i_luften" end
	local kvar = {}
	for _, t in globala do
		if nu - t < 60 then table.insert(kvar, t) end
	end
	globala = kvar
	if #globala >= JevShadow.GLOBAL_PER_MIN then return "globalt_tak" end
	return nil
end

--[[ Ett KASTAT anrop är en timeout om felet säger det eller om det kastades
     först efter tidsgränsen. Roblox skriver `HttpError: Timedout` — ett ord,
     inte "timed out" — så alla tre stavningarna prövas. Ett anrop som
     faktiskt SVARADE räknas aldrig som timeout, hur sent det än kom. ]]
local function arTimeout(fel: any, latens: number): boolean
	if latens >= JevShadow.TIMEOUT_SEK then return true end
	local s = string.lower(tostring(fel))
	return string.find(s, "timedout", 1, true) ~= nil
		or string.find(s, "timed out", 1, true) ~= nil
		or string.find(s, "timeout", 1, true) ~= nil
end

--[[ Nätverksdelen. Körs ALLTID i en egen tråd och ALLTID i pcall. Hur
     det än går blir resultatet en post i bufferten och inget annat. ]]
local function fraga(d: Deps, spelare: any, post: { [string]: any }, rent: JevShadowPolicy.Rent, hemlighet: any)
	local start = d.klocka()
	local ok, svar = pcall(function()
		return d.begar({
			Url = JevShadowPolicy.URL,
			Method = "POST",
			Headers = {
				["Authorization"] = hemlighet,
				["Content-Type"] = "application/json",
				["Accept"] = "application/json",
			},
			Body = d.kodaJson(JevShadowPolicy.kropp(rent)),
			Timeout = JevShadow.TIMEOUT_SEK,
		})
	end)
	local latens = d.klocka() - start
	post.latensMs = math.floor(latens * 1000 + 0.5)
	iLuften[spelare] = nil
	if not ok then
		post.kalla = if arTimeout(svar, latens) then "timeout" else "api_error"
		post.reason = if post.kalla == "api_error" then "anrop" else nil
		spara(post)
		return
	end
	local status = if type(svar) == "table" then svar.StatusCode else nil
	post.status = if type(status) == "number" then status else nil
	if type(svar) ~= "table" or svar.Success ~= true
		or type(status) ~= "number" or status < 200 or status > 299 then
		post.kalla = "api_error"
		spara(post)
		return
	end
	local okJ, tabell = pcall(d.avkodaJson, svar.Body)
	if not okJ then
		post.kalla, post.reason = "api_error", "avkodning"
		spara(post)
		return
	end
	local tolkat, skal = JevShadowPolicy.tolka(tabell, rent)
	if not tolkat then
		post.kalla, post.reason = "api_error", skal
		spara(post)
		return
	end
	post.kalla = "jev"
	post.jev = { fokus = tolkat.fokus, confidence = tolkat.confidence, model = tolkat.model }
	post.agree = tolkat.fokus == post.ugneta.fokus
	spara(post)
end

--[[ Mottagaren. Returnerar postens källa så att provet kan läsa den
     synkront; nätverksvägen svarar `"skickad"` och fyller i posten senare. ]]
function JevShadow._mottag(spelare: any, payload: any): string
	local d = deps
	if not d then return "av" end
	local rent, skal = JevShadowPolicy.validera(payload)
	if not rent then
		--[[ Ingenting ur det avvisade underlaget sparas — bara skälet. ]]
		local post = nyPost(d, "invalid_input")
		post.reason = skal
		spara(post)
		return "invalid_input"
	end
	--[[ Båda sidor får det PROJICERADE underlaget: jämförelsen räknas på
	     det, kroppen byggs av det, och provet sparar exakt det som gick
	     till Jev. Namnen på det som klipptes bort sparas för granskningen. ]]
	local proj, projSkal, bort = JevShadowPolicy.projicera(rent)
	local post = nyPost(d, "hard_gate")
	post.ovningId, post.forsokNr = rent.ovningId, rent.forsokNr
	post.utanforOvning = bort
	if not proj then
		post.reason = projSkal
		spara(post)
		return "hard_gate"
	end
	rent = proj
	local fokus, kort = JevShadowPolicy.ugneta(rent)
	post.nu, post.fore = rent.nu, rent.fore
	post.ugneta = { fokus = fokus, obs = kort }

	local okH, rider = pcall(d.horseOf, spelare)
	if not okH or rider == nil then
		post.reason = "ej_uppsuten"
		spara(post)
		return "hard_gate"
	end
	local stopp = takt(d, spelare)
	if stopp then
		post.reason = stopp
		spara(post)
		return "hard_gate"
	end
	local okS, hemlighet = pcall(d.hamtaHemlighet)
	if not okS or hemlighet == nil then
		post.reason = "ingen_hemlighet"
		spara(post)
		return "hard_gate"
	end
	senast[spelare] = d.klocka()
	iLuften[spelare] = true
	table.insert(globala, d.klocka())
	d.spawn(function()
		local okF = pcall(fraga, d, spelare, post, rent, hemlighet)
		if not okF then
			iLuften[spelare] = nil
			post.kalla, post.reason = "api_error", "internt"
			spara(post)
		end
	end)
	return "skickad"
end

--[[ Med beroenden inskjutna — så kör provet, och så kör `start` i drift.
     Anslutningen görs en gång; ett andra anrop byter bara beroendena. ]]
function JevShadow._start(d: Deps)
	deps = d
	if anslutning == nil then
		d.remote:SetAttribute("Aktiv", true)
		anslutning = d.remote.OnServerEvent:Connect(function(spelare, payload)
			pcall(JevShadow._mottag, spelare, payload)
		end)
	end
end

--[[ Nollställ, bara för prov. ]]
function JevShadow._aterstall()
	if anslutning then pcall(function() anslutning:Disconnect() end) end
	anslutning = nil
	deps = nil
	prov = {}
	raknare = 0
	senast = setmetatable({}, { __mode = "k" }) :: any
	iLuften = setmetatable({}, { __mode = "k" }) :: any
	globala = {}
end

--[[ I drift. Flaggan AV betyder: ingen lyssnare, inget attribut, ingen
     hemlighet läst, inget nätverk. Returnerar om skuggan startades. ]]
function JevShadow.start(horseOf: (any) -> any): boolean
	local ServerStorage = game:GetService("ServerStorage")
	if ServerStorage:GetAttribute("JevShadowEnabled") ~= true then return false end
	local Http = game:GetService("HttpService")
	JevShadow._start({
		remote = Networking.get("JevSkugga"),
		horseOf = horseOf,
		hamtaHemlighet = function()
			return Http:GetSecret(JevShadow.HEMLIGHET):AddPrefix("Bearer ")
		end,
		begar = function(req) return Http:RequestAsync(req :: any) end,
		kodaJson = function(v) return Http:JSONEncode(v) end,
		avkodaJson = function(s) return Http:JSONDecode(s) end,
		klocka = os.clock,
		spawn = function(f) task.spawn(f) end,
		logg = print,
	})
	return true
end

--[[ ── Läsning (MCP / serverkonsolen) ──────────────────────────────── ]]

function JevShadow.prov(): { { [string]: any } }
	return table.clone(prov)
end

local function percentil(sorterad: { number }, p: number): number?
	if #sorterad == 0 then return nil end
	local i = math.clamp(math.ceil(p * #sorterad), 1, #sorterad)
	return sorterad[i]
end

function JevShadow.sammanfattning(): { [string]: any }
	local kallor: { [string]: number } = {}
	local jev, lika = 0, 0
	local latens = {}
	for _, p in prov do
		kallor[p.kalla] = (kallor[p.kalla] or 0) + 1
		if p.kalla == "jev" then
			jev += 1
			if p.agree then lika += 1 end
		end
		if type(p.latensMs) == "number" then table.insert(latens, p.latensMs) end
	end
	table.sort(latens)
	return {
		antal = #prov,
		kallor = kallor,
		jev = jev,
		lika = lika,
		andelLika = if jev > 0 then lika / jev else nil,
		latensP50 = percentil(latens, 0.5),
		latensP95 = percentil(latens, 0.95),
		latensMax = latens[#latens],
	}
end

return JevShadow
