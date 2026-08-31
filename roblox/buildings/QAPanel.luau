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

	--[[ NÄMNAREN KOMMER UR KÄLLAN, INTE UR KLICKEN. Förut räknades
	     bedömbara som "alla minus de GAP någon HUNNIT klicka", så en vy som
	     panelen samtidigt sa var obedömbar låg kvar i nämnaren tills Tobias
	     kvitterat den. Nämnaren rörde sig alltså medan han arbetade.

	     Nu är `ejBedombar` sanningen: en vy utan underlag ligger utanför
	     nämnaren från början. Kvitteringen redovisas separat. ]]
	local r = QAPanel.rakna(vyer, resultat)
	print(("  %d PASS, %d FEL, %d kvar av %d bedömbara"):format(
		r.pass, r.fel, r.kvar, r.bedombara))
	if r.ejBedombara > 0 then
		print(("  %d vyer är EJ BEDÖMBARA (REFERENCE GAP) och ligger utanför nämnaren."):format(
			r.ejBedombara))
		if r.gapKvar > 0 then
			print(("  %d av dem är inte kvitterade än (GAP kvar att kvittera)."):format(r.gapKvar))
		end
	end
	if fel > 0 then
		print("  Skriv for varje FEL vad du SAG och VAR — inte gissad orsak.")
	end
	return r
end

--[[ HELA den klickbara layouten, som data.

     Första försöket beskrev bara PASS, FEL och GAP och prövade dem mot
     varandra. Provet blev grönt medan F02:s PASS låg rakt över ◀ och ▶ —
     de satt kvar på samma rad och ingick inte i prövningen. Ett prov som
     bara ser en del av ytan godkänner resten osett, och det är samma fel
     som allt annat i den här gaten finns till för att fånga.

     Nu ligger navigering, bedömning och kameraåterställning i samma
     tabell, och ramhöjden följer med så att ingen knapp hamnar utanför.

     UTAN GAP är varje tal exakt F01:s. F02 får en egen rad för bedömningen
     och en högre ram. ]]
function QAPanel.knapplayout(harGap: boolean)
	if not harGap then
		return {
			ramhojd = 188,
			knappar = {
				forra = { x = 0.03, b = 0.16, y = 122, h = 28 },
				nasta = { x = 0.20, b = 0.16, y = 122, h = 28 },
				pass = { x = 0.38, b = 0.28, y = 122, h = 28 },
				fel = { x = 0.67, b = 0.30, y = 122, h = 28 },
				aterstall = { x = 0.03, b = 0.94, y = 154, h = 26 },
			},
		}
	end
	return {
		ramhojd = 222,
		knappar = {
			forra = { x = 0.03, b = 0.16, y = 122, h = 28 },
			nasta = { x = 0.20, b = 0.16, y = 122, h = 28 },
			pass = { x = 0.03, b = 0.30, y = 156, h = 28 },
			fel = { x = 0.35, b = 0.30, y = 156, h = 28 },
			gap = { x = 0.67, b = 0.30, y = 156, h = 28 },
			aterstall = { x = 0.03, b = 0.94, y = 188, h = 26 },
		},
	}
end

--[[ Prövar HELA layouten: ingen kontroll får överlappa en annan, och ingen
     får ligga utanför ramen. Överlapp räknas som rektanglar — både x och y
     måste skära. ]]
