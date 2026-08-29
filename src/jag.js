/* ══════════════════════════════════════════════════════════════════
   JAG — ryttaren du skapar, och det du redan bär med dig.

   Två delar som hör ihop men gör olika saker:

     UTSEENDET  ändrar ingenting i hur hästen går. Det är ditt, och det
                enda kravet är att det syns i sadeln, i stallet och på
                gården — samma färger i klossläget som i det svepta.

     EGENSKAPERNA är tre av åtta, valda en gång. De är en LUTNING, inte
                en genväg: var och en flyttar en tolerans i ridmodellen
                någon tiondel, och ingen av dem låter dig hoppa över att
                lära dig något. En egenskap som gjorde ett moment
                onödigt vore ett designfel, inte en belöning.

   Sju av egenskaperna kommer ur artikeln "7 egenskaper hos en skicklig
   ryttare", den åttonde — Pondus — ur Markus Holsts Ridhandbok, samma
   delar som `KUNSKAP` i ovningar.js sammanfattar. Varje egenskap bär sin
   källa med sig, och skaparrutan skriver ut både vad den gör i spelet
   och varför källan säger så. Det är hela poängen: valet ska lära dig
   något om ridning, inte bara ge dig en siffra.

   Allt bor i ryttarprofilen (SPAR) och följer därmed med både till
   localStorage och till molnet, utan egen lagring.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* ── Utseendet ────────────────────────────────────────────────────
   Färgerna är valda så att varje kombination fungerar mot stallets
   ljus. Inga fria färgväljare: en ryttare i neongrönt hör inte hemma
   på en ridskola, och begränsningen gör valet lättare, inte fattigare. */
const JAGVAL={
  hy:      [["ljus","#E8C4A2"],["mellan","#D2A074"],["oliv","#B98455"],
            ["brun","#8D5A38"],["mörk","#5E3A25"]],
  har:     [["ljus","#D8B968"],["ljusbrun","#A87B4A"],["brun","#6B4526"],
            ["mörk","#2E241C"],["röd","#A8502C"],["grå","#B8B2A6"]],
  harstil: [["hästsvans","svans"],["fläta","flata"],["kort","kort"],
            ["uppsatt","uppsatt"]],
  kavaj:   [["marinblå","#33465F"],["mörkgrön","#2E4638"],["vinröd","#6E2F3A"],
            ["grå","#4A4F57"],["svart","#23282F"],["ljusblå","#5B7C99"]],
  byxa:    [["beige","#D6C9AE"],["vit","#EDE9DE"],["grå","#9AA0A8"],
            ["mörkblå","#3A4553"],["svart","#2A2A2C"]],
  hjalm:   [["svart","#23282F"],["marinblå","#2C3A50"],["mörkgrön","#2C4636"],
            ["vinröd","#5E2A33"]],
};
/* Klubbens färg på hjälmen är inte valbar. Alla på UBRF bär den. */
const KLUBBFARG="#3E6B47";

/* ── Egenskaperna ─────────────────────────────────────────────────
   Åtta att välja mellan, tre att bära. `mod` är lutningen: nycklarna är
   samma som fardighetsMod() i framsteg.js skickar in i ridmodellen,
   plus tre egna: `skygghet` dämpar hästens skygghet i modellen,
   `larande` snabbar på färdighetsväxten i framsteg.js, och
   `visaSpanning` är ingen kraft alls utan information — HUD:en visar
   spänningen i stället för att bara varna när den redan är för hög.

   Sju av dem kommer ur artikeln "7 egenskaper hos en skicklig ryttare"
   (Ophena). Produktdelarna i den — säkerhetsstigbyglarna — är inte med:
   det här är ett spel, ingen annonsplats. Pondus är den åttonde och
   kommer ur Ridhandbokens del om hästhantering.

   Håll talen små — de ska kännas, inte bära passet. */
