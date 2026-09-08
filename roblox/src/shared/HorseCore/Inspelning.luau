--!strict
-- G02-D: motoroberoende, read-only inspelning för replay. Ingen bedömning.
local Inspelning = {}
Inspelning.HZ = 20
Inspelning.MAX_SEK = 120
export type Sampel = { t:number, x:number?, z:number?, yaw:number?, gangart:string?, fart:number?, balans:number? }
export type Post = { schema:number, ovning:string, ovningVersion:number, hast:string?, hz:number, sekunder:number, trunkerad:boolean, sampel:{Sampel} }
export type Recorder = { post:Post, aktiv:boolean, t:number, nasta:number }
local function finite(v:any): number?
	if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return nil end
	return v
end
function Inspelning.ny(ovning:string, version:number, hast:string?): Recorder
	return { aktiv=true, t=0, nasta=0, post={schema=1,ovning=ovning,ovningVersion=version,hast=hast,hz=Inspelning.HZ,sekunder=0,trunkerad=false,sampel={}} }
end
function Inspelning.sampla(r:Recorder, dt:number, tm:{[string]:any}, pose:{[string]:any}?): boolean
	if not r.aktiv or type(dt)~="number" or dt<=0 or dt>0.5 then return false end
	r.t += dt
	if r.t < r.nasta then return false end
	r.nasta += 1/Inspelning.HZ
	if r.nasta <= r.t then r.nasta = r.t + 1/Inspelning.HZ end
	if #r.post.sampel >= Inspelning.MAX_SEK*Inspelning.HZ then r.aktiv=false;r.post.trunkerad=true;return false end
	local p = pose or {}
	table.insert(r.post.sampel,{t=math.floor(r.t*1000+0.5)/1000,x=finite(p.x),z=finite(p.z),yaw=finite(p.yaw),gangart=tm.gangart,fart=finite(tm.fart),balans=finite(tm.balans)})
	r.post.sekunder = r.t
	return true
end
function Inspelning.avsluta(r:Recorder?): Post?
	if not r then return nil end
	r.aktiv=false
	return r.post
end
function Inspelning.vid(post:Post, tid:number): Sampel?
	local s=post.sampel;if #s==0 then return nil end
	local t=math.max(0,math.min(tid,post.sekunder));local lo=1;local hi=#s
	while lo < hi-1 do local m=math.floor((lo+hi)/2); if s[m].t<=t then lo=m else hi=m end end
	local a=s[lo];local b=s[hi]; if a==b or b.t<=a.t then return a end
	local k=math.max(0,math.min(1,(t-a.t)/(b.t-a.t)))
	local function lerp(x:number?,y:number?):number? if x==nil or y==nil then return nil end return x+(y-x)*k end
	return {t=t,x=lerp(a.x,b.x),z=lerp(a.z,b.z),yaw=lerp(a.yaw,b.yaw),gangart=if k<0.5 then a.gangart else b.gangart,fart=lerp(a.fart,b.fart),balans=lerp(a.balans,b.balans)}
end
return Inspelning
