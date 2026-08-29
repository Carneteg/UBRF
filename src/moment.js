/* ══════════════════════════════════════════════════════════════════
   MOMENTEN VID HÄSTEN — kameran och hoven.

   Skötseln hade en enda bild: hästen i profil, hela tiden, för alla
   fyra momenten. Det gick att klicka rätt utan att förstå någonting,
   och framför allt syntes aldrig det man faktiskt gör.

   Två saker här:

   1. KAMERAN. Varje moment har sin egen utsnitt, och den glider dit när
      man byter. Visitera går nära huvudet, kratsa går ner till benen,
      sadla till ryggen. Man ska se det man håller på med.

   2. HOVEN. Att kratsa är det moment där tekniken betyder mest och
      syns minst — hela poängen ligger på hovens undersida, som man
      aldrig ser i profil. När du lyfter en hov zoomar bilden in på
      sulan: hovväggen, strålen som en pil mot tån, och strålfårorna på
      var sida där gruset packar sig.

      Och riktningen lärs ut. Man kratsar FRÅN TRAKTEN MOT TÅN, längs
      fårorna. Gör man tvärtom pressar man in gruset mot strålen och
      drar redskapet mot sig själv. Spelet säger ifrån.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* Utsnitt per moment: s = zoom, (x,y) = punkten som hamnar i mitten,
   i canvasens 0–1-koordinater. Talen är valda mot hästbilden i
   ritaHastSida: huvudet ligger till vänster, bakbenen till höger. */
const MOMENTKAM=[
  {s:2.15, x:0.235, y:0.415},   // 0 visitera — mungipa och sadelläge
  {s:1.00, x:0.500, y:0.560},   // 1 rykta — hela hästen
  {s:2.05, x:0.560, y:0.760},   // 2 kratsa — benen och hovarna
  {s:1.60, x:0.520, y:0.470},   // 3 sadla — rygg och gjord
];
const KAM={s:1, x:0.5, y:0.56, mal:null, kor:false};

function momentKamMal(steg){
  return MOMENTKAM[steg]||MOMENTKAM[1];
}
/* Glider mot målet. Anropas från ritningen; körs bara medan den rör sig,
   så en stillastående ruta kostar ingenting. */
function momentKamSteg(){
  const m=KAM.mal||momentKamMal(0);
  const f=0.22;
  KAM.s+=(m.s-KAM.s)*f; KAM.x+=(m.x-KAM.x)*f; KAM.y+=(m.y-KAM.y)*f;
  return Math.abs(m.s-KAM.s)>0.004||Math.abs(m.x-KAM.x)>0.002||Math.abs(m.y-KAM.y)>0.002;
}
function momentKamTill(steg,direkt){
  KAM.mal=momentKamMal(steg);
  if(direkt){KAM.s=KAM.mal.s;KAM.x=KAM.mal.x;KAM.y=KAM.mal.y;}
  momentKamKor();
}
let _kamRaf=0;
function momentKamKor(){
  if(KAM.kor)return;
  KAM.kor=true;
  const steg=()=>{
    const mer=momentKamSteg()|| (HOV.i>=0&&HOV.t<1) || (HOV.i<0&&HOV.t>0);
    if(HOV.i>=0)HOV.t=Math.min(1,HOV.t+0.10);
    else if(HOV.t>0)HOV.t=Math.max(0,HOV.t-0.12);
    if(typeof ritaGroom==="function")ritaGroom();
    if(mer)_kamRaf=requestAnimationFrame(steg); else KAM.kor=false;
  };
  _kamRaf=requestAnimationFrame(steg);
}
/* Skärmpunkt (0–1) → bildpunkt (0–1). Input måste räknas tillbaka
   genom samma utsnitt som ritningen använder, annars klickar man fel. */
function momentTillBild(sx,sy){
  return [(sx-0.5)/KAM.s+KAM.x, (sy-0.5)/KAM.s+KAM.y];
}

/* ══ HOVEN ════════════════════════════════════════════════════════
   Tillstånd för närbilden. i = vilken hov (0–3), −1 = ingen.
   t = hur långt in zoomningen kommit, 0–1. */
const HOV={i:-1, t:0, smuts:[], ren:0, fel:0, sista:null, varning:"", sten:null};

/* Fyllningen: gruset ligger i strålfårorna, ibland en sten i den ena.
   Fröet är hoven och dagen, så samma hov ser likadan ut om man går ur
   och in igen — men olika mellan hovar och mellan dagar. */
