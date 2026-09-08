from pathlib import Path

def patch(path, replacements):
    p=Path(path); s=p.read_text()
    for old,new in replacements:
        if old not in s:
            raise SystemExit(f'MISSING PATCH in {path}: {old[:70]!r}')
        s=s.replace(old,new,1)
    p.write_text(s)

# P0 steering retained on top of PR138 replay lifecycle.
patch('src/game.js', [
('  latt:true,diagonal:1,spo:false,hh:-1,paradFore:0,ned:{},\n  joy:null,', '  latt:true,diagonal:1,spo:false,hh:-1,paradFore:0,ned:{},\n  styrDigital:null,styrKansla:{v:0},\n  joy:null,'),
('  RIDIN.skankel=0; RIDIN.tygel=0; RIDIN.sits=0; RIDIN.styr=0; RIDIN.parad=0; RIDIN.pek=false;\n  ridAvsiktTillHjalp();', '  RIDIN.skankel=0; RIDIN.tygel=0; RIDIN.sits=0; RIDIN.styr=0; RIDIN.parad=0; RIDIN.pek=false;\n  IN.styrDigital=null; IN.styrKansla.v=0;\n  ridAvsiktTillHjalp();'),
('    case"KeyA":RIDIN.styr=-1;RIDIN.pek=false;break;\n    case"KeyD":RIDIN.styr=1;RIDIN.pek=false;break;', '    case"KeyA":IN.styrDigital=-1;RIDIN.pek=false;break;\n    case"KeyD":IN.styrDigital=1;RIDIN.pek=false;break;'),
('    case"KeyA":RIDIN.styr=IN.ned.KeyD?1:0;break;\n    case"KeyD":RIDIN.styr=IN.ned.KeyA?-1:0;break;', '    case"KeyA":if(!RIDIN.pek)IN.styrDigital=IN.ned.KeyD?1:0;break;\n    case"KeyD":if(!RIDIN.pek)IN.styrDigital=IN.ned.KeyA?-1:0;break;'),
('function stegaInput(dt){\n  ridAvsiktTillHjalp();', 'function stegaInput(dt){\n  // Forma digital A/D före det befintliga hjälp- och kurvaturfiltret.\n  if(RIDIN.pek){IN.styrDigital=null;IN.styrKansla.v=RIDIN.styr;}\n  else if(IN.styrDigital!==null){RIDIN.styr=InputFeel.ride(IN.styrDigital,dt,IN.styrKansla);}\n  ridAvsiktTillHjalp();')])
patch('index.html', [('<script src="src/uppdrag.js"></script>\n<script src="world.js"></script>', '<script src="src/uppdrag.js"></script>\n<script src="src/input-feel.js"></script>\n<script src="world.js"></script>') if Path('index.html').read_text().find('<script src="world.js"></script>')>=0 else ('<script src="src/uppdrag.js"></script>\n<script src="src/world.js"></script>', '<script src="src/uppdrag.js"></script>\n<script src="src/input-feel.js"></script>\n<script src="src/world.js"></script>')])

# Actionable, evidence-grounded coaching instead of generic criticism.
p=Path('src/larare.js'); s=p.read_text()
anchor='function ugnetaJamfor(id,fore,nu,nr){'
if 'const UGNETA_DIM_TIPS=' not in s:
    s=s.replace(anchor,'''const UGNETA_DIM_TIPS={\n  linje:"förbered svängen tidigare och håll yttertygeln stadig",\n  rytm:"håll samma takt genom hela vägen",\n  balans:"sitt mitt över hästen och gör hjälpen mindre",\n  timing:"förbered hjälpen innan du vill ha svaret",\n  mjukhet:"mjukna i handen när hästen svarar",\n  respons:"ge en tydlig hjälp och vänta på hästens svar",\n  tempo:"håll tempot jämnt i stället för att jaga fart"\n};\nfunction ugnetaTips(k){return UGNETA_DIM_TIPS[k]||`fortsätt med ${UGNETA_DIM_LABEL[k]||k}`;}\n'''+anchor)
