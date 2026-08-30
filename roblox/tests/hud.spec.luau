--!nostrict
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
if not panel then error("hud.spec: panelen saknas") end

print("\n── G01 HUD: 320 px telefon ──")
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
	check("panelen ryms i 320 px", vanster + bredd(vp) <= vp,
		string.format("högerkant %.0f/%d", vanster + bredd(vp), vp))
	check("panelen blir max 360 px på desktop", bredd(1920) <= 360, tostring(bredd(1920)))
end

print("\n── G01 HUD: all text ligger på bakgrunden ──")
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
	check("alla etiketter ryms i paddad yta", varsta <= innehall,
		string.format("%s slutar %d, ytan %d", tostring(varstaNamn), varsta, innehall))
	local fb = hitta(panel, "Feedback")
	check("feedback rymmer två rader", fb and fb.Size.Y.Offset >= (fb.TextSize + 2) * 2,
		fb and tostring(fb.Size.Y.Offset) or "saknas")
end

print("\n── G01 HUD: serverfeedback vinner över sent initialt svar ──")
do
	local fb = hitta(panel, "Feedback")
	local horse = hitta(panel, "Horse")
	local objective = hitta(panel, "Objective")
	local stateChanged = __Core.Networking.get("G01StateChanged")

	stateChanged.OnClientEvent._fire({
		enabled = true, phase = "check", horseName = "Toblerone",
		objective = "Gör en snabb visitering.", mountUnlocked = false,
	}, "Bra. En häst ska inte överraskas från en blind vinkel.")
	check("serverfeedback syns", fb.Text ~= nil and fb.Text ~= "", tostring(fb.Text))
	check("hästnamnet syns", horse.Text == "Toblerone", tostring(horse.Text))

	__Core.Networking.get("G01GetState").InvokeServer = function()
		stateChanged.OnClientEvent._fire({
			enabled = true, phase = "groom", horseName = "Toblerone",
			objective = "Rykta hästen.", mountUnlocked = false,
		}, "Bra. En snabb kontroll före ridning kan upptäcka att något inte känns som vanligt.")
		return {
			enabled = true, phase = "check", horseName = "Toblerone",
			objective = "Gör en snabb visitering.", mountUnlocked = false,
		}
	end
	GameplayController.start()
	check("sen refresh raderar inte feedback", fb.Text ~= nil and fb.Text ~= "", tostring(fb.Text))
	check("sen refresh skriver inte över nyare objective", objective.Text == "Rykta hästen.", tostring(objective.Text))
end

print("\n── G01 HUD: saknad produktionsrigg kommuniceras utan låtsashäst ──")
do
	local stateChanged = __Core.Networking.get("G01StateChanged")
	local objective = hitta(panel, "Objective")
	local horse = hitta(panel, "Horse")
	stateChanged.OnClientEvent._fire({
		enabled = true, phase = "waiting_model", horseName = "Air Italia",
		objective = "Din häst är tilldelad, men hennes ridmodell finns inte i världen ännu.",
		mountUnlocked = false,
	}, nil)
	check("hästidentiteten visas även utan rigg", horse.Text == "Air Italia")
	check("waiting_model-målet visas", string.find(objective.Text, "ridmodell") ~= nil, objective.Text)
end

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("hud.spec: " .. fails .. " fel")
end
print("\nG01 hud: alla gröna")
