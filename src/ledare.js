/* ══════════════════════════════════════════════════════════════════
   LEDARNA — ridlärarna som håller i dagen.

   Fyra ledare med var sin personlighet. Samma sak kan sägas på fyra
   sätt: Maria säger bara det som behövs, Sofie peppar, Bengt är kort
   och sträng, Elin pratar genom hästen. Vem som håller lektionen
   roterar med dagen (fröet); på tävlingsdag håller huvudridläraren.

   Personligheten sitter i ORDEN, inte i bedömningen: modellen dömer
   likadant oavsett ledare. Det som skiljer är vad de säger, hur ofta
   de ropar, hur ofta de berömmer — och rösten i talsyntesen.

   [antagande] Namnen är spelets egna tills ubrf.se/vår-personal kan
   hämtas (nätspärren) — då byts de mot klubbens riktiga ridlärare.

   Spelarna är 8–15 år: korta meningar, enkla ord, aldrig elakt.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const LEDARE=[
  {id:"maria", namn:"Maria", roll:"huvudridlärare", stil:"lugn och tydlig",
   farg:"#2E4638", rost:{rate:1.00,pitch:1.00},
   prat:12, beromChans:0.35,
   nej:"Nej. Du rider den du fått. Så fungerar det här.",
   rop:{
     takt:["Samma tempo hela varvet.","Räkna i huvudet: ett–två, ett–två."],
     losgjordhet:["Andas ut. Mjuk hand.","Låt hästen sträcka på halsen en stund."],
     kontakt:["Ta upp tyglarna lite.","Håll handen stilla och jämn."],
     schvung:["Lite mer skänkel.","Rid framåt — hästen ska jobba."],
     rakriktning:["Titta dit du ska.","Gör volten rund."],
     samling:["En halvhalt före hörnet.","Balansera om — och släpp sedan fram."],
   },
   berom:["Bra. Fortsätt precis så.","Nu sitter det.","Snyggt ridet."],
   skotsel:{bra:"Fint skött. Det syns på hästen.",
     ok:"Godkänt. Rykta lite extra vid sadeln nästa gång.",
     dalig:"Du hade bråttom i dag. Hästen märker det."},
   lektion:{
     uppflytt:g=>`Det där satt. Nästa vecka rider du i ${g}.`,
     utesluten:h=>"Inte er dag. Vi tar det igen nästa vecka.",
     felfriBra:"Felfritt — och du red vägen, inte hindren. Mycket bra.",
     felfri:"Felfritt! Nu jobbar vi på ridningen mellan hindren.",
     bra:"Bra ridet. Fortsätt så.",
     jobbaPa:"Vi jobbar vidare. Titta i träningsboken hemma.",
     felBra:n=>`${n} fel, men ridningen håller. Det kommer.`,
     fel:n=>`${n} fel. Titta på vägen, inte på hindret.`,
   }},
  {id:"sofie", namn:"Sofie", roll:"ungdomsledare", stil:"glad och peppande",
   farg:"#A34E6E", rost:{rate:1.12,pitch:1.25},
   prat:8, beromChans:0.65,
   nej:"Neej, ge honom en chans! Ni kommer bli ett superpar.",
   rop:{
     takt:["Hitta takten igen — du hade den nyss!","Klappa takten inuti: ett–två!"],
     losgjordhet:["Slappna av i armarna, det smittar!","Ge lite med handen — så där ja!"],
     kontakt:["Plocka upp tyglarna lite grann!","Snälla händer — inga ryck!"],
     schvung:["Mer ben! Framåt!","Väck bakbenen — krama med vaderna!"],
     rakriktning:["Titta upp! Dit du ska!","Rund volt — som en pannkaka, inte ett ägg!"],
     samling:["Testa en halvhalt före hörnet!","Liten paus i sitsen — sen framåt igen!"],
   },
   berom:["JA! Precis så där!","Ni två är ett riktigt team nu!","Superbra — fortsätt!"],
   skotsel:{bra:"Wow, vad fin han blev! Bra jobbat!",
     ok:"Bra försök! Lite till vid sadeln nästa gång.",
     dalig:"Oj, det gick lite fort i dag. Vi tränar mer på det!"},
   lektion:{
     uppflytt:g=>`HURRA! Du flyttas upp till ${g}!`,
     utesluten:h=>"Sånt händer alla. Nästa gång går det bättre — jag lovar!",
     felfriBra:"Felfritt OCH snyggt ridet! Jag är så stolt!",
     felfri:"Felfritt! Nu putsar vi på resten också!",
     bra:"Vilken fin lektion ni hade! Fortsätt så!",
     jobbaPa:"Bra kämpat! Nästa gång tar vi det ett snäpp till.",
     felBra:n=>`${n} fel — men du red jättefint. Det ordnar sig!`,
     fel:n=>`${n} fel i dag. Vi tränar mer — det släpper snart!`,
   }},
  {id:"bengt", namn:"Bengt", roll:"ridlärare", stil:"sträng men rättvis",
   farg:"#3A3E44", rost:{rate:0.92,pitch:0.72},
   prat:10, beromChans:0.15,
   nej:"Nej.",
   rop:{
     takt:["Takten. Ett–två.","Du rusar. Sakta ner."],
     losgjordhet:["Hästen är spänd. Släpp handen.","Lång hals. Vänta."],
     kontakt:["Ta tyglarna. Nu.","Inga ryck."],
     schvung:["Skänkel. Mer.","Framåt. Inte snigelfart."],
     rakriktning:["Inre skänkel i hörnet.","Rakt på medellinjen. Rakt."],
     samling:["Halvhalt. Före hörnet, inte efter.","Balans först. Sen vändning."],
   },
   berom:["Godkänt.","Så ska det se ut.","Inte illa."],
   skotsel:{bra:"Bra. Så sköter man en häst.",
     ok:"Godkänt. Nätt och jämnt.",
     dalig:"Om igen nästa gång. Ordentligt."},
   lektion:{
     uppflytt:g=>`Uppflyttad. ${g}. Gör inte bort dig.`,
     utesluten:h=>"Uteslutning. Hem och tänk. Vi ses nästa vecka.",
     felfriBra:"Felfritt och rätt ridet. Bra.",
     felfri:"Felfritt. Men ridningen var stökig.",
     bra:"Godkänt.",
     jobbaPa:"Inte godkänt. Läs träningsboken.",
     felBra:n=>`${n} fel. Ridningen duger. Felen försvinner.`,
     fel:n=>`${n} fel. Vägen först. Hindret sen.`,
   }},
  {id:"elin", namn:"Elin", roll:"ridlärare", stil:"hör vad hästarna tycker",
   farg:"#4E6B8A", rost:{rate:0.98,pitch:1.10},
   prat:13, beromChans:0.50,
   nej:"Hon valde faktiskt dig. Testa.",
   rop:{
     takt:["Känner du? Hon vill hitta sin takt.","Lyssna på hovarna — ett–två, ett–två."],
     losgjordhet:["Hon är spänd i ryggen. Andas med henne.","Låt henne sänka huvudet, så släpper det."],
     kontakt:["Hon söker din hand. Möt henne.","Håll handen som om du höll en fågel."],
     schvung:["Hon väntar på ditt ben. Be henne.","Hon vill framåt — våga följa med."],
     rakriktning:["Hon lutar inåt. Hjälp henne med inre benet.","Visa henne vägen med blicken."],
     samling:["En halvhalt — säg ”vänta lite” till henne.","Samla ihop henne. Sen släpp."],
   },
   berom:["Titta — öronen framåt. Hon trivs.","Nu pratar ni samma språk.","Hon litar på dig nu."],
   skotsel:{bra:"Känn på henne — hon är nöjd med dig.",
     ok:"Hon är okej. Men hon hade velat ha lite mer tid.",
     dalig:"Hon känner sig bortglömd i dag. Ge henne mer tid nästa gång."},
   lektion:{
     uppflytt:g=>`Hästarna har bestämt sig: du är redo för ${g}.`,
     utesluten:h=>`${h} behövde en lugnare dag. Ni försöker igen.`,
     felfriBra:"Felfritt — och hästen såg glad ut hela vägen. Finaste betyget.",
     felfri:"Felfritt! Men hästen fick jobba hårt för det.",
     bra:"Hästen litade på dig i dag. Det syntes.",
     jobbaPa:"Hästen förstod inte alltid vad du menade. Vi övar mer.",
     felBra:n=>`${n} fel, men ni två börjar förstå varandra.`,
     fel:n=>`${n} fel. Lyssna på hästen — den vet var hindret är.`,
   }},
];

/* Dagens ledare roterar med fröet, men låses när dagen börjar — hon
   byts inte för att du frågar om en annan häst. På tävlingsdag håller
   huvudridläraren i det, som på en riktig klubbtävling. */