s=s.replace('if(kvar&&kvar.v<UGNETA_KVALITET.SVAG)punkter.push(`Fortsätt med ${UGNETA_DIM_LABEL[kvar.k]}.`);','if(kvar&&kvar.v<UGNETA_KVALITET.SVAG)punkter.push(`Nästa gång: ${ugnetaTips(kvar.k)}.`);')
s=s.replace('if(samst&&(!bast||samst.k!==bast.k))punkter.push(`Jobba på ${UGNETA_DIM_LABEL[samst.k]}.`);','if(samst&&(!bast||samst.k!==bast.k))punkter.push(`Nästa gång: ${ugnetaTips(samst.k)}.`);')
s=s.replace('if(!punkter.length)punkter.push(`Jobba på ${UGNETA_DIM_LABEL[rank[0].k]}.`);','if(!punkter.length)punkter.push(`Nästa gång: ${ugnetaTips(rank[0].k)}.`);')
p.write_text(s)

# Roblox Ugneta: replay and skip are explicit touch-friendly choices.
p=Path('roblox/src/client/UgnetaController.luau'); s=p.read_text()
s=s.replace('local kortKnapp: TextButton? = nil\n', 'local kortKnapp: TextButton? = nil\nlocal replayKnapp: TextButton? = nil\nlocal vidareKnapp: TextButton? = nil\nlocal replayFn: (() -> ())? = nil\nlocal vidareFn: (() -> ())? = nil\n')
s=s.replace('local DIM_ORD = {\n', '''local DIM_TIPS = {\n\tlinje = "Förbered svängen tidigare och håll yttertygeln stadig.",\n\trytm = "Håll samma takt genom hela vägen.",\n\tbalans = "Sitt mitt över hästen och gör hjälpen mindre.",\n\ttiming = "Förbered hjälpen innan du vill ha svaret.",\n\tmjukhet = "Mjukna i handen när hästen svarar.",\n\trespons = "Ge en tydlig hjälp och vänta på hästens svar.",\n\ttempo = "Håll tempot jämnt i stället för att jaga fart.",\n}\n\nlocal DIM_ORD = {\n''')
s=s.replace('k.Size = UDim2.new(0.92, 0, 0, 108)', 'k.Size = UDim2.new(0.92, 0, 0, 170)')
s=s.replace('kmax.MaxSize = Vector2.new(640, 200)', 'kmax.MaxSize = Vector2.new(640, 260)')
needle='\tkortKnapp = kn\n\t--[[ Mus och finger går in här.'
insert='''\tkortKnapp = kn\n\n\tlocal rk = Instance.new("TextButton")\n\trk.Name = "ReplayKnapp"; rk.AutoButtonColor = true; rk.LayoutOrder = 10\n\trk.Size = UDim2.new(0,108,0,22); rk.BackgroundColor3 = Color3.fromRGB(60,72,68)\n\trk.TextColor3 = FARG_TEXT; rk.Font = Enum.Font.GothamBold; rk.TextSize = 12\n\trk.Text = "Se ritten"; rk.Visible = false; rk.ZIndex = 6; rk.Parent = k; replayKnapp = rk\n\tlocal rkc = Instance.new("UICorner"); rkc.CornerRadius=UDim.new(1,0); rkc.Parent=rk\n\trk.Activated:Connect(function() if replayFn then replayFn() end end)\n\n\tlocal vk = Instance.new("TextButton")\n\tvk.Name = "VidareKnapp"; vk.AutoButtonColor = true; vk.LayoutOrder = 11\n\tvk.Size = UDim2.new(0,108,0,22); vk.BackgroundColor3 = Color3.fromRGB(60,72,68)\n\tvk.TextColor3 = FARG_TEXT; vk.Font = Enum.Font.GothamBold; vk.TextSize = 12\n\tvk.Text = "Gå vidare"; vk.Visible = false; vk.ZIndex = 6; vk.Parent = k; vidareKnapp = vk\n\tlocal vkc = Instance.new("UICorner"); vkc.CornerRadius=UDim.new(1,0); vkc.Parent=vk\n\tvk.Activated:Connect(function() if vidareFn then vidareFn() end end)\n\t--[[ Mus och finger går in här.'''
if needle not in s: raise SystemExit('Ugneta button anchor missing')
s=s.replace(needle,insert)
s=s.replace('local function visaKort(rubrik: string, punkter: { string }, knapp: boolean,\n\tknappText: string?)', 'local function visaKort(rubrik: string, punkter: { string }, knapp: boolean,\n\tknappText: string?, replay: boolean?, vidare: boolean?)')
s=s.replace('\tif kn then\n\t\tkn.Visible = knapp\n\t\tif knapp and knappText then kn.Text = medLedtext(knappText) end\n\tend\n', '\tif kn then\n\t\tkn.Visible = knapp\n\t\tif knapp and knappText then kn.Text = medLedtext(knappText) end\n\tend\n\tif replayKnapp then replayKnapp.Visible = replay == true end\n\tif vidareKnapp then vidareKnapp.Visible = vidare == true end\n')
s=s.replace('\t\telseif o.sort == "kvar" then\n\t\t\ttable.insert(punkter, `Fortsätt med {ord}.`)', '\t\telseif o.sort == "kvar" then\n\t\t\ttable.insert(punkter, DIM_TIPS[o.dim] or `Fortsätt med {ord}.`)')
s=s.replace('\t\telse\n\t\t\ttable.insert(punkter, `Jobba på {ord}.`)\n', '\t\telse\n\t\t\ttable.insert(punkter, DIM_TIPS[o.dim] or `Jobba på {ord}.`)\n')
s=s.replace('''\tvisaKort(if forsta then "Prova igen" else `Försök {forsokNr}`, punkter, true,\n\t\tif forsta then "Prova igen" else "Nästa övning")''','''\tvisaKort(if forsta then "Prova igen" else `Försök {forsokNr}`, punkter, true,\n\t\tif forsta then "Prova igen" else "Nästa övning", true, forsta)''')
s=s.replace('function UgnetaController.start()\n','''function UgnetaController.vidReplay(fn: (() -> ())?) replayFn = fn end\nfunction UgnetaController.vidVidare(fn: (() -> ())?) vidareFn = fn end\nfunction UgnetaController.replay(): boolean\n\tif not vantarPa or not replayFn then return false end; replayFn(); return true\nend\nfunction UgnetaController.gaVidare(): boolean\n\tif not vantarPa or not vidareFn then return false end; vantarPa=false\n\tlocal k=kort; if k then k.Visible=false end; vidareFn(); return true\nend\n\nfunction UgnetaController.start()\n''')
p.write_text(s)

