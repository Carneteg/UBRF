--!strict
--[[
	SPRÅKET — spelarens text, svenska eller engelska, ur en källa.

	Produktkravet i #162: svenska för svenska spelare, engelska annars, och
	ingen hårdkodad spelartext i logiken. Den här modulen är UPPSLAGET;
	texten själv ligger i `ReplicatedStorage.UBRFSprak`, som genereras ur
	`src/spel/sprak.js` — samma källa som webben läser. Skälet är detsamma
	som för hästdatan: en spelare som byter plattform ska läsa samma ord.

	REGELN, på ett ställe: en locale som börjar på `sv` ger svenska, allt
	annat ger engelska. Roblox svarar med strängar som `sv-se` och `en-us`;
	`sprakFor` bryr sig bara om de två första tecknen, så `sv-fi` läser
	också svenska.

	FALLBACKEN ÄR SVENSKA, INTE TOMHET. Saknas en engelsk text visas den
	svenska — och `saknade("en")` räknar dem, så en lucka syns i grinden i
	stället för att bli ett tomt HUD-fält hos spelaren. Det finns dessutom
	en redovisad översättningsskuld: hästarnas verkliga beskrivningar och
	skötselkanonens undervisande text är svenska och får inte
	maskinöversättas av en builder (se `Sprak.backlog`).

	KLIENTEN översätter. Servern äger reglerna och skickar nycklar där den
	kan; texten sätts där spelarens locale är känd. Anropas modulen på
	servern utan spelare faller den tillbaka på serverns egen locale, och
	det är en medveten degradering: en logg får bli engelsk, en HUD får
	inte bli fel.
]]

local RS = game:GetService("ReplicatedStorage")

local Sprak = {}

--[[ Texttabellen laddas LAT och i två steg, och båda stegen har ett skäl:

	  · `require(RS.UBRFSprak)` är den snabba vägen och den enda formen
	    testbänken kan foga ihop (build.py skriver om just det uttrycket
	    till modulnamnet). Indexeringen kan kasta på en klient som hunnit
	    starta före replikeringen.
	  · `WaitForChild` är då den riktiga vägen, och den blockerar bara den
	    första gången.

	Faller båda blir tabellen tom, och varje uppslag svarar med sin nyckel.
	Det är avsiktligt fult: en HUD som visar `hud.du_rider` säger att
	texttabellen inte kom med i bygget, medan ett tomt fält inte säger
	någonting alls. ]]
local data: any = nil
local function tabell(): any
	if data then return data end
	local ok, modul = pcall(function()
		return require(RS.UBRFSprak)
	end)
	if not ok then
		ok, modul = pcall(function()
			return require((RS :: any):WaitForChild("UBRFSprak"))
		end)
	end
	data = if ok and type(modul) == "table" then modul else { text = {}, backlog = {} }
	return data
end

--[[ Språkvalet ur en locale-sträng. Samma regel som webbens `sprakFor`. ]]
function Sprak.sprakFor(localeId: string?): string
	local kod = string.lower(tostring(localeId or ""))
	return if string.sub(kod, 1, 2) == "sv" then "sv" else "en"
end

--[[ Spelarens språk. `player.LocaleId` är spelarens EGET val i Roblox och
	finns på både klient och server, vilket är det som gör att servern kan
	svara rätt spelare på rätt språk när den måste. ]]
