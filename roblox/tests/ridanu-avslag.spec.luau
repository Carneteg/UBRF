--!nostrict
--[[
	«RIDA NU» — AVSLAGET SKA BÄRA SITT ARGUMENT HELA VÄGEN (#246 A).

	Fysisk Studio-QA 2026-09-18, touch, dagens häst Trixie: sadeln hämtad,
	ledning igång, spelaren trycker «Rida nu». Loggen:

	    [Tack] SagaAberg tog Trixies sadel.
	    [Led]  SagaAberg · trixie · LedBorja
	    [Led]  SagaAberg · trixie · RidaNu NEKAD: forb.fel_tur
	    [Horse] Rida nu: wrong turn — %s is next (forb.fel_tur)

	Sista raden är felet. Spelaren fick se ett bokstavligt `%s` i stället
	för vilket moment som stod på tur — alltså ett avslag utan väg vidare.

	ARGUMENTET FINNS VID KÄLLAN. `Preparation.provaSteg` och
	`Preparation.provaMoment` lämnar båda namnet som TREDJE returvärde.
	Det tappas sedan, och den här specen mäter varje led för sig så att
	fyndet pekar på en RAD och inte på "någonstans i kedjan":

	    provaSteg      -> (false, "forb.fel_tur", namn)   källan
	    provaMoment    -> tappar det                      led 1
	    utforMoment    -> tappar det                      led 2
	    Gameplay.moment-> tappar det                      led 3
	    ridaNuInre     -> tappar det                      led 4
	    (klienten      -> tappar det                      led 5, se
	     klient-ridanu.spec.luau — den hör hemma i klientbänken)

	Samma felklass är redan rättad två gånger i repot, i
	`HorseService.tryMount` och i passets `Pass.utfor` — se noten vid
	`GameplayService.luau:1184`. Den här gången gällde det förberedelsen.

	Kör: python3 roblox/tests/build.py tests/ridanu-avslag.spec.luau
	     && luau roblox/tests/.build/ridanu-avslag.spec.luau
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

local HAST = "blackrock_jack"

--[[ En fas som INTE står på tur, och ett giltigt moment i den. Provet
     letar upp den i stället för att skriva in ett fasnamn: fasordningen är
     kanonens, och ett hårdkodat id här hade blivit en andra sanning om
     den. ]]
local function felTurFas(state)
	local nasta = Preparation.nasta(state)
	for _, f in ipairs(Preparation.stegFaser()) do
		if nasta == nil or f.id ~= nasta.id then
			for _, m in ipairs(Preparation.moment(f.id)) do
				if not m.fel and m.id then return f, m end
			end
		end
	end
	return nil, nil
end

print("")
print("RIDA NU — AVSLAGETS ARGUMENT (#246 A)")

print("\n── Källan bär namnet ──")

local state = Preparation.nyState(HAST, 1)
local fas, moment = felTurFas(state)
check("provet hittade en fas som inte står på tur", fas ~= nil and moment ~= nil,
	fas and ("%s · %s"):format(fas.id, moment.id) or "ingen")

local kallArg
do
	local ok, skal, arg = Preparation.provaSteg(state, fas.id, HAST)
	kallArg = arg
	check("provaSteg nekar med forb.fel_tur",
		ok == false and skal == "forb.fel_tur", tostring(skal))
	--[[ DET HÄR ÄR HELA POÄNGEN: namnet finns, och det är inte tomt. ]]
	check("och lämnar namnet på den fas som står på tur som tredje värde",
		type(arg) == "string" and arg ~= "" and arg ~= "%s",
		("arg = %s"):format(tostring(arg)))
end

print("\n── Led 1: provaMoment ──")
do
	local ok, skal, arg = Preparation.provaMoment(state, fas.id, moment.id, HAST)
	check("provaMoment nekar med samma skäl",
		ok == false and skal == "forb.fel_tur", tostring(skal))
	check("och FÖR VIDARE argumentet från provaSteg",
		arg == kallArg, ("arg = %s (väntat %s)"):format(tostring(arg), tostring(kallArg)))
end

print("\n── Led 2: utforMoment ──")
do
	local ok, skal, arg = Preparation.utforMoment(state, fas.id, moment.id, HAST)
	check("utforMoment nekar med samma skäl",
		ok == false and skal == "forb.fel_tur", tostring(skal))
	check("och FÖR VIDARE argumentet",
		arg == kallArg, ("arg = %s (väntat %s)"):format(tostring(arg), tostring(kallArg)))
	--[[ Och den nekade provningen får inte ha flyttat förberedelsen. ]]
	check("ett avvisat moment flyttar ingenting",
		(state.gjorda[fas.id] or {})[moment.id] == nil)
end

print("\n── Texten spelaren möter ──")
do
	--[[ Nyckeln bär ett `%s`. Utan argument ser spelaren det bokstavligt,
	     vilket är precis vad Studio-loggen visade. Provet mäter bådadera:
	     att formateringen MED argument blir läsbar, och att den UTAN blir
	     det oläsliga som rapporterades. ]]
	check("språknyckeln finns", Sprak.finns("forb.fel_tur") == true)
	local med = Sprak.t("forb.fel_tur", kallArg)
	local utan = Sprak.t("forb.fel_tur")
	check("med argument nämner texten vad som står på tur",
		string.find(med, "%%s") == nil and string.find(med, kallArg, 1, true) ~= nil,
		("%q"):format(med))
	check("och utan argument blir det just det oläsliga QA såg",
		string.find(utan, "%%s") ~= nil, ("%q"):format(utan))
end

--[[ ══ SPELARENS TEXT — DE TVÅ KRAVEN UR PRECISERINGEN ══════════════

	Arkitekturpreciseringen 2026-09-18 på #246 är uttrycklig om vem som
	äger texten: `PreparationController.skalText(skal, arg)` och
	språkkanonen. Två prov krävs, och de mäter motsatta fall.

	Notera att argumentet är en KANON-token (`kanon:…`), inte färdig text.
	`skalText` löser upp den på spelarens språk — provet mäter alltså vad
	spelaren faktiskt läser, inte att en token råkar finnas med. ]]
print("\n── Vad spelaren läser ──")
do
	local med = PreparationController.skalText("forb.fel_tur", kallArg)
	check("med argument ersätts %s av nästa FÖRBEREDELSEMOMENT",
		string.find(med, "%%s") == nil
			and string.find(med, Preparation.utanKanonprefix(kallArg), 1, true) ~= nil,
		("%q"):format(med))
	--[[ …och prefixet får inte läcka ut. "kanon:Hälsa lugnt" är en
	     intern token; spelaren ska läsa meningen, inte nyckeln. ]]
	check("och kanon-prefixet syns aldrig för spelaren",
		string.find(med, "kanon:", 1, true) == nil, ("%q"):format(med))

	--[[ DET ANDRA KRAVET: saknat argument får ALDRIG ge rå %s. ]]
	local utan = PreparationController.skalText("forb.fel_tur", nil)
	check("utan argument visas ingen rå %s",
		string.find(utan, "%%s") == nil, ("%q"):format(utan))
	check("och fallbacken håller sig i förberedelsens domän",
		string.find(utan, Sprak.t("forb.nasta_steget"), 1, true) ~= nil,
		("%q"):format(utan))
	--[[ Ingen ryttarkö, ingen "vänta på din tur" — preciseringen förbjuder
	     uttryckligen att felet ges en annan domänbetydelse. ]]
	check("och nämner ingen annan ryttare",
		string.find(string.lower(utan), "ryttare") == nil
			and string.find(string.lower(utan), "rider") == nil,
		("%q"):format(utan))
end

print("")
if fails > 0 then
	print(string.format("%d mätning(ar) föll.", fails))
else
	print("Alla mätningar gick igenom.")
end
