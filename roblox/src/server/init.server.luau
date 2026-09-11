--!strict
--[[
	Serverns start. Håll den tom på logik — den ska bara starta tjänsterna
	i rätt ordning, så att det syns var något går fel.
]]

local SparService = require(script.SparService)
local HorseService = require(script.HorseService)
local StallService = require(script.StallService)
local GameplayService = require(script.GameplayService)
local DorrService = require(script.DorrService)
local LedService = require(script.LedService)
local HastRigg = require(script.HastRigg)
local Preflight = require(script.Preflight)

--[[ Ordningen är ett beroende, inte en smaksak: GameplayService registrerar
     sin uppsittningsgrind i HorseService och läser tilldelad HorseId ur
     StallService, så båda måste vara igång först.

     SparService ligger FÖRST sedan #161, och det är också ett beroende:
     StallService.tilldela frågar efter spelarens hästminnen för att inte
     dela ut en häst som vilar för en skada, och GameplayService läser
     passnumret för att veta om det är första dagen.

     MEN ORDNINGEN HÄR ÄR INTE EN BARRIÄR, och sedan #162 blockerare 1
     låtsas den inte vara det. Den bestämmer bara i vilken ordning
     anslutningarna görs. `SparService.ladda` yieldar i sitt `GetAsync`,
     och Roblox kör varje `PlayerAdded`-anslutning på egen tråd — så en
     tjänst som kopplade signalen själv startade mitt i läsningen, hur
     sent den än startades.

     Därför finns nu exakt EN `PlayerAdded`-lyssnare i servern, i
     SparService, och StallService/GameplayService hänger på
     `SparService.efterLaddning`. Startordningen nedan avgör i vilken
     ordning de hookarna körs, och det beroendet gäller fortfarande. ]]
--[[ ══ VÄRLDEN FÖRST ═══════════════════════════════════════════════════

	Blockerare i #162: Roblox-sidan hade två halvor som aldrig möttes. Det
	inklistrade Studio-paketet byggde anläggningen men innehöll ingen rad ur
	`roblox/src/`; Rojo-projektet mappade gameplay men INTE `Anlaggningen`,
	så en fullständig synk byggde ingen anläggning alls. Det fanns alltså
	ingen väg som gav värld och gameplay i samma place — och därför testade
	Tobias miljö + QA-panel i tron att det var First Playable.

	Här möts de. Världen byggs innan tjänsterna startar, av samma
	`Anlaggningen.luau` som paketet använder, och den ordningen är ett
	beroende: `StallService` sätter sin boxmarkör i den byggda modellen och
	`DorrService` letar dörrblad i den. Utan värld först får båda ingenting
	att arbeta på, och det ska då SYNAS i outputen. ]]
--[[ INGEN SPAWN FÖRE VÄRLDEN.

	Andra halvan av att Tobias föll: även med spawnen på rätt plats hinner
	Studio i Play-läge ladda karaktären innan servern byggt anläggningen —
	bygget är 3300 delar. Finns ingen `SpawnLocation` ännu spawnar Roblox på
	sitt standardläge, och står det inget där faller man.

	`CharacterAutoLoads = false` håller karaktären tillbaka tills världen
	står. Den som redan anslutit laddas sedan för hand. ]]
local Players = game:GetService("Players")
Players.CharacterAutoLoads = false

local function slappInSpelare()
	Players.CharacterAutoLoads = true
	for _, p in ipairs(Players:GetPlayers()) do
		if not p.Character then
			local ok, fel = pcall(function() p:LoadCharacter() end)
			if not ok then warn("[Horse] Kunde inte ladda karaktär: " .. tostring(fel)) end
		end
	end
end

