--!nostrict
--[[
	VÄRLDSMÄTNINGEN — avatarens mått och konfigurationsrymden, EN gång.

	`varldskoherens.spec` och `topologi.spec` mäter båda om en människa kan
	ta sig fram i den byggda världen. Två kopior av avatarens mått hade
	varit två sanningar om samma spelare, och det är precis den sortens
	glidning som lät HUD:en lova något servern nekade.

	Modulen är en TESTMODUL. Den bygger ingenting och ändrar ingenting —
	den läser den byggda världen och svarar på frågor om den.

	`END_TO_END_PLAYABILITY_GATE` (spelbarhet.spec) har fortfarande sin
	egen kopia med den äldre golvregeln. Det är en redovisad skuld, inte
	ett förbiseende: den grinden är grön och rör en annan kedja, och att
	skriva om den i samma andetag som en blockerarrättelse vore att blanda
	två leveranser.
]]

local VM = {}

--[[ Roblox standardavatar: ~2 studs bred, ~5 studs hög. I meter med
	M = 3 studs/m blir det 0,67 m bred och 1,7 m hög. Radien är alltså
	0,34 m; 0,35 används för marginal. STEG är vad en Humanoid klarar att
	kliva upp på utan hopp. ]]
VM.RADIE = 0.35
VM.HOJD = 1.75
VM.STEG = 0.55
VM.MAXGOLV = 3.0
VM.CELL = 0.25

--[[ Alla kolliderande delar i KARTANS koordinater. `tomtkoord` är vägen
	tillbaka från den vända världen; se `BuildKit.tomtlage`. ]]
function VM.lador(modell, bas)
	local M = BuildKit.M
	local ut = {}
	for _, d in ipairs(modell:GetDescendants()) do
		if d.CFrame and d.Size and d.CanCollide ~= false and d.Transparency ~= 1 then
			local c, s = d.CFrame.Position, d.Size
			local cx, cz = BuildKit.tomtkoord(bas, c)
			table.insert(ut, {
				namn = d.Name, del = d,
				x0 = cx - s.X / (2 * M), x1 = cx + s.X / (2 * M),
				z0 = cz - s.Z / (2 * M), z1 = cz + s.Z / (2 * M),
				y0 = (c.Y - s.Y / 2) / M, y1 = (c.Y + s.Y / 2) / M,
			})
		end
	end
	return ut
end

--[[ ══ EN LOKAL KONFIGURATIONSRYMD ══════════════════════════════════════

	Hela tomten är 210×170 m; ett rutnät över allt hade blivit en halv
	miljon celler per dörr. Varje prov bygger därför sin egen lilla karta
	kring det som mäts. Metoden är densamma som i END_TO_END: varje hinder
	blåses upp med avatarens radie och sökningen sker för en PUNKT. ]]
