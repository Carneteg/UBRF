--!strict
-- Presentation of the server's on-foot leading lesson (docs/LEADING-LESSON-CONTRACT.md),
-- never a client-side assessment. The on-foot entry is SECONDARY: Naromrade skips it
-- while the care preparation has an open question, so care cards are never hidden.
local Net = require(game:GetService("ReplicatedStorage").HorseCore.Networking)
local Sprak = require(game:GetService("ReplicatedStorage").HorseCore.Sprak)
local Plats = require(game:GetService("ReplicatedStorage").HorseCore.Ridhusplats)
local Ugneta = require(script.Parent.UgnetaController)
local Aterkoppling = require(script.Parent.LektionsAterkoppling)
local L = {}

local M, TOMTDJUP = 3, 170 -- samma omräkning som LedService.tomt
local bild: any = nil
local sekvens, requestNr = 0, 0
local pending, pendingTid = false, 0
local fel: string? = nil
local valt = false
local startad = false
--[[ R1: sidans generation. Varje ritad kontroll bär den och det VISADE
	försöket; en ny sida, Tillbaka, en ny begäran eller ett nytt försök gör
	äldre kontroller döda, så en kvarglömd återkallning aldrig skickar. ]]
local sidGen = 0
local guide: Model? = nil
local guideNyckel: string? = nil

local AKTIVA = { lead_first = true, leading = true }

local function rivGuide()
	if guide then guide:Destroy() end
	guide, guideNyckel = nil, nil
end

--[[ The goal outline at the arena floor, from the server's goal key only.
	Without a resolvable floor there is no guide (never a guessed height). ]]
local function visaGuide(ref: any)
	if not ref or type(ref.nyckel) ~= "string" then rivGuide(); return end
	if guide and guideNyckel == ref.nyckel then return end
	rivGuide()
	local anl = workspace:FindFirstChild("Anläggning")
	local ubrf = anl and anl:FindFirstChild("UBRF")
	local plats = ubrf and Plats.los(ubrf) or nil
	if not plats then return end
	local y = plats.golvY + 0.1
	local m = Instance.new("Model"); m.Name = "Ledguide"
	local function varld(tx: number, ty: number): Vector3
		return Vector3.new(tx * M, y, (TOMTDJUP - ty) * M)
	end
	local horn = { { ref.x, ref.y }, { ref.x + ref.w, ref.y }, { ref.x + ref.w, ref.y + ref.h },
		{ ref.x, ref.y + ref.h } }
	for i = 1, 4 do
		local a, b = horn[i], horn[(i % 4) + 1]
		local langd = math.sqrt((b[1] - a[1]) ^ 2 + (b[2] - a[2]) ^ 2)
		local n = math.max(1, math.floor(langd / 2))
		for j = 0, n - 1 do
			local t = (j + 0.5) / n
			local pos = varld(a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t)
			local fram = varld(a[1] + (b[1] - a[1]) * (t + 0.01), a[2] + (b[2] - a[2]) * (t + 0.01))
			local part = Instance.new("Part")
			part.Name = "Guide"; part.Anchored = true; part.CanCollide = false
			part.CanTouch = false; part.CanQuery = false; part.CastShadow = false
			part.Size = Vector3.new(0.3 * M, 0.05, 0.9 * M)
			part.CFrame = CFrame.lookAt(pos, fram)
			part.Color = Color3.fromRGB(77, 174, 142); part.Transparency = 0.35
			part.Parent = m
		end
	end
	m.Parent = workspace
	guide, guideNyckel = m, ref.nyckel
end

local function mottag(b: any)
	if type(b) ~= "table" or b.typ ~= "leda" or type(b.revision) ~= "number"
		or type(b.forsokNr) ~= "number" then return end
	--[[ R1: en bild från ett ÄLDRE försök ersätter aldrig ett nyare, och
		inom samma försök aldrig en nyare revision. ]]
	if bild and (b.forsokNr < bild.forsokNr
		or (b.forsokNr == bild.forsokNr and b.revision < bild.revision)) then return end
	if not bild or b.forsokNr ~= bild.forsokNr or b.lage ~= bild.lage or b.kontextNr ~= bild.kontextNr then
		sidGen += 1
	end
	bild = b
	sekvens = math.max(sekvens, b.sekvens or 0)
	if valt and AKTIVA[b.lage] then visaGuide(b.referens) else rivGuide() end
