--!strict
--[[
	UGNETAS RIDRAD — vad ridinstruktören säger när ingen lektion pågår
	(#264 GAIT_READABILITY_AND_UGNETA).

	Ugneta är lugn, varm och tydlig. Hon berömmer något som FAKTISKT hänt —
	en etablerad skritt, en lugn övergång — och säger aldrig att allt är
	perfekt. En rättelse är nästa försök, inte ett fel.

	Modulen är ren logik: den läser ett läge och svarar med en NYCKEL och
	dess argument, aldrig med en färdig mening. Ytan slår upp texten när den
	ritas, så ett språkbyte ändrar det som står utan att någonting räknas om
	här. Ingen text finns i den här filen.

	Prioritet (ordern): säkerhet och nej först — det bor i panelen och i
	lektionen, inte här — sedan aktuell instruktion, sedan beröm. Beröm
	skymmer aldrig målet: det står en stund och lämnar sedan plats åt
	instruktionen igen. Lektionen äger rösten medan den pågår; då är den här
	raden tyst.
]]

local UgnetaRad = {}

--[[ Tiderna. Beröm kommer först när gångarten är ETABLERAD, inte när den
	begärs, och högst ett icke-kritiskt tips per `PAUS` sekunder. ]]
UgnetaRad.ETABLERAD = 3.0      -- s i skritt innan «bra skritt»
UgnetaRad.ETABLERAD_KORT = 1.2 -- s i trav/galopp innan raden om sitsen
UgnetaRad.BEROM_TID = 6.0      -- s som ett beröm står
UgnetaRad.PAUS = 8.0           -- s mellan två icke-kritiska tips
UgnetaRad.START_VANTA = 1.5    -- s i halt innan «börja i skritt»

local ORDNING = { halt = 0, walk = 1, trot = 2, canter = 3, gallop = 4 }

export type Lage = {
	gait: string?,
	sedan: number,
	forra: string?,
	nedat: boolean,
	haftRorelse: boolean,
	sagt: { [string]: boolean },
	berom: { nyckel: string, args: { any } }?,
	beromKvar: number,
	sedanTips: number,
}

function UgnetaRad.ny(): Lage
	return {
		gait = nil, sedan = 0, forra = nil, nedat = false, haftRorelse = false,
		sagt = {}, berom = nil, beromKvar = 0, sedanTips = math.huge,
	}
end

--[[ Ett steg. `in`:
	  uppsutten  boolean
	  lektion    boolean — pågår en lektion, är raden tyst
	  gait       den ETABLERADE gångarten
	  driv       reglagets etikett för «högre gångart» på spelarens inmatning
	Svarar med (nyckel, args) för det som ska stå, eller nil. ]]
function UgnetaRad.steg(s: Lage, dt: number, inn: { [string]: any }): (string?, { any }?)
	if not inn.uppsutten then
		--[[ Avsittning, respawn, ny häst: allt gammalt kastas. Fälten
		     skrivs ett och ett — en kopia med `pairs` hoppar över de fält som
		     ska bli nil (gångart, förra gångart, beröm), och då låg förra
		     rittens läge kvar (fångat av klient-ugnetayta.spec). ]]
		s.gait, s.forra, s.berom = nil, nil, nil
		s.sedan, s.nedat, s.haftRorelse = 0, false, false
		s.sagt = {}
		s.beromKvar, s.sedanTips = 0, math.huge
		return nil, nil
	end
	local gait = inn.gait or "halt"
	s.sedanTips += dt
	if gait ~= s.gait then
		local fore = s.gait
		s.forra = fore
		s.nedat = fore ~= nil and (ORDNING[gait] or 0) < (ORDNING[fore] or 0)
		s.gait = gait
		s.sedan = 0
		--[[ Ett byte gör en ny episod: samma beröm får komma igen nästa
		     gång hon skrittar lugnt, men inte två gånger i samma skritt. ]]
		s.sagt = {}
	else
		s.sedan += dt
	end
	if gait ~= "halt" then s.haftRorelse = true end

	if s.beromKvar > 0 then s.beromKvar -= dt end
	if s.beromKvar <= 0 then s.berom = nil end

	if inn.lektion then return nil, nil end

	local function berom(nyckel: string, args: { any }?)
		if s.sagt[nyckel] or s.sedanTips < UgnetaRad.PAUS then return end
		s.sagt[nyckel] = true
		s.berom = { nyckel = nyckel, args = args or {} }
		s.beromKvar = UgnetaRad.BEROM_TID
		s.sedanTips = 0
	end

	--[[ En lugn övergång NEDÅT som hållit — beröm för det som hände. ]]
	if s.nedat and s.sedan >= UgnetaRad.ETABLERAD_KORT then
		berom("ugneta.rad.fin_overgang")
		s.nedat = false
	end
	if gait == "walk" and s.sedan >= UgnetaRad.ETABLERAD then
		berom("ugneta.rad.bra_skritt")
	elseif gait == "trot" and s.sedan >= UgnetaRad.ETABLERAD_KORT then
		berom("ugneta.rad.lattridning")
	elseif (gait == "canter" or gait == "gallop") and s.sedan >= UgnetaRad.ETABLERAD_KORT then
		berom("ugneta.rad.galopp")
	end

	if s.berom then return s.berom.nyckel, s.berom.args end

	--[[ Aktuell instruktion. Står kvar tills läget ändras. ]]
	local driv = inn.driv
	if gait == "halt" and not s.haftRorelse and s.sedan >= UgnetaRad.START_VANTA
		and type(driv) == "string" and driv ~= "" then
		return "ugneta.rad.borja_skritt", { driv }
	end
	if gait == "walk" and s.sagt["ugneta.rad.bra_skritt"] and inn.travTillaten
		and type(driv) == "string" and driv ~= "" then
		return "ugneta.rad.be_om_trav", { driv }
	end
	return nil, nil
end

return UgnetaRad
