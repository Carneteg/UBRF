--!strict
--[[
	Typerna som resten av systemet talar i.

	Poängen med att ha dem här: controllern rör aldrig ett MeshPart, ett
	Bone eller ett AnimationTrack direkt. Den ser bara Rig, Intent och
	State. Det är det som gör att hästmodellen går att byta ut utan att
	ridlogiken skrivs om.
]]

export type GaitName = "halt" | "walk" | "trot" | "canter" | "gallop"

export type State =
	"Idle" | "Walk" | "Trot" | "Canter" | "Gallop"
	| "Jump" | "Landing" | "Stopping" | "BackingUp" | "TurningInPlace"

--[[ Vad ryttaren ber om. Aldrig ett kommando — hästen förhandlar. ]]
export type Intent = {
	forward: number,     -- -1..1, W framåt, S ned i gångart och bakåt
	steer: number,       -- -1..1, vänster..höger
	gaitUp: boolean,     -- begär högre gångart
	gaitDown: boolean,
	jump: boolean,
	--[[ G02-B punkt 1: TYGELN och PARADEN som egna avsikter.

	     `rein` är kontakten ryttaren håller, 0 lös … 1 tagen. Den är
	     analog med flit: på gamepad ligger den på en riktig trigger, så
	     halva utslaget ger halv kontakt. Yttertygelstödet — och därmed
	     hästens balans i svängen — hänger på den.

	     `parad` är halvhalten som EGEN signal, inte tre hjälper som
	     knuffas samtidigt. Kanalen är en impuls: flanken uppåt startar
	     förloppet, och att hålla knappen ger inte en oändlig parad.

	     Båda är valfria i typen så att äldre anropare (specar,
	     autopilot) inte behöver skrivas om för att kompilera; de läses
	     med `or 0`. ]]
	rein: number?,
	parad: number?,
}

--[[ Hästens rörelsetillstånd. Simuleras hos den som äger nätverket. ]]
export type Locomotion = {
	speed: number,       -- m/s framåt, negativ vid backning
	heading: number,     -- radianer, world Y
	turnRate: number,    -- rad/s, filtrerad
	lean: number,        -- radianer roll, positiv = lutar in i högersväng
	gait: GaitName,
	targetGait: GaitName,
	state: State,
	phase: number,       -- 0..1 inom gångartens cykel, driver ljud och damm
	airborne: boolean,
	grounded: boolean,
	slope: Vector3,      -- markens normal, utjämnad
	stamina: number,     -- 0..MaxStamina
	--[[ G02-B punkt 2: hästens svar. Valfria i typen eftersom en rig som
	     stegas av en äldre spec inte fyller dem; Telemetri deklarerar de
	     som saknar källa. ]]
	balans: number?,
	energi: number?,
	svarstid: number?,
	beddGangart: GaitName?,
	paradKvalitet: number?,
}

--[[ Hästmodellen, upplöst till det systemet behöver. Allt utom model,
     root och animator får saknas. ]]
export type Rig = {
	model: Model,
	root: BasePart,
	animator: Animator,
	humanoid: Humanoid?,
	controller: AnimationController?,
	rootJoint: Motor6D?,             -- bär lutningen i svängar
	seat: Seat?,
	attachments: { [string]: Attachment },
	bones: { [string]: Bone },
	stats: Configuration?,
	gaitConfig: Configuration?,
	animConfig: Configuration?,
}

return nil