# Roblox lesson: one recorder per attempt, previous attempt ghost, never a second scoring path.
p=Path('roblox/src/client/LektionController.luau'); s=p.read_text()
s=s.replace('local UgnetaGestalt = require(script.Parent.UgnetaGestalt)\n', 'local UgnetaGestalt = require(script.Parent.UgnetaGestalt)\nlocal ReplayController = require(script.Parent.ReplayController)\nlocal Inspelning = require(game:GetService("ReplicatedStorage").HorseCore.Inspelning)\n')
s=s.replace('local lage = "ingen"\n', 'local lage = "ingen"\nlocal inspelare: any = nil\nlocal inspelningar: {[string]: {any}} = {}\nlocal senasteOvning: string? = nil\n')
anchor='local function fortsattning()\n'
helpers='''local function ovningSpelasIn(id: string?): boolean return id == "storvolt" or id == "trav_skritt" end\nlocal function startaInspelning(p: Lektion.Pass, tm: {[string]:any}?)\n\tlocal id=Lektion.ovningId(p); if not ovningSpelasIn(id) then inspelare=nil; return end\n\tif inspelare then return end; inspelare=Inspelning.ny(id :: string,1,tm and tm.hast or nil); senasteOvning=id\nend\nlocal function stangInspelning()\n\tlocal post=Inspelning.avsluta(inspelare); inspelare=nil\n\tif post and #post.sampel>0 then local l=inspelningar[post.ovning] or {}; table.insert(l,post); inspelningar[post.ovning]=l end\nend\nlocal function oppnaReplay()\n\tlocal id=senasteOvning; if not id then return end; local l=inspelningar[id]; if not l or #l==0 then return end\n\tReplayController.oppna(l[#l], if #l>1 then l[#l-1] else nil, function() end)\nend\n\n'''
if anchor not in s: raise SystemExit('lesson anchor missing')
s=s.replace(anchor,helpers+anchor)
s=s.replace('\tif lage == "presentation" then\n\t\tlage = "rider"','\tif lage == "presentation" then\n\t\tinspelare=nil; lage = "rider"')
s=s.replace('\t\tif p.klar then','\t\tinspelare=nil\n\t\tif p.klar then',1)
s=s.replace('\tUgnetaController.vidFortsatt(fortsattning)\n','''\tUgnetaController.vidFortsatt(fortsattning)\n\tUgnetaController.vidReplay(oppnaReplay)\n\tUgnetaController.vidVidare(function()\n\t\tlocal p=pass; if not p then return end; Lektion.vidare(p); inspelare=nil\n\t\tif p.klar then lage="ingen" else lage="ny" end\n\tend)\n''')
needle='function LektionController.fortsatt(): boolean\n\tif not pass then return false end\n\treturn UgnetaController.fortsatt()\nend\n'
s=s.replace(needle,needle+'''\nfunction LektionController.replay(): boolean return UgnetaController.replay() end\nfunction LektionController.gaVidare(): boolean return UgnetaController.gaVidare() end\nfunction LektionController.replayAktiv(): boolean return ReplayController.aktiv() end\n''')
s=s.replace('function LektionController.steg(dt: number, tm: { [string]: any }?)','function LektionController.steg(dt: number, tm: { [string]: any }?, pose: { [string]: any }?)')
s=s.replace('\tif not tm or tm.uppsutten ~= true then return end\n\n\tp.tid += dt','\tif not tm or tm.uppsutten ~= true then return end\n\n\tstartaInspelning(p,tm); if inspelare then Inspelning.sampla(inspelare,dt,tm,pose) end\n\tp.tid += dt')
s=s.replace('\tlocal h = Lektion.avslutaForsok(p)\n','\tstangInspelning()\n\tlocal h = Lektion.avslutaForsok(p)\n')
s=s.replace('\tUgnetaController.vidFortsatt(nil)\n','\tstangInspelning()\n\tUgnetaController.vidFortsatt(nil); UgnetaController.vidReplay(nil); UgnetaController.vidVidare(nil)\n')
p.write_text(s)

