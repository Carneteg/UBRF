--!nostrict
--[[
	WORLD_MANIFEST — vad som FAKTISKT står i den byggda världen.

	Processändringen 05:42, punkt 3: release ska kunna fällas på att
	manifestet motsäger produktkanon eller spelresan. Det kräver att det
	finns ett manifest.

	── OM "ARTIFACT-FIRST" ────────────────────────────────────────────────

	Ordern säger att kontrollerna ska läsa den genererade `.rbxlx` eller
	ett manifest DERIVERAT UR DEN. Placen är script-only: 62 instanser,
	noll geometri. Världens 3300 delar byggs vid runtime av
	`Anlaggningen.luau` när placen startar. Det går alltså inte att läsa
	gångytor, zoner eller hästar ur filen — de finns inte där förrän
	Studio kört den.

	Kedjan som finns i stället är två led, och båda är mätta:

	  1. `kolla-place.py` jämför artefaktens 54 inbäddade moduler ORDAGRANT
	     mot disk, byte för byte.
	  2. Den här specen kör exakt de modulerna och skriver manifestet ur
	     den värld de bygger.

	Det ger samma bevisvärde som att läsa geometri ur filen. Men det är ett
	ARGUMENT och inte en mätning, och det ska stå som just det. Vill man ha
	det bokstavligt — modulerna extraherade ur XML:en och körda därifrån —
	är det görbart och står som öppen fråga i PR:en.

	Manifestet skrivs som JSON mellan två markörer så att
	`tools/pre-tobias-grind.py` kan plocka ut det ur utskriften.

	Kör: python3 roblox/tests/build.py tests/varldsmanifest.spec.luau
	     && luau roblox/tests/.build/varldsmanifest.spec.luau
]]

local M = BuildKit.M
local G = UBRFKomplex
local modell = workspace:FindFirstChild("Anläggning"):FindFirstChild("UBRF")
local bas = modell.PrimaryPart.CFrame

--[[ En minimal JSON-skrivare. Manifestet är maskinläsbart och ska inte
	bero på ett bibliotek bänken inte har. ]]
local function q(s)
	s = tostring(s)
	s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
	return '"' .. s .. '"'
end
local function tal(x) return ("%.3f"):format(x) end

local rader = {}
local function ut(s) table.insert(rader, s) end

HastRigg.start()

ut("{")

