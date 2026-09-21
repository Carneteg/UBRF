--!strict
--[[
	Serverns start. Håll den tom på logik — den ska bara starta tjänsterna
	i rätt ordning, så att det syns var något går fel.

	Sedan #264 ligger själva ordningen i `Start.luau` bredvid. Den här
	filen är kvar som serverns ingång och gör exakt en sak: anropar den.

	Varför utbrytningen: Open Clouds Luau Execution kör INTE placens egna
	Scripts — Roblox dokumenterar det rakt ut, och runtime-grinden väntade
	därför 120 sekunder på en start som aldrig kunde ske. ModuleScripts
	får däremot requiras, så grinden kan nu starta EXAKT samma sekvens som
	den här filen kör. En kopia av startordningen i QA hade mätt sig själv.
]]

require(script.Start).kor()
