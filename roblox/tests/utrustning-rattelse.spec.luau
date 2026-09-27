--!nostrict
--[[ FEL UTRUSTNING: VÄGLEDNING OCH EN RIKTIG ÅTERLÄMNING — docs/EQUIPMENT-GUIDANCE-CONTRACT.md.

	KOHERENS-bänken med tack-fas2:s uppställning: riktiga boxfronter ur den
	byggda anläggningen, hästar byggda med produktionens `HastRigg` vid sina
	egna fronter, `TackForradService.tagSadel/tagTrans` (fronternas
	handling), `GameplayService.sadla/transa` och den nya
	`GameplayService.lamnaTillbaka`. Klientens rättelse provas genom den
	riktiga `PreparationSync`-lyssnaren och `PreparationController.panel`,
	med en SYNTETISK vy (fält som servern skickar); antagandet redovisas.

	SKRIVEN FÖR SENARE KÖRNING (bygg nu, testa sist). Inte körd. ]]
local fails, total = 0, 0
local function check(namn, villkor, detalj)
	total += 1
	if not villkor then fails += 1 end
	print((if villkor then "  OK   " else "  FEL  ") .. namn .. (if detalj then "  " .. tostring(detalj) else ""))
end
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
RunService._server = true

local function nyKaraktar(pos)
	local k = Instance.new("Model"); k.Name = "Karaktar"
	local rot = Instance.new("Part"); rot.Name = "HumanoidRootPart"; rot.Size = Vector3.new(2, 2, 1)
	rot.CFrame = CFrame.new(pos); rot.Parent = k
	local torso = Instance.new("Part"); torso.Name = "UpperTorso"; torso.Size = Vector3.new(2, 2, 1)
	torso.CFrame = CFrame.new(pos); torso.Parent = k
	local hum = Instance.new("Humanoid"); hum.Name = "Humanoid"; hum.Parent = k
	k.Parent = workspace
	return k, rot
end
local function nySpelare(namn, userId, pos)
	local k, rot = nyKaraktar(pos)
	return { Name = namn, UserId = userId, Character = k,
		CharacterAdded = __signal_ny(), CharacterRemoving = __signal_ny() }, rot
end

TackForradService.start(GameplayService.valjEn)
GameplayService.start()

local hastar, ordning = {}, {}
do
	local mapp = TackForradService.mapp()
	if mapp then
		for _, f in ipairs(mapp:GetChildren()) do
			local id = f:IsA("Model") and tostring(f:GetAttribute("ForHast") or "")
			if id and id ~= "" and f.PrimaryPart and hastar[id] == nil then
				local m = HastRigg.bygg(id, id, CFrame.new(f.PrimaryPart.Position + Vector3.new(0, 0, 6)))
				if m then
					m.Parent = workspace
					m:SetAttribute("HorseId", id)
					CollectionService:AddTag(m, "Horse")
					hastar[id] = m
					table.insert(ordning, id)
				end
			end
			if #ordning >= 5 then break end
		end
	end
