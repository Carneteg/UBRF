--!nostrict
--[[
	DEN BESTÄENDE STATUSRADEN FÖR BUREN UTRUSTNING (#182 del 1).

	Human-QA såg ingenting på skärmen som sa att spelaren gick omkring
	med en sadel. En kvittens räcker inte — den slocknar — och statusen
	måste stå kvar så länge utrustningen bärs.

	Specen kör `init.client.luau` på riktigt, precis som klient.spec, och
	matar SERVERNS vy genom `PreparationController.tillampa` — samma väg
	in som `PreparationSync` använder. Det är skillnaden mot att anropa
	`DinHast.satBurenstatus` direkt: provet mäter att KEDJAN finns, inte
	bara att funktionen går att anropa. Precis det felet fällde
	UgnetaController i #119.

	Raden är dessutom mätt som BESTÄENDE: den ska överleva att klientens
	egen loop kör vidare, inte bara att den skrevs en gång.

	VAD BÄNKEN INTE KAN: hur raden ser ut, om den ligger i vägen för
	kortet, och om «diskret» är diskret nog för ett öga. Mänskliga
	grindar, och de står som sådana i PR-texten.

	Kör: python3 roblox/tests/build.py tests/klient-burenstatus.spec.luau
	     && luau roblox/tests/.build/klient-burenstatus.spec.luau
]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local RunService = game:GetService("RunService")

Sprak.satLocale("sv-se")

--[[ En vy av samma form som `Preparation.vy` bygger. `rev` måste växa:
	klienten kastar en äldre vy, och det är rätt (krav 10). ]]
local rev = 0
local function vy(buren)
	rev += 1
	return {
		status = "preparing", hastId = "trixie", hastnamn = "Trixie",
		steg = {}, nasta = nil, moment = {}, nastaMoment = nil,
		fynd = nil, svar = {}, stoppad = nil, redo = false,
		burenUtrustning = buren, rev = rev,
	}
end

--[[ Klientens egen loop, som Roblox kör den. Raden ska stå kvar efteråt —
	det är hela innebörden av «beständig». ]]
local function bildrutor(sek)
	local dt = 1 / 30
	for _ = 1, math.floor(sek / dt) do
		RunService.Heartbeat:Fire(dt)
	end
end

print("\nDEN BESTÄENDE STATUSRADEN — BUREN UTRUSTNING\n")

print("── Utgångsläget ──")

do
	PreparationController.tillampa(vy(nil))
	prova("ingen rad när spelaren inte bär något",
		DinHast._burenstatus() == nil, tostring(DinHast._burenstatus()))
end

print("\n── Hämtningen tänder raden, genom serverns vy ──")

do
	PreparationController.tillampa(vy({
		hastId = "trixie", hastnamn = "Trixie", delar = { "sadel", "trans" },
	}))
	local text = DinHast._burenstatus()
	prova("raden tändes av serverns vy — kedjan finns", text ~= nil)
	prova("och den säger vad spelaren bär och vems det är",
		text == Sprak.t("tack.bar_par", "Trixie"),
		("[%s]"):format(tostring(text)))
	prova("hästens egennamn står i klartext",
		type(text) == "string" and text:find("Trixie") ~= nil,
		("[%s]"):format(tostring(text)))

	--[[ BESTÄENDE, inte en kvittens. Kör klientens loop långt förbi den
		tid en kvittens lever på (`BEKRAFTELSE_TID`) och kräv att raden
		står kvar. Utan den här mätningen kunde statusen ha byggts som en
		blinkande notis utan att något prov märkte skillnaden. ]]
	bildrutor(PreparationController.BEKRAFTELSE_TID + 3)
	prova("raden står kvar efter klientens egen loop",
		DinHast._burenstatus() == text, tostring(DinHast._burenstatus()))
end

print("\n── Varje del släcker sin egen halva ──")

do
	PreparationController.tillampa(vy({
		hastId = "trixie", hastnamn = "Trixie", delar = { "trans" },
	}))
	prova("med sadeln påsatt står bara tränset kvar",
		DinHast._burenstatus() == Sprak.t("tack.bar_trans", "Trixie"),
		("[%s]"):format(tostring(DinHast._burenstatus())))

	PreparationController.tillampa(vy({
		hastId = "trixie", hastnamn = "Trixie", delar = { "sadel" },
	}))
	prova("och tvärtom när det är tränset som sitter på",
		DinHast._burenstatus() == Sprak.t("tack.bar_sadel", "Trixie"),
		("[%s]"):format(tostring(DinHast._burenstatus())))
end

print("\n── Fel hästs utrustning namnger den hästen ──")

do
	--[[ Att kunna ta fel sadel ÄR poängen (`tack.fel_sadel`). Statusraden
		ska då säga vems utrustning spelaren faktiskt bär, inte vilken
		häst hon ska rida — annars döljer raden precis det misstag
		momentet finns för att lära ut. ]]
	PreparationController.tillampa(vy({
		hastId = "marabou", hastnamn = "Marabou", delar = { "sadel", "trans" },
	}))
	local text = DinHast._burenstatus()
	prova("raden namnger utrustningens häst, inte spelarens",
		type(text) == "string" and text:find("Marabou") ~= nil
			and text:find("Trixie") == nil,
		("[%s]"):format(tostring(text)))
end

print("\n── Påsättningen släcker raden helt ──")

do
	PreparationController.tillampa(vy(nil))
	prova("all utrustning på hästen släcker statusen",
		DinHast._burenstatus() == nil, tostring(DinHast._burenstatus()))
	bildrutor(1)
	prova("och den tänds inte igen av loopen",
		DinHast._burenstatus() == nil, tostring(DinHast._burenstatus()))
end

print("\n── Under ritten är frågan besvarad ──")

do
	PreparationController.tillampa(vy({
		hastId = "trixie", hastnamn = "Trixie", delar = { "sadel" },
	}))
	prova("raden syns i stallet", DinHast._burenstatus() ~= nil)
	--[[ Samma flagga som släcker skylten över hästen under ritten. Sitter
		spelaren upp ligger utrustningen på hästen, och en rad som påstår
		att hon bär den vore direkt osann. ]]
	DinHast.satDold(true)
	bildrutor(1)
	prova("men inte under ritten", DinHast._burenstatus() == nil,
		tostring(DinHast._burenstatus()))
	DinHast.satDold(false)
	bildrutor(1)
	prova("och den kommer tillbaka när spelaren sitter av",
		DinHast._burenstatus() ~= nil, tostring(DinHast._burenstatus()))
end

print("\n── Serverns kvittens blir text spelaren kan läsa ──")

do
	--[[ Servern svarar `(true, "tack.pa_plats", { del, hast })` på ett
		utrustningsmoment. Att den GÖR det mäter `buren-tack.spec`; det
		här mäter andra halvan — att klienten skriver ut det, och att
		texten hamnar i den kvittens spelaren faktiskt läser.

		Utan den här mätningen kunde servern ha skickat nycklarna i
		tomma intet: `PreparationController.skicka` hade struntat i dem
		och skrivit "Bra" precis som förut, och ingen grind hade sett
		skillnaden. ]]
	RunService._server = true
	local remote = Networking.get("PreparationMoment")
	RunService._server = false
	local ursprung = remote.InvokeServer

	remote.InvokeServer = function()
		return true, "tack.pa_plats", { del = "tack.del_sadel", hast = "Trixie" }
	end
	PreparationController.begar("iordning", "utr:2")
	task.wait()
	local kvitto = PreparationController._bekraftelse()
	prova("kvittensen namnger delen och hästen",
		type(kvitto) == "string" and kvitto:find("Sadeln") ~= nil
			and kvitto:find("Trixie") ~= nil,
		("[%s]"):format(tostring(kvitto)))
	prova("och den är inte det generiska ordet",
		type(kvitto) == "string" and kvitto:find(Sprak.t("hud.bra")) == nil,
		("[%s]"):format(tostring(kvitto)))

	--[[ EN OKÄND NYCKEL FÅR INTE TYSTA FEEDBACKEN. Faller uppslaget ska
		kvittensen bli den klienten räknade fram före anropet, inte
		ingenting — direkt feedback är hela poängen med raden. ]]
	remote.InvokeServer = function()
		return true, "tack.finns_inte_i_katalogen", { del = "x", hast = "Trixie" }
	end
	PreparationController.begar("iordning", "utr:3")
	task.wait()
	local reserv = PreparationController._bekraftelse()
	prova("en okänd nyckel faller tillbaka på den lokala kvittensen",
		type(reserv) == "string" and reserv ~= "" and reserv ~= kvitto,
		("[%s]"):format(tostring(reserv)))

	remote.InvokeServer = ursprung
end

print("\n── Statusraden och ledningens rad är två olika rader ──")

do
	--[[ De två tillstånden kan stå samtidigt: man leder henne med tränset
		påsatt och sadeln kvar i handen. Skrevs de i samma etikett hade
		det ena tyst målat över det andra — exakt den klass av fel som
		ledningens egen rad byggdes för att rätta. ]]
	DinHast.satLedstatus("Trixie")
	local buren = DinHast._burenstatus()
	prova("ledningens status är satt", DinHast._ledstatus() == "Trixie")
	prova("och den burna statusen står kvar oförändrad",
		buren ~= nil and DinHast._burenstatus() == buren,
		("[%s]"):format(tostring(DinHast._burenstatus())))
	prova("de två texterna är inte samma rad",
		DinHast._burenstatus() ~= Sprak.t("led.leder", "Trixie"))
	DinHast.satLedstatus(nil)
end

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fel), 0)
else
	print("\nklient-burenstatus.spec: alla gröna")
end
