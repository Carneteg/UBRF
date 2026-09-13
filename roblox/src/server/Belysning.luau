--!strict
--[[
	INOMHUSBELYSNINGEN — armaturerna får faktiskt lysa.

	══ ROTORSAKEN ═════════════════════════════════════════════════════

	Stallet och ridhuset var nästan svarta i spel. Mätt i den byggda
	världen:

	    Light-instanser i hela anläggningen:  0
	    Stallarmatur   30 st   (Neon, tak, y ≈ 9,6)
	    Armaturpendel  30 st   (upphäng)
	    Lysrör 1..22   22 st   (Neon, ridhusets tak, y ≈ 17,7)
	    Mastarmatur    10 st   (utomhus, master)

	Armaturerna FANNS alltså — som geometri. De var ljusa ytor utan
	ljuskällor. Inomhus lystes världen bara av `Lighting.Ambient` på 0,275,
	och det är därför man inte kunde se hästen i sin egen box.

	══ VARFÖR INTE BARA HÖJA BRIGHTNESS ═══════════════════════════════

	`Brightness` är solen. Att skruva upp den tills stallet syns bränner ut
	gården, och ordern säger uttryckligen nej.

	`Ambient` är däremot golvet för allt ljus och `OutdoorAmbient` det som
	himlen lägger på ytor som ser himlen. Att lyfta `Ambient` men lämna
	`OutdoorAmbient` orörd lyfter alltså INOMHUS mer än utomhus — utomhus
	domineras redan av sol och himmel. Det är en riktad spak, inte en
	generell, och den kombineras här med riktiga armaturer.

	══ VARFÖR EN EGEN MODUL OCH INTE I VÄRLDSBYGGAREN ═════════════════

	`roblox/buildings/Anlaggningen.luau` är Replits miljöfil. Den här
	modulen rör inte geometrin: den letar upp de armaturer som redan står
	där och hänger en ljuskälla i dem. Additivt, omkörbart, och lätt att
	backa — och den ändrar inte en enda del som Replit äger.
]]

local Lighting = game:GetService("Lighting")

local Belysning = {}

local ANLAGGNING = "Anläggning"

--[[ ══ ARMATURTYPERNA ════════════════════════════════════════════════

	`range` i studs, `brightness` i Roblox egen skala. Talen är valda så
	att ljuskäglorna ÖVERLAPPAR utan att bli en jämn vit yta — ordern säger
	uttryckligen att det inte får bli platt vitt.

	Färgerna skiljer sig med flit: stallarmaturen är varmvit som en
	verklig stallampa, ridhusets lysrör svalare, och båda ligger långt
	från ren vit. ]]
local TYPER: { [string]: any } = {
	--[[ Stallets taklampor: 30 stycken över gångarna. Kort räckvidd, för
		de sitter lågt (y ≈ 9,6) och ska lysa gången — inte hela huset. ]]
	Stallarmatur = {
		klass = "SurfaceLight",
		farg = Color3.fromRGB(255, 244, 224),
		brightness = 2.8,
		range = 18,
		angle = 150,
		yta = Enum.NormalId.Bottom,
		skugga = false,
	},
	--[[ Ridhusets lysrör: 22 stycken högt uppe (y ≈ 17,7) över en mycket
		större yta, alltså längre räckvidd och bredare vinkel.

		TALEN ÄR FRAMSÖKTA MOT EN HÄST, inte mot sanden. 3,6 och 2,4 gav
		båda en läsbar bana — men en brun häst mitt i den lästes som
		gräddvit. Ridhuset är en stor ljus yta och 22 armaturer överlappar;
		det som ser lagom ut på underlaget bränner ut det som står på det.
		1,5 behåller hästens färg och banan är fortfarande läsbar. ]]
	["Lysrör"] = {
		klass = "SurfaceLight",
		farg = Color3.fromRGB(240, 246, 255),
		brightness = 1.5,
		range = 30,
		angle = 165,
		yta = Enum.NormalId.Bottom,
		skugga = false,
	},
	--[[ Utomhusmasterna lämnas MÖRKA med flit: klockan är 14.5 och solen
		är uppe. En mast som lyser mitt på dagen ser fel ut. Raden står
		kvar som dokumentation av att valet är gjort, inte glömt. ]]
}

