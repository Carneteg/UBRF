--!nostrict
--[[
	SPRÅKFLAGGAN PÅ SERVERN (#264 GAIT_READABILITY_AND_UGNETA).

	Ordern: där servern måste välja språk tar den bara emot "sv" eller "en"
	per spelare, och ingenting annat tillstånd eller behörighet går att nå
	den vägen. Provet går genom `GameplayService.sprakVal` — samma funktion
	fjärranropet `SprakVal` anropar — och genom facit över fjärrobjekten.

	Kör: python3 roblox/tests/build.py tests/integration-flagga.spec.luau
	     && luau roblox/tests/.build/integration-flagga.spec.luau
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

local function spelare(namn)
	local p = { Name = namn, _attr = {}, LocaleId = "sv-se" }
	function p:GetAttribute(n) return self._attr[n] end
	function p:SetAttribute(n, v) self._attr[n] = v end
	return p
end

print("\n── Språkvalet valideras och gäller bara spelaren själv ──")
do
	local a, b = spelare("A"), spelare("B")
	local ok, val = GameplayService.sprakVal(a, "en")
	prova("\"en\" tas emot och skrivs på spelarens eget attribut",
		ok == true and val == "en" and a:GetAttribute("UBRFSprak") == "en")
	prova("och den andra spelaren är orörd", b:GetAttribute("UBRFSprak") == nil)
	prova("serverns text till A följer valet, till B inte",
		Sprak.forSpelare(a, "ugneta.titel") == Sprak.iSprak("en", "ugneta.titel")
			and Sprak.forSpelare(b, "ugneta.titel") == Sprak.iSprak("sv", "ugneta.titel"))
	for _, dumt in ipairs({ "de", "", 1, true, { "en" } }) do
		local ok2 = GameplayService.sprakVal(a, dumt)
		prova(("ogiltigt värde avvisas: %s"):format(tostring(dumt)),
			ok2 == false and a:GetAttribute("UBRFSprak") == "en")
	end
	local ok3 = GameplayService.sprakVal(a, nil)
	prova("nil avvisas också", ok3 == false and a:GetAttribute("UBRFSprak") == "en")
end

print("\n── Fjärrobjektet finns i facit och har en egen takt ──")
do
	prova("SprakVal är ett deklarerat RemoteFunction",
		Networking.definitioner().SprakVal == "RemoteFunction")
	prova("och skopan har en gräns för det", Skopa.GRANSER.SprakVal ~= nil)
end

if fel > 0 then
	print(("\n%d mätning(ar) föll."):format(fel))
	error("integration-flagga.spec: " .. fel .. " fel")
end
print("\nintegration-flagga.spec: alla gröna")
