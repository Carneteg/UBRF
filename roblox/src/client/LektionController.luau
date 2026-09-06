--!strict
--[[
	LEKTIONEN PÅ KLIENTEN — den kedja som saknades.

	UgnetaController är en HUD och UgnetaGestalt är en figur. Ingen av dem
	kör en lektion. Den här modulen gör det, och den anropas från den
	ENDA uppdateringsloopen i init.client.luau — inte från en egen
	Heartbeat, av samma skäl som står i loopens huvud.

	Vad spelaren får, i den ordningen UX-variant 1 + 3 säger:

	  1. övningen presenteras (rubrik + två punkter, ur kanonen),
	  2. hon rider — och får bara några ord live, aldrig ett kort,
	  3. efter försök 1: en sak som var bra, en att förbättra,
	     "Prova igen",
	  4. försök 2 på SAMMA övning, mätt från noll,
	  5. efter försök 2: en konkret jämförelse mot försök 1,
	  6. nästa övning.

	Mätningen kommer ur `ride.telemetri`, alltså ur HorseCore/Telemetri —
	samma avläsning webben gör. Ingen egen fysik, inga egna formler:
	bedömningen ligger i HorseCore/Lektion och HorseCore/Ugneta.

	SÄKERHET VINNER. `avbryt` släcker chip, kort och gestalt på en gång.
	Den anropas när ritten tar slut av vilket skäl som helst — inklusive
	de skäl som ÄR säkerhetshändelser: karaktären försvinner, riggen är
	borta ur workspace, servern flyttar uppsittningen. En "Bra rytm" får
	aldrig bli kvar på skärmen efter att ekipaget inte finns längre.
]]

local Lektion = require(game:GetService("ReplicatedStorage").HorseCore.Lektion)
local UgnetaController = require(script.Parent.UgnetaController)
local UgnetaGestalt = require(script.Parent.UgnetaGestalt)

local LektionController = {}

local LIVE_CD = require(game:GetService("ReplicatedStorage").HorseCore.RidKanon).UGNETA.LIVE_CD

--[[ Hur länge kortet mellan försöken står kvar innan nästa försök
     börjar. Spelbeslut, inte mätning — därför en siffra här och inte i
     kanonen. ]]
LektionController.PAUS_SEK = 6

local pass: Lektion.Pass? = nil
local liveCd = 0
local liveSagt = ""
local paus = 0
local presenterad = false

--[[ Startar lektionen. `ridhus` är den byggda modellen; utan den finns
     ingen plats att ställa Ugneta på, och då körs lektionen ändå — HUD:en
     är inte beroende av gestalten. En saknad byggnad ska inte tysta
     undervisningen, bara gestalten. ]]
function LektionController.start(ridhus: Instance?)
	pass = Lektion.nyttPass()
	liveCd, liveSagt, paus, presenterad = 0, "", 0, false
	UgnetaGestalt.visa(ridhus)
end

function LektionController.pagar(): boolean
	return pass ~= nil and not (pass :: Lektion.Pass).klar
end

function LektionController.pass(): Lektion.Pass?
	return pass
end

--[[ Presentationen av övningen. Kortet, men INTE mitt under ridningen:
     det visas innan försöket börjar och stängs när hon rider. ]]
local function presentera(p: Lektion.Pass)
	local o = Lektion.ovning(p)
	if not o then return end
	UgnetaController.visa(o.rubrik, o.punkter, false)
	presenterad = true
	paus = LektionController.PAUS_SEK
end

--[[ ETT STEG. Anropas varje bildruta med ritt-telemetrin. ]]
function LektionController.steg(dt: number, tm: { [string]: any }?)
	local p = pass
	if not p or p.klar then return end
	UgnetaController.steg(dt)

	if not presenterad then
		presentera(p)
		return
	end

	--[[ Pausen mellan försöken: kortet står kvar, ingenting mäts, och
	     live-chipet är släckt. Det är här pedagogiken sitter. ]]
	if paus > 0 then
		paus -= dt
		if paus <= 0 then
			UgnetaController.dolj()
			liveCd, liveSagt = 0, ""
		end
		return
	end

	if not tm or tm.uppsutten ~= true then return end

	p.tid += dt
	Lektion.matning(p, tm)

	--[[ LIVE: några ord, och aldrig samma ord två gånger i rad. ]]
	liveCd -= dt
	if liveCd <= 0 then
		local txt, bra = Lektion.liveCue(p, Lektion.kvalitet(tm))
		if txt ~= "" and txt ~= liveSagt then
			liveCd = if bra then LIVE_CD.bra else LIVE_CD.fel
			liveSagt = txt
			UgnetaController.live(txt, bra)
		end
	end

	if p.tid < Lektion.FORSOK_SEK then return end

	--[[ FÖRSÖKET ÄR SLUT. Betyget hör till underlaget, inte till
	     lifecyclen: `avslutaForsok` lämnar medelvärdena och Ugneta
	     rangordnar dem. ]]
	local h = Lektion.avslutaForsok(p)
	if h then
		UgnetaController.efterForsok(h.ovningId, h.nu, h.fore, h.forsokNr)
		paus = LektionController.PAUS_SEK
	end
	Lektion.vidare(p)
	presenterad = false
	liveCd, liveSagt = 0, ""
	if h then presenterad = true end       -- kortet visas redan
end

--[[ Slut på ritten, av vilket skäl som helst. Säkerhet före undervisning:
     chipet släcks, kortet stängs och gestalten tas bort. ]]
function LektionController.avbryt()
	pass = nil
	liveCd, liveSagt, paus, presenterad = 0, "", 0, false
	UgnetaController.sakerhetTarOver()
	UgnetaGestalt.dolj()
end

return LektionController
