--!strict
--[[ DRESSYRBOKSTÄVERNA — EN uppslagsväg (#289).

	Bokstävernas id och läge finns på ETT ställe: `UBRFKomplex.ridhus.
	dressyrBokstaver`, som `tools/exportera-geometri.js` genererar ur
	`DRESSYRBOKSTAVER` i `src/data.js`. Den här modulen LÄSER den listan;
	den äger ingen egen position och ingen egen bokstavslista. Det är
	därför "K" betyder västra långsidans skylt överallt, och en lektion
	kan inte längre döpa något annat till K.

	Fyra svar, alla ur listan:
	  · `finns(id)`      är id:t en dressyrbokstav?
	  · `lage(id)`       bokstavens plats i dressyrlayoutens meter (x, y)
	  · `sarg(id)`       vilken sarg skylten sitter på: "S" "N" "W" "E"
	  · `krav(id)`       som `finns`, men FALLER för ett okänt id

	`fran(lista)` bygger samma uppslagare ur en given lista och vägrar en
	lista med dubblerade, tomma eller felformade poster. `standard()` gör
	det ur den levande exporten, så ett test kan mata in en trasig lista
	och se att den nekas.

	Regeln för vilken sarg en bokstav sitter på är DENSAMMA som
	`byggDressyrBokstaver` i Anlaggningen och webbens `bokstavLage`:
	`paSarg` först, sedan x == 0 (väst), x == bredden (öst), y == 0 (syd),
	annars norr. ]]
local Dressyrbokstaver = {}

export type Post = { b: string, x: number, y: number, paSarg: string? }

local function sargFor(post: Post, bredd: number): string
	if post.paSarg == "N" or post.paSarg == "S" then return post.paSarg :: string end
	if post.x == 0 then return "W" end
	if post.x == bredd then return "E" end
	if post.y == 0 then return "S" end
	return "N"
end

function Dressyrbokstaver.fran(lista: any, bredd: number): (any, string?)
	if type(lista) ~= "table" or #lista == 0 then return nil, "ingen_lista" end
	if type(bredd) ~= "number" then return nil, "ingen_bredd" end
	local poster: { [string]: Post } = {}
	for _, p in ipairs(lista) do
		if type(p) ~= "table" or type(p.b) ~= "string" or p.b == "" then return nil, "felformad_post" end
		if type(p.x) ~= "number" or type(p.y) ~= "number" then return nil, "saknar_lage:" .. p.b end
		if poster[p.b] ~= nil then return nil, "dubblett:" .. p.b end
		poster[p.b] = p :: Post
	end
	local r = {}
	function r.finns(id: any): boolean
		return type(id) == "string" and poster[id] ~= nil
	end
	function r.lage(id: any): (number?, number?)
		local p = if type(id) == "string" then poster[id] else nil
		if p == nil then return nil, nil end
		return p.x, p.y
	end
	function r.sarg(id: any): string?
		local p = if type(id) == "string" then poster[id] else nil
		if p == nil then return nil end
		return sargFor(p, bredd)
	end
	function r.krav(id: any): string
		if not r.finns(id) then error("okand_dressyrbokstav:" .. tostring(id), 2) end
		return id :: string
	end
	function r.alla(): { string }
		local ut = {}
		for _, p in ipairs(lista) do table.insert(ut, p.b) end
		return ut
	end
	return r, nil
end

local cache: any = nil

--[[ Uppslagaren ur den LEVANDE exporten. Fallerar högt om exporten saknas
	eller är trasig — ett tyst "inga bokstäver" hade fått varje lektion att
	se giltig ut. ]]
function Dressyrbokstaver.standard(): any
	if cache ~= nil then return cache end
	local RS = game:GetService("ReplicatedStorage")
	local G = (require(RS.UBRFKomplex) :: any)
	local R = G.ridhus
	local r, fel = Dressyrbokstaver.fran(R and R.dressyrBokstaver, R and R.dressyr and R.dressyr.w)
	assert(r, "dressyrBokstaver ur UBRFKomplex ar trasig: " .. tostring(fel))
	cache = r
	return r
end

function Dressyrbokstaver.finns(id: any): boolean return Dressyrbokstaver.standard().finns(id) end
function Dressyrbokstaver.lage(id: any): (number?, number?) return Dressyrbokstaver.standard().lage(id) end
function Dressyrbokstaver.sarg(id: any): string? return Dressyrbokstaver.standard().sarg(id) end
function Dressyrbokstaver.krav(id: any): string return Dressyrbokstaver.standard().krav(id) end

return Dressyrbokstaver
