--!strict
--[[
	G02-B punkt 2 — HÄSTENS SVAR, Roblox-sidan.

	Motsvarigheten till src/riding/svar.js. Samma formler, och talen läses
	ur RidKanon.SVAR och RidKanon.PROFILER — genererade ur webbens modul,
	inte avskrivna. Ändras en konstant på webben ändras den här, och
	paritetsspecen faller om exporten inte körts.

MJUKHET, SPÄNNING OCH FOKUS FINNS HÄR sedan senior review av #87.

	De tre stod förut som deklarerade luckor med G02-C som hem. Reviewen
	underkände det: #83 kräver balans, fokus, spänning och energi i
	G02-B, och plattformsspecifik input får skilja sig — produkten får
	inte sakna själva beteendet.

	Formlerna är webbens, och talen läses ur RidKanon.SVAR. För att det
	skulle gå fick spänningens literaler i src/model.js namn (SP_*) och
	flyttade till kanonen; ingen siffra ändrades, och paritetsspecens
	golden-rader bevakar att de två räknar lika.

	FEM INGÅNGAR SAKNAR KÄLLA PÅ ROBLOX, och de fylls inte med gissningar
	utan anropas med sina NEUTRALA element, var och en namngiven:

	  stallro    1  — ingen stallro-modell finns; termen blir noll
	  sadellage  1  — ingen sadelpassning finns
	  underlag   1  — inget underlagssystem finns
	  dagsform   0  — bidrar bara till lugnet, som då blir mindre
	  spö        av — inget spö finns på Roblox

	Skillnaden mot webben är därmed en känd och deklarerad förskjutning i
	spänningens nivå, inte i dess form. Att fylla dem med konstanter för
	att få identiska tal hade gett paritet i siffran och inte i
	upplevelsen.
]]

local RidKanon = require(script.Parent.RidKanon)

local Svar = {}

Svar.PROFILER = RidKanon.PROFILER

--[[ Tomt sedan #87:s review. Listan står kvar som kontrakt: nästa
     storhet utan källa ska deklareras här och inte utelämnas tyst. ]]
Svar.SAKNAS = {}

local function kl(v: number, lo: number, hi: number): number
	return math.clamp(v, lo, hi)
end

--[[ Hästens profil, med `skolhast` som fallback. Att fallbacken är
     utgångsläget och inte ett fel är avsiktligt: en häst utan tilldelad
     profil ska bete sig som modellen alltid gjort. ]]
function Svar.profil(h: { [string]: any }?): { [string]: any }
	--[[ Två stavningar med flit: `profil` är hästdatans fältnamn
	     (UBRFSpelData, samma som webbens), `Profil` är Roblox
	     attributnamn i Config.STATS. Samma värde, två vägar in, och
	     ingen av dem ska behöva skrivas om för att den andra finns. ]]
	local namn = if h then (h.profil or h.Profil) else nil
	return (namn and Svar.PROFILER[namn]) or Svar.PROFILER.skolhast
end

--[[ Hästens KÄNSLIGHET, 0–1, ur det Roblox redan har.

     Webbens `h.kanslighet` säger hur mycket hon reagerar. Roblox
     motsvarighet är temperamentets `reactGain` — samma storhet, annan
     skala — och den normaliseras här i stället för att ett nytt
     stat-fält uppfinns. Spannet är temperamentstabellens eget:
     Brave 0,70 lägst, Sensitive 1,35 högst. ]]
function Svar.kanslighet(temperament: { [string]: any }?): number
	local g = if temperament then (temperament.reactGain or 1) else 1
	return kl((g - 0.70) / (1.35 - 0.70), 0, 1)
end

--[[ Svarstiden för EN hjälp, i sekunder. `kanslighet` är hästens egen,
     `klarhet` hur samordnad hjälpen var (0–1).

     Profilen skalar SUMMAN, inte varje term för sig, och avdraget för
     tydlighet läggs efter skalningen — annars hade en trög häst också
     blivit den som tjänar mest på en tydlig hjälp, alltså motsatsen till
     vad profilen säger. Identiskt med webben. ]]
function Svar.svarstid(h: { [string]: any }?, kanslighet: number, fokus: number,
	energi: number, klarhet: number): number
	local S = RidKanon.SVAR
	local P = Svar.profil(h)
	local t = (S.SVAR_BAS
		+ S.SVAR_TROG * (1 - kl(kanslighet, 0, 1))
		+ S.SVAR_FOKUS * (1 - kl(fokus, 0, 1))
		+ S.SVAR_ENERGI * (1 - kl(energi, 0, 1))) * P.svar
		- S.SVAR_KLAR * P.klar * kl(klarhet, 0, 1)
	return kl(t, S.SVAR_MIN, S.SVAR_MAX)
