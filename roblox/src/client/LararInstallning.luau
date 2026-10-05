--!strict
--[[ UGNETAS TEXTINSTÄLLNINGAR — docs/INSTRUCTOR-TEXT-CONTROLS-CONTRACT.md.

	Två val, spelarens egna, i klientens minne för den här sessionen:
	  · `kommentarer`: "normal" | "farre" | "inga" — de VALFRIA live-
	    kommentarerna (chipet). Obligatorisk text rörs aldrig.
	  · `detalj`: "detaljerad" | "kort" — texten när en övning är slut.

	Standard är dagens beteende (normal, detaljerad). Ingen DataStore, inget
	attribut, inget serveranrop: överlever GUI-ombygge, respawn och byte av
	lektion eller häst, men inte en ny inloggning. Inget resultat och ingen
	försöksidentitet sparas här — bara de två valen. ]]
local L = {}

local KOMMENTARER = { normal = true, farre = true, inga = true }
local DETALJ = { detaljerad = true, kort = true }

local kommentarer = "normal"
local detalj = "detaljerad"
local lyssnare: { [number]: () -> () } = {}
local nasta = 0

function L.kommentarer(): string return kommentarer end
function L.detalj(): string return detalj end

local function meddela()
	local kopia = {}
	for _, fn in pairs(lyssnare) do table.insert(kopia, fn) end
	for _, fn in kopia do fn() end
end

--[[ Returnerar true om valet ändrades. Ett okänt värde avvisas. ]]
function L.satKommentarer(v: string): boolean
	if not KOMMENTARER[v] or v == kommentarer then return false end
	kommentarer = v
	meddela()
	return true
end

function L.satDetalj(v: string): boolean
	if not DETALJ[v] or v == detalj then return false end
	detalj = v
	meddela()
	return true
end

--[[ En prenumeration; svaret är dess frånkoppling. ]]
function L.vidByte(fn: () -> ()): () -> ()
	nasta += 1
	local id = nasta
	lyssnare[id] = fn
	return function() lyssnare[id] = nil end
end

function L._antalLyssnare(): number
	local n = 0
	for _ in pairs(lyssnare) do n += 1 end
	return n
end

--[[ Provkrok: tillbaka till standard utan att meddela. ]]
function L._aterstallForProv()
	kommentarer, detalj = "normal", "detaljerad"
end

return L
