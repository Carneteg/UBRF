--!nostrict
--[[ D2c EFTER RITTEN — docs/D2C-AFTERCARE-CONTRACT.md.

	KEDJAN genom de RIKTIGA tjänsterna (Spar-, Stall-, Horse- och
	GameplayService) i det byggda ridhuset med de befintliga hindren:
	passet → skötseln → uppsittning (riding) → clear round anmälan →
	banskiss → startsignal → banan → resultat (bilden bär eftervården ur
	kanonen) → avsittning (aftercare) → eftervårdens moment → passet räknat
	EN gång. Och: en avsittning mitt i banan ger OCKSÅ eftervård.

	KOHERENS-bänken. Hästens läge sätts mellan hjärtslagen i ridhusets ram
	(syntetisk rutt, inte spelarens ridning). Ledningen till ridbanan drivs
	som i integration.spec (tjänstens egen följlogik avgör zonen). ]]
local fails, total = 0, 0
local function check(name, yes, detalj)
	total += 1
	if not yes then fails += 1 end
	print((if yes then "  OK   " else "  FEL  ") .. name .. (if detalj then "  " .. tostring(detalj) else ""))
end
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Tags = game:GetService("CollectionService")
local vec = Vector3.new
local RP = assert(Ridhusplats.los(workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")))
local G = ClearRoundLektion.GRANSER

local function nySpelare(namn, userId)
	local k = Instance.new("Model"); k.Name = namn
	local rot = Instance.new("Part"); rot.Name = "HumanoidRootPart"; rot.Size = vec(2, 2, 1); rot.Parent = k
	local hum = Instance.new("Humanoid"); hum.Name = "Humanoid"; hum.Parent = k
	local anim = Instance.new("Animator"); anim.Name = "Animator"; anim.Parent = hum
	return { Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }
end

-- En session som i integration.spec: tjänsterna i produktionens ordning.
local function nySession(namn, userId)
	__datastore.nollstall()
	Players.PlayerAdded:nollstall(); Players.PlayerRemoving:nollstall()
	Run._server = true; Run.Heartbeat:nollstall()
	Players._spelare = {}
	SparService._glomHookarForProv()
	local spelare = nySpelare(namn, userId)
	SparService._glomForProv(spelare)
	SparService.start(); StallService.start(); HorseService.setMountGate(nil); HorseService.start()
	GameplayService.start()
	Players._spelare = { spelare }
	Players.PlayerAdded:Fire(spelare); Players.PlayerAdded:slutfor()
	local hastId = StallService.hastIdFor(spelare)
	local h = (UBRFSpel.hastar or {})[hastId]
	local modell = HastRigg.bygg(hastId, (h and h.namn) or hastId, CFrame.new(Ridhusplats.tillVarld(RP, vec(0, 0, 4))))
	modell.Parent = workspace; Tags:AddTag(modell, "Horse")
	-- Spelaren står bredvid hästen (skötselns närvarokrav), som i integration.spec.
	local rot = spelare.Character:FindFirstChild("HumanoidRootPart")
	local pp = modell.PrimaryPart.Position + vec(4, 0, 0)
	rot.CFrame = CFrame.new(pp); rot.Position = pp
	return { spelare = spelare, modell = modell, hastId = hastId }
end

local function skotsel(spelare)
	for _, fas in ipairs(Preparation.stegFaser()) do
		if fas.id == "leda" then
			local modell = GameplayService.modellFor(spelare)
			local zon = LedService.malzon()
			local rot = spelare.Character:FindFirstChild("HumanoidRootPart")
			if modell and zon and rot and modell.PrimaryPart then
				LedService.borja(spelare, modell, modell)
				local mx = (zon.x + zon.w / 2) * 3
				local mz = (170 - (zon.y + zon.h / 2)) * 3
				local hp, sp = vec(mx, modell.PrimaryPart.Position.Y, mz), vec(mx + 6, rot.Position.Y, mz)
				modell.PrimaryPart.CFrame = CFrame.new(hp); modell.PrimaryPart.Position = hp
				rot.CFrame = CFrame.new(sp); rot.Position = sp
				LedService._steg(1 / 30)
			end
		end
		if fas.id == "iordning" then
			local s0 = GameplayService.stateFor(spelare)
			GameplayService.valjUtrustning(spelare, "sadel", s0.hastId)
			GameplayService.valjUtrustning(spelare, "trans", s0.hastId)
		end
		while true do
			local m = Preparation.nastaMoment(GameplayService.stateFor(spelare), fas.id)
			if not m then break end
			local ok, skal = GameplayService.moment(spelare, fas.id, m.id)
			if not ok then return false, fas.id .. "/" .. m.id .. ": " .. tostring(skal) end
		end
	end
	return true
end

-- Ridhusets ram: roten flyttas mellan hjärtslagen, som i clearroundlektion.spec.
local S, sess, nu, rittId, seq
local function point(u, v)
	local a = Ridhusplats.tillVarld(RP, vec(u, 0, v))
	return vec(a.X, sess.rig.root.Position.Y, a.Z)
end
local function step(u, v)
	local a = point(u, v); sess.rig.root.CFrame = CFrame.new(a); sess.rig.root.Position = a
	sess.energi = 1; Run.Heartbeat:Fire(0.25)
	nu = { u = u, v = v }
end
local function till(u, v)
	local n = math.max(1, math.ceil(math.sqrt((u - nu.u) ^ 2 + (v - nu.v) ^ 2) / 0.8))
	local u0, v0 = nu.u, nu.v
	for i = 1, n do step(u0 + (u - u0) * i / n, v0 + (v - v0) * i / n) end
end
local function request(op)
	seq += 1
	return HorseService.voltLektionsBegaran(S.spelare, rittId, op, seq, "clearround")
end
local function spelareVidHasten()
	local rot = S.spelare.Character:FindFirstChild("HumanoidRootPart")
	local p = sess.rig.root.Position + vec(4, 0, 0)
	rot.CFrame = CFrame.new(p); rot.Position = p
end
-- Hindren ur registret (fyllt när HorseService startat), aldrig ur en lista.
local B, R
local function iRam(hid)
	local h = HinderObservation.register().hinder[hid]
	local c = Ridhusplats.tillLokal(RP, vec(h.x, h.y, h.z))
	return { u = c.X, v = c.Z }
end
local function uppOchIRidhuset()
	sess = HorseService.sessionFor(S.modell)
	nu = { u = 0, v = 4 }
	step(0, 4); spelareVidHasten()
	local ok, skal, marke = HorseService.tryMount(S.spelare, S.modell)
	rittId, seq = marke, 0
	B, R = iRam("ridhus_hinder_bla_24"), iRam("ridhus_hinder_rod_38")
	step(0, 4); step(0, 4)
	return ok, skal
end

local function tillStart() till(B.u, nu.v); till(B.u, B.v - 13) end
local function helaBanan()
	till(B.u, B.v - G.LINJE_M + 1)                                   -- startlinjen
	till(B.u, B.v + 4)                                               -- 1 blått mot C
	till(R.u, B.v + 4); till(R.u, R.v - 5); till(R.u, R.v + 4)       -- 2 rött mot C
	till(B.u, R.v + 4); till(B.u, B.v + 5); till(B.u, B.v - 4)       -- 3 blått mot A
	till(R.u, B.v - 4); till(R.u, R.v - 5); till(R.u, R.v + 4)       -- 4 rött mot C
	till(R.u, R.v + G.LINJE_M + 1)                                   -- mållinjen
end

-- Sessionens slut: spelaren lämnar och hästmodellen tas bort ur världen,
-- så att nästa session (samma häst ur stallet) binder sin egen modell.
local function stada()
	Players.PlayerRemoving:Fire(S.spelare); Players._spelare = {}; SparService._glomForProv(S.spelare)
	Tags:RemoveTag(S.modell, "Horse"); S.modell:Destroy()
end

print("\n── 1. Hela kedjan: pass → clear round → avsittning → eftervård → räknat en gång ──")
;(function()
	S = nySession("Eftervard", 9301)
	local okS, skalS = skotsel(S.spelare)
	check("skötseln genom tjänsten", okS == true, skalS)
	check("passet finns och väntar på ritten", GameplayService.passFor(S.spelare) ~= nil
		and GameplayService.passFor(S.spelare).lage == Pass.LAGE.FORE, tostring(GameplayService.passFor(S.spelare)
		and GameplayService.passFor(S.spelare).lage))
	local okM, skalM = uppOchIRidhuset()
	check("uppsittningen i ridhuset går igenom, passet rider", okM == true
		and GameplayService.passFor(S.spelare).lage == Pass.LAGE.RIDER, tostring(skalM))
	tillStart()
	local skrivFore = __datastore.forsok and __datastore.forsok.skriv or 0
	local _, _, b0 = request("sync")
	check("ingen eftervård i bilden före anmälan", b0 and b0.lage == "ready" and b0.eftervard == nil)
	local _, _, b1 = request("anmal")
	check("anmälan: startlistan, ingen eftervård", b1 and b1.lage == "startlista" and b1.eftervard == nil)
	local _, _, b2 = request("ga_banan")
	check("banskissen: ingen eftervård", b2 and b2.lage == "banskiss" and b2.eftervard == nil)
	local okSt, _, b3 = request("start")
	check("startsignalen: ingen eftervård", okSt and b3.lage == "to_start" and b3.eftervard == nil)
	till(B.u, B.v - G.LINJE_M + 1)
	local _, _, b4 = request("sync")
	check("på banan: ingen eftervård", b4 and b4.lage == "course" and b4.eftervard == nil, b4 and b4.lage)
	nu = { u = B.u, v = B.v - G.LINJE_M + 1 }
	till(B.u, B.v + 4)
	till(R.u, B.v + 4); till(R.u, R.v - 5); till(R.u, R.v + 4)
	till(B.u, R.v + 4); till(B.u, B.v + 5); till(B.u, B.v - 4)
	till(R.u, B.v - 4); till(R.u, R.v - 5); till(R.u, R.v + 4)
	till(R.u, R.v + G.LINJE_M + 1)
	local _, _, b = request("sync")
	check("resultatet: complete, inga observerade fel", b and b.lage == "complete" and b.resultat
		and b.resultat.utfall == "inga_observerade_fel", b and b.lage)
	-- Eftervården i bilden är kanonens, i kanonens ordning.
	local kanon = Pass.moment()
	local lika = b and type(b.eftervard) == "table" and #b.eftervard == #kanon and #kanon == 5
	if lika then
		for i, m in ipairs(kanon) do
			local e = b.eftervard[i]
			if not (e.id == m.id and e.namn == m.namn and type(e.namnEn) == "string" and e.namnEn ~= "") then lika = false end
		end
	end
	check("resultatbilden bär eftervårdens fem moment, i kanonens ordning, med sv och en", lika,
		b and b.eftervard and (function() local t = {} for _, e in ipairs(b.eftervard) do table.insert(t, e.id) end
			return table.concat(t, ",") end)())
	check("och inget i bilden säger att passet redan räknats", b ~= nil and b.passRaknat == nil and b.rosett == nil)
	check("clear round, anmälan till resultat, skrev ingenting i lagret",
		(__datastore.forsok and __datastore.forsok.skriv or 0) == skrivFore)
	-- Avsittning: passet går in i eftervården genom produktionens krok.
	check("avsittningen går igenom", HorseService.dismount(S.spelare) == true)
	check("passet gick vidare till eftervården", GameplayService.passFor(S.spelare).lage == Pass.LAGE.EFTERVARD,
		tostring(GameplayService.passFor(S.spelare).lage))
	spelareVidHasten()
	local allaOk, sista = true, nil
	for _, m in ipairs(Pass.moment()) do
		local okE, skalE = GameplayService.eftervard(S.spelare, m.id)
		if not okE then allaOk = false; sista = m.id .. ": " .. tostring(skalE) end
	end
	check("hela eftervården går igenom vid hästen", allaOk, sista)
	local save = SparService.save(S.spelare)
	check("passet är räknat EN gång", save ~= nil and save.pass == 1, save and tostring(save.pass))
	check("och markerat räknat", GameplayService.passFor(S.spelare).lage == Pass.LAGE.RAKNAT)
	stada()
end)()

print("\n── 2. Avsittning mitt i banan: «avbruten» — och hästen får ändå sin eftervård ──")
;(function()
	S = nySession("Avbruten", 9302)
	local okS2, skalS2 = skotsel(S.spelare)
	check("skötseln genom tjänsten", okS2 == true, skalS2)
	local okM2, skalM2 = uppOchIRidhuset()
	check("uppsittningen", okM2 == true, skalM2)
	tillStart(); request("anmal"); request("ga_banan"); request("start")
	till(B.u, B.v - G.LINJE_M + 1); till(B.u, B.v + 4)
	check("mitt i banan", RidForsok.aktivt(rittId) ~= nil)
	check("avsittningen går igenom", HorseService.dismount(S.spelare) == true)
	local avb = ClearRoundLektion._senasteForProv(S.spelare.UserId)
	check("utfallet är «avbruten»", avb ~= nil and avb.utfall == "avbruten" and avb.orsak == "avsittning")
	check("och passet gick ändå till eftervården", GameplayService.passFor(S.spelare).lage == Pass.LAGE.EFTERVARD,
		tostring(GameplayService.passFor(S.spelare).lage))
	spelareVidHasten()
	local allaOk = true
	for _, m in ipairs(Pass.moment()) do
		if not GameplayService.eftervard(S.spelare, m.id) then allaOk = false end
	end
	check("eftervården går igenom och passet räknas", allaOk and SparService.save(S.spelare).pass == 1)
	stada()
end)()

print("\n── 3. Resultatkortet: raden ur serverns bild ──")
;(function()
	local A = LektionsAterkoppling
	local function bild(eftervard, lage)
		local r = { forsokId = "f1", rittId = "r1", ovning = "clearround", bedomning = "forenklad", forsokNr = 1,
			utfall = "inga_observerade_fel", tid = 31 }
		return { typ = "clearround", lage = lage or "complete", forsokId = "f1", rittId = "r1",
			resultat = r, eftervard = eftervard }
	end
	local kanon = {}
	for _, e in ipairs(Pass.EFTERVARD) do table.insert(kanon, { id = e.id, namn = e.namn, namnEn = e.namnEn }) end
	local kontext = { typ = "clearround", ritt = "r1" }
	Sprak.satVal("sv")
	local t = A.text(bild(kanon), kontext)
	check("sv: raden med kanonens namn i ordning", t ~= nil and string.find(t,
		"eftervården väntar: Lossa gjorden · Ta av sadeln · Ta av tränset · Känn igenom benen · Vatten och hö.", 1, true) ~= nil, t)
	Sprak.satVal("en")
	t = A.text(bild(kanon), kontext)
	check("en: the aftercare line", t ~= nil and string.find(t,
		"the aftercare is waiting: Loosen the girth · Take off the saddle", 1, true) ~= nil, t)
	Sprak.satVal("sv")
	local annan = { { id = "x", namn = "Borsta", namnEn = "Brush" }, { id = "y", namn = "Filt på", namnEn = "Rug on" } }
	t = A.text(bild(annan), kontext)
	check("raden följer bilden (deklarerad annan lista syns ordagrant)", t ~= nil
		and string.find(t, "eftervården väntar: Borsta · Filt på.", 1, true) ~= nil, t)
	t = A.text(bild(nil), kontext)
	check("utan eftervård i bilden: ingen rad", t ~= nil and string.find(t, "eftervården", 1, true) == nil, t)
	t = A.text(bild({ { id = "x", namn = "" } }), kontext)
	check("trasig lista: ingen rad", t ~= nil and string.find(t, "eftervården", 1, true) == nil, t)
	check("aldrig i banans läge", A.text(bild(kanon, "course"), kontext) == nil)
end)()

if fails > 0 then error(("%d mätning(ar) föll."):format(fails), 0) end
print(string.format("\nclearround-eftervard.spec: %d prov, alla gröna", total))
