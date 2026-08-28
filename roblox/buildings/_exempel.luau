-- EXEMPEL på hur ett byggnadsskript ska se ut. Kopiera till src/buildings/Ridhuset.lua och byt ut ALLA siffror mot värden från KORT.md.
-- Siffrorna nedan är påhittade platshållare – de får inte användas som de är.
-- Körs i Studio via MCP: klistra in BuildKit.lua följt av detta skript i samma run_code-anrop.

local BK = BuildKit -- (om BuildKit är inklistrad ovanför) eller: require(game.ServerStorage.BuildKit)

-- KORT.md › Placering
local model, base = BK.newBuilding("Ridhuset", Vector3.new(0, 0, 0), 0, {
	Referens = "references/buildings/ridhus", Version = 1,
})

-- KORT.md › Volym: fotavtryck 60 × 22 m, takfot 4,5 m   [PLATSHÅLLARE]
local L, B, H = 60, 22, 4.5
local FASAD = Color3.fromRGB(150, 45, 40)   -- KORT.md › Fasader › Syd: "falurött" (RGB från foto)
local TAK   = Color3.fromRGB(190, 195, 200) -- KORT.md › Tak › ljusgrå plåt
local VIND  = Color3.fromRGB(235, 235, 230) -- KORT.md › Tak › vindskivor, vita

-- Golv/grund
BK.box(model, base, "Grund", 0, -0.2, 0, L, 0.2, B, Color3.fromRGB(120,120,115), Enum.Material.Concrete)

-- Väggar (KORT.md › Fasader)
BK.wall(model, base, "Vägg Syd",  0, 0,     L, H, 0.3, "X", FASAD)
BK.wall(model, base, "Vägg Norr", 0, B-0.3, L, H, 0.3, "X", FASAD)
BK.wall(model, base, "Vägg Väst", 0, 0,     B, H, 0.3, "Z", FASAD)
BK.wall(model, base, "Vägg Öst",  L-0.3, 0, B, H, 0.3, "Z", FASAD)

-- Fönster, sydfasad: 6 st ~1,2×1,0 m, sill 1,4 m, jämnt fördelade  [KORT.md › Fasader › Syd]
for i = 1, 6 do
	local x = (L / 7) * i - 0.6
	BK.window(model, base, x, 0, 1.4, 1.2, 1.0, "X", -1, VIND)
end

-- Skjutport, sydfasad, 4 m bred, 3,5 m hög, ljusgrå  [KORT.md › Fasader › Syd]
BK.door(model, base, "Skjutport", 3, 0, 4, 3.5, "X", -1, Color3.fromRGB(200, 200, 205))

-- Tak: sadeltak, nock längs långsidan, ~22°, överhäng 0,5 m  [KORT.md › Tak]
model:SetAttribute("GavelFärg", FASAD)
BK.gableRoof(model, base, 0, 0, L, B, H, 22, "X", 0.5, TAK)

print("OK Ridhuset byggd, " .. #model:GetDescendants() .. " objekt")

-- Kamera för jämförelse mot ridhus-syd-01.jpg (stå ~25 m söder om SV-hörnet, snett)  [KORT.md › Foton]
-- BK.cameraLike(base, -8, -25, L/2, B/2)
