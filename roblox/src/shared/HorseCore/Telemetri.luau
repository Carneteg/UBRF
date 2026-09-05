--!strict
--[[
	G02-A — RIDNINGENS TELEMETRI OCH TILLSTÅNDSKONTRAKT, Roblox-sidan.

	Motsvarigheten till src/riding/telemetri.js. Samma tre uppgifter, samma
	fältnamn, samma ärlighet om vad som är mätt och vad som är härlett:

	1. LÄSER ut telemetrin G02-B/C behöver ur tillstånd som redan finns i
	   MovementController. Ren avläsning — modulen räknar ingen fysik, rör
	   ingen Instance och kan alltså inte påverka ridkänslan.
	2. Namnger UPPSUTTEN/AVSUTTEN som ett riktigt tillstånd i stället för
	   något som bara framgår av om en Seat råkar vara ockuperad.
	3. Skriver ned gångartsövergångarnas kontrakt, så att ett olagligt hopp
	   går att UPPTÄCKA. Gångarten kommer fortsatt ur Gaits.forSpeed med
	   hysteres — kontraktet dömer, det styr inte.

	VAD SOM SAKNAS PÅ ROBLOX, och varför det står här i stället för att
	fyllas med ett påhittat värde: webbens ridmodell har spänning, mjukhet
	och ett hjälplager med skänkel/tygel/sits. Roblox rörelsekärna har
	ingen motsvarighet ännu — den tar `forward`/`steer`, inte sits och
	tygel. Fälten finns därför i FALT (kontraktet är detsamma) men listas i
	SAKNAS, och `las()` fyller dem inte. Att räkna fram en balanssiffra ur
	`lean` vore att uppfinna en annan modell än webbens och kalla den
	paritet. Det är G02-B:s arbete att ge dem riktiga källor.
]]

local Gaits = require(script.Parent.Gaits)
local RidKanon = require(script.Parent.RidKanon)

local Telemetri = {}

--[[ Kontraktets fältnamn — SAMMA namn som webben, hämtade ur den
     genererade kanonen så att de två inte kan driva isär. ]]
Telemetri.FALT = RidKanon.TELEMETRI_FALT

--[[ Fält som är härledda, inte mätta. Speglar webbens `_harledda`. ]]
Telemetri.HARLEDDA = RidKanon.HARLEDDA

--[[ Fält utan källa på Roblox ännu. Deklarerad lucka, inte en bugg som
     ska tystas: paritetsspecen kräver att listan stämmer exakt, så ett
     nytt hål blir rött och ett igenfyllt hål tvingar fram en ändring här. ]]
--[[ G02-B punkt 1 la till paradKvalitet och paradAlder i kontraktet:
     webben läser nu HUR en halvhalt reds, inte bara att den gavs.
     Roblox har ingen parad alls ännu — ingen kanal, ingen läsning —
     så de två är luckor av exakt samma slag som hjälplagret. ]]
--[[ G02-B punkt 2 gav balans och fokus riktiga källor i webbens modell
     och la till energi, svarstid och svarAlder. På Roblox finns ingen av
     dem: rörelsekärnan har varken hjälplager, spänning eller en väntan
     mellan begäran och svar — en cue startar förloppet i samma bildruta.
     Att räkna fram en balanssiffra ur `lean` vore att uppfinna en annan
     modell och kalla den paritet. ]]
Telemetri.SAKNAS = { "balans", "energi", "fokus", "hjalper", "mjukhet",
	"paradAlder", "paradKvalitet", "spanning", "svarAlder", "svarstid" }

--[[ Lagliga gångartsbyten: grannsteg i ordningen, plus halt från vad som
     helst (en häst kan stanna ur galopp). Ordningen är Roblox egen — den
     har fyrsprånget som webben saknar — men de fyra första stegen är
     desamma, vilket paritetsspecen kontrollerar. ]]
function Telemetri.lagligtByte(fran: string, till: string): boolean
	if fran == till then return true end
	if till == "halt" then return true end
	local i, j = Gaits.index(fran), Gaits.index(till)
	return math.abs(i - j) == 1
end

export type Ritt = {
	uppsutten: boolean,
	hast: string?,
	plats: string?,
	gangart: string,
	glapp: number,
}

function Telemetri.nyRitt(): Ritt
	return { uppsutten = false, hast = nil, plats = nil, gangart = "halt", glapp = 0 }
end

function Telemetri.sittUpp(ritt: Ritt, hastId: string?, plats: string?): Ritt
	ritt.uppsutten = true
	ritt.hast = hastId
	ritt.plats = plats
	ritt.gangart = "halt"
	ritt.glapp = 0
	return ritt
end

function Telemetri.sittAv(ritt: Ritt): Ritt
	ritt.uppsutten = false
	ritt.hast = nil
	ritt.plats = nil
	return ritt
end

--[[ Följ gångarten och räkna glapp. Anropas av den som redan stegar
     ritten; dömer, styr inte. ]]
function Telemetri.foljGangart(ritt: Ritt, gangart: string): string
	if gangart ~= ritt.gangart and not Telemetri.lagligtByte(ritt.gangart, gangart) then
		ritt.glapp += 1
	end
	ritt.gangart = gangart
	return gangart
end

--[[ TELEMETRIN. `loco` är MovementControllerns Locomotion, `kurvatur`
     dess `self.curvature` (1/m, tecknad).

     Notera identiteten: MovementController skriver redan
     `loco.turnRate = curvature * speed`, alltså exakt webbens
     `vridhastighet = kurvatur × tempo`. Den läses ut, den räknas inte om. ]]
function Telemetri.las(ritt: Ritt, loco: { [string]: any }, kurvatur: number): { [string]: any }
	local k = kurvatur or 0
	return {
		uppsutten = ritt.uppsutten,
		hast = ritt.hast,
		gangart = loco.gait,
		gangartGlapp = ritt.glapp,
		fart = loco.speed,
		onskadFart = Gaits.get(loco.targetGait).norm,
		kurvatur = k,
		svangradie = if math.abs(k) > 0.002 then 1 / math.abs(k) else math.huge,
		vridhastighet = loco.turnRate,
		rytm = loco.phase,
		steglangd = Gaits.cycleLength(loco.gait),
		--[[ CUE-FÄLTEN. Roblox hade redan modellen webben nu fått: spelaren
		     väljer gångart, inte tempo (se MovementController:_targetGait —
		     "det är skillnaden mot en gaspedal"). `targetGait` ÄR alltså den
		     beddna gångarten, och fälten har riktiga källor här, inte
		     härledda. ]]
		beddGangart = loco.targetGait,
		cue = loco.cue,
		cueAlder = if loco.cueTid then math.max(0, (loco.tid or 0) - loco.cueTid) else nil,
		overgangstid = loco.senasteOvergang or 0,
		iOvergang = loco.gait ~= loco.targetGait,
	}
end

return Telemetri
