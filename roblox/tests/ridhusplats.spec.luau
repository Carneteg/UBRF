--[[ RIDHUSPLATS — #264 INFRA-PLATS1.

	Körs i GESTALT-bänken ovanpå den FÄRDIGBYGGDA och speglade anläggningen:
	`Ridhusplats` löser upp platsen ur de byggda delarna, och Ugnetas riktiga
	väg (`UgnetaGestalt.plats`/`visa`) läser den. Måtten jämförs med
	källdatan (`UBRFKomplex.ridhus`). Blocken med syntetiska delar prövar
	flyttad/vriden byggnad och ogiltigt underlag genom samma produktionsmodul.

	EVIDENSNIVÅ: BANK_ONLY. Ingen motor, ingen visuell kvalitet, inget spel. ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, detalj and ("  " .. tostring(detalj)) or ""))
	else
		fel += 1
		print(("  FEL  %s — %s"):format(vad, tostring(detalj)))
	end
end
local function nara(a, b, tol) return a ~= nil and b ~= nil and math.abs(a - b) <= (tol or 1e-6) end
local function naraV(a, b, tol)
	return a ~= nil and b ~= nil and nara(a.X, b.X, tol) and nara(a.Y, b.Y, tol) and nara(a.Z, b.Z, tol)
end
local function v3(p) return p and ("(%.3f, %.3f, %.3f)"):format(p.X, p.Y, p.Z) or "nil" end

local M = 3
local hus = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local R = UBRFKomplex.ridhus

print("\n── Det byggda ridhuset ──")
local rp, skal = Ridhusplats.los(hus)
prova("platsen löses ur det byggda", rp ~= nil, skal)
local bana = hus:FindFirstChild("Ridbanan")
local lay = hus:FindFirstChild("Dressyrlayout 20x60")
if rp then
	prova("stabila id:n på banan och layouten", rp.bana.id == "ridhus_bana" and rp.dressyr.id == "ridhus_dressyr"
		and bana:GetAttribute("PlatsId") == "ridhus_bana" and lay:GetAttribute("PlatsId") == "ridhus_dressyr")
	prova("enheter: världen i studs, 3 studs per meter", rp.enhet == "studs" and rp.studsPerMeter == M)
	prova("layoutens mått är källans 20 × 60 m", nara(rp.dressyr.halvLangs * 2 / M, R.dressyr.h, 1e-6)
		and nara(rp.dressyr.halvTvars * 2 / M, R.dressyr.w, 1e-6),
		("%.2f × %.2f m"):format(rp.dressyr.halvTvars * 2 / M, rp.dressyr.halvLangs * 2 / M))
	prova("banans mått är källans 20 × 65,53 m", nara(rp.bana.halvLangs * 2 / M, R.bana.h, 1e-6)
		and nara(rp.bana.halvTvars * 2 / M, R.bana.w, 1e-6))
	prova("A → C följer den speglade världen: A söderut vid +Z, C mot −Z", naraV(rp.motC, Vector3.new(0, 0, -1), 1e-6),
		v3(rp.motC))
	--[[ A-förankringen: banan och layouten börjar på samma källkoordinat
		(y = 0,15 m), så banans A-ände och layoutens A-kant sammanfaller. ]]
	local banansA = rp.bana.centrum - rp.motC * rp.bana.halvLangs
	prova("layoutens A-kant ligger där banans A-ände ligger (källan: samma y)",
		nara(rp.dressyr.A.X, banansA.X, 1e-6) and nara(rp.dressyr.A.Z, banansA.Z, 1e-6),
		v3(rp.dressyr.A) .. " mot " .. v3(banansA))
	prova("golvet är sandens överkant", nara(rp.golvY, bana.Position.Y + bana.Size.Y / 2, 1e-6))

	print("\n── Lokalt och världsläge ──")
	prova("A är lokalt origo", naraV(Ridhusplats.tillLokal(rp, rp.dressyr.A), Vector3.new(0, 0, 0), 1e-6))
	prova("C ligger 60 m längs", naraV(Ridhusplats.tillLokal(rp, rp.dressyr.C), Vector3.new(0, 0, 60), 1e-6),
		v3(Ridhusplats.tillLokal(rp, rp.dressyr.C)))
	local okRund = true
	for _, l in ipairs({ Vector3.new(0, 0, 0), Vector3.new(-9.5, 0, 12), Vector3.new(7, 1.2, 63), Vector3.new(3, 0, -2) }) do
		if not naraV(Ridhusplats.tillLokal(rp, Ridhusplats.tillVarld(rp, l)), l, 1e-6) then okRund = false end
	end
	prova("lokalt → värld → lokalt är identitet", okRund)

	print("\n── Banan och layouten är skilda ytor ──")
	local bortomC = Ridhusplats.tillVarld(rp, Vector3.new(0, 0, 62))
	prova("62 m från A: på banan, inte på layouten", Ridhusplats.inom(rp, "bana", bortomC)
		and not Ridhusplats.inom(rp, "dressyr", bortomC))
	prova("C-linjen räknas till layouten", Ridhusplats.inom(rp, "dressyr", Ridhusplats.tillVarld(rp, Vector3.new(0, 0, 60))))
	prova("bakom A: varken bana eller layout", not Ridhusplats.inom(rp, "bana", Ridhusplats.tillVarld(rp, Vector3.new(0, 0, -0.5)))
		and not Ridhusplats.inom(rp, "dressyr", Ridhusplats.tillVarld(rp, Vector3.new(0, 0, -0.5))))
	prova("utanför långsidan: inte på banan", not Ridhusplats.inom(rp, "bana", Ridhusplats.tillVarld(rp, Vector3.new(10.5, 0, 30))))
	prova("okänd yta är aldrig inom", not Ridhusplats.inom(rp, "hage", rp.dressyr.A))