--[[ ══ VARFÖR DET INTE FINNS NÅGRA FYLLNADSLJUS ═══════════════════

	Första versionen hängde 28 osynliga `PointLight` mitt emellan
	takarmaturerna, för att gången inte skulle bli fläckig mellan
	lamporna. Den gjorde precis det ordern förbjuder: den gjorde bilden
	PLATT. Uppmätt genom att växla dem på och av från samma kamera —
	med fyllnad tappade takbjälkarna sin färg, golvet blev urtvättat och
	boxarnas insidor läste lika ljust som gången.

	En stallgång SKA ha ljusare och mörkare partier. Det är det som gör
	att man ser att ljuset kommer någonstans ifrån. Armaturerna får
	därför stå för allt, och luckorna mellan dem är en egenskap, inte en
	brist.

]]

--[[ Ambient-golvet. Lyfter inomhus; `OutdoorAmbient` rörs INTE, så
	gården ser likadan ut. Talen är avläsbara i rapporten och avsiktligt
	måttliga — inomhus ska fortfarande LÄSAS som inomhus.

	Talet är framsökt, inte valt: 112 gav en gång där allt låg på samma
	ljusstyrka. 74 lyfter svärtan utan att äta kontrasten. ]]
Belysning.AMBIENT = Color3.fromRGB(74, 72, 68)

local function typFor(namn: string): any?
	for nyckel, t in pairs(TYPER) do
		if namn == nyckel or namn:sub(1, #nyckel) == nyckel then return t end
	end
	return nil
end

--[[ Hänger en ljuskälla i en armatur. Idempotent: körs modulen om byts
	ljuset ut i stället för att dubbleras. ]]
local function tand(del: BasePart, t: any): boolean
	local gammal = del:FindFirstChild("UBRFLjus")
	if gammal then gammal:Destroy() end
	local l = Instance.new(t.klass) :: any
	l.Name = "UBRFLjus"
	l.Color = t.farg
	l.Brightness = t.brightness
	l.Range = t.range
	l.Shadows = t.skugga == true
	if t.klass == "SurfaceLight" then
		l.Face = t.yta
		l.Angle = t.angle
	end
	l.Parent = del
	return true
end

--[[ Städar bort en tidigare körnings fyllnadsljus. Modulen byggde dem
	förut; en plats som redan kört den gamla versionen ska inte bli kvar
	med dem bara för att den här är omkörbar. ]]
local function rivFyllnad(foralder: Instance): number
	local n = 0
	for _, d in ipairs(foralder:GetDescendants()) do
		if d.Name == "UBRFFyllnad" then
			d:Destroy()
			n += 1
		end
	end
	return n
end

--[[ Tänder hela anläggningen. Svarar med en rad per armaturtyp så att
	Output säger vad som faktiskt hände — en tyst belysningsmodul är en
	som ingen märker när den slutar fungera. ]]
function Belysning.start(): string
	local modell = workspace:FindFirstChild(ANLAGGNING)
	local ubrf = modell and modell:FindFirstChild("UBRF")
	if not ubrf then
		warn("[Ljus] Anläggningen är inte byggd — ingen belysning tänd.")
		return "ingen anläggning"
	end

	local rakna: { [string]: number } = {}
	for _, d in ipairs(ubrf:GetDescendants()) do
		if d:IsA("BasePart") then
			local t = typFor(d.Name)
			if t then
				tand(d, t)
				local nyckel = if d.Name:sub(1, 6) == "Lysrör" then "Lysrör" else d.Name
				rakna[nyckel] = (rakna[nyckel] or 0) + 1
			end
		end
	end

	local n = rivFyllnad(ubrf)

	--[[ Golvet lyfts; himlens bidrag utomhus rörs inte. ]]
	local fore = Lighting.Ambient
	Lighting.Ambient = Belysning.AMBIENT

	local rader = {}
	for namn, antal in pairs(rakna) do table.insert(rader, ("%s %d"):format(namn, antal)) end
	table.sort(rader)
	local sammanfattning = ("%s · %d gamla fyllnadsljus rivna · Ambient %s -> %s (OutdoorAmbient orörd %s)"):format(
		table.concat(rader, ", "), n, tostring(fore), tostring(Lighting.Ambient),
		tostring(Lighting.OutdoorAmbient))
	print("[Ljus] " .. sammanfattning)
	return sammanfattning
end

return Belysning
