/* ══════════════════════════════════════════════════════════════════
   RIDLÄRAREN — en sak i taget, hela lektionen.

   Så här såg hon ut innan: ridlararRop() tog den lägsta siffran på
   utbildningsskalan just den bildrutan, läste upp en färdig replik ur en
   lista, och gjorde om det var trettonde sekund. Byttes den lägsta
   siffran bytte hon ämne mitt i meningen.

   Det är inte en instruktör. Det är en felrapport, och det är precis vad
   en dålig ridlärare gör: rabblar allt som är fel tills eleven slutar
   höra något alls.

   En riktig instruktör gör tvärtom. Hon BESTÄMMER en sak när hon ser er
   komma in på banan, säger den, och ändrar sig inte på fyrtio minuter.
   Rider du med spända händer och tappar takten samtidigt säger hon
   ingenting om takten — takten kommer när händerna släpper. Säger hon
   båda får du ingendera.

   Fyra saker gör henne till en lärare i stället för en mätare:

     FOKUS      Ett tema per lektion, valt ur din svagaste färdighet och
                förra passets historik — inte ur bildrutans lägsta tal.
     MINNE      Hon vet vad ni jobbade med förra gången och säger det.
     ATTRIBUT   Hon skiljer dig från hästen. "Det där var hon, inte du"
                är den viktigaste meningen på hela lektionen.
     BERÖM      Sällan, och exakt. Beröm var tionde sekund betyder inget;
                beröm när något faktiskt hände lär dig känna igen det
                själv nästa gång. Målet är att du ska sluta behöva henne.

   Säkerhet ligger inte här. Den avbryter allt och har sin egen röst
   (avståndsregeln i game.js) — en tillsägelse om takten och ett stopp
   ska aldrig låta likadant.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* ── Temana ───────────────────────────────────────────────────────
   `vikt` läser ryttarens FÄRDIGHETER och dagens häst, inte ögonblickets
   siffror — fokus ska väljas en gång och hålla. `bra` avgör om du gör
   det just nu; det styr både beröm och när temat får släppas.

   Varje `bra` kräver att det syns på HÄSTEN — en siffra ur
   utbildningsskalan — och inte bara att en tangent står i rätt läge. Med
   bara tangentkravet räckte det att hålla tygeln stilla i bandet för att
   få andelen 1,00 och tre beröm: hon berömde att spelaren tryckte rätt,
   inte att hästen svarade. Passets betyg låg samtidigt på 0,11, och hon
   sa både "det satt" efteråt och "samma sak som förra gången" nästa
   pass. Kraven är kalibrerade så att de går att nå men inte gratis.

   `ratta` sägs när det inte sitter, `beroem` när det gör det. Båda är
   listor så att hon inte upprepar sig ordagrant. */