# Client loop: extra choices and frozen live horse while card/replay is open.
patch('roblox/src/client/init.client.luau', [
('''\tif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then\n\t\tif LektionController.fortsatt() then return end\n\tend\n''','''\tif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then\n\t\tif LektionController.fortsatt() then return end\n\tend\n\tif input.KeyCode == Enum.KeyCode.T or input.KeyCode == Enum.KeyCode.ButtonX then\n\t\tif LektionController.replay() then return end\n\tend\n\tif input.KeyCode == Enum.KeyCode.G then\n\t\tif LektionController.gaVidare() then return end\n\tend\n'''),
('''\tlocal intent = Input.consume()\n\tride.movement:step(intent, dt)\n''','''\tif LektionController.vantar() or LektionController.replayAktiv() then\n\t\tlocal loco = ride.movement.loco\n\t\tride.animation:step(loco, dt); ride.rider:step(loco, dt); ride.camera:step(loco, dt)\n\t\treturn\n\tend\n\tlocal intent = Input.consume()\n\tride.movement:step(intent, dt)\n'''),
('LektionController.steg(dt, ride.telemetri)','LektionController.steg(dt, ride.telemetri, { x=ride.rig.root.Position.X, z=ride.rig.root.Position.Z, yaw=select(2, ride.rig.root.CFrame:ToOrientation()) })')])

# Test builder must inline the two new modules before LektionController.
p=Path('roblox/tests/build.py'); s=p.read_text()
s=s.replace('    ("Lektion",    "src/shared/HorseCore/Lektion.luau"),\n', '    ("Lektion",    "src/shared/HorseCore/Lektion.luau"),\n    ("Inspelning", "src/shared/HorseCore/Inspelning.luau"),\n',1)
s=s.replace('    ("UgnetaGestalt",    "src/client/UgnetaGestalt.luau"),\n', '    ("UgnetaGestalt",    "src/client/UgnetaGestalt.luau"),\n    ("ReplayController", "src/client/ReplayController.luau"),\n',1)
p.write_text(s)
print('G02-D patches applied')