function dagensLedare(){
  if(typeof G==="undefined")return LEDARE[0];
  if(G.tavling)return LEDARE[0];
  if(G.ledareId){const l=LEDARE.find(x=>x.id===G.ledareId);if(l)return l;}
  return LEDARE[(G.seed||0)%LEDARE.length];
}
function nyLedareForDagen(){
  if(typeof G!=="undefined")G.ledareId=LEDARE[(G.seed||0)%LEDARE.length].id;
  return dagensLedare();
}

/* ── Kopplingen till lektionsmotorn (larare.js) ───────────────────
   Motorn bestämmer VAD som sägs och NÄR (ett tema hela lektionen);
   ledaren färgar HUR. Varje tema mappas till den punkt på skalan som
   ledarens egna repliker handlar om, och läggs till som varianter. */
const LEDARE_TEMA={hand:"kontakt", sits:"losgjordhet", framat:"schvung",
  timing:"samling", lugn:"losgjordhet", vagen:"rakriktning"};
function ledarTemaRattor(fokusId){
  const k=LEDARE_TEMA[fokusId], led=dagensLedare();
  return (k&&led.rop[k])?led.rop[k]:[];
}
function ledarTemaBerom(){ return dagensLedare().berom; }
/* Pratiga ledare håller kortare pauser mellan replikerna. 1,0 = motorns
   egen takt; Sofie ligger under, Elin över. */
function ledarTakt(){ return dagensLedare().prat/12; }

/* Skötselomdömet: risker behåller sina lärande rader (de säger exakt
   vad som blev fel), men helhetsbetyget sägs med ledarens ord. */
function ledarSkotselOmdome(res){
  if(res.risker&&res.risker.length)return res.omdome;
  const led=dagensLedare();
  if(res.dagsform>0.82)return led.skotsel.bra;
  if(res.dagsform>0.62)return led.skotsel.ok;
  return led.skotsel.dalig;
}

/* Omdömet efter lektionen — samma utfall, ledarens ord. */
function ledarLektionsOmdome(P,dom,snitt,forv,hadeBana,hastNamn){
  const led=dagensLedare(), L=led.lektion;
  if(P.uppflyttad)return L.uppflytt(P.gruppNamn);
  if(dom.utesluten)return L.utesluten(hastNamn);
  if(!hadeBana)return snitt>=forv?L.bra:L.jobbaPa;
  if(dom.totalfel===0)return snitt>=forv?L.felfriBra:L.felfri;
  return snitt>=forv?L.felBra(dom.totalfel):L.fel(dom.totalfel);
}