end
check("KONTROLL: five horses with box fronts and rigs", #ordning >= 5, #ordning)
local A, B, C, D = ordning[1], ordning[2], ordning[3], ordning[4]
local function front(id) return TackForradService.forHast(id).PrimaryPart.Position end
local function hast(id) return (hastar[id].PrimaryPart or hastar[id]:FindFirstChildWhichIsA("BasePart")).Position end
local function stall(rot, pos) rot.CFrame = CFrame.new(pos + Vector3.new(2, 0, 0)); rot.Position = pos + Vector3.new(2, 0, 0) end

-- ── Fel sadel → nej utan spår → återlämning vid rätt front → rätt sadel ──
local p, rot = nySpelare("Rattelse", 9501, front(A))
Players._spelare = { p }
check("KONTROLL: she takes horse A's saddle at A's front", TackForradService.tagSadel(p, A, "A") == true)
stall(rot, hast(B))
local fore = TackService.felAntal(p)
local ok1, skal1 = GameplayService.sadla(p, hastar[B])
check("a wrong saddle is refused with the fit reason", ok1 == false and skal1 == "tack.fel_sadel", skal1)
check("the refusal consumes nothing: she still carries A's saddle", TackService.barBuren(p, "sadel") == A)
check("the wrong horse is untouched", TackService.sadlad(hastar[B]) == false
	and TackService.harTack(hastar[B], "underlagg") == false)
check("the diagnostic counter counts it", TackService.felAntal(p) == fore + 1)
local okFar, skalFar = GameplayService.lamnaTillbaka(p, "sadel", A)
check("returning far from A's front is refused with guidance", okFar == false
	and skalFar == "tack.ga_till_fronten" and TackService.barBuren(p, "sadel") == A)
local okStale, skalStale = GameplayService.lamnaTillbaka(p, "sadel", B)
check("a stale intent (another expected horse) is refused", okStale == false and skalStale == "tack.bar_inte_den")
stall(rot, front(A))
local felFore = TackService.felAntal(p)
local okR, skalR = GameplayService.lamnaTillbaka(p, "sadel", A)
check("at A's front the saddle is hung back", okR == true, skalR)
check("her hands are empty, the front shows it and ownership is cleared",
	TackService.barBuren(p, "sadel") == nil and TackForradService.paFronten(A, "sadel") == true
	and GameplayService.barasAv("sadel", A) == nil)
check("returning never touches the diagnostic counter", TackService.felAntal(p) == felFore)
local okIngen, skalIngen = GameplayService.lamnaTillbaka(p, "sadel", A)
check("returning with nothing carried is refused", okIngen == false and skalIngen == "tack.bar_inget")
stall(rot, front(B))
check("she fetches horse B's own saddle", TackForradService.tagSadel(p, B, "B") == true)
stall(rot, hast(B))
local okS, skalS = GameplayService.sadla(p, hastar[B])
check("and saddles B through the normal path", okS == true and TackService.sadlad(hastar[B]), skalS)

-- ── Fel träns → återlämning → rätt träns ──
stall(rot, front(C))
check("KONTROLL: she takes horse C's bridle", TackForradService.tagTrans(p, C, "C") == true)
stall(rot, hast(B))
local okT, skalT = GameplayService.transa(p, hastar[B])
check("a wrong bridle is refused with its reason", okT == false and skalT == "tack.fel_trans", skalT)
check("the bridle is still carried", TackService.barBuren(p, "trans") == C and TackService.transad(hastar[B]) == false)
stall(rot, front(C))
check("C's bridle is hung back at C's front", GameplayService.lamnaTillbaka(p, "trans", C) == true
	and TackService.barBuren(p, "trans") == nil and TackForradService.paFronten(C, "trans") == true)
stall(rot, front(B))
check("KONTROLL: she fetches B's bridle", TackForradService.tagTrans(p, B, "B") == true)
stall(rot, hast(B))
check("and bridles B", GameplayService.transa(p, hastar[B]) == true and TackService.transad(hastar[B]))

-- ── Upptagen front, misslyckat släpp, två spelare, «Rida nu» ──
local q, rotQ = nySpelare("Andra", 9502, front(C))
Players._spelare = { p, q }
check("KONTROLL: the second player takes C's saddle", TackForradService.tagSadel(q, C, "C") == true)
TackForradService.satSynlig(C, "sadel", true) -- injicerat: en sadel hänger redan där
local okUpp, skalUpp = GameplayService.lamnaTillbaka(q, "sadel", C)
check("an occupied front is refused (no duplicate)", okUpp == false and skalUpp == "tack.front_upptagen"
	and TackService.barBuren(q, "sadel") == C)
TackForradService.satSynlig(C, "sadel", false)
local riktig = TackService.slappBuren
TackService.slappBuren = function() return false end -- injicerat släppfel
local okFel, skalFel = GameplayService.lamnaTillbaka(q, "sadel", C)
TackService.slappBuren = riktig
check("a failed release rolls back: front hidden again, still carried", okFel == false
	and skalFel == "tack.kunde_inte_slappas" and TackForradService.paFronten(C, "sadel") == false
	and TackService.barBuren(q, "sadel") == C and GameplayService.barasAv("sadel", C) == q)
local r3, rot3 = nySpelare("Tredje", 9503, front(C))
Players._spelare = { p, q, r3 }
local okAnnans, skalAnnans = GameplayService.lamnaTillbaka(r3, "sadel", C)
check("another player cannot return someone else's item", okAnnans == false and skalAnnans == "tack.bar_inget"
	and TackService.barBuren(q, "sadel") == C)
check("the carrier can return her own", GameplayService.lamnaTillbaka(q, "sadel", C) == true)
stall(rot3, front(D))
TackService.satBuren(r3, "sadel", D) -- «Rida nu»: buren utan ägarpost
local okRn, skalRn = GameplayService.lamnaTillbaka(r3, "sadel", D)
check("a stable-prepared (Rida nu) carried part is not returned through this path",
	okRn == false and skalRn == "tack.kan_inte_lamnas" and TackService.barBuren(r3, "sadel") == D)
TackService.slappBuren(r3, "sadel")

-- ── Klientens rättelse (riktig lyssnare och panel, syntetisk vy) ──
PreparationController.start()
local sync = Networking.get("PreparationSync")
local rev = 1000
local function vy(buren)
	rev += 1
	return { hastId = "hastB", hastnamn = "Bella", status = "preparing", moment = {}, steg = {},
		nasta = nil, redo = false, burenUtrustning = buren, rev = rev }
end
sync.OnClientEvent:Fire(vy({ hastId = "hastA", hastnamn = "Larry", delar = { "sadel" } }))
local r = PreparationController._rattelseForProv()
local pd = PreparationController.panel()
check("carrying another horse's saddle gives a correction with a return choice first",
	r ~= nil and r.hastId == "hastA" and r.typ == "sadel" and pd ~= nil and pd.val[1] ~= nil
	and pd.val[1].rattelse == true and pd.harVal == true)
check("the guidance names whose saddle it is", pd ~= nil and type(pd.text) == "string"
	and string.find(pd.text, "Larry", 1, true) ~= nil)
sync.OnClientEvent:Fire(vy(nil))
check("after the return the correction is gone", PreparationController._rattelseForProv() == nil
	and (PreparationController.panel().val[1] == nil or PreparationController.panel().val[1].rattelse ~= true))

if fails > 0 then error(tostring(fails) .. " FEL") end
print(string.format("\nUTRUSTNING-RATTELSE: %d prov, alla gröna", total))
