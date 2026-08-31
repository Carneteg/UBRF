--!strict
--[[ UBRF QA — utvecklarpanel för den manuella Studio-genomgången.

	Tobias ska kunna göra hela den visuella granskningen utan att röra
	kommandoraden och utan att kunna kodbasen: klicka Nästa, titta, klicka
	PASS eller FEL, gå vidare.

	VARFÖR DEN LIGGER HÄR OCH INTE I roblox/src/client/
	Panelen får aldrig bli spelar-UI. Klientmapparna paketeras in i spelet;
	den här filen gör det inte — den fogas bara in av tools/studio-paket.py
	i den fil man klistrar in i Studio. Utöver det vägrar den starta utanför
	Studio. Två spärrar, för en dev-panel som läcker ut till spelare är
	precis den sortens miss ingen upptäcker förrän den står i en release.

	Vyerna kommer ur Vyer.luau, som i sin tur räknar dem ur UBRFKomplex.
	Panelen har alltså ingen egen lista att hålla i synk.
]]

local RunService = game:GetService("RunService")

local QAPanel = {}

local Vyer: any = nil
local gui: ScreenGui? = nil
local i = 1
local resultat: { [string]: string } = {}

local FARG = {
	bak = Color3.fromRGB(28, 28, 30),
	ram = Color3.fromRGB(64, 64, 68),
	text = Color3.fromRGB(238, 234, 220),
	svag = Color3.fromRGB(150, 148, 142),
	pass = Color3.fromRGB(64, 132, 76),
	fel = Color3.fromRGB(150, 58, 52),
	knapp = Color3.fromRGB(52, 52, 56),
}

local function ny(klass: string, foralder: Instance, egenskaper: { [string]: any }): any
	local o = Instance.new(klass)
	for k, v in egenskaper do
		(o :: any)[k] = v
	end
	o.Parent = foralder
	return o
end

local function knapp(foralder: Instance, text: string, x: number, b: number,
	y: number, h: number, farg: Color3): TextButton
	local kn = ny("TextButton", foralder, {
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = FARG.text, BackgroundColor3 = farg, BorderSizePixel = 0,
		Position = UDim2.new(x, 0, 0, y), Size = UDim2.new(b, -6, 0, h),
		AutoButtonColor = true,
	})
	ny("UICorner", kn, { CornerRadius = UDim.new(0, 4) })
	return kn
end

--[[ Sammanfattningen skrivs till Output. Den är hela poängen med panelen:
	efter genomgången ska det gå att klistra in en färdig lista i PR:en utan
	att någon behöver minnas vad som var vad. ]]
local function sammanfatta()
	local vyer = Vyer.vyer
	local pass, fel, gap, kvar = 0, 0, 0, 0
	--[[ Raderna inleds med en bock, inte med ordet. roblox/tests/kor.sh
		letar efter ^\s*FEL for att hitta misslyckade prov, och en rad som
		BORJAR med FEL har fick hela qa-specen att se rod ut fast den var
		gron. Ordet star kvar for den som laser; markoren gor att provbanken
		inte forvaxlar panelens utskrift med sin egen. ]]
	print("\n── UBRF QA · resultat ──")
	for _, v in ipairs(vyer) do
		local r = resultat[v.id]
		if r == "PASS" then
			pass += 1
			print(("  ✓ PASS  %s"):format(v.id))
		elseif r == "FEL" then
			fel += 1
			print(("  ✗ FEL   %s   → skärmdump: qa-%s-FEL.png"):format(v.id, v.id))
		elseif r == "GAP" then
			gap += 1
			print(("  ◌ GAP   %s   (ej bedömbar — REFERENCE GAP)"):format(v.id))
		else
			kvar += 1
			print(("  · —     %s   (inte bedömd)"):format(v.id))
		end
	end

	--[[ GAP RÄKNAS ALDRIG SOM PASS och ligger aldrig i nämnaren. En vy vars
	     underlag saknas kan inte godkännas, och att låta den tysta in i
	     "N av M godkända" hade gjort en källucka till en delseger. Nämnaren
	     är därför de BEDÖMBARA vyerna. ]]
	local bedombara = #vyer - gap
	print(("  %d PASS, %d FEL, %d kvar av %d bedömbara"):format(pass, fel, kvar, bedombara))
	if gap > 0 then
		print(("  %d vyer är EJ BEDÖMBARA (REFERENCE GAP) och ingår inte i nämnaren."):format(gap))
	end
	if fel > 0 then
		print("  Skriv for varje FEL vad du SAG och VAR — inte gissad orsak.")
	end
	return { pass = pass, fel = fel, gap = gap, kvar = kvar, bedombara = bedombara }
