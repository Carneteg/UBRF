--!nostrict
--[[
	ENGELSK NEJ-VÄGS-SVEP (#162, ChatGPT-review 18:27 punkt 4).

	`sprak.spec.luau` mäter att ytorna RITAS OM på en-us. Den mäter inte
	nej-vägarna, och det var precis där den svenska prosan satt: servern
	returnerade "Du står för långt bort" som text, och ingen grind sa till.

	Den här specen driver varje nekande väg genom TJÄNSTERNA och skriver ut
	skälet med SAMMA funktion klienten använder
	(`PreparationController.skalText`) under `en-us`. Kravet är hårt:

	  · varje skäl är antingen en nyckel som finns i katalogen, eller
	    uttryckligen kanontext (`kanon:`-prefix),
	  · den engelska utskriften innehåller inga svenska tecken (å, ä, ö) —
	    utom i kanontexten, som RÄKNAS och LISTAS som översättningsskuld,
	  · kanonlistan är inte tom och inte tyst: varje post skrivs ut, så en
	    svensk mening i en engelsk HUD är ett redovisat beslut och inte en
	    lucka någon glömt.

	Ett rått svenskt servernej fäller specen på TVÅ rader: skälet är ingen
	nyckel, och utskriften bär svenska tecken. Det är mutationen reviewn
	ber om.

	Kör: python3 roblox/tests/build.py tests/sprak-en.spec.luau
	     && luau roblox/tests/.build/sprak-en.spec.luau
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

local Players = game:GetService("Players")
local Taggar = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local SVENSKA_TECKEN = "[åäöÅÄÖ]"

--[[ ÅÄÖ RÄCKER INTE. Mutationen "eftervårdsmomentet heter Lossa gjorden på
	engelska" gick rakt igenom teckendetektorn — meningen har inte en enda
	omljudsbokstav. Samma hål som den statiska skannern hade, hittat på
	samma sätt: genom att prova, inte genom att läsa.

	Andra detektorn är ORDBASERAD och listan är kort med flit: det är
	svenska funktions- och stallord som inte finns i engelskan. En engelsk
	mening kan innehålla "hand", "in" och "under" — de står därför inte
	här. ]]
local SVENSKA_ORD = {
	"och", "inte", "eller", "med", "fran", "till", "som", "det", "den",
	"lossa", "gjorden", "sadeln", "transet", "benen", "hovar", "hoven",
	"halsa", "visitera", "rykta", "ridhuset", "ridlararen", "hasten",
	"vanster", "hoger", "ogon", "mungiporna", "sadellaget", "gjordlaget",
	"borste", "kardborste", "underlagget", "manken", "vatten",
}

--[[ Orden jämförs OMLJUDSLÖST. `Höger bak` och det felstavade `Hoger bak`
	är samma fel för en engelsk spelare, och en mutation som råkar tappa
	prickarna ska inte glida igenom just därför. ]]
local function fallOmljud(s)
	s = string.gsub(string.lower(s), "[åä]", "a")
	return (string.gsub(s, "ö", "o"))
end

local function svenskSpelartext(rad)
	if string.find(rad, SVENSKA_TECKEN) then return true end
	local platt = fallOmljud(rad)
	for _, ord in ipairs(SVENSKA_ORD) do
		if string.find(platt, "%f[%a]" .. ord .. "%f[%A]") then return true end
	end
	return false
end

local function nyKaraktar(pos)
	local k = Instance.new("Model")
	k.Name = "Karaktar"
	local rot = Instance.new("Part")
	rot.Name = "HumanoidRootPart"
	rot.Size = vec(2, 2, 1)
	rot.CFrame = CFrame.new(pos)
	rot.Parent = k
	local hum = Instance.new("Humanoid")
	hum.Name = "Humanoid"
	hum.Parent = k
	local anim = Instance.new("Animator")
	anim.Name = "Animator"
	anim.Parent = hum
	return k, rot, hum
end

--[[ En spelare med häst i världen, genom produktionens egen startväg. ]]
local function nySession(namn, userId, forbered)
	__datastore.nollstall()
	Taggar:nollstall()
	Players.PlayerAdded:nollstall()
	Players.PlayerRemoving:nollstall()
	RunService._server = true
	Players._spelare = {}
	SparService._glomHookarForProv()

	local karaktar, _, hum = nyKaraktar(vec(6, 0, 0))
	local spelare = { Name = namn, UserId = userId, Character = karaktar,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	SparService._glomForProv(spelare)
	if forbered then forbered(spelare) end

	SparService.start()
	StallService.start()
	HorseService.start()
	GameplayService.start()
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare)
	Players.PlayerAdded:slutfor()

	local hastId = StallService.hastIdFor(spelare)
	local modell
	if hastId then
		local h = (UBRFSpel.hastar or {})[hastId]
		modell = HastRigg.bygg(hastId, (h and h.namn) or hastId, CFrame.new(vec(0, 0, 0)))
		modell.Parent = workspace
		Taggar:AddTag(modell, "Horse")
	end
	return { spelare = spelare, karaktar = karaktar, hum = hum,
		hastId = hastId, modell = modell }
end

local function stadaSession(S)
	Players.PlayerRemoving:Fire(S.spelare)
	Players._spelare = {}
	SparService._glomForProv(S.spelare)
	RunService._server = false
end

local function stall(spelare, pos)
	spelare.Character:FindFirstChild("HumanoidRootPart").CFrame = CFrame.new(pos)
end

--[[ ── SAMLA IN VARJE NEJ ────────────────────────────────────────────────
	Listan byggs av FAKTISKA anrop mot tjänsterna, inte av en tabell med
	förväntade nycklar. En nyckel som ingen kodväg längre använder ska inte
	kunna hålla svepet grönt. ]]
local nejen = {}
local function nej(vad, ok, skal, extra)
	table.insert(nejen, { vad = vad, ok = ok, skal = skal, extra = extra })
end

print("\n── Driver nej-vägarna genom tjänsterna ──")
do
	local S = nySession("EnSvep", 9401)
	local fas1 = Preparation.stegFaser()[1]
	local moment1 = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), fas1.id)
	local sista = Preparation.stegFaser()[#Preparation.stegFaser()]

	nej("uppsittning för tidigt", HorseService.tryMount(S.spelare, S.modell))
	nej("moment ur sista fasen först",
		GameplayService.moment(S.spelare, sista.id, Preparation.moment(sista.id)[1].id))
	nej("ogiltigt momentnamn", GameplayService.moment(S.spelare, fas1.id, "finns:inte"))
	nej("ogiltig indata", GameplayService.moment(S.spelare, 17, 42))
	nej("svar utan fynd", GameplayService.svara(S.spelare, "svar:1"))
	nej("eftervård utan ritt", GameplayService.eftervard(S.spelare, Pass.moment()[1].id))
	nej("avsluta pass som inte är klart", GameplayService.avslutaPass(S.spelare))

	--[[ Avståndet: samma anrop, 40 studs bort. ]]
	stall(S.spelare, vec(40, 0, 0))
	nej("skötselmoment för långt bort", GameplayService.moment(S.spelare, fas1.id, moment1.id))
	nej("uppsittning för långt bort", HorseService.tryMount(S.spelare, S.modell))
	stall(S.spelare, vec(6, 0, 0))

	--[[ Dubbeltryck: gör momentet och gör det igen. ]]
	GameplayService.moment(S.spelare, fas1.id, moment1.id)
	nej("dubbeltryck", GameplayService.moment(S.spelare, fas1.id, moment1.id))

	--[[ Fel häst: en andra rigg med annan identitet. ]]
	local annanId
	for id in pairs(UBRFSpel.hastar) do
		if id ~= S.hastId then annanId = id break end
	end
	local annan = HastRigg.bygg(annanId, tostring(annanId), CFrame.new(vec(3, 0, 0)))
	annan.Parent = workspace
	Taggar:AddTag(annan, "Horse")
	nej("fel häst", HorseService.tryMount(S.spelare, annan))

	--[[ Hästsystemets egna nej, utan G01-grinden i vägen. ]]
	HorseService.setMountGate(nil)
	local oregistrerad = HastRigg.bygg(S.hastId, "Oregistrerad", CFrame.new(vec(9, 0, 0)))
	oregistrerad.Parent = workspace
	nej("oregistrerad häst", HorseService.tryMount(S.spelare, oregistrerad))
	nej("upptagen häst", (function()
		HorseService.tryMount(S.spelare, S.modell)
		local annanSpelare = { Name = "Andra", UserId = 9402,
			Character = nyKaraktar(vec(4, 0, 0)),
			CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
		return HorseService.tryMount(annanSpelare, S.modell)
	end)())
	nej("rider redan", HorseService.tryMount(S.spelare, annan))
	HorseService.dismount(S.spelare)
	local utanKropp = { Name = "Kroppslos", UserId = 9403, Character = nil,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
	nej("ingen karaktär", HorseService.tryMount(utanKropp, S.modell))

	check("svepet drev tillräckligt många nej", #nejen >= 14, #nejen .. " nej")
	local allaNej = true
	for _, n in ipairs(nejen) do
		if n.ok ~= false then allaNej = false end
	end
	check("och varje väg svarade faktiskt NEJ", allaNej,
		(function()
			local kvar = {}
			for _, n in ipairs(nejen) do
				if n.ok ~= false then table.insert(kvar, n.vad) end
			end
			return table.concat(kvar, ", ")
		end)())
	stadaSession(S)
end

--[[ ── VÄLFÄRDSSTOPPET: RAM OCH MENING, BÅDA PÅ SPELARENS SPRÅK ────────
	Reviewen listar välfärdsstoppet uttryckligen, och det är det svåraste
	fallet: ramen ("Ridläraren tar över …") är gränssnitt, medan fyndets
	mening kommer ur skötselkanonen. Före produktbeslutet i #162 var bara
	ramen engelsk och meningen svensk. Nu ska BÅDA byta språk, och det är
	det den här sektionen mäter. Fallet finns bara från pass 2, så
	sessionen förbereds med en sparfil där hästen bär ett fynd. ]]
print("\n── Välfärdsstoppet, med fynd ──")
do
	local ID = 9410
	local hast = Stallet.tilldelaLedig(ID, {}, {})
	local fyndPass
	for pnr = 2, 40 do
		if Preparation.fyndFor(hast, pnr) then fyndPass = pnr break end
	end
	check("det finns ett pass där hästen bär ett fynd", fyndPass ~= nil,
		string.format("%s, pass %s", tostring(hast), tostring(fyndPass)))

	local S = nySession("EnFynd", ID, function(spelare)
		local sav = Sparning.tom()
		sav.pass = (fyndPass or 2) - 1
		sav.forstaDagen = { klar = true, hastId = Stallet.FORSTA_DAGEN_HAST }
		__datastore._data["spelare_" .. spelare.UserId] = Sparning.tillRad(sav)
	end)
	local st = GameplayService.stateFor(S.spelare)
	--[[ Hälsa, hitta fyndet, svara rätt → arbetet stoppas. ]]
	local halsa = Preparation.stegFaser()[1]
	while true do
		local m = Preparation.nastaMoment(GameplayService.stateFor(S.spelare), halsa.id)
		if not m then break end
		if not GameplayService.moment(S.spelare, halsa.id, m.id) then break end
	end
	for _, m in ipairs(Preparation.moment("visitera")) do
		GameplayService.moment(S.spelare, "visitera", m.id)
	end
	local ratt
	for _, sv in ipairs(Preparation.fyndSvar()) do
		if not sv.fel then ratt = sv break end
	end
	GameplayService.svara(S.spelare, ratt.id)
	check("arbetet är stoppat av välfärdsskäl",
		GameplayService.statusFor(S.spelare) == Preparation.STATUS.STOPPAD,
		tostring(GameplayService.statusFor(S.spelare)))

	local okV, skalV, argV = HorseService.tryMount(S.spelare, S.modell)
	nej("uppsittning efter välfärdsstopp", okV, skalV, argV)
	check("stoppets skäl är en RAM som nyckel plus kanonmeningen som argument",
		skalV == "forb.lararen_tar_over" and Preparation.arKanontext(argV),
		string.format("%s + %s", tostring(skalV), tostring(argV)))

	Sprak.satLocale("en-us")
	local text = PreparationController.skalText(skalV, argV)
	Sprak.satLocale("sv-se")
	local svText = PreparationController.skalText(skalV, argV)
	--[[ RAMEN mäts mot katalogens engelska ram, inte mot en handskriven
		sträng. MENINGEN mäts mot kanonens engelska fyndtext — och att den
		inte längre bär en enda svensk bokstav är det produktbeslutet
		ändrade. ]]
	local enRam = Sprak.iSprak("en", "forb.lararen_tar_over"):gsub("%%s", "")
	check("ramen är ENGELSK på en-us",
		string.find(text, (enRam:gsub("(%W)", "%%%1")):sub(1, 30)) ~= nil,
		string.format("%q", text))
	local fyndId = Preparation.fyndFor(hast, fyndPass or 2)
	local enFynd = (UBRFSkotsel.visitation.fyndEn or {})[fyndId or ""]
	check("och FYNDETS MENING är också engelsk, inte kvarlämnad svenska",
		type(enFynd) == "string" and string.find(text, (enFynd:gsub("(%W)", "%%%1")), 1) ~= nil
			and not string.find(text, SVENSKA_TECKEN),
		string.format("fynd %s → %q", tostring(fyndId), tostring(enFynd)))
	check("och svensk på sv-se", text ~= svText,
		string.format("en %q · sv %q", text:sub(1, 60), svText:sub(1, 60)))
	stadaSession(S)
end

--[[ ── HELA DAGEN PÅ en-US ────────────────────────────────────────────────

	PRODUKTBESLUTET i #162 (punkt 4): en full First Playable-genomgång på
	`en-US`, negativa vägar inkluderade, ska FÄLLA på svensk spelartext
	eller oöversatt fallback.

	Nej-vägarna mäts längre ner. Det här är den POSITIVA vägen — och den
	var hålet: en spelare som gör rätt hela dagen ser aldrig ett enda nej,
	men läser fas efter fas, moment efter moment och hela eftervården.
	Sveper man bara avslagen kan hela undervisningstexten vara svensk i en
	engelsk klient utan att någon grind säger ifrån.

	Provet läser det HUD:EN RITADE (`_ritadText`), inte vyn det skickade
	in. En översättning som aldrig når TextLabel:en är ingen översättning. ]]
print("\n── en-us: hela dagen, inte bara nejen ──")
do
	local S = nySession("EnDagen", 9411)
	local hastnamn
	do
		local dagens = StallService.hastFor(S.spelare)
		hastnamn = dagens and dagens.namn
	end
	check("sessionen har en häst med ett egennamn",
		type(hastnamn) == "string" and hastnamn ~= "", tostring(hastnamn))

	--[[ Ritar en vy på ett locale och lämnar tillbaka varje ritad sträng. ]]
	local function ritaPa(locale)
		Sprak.satLocale(locale)
		PreparationController.tillampa(Preparation.vy(
			GameplayService.stateFor(S.spelare),
			GameplayService.statusFor(S.spelare), os.clock(), hastnamn))
		local ut = PreparationController._ritadText()
		Sprak.satLocale("sv-se")
		return ut
	end

	local svenskaFynd, vyer, tvillingar = {}, 0, {}
	local function svep(vad)
		vyer += 1
		local en = ritaPa("en-us")
		local sv = ritaPa("sv-se")
		for _, rad in ipairs(en) do
			if svenskSpelartext(rad) then
				table.insert(svenskaFynd, string.format("%s → %q", vad, rad))
			end
			--[[ `%N` kvar betyder att hästens namn aldrig sattes in — det
				var precis felet Roblox bar innan produktbeslutet. ]]
			if string.find(rad, "%%N") then
				table.insert(svenskaFynd, string.format("%s → osatt %%N i %q", vad, rad))
			end
		end
		--[[ FÄLT FÖR FÄLT, inte vy för vy. En enda oöversatt rad gör inte
			hela vyn identisk, och just den luckan var det mutationen
			ovan gled igenom. Tomma fält och rena egennamn hoppas över:
			hästen heter samma sak på båda språken. ]]
		for i, rad in ipairs(en) do
			local svRad = sv[i]
			if rad ~= "" and rad == svRad and string.find(rad, "%a")
				and not (hastnamn and string.find(rad, hastnamn, 1, true)) then
				table.insert(tvillingar, string.format("%s → %q", vad, rad))
			end
		end
	end

	--[[ Varje fas, varje moment, i den ordning dagen faktiskt spelas. ]]
	for _, fas in ipairs(Preparation.stegFaser()) do
		svep("fas " .. fas.id)
		local varv = 0
		while varv < 40 do
			varv += 1
			local st = GameplayService.stateFor(S.spelare)
			local m = Preparation.nastaMoment(st, fas.id)
			if not m then break end
			svep(string.format("%s/%s", fas.id, m.id))
			if not GameplayService.moment(S.spelare, fas.id, m.id) then break end
		end
	end
	svep("klar att sitta upp")

	--[[ EFTERVÅRDEN är andra halvan av dagen och ritas av en EGEN vy
		(`tillampaPass`). Den låg utanför svepet i första utkastet, och det
		hade varit ett hål av precis den sort som den här grinden finns
		för: momenten går genom samma översättare, men "går genom samma
		kod" är ett antagande tills det är mätt. Passet drivs framåt direkt
		på `Pass`, för uppsittning och avsittning mäts på annat håll. ]]
	do
		local passState = Pass.nyState(S.hastId, Pass.byggId(9411, S.hastId, 1))
		Pass.vidUppsittning(passState)
		Pass.vidAvsittning(passState)
		local function ritaPassPa(locale)
			Sprak.satLocale(locale)
			PreparationController.tillampaPass(Pass.vy(passState, os.clock()))
			local ut = PreparationController._ritadText()
			Sprak.satLocale("sv-se")
			return ut
		end
		local varv = 0
		while varv < 20 do
			varv += 1
			vyer += 1
			local en, sv = ritaPassPa("en-us"), ritaPassPa("sv-se")
			for _, rad in ipairs(en) do
				if svenskSpelartext(rad) then
					table.insert(svenskaFynd, string.format("eftervård → %q", rad))
				end
			end
			for i, rad in ipairs(en) do
				if rad ~= "" and rad == sv[i] and string.find(rad, "%a")
					and not (hastnamn and string.find(rad, hastnamn, 1, true)) then
					table.insert(tvillingar, string.format("eftervård → %q", rad))
				end
			end
			local m = Pass.nastaMoment(passState)
			if not m then break end
			if not Pass.utfor(passState, m.id) then break end
		end
		check("eftervården sveptes också", varv > 1, varv .. " eftervårdsvyer")
	end

	check("hela dagen sveptes, inte bara en vy", vyer >= 10, vyer .. " vyer")
	check("ingen svensk bokstav i något ritat fält på en-us", #svenskaFynd == 0,
		#svenskaFynd > 0 and table.concat(svenskaFynd, " · ")
			or (vyer .. " vyer lästa på engelska"))
	--[[ EN TYST FALLBACK ser ut som en översättning. Är den engelska vyn
		tecken för tecken identisk med den svenska har ingenting bytts. ]]
	check("inget ritat fält är identiskt på de två språken", #tvillingar == 0,
		#tvillingar > 0 and table.concat(tvillingar, " · ") or "varje fält skiljer sig")
	stadaSession(S)
end

--[[ ── VARJE SKÄL ÄR EN NYCKEL ELLER UTTRYCKLIG KANONTEXT ─────────────── ]]
print("\n── Varje nej är en nyckel, inte prosa ──")
do
	local rap = {}
	for _, n in ipairs(nejen) do
		local skal = n.skal
		local nyckel = type(skal) == "string" and Sprak.finns(skal)
		local kanon = Preparation.arKanontext(skal)
		if not (nyckel or kanon) then
			table.insert(rap, string.format("%s → %q", n.vad, tostring(skal)))
		end
	end
	check("inget nej är rå prosa — allt är nyckel eller kanontext", #rap == 0,
		#rap > 0 and table.concat(rap, " · ") or (#nejen .. " nej granskade"))
end

--[[ ── OCH DEN ENGELSKA UTSKRIFTEN ÄR ENGELSK ──────────────────────────── ]]
print("\n── en-us: ingen svensk spelartext på nej-vägarna ──")
do
	Sprak.satLocale("en-us")
	local svenska, kanonvagar = {}, 0
	for _, n in ipairs(nejen) do
		local text = PreparationController.skalText(n.skal, n.extra)
		--[[ KANONTEXTEN HAR INGEN DISPENS LÄNGRE.

			Här stod ett undantag: var skälet eller argumentet kanontext
			fick svaret vara svenskt, och posten räknades som redovisad
			skuld. PRODUKTBESLUTET i #162 tog bort skulden — kanonen har
			engelska poster — och därmed undantaget. Ett kanonskäl mäts nu
			som alla andra, och det är just de vägarna som skulle ha varit
			svenska om översättningen inte nått fram. ]]
		if Preparation.arKanontext(n.skal) or Preparation.arKanontext(n.extra) then
			kanonvagar += 1
		end
		if string.find(text, SVENSKA_TECKEN) then
			table.insert(svenska, string.format("%s → %q", n.vad, text))
		end
	end
	Sprak.satLocale("sv-se")
	check("ingen svensk text i något nej på en-us — kanontexten inräknad",
		#svenska == 0,
		#svenska > 0 and table.concat(svenska, " · ")
			or string.format("%d nej lästa på engelska, varav %d går genom kanonen",
				#nejen, kanonvagar))
	check("och kanonvägarna finns med i svepet — annars mäter raden ovan inget",
		kanonvagar > 0, kanonvagar .. " kanonskäl")
end

--[[ ── OCH SVENSKAN FINNS KVAR FÖR SVENSKA SPELARE ─────────────────────── ]]
print("\n── sv-se: samma nej på svenska ──")
do
	Sprak.satLocale("sv-se")
	local ejSvenska = {}
	for _, n in ipairs(nejen) do
		local text = PreparationController.skalText(n.skal, n.extra)
		local en = if type(n.skal) == "string" and Sprak.finns(n.skal)
			then Sprak.iSprak("en", n.skal) else nil
		--[[ Nyckeln ska ge ETT ord på svenska och ett ANNAT på engelska.
			Är de lika är posten oöversatt, och då är en-us-raden ovan grön
			av fel skäl. ]]
		if en and text == en and not Preparation.arKanontext(n.skal) then
			table.insert(ejSvenska, string.format("%s → %q", n.vad, text))
		end
	end
	check("varje översatt nej skiljer sig mellan språken", #ejSvenska == 0,
		#ejSvenska > 0 and table.concat(ejSvenska, " · ") or "alla skiljer sig")
end


--[[ ── LEKTIONSKORTET PÅ EN-US (#162, lokal Studio-QA på 9b5a570) ──────

	Mätt i runtime: kortets ram var engelsk ("UGNETA · RIDING INSTRUCTOR",
	"Continue to start the lesson") medan rubriken och BÅDA punkterna var
	svenska — "Halt → skritt", "Titta dit du ska.", "En tydlig skänkel —
	vänta på svaret." De låg som literaler i `RidKanon.OVNINGAR` och nådde
	aldrig katalogen.

	Den här mätningen fäller exakt det: varje övning i kanonens ORDNING
	måste ha rubrik och punkter i katalogen, den engelska raden får inte
	bära svenska tecken, och den måste faktiskt SKILJA SIG från den svenska.
	Utan det sista går en oöversatt sträng igenom bara för att den råkar
	sakna å, ä och ö. ]]
do
	--[[ `Sprak` och `RidKanon` är redan inlinade av build.py. ]]
	local UG = RidKanon.UGNETA
	local saknade, svenska, osarskilda = {}, {}, {}
	local provade = 0
	for _, ovId in ipairs((UG and UG.ORDNING) or {}) do
		for _, del in ipairs({ "rubrik", "p1", "p2" }) do
			local nyckel = ("ugneta.ovning.%s.%s"):format(ovId, del)
			if not Sprak.finns(nyckel) then
				table.insert(saknade, nyckel)
			else
				provade += 1
				local en = Sprak.iSprak("en", nyckel)
				local sv = Sprak.iSprak("sv", nyckel)
				if string.find(en, SVENSKA_TECKEN) then
					table.insert(svenska, nyckel .. " = " .. en)
				end
				if en == sv then table.insert(osarskilda, nyckel) end
			end
		end
	end
	check("lektionskortets övningar finns i katalogen", #saknade == 0,
		#saknade > 0 and table.concat(saknade, " · ") or (provade .. " strängar"))
	check("den engelska korttexten bär inga svenska tecken", #svenska == 0,
		#svenska > 0 and table.concat(svenska, " · ") or "rena")
	check("kortets engelska skiljer sig faktiskt från svenskan", #osarskilda == 0,
		#osarskilda > 0 and table.concat(osarskilda, " · ") or "alla översatta")

	--[[ Observationerna efter ett försök byggdes som svenska mallar i
		UgnetaController. Samma krav på dem. ]]
	local obsSaknade, obsSvenska = {}, {}
	for _, sort in ipairs({ "battre", "kvar", "bra", "jobba" }) do
		local nyckel = "ugneta.obs." .. sort
		if not Sprak.finns(nyckel) then
			table.insert(obsSaknade, nyckel)
		elseif string.find(Sprak.iSprak("en", nyckel), SVENSKA_TECKEN) then
			table.insert(obsSvenska, nyckel)
		end
	end
	check("observationsmallarna finns i katalogen och är engelska på en",
		#obsSaknade == 0 and #obsSvenska == 0,
		table.concat(obsSaknade, " · ") .. table.concat(obsSvenska, " · "))
end
if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nsprak-en.spec: alla gröna")
end
