--!strict
--[[ STALLSERVICE — din häst, och skylten vid hennes box.

	Gate G01, första skivan. Före det här mötte en Roblox-spelare en
	hästMODELL: HorseStats stod på "Namnlös" av rasen "Warmblood", medan de
	sjutton riktiga UBRF-hästarna bara fanns i webbversionens JS.

	Tjänsten gör tre saker och inget mer:
	  1. tilldelar spelaren en häst vid ankomsten,
	  2. sätter en ProximityPrompt vid hennes box,
	  3. svarar på frågan "vilken är min häst" över nätet.

	Reglerna ligger i ReplicatedStorage.Stallet, som är ren logik och provas
	i roblox/tests/spel.spec.luau utan Studio. Den här filen är bara
	instanserna. Den uppdelningen finns för att regler ska gå att falsifiera
	härifrån; en ProximityPrompt går inte.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Stallet = require(ReplicatedStorage.Stallet)
local Sparning = require(ReplicatedStorage.HorseCore.Sparning)
local SparService = require(script.Parent.SparService)

local StallService = {}

local M = 3          -- studs per meter, samma som BuildKit.M
local ANLAGGNING = "Anläggning"

local tilldelade: { [Player]: any } = {}
local markorer: { [Player]: Model } = {}

--[[ Anläggningens bas. Byggskriptet lägger allt relativt PrimaryPart, så
	utan den vet vi inte var i världen stallet står. Saknas den är
	anläggningen inte byggd — säg det rakt ut i stället för att lägga en
	skylt i origo och låta någon leta. ]]
local function bas(): CFrame?
	local modell = workspace:FindFirstChild(ANLAGGNING)
	local ubrf = modell and modell:FindFirstChild("UBRF")
	return ubrf and ubrf.PrimaryPart and ubrf.PrimaryPart.CFrame or nil
end

local function taBortMarkor(player: Player)
	local m = markorer[player]
	if m then
		m:Destroy()
		markorer[player] = nil
	end
end

--[[ Skylten vid boxen. Osynlig och genomsläpplig — den är bara en bärare
	för prompten, inte något att gå in i. ]]
local function satMarkor(player: Player, dagens: any): Model?
	local b = bas()
	if not b then
		warn("[Stallet] Anläggningen är inte byggd — ingen boxmarkör satt.")
		return nil
	end

	local modell = Instance.new("Model")
	modell.Name = "Boxmarkor_" .. player.Name

	local del = Instance.new("Part")
	del.Name = "Box"
	del.Anchored = true
	del.CanCollide = false
	del.CanQuery = false
	del.Transparency = 1
	del.Size = Vector3.new(1, 2, 1)
	del.CFrame = b * CFrame.new(dagens.box.varld.x * M, 1 * M, dagens.box.varld.y * M)
	del.Parent = modell

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BoxPrompt"
	prompt.ActionText = "Titta in"
	prompt.ObjectText = dagens.namn .. " står här"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = del

	prompt.Triggered:Connect(function(spelare)
		if spelare ~= player then return end
		--[[ Ingen egen text hittas på: beskrivningen är ordagrann från
			ubrf.se/hastar och foderraden kommer ur samma delade data. ]]
		print(("[Stallet] %s — %s, %s. %s"):format(
			dagens.namn, dagens.ras, dagens.typ, dagens.besk))
		if dagens.foder then
			print(("[Stallet] Foder: %d kg hö, kraftfoder %s. %s"):format(
				dagens.foder.ho, tostring(dagens.foder.kraft), dagens.foder.notis))
		end
	end)

	modell.PrimaryPart = del
	modell.Parent = workspace
	return modell
end

--[[ Vilka identiteter som redan är utdelade till någon som är inne.

	Nyckeln är hästens id, inte spelaren: frågan reservationen ställer är
	"står någon redan i den här boxen", inte "har den här spelaren en häst". ]]
local function upptagnaHastar(utom: Player?): { [string]: boolean }
	local ut = {}
	for player, dagens in pairs(tilldelade) do
		if player ~= utom and dagens and dagens.id then
			ut[dagens.id] = true
		end
	end
	return ut
end

--[[ Spelarens sparade hästminnen, i webbens form: `{ [id] = { skada = … } }`.

	EN ENDA PLATS ATT KOPPLA IN ETT MINNE, och sedan #161 är den inkopplad.
	PR #154 lämnade den som `return nil` med noten *"den dagen ett DataStore
	läggs till är det HÄR det hämtas — inte genom att sprida läsningar ut i
	tilldelningen"*. Den dagen är nu, och noten höll: det blev en rad.

	Formen konverteras inte. `Sparning.hastminnen` returnerar exakt den
	tabell `Stallet.vilandeHastar` redan läser, som i sin tur är webbens
	form i `src/ryttare.js`. En översättning här hade blivit en tredje
	sanning om samma sak.

	Faller läsningen ur datalagret är saven tom och mängden blir tom — och
	det är rätt fail-läge för just den här frågan: en spelare som inte kan
	nå sin sparfil ska kunna rida, inte nekas häst. Skadan går ändå inte
	förlorad, för `SparService` skriver inte över en sparfil den inte kunde
	läsa. ]]
function StallService.hastminnen(player: Player): { [string]: any }?
	local save = SparService.save(player)
	return save and Sparning.hastminnen(save) or nil
end

function StallService.tilldela(player: Player)
	--[[ Reservationen görs HÄR och inte i Stallet: modulen äger regeln, den
		här filen äger vem som faktiskt är inloggad. Skickas ingen upptagen-
		lista får två spelare med UserId som skiljer 33 samma häst. ]]
	--[[ VÄLFÄRDEN GÅR GENOM SAMMA CHOKE POINT som reservationen (#153 fix 1).
		En häst som vilar för en skada ska aldrig kunna tilldelas, och den
		regeln hör hemma här där tilldelningen faktiskt sker — inte spridd
		över anropskedjan, vilket var precis hur webbens spärr gick att
		kringgå på tre ställen.

		MINNET ÄR INKOPPLAT sedan #161: `hastminnen()` läser spelarens
		sparfil ur `SparService`, så spärren utlöses nu i drift och inte
		bara i provet. (Fram till #161 stod här att inget `DataStoreService`
		fanns i `roblox/` och att mängden därför alltid var tom — det är
		inte längre sant, och en kommentar som säger motsatsen om koden är
		värre än ingen kommentar.)

		Att mängden är riktig kräver att saven är LÄST när den här raden
		körs. Det är vad barriären i `SparService.efterLaddning` finns för;
		se `start()` längst ned. ]]
	local vilande = Stallet.vilandeHastar(StallService.hastminnen(player))

	--[[ FÖRSTA DAGEN ÄR JACK (#162 blockerare 3). Regeln låg tidigare bara
		i webbens `scenes.js`; på Roblox valde rotationen fritt, så en ny
		spelare kunde få vilken häst som helst.

		Önskan skickas till samma `dagensHast` som allt annat och passerar
		därmed både reservationen och välfärdsspärren — se `tilldelaLedig`.
		Vilar Jack blir svaret nil och spelaren får vänta; ingen ersättare
		delas ut bakom regelns rygg.

		Saven kan vara en SESSIONSAVE om läsningen föll. Då ser dagen ut som
		en första dag, och det är samma avsiktliga fail-safe som
		`GameplayService.passnummer` redan har: ett datalagerfel ska inte
		hitta på progression. Följden är att en återvändande spelare med
		trasigt datalager får Jack i stället för sin rotationshäst — sämre
		än rätt, bättre än att hennes riktiga pass skrivs över. ]]
	local save = SparService.save(player)
	local onskad = if save ~= nil and Sparning.forstaDagen(save)
		then Stallet.FORSTA_DAGEN_HAST else nil

	local dagens = Stallet.dagensHast(player.UserId, upptagnaHastar(player),
		vilande, onskad)
	if not dagens then
		if onskad then
			warn(("[Stallet] Första dagen skulle ridits på %s, men hon är "
				.. "upptagen eller vilar. %s får vänta."):format(
				tostring(onskad), player.Name))
		else
			warn("[Stallet] Ingen häst kunde tilldelas " .. player.Name
				.. " — hela stallet är upptaget eller vilar. Spelaren får vänta.")
		end
		tilldelade[player] = nil
		taBortMarkor(player)
		return nil
	end
	tilldelade[player] = dagens
	taBortMarkor(player)
	local m = satMarkor(player, dagens)
	if m then markorer[player] = m end

	print(("[Stallet] %s rider %s idag — box %d, rad %s, gång %s."):format(
		player.Name, dagens.namn, dagens.box.nummer, dagens.box.rad, dagens.box.gang))
	return dagens
end

function StallService.hastFor(player: Player)
	return tilldelade[player]
end

--[[ Den kanoniska identiteten, och inget annat. GameplayService binder på
	det här id:t — aldrig på namn, box eller närmaste modell. ]]
function StallService.hastIdFor(player: Player): string?
	local dagens = tilldelade[player]
	return dagens and dagens.id or nil
end

function StallService.start()
	local fraga = Instance.new("RemoteFunction")
	fraga.Name = "MinHast"
	fraga.Parent = ReplicatedStorage
	fraga.OnServerInvoke = function(player)
		--[[ Klienten får FRÅGA, aldrig bestämma. Samma regel som
			uppsittningen redan följer.

			OCH DEN FÅR INTE FRÅGA FÖRBI BARRIÄREN (#162 re-review). Ett
			tidigt anrop hit — klienten är uppe innan läsningen landat —
			gjorde en tilldelning mot `save == nil`, alltså exakt det som
			blockerare 1 stängde på `PlayerAdded`-vägen. Är laddningen inte
			i slutläge finns inget svar att ge ännu.

			`nil` är rätt svar och inte en förlust: hooken i
			`SparService.efterLaddning` tilldelar så fort läsningen landar,
			så nästa fråga får hästen. Att i stället VÄNTA här hade hållit
			en RemoteFunction öppen över ett nätverksanrop. ]]
		if tilldelade[player] then return tilldelade[player] end
		if not SparService.redo(player) then
			return nil
		end
		return StallService.tilldela(player)
	end

	--[[ TILLDELNINGEN HÄNGER PÅ BARRIÄREN, INTE PÅ `PlayerAdded` (#162
		blockerare 1). Kopplade den här filen signalen själv kördes den på
		egen tråd medan `SparService.ladda` fortfarande yieldade i sitt
		`GetAsync` — och då svarade `hastminnen()` nil, välfärdsmängden blev
		tom, och en häst som vilade för en skada kunde tilldelas. Provet
		"ingen häst är tilldelad innan saven laddat" i skotselpass.spec
		mätte upp exakt det.

		`SparService.efterLaddning` körs efter att läsningen returnerat,
		också när den föll — så en spelare utan datalager får fortfarande
		en häst. ]]
	SparService.efterLaddning(function(player)
		StallService.tilldela(player)
	end)
	--[[ HÄR STOD EN `GetPlayers()`-LOOP, och den var ett hål (#162
		re-review). Kommentaren påstod att "deras save är redan läst av
		SparService, så det finns inget fönster här". Det var fel: en
		spelare kan ha anlänt medan SparService läste, och då är hennes
		laddning fortfarande i luften när den här tjänsten startar — loopen
		tilldelade då mot `save == nil` och gick förbi hela barriären.

		Återhämtningen ligger nu i `efterLaddning` självt, som kör hooken
		direkt för alla som redan ÄR redo. Ett ställe, ingen väg runt. ]]
	Players.PlayerRemoving:Connect(function(player)
		taBortMarkor(player)
		tilldelade[player] = nil
	end)

	print("[Stallet] Igång")
end

return StallService
