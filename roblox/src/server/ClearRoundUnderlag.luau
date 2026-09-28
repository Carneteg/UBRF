--!strict
--[[ CLEAR ROUND-UNDERLAGET — B4c, docs/B4C-COURSE-EVIDENCE-CONSUMER-CONTRACT.md.

	En SKUGGBEDÖMNING, aldrig officiell. Den banmedvetna konsumenten av
	HinderObservations neutrala evidens (B4b R1) och nedslagshändelse (B4a):
	den första nivå som får säga vägran, utbrytning, ingen eller okänt — och
	bara för det hinder som SKA hoppas (nästa banhinder), eftersom TR III 2025
	moment 385 dömer mot det. Källa: references/rules/TR-III-2025-hoppning-A-clear-round.md.

	Ren: inga instanser, ingen tid, inget nät. In: banan i ordning
	(`{ id, riktning }`), rittens hinderförsök (ur `HinderObservation.ogonblick`)
	och försöksnumren vid startlinjen. Ut: ett fryst underlag.

	Genomgången är densamma som ClearRoundLektions: stängda försök efter
	startlinjen i `tUt`-ordning; pekaren står på nästa banhinder; en passage i
	banans riktning flyttar den. Försök vid andra hinder dömer den inte.

	`OFFICIELL` är false tills fysiska bommar och kalibrering av trösklarna är
	verifierade och ett nytt beslut finns. Inget här ändrar den officiella
	D2-bedömningen, delar ut en rosett eller sparar något. ]]

local ClearRoundUnderlag = {}

ClearRoundUnderlag.VERSION = 1
ClearRoundUnderlag.OFFICIELL = false

local function frys(t: any): any
	if type(t) ~= "table" then return t end
	local k = {}
	for a, b in pairs(t) do k[a] = frys(b) end
	return table.freeze(k)
end

--[[ Domtabellen ur B4b R1-kontraktet, för ett försök vid NÄSTA banhinder.
	Svarar (dom, grund). ]]
local function dom(f: any, riktning: string): (string, string?)
	if f.evidensGrund == "ofullstandigt" or f.giltighet ~= "fullstandig" then
		return "okand", "ofullstandigt"
	end
	if f.inSida == nil or f.inSida ~= riktning then return "okand", "fel_sida" end
	if f.stoppObserverat == true and f.bakatEfterStopp == true then return "vagran", "stopp_och_bakat" end
	if f.sidanOm == true then return "utbrytning", "sidan_om" end
	if f.utfall == "passage" then
		if f.stoppObserverat == true then return "okand", "stopp_sedan_passage" end
		return "ingen", nil
	end
	return "okand", "ingen_passage"
end

local function nedslagFor(f: any): string
	if f.nedslag == "ja" or f.nedslag == "nej" then return f.nedslag end
	return "okand" -- "vantar" och allt annat: fönstret kan stå öppet, eller bommen kan inte falla
end

function ClearRoundUnderlag.bygg(banHinder: any, forsok: any, nrBas: any): any
	if type(banHinder) ~= "table" or type(forsok) ~= "table" or type(nrBas) ~= "table" then return nil end
	local steg = {}
	for i, b in ipairs(banHinder) do
		steg[i] = { nr = i, hinderId = b.id, passerad = false, nedslag = nil, handelser = {} }
	end
	-- Stängda försök efter startlinjen, i tidsordning.
	local nya = {}
	for _, f in ipairs(forsok) do
		local bas = nrBas[f.hinderId]
		if type(bas) == "number" and type(f.nr) == "number" and f.nr > bas and f.giltighet ~= "pagar" then
			table.insert(nya, f)
		end
	end
	table.sort(nya, function(a, b) return (a.tUt or 0) < (b.tUt or 0) end)
	local pek = 1
	for _, f in ipairs(nya) do
		local mal = banHinder[pek]
		if not mal then break end
		if f.hinderId == mal.id then
			local d, grund = dom(f, mal.riktning)
			table.insert(steg[pek].handelser, { forsokNr = f.nr, dom = d, grund = grund })
			if f.utfall == "passage" and f.riktning == mal.riktning and f.giltighet == "fullstandig" then
				steg[pek].passerad = true
				steg[pek].nedslag = nedslagFor(f)
				pek += 1
			end
		end
	end
	local summa = { olydnader = 0, olydnaderOkanda = 0, nedslag = 0, nedslagOkanda = 0, fullstandigt = true }
	for _, st in ipairs(steg) do
		if not st.passerad then summa.fullstandigt = false end
		if st.nedslag == "ja" then summa.nedslag += 1 end
		if st.nedslag == "okand" then summa.nedslagOkanda += 1; summa.fullstandigt = false end
		for _, h in ipairs(st.handelser) do
			if h.dom == "vagran" or h.dom == "utbrytning" then summa.olydnader += 1 end
			if h.dom == "okand" then summa.olydnaderOkanda += 1; summa.fullstandigt = false end
		end
	end
	return frys({ version = ClearRoundUnderlag.VERSION, officiell = ClearRoundUnderlag.OFFICIELL,
		steg = steg, summa = summa })
end

return ClearRoundUnderlag
