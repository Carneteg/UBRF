--!nostrict
--[[
	Blickgesten på pekskärm (#220).

	`TouchControls` har haft ryttarens blick sedan #162: ett eget finger på
	den genomskinliga ytan till höger vrider kameran, skilt från spakens
	finger. Ingen grind mätte den. Det här är den grinden — mot koden på
	main, inte mot den gamla grenen.

	Vad som mäts är KONTRAKTET mellan fingret och kameran:

	  1. START — ett nedslag rycker aldrig kameran. Allt som skickas är
	     skillnaden mot fingrets FÖRRA läge, så första nedslaget är noll.
	  2. RÖRELSE — skillnaden går till `blick`-hooken med fingrets håll:
	     höger vrider höger, nedåt sänker blicken.
	  3. SLÄPP — bara fingret nollas. Kameran lämnas där den står, ingen
	     återfjädring, och en rörelse med det släppta fingret gör inget.
	  4. SEPARATION — spakens finger kan aldrig bli ett blickfinger, och
	     blickens finger skriver aldrig i `Input`. Gångartsknapparna
	     startar ingen blick.
	  5. INGEN FASTNAD BLICK — avsittningen släpper fingret och hooken.
	  6. #206-SEMANTIKEN — på skrivbordet finns ingen blickyta alls, och en
	     anropare utan `blick`-hook fungerar ändå.

	Gesterna körs genom samma signaler som i Studio: `Blickyta.InputBegan`,
	`Spak.InputBegan`, `UserInputService.InputChanged/InputEnded`. Provet
	fyrar dem självt med InputObject-tabeller; det som mäts är vad
	TouchControls GÖR med dem. Hur det känns på en fysisk iPad mäts inte
	här — det är #206:s mänskliga grind, och den förblir NOT_TESTED av
	den här specen.

	Kör: python3 roblox/tests/build.py tests/blick.spec.luau
	     && luau roblox/tests/.build/blick.spec.luau
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

local UIS = game:GetService("UserInputService")
local spelare = game:GetService("Players").LocalPlayer
local kam = workspace.CurrentCamera
spelare:WaitForChild("PlayerGui")
local playerGui = spelare:FindFirstChildOfClass("PlayerGui")

--[[ Samma tal som i TouchControls: radianer per pixel i sidled, studs per
     pixel i höjdled. Pinnas här så att en ändring av känsligheten syns
     som ett medvetet beslut i två filer. ]]
local PER_PIXEL_X = 0.006
local PER_PIXEL_Y = 0.02
local EPS = 1e-9

local function barn(inst, namn)
	for _, b in ipairs(inst and inst._barn or {}) do
		if b.Name == namn then return b end
	end
	return nil
end
local function antalHorseTouch()
	local n = 0
	for _, g in ipairs(playerGui._barn or {}) do
		if g.Name == "HorseTouch" then n += 1 end
	end
	return n
end

--[[ Hookens logg. `ickeNoll` räknar bara anrop som faktiskt vrider något:
     TouchControls kopplar sina globala lyssnare per montering, så en
     rörelse kan ge fler anrop än ett — men bara det första bär skillnaden,
     resten är noll. Kontraktet är VAD kameran får, inte hur många gånger
     den får noll. ]]
local logg = {}
local function hook(dYaw, dPitch)
	table.insert(logg, { yaw = dYaw, pitch = dPitch })
end
local function ickeNoll()
	local n, yaw, pitch = 0, 0, 0
	for _, a in ipairs(logg) do
		if a.yaw ~= 0 or a.pitch ~= 0 then
			n += 1
			yaw += a.yaw
			pitch += a.pitch
		end
	end
	return n, yaw, pitch
end
local function tomLogg() logg = {} end

--[[ Ett finger är ett InputObject: TouchControls jämför dem på IDENTITET,
     aldrig på läge, så varje finger är en egen tabell. ]]
local nastaFinger = 0
local function finger(x, y, typ)
	nastaFinger += 1
	return { Id = nastaFinger, UserInputType = typ or Enum.UserInputType.Touch,
		Position = { X = x, Y = y, Z = 0 } }
end
local function dra(f, x, y)
	f.Position = { X = x, Y = y, Z = 0 }
	UIS.InputChanged:Fire(f)
end
local function slapp(f)
	UIS.InputEnded:Fire(f)
end

local function nollstallInput()
	Input.unbind()
	__setStick(nil)
	Input.bind()
end

--[[ Monterar på en pekenhet i landskap (iPad-höjd, så skalan är 1) och
     lämnar tillbaka ytorna. ]]
local function montera(hooks)
	TouchControls.unmount()
	UIS.TouchEnabled = true
	kam.ViewportSize = { _typ = "Vector2", X = 1180, Y = 820 }
	nollstallInput()
	tomLogg()
	TouchControls.mount(Input, hooks or { dismount = function() end, blick = hook })
	local ht = barn(playerGui, "HorseTouch")
	return ht, barn(ht, "Blickyta"), barn(ht, "Spak")
end

local function stillaIntent(i)
	return i.forward == 0 and i.steer == 0 and i.rein == 0 and i.seat == 0
		and i.gaitUp == false and i.gaitDown == false and i.gaitTo == nil
		and i.jump == false and i.parad == 0
end

print("\n── Blickytan finns, ligger underst och lämnar spaken fri ──")
do
	local ht, yta, spak = montera()
	check("pekreglagen monterades", ht ~= nil and TouchControls.isActive())
	check("det finns en blickyta", yta ~= nil)
	check("och en spak", spak ~= nil)
	if yta and spak and ht then
		check("blickytan täcker högra två tredjedelarna",
			math.abs(yta.Position.X.Scale - 0.34) < EPS
				and math.abs(yta.Size.X.Scale - 0.66) < EPS
				and math.abs(yta.Size.Y.Scale - 1) < EPS,
			string.format("(x %.2f, bredd %.2f, höjd %.2f)",
				yta.Position.X.Scale, yta.Size.X.Scale, yta.Size.Y.Scale))
		check("blickytan ligger UNDERST i sin ScreenGui, så knappar och spak tar sitt finger först",
			ht._barn[1] == yta and yta.ZIndex == 0,
			string.format("(första barnet: %s, ZIndex %d)", tostring(ht._barn[1] and ht._barn[1].Name), yta.ZIndex))
		check("blickytan är Active — fingret faller inte igenom till världen",
			yta.Active == true)
		local spakHoger = spak.Position.X.Offset + spak.Size.X.Offset
		local blickVanster = yta.Position.X.Scale * kam.ViewportSize.X
		check("spaken ligger helt i den vänstra tredjedelen, utanför blickytan",
			spak.Position.X.Scale == 0 and spakHoger < blickVanster,
			string.format("(spakens högerkant %d px, blickytan börjar vid %d px)",
				spakHoger, math.floor(blickVanster)))
	end
end

print("\n── Start: ett nedslag rycker inte kameran ──")
do
	local _, yta = montera()
	local f = finger(700, 400)
	yta.InputBegan:Fire(f)
	check("nedslaget i sig skickar INGENTING till kameran",
		#logg == 0, string.format("(%d anrop)", #logg))
	--[[ Första rörelsen räknas mot nedslagsläget, inte mot skärmens origo
	     eller en absolut vinkel: ett nedslag långt ut till höger följt av
	     ett stillastående finger ger noll. ]]
	dra(f, 700, 400)
	local n = ickeNoll()
	check("en rörelse till samma läge vrider ingenting",
		n == 0, string.format("(%d vridande anrop)", n))
	slapp(f)
end

print("\n── Rörelse: skillnaden mot förra läget, med fingrets håll ──")
do
	local _, yta = montera()
	local f = finger(700, 400)
	yta.InputBegan:Fire(f)

	dra(f, 750, 400)                        -- 50 px åt höger
	local n1, yaw1, pitch1 = ickeNoll()
	check("50 px åt höger vrider blicken åt höger med 50 × 0,006 rad",
		n1 == 1 and math.abs(yaw1 - 50 * PER_PIXEL_X) < EPS and pitch1 == 0,
		string.format("(yaw %.4f, pitch %.4f, %d vridande anrop)", yaw1, pitch1, n1))

	tomLogg()
	dra(f, 750, 440)                        -- 40 px nedåt
	local n2, yaw2, pitch2 = ickeNoll()
	check("40 px nedåt SÄNKER blicken med 40 × 0,02 studs — samma håll som fingret",
		n2 == 1 and yaw2 == 0 and math.abs(pitch2 + 40 * PER_PIXEL_Y) < EPS,
		string.format("(yaw %.4f, pitch %.4f)", yaw2, pitch2))

	tomLogg()
	dra(f, 720, 410)                        -- 30 px vänster, 30 px uppåt
	local n3, yaw3, pitch3 = ickeNoll()
	check("vänster och uppåt ger negativ yaw och positiv pitch",
		n3 == 1 and math.abs(yaw3 + 30 * PER_PIXEL_X) < EPS
			and math.abs(pitch3 - 30 * PER_PIXEL_Y) < EPS,
		string.format("(yaw %.4f, pitch %.4f)", yaw3, pitch3))

	--[[ RELATIVT, INTE ABSOLUT: summan av tre drag är skillnaden mellan
	     sista och första läget — inte tre gånger avståndet från origo. ]]
	local total = 50 - 30
	check("skillnaderna summerar till fingrets nettoförflyttning",
		math.abs((yaw1 + yaw2 + yaw3) - total * PER_PIXEL_X) < EPS,
		string.format("(summa yaw %.4f = %d px)", yaw1 + yaw2 + yaw3, total))
	slapp(f)
end

print("\n── Släpp: fingret nollas, kameran lämnas där den står ──")
do
	local _, yta = montera()
	local f = finger(700, 400)
	yta.InputBegan:Fire(f)
	dra(f, 760, 400)
	local fore = #logg
	slapp(f)
	check("släppet skickar ingen återfjädring eller omcentrering",
		#logg == fore, string.format("(%d anrop före, %d efter)", fore, #logg))
	dra(f, 900, 500)
	check("ett släppt finger som fortsätter röra sig gör ingenting",
		#logg == fore, string.format("(%d anrop)", #logg - fore))

	--[[ Och ett NYTT nedslag efteråt fungerar: fingret var släppt, inte
	     låst. ]]
	tomLogg()
	local f2 = finger(650, 300)
	yta.InputBegan:Fire(f2)
	dra(f2, 660, 300)
	local n = ickeNoll()
	check("ett nytt finger efter släppet vrider igen", n == 1,
		string.format("(%d vridande anrop)", n))
	slapp(f2)
end

print("\n── Ett blickfinger i taget ──")
do
	local _, yta = montera()
	local f1 = finger(700, 400)
	local f2 = finger(900, 500)
	yta.InputBegan:Fire(f1)
	yta.InputBegan:Fire(f2)
	tomLogg()
	dra(f2, 950, 500)
	local n2 = ickeNoll()
	check("ett andra finger på ytan tas inte emot medan det första ligger kvar",
		n2 == 0, string.format("(%d vridande anrop från finger 2)", n2))
	dra(f1, 710, 400)
	local n1 = ickeNoll()
	check("det första fingret vrider fortfarande", n1 == 1)
	--[[ Att släppa det AVVISADE fingret släpper inte det aktiva. ]]
	slapp(f2)
	tomLogg()
	dra(f1, 720, 400)
	check("att lyfta det andra fingret släpper inte det första",
		ickeNoll() == 1)
	slapp(f1)
end

print("\n── Separation: spakens finger blir aldrig blick, blicken skriver aldrig i Input ──")
do
	local _, yta, spak = montera()

	--[[ Spakfingret. Basens AbsolutePosition/AbsoluteSize är noll i bänken,
	     så spakens mitt är origo och fingrets läge är utslaget. 40 px åt
	     höger och 40 px uppåt av radien 66 är ett tydligt utslag. ]]
	local fs = finger(40, -40)
	spak.InputBegan:Fire(fs)
	local i1 = Input.consume()
	check("spakfingret styr hästen", i1.steer > 0.1 and i1.forward > 0.1,
		string.format("(forward %.3f, steer %.3f)", i1.forward, i1.steer))
	check("men vrider inte kameran", ickeNoll() == 0)

	dra(fs, 60, -20)
	local i2 = Input.consume()
	check("spakfingrets rörelse ändrar styrningen", i2.steer > i1.steer,
		string.format("(steer %.3f → %.3f)", i1.steer, i2.steer))
	check("och vrider fortfarande inte kameran", ickeNoll() == 0)

	--[[ SAMMA finger når blickytan (tummen gled över kanten): det får
	     inte kapas till ett blickfinger. ]]
	yta.InputBegan:Fire(fs)
	dra(fs, 300, -20)
	check("spakens finger kan inte bli ett blickfinger",
		ickeNoll() == 0, string.format("(%d vridande anrop)", (ickeNoll())))
	--[[ Fingret DROGS dit — spaken följer det globalt, så utslaget är nu
	     fullt åt höger. Det är referensen för nästa mätning. ]]
	local iRef = Input.consume()
	check("det styr fortfarande hästen", iRef.steer > 0,
		string.format("(steer %.3f)", iRef.steer))

	--[[ Ett RIKTIGT blickfinger samtidigt: högertummen tittar sig omkring
	     medan vänstertummen styr. ]]
	local fb = finger(800, 400)
	yta.InputBegan:Fire(fb)
	dra(fb, 830, 400)
	local n, yaw = ickeNoll()
	check("högertummen vrider kameran medan vänstertummen styr",
		n == 1 and yaw > 0, string.format("(yaw %.4f)", yaw))
	local i3 = Input.consume()
	check("blickfingret ändrar inte styrningen",
		math.abs(i3.steer - iRef.steer) < EPS and math.abs(i3.forward - iRef.forward) < EPS,
		string.format("(steer %.3f mot %.3f, forward %.3f mot %.3f)",
			i3.steer, iRef.steer, i3.forward, iRef.forward))

	--[[ Spaken släpps: hästen stannar, blicken fortsätter. ]]
	slapp(fs)
	local i4 = Input.consume()
	check("att släppa spaken nollar styrningen", i4.forward == 0 and i4.steer == 0)
	tomLogg()
	dra(fb, 860, 420)
	check("blickfingret lever kvar efter att spaken släppts", ickeNoll() == 1)
	check("och blicken ensam lämnar Input helt stilla",
		stillaIntent(Input.consume()))
	slapp(fb)
	check("släppt blick lämnar också Input stilla", stillaIntent(Input.consume()))

	--[[ Gångartsknapparna: ett tryck på GALOPP är ett tryck på GALOPP. ]]
	local ht = barn(playerGui, "HorseTouch")
	local galopp = barn(barn(ht, "Gangarter"), "Galopp")
	tomLogg()
	galopp.MouseButton1Click:Fire()
	local ig = Input.consume()
	check("ett tryck på GALOPP begär galopp", ig.gaitTo == "canter",
		string.format("(gaitTo %s)", tostring(ig.gaitTo)))
	check("och startar ingen blick", #logg == 0)
end

print("\n── Bara pekfingrar: en mus på ytan är ingen blick ──")
do
	local _, yta = montera()
	local mus = finger(700, 400, Enum.UserInputType.MouseButton1)
	yta.InputBegan:Fire(mus)
	dra(mus, 800, 400)
	check("en musknapp på blickytan avvisas", #logg == 0,
		string.format("(%d anrop)", #logg))
	local f = finger(700, 400)
	yta.InputBegan:Fire(f)
	dra(f, 710, 400)
	check("ett pekfinger direkt efteråt tas emot — musen låste ingenting",
		ickeNoll() == 1)
	slapp(f)
end

print("\n── Avsittning lämnar ingen blick kvar ──")
do
	local _, yta = montera()
	local f = finger(700, 400)
	yta.InputBegan:Fire(f)
	dra(f, 720, 400)
	check("blicken vrider före avsittningen", ickeNoll() == 1)
	TouchControls.unmount()
	check("reglagen är borta", not TouchControls.isActive() and antalHorseTouch() == 0,
		string.format("(%d HorseTouch kvar)", antalHorseTouch()))
	tomLogg()
	dra(f, 800, 450)
	check("ett finger som låg nere vid avsittningen vrider inget efteråt",
		#logg == 0, string.format("(%d anrop)", #logg))

	--[[ Nästa uppsittning börjar utan förra rittens finger. ]]
	local _, yta2 = montera()
	dra(f, 900, 450)
	check("förra rittens finger är okänt för den nya monteringen", #logg == 0)
	local f2 = finger(700, 400)
	yta2.InputBegan:Fire(f2)
	dra(f2, 730, 400)
	check("ett nytt finger på den nya ytan vrider", ickeNoll() == 1)
	slapp(f2)
	check("efter ombyggnaden finns exakt EN uppsättning reglage",
		antalHorseTouch() == 1, string.format("(%d st)", antalHorseTouch()))
	TouchControls.unmount()
end

print("\n── #206-semantiken: skrivbordet får ingen blickyta, och hooken är valfri ──")
do
	TouchControls.unmount()
	UIS.TouchEnabled = false
	nollstallInput()
	tomLogg()
	TouchControls.mount(Input, { dismount = function() end, blick = hook })
	check("på en enhet utan pekskärm monteras ingenting",
		not TouchControls.isActive() and antalHorseTouch() == 0)
	local f = finger(700, 400)
	dra(f, 800, 400)
	slapp(f)
	check("och ett pekliknande input vrider inget", #logg == 0)

	--[[ En anropare utan `blick`: samma gest får inte krascha, och den
	     får inte läcka in i Input. ]]
	UIS.TouchEnabled = true
	nollstallInput()
	TouchControls.mount(Input, { dismount = function() end })
	local ht = barn(playerGui, "HorseTouch")
	local yta = barn(ht, "Blickyta")
	local ok, felet = pcall(function()
		local g = finger(700, 400)
		yta.InputBegan:Fire(g)
		dra(g, 760, 430)
		slapp(g)
	end)
	check("blickgesten utan hook är ofarlig", ok, if ok then nil else tostring(felet))
	check("och lämnar Input stilla", stillaIntent(Input.consume()))
	TouchControls.unmount()
	UIS.TouchEnabled = false
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
