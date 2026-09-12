--!strict
--[[
	UTRUSTNINGEN SOM FYSISKA DELAR — sadel, underlägg, träns och tyglar.

	Blockerare 5 i #162. Före den här modulen betydde "sadlad" exakt två
	booleans i en Lua-tabell: `state.gjorda["iordning"]["utr:2"] = true`.
	Ingen del skapades, inget attribut sattes på hästen, och
	uppsittningsgrinden kunde inte pröva något annat än att booleanen fanns.
	En häst som aldrig sett en sadel satt man upp på precis som en sadlad.

	GEOMETRIN ÄR PROTOTYP, OCH DET ÄR MEDVETET. Lådor i rätt storlek på rätt
	ställe, i läderfärg. `HORSE_VISUAL_QUALITY_GATE` byter ut hästen och
	utrustningen tillsammans; att göra vacker sadel åt en låd-häst vore att
	polera fel sak. Det som MÅSTE vara rätt nu är läget och fästet.

	MODULEN VET INGENTING OM HÄSTENS MODELLSTRUKTUR. Den frågar
	`RigAdapter.tackfaste(rig, "sadel")` efter en anatomisk plats och
	svetsar i den punktens VÄRDDEL. Därför följer tränset huvudet när
	hästen sänker det, och därför fungerar hela filen oförändrad den dag
	riggen byts mot ett riktigt nät: den nya riggen behöver bara bära samma
	fyra fästpunkter på rätt kroppsdelar.

	INGEN DEL KOLLIDERAR. Utrustning ska inte kunna knuffa hästen, fastna i
	en boxdörr eller ändra hennes kollisionshölje — lokomotionen är låst och
	får inte påverkas av att hon blir sadlad.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RigAdapter = require(ReplicatedStorage.HorseCore.RigAdapter)
local Types = require(ReplicatedStorage.HorseCore.Types)

local TackRigg = {}

local M = 3   -- studs per meter, som BuildKit.M

local LADER      = Color3.fromRGB(96, 61, 36)
local LADER_MORK = Color3.fromRGB(64, 41, 25)
local FILT       = Color3.fromRGB(226, 222, 212)
local METALL     = Color3.fromRGB(176, 178, 182)

--[[ Varje del bär vem den tillhör. Attributen är den fysiska världens
	egen sanning: `TackService` läser DEM, inte en tabell vid sidan av. ]]
export type Tackdel = {
	typ: string,      -- "underlagg" | "sadel" | "trans" | "tygel"
	hastId: string,   -- vilken häst utrustningen tillhör
}

local function del(foralder: Instance, namn: string, storlek: Vector3,
	cf: CFrame, farg: Color3, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = namn
	p.Size = storlek
	p.CFrame = cf
	p.Color = farg
	p.Material = material or Enum.Material.Leather
	p.Anchored = false
	--[[ Utrustning kolliderar ALDRIG. Se filhuvudet. ]]
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = foralder
	return p
end

local function svets(a: BasePart, b: BasePart, namn: string)
	local w = Instance.new("WeldConstraint")
	w.Name = namn
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

--[[ Mappen som håller en hästs utrustning. En per häst, skapad först när
	något faktiskt sätts på — en tom mapp är inte ett tillstånd. ]]
function TackRigg.mapp(modell: Model, skapa: boolean?): Folder?
	local f = modell:FindFirstChild("Tack")
	if f and f:IsA("Folder") then return f end
	if not skapa then return nil end
	local ny = Instance.new("Folder")
	ny.Name = "Tack"
	ny.Parent = modell
	return ny
end

--[[ Hittar en påsatt del av en viss typ. Läser VÄRLDEN. ]]
function TackRigg.hittaDel(modell: Model, typ: string): BasePart?
	local f = TackRigg.mapp(modell)
	if not f then return nil end
	for _, d in ipairs(f:GetChildren()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFTack") == typ then
			return d
		end
	end
	return nil
end

--[[ ══ BYGGARNA ══════════════════════════════════════════════════════

	Var och en tar riggen, hittar sin anatomiska punkt och svetsar i den
	punktens värddel. Svarar nil när punkten saknas — en rigg utan
	huvudpunkt ska ge ett tydligt nej. ]]

local function fastOch(rig: Types.Rig, plats: string): (Attachment?, BasePart?)
	local a = RigAdapter.tackfaste(rig, plats)
	if not a then return nil, nil end
	local vard = a.Parent
	if not (vard and vard:IsA("BasePart")) then return nil, nil end
	return a, vard
end

--[[ ══ VARFÖR GJORD OCH NOSGRIMMA ÄR RINGAR ══════════════════════════

	Gjorden var en kloss under bålen och nosgrimman en stång tvärs över
	nosen. På lådhästen gick det an — en låda har inga rundningar att
	följa. På ett nät läser samma kloss som en planka genom kinden, och
	det är precis vad den visuella granskningen såg.

	Ett band som går RUNT något kan inte byggas av en del: en `Part` är
	rät. Det byggs av segment längs en ellips, och varje segment läggs
	TANGENTIELLT. Det sista är hela skillnaden — en ring av klossar som
	alla pekar utåt blir en solros, inte en gjord.

	`vinkel` mäts från ovansidans mitt och går medurs sett framifrån, så
	0 är ryggen/nosryggen och π är buken/hakan. Det gör det möjligt att
	HOPPA ÖVER ett stycke: gjorden ska inte gå tvärs igenom sadeln. ]]
local function ringsegment(f: Folder, namn: string, mitt: CFrame, vinkel: number,
	rx: number, ry: number, steg: number, tjocklek: number, bredd: number,
	farg: Color3, material: Enum.Material?): BasePart
	--[[ Segmentets längd räknas ur vinkelsteget gånger medelradien, med
		lite överlapp — annars glipar ringen mellan segmenten. ]]
	local langd = steg * ((rx + ry) / 2) * 1.25
	local p = del(f, namn, Vector3.new(langd, tjocklek, bredd),
		mitt * CFrame.new(math.sin(vinkel) * rx, math.cos(vinkel) * ry, 0)
			* CFrame.Angles(0, 0, -vinkel),
		farg, material)
	return p
end

--[[ En del som SPÄNNER mellan två punkter i ett lokalt rum: kindstycke,
	tygel, stigläder. Att rita dem som lådor med gissad längd var det som
	gjorde tränset till lösa stänger under hakan. ]]
local function spann(f: Folder, namn: string, rum: CFrame, fran: Vector3,
	till: Vector3, tjocklek: number, farg: Color3): BasePart?
	local d = till - fran
	local langd = d.Magnitude
	if langd < 1e-3 then return nil end
	local mitt = rum * ((fran + till) / 2)
	local riktning = rum * till
	return del(f, namn, Vector3.new(tjocklek, tjocklek, langd),
		CFrame.lookAt(mitt, riktning), farg)
end

--[[ ══ BÅLENS MÅTT ══════════════════════════════════════════════════

	Talen är uppmätta på K3 i spel och uttryckta RELATIVT sadelpunkten,
	inte i absoluta studs — en mindre häst får då en mindre gjord utan
	att någon skriver om filen.

	    ryggen (sadelpunkten)   y =  0
	    buken                   y = -1,88 studs
	    bålens bredd            x = ±0,86 studs

	Mätt genom nätets utsträckning i rotens rum: x −0,91..0,91,
	hovarna på y −3,18, och en ponnys bukfrihet på 0,62 m. ]]
local BAL_HALVBREDD = 0.80        -- studs, gjordens sidoradie
local BAL_MITT      = -1.10       -- studs under sadelpunkten
local BAL_HALVHOJD  = 0.98        -- studs, gjordens höjdradie

--[[ UNDERLÄGGET ligger under sadeln, högt på manken. Egen del därför att
	kanon har det som ett eget moment: "Lägg underlägget högt på manken
	och skjut det bakåt i hårets riktning."

	Det är två delar nu: ryggpanelen som förut, plus två FLIKAR som faller
	längs bålen. Utan flikarna syntes underlägget bara som en ljus strimma
	i sadelns kant; ett schabrak är just det som sticker fram under
	sadelns sidoflikar. ]]
function TackRigg.byggUnderlagg(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local a, vard = fastOch(rig, "sadel")
	if not (a and vard) then return nil end
	local f = TackRigg.mapp(modell, true) :: Folder
	local bas = a.WorldCFrame
	local p = del(f, "Underlägg",
		Vector3.new(0.44 * M, 0.022 * M, 0.60 * M),
		bas * CFrame.new(0, 0.010 * M, 0.01 * M),
		FILT, Enum.Material.Fabric)
	p:SetAttribute("UBRFTack", "underlagg")
	p:SetAttribute("ForHast", hastId)
	svets(vard, p, "TackWeld")
	for _, sida in ipairs({ -1, 1 }) do
		--[[ Fliken ligger INNANFÖR sadelns flik och sticker ut en aning
			nedanför och bakom den — det är så ett schabrak syns. Första
			måtten (0,26 x 0,68 m på ±0,24) gav i stället en vit skiva som
			var längre än sadeln och dolde henne helt. ]]
		local flik = del(f, "Underläggets flik",
			Vector3.new(0.020 * M, 0.22 * M, 0.52 * M),
			bas * CFrame.new(sida * 0.27 * M, -0.10 * M, 0.01 * M)
				* CFrame.Angles(0, 0, sida * math.rad(5)),
			FILT, Enum.Material.Fabric)
		svets(p, flik, "TackWeld")
	end
	return p
end

--[[ SADELN sitter ovanpå underlägget, bakom bogbladet: sits, framvalv,
	bakvalv, två sidoflikar, en gjord RUNT bålen och stigläder med byglar.

	Allt utom sitsen är namnlöst i `UBRFTack`-mening och svetsat i sitsen.
	Det är `taAv`:s kontrakt: den bärande delen tas, och med den allt utan
	eget `UBRFTack` som hänger i henne. ]]
function TackRigg.byggSadel(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local a, vard = fastOch(rig, "sadel")
	if not (a and vard) then return nil end
	local f = TackRigg.mapp(modell, true) :: Folder
	local bas = a.WorldCFrame * CFrame.new(0, 0.055 * M, 0)

	local sits = del(f, "Sadel",
		Vector3.new(0.40 * M, 0.055 * M, 0.46 * M), bas, LADER)
	sits:SetAttribute("UBRFTack", "sadel")
	sits:SetAttribute("ForHast", hastId)
	svets(vard, sits, "TackWeld")
	local function ihop(d: BasePart?) if d then svets(sits, d, "TackWeld") end end

	--[[ FRAMVALVET lutar framåt över manken och BAKVALVET reser sig bakåt.
		Lutningen är det som gör att en låda läses som en sadel — en rät
		kloss i var ände läser som en låda med två mindre lådor på. ]]
	ihop(del(f, "Sadelns framvalv", Vector3.new(0.32 * M, 0.13 * M, 0.07 * M),
		bas * CFrame.new(0, 0.055 * M, -0.215 * M) * CFrame.Angles(math.rad(-20), 0, 0),
		LADER_MORK))
	ihop(del(f, "Sadelns bakvalv", Vector3.new(0.36 * M, 0.10 * M, 0.08 * M),
		bas * CFrame.new(0, 0.045 * M, 0.215 * M) * CFrame.Angles(math.rad(18), 0, 0),
		LADER_MORK))
	--[[ SIDOFLIKARNA hänger ned över bålen, där ryttarens ben ligger. ]]
	for _, sida in ipairs({ -1, 1 }) do
		--[[ ±0,19 m la fliken INNE i bålen: uppmätt är hästen 0,86 studs
			halvbred vid sadeln, och 0,19 m är 0,57 studs. Den ligger nu
			utanpå kroppen, strax utanför underläggets flik. ]]
		ihop(del(f, "Sadelns flik", Vector3.new(0.026 * M, 0.20 * M, 0.44 * M),
			bas * CFrame.new(sida * 0.275 * M, -0.11 * M, 0),
			LADER))
	end

	--[[ GJORDEN: en RING runt bålen, inte en kloss under den. Segmenten
		täcker 36°..324° — hela varvet utom ryggens topp, där sadeln
		redan ligger. Radierna är bålens uppmätta, se konstanterna ovan. ]]
	local gjordMitt = bas * CFrame.new(0, BAL_MITT, -0.09 * M)
	local steg = math.rad(32)
	for i = 1, 10 do
		ihop(ringsegment(f, "Sadelns gjord", gjordMitt, math.rad(36) + (i - 1) * steg,
			BAL_HALVBREDD, BAL_HALVHOJD, steg, 0.035 * M, 0.11 * M,
			LADER_MORK, nil))
	end

	--[[ STIGLÄDER och BYGEL. Lädret spänner från sadelns sida ned till
		bygelpunkten — samma punkt ryttarens fot söker — så att bygeln
		hamnar där foten faktiskt hamnar i stället för bredvid den. ]]
	for _, plats in ipairs({ { "bygelV", -1 }, { "bygelH", 1 } }) do
		local bygelA = RigAdapter.tackfaste(rig, plats[1] :: string)
		local sida = plats[2] :: number
		local topp = Vector3.new(sida * 0.27 * M, -0.03 * M, -0.02 * M)
		local botten = if bygelA
			then bas:PointToObjectSpace(bygelA.WorldPosition)
			else Vector3.new(sida * 0.20 * M, -0.36 * M, -0.02 * M)
		ihop(spann(f, "Stigläder", bas, topp, botten + Vector3.new(0, 0.05 * M, 0),
			0.026 * M, LADER_MORK))
		ihop(del(f, "Stigbygel", Vector3.new(0.11 * M, 0.11 * M, 0.035 * M),
			bas * CFrame.new(botten), METALL, Enum.Material.Metal))
	end
	return sits
end

--[[ TRÄNSET sitter på HUVUDET, inte på bålen.

	══ VARFÖR MÅTTEN KOMMER UR BETTET ═════════════════════════════════

	Den gamla versionen byggde tränset i absoluta meter: ett nackstycke
	0,30 m brett och en nosgrimma 0,32 m. Uppmätt på K3 är hela huvudet
	0,759 studs brett — alltså 0,25 m. Nosgrimman var mer än en och en
	tredjedels HUVUDBREDD bred. Det är den bruna plankan tvärs genom
	kinden som granskningen såg, och den var inte ett ritfel utan ett
	skalfel: måtten hörde till lådhästens huvud.

	Nu räknas allt ur två punkter riggen redan bär: `trans` på nosryggen
	och bettet i mungiporna. Avståndet mellan tygelfästena ÄR munnens
	bredd, och avståndet ned till bettet ÄR huvudets längd i den ände
	som betyder något. En häst med annat huvud får rätt träns utan att
	någon rör den här filen.

	    uppmätt K3, i nosryggspunktens rum:
	        bettet   (±0,218 · −0,474 · −0,421) studs ]]
function TackRigg.byggTrans(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local a, vard = fastOch(rig, "trans")
	if not (a and vard) then return nil end
	local bettV = RigAdapter.tackfaste(rig, "tygelV")
	local bettH = RigAdapter.tackfaste(rig, "tygelH")
	local f = TackRigg.mapp(modell, true) :: Folder
	local bas = a.WorldCFrame

	--[[ Munnens bredd och huvudets riktning, ur riggens egna punkter.
		Saknas bettpunkterna faller vi tillbaka på huvuddelens storlek —
		sämre, men aldrig en planka: måtten är fortfarande hästens. ]]
	--[[ HUVUDETS FORM. `HastVisual` mäter hela huvudet när nätet monteras
		och skriver det som attribut i FÄSTPUNKTENS rum; saknas de är
		värddelen hela huvudet, vilket är sant för en lådhäst. ]]
	local hx = vard:GetAttribute("UBRFHuvudX") :: number?
	local hy0 = vard:GetAttribute("UBRFHuvudY0") :: number?
	local hy1 = vard:GetAttribute("UBRFHuvudY1") :: number?
	local hz0 = vard:GetAttribute("UBRFHuvudZ0") :: number?
	local hz1 = vard:GetAttribute("UBRFHuvudZ1") :: number?
	if not (hx and hy0 and hy1 and hz0 and hz1) then
		local mitt = bas:PointToObjectSpace(vard.Position)
		hx = vard.Size.X / 2
		hy0, hy1 = mitt.Y - vard.Size.Y / 2, mitt.Y + vard.Size.Y / 2
		hz0, hz1 = mitt.Z - vard.Size.Z / 2, mitt.Z + vard.Size.Z / 2
	end
	local HX = hx :: number
	local HY0, HY1 = hy0 :: number, hy1 :: number
	local HZ0, HZ1 = hz0 :: number, hz1 :: number

	--[[ MUNNENS halva bredd, ur bettpunkterna. Taket är huvudets egen
		halva bredd: lådriggens bettpunkter ligger i huvudets ytterkanter
		och skulle annars ge ett nackstycke bredare än hästen. ]]
	local hb: number
	local bett: Vector3
	if bettV and bettH then
		local v = bas:PointToObjectSpace(bettV.WorldPosition)
		local h = bas:PointToObjectSpace(bettH.WorldPosition)
		hb = math.max(math.abs(v.X - h.X) / 2, 0.05)
		bett = (v + h) / 2
	else
		hb = HX * 0.4
		bett = Vector3.new(0, HY0 * 0.45, HZ0 * 0.55)
	end
	hb = math.min(hb, HX * 0.45)

	--[[ NACKSTYCKET tvärs över nacken bakom öronen — den del som BÄR hela
		tränset, och den som helt saknades förut. Alla mått nedan är
		andelar av huvudets uppmätta form, inte meter: ett annat huvud får
		ett träns som passar det utan att någon rör den här filen. ]]
	local nack = del(f, "Träns",
		Vector3.new(HX * 1.75, 0.05, 0.14),
		bas * CFrame.new(0, HY1 * 0.55, HZ1 * 0.53), LADER)
	nack:SetAttribute("UBRFTack", "trans")
	nack:SetAttribute("ForHast", hastId)
	svets(vard, nack, "TackWeld")
	local function ihop(d: BasePart?) if d then svets(nack, d, "TackWeld") end end

	--[[ PANNBANDET tvärs över pannan, framför nackstycket. ]]
	ihop(del(f, "Tränsets pannband", Vector3.new(HX * 1.72, 0.06, 0.06),
		bas * CFrame.new(0, HY1 * 0.46, HZ1 * 0.12), LADER_MORK))

	--[[ KINDSTYCKENA SPÄNNER från nackstyckets ändar ned till bettet. Att
		rita dem som lådor med gissad längd var det som gav de lösa
		stängerna under hakan. ]]
	for _, sida in ipairs({ -1, 1 }) do
		ihop(spann(f, "Tränsets kindstycke", bas,
			Vector3.new(sida * HX * 0.74, HY1 * 0.51, HZ1 * 0.48),
			Vector3.new(sida * hb * 1.05, bett.Y, bett.Z), 0.05, LADER))
	end

	--[[ NOSGRIMMAN som en RING runt nosen, strax ovanför bettet. ]]
	local nosMitt = bas * CFrame.new(0,
		bett.Y + HY1 * 0.25,
		bett.Z + HZ0 * 0.11)
	local steg = math.rad(45)
	for i = 1, 8 do
		ihop(ringsegment(f, "Tränsets nosgrimma", nosMitt, math.rad(22.5) + (i - 1) * steg,
			HX * 0.63, HY1 * 0.55, steg, 0.04, 0.09, LADER, nil))
	end

	--[[ HAKREMMEN under käken, bakom nosgrimman. ]]
	ihop(del(f, "Tränsets hakrem", Vector3.new(HX * 1.40, 0.045, 0.045),
		bas * CFrame.new(0, bett.Y + HY0 * 0.07, HZ1 * 0.30), LADER_MORK))
	return nack
end

--[[ TYGLARNA går från bettet i mungiporna BAKÅT TILL RYTTARENS HÄNDER.
	De hänger i HUVUDET, så de följer med när hon sänker det.

	Förut ritades de som två lådor 0,70 m långa rakt bakåt från bettet —
	de slutade i luften. Nu spänner de mellan bettet och handläget
	(`handV`/`handH`), samma punkt som ryttarens hand-IK siktar på. Saknas
	handpunkterna faller tygeln tillbaka på en punkt framför och ovanför
	sadeln, alltså där en hand HADE varit. ]]
function TackRigg.byggTyglar(modell: Model, rig: Types.Rig, hastId: string): BasePart?
	local vansterA, vard = fastOch(rig, "tygelV")
	local hogerA = RigAdapter.tackfaste(rig, "tygelH")
	if not (vansterA and hogerA and vard) then return nil end
	local f = TackRigg.mapp(modell, true) :: Folder
	--[[ HÖGER TYGEL SVETSAS I VÄNSTER, inte i huvudet.

		Fysiskt är det samma sak — vänster tygel sitter i sin tur i huvudet
		— men `taAv` river en typ genom att ta den BÄRANDE delen och allt
		utan eget `UBRFTack` som är svetsat i HENNE. Satt höger tygel i
		huvudet blev den aldrig upphämtad: den överlevde avtagningen och
		hängde kvar i luften vid hästens mun, och nästa tränsning byggde
		ett nytt par ovanpå den.

		Hittat i den kanoniska genomspelningen efter blockerare 5, när
		tränset revs och sattes på igen: 13 delar in, 14 delar ut. ]]
	--[[ Var tygeln SLUTAR: ryttarens hand om riggen bär punkten, annars en
		punkt framför och ovanför sadeln — där en hand hade varit. ]]
	local sadelA = RigAdapter.tackfaste(rig, "sadel")
	local function slut(namn: string, sida: number): Vector3
		local hand = RigAdapter.tackfaste(rig, namn)
		if hand then return hand.WorldPosition end
		if sadelA then
			return (sadelA.WorldCFrame * CFrame.new(sida * 0.10 * M, 0.62, -0.62)).Position
		end
		return (vansterA :: Attachment).WorldCFrame.Position + Vector3.new(0, 0.3 * M, 0)
	end

	local forsta: BasePart? = nil
	for _, par in ipairs({ { vansterA, "handV", -1 }, { hogerA, "handH", 1 } }) do
		local a = par[1] :: Attachment
		local fran = a.WorldPosition
		local till = slut(par[2] :: string, par[3] :: number)
		--[[ Faller punkterna ihop finns ingen riktning att se mot, och
			`CFrame.lookAt` kastar. En kort stump bakåt är rätt svar. ]]
		if (till - fran).Magnitude < 1e-3 then till = fran + Vector3.new(0, 0, 0.5) end
		local langd = (till - fran).Magnitude
		--[[ EN del hela vägen. Två segment hade lästs som ett brott mitt på
			tygeln, och tygeln är just det som ska se obruten ut. ]]
		local tygel = del(f, "Tygel",
			Vector3.new(0.022 * M, 0.022 * M, langd),
			CFrame.lookAt((fran + till) / 2, till), LADER_MORK)
		if forsta then
			svets(forsta, tygel, "TackWeld")
		else
			svets(vard, tygel, "TackWeld")
			forsta = tygel
			tygel:SetAttribute("UBRFTack", "tygel")
			tygel:SetAttribute("ForHast", hastId)
		end
	end
	return forsta
end

TackRigg.BYGGARE = {
	underlagg = TackRigg.byggUnderlagg,
	sadel = TackRigg.byggSadel,
	trans = TackRigg.byggTrans,
	tygel = TackRigg.byggTyglar,
}

--[[ Tar av en typ, med allt som hänger i den. Sadeln tar sina valv, sin
	gjord och sina stigbyglar med sig — de är svetsade i henne. ]]
function TackRigg.taAv(modell: Model, typ: string): boolean
	local f = TackRigg.mapp(modell)
	if not f then return false end
	local bar = TackRigg.hittaDel(modell, typ)
	if not bar then return false end
	--[[ Delar utan eget `UBRFTack` hör till den bärande delen de är
		svetsade i. De rivs med den. ]]
	local rivs = { bar }
	for _, d in ipairs(f:GetChildren()) do
		if d:IsA("BasePart") and d:GetAttribute("UBRFTack") == nil then
			local w = d:FindFirstChildOfClass("WeldConstraint")
			if w and w.Part0 == bar then table.insert(rivs, d) end
		end
	end
	for _, d in ipairs(rivs) do d:Destroy() end
	if #f:GetChildren() == 0 then f:Destroy() end
	return true
end

return TackRigg
