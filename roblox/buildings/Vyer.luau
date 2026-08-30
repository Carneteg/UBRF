--!strict
-- De fem vyer Senior Fidelity Review 03 kräver för Product Owner visual
-- acceptance, uträknade ur geometrin i stället för nedskrivna som siffror.
-- Flyttas ett hus i src/site.js följer kamerorna med.
--
-- Använd i Studio efter att Anlaggningen.luau körts:
--
--     Vyer.lista()            -- skriver ut vad som finns
--     Vyer.ga("ankomsten")    -- ställer kameran
--
-- Måtten i meter, samma koordinatsystem som resten: origo i sydväst,
-- +x öster, +y norr. BuildKit räknar om till studs.

local Vyer = {}

local BK = BuildKit
local G = UBRFKomplex

local function hus(id)
	for _, b in ipairs(G.byggnader) do
		if b.id == id then return b end
	end
	error("hittar inte byggnaden " .. id)
end

local ridhus, stall, hg = hus("ridhus"), hus("stall"), hus("hastgang")
local S, R = G.stall, G.ridhus

-- Gårdarna på var sida om hästgången.
local gardMitt = (ridhus.rekt.x + ridhus.rekt.w + stall.rekt.x) / 2
local sodraGard = (math.max(ridhus.rekt.y, stall.rekt.y) + hg.rekt.y) / 2
local norraGard = (hg.rekt.y + hg.rekt.h
	+ math.min(ridhus.rekt.y + ridhus.rekt.h, stall.rekt.y + stall.rekt.h)) / 2

-- Gång A i stallet, i världskoordinater.
local gangA = S.gangar.A
local gangAx = S.origo.x + (gangA.x0 + gangA.x1) / 2

Vyer.vyer = {
	{
		id = "oversikt",
		text = "Översikt uppifrån — jämför med satellitbilden",
		fran = { x = gardMitt, y = sodraGard - 40, h = 95 },
		mot = { x = gardMitt, y = (sodraGard + norraGard) / 2 },
		krav = "Två parallella huvudvolymer, EN tvärgående förbindelse mellan dem, och mellanrummet delat i två gårdsytor.",
	},
	{
		id = "ankomsten",
		text = "Grusplanen mot de norra gavlarna — så man kommer till UBRF",
		fran = { x = gardMitt, y = math.min(ridhus.rekt.y + ridhus.rekt.h,
			stall.rekt.y + stall.rekt.h) + 16, h = 1.7 },
		mot = { x = gardMitt, y = norraGard },
		krav = "Ridhuset till höger, stallet till vänster, och husen ska läsa som ETT komplex — inte som två fristående lador.",
	},
	{
		id = "gardarna",
		text = "Södra gårdsytan norrut, mot hästgången",
		fran = { x = gardMitt, y = sodraGard - 6, h = 1.7 },
		mot = { x = gardMitt, y = hg.rekt.y + hg.rekt.h / 2 },
		krav = "Gården ska STÄNGAS av hästgången. Ser man rakt igenom till nästa gårdsyta är förbindelsen fel byggd.",
	},
	{
		id = "stallgangen",
		text = "Inne i gång A, mot tvärkorridoren",
		fran = { x = gangAx, y = S.origo.y + S.boxStartY + 2, h = 1.7 },
		mot = { x = gangAx, y = S.origo.y + (S.tvarGang.y0 + S.tvarGang.y1) / 2 },
		krav = "Boxar på båda sidor, och tvärkorridoren ska gå att se HELA vägen tvärs huset — den når båda långsidorna i planen.",
	},
	{
		id = "ridhuset",
		text = "Inne på banan, mot läktaren, E och hästgången",
		fran = { x = R.origo.x + R.bana.x + 4,
			y = R.origo.y + (R.laktare.gap.y0 + R.laktare.gap.y1) / 2, h = 1.7 },
		mot = { x = R.origo.x + R.laktare.x0 + 3,
			y = R.origo.y + (R.laktare.gap.y0 + R.laktare.gap.y1) / 2 },
		krav = "Läktaren ska ha ett GAP rakt fram, och sargen en GRIND i det gapet. Är sargen obruten går det inte att leda hästen ut på banan.",
	},
}

function Vyer.lista()
	print("Vyer för Gate F01 · Product Owner visual acceptance")
	for i, v in ipairs(Vyer.vyer) do
		print(string.format("  %d. Vyer.ga(\"%s\")  — %s", i, v.id, v.text))
	end
	print("\nKör Vyer.ga(id) och ta en skärmdump från var och en.")
end

function Vyer.ga(id: string)
	for _, v in ipairs(Vyer.vyer) do
		if v.id == id then
			local modell = workspace:FindFirstChild("Anläggning")
			local ubrf = modell and modell:FindFirstChild("UBRF")
			local bas = ubrf and ubrf.PrimaryPart and ubrf.PrimaryPart.CFrame
			if not bas then error("bygg Anlaggningen.luau först") end
			BK.cameraLike(bas, v.fran.x, v.fran.y, v.mot.x, v.mot.y, v.fran.h)
			print("── " .. v.text)
			print("   Att titta efter: " .. v.krav)
			return
		end
	end
	error("okänd vy: " .. id .. " — kör Vyer.lista()")
end

return Vyer