function QAPanel.layoutfel(L): (number, string)
	local rutor = {}
	for namn, r in pairs(L.knappar) do
		if r then table.insert(rutor, { namn = namn, r = r }) end
	end
	table.sort(rutor, function(a, b)
		if a.r.y ~= b.r.y then return a.r.y < b.r.y end
		return a.r.x < b.r.x
	end)
	local fel, text = 0, {}
	for _, e in ipairs(rutor) do
		if e.r.x < 0 or e.r.x + e.r.b > 1.0 then
			fel += 1
			table.insert(text, e.namn .. " ligger utanför panelens bredd")
		end
		if e.r.y < 0 or e.r.y + e.r.h > L.ramhojd then
			fel += 1
			table.insert(text, e.namn .. " ligger utanför panelens höjd")
		end
	end
	for i = 1, #rutor do
		for j = i + 1, #rutor do
			local a, b = rutor[i].r, rutor[j].r
			local xkross = a.x < b.x + b.b and b.x < a.x + a.b
			local ykross = a.y < b.y + b.h and b.y < a.y + a.h
			if xkross and ykross then
				fel += 1
				table.insert(text, rutor[i].namn .. " överlappar " .. rutor[j].namn)
			end
		end
	end
	return fel, table.concat(text, "; ")
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
	--[[ Panelen får inte återanvändas över lägesbyte. Öppnades F01 först och
	     F02 sedan, i samma Studio-session, saknade F02 sin GAP-knapp — den
	     byggs bara när ett NYTT gui skapas. Omvänt kunde F01 ärva en
	     GAP-knapp den inte får ha. Läget är därför en del av identiteten:
	     skiljer det sig rivs panelen och byggs om. ]]
	local nyttLage = vyModul.gapKnapp == true
	if gui and gui.Parent and gui:GetAttribute("F02Lage") ~= nyttLage then
		gui:Destroy()
		gui = nil
		i = 1
	end

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

	gui:SetAttribute("F02Lage", nyttLage)
	local L = QAPanel.knapplayout(nyttLage)
	local ram = ny("Frame", gui :: any, {
		BackgroundColor3 = FARG.bak, BorderSizePixel = 0,
		Position = UDim2.new(0, 16, 0, 16), Size = UDim2.new(0, 300, 0, L.ramhojd),
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

	local K = L.knappar
	local forra = knapp(ram, "◀", K.forra.x, K.forra.b, K.forra.y, K.forra.h, FARG.knapp)
	local nasta = knapp(ram, "▶", K.nasta.x, K.nasta.b, K.nasta.y, K.nasta.h, FARG.knapp)
	--[[ Layouten kommer ur en ren funktion, inte ur tre lösa tal på tre
	     rader. GAP lades först på x = 0,38 med bredden 0,62 — samma rad och
	     samma yta som PASS och FEL, och skapad efter dem, så den la sig
	     ÖVER de två knappar Tobias behöver för human gate. Ett ögonmått
	     räcker inte till det här; rektanglarna prövas nu. ]]
	local pass = knapp(ram, "PASS", K.pass.x, K.pass.b, K.pass.y, K.pass.h, FARG.pass)
	local fel = knapp(ram, "FEL", K.fel.x, K.fel.b, K.fel.y, K.fel.h, FARG.fel)
	local gapKnapp = if K.gap
		then knapp(ram, "GAP", K.gap.x, K.gap.b, K.gap.y, K.gap.h, FARG.knapp)
		else nil
	local aterstall = knapp(ram, "Återställ kameran",
		K.aterstall.x, K.aterstall.b, K.aterstall.y, K.aterstall.h, FARG.knapp)

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
		if gapKnapp then gapKnapp.Visible = v.ejBedombar == true end
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
		if not QAPanel.farBedomas(v, varde) then
			if v.ejBedombar then
				warn("[UBRF QA] '" .. v.id .. "' är EJ BEDÖMBAR (REFERENCE GAP) "
					.. "och kan inte godkännas. Använd GAP.")
			else
				warn("[UBRF QA] '" .. v.id .. "' ÄR bedömbar och kan inte "
					.. "kvitteras som GAP. Använd PASS eller FEL.")
			end
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
	local pass, fel, gap, kvar, ejBedombara, gapKvar = 0, 0, 0, 0, 0, 0
	for _, v in ipairs(vyer) do
		local r = res[v.id]
		if v.ejBedombar then
			ejBedombara += 1
			if r == "GAP" then gap += 1 else gapKvar += 1 end
		elseif r == "PASS" then pass += 1
		elseif r == "FEL" then fel += 1
		elseif r == "GAP" then
			--[[ Ska inte kunna hända: farBedomas vägrar. Räknas som kvar,
			     aldrig som något som minskar nämnaren. ]]
			kvar += 1
		else kvar += 1 end
	end
	return { pass = pass, fel = fel, gap = gap, kvar = kvar,
		ejBedombara = ejBedombara, gapKvar = gapKvar,
		bedombara = #vyer - ejBedombara }
end

--[[ GAP är till för uttömda källuckor, inte för att slippa bedöma. En
     vanlig vy får därför INTE kvitteras bort som GAP: hade den kunnat det
     hade vem som helst kunnat lyfta ut en granskbar yta ur acceptansen med
     ett klick. ]]
function QAPanel.farBedomas(vy, varde: string): boolean
	if vy.ejBedombar then
		return varde ~= "PASS"
	end
	return varde ~= "GAP"
end

return QAPanel
