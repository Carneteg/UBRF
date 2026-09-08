--!strict
-- G02-D: bounded, read-only replay. No physics, scoring, persistence or Instances.
-- Definitions and numeric limits are generated from the web source of truth.
local K = require(script.Parent.RidKanon).RIDANALYS
assert(K and K.schema == 1, "Ridanalys canon missing or incompatible")
local Replay = {}

local function num(v: any): number?
    if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then return nil end
    return v
end
local function copy(v: any): any
    if type(v) ~= "table" then return v end
    local t = {}
    for k, x in v do t[k] = copy(x) end
    return t
end
local function sample(s: any, t: number): { [string]: any }
    s = if type(s) == "table" then s else {}
    local h = if type(s.hjalper) == "table" then s.hjalper else {}
    return {t=t, x=num(s.x), y=num(s.y), kurs=num(s.kurs),
        gangart=if type(s.gangart)=="string" then s.gangart else nil,
        fas=num(s.fas), fart=num(s.fart), kurvatur=num(s.kurvatur), balans=num(s.balans),
        hjalper={skankel=num(h.skankel), tygel=num(h.tygel), sits=num(h.sits), styrning=num(h.styrning)}}
end

function Replay.ny(id: string, meta: { [string]: any }): { [string]: any }?
    local d = K.ovningar[id]
    if not d then return nil end
    meta = meta or {}
    local p = {schema=K.schema, ovning=id, ovningVersion=d.version,
        hast=meta.hast, profil=if type(meta.profil)=="string" then meta.profil else nil,
        start=copy(meta.start), build=meta.build, referens=copy(d.referens),
        klocka="sim", ram=d.ram, hz=K.hz, sampel={}, handelser={}, trunkerad=false, sekunder=0}
    return {post=p, aktiv=true, t=0, nasta=0}
end
function Replay.sampla(r: { [string]: any }, dt: number, state: { [string]: any }): boolean
    if not r or not r.aktiv or not r.post then return false end
    local d = num(dt)
    if not d or d <= 0 or d > 0.5 then return false end
    r.t += d
    if r.t < r.nasta then return false end
    r.nasta += 1 / K.hz
    if r.nasta <= r.t then r.nasta = r.t + 1 / K.hz end
    local p = r.post
    if #p.sampel >= K.maxSampel or r.t > K.maxSek then
        p.trunkerad = true; r.aktiv = false; return false
    end
    local s = sample(state, math.floor(r.t * 1000 + 0.5) / 1000)
    table.insert(p.sampel, s)
    p.sekunder = s.t
    return true
end
function Replay.handelse(r: { [string]: any }, typ: string, data: any): boolean
    if not r or not r.aktiv or not r.post or type(typ) ~= "string" or typ == "" then return false end
    if #r.post.handelser >= K.maxHandelser then return false end
    table.insert(r.post.handelser, {t=math.floor(r.t*1000+0.5)/1000, typ=typ, data=copy(data)})
    return true
end
function Replay.avsluta(r: { [string]: any }): { [string]: any }?
    if not r then return nil end
    local p = r.post
    r.aktiv = false; r.post = nil; r.t = 0; r.nasta = 0
    return p
end