const FOKUS=[
  {id:"hand", namn:"Handen",
   inledning:h=>`Idag tittar vi på handen. Allt annat får vänta — får du `
     +`förbindelsen mjuk kommer resten efter.`,
   vikt:(f)=>1-f.hand,
   bra:()=>{const t=G.aids?G.aids.tygel:0;
     return t>K.TYGEL_BAND_MIN&&t<K.TYGEL_BAND_MAX&&G.ride.mjukhet>0.62
       &&G.ride.skala.kontakt>0.45;},
   ratta:["Mjuka händer. Du hänger i munnen.",
     "Jämn förbindelse — inte ryck och släpp.",
     "Tänk att du håller två fågelungar. Så mycket, inte mer.",
     "Släpp med handen och behåll skänkeln. Tvärtom mot vad det känns."],
   beroem:["Där. Kände du att hon blev mjuk i käken?",
     "Så där ser en förbindelse ut. Kom ihåg hur det känns.",
     "Nu bär hon sig själv. Det är din hand som gjorde det."]},

  {id:"sits", namn:"Sitsen",
   inledning:h=>`Idag är det sitsen. Sitt still, så slutar ${h.namn} `
     +`gissa vad du menar.`,
   vikt:(f)=>1-f.sits,
   bra:()=>G.ride.mjukhet>0.72&&G.ride.spanning<0.45,
   ratta:["Sitt still. Varje rörelse du gör är ett besked till henne.",
     "Axel, höft, häl i lodlinje. Känn efter var du sitter.",
     "Du kastar med kroppen i övergången. Låt henne komma till dig.",
     "Djupare i sadeln — sitt ner i henne, inte på henne."],
   beroem:["Nu satt du still. Ser du hur mycket lugnare hon blir?",
     "Där höll du lodlinjen hela långsidan.",
     "Bra sits. Det är den som gör allt annat möjligt."]},

  {id:"framat", namn:"Framåtbjudningen",
   inledning:h=>`Idag rider vi framåt. ${h.namn} ska gå för din skänkel, `
     +`inte för att du tjatar.`,
   vikt:(f,h)=>0.55+0.45*(1-(h.framatbjudning||0.5))-0.30*f.sits,
   bra:()=>{const b=(typeof tempoBand==="function")&&tempoBand(
     (G.moment&&G.moment.gangart)||G.ride.gangart,G.grupp);
     const iband=b?G.ride.tempo>=b.min&&G.ride.tempo<=b.max:G.ride.tempo>0.9;
     return iband&&G.ride.skala.schvung>0.40;},
   ratta:["Mer skänkel. Rid framåt först, forma sedan.",
     "Bakbenen sover. Driv in i handen.",
     "Håll takten — du travar fortare på långsidan.",
     "En gång med skänkeln, tydligt. Inte tio gånger halvt."],
   beroem:["Nu går hon för dig. Känn skillnaden.",
     "Där kom bakbenen med.",
     "Jämn takt hela varvet. Precis så."]},

  {id:"timing", namn:"Timingen",
   inledning:h=>`Idag jobbar vi med när du ber, inte hur mycket. `
     +`${h.namn} svarar på det du gör just nu.`,
   vikt:(f)=>1-f.kansla,
   bra:()=>G.ride.skala.samling>0.34,
   ratta:["Halvhalt före hörnet, inte i det.",
     "Förbered övergången ett par steg innan. Sitt ner, andas, be.",
     "Balansera om henne innan du vänder.",
     "Be en gång och vänta på svaret. Hon behöver en sekund."],
   beroem:["Den halvhalten satt precis rätt.",
     "Där bad du i rätt ögonblick. Det är timing.",
     "Nu väntade du på svaret i stället för att fråga igen."]},

  {id:"lugn", namn:"Lugnet",
   inledning:h=>`${h.namn} är en känslig individ. Idag handlar allt om `
     +`att hålla henne lugn — resten kommer av sig självt.`,
   vikt:(f,h)=>0.35+0.75*(h.kanslighet||0.5)-0.25*f.sits,
   bra:()=>G.ride.spanning<0.30,
   ratta:["Hon är spänd. Ge lite med handen och andas själv.",
     "Långsammare. Du har all tid i världen.",
     "Låt henne sträcka sig framåt-nedåt ett varv.",
     "Ditt lugn smittar. Släpp axlarna."],
   beroem:["Där släppte hon. Bra jobbat.",
     "Nu är hon mjuk i ryggen. Det var du som gjorde det.",
     "Se — hon andas ut. Det där är förtroende."]},

  {id:"vagen", namn:"Vägen",
   inledning:h=>`Idag rider vi vägen. Bestäm var ni ska gå innan ni går `
     +`dit — ${h.namn} följer den som vet.`,
   vikt:(f)=>0.45+0.35*(1-f.kansla),
   bra:()=>G.ride.skala.rakriktning>0.45,
   ratta:["Rid volten rund, inte som en potatis.",
     "Hon faller in i hörnet — inre skänkel.",
     "Styr med kroppen och blicken, inte med handen.",
     "Titta dit du ska. Hon går dit du tittar."],
   beroem:["Rund volt. Precis så.",
     "Nu red du vägen, inte hindret.",
     "Rak på medellinjen. Det är svårare än det ser ut."]},
];

/* ── Lektionens tillstånd ─────────────────────────────────────────
   `start` är temat hon valde när ni kom in på banan. `fokus` kan byta
   under passet (se nedan), men det är `start` som hör hemma i
   historiken och i efter-passet — annars skulle en lektion som gick så
   bra att hon hann byta ämne registreras som en lektion om det andra
   ämnet, och nästa pass skulle ta upp fel tråd.

   `bratid`/`tid` är underlaget för omdömet efteråt: andelen av passet
   du faktiskt gjorde det hon bad om. */
const LARARE={fokus:null, start:null, sagt:"", cd:0, brasedan:0, beromt:0,
  bytt:0, attributCd:0, upprepad:null, inled:false, bratid:0, tid:0};

