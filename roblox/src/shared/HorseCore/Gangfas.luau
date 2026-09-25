--!strict
--[[
	GÅNGFASEN — vilket ben som bär när, ur en tabell (#264
	GAIT_READABILITY_AND_UGNETA).

	Benen i `HastGang`, hovslagen i `SoundController` och lättridningen i
	`RiderController` läser ALLA härifrån, och alla med samma fas. Förut
	hade benen en fast fyrtakt oavsett gångart och en egen fasklocka, medan
	ljudet delade en annan fas jämnt i `steps` delar: en trav som såg ut som
	skritt och en galopp med tre lika långa slag.

	Tabellen är inte den här modulens. Den bor i `src/riding/gangfas.js` och
	exporteras till `RidKanon.GANGFAS`; här finns bara uppslaget och
	räkningen. Samma skäl som för resten av ridkanonen: två tabeller glider
	isär i tysthet.

	Fasen är 0..1 inom cykeln. En cykel går från en hovs isättning till
	samma hovs nästa, och `td` är isättningen. Den som behöver räkna slag
	över flera cykler bär ett LÖPANDE tal (cykler + fas) — se `passerade`.
]]

local RidKanon = require(script.Parent.RidKanon)

local Gangfas = {}

export type Ben = { td: number, stod: number }
export type Monster = { takt: number, ben: { [string]: Ben } }

--[[ Benens namn i rigg-ordning: fram vänster/höger, bak vänster/höger. ]]
Gangfas.BEN = { "LF", "RF", "LH", "RH" }

--[[ Vilken rad en rörelse läser. Halt och luft har ingen: då bär alla fyra
	och ingen benföljd ska ritas eller höras. Ryggning har en egen rad så
	att framåtgångens kontaktmodell aldrig används baklänges. Fyrsprånget
	är inte spelbart i den här leveransen; kommer det ändå hit ritas det
	som galopp, inte som något påhittat. ]]
function Gangfas.monsterNamn(gait: string?, lead: string?, ryggar: boolean?): string?
	if ryggar then return "rygga" end
	if gait == "walk" then return "skritt" end
	if gait == "trot" then return "trav" end
	if gait == "canter" or gait == "gallop" then
		return if lead == "left" then "galopp_vanster" else "galopp_hoger"
	end
	return nil
end

function Gangfas.monster(namn: string?): Monster?
	if namn == nil then return nil end
	return (RidKanon :: any).GANGFAS[namn]
end

--[[ Ett bens läge i cykeln: hur långt efter sin isättning det är (0..1),
	och hur stor del av cykeln det bär. `u < stod` betyder stöd. ]]
function Gangfas.ben(m: Monster, ben: string, fas: number): (number, number)
	local b = m.ben[ben]
	if not b then return 0, 1 end
	return (fas - b.td) % 1, b.stod
end

function Gangfas.iStod(m: Monster, ben: string, fas: number): boolean
	local u, stod = Gangfas.ben(m, ben, fas)
	return u < stod
end

--[[ Taktslagen: de SKILDA isättningsfaserna, sorterade. Ett diagonalpar
	är ETT slag, inte två — trav har två slag per cykel, galopp tre, skritt
	fyra. Benen som sätts i samtidigt följer med, så att ljudet kan veta
	vilka hovar som slog. ]]
function Gangfas.slag(m: Monster): { { fas: number, ben: { string } } }
	local per: { [number]: { string } } = {}
	local faser: { number } = {}
	for _, namn in ipairs(Gangfas.BEN) do
		local b = m.ben[namn]
		if b then
			if not per[b.td] then
				per[b.td] = {}
				table.insert(faser, b.td)
			end
			table.insert(per[b.td], namn)
		end
	end
	table.sort(faser)
	local ut = {}
	for _, f in ipairs(faser) do table.insert(ut, { fas = f, ben = per[f] }) end
	return ut
end

--[[ Slagen som PASSERATS mellan två löpande lägen (cykler + fas), i
	ordning. `fran` räknas inte med, `till` gör det — så att ett slag som
	ligger exakt på en bildrutegräns hörs en gång, inte noll eller två
	gånger. Taket skyddar mot en ljudsalva när lägena ligger långt isär;
	en teleport eller ett återinsteg ska seedas om av den som bär läget. ]]
Gangfas.MAX_SLAG = 6
function Gangfas.passerade(m: Monster, fran: number, till: number):
	{ { fas: number, ben: { string }, lage: number } }
	local ut: { { fas: number, ben: { string }, lage: number } } = {}
	if till <= fran then return ut end
	local slag = Gangfas.slag(m)
	local forsta = math.floor(fran)
	local sista = math.floor(till)
	for c = forsta, sista do
		for _, s in ipairs(slag) do
			local t = c + s.fas
			if t > fran and t <= till then
				table.insert(ut, { fas = s.fas, ben = s.ben, lage = t })
				if #ut >= Gangfas.MAX_SLAG then return ut end
			end
		end
	end
	return ut
end

--[[ LÄTTRIDNINGEN: hur högt ryttaren står, 0..1.

	EN uppresning per hel travcykel — det är hela skillnaden mot en ryttare
	som studsar. Hon reser sig medan det YTTRE frambenet förs fram (dess
	svängfas) och sitter ned när det sätts i. Bålens två vertikala impulser
	per cykel är hästens, inte ryttarens, och får inte bli två uppresningar. ]]
function Gangfas.lattridning(m: Monster, fas: number, yttreFram: string): number
	local b = m.ben[yttreFram]
	if not b then return 0 end
	local sving = 1 - b.stod
	if sving <= 0 then return 0 end
	local u = (fas - (b.td + b.stod)) % 1
	if u >= sving then return 0 end
	local s = math.sin(math.pi * u / sving)
	return s
end

--[[ VILKET VARV hon rider: ligger banans mitt till höger eller vänster om
	kursen? Räknat i banans och hästens koordinater, aldrig ur kamerans
	sida. Nära mittlinjen (rakt mot eller från mitten) finns inget svar,
	och då ska den som frågar behålla det senast giltiga. ]]
function Gangfas.varv(pos: Vector3, framat: Vector3, mitt: Vector3): string?
	local cx, cz = mitt.X - pos.X, mitt.Z - pos.Z
	--[[ Högervektorn till en horisontell framåtriktning (f × upp). ]]
	local hx, hz = -framat.Z, framat.X
	local langd = math.sqrt(cx * cx + cz * cz)
	if langd < 1e-3 then return nil end
	local d = (cx * hx + cz * hz) / langd
	if math.abs(d) < 0.25 then return nil end
	return if d > 0 then "right" else "left"
end

--[[ Det yttre frambenet på ett varv. På höger varv ligger mitten till
	höger, och då är VÄNSTER fram det yttre. Okänt varv: nil. ]]
function Gangfas.yttreFram(varv: string?): string?
	if varv == "right" then return "LF" end
	if varv == "left" then return "RF" end
	return nil
end

return Gangfas
