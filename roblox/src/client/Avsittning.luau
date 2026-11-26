--!strict
--[[
	AVSITTNING BARA FRÅN HALT (Batch 0.11, E2).

	Man sitter av en häst som står. Det är ridskolans regel och den är inte
	förhandlingsbar: att kliva av i trav eller galopp är hur ryttare skadar
	sig, och spelet ska inte lära ut det för att spara tre sekunder.

	REGELN, samma som webbens src/riding/avsittning.js — tre funktioner,
	samma namn, samma svar:

	  · Står hästen — gångarten är halt och farten är under STILLA — sker
	    avsittningen DIREKT, som förut.
	  · Rör hon sig BER knappen om halt: stallet tar ner henne genom
	    ridtrappans egna BROMS-steg, en rad säger vad som händer, och
	    avsittningen sker när hon står.
	  · Efter NODUTGANG sekunder sitter spelaren av ändå. Ingen ska bli
	    fast i sadeln.

	Modulen är REN: den läser gångart och fart och svarar med ett ord. Den
	bromsar ingenting och river ingen ritt — det gör `init.client`. Därför
	går regeln att mäta utan en enda Instance.

	Ett andra tryck medan hon bromsar startar INTE om klockan och sitter
	inte av i förtid: nödutgången räknas från den första begäran.

	TALEN bor i `Config.AVSITTNING` och ska vara identiska med webbens
	`RID_KANON.AVSITTNING` (exporterad som `RidKanon.AVSITTNING`); det
	mäts av `klient-sittav-halt.spec`.

	SERVERN ÄR ORÖRD. `HorseService.dismount` måste kunna sätta av en
	ryttare vid frånkoppling och städning oavsett fart, och gör det
	fortfarande. Regeln här är vad SPELARENS knapp gör.
]]

local Config = require(game:GetService("ReplicatedStorage").HorseCore.Config)

local Avsittning = {}

Avsittning.STILLA = Config.AVSITTNING.Stilla
Avsittning.NODUTGANG = Config.AVSITTNING.Nodutgang

export type Lage = { vantar: boolean, tid: number }

function Avsittning.ny(): Lage
	return { vantar = false, tid = 0 }
end

--[[ `speed` är m/s och negativ när hon ryggar — en häst som ryggar står
     inte, fast gångarten läser "halt". ]]
function Avsittning.star(gait: string?, speed: number?): boolean
	return gait == "halt" and math.abs(speed or 0) <= Avsittning.STILLA
end

--[[ Spelaren tryckte. "nu" = sitt av i den här bildrutan; "vantar" =
     hästen ska först till halt. ]]
function Avsittning.begar(a: Lage, gait: string?, speed: number?): string
	if Avsittning.star(gait, speed) then
		a.vantar, a.tid = false, 0
		return "nu"
	end
	if not a.vantar then
		a.vantar, a.tid = true, 0
	end
	return "vantar"
end

--[[ En bildruta. nil = ingen begäran; "bromsa" = håll nedtagningen igång;
     "sitt_av" = hon står, eller nödutgången har löst ut. ]]
function Avsittning.steg(a: Lage, gait: string?, speed: number?, dt: number): string?
	if not a.vantar then return nil end
	a.tid += dt
	if Avsittning.star(gait, speed) or a.tid >= Avsittning.NODUTGANG then
		a.vantar, a.tid = false, 0
		return "sitt_av"
	end
	return "bromsa"
end

return Avsittning