end

print("\n── Ugneta genom platsgrunden ──")
do
	local P = RidKanon.UGNETA.PLATS
	local plats = UgnetaGestalt.plats(hus)
	prova("Ugnetas plats kommer ur platsgrunden", plats ~= nil and rp ~= nil
		and naraV(plats.pos, Ridhusplats.tillVarld(rp, Vector3.new((P.u - 0.5) * P.bredd, 0, P.langd + P.bortomC)), 1e-6))
	local lokal = plats and Ridhusplats.tillLokal(rp, plats.pos)
	prova("hon står mitt på och P.bortomC bortom C", lokal ~= nil and nara(lokal.X, 0, 1e-6)
		and nara(lokal.Z - P.langd, P.bortomC, 1e-6), v3(lokal))
	prova("på banan, inte på layouten, och på golvet", plats ~= nil and Ridhusplats.inom(rp, "bana", plats.pos)
		and not Ridhusplats.inom(rp, "dressyr", plats.pos) and nara(plats.pos.Y, rp.golvY, 1e-6))
	prova("hon tittar mot A", plats ~= nil and naraV(plats.motC, rp.motC, 1e-9))
	local m = UgnetaGestalt.visa(hus)
	prova("gestalten byggs på den platsen", m ~= nil and m.PrimaryPart ~= nil
		and nara(m.PrimaryPart.Position.X, plats.pos.X, 1e-6) and nara(m.PrimaryPart.Position.Z, plats.pos.Z, 1e-6))
	UgnetaGestalt.dolj()

	--[[ REDOVISAD MOTSÄGELSE: den gamla formeln, räknad här för att visa
		flytten — från biten `FindFirstChild("Sarg syd")` mot banans mitt. ]]
	local bit = hus:FindFirstChild("Sarg syd")
	local l = bana.Position - bit.Position
	local gammal = bit.Position + l.Unit * ((P.langd + P.bortomC) * M)
	local gl = Ridhusplats.tillLokal(rp, Vector3.new(gammal.X, rp.golvY, gammal.Z))
	print(("  mät  gammal plats %s = lokalt u %.2f m, v %.2f m; ny u 0,00 m, v %.2f m")
		:format(v3(gammal), gl.X, gl.Z, P.langd + P.bortomC))
	prova("MOTSÄGELSEN ÄR VERKLIG: den gamla platsen låg vid sidan av mittlinjen och innanför C",
		math.abs(gl.X) > 1 and gl.Z < P.langd and Ridhusplats.inom(rp, "dressyr",
			Vector3.new(gammal.X, rp.golvY, gammal.Z)),
		("u %.2f, v %.2f"):format(gl.X, gl.Z))
	local bitar = 0
	for _, d in ipairs(hus:GetChildren()) do if d.Name == "Sarg syd" then bitar += 1 end end
	prova("orsaken: 'Sarg syd' är sågad i flera bitar med samma namn", bitar >= 2, bitar)