--[[ ── Identitet ─────────────────────────────────────────────────────── ]]
ut(('  "byggda_delar": %d,'):format(#modell:GetDescendants()))

--[[ ── Marken: vad som bär och vad som är dekor ───────────────────────── ]]
do
	local barande, dekor = 0, 0
	local lager = {}
	for _, d in ipairs(modell:GetDescendants()) do
		local t = d:GetAttribute("UBRFMark")
		if typeof(t) == "string" then
			if d.CanCollide then barande += 1 else dekor += 1 end
			local y = (d.CFrame.Position.Y + d.Size.Y / 2) / M
			table.insert(lager, ("    {\"typ\": %s, \"bar\": %s, \"ovansida\": %s}")
				:format(q(t), tostring(d.CanCollide), tal(y)))
		end
	end
	ut(('  "mark": {"barande": %d, "dekor": %d, "lager": ['):format(barande, dekor))
	ut(table.concat(lager, ",\n"))
	ut("  ]},")
end

--[[ ── Portalerna ─────────────────────────────────────────────────────── ]]
do
	local p = {}
	for _, d in ipairs(modell:GetDescendants()) do
		if d:GetAttribute("UBRFDorr") == true then
			local cx, cz = BuildKit.tomtkoord(bas, d.CFrame.Position)
			table.insert(p, ("    {\"byggnad\": %s, \"sida\": %s, \"typ\": %s, \"x\": %s, \"y\": %s, \"bredd\": %s}")
				:format(q(d:GetAttribute("Byggnad")), q(d:GetAttribute("Sida")),
					q(d:GetAttribute("Oppningstyp")), tal(cx), tal(cz),
					tal(tonumber(d:GetAttribute("Bredd")) or 0)))
		end
	end
	ut(('  "portaler": ['))
	ut(table.concat(p, ",\n"))
	ut("  ],")

	local ip = {}
	for _, d in ipairs(modell:GetDescendants()) do
		local skal = d:GetAttribute("IngenPassage")
		if typeof(skal) == "string" then
			table.insert(ip, ("    {\"byggnad\": %s, \"sida\": %s, \"typ\": %s, \"skal\": %s}")
				:format(q(d:GetAttribute("Byggnad")), q(d:GetAttribute("Sida")),
					q(d:GetAttribute("Oppningstyp")), q(skal)))
		end
	end
	ut('  "icke_passager": [')
	ut(table.concat(ip, ",\n"))
	ut("  ],")
end

--[[ ── Hästarna ───────────────────────────────────────────────────────── ]]
do
	local h = {}
	for _, m in ipairs(game:GetService("CollectionService"):GetTagged("Horse")) do
		local rot = (m :: any).PrimaryPart or m:FindFirstChild("BodyCollider")
		if rot then
			local cx, cz = BuildKit.tomtkoord(bas, rot.CFrame.Position)
			local id = tostring(m:GetAttribute("HorseId"))
			local box = (Stallet :: any).boxFor(id)
			table.insert(h, ("    {\"id\": %s, \"x\": %s, \"y\": %s, \"box\": %s}")
				:format(q(id), tal(cx), tal(cz),
					box and tostring(box.nummer) or "null"))
		end
	end
	ut(('  "hastar": {"antal": %d, "kanoniska": %d, "lista": ['):format(
		#h, #(UBRFSpel :: any).ordning))
	ut(table.concat(h, ",\n"))
	ut("  ]},")
end

--[[ ── Utrustningsplatserna ───────────────────────────────────────────── ]]
do
	--[[ En utrustningsplats är oftast flera delar med samma Inredning-id (en
		sadelkrok består av krok, hylla och sadel). Manifestet ska räkna
		PLATSER, inte delar — annars ser sex delar ut som sex sadelplatser.
		Mittpunkten är delarnas medelläge, alltså platsens läge på tomten. ]]
	local ordning, sum = {}, {}
	for _, d in ipairs(modell:GetDescendants()) do
		local id = d:GetAttribute("Inredning")
		if typeof(id) == "string" and string.sub(id, 1, 6) == "sadel_" then
			local cx, cz = BuildKit.tomtkoord(bas, d.CFrame.Position)
			if not sum[id] then
				sum[id] = { x = 0, y = 0, n = 0 }
				table.insert(ordning, id)
			end
			local a = sum[id]
			a.x, a.y, a.n = a.x + cx, a.y + cz, a.n + 1
		end
	end
	table.sort(ordning)
	local u = {}
	for _, id in ipairs(ordning) do
		local a = sum[id]
		table.insert(u, ("    {\"id\": %s, \"delar\": %d, \"x\": %s, \"y\": %s}")
			:format(q(id), a.n, tal(a.x / a.n), tal(a.y / a.n)))
	end
	ut('  "utrustning": [')
	ut(table.concat(u, ",\n"))
	ut("  ],")
end

--[[ ── Skyltarna ur kanon ─────────────────────────────────────────────── ]]
do
	local s = {}
	for _, d in ipairs(modell:GetDescendants()) do
		local t = d:GetAttribute("Propstyp")
		if typeof(t) == "string" then
			local cx, cz = BuildKit.tomtkoord(bas, d.CFrame.Position)
			table.insert(s, ("    {\"typ\": %s, \"text\": %s, \"x\": %s, \"y\": %s}")
				:format(q(t), q(d:GetAttribute("Text")), tal(cx), tal(cz)))
		end
	end
	ut('  "skyltar": [')
	ut(table.concat(s, ",\n"))
	ut("  ],")

	--[[ Och vad kanon HAR som världen ännu inte bygger. Ett manifest som
		bara listar det byggda kan aldrig visa det som saknas. ]]
	local saknas = {}
	local byggdaTyper = { mast = true }
	for _, d in ipairs(modell:GetDescendants()) do
		local t = d:GetAttribute("Propstyp")
		if typeof(t) == "string" then byggdaTyper[t] = true end
	end
	local antal = {}
	for _, pr in ipairs(G.props or {}) do
		if not byggdaTyper[pr.typ] then antal[pr.typ] = (antal[pr.typ] or 0) + 1 end
	end
	for t, n in pairs(antal) do
		table.insert(saknas, ("    {\"typ\": %s, \"antal\": %d}"):format(q(t), n))
	end
	table.sort(saknas)
	ut('  "rekvisita_som_saknas": [')
	ut(table.concat(saknas, ",\n"))
	ut("  ],")
end

--[[ ── Spawnen ────────────────────────────────────────────────────────── ]]
do
	local sp = nil
	for _, d in ipairs(modell:GetDescendants()) do
		if d.ClassName == "SpawnLocation" then sp = d end
	end
	if sp then
		local cx, cz = BuildKit.tomtkoord(bas, sp.CFrame.Position)
		ut(('  "spawn": {"x": %s, "y": %s, "motdorr": %s}')
			:format(tal(cx), tal(cz), q(sp:GetAttribute("MotDorr"))))
	else
		ut('  "spawn": null')
	end
end

ut("}")

print("### WORLD_MANIFEST_BORJAR ###")
print(table.concat(rader, "\n"))
print("### WORLD_MANIFEST_SLUTAR ###")