function VM.karta(alla, x0, z0, x1, z1, utan)
	local NX = math.ceil((x1 - x0) / VM.CELL)
	local NZ = math.ceil((z1 - z0) / VM.CELL)
	local k = {
		NX = NX, NZ = NZ, x0 = x0, z0 = z0,
		golv = {}, blockerad = {},
		idx = function(ix, iz) return (iz - 1) * NX + ix end,
		cellFor = function(x, z)
			return math.floor((x - x0) / VM.CELL) + 1, math.floor((z - z0) / VM.CELL) + 1
		end,
		mitt = function(ix, iz)
			return x0 + (ix - 0.5) * VM.CELL, z0 + (iz - 0.5) * VM.CELL
		end,
	}
	local lista = {}
	for _, l in ipairs(alla) do
		if l.x1 >= x0 - 1 and l.x0 <= x1 + 1 and l.z1 >= z0 - 1 and l.z0 <= z1 + 1
			and l.del ~= utan then
			table.insert(lista, l)
		end
	end

	--[[ ══ VILKEN YTA STÅR MAN PÅ? ════════════════════════════════════════

		END_TO_END-grinden tar den HÖGSTA ytan under VM.MAXGOLV. Den regeln
		stämmer för staplade plan — man står på läktardäcket, inte på marken
		under det — men den gör ett SKÄRMTAK till ett golv. Skärmtaket över
		en entrédörr ligger på 2,63 m, alltså under VM.MAXGOLV, och då blev
		marken utanför dörren "golv 2,63" och steget dit 2,63 m. Sex av de
		elva dörrar som föll här föll på just det, och de är inte trasiga i
		världen — en avatar går obehindrat under ett tak i 2,5 m.

		Regeln här är i stället fysisk:

		    man står på den LÄGSTA yta man får plats ovanpå.

		Marken under skärmtaket har 2,5 m fritt ovanför sig och väljs.
		Marken under läktardäcket har 1,70 m — mindre än avatarens 1,75 —
		så där väljs däcket. Samma regel ger båda svaren. ]]
	local ytor = {}
	for _, l in ipairs(lista) do
		local ax0, az0 = k.cellFor(l.x0, l.z0)
		local ax1, az1 = k.cellFor(l.x1, l.z1)
		for iz = math.max(1, az0), math.min(NZ, az1) do
			for ix = math.max(1, ax0), math.min(NX, ax1) do
				local mx, mz = k.mitt(ix, iz)
				if mx >= l.x0 and mx <= l.x1 and mz >= l.z0 and mz <= l.z1 then
					local i = k.idx(ix, iz)
					local t = ytor[i]
					if t == nil then t = {}; ytor[i] = t end
					table.insert(t, l)
				end
			end
		end
	end
	for i, t in pairs(ytor) do
		local kandidater = {}
		for _, l in ipairs(t) do
			if l.y1 <= VM.MAXGOLV then table.insert(kandidater, l.y1) end
		end
		table.sort(kandidater)
		for _, y in ipairs(kandidater) do
			local fritt = true
			for _, l in ipairs(t) do
				if l.y1 > y + 0.001 and l.y0 < y + VM.HOJD then fritt = false break end
			end
			if fritt then k.golv[i] = y break end
		end
		--[[ Ingen yta har full takhöjd: då står man ändå på den högsta —
			ett för lågt utrymme är en blockering, inte ett hål i världen,
			och det avgörs i nästa pass. ]]
		if k.golv[i] == nil and #kandidater > 0 then
			k.golv[i] = kandidater[#kandidater]
		end
	end

	for _, l in ipairs(lista) do
		local ax0, az0 = k.cellFor(l.x0 - VM.RADIE, l.z0 - VM.RADIE)
		local ax1, az1 = k.cellFor(l.x1 + VM.RADIE, l.z1 + VM.RADIE)
		for iz = math.max(1, az0), math.min(NZ, az1) do
			for ix = math.max(1, ax0), math.min(NX, ax1) do
				local i = k.idx(ix, iz)
				local g = k.golv[i]
				if g ~= nil and not k.blockerad[i] then
					local mx, mz = k.mitt(ix, iz)
					if mx >= l.x0 - VM.RADIE and mx <= l.x1 + VM.RADIE
						and mz >= l.z0 - VM.RADIE and mz <= l.z1 + VM.RADIE then
						if l.y1 > g + VM.STEG and l.y0 < g + VM.HOJD then
							k.blockerad[i] = true
						end
					end
				end
			end
		end
	end
	return k
end

function VM.gangbar(k, ix, iz)
	if ix < 1 or iz < 1 or ix > k.NX or iz > k.NZ then return false end
	local i = k.idx(ix, iz)
	return k.golv[i] ~= nil and not k.blockerad[i]
end

function VM.sok(k, fran, till)
	local sx, sz = k.cellFor(fran.x, fran.y)
	local tx, tz = k.cellFor(till.x, till.y)
	if not VM.gangbar(k, sx, sz) then return nil, "startcellen är inte gångbar" end
	if not VM.gangbar(k, tx, tz) then return nil, "målcellen är inte gångbar" end
	local ko, huvud = { { sx, sz } }, 1
	local steg = { [k.idx(sx, sz)] = 0 }
	while huvud <= #ko do
		local c = ko[huvud]; huvud += 1
		if c[1] == tx and c[2] == tz then return steg[k.idx(c[1], c[2])] end
		for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
			local nx, nz = c[1] + d[1], c[2] + d[2]
			local ni = k.idx(nx, nz)
			if VM.gangbar(k, nx, nz) and steg[ni] == nil
				and math.abs(k.golv[ni] - k.golv[k.idx(c[1], c[2])]) <= VM.STEG then
				steg[ni] = steg[k.idx(c[1], c[2])] + 1
				table.insert(ko, { nx, nz })
			end
		end
	end
	return nil, "ingen sammanhängande gångväg"
end


return VM
