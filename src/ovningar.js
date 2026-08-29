/* ══════════════════════════════════════════════════════════════════
   TRÄNINGSBOKEN — övningsbank och hästkunskap.
   Strukturen följer Markus Holsts Ridhandbok (markusholst.com/
   ridhandboken); texterna är egna sammanfattningar, inte citat.
   Varje övning bär vikter mot utbildningsskalan så att modellen
   kan bedöma den — samma skala som lektionen redan använder.
   Ingen databas behövs: spelet är en fil, banken är data.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const KUNSKAP=[
  {id:"sakerhet", titel:"Säkerhet och hästhantering",
   text:"Rätt hantering av hästen är den viktigaste olycksförebyggande åtgärden som finns. Gå aldrig rakt bakom en häst, led i grimskaft med handen nära grimman, och låt hästen veta var du är. Stallregler finns för hästens skull, inte för ordningens.",
   kalla:"Ridhandboken del 2"},
  {id:"sprak", titel:"Ryttarens och hästens språk",
   text:"All inverkan bygger på att hästen går undan för tryck. Fem grundkommandon räcker för att rida allt: reglera tempot, reglera gångarten, flytta framdelen i sidled, flytta bakdelen i sidled och böj hästen — ett i taget, med en hjälp i taget. Skruva ner bakgrundsbruset: en hjälp som ges hela tiden slutar betyda något.",
   kalla:"Ridhandboken del 5"},
  {id:"sits", titel:"Sitsen",
   text:"Den lodräta sitsen är utgångsläget: axel–höft–häl i lodlinje, underskänkeln stilla. Lättridning avlastar hästens rygg i trav — och du ska sitta på rätt diagonal. Den lätta sitsen (fältsits) hör hemma över bommar, i hoppning och i terräng.",
   kalla:"Ridhandboken del 6"},
  {id:"inverkan", titel:"Inverkan: hand, skänkel, spö",
   text:"Handen hör till en mjuk och jämn förbindelse — tygeltag är korta, aldrig hängande. Skänkeln driver; den som ligger på i varje steg blir brus som hästen lär sig sortera bort. Spöet är en förstärkning av skänkeln, inget straff — och på en spörädd häst låter du bli det helt.",
   kalla:"Ridhandboken del 7"},
  {id:"form", titel:"Hästens form",
   text:"Framåt–nedåt — lång hals, låg nos — är kontrollformen som alltid ska finnas ett tygeltag bort, och den första form unghästen lär sig. Arbetet strävar sedan framåt–uppåt. Eftergiften är kvittot: ger du efter med handen ska hästen söka bettet och bära sig själv, inte falla isär.",
   kalla:"Ridhandboken del 8"},
  {id:"overgangar", titel:"Övergångar",
   text:"Det som skiljer den utbildade hästen från den ogymnastiserade är övergångarna den klarar. Byt, byt och byt igen — gångart, tempo, form — tills hästen väntar på nästa fråga i stället för att somna i den förra. Halvhalten är omdiskuterad som begrepp; det viktiga är omtaget: gör hästen uppmärksam, balansera om, släpp fram.",
   kalla:"Ridhandboken del 10"},
  {id:"rorelser", titel:"Rörelserna",
   text:"Rörelserna delas i lösgörande — som framdelsvändning och skänkelvikning — och samlande, som piruetterna. De lösgörande öppnar kroppen och kan ridas tidigt; de samlande kräver bärighet men kan förberedas långt innan hästen är samlad. Samlade gångarter är beredskap: hästen är redo att göra något annat i varje steg.",
   kalla:"Ridhandboken del 11"},
  {id:"skolorna", titel:"Sidvärtsrörelserna och skolorna",
   text:"Fyra sidvärtsrörelser: skänkelvikning, öppna, sluta och förvänd sluta — de tre sista kallas skolorna. I öppnan rider du den böjda hästen ut från innerskänkeln; half-pass heter här diagonalsluta. Skolorna är lekmaterial: byt mellan dem, behåll riktningen men byt böjning, och hästen blir genomsläpplig på riktigt.",
   kalla:"Ridhandboken del 13"},
  {id:"galopp", titel:"Galopparbete",
   text:"Galoppfattningen beskrivs olika av alla klassiska mästare — mysteriet löses med balans: målet är att hästen kan fatta galopp direkt ur varje gångart och tempo. Kontragalopp med behållen böjning är grunden för goda galoppombyten. Rid serpentiner med byten mellan galopp och trav, och fatta galopp på tiometersvolter på långsidan.",
   kalla:"Ridhandboken del 14"},
  {id:"utrustning", titel:"Utrustning",
   text:"Sadeln ska passa hästen — en pad som döljer felpassning är en tillfällig lösning, ingen permanent. Träns heter det bara om det bär ett tränsbett; annars är det betsel eller huvudlag. Kolla sömmar, spännen och bettets läge varje gång du tränsar: skav i mungipan syns först när det redan gjort ont.",
   kalla:"Ridhandboken del 15"},
  {id:"markarbete", titel:"Longering och arbete för hand",
   text:"Longera med syfte — inte för att trötta ut hästen och inte för att tvinga fram en 'form'. Arbete för hand lär hästen böjning i stillastående, flyttningar och så småningom de långsamma rörelserna; mycket av det svåra kan och bör grundläggas från marken.",
   kalla:"Ridhandboken del 17–18"},
];

/* Övningar. skala = vikter mot utbildningsskalan (bedömningen),
   gangart = var den rids, niva = från vilken grupp den ges. */