end

--[[ Sitsens stöd i svängen, 0–1: hur mycket av vägen från neutral sits
     till den djupa paradsitsen ryttaren sitter. Samma funktion som
     webbens svarSitsStod. ]]
function Svar.sitsStod(sits: number): number
	local KN = RidKanon.KONTAKT
	return kl(((sits or 0) - KN.SITS_NEUTRAL) / (KN.SITS_PARAD - KN.SITS_NEUTRAL), 0, 1)
end

--[[ Balansens målvärde. `bojkrav` 0–1 av fullt styrutslag, `ytterstod`
     ur hjälpsemantiken, `fartkrav` svängens centripetalkrav normaliserat
     som på webben, `sits` hjälpsemantikens sits.

     SÄTET ÄR EN BALANSMODIFIERARE (senior review #87): sitter ryttaren
     ned i bågen bär hon hästen, sitter hon lätt får hästen bära den
     själv. Termen biter bara när det finns en båge att stödja. ]]
function Svar.balansMal(h: { [string]: any }?, utbildning: number, bojkrav: number,
	ytterstod: number, fartkrav: number, iOvergang: boolean,
	spanning: number, sits: number): number
	local S = RidKanon.SVAR
	local avdrag = S.BALANS_YTTER * kl(bojkrav, 0, 1) * (1 - kl(ytterstod, 0, 1))
		+ S.BALANS_VIKT * kl(bojkrav, 0, 1) * (1 - Svar.sitsStod(sits))
		+ S.BALANS_FART * kl(fartkrav, 0, 1)
		+ (if iOvergang then S.BALANS_OVERGANG else 0)
		+ S.BALANS_SPANNING * kl(spanning or 0, 0, 1)
	local damp = 1 - S.BALANS_UTB * kl(utbildning, 0, 1)
	return kl(1 - avdrag * damp * Svar.profil(h).balans, 0, 1)
end

--[[ FOKUSENS MÅLVÄRDE. Webbens formel, talen ur kanonen. `paradLyft` är
     0–1 och läggs på när en halvhalt just lästes. ]]
function Svar.fokusMal(mjukhet: number, spanning: number, utomhus: boolean,
	paradLyft: number, h: { [string]: any }?): number
	local S = RidKanon.SVAR
	return kl(S.FOKUS_BAS + S.FOKUS_MJUK * kl(mjukhet, 0, 1)
		+ S.FOKUS_LUGN * (1 - kl(spanning, 0, 1))
		- (if utomhus then S.FOKUS_UTE else 0)
		+ S.FOKUS_PARAD * Svar.profil(h).fokus * kl(paradLyft or 0, 0, 1), 0, 1)
end

--[[ MJUKHETEN — handens stadga över tid. Webbens formel: hjälpernas
     avvikelse från sitt eget glidande medel, filtrerad.

     `medel` är anroparens lilla tabell {skankel,tygel,sits,styrning} som
     modulen uppdaterar. Att den ligger hos anroparen och inte här är för
     att modulen ska förbli tillståndslös och gå att prova rad för rad. ]]
function Svar.mjukhet(nuv: number, medel: { [string]: number },
	a: { [string]: number }, dt: number): number
	local KN = RidKanon.KONTAKT
	local beta = kl(dt / KN.AIDS_TAU, 0, 1)
	local avvik = math.abs((a.skankel or 0) - medel.skankel)
		+ math.abs((a.tygel or 0) - medel.tygel)
		+ 0.7 * math.abs((a.sits or 0) - medel.sits)
		+ 0.7 * math.abs((a.styrning or 0) - medel.styrning)
	medel.skankel += ((a.skankel or 0) - medel.skankel) * beta
	medel.tygel += ((a.tygel or 0) - medel.tygel) * beta
	medel.sits += ((a.sits or 0) - medel.sits) * beta
	medel.styrning += ((a.styrning or 0) - medel.styrning) * beta
	local kvot = avvik / KN.AMPLITUD_SKALA
	local tick = 1 / (1 + kvot * kvot)
	return nuv + (tick - nuv) * kl(KN.MJUKHET_EMA * dt, 0, 1)
end

--[[ SPÄNNINGENS MÅLVÄRDE. Webbens formel, talen ur kanonen.

     `ctx` bär de fem ingångar Roblox saknar källa till; anroparen skickar
     deras neutrala element och modulen räknar med dem som vilka andra
     som helst. Se modulhuvudet för vilka och varför. ]]
function Svar.spanningMal(a: { [string]: number }, hast: { [string]: any },
	mjukhet: number, rang: number, gangart: string, ctx: { [string]: any }): number
	local S, KN = RidKanon.SVAR, RidKanon.KONTAKT
	local kf = S.SP_KANSL_BAS + S.SP_KANSL * kl(hast.kanslighet or 0.5, 0, 1)
	local press = 0
	local tygel = a.tygel or 0
	if tygel > KN.TYGEL_HART then
		press += (tygel - KN.TYGEL_HART) * S.SP_HART
	elseif tygel > KN.TYGEL_BAND_MAX then
		press += (tygel - KN.TYGEL_BAND_MAX) * S.SP_BAND
	end
	press += (1 - kl(mjukhet, 0, 1)) * S.SP_OMJUK
	if (a.skankel or 0) > KN.SKANKEL_FOR_MYCKET then
		press += ((a.skankel or 0) - KN.SKANKEL_FOR_MYCKET) * S.SP_SKANKEL
	end
	if (a.sits or 0) > S.SP_SITS_TROSKEL and gangart == "galopp" then
		press += ((a.sits or 0) - S.SP_SITS_TROSKEL) * S.SP_SITS_GALOPP
	end
	press += (1 - (ctx.stallro or 1)) * S.SP_STALLRO
		+ (1 - (ctx.sadellage or 1)) * S.SP_SADEL
		+ (1 - (ctx.underlag or 1)) * S.SP_UNDERLAG
	press += kl(hast.skygghet or 0.2, 0, 1) * S.SP_SKYGG
		* (if ctx.utomhus then S.SP_SKYGG_UTE else 1)
	local lugn = kl(rang, 0, 1) * S.SP_LUGN_RANG
		+ kl(hast.forlatande or 0.6, 0, 1) * S.SP_LUGN_FORLAT
		+ kl(mjukhet, 0, 1) * S.SP_LUGN_MJUK
		+ kl(ctx.dagsform or 0, 0, 1) * S.SP_LUGN_DAGSFORM
	return kl(press * kf - lugn * S.SP_LUGN_VIKT, 0, 1)
end

--[[ Spänningens rörelse mot målet. Stiger med känsligheten, faller med
     förlåtandet — webbens approach(), samma tal. ]]
function Svar.spanningSteg(nuv: number, mal: number, hast: { [string]: any },
	dt: number): number
	local S, KN = RidKanon.SVAR, RidKanon.KONTAKT
	local upp = KN.SPANNING_STIGNING
		* (S.SP_STIG_BAS + S.SP_STIG_KANSL * kl(hast.kanslighet or 0.5, 0, 1))
	local ner = KN.SPANNING_FALL
		* (S.SP_FALL_BAS + S.SP_FALL_FORLAT * kl(hast.forlatande or 0.6, 0, 1))
	if mal > nuv then return nuv + math.min(mal - nuv, upp * dt) end
	return nuv - math.min(nuv - mal, ner * dt)
end

--[[ Hur mycket snävare bågen blir än den ryttaren bad om, som en faktor
     på kurvaturen. 0 vid full balans, 0 på rakt spår. ]]
function Svar.infall(balans: number, bojkrav: number): number
	local S = RidKanon.SVAR
	return S.INFALL_MAX * (1 - kl(balans, 0, 1)) * kl(bojkrav, 0, 1)
end

--[[ Energins ändring per sekund. Positiv = hämtar sig. `gangart` är
     WEBBENS namn — anroparen översätter Roblox gångartsnamn med
     RidKanon.MOTSVARIGHET, så tabellen inte behöver finnas i två
     nyckelrymder.

     Spänningen tär på webben; här finns den inte, och termen anropas
     därför med 0. Det är samma frånvaro som i balansen. ]]
function Svar.energiTakt(gangart: string, spanning: number, h: { [string]: any }?): number
	local S = RidKanon.SVAR
	local P = Svar.profil(h)
	local tapp = (S.ENERGI_TAPP[gangart] or 0) * (1 + S.ENERGI_SPANN * (spanning or 0)) * P.tapp
	local ater = (S.ENERGI_ATER[gangart] or 0) * P.ater
	return ater - tapp
end

--[[ Energin en häst går ut med. Webben räknar den ur dagsformen; Roblox
     har ingen dagsform, så en utvilad häst startar på full energi — det
     är webbens värde vid dagsform 1,0 och alltså ingen egen konstant. ]]
function Svar.startEnergi(): number
	return 1
end

return Svar