end

local function skicka(op: string, forvantat: number?, kontext: number?)
	if pending and op ~= "finish" then return end
	requestNr += 1
	sidGen += 1
	local token = requestNr
	if op ~= "sync" then sekvens += 1 end
	local seq = sekvens
	pending, pendingTid, fel = true, 0, nil
	task.spawn(function()
		local transport, ok, reason, b = pcall(function()
			return Net.get("LedLektion"):InvokeServer(op, seq, forvantat, kontext)
		end)
		if token ~= requestNr then return end
		pending = false
		if not transport then fel = "network"; return end
		mottag(b)
		if ok ~= true then
			fel = if reason == "inside" or reason == "target" or reason == "horse" or reason == "mounted"
				or reason == "character" or reason == "active" or reason == "stale_attempt"
				or reason == "stale_context" then reason
				else "network"
		elseif op == "finish" then
			valt = false; rivGuide()
		end
	end)
end

local function text(key: string): string
	return Sprak.t("ledlektion." .. key)
end

--[[ En ritad kontroll: bunden till sidans generation och det visade
	försöket (R1). Den gäller bara om ingenting har hänt sedan den ritades. ]]
local function val(key: string, fn: (number, number) -> (), sekundar: boolean?)
	local gen = sidGen
	local forsok = if bild and type(bild.forsokNr) == "number" then bild.forsokNr else 0
	local kontext = if bild and type(bild.kontextNr) == "number" then bild.kontextNr else 0
	return { text = text(key), aktiv = true, sekundar = sekundar == true,
		skicka = function() if gen == sidGen and not pending then fn(forsok, kontext) end end }
end

--[[ Ugneta's on-foot choices: ONE secondary entry, or the lesson page. ]]
function L.panel(): any
	if not startad then return nil end
	if not valt then
		return { ersatt = false, text = nil, ovning = "", vantar = false,
			knappar = { val("choose", function() valt = true; sidGen += 1; skicka("sync") end, true) } }
	end
	local b = bild or { lage = "ready", progress = 0, tips = "intro" }
	local key = if pending then "pending" elseif fel then fel
		elseif b.lage == "ready" or b.lage == "closed" then "intro" else b.tips
	local txt = text(key)
	if not pending and not fel then
		local lp = game:GetService("Players").LocalPlayer
		local at = Aterkoppling.text(b, { typ = "leda", userId = lp and lp.UserId })
		if at then txt = at end
	end
	if b.lage == "leading" and not pending and not fel then
		txt ..= " " .. tostring(b.progress) .. "%"
	end
	local knappar = {}
	if not pending then
		if fel == "network" then
			table.insert(knappar, val("sync", function() skicka("sync") end))
		elseif b.lage == "ready" or b.lage == "closed" then
			table.insert(knappar, val("start", function(f, k) skicka("start", f, k) end))
		elseif b.lage == "complete" or b.lage == "timeout" then
			table.insert(knappar, val("retry", function(f, k) skicka("retry", f, k) end))
		end
	end
	if AKTIVA[b.lage] then
		table.insert(knappar, val("finish", function(f, k) skicka("finish", f, k) end))
	else
		--[[ Tillbaka: nya sidor och ett sent svar på en gammal begäran tas
			inte emot (requestNr), och gamla kontroller dör (sidGen). ]]
		table.insert(knappar, val("back", function()
			valt = false; rivGuide(); sidGen += 1; requestNr += 1; pending = false
		end))
	end
	return { ersatt = true, knappar = knappar, text = txt, ovning = txt, vantar = false }
end

function L.steg(dt: number)
	if pending then
		pendingTid += dt
		if pendingTid >= 10 then pending = false; requestNr += 1; fel = "network" end
	end
end

function L.start()
	if startad then return end
	startad = true
	Net.get("LedLektionSync").OnClientEvent:Connect(mottag)
	game:GetService("RunService").Heartbeat:Connect(L.steg)
	Ugneta.satFotVal(L.panel)
end

--[[ Provkrokar. ]]
function L._valtForProv(): boolean return valt end
function L._bildForProv(): any return bild end
--[[ Provkrok: den RIKTIGA synkvägen (skicka("sync")), så att klientens sekvens
	följer serverns efter att ett prov anropat handlaren direkt. ]]
function L._synkaForProv() skicka("sync") end
function L._guideForProv(): Model? return guide end

return L