const OVNINGAR=[
  {id:"langtygel", namn:"Skritt på lång tygel", gangart:"skritt", niva:"alla",
   syfte:"Lösgörande start och avslut. Hästen får sträcka halsen framåt–nedåt och titta sig omkring; du kontrollerar att kontrollformen finns där.",
   utforande:["Skritta på fyrkantspåret med tygeln så lång att nosen når framåt–nedåt.",
     "Behåll rak väg med sätet och blicken, inte med handen.",
     "Ta upp tyglarna stegvis utan att takten ändras."],
   fel:["Hästen drar sig ihop när tyglarna tas upp — du tog upp för fort.",
     "Slingrande väg: styr med kroppen, inte tygeln."],
   skala:{takt:.4,losgjordhet:.5,kontakt:.1}},
  {id:"halt_skritt", namn:"Övergångar halt–skritt", gangart:"skritt", niva:"alla",
   syfte:"Ren lydnad. De lägsta dressyrprogrammen är lydnadsövningar — och de behöver ingen bana: en grusväg duger.",
   utforande:["Gör halt vid en bestämd punkt — bestäm punkten INNAN.",
     "Stå kvar tills du bestämmer något annat. Stillastående är en övning.",
     "Skritta fram utan att hästen faller åt sidan."],
   fel:["Halten smyger fram över flera steg — begär den tydligare.",
     "Hästen backar i halten: för mycket hand, för lite säte."],
   skala:{takt:.2,kontakt:.3,rakriktning:.3,samling:.2}},
  {id:"trav_skritt", namn:"Övergångar trav–skritt–trav", gangart:"trav", niva:"alla",
   syfte:"Byt, byt och byt igen. Övergångarna gymnastiserar mer än momenten mellan dem och håller hästen på hjälperna.",
   utforande:["Rid trav–skritt vid varje halvt varv, sedan vid varje kortsida.",
     "Förbered varje övergång ett par steg innan — sitt ner, andas, be.",
     "Nedåtgående övergång utan att hästen faller på framdelen."],
   fel:["Hästen 'ramlar' ner i skritt: mer skänkel IN i övergången.",
     "Traven rusar iväg efteråt — halvera tempot med sätet direkt."],
   skala:{takt:.3,losgjordhet:.2,kontakt:.2,schvung:.3}},
  {id:"storvolt", namn:"Stora volten, 20 m", gangart:"trav", niva:"alla",
   syfte:"Böjning och takt. Volten är rund bara om hästen är böjd runt innerskänkeln — annars är den en potatis.",
   utforande:["Rid en 20-metersvolt vid A eller C.",
     "Inre skänkel böjer, yttre tygel bestämmer voltens storlek.",
     "Samma takt hela varvet — räkna högt om det behövs."],
   fel:["Volten blir äggformad mot ingången: hästen drar hemåt.",
     "Inre tygeln gör böjningen — då faller ytterbogen ut."],
   skala:{takt:.3,losgjordhet:.2,rakriktning:.4,kontakt:.1}},
  {id:"serpentin", namn:"Serpentin, tre bågar", gangart:"trav", niva:"grupp2",
   syfte:"Ridvägar och omböjning. Varje båge är en ny volt med ny böjning — och ett nytt tillfälle att fråga om hästen faktiskt lyssnar.",
   utforande:["Börja vid A, rid tre lika stora bågar till C.",
     "Byt böjning över medellinjen — några raka steg mitt i.",
     "I lättridning: byt diagonal i varje bågbyte."],
   fel:["Bågarna olika stora — bestäm vändpunkterna i förväg.",
     "Omböjningen sker i handen i stället för i kroppen."],
   skala:{rakriktning:.4,losgjordhet:.3,takt:.3}},
  {id:"framdelsvandning", namn:"Framdelsvändning", gangart:"halt", niva:"grupp2",
   syfte:"DEN grundläggande övningen för att lära bakdelen flytta i sidled — det finns ingen lika bra för något annat.",
   utforande:["Gör halt. Flytta bakdelen steg för steg runt framdelen.",
     "Inre skänkeln bakom gjorden frågar; handen hindrar bara framåtsteg.",
     "Ett steg i taget — belöna varje korrekt steg med paus."],
   fel:["Hästen går framåt: mer hand är fel svar, be om färre steg.",
     "Snurrar för fort — då flyttar hästen sig undan, inte på hjälp."],
   skala:{rakriktning:.3,kontakt:.2,samling:.3,losgjordhet:.2}},
  {id:"skankelvikning", namn:"Skänkelvikning på diagonalen", gangart:"skritt", niva:"grupp2",
   syfte:"Första sidvärtsrörelsen: hästen rak, lätt ställd från rörelseriktningen, går undan för skänkeln.",
   utforande:["Vänd upp på diagonalens linje i skritt.",
     "Be hästen flytta sig i sidled mot spåret — framdel och bakdel samtidigt.",
     "Gör halt mitt i, stå, och fortsätt för samma skänkel."],
   fel:["Hästen blir öppen som en sax: för mycket sidled, för lite framåt.",
     "Böjning i halsen i stället för ställning — släpp inre tygeln."],
   skala:{rakriktning:.35,losgjordhet:.25,kontakt:.2,takt:.2}},
  {id:"stromsholm", namn:"Strömsholmsövningen", gangart:"skritt", niva:"grupp3",
   syfte:"Kedjan skänkelvikning → framdelsvändning → skänkelvikning tillbaka, allt för samma skänkel. En hel lektion i en övning.",
   utforande:["Skänkelvik på diagonalen i skritt.",
     "Halt — framdelsvändning för samma skänkel.",
     "Skänkelvik tillbaka till spåret, fortfarande samma skänkel."],
   fel:["Bytt skänkel halvvägs — då tränade du två halva övningar.",
     "Vändningen rusar: dela den i enskilda steg igen."],
   skala:{rakriktning:.3,losgjordhet:.25,samling:.25,kontakt:.2}},
  {id:"oppna", namn:"Öppna längs långsidan", gangart:"skritt", niva:"grupp3",
   syfte:"Första skolan: den böjda hästen rids ut från innerskänkeln. Bogarna in från spåret, bakbenen kvar — hästen tittar bort från vägen den går.",
   utforande:["Kom ur hörnet med böjning som på en volt.",
     "Behåll böjningen och för framdelen ett spår in i banan.",
     "Rid framåt–sidvärts längs långsidan; avsluta med att rida rakt fram."],
   fel:["Bara halsen viks in — böjningen ska gå genom hela kroppen.",
     "Tempot dör: öppnan är en framåtrörelse, inte en broms."],
   skala:{rakriktning:.3,samling:.25,losgjordhet:.25,schvung:.2}},
  {id:"kontrabojning", namn:"Kontraböjning på spåret", gangart:"trav", niva:"grupp3",
   syfte:"Rid med böjning åt fel håll — det tränar din hjälpgivning, hästens hjälpförståelse, och lägger grunden för kontragalopp och ombyten.",
   utforande:["På fyrkantspåret i skritt: ställ om hästen utåt, behåll vägen.",
     "Samma sak i trav. Vägen bestäms av dig, inte av böjningen.",
     "Växla inner- och ytterböjning på långsidan utan att spåret ändras."],
   fel:["Hästen följer böjningen ut från spåret — sätet håller vägen.",
     "Omställningen sker med ryck: den ska ta flera steg."],
   skala:{rakriktning:.4,kontakt:.3,losgjordhet:.3}},
  {id:"galoppfattning", namn:"Galoppfattning i hörnet", gangart:"galopp", niva:"grupp2",
   syfte:"Hörnet böjer hästen åt rätt håll och gör fattningen nästan självklar. Målet på sikt: kunna fatta ur varje gångart, i varje tempo.",
   utforande:["Rid in i hörnet i arbetstrav med inre böjning.",
     "Yttre skänkeln bakom gjorden frågar; sitt ner och släpp fram språnget.",
     "Galoppera långsidan, fånga i trav före nästa kortsida."],
   fel:["Rusad trav före fattningen — då blev det fel galopp eller ingen.",
     "Fel galopp: fånga i trav direkt, gör om i nästa hörn i stället för att tvinga."],
   skala:{schvung:.35,takt:.25,losgjordhet:.2,kontakt:.2}},
  {id:"voltfattning", namn:"Galoppfattning på tiometersvolt", gangart:"galopp", niva:"grupp4",
   syfte:"Volten på långsidan ger tre fattningspunkter — i början, mitten och slutet. Precisionen är själva övningen.",
   utforande:["Rid en tiometersvolt mitt på långsidan i trav.",
     "Fatta galopp på voltens första fjärdedel. Fånga. Gör om — fatta i mitten.",
     "Tredje varvet: fatta i voltens sista fjärdedel, rakt ut på spåret."],
   fel:["Volten växer när du tänker på fattningen — vägen först, alltid.",
     "Fattningen 'händer' i stället för att bestämmas: bestäm punkten högt."],
   skala:{schvung:.3,rakriktning:.3,samling:.2,takt:.2}},
  {id:"galoppserpentin", namn:"Serpentin med galopp och trav", gangart:"galopp", niva:"grupp4",
   syfte:"Varannan båge i galopp, varannan i trav. Övergångarna mitt i vägbytet gör hästen kvick på hjälperna utan att bli het.",
   utforande:["Serpentin tre bågar: galopp i första, trav över medellinjen, ny fattning i andra.",
     "Fattningen ska komma ur bågens böjning — inte ur fart.",
     "Sista bågen: behåll traven och rid framåt–nedåt som belöning."],
   fel:["Ombytet blir stressigt: gör bågarna större, inte tempot lägre.",
     "Traven mellan bågarna rusar — sätt dig och vänta ut den."],
   skala:{schvung:.3,takt:.3,losgjordhet:.2,rakriktning:.2}},
  {id:"kontragalopp", namn:"Kontragalopp på stora vägar", gangart:"galopp", niva:"grupp5",
   syfte:"Galopp på 'fel' ben med behållen böjning — grunden för galoppombytet och det bästa balansprovet som finns.",
   utforande:["Fatta vänster galopp, rid en flack bågvändning ut från spåret och tillbaka.",
     "Behåll ställningen över fattningsbenet hela vägen.",
     "Stora, mjuka vägar först; trängre vändningar allteftersom balansen bär."],
   fel:["Hästen byter själv — vägarna för trånga för dagsformen.",
     "Ombytt böjning: då är det bara fel galopp, inte kontragalopp."],
   skala:{rakriktning:.3,samling:.3,takt:.2,schvung:.2}},
  {id:"halvhalter", namn:"Omtag före hörnen", gangart:"trav", niva:"grupp3",
   syfte:"Kärt barn har många namn — kalla det halvhalt eller omtag: gör hästen uppmärksam, balansera om, släpp fram. Före varje hörn, tills det sker av sig självt.",
   utforande:["Tre steg före hörnet: sitt upp, slut hästen ett ögonblick, ge efter.",
     "Hörnet rids som en kvarts volt — inte som en kana.",
     "Ut ur hörnet: kontrollera att tempot är exakt det du hade innan."],
   fel:["Omtaget blir en broms som hänger kvar — eftergiften är halva övningen.",
     "Bara hand: utan säte och skänkel är det ett ryck, inget omtag."],
   skala:{samling:.4,kontakt:.3,takt:.3}},
  {id:"ridvagar", namn:"Rid vägen — banan utan hinder", gangart:"galopp", niva:"hoppgrupp",
   syfte:"Hoppningens hemlighet: rid vägen, inte hindret. Hela banan i galopp med exakta vändpunkter — bommarna är oväsentliga, linjen är allt.",
   utforande:["Gå banan till fots först. Bestäm varje vändpunkt.",
     "Rid banans väg i galopp utan att hoppa — förbi varje hinder på anridningslinjen.",
     "Samma tempo hela vägen: banans takt sätts före första vändningen."],
   fel:["Blicken på hindret drar dig ur vägen — titta dit du ska, inte på bommen.",
     "Tempot stiger för varje 'hinder': fång med omtag i varje sväng."],
   skala:{takt:.3,rakriktning:.3,schvung:.2,samling:.2}},
];

