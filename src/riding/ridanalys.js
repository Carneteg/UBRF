/* RIDANALYSEN — vad den inspelade ritten faktiskt SÅG UT SOM.

   G02-D (#137): "20 m circle: measure route deviation, radius/shape,
   rhythm and balance. Show the actual route and a feasible reference
   route ... Explain the main point of difference."

   Den här filen mäter VÄGEN. Det är information som inte fanns förut:
   ridmodellen publicerar `svangradie` — hur snävt hästen böjer sig just
   nu — men ingen har kunnat säga hur den färdiga volten blev. Med en
   inspelning går det, och det är en riktig mätning av spelarens egen
   ritt, inte ett härlett värde.

   DEN BEDÖMER INGENTING. Inga betyg, inga trösklar, ingen andra
   bedömningsväg vid sidan av ugnetaKvalitet(). Specen är tydlig: "Do not
   create a separate scoring model for replay." Det som står här är
   beskrivningar — meter, sekunder, procent — som UI:t och Ugneta kan
   läsa och sätta ord på.

   MOTOROBEROENDE. Ingen DOM, ingen renderare, ingen Roblox. */

/* Ett tal, eller ingenting. Samma disciplin som resten av spåret.

   OBS null: `Number(null)` är 0, inte NaN. Utan den första raden hade
   ett saknat x blivit koordinaten noll, och analysen hade räknat en
   cirkel på punkter som inte finns. Upptäckt av provet "sampel utan
   position räknas inte som punkter", som annars fick 30 punkter ur en
   post utan en enda position. */
function raTal(v){
  if(v===null||v===undefined)return null;
  const n=typeof v==="number"?v:Number(v);
  return Number.isFinite(n)?n:null;
}

/* Sampeln som har en användbar position. En post kan innehålla hål —
   uppspelningen vägrar interpolera över dem, och analysen räknar inte
   på dem heller. */
function raPunkter(post){
  if(!post||!Array.isArray(post.sampel))return [];
  return post.sampel.filter(p=>raTal(p.x)!==null&&raTal(p.y)!==null);
}

/* ── CIRKELN SPELAREN FAKTISKT RED ──────────────────────────────────
   Algebraisk minsta-kvadrat (Kåsa): den cirkel som ligger närmast alla
   punkterna. Vald för att den är sluten, snabb och deterministisk — en
   iterativ anpassning hade gett olika svar beroende på startgissning,
   och en analys som inte är reproducerbar duger inte som underlag för
   ett omdöme.

   Returnerar null när underlaget inte räcker: färre än tre punkter, en
   rak linje (då finns ingen cirkel), eller en degenererad lösning. Att
   svara "ingen cirkel" är rätt svar när spelaren red rakt fram. */
function anpassaCirkel(punkter){
  const n=punkter.length;
  if(n<3)return null;
  let sx=0,sy=0;
  for(const p of punkter){sx+=p.x;sy+=p.y;}
  const mx=sx/n,my=sy/n;                       // centrera för numerisk stabilitet
  let Suu=0,Suv=0,Svv=0,Suuu=0,Svvv=0,Suvv=0,Svuu=0;
  for(const p of punkter){
    const u=p.x-mx,v=p.y-my;
    Suu+=u*u; Svv+=v*v; Suv+=u*v;
    Suuu+=u*u*u; Svvv+=v*v*v; Suvv+=u*v*v; Svuu+=v*u*u;
  }
  const det=2*(Suu*Svv-Suv*Suv);
  if(!Number.isFinite(det)||Math.abs(det)<1e-12)return null;   // rak linje
  const uc=(Svv*(Suuu+Suvv)-Suv*(Svvv+Svuu))/det;
  const vc=(Suu*(Svvv+Svuu)-Suv*(Suuu+Suvv))/det;
  const r=Math.sqrt(uc*uc+vc*vc+(Suu+Svv)/n);
  if(!Number.isFinite(r)||r<=0)return null;
  return {x:uc+mx, y:vc+my, radie:r};
}

/* Hur långt gick hästen? Bågens längd längs den inspelade vägen. */
function raStracka(punkter){
  let s=0;
  for(let i=1;i<punkter.length;i++)
    s+=Math.hypot(punkter[i].x-punkter[i-1].x, punkter[i].y-punkter[i-1].y);
  return s;
}

/* Målradien för övningen. Tas som ARGUMENT i första hand, så att
   modulen inte har ett dolt beroende till src/larare.js — den laddas
   senare än den här filen och saknas helt när analysen provas isolerat.
   Finns inget argument frågas övningsdefinitionen, och saknas även den
   beskrivs volten utan att jämföras med ett mål. */
function raMal(post,mal){
  const m=raTal(mal);
  if(m!==null)return m;
  if(typeof ovningsGeometri==="function"&&post&&post.ovning){
    const g=ovningsGeometri(post.ovning);
    const gm=g?raTal(g.radie):null;
    if(gm!==null)return gm;
  }
  return null;
}

