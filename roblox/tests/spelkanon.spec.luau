--!nostrict
--[[
	S2c — den verklighetsdrivna hästkanonen.

	Källfälten grindas i Node-exporten mot den versionssparade snapshoten.
	Här provas Roblox-kontraktet som konsumenterna faktiskt får efter wrappern.
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

check("hela aktiva rostern är 33 hästar/ponnyer",
	#UBRFSpel.ordning == 33, #UBRFSpel.ordning .. " st")

local antalTabell = 0
for _ in pairs(UBRFSpel.hastar) do antalTabell += 1 end
check("ordning och hästtabell har samma 33 poster",
	antalTabell == 33 and antalTabell == #UBRFSpel.ordning,
	antalTabell .. " poster")

local bing = UBRFSpel.hastar.bing
check("Bing finns i Roblox-kanonen", bing ~= nil)
check("Bing kan inte hoppa enligt källbeskrivningen",
	bing ~= nil and bing.hoppkapacitet == 0
		and bing.flaggor ~= nil and bing.flaggor.hoppar_inte == true,
	bing and ("hoppkapacitet=" .. tostring(bing.hoppkapacitet)) or "saknas")
check("Bings hopplust är neutral — källan säger inget om motivation",
	bing ~= nil and bing.hopplust == 0.6,
	bing and ("hopplust=" .. tostring(bing.hopplust)) or "saknas")

local function neutralTuning(h)
	return h ~= nil
		and h.kanslighet == 0.5
		and h.framatbjudning == 0.5
		and h.forlatande == 0.6
		and h.skygghet == 0.2
		and h.hoppkapacitet == 0.6
		and h.hopplust == 0.6
		and h.tyngd == 0.4
		and h.utbildning == 0.6
		and h.maxhojd == 0.8
		and h.fjader == nil
		and h.tecken == nil
end

local lady = UBRFSpel.hastar.lady
check("Lady är den verifierade D-ponnyn, inte gammal fabricerad profil",
	lady ~= nil and lady.typ == "ponny" and lady.kategori == "D"
		and lady.fodd == 2011 and lady.ras == "Connemara",
	lady and (tostring(lady.fodd) .. " / " .. tostring(lady.ras)) or "saknas")
check("Lady återanvänder inte gammal felaktig gameplay-tuning",
	neutralTuning(lady))

local westside = UBRFSpel.hastar.westside
check("Westside är Haflinger C-ponny",
	westside ~= nil and westside.typ == "ponny" and westside.kategori == "C"
		and westside.fodd == 2009 and westside.ras == "Haflinger",
	westside and (tostring(westside.fodd) .. " / " .. tostring(westside.ras)) or "saknas")
check("Westside återanvänder inte gammal felaktig gameplay-tuning",
	neutralTuning(westside))

local kennedy = UBRFSpel.hastar.kennedy
check("Kennedy är D-ponny född 2019",
	kennedy ~= nil and kennedy.typ == "ponny" and kennedy.kategori == "D"
		and kennedy.fodd == 2019,
	kennedy and tostring(kennedy.fodd) or "saknas")
check("Kennedy återanvänder inte gammal felaktig gameplay-tuning",
	neutralTuning(kennedy))

local felFoder = {}
for id, f in pairs(UBRFSpel.foder) do
	if f.status ~= "ASSUMPTION" then table.insert(felFoder, id) end
end
check("individuella fodergivor utger sig inte för att vara verifierade",
	#felFoder == 0, table.concat(felFoder, ", "))

check("S2a-skötselfasaden överlever moduldelningen",
	UBRFSpel.rykt ~= nil and UBRFSpel.sadelfaser ~= nil and UBRFSpel.visitation ~= nil)

if fails > 0 then
	print(string.format("\n%d FEL", fails))
	error("spelkanon.spec: " .. fails .. " fel")
end
print("\nalla gröna")