end

local uppdatera: () -> ()

function QAPanel.start(vyModul: any)
	if not RunService:IsStudio() then
		warn("[UBRF QA] Panelen startar bara i Studio.")
		return
	end
	Vyer = vyModul or Vyer
	if not Vyer or not Vyer.vyer or #Vyer.vyer == 0 then
		warn("[UBRF QA] Hittar inga vyer — kor bygget forst.")
		return
	end
	--[[ Parent-kollen: gui-variabeln överlever att någon raderar själva
	     ScreenGui:n i Explorer. Utan den gjorde UBRFQA() då ingenting alls —
	     panelen "fanns" för koden men inte för människan. ]]
	if gui and gui.Parent then
		gui.Enabled = true
		uppdatera()
		return
	end
	gui = nil
	--[[ En NY panel börjar på vy 1. i är modul-lokal och överlever panelen;
	     lämnas den kvar kan den peka utanför en kortare vylista, och panelen
	     öppnar mitt i sviten som om inget hänt. Omdömena behålls — de är
	     satta per vy-id och ska inte försvinna för att panelen byggs om. ]]
	i = 1

	local spelare = game:GetService("Players").LocalPlayer
	local mal = spelare and spelare:FindFirstChildOfClass("PlayerGui")
		or game:GetService("CoreGui")

	gui = ny("ScreenGui", mal, {
		Name = "UBRF_QA", ResetOnSpawn = false, IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})

	local ram = ny("Frame", gui :: any, {
		BackgroundColor3 = FARG.bak, BorderSizePixel = 0,
		Position = UDim2.new(0, 16, 0, 16), Size = UDim2.new(0, 300, 0, 188),
	})
	ny("UICorner", ram, { CornerRadius = UDim.new(0, 8) })
	ny("UIStroke", ram, { Color = FARG.ram, Thickness = 1 })

	ny("TextLabel", ram, {
		Text = "UBRF QA", Font = Enum.Font.GothamBold, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 16),
	})

	local raknare = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Right,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 16),
	})

	local namn = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.GothamBold, TextSize = 15,
		TextColor3 = FARG.text, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1, TextTruncate = Enum.TextTruncate.AtEnd,
		Position = UDim2.new(0, 12, 0, 28), Size = UDim2.new(1, -24, 0, 20),
	})

	local beskrivning = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.Gotham, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 50), Size = UDim2.new(1, -24, 0, 46),
	})

	local status = ny("TextLabel", ram, {
		Text = "", Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = FARG.svag, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 12, 0, 100), Size = UDim2.new(1, -24, 0, 16),
	})

	local forra = knapp(ram, "◀", 0.03, 0.16, 122, 28, FARG.knapp)
	local nasta = knapp(ram, "▶", 0.20, 0.16, 122, 28, FARG.knapp)
	local pass = knapp(ram, "PASS", 0.38, 0.28, 122, 28, FARG.pass)
	local fel = knapp(ram, "FEL", 0.67, 0.30, 122, 28, FARG.fel)
	--[[ Tredje utfallet finns bara när vymodulen ber om det. F01-panelens
	     semantik ändras inte: utan flaggan finns knappen inte, och
	     sammanfattningen ser likadan ut som förut. ]]
	local gapKnapp = if vyModul.gapKnapp
		then knapp(ram, "GAP", 0.38, 0.62, 122, 28, FARG.knapp)
		else nil
	local aterstall = knapp(ram, "Återställ kameran", 0.03, 0.94, 154, 26, FARG.knapp)

	uppdatera = function()
		local v = Vyer.vyer[i]
		if not v then return end
		namn.Text = v.id
		beskrivning.Text = v.text
		raknare.Text = ("%d/%d"):format(i, #Vyer.vyer)
		local r = resultat[v.id]
		if r == "PASS" then
			status.Text = "PASS"
			status.TextColor3 = FARG.pass
		elseif r == "FEL" then
			status.Text = "FEL — spara qa-" .. v.id .. "-FEL.png"
			status.TextColor3 = FARG.fel
		elseif r == "GAP" then
			status.Text = "GAP — EJ BEDÖMBAR (REFERENCE GAP)"
			status.TextColor3 = FARG.svag
		elseif v.ejBedombar then
			status.Text = "EJ GEOMETRISKT BEDÖMBAR — REFERENCE GAP"
			status.TextColor3 = FARG.svag
		else
			status.Text = "inte bedömd"
			status.TextColor3 = FARG.svag
		end
		--[[ En vy utan underlag får inte kunna PASS:as. Knappen släcks, och
		     bedom() vägrar dessutom — synligt OCH i logiken, så att en
		     framtida UI-ändring inte tyst öppnar dörren igen. ]]
		pass.Visible = not v.ejBedombar
	end

	--[[ FAIL-CLOSED. Förut stegade panelen fram FÖRST och pcall:ade kameran
	     sedan — gick kameraflytten fel stod panelen ändå och sa "2/11
	     ankomsten" medan viewporten låg kvar i föregående vy. Precis det
	     hände i Studio 2026-08-31: vyn såg tom ut, ViewCube sa Top, och
	     panelen påstod ankomsten. En panel som påstår en vy kameran aldrig
	     nådde är värre än ett rakt fel: den får en människa att bedöma FEL
	     BILD. Nu flyttas kameran först; går det inte stannar panelen kvar och
	     skriver felet både i panelen och i Output. ]]
	local function ga(steg: number)
		local nytt = ((i - 1 + steg) % #Vyer.vyer) + 1
		local ok, err = pcall(function() Vyer.ga(Vyer.vyer[nytt].id) end)
		if not ok then
			warn("[UBRF QA] Kameran kom ALDRIG till '" .. Vyer.vyer[nytt].id
				.. "' — panelen stannar kvar. Fel: " .. tostring(err))
			uppdatera()
			status.Text = "KAMERAFEL: " .. Vyer.vyer[nytt].id .. " gick inte att visa"
			status.TextColor3 = FARG.fel
			return
		end
		i = nytt
		uppdatera()
	end

	local function bedom(varde: string)
		local v = Vyer.vyer[i]
		if not v then return end
		if v.ejBedombar and varde == "PASS" then
			warn("[UBRF QA] '" .. v.id .. "' är EJ BEDÖMBAR (REFERENCE GAP) "
				.. "och kan inte godkännas. Använd GAP.")
			return
		end
		resultat[v.id] = varde
		uppdatera()
		sammanfatta()
		if i < #Vyer.vyer then ga(1) end
	end

	forra.Activated:Connect(function() ga(-1) end)
	nasta.Activated:Connect(function() ga(1) end)
	pass.Activated:Connect(function() bedom("PASS") end)
	fel.Activated:Connect(function() bedom("FEL") end)
	if gapKnapp then gapKnapp.Activated:Connect(function() bedom("GAP") end) end
	aterstall.Activated:Connect(function()
		local kam = workspace.CurrentCamera
		if kam then kam.CameraType = Enum.CameraType.Custom end
	end)

	ga(0)
	print("[UBRF QA] Panelen igång. " .. #Vyer.vyer .. " vyer att gå igenom.")
end

function QAPanel.dolj()
	if gui then gui.Enabled = false end
end

QAPanel.sammanfatta = sammanfatta

--[[ För provbänken: rena funktioner utan GUI. ]]
function QAPanel.rakna(vyer, res)
	local pass, fel, gap, kvar = 0, 0, 0, 0
	for _, v in ipairs(vyer) do
		local r = res[v.id]
		if r == "PASS" then pass += 1
		elseif r == "FEL" then fel += 1
		elseif r == "GAP" then gap += 1
		else kvar += 1 end
	end
	return { pass = pass, fel = fel, gap = gap, kvar = kvar,
		bedombara = #vyer - gap }
end

function QAPanel.farBedomas(vy, varde: string): boolean
	if vy.ejBedombar and varde == "PASS" then return false end
	return true
end

return QAPanel