/* ANALYS AV EN VOLT.

   `radie` är den cirkel ritten faktiskt beskrev. `avvikelse` säger hur
   mycket vägen vandrade in och ut ur den cirkeln — det är formen, inte
   storleken. `varv` säger hur stor del av en hel volt som hanns med;
   ett halvt varv går att beskriva, men inte att kalla en volt.

   Ingen av siffrorna är ett betyg. `mal` finns med enbart för att UI:t
   ska kunna skriva "du red 8,4 m, målet är 10" utan att räkna själv. */
function analysVolt(post,mal){
  const p=raPunkter(post);
  if(p.length<3)return {ok:false, skal:"för få punkter med position", punkter:p.length};
  const c=anpassaCirkel(p);
  if(!c)return {ok:false, skal:"ingen cirkel går att anpassa — vägen är rak", punkter:p.length};

  let varst=0,kvadrat=0;
  for(const q of p){
    const d=Math.abs(Math.hypot(q.x-c.x,q.y-c.y)-c.radie);
    varst=Math.max(varst,d); kvadrat+=d*d;
  }
  const rms=Math.sqrt(kvadrat/p.length);
  const stracka=raStracka(p);
  const varv=c.radie>0?stracka/(2*Math.PI*c.radie):0;

  return {
    ok:true,
    mitt:{x:c.x,y:c.y},
    radie:c.radie,
    mal:raMal(post,mal),
    avvikelse:{varst,rms},
    stracka,
    varv,
    punkter:p.length,
  };
}

/* ANALYS AV EN ÖVERGÅNG.

   Läser postens HÄNDELSER och sampel, inte telemetrins tre tider — de
   är redan mätta av modellen och står i bedömningen. Det den här
   tillför är VAR i ritten övergången skedde och hur farten faktiskt
   förändrades, alltså det som går att visa på en tidslinje.

   Hittas ingen gångartsändring säger den det. En övergång som aldrig
   reds ska inte beskrivas som en snabb sådan. */
function analysOvergang(post){
  const p=raPunkter(post);
  if(p.length<2)return {ok:false, skal:"för få punkter", punkter:p.length};
  const byten=[];
  for(let i=1;i<p.length;i++){
    if(p[i].gangart&&p[i-1].gangart&&p[i].gangart!==p[i-1].gangart)
      byten.push({t:p[i].t, fran:p[i-1].gangart, till:p[i].gangart,
        fartFore:raTal(p[i-1].fart), fartEfter:raTal(p[i].fart)});
  }
  if(!byten.length)return {ok:false, skal:"ingen gångartsändring i posten", punkter:p.length};
  return {ok:true, byten, forsta:byten[0], antal:byten.length, punkter:p.length};
}

/* ── JÄMFÖRELSEN MELLAN TVÅ RITTER ──────────────────────────────────
   Den läsbara väg- och metrikjämförelsen specen kräver som
   reduced-motion-alternativ: siffror i stället för en animerad ghost,
   för den som inte vill eller kan se rörelsen.

   Beskriver skillnaden. Väljer inte vinnare, sätter inget betyg. */
function jamforRitter(fore,nu,mal){
  const a=analysVolt(fore,mal), b=analysVolt(nu,mal);
  if(!a.ok||!b.ok)return {ok:false, skal:a.ok?b.skal:a.skal};
  return {
    ok:true,
    radie:{fore:a.radie, nu:b.radie, diff:b.radie-a.radie, mal:b.mal},
    avvikelse:{fore:a.avvikelse.rms, nu:b.avvikelse.rms, diff:b.avvikelse.rms-a.avvikelse.rms},
    varv:{fore:a.varv, nu:b.varv},
    stracka:{fore:a.stracka, nu:b.stracka},
  };
}

/* En rad på svenska om voltens FORM — den mening UI:t kan visa bredvid
   siffrorna. Den påstår ingenting om kvalitet; den beskriver.

   Tröskeln 0,5 m är en LÄSBARHETSGRÄNS, inte ett betygskriterium: under
   en halvmeter är skillnaden inte värd en mening. Den ändrar ingen
   bedömning och står med flit inte i UGNETA_KVALITET. */
const RIDANALYS_MARKBAR_M = 0.5;
function voltIOrd(analys){
  if(!analys||!analys.ok)return null;
  const mal=analys.mal;
  const bitar=[`Din volt blev ${analys.radie.toFixed(1)} m i radie`];
  if(mal!==null&&mal!==undefined){
    const d=analys.radie-mal;
    if(Math.abs(d)>=RIDANALYS_MARKBAR_M)
      bitar.push(d>0?`— större än de ${mal} m övningen ber om`
                    :`— mindre än de ${mal} m övningen ber om`);
    else bitar.push(`— nära de ${mal} m övningen ber om`);
  }
  return bitar.join(" ")+`. Formen höll sig inom ${(analys.avvikelse.rms).toFixed(2)} m från cirkeln.`;
}

if(typeof window!=="undefined"){
  window.analysVolt=analysVolt;
  window.analysOvergang=analysOvergang;
  window.jamforRitter=jamforRitter;
}