/* Lektionens moment pekar in i banken. */
const MOMENT_OVNING={
  skritt:"langtygel", uppvarmning:"trav_skritt", losgorande:"storvolt",
  galopp:"galoppfattning", bana:"ridvagar",
};

/* ── Träningsboken som overlay ────────────────────────────────── */
function visaTraningsbok(fran){
  const tillbaka=fran||"meny";
  const kap=KUNSKAP.map(K=>`<button class="tb-rad" data-k="${K.id}">${K.titel}</button>`).join("");
  const ovn=OVNINGAR.map(o=>`<button class="tb-rad" data-o="${o.id}">
    ${o.namn} <span class="dim">· ${o.gangart} · ${o.niva}</span></button>`).join("");
  overlay(true,`
  <span class="lbl">Träningsboken · efter Markus Ridhandbok (markusholst.com)</span>
  <h1 style="margin-top:8px">Allt du behöver veta</h1>
  <p class="dim" style="font-size:13.5px">Kunskapen och övningarna nedan följer ridhandbokens
  uppbyggnad — fem grundkommandon, formen, övergångarna, skolorna. Texterna är spelets egna.
  Lektionens moment hämtas härifrån.</p>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:22px;margin-top:12px">
    <div><div class="lbl" style="margin-bottom:6px">Hästkunskap</div>${kap}</div>
    <div><div class="lbl" style="margin-bottom:6px">Övningsbanken · ${OVNIN_ANTAL()} övningar</div>
      <div style="max-height:46vh;overflow:auto">${ovn}</div></div>
  </div>
  <div class="lbl" style="margin-top:22px;margin-bottom:6px">Tangenter</div>
  <div class="keys">${
    (typeof TANGENTSTEG!=="undefined"?TANGENTSTEG:[]).map(t=>{
      const av=(typeof introNiva==="function")&&t.fran>introNiva();
      return `<div${av?' class="dim"':''}>`
        +t.k.split(" ").map(k=>`<kbd>${k}</kbd>`).join("")+" "+t.txt
        +(av?` <span class="dim">(från ${GRUPPNAMN[GRUPPSTEGE[t.fran]]})</span>`:"")
        +`</div>`;}).join("")
  }${
    (typeof TANGENTOVRIGA!=="undefined"?TANGENTOVRIGA:[])
      .map(t=>`<div><kbd>${t.k}</kbd> ${t.txt}</div>`).join("")
  }<div><kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> gå — till fots</div>
   <div><kbd>E</kbd> interagera (dörrar, ridlärare, box)</div>
   <div><kbd>Shift</kbd> jogga — till fots</div></div>
  <p class="dim" style="font-size:12.5px">Raderna som är nedtonade kommer när du flyttas
  upp. I ridningen visas bara de du har, de tre första passen.</p>
  <div class="btnrow"><button class="btn ghost" id="tbTillbaka">Tillbaka</button></div>`);
  stylaTraningsbok();
  for(const el of document.querySelectorAll("[data-k]"))
    el.onclick=()=>visaKunskap(el.dataset.k,tillbaka);
  for(const el of document.querySelectorAll("[data-o]"))
    el.onclick=()=>visaOvning(el.dataset.o,tillbaka);
  document.getElementById("tbTillbaka").onclick=()=>{
    if(tillbaka==="meny")visaMeny(); else overlay(false);};
}
function OVNIN_ANTAL(){return OVNINGAR.length;}
function stylaTraningsbok(){
  if(document.getElementById("tbStil"))return;
  const s=document.createElement("style");s.id="tbStil";
  s.textContent=`.tb-rad{display:block;width:100%;text-align:left;background:var(--panel-2);
    border:1px solid var(--rule);color:var(--ink);padding:7px 10px;margin-bottom:5px;
    border-radius:3px;font-size:13.5px;cursor:pointer}
    .tb-rad:hover{border-color:var(--gold);}
    .tb-rad .dim{color:var(--muted);font-size:11.5px}`;
  document.head.appendChild(s);
}
function visaKunskap(id,fran){
  const K=KUNSKAP.find(x=>x.id===id); if(!K)return visaTraningsbok(fran);
  overlay(true,`
  <span class="lbl">Träningsboken · hästkunskap · ${K.kalla}</span>
  <h1 style="margin-top:8px">${K.titel}</h1>
  <p style="font-size:16px;margin-top:10px">${K.text}</p>
  <div class="btnrow"><button class="btn" id="tbT">Till träningsboken</button></div>`);
  document.getElementById("tbT").onclick=()=>visaTraningsbok(fran);
}
function visaOvning(id,fran){
  const o=OVNINGAR.find(x=>x.id===id); if(!o)return visaTraningsbok(fran);
  const steg=o.utforande.map(s=>`<li>${s}</li>`).join("");
  const fel=o.fel.map(s=>`<li>${s}</li>`).join("");
  const vikt=Object.entries(o.skala).map(([k,v])=>
    `<span>${Skala.LABEL[k]} <b>${Math.round(v*100)} %</b></span>`).join(" · ");
  overlay(true,`
  <span class="lbl">Träningsboken · övning · ${o.gangart} · från ${o.niva}</span>
  <h1 style="margin-top:8px">${o.namn}</h1>
  <p style="font-size:15px;margin-top:8px">${o.syfte}</p>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:22px;margin-top:8px">
    <div><div class="lbl" style="margin-bottom:6px">Utförande</div>
      <ol style="font-size:13.5px;line-height:1.6;padding-left:18px">${steg}</ol></div>
    <div><div class="lbl" style="margin-bottom:6px">Vanliga fel</div>
      <ul style="font-size:13.5px;line-height:1.6;padding-left:18px">${fel}</ul></div>
  </div>
  <div class="note" style="font-size:12.5px">Bedöms mot utbildningsskalan: ${vikt}</div>
  <div class="btnrow"><button class="btn" id="tbT">Till träningsboken</button></div>`);
  document.getElementById("tbT").onclick=()=>visaTraningsbok(fran);
}