function hovOppna(i){
  HOV.i=i; HOV.t=0; HOV.ren=0; HOV.fel=0; HOV.varning=""; HOV.sista=null;
  let fro=((G.seed||1)*7919+i*131+(G.hastId||"").length*17)>>>0;
  const rnd=()=>{fro=(fro*1664525+1013904223)>>>0; return fro/4294967296;};
  HOV.smuts=[];
  const antal=7+Math.floor(rnd()*5);
  for(let k=0;k<antal;k++){
    const sida=rnd()<0.5?-1:1;
    HOV.smuts.push({
      x:sida*(0.20+rnd()*0.13),          // i strålfåran
      y:-0.34+rnd()*0.74,                 // tå (−) till trakt (+)
      r:0.055+rnd()*0.045,
      liv:1,
    });
  }
  /* Sten i hoven: den gör ont och ska bort. Den sitter fast och kräver
     att man går över den flera gånger. */
  HOV.sten=rnd()<0.45?{x:(rnd()<0.5?-1:1)*0.24, y:0.10+rnd()*0.25, r:0.075, liv:1}:null;
  momentKamKor();
}
function hovStang(){ HOV.i=-1; HOV.sista=null; momentKamKor(); }

/* Ett drag över sulan. p är i hovens egna koordinater: (0,0) i mitten,
   −y mot tån, +y mot trakten, x åt sidorna. */
function hovDrag(p){
  if(HOV.i<0)return;
  const f=HOV.sista; HOV.sista=p;
  if(!f)return;
  const dx=p[0]-f[0], dy=p[1]-f[1];
  const len=Math.hypot(dx,dy);
  if(len<0.012)return;
  /* Rätt håll är mot tån, alltså minskande y. Ett drag som mest går
     tvärs över räknas inte som fel — det är bara verkningslöst. */
  if(dy>0.030){
    HOV.fel++;
    HOV.varning="Kratsa från trakten mot tån — annars pressar du in gruset mot strålen.";
    return;
  }
  if(dy>-0.012)return;
  HOV.varning="";
  const traff=(o,styrka)=>{
    if(o.liv<=0)return;
    /* Avståndet från draget till smutsen, mätt mot sträckan. */
    const t=clamp(((o.x-f[0])*dx+(o.y-f[1])*dy)/(len*len),0,1);
    const d=Math.hypot(f[0]+dx*t-o.x, f[1]+dy*t-o.y);
    if(d<o.r+0.075)o.liv=Math.max(0,o.liv-styrka);
  };
  for(const o of HOV.smuts)traff(o,0.62);
  if(HOV.sten)traff(HOV.sten,0.22);      // stenen sitter hårdare

  const kvar=HOV.smuts.reduce((a,o)=>a+o.liv,0)+(HOV.sten?HOV.sten.liv*1.5:0);
  const allt=HOV.smuts.length+(HOV.sten?1.5:0);
  HOV.ren=clamp(1-kvar/allt,0,1);
  if(HOV.ren>=0.94){
    SK.hovar[HOV.i]=1;
    if(typeof ljudStot==="function")ljudStot(720,"sine",0.10,0.05);
    setTimeout(hovStang,420);
  }
}

/* ── Ritningen ────────────────────────────────────────────────────
   Hoven underifrån, tån uppåt — så ser den ut när man håller den. */
