--!strict
--[[
	DEN VISUELLA HÄSTEN — ett presentationslager ovanpå spelhästen.

	══ VAD DEN HÄR MODULEN INTE GÖR ═══════════════════════════════════

	Den rör inte rörelsen. Inte ledningen. Inte tackets tillstånd. Inte
	uppsittningsgrinden. Inte kollisionshöljet.

	`HastRigg` bygger fortfarande hästen: `HumanoidRootPart` är den enda
	delen som kolliderar, Humanoiden bär `HipHeight`, och de anatomiska
	fästpunkterna bär utrustningen. Allt det är låst mark sedan
	blockerare 5 och `HORSE_FORWARD_CONVENTION`.

	Det den här modulen gör är att byta ut INNEHÅLLET i `Visual`-mappen:
	lådorna åker ut, ett riktigt nät åker in, och de anatomiska
	fästpunkterna flyttas med till nätets motsvarande kroppsdelar så att
	tränset följer huvudet och sadeln följer ryggen.

	Vad modellen kallar sina delar står i `HorseCore.Riggprofiler`, inte
	här. Den här filen kan alltså montera vilken profilerad rigg som helst
	utan att ändras.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Riggprofiler = require(ReplicatedStorage.HorseCore.Riggprofiler)

local HastVisual = {}

local M = 3             -- studs per meter, som BuildKit.M
local MANKHOJD = 1.45   -- m, kategori D-ponny — samma tal som HastRigg
local MALLMAPP = "HastVisualer"

--[[ ══ MALLARNA ══════════════════════════════════════════════════════

	Ett nät går inte att uttrycka i Luau. Mallen ligger därför i placen,
	under `ServerStorage.HastVisualer`, precis som världsbyggaren ligger i
	`ServerScriptService.Varld`. Saknas den byggs hästen med lådorna som
	förut — det visuella lagret får aldrig kunna fälla spelbarheten. ]]
function HastVisual.mall(namn: string): Model?
	local ss = game:GetService("ServerStorage")
	local mapp = ss:FindFirstChild(MALLMAPP)
	local m = mapp and mapp:FindFirstChild(namn)
	return (m and m:IsA("Model")) and m or nil
end

--[[ ══ STÄDNINGEN ════════════════════════════════════════════════════

	Körs EN gång på mallen, inte per häst. Allt som inte är häst rivs:
	skript, remotes, ljud, partiklar, fysikmotorer och modellens egen
	utrustning. Vad som räknas som "inte häst" står i profilens `riv`. ]]
function HastVisual.stada(mall: Model, profilNamn: string): (number, { string })
	local p = Riggprofiler.profil(profilNamn)
	if not p then return 0, { "okänd profil " .. tostring(profilNamn) } end
	local klasser: { [string]: boolean } = {}
	for _, c in ipairs(p.riv.klasser) do klasser[c] = true end
	local namn: { [string]: boolean } = {}
	for _, n in ipairs(p.riv.namn) do namn[n] = true end

	local rivna, logg = 0, {}
	--[[ Bakifrån: att riva mitt i en iteration över `GetDescendants` gör
		att syskon hoppas över, och då blir städningen ofullständig på ett
		sätt som inte syns förrän något kör i produktion. ]]
	local alla = mall:GetDescendants()
	for i = #alla, 1, -1 do
		local d = alla[i]
		if d.Parent and (klasser[d.ClassName] or namn[d.Name]) then
			table.insert(logg, ("%s [%s]"):format(d.Name, d.ClassName))
			d:Destroy()
			rivna += 1
		end
	end
	return rivna, logg
end

--[[ ══ MONTERINGEN ═══════════════════════════════════════════════════ ]]

local function hitta(modell: Instance, namn: string): BasePart?
	local d = modell:FindFirstChild(namn, true)
	return (d and d:IsA("BasePart")) and d or nil
end

--[[ Fästpunkterna flyttas till NÄTETS kroppsdelar, och det är hela
	poängen: `TackRigg` svetsar utrustningen i fästpunktens värddel, så
	det är värddelen som avgör om tränset följer huvudet eller hänger
	kvar i luften framför bålen. ]]
local function flyttaFasten(hast: Model, natet: Model, p: any, skala: number): { string }
	local flyttade = {}
	for namn, spec in pairs(p.tackfasten) do
		local vard = hitta(natet, spec.vard)
		if vard then
			--[[ Riv den gamla punkten var den än satt — annars bär hästen
				två `SaddleAttachment` och adaptern får välja. ]]
			local gammal = hast:FindFirstChild(namn, true)
			if gammal and gammal:IsA("Attachment") then gammal:Destroy() end
			--[[ Läget mättes på det OSKALADE nätet och skalas med det.
				Rotationen — om en profil någon gång bär en — följer
				oförändrad; bara avståndet krymper. ]]
			local a = Instance.new("Attachment")
			a.Name = namn
			a.CFrame = CFrame.new(spec.cf.Position * skala) * spec.cf.Rotation
			a.Parent = vard
			table.insert(flyttade, ("%s->%s"):format(namn, vard.Name))
		end
	end
	table.sort(flyttade)
	return flyttade
end

--[[ Monterar ett visuellt nät på en spelhäst. Svarar false och ett skäl
	när något saknas; hästen fungerar då vidare med lådorna. ]]
function HastVisual.montera(hast: Model, mall: Model, profilNamn: string): (boolean, string?)
	local p = Riggprofiler.profil(profilNamn)
	if not p then return false, "okänd profil " .. tostring(profilNamn) end
	local rot = hast:FindFirstChild("HumanoidRootPart")
	if not (rot and rot:IsA("BasePart")) then return false, "spelhästen saknar rot" end

	--[[ LÅDORNA UT. Mappen behålls: en tom mapp är enklare att felsöka än
		en saknad, och `HastRigg` känner igen den. ]]
	local visual = hast:FindFirstChild("Visual")
	if visual then
		for _, d in ipairs(visual:GetChildren()) do d:Destroy() end
	else
		visual = Instance.new("Folder")
		visual.Name = "Visual"
		visual.Parent = hast
	end

	local natet = mall:Clone()
	natet.Name = "Nät"
	--[[ SKALAN UR MÄTNINGEN, inte ur en magisk konstant. ]]
	local skala = (MANKHOJD * M) / p.mankhojd
	natet:ScaleTo(skala)

	local natRot = hitta(natet, p.rot)
	if not natRot then
		natet:Destroy()
		return false, "nätet saknar sin rot: " .. tostring(p.rot)
	end

	--[[ MONTERINGEN. `framatZ = 1` betyder att modellören byggde nosen åt
		+Z, och då — och bara då — vrids nätet ett halvt varv HÄR. Det är
		den enda plats i projektet där en sådan vridning får finnas.
		Spelhästens rot, kursintegrationen och `LookVector` rörs inte. ]]
	local vridning = if p.framatZ > 0 then CFrame.Angles(0, math.pi, 0) else CFrame.identity
	natet.Parent = visual
	natet:PivotTo(rot.CFrame * vridning)

	--[[ HOVARNA PÅ MARKEN.

		Nätets egen rot sitter inte på samma höjd över hovarna som vår.
		Svetsas den rakt av svävar hästen — uppmätt 0,33 studs första
		gången, alltså 11 cm luft under hovarna, och mankhöjden blev 1,56 m
		i stället för kanons 1,45.

		Marken räknas ur riggens egen `HipHeight`, som per definition är
		avståndet mark→rotens underkant. Då blir höjdsättningen en MÄTNING
		och inte en konstant som måste stämmas om varje gång en modell
		byter proportioner. ]]
	local hum = hast:FindFirstChildOfClass("Humanoid")
	local markY = (rot.Position.Y - rot.Size.Y / 2) - (hum and hum.HipHeight or 0)
	local lagst = math.huge
	for _, d in ipairs(natet:GetDescendants()) do
		if d:IsA("BasePart") then
			lagst = math.min(lagst, d.Position.Y - d.Size.Y / 2)
		end
	end
	if lagst < math.huge then
		--[[ Förskjutningen läggs i VÄRLDENS rum och inte i nätets eget:
			en profil som någon gång monteras med lutning ska flyttas rakt
			upp, inte längs sin egen sneda y-axel. ]]
		natet:PivotTo(CFrame.new(0, markY - lagst, 0) * natet:GetPivot())
	end

	--[[ Nätet syns, kolliderar aldrig och väger ingenting. Kollisionen är
		och förblir `HumanoidRootPart`. ]]
	for _, d in ipairs(natet:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
			d.Anchored = false
		end
	end

	--[[ Nätets egen rot svetsas i spelhästens. Resten hänger i sina
		Motor6D och kan därför animeras utan att kroppen glider. ]]
	local w = Instance.new("WeldConstraint")
	w.Name = "VisualWeld"
	w.Part0 = rot
	w.Part1 = natRot
	w.Parent = natRot

	local flyttade = flyttaFasten(hast, natet, p, skala)

	--[[ SITSEN flyttas till nätets rygg så att ryttaren hamnar i sadeln
		och inte i luften. Sitsen är fortfarande gameplay — den byter bara
		läge, och `HorseService` hittar den på samma namn som förut. ]]
	local sits = hast:FindFirstChild("RiderSeat")
	local sitsVard = hitta(natet, p.sits.vard)
	if sits and sits:IsA("BasePart") and sitsVard then
		local gammal = sits:FindFirstChild("SitsFaste")
		if gammal then gammal:Destroy() end
		sits.CFrame = sitsVard.CFrame * CFrame.new(p.sits.cf.Position * skala)
		local sw = Instance.new("WeldConstraint")
		sw.Name = "SitsFaste"
		sw.Part0 = sitsVard
		sw.Part1 = sits
		sw.Parent = sits
	end

	--[[ Attributet är klientens enda ingång: gånglagret läser profilen
		härifrån i stället för att känna till modellen. ]]
	hast:SetAttribute("Riggkalla", p.kalla)
	hast:SetAttribute("VisuellProfil", profilNamn)
	return true, ("skala %.3f · %d fästpunkter: %s"):format(skala, #flyttade, table.concat(flyttade, " "))
end

return HastVisual
