/* ══════════════════════════════════════════════════════════════════
   INTRO — de första sextio sekunderna.

   Mätningen som gjorde den här filen nödvändig:

     · Menyn krävde att man läste 142 ord innan man fick rida.
     · Spelet band 15 tangenter, alla presenterade på en gång.
     · En förstagångsspelare som tryckte "Sitt upp" direkt fick
       dagsform 0,35 och FEM risker samtidigt — utskälld av ridläraren
       innan hon ridit en meter.

   Ingen tioåring tar sig igenom det, och då spelar det ingen roll hur
   bra ridmodellen under är. Tre saker görs här:

   1. TANGENTERNA GES I TUR OCH ORDNING. Ledlektionen har fyra rader,
      inte femton. Resten kommer när gruppen kommer, och hela listan
      står kvar i träningsboken för den som vill se den.

   2. FÖRSTA PASSET ÄR FÖRBERETT. Ridläraren har hämtat och gjort i
      ordning hästen — en gång. Du rider inom en halvminut, och
      efter-passet säger att nästa gång är det ditt jobb. Det är så det
      går till på riktigt med en nybörjare, och det är den enda ärliga
      vägen förbi klippan ovan.

   3. FÖRSTA RITTEN LEDS. Ridläraren ber om en sak i taget och väntar
      tills du gjort den, i stället för att lämna dig med en stapel.

   Allt det här gäller BARA pass noll. Från pass ett är spelet det
   spelet är — filen ska aldrig göra något lättare för en spelare som
   redan kan.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* ── Tangenterna, i tur och ordning ───────────────────────────────
   `fran` är index i GRUPPSTEGE: raden visas från och med den gruppen.
   Ordningen inom varje steg är den man lär sig dem i. */
const TANGENTSTEG=[
  {fran:0, k:"W",     txt:"skänkel på — be om framåt"},
  {fran:0, k:"S",     txt:"skänkel av"},
  {fran:0, k:"Space", txt:"tygeltag — håll i det gröna"},
  {fran:0, k:"A D",   txt:"styrning"},
  {fran:2, k:"R",     txt:"lättridning"},
  {fran:2, k:"Q",     txt:"byt diagonal"},
  {fran:3, k:"E",     txt:"halvhalt — det enda som samlar"},
  {fran:5, k:"Shift", txt:"lätt sits"},
  {fran:5, k:"Ctrl",  txt:"djup nedsittning"},
];
/* Alltid tillgängliga, men de hör inte till ridningen — de står i
   träningsboken och tar ingen plats i HUD:en. */
const TANGENTOVRIGA=[
  {k:"T", txt:"träningsboken"}, {k:"V", txt:"växla vy"},
  {k:"M", txt:"ljud av/på"},    {k:"P", txt:"ridläraren visar"},
  {k:"F", txt:"spö — läs hästlistan först"},
];

function introNiva(){
  const i=GRUPPSTEGE.indexOf((typeof SPAR!=="undefined"&&SPAR&&SPAR.grupp)||"ledlektion");
  return i<0?0:i;
}
function introTangenter(){
  const n=introNiva();
  return TANGENTSTEG.filter(t=>t.fran<=n);
}

/* Remsan i HUD:en. Den visas de tre första passen och försvinner sedan
   av sig själv — en spelare som kan tangenterna ska inte titta på dem. */
function introVisaTangenter(){
  return (typeof SPAR==="undefined"||!SPAR)?true:SPAR.pass<3;
}
function ritaIntroTangenter(){
  const el=document.getElementById("tangenter");
  if(!el)return;
  if(!introVisaTangenter()){ el.hidden=true; return; }
  el.hidden=false;
  const nya=introTangenter();
  if(el.dataset.n===String(nya.length))return;      // ritas om bara när den ändras
  el.dataset.n=String(nya.length);
  el.innerHTML=nya.map(t=>`<div class="tRad">`
    +t.k.split(" ").map(k=>`<kbd>${k}</kbd>`).join("")
    +`<span>${t.txt}</span></div>`).join("");
}

/* ══ FÖRSTA PASSET ═════════════════════════════════════════════════ */
function introForstaPasset(){
  return typeof SPAR!=="undefined"&&SPAR&&SPAR.pass===0;
}

/* Ridläraren har gjort i ordning hästen — men inte allt, och det är
   avsiktligt. Hon har gjort det SÄKERHETSKRITISKA: sadeln på rätt plats,
   gjorden i bandet, manken fri, bettet kollat. Ryktningen och hovarna är
   bara påbörjade, för det är de momenten spelaren ska ta över.

   Med full skötsel landade dagsformen på 0,96, och då lär sig spelaren
   att skötseln är gratis. Nu landar den kring 0,7: fullt spelbart, men
   efter-passet har något att peka på. */
