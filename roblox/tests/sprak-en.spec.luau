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
	local svenska, kanonskuld = {}, {}
	for _, n in ipairs(nejen) do
		local text = PreparationController.skalText(n.skal, n.extra)
		if Preparation.arKanontext(n.skal) then
			table.insert(kanonskuld, string.format("%s → %q", n.vad, text))
		elseif string.find(text, SVENSKA_TECKEN) then
			table.insert(svenska, string.format("%s → %q", n.vad, text))
		end
	end
	Sprak.satLocale("sv-se")
	check("ingen svensk text i något nej på en-us", #svenska == 0,
		#svenska > 0 and table.concat(svenska, " · ")
			or ((#nejen - #kanonskuld) .. " nej lästa på engelska"))
	--[[ Kanonskulden REDOVISAS. Att listan får finnas är ett beslut; att
		den skulle vara tyst är det inte. ]]
	if #kanonskuld > 0 then
		print("       redovisad kanonskuld på nej-vägarna:")
		for _, r in ipairs(kanonskuld) do print("         · " .. r) end
	end
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

if fails > 0 then
	print(string.format("\n%d mätning(ar) föll.", fails))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätning(ar) föll."):format(fails), 0)
else
	print("\nsprak-en.spec: alla gröna")
end
