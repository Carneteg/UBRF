--!nostrict
--[[
	#279 — «DONE (R)» EFTER AVSITTNINGEN SKA STÄNGAS AV R OCH Y.

	Efter-ritten-kortet visas först när ritten är riven (`ride = nil`,
	`pass = nil`). Tangentlyssnaren i `init.client` hade R-blocket bakom
	`if not ride then return end` och `LektionController.fortsatt` har en
	`pass`-vakt — så tangenten nådde aldrig kortet, medan panelknappen gick
	rakt till `UgnetaController.fortsatt()`.

	Rättelsen släpper igenom R/ButtonY till SAMMA handling, men bara när
	hon inte rider. Provet kör den riktiga `init.client` och mäter:

	  1. en ACCEPTERAD avsittning ger en summering, och R stänger kortet,
	  2. ButtonY gör detsamma,
	  3. knappen och tangenten kör samma handling (`fortsattFn` en gång var),
	  4. R/Y till fots utan väntande kort gör ingenting,
	  5. under ridning går R fortfarande via `LektionController.fortsatt`
	     (en gång) och den nya grenen rör det inte.

	Det här är stubbad Luau-evidens. Det är INTE verklig motor, fysisk
	tangent eller device-acceptans.

	Kör: python3 roblox/tests/build.py tests/klient-efterritt-tangent.spec.luau
	     && luau roblox/tests/.build/klient-efterritt-tangent.spec.luau ]]