-- Read validation is deliberately stricter than recording: malformed imported
-- data cannot become a plausible route, a score or a new live horse state.
function Replay.lasbar(p: any): (boolean, string)
    if type(p) ~= "table" or p.schema ~= K.schema then return false, "schema" end
    local d = K.ovningar[p.ovning]
    if not d or p.ovningVersion ~= d.version then return false, "ovningsversion" end
    if p.ram ~= d.ram or p.klocka ~= "sim" or p.hz ~= K.hz then return false, "koordinatram" end
    if type(p.sampel) ~= "table" or #p.sampel > K.maxSampel then return false, "sampel" end
    if type(p.handelser) ~= "table" or #p.handelser > K.maxHandelser then return false, "handelser" end
    local last = -1
    for _, s in p.sampel do
        if type(s) ~= "table" or not num(s.t) or s.t <= last or s.t > K.maxSek then return false, "tid" end
        last = s.t
        for _, field in {"x","y","kurs","fas","fart","kurvatur","balans"} do
            if s[field] ~= nil and num(s[field]) == nil then return false, "ogiltigt matvarde" end
        end
        if s.gangart ~= nil and type(s.gangart) ~= "string" then return false, "gangart" end
        if s.hjalper ~= nil then
            if type(s.hjalper) ~= "table" then return false, "hjalper" end
            for _, field in {"skankel","tygel","sits","styrning"} do
                if s.hjalper[field] ~= nil and num(s.hjalper[field]) == nil then return false, "hjalper" end
            end
        end
    end
    if p.sekunder ~= nil and (not num(p.sekunder) or p.sekunder > K.maxSek) then return false, "langd" end
    return true, ""
end
local function lerp(a: number?, b: number?, k: number): number?
    if a == nil or b == nil then return nil end
    return a+(b-a)*k
end
local function angle(a: number?, b: number?, k: number): number?
    if a == nil or b == nil then return nil end
    local d = (b-a+math.pi)%(2*math.pi)-math.pi
    return a+d*k
end
function Replay.vid(p: { [string]: any }, t: number): { [string]: any }?
    local ok = Replay.lasbar(p)
    if not ok or #p.sampel == 0 then return nil end
    local S = p.sampel
    local time = math.clamp(num(t) or 0, 0, S[#S].t)
    local lo, hi = 1, #S
    while lo < hi-1 do
        local m=math.floor((lo+hi)/2)
        if S[m].t <= time then lo=m else hi=m end
    end
    local a,b=S[lo],S[hi]
    local k=if b.t>a.t then math.clamp((time-a.t)/(b.t-a.t),0,1) else 0
    if lo==hi then k=0 end
    local near=if k<0.5 then a else b
    return {t=time, x=lerp(a.x,b.x,k), y=lerp(a.y,b.y,k), kurs=angle(a.kurs,b.kurs,k),
        gangart=near.gangart, fas=near.fas, fart=lerp(a.fart,b.fart,k),
        kurvatur=lerp(a.kurvatur,b.kurvatur,k), balans=lerp(a.balans,b.balans,k)}
end
function Replay.spelare(p: { [string]: any }): { [string]: any }?
    local ok = Replay.lasbar(p)
    if not ok then return nil end
    local up = {post=p, lage=0, spelar=false, fart=1}
    function up:spela() self.spelar=true end
    function up:pausa() self.spelar=false end
    function up:hoppa(t: number)
        self.lage=math.clamp(num(t) or 0,0,self.post.sekunder or 0)
        return self.lage
    end
    function up:sattFart(f: number)
        if num(f) and f>0 and f<=4 then self.fart=f end
    end
    function up:steg(dt: number)
        local d=num(dt)
        if not self.spelar or not d or d<=0 or d>0.5 then return self.lage end
        self.lage=math.min(self.post.sekunder or 0,self.lage+d*self.fart)
        if self.lage >= (self.post.sekunder or 0) then self.spelar=false end
        return self.lage
    end
    function up:vid() return Replay.vid(self.post,self.lage) end
    return up
end

-- Descriptive comparison only. Lesson/Ugneta owns every assessment and score.
function Replay.jamfor(a: any,b: any): (boolean,string)
    local okA=Replay.lasbar(a); local okB=Replay.lasbar(b)
    if not okA or not okB then return false,"ogiltig inspelning" end
    if a.trunkerad or b.trunkerad then return false,"ofullstandig inspelning" end
    if a.ovning~=b.ovning or a.ovningVersion~=b.ovningVersion or a.ram~=b.ram
        or a.hast~=b.hast or a.profil~=b.profil
        or (a.start and a.start.gangart) ~= (b.start and b.start.gangart) then return false,"olika forutsattningar" end
    if #a.sampel<2 or #b.sampel<2 then return false,"otillrackligt underlag" end
    return true,""
end
return Replay
