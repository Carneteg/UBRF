--!strict
--[[ TÄVLINGSKLÄDER — DEN SERVERÄGDA LIVSCYKELN (#248 Fas B).

	Fas A gav katalogen: tre set, sex katalogposter, ett ord in. Den här
	filen är det som tar emot ordet och klär en avatar — och som tar av
	kläderna igen, exakt, vad som än händer under tiden.

	Tjänsten äger per-player-sessionen och ingenting annat. Den startar
	ingen tävling, ritar ingen UI, äger ingen RemoteEvent och kopplas
	inte in i `init.server.luau`. Den är GRÄNSEN som en framtida,
	serverägd tävlingskontext anropar:

	    local tjanst = TavlingskladerService.nya()
	    tjanst.starta(player, "white")
	    tjanst.avsluta(player, "tavling_slut")

	Att den inte startas vid boot är ett beslut, inte en glömska: en
	tjänst som lyssnar på spelarnas livscykel utan att någon bett om ett
	set är ett låtsat tävlingsläge, och ordern förbjuder just det.
	Vakterna binds när en session FAKTISKT börjar och rivs när den slutar.

	══ SÄKERHETSORDNINGEN ════════════════════════════════════════════

	Regeln som hela filen är byggd kring:

	    VERIFIERA BÅDA POSTERNA. SEDAN SKRIV BÅDA LAGREN.
	    FALLER NÅGOT — LÄGG TILLBAKA ALLT.

	Det är i den ordningen för att spelaren aldrig ska stå halvklädd.
	Att verifiera tröjan, skriva den, och sedan upptäcka att byxan är
	borttagen ur katalogen ger en ryttare i tävlingströja och egna byxor
	— och en sådan avatar går inte att skilja från ett medvetet val.

	FAIL CLOSED genomgående: uppslag som inte svarar, svarar fel typ,
	svarar utan typ eller kastar ger NEJ och en orörd avatar. Ett `ja`
	som bygger på tystnad är värre än ett nej.

	Två fönster är särskilt lätta att missa, och båda är stängda här.
	Det första är spelaren som LÄMNAR medan uppslaget yieldar: vakten
	för det binds före första yield, inte när sessionen föds, för innan
	dess finns ingen session att binda den till. Det andra är snapshotet
	av spelarens egna kläder, som måste kunna MISSLYCKAS — ett snapshot
	som gissar "fanns inte" eller "var tomt" när lagret inte gick att
	läsa tar ifrån henne ett plagg vid avslut.

	══ ÄGARSKAPETS GRÄNS ═════════════════════════════════════════════

	Bara klassiska `Shirt` och `Pants`. Hår, ansikte, kropp, hudton,
	hjälm och accessoarer är uttryckligen INTE tjänstens. Den läser dem
	inte, sparar dem inte och rör dem inte.

	══ ADAPTRARNA, OCH VAD DE FAKTISKT ÄR FÖR ════════════════════════

	Två små injicerbara adaptrar: en som frågar Roblox vad en katalogpost
	är, och en som läser och skriver lagren på en avatar. De finns för
	att felvägarna ska gå att FÄLLA i en Luau-bänk — ett API-fel, en
	modererad post, en skrivning som vägrar. Utan dem vore fail
	closed-kravet ett påstående i en kommentar.

	Avatarsidans standardadapter är så tunn att bänken kan köra den rakt
	av mot `Instance.new`. Katalogsidans kan den inte: den ringer Roblox.

	[antagande] Att `MarketplaceService:GetProductInfoAsync` svarar med
	`AssetTypeId`, och att en serverskrivning av `ShirtTemplate` slår
	igenom på en spelares avatar, är läst ur Robloxs dokumentation —
	inte mätt härifrån. Det hör till Studio-QA och står som `Not tested`
	i leveransen. `GetProductInfo` utan `Async` är deprecated och används
	därför inte.

	Katalogtjänsten hämtas LAT, inne i adaptern, och det är avsiktligt:
	bänken har ingen stub för den, och den ska inte behöva någon, för
	den vägen går inte att mäta utan nät. En stub där hade sett ut som
	evidens utan att vara det.
]]

local Players = game:GetService("Players")

local Tavlingsklader = require(game:GetService("ReplicatedStorage").HorseCore.Tavlingsklader)

local TavlingskladerService = {}

--[[ ══ TYPER ════════════════════════════════════════════════════════ ]]

--[[ Svaret på "vad är den här katalogposten?". `ok` falskt betyder att
	frågan inte gick att besvara — nätet, throttling, en borttagen post.
	`assetTypeId` frånvarande på ett `ok`-svar är också ett nej: en post
	som inte vill säga vad den är får inte hamna på en spelare. ]]
export type Uppslag = {
	ok: boolean,
	assetTypeId: number?,
	fel: string?,
}

export type Katalogadapter = {
	assetTyp: (assetId: number) -> Uppslag,
}

--[[ Avataroperationerna, var för sig och utan egen policy. `skrivMall`
	skapar lagret om det saknas — det är Robloxs eget mönster, och det
	är också skälet till att `taBort` finns: ett lager som tjänsten
	SKAPADE måste kunna försvinna igen. ]]
export type Avataradapter = {
	lager: (character: Instance, klass: string) -> Instance?,
	lasMall: (lager: Instance, egenskap: string) -> string,
	skrivMall: (character: Instance, klass: string, egenskap: string, mall: string) -> boolean,
	taBort: (character: Instance, klass: string) -> boolean,
}

export type Adaptrar = {
	katalog: Katalogadapter?,
	avatar: Avataradapter?,
}

type Lagerlage = { fanns: boolean, mall: string }

type Session = {
	setId: string,
	character: Instance,
	--[[ Läget INNAN sessionen började. Sparas EN gång, aldrig om: ett
		andra `starta` som skrev över den hade gjort tävlingskläderna
		till spelarens nya "original", och då får hon aldrig tillbaka
		sina egna. ]]
	ursprung: { [string]: Lagerlage },
	kopplingar: { RBXScriptConnection },
}

--[[ ══ DE TVÅ LAGREN ════════════════════════════════════════════════

	Klass, egenskapsnamn, förväntad `AssetType` och vilket fält i
	katalogposten talet står i — på ETT ställe. AssetType-talen och
	asset-id:na kommer båda ur `Tavlingsklader`; den här filen bär inga
	egna. ]]
local LAGER = {
	{
		klass = "Shirt",
		egenskap = "ShirtTemplate",
		assetType = Tavlingsklader.ASSETTYPE_SHIRT,
		falt = "shirtAssetId",
	},
	{
		klass = "Pants",
		egenskap = "PantsTemplate",
		assetType = Tavlingsklader.ASSETTYPE_PANTS,
		falt = "pantsAssetId",
	},
}

--[[ Robloxs ContentId-form för ett plagg. En funktion och inte en
	formatsträng på sex ställen: formen är en sanning om motorn, och den
	ska stå en gång. ]]
function TavlingskladerService.mall(assetId: number): string
	return ("rbxassetid://%d"):format(assetId)
end

--[[ ══ STANDARDADAPTRARNA ═══════════════════════════════════════════ ]]

local Standardkatalog: Katalogadapter = {
	assetTyp = function(assetId: number): Uppslag
		--[[ Lat hämtning: se filhuvudet. Faller den får uppslaget svara
			nej som vilket annat fel som helst. ]]
		local okTjanst, marketplace = pcall(function()
			return game:GetService("MarketplaceService")
		end)
		if not okTjanst or not marketplace then
			return { ok = false, fel = "MarketplaceService saknas" }
		end
		--[[ `GetProductInfoAsync` KASTAR om posten inte finns. Det är
			dokumenterat beteende, inte en gissning, och därför är pcall
			här inte defensiv slentrian utan den enda korrekta vägen. ]]
		local okSvar, svar = pcall(function()
			return (marketplace :: any):GetProductInfoAsync(assetId, Enum.InfoType.Asset)
		end)
		if not okSvar then
			return { ok = false, fel = tostring(svar) }
		end
		if type(svar) ~= "table" then
			return { ok = false, fel = "oväntat svar" }
		end
		local typ = (svar :: any).AssetTypeId
		if type(typ) ~= "number" then
			--[[ Ett svar utan typ är inget ja. En modererad eller privat
				post kan svara med ett halvt objekt. ]]
			return { ok = false, fel = "svar utan AssetTypeId" }
		end
		return { ok = true, assetTypeId = typ }
	end,
}

local Standardavatar: Avataradapter = {
	lager = function(character: Instance, klass: string): Instance?
		return character:FindFirstChildOfClass(klass)
	end,
	lasMall = function(lager: Instance, egenskap: string): string
		local varde = (lager :: any)[egenskap]
		return if type(varde) == "string" then varde else ""
	end,
	skrivMall = function(character: Instance, klass: string, egenskap: string, mall: string): boolean
		local l = character:FindFirstChildOfClass(klass)
		if not l then
			l = Instance.new(klass)
			;(l :: any).Name = klass
			;(l :: any).Parent = character
		end
		;(l :: any)[egenskap] = mall
		return true
	end,
	taBort = function(character: Instance, klass: string): boolean
		local l = character:FindFirstChildOfClass(klass)
		if l then
			l:Destroy()
		end
		return true
	end,
}

TavlingskladerService.STANDARD = {
	katalog = Standardkatalog,
	avatar = Standardavatar,
}

--[[ ══ TJÄNSTEN ═════════════════════════════════════════════════════

	En fabrik och inte en modulglobal. Två skäl, båda praktiska: en
	provkörning ska inte kunna ärva en annan provkörnings sessioner, och
	en adapterväxling ska inte vara en global omskrivning som vem som
	helst kan göra mitt i en match. ]]
export type Tjanst = {
	starta: (player: Player, katalogId: any) -> (boolean, string),
	avsluta: (player: Player, reason: string?) -> (boolean, string, string),
	aktivt: (player: Player) -> string?,
	aktivaSpelare: () -> { Player },
	kvarvarande: () -> number,
}

function TavlingskladerService.nya(adaptrar: Adaptrar?): Tjanst
	local katalogadapter: Katalogadapter =
		(adaptrar and adaptrar.katalog) or Standardkatalog
	local avataradapter: Avataradapter =
		(adaptrar and adaptrar.avatar) or Standardavatar

	local sessioner: { [Player]: Session } = {}

	--[[ GENERATIONEN. Uppslaget yieldar, och under den pausen kan
		spelaren dö, respawna, logga ut eller bli avslutad av kontexten.
		Tråden som vaknar efteråt bär med sig talet den startade på; har
		det ändrats hör svaret till en session som inte finns längre, och
		då skriver den ingenting.

		Varje `starta` och varje `avsluta` räknar upp. Det gör också två
		överlappande `starta` säkra: den som startade först faller, och
		det sista anropet vinner.

		INVARIANTEN, och den är hela skälet till `pagaende` nedan:

		    ett generationstal finns bara så länge minst ett `starta`
		    ligger och väntar på Roblox för just den spelaren.

		Talets enda uppgift är att ogiltigförklara anrop som är i luften.
		Är inget i luften är det dött viktgods — en stark Player-nyckel i
		en tabell som ingen längre läser, alltså precis den referens
		kontraktet förbjuder. Den låg kvar efter varje nekad start och
		efter varje normalt avslut.

		Att i stället städa "om posten fortfarande är MIN generation"
		räcker inte, och det är värt att skriva ut varför: med A på 1 och
		B på 2 båda i luften skulle B:s utgång nolla talet, ett nytt
		anrop C skulle räkna upp till 1 igen — och A skulle vakna och
		känna igen sitt eget tal. Ett ÅTERANVÄNT tal är ett osett race.
		Räknaren gör återanvändning omöjlig: talet nollas först när noll
		trådar kan läsa det. ]]
	local generation: { [Player]: number } = {}

	--[[ Hur många `starta` som är i luften för en spelare just nu. Noll
		skrivs som `nil`, aldrig som 0: en post kvar med värdet noll vore
		samma läcka en våning ned. ]]
	local pagaende: { [Player]: number } = {}

	local function bumpa(player: Player): number
		local n = (generation[player] or 0) + 1
		generation[player] = n
		return n
	end

	--[[ Städar generationen när — och bara när — ingen tråd kan läsa
		den. Anropas från varje utgång ur `starta` och ur `avsluta`. ]]
	local function stadaGeneration(player: Player)
		if pagaende[player] == nil then
			generation[player] = nil
		end
	end

	--[[ Har världen gått vidare sedan vi började? Två frågor, för de
		fångar olika saker: generationen fångar avslut och konkurrerande
		start, karaktärsjämförelsen fångar en respawn som skedde innan
		någon session — och därmed innan någon vakt — fanns. ]]
	local function inaktuell(player: Player, genFore: number, character: Instance): boolean
		if generation[player] ~= genFore then
			return true
		end
		return player.Character ~= character
	end

	local function sakert(fn: any, ...): boolean
		local ok, svar = pcall(fn, ...)
		return ok and svar ~= false
	end

	--[[ Läser av båda lagren som de ligger just nu. `fanns = false`
		betyder att lagret inte finns — inte att det är tomt. Det är
		den skillnaden återställningen står och faller med.

		FAIL CLOSED, och det är hela skälet till frågetecknet i
		returtypen: ett lager som inte går att läsa ENTYDIGT ger `nil`,
		inte en gissning. Förut sväljdes både ett kast från `lager` och
		ett kast eller ett icke-strängsvar från `lasMall`; gissningen
		blev "lagret fanns inte" respektive "mallen var tom", och båda
		löpte vidare in i avatarskrivningen. Vid avslut tog tjänsten då
		bort ett plagg som faktiskt fanns, eller nollade en mall som
		hade ett värde. Ett snapshot som inte är exakt är inget
		snapshot — det är ett beslut att ändra spelarens avatar i
		tysthet.

		Att lagret SAKNAS är däremot ett fullgott svar. Skillnaden mot
		ett läsfel är precis den här funktionen finns för. ]]
	local function lasLage(character: Instance): { [string]: Lagerlage }?
		local lage: { [string]: Lagerlage } = {}
		for _, l in ipairs(LAGER) do
			local okL, inst = pcall(avataradapter.lager, character, l.klass)
			if not okL then
				return nil
			end
			if inst == nil then
				lage[l.klass] = { fanns = false, mall = "" }
			else
				local okM, mall = pcall(avataradapter.lasMall, inst, l.egenskap)
				if not okM or type(mall) ~= "string" then
					return nil
				end
				lage[l.klass] = { fanns = true, mall = mall }
			end
		end
		return lage
	end

	--[[ Lägger tillbaka exakt det `lasLage` såg. Ett lager som inte
		fanns tas BORT igen; att lämna kvar ett tomt `Shirt` vore att
		ändra avataren i tysthet. ]]
	local function aterstall(character: Instance, lage: { [string]: Lagerlage }): boolean
		local allt = true
		for _, l in ipairs(LAGER) do
			local f = lage[l.klass]
			if f and f.fanns then
				if not sakert(avataradapter.skrivMall, character, l.klass, l.egenskap, f.mall) then
					allt = false
				end
			else
				if not sakert(avataradapter.taBort, character, l.klass) then
					allt = false
				end
			end
		end
		return allt
	end

	local tjanst = {} :: any

	--[[ Vakterna. Binds när en session börjar, rivs när den slutar —
		alla fyra. Att `PlayerRemoving` är en av dem, och inte en
		modulglobal lyssnare som lever för evigt, är samma beslut som att
		tjänsten inte startas vid boot. ]]
	local function bindVakter(player: Player, character: Instance): { RBXScriptConnection }
		local k: { RBXScriptConnection } = {}
		table.insert(k, player.CharacterAdded:Connect(function()
			tjanst.avsluta(player, "respawn")
		end))
		table.insert(k, player.CharacterRemoving:Connect(function()
			tjanst.avsluta(player, "karaktar_borta")
		end))
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			table.insert(k, (humanoid :: any).Died:Connect(function()
				tjanst.avsluta(player, "dod")
			end))
		end
		table.insert(k, Players.PlayerRemoving:Connect(function(lamnade)
			if lamnade == player then
				--[[ Spelaren är borta för gott, och generationen ska bort
					med henne — men `avsluta` städar den redan, och gör det
					med räknaren i handen. En ovillkorlig nollning här hade
					nollat talet mitt under ett pågående uppslag och därmed
					öppnat återanvändningen som invarianten finns för. ]]
				tjanst.avsluta(player, "lamnade")
			end
		end))
		return k
	end

	--[[ ── STARTA ───────────────────────────────────────────────────

		Returnerar `(ok, utfall)`. `utfall` är mekaniskt och menat att
		loggas eller mätas, inte visas: tjänsten äger ingen text som en
		spelare läser. ]]
	function tjanst.starta(player: Player, katalogId: any): (boolean, string)
		if type(player) ~= "table" and typeof(player) ~= "Instance" then
			return false, "ingen_spelare"
		end

		--[[ GRÄNSEN. Katalogen avgör, och den gör det FÖRE allt annat:
			ett asset-id, ett okänt ord eller fel skiftläge ska aldrig
			hinna bli ett nätanrop. ]]
		local set = Tavlingsklader.set(katalogId)
		if not set then
			return false, "ogiltigt_set"
		end

		local character = player.Character
		if not character then
			return false, "ingen_karaktar"
		end

		local befintlig = sessioner[player]
		if befintlig and befintlig.setId == set.id and befintlig.character == character then
			return true, "oforandrad"
		end

		local genFore = bumpa(player)

		--[[ FRÅNKOPPLINGSVAKTEN, bunden FÖRE första yield.

			`bindVakter` binder sina fyra först när en session finns, och
			en session finns inte förrän båda uppslagen är klara. Lämnade
			spelaren mitt i ett uppslag såg alltså ingen det: `inaktuell`
			prövar generationen och `player.Character`, och under
			bortkopplingsfönstret kan båda vara oförändrade. Tråden som
			vaknade efteråt klädde då en spelare som inte fanns kvar,
			registrerade en session åt henne och lämnade fyra vakter
			bundna till en borttagen Player.

			Flaggan är ett UPPVÄRDE i det här anropet, inte en post i en
			tabell: en tjänst som minns frånkopplingar i ett register har
			bytt en läcka mot en annan. ]]
		local lamnad = false
		local frankoppling = Players.PlayerRemoving:Connect(function(lamnade)
			if lamnade == player then
				lamnad = true
			end
		end)

		--[[ Härifrån och till `slut` är det här anropet i luften. ]]
		pagaende[player] = (pagaende[player] or 0) + 1

		--[[ Varje utgång ur `starta` härifrån och ned går genom den här.
			Vakten ovan får inte överleva anropet, och inte heller
			generationstalet: hade starten hunnit bli en session finns en
			sessionsvakt som städar, men en NEKAD start lämnar ingen —
			varken vid `uppslag_nekade`, `fel_assettype`, `lage_olasbart`
			eller `skrivning_foll`. Räknaren ned först, sedan städningen,
			för städaren frågar just räknaren om någon annan tråd
			fortfarande läser talet. ]]
		local function slut(ok: boolean, utfall: string): (boolean, string)
			frankoppling:Disconnect()
			local kvar = (pagaende[player] or 1) - 1
			if kvar > 0 then
				pagaende[player] = kvar
			else
				pagaende[player] = nil
			end
			stadaGeneration(player)
			return ok, utfall
		end

		--[[ Har världen gått vidare på något sätt som gör svaret
			värdelöst? Frånkopplingen prövas först, för den är den enda av
			dem som varken syns i generationen eller i karaktären. ]]
		local function avbrutet(): boolean
			if lamnad then
				return true
			end
			return inaktuell(player, genFore, character)
		end

		--[[ STEG 1: BÅDA posterna verifieras. Inget skrivs här. ]]
		for _, l in ipairs(LAGER) do
			local assetId = (set :: any)[l.falt]
			local okA, svar = pcall(katalogadapter.assetTyp, assetId)
			--[[ Uppslaget kan ha yieldat. Färskheten prövas direkt efter
				varje anrop, innan svaret används till något. ]]
			if avbrutet() then
				return slut(false, "inaktuell")
			end
			if not okA or type(svar) ~= "table" then
				return slut(false, "uppslag_kastade")
			end
			local uppslag = svar :: Uppslag
			if not uppslag.ok then
				return slut(false, "uppslag_nekade")
			end
			if uppslag.assetTypeId ~= l.assetType then
				return slut(false, "fel_assettype")
			end
		end

		--[[ STEG 2: skriv båda. `fore` är läget i just det här ögonblicket
			— rollbackens facit. För en NY session är det också spelarens
			ursprungsläge; för ett setbyte mitt i en session är det bara
			rollbackfacit, och ursprunget står kvar orört i sessionen.

			Går läget inte att läsa entydigt skrivs ingenting alls. En
			rollback mot ett gissat facit är sämre än ett nej: den lämnar
			spelaren i ett läge hon aldrig var i. ]]
		local fore = lasLage(character)
		if not fore then
			return slut(false, "lage_olasbart")
		end

		--[[ Sista prövningen FÖRE första mutationen. Läsadaptern är
			injicerbar och kan yielda, och då är det här — inte uppslagets
			checkpoint — sista stället före en skrivning. ]]
		if avbrutet() then
			return slut(false, "inaktuell")
		end

		for _, l in ipairs(LAGER) do
			local assetId = (set :: any)[l.falt]
			local mall = TavlingskladerService.mall(assetId)
			if not sakert(avataradapter.skrivMall, character, l.klass, l.egenskap, mall) then
				aterstall(character, fore)
				return slut(false, "skrivning_foll")
			end
		end

		--[[ Och en prövning FÖRE sessionsregistreringen. En session åt
			någon som hunnit lämna är precis det fel den här vakten finns
			för, och skrivadaptern är injicerbar på samma sätt som
			läsadaptern.

			Rollbacken hoppas över om registret bytts under oss: då har ett
			`avsluta` redan lagt tillbaka ursprungsläget, och en andra
			återställning hade satt tillbaka det FÖRRA setets
			tävlingskläder i stället för spelarens egna. ]]
		if avbrutet() then
			if sessioner[player] == befintlig then
				aterstall(character, fore)
			end
			return slut(false, "inaktuell")
		end

		if befintlig then
			befintlig.setId = set.id
		else
			sessioner[player] = {
				setId = set.id,
				character = character,
				ursprung = fore,
				kopplingar = bindVakter(player, character),
			}
		end
		return slut(true, "applicerat")
	end

	--[[ ── AVSLUTA ──────────────────────────────────────────────────

		Returnerar `(ok, utfall, orsak)`. `orsak` är anroparens eget ord
		— "tavling_slut", "respawn", "lamnade" — och tjänsten ekar det
		tillbaka i stället för att spara det. Det är HELA vad `reason`
		gör i den här fasen; den styr ingenting, och att låtsas annat
		vore att bygga en kontext som inte är beställd. ]]
	function tjanst.avsluta(player: Player, reason: string?): (boolean, string, string)
		local orsak = if type(reason) == "string" then reason else "avslutad"
		if type(player) ~= "table" and typeof(player) ~= "Instance" then
			return false, "ingen_spelare", orsak
		end

		local session = sessioner[player]

		--[[ Räknas upp OAVSETT om en session fanns: ett `starta` som just
			nu ligger och väntar på Roblox ska falla även om det ännu inte
			hunnit bli en session. ]]
		bumpa(player)

		--[[ Varje utgång härifrån och ned går genom den här. `bumpa` ovan
			har precis lagt ett tal i registret som ingen kommer att läsa
			om inget `starta` är i luften, och då ska det bort igen —
			annars läcker ett vanligt, lyckat avslut en Player-referens.
			Städaren frågar räknaren först, så bumpen står kvar så länge
			en pending start behöver se den. ]]
		local function avslutat(utfall: string): (boolean, string, string)
			stadaGeneration(player)
			return true, utfall, orsak
		end

		if not session then
			return avslutat("ingen_session")
		end

		--[[ Tas ur registret FÖRST. Vakterna kan fyra i varandra — en död
			följs av en respawn — och ett andra varv ska då hitta noll att
			göra i stället för att återställa en gång till. ]]
		sessioner[player] = nil
		for _, k in ipairs(session.kopplingar) do
			k:Disconnect()
		end
		table.clear(session.kopplingar)

		--[[ DEN GAMLA KROPPEN SKRIVS ALDRIG PÅ NÅGON ANNAN. Har spelaren
			fått en ny avatar är den redan klädd av Roblox i hennes egna
			kläder, och tjänsten har ingenting där att göra. ]]
		if player.Character ~= session.character then
			return avslutat("karaktar_borta")
		end

		local helt = aterstall(session.character, session.ursprung)
		return avslutat(if helt then "aterstalld" else "aterstalld_delvis")
	end

	function tjanst.aktivt(player: Player): string?
		local session = sessioner[player]
		return session and session.setId or nil
	end

	function tjanst.aktivaSpelare(): { Player }
		local ut: { Player } = {}
		for player in pairs(sessioner) do
			table.insert(ut, player)
		end
		return ut
	end

	--[[ Ett MÅTT, ingen spelmekanik: hur många spelare tjänsten
		fortfarande håller något om — en session eller ett generationstal.

		Den finns för att "ingen referens lämnas kvar efter en
		frånkoppling" annars bara är ett påstående i en kommentar.
		Sessionerna går att räkna utifrån med `aktivaSpelare`;
		generationsregistret gör det inte, och det var just där den
		läckta referensen låg. Räknaren för pågående starter räknas med
		av samma skäl: den är en tabell med Player-nycklar, och en sådan
		som aldrig töms är samma fel en våning ned. ]]
	function tjanst.kvarvarande(): number
		local sedda: { [Player]: boolean } = {}
		local n = 0
		local function rakna(register)
			for player in pairs(register) do
				if not sedda[player] then
					sedda[player] = true
					n += 1
				end
			end
		end
		rakna(sessioner)
		rakna(generation)
		rakna(pagaende)
		return n
	end

	return tjanst :: Tjanst
end

return TavlingskladerService