const EGENSKAP=[
  {id:"balans", namn:"Balans och kärnstyrka",
   kort:"Grunden i sadeln",
   effekt:"Hästen glider mindre ifrån dig, och du hittar tillbaka snabbare efter ett ryck.",
   varfor:"Allt du gör i sadeln börjar i kärnan. Är du obalanserad känner hästen det "+
     "omedelbart och kompenserar för dina viktförskjutningar — det påverkar hennes "+
     "rörelser och kan göra ont över tid.",
   kalla:"7 egenskaper hos en skicklig ryttare · Ridhandboken del 6",
   mod:{halla:0.10, mjukhetFart:0.22}},

  {id:"oberoende", namn:"Oberoende sits",
   kort:"Hand, ben och sits var för sig",
   effekt:"Hästen blir mindre spänd av dig. Du tynger henne inte framåt.",
   varfor:"En stark kärna ger en oberoende sits: händer, ben och sits kan arbeta "+
     "separat utan att du tappar balansen. Utan den ger varje benrörelse också ett "+
     "handutslag, och hästen får två besked när du menade ett.",
   kalla:"7 egenskaper hos en skicklig ryttare · Ridhandboken del 6",
   mod:{lugn:0.12}},

  {id:"timing", namn:"Timing",
   kort:"Rätt ögonblick, inte rätt kraft",
   effekt:"Halvhalten får ett bredare tidsfönster och gesten får vara mindre.",
   varfor:"Hästar lever i nuet. Ber du om en galoppövergång precis när yttre bakbenet "+
     "är på väg att ta steget talar du deras språk; dålig timing skapar förvirring, "+
     "för hon är inte positionerad för att göra det du ber om.",
   kalla:"7 egenskaper hos en skicklig ryttare · Ridhandboken del 10",
   mod:{hhFonster:0.30, hhAmplitud:-0.12}},

  {id:"sjalvfortroende", namn:"Självförtroende",
   kort:"Utan vårdslöshet",
   effekt:"Hästens spänning sjunker undan fortare när något skrämt henne.",
   varfor:"Självförtroende är inte oräddhet — det är att lita på sin förberedelse och "+
     "känna sina gränser. Duktiga ryttare blir också nervösa; skillnaden är att de "+
     "arbetar sig igenom nervositeten i stället för att bli paralyserade av den. "+
     "Hästen känner skillnaden.",
   kalla:"7 egenskaper hos en skicklig ryttare",
   mod:{spanningFall:0.22}},

  {id:"kansla", namn:"Känsla och lyhördhet",
   kort:"Ditt sjätte sinne",
   effekt:"Du ser hästens spänning hela tiden, inte bara när den redan är för hög.",
   varfor:"Känsla är att märka vad som händer under dig — spänningen i ryggen, den "+
     "lilla tvekan innan hon skyggar. Det går inte att läsa sig till, men det går att "+
     "träna: blunda i skritt och känn efter hur ryggen svänger och när varje bakben "+
     "tar av.",
   kalla:"7 egenskaper hos en skicklig ryttare · Ridhandboken del 5",
   mod:{visaSpanning:1}},

  {id:"mjukhet", namn:"Mjukhet",
   kort:"En förbindelse, inte ett grepp",
   effekt:"Du får ta mer tygel innan hästen tolkar det som hårdhet.",
   varfor:"Hästar känner när en fluga landar på huden. Använder du kraft dämpar du "+
     "hennes svarsförmåga med tiden; lätta, vältajmade hjälper som hon knappt kan se "+
     "skapar en villig partner.",
   kalla:"7 egenskaper hos en skicklig ryttare · Ridhandboken del 7",
   mod:{tygelband:0.035}},

  {id:"larande", namn:"Kontinuerligt lärande",
   kort:"Du slutar aldrig ta lektioner",
   effekt:"Färdigheterna växer omkring en tiondel snabbare — men bara av pass som räknas.",
   varfor:"De bästa ryttarna du känner tar fortfarande lektioner. Bra hästhantering är "+
     "inget mål man når och sedan vilar på; varje ritt bär en lärdom om man är "+
     "uppmärksam. Egenskapen ger dig ingenting gratis — den gör bara att det du "+
     "faktiskt gör bra fastnar lite fortare.",
   kalla:"7 egenskaper hos en skicklig ryttare",
   mod:{larande:0.15}},

  {id:"pondus", namn:"Pondus",
   kort:"Hästen följer när du leder",
   effekt:"En skygg häst blir mindre skygg av dig. Märks mest på de nervösa.",
   varfor:"Rätt hantering är den viktigaste olycksförebyggande åtgärd som finns. "+
     "Led i grimskaft med handen nära grimman, och låt hästen veta var du är.",
   kalla:"Ridhandboken del 2 · Säkerhet och hästhantering",
   mod:{skygghet:0.30}},
];
const EGENSKAP_ANTAL=3;