function ritaHov(cx,W,H){
  if(HOV.t<=0.001)return;
  const a=HOV.t;
  cx.save();
  cx.globalAlpha=a;
  cx.fillStyle="rgba(12,14,18,.82)"; cx.fillRect(0,0,W,H);
  const cxx=W*0.5, cyy=H*0.50, R=Math.min(W,H)*0.43*(0.86+0.14*a);
  const P=(x,y)=>[cxx+x*R, cyy+y*R];

  /* Hovvägg: bredare vid tån, smalare vid trakterna. */
  cx.beginPath();
  cx.moveTo(...P(0,-1.06));
  cx.bezierCurveTo(...P(0.86,-0.92),...P(1.02,-0.06),...P(0.72,0.78));
  cx.bezierCurveTo(...P(0.50,1.08),...P(-0.50,1.08),...P(-0.72,0.78));
  cx.bezierCurveTo(...P(-1.02,-0.06),...P(-0.86,-0.92),...P(0,-1.06));
  cx.closePath();
  cx.fillStyle="#3E342A"; cx.fill();
  cx.lineWidth=Math.max(2,R*0.055); cx.strokeStyle="#2A231C"; cx.stroke();

  /* Sulan innanför väggen. */
  cx.save(); cx.clip();
  cx.beginPath();
  cx.moveTo(...P(0,-0.80));
  cx.bezierCurveTo(...P(0.66,-0.68),...P(0.78,-0.04),...P(0.55,0.66));
  cx.bezierCurveTo(...P(0.38,0.90),...P(-0.38,0.90),...P(-0.55,0.66));
  cx.bezierCurveTo(...P(-0.78,-0.04),...P(-0.66,-0.68),...P(0,-0.80));
  cx.closePath();
  cx.fillStyle="#8A7358"; cx.fill();

  /* Strålen — en pil mot tån, med mittfåran. */
  cx.beginPath();
  cx.moveTo(...P(0,-0.46));
  cx.lineTo(...P(0.19,0.20));
  cx.lineTo(...P(0.34,0.86));
  cx.lineTo(...P(-0.34,0.86));
  cx.lineTo(...P(-0.19,0.20));
  cx.closePath();
  cx.fillStyle="#5E4A3A"; cx.fill();
  cx.beginPath(); cx.moveTo(...P(0,0.16)); cx.lineTo(...P(0,0.80));
  cx.lineWidth=Math.max(2,R*0.05); cx.strokeStyle="#453528"; cx.stroke();

  /* Strålfårorna: det är hit man för kratsen. */
  for(const s of [-1,1]){
    cx.beginPath();
    cx.moveTo(...P(s*0.16,-0.34));
    cx.quadraticCurveTo(...P(s*0.34,0.24),...P(s*0.40,0.82));
    cx.lineWidth=Math.max(3,R*0.13); cx.strokeStyle="#4A3B2E";
    cx.lineCap="round"; cx.stroke();
  }
  /* Gruset och stenen. */
  for(const o of HOV.smuts){
    if(o.liv<=0)continue;
    cx.globalAlpha=a*(0.40+0.60*o.liv);
    const rr=R*o.r*(0.62+0.38*o.liv);
    cx.beginPath();
    for(let k=0;k<7;k++){const w=k/7*Math.PI*2, q=rr*(0.78+0.30*((k*37%11)/11));
      const pt=P(o.x+Math.cos(w)*q/R, o.y+Math.sin(w)*q/R);
      k?cx.lineTo(...pt):cx.moveTo(...pt);}
    cx.closePath();
    cx.fillStyle="#241F18"; cx.fill();
    cx.lineWidth=Math.max(1,R*0.012); cx.strokeStyle="#4A4034"; cx.stroke();
  }
  if(HOV.sten&&HOV.sten.liv>0){
    cx.globalAlpha=a;
    cx.beginPath(); cx.arc(...P(HOV.sten.x,HOV.sten.y),R*HOV.sten.r,0,7);
    cx.fillStyle="#9A968E"; cx.fill();
    cx.lineWidth=Math.max(1,R*0.02); cx.strokeStyle="#6E6A62"; cx.stroke();
  }
  cx.restore();
  cx.globalAlpha=a;

  /* Riktningspilen: trakt → tå, ritad längs den vänstra fåran. */
  cx.strokeStyle="rgba(214,174,60,.60)"; cx.lineWidth=Math.max(2,R*0.045);
  cx.setLineDash([R*0.10,R*0.09]);
  cx.beginPath(); cx.moveTo(...P(-0.30,0.74)); cx.lineTo(...P(-0.19,-0.26)); cx.stroke();
  cx.setLineDash([]);
  cx.beginPath();
  cx.moveTo(...P(-0.19,-0.40)); cx.lineTo(...P(-0.31,-0.16)); cx.lineTo(...P(-0.07,-0.16));
  cx.closePath(); cx.fillStyle="rgba(214,174,60,.75)"; cx.fill();

  /* Texten: vilken hov, hur rent, och tillsägelsen om man drar fel. */
  const namn=["vänster fram","höger fram","vänster bak","höger bak"][HOV.i]||"";
  cx.fillStyle="#E6E4DE"; cx.textAlign="center";
  cx.font='600 15px "IBM Plex Sans", sans-serif';
  cx.fillText(namn.toUpperCase()+" · "+Math.round(HOV.ren*100)+" %", W*0.5, H*0.075);
  cx.font='13px "IBM Plex Sans", sans-serif';
  cx.fillStyle=HOV.varning?"#D0655A":"#A6ABB3";
  const rad=HOV.varning||"Dra från trakten mot tån, i fårorna på var sida om strålen.";
  cx.fillText(rad, W*0.5, H*0.945);
  cx.restore();
}

/* Skärmpunkt (0–1) → hovens koordinater, för dragen i närbilden. */
function hovTillLokal(sx,sy,W,H){
  const R=Math.min(W,H)*0.43*(0.86+0.14*HOV.t);
  return [(sx*W-W*0.5)/R, (sy*H-H*0.50)/R];
}
