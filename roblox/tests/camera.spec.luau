--!nostrict
--[[
	Mätningar på ridkameran.

	Kameran har en egen kurs som följer hästens med kort fördröjning. Två
	saker kan gå fel med det, och båda går att mäta: fördröjningen kan bli
	så lång att man tappar känslan av att styra, och vinkelutjämningen kan
	ta den långa vägen runt cirkeln när hästens kurs passerar noll — då
	snurrar bilden ett helt varv.

	Kör: python3 roblox/tests/build.py tests/camera.spec.luau
	     && luau roblox/tests/.build/camera.luau
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

local function newCam()
	return CameraController.new(__makeRig())
end

--[[ Ett locomotion-tillstånd att mata kameran med. ]]
local function loco(o)
	o = o or {}
	return {
		speed = o.speed or 0, heading = o.heading or 0,
		turnRate = o.turnRate or 0, lean = 0,
		gait = o.gait or "walk", targetGait = o.gait or "walk",
		state = "Walk", phase = 0, airborne = false, grounded = true,
		slope = Vector3.yAxis, stamina = 100,
	}
end

print("\n── Kameran hinner ifatt, men inte direkt ──")
do
	local cam = newCam()
	local dt = 1 / 60
	--[[ Hästen svänger till 1,0 rad och står kvar där. Kameran ska ligga
	     efter i början och vara framme efter en halv sekund. ]]
	cam:step(loco({ heading = 1.0, turnRate = 1.0 }), dt)
	local efterEn = math.abs(1.0 - cam.yaw)
	for _ = 1, 30 do cam:step(loco({ heading = 1.0 }), dt) end
	local efterHalv = math.abs(1.0 - cam.yaw)
	print(string.format("  kvar efter en bildruta: %.3f rad", efterEn))
	print(string.format("  kvar efter 0,5 s:       %.4f rad", efterHalv))
	check("kameran ligger efter i första bildrutan", efterEn > 0.5,
		string.format("(%.3f rad kvar, kräver > 0,5)", efterEn))
	check("kameran är ifatt inom en halv sekund", efterHalv < 0.05,
		string.format("(%.4f rad kvar, kräver < 0,05)", efterHalv))
end

print("\n── Nollpassage: kameran tar den korta vägen ──")
do
	local cam = newCam()
	local dt = 1 / 60
	--[[ Hästen står strax under 2π och svänger förbi noll. Tar kameran
	     den långa vägen syns det som en hastig helvarvssnurr. ]]
	cam.yaw = 6.20                                   -- knappt 2π
	local mest = 0
	local forra = cam.yaw
	for i = 1, 40 do
		local h = (6.20 + i * 0.02) % (2 * math.pi)   -- passerar noll
		cam:step(loco({ heading = h }), dt)
		local steg = math.abs((cam.yaw - forra + math.pi) % (2 * math.pi) - math.pi)
		mest = math.max(mest, steg)
		forra = cam.yaw
	end
	print(string.format("  största kurssteg per bildruta: %.4f rad", mest))
	check("ingen helvarvssnurr vid nollpassagen", mest < 0.15,
		string.format("(%.4f rad, ett varv vore ~6,28)", mest))
end

print("\n── Gångartsbytet syns i bilden ──")
do
	local cam = newCam()
	local dt = 1 / 60
	for _ = 1, 120 do cam:step(loco({ gait = "walk" }), dt) end
	local naraDist, naraFov = cam.dist, cam.fov
	for _ = 1, 180 do cam:step(loco({ gait = "gallop", speed = 8.6 }), dt) end
	local fjarrDist, fjarrFov = cam.dist, cam.fov
	print(string.format("  skritt:    avstånd %.1f, fov %.1f", naraDist, naraFov))
	print(string.format("  fyrsprång: avstånd %.1f, fov %.1f", fjarrDist, fjarrFov))
	check("kameran backar undan i fyrsprång", fjarrDist > naraDist + 4,
		string.format("(%.1f → %.1f studs)", naraDist, fjarrDist))
	check("synfältet öppnar sig i fart", fjarrFov > naraFov + 3,
		string.format("(%.1f → %.1f grader)", naraFov, fjarrFov))
end

--[[ ══════════════════════════════════════════════════════════════════
     KAMERALÄGET — G02-E del 1 (issue #150), Roblox-halvan.

     Webbens tillstånds-/livscykelkontrakt provas grundligt i
     tools/kameralagetest.mjs (37 mätningar + 5 mutationsfalsifieringar).
     Den här filen upprepar INTE alla — modulen är en ordagrann
     tal-för-tal-portering och paritetsspecen jämför redan att
     vinkeltabellerna är identiska. Det som provas här är det som är
     SPECIFIKT för Roblox-ytan och det EN konkreta fyndet som gällde
     båda:

       1. att `CameraController` faktiskt ÄGER och DRIVER en
          `Kameralage`-instans genom sin egen `:step()` — inte bara att
          modulen fungerar isolerat (kravet "renderaren måste påvisbart
          konsumera läget"),
       2. den rapporterade regressionen (ChatGPT, #150): en anropare som
          begär om SAMMA vinkel varje bildruta fick INTE kunna hålla
          feedbackvyn för evigt genom att varje anrop nollställde
          `total`. Provas här mot den RIKTIGA, körande kameran — inte
          bara mot den bara modulen. ]]

print("\n── Kameraläget: CameraController äger och driver Kameralage ──")
do
	local cam = newCam()
	local dt = 1 / 60
	local vila = loco({ gait = "walk" })

	--[[ Standard: ryttarperspektiv. Ingen begäran är gjord, så
	     Kameralage-instansen `cam` äger ska vara i vila med vikt 0. ]]
	for _ = 1, 30 do cam:step(vila, dt) end
	local vilaVikt = Kameralage.las(cam.lage).vikt
	check("kameran startar i ryttarperspektiv (Kameralage-vikt 0)",
		vilaVikt == 0, string.format("(vikt %.3f)", vilaVikt))

	--[[ Bommen (avstånds-multiplikatorn) ska följa gångarten i vila —
	     samma tal som förut, inget bidrag från någon vinkel. ]]
	local restDist = cam.dist
	local vantatVila = Gaits.get("walk").camera.dist * Kameralage.NEUTRAL.bak
	check("viloavståndet matchar gångartens egen bom (× 1,0)",
		math.abs(restDist - vantatVila) < 0.5,
		string.format("(%.2f mot %.2f)", restDist, vantatVila))

	--[[ Begär en feedbackvinkel via CAMERACONTROLLERNS EGET API — inte
	     mot Kameralage-modulen direkt. Det är skillnaden mellan att
	     bevisa att modulen fungerar och att bevisa att kameran faktiskt
	     använder den. `vagval` skalar bommen 1,90×. ]]
	local togEmot = cam:begarFeedback("vagval", "spec")
	check("kameran tar emot en feedbackbegäran via sitt eget API", togEmot == true)

	--[[ Sampla TOPPEN mitt i hålfasen, INTE efter den. vagval: in 0,45 s,
	     håll 1,70 s → hållfasen pågår 0,45–2,15 s, och vikten är EXAKT 1
	     bara däremellan. 1,5 s ligger gott och väl inuti det fönstret —
	     samplar man i stället efter 2,15 s (t.ex. vid 2,4 s, som en
	     tidigare version av det här provet gjorde) har uttoningen redan
	     börjat och vikten är inte längre 1, vilket är en provbugg, inte
	     ett produktionsfel. 1,5 s ger också kamerans EGNA Tau=0,35 s-
	     utjämning av `dist` (~4,3 tidskonstanter) gott om tid att hinna
	     ikapp den — bommens mål hoppar till fullt 1,90× redan i samma
	     bildruta som begäran görs, det är bara `self.dist` som glider. ]]
	for _ = 1, 90 do cam:step(vila, dt) end
	local toppVikt = Kameralage.las(cam.lage).vikt
	local toppDist = cam.dist
	check("Kameralage-vikten är EXAKT 1 mitt i hållfasen, genom kamerans egen step()",
		toppVikt == 1, string.format("(vikt %.4f)", toppVikt))
	check("kamerans EGET avstånd följde med upp mot vagval-bommen (1,90×)",
		toppDist > restDist * 1.4,
		string.format("(%.2f → %.2f, gräns %.2f)", restDist, toppDist, restDist * 1.4))

	--[[ Vinkelns hela livslängd är in+håll+ut = 0,45+1,70+0,55 = 2,70 s,
	     alltså 1,20 s till efter de 1,5 s som redan körts. Men `self.dist`
	     hoppar inte tillbaka förrän MÅLET gör det — och målet ändras
	     inte förrän `nollstall` faktiskt fyrar vid t=2,70 s. Ytterligare
	     3,75 s (7,5 tau) därefter ger `self.dist` gott om tid att glida
	     tillbaka till viloläget innan det mäts. ]]
	for _ = 1, math.floor((1.20 + 3.75) * 60) do cam:step(vila, dt) end
	local slutVikt = Kameralage.las(cam.lage).vikt
	local slutDist = cam.dist
	check("Kameralage-vikten är EXAKT noll igen — automatisk återgång",
		slutVikt == 0, string.format("(vikt %.4f)", slutVikt))
	check("kamerans EGET avstånd är tillbaka vid vilobommen",
		math.abs(slutDist - restDist) < 0.6,
		string.format("(%.2f, ursprung %.2f)", slutDist, restDist))
end

print("\n── Kameraläget: upprepad begäran kan inte hålla vyn för evigt (blocker #150) ──")
do
	--[[ ChatGPT:s fynd (kommentar på #150): `Kameralage.begar()` nollställde
	     `total` vid VARJE anrop — inte bara vid en riktigt ny begäran.
	     En anropare som råkar begära om SAMMA vinkel varje bildruta (ett
	     dubbeltryck som studsar, en händelse som triggar upprepat) kunde
	     då hålla kvar feedbackvyn för evigt.

	     Provat HÄR mot den RIKTIGA, körande `CameraController` — inte
	     mot den bara modulen (den mätningen finns redan, grundligt, i
	     tools/kameralagetest.mjs). Om fixen bara satt i modulen men
	     kameran av någon anledning gick runt den, hade den här faktiskt
	     kunnat missa det. ]]
	local cam = newCam()
	local dt = 1 / 60
	local vila = loco({ gait = "walk" })

	cam:begarFeedback("utifran", "spam")
	--[[ Nödbromsens tak (MAX_TOTAL 6,0 + MAX_UT 1,5 = 7,5 s) plus
	     marginal: om vyn INTE stängt sig innan dess trots att SAMMA
	     vinkel begärs om varje bildruta är deadlinen bruten. ]]
	local grans = math.ceil((Kameralage.MAX_TOTAL + Kameralage.GRANS.ut[2] + 1) * 60)
	local n = 0
	while Kameralage.aktiv(cam.lage) and n < grans do
		cam:begarFeedback("utifran", "spam")   -- samma vinkel begärs om, varje bildruta
		cam:step(vila, dt)
		n += 1
	end
	local stannade = not Kameralage.aktiv(cam.lage)
	check("upprepade begäranden av SAMMA vinkel kan inte hålla kamerans vy för evigt",
		stannade and n < grans,
		string.format("stannade %s (tak %.2f s)",
			if stannade then string.format("efter %.2f s", n / 60) else "aldrig",
			grans / 60))
end

print("\n── Kameraläget: hård avsittning lämnar inget spöke ──")
do
	--[[ `:release()` (dismount) ska nollställa Kameralage HÅRT, precis
	     som webbens `ridKameraNollstall`. Ingen begäran får överleva och
	     tändas på nästa häst. ]]
	local cam = newCam()
	local dt = 1 / 60
	cam:begarFeedback("sits", "test")
	for _ = 1, 40 do cam:step(loco({ gait = "walk" }), dt) end
	check("en vy var uppe före avsittningen", Kameralage.aktiv(cam.lage) == true)
	cam:release()
	check("avsittningen nollställer kameraläget hårt",
		Kameralage.las(cam.lage).vikt == 0 and not Kameralage.aktiv(cam.lage))
end

--[[ ══ DET EGNA HUVUDET ═══════════════════════════════════════════════

	Uppmätt uppsutten i spel, före rättningen:

	    HUVUD Transparency=0.000  LocalTransparencyModifier=1.000
	    KAMERA->HUVUD 0.570 studs
	    varje ANNAN kroppsdel     LocalTransparencyModifier=0.000

	Huvudet var varken borttaget, flyttat eller skymt — vi gömde det
	själva, och vi gömde det utifrån kameralägets VIKT i stället för
	utifrån var kameran faktiskt stod. Vikten är ett abstrakt tal; den
	kan stå på noll medan kameran redan glidit flera studs bakom
	ryttaren, och då ser man en ryttare utan huvud.

	Regeln är nu en ren funktion av avståndet, och därför mätbar utan
	kamera, karaktär eller häst. ]]
print("\n── Det egna huvudet tonas ur AVSTÅNDET ──")
do
	--[[ Ett riktigt R15-huvud: uppmätt (1,16 · 1,11 · 1,14). ]]
	local radie = Vector3.new(1.16, 1.11, 1.14).Magnitude * 0.5
	local f = CameraController.huvudsynlighet

	--[[ Den uppmätta förstapersonssituationen: objektivet sitter inuti
		huvudet. Då ÄR huvudet en vägg och ska bort. ]]
	check("kameran inuti huvudet: huvudet borta", f(0.57, radie) == 0,
		string.format("synlighet %.3f vid 0,57 studs", f(0.57, radie)))
	--[[ Och det som var felet: en kamera som står ute bakom ryttaren ska
		visa huvudet, oavsett vilket läge kameran råkar vara på väg till. ]]
	check("kameran ute bakom ryttaren: huvudet syns", f(6.0, radie) == 1,
		string.format("synlighet %.3f vid 6,0 studs", f(6.0, radie)))
	check("och på granskningsavstånd syns det också", f(12.0, radie) == 1)

	--[[ Övergången ska vara monoton och mjuk i båda ändar — annars poppar
		huvudet fram mitt i en kamerarörelse. ]]
	local forra, monoton = -1, true
	for i = 0, 40 do
		local v = f(i * 0.25, radie)
		if v < forra - 1e-9 then monoton = false end
		forra = v
	end
	check("synligheten växer monotont med avståndet", monoton)
	local d0 = math.abs(f(radie * 1.15 + 0.01, radie) - f(radie * 1.15, radie))
	local d1 = math.abs(f(radie * 2.40, radie) - f(radie * 2.40 - 0.01, radie))
	check("kurvan planar ut i båda ändarna", d0 < 0.01 and d1 < 0.01,
		string.format("lutning %.5f vid start, %.5f vid slut", d0, d1))

	--[[ Ett annat avatarhuvud ska ge samma BETEENDE, inte samma tal: det
		är därför gränserna räknas ur delens egen storlek. ]]
	local litet = radie * 0.5
	check("ett mindre huvud slocknar närmare", f(0.57, litet) > f(0.57, radie))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