/* ── Lektionsbyggaren — steg 4: ridläraren sätter ihop dagens
      lektion ur banken efter din grupp. Alltid skritt på lång tygel
      först, sedan skritt-, trav- och galoppövningar som roterar med
      dagen, och i hoppgruppen banan som avslutning. ── */
const NIVAIDX={alla:0, grupp2:4, grupp3:5, grupp4:6, grupp5:7, hoppgrupp:8};

function byggLektion(grupp,seed,plats){
  const gIdx=(typeof GRUPPSTEGE!=="undefined")?GRUPPSTEGE.indexOf(grupp):4;
  const tillg=OVNINGAR.filter(o=>(NIVAIDX[o.niva]??0)<=Math.max(gIdx,0));
  const av=(g)=>tillg.filter(o=>o.gangart===g&&o.id!=="langtygel"&&o.id!=="ridvagar");
  const valj=(arr,k)=>arr.length?arr[(seed+k)%arr.length]:null;
  const moment=(o,tid,bedoms)=>o&&{id:o.id, namn:o.namn, tid, bedoms,
    ovning:o.id, text:o.utforande[0]};
  const lek=[];
  const skrittrunda={id:"skrittrunda", namn:"Skritta av på lång tygel", tid:20,
    bedoms:false, ovning:"langtygel",
    text:"Ge tygeln och låt hästen sträcka sig framåt-nedåt. Lektionen slutar alltid i skritt."};
  /* Uteritt på skogsstigen: lydighetsövningar behöver ingen bana —
     övergångar, halvhalter och fattningar rids på grusvägen. */
  if(plats==="stig"){
    const lydIds=["halt_skritt","trav_skritt","halvhalter","kontrabojning","galoppfattning"];
    const lyd=lydIds.map(id=>OVNINGAR.find(o=>o.id===id))
      .filter(o=>o&&(NIVAIDX[o.niva]??0)<=Math.max(gIdx,0));
    lek.push({id:"skritt", namn:"Skritt ut på stigen", tid:26, bedoms:false, ovning:"langtygel",
      text:"Skritta ut på skogsstigen på lång tygel. Låt hästen titta — här ute finns mer att titta på."});
    for(let k=0;k<3&&lyd.length;k++){
      const o=lyd[(seed+k*2)%lyd.length];
      if(!lek.some(m=>m.id===o.id))lek.push(moment(o,40,true));
    }
    lek.push(skrittrunda);
    return lek;
  }
  lek.push({id:"skritt", namn:"Skritt på lång tygel", tid:26, bedoms:false, ovning:"langtygel",
    text:"Skritta ett varv på fyrkanten och låt hästen titta sig omkring."});
  const sk=moment(valj(av("skritt").concat(av("halt")),1),38,true);
  if(sk)lek.push(sk);
  const travA=av("trav");
  const t1=moment(valj(travA,2),40,true); if(t1)lek.push(t1);
  const t2=moment(valj(travA.filter(o=>!t1||o.id!==t1.id),3),40,true);
  if(t2&&gIdx>=3)lek.push(t2);
  const g1=moment(valj(av("galopp"),4),40,true);
  if(g1)lek.push(g1);
  if(grupp==="hoppgrupp")
    lek.push({id:"bana", namn:"Banan", tid:0, bedoms:true, ovning:"ridvagar",
      text:"Nu hela banan — sex hinder, 60 cm. Rid vägen, inte hindret."});
  else
    lek.push(skrittrunda);   // efter banan går ekipagen direkt till protokollet
  return lek;
}

