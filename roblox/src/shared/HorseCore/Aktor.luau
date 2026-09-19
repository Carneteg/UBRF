--!strict
--[[
	AKTÖREN — vem servern arbetar för, och om det finns en klient att
	skicka presentationen till.

	══ VARFÖR MODULEN FINNS (#252 DEL C) ═══════════════════════════════

	Runtime-grinden kör spelet i RIKTIG Roblox-motor genom Open Cloud
	Luau Execution. Den sessionen är en server UTAN klienter, och en
	`Player` går inte att skapa. Mätt i motorn, tre trådtyper:

	    Instance.new("Player")        -> "The current thread cannot create
	                                      'Player' (lacking capability
	                                      WritePlayer)"   [plugin + server]
	    Players:CreateLocalPlayer(1)  -> samma capability-avslag

	Serverlogiken behöver ingen `Player`. Den läser `Name`, `UserId`,
	`Character` och de två karaktärssignalerna, och använder aktören som
	nyckel i sina egna register. Det enda som är omöjligt utan en riktig
	spelare är UTSKICKET:

	    RemoteEvent:FireClient(<tabell>)  -> "Unable to cast value to Object"
	    RemoteEvent:FireClient(nil)       -> "player argument must be a
	    RemoteEvent:FireClient(workspace)     Player object"

	══ REGELN ═════════════════════════════════════════════════════════

	    Aktor.klient(a)  ->  mottagaren, eller nil när aktören säger att
	                         hon inte har någon klient.

	DEN ÄR AVSIKTLIGT EN OPT-OUT, inte ett typtest. En sträng vakt —
	«bara `typeof(a) == "Instance" and a:IsA("Player")`» — skrevs först,
	och den gjorde precis det som inte får hända: bänkens spelare är rena
	tabeller, så varje `FireClient` i bänken försvann tyst och
	`integration.spec`:s mätning «och servern skickade en ny passvy trots
	nejet» gick från 1 → 0 utskick utan att något sa ifrån. En ändring som
	SLÄCKER assertions i tysthet är samma klass av fel som #252 finns för
	att stänga.

	Därför: allt som inte uttryckligen säger ifrån behandlas som en
	mottagare, precis som före den här modulen. Bara den som deklarerar
	`harKlient = false` hoppas över — och det gör exakt en sak i hela
	projektet, `qa/runtime/smoke.luau`:s testsäte.

	`nil` betyder INTE «hoppa över kontrollen». All sanning, alla nej och
	all fysik är oförändrade; det är bara presentationen som saknar
	mottagare, precis som för en spelare som just kopplat ned.

	══ VAD DEN INTE ÄR ════════════════════════════════════════════════

	Det här är inte en av de fem bänk-toleranta vakterna i
	`audits/BANK-AUDIT-2026-09-19.md` § 4.1. De släpper igenom en tabell
	DÄR EN INSTANS KRÄVS, och skrevs så för att passera bänken. Den här
	ändrar ingenting för en `Player` och ingenting för bänken; den öppnar
	en namngiven dörr för en aktör som själv säger att hon är klientlös.

	[DEL D-kandidat] Den strikta formen är den rätta på sikt, men den
	kräver att bänkens 42 spelartabeller i 20 specfiler blir stubb-
	instanser med `ClassName = "Player"` först. Det ligger utanför DEL C.
]]

local Aktor = {}

export type Aktor = {
	Name: string,
	UserId: number,
	Character: Model?,
	--[[ Sätts till `false` av ett testsäte som kör serverhandlingarna
		utan någon klient i andra änden. Utelämnad = vanlig spelare. ]]
	harKlient: boolean?,
}

--[[ Mottagaren för ett fjärranrop, eller `nil` när aktören saknar klient. ]]
function Aktor.klient(a: any): any
	if a == nil then return nil end
	if type(a) == "table" and rawget(a :: any, "harKlient") == false then
		return nil
	end
	return a
end

--[[ Namnet i loggen. En aktör utan namn ska synas som saknad, inte som
	`nil` mitt i en mening. ]]
function Aktor.namn(a: any): string
	if a ~= nil then
		local ok, n = pcall(function() return (a :: any).Name end)
		if ok and type(n) == "string" and n ~= "" then return n end
	end
	return "okänd aktör"
end

return Aktor
