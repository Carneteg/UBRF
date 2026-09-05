--!strict
--[[
	Gångarterna — en rad per gångart, och allt som skiljer dem åt.

	Tempobanden är portade rakt av från den befintliga ridmodellen. De är
	intrimmade mot hur en häst faktiskt rör sig; ändra dem inte för att en
	animation känns fel, justera animationens hastighet i stället.

	Fyrsprånget är tillagt ovanpå den gamla galoppen genom att dela dess
	övre band. Allt annat i tabellen — acceleration, svarvhet, uthållighet,
	kamera, hovtakt — är nytt och satt för spelkänsla, inte för realism.
]]

local Gaits = {}

--[[ En rad i tabellen. Explicit typad: utan den härleder Luau
     "number | string" ur den blandade tabellen och varje jämförelse
     mot min/max blir ett typfel. ]]
export type Gait = {
	name: string, label: string,
	min: number, max: number, norm: number,
	cycles: number, steps: number,
	accel: number, retard: number, turn: number, svangTau: number, stamina: number,
	camera: { dist: number, height: number, fov: number },
}

Gaits.ORDER = { "halt", "walk", "trot", "canter", "gallop" }

--[[ steps  = hovnedslag per cykel (skritt fyra, trav två, galopp tre)
     accel  = m/s² uppåt   retard = m/s² nedåt
     turn   = andel av grundsvarvheten; hög fart ger vidare sväng
     svangTau = hur TRÖGT kurvaturen följer styrningen (G02-A.1 P3).
                turn säger hur snävt hon KAN svänga, svangTau hur snabbt
                bågen ändras. Skritten rättar sig kvickast, galoppen
                lägger sig i bågen långsammare och känns vidare.
                Samma tal som RID_KANON.SVANGTAU på webben.
     stamina = enheter per sekund, 0 = gratis
     camera = { avstånd, höjd, fov-tillägg } ]]
Gaits.BY_NAME = ({
	halt = {
		name = "halt", label = "Halt", min = 0.00, max = 0.20,
		norm = 0.00, cycles = 0.00, steps = 0,
		accel = 3.2, retard = 5.5, turn = 1.00, svangTau = 1.00, stamina = -3.0,
		camera = { dist = 14, height = 5.0, fov = 0 },
	},
	walk = {
		name = "walk", label = "Skritt", min = 0.90, max = 2.00,
		norm = 1.45, cycles = 0.900621, steps = 4,
		accel = 2.6, retard = 3.4, turn = 1.00, svangTau = 0.85, stamina = 0.0,
		camera = { dist = 15, height = 5.2, fov = 0 },
	},
	trot = {
		name = "trot", label = "Trav", min = 2.40, max = 4.30,
		norm = 3.20, cycles = 1.451247, steps = 2,
		accel = 2.9, retard = 3.6, turn = 0.82, svangTau = 1.00, stamina = 0.4,
		camera = { dist = 17, height = 5.6, fov = 1 },
	},
	canter = {
		name = "canter", label = "Galopp", min = 4.60, max = 8.00,
		norm = 5.60, cycles = 1.6, steps = 3,
		accel = 3.4, retard = 3.2, turn = 0.52, svangTau = 1.45, stamina = 2.2,
		camera = { dist = 19, height = 6.0, fov = 4 },
	},
	gallop = {
		name = "gallop", label = "Fyrsprång", min = 8.20, max = 11.0,
		norm = 8.60, cycles = 2.05, steps = 4,
		accel = 3.0, retard = 2.6, turn = 0.42, svangTau = 1.60, stamina = 5.5,
		camera = { dist = 23, height = 6.4, fov = 8 },
	},
} :: { [string]: Gait })

--[[ Hysteres: hur långt utanför sitt band en gångart får leva kvar.
     Utan den flimrar animationen fram och tillbaka vid varje gräns. ]]
Gaits.HYSTERESIS = 0.35

--[[ Trösklarna som gäller när nuvarande gångart inte längre räcker.
     Medvetet lagda mellan banden, inte på dem. ]]
local THRESHOLDS: { { under: number, gait: string } } = {
	{ under = 0.25, gait = "halt" },
	{ under = 2.20, gait = "walk" },
	{ under = 4.45, gait = "trot" },
	{ under = 7.10, gait = "canter" },
}