/* ── Profilen ─────────────────────────────────────────────────────── */
function nyJag(){
  return {namn:"", hy:1, har:2, harstil:0, kavaj:0, byxa:0, hjalm:0,
    egenskaper:[], skapad:false};
}
/* Läses ur SPAR, som redan sparas och synkas. Saknas något fält fylls
   det med normalvärdet — en gammal sparning ska aldrig krascha. */
function jag(){
  if(typeof SPAR==="undefined"||!SPAR)return nyJag();
  if(!SPAR.jag)SPAR.jag=nyJag();
  const d=nyJag();
  for(const k in d)if(SPAR.jag[k]===undefined)SPAR.jag[k]=d[k];
  if(!Array.isArray(SPAR.jag.egenskaper))SPAR.jag.egenskaper=[];
  return SPAR.jag;
}
function jagKlar(){ return !!jag().skapad; }
function jagNamn(){ return jag().namn||"Ryttaren"; }

/* Färgerna som 3D-delarna byggs av. En enda källa, så klossläget och
   det svepta läget aldrig kan glida isär. */
function jagFarg(){
  const j=jag(), v=(lista,i)=>lista[Math.min(Math.max(i|0,0),lista.length-1)][1];
  return {
    hy:    v(JAGVAL.hy, j.hy),
    har:   v(JAGVAL.har, j.har),
    kavaj: v(JAGVAL.kavaj, j.kavaj),
    byxa:  v(JAGVAL.byxa, j.byxa),
    hjalm: v(JAGVAL.hjalm, j.hjalm),
    stovel:"#1E1A16",
    klubb: KLUBBFARG,
    harstil:(JAGVAL.harstil[Math.min(Math.max(j.harstil|0,0),
      JAGVAL.harstil.length-1)]||["",""])[1],
  };
}

/* En mörkare ton av en färg — hjälmens skärm, kavajens skugga. */
function jagMorkare(hex,f){
  const n=parseInt(hex.slice(1),16), k=1-(f===undefined?0.18:f);
  const r=Math.round(((n>>16)&255)*k), g=Math.round(((n>>8)&255)*k), b=Math.round((n&255)*k);
  return "#"+((1<<24)|(r<<16)|(g<<8)|b).toString(16).slice(1);
}

/* ── Lutningen ────────────────────────────────────────────────────
   Summan av de valda egenskapernas mod. Nycklarna läses av
   fardighetsMod() i framsteg.js (ridmodellen), av dagens stallro och av
   förtroendetaket i ryttare.js. Ingen annan läser den här. */
function jagMod(){
  const ut={};
  for(const id of jag().egenskaper){
    const e=EGENSKAP.find(x=>x.id===id);
    if(!e)continue;
    for(const k in e.mod)ut[k]=(ut[k]||0)+e.mod[k];
  }
  return ut;
}
function jagHar(id){ return jag().egenskaper.includes(id); }

/* ══ SKAPARRUTAN ═══════════════════════════════════════════════════
   Ritas som ett vanligt overlay-ark. Förhandsbilden är 2D — samma
   klossiga siluett som i sadeln, men den behöver ingen WebGL-kontext
   och fungerar därför även innan spelet startat. */
const SKAP={flik:0, utkast:null, retur:null};

