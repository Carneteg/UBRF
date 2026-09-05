--!strict
--[[
	G02-B punkt 1 — RYTTARENS HJÄLPER SOM SEMANTIK, Roblox-sidan.

	Motsvarigheten till src/riding/hjalper.js. Samma översättning, samma
	tal — och talen SKRIVS INTE AV: de läses ur RidKanon.HJALP, som
	genereras ur webbens modul av tools/exportera-ridkanon.mjs. Ändras de
	på webben ändras de här, och paritetsspecen faller om exporten inte
	körts.

	Axlarna är enhetens språk, orden är ridningens:

	  skänkel     framåtdrivande hjälp        (Roblox `intent.forward`)
	  styrning    hur mycket böjning som begärs (`intent.steer`)
	  tygel       kontakten ryttaren håller    (`intent.rein`, ny i G02-B)
	  innertygel  tygel + styrutslagets begäran
	  yttertygel  tygel − styrutslagets eftergift
	  yttertygelstöd  hur stor del av böjningen yttertygeln bär
	  parad       halvhalten som EGEN signal   (`intent.parad`)

	SITSEN SAKNAS PÅ ROBLOX. Webben har en sitsaxel (Shift/Ctrl); här är
	de tangenterna gångartsknappar sedan Gate 01, och att flytta dem vore
	en inputändring utanför G02-B:s scope. `sits` fylls därför INTE med
	ett påhittat värde: fältet står som deklarerad lucka i Telemetri.SAKNAS
	och paradens kvalitet räknas på de två hjälper som finns.
]]

local RidKanon = require(script.Parent.RidKanon)

local Hjalper = {}

--[[ Fältnamnen är kontraktet, hämtade ur kanonen så att de två ytorna
     inte kan publicera olika ord för samma sak. ]]
Hjalper.FALT = RidKanon.HJALP_FALT
Hjalper.HARLEDDA = RidKanon.HJALP_HARLEDDA

--[[ Hjälper som Roblox inte har någon källa till. `sits` av skälet ovan;
     de härledda som hänger på den följer med. ]]
Hjalper.SAKNAS = { "sits", "vikt" }

local function kl(v: number, lo: number, hi: number): number
	return math.clamp(v, lo, hi)
end

--[[ En bildrutas hjälper → ridningens ord. `a` har fälten skankel, tygel
     och styrning i samma skalor som webbens: skänkel och tygel 0–1 kring
     sina neutrallägen, styrning −1..1. ]]
function Hjalper.semantik(a: { [string]: number }): { [string]: any }
	local H = RidKanon.HJALP
	local t = kl(a.tygel or 0, 0, 1)
	local sb = kl(a.styrning or 0, -1, 1)
	local s = math.abs(sb)
	local innerTygel = kl(t + s * H.INNER_BER * (1 - t), 0, 1)
	local ytterTygel = kl(t - s * H.YTTER_SLAPP * t, 0, 1)
	--[[ Rakt fram är `ber` noll och stödet därmed 1 — på ett rakt spår
	     finns ingen inner- och yttersida att göra fel med. Formen faller
	     ut i 1 av sig själv i stället för att behöva en gräns som stänger
	     av termen. Identisk med webbens. ]]
	local ber = kl(s / H.STYR_FULLT, 0, 1)
	local behov = H.TYGEL_NEUTRAL + H.STOD_KRAV * ber
	local bar = kl(ytterTygel / behov, 0, 1)
	return {
		skankel = a.skankel or 0,
		tygel = t,
		styrning = sb,
		innerTygel = innerTygel,
		ytterTygel = ytterTygel,
		ytterstod = 1 - ber * (1 - bar),
		bojSida = if s > H.BOJ_TROSKEL then (if sb > 0 then 1 else -1) else 0,
		parad = kl(a.parad or 0, 0, 1),
	}
end

--[[ Paradens kvalitet i det ögonblick den ges: hästen ska vara framför
     skänkeln och handen i kontaktbandet.

     WEBBEN VÄGER TRE HJÄLPER, ROBLOX TVÅ. Sitsen finns inte här (se
     modulhuvudet), så termen som väger den saknas. Skillnaden är
     deklarerad i Telemetri.SAKNAS och mäts av paritetsspecen — den är
     inte bortgömd i en formel som ser lika ut. ]]
function Hjalper.paradKvalitet(a: { [string]: number }): number
	local H = RidKanon.HJALP
	local K = RidKanon.KONTAKT
	local driv = kl(((a.skankel or 0) - K.SKANKEL_TROSKEL) / 0.30, 0, 1)
	local mitt = (K.TYGEL_BAND_MIN + K.TYGEL_BAND_MAX) / 2
	local halv = (K.TYGEL_BAND_MAX - K.TYGEL_BAND_MIN) / 2
	local iband = kl(1 - math.abs((a.tygel or 0) - mitt) / (halv * 1.6), 0, 1)
	return kl(H.PARAD_GOLV + H.PARAD_DRIV * driv + H.PARAD_BAND * iband, 0, 1)
end

return Hjalper