function lararNollstall(){
  LARARE.fokus=null; LARARE.start=null; LARARE.sagt=""; LARARE.cd=0;
  LARARE.brasedan=0; LARARE.beromt=0; LARARE.bytt=0; LARARE.attributCd=0;
  LARARE.upprepad=null; LARARE.inled=false; LARARE.bratid=0; LARARE.tid=0;
}

/* Väljer dagens tema. Görs EN gång, vid lektionens start.

   Historiken väger in: jobbade ni med samma sak förra gången och det
   inte satt, tar hon det igen — och säger att hon gör det. Satt det,
   går hon vidare. Det är skillnaden mellan en lärare och en främling. */
function lararValjFokus(){
  const f=(typeof fard==="function")?fard():{sits:.3,hand:.3,kansla:.3,skotsel:.3};
  const h=HORSES[G.hastId]||{};
  const forra=(SPAR.historik&&SPAR.historik[0])||null;
  /* Vad "gick bra" betyder: hur mycket av FÖRRA passet du höll förra
     temat — inte vad passet fick i snitt. Ett pass kan vara svagt i sin
     helhet och ändå ha löst just den sak hon bad om, och det är den
     saken hon minns. Äldre spar saknar talet; då duger snittet. */
  const forraOk=forra
    ? (typeof forra.fokusAndel==="number"?forra.fokusAndel>=0.55:forra.snitt>=0.66)
    : false;
  let bast=null,bastV=-9;
  for(const F of FOKUS){
    let v=F.vikt(f,h);
    /* Samma tema som förra passet får en knuff uppåt om det gick dåligt
       och en knuff nedåt om det gick bra. */
    if(forra&&forra.fokus===F.id)v+=forraOk?-0.30:0.22;
    v+=(Math.random()-0.5)*0.06;          // två jämna teman ska inte låsa sig
    if(v>bastV){bastV=v;bast=F;}
  }
  LARARE.fokus=bast; LARARE.start=bast;
  LARARE.upprepad=!!(forra&&forra.fokus===bast.id&&!forraOk);
  LARARE.inled=true;                    // sägs av lararSteg när passet börjat
  return bast;
}

/* Repliken vid lektionens början. */
function lararInledning(){
  const F=LARARE.fokus||lararValjFokus();
  const h=HORSES[G.hastId]||{namn:"hon"};
  if(LARARE.upprepad)
    return `Samma sak som förra gången: ${F.namn.toLowerCase()}. `
      +`Vi lämnar den inte förrän den sitter.`;
  return F.inledning(h);
}

/* Hämtar en replik ur en lista utan att ta samma två gånger i rad. */
function lararRad(lista){
  if(!lista||!lista.length)return "";
  let r=lista[Math.floor(Math.random()*lista.length)];
  if(lista.length>1&&r===LARARE.sagt)
    r=lista[(lista.indexOf(r)+1)%lista.length];
  LARARE.sagt=r;
  return r;
}

/* ── Anropas varje bildruta under lektionen ───────────────────────
   Returnerar en replik när det är dags att säga något, annars "". */