end

print("\n── Flyttad och vriden byggnad ──")
local function syntetisk(pos, gir, banaFram)
	local m = Instance.new("Model")
	local bas = CFrame.new(pos) * CFrame.Angles(0, gir, 0)
	local lb = Instance.new("Part")
	lb.Name = "Ridbanan"
	lb.Size = Vector3.new(60, 0.18, 196.59)
	lb.CFrame = bas * CFrame.new(0, 0.09, if banaFram then -8.295 else 8.295)
	lb:SetAttribute("PlatsId", "ridhus_bana")
	lb.Parent = m
	local ll = Instance.new("Part")
	ll.Name = "Dressyrlayout 20x60"
	ll.Size = Vector3.new(60, 0.06, 180)
	ll.CFrame = bas * CFrame.new(0, 0.12, 0)
	ll:SetAttribute("PlatsId", "ridhus_dressyr")
	ll:SetAttribute("Forankring", "A")
	ll.Parent = m
	return m, lb, ll
end
do
	local th = math.rad(90)
	local m = syntetisk(Vector3.new(1000, 5, -300), th, true)
	local s = Ridhusplats.los(m)
	--[[ Lokalt −Z vriden 90° runt Y: (−sin θ, 0, −cos θ) = (−1, 0, 0). ]]
	prova("vriden 90°: A → C följer de vridna delarna", s ~= nil and naraV(s.motC, Vector3.new(-1, 0, 0), 1e-6),
		s and v3(s.motC))
	prova("och A-kanten flyttar med byggnaden (90 studs bakom layoutens mitt)",
		s ~= nil and nara(s.dressyr.A.X, 1090, 1e-6) and nara(s.dressyr.A.Z, -300, 1e-6),
		s and v3(s.dressyr.A))
	local l = s and Ridhusplats.tillLokal(s, Ridhusplats.tillVarld(s, Vector3.new(4, 0, 30)))
	prova("och lokalt ↔ värld stämmer i den vridna ramen", l ~= nil and naraV(l, Vector3.new(4, 0, 30), 1e-6))
	local m2 = syntetisk(Vector3.new(0, 0, 0), 0, false)
	local s2 = Ridhusplats.los(m2)
	prova("banan åt andra hållet: C byter håll (tecknet ur geometrin, inte ur ett fast origo)",
		s2 ~= nil and naraV(s2.motC, Vector3.new(0, 0, 1), 1e-6), s2 and v3(s2.motC))
end

print("\n── Ogiltigt underlag ger otillgängligt, aldrig en gissning ──")
do
	local function skalFor(m) local s, k = Ridhusplats.los(m); return s, k end
	local _, k0 = skalFor(nil)
	prova("ingen byggnad", k0 == "ingen_byggnad", k0)
	local m1, lb1 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb1:SetAttribute("PlatsId", nil)
	local s1, k1 = skalFor(m1)
	prova("saknat id", s1 == nil and k1 == "saknas:ridhus_bana", k1)
	local m2, _, ll2 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	local extra = Instance.new("Part")
	extra:SetAttribute("PlatsId", "ridhus_dressyr")
	extra.Size = ll2.Size
	extra.CFrame = ll2.CFrame
	extra.Parent = m2
	local s2, k2 = skalFor(m2)
	prova("dubbelt id", s2 == nil and k2 == "dubbelt_id:ridhus_dressyr", k2)
	local m3, lb3 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb3:SetAttribute("PlatsId", nil)
	local fel3 = Instance.new("Model")
	fel3:SetAttribute("PlatsId", "ridhus_bana")
	fel3.Parent = m3
	local s3, k3 = skalFor(m3)
	prova("feltypat underlag", s3 == nil and k3 == "feltyp:ridhus_bana", k3)
	local m4, lb4 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb4.CFrame = CFrame.new(0, 0.09, 0)
	local s4, k4 = skalFor(m4)
	prova("degenererad riktning (banan och layouten har samma mitt)", s4 == nil and k4 == "degenererad_riktning", k4)
	local m5, _, ll5 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	ll5:SetAttribute("Forankring", "C")
	local s5, k5 = skalFor(m5)
	prova("fel förankring", s5 == nil and k5 == "fel_forankring", k5)
	local m6, lb6 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb6.Size = Vector3.new(0 / 0, 1, 1)
	local s6, k6 = skalFor(m6)
	prova("icke-ändliga mått", s6 == nil and k6 == "ogiltig_geometri:ridhus_bana", k6)
	local m7, lb7 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	prova("KONTROLL: hel byggnad löses", Ridhusplats.los(m7) ~= nil)
	lb7:Destroy()   -- bänkens `Parent = nil` lämnar barnet kvar hos föräldern; `Destroy` tar bort det, som i motorn
	local s7, k7 = skalFor(m7)
	prova("borttagen del: ingen gammal giltig plats", s7 == nil and k7 == "saknas:ridhus_bana", k7)
	prova("och Ugneta placeras inte på en ofullständig byggnad", UgnetaGestalt.plats(m7) == nil)
