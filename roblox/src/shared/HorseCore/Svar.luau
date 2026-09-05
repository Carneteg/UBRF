--!strict
--[[
	G02-B punkt 2 — HÄSTENS SVAR, Roblox-sidan.

	Motsvarigheten till src/riding/svar.js. Samma formler, och talen läses
	ur RidKanon.SVAR och RidKanon.PROFILER — genererade ur webbens modul,
	inte avskrivna. Ändras en konstant på webben ändras den här, och
	paritetsspecen faller om exporten inte körts.

	VAD SOM PORTERAS OCH VAD SOM INTE GÖR DET

	Roblox rörelsekärna har ingen mjukhet (handens stadga över tid) och
	ingen spänning. De två är egna delsystem på webben och att bygga dem
	här vore att porta halva ridmodellen, inte att harmonisera den. De
	står därför kvar i Telemetri.SAKNAS, och de termer som väger dem är
	FRÅNVARANDE här — inte utfyllda med ett påhittat tal:

	  fokus      saknar källa. Svarstiden anropas med fokus = 1, alltså
	             termens neutrala element: den bidrar med noll i stället
	             för med en gissning. Skillnaden mot webben är därmed
	             högst SVAR_FOKUS sekunder, den är deklarerad, och
	             paritetsspecen mäter den i stället för att dölja den.
	  balans     spänningstermen är frånvarande av samma skäl. Övriga
	             tre avdrag — yttertygelstöd, svängens fartkrav och
	             övergången — har riktiga källor här.

	Hemmet för de två är G02-C. Att fylla dem med konstanter för att få
	identiska tal hade gett paritet i siffran och inte i upplevelsen, och
	det är precis vad paritetsregeln finns för att förhindra.
]]

local RidKanon = require(script.Parent.RidKanon)

local Svar = {}

Svar.PROFILER = RidKanon.PROFILER

--[[ Fält utan källa på Roblox. Läses av Telemetri, som deklarerar dem. ]]
Svar.SAKNAS = { "fokus" }

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

--[[ Balansens målvärde. `bojkrav` 0–1 av fullt styrutslag, `ytterstod`
     ur hjälpsemantiken, `fartkrav` svängens centripetalkrav normaliserat
     som på webben.

     SPÄNNINGSTERMEN ÄR FRÅNVARANDE — se modulhuvudet. ]]
function Svar.balansMal(h: { [string]: any }?, utbildning: number, bojkrav: number,
	ytterstod: number, fartkrav: number, iOvergang: boolean): number
	local S = RidKanon.SVAR
	local avdrag = S.BALANS_YTTER * kl(bojkrav, 0, 1) * (1 - kl(ytterstod, 0, 1))
		+ S.BALANS_FART * kl(fartkrav, 0, 1)
		+ (if iOvergang then S.BALANS_OVERGANG else 0)
	local damp = 1 - S.BALANS_UTB * kl(utbildning, 0, 1)
	return kl(1 - avdrag * damp * Svar.profil(h).balans, 0, 1)
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
