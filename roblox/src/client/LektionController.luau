--!strict
--[[
	LEKTIONEN PÅ KLIENTEN — den kedja som saknades.

	UgnetaController är en HUD och UgnetaGestalt är en figur. Ingen av dem
	kör en lektion. Den här modulen gör det, och den anropas från den
	ENDA uppdateringsloopen i init.client.luau — inte från en egen
	Heartbeat, av samma skäl som står i loopens huvud.

	Vad spelaren får, i den ordningen UX-variant 1 + 3 säger:

	  1. övningen presenteras (rubrik + två punkter, ur kanonen),
	  2. spelaren startar försöket själv,
	  3. hon rider — och får bara några ord live, aldrig ett kort,
	  4. efter försök 1: en sak som var bra, en att förbättra,
	     "Prova igen",
	  5. försök 2 på SAMMA övning, mätt från noll,
	  6. efter försök 2: en konkret jämförelse mot försök 1,
	  7. nästa övning.

	LEKTIONEN VÄNTAR PÅ SPELAREN (senior review av c53a2c7). Förut gick
	den vidare på en sexsekunderstimer, och "Prova igen" var en TextLabel
	utan input: kortet såg ut som ett val men var en nedräkning. Två fel
	föll ut av det. Spelaren kunde inte välja att försöka igen, och
	mätningen av nästa försök började medan ryttaren fortfarande läste
	kortet — timern brydde sig inte om ifall någon var redo.

	Nu finns `lage`, och det är hela rättelsen:

	  "ny"           en övning ska presenteras
	  "presentation" kortet uppe, spelaren väljer när försöket börjar
	  "rider"        DET ENDA läget där något mäts
	  "efter"        återkopplingen uppe, spelaren väljer att gå vidare
	  "ingen"        passet är slut

	Mätningen nollställs vid spelarens handling (`Lektion.vidare` i
	`fortsattning`), inte när timern råkar löpa ut.

	Mätningen kommer ur `ride.telemetri`, alltså ur HorseCore/Telemetri —
	samma avläsning webben gör. Ingen egen fysik, inga egna formler:
	bedömningen ligger i HorseCore/Lektion och HorseCore/Ugneta.

	SÄKERHET VINNER. `avbryt` släcker chip, kort och gestalt på en gång —
	och kastar den väntande fortsättningen, så att ett tangenttryck efter
	avsittningen inte kan starta ett försök på en häst som inte finns.
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

local pass: Lektion.Pass? = nil
local liveCd = 0
local liveSagt = ""
local lage = "ingen"

--[[ SPELARENS HANDLING. Registreras hos HUD:en i `start` och körs när
     knappen, tangenten eller gamepadknappen fyrar — HUD:en har redan
     stängt kortet när vi kommer hit, så det här är bara lifecyclen.

     `Lektion.vidare` ligger HÄR och inte direkt efter `avslutaForsok`:
     det är spelarens val som nollställer mätningen, vilket är precis vad
     provet kan mäta. ]]
local function fortsattning()
	local p = pass
	if not p then return end
	if lage == "presentation" then
		lage = "rider"
	elseif lage == "efter" then
		local forra = p.ix
		Lektion.vidare(p)
		if p.klar then
			lage = "ingen"
		elseif p.ix == forra then
			--[[ SAMMA övning, nytt försök. Spelaren tryckte "Prova igen",
			     och det ÄR valet att börja om — att sedan visa samma
			     presentationskort igen vore ett andra klick för ett beslut
			     som redan är fattat. ]]
			lage = "rider"
		else
			--[[ Ny övning: den ska presenteras innan den rids. ]]
			lage = "ny"
		end
	end
	liveCd, liveSagt = 0, ""
end

--[[ Startar lektionen. `ridhus` är den byggda modellen; utan den finns
     ingen plats att ställa Ugneta på, och då körs lektionen ändå — HUD:en
     är inte beroende av gestalten. En saknad byggnad ska inte tysta
     undervisningen, bara gestalten. ]]
function LektionController.start(ridhus: Instance?)
	pass = Lektion.nyttPass()
	liveCd, liveSagt = 0, ""
	lage = "ny"
	UgnetaController.vidFortsatt(fortsattning)
	UgnetaGestalt.visa(ridhus)
end

function LektionController.pagar(): boolean
	return pass ~= nil and not (pass :: Lektion.Pass).klar
end

function LektionController.pass(): Lektion.Pass?
	return pass
end

function LektionController.lage(): string
	return lage
end

--[[ Väntar lektionen på spelaren just nu? init.client frågar innan den
     tolkar tangenten, så att samma knapp kan betyda något annat när
     inget kort står uppe. ]]
function LektionController.vantar(): boolean
	return pass ~= nil and UgnetaController.vantar()
end

--[[ Spelaren gick vidare, via tangent eller gamepad. Musen och fingret
     går in genom knappens eget Activated. Returnerar false när det inte
     fanns någon väntan — då har tangenten inte betytt något här. ]]
function LektionController.fortsatt(): boolean
	if not pass then return false end
	return UgnetaController.fortsatt()
end

--[[ Presentationen av övningen. Kortet, men INTE mitt under ridningen:
     det visas innan försöket börjar och spelaren stänger det själv
     genom att starta. ]]
local function presentera(p: Lektion.Pass)
	local o = Lektion.ovning(p)
	if not o then return end
	UgnetaController.visa(o.rubrik, o.punkter, true, "Börja")
	lage = "presentation"
end

--[[ ETT STEG. Anropas varje bildruta med ritt-telemetrin. ]]
function LektionController.steg(dt: number, tm: { [string]: any }?)
	local p = pass
	if not p or p.klar then return end
	UgnetaController.steg(dt)

	if lage == "ny" then
		presentera(p)
		return
	end

	--[[ VÄNTAN PÅ SPELAREN. Kortet står kvar, ingenting mäts, tiden växer
	     inte. Det är här den gamla timern satt, och det är därför
	     mätningen kunde börja innan ryttaren var redo. ]]
	if UgnetaController.vantar() then return end
	if lage ~= "rider" then return end

	if not tm or tm.uppsutten ~= true then return end

	p.tid += dt
	--[[ `dt` följer med: täckningen räknas i uppmätta sekunder, inte i
	     bildrutor, så en snabb klient inte får "mer underlag" än en
	     långsam på samma ritt. ]]
	Lektion.matning(p, tm, dt)

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
		lage = "efter"
	else
		--[[ INGET UNDERLAG → INGET OMDÖME, men spelaren får veta varför.
		     `avslutaForsok` ger nil när ingen dimension nådde kraven
		     (ryttaren satt aldrig upp, telemetrin uteblev, fälten var
		     ogiltiga). Att gissa fram ett omdöme hade blivit falskt
		     beröm eller falskt fel om en ritt som aldrig mättes — men att
		     bara tyst gå vidare vore obegripligt: hon såg ett försök ta
		     slut utan ett ord. Kortet säger därför exakt det som är
		     sant, varken mer eller mindre, och väntar på spelaren som
		     alla andra kort. ]]
		UgnetaController.visa("Försöket kunde inte bedömas",
			{ "Det fanns inte tillräckligt mätt underlag den här gången." },
			true, if p.forsokNr < 2 then "Prova igen" else "Nästa övning")
		lage = "efter"
	end
	liveCd, liveSagt = 0, ""
end

--[[ Slut på ritten, av vilket skäl som helst. Säkerhet före undervisning:
     chipet släcks, kortet stängs, den väntande fortsättningen kastas och
     gestalten tas bort. ]]
function LektionController.avbryt()
	pass = nil
	liveCd, liveSagt = 0, ""
	lage = "ingen"
	UgnetaController.vidFortsatt(nil)
	UgnetaController.sakerhetTarOver()
	UgnetaGestalt.dolj()
end

return LektionController