local fel = 0
local function prova(vad, ok, detalj)
	if ok then
		print(("  OK   %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	else
		fel += 1
		print(("  FEL  %s%s"):format(vad, if detalj then "  " .. detalj else ""))
	end
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CAS = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Net = Networking

local dt = 1 / 30
local function bildrutor(n)
	for _ = 1, n do RunService.RenderStepped:Fire(dt) end
end

local nu = 1000
Input._klocka = function() return nu end
local function gaTiden(sek) nu += sek end

local function tryck(kod)
	UIS.InputBegan:Fire({ KeyCode = kod }, false)
end

local hastNr = 0
local function nyHast(): Model
	hastNr += 1
	gaTiden(Input.IMPULS_SPARR + 0.05)
	local h = __makeHastModell("Efterritthast" .. hastNr)
	h:SetAttribute("RidSession", "ritt-efterritt-" .. hastNr)
	h:SetAttribute("RiderUserId", player.UserId)
	h.Parent = workspace
	return h
end

local function sittAv()
	local fn = CAS._bound[Input.AVSITT]
	if fn then fn(Input.AVSITT, Enum.UserInputState.Begin, {}) end
	return fn ~= nil
end

--[[ UNDERLAGET MÅSTE FINNAS, annars är provet grönt av fel skäl:
     `Ugneta.efterrittFor` svarar `nil` när historiken är tom, och
     `visaEfterritt(nil)` är tyst. Samma injektion som `klient-sessionskedja`. ]]
local function nyttUnderlag()
	return { provovning = {
		{ rytm = 0.20, balans = 0.20, mjukhet = 0.20 },
		{ rytm = 0.90, balans = 0.90, mjukhet = 0.90 },
	} }
end

local dr = Net.get("DismountRequest")
local originalHandlare = dr.OnServerInvoke

--[[ En ritt med underlag, avslutad genom produktionens egen väg: AVSITT
     bunden i CAS, servern säger ja, och summeringen läggs upp av
     `begarAvsittning`. Returnerar hästen. ]]
local function ridOchSittAv(): Model
	local h = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	local pass = LektionController.pass()
	if pass then pass.historik = nyttUnderlag() end
	UgnetaController.dolj()
	dr.OnServerInvoke = function() return true end
	__schemaPa(true)
	sittAv()
	__schemaTomKo()
	bildrutor(2)
	__schemaPa(false)
	return h
end

--[[ Räknare på det som tangenten och knappen ska nå. `fortsattFn` är vad
     den som kör lektionen registrerar; efter en avsittning är den riven,
     så provet lägger dit en egen. ]]
local function raknaFortsatt()
	local n = 0
	UgnetaController.vidFortsatt(function() n += 1 end)
	return function() return n end
end

local function spionLektionFortsatt()
	local fore = LektionController.fortsatt
	local n = 0
	LektionController.fortsatt = function(...)
		n += 1
		return fore(...)
	end
	return function() return n end, function() LektionController.fortsatt = fore end
end

print("\n══ 1. ACCEPTERAD AVSITTNING → SUMMERING → R STÄNGER ══════════")
do
	local h = ridOchSittAv()
	prova("KONTROLL: avsittningen är accepterad och kortet väntar",
		UgnetaController.vantar() == true, tostring(UgnetaController.vantar()))
	prova("KONTROLL: hon rider inte längre och passet är rivet",
		LektionController.pagar() == false and LektionController.pass() == nil)
	prova("KONTROLL: LektionController.fortsatt() når det inte (pass-vakten är kvar)",
		LektionController.fortsatt() == false and UgnetaController.vantar() == true)

	local antalFn = raknaFortsatt()
	tryck(Enum.KeyCode.Space)
	tryck(Enum.KeyCode.E)
	prova("en ANNAN tangent (Space, E) stänger inte kortet",
		UgnetaController.vantar() == true and antalFn() == 0,
		("vantar=%s fn=%d"):format(tostring(UgnetaController.vantar()), antalFn()))
	tryck(Enum.KeyCode.R)
	prova("R STÄNGER efter-ritten-kortet", UgnetaController.vantar() == false,
		tostring(UgnetaController.vantar()))
	prova("och kör kortets handling en gång", antalFn() == 1, tostring(antalFn()))
	tryck(Enum.KeyCode.R)
	prova("ett andra R gör ingenting mer (inget kort väntar)",
		antalFn() == 1 and UgnetaController.vantar() == false)

	UgnetaController.vidFortsatt(nil)
	dr.OnServerInvoke = originalHandlare
	h:Destroy()
	bildrutor(1)
end

print("\n══ 2. ButtonY GÅR SAMMA VÄG ══════════════════════════════════")
do
	local h = ridOchSittAv()
	prova("KONTROLL: kortet väntar", UgnetaController.vantar() == true)
	local antalFn = raknaFortsatt()
	tryck(Enum.KeyCode.ButtonY)
	prova("ButtonY STÄNGER kortet", UgnetaController.vantar() == false,
		tostring(UgnetaController.vantar()))
	prova("och kör samma handling en gång", antalFn() == 1, tostring(antalFn()))

	UgnetaController.vidFortsatt(nil)
	dr.OnServerInvoke = originalHandlare
	h:Destroy()
	bildrutor(1)
end

print("\n══ 3. PANELKNAPPEN FUNGERAR OCH GÖR DET TANGENTEN GÖR ═════════")
do
	local h = ridOchSittAv()
	--[[ Panelens rad är `UgnetaController.panel().knappar` — samma data som
	     `Naromrade` ritar som vänsterpanelens val, och dess `skicka` är
	     det knappens `Activated` kör. ]]
	local knappar = UgnetaController.panel(4).knappar or {}
	--[[ Första raden är kortknappen, den lyfta («Done (R)»). Stubbens
	     övriga knappar är inte det provet mäter. ]]
	prova("KONTROLL: panelens första val är den lyfta kortknappen",
		knappar[1] ~= nil and knappar[1].paTur == true
			and string.find(tostring(knappar[1].text), Sprak.t("ugneta.efterritt.stang"), 1, true) == 1,
		knappar[1] and tostring(knappar[1].text))
	local antalFn = raknaFortsatt()
	if knappar[1] and knappar[1].skicka then knappar[1].skicka() end
	prova("knappen stänger kortet", UgnetaController.vantar() == false)
	prova("och kör kortets handling en gång — samma som tangenten",
		antalFn() == 1, tostring(antalFn()))

	UgnetaController.vidFortsatt(nil)
	dr.OnServerInvoke = originalHandlare
	h:Destroy()
	bildrutor(1)
end

print("\n══ 4. TILL FOTS UTAN KORT: R OCH Y GÖR INGENTING ═════════════")
do
	prova("KONTROLL: ingen ritt, inget kort",
		LektionController.pagar() == false and UgnetaController.vantar() == false)
	local antalFn = raknaFortsatt()
	local lek, slappLek = spionLektionFortsatt()
	local ok1 = pcall(tryck, Enum.KeyCode.R)
	local ok2 = pcall(tryck, Enum.KeyCode.ButtonY)
	prova("R och Y kastar inte", ok1 and ok2)
	prova("ingen handling kördes och inget kort uppstod",
		antalFn() == 0 and UgnetaController.vantar() == false
			and LektionController.pagar() == false,
		("fn=%d vantar=%s"):format(antalFn(), tostring(UgnetaController.vantar())))
	prova("och lektionens fortsätt rördes inte (ingen ritt att tolka tangenten för)",
		lek() == 0, tostring(lek()))
	slappLek()
	UgnetaController.vidFortsatt(nil)
end

print("\n══ 5. UNDER RIDNING ÄR R OFÖRÄNDRAT ══════════════════════════")
do
	local h = nyHast()
	Net.get("MountChanged").OnClientEvent:Fire(h, player)
	bildrutor(1)
	prova("KONTROLL: hon rider och ett lektionskort väntar",
		LektionController.pagar() == true and UgnetaController.vantar() == true,
		("pagar=%s vantar=%s"):format(tostring(LektionController.pagar()),
			tostring(UgnetaController.vantar())))
	local lek, slappLek = spionLektionFortsatt()
	tryck(Enum.KeyCode.R)
	prova("R går via LektionController.fortsatt, en gång — som före rättelsen",
		lek() == 1, tostring(lek()))
	prova("kortet är kvitterat och hon rider vidare",
		UgnetaController.vantar() == false and LektionController.pagar() == true)
	tryck(Enum.KeyCode.R)
	prova("ett R utan väntande kort under ridning stänger ingenting",
		LektionController.pagar() == true)
	slappLek()

	dr.OnServerInvoke = originalHandlare
	h:Destroy()
	bildrutor(1)
end

print("")
if fel > 0 then
	print(("EFTERRITT-TANGENT: %d FEL"):format(fel))
	error("efterritt-tangent foll")
end
--[[ SLUTRADEN AR ETT KONTRAKT mot `kor.sh`: den letar efter
     "alla gröna" och tolkar franvaron som en KRASCH. ]]
print("EFTERRITT-TANGENT: alla gröna")
