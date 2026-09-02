--!strict
--[[ FÖRBEREDELSEN — reglerna för att göra i ordning en häst, som ren logik.

	Ingen Roblox-anrop här inne. Det är samma val som `Stallet.luau` gör och
	av samma skäl: det här ÄR reglerna, och regler ska gå att falsifiera utan
	Studio. `GameplayService` äger instanserna, nätverket och avstånden.

	Faserna hittas inte på här. De kommer ur `UBRFSkotsel.faser`, som
	genereras ur `src/spel/skotsel.js` — samma källa som webben lär ut. Den
	gamla Roblox-sidan hade en egen lista med fyra etiketter utan innehåll,
	och det var precis den dubbla sanningen som S2a fanns till för att ta
	bort. Läs aldrig fasordningen från något annat än den här modulen.

	Tillståndet är ett rent värde: `GameplayService` håller ett per spelare,
	provet håller sina egna. Modulen har medvetet inget eget minne — hade den
	haft det gick den inte att prova två spelare samtidigt i samma process.
]]

local RS = game:GetService("ReplicatedStorage")
local Skotsel = require(RS.UBRFSkotsel)

local Preparation = {}

Preparation.FASER = Skotsel.faser

--[[ Statusorden går ut till klienten och in i provet. De är engelska för att
	arbetsordern (issue #58) namnger dem så; texten spelaren ser är svensk
	och kommer ur fasernas `namn`/`text`. ]]
Preparation.STATUS = {
	VANTAR_MODELL = "waiting_model",   -- identiteten är tilldelad, riggen saknas
	FORBEREDER = "preparing",
	REDO = "ready_to_mount",
	RIDER = "riding",
}

export type State = {
	hastId: string,
	klara: { [string]: boolean },
}

--[[ Index i fasordningen, eller nil för ett okänt id. Slås upp linjärt över
	fem element; en tabell hade varit snabbare och svårare att läsa. ]]
function Preparation.fasIndex(fasId: string): number?
	for i, f in ipairs(Preparation.FASER) do
		if f.id == fasId then return i end
	end
	return nil
end

function Preparation.fas(fasId: string)
	local i = Preparation.fasIndex(fasId)
	return i and Preparation.FASER[i] or nil
end

--[[ Faserna som faktiskt utförs — alla utom den avslutande uppsittningen.
	Uppsittningen är inte ett moment i förberedelsen, den är det man får göra
	NÄR förberedelsen är klar. Räknas den som ett steg blir hästen redo att
	sitta upp på först efter att man redan suttit upp. ]]
function Preparation.stegFaser()
	local ut = {}
	for _, f in ipairs(Preparation.FASER) do
		if not f.sitt then table.insert(ut, f) end
	end
	return ut
end

function Preparation.nyState(hastId: string): State
	return { hastId = hastId, klara = {} }
end

--[[ Nästa fas som ska göras, eller nil när alla steg är klara. Ordningen är
	fasernas ordning — det finns ingen valfrihet och ska inte finnas. ]]
function Preparation.nasta(state: State)
	for _, f in ipairs(Preparation.stegFaser()) do
		if not state.klara[f.id] then return f end
	end
	return nil
end

function Preparation.redo(state: State): boolean
	return Preparation.nasta(state) == nil
end

--[[ Får spelaren utföra `fasId` på hästen `hastId` just nu?

	Tre nej, i den ordning de ska prövas:
	  1. fel häst — förberedelsen gäller EN tilldelad identitet,
	  2. okänd eller redan gjord fas,
	  3. fel tur.

	Ordningen spelar roll för meddelandet: står man vid fel häst ska man få
	veta det, inte att "det är inte din tur att rykta". ]]
function Preparation.provaSteg(state: State, fasId: string, hastId: string): (boolean, string?)
	if hastId ~= state.hastId then
		return false, "fel häst"
	end
	local fas = Preparation.fas(fasId)
	if not fas then
		return false, "okänd fas"
	end
	if fas.sitt then
		return false, "uppsittningen är inget förberedelsesteg"
	end
	if state.klara[fasId] then
		return false, "redan gjort"
	end
	local nasta = Preparation.nasta(state)
	if not nasta or nasta.id ~= fasId then
		return false, "fel tur — " .. (nasta and nasta.namn or "inget kvar") .. " står på tur"
	end
	return true, nil
end

--[[ Utför steget. Muterar `state` bara när provningen gick igenom, så ett
	avvisat försök aldrig kan flytta fram förberedelsen halvvägs. ]]
function Preparation.utfor(state: State, fasId: string, hastId: string): (boolean, string?)
	local ok, skal = Preparation.provaSteg(state, fasId, hastId)
	if not ok then return false, skal end
	state.klara[fasId] = true
	return true, nil
end

--[[ Får spelaren sitta upp? Egen fråga, inte `redo` — uppsittningen prövas
	mot BÅDE förberedelsen och hästens identitet, och den som frågar sitter i
	`GameplayService` med en modell i handen. ]]
function Preparation.provaUppsittning(state: State, hastId: string): (boolean, string?)
	if hastId ~= state.hastId then
		return false, "det är inte din häst"
	end
	local nasta = Preparation.nasta(state)
	if nasta then
		return false, nasta.namn .. " återstår"
	end
	return true, nil
end

--[[ ── Bindningen ──────────────────────────────────────────────────

	Valet av modell är också en REGEL, inte instanshantering, så den bor
	här och inte i `GameplayService`. Tjänsten samlar ihop kandidaterna ur
	`CollectionService` och frågar; den letar aldrig själv.

	Uppdelningen finns av samma skäl som i riggkontraktet: hade tjänsten
	haft en egen kopia av villkoret gick regeln bara att prova genom att
	starta en server, och då provas den aldrig. ]]

--[[ Väljer den modell vars id är EXAKT det tilldelade och som ingen annan
	spelare håller.

	`kandidater` är { { id = <HorseId>, modell = <valfritt> } }.
	`upptagna` är { [modell] = true } för modeller andra redan bundit.

	Ingen närmast-häst-fallback, med flit. Att binda närmaste Horse-taggade
	modell gör att något alltid händer — och att spelaren gör i ordning fel
	individ utan att få veta det. Hellre nil, som blir `waiting_model`. ]]
function Preparation.valjModell(kandidater, hastId: string, upptagna)
	local taget = upptagna or {}
	for _, kandidat in ipairs(kandidater or {}) do
		if kandidat.id == hastId and not taget[kandidat.modell] then
			return kandidat.modell
		end
	end
	return nil
end

--[[ Får spelaren sitta upp på en modell vars HorseId är `modellHastId`?

	Krav 6 och 7 i ett: rätt identitet OCH färdig förberedelse. Identiteten
	prövas först — en fullt förberedd spelare som står vid någon annans häst
	ska få veta att det är fel häst, inte att något återstår. ]]
function Preparation.provaModell(state: State?, modellHastId): (boolean, string?)
	if not state then
		return false, "Du har ingen tilldelad häst"
	end
	if modellHastId ~= state.hastId then
		return false, "Det är inte din häst"
	end
	return Preparation.provaUppsittning(state, state.hastId)
end

--[[ Det klienten ska visa. Servern skickar hela den här tabellen; klienten
	räknar inte ut någon del av den själv. ]]
function Preparation.vy(state: State?, status: string)
	if not state then
		return { status = status, hastId = nil, steg = {}, nasta = nil, redo = false }
	end
	local steg = {}
	for _, f in ipairs(Preparation.stegFaser()) do
		table.insert(steg, {
			id = f.id,
			namn = f.namn,
			text = f.text,
			klar = state.klara[f.id] == true,
		})
	end
	local nasta = Preparation.nasta(state)
	return {
		status = status,
		hastId = state.hastId,
		steg = steg,
		nasta = nasta and nasta.id or nil,
		redo = nasta == nil,
	}
end

return Preparation