function Gaits.get(name: string): Gait
	return Gaits.BY_NAME[name] or Gaits.BY_NAME.halt
end

function Gaits.index(name: string): number
	for i, n in Gaits.ORDER do
		if n == name then return i end
	end
	return 1
end

function Gaits.byIndex(i: number): string
	return Gaits.ORDER[math.clamp(i, 1, #Gaits.ORDER)]
end

--[[ Vilken gångart ett tempo hör till, givet vilken vi är i nu. ]]
function Gaits.forSpeed(speed: number, current: string?): string
	local h = Gaits.HYSTERESIS
	if current then
		local g = Gaits.BY_NAME[current]
		if g and speed >= g.min - h and speed <= g.max + h then
			return current
		end
	end
	for _, row in THRESHOLDS do
		if speed < row.under then
			return row.gait
		end
	end
	return "gallop"
end

--[[ Hur snabbt animationsklippet ska spelas för att hovarna ska landa där
     marken är. Klippet är gjort för gångartens norm-tempo. Klampningen är
     medveten: sträcks ett klipp mer än så ska gångarten byta i stället,
     annars ser hästen ut att åka skridskor. ]]
function Gaits.playbackRate(name: string, speed: number): number
	local g = Gaits.get(name)
	if g.norm <= 0 then return 1 end
	return math.clamp(speed / g.norm, 0.72, 1.32)
end

--[[ Hur långt hästen går på en hel rörelsecykel, i meter.

     Fasen ska följa MARKEN, inte klockan: samma sträcka i samma gångart
     ska ge samma antal hovnedslag oavsett hur tempot råkade variera på
     vägen. Cykellängden räknas ur gångartens hemtempo delat med dess
     cykelfrekvens — det bevarar dagens takt vid normtempo och gör den
     distanslåst över resten av bandet.

     DET FANNS ETT stride-FÄLT HÄR. Det är borta, och skälet bör stå kvar.

     Fältet bar värdena 0,46 / 0,63 / 1,00 / 1,28 och en kommentar som sa att
     animationslagret använde dem som enskild steglängd i meter. Ingen av de två
     uppgifterna var sann. Fältet lästes inte av någon modul, och värdena var
     inte meter.

     Värdena är webbmodellens `steg`-fält i `src/model.js`, och där är de
     DIMENSIONSLÖSA FAKTORER. Webben räknar
     `SPRANG[kategori] × steg × modulering`, med `SPRANG.hast = 3,50 m`.
     Vid porteringen till Luau följde faktorerna med men multiplikatorn
     lämnades kvar. En faktor utan sin bas ser ut som ett mått och är det inte.

     Konsekvensen om någon hade trott på kommentaren: hovavtryck lagda på
     0,63 m i trav mot en verklig cykellängd på 2,13 m är 41 % fel, alltså
     precis den hovglidning som är förbjuden i acceptanskraven för riggen.

     Cykellängden är `Gaits.cycleLength`, och den är det enda bindande måttet.

     HARMONISERAD MOT WEBBEN (PO-beslut 2026-09-05). `cycles` är satt så att
     norm ÷ cycles ger webbens cykellängd, alltså SPRANG("hast") 3,50 gånger
     gångartens stegfaktor: skritt 1,61 m, trav 2,205 m, galopp 3,50 m. Var
     1,45 / 2,133 / 3,20. Det ändrar takten i animationen, och det är just
     vad harmoniseringen innebär — två produktfysiker blir en.
     Webben och Roblox är dock inte överens om den — se `HASTRIGG-KRAVSPEC.md`
     § 4 och issue om plattformsavvikelsen. ]]
function Gaits.cycleLength(name: string): number
	local g = Gaits.get(name)
	if g.cycles <= 0 or g.norm <= 0 then return 0 end
	return g.norm / g.cycles
end

--[[ Hovnedslag per sekund — driver ljud och damm. ]]
function Gaits.beatRate(name: string, speed: number): number
	local g = Gaits.get(name)
	if g.steps == 0 or g.norm <= 0 then return 0 end
	return g.cycles * g.steps * (speed / g.norm)
end

return Gaits
