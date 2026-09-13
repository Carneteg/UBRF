--!nostrict
--[[ PEKRIDNINGENS KONTRAKT — den RIKTIGA `TouchControls.mount()` i bänken

	Order 2026-09-13 13:21, TOUCH-MOUNTED CONTROL CONTRACT, punkt 1–8.

	`touch.spec` mäter de rena funktionerna (`axis`, `Input`-maskinen), och
	`flerspelare.spec` §2 monterar reglagen mot en FALSK `Input`-tabell för
	att mäta blickytans geometri. Ingen spec har hittills tryckt på en
	riktig knapp i det riktiga gallret och sett hästen svara. Det är vad
	den här gör, och den gör det genom klientens egen loop:

	    MountChanged ──▶ init.client.mount ──▶ TouchControls.mount(Input, …)
	    knapp.MouseButton1Click / spakens InputBegan ──▶ Input.*
	    RenderStepped ──▶ Input.consume() ──▶ MovementController:step()

	Provet anropar ALDRIG `Input.consume`, `movement:step` eller
	`TouchControls.mount` självt under en ritt. De tre observeras i stället
	på produktionens egna anropsplatser — omslag som skickar vidare och
	antecknar — så att det som mäts är exakt vad spelaren får.

	══ VAD BÄNKEN INTE KAN SÄGA (HARDWARE CHECK) ═══════════════════════

	  · Träffprovet. Roblox avgör vilken GuiObject som får ett finger;
	    stubben har ingen sådan routing. Att en knapp tar sitt finger FÖRE
	    blickytan mäts därför som STAPLINGSKONTRAKT (syskonordning,
	    ZIndex, DisplayOrder), inte som ett tryck.
	  · Riktig multitouch. Två `InputObject` i bänken är två tabeller; att
	    iOS/Android levererar dem som två spår är hårdvarans sak.
	  · Känsla: knappstorlek under tummen, spakens tröghet, kamerans
	    hastighet per dragen pixel.

	Kör: python3 roblox/tests/build.py tests/pekridning.spec.luau
	     && luau roblox/tests/.build/pekridning.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

print("\nPEKRIDNINGENS KONTRAKT — RIKTIG mount() GENOM KLIENTENS LOOP\n")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local usv = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local cam = game:GetService("Workspace").CurrentCamera
local player = Players.LocalPlayer
local Net = Networking

--[[ Skärmar familjen faktiskt spelar på, samma tal som `mobillayout.spec`
	och `KontrollHjalp`. Höjden är VYPORTEN; GUI-ytan är 36 px lägre för
	varje ScreenGui som inte ignorerar topbaren — och det gör varken
	pekreglagen eller `?`-knappen. ]]
local SKARMAR = {
	{ namn = "iPhone landskap", B = 749, H = 309 },
	{ namn = "iPad landskap", B = 1194, H = 761 },
}
local INSET = GuiService:GetGuiInset().Y

--[[ ── En pekenhet ────────────────────────────────────────────────── ]]
usv.TouchEnabled = true
local pg = Instance.new("PlayerGui")
pg.Name = "PlayerGui"
player._barn = { pg }
--[[ `?`-knappen byggs bara när inmatningen behöver den; på en riktig
	telefon är `TouchEnabled` sant redan vid start, så modulen startas om
	här — samma beslut `KontrollHjalp.start` gör i produktion. ]]
KontrollHjalp.start()

local hast = __makeHastModell("Bamse")
hast.Parent = workspace
local hum = hast:FindFirstChild("Humanoid")
prova("bänken har en häst klienten kan bygga en rigg av",
	select(1, RigAdapter.build(hast)) ~= nil)

local avsittningar = 0
local fjarr = Net.get("DismountRequest")
fjarr.InvokeServer = function() avsittningar += 1; return true end

--[[ ── Observatörer på produktionens anropsplatser ─────────────────
	Omslagen SKICKAR VIDARE. De ändrar varken argument eller returvärde;
	de antecknar bara vad som passerade. ]]
local senaste = nil
local origConsume = Input.consume
Input.consume = function()
	local i = origConsume()
	senaste = i
	return i
end
local rorelse = nil
local origStep = MovementController.step
MovementController.step = function(self, intent, dt)
	rorelse = self
	return origStep(self, intent, dt)
end
local blickar = {}
local origBlick = CameraController.vridBlick
CameraController.vridBlick = function(self, dYaw, dPitch)
	table.insert(blickar, { dYaw, dPitch })
	return origBlick(self, dYaw, dPitch)
end

--[[ ── Sökning och geometri ───────────────────────────────────────── ]]
local function sok(nod, namn)
	if type(nod) ~= "table" then return nil end
	if nod.Name == namn then return nod end
	for _, b in ipairs(rawget(nod, "_barn") or {}) do
		local t = sok(b, namn)
		if t then return t end
	end
	return nil
end
local function hittaHud(namn) return sok(player._gui, namn) end
local function hittaPek(namn) return sok(pg, namn) end

local function skarmGui(o)
	local n = o
	while type(n) == "table" and rawget(n, "ClassName") ~= "ScreenGui" do
		n = n.Parent
	end
	return if type(n) == "table" then n else nil
end

--[[ Rektangel i SKÄRMPIXLAR. `AbsolutePosition` räknas från GUI-ytans
	origo, och den ligger 36 px ned för en ScreenGui som respekterar
	topbaren. Två ytor i olika ScreenGui jämförs därför först när båda
	flyttats till samma rum. [antagande] att `AbsolutePosition` exkluderar
	inseten (Robloxs `Mouse`-rum) är läst ur dokumentationen, inte mätt i
	Studio. Pekreglagen och `?`-knappen delar inställning, så DERAS
	jämförelse hänger inte på antagandet. ]]
local function rekt(o)
	local p, s = o.AbsolutePosition, o.AbsoluteSize
	local g = skarmGui(o)
	local dy = if g and rawget(g, "IgnoreGuiInset") == true then 0 else INSET
	return { x0 = p.X, y0 = p.Y + dy, x1 = p.X + s.X, y1 = p.Y + s.Y + dy,
		namn = o.Name }
end
local function overlappar(a, b)
	return a.x0 < b.x1 - 0.01 and a.x1 > b.x0 + 0.01
		and a.y0 < b.y1 - 0.01 and a.y1 > b.y0 + 0.01
end
local function synlig(o)
	local n = o
	while type(n) == "table" and rawget(n, "ClassName") ~= "ScreenGui" do
		if n.Visible == false then return false end
		n = n.Parent
	end
	return type(n) == "table" and n.Enabled ~= false
end

local KNAPPAR = { "Halt", "Skritt", "Trav", "Galopp", "Sakta",
	"Tygel", "Sits", "Parad", "Hoppa", "Av" }

--[[ ── Bildrutor genom klientens loop ─────────────────────────────── ]]
local dt = 1 / 30
--[[ Kvitterar ett väntande lektionskort med FINGRET: knappens eget
	`Activated`, som ett tryck. Ingen tangent, inget direktanrop. ]]
local function kvittera()
	for _, namn in { "UgnetaKnapp", "Knapp", "GaVidare" } do
		local kn = hittaHud(namn)
		if kn and kn.Visible and kn.Activated then
			kn.Activated:Fire()
			return true
		end
	end
	return false
end
--[[ Rider `sek` sekunder. `WalkSpeed` — produktionens enda väg ut mot
	Roblox humanoid — samlas bara i bildrutor där lektionen INTE pausar:
	pausens `release()` nollar den, och en nolla därifrån är inte en halt.
	`prov` får varje sådan bildruta för egna avläsningar. ]]
local function rid(sek, prov)
	local st = { max = 0, min = math.huge, n = 0, pausade = 0, kort = 0 }
	for _ = 1, math.floor(sek / dt + 0.5) do
		if LektionController.vantar() and kvittera() then st.kort += 1 end
		RunService.RenderStepped:Fire(dt)
		if LektionController.vantar() then
			st.pausade += 1
		else
			st.n += 1
			local ws = hum.WalkSpeed
			st.max = math.max(st.max, ws)
			st.min = math.min(st.min, ws)
			if prov then prov(st) end
		end
	end
	return st
end

local function sittUpp(skarm)
	cam.ViewportSize = { _typ = "Vector2", X = skarm.B, Y = skarm.H }
	blickar = {}
	Net.get("MountChanged").OnClientEvent:Fire(hast, player)
	return hittaPek("HorseTouch")
end
local function sittAv(gui)
	local av = gui and sok(gui, "Av")
	if av then av.MouseButton1Click:Fire() end
end

--[[ Ett finger. Samma tabell genom Began/Changed/Ended — det är
	identiteten `TouchControls` jämför på. ]]
local function finger(x, y)
	return { UserInputType = Enum.UserInputType.Touch, Position = Vector2.new(x, y) }
end
local function spakCentrum(gui)
	local spak = sok(gui, "Spak")
	local p, s = spak.AbsolutePosition, spak.AbsoluteSize
	return p.X + s.X / 2, p.Y + s.Y / 2, spak
end

--[[ ══ 1. LAYOUTEN PÅ TVÅ SKÄRMAR ══════════════════════════════════ ]]
for _, skarm in SKARMAR do
	print(("\n── 1. %s (%d×%d, GUI-höjd %d) ──"):format(skarm.namn, skarm.B,
		skarm.H, skarm.H - INSET))
	local gui = sittUpp(skarm)
	prova("HorseTouch byggdes vid uppsittningen", gui ~= nil)
	if not gui then break end

	prova("Roblox egna pekreglage är släckta under ritten (ModalEnabled)",
		usv.ModalEnabled == true, tostring(usv.ModalEnabled))

	--[[ FÖRSTA uppsittningen öppnar hjälppanelen av sig själv, och medan
		den står uppe är `?`-knappen gömd. Ridläget som VARAR är det med
		panelen stängd och `?` uppe — det är det som mäts. Panelen stängs
		som spelaren gör det: med sin egen Stäng-knapp. ]]
	local stang = hittaHud("StangHjalp")
	if stang and KontrollHjalp.synlig() then stang.Activated:Fire() end
	prova("hjälppanelen är stängd och ?-knappen uppe under mätningen",
		KontrollHjalp.synlig() == false and KontrollHjalp._oppnaKnapp() ~= nil
			and KontrollHjalp._oppnaKnapp().Visible == true)

	--[[ Kortet kommer en bildruta in. Rid tills det står uppe, UTAN att
		kvittera, så att knappraden kan mätas mot det. ]]
	for _ = 1, 10 do
		if LektionController.vantar() then break end
		RunService.RenderStepped:Fire(dt)
	end
	local kort = hittaHud("Kort")
	prova("lektionskortet står uppe medan layouten mäts",
		LektionController.vantar() and kort ~= nil and kort.Visible == true)

	local rekter = {}
	local saknas = {}
	for _, namn in KNAPPAR do
		local k = sok(gui, namn)
		if k and k.ClassName == "TextButton" then
			table.insert(rekter, rekt(k))
		else
			table.insert(saknas, namn)
		end
	end
	prova("alla tio knappar finns som TextButton", #saknas == 0,
		if #saknas > 0 then "saknas: " .. table.concat(saknas, ", ") else "10/10")

	local cx, cy, spak = spakCentrum(gui)
	local spakR = rekt(spak)
	local blick = rekt(sok(gui, "Blickyta"))

	--[[ Innanför GUI-ytan: 0..B i sidled, inset..H i höjdled. ]]
	local utanfor, minB, minH = {}, math.huge, math.huge
	for _, r in rekter do
		if r.x0 < -0.5 or r.y0 < INSET - 0.5 or r.x1 > skarm.B + 0.5
			or r.y1 > skarm.H + 0.5 then
			table.insert(utanfor, ("%s(%d..%d·%d..%d)"):format(r.namn, r.x0, r.x1, r.y0, r.y1))
		end
		minB = math.min(minB, r.x1 - r.x0)
		minH = math.min(minH, r.y1 - r.y0)
	end
	prova("varje knapp ligger helt innanför skärmen", #utanfor == 0,
		if #utanfor > 0 then table.concat(utanfor, " ") else
			("(minsta knapp %d×%d px)"):format(minB, minH))

	--[[ Knapparna får inte ligga på varandra, och inte på spaken. ]]
	local dubbla = {}
	local alla = table.clone(rekter)
	table.insert(alla, spakR)
	for i = 1, #alla do
		for j = i + 1, #alla do
			if overlappar(alla[i], alla[j]) then
				table.insert(dubbla, alla[i].namn .. "/" .. alla[j].namn)
			end
		end
	end
	prova("ingen knapp överlappar en annan knapp eller spaken", #dubbla == 0,
		if #dubbla > 0 then table.concat(dubbla, " ") else "(11 ytor)")

	local vansterom = 0
	for _, r in rekter do
		if r.x0 < spakR.x1 then vansterom += 1 end
	end
	prova("hela knappraden ligger till höger om spaken", vansterom == 0,
		("(spakens högerkant %d)"):format(spakR.x1))

	--[[ Lektionskortet — samma skärm, samma ögonblick. ]]
	if kort then
		local kr = rekt(kort)
		local overKort = {}
		for _, r in rekter do
			if overlappar(r, kr) then table.insert(overKort, r.namn) end
		end
		prova("lektionskortet täcker ingen knapp", #overKort == 0,
			if #overKort > 0 then table.concat(overKort, ", ") else
				("(kort x %d..%d · y %d..%d)"):format(kr.x0, kr.x1, kr.y0, kr.y1))
	end

	--[[ ANDRA TRYCKBARA YTOR som klienten ritar samtidigt — `?`-knappen,
		skötselspåraren, vad som än är synligt. En knapp som ligger under
		en annan ScreenGui med högre DisplayOrder går inte att träffa. ]]
	local andra = {}
	local function samla(nod)
		if type(nod) ~= "table" then return end
		local klass = rawget(nod, "ClassName")
		if (klass == "TextButton" or klass == "ImageButton") and synlig(nod) then
			local r = rekt(nod)
			if r.x1 > r.x0 and r.y1 > r.y0 then table.insert(andra, r) end
		end
		for _, b in ipairs(rawget(nod, "_barn") or {}) do samla(b) end
	end
	samla(player._gui)
	for _, a in andra do
		print(("  info annan tryckbar yta %-12s x %4d..%4d · y %4d..%4d"):format(
			a.namn, a.x0, a.x1, a.y0, a.y1))
	end
	local skymda = {}
	for _, r in rekter do
		for _, a in andra do
			if overlappar(r, a) then
				table.insert(skymda, ("%s under %s(%d..%d·%d..%d)"):format(
					r.namn, a.namn, a.x0, a.x1, a.y0, a.y1))
			end
		end
	end
	prova("ingen annan tryckbar yta ligger över en reglageknapp", #skymda == 0,
		if #skymda > 0 then table.concat(skymda, "; ") else
			("(%d andra ytor provade)"):format(#andra))

	--[[ Blickytan: knapparna bor ovanpå den, med flit — ett tryck på
		GALOPP ska vara GALOPP. Ordningen som ger det mäts i §7. Här bara
		att ytan verkligen börjar till höger om spaken. ]]
	prova("blickytan börjar till höger om spaken", blick.x0 >= spakR.x1 - 0.01,
		("(blick från %d, spak till %d)"):format(blick.x0, spakR.x1))

	--[[ Spakens ritade radie mot inmatningens. `flytta` klampar mot
		`TouchControls.RADIE` (66) oavsett hur stor cirkeln ritas. ]]
	print(("  info spakens ritade radie %d px · inmatningens radie %d px · minsta knapp %d×%d px"):format(
		(spakR.x1 - spakR.x0) / 2, TouchControls.RADIE, minB, minH))

	kvittera()
	sittAv(gui)
	prova("SITT AV går genom klientens avsittning till servern",
		avsittningar == _ and true or avsittningar >= 1, ("(%d begäran)"):format(avsittningar))
	prova("pekreglagen är rivna efter avsittningen",
		gui.Parent == nil and TouchControls.isActive() == false)
	prova("Roblox egna pekreglage är tillbaka (ModalEnabled false)",
		usv.ModalEnabled == false, tostring(usv.ModalEnabled))
end

--[[ ══ 2. HALT-KNAPPEN HÅLLER NOLL — ÄNDE TILL ÄNDE ═══════════════ ]]
print("\n── 2. HALT genom knappen, spaken och den riktiga loopen (iPhone) ──")
do
	local gui = sittUpp(SKARMAR[1])
	rid(0.2)
	prova("ritten är igång och kortet kvitterat", gui ~= nil
		and LektionController.vantar() == false)

	sok(gui, "Trav").MouseButton1Click:Fire()
	local s1 = rid(2.5)
	prova("TRAV-knappen sätter hästen i rörelse", s1.max > 0.5 and s1.n > 0,
		("(WalkSpeed max %.2f på %d bildrutor)"):format(s1.max, s1.n))

	--[[ Tummen på spaken, fullt framåt: ett finger på spakens yta,
		`TouchControls.RADIE` px rakt upp från mitten. ]]
	local cx, cy, spak = spakCentrum(gui)
	local F1 = finger(cx, cy - TouchControls.RADIE)
	spak.InputBegan:Fire(F1)
	usv.InputChanged:Fire(F1)
	local s2 = rid(0.5)
	prova("spaken framåt ger full framåtavsikt i loopens Intent",
		senaste and senaste.forward > 0.95,
		("(forward %.2f)"):format(senaste and senaste.forward or -9))

	--[[ HALT med tummen kvar på spaken. ]]
	sok(gui, "Halt").MouseButton1Click:Fire()
	local nadde = false
	local s3 = rid(3, function(st) if hum.WalkSpeed == 0 then nadde = true end end)
	local s4 = rid(1.5)
	prova("HALT når noll trots att spaken hålls framåt", nadde,
		("(min %.2f under 3 s)"):format(s3.min))
	prova("…och HÅLLER noll medan tummen ligger kvar", s4.max == 0 and s4.n > 30,
		("(max %.2f på %d bildrutor · forward %.2f · haltLas %s)"):format(
			s4.max, s4.n, senaste.forward, tostring(rorelse and rorelse.haltLas)))
	prova("låset ligger tänt så länge spaken är framme",
		rorelse and rorelse.haltLas == true)

	--[[ Neutral: fingret lyfts. Låset släpper — men hästen står kvar, för
		ingen har bett henne gå. ]]
	usv.InputEnded:Fire(F1)
	local s5 = rid(1)
	prova("släppt spak nollar avsikten", senaste.forward == 0 and senaste.steer == 0,
		("(forward %.2f · steer %.2f)"):format(senaste.forward, senaste.steer))
	prova("neutral spak släpper låset utan att hästen går", s5.max == 0
		and rorelse.haltLas == false,
		("(max %.2f · haltLas %s)"):format(s5.max, tostring(rorelse.haltLas)))

	--[[ Ny framåtbegäran: fingret ned igen. Nu är det en NY begäran. ]]
	local F1b = finger(cx, cy - TouchControls.RADIE)
	spak.InputBegan:Fire(F1b)
	local s6 = rid(2.5)
	prova("nästa framåtutslag startar hästen igen", s6.max > 0.5,
		("(WalkSpeed max %.2f)"):format(s6.max))

	--[[ HALT igen, tummen kvar — och sedan en NAMNGIVEN gångart ovanpå. ]]
	sok(gui, "Halt").MouseButton1Click:Fire()
	rid(3)
	local s7 = rid(1)
	prova("HALT igen håller noll med spaken framme", s7.max == 0 and rorelse.haltLas == true,
		("(max %.2f)"):format(s7.max))
	sok(gui, "Trav").MouseButton1Click:Fire()
	local s8 = rid(2.5)
	prova("TRAV-knappen släpper låset och hästen går igång", s8.max > 0.5
		and rorelse.haltLas == false,
		("(max %.2f · haltLas %s)"):format(s8.max, tostring(rorelse.haltLas)))
	usv.InputEnded:Fire(F1b)
	rid(0.2)

	--[[ ══ 3. TYGELN ÄR ETT HÅLL, INTE EN KNÄPP ═══════════════════════ ]]
	print("\n── 3. Tygel och sits hålls — tryck ned påverkar, släpp nollar ──")
	local tygel, sits = sok(gui, "Tygel"), sok(gui, "Sits")
	local function samlaRein(sek)
		local minR, maxR, minS, maxS = math.huge, -math.huge, math.huge, -math.huge
		rid(sek, function()
			minR, maxR = math.min(minR, senaste.rein), math.max(maxR, senaste.rein)
			minS, maxS = math.min(minS, senaste.seat), math.max(maxS, senaste.seat)
		end)
		return minR, maxR, minS, maxS
	end
	local r0a, r0b = samlaRein(0.5)
	prova("utan tryck är tygeln lös", r0a == 0 and r0b == 0, ("(%.2f..%.2f)"):format(r0a, r0b))
	tygel.MouseButton1Down:Fire()
	local r1a, r1b = samlaRein(1)
	prova("nedtryckt TYGEL ger kontakt 1 i varje bildruta", r1a == 1 and r1b == 1,
		("(%.2f..%.2f)"):format(r1a, r1b))
	tygel.MouseButton1Up:Fire()
	local r2a, r2b = samlaRein(1)
	prova("släppt TYGEL nollar — ingen kvarhängande kontakt", r2a == 0 and r2b == 0,
		("(%.2f..%.2f)"):format(r2a, r2b))
	tygel.MouseButton1Down:Fire()
	samlaRein(0.2)
	tygel.MouseLeave:Fire()
	local r3a, r3b = samlaRein(0.5)
	prova("fingret som glider AV knappen släpper också", r3a == 0 and r3b == 0,
		("(%.2f..%.2f)"):format(r3a, r3b))

	sits.MouseButton1Down:Fire()
	local _, _, s1a, s1b = samlaRein(0.5)
	sits.MouseButton1Up:Fire()
	local _, _, s2a, s2b = samlaRein(0.5)
	prova("DJUP SITS hålls på samma sätt: 1 nedtryckt, 0 släppt",
		s1a == 1 and s1b == 1 and s2a == 0 and s2b == 0,
		("(%.0f..%.0f → %.0f..%.0f)"):format(s1a, s1b, s2a, s2b))

	--[[ Tygeln hålls när ryttaren sitter av: nästa ritt får inte ärva
		kontakten. Mäts genom avsittning + ny uppsittning. ]]
	tygel.MouseButton1Down:Fire()
	samlaRein(0.2)
	sittAv(gui)
	prova("avsittningen river reglagen medan tygeln hölls", TouchControls.isActive() == false)
	local efter = origConsume()
	prova("ingen kvarhängande tygel, spak eller sits efter avsittningen",
		efter.rein == 0 and efter.forward == 0 and efter.steer == 0 and efter.seat == 0,
		("(rein %.2f · forward %.2f · seat %.2f)"):format(efter.rein, efter.forward, efter.seat))
end

--[[ ══ 4. GÅNGARTSKNAPPARNA GÅR SAMMA VÄG SOM TANGENTERNA ═══════════ ]]
print("\n── 4. SKRITT/TRAV/GALOPP/SAKTA/HALT genom den delade avsikten (iPad) ──")
do
	local gui = sittUpp(SKARMAR[2])
	rid(0.2)
	prova("ritten är igång efter ny uppsittning", gui ~= nil
		and LektionController.vantar() == false)

	local function enBildruta()
		if LektionController.vantar() then kvittera() end
		RunService.RenderStepped:Fire(dt)
		return senaste
	end
	local function knappGer(namn, falt, varde)
		sok(gui, namn).MouseButton1Click:Fire()
		local i1 = enBildruta()
		local i2 = enBildruta()
		local traff = i1[falt] == varde
		local impuls = i2[falt] == nil or i2[falt] == false
		prova(("%s → Intent.%s = %s, och bara EN bildruta"):format(namn, falt, tostring(varde)),
			traff and impuls,
			("(%s, sedan %s)"):format(tostring(i1[falt]), tostring(i2[falt])))
	end
	knappGer("Skritt", "gaitTo", "walk")
	knappGer("Trav", "gaitTo", "trot")
	knappGer("Galopp", "gaitTo", "canter")
	knappGer("Halt", "gaitTo", "halt")
	knappGer("Sakta", "gaitDown", true)

	--[[ Tangentbordet skriver i SAMMA Intent-tabell, genom samma
		`Input.consume`. Shift är gångart upp; `__key` går genom den
		bindning `Input.bind()` lade upp vid uppsittningen. ]]
	__key(Enum.KeyCode.LeftShift, true)
	local k1 = enBildruta()
	__key(Enum.KeyCode.LeftShift, false)
	local k2 = enBildruta()
	prova("Shift → Intent.gaitUp en bildruta, samma tabell som knapparna",
		k1.gaitUp == true and k2.gaitUp == false and k1.gaitTo == nil,
		("(%s, sedan %s)"):format(tostring(k1.gaitUp), tostring(k2.gaitUp)))

	--[[ SAMMA UTFALL: knappen TRAV och två Shift ur halt ska landa på
		samma begärda gångart i `MovementController` — det är
		`_targetGait` som gör om båda till en plats i `Gaits.ORDER`. ]]
	sok(gui, "Halt").MouseButton1Click:Fire()
	rid(2)
	sok(gui, "Trav").MouseButton1Click:Fire()
	rid(1.5)
	local viaKnapp = rorelse.loco.beddGangart
	sok(gui, "Halt").MouseButton1Click:Fire()
	rid(2)
	__key(Enum.KeyCode.LeftShift, true); rid(0.2); __key(Enum.KeyCode.LeftShift, false)
	rid(0.2)
	__key(Enum.KeyCode.LeftShift, true); rid(0.2); __key(Enum.KeyCode.LeftShift, false)
	rid(1)
	local viaTangent = rorelse.loco.beddGangart
	prova("TRAV-knappen och Shift×2 ur halt begär samma gångart",
		viaKnapp == "trot" and viaTangent == "trot",
		("(knapp %s · tangent %s)"):format(tostring(viaKnapp), tostring(viaTangent)))

	--[[ Taket är gemensamt: GALOPP-knappen ger canter, och varken den
		eller ännu ett Shift öppnar fyrsprånget. ]]
	sok(gui, "Galopp").MouseButton1Click:Fire()
	rid(1)
	local g1 = rorelse.loco.beddGangart
	__key(Enum.KeyCode.LeftShift, true); rid(0.2); __key(Enum.KeyCode.LeftShift, false)
	rid(1)
	local g2 = rorelse.loco.beddGangart
	prova("GALOPP begär canter och taket SPELBAR_TOPP gäller båda vägarna",
		g1 == "canter" and g2 == "canter" and Gaits.SPELBAR_TOPP == "canter",
		("(knapp %s · +Shift %s)"):format(tostring(g1), tostring(g2)))
	sok(gui, "Sakta").MouseButton1Click:Fire()
	rid(1)
	prova("SAKTA är ett steg ned från den begärda gångarten",
		rorelse.loco.beddGangart == "trot", ("(%s)"):format(tostring(rorelse.loco.beddGangart)))

	--[[ ══ 5. SITT AV — OCH UPP IGEN ═══════════════════════════════════ ]]
	print("\n── 5. SITT AV-knappen och ny uppsittning ──")
	local fore = avsittningar
	sittAv(gui)
	prova("SITT AV-knappen begär avsittning hos servern exakt en gång",
		avsittningar == fore + 1, ("(%d → %d)"):format(fore, avsittningar))
	prova("HorseTouch är borta ur PlayerGui", hittaPek("HorseTouch") == nil)
	local gui2 = sittUpp(SKARMAR[2])
	rid(0.2)
	prova("ny uppsittning bygger nya reglage", gui2 ~= nil and gui2 ~= gui
		and TouchControls.isActive() == true)
	if gui2 then
		sok(gui2, "Trav").MouseButton1Click:Fire()
		local s = rid(2.5)
		prova("och de nya knapparna driver hästen", s.max > 0.5,
			("(WalkSpeed max %.2f)"):format(s.max))
		sittAv(gui2)
	end
end

--[[ ══ 6. BLICKFINGRET ÄGS FÖR SIG ═════════════════════════════════ ]]
print("\n── 6. Blickfingret och spakfingret följs var för sig (iPhone) ──")
do
	local gui = sittUpp(SKARMAR[1])
	rid(0.2)
	local cx, cy, spak = spakCentrum(gui)
	local yta = sok(gui, "Blickyta")
	local yr = rekt(yta)

	local F1 = finger(cx, cy - TouchControls.RADIE)
	spak.InputBegan:Fire(F1)
	rid(0.2)

	--[[ Spakfingret glider in över blickytan INNAN något annat finger
		finns: det är fortfarande spakens finger och får inte bli ett
		blickfinger. Mäts här, med blicken ledig, för att det är då vakten
		`obj == aktivFinger` är det enda som skyddar — med ett blickfinger
		redan nere hade `if blickFinger then return end` tagit fallet och
		provet hade inte kunnat falla (falsifierat: så var det först). ]]
	yta.InputBegan:Fire(F1)
	F1.Position = Vector2.new(cx, cy - TouchControls.RADIE - 10)
	usv.InputChanged:Fire(F1)
	rid(0.1)
	prova("spakens finger tas inte över av blickytan när blicken är ledig",
		#blickar == 0 and senaste.forward > 0.95 and senaste.steer == 0,
		("(blickanrop %d · forward %.2f)"):format(#blickar, senaste.forward))

	local F2 = finger(yr.x0 + 200, yr.y0 + 100 - INSET)
	yta.InputBegan:Fire(F2)
	prova("ett andra finger på blickytan vrider inte kameran vid nedslaget",
		#blickar == 0, ("(%d anrop)"):format(#blickar))

	F2.Position = Vector2.new(F2.Position.X + 50, F2.Position.Y)
	usv.InputChanged:Fire(F2)
	rid(0.1)
	prova("blickfingret som dras åt höger vrider blicken åt höger",
		#blickar == 1 and blickar[1][1] > 0 and math.abs(blickar[1][2]) < 1e-9,
		("(%d anrop · dYaw %.3f · dPitch %.3f)"):format(#blickar,
			blickar[1] and blickar[1][1] or 0, blickar[1] and blickar[1][2] or 0))
	prova("…och spakens avsikt är orörd av det", senaste.forward > 0.95
		and senaste.steer == 0,
		("(forward %.2f · steer %.2f)"):format(senaste.forward, senaste.steer))

	F2.Position = Vector2.new(F2.Position.X, F2.Position.Y + 50)
	usv.InputChanged:Fire(F2)
	prova("dras fingret nedåt sänks blicken", #blickar == 2 and blickar[2][2] < 0,
		("(dPitch %.3f)"):format(blickar[2] and blickar[2][2] or 0))

	--[[ Spakfingret dras åt sidan — styrningen ska följa, blicken inte. ]]
	local n = #blickar
	F1.Position = Vector2.new(cx + TouchControls.RADIE, cy)
	usv.InputChanged:Fire(F1)
	rid(0.1)
	prova("spakfingret styr och rör inte blicken", senaste.steer > 0.9
		and #blickar == n,
		("(steer %.2f · blickanrop %d → %d)"):format(senaste.steer, n, #blickar))

	--[[ Ett tredje finger medan blickfingret är nere: ignoreras. ]]
	local F3 = finger(yr.x0 + 300, yr.y0 + 50 - INSET)
	yta.InputBegan:Fire(F3)
	F3.Position = Vector2.new(F3.Position.X + 80, F3.Position.Y)
	usv.InputChanged:Fire(F3)
	prova("ett tredje finger stjäl inte blicken", #blickar == n,
		("(blickanrop %d)"):format(#blickar))

	--[[ Mus/knapp på ytan är inte ett finger. ]]
	yta.InputBegan:Fire({ UserInputType = Enum.UserInputType.MouseButton1,
		Position = Vector2.new(400, 100) })
	usv.InputEnded:Fire(F2)
	local F2b = finger(yr.x0 + 100, yr.y0 + 60 - INSET)
	yta.InputBegan:Fire(F2b)
	F2b.Position = Vector2.new(F2b.Position.X + 10, F2b.Position.Y)
	usv.InputChanged:Fire(F2b)
	prova("efter släpp kan ett nytt finger ta blicken — och nedslaget rycker inte",
		#blickar == n + 1 and math.abs(blickar[n + 1][1] - 10 * 0.006) < 1e-9,
		("(dYaw %.4f, förväntat 0.0600)"):format(blickar[n + 1] and blickar[n + 1][1] or 0))

	--[[ Blickfingret släpps: spaken ligger kvar. Spaken släpps: nollat. ]]
	usv.InputEnded:Fire(F2b)
	rid(0.1)
	prova("släppt blickfinger lämnar spaken orörd", senaste.steer > 0.9
		and #blickar == n + 1)
	usv.InputEnded:Fire(F1)
	rid(0.1)
	prova("släppt spakfinger nollar båda axlarna", senaste.forward == 0
		and senaste.steer == 0)

	--[[ ══ 7. STAPLINGSKONTRAKTET (träffprovet är HARDWARE CHECK) ═══ ]]
	print("\n── 7. Ordningen som ger knapparna sitt eget finger ──")
	local barn = rawget(gui, "_barn")
	prova("blickytan är FÖRSTA syskonet i HorseTouch, med ZIndex 0",
		barn[1] == yta and yta.ZIndex == 0)
	prova("och ScreenGui:n ritar i syskonordning",
		gui.ZIndexBehavior == Enum.ZIndexBehavior.Sibling)
	local senareSyskon = true
	for _, namn in KNAPPAR do
		local k = sok(gui, namn)
		local galler = k and k.Parent
		local hittad = false
		for i = 2, #barn do if barn[i] == galler then hittad = true end end
		if not hittad then senareSyskon = false end
	end
	prova("alla tio knappar ligger i galler som är senare syskon än blickytan",
		senareSyskon)
	prova("blickytan är Active — tar sitt finger, låter det inte falla igenom",
		yta.Active == true)

	--[[ Lektions-, skötsel-, hjälp- och replaygui ligger ÖVER reglagen:
		deras knappar vinner om de ligger på samma plats, och det är därför
		§1 mäter att de inte gör det. ]]
	--[[ Bara ScreenGui:er MED knappar räknas: en skylt utan tryckyta
		(`UBRFDinHast`, DisplayOrder 6) tar inget finger och får ligga
		var den vill i stapeln. ]]
	local function harKnapp(nod)
		if type(nod) ~= "table" then return false end
		local klass = rawget(nod, "ClassName")
		if klass == "TextButton" or klass == "ImageButton" then return true end
		for _, b in ipairs(rawget(nod, "_barn") or {}) do
			if harKnapp(b) then return true end
		end
		return false
	end
	local lagre, provade = {}, 0
	for _, g in ipairs(rawget(player._gui, "_barn") or {}) do
		if rawget(g, "ClassName") == "ScreenGui" and g.Enabled ~= false and harKnapp(g) then
			provade += 1
			local d = g.DisplayOrder or 0
			if d <= gui.DisplayOrder and g.Name ~= "HorseTouch" then
				table.insert(lagre, ("%s(%d)"):format(g.Name, d))
			end
		end
	end
	prova("varje annan ScreenGui med knappar ritar över HorseTouch (DisplayOrder 8)",
		#lagre == 0 and provade > 0,
		if #lagre > 0 then table.concat(lagre, " ") else ("(%d provade)"):format(provade))

	sittAv(gui)
end

--[[ Ta bort omslagen: modulerna är delade med resten av banken. ]]
Input.consume = origConsume
MovementController.step = origStep
CameraController.vridBlick = origBlick
usv.TouchEnabled = false

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
else
	print("\npekridning.spec: alla gröna")
end
