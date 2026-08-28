/* ══════════════════════════════════════════════════════════════════
   SPRITES — de målade bilderna.

   Hästar, ryttare, byggnader och träd ritas aldrig med kod. De är
   PNG-filer i assets/, och läggs in med drawImage. Saknas en fil ritas
   en tydligt markerad platshållare och namnet förs upp i SPRITE.saknas
   så att ASSETS_NEEDED.md går att stämma av mot verkligheten.

   I utvecklingsversionen laddas filerna från assets/. I den byggda
   enfilsversionen har tools/build.py bakat in dem som data-URI:er i
   SPRITE_DATA, så att spelet fortfarande är en enda fil utan nätverk.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const SPRITE={
  bild:{},            // namn → HTMLImageElement (redo att rita)
  laddar:{},          // namn → true medan hämtningen pågår
  saknas:new Set(),   // namn som inte finns — visas som platshållare
  redo:0, forsokt:0,
};

/* Hämtar en sprite. Returnerar bilden när den är laddad, annars null —
   anroparen ritar då sin platshållare. Aldrig blockerande. */
function sprite(namn){
  const b=SPRITE.bild[namn];
  if(b)return b.complete&&b.naturalWidth>0?b:null;
  if(SPRITE.laddar[namn]||SPRITE.saknas.has(namn))return null;
  SPRITE.laddar[namn]=true; SPRITE.forsokt++;
  const img=new Image();
  img.onload=()=>{SPRITE.bild[namn]=img; SPRITE.redo++; delete SPRITE.laddar[namn];};
  img.onerror=()=>{SPRITE.saknas.add(namn); delete SPRITE.laddar[namn];};
  const data=(typeof window!=="undefined")&&window.SPRITE_DATA&&window.SPRITE_DATA[namn];
  img.src=data||("assets/"+namn+".png");
  return null;
}

/* Ritar en sprite centrerad i (x, markY) med given höjd i pixlar.
   vand=-1 speglar den. Returnerar true om en riktig bild ritades. */
function ritaSprite(c,namn,x,markY,hojd,vand,alfa){
  const img=sprite(namn);
  if(!img)return false;
  const w=hojd*(img.naturalWidth/img.naturalHeight);
  c.save();
  if(alfa!==undefined)c.globalAlpha=alfa;
  c.translate(x,markY);
  if(vand<0)c.scale(-1,1);
  c.drawImage(img,-w/2,-hojd,w,hojd);
  c.restore();
  return true;
}

/* Platshållaren: streckad guldruta med filnamnet, i kitets färger.
   Den ska synas — en saknad bild får aldrig gå obemärkt förbi. */
function ritaPlatshallare(c,namn,x,markY,hojd,bredd){
  const w=bredd||hojd*1.25;
  c.save();
  c.translate(x,markY-hojd);
  c.fillStyle="rgba(74,27,109,.42)";
  c.strokeStyle="#F6C445"; c.lineWidth=3; c.setLineDash([9,7]);
  const r=14;
  c.beginPath();
  c.moveTo(-w/2+r,0); c.arcTo(w/2,0,w/2,hojd,r); c.arcTo(w/2,hojd,-w/2,hojd,r);
  c.arcTo(-w/2,hojd,-w/2,0,r); c.arcTo(-w/2,0,w/2,0,r); c.closePath();
  c.fill(); c.stroke(); c.setLineDash([]);
  c.fillStyle="#F6C445";
  c.font='700 12px "Arial Rounded MT Bold","Trebuchet MS",sans-serif';
  c.textAlign="center"; c.textBaseline="middle";
  c.fillText(namn+".png",0,hojd/2-8);
  c.fillStyle="rgba(245,239,224,.85)"; c.font='700 10px "Trebuchet MS",sans-serif';
  c.fillText("saknas i assets/",0,hojd/2+8);
  c.restore();
}

/* Vilken hästsprite en häst ska ha. Färgen avgör, inte namnet — så att
   en ny häst i data.js får rätt bild utan att listan här ändras. */
function hastSprite(h){
  if(!h)return "hast-fux-sida";
  if(h.spriteNamn)return h.spriteNamn;
  const f=(h.farg||"").toUpperCase();
  const KARTA={
    "#C8A96B":"hast-fjord-sida", "#A9A29A":"hast-skimmel-sida",
    "#9A938A":"hast-skimmel-sida", "#B0693A":"hast-fux-sida",
    "#2E2A26":"hast-svart-sida", "#3B2E24":"hast-morkbrun-sida",
    "#3F3126":"hast-morkbrun-sida", "#4C3527":"hast-morkbrun-sida",
    "#4E3A2B":"hast-morkbrun-sida", "#8F7351":"hast-palomino-sida",
  };
  return KARTA[f]||"hast-brun-sida";
}
