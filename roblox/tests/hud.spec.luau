--!nostrict
--[[
	G01-panelen — ryms allt inuti den, på en smal telefon?

	Panelen är fast höjd med UIPadding. Ett barn som sträcker sig förbi
	innehållsytan klipps inte bort (ClipsDescendants är falskt som standard) —
	det ritas UTANFÖR den mörka bakgrunden, ovanpå 3D-scenen. Feedbacktexten
	blir då oläslig, vilket är samma sak som att den försvinner.

	Provet räknar på samma tal som koden sätter, i stället för att lita på en
	kommentar om att det ryms.

	Kör: python3 roblox/tests/build.py tests/hud.spec.luau
	     && luau roblox/tests/.build/hud.spec.luau
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

GameplayController.start()

local function hitta(rot, namn)
	if rot.Name == namn then return rot end
	for _, b in ipairs(rot.Children or {}) do
		local t = hitta(b, namn)
		if t then return t end
	end
	return nil
end

local skarm = hitta(__playerGuiRef, "UBRFG01")
check("panelen byggdes", skarm ~= nil)
local panel = skarm and hitta(skarm, "ObjectivePanel")
check("ObjectivePanel finns", panel ~= nil)

if not panel then
	print("\n1 FEL")
	error("hud.spec: panelen saknas")
end

--[[ ── Bredd på en 320 px telefon ────────────────────────────────────── ]]
do
	local size = hitta(panel, "UISizeConstraint")
	local minB = size and size.MinSize and size.MinSize.X or 0
	local maxB = size and size.MaxSize and size.MaxSize.X or math.huge
	local vanster = panel.Position.X.Offset

	local function bredd(viewport)
		local b = panel.Size.X.Scale * viewport + panel.Size.X.Offset
		return math.max(minB, math.min(maxB, b))
	end

	local vp = 320
	local hoger = vanster + bredd(vp)
	check("panelen ryms i en 320 px viewport", hoger <= vp,
		string.format("högerkant %.0f av %d", hoger, vp))

	check("panelen växer inte förbi 360 px på stor skärm",
		bredd(1920) <= 360, string.format("%.0f px", bredd(1920)))
end

--[[ ── Höjd: ryms barnen i den PADDADE innehållsytan? ─────────────────── ]]
do
	local pad = hitta(panel, "UIPadding")
	local top = pad and pad.PaddingTop and pad.PaddingTop.Offset or 0
	local bot = pad and pad.PaddingBottom and pad.PaddingBottom.Offset or 0
	local innehall = panel.Size.Y.Offset - top - bot

	local varsta, varstaNamn = 0, nil
	for _, b in ipairs(panel.Children) do
		if b.Position and b.Size and b.ClassName == "TextLabel" then
			local underkant = b.Position.Y.Offset + b.Size.Y.Offset
			if underkant > varsta then varsta, varstaNamn = underkant, b.Name end
		end
	end
	check("alla etiketter ryms innanför panelens innehållsyta",
		varsta <= innehall,
		string.format("%s slutar på %d, innehållsytan är %d", tostring(varstaNamn), varsta, innehall))
end

--[[ ── Feedbacken måste rymma två rader ────────────────────────────────
	Den längsta pedagogiska texten är 81 tecken. Vid TextSize 11 i en panel
	som är ~268 px bred invändigt blir det två rader. En etikett som bara
	rymmer en rad klipper bort halva meningen. ]]
do
	local fb = hitta(panel, "Feedback")
	check("feedbacketiketten finns", fb ~= nil)
	if fb then
		local radhojd = fb.TextSize + 2
		check("feedbacken rymmer två rader text",
			fb.Size.Y.Offset >= radhojd * 2,
			string.format("höjd %d, två rader behöver %d", fb.Size.Y.Offset, radhojd * 2))
	end
end

--[[ ── Feedbacken får inte raderas av en sen initialRefresh ─────────────
	Servern skickar fas + feedback i G01StateChanged. Om en långsam
	initialRefresh landar EFTER den, och renderar med feedback = nil, torkas
	den pedagogiska texten bort. Det är precis det spelaren skulle ha läst. ]]
do
	local fb = hitta(panel, "Feedback")
	local horse = hitta(panel, "Horse")
	local stateChanged = __Core.Networking.get("G01StateChanged")

	stateChanged.OnClientEvent._fire({
		enabled = true, phase = "check", horseName = "Alfa",
		objective = "Gör en snabb visitering.", mountUnlocked = false,
	}, "Bra. En häst ska inte överraskas från en blind vinkel.")

	check("feedbacken visas när servern skickar den",
		fb.Text ~= nil and fb.Text ~= "", tostring(fb.Text))
	check("hästens namn visas", horse.Text == "Alfa", tostring(horse.Text))

	--[[ Det farliga fallet i verkligheten: refreshen HINNER YIELDA, servern
		skickar sin feedback under tiden, och refreshen svarar EFTERÅT med
		feedback = nil. Stubben kan inte yielda, så vi gör det som händer i den
		luckan: InvokeServer fyrar av händelsen innan den returnerar. Utan den
		konstruktionen mäter provet ingenting — den första versionen "föll"
		bara för att anropet misslyckades, vilket är en annan sak. ]]
	__Core.Networking.get("G01GetState").InvokeServer = function()
		stateChanged.OnClientEvent._fire({
			enabled = true, phase = "groom", horseName = "Alfa",
			objective = "Rykta hästen.", mountUnlocked = false,
		}, "Bra. En snabb kontroll före ridning kan upptäcka att något inte känns som vanligt.")
		return {
			enabled = true, phase = "check", horseName = "Alfa",
			objective = "Gör en snabb visitering.", mountUnlocked = false,
		}
	end
	GameplayController.start()
	check("en sen refresh raderar inte serverns feedback",
		fb.Text ~= nil and fb.Text ~= "", "efter refresh: " .. tostring(fb.Text))
	check("den sena refreshen skriver inte över serverns nyare läge",
		hitta(panel, "Objective").Text == "Rykta hästen.",
		tostring(hitta(panel, "Objective").Text))
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("hud.spec: " .. fails .. " fel")
end
print("\nG01.1 hud: alla gröna")