function visaSkaparen(retur){
  SKAP.retur=retur||"meny";
  SKAP.utkast=SKAP.utkast||{...jag()};
  const u=SKAP.utkast;
  const forsta=!jag().skapad;

  const rad=(nyckel,etikett)=>`
    <div class="skapRad">
      <span class="skapEtikett">${etikett}</span>
      <div class="skapChipp">${JAGVAL[nyckel].map((v,i)=>`
        <button class="skapChip${u[nyckel]===i?" pa":""}" data-f="${nyckel}" data-i="${i}"
          ${nyckel==="harstil"?"":`style="--prov:${v[1]}"`}>
          ${nyckel==="harstil"?"":'<i class="skapProv"></i>'}${v[0]}
        </button>`).join("")}</div>
    </div>`;

  const valda=u.egenskaper.length;
  const egenskapKort=EGENSKAP.map(e=>{
    const pa=u.egenskaper.includes(e.id);
    const full=!pa&&valda>=EGENSKAP_ANTAL;
    return `<button class="egKort${pa?" pa":""}${full?" tom":""}" data-eg="${e.id}">
      <span class="egNamn">${e.namn}</span>
      <span class="egKort2">${e.kort}</span>
      <span class="egEffekt">${e.effekt}</span>
      <span class="egVarfor">${e.varfor}<br><i>${e.kalla}</i></span>
    </button>`;}).join("");

  overlay(true,`
  <span class="lbl">${forsta?"Välkommen till UBRF":"Din ryttare"}</span>
  <h1 style="margin-top:6px">${forsta?"Vem är du?":"Ändra din ryttare"}</h1>
  <p class="dim" style="font-size:13.5px;margin-top:2px">
    Utseendet är ditt och ändrar ingenting i ridningen.
    Egenskaperna är <b>tre av ${EGENSKAP.length}</b>, och var och en lutar spelet en
    aning — ingen av dem gör något moment onödigt. Sju kommer ur artikeln
    <i>7 egenskaper hos en skicklig ryttare</i>, den åttonde ur Ridhandboken.</p>

  <div id="skapDelar">
    <div>
      <canvas id="skapDuk"></canvas>
      <div class="skapNamn">
        <input id="skapNamnFalt" maxlength="18" placeholder="Ditt namn"
          value="${(u.namn||"").replace(/"/g,"&quot;")}">
      </div>
    </div>
    <div id="skapVal">
      <div class="skapFlikar">
        <button class="skapFlik${SKAP.flik===0?" pa":""}" data-flik="0">Utseende</button>
        <button class="skapFlik${SKAP.flik===1?" pa":""}" data-flik="1">
          Egenskaper <span class="dim">${valda}/${EGENSKAP_ANTAL}</span></button>
      </div>
      <div id="skapKropp">
        ${SKAP.flik===0
          ? rad("hy","Hy")+rad("har","Hårfärg")+rad("harstil","Frisyr")+
            rad("kavaj","Kavaj")+rad("byxa","Ridbyxor")+rad("hjalm","Hjälm")+
            `<p class="dim" style="font-size:12px;margin-top:10px">
              Hjälmens gröna band är klubbens och går inte att byta.</p>`
          : `<p class="dim" style="font-size:12.5px;margin:0 0 10px">
              Välj <b>${EGENSKAP_ANTAL}</b>. Du kan ändra dem när du vill —
              de är en lutning, inte ett låst öde.</p>
             <div id="egLista">${egenskapKort}</div>`}
      </div>
    </div>
  </div>

  <div class="btnrow">
    <button class="btn" id="bSkapKlar">${forsta?"Så här ser jag ut":"Spara"}</button>
    ${forsta
      ? '<button class="btn ghost" id="bSkapHoppa">Rid direkt — jag fixar det sen</button>'
      : '<button class="btn ghost" id="bSkapAvbryt">Avbryt</button>'}
    <span class="dim" style="font-size:13px" id="skapVarning"></span>
  </div>
  ${forsta?`<p class="dim" style="font-size:12.5px;margin-top:10px">
    Inget konto behövs för att spela — allt sparas i den här webbläsaren.
    Utseende och egenskaper går att ändra när som helst från menyn.</p>`:""}`);

  kopplaSkaparen(forsta);
}

