#!/usr/bin/env node
/* Applies only to the pinned integration source. Unknown anchors fail closed. */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from "node:url";
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
function edit(file,changes){
  let s=fs.readFileSync(path.join(root,file),'utf8');
  for(const [before,after] of changes){
    const n=s.split(before).length-1;
    if(n!==1)throw Error(`${file}: expected one anchor, got ${n}: ${before.slice(0,80)}`);
    s=s.replace(before,after);
  }
  fs.writeFileSync(path.join(root,file),s);
}
edit('index.html',[[
  '<script src="src/world.js"></script>',
  '<script src="src/input-feel.js"></script>\n<script src="src/world.js"></script>'
]]);
edit('src/world.js',[[
  'const GA={fart:1.8, jogg:3.4, svangMax:5.5, accel:8, broms:13, radie:0.35};',
  'const GA={fart:1.8, jogg:3.4, svangMax:InputFeel.WALK.turn, accel:InputFeel.WALK.accel, broms:InputFeel.WALK.brake, radie:0.35};'
],[
  '  mal:null, malT:0, malAvst:0, vag:null,',
  '  mal:null, malT:0, malAvst:0, vag:null,\n  styrKansla:{x:0,y:0},'
],[
  `  let styrka=1;
  if(IN.joy){ ix=IN.joy.x; iy=-IN.joy.y; styrka=IN.joy.styrka; }
  const jogg=IN.ned.ShiftLeft||IN.ned.ShiftRight;
  let onskad=null, malFart=0;
  if(ix||iy){
    const v=vandringYaw();
    const rx=Math.cos(v)*iy+Math.sin(v)*ix;
    const ry=Math.sin(v)*iy-Math.cos(v)*ix;
    onskad=Math.atan2(ry,rx);
    malFart=IN.joy ? GA.fart+(GA.jogg-GA.fart)*Math.max(0,styrka-0.55)/0.45
                   : (jogg?GA.jogg:GA.fart);
  }`,
  `  const analog=!!IN.joy;
  if(analog){ix=IN.joy.x;iy=-IN.joy.y;}
  const jogg=IN.ned.ShiftLeft||IN.ned.ShiftRight;
  const styr=InputFeel.walk(ix,iy,dt,VD.styrKansla,analog);
  let onskad=null, malFart=0;
  if(styr.moving){
    const v=vandringYaw();
    const rx=Math.cos(v)*styr.y+Math.sin(v)*styr.x;
    const ry=Math.sin(v)*styr.y-Math.cos(v)*styr.x;
    onskad=Math.atan2(ry,rx);
    malFart=analog ? GA.fart*styr.strength+(GA.jogg-GA.fart)*Math.max(0,styr.strength-0.55)/0.45
                   : (jogg?GA.jogg:GA.fart)*styr.strength;
  }`
],[
  '    if(ix||iy||avst<0.9){',
  '    if(styr.moving||avst<0.9){'
]]);
edit('src/game.js',[[
  '  latt:true,diagonal:1,spo:false,hh:-1,paradFore:0,ned:{},',
  '  latt:true,diagonal:1,spo:false,hh:-1,paradFore:0,ned:{},\n  styrDigital:null,styrKansla:{v:0},'
],[
  '  RIDIN.skankel=0; RIDIN.tygel=0; RIDIN.sits=0; RIDIN.styr=0; RIDIN.parad=0; RIDIN.pek=false;',
  '  RIDIN.skankel=0; RIDIN.tygel=0; RIDIN.sits=0; RIDIN.styr=0; RIDIN.parad=0; RIDIN.pek=false;\n  IN.styrDigital=null; IN.styrKansla.v=0;'
],[
  '    case"KeyA":RIDIN.styr=-1;RIDIN.pek=false;break;',
  '    case"KeyA":IN.styrDigital=-1;RIDIN.pek=false;break;'
],[
  '    case"KeyD":RIDIN.styr=1;RIDIN.pek=false;break;',
  '    case"KeyD":IN.styrDigital=1;RIDIN.pek=false;break;'
],[
  '    case"KeyA":RIDIN.styr=IN.ned.KeyD?1:0;break;',
  '    case"KeyA":if(!RIDIN.pek)IN.styrDigital=IN.ned.KeyD?1:0;break;'
],[
  '    case"KeyD":RIDIN.styr=IN.ned.KeyA?-1:0;break;',
  '    case"KeyD":if(!RIDIN.pek)IN.styrDigital=IN.ned.KeyA?-1:0;break;'
],[
  'function stegaInput(dt){\n  ridAvsiktTillHjalp();',
  `function stegaInput(dt){
  // Forma digital A/D före det befintliga hjälp- och kurvaturfiltret.
  // Direkta modellprov och analog spak behåller hela sitt omfång.
  if(RIDIN.pek){IN.styrDigital=null;IN.styrKansla.v=RIDIN.styr;}
  else if(IN.styrDigital!==null){
    RIDIN.styr=InputFeel.ride(IN.styrDigital,dt,IN.styrKansla);
  }
  ridAvsiktTillHjalp();`
]]);
console.log('Control-feel source patch applied.');