function introForberedd(){
  SK.visitering=0.55; SK.betsling=0.85;
  SK.hovar=[0.55,0.55,0.55,0.55];
  SK.sadelX=SADEL_RATT; SK.gjord=0.55;
  SK.ryktning=new Set();
  const halva=Math.ceil(RYKTZON.length*0.55);
  for(let i=0;i<halva;i++){
    SK.ryktning.add(i);
    if(typeof RY!=="undefined"&&RY.gjort&&RY.gjort[i])
      for(const kr of RYKTKRAV[RYKTZON[i].typ])RY.gjort[i].add(kr);
  }
  if(typeof SA!=="undefined"){ SA.mankfri=true; SA.tag=3; SA.fas=3; }
  if(typeof VIS!=="undefined"){ VIS.gang=0;
    for(const p of VISITPUNKT.slice(0,3))VIS.sedd.add(p.id); }
}

/* ── Den ledda ritten ─────────────────────────────────────────────
   Ridläraren ber om en sak i taget och väntar tills den är gjord. Inget
   steg har en klocka: det som stänger ett steg är att spelaren FAKTISKT
   gjort det, annars lär man sig ingenting av att vänta ut det. */
const INTROSTEG=[
  {id:"skankel",
   sag:"Lägg på skänkeln med W. Hon behöver veta att du vill framåt.",
   klar:()=>G.aids&&G.aids.skankel>0.30},
  {id:"tygel",
   sag:"Bra. Ta upp tygeln med Space och håll kvar — sikta på det gröna bandet.",
   klar:()=>G.aids&&G.aids.tygel>K.TYGEL_BAND_MIN&&G.aids.tygel<K.TYGEL_BAND_MAX},
  {id:"gang",
   sag:"Där. Nu går hon. Känn hur hon rör sig under dig.",
   klar:()=>G.ride&&G.ride.tempo>0.9},
  {id:"styr",
   sag:"Styr med A och D. Rid mot långsidan.",
   klar:()=>G.aids&&Math.abs(G.aids.styrning)>0.25},
  {id:"klart",
   sag:"Så. Mer än så är det inte — resten är att göra det jämnt. Nu rider vi.",
   klar:()=>true},
];
const INTRO={steg:-1, t:0, kvar:0, pafminnelser:0};

function introNollstall(){ INTRO.steg=-1; INTRO.t=0; INTRO.kvar=0; INTRO.pafminnelser=0; }

/* Anropas varje bildruta under lektionen. Returnerar sant så länge
   introt håller på — då pausas momentets stapel, så att den ledda
   genomgången inte tickar mot ett krav spelaren inte fått höra än. */
function introRittSteg(dt){
  if(!introForstaPasset())return false;
  if(INTRO.steg>=INTROSTEG.length)return false;
  INTRO.t+=dt;
  if(INTRO.steg<0){                       // första repliken
    INTRO.steg=0; INTRO.kvar=0;
    saga(INTROSTEG[0].sag,6);
    return true;
  }
  const s=INTROSTEG[INTRO.steg];
  INTRO.kvar-=dt;
  if(s.klar()&&INTRO.kvar<=0){
    INTRO.steg++;
    if(INTRO.steg>=INTROSTEG.length)return false;
    saga(INTROSTEG[INTRO.steg].sag,6);
    INTRO.kvar=1.6;                       // låt repliken höras innan nästa mäts
    return true;
  }
  /* Fastnar man i ett steg upprepas uppmaningen — men bara var tolfte
     sekund, så att den blir en påminnelse och inte ett gnäll.

     Och efter tre påminnelser går ridläraren vidare ändå. En guidad
     genomgång får aldrig bli en vägg: gör spelaren inte just det steget
     — hon kanske inte hittar tangenten, kanske inte vill svänga — ska
     lektionen börja i alla fall. Utan den här utgången pausades
     momentets stapel i all evighet, och passet gick aldrig att avsluta.
     Provat: en styrning som låg exakt på gränsen låste introt för gott. */
  if(INTRO.t>12){
    INTRO.t=0; INTRO.pafminnelser=(INTRO.pafminnelser||0)+1;
    if(INTRO.pafminnelser>=3){
      INTRO.pafminnelser=0; INTRO.steg++;
      if(INTRO.steg>=INTROSTEG.length){
        saga("Vi tar resten medan vi rider. Nu kör vi.",4); return false; }
      saga(INTROSTEG[INTRO.steg].sag,6); INTRO.kvar=1.6;
      return true;
    }
    saga(s.sag,5);
  }
  return true;
}