/* Banguider: geometri per övning, ritas i banskissen (20×60). */
const OVNINGSGUIDE={
  langtygel:{typ:"spar"},
  halt_skritt:{typ:"punkter", p:[[10,1.5],[18.5,30],[10,58.5],[1.5,30]]},
  trav_skritt:{typ:"punkter", p:[[10,1.5],[10,58.5]]},
  storvolt:{typ:"volt", cx:10, cy:10, r:10},
  serpentin:{typ:"serpentin", bagar:3},
  framdelsvandning:{typ:"punkter", p:[[10,30]]},
  skankelvikning:{typ:"diagonal", fran:[1.8,6], till:[18.2,54]},
  stromsholm:{typ:"diagonal", fran:[1.8,6], till:[10,30], ater:[1.8,54]},
  oppna:{typ:"langsida", x:1.8, inre:3.2, y0:10, y1:50},
  kontrabojning:{typ:"spar"},
  galoppfattning:{typ:"horn"},
  voltfattning:{typ:"volt", cx:13.5, cy:30, r:5},
  galoppserpentin:{typ:"serpentin", bagar:3},
  kontragalopp:{typ:"bage"},
  halvhalter:{typ:"horn"},
};

/* ── Teorisalen — tre frågor ur kunskapskapitlen ─────────────── */
const FRAGOR=[
  {f:"Vilken form är ”kontrollformen” som alltid ska finnas ett tygeltag bort?",
   alt:["Framåt–nedåt","Samlad form","Bakom handen"], ratt:0},
  {f:"Vad prövar eftergiften?",
   alt:["Att hästen söker bettet och bär sig själv","Hästens topptempo","Sadelns läge"], ratt:0},
  {f:"Vad kallas öppna, sluta och förvänd sluta tillsammans?",
   alt:["Skolorna","Vändningarna","Programmen"], ratt:0},
  {f:"Vad heter half-pass i ridhandbokens språk?",
   alt:["Diagonalsluta","Skänkelvikning","Förvänd piruett"], ratt:0},
  {f:"Vilken övning lär bakdelen att flytta i sidled?",
   alt:["Framdelsvändning","Ryggning","Stora volten"], ratt:0},
  {f:"Vad är det enda som bygger samling?",
   alt:["Halvhalter — omtag","Mer skänkel hela tiden","Kortare tyglar"], ratt:0},
  {f:"När är det rätt att longera enligt handboken?",
   alt:["Med syfte — aldrig bara för att trötta ut hästen","För att få bort överskottsenergi","För att forma halsen"], ratt:0},
  {f:"Vad gör en övergång?",
   alt:["Byter gångart, tempo eller form","Byter varv","Byter diagonal"], ratt:0},
  {f:"Varför rids kontraböjning?",
   alt:["Den tränar hjälperna och förbereder galoppombyten","Den vilar hästens rygg","Den ser snygg ut för domaren"], ratt:0},
  {f:"Vad gäller för spöet på Crokino?",
   alt:["Låt bli det helt — det står på hästlistan","Bara lätta klappar","Bara i galopp"], ratt:0},
  {f:"Vad skiljer den utbildade hästen från den ogymnastiserade?",
   alt:["Övergångarna den klarar","Hur hög den hoppar","Färgen på täcket"], ratt:0},
  {f:"Varför finns de tjugo minuterna i stallet före lektionen?",
   alt:["Dagsformen och sadelläget avgör hela ritten","Ridläraren behöver rast","Hästen ska hinna äta klart"], ratt:0},
];
const TE={fragor:[],i:0,ratt:0};
function visaTeori(){
  // tre roterande frågor med blandad alternativordning
  const start=(G.seed*7+ (SPAR?SPAR.pass:0)*3)%FRAGOR.length;
  TE.fragor=[0,1,2].map(k=>FRAGOR[(start+k*4)%FRAGOR.length]);
  TE.i=0; TE.ratt=0;
  visaFraga();
}
function visaFraga(){
  if(TE.i>=TE.fragor.length){
    overlay(true,`
    <span class="lbl">Teorisalen · resultat</span>
    <h1 style="margin-top:8px">${TE.ratt} rätt av ${TE.fragor.length}</h1>
    <p style="font-size:16px">${TE.ratt===3?"Ridläraren nickar. Teorin sitter — nu ska den ner i sadeln."
      :TE.ratt===2?"Nästan. Slå upp det sista i träningsboken."
      :"Sätt dig en stund med träningsboken — teorin gör ridningen billigare."}</p>
    <div class="btnrow">
      <button class="btn" id="bTeoriOk">Tillbaka till stallet</button>
      <button class="btn ghost" id="bTeoriBok">Öppna träningsboken</button>
    </div>`);
    document.getElementById("bTeoriOk").onclick=()=>overlay(false);
    document.getElementById("bTeoriBok").onclick=()=>visaTraningsbok("spel");
    return;
  }
  const q=TE.fragor[TE.i];
  const ordning=[0,1,2].sort((a,b)=>((a*7+TE.i*5+G.seed)%3)-((b*7+TE.i*5+G.seed)%3));
  overlay(true,`
  <span class="lbl">Teorisalen · fråga ${TE.i+1} av ${TE.fragor.length}</span>
  <h1 style="margin-top:8px;font-size:clamp(22px,3vw,30px)">${q.f}</h1>
  <div style="display:grid;gap:10px;margin-top:16px">
    ${ordning.map(i=>`<button class="btn ghost te-alt" data-i="${i}"
      style="width:100%;text-align:left;justify-content:flex-start">${q.alt[i]}</button>`).join("")}
  </div>
  <div class="btnrow"><button class="btn ghost" id="bTeoriAvbryt">Avbryt</button></div>`);
  for(const b of document.querySelectorAll(".te-alt"))
    b.onclick=()=>{
      const ratt=+b.dataset.i===q.ratt;
      if(ratt)TE.ratt++;
      saga(ratt?"Rätt.":"Inte riktigt — "+q.alt[q.ratt].toLowerCase()+".",2.5);
      TE.i++; visaFraga();
    };
  document.getElementById("bTeoriAvbryt").onclick=()=>overlay(false);
}
