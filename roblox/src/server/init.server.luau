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

local varldenFinns = byggVarlden()

SparService.start()
HorseService.start()
StallService.start()
GameplayService.start()
DorrService.start()
print("[Horse] Servern igång")

--[[ Preflight SIST: den mäter det färdiga läget, inte avsikten. ]]
Preflight.kor(varldenFinns)