function kopplaSkaparen(forsta){
  const rita=()=>ritaSkapDuk();
  for(const b of document.querySelectorAll(".skapChip"))
    b.onclick=()=>{ SKAP.utkast[b.dataset.f]=+b.dataset.i; visaSkaparen(SKAP.retur); };
  for(const b of document.querySelectorAll(".skapFlik"))
    b.onclick=()=>{ SKAP.flik=+b.dataset.flik; visaSkaparen(SKAP.retur); };
  for(const b of document.querySelectorAll(".egKort"))
    b.onclick=()=>{
      const id=b.dataset.eg, e=SKAP.utkast.egenskaper, i=e.indexOf(id);
      if(i>=0)e.splice(i,1);
      else if(e.length<EGENSKAP_ANTAL)e.push(id);
      else{ const v=document.getElementById("skapVarning");
        if(v)v.textContent=`Du bär redan ${EGENSKAP_ANTAL}. Ta bort en först.`;
        return; }
      visaSkaparen(SKAP.retur);
    };
  const namn=document.getElementById("skapNamnFalt");
  if(namn)namn.oninput=()=>{ SKAP.utkast.namn=namn.value; };

  /* Vägen förbi skaparen. En elva-åring som öppnar spelet ska kunna
     rida, inte fylla i ett formulär först: knappen slumpar ett utseende
     och tar de tre egenskaper som är minst laddade, och allt går att
     ändra sedan. Utan den här knappen är skaparen en registrering. */
  const hoppa=document.getElementById("bSkapHoppa");
  if(hoppa)hoppa.onclick=()=>{
    const u=SKAP.utkast, sl=n=>Math.floor(Math.random()*n);
    for(const k of ["hy","har","harstil","kavaj","byxa","hjalm"])
      if(JAGVAL[k])u[k]=sl(JAGVAL[k].length);
    if(!u.namn)u.namn="Ryttaren";
    if(u.egenskaper.length<EGENSKAP_ANTAL){
      u.egenskaper=EGENSKAP.slice(0,EGENSKAP_ANTAL).map(e=>e.id);
    }
    u.namn=(u.namn||"Ryttaren").trim(); u.skapad=true;
    SPAR.jag={...u}; sparaRyttare(); jagBygg();
    SKAP.utkast=null; SKAP.flik=0;
    if(SKAP.retur==="meny")visaMeny(); else overlay(false);
  };

  const klar=document.getElementById("bSkapKlar");
  if(klar)klar.onclick=()=>{
    const v=document.getElementById("skapVarning");
    if(SKAP.utkast.egenskaper.length<EGENSKAP_ANTAL){
      SKAP.flik=1; visaSkaparen(SKAP.retur);
      const w=document.getElementById("skapVarning");
      if(w)w.textContent=`Välj ${EGENSKAP_ANTAL} egenskaper innan du börjar.`;
      return;
    }
    SKAP.utkast.namn=(SKAP.utkast.namn||"").trim();
    SKAP.utkast.skapad=true;
    SPAR.jag={...SKAP.utkast};
    sparaRyttare();
    jagBygg();                       // ryttarens 3D-delar byggs om i nya färger
    SKAP.utkast=null; SKAP.flik=0;
    if(SKAP.retur==="meny")visaMeny(); else overlay(false);
    if(v)v.textContent="";
  };
  const avb=document.getElementById("bSkapAvbryt");
  if(avb)avb.onclick=()=>{ SKAP.utkast=null; SKAP.flik=0;
    if(SKAP.retur==="meny")visaMeny(); else overlay(false); };

  const duk=document.getElementById("skapDuk");
  if(duk){
    const passa=()=>{ const r=duk.getBoundingClientRect();
      duk.width=r.width*DPR; duk.height=r.height*DPR;
      duk.getContext("2d").setTransform(DPR,0,0,DPR,0,0); rita(); };
    passa(); new ResizeObserver(passa).observe(duk);
  }
  if(forsta&&namn)namn.focus();
}

