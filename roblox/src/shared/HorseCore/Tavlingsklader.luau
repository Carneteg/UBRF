--!strict
--[[ TÄVLINGSKLÄDER — KATALOGEN OCH VALIDERINGSGRÄNSEN (#248 Fas A).

	Tre valbara ryttarset för Roblox-tävlingar. Den här modulen är
	**enda stället** de finns, och den gör exakt två saker: bär katalogen,
	och svarar på om ett id är ett av de tre.

	══ VAD DEN INTE GÖR, OCH VARFÖR ══════════════════════════════════

	Roblox-ytan har ännu inget tävlingsläge. Ordern är uttrycklig om att
	Fas A inte får bygga ett låtsat sådant, inte visa klädval under
	vanliga lektioner och inte lägga oanvänd UI. Modulen skriver därför
	ingenting på en avatar, äger ingen RemoteEvent och känner inte till
	någon spelare.

	Den är gränssnittet som den framtida, SERVERÄGDA tävlingskontexten
	kopplar in sig på — inte kontexten. Områdena 2–4 i #248:s acceptance
	contract (serverauktoritet, avatarbevarande, UX) hör dit, och enligt
	orderns egen leveransordning kräver de ett eget accepterat kontrakt
	först.

	══ EXTERNA KATALOGBEROENDEN ══════════════════════════════════════

	De sex talen nedan är Roblox-katalogposter, skapade av **Ambient Rose
	Equestrian**. De ägs inte av det här projektet, och de kan försvinna
	utan förvarning: en post kan modereras bort, göras privat eller tas
	ur försäljning. Ett id är därför en UPPGIFT, inte en garanti.

	[antagande] Att varje id existerar och har rätt `AssetType` — 11 för
	Shirt, 12 för Pants — är verifierat av produktägaren via Robloxs
	katalog-/economy-API och står i #248. Det är INTE mätt härifrån; en
	Luau-bänk kan inte fråga Roblox. Modulen bär talen som de uppgavs och
	märker dem som vad de är.

	KONSEKVENSEN AV DET: den som laddar ett set måste tåla att det inte
	går. `Tavlingsklader.set` svarar `nil` på ett okänt id i stället för
	att kasta, och kontraktets krav på att en misslyckad laddning lämnar
	avataren intakt hör till den kontext som gör laddningen — inte hit.

	══ EN KATALOG, INTE FLERA ════════════════════════════════════════

	"Inga kopierade ID-tabeller i UI och server." Den regeln går inte att
	mäta i en Luau-bänk — ett andra id någon annanstans kompilerar lika
	fint som inget. `tools/kolla-tavlingsklader.py` läser därför källan
	och faller om något av talen dyker upp utanför den här filen.
]]

local Tavlingsklader = {}

--[[ Ett set. `id` är det STABILA INTERNA namnet — det enda klienten
	någonsin skickar. Asset-id:na lämnar aldrig servern som något en
	klient får välja fritt; se `giltig` nedan. ]]
export type Set = {
	id: string,
	namn: string,
	shirtAssetId: number,
	pantsAssetId: number,
}

--[[ Skaparen bakom samtliga sex poster. Står som data och inte bara i
	kommentaren, så att en framtida attribution kan läsa den i stället för
	att skriva av den. ]]
Tavlingsklader.SKAPARE = "Ambient Rose Equestrian"

--[[ Robloxs egna AssetType-nummer för de två lagren kontraktet äger.
	De står här för att provet ska kunna mäta att rätt tal hamnat i rätt
	FÄLT — inte för att modulen själv slår upp något. ]]
Tavlingsklader.ASSETTYPE_SHIRT = 11
Tavlingsklader.ASSETTYPE_PANTS = 12

--[[ KATALOGEN. Ordningen är den ordern räknar upp dem i, och den är
	också den ordning ett framtida val bör visa dem i — men det är den
	kontextens beslut, inte det här modulens. ]]
local KATALOG: { Set } = {
	{
		id = "white",
		namn = "White Equestrian Set",
		shirtAssetId = 11268412339,
		pantsAssetId = 11268415210,
	},
	{
		id = "pink",
		namn = "Pink Equestrian Set",
		shirtAssetId = 11268345931,
		pantsAssetId = 11268349501,
	},
	{
		id = "oak",
		namn = "Oak Equestrian Set",
		shirtAssetId = 11268265001,
		pantsAssetId = 11268267939,
	},
}

--[[ Uppslaget byggs EN gång ur listan. Att skriva en andra tabell med
	samma id:n vore precis den dubblering kontraktet förbjuder — även när
	den bara är ett index. ]]
local EFTER_ID: { [string]: Set } = {}
for _, s in ipairs(KATALOG) do
	EFTER_ID[s.id] = s
end

--[[ Alla set, i kanonens ordning. Kopia: den som läser listan ska inte
	kunna skriva i katalogen genom att råka mutera svaret. ]]
function Tavlingsklader.alla(): { Set }
	local ut: { Set } = {}
	for _, s in ipairs(KATALOG) do
		table.insert(ut, {
			id = s.id, namn = s.namn,
			shirtAssetId = s.shirtAssetId, pantsAssetId = s.pantsAssetId,
		})
	end
	return ut
end

--[[ ── VALIDERINGSGRÄNSEN ──────────────────────────────────────────

	DET HÄR ÄR MODULENS VIKTIGASTE RAD. Klienten får skicka ett av tre
	ord. Den får aldrig skicka ett asset-id, och därför finns ingen väg
	in som tar ett tal.

	`giltig` svarar bara ja eller nej och är avsiktligt snål: den tar
	emot `any`, för det klienten skickar ÄR `any` tills någon prövat det.
	Ett tal, en tabell, `nil`, ett id med annan skiftläge — allt faller.

	SKIFTLÄGET ÄR INTE TOLERANT MED FLIT. "White" är inte "white". Ett
	id som matchas luddigt är ett id som kan matchas på ett sätt ingen
	räknade med, och de tre orden skrivs av maskiner, inte av människor. ]]
function Tavlingsklader.giltig(id: any): boolean
	return type(id) == "string" and EFTER_ID[id] ~= nil
end

--[[ Setet för ett id, eller `nil`. Svarar nil i stället för att kasta:
	ett id kan komma från en sparad preferens som blivit inaktuell, och
	den som frågar ska kunna behandla det som "inget val" utan att
	bygga en felhanterare runt ett anrop. ]]
function Tavlingsklader.set(id: any): Set?
	if not Tavlingsklader.giltig(id) then return nil end
	local s = EFTER_ID[id]
	return { id = s.id, namn = s.namn,
		shirtAssetId = s.shirtAssetId, pantsAssetId = s.pantsAssetId }
end

--[[ De stabila id:na, i kanonens ordning. För den som vill räkna upp
	dem utan att bära hela posterna. ]]
function Tavlingsklader.idn(): { string }
	local ut: { string } = {}
	for _, s in ipairs(KATALOG) do table.insert(ut, s.id) end
	return ut
end

return Tavlingsklader