end

print("\n── R1: underlag som modellen inte stödjer ger otillgängligt ──")
do
	--[[ Granskningens fyra fall, genom samma produktionsmodul och Ugnetas väg. ]]
	local m1, lb1 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb1.CFrame = CFrame.new(0, 0.09, -8.295) * CFrame.Angles(0, math.rad(45), 0)
	local s1, k1 = Ridhusplats.los(m1)
	prova("R1-1a: bara banan vriden 45°: inte samriktade", s1 == nil and k1 == "ej_samriktade", k1)
	prova("R1-1a: och Ugneta placeras inte", UgnetaGestalt.plats(m1) == nil)

	local m2, lb2 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb2.CFrame = CFrame.new(300, 0.09, -8.295)
	local s2, k2 = Ridhusplats.los(m2)
	prova("R1-1b: banans mitt flyttad i sidled: layouten utanför banan", s2 == nil and k2 == "layout_utanfor_bana", k2)
	prova("R1-1b: och Ugneta placeras inte utanför banan", UgnetaGestalt.plats(m2) == nil)

	local m3, _, ll3 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	ll3.CFrame = CFrame.new(0, 0.12, 0) * CFrame.Angles(0, 0 / 0, 0)
	local s3, k3 = Ridhusplats.los(m3)
	prova("R1-2a: layoutens rotation NaN: ogiltig bas", s3 == nil and k3 == "ogiltig_bas:ridhus_dressyr", k3)
	prova("R1-2a: och ingen NaN-plats för Ugneta", UgnetaGestalt.plats(m3) == nil)

	local m4, lb4 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb4.CFrame = CFrame.new(0, 0.09, -8.295, 1, 0, 0 / 0, 0, 1, 0, 0, 0, 0 / 0)
	local s4, k4 = Ridhusplats.los(m4)
	prova("R1-2b: banans rotationsmatris med NaN: ogiltig bas", s4 == nil and k4 == "ogiltig_bas:ridhus_bana", k4)
	prova("R1-2b: och ingen NaN-plats för Ugneta", UgnetaGestalt.plats(m4) == nil)

	--[[ Fler fall inom samma validering. ]]
	local m5, lb5 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb5.CFrame = CFrame.new(0, 0.09, 30)
	local s5, k5 = Ridhusplats.los(m5)
	prova("banan förskjuten längs: inte A-förankrad", s5 == nil and k5 == "ej_a_forankrad", k5)
	local m6, lb6 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb6.Size = Vector3.new(60, 0, 196.59)
	local s6, k6 = Ridhusplats.los(m6)
	prova("banan med höjd 0: ogiltig geometri", s6 == nil and k6 == "ogiltig_geometri:ridhus_bana", k6)
	local m7, lb7 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	lb7.Size = Vector3.new(40, 0.18, 196.59)
	local s7, k7 = Ridhusplats.los(m7)
	prova("banan smalare än layouten: layouten utanför banan", s7 == nil and k7 == "layout_utanfor_bana", k7)

	print("\n── R1: positiva kontroller ──")
	local th = math.rad(37)
	local m8 = syntetisk(Vector3.new(-512, 3, 77), th, true)
	local s8, k8 = Ridhusplats.los(m8)
	prova("KONTROLL: hela byggnaden vriden 37° och flyttad löses", s8 ~= nil, k8)
	if s8 then
		prova("KONTROLL: A → C följer den gemensamma girningen",
			naraV(s8.motC, Vector3.new(-math.sin(th), 0, -math.cos(th)), 1e-6), v3(s8.motC))
		local ok = true
		for _, l in ipairs({ Vector3.new(0, 0, 0), Vector3.new(-9.9, 0, 5), Vector3.new(4, 2, 64) }) do
			if not naraV(Ridhusplats.tillLokal(s8, Ridhusplats.tillVarld(s8, l)), l, 1e-6) then ok = false end
		end
		prova("KONTROLL: lokalt ↔ värld i den vridna byggnaden", ok)
		prova("KONTROLL: banmarginalen bortom C (63 m) är bana, inte layout",
			Ridhusplats.inom(s8, "bana", Ridhusplats.tillVarld(s8, Vector3.new(0, 0, 63)))
				and not Ridhusplats.inom(s8, "dressyr", Ridhusplats.tillVarld(s8, Vector3.new(0, 0, 63))))
		prova("KONTROLL: gränspunkten på layoutens långsida (u = 10 m) är inom",
			Ridhusplats.inom(s8, "dressyr", Ridhusplats.tillVarld(s8, Vector3.new(10, 0, 30))))
		prova("KONTROLL: Ugneta i den vridna byggnaden står mitt på, 1,4 m bortom C",
			UgnetaGestalt.plats(m8) ~= nil and naraV(Ridhusplats.tillLokal(s8, UgnetaGestalt.plats(m8).pos),
				Vector3.new(0, 0, 61.4), 1e-6))
	end
	local m9, lb9 = syntetisk(Vector3.new(0, 0, 0), 0, true)
	local ersattare = Instance.new("Part")
	ersattare.Name = "Ridbanan"
	ersattare.Size = lb9.Size
	ersattare.CFrame = lb9.CFrame
	ersattare:SetAttribute("PlatsId", "ridhus_bana")
	ersattare.Parent = m9
	prova("KONTROLL: en dubblett avvisas", select(2, Ridhusplats.los(m9)) == "dubbelt_id:ridhus_bana")
	lb9:Destroy()
	prova("KONTROLL: en ensam ersättare godtas", Ridhusplats.los(m9) ~= nil)