/* ── Förhandsbilden ───────────────────────────────────────────────
   Ryttaren rakt framifrån, byggd av rätblock precis som i 3D. Måtten
   är samma proportioner som klossRyttarDelar() använder, omräknade till
   dukens höjd — så det du ser här är det du får i sadeln. */
function ritaSkapDuk(){
  const duk=document.getElementById("skapDuk"); if(!duk)return;
  const cx=duk.getContext("2d");
  const W=duk.width/DPR, H=duk.height/DPR;
  const u=SKAP.utkast||jag();
  const f=(lista,i)=>lista[Math.min(Math.max(i|0,0),lista.length-1)][1];
  const HY=f(JAGVAL.hy,u.hy), HAR=f(JAGVAL.har,u.har);
  const KAV=f(JAGVAL.kavaj,u.kavaj), BYX=f(JAGVAL.byxa,u.byxa);
  const HJ=f(JAGVAL.hjalm,u.hjalm);
  const stil=(JAGVAL.harstil[Math.min(Math.max(u.harstil|0,0),3)]||["",""])[1];

  cx.clearRect(0,0,W,H);
  /* Stallgången bakom: en vägg och ett golv, inget mer. */
  const him=cx.createLinearGradient(0,0,0,H);
  him.addColorStop(0,"#3A3038"); him.addColorStop(1,"#241E24");
  cx.fillStyle=him; cx.fillRect(0,0,W,H);
  cx.fillStyle="#4A3B2E"; cx.fillRect(0,H*0.84,W,H*0.16);

  /* Figuren är 1,68 m hög och centrerad. Allt nedan i meter. */
  const mark=H*0.90, hojd=H*0.74, m=hojd/1.68, mx=W*0.5;
  const P=(x,y,w,h,farg)=>{ cx.fillStyle=farg;
    cx.fillRect(mx+x*m-w*m/2, mark-(y+h)*m, w*m, h*m); };
  const kant=(x,y,w,h)=>{ cx.strokeStyle="rgba(0,0,0,.22)"; cx.lineWidth=1;
    cx.strokeRect(mx+x*m-w*m/2, mark-(y+h)*m, w*m, h*m); };

  cx.save();
  cx.globalAlpha=0.30; cx.fillStyle="#000";
  cx.beginPath(); cx.ellipse(mx,mark,0.30*m,0.075*m,0,0,7); cx.fill();
  cx.restore();

  /* Håret först, så att det hamnar BAKOM kroppen. En hästsvans faller
     bakom axeln — ritad efteråt låg den över bröstet i stället. */
  const hjY=1.53;
  /* Framifrån syns svansen och flätan vid sidan av nacken, inte över
     bröstet — därför ligger de utanför huvudets halva bredd. */
  if(stil==="svans"){ P(0,hjY-0.46,0.115,0.40,HAR);
    for(const s of [-1,1])P(s*0.125,hjY-0.30,0.05,0.26,HAR); }
  else if(stil==="flata"){ for(let i=0;i<3;i++)
      P(0, hjY-0.16-i*0.13, 0.105-i*0.018, 0.13, HAR);
    for(const s of [-1,1])for(let i=0;i<3;i++)
      P(s*0.122, hjY-0.16-i*0.10, 0.045,0.10, HAR); }
  else if(stil==="kort"){ P(0,hjY-0.14, 0.235,0.17, HAR);
    for(const s of [-1,1])P(s*0.115,hjY-0.12,0.045,0.16,HAR); }

  /* Stövlar och ben. Vaden är stöveln hela vägen upp, som i sadeln. */
  for(const s of [-1,1]){
    P(s*0.105,0,     0.155,0.44,"#1E1A16");     // stövelskaft
    P(s*0.105,0.44,  0.170,0.34,BYX);           // lår
    kant(s*0.105,0.44,0.170,0.34);
  }
  P(0,0.74, 0.34,0.14, BYX);                    // höften
  /* Bålen med kavaj, krage och knäppning. */
  P(0,0.86, 0.40,0.46, KAV); kant(0,0.86,0.40,0.46);
  cx.fillStyle="rgba(0,0,0,.20)";
  cx.fillRect(mx-0.008*m, mark-1.30*m, 0.016*m, 0.44*m);
  P(0,1.30, 0.30,0.05, "#F4F1E8");              // kragen
  /* Armarna hänger, händerna i handskar. */
  for(const s of [-1,1]){
    P(s*0.255,0.92, 0.11,0.40, KAV); kant(s*0.255,0.92,0.11,0.40);
    P(s*0.255,0.84, 0.115,0.09, "#2B2620");
  }
  /* Huvudet, med luggen under hjälmkanten. */
  P(0,1.35, 0.21,0.22, HY); kant(0,1.35,0.21,0.22);
  for(const s of [-1,1]){ P(s*0.05,1.46, 0.035,0.035, "#241A14"); }
  P(0,1.40, 0.06,0.018, "#B9755E");
  P(0,1.55, 0.225,0.035, HAR);                  // luggen
  /* Hjälmen sist, med klubbens band. */
  P(0,hjY+0.03, 0.245,0.15, HJ); kant(0,hjY+0.03,0.245,0.15);
  P(0,hjY+0.16, 0.13,0.035, KLUBBFARG);
  P(0,hjY+0.02, 0.245,0.030, "rgba(0,0,0,.35)");

  /* Namnet under figuren. */
  const namn=(u.namn||"").trim();
  cx.textAlign="center"; cx.fillStyle="#E6E4DE";
  cx.font=`600 ${Math.max(12,Math.round(H*0.045))}px "IBM Plex Sans", sans-serif`;
  cx.fillText(namn||"Namnlös ryttare", W*0.5, H*0.965);
}

