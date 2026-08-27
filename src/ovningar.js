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