function Sprak.sprakForSpelare(player: Player?): string
	if player then
		--[[ SPELARENS VAL I SPELET GÅR FÖRE (#264 GAIT_READABILITY_AND_UGNETA).
		     Flaggan i Ugnetas yta skriver attributet genom servern, som bara
		     tar emot "sv" eller "en". Ett attribut på `Player` överlever
		     respawn men inte utloggning, och det är hela beständigheten:
		     ingen DataStore, och Roblox-kontots locale rörs inte. ]]
		local okVal, val = pcall(function() return player:GetAttribute(Sprak.ATTRIBUT) end)
		if okVal and (val == "sv" or val == "en") then return val end
		local ok, locale = pcall(function() return (player :: any).LocaleId end)
		if ok and type(locale) == "string" and locale ~= "" then
			return Sprak.sprakFor(locale)
		end
	end
	return Sprak.sprakFor(Sprak._locale)
end

--[[ Attributet på `Player` som bär spelarens val. Ett namn, ett ställe. ]]
Sprak.ATTRIBUT = "UBRFSprak"

--[[ ── SPELARENS EGET VAL, OCH DE SOM MÅSTE RITA OM (#264) ──────────

	`valt` är spelarens uttryckliga val i spelet och går före allt annat.
	`lyssnare` är ytor som redan visar text: ett byte ska ändra det som
	STÅR på skärmen, inte bara det som byggs härnäst. ]]
local valt: string? = nil
local lyssnare: { [number]: (string) -> () } = {}
local nastaLyssnare = 0

local function meddela()
	local sprak = Sprak.eget()
	--[[ Kopia först: en lyssnare som kopplar ifrån sig själv mitt i
	     varvet ska inte hoppa över grannen. ]]
	local kopia = {}
	for id, fn in pairs(lyssnare) do kopia[id] = fn end
	for _, fn in pairs(kopia) do
		local ok, fel = pcall(fn, sprak)
		if not ok then warn("[Sprak] lyssnare föll: " .. tostring(fel)) end
	end
end

--[[ Klientens eget språk, ur `LocalizationService`. Läses en gång och
	sparas: den ändras inte mitt i en session. ]]
local eget: string? = nil
function Sprak.eget(): string
	if valt then return valt end
	if eget then return eget end
	if Sprak._locale then
		eget = Sprak.sprakFor(Sprak._locale)
		return eget
	end
	local ok, locale = pcall(function()
		return game:GetService("LocalizationService").RobloxLocaleId
	end)
	eget = Sprak.sprakFor(if ok then locale else "sv-se")
	return eget
end

--[[ Provkrok OCH felsökningsknapp: sätter locale rakt. Grinden kör hela
	HUD:en på `sv-se` och `en-us` med den, och utan en sådan väg vore
	kravet oprövbart utanför två olika Roblox-konton. ]]
function Sprak.satLocale(localeId: string?)
	Sprak._locale = localeId
	eget = nil
	meddela()
end

--[[ Spelarens uttryckliga val: "sv", "en" eller nil (tillbaka till
	locale). Allt annat avvisas, så att ingen yta kan hamna i ett tredje
	språk som katalogen inte har. Ytor som lyssnar ritas om direkt. ]]
function Sprak.satVal(sprak: string?): boolean
	if sprak ~= nil and sprak ~= "sv" and sprak ~= "en" then return false end
	if valt == sprak then return true end
	valt = sprak
	meddela()
	return true
end

function Sprak.valt(): string?
	return valt
end

--[[ Prenumeration. Returnerar en funktion som kopplar ifrån — ägaren
	river sin lyssnare, ingen annan. ]]
function Sprak.vidByte(fn: (string) -> ()): () -> ()
	nastaLyssnare += 1
	local id = nastaLyssnare
	lyssnare[id] = fn
	return function() lyssnare[id] = nil end
end

--[[ Provets fönster in: hur många lyssnare som är kopplade. ]]
function Sprak._antalLyssnare(): number
	local n = 0
	for _ in pairs(lyssnare) do n += 1 end
	return n
end

--[[ Slår upp och formaterar. Okänd nyckel returnerar NYCKELN, inte tom
	sträng: ett stavfel ska synas som `hud.gor_i_ordnign` i HUD:en och i
	grinden, inte som ett tomt fält. ]]
function Sprak.iSprak(sprak: string, nyckel: string, ...): string
	local post = tabell().text[nyckel]
	if not post then return nyckel end
	local text = post[sprak] or post.sv or nyckel
	if select("#", ...) > 0 then
		local ok, formaterad = pcall(string.format, text, ...)
		if ok then return formaterad end
	end
	return text
end

--[[ Kortformen klienten använder: spelarens eget språk. ]]
function Sprak.t(nyckel: string, ...): string
	return Sprak.iSprak(Sprak.eget(), nyckel, ...)
end

--[[ Serverns form när den vet vem den talar till. ]]
function Sprak.forSpelare(player: Player?, nyckel: string, ...): string
	return Sprak.iSprak(Sprak.sprakForSpelare(player), nyckel, ...)
end

function Sprak.finns(nyckel: string): boolean
	return tabell().text[nyckel] ~= nil
end

function Sprak.nycklar(): { string }
	local ut = {}
	for nyckel in pairs(tabell().text) do table.insert(ut, nyckel) end
	table.sort(ut)
	return ut
end

--[[ Nycklar som saknar text i ett språk. Grinden kräver noll. ]]
function Sprak.saknade(sprak: string): { string }
	local ut = {}
	for nyckel, post in pairs(tabell().text) do
		local text = post[sprak]
		if type(text) ~= "string" or text == "" then table.insert(ut, nyckel) end
	end
	table.sort(ut)
	return ut
end

function Sprak.backlog(): any
	return tabell().backlog or {}
end

return Sprak