/* ── 3D-delarna byggs om ──────────────────────────────────────────
   Din ryttare ligger i S3.del.jag, eleverna i S3.del. Bara din byggs om
   när färgerna ändras — och de gamla buffrarna lämnas tillbaka först,
   annars läcker ett byte per ändring. */
function jagBygg(){
  if(typeof S3==="undefined"||!S3.redo||typeof GL==="undefined"||!GL.gl)return;
  if(typeof s3BygRyttarSet!=="function")return;
  const D=S3.del.jag=S3.del.jag||{};
  for(const k of RYTTARDELAR)if(D[k]){ GL.fritt(D[k]); D[k]=null; }
  s3BygRyttarSet(D, jagFarg());
}

/* ── Panelen i menyn ──────────────────────────────────────────────
   En rad som visar vem du är och vad du bär, med vägen tillbaka in i
   skaparrutan. Egenskaperna står med sin effekt, inte bara sitt namn —
   du ska aldrig behöva gissa vad ett val gjorde. */
function jagPanelHTML(){
  const j=jag();
  const F=jagFarg();
  const brickor=j.egenskaper.map(id=>{
    const e=EGENSKAP.find(x=>x.id===id); if(!e)return "";
    return `<span class="egBricka" title="${e.effekt} (${e.kalla})">${e.namn}</span>`;
  }).join("");
  const saknas=EGENSKAP_ANTAL-j.egenskaper.length;
  return `<div class="note" id="jagRuta" style="display:flex;gap:14px;align-items:center;flex-wrap:wrap">
    <span class="jagProv" style="--kavaj:${F.kavaj};--hjalm:${F.hjalm};--hy:${F.hy}"></span>
    <span style="flex:1 1 200px;min-width:0">
      <b class="gold">${jagNamn()}</b>
      <span class="dim"> · ${GRUPPNAMN[SPAR.grupp]||SPAR.grupp}</span><br>
      <span class="egRad">${brickor||'<span class="dim">inga egenskaper valda</span>'}${
        saknas>0?`<span class="dim"> · ${saknas} kvar att välja</span>`:""}</span>
    </span>
    <button class="btn ghost" id="bJagAndra" style="padding:6px 12px;font-size:12px">Ändra ryttare</button>
  </div>`;
}
function kopplaJagPanel(){
  const b=document.getElementById("bJagAndra");
  if(b)b.onclick=()=>visaSkaparen("meny");
}
