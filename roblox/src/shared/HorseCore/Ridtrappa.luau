--!strict
--[[
	Ridtrappan — ett steg, och EN sanning om vad ett steg är.

	    Rygga ↔ Halt ↔ Skritt ↔ Trav ↔ Galopp

	Trappan fanns redan, men den fanns på TVÅ ställen: `MovementController`
	hade sin `RYGGA = 0` och sin klampning, och `HorseService` hade inget
	alls — servern läste bara vad klienten påstod. Fas 4b flyttar
	auktoriteten till servern, och då måste båda sidor stega i exakt samma
	trappa. Två kopior av en trappa är två trappor.

	MODULEN RÖR INTE `Gaits.ORDER`. Rygga är en pinne UNDER halt och har
	ingen egen gångartsrad — hon ryggar i halt. Att skjuta in den i
	`Gaits.ORDER` hade flyttat varje index med ett, och taket,
	uthålligheten, serverns validering och paritetsprovet läser alla
	`Gaits.index`. Ingen av dem handlar om rygga. Pinnen bor här.

	Modulen är REN: inga Instance-anrop, ingen tid, inget nätverk. Den går
	därför att prova direkt och att köra på båda sidor av tråden.
]]

local Gaits = require(script.Parent.Gaits)

local Ridtrappa = {}

--[[ Pinnen under `Gaits.index("halt")`, som är 1. ]]
Ridtrappa.RYGGA = 0

--[[ De två semantiska handlingarna. Det här är hela det ordförråd
     klienten får skicka över tråden — inte en gångart, inte ett tempo. ]]
Ridtrappa.DRIV = "driv"
Ridtrappa.BROMS = "broms"

function Ridtrappa.arHandling(h: any): boolean
	return h == Ridtrappa.DRIV or h == Ridtrappa.BROMS
end

--[[ Det högsta index trappan får nå.

     TVÅ TAK, och det yttre går inte att förhandla bort: uthålligheten kan
     sänka taket, men ingenting kan höja det över `Gaits.SPELBAR_TOPP`.
     Utan `min()` hade ett felaktigt eller manipulerat `GaitCeiling` öppnat
     fyrsprånget — gångarten webben inte har.

     Ett okänt namn läses som SPELBAR_TOPP och inte som "inget tak": ett
     skräpvärde ska inte kunna stänga ridningen helt heller. ]]
function Ridtrappa.takIndex(tak: any): number
	local namn = if typeof(tak) == "string" and Gaits.BY_NAME[tak]
		then tak else Gaits.SPELBAR_TOPP
	return math.min(Gaits.index(namn), Gaits.index(Gaits.SPELBAR_TOPP))
end

--[[ Ett steg i trappan. Returnerar det nya indexet — OFÖRÄNDRAT om steget
     inte får tas.

     TAKET GÄLLER UPPÅT, ALDRIG NEDÅT. Det är inte en detalj: när
     uthålligheten sjunker faller taket under den gångart hästen redan
     går i, och om taket då också hade klampat nedstegringen kunde en
     trött häst inte bromsas. Nedåt är alltid tillåtet ned till rygga. ]]
function Ridtrappa.steg(index: number, handling: string, tak: any): number
	if handling == Ridtrappa.DRIV then
		local takI = Ridtrappa.takIndex(tak)
		if index >= takI then return index end
		return index + 1
	end
	if handling == Ridtrappa.BROMS then
		if index <= Ridtrappa.RYGGA then return index end
		return index - 1
	end
	return index
end

--[[ Taket har sjunkit — dra ned trappan till det. Används av
     uthålligheten, som sänker taket av sig själv utan att spelaren bett
     om något. Aldrig under rygga. ]]
function Ridtrappa.underTak(index: number, tak: any): number
	return math.max(math.min(index, Ridtrappa.takIndex(tak)), Ridtrappa.RYGGA)
end

--[[ Trappans index ur ett gångartsläge. Ryggningen vinner: hon ryggar
     i halt, så gångarten ensam kan inte skilja de två pinnarna åt. ]]
function Ridtrappa.index(gangart: string?, ryggar: boolean?): number
	if ryggar then return Ridtrappa.RYGGA end
	return Gaits.index(gangart or "halt")
end

--[[ Gångarten ett index betyder. Rygga läser "halt" — allt som läser
     gångarten (animation, ljud, kamera, uthållighet) ska fortsätta göra
     det, och det är ryggningsflaggan som bär den nedersta pinnen. ]]
function Ridtrappa.gangart(index: number): string
	return Gaits.byIndex(math.max(index, 1))
end

function Ridtrappa.ryggar(index: number): boolean
	return index <= Ridtrappa.RYGGA
end

return Ridtrappa