end

print("\n── R2: relativ girning mätt som rumsligt fel ──")
do
	local BANA_P = Vector3.new(0, 0.09, -8.295)
	local function vriden(grader)
		local m, lb = syntetisk(Vector3.new(0, 0, 0), 0, true)
		lb.CFrame = CFrame.new(BANA_P) * CFrame.Angles(0, math.rad(grader), 0)
		return m, lb
	end
	--[[ Ett läge i banans EGNA ram (x tvärs, z längs), i världen. ]]
	local function iBanansRam(lb, x, z)
		return (lb.CFrame * CFrame.new(x, 0.09, z)).Position
	end

	--[[ Granskningens reproduktion, båda tecknen. ]]
	for _, fall in ipairs({ { 0.5, 29.9 }, { -0.5, -29.9 } }) do
		local m = vriden(fall[1])
		local s, k = Ridhusplats.los(m)
		prova(("%+.1f° relativ girning: inte samriktade"):format(fall[1]), s == nil and k == "ej_samriktade", k)
		prova(("%+.1f°: och Ugneta får ingen plats"):format(fall[1]), UgnetaGestalt.plats(m) == nil)
		local m0 = vriden(0)
		local s0 = Ridhusplats.los(m0)
		prova(("KONTROLL 0°: punkten (%.1f, −88,295) ligger verkligen i banan"):format(fall[2]),
			s0 ~= nil and Ridhusplats.inom(s0, "bana", Vector3.new(fall[2], 0.18, -88.295)))
	end

	--[[ Precis innanför och utanför toleransen: sin θ · halvdiagonalen mot
		TOL_LAGE (0,1 studs). Banans halva diagonal är √(98,295² + 30²). ]]
	local halvDiag = math.sqrt(98.295 ^ 2 + 30 ^ 2)
	local innanfor = math.deg(math.asin(0.08 / halvDiag))
	local utanfor = math.deg(math.asin(0.12 / halvDiag))
	for _, tecken in ipairs({ 1, -1 }) do
		local mIn, lbIn = vriden(tecken * innanfor)
		local sIn, kIn = Ridhusplats.los(mIn)
		prova(("%+.4f° (0,08 studs): godtas"):format(tecken * innanfor), sIn ~= nil, kIn)
		if sIn then
			prova("och banans medlemskap följer banans EGNA axlar: 29,99 tvärs är inom",
				Ridhusplats.inom(sIn, "bana", iBanansRam(lbIn, tecken * 29.99, -80)))
			prova("och 30,01 tvärs är utanför", not Ridhusplats.inom(sIn, "bana", iBanansRam(lbIn, tecken * 30.01, -80)))
			prova("långa änden: 98,29 längs är inom", Ridhusplats.inom(sIn, "bana", iBanansRam(lbIn, 0, -98.29))
				and Ridhusplats.inom(sIn, "bana", iBanansRam(lbIn, 0, 98.29)))
			prova("och 98,30 längs är utanför", not Ridhusplats.inom(sIn, "bana", iBanansRam(lbIn, 0, -98.30))
				and not Ridhusplats.inom(sIn, "bana", iBanansRam(lbIn, 0, 98.30)))
			prova("och Ugneta står kvar mitt på, 1,4 m bortom C", UgnetaGestalt.plats(mIn) ~= nil
				and naraV(Ridhusplats.tillLokal(sIn, UgnetaGestalt.plats(mIn).pos), Vector3.new(0, 0, 61.4), 1e-6))
		end
		local mUt = vriden(tecken * utanfor)
		local sUt, kUt = Ridhusplats.los(mUt)
		prova(("%+.4f° (0,12 studs): avvisas"):format(tecken * utanfor), sUt == nil and kUt == "ej_samriktade", kUt)
	end

	--[[ Layoutens hörn prövas i BANANS ram: en smalare bana (59,86 studs)
		och en godtagen liten girning. I layoutens ram hade hörnet sett ut
		att rymmas (30 mot 29,93 + 0,1); i banans ram ligger det 30,07 från
		mitten, 0,14 utanför — mer än TOL_LAGE. ]]
	local function smal(grader)
		local m, lb = syntetisk(Vector3.new(0, 0, 0), 0, true)
		lb.Size = Vector3.new(59.86, 0.18, 196.59)
		lb.CFrame = CFrame.new(BANA_P) * CFrame.Angles(0, math.rad(grader), 0)
		return m
	end
	local sSmal0 = Ridhusplats.los(smal(0))
	prova("KONTROLL: smal bana utan girning godtas (hörnet 0,07 utanför, inom TOL_LAGE)", sSmal0 ~= nil)
	local sSmal, kSmal = Ridhusplats.los(smal(innanfor))
	prova("smal bana med godtagen girning: hörnet prövat i banans ram ligger utanför",
		sSmal == nil and kSmal == "layout_utanfor_bana", kSmal)

	--[[ Gemensam girning 37° plus flytt: fortfarande giltig, A/C och
		lokal ↔ värld. ]]
	local m37 = syntetisk(Vector3.new(250, -4, -60), math.rad(37), true)
	local s37 = Ridhusplats.los(m37)
	prova("KONTROLL: gemensam girning 37° och flytt godtas", s37 ~= nil)
	if s37 then
		prova("KONTROLL: A → C är 60 m", nara((s37.dressyr.C - s37.dressyr.A).Magnitude / 3, 60, 1e-6))
		prova("KONTROLL: lokal ↔ värld", naraV(Ridhusplats.tillLokal(s37, Ridhusplats.tillVarld(s37,
			Vector3.new(-3, 0.5, 44))), Vector3.new(-3, 0.5, 44), 1e-6))
	end
end

print("\n── Bilden går inte att skriva om ──")
if rp then
	prova("platsen är fryst", pcall(function() rp.golvY = 0 end) == false
		and pcall(function() rp.dressyr.halvLangs = 0 end) == false)
end

if fel > 0 then
	print(("\n%d mätningar föll."):format(fel))
	local avsluta = (os :: any).exit
	if avsluta then avsluta(1) end
	error(("%d mätningar föll."):format(fel), 0)
else
	print("\nridhusplats.spec: alla gröna")
end