function lararSteg(dt){
  if(!G.ride||!LARARE.fokus)return "";
  const F=LARARE.fokus;
  LARARE.cd-=dt; LARARE.attributCd-=dt;

  /* Dagens tema sägs en gång, som första repliken på banan. Den ligger
     här och inte i startaLektion för att momentets egen text hinner
     sägas först — sägs de i samma bildruta skriver den ena över den
     andra och spelaren får aldrig veta vad passet handlar om. */
  if(LARARE.inled){
    LARARE.inled=false; LARARE.cd=13;
    return lararInledning();
  }

  /* Håller du temat? Räknas i sträck — en tillfällig träff är ingen
     prestation, femton sekunder är det. */
  const bra=!!F.bra();
  LARARE.brasedan=bra?LARARE.brasedan+dt:0;
  LARARE.tid+=dt; if(bra)LARARE.bratid+=dt;

  /* Det där var hon, inte du. Hästens egen skygghet och dagsform får
     inte läggas på ryttaren — en nybörjare som tror att allt är hennes
     fel slutar rida, och en van ryttare som skyller allt på hästen
     slutar lära sig. */
  if(LARARE.attributCd<=0&&G.ride.spanning>0.55){
    const h=HORSES[G.hastId]||{};
    const hennes=(h.skygghet||0)>0.28||G.dagsform<0.55;
    if(hennes){
      LARARE.attributCd=26; LARARE.cd=Math.max(LARARE.cd,7);
      return lararRad([
        `Det där var ${h.namn||"hon"}, inte du. Sitt still och rid vidare.`,
        `Hon spökar. Det gör hon — låt henne, och fortsätt.`,
        `Inte ditt fel. Hon är på tå idag. Håll bara i vägen.`]);
    }
  }

  /* Beröm: sällan, och bara när något faktiskt hållit i sig.

     Tjugo sekunder i sträck, och sedan tyst i tjugofyra. Med fjorton och
     sexton — de tal som stod här först — hann en ryttare som red rätt få
     tre beröm på femtio sekunder och blev bytt på tema efter sjuttio.
     Då är beröm ingen belöning längre utan en kvittens per långsida, och
     hela poängen med att hålla ETT tema hela lektionen försvann. */
  if(LARARE.brasedan>20&&LARARE.beromt<3){
    LARARE.brasedan=0; LARARE.beromt++; LARARE.cd=24;
    return lararRad(F.beroem);
  }

  if(LARARE.cd>0)return "";
  LARARE.cd=12+Math.random()*5;

  /* Sitter det efter tre beröm och en hel lektion — då först byter hon
     tema, och säger att hon gör det. Det är en riktig undervisningsbeat:
     "bra, nu tittar vi på något annat". */
  /* …och inte förrän lektionen är ridd ett tag. Ett tema man släppte
     efter en dryg minut var aldrig dagens tema. */
  if(LARARE.beromt>=3&&LARARE.bytt<1&&bra&&LARARE.tid>210){
    LARARE.bytt++;
    const gammalt=F.namn.toLowerCase();
    const kvar=FOKUS.filter(x=>x.id!==F.id);
    LARARE.fokus=kvar[Math.floor(Math.random()*kvar.length)];
    LARARE.beromt=0; LARARE.brasedan=0;
    return `${gammalt[0].toUpperCase()+gammalt.slice(1)} sitter. `
      +`Nu tittar vi på ${LARARE.fokus.namn.toLowerCase()} i stället.`;
  }
  if(bra)return "";                      // går det bra ska hon vara tyst
  return lararRad(F.ratta);
}

/* Vad hon tittar på just nu — för HUD:en. */
function lararFokusId(){ return LARARE.fokus?LARARE.fokus.id:null; }
function lararFokusNamn(){ return LARARE.fokus?LARARE.fokus.namn:""; }
/* Vad passet HANDLADE om — för historiken och efter-passet. */
function lararDagensId(){ return LARARE.start?LARARE.start.id:null; }
function lararAndel(){ return LARARE.tid>4?LARARE.bratid/LARARE.tid:0; }

/* ── Omdömet efteråt ──────────────────────────────────────────────
   En mening om dagens tema, i samma enhet som hon undervisade i: hur
   stor del av passet du gjorde det hon bad om. Den ska gå att läsa som
   ett besked om nästa gång, inte som ett betyg — därför säger den alltid
   vad som händer härnäst.

   Ingen siffra utan riktning: "du höll det 41 %" lär ingen någonting. */
function lararOmdome(){
  if(!LARARE.start||LARARE.tid<8)return "";
  const namn=LARARE.start.namn.toLowerCase();
  const a=lararAndel();
  if(LARARE.bytt>0)
    return `Dagens tema var <b>${namn}</b>, och den satt så pass att vi hann `
      +`gå vidare till ${(LARARE.fokus?LARARE.fokus.namn:"nästa sak").toLowerCase()} `
      +`på slutet. Den delen är avklarad.`;
  if(a>=0.62)
    return `Dagens tema var <b>${namn}</b>, och du höll den `
      +`större delen av passet. Nästa gång tittar vi på något annat.`;
  if(a>=0.30)
    return `Dagens tema var <b>${namn}</b>. Den kom och gick — du hittar `
      +`den, men tappar den i övergångarna. Vi tar den en gång till.`;
  return `Dagens tema var <b>${namn}</b>, och dit kom vi inte idag. `
    +`Det gör inget: vi lämnar den inte förrän den sitter, så den står `
    +`kvar till nästa pass.`;
}
