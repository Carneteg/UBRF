--!nostrict
--[[
	TÄVLINGSKLÄDER — KATALOGEN OCH GRÄNSEN (#248 Fas A).

	Ordern räknar upp tre verifierade par. Provet mäter fyra saker, och
	inget mer — Fas A bygger ingen tävling, och ett prov som låtsades mäta
	en sådan hade varit en andra sanning om vad som finns.

	  1. varje id ligger i RÄTT FÄLT på rätt set,
	  2. valideringsgränsen släpper igenom exakt tre ord och inget annat,
	  3. katalogen går inte att mutera genom svaren den ger,
	  4. posterna bär sin källa och är märkta som externa beroenden.

	VAD SOM INTE MÄTS: att id:na faktiskt finns i Robloxs katalog, och att
	deras `AssetType` är 11 respektive 12. Det är verifierat av
	produktägaren via katalog-/economy-API och står i #248; en Luau-bänk
	kan inte fråga Roblox. Provet mäter att TALEN kom in rätt, inte att de
	är rätt.

	Att inga parallella ID-tabeller finns mäts av
	`tools/kolla-tavlingsklader.py`, som läser källan — en bänk ser inte
	skillnad på ett andra id och inget andra id.

	Kör: python3 roblox/tests/build.py tests/tavlingsklader.spec.luau
	     && luau roblox/tests/.build/tavlingsklader.spec.luau
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

local T = Tavlingsklader

print("")
print("TÄVLINGSKLÄDER — KATALOG OCH GRÄNS (#248 Fas A)")

--[[ ══ 1. RÄTT ID I RÄTT FÄLT ═══════════════════════════════════════

	Talen skrivs av ur ordern EN gång — här — och jämförs mot modulen.
	Att provet bär sin egen kopia är hela poängen med just det här
	provet: det är den enda sortens dubblering som är rätt, för den är
	facit och inte en andra sanning i produktionen. ]]
print("\n── De tre paren, fält för fält ──")

local ORDERN = {
	{ id = "white", namn = "White Equestrian Set",
		shirt = 11268412339, pants = 11268415210 },
	{ id = "pink", namn = "Pink Equestrian Set",
		shirt = 11268345931, pants = 11268349501 },
	{ id = "oak", namn = "Oak Equestrian Set",
		shirt = 11268265001, pants = 11268267939 },
}

check("katalogen har exakt tre set", #T.alla() == 3, ("%d"):format(#T.alla()))

for _, v in ipairs(ORDERN) do
	local s = T.set(v.id)
	check(("«%s» finns i katalogen"):format(v.id), s ~= nil)
	if s then
		check(("  %s: shirt i shirtAssetId"):format(v.id),
			s.shirtAssetId == v.shirt,
			("%s (väntat %d)"):format(tostring(s.shirtAssetId), v.shirt))
		check(("  %s: pants i pantsAssetId"):format(v.id),
			s.pantsAssetId == v.pants,
			("%s (väntat %d)"):format(tostring(s.pantsAssetId), v.pants))
		--[[ KORSPROVET: fälten får inte vara ombytta. Två tal i rätt post
		     men fel fält hade gett en ryttare byxor på överkroppen, och
		     bådadera "finns" i katalogen. ]]
		check(("  %s: fälten är inte ombytta"):format(v.id),
			s.shirtAssetId ~= v.pants and s.pantsAssetId ~= v.shirt)
		check(("  %s: bär sitt spelarnamn"):format(v.id),
			s.namn == v.namn, ("%q"):format(tostring(s.namn)))
	end
end

--[[ Inget tal får förekomma två gånger i hela katalogen. Ett id som
     råkat klistras in i två set är exakt den sortens fel som ser rätt ut
     i en tabell och fel på en ryttare. ]]
do
	local sedda, dubbletter = {}, {}
	for _, s in ipairs(T.alla()) do
		for _, n in ipairs({ s.shirtAssetId, s.pantsAssetId }) do
			if sedda[n] then table.insert(dubbletter, tostring(n)) end
			sedda[n] = true
		end
	end
	check("inget asset-id förekommer i två fält", #dubbletter == 0,
		table.concat(dubbletter, ", "))
end

--[[ ══ 2. VALIDERINGSGRÄNSEN ═══════════════════════════════════════

	Kontraktet: "Klienten får välja ett katalog-id, aldrig skicka
	godtyckliga Roblox-asset-ID:n." Gränsen prövas därför med just det en
	manipulerad klient skulle skicka. ]]
print("\n── Gränsen släpper igenom tre ord, inget annat ──")

do
	for _, id in ipairs(T.idn()) do
		check(("«%s» accepteras"):format(id), T.giltig(id) == true)
	end
	check("och de är exakt white, pink, oak",
		table.concat(T.idn(), ",") == "white,pink,oak",
		table.concat(T.idn(), ","))

	--[[ ETT ASSET-ID ÄR INTE ETT KATALOG-ID. Det här är hela gränsen. ]]
	local somTal = T.giltig(11268412339)
	local somText = T.giltig("11268412339")
	check("ett asset-id som TAL nekas", somTal == false, tostring(somTal))
	check("och som TEXT nekas det också", somText == false, tostring(somText))
	check("och det ger inget set",
		T.set(11268412339) == nil and T.set("11268412339") == nil)

	local skrap = { "", "White", "WHITE", "whit", "white ", " white",
		"oak;white", "../white", "black" }
	local slapptIgenom = {}
	for _, s in ipairs(skrap) do
		if T.giltig(s) then table.insert(slapptIgenom, ("%q"):format(s)) end
	end
	check("skiftläge, mellanslag och påhittade namn nekas",
		#slapptIgenom == 0, table.concat(slapptIgenom, ", "))

	--[[ Icke-strängar: nil, tal, tabell, boolean. En klient kan skicka
	     vad som helst över nätet, och gränsen ska inte anta något. ]]
	local ejStrangar = { T.giltig(nil), T.giltig(0), T.giltig(true),
		T.giltig({ id = "white" }), T.giltig({ "white" }) }
	local nagotSant = false
	for _, v in ipairs(ejStrangar) do if v then nagotSant = true end end
	check("nil, tal, boolean och tabeller nekas", nagotSant == false)
	check("och de kastar inte — de svarar nej",
		T.set(nil) == nil and T.set({}) == nil)
end

--[[ ══ 3. KATALOGEN GÅR INTE ATT SKRIVA I ═════════════════════════

	Modulen är den enda sanningen. Om `alla()` eller `set()` lämnade ut
	själva posterna kunde vilken läsare som helst ändra katalogen genom
	att råka mutera sitt svar — och då finns det två sanningar igen, bara
	med ett extra steg emellan. ]]
print("\n── Svaren är kopior, inte katalogen ──")
do
	local a = T.set("white")
	a.shirtAssetId = 1
	a.namn = "kapad"
	local b = T.set("white")
	check("ett muterat svar ändrar inte katalogen",
		b.shirtAssetId == 11268412339 and b.namn == "White Equestrian Set",
		("%s / %q"):format(tostring(b.shirtAssetId), tostring(b.namn)))

	local lista = T.alla()
	table.remove(lista)
	lista[1].id = "kapad"
	check("och en muterad lista gör det inte heller",
		#T.alla() == 3 and T.alla()[1].id == "white",
		("%d set, första %q"):format(#T.alla(), tostring(T.alla()[1].id)))

	local idn = T.idn()
	table.remove(idn)
	check("inte heller id-listan", #T.idn() == 3, ("%d"):format(#T.idn()))
end

--[[ ══ 4. KÄLLA OCH BEROENDESTATUS ═════════════════════════════════ ]]
print("\n── Källan står i modulen ──")
do
	check("skaparen är namngiven i data, inte bara i en kommentar",
		T.SKAPARE == "Ambient Rose Equestrian", tostring(T.SKAPARE))
	--[[ AssetType-talen står i modulen för att en framtida laddning ska
	     kunna pröva dem mot Roblox svar. Provet kan bara mäta att de är
	     Robloxs egna tal för de två lagren — inte att posterna HAR dem. ]]
	check("Robloxs AssetType för de två lagren finns att pröva mot",
		T.ASSETTYPE_SHIRT == 11 and T.ASSETTYPE_PANTS == 12,
		("shirt %s · pants %s"):format(tostring(T.ASSETTYPE_SHIRT),
			tostring(T.ASSETTYPE_PANTS)))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
