--!strict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Inspelning=require(game:GetService("ReplicatedStorage").HorseCore.Inspelning)
local Replay={}
local player=Players.LocalPlayer
local gui:ScreenGui?=nil
local aktiv=false
local post:any=nil
local ghost:any=nil
local tid=0
local fart=1
local spelar=false
local marker:Frame?=nil
local bana:Frame?=nil
local tidLabel:TextLabel?=nil
local conn:RBXScriptConnection?=nil
local onClose:(()->())?=nil
local minx,maxx,minz,maxz=0,1,0,1
local function clearRoute()
	if not bana then return end
	for _,c in bana:GetChildren() do if c.Name=="P" or c.Name=="G" then c:Destroy() end end
end
local function bounds()
	minx,maxx,minz,maxz=math.huge,-math.huge,math.huge,-math.huge
	local function take(p:any) if p.x and p.z then minx=math.min(minx,p.x);maxx=math.max(maxx,p.x);minz=math.min(minz,p.z);maxz=math.max(maxz,p.z) end end
	for _,p in post.sampel do take(p) end; if ghost then for _,p in ghost.sampel do take(p) end end
	if minx==math.huge then minx,maxx,minz,maxz=0,1,0,1 end
	if maxx-minx<1 then maxx=minx+1 end;if maxz-minz<1 then maxz=minz+1 end
end
local function xy(p:any):(number,number) return (p.x-minx)/(maxx-minx),(p.z-minz)/(maxz-minz) end
local function dot(p:any,name:string,color:Color3,alpha:number)
	if not bana or p.x==nil or p.z==nil then return end
	local x,y=xy(p);local d=Instance.new("Frame");d.Name=name;d.Size=UDim2.fromOffset(4,4);d.AnchorPoint=Vector2.new(.5,.5);d.Position=UDim2.fromScale(x,1-y);d.BackgroundColor3=color;d.BackgroundTransparency=alpha;d.BorderSizePixel=0;d.Parent=bana
end
local function build()
	if gui then return end
	local g=Instance.new("ScreenGui");g.Name="UBRFReplay";g.ResetOnSpawn=false;g.IgnoreGuiInset=true;g.DisplayOrder=20;g.Enabled=false;g.Parent=player:WaitForChild("PlayerGui");gui=g
	local panel=Instance.new("Frame");panel.Size=UDim2.new(.9,0,.78,0);panel.Position=UDim2.new(.05,0,.11,0);panel.BackgroundColor3=Color3.fromRGB(12,14,18);panel.BackgroundTransparency=.04;panel.Parent=g
	local title=Instance.new("TextLabel");title.Size=UDim2.new(1,-24,0,34);title.Position=UDim2.fromOffset(12,8);title.BackgroundTransparency=1;title.Text="RIDANALYS · DIN RITT";title.TextColor3=Color3.fromRGB(246,242,232);title.Font=Enum.Font.GothamBold;title.TextSize=18;title.Parent=panel
	local b=Instance.new("Frame");b.Name="Bana";b.Size=UDim2.new(1,-24,1,-116);b.Position=UDim2.fromOffset(12,48);b.BackgroundColor3=Color3.fromRGB(24,27,33);b.ClipsDescendants=true;b.Parent=panel;bana=b
	local m=Instance.new("Frame");m.Name="Marker";m.Size=UDim2.fromOffset(10,10);m.AnchorPoint=Vector2.new(.5,.5);m.BackgroundColor3=Color3.fromRGB(255,249,236);m.BorderSizePixel=0;m.ZIndex=4;m.Parent=b;marker=m
	local controls=Instance.new("Frame");controls.Size=UDim2.new(1,-24,0,46);controls.Position=UDim2.new(0,12,1,-58);controls.BackgroundTransparency=1;controls.Parent=panel
	local layout=Instance.new("UIListLayout");layout.FillDirection=Enum.FillDirection.Horizontal;layout.Padding=UDim.new(0,6);layout.Parent=controls
	local function btn(txt:string,fn:()->()) local x=Instance.new("TextButton");x.Size=UDim2.fromOffset(104,36);x.Text=txt;x.Font=Enum.Font.GothamBold;x.TextSize=12;x.BackgroundColor3=Color3.fromRGB(232,181,74);x.Parent=controls;x.Activated:Connect(fn);return x end
	btn("Spela/Pausa",function() spelar=not spelar end)
	btn("0,5× / 1×",function() fart=if fart==1 then .5 else 1 end)
	btn("−5 s",function() tid=math.max(0,tid-5) end)
	btn("+5 s",function() if post then tid=math.min(post.sekunder,tid+5) end end)
	btn("Tillbaka",function() Replay.stang() end)
	local tl=Instance.new("TextLabel");tl.Name="Tid";tl.Size=UDim2.fromOffset(120,36);tl.BackgroundTransparency=1;tl.TextColor3=Color3.fromRGB(246,242,232);tl.Font=Enum.Font.RobotoMono;tl.TextSize=12;tl.Parent=controls;tidLabel=tl
end
local function render()
	if not post or not marker or not bana then return end
	local p=Inspelning.vid(post,tid);if p and p.x and p.z then local x,y=xy(p);marker.Position=UDim2.fromScale(x,1-y);marker.Visible=true else marker.Visible=false end
	if tidLabel then tidLabel.Text=string.format("%.1f / %.1f s",tid,post.sekunder) end
end
function Replay.oppna(nyPost:any,nyGhost:any,stangFn:(()->())?)
	build();post=nyPost;ghost=nyGhost;onClose=stangFn;tid=0;fart=1;spelar=true;aktiv=true;if gui then gui.Enabled=true end;clearRoute();bounds()
	if ghost then local step=math.max(1,math.floor(#ghost.sampel/100));for i=1,#ghost.sampel,step do dot(ghost.sampel[i],"G",Color3.fromRGB(214,174,60),.45) end end
	local step=math.max(1,math.floor(#post.sampel/120));for i=1,#post.sampel,step do dot(post.sampel[i],"P",Color3.fromRGB(127,180,137),.15) end
	if conn then conn:Disconnect() end;conn=RunService.RenderStepped:Connect(function(dt) if not aktiv then return end;if spelar then tid=math.min(post.sekunder,tid+dt*fart);if tid>=post.sekunder then spelar=false end end;render() end);render()
end
function Replay.stang() aktiv=false;if gui then gui.Enabled=false end;if conn then conn:Disconnect();conn=nil end;local fn=onClose;onClose=nil;if fn then fn() end end
function Replay.aktiv():boolean return aktiv end
return Replay
