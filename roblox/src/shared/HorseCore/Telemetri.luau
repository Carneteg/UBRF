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

	G02-B GAV DEM RIKTIGA KÄLLOR. Modulen skrev tidigare att spänning,
	mjukhet och hjälplagret saknades på Roblox — rörelsekärnan tog bara
	`forward`/`steer`. Efter G02-B har den tygel, sits och parad som egna
	axlar, och mjukhet, spänning, fokus, balans och energi räknas med
	webbens formler och webbens tal ur RidKanon. SAKNAS är därför tom.
]]

local Gaits = require(script.Parent.Gaits)
local RidKanon = require(script.Parent.RidKanon)
local Hjalper = require(script.Parent.Hjalper)

local Telemetri = {}

--[[ Kontraktets fältnamn — SAMMA namn som webben, hämtade ur den
     genererade kanonen så att de två inte kan driva isär. ]]
Telemetri.FALT = RidKanon.TELEMETRI_FALT

--[[ Fält som är härledda, inte mätta. Speglar webbens `_harledda`. ]]
Telemetri.HARLEDDA = RidKanon.HARLEDDA

--[[ KONTRAKTET G02-C LÄSER (G02-B punkt 5). `HJALP_FALT` är vad ryttaren
     gör, `SVAR_FALT` vad hästen svarar. Indelningen kommer ur kanonen,
     alltså ur webbens moduler — inte ur en handskriven uppräkning här.
     En läsare som vill veta "vad bad ryttaren om, och vad gjorde hon av
     det" behöver inte gissa vilka fält som är vilka. ]]
Telemetri.HJALP_FALT = RidKanon.HJALP_FALT
Telemetri.SVAR_FALT = RidKanon.SVAR_FALT

--[[ Fält utan källa på Roblox ännu. Deklarerad lucka, inte en bugg som
     ska tystas: paritetsspecen kräver att listan stämmer exakt, så ett
     nytt hål blir rött och ett igenfyllt hål tvingar fram en ändring här. ]]
--[[ G02-B punkt 1 la till paradKvalitet och paradAlder i kontraktet:
     webben läser nu HUR en halvhalt reds, inte bara att den gavs.
     Roblox har ingen parad alls ännu — ingen kanal, ingen läsning —
     så de två är luckor av exakt samma slag som hjälplagret. ]]
--[[ Tomt sedan senior review av #87. Sitsen fick en egen axel, och
     mjukhet, spänning och fokus räknas nu på Roblox med webbens formler
     och webbens tal. Listan står kvar som kontrakt: ett fält utan källa
     ska deklareras här och inte utelämnas tyst. ]]
Telemetri.SAKNAS = {}

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
function Telemetri.las(ritt: Ritt, loco: { [string]: any }, kurvatur: number,
	hjalper: { [string]: any }?): { [string]: any }
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
		--[[ G02-B punkt 2: `beddGangart` är vad ryttaren BAD om,
		     `gangart`/`targetGait` vad hästen svarat på. Under svarstiden
		     skiljer de sig utan att `iOvergang` är sant — hon har hört,
		     men inte börjat. ]]
		beddGangart = loco.beddGangart or loco.targetGait,
		cue = loco.cue,
		cueAlder = if loco.cueTid then math.max(0, (loco.tid or 0) - loco.cueTid) else nil,
		--[[ TRE TIDER, TRE LÅSTA BETYDELSER (senior review #87). Samma
		     kontrakt som webbens: svarstid = begäran → svar,
		     overgangstid = förloppets faktiska längd, etableringstid =
		     begäran → gångarten ÄR den beddna. ]]
		overgangstid = loco.overgangstid or 0,
		etableringstid = loco.etableringstid or 0,
		iOvergang = loco.gait ~= loco.targetGait,
		--[[ ── HÄSTENS SVAR OCH RYTTARENS HJÄLPER (G02-B) ───────────
		     Samma fältnamn och samma tal som webben. `hjalper` kommer ur
		     den delade semantiken i HorseCore.Hjalper, som läser
		     RidKanon.HJALP — inga tal skrivs av här.

		     `sits` och `vikt` saknas i hjälperna av det skäl som står i
		     Hjalper.SAKNAS: Shift och Ctrl är gångartsknappar på Roblox
		     sedan Gate 01, och att flytta dem är en inputändring utanför
		     G02-B. Fälten utelämnas hellre än fylls. ]]
		balans = loco.balans,
		energi = loco.energi,
		--[[ Senior review #87: de tre som stod som luckor har källor nu.
		     `mjukhet` är handens stadga över tid, `spanning` webbens
		     formel med Roblox egna hästdata, `fokus` bygger på de två. ]]
		mjukhet = loco.mjukhet,
		spanning = loco.spanning,
		fokus = loco.fokus,
		svarstid = loco.svarstid or 0,
		svarAlder = if loco.svarTid then math.max(0, (loco.tid or 0) - loco.svarTid) else nil,
		paradKvalitet = loco.paradKvalitet or 0,
		paradAlder = if loco.paradTid then math.max(0, (loco.tid or 0) - loco.paradTid) else nil,
		hjalper = hjalper,
	}
end

return Telemetri
