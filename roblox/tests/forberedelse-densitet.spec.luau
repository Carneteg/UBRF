--!nostrict
--[[ MÄTNING, INTE GRIND. Räknar hur många instruktioner panelen visar i
	varje förberedelseflöde, och vilken rad det är. Körs för hand före och
	efter #185 för att jämförelsen i PR-texten ska vara mätt, inte påstådd.

	Inte med i kor.sh: den mäter, den mäter inte mot ett krav. ]]

local PC = PreparationController
local rev = 5000

local function visa(st)
	rev += 1
	PC.tillampa(Preparation.vy(st, Preparation.STATUS.FORBEREDER, rev, "Cosmo"))
	PC.uppdateraKontext()
end

local function rad(etikett, st)
	visa(st)
	local ytor = PC._ytor()
	local vy = Preparation.vy(st, Preparation.STATUS.FORBEREDER, rev, "Cosmo")
	local synliga = PC._synligaMoment()
	local hk = ytor.interaktionVaxla
	local L = PC.layout()
	local visadRad = synliga[1] and (ytor.moment:FindFirstChild(synliga[1]) or {}).Text
	print(string.format(
		"%-26s | vy %d | synliga %d | rad %-34s | pa tur %-10s | hjalp %-18s | panel %d px",
		etikett, #(vy.moment or {}), #synliga,
		string.sub(tostring(visadRad), 1, 34),
		tostring(vy.nastaMoment),
		(hk and hk.Visible and ("[" .. tostring(hk.Text) .. "]")) or "-",
		L.interaktion.y1 - L.interaktion.y0))
	print(string.format("%-26s | instruktion: %s", "", tostring(ytor.instruktion.Text)))
end

print("\n== INSTRUKTIONSTATHET, FLODE FOR FLODE ==")

local st = Preparation.nyState("cosmo", 1)
rad("halsning", st)
for _, m in ipairs(Preparation.moment("halsa")) do
	if not m.fel then
		Preparation.utforMoment(st, "halsa", m.id, "cosmo")
		break
	end
end

rad("visitation (0 av 5)", st)
local vm = Preparation.moment("visitera")
Preparation.utforMoment(st, "visitera", vm[1].id, "cosmo")
rad("visitation (1 av 5)", st)
for i = 2, #vm do Preparation.utforMoment(st, "visitera", vm[i].id, "cosmo") end

rad("ryktning (0 gjorda)", st)
local rm = Preparation.moment("rykta")
Preparation.utforMoment(st, "rykta", rm[1].id, "cosmo")
rad("ryktning (1 gjord)", st)
for i = 2, #rm do Preparation.utforMoment(st, "rykta", rm[i].id, "cosmo") end

rad("hovar (0 av 4)", st)
Preparation.utforMoment(st, "iordning", "hov:vf", "cosmo")
rad("hovar (1 av 4)", st)
for _, h in ipairs({ "vb", "hb", "hf" }) do
	Preparation.utforMoment(st, "iordning", "hov:" .. h, "cosmo")
end

rad("underlagg/sadel (steg 1)", st)
Preparation.utforMoment(st, "iordning", "utr:1", "cosmo")
Preparation.utforMoment(st, "iordning", "utr:2", "cosmo")
Preparation.utforMoment(st, "iordning", "utr:3", "cosmo")
rad("gjorden (steg 4)", st)
Preparation.utforMoment(st, "iordning", "utr:4", "cosmo")
rad("betsling (steg 5)", st)
Preparation.utforMoment(st, "iordning", "utr:5", "cosmo")

rad("ledning/fore ridning", st)

print("\n== FYNDET ==")
local pass, fynd = nil, nil
for p = 2, 60 do
	local f = Preparation.fyndFor("cosmo", p)
	if f then
		pass, fynd = p, f
		break
	end
end
local fst = Preparation.nyState("cosmo", pass)
for _, m in ipairs(Preparation.moment("halsa")) do
	if not m.fel then
		Preparation.utforMoment(fst, "halsa", m.id, "cosmo")
		break
	end
end
Preparation.utforMoment(fst, "visitera", "vis:" .. fynd, "cosmo")
rad("fyndet (" .. tostring(fynd) .. ")", fst)

print("\nMATNING KLAR")
