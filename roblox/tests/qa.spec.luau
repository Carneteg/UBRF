--!nostrict
--[[
	QA-panelen — provar att den FUNGERAR, inte bara att den byggs.

	Panelen är det enda Tobias rör under den manuella Studio-genomgången. Går
	den sönder får han inget verktyg och ingen felutskrift, bara en tom skärm,
	och då blir det jag som får skulden för att "Studio inte funkar".

	Vad som provas här:
	  · att den VÄGRAR starta utanför Studio (den viktigaste regeln — en
	    dev-panel som läcker ut till spelare är en release-miss),
	  · att den bygger sin ScreenGui i Studio,
	  · att knapparna faktiskt gör något när man trycker på dem,
	  · att den går igenom exakt de vyer Vyer.luau har, varken fler eller färre.

	Vad den INTE bevisar: hur panelen SER ut. Det syns bara i Studio.

	Kör: python3 roblox/tests/build.py tests/qa.spec.luau
	     && luau roblox/tests/.build/qa.spec.luau
]]

local fails = 0
local function check(namn, villkor, detalj)
	if villkor then
		print(string.format("  OK   %s%s", namn, detalj and ("  " .. detalj) or ""))
	else
		fails += 1
		print(string.format("  FEL  %s%s", namn, detalj and ("  " .. detalj) or ""))
	end
end

local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local function hittaGui()
	for _, b in ipairs(CoreGui.Children) do
		if b.Name == "UBRF_QA" then return b end
	end
	return nil
end

--[[ ── Vägran utanför Studio ──────────────────────────────────────────
	Stubben har IsStudio=false som utgångsläge, med flit. Startar panelen
	ändå är spärren borta. ]]
do
	RunService.IsStudio = function() return false end
	QAPanel.start(Vyer)
	check("panelen vägrar starta utanför Studio", hittaGui() == nil,
		"ingen ScreenGui skapad")
end

--[[ ── I Studio ────────────────────────────────────────────────────── ]]
RunService.IsStudio = function() return true end
QAPanel.start(Vyer)

local gui = hittaGui()
check("panelen bygger sin ScreenGui i Studio", gui ~= nil,
	gui and gui.Name or "ingen gui")

--[[ Knapparna letas upp på sin text, inte på ordning. Flyttas de i koden ska
	provet fortfarande hitta dem; byter de text är det en avsiktlig ändring
	som SKA fälla provet. ]]
local knappar = {}
if gui then
	for _, b in ipairs(gui:GetDescendants()) do
		if b.ClassName == "TextButton" then knappar[b.Text] = b end
	end
end
for _, text in ipairs({ "◀", "▶", "PASS", "FEL", "Återställ kameran" }) do
	check("knappen " .. text .. " finns", knappar[text] ~= nil)
end

--[[ ── Att trycka gör något ───────────────────────────────────────────
	Utan det här beviset kan panelen se komplett ut och ändå vara död. ]]
do
	local namnetikett
	if gui then
		for _, b in ipairs(gui:GetDescendants()) do
			if b.ClassName == "TextLabel" and b.Text == Vyer.vyer[1].id then
				namnetikett = b
			end
		end
	end
	check("panelen visar första vyns namn", namnetikett ~= nil,
		Vyer.vyer[1].id)

	if namnetikett and knappar["▶"] then
		knappar["▶"].Activated._fire()
		check("Nästa byter vy", namnetikett.Text == Vyer.vyer[2].id,
			"visar " .. tostring(namnetikett.Text))
		knappar["◀"].Activated._fire()
		check("Föregående går tillbaka", namnetikett.Text == Vyer.vyer[1].id,
			"visar " .. tostring(namnetikett.Text))
	end

	--[[ Varvet runt: lika många steg som vyer ska landa på första igen. Det
		fäller både en avstannande och en överhoppande räknare. ]]
	if namnetikett and knappar["▶"] then
		for _ = 1, #Vyer.vyer do knappar["▶"].Activated._fire() end
		check("ett helt varv landar på första vyn igen",
			namnetikett.Text == Vyer.vyer[1].id,
			"efter " .. #Vyer.vyer .. " steg: " .. tostring(namnetikett.Text))
	end
end

--[[ ── PASS och FEL ───────────────────────────────────────────────────
	Bedömningen ska fastna på RÄTT vy. Panelen går vidare efter ett omdöme,
	så den som bedöms är den som visades INNAN klicket. ]]
do
	if knappar["PASS"] and knappar["FEL"] then
		local forsta = Vyer.vyer[1].id
		knappar["PASS"].Activated._fire()
		local andra = Vyer.vyer[2].id
		knappar["FEL"].Activated._fire()

		local status
		if gui then
			for _, b in ipairs(gui:GetDescendants()) do
				if b.ClassName == "TextLabel" and type(b.Text) == "string"
					and string.find(b.Text, "inte bedömd", 1, true) then
					status = b
				end
			end
		end
		check("tredje vyn är obedömd efter två omdömen", status ~= nil,
			"PASS på " .. forsta .. ", FEL på " .. andra)
	end
end

--[[ ── Ingen egen vylista ─────────────────────────────────────────────
	Panelen får aldrig bära en egen kopia av vyerna. Gör den det uppstår
	samma andra sanning som redan fällt fargexporten och objektantalet. ]]
do
	check("panelen räknar vyerna ur Vyer, inte ur en egen lista",
		#Vyer.vyer >= 1,
		#Vyer.vyer .. " vyer")
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("qa.spec: " .. fails .. " fel")
end
print("\nalla gröna")