local function byggVarlden(): boolean
	local sss = game:GetService("ServerScriptService")
	local varld = sss:FindFirstChild("Varld")
	local byggare = varld and varld:FindFirstChild("Anlaggningen")
	if not byggare then
		warn("[Horse] ServerScriptService.Varld.Anlaggningen saknas — "
			.. "ingen anläggning byggs. Det här är INTE en First Playable-build.")
		return false
	end
	--[[ Modulen bygger för sin verkan när den requiras. ]]
	require(byggare)
	return true
end

--[[ Varje fas i egen pcall.

	Andra halvan av den frusna himlen: `require(byggare)` kastade EFTER att
	världen byggts, skriptet dog på nästa rad, och därmed startade ingen
	tjänst, ingen dörr fick interaktion och `CharacterAutoLoads` stod kvar
	på false. Resultatet var en spelare utan kropp och utan ledtråd.

	En trasig start ska säga vad som gick fel och ändå släppa in spelaren,
	så att läget går att titta på. Att STOPPA hör till preflighten, som
	skriver FAIL — inte till en frusen skärm som inte säger något. ]]
local function fas(namn: string, f: () -> ()): boolean
	local ok, fel = pcall(f)
	if not ok then
		warn(("[Horse] %s föll: %s"):format(namn, tostring(fel)))
	end
	return ok
end

local varldenFinns = false
local kritisktFel: { string } = {}
local function kritisk(namn: string, f: () -> ())
	if not fas(namn, f) then table.insert(kritisktFel, namn) end
end

kritisk("världsbygget", function()
	varldenFinns = byggVarlden()
	if not varldenFinns then error("anläggningen byggdes inte") end
end)

--[[ Hästen FÖRE HorseService. Tjänsten registrerar `GetTagged("Horse")`
	vid start; en rigg som taggas efteråt fångas visserligen av
	`GetInstanceAddedSignal`, men att förlita sig på det gör startordningen
	till en tävling. Bygg först, registrera sedan.

	P0 i #162: det fanns ingen hästmodell alls i placen. Spelaren tilldelades
	blackrock_jack i datan och `bind()` fick aldrig en modell. ]]
kritisk("Jack-riggen", function()
	if HastRigg.start() == nil then error("hästen byggdes inte") end
end)

kritisk("SparService", SparService.start)
kritisk("HorseService", HorseService.start)
kritisk("StallService", StallService.start)
kritisk("GameplayService", GameplayService.start)
kritisk("DorrService", DorrService.start)
kritisk("LedService", LedService.start)

--[[ ══ CRITICAL_STARTUP_GATE ═════════════════════════════════════════════

	Preflighten körs FÖRE spelaren släpps in, och utfallet avgör om hon
	släpps in alls.

	Förra varianten körde `slappInSpelare()` alltid, före preflighten, med
	argumentet att en frusen skärm inte säger något. ChatGPT:s review 16:40
	invände, och invändningen är bättre än mitt argument: att släppa in
	någon i en värld som saknar kritiska tjänster är precis den felklass vi
	redan träffat fysiskt två gånger. En spelare som står i en halvbyggd
	värld och undrar varför inget händer är sämre än ingen spelare alls med
	ett tydligt STOPP i Output.

	Fail closed: vid kritiskt fel laddas ingen karaktär.
	`CharacterAutoLoads` förblir false, och Output säger vad som saknas. ]]
local preflightOk = false
fas("preflight", function()
	local ok = Preflight.kor(varldenFinns)
	preflightOk = ok == true
end)

if #kritisktFel > 0 or not preflightOk then
	warn(("[Horse] CRITICAL_STARTUP_GATE: FAIL — %s")
		:format(if #kritisktFel > 0 then table.concat(kritisktFel, ", ")
			else "preflighten föll"))
	warn("[Horse] INGEN SPELARE SLÄPPS IN. CharacterAutoLoads förblir false. "
		.. "Det här är inte en spelbar build; rapportera raderna ovan i stället "
		.. "för att fortsätta.")
else
	slappInSpelare()
	print("[Horse] CRITICAL_STARTUP_GATE: PASS — servern igång")
end
