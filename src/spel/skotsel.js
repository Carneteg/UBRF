/* ══════════════════════════════════════════════════════════════════
   SKÖTSELN — kanoniska regler för att göra i ordning en häst.

   Låg förut i src/moment.js, alltså bara i JS. Roblox hade sin egen
   Preparation.luau med fyra fasetiketter och handskrivna texter — inget som
   kopplade till det webben faktiskt lär ut. Två sanningar om samma pedagogik,
   och bara den ena hade innehållet.

   Filen är källan. tools/exportera-spel.js skriver roblox/game/UBRFSpel.luau
   ur den, och --kontrollera fäller om de glidit isär.

   Innehållet är hästkunskap, inte spelbalans: att huvudet bara tål den mjuka
   borsten, att gjorden dras i tre tag med paus, att en elev RAPPORTERAR ett
   fynd i stället för att diagnostisera det. Ändra det inte för att göra
   spelet lättare — det är själva poängen med gaten.
   ══════════════════════════════════════════════════════════════════ */

/* ── FASERNA ────────────────────────────────────────────────────────
   Ordningen man gör i ordning en häst i, som DATA.

   Fanns inte förut någonstans. Webben kunde sekvensen implicit — sysslor.js
   skriver "Visitera, rykta, kratsa och sadla" i en fritext och moment.js
   har kameran per moment — men ingen fil sa vilken ordningen VAR. Roblox
   hade sin egen lista med fyra etiketter. Två sanningar igen, och den här
   gången utan innehåll i någon av dem.

   Ordningen är inte godtycklig och får inte kastas om för att korta ner
   loopen:
     · man hälsar innan man tar på — en häst som inte sett dig komma
       skräms av en hand bakifrån,
     · man visiterar INNAN man ryktar, för ett fynd på gjordläget ska
       upptäckas medan det fortfarande går att avbryta,
     · man ryktar innan sadeln läggs på, annars gnids grus in under
       underlägget,
     · och man sitter upp SIST. Att sitta upp är inte steg fem av fem
       moment — det är belöningen för att de fyra andra är gjorda.

   `krav = false` betyder att fasen inte har något eget delmoment ännu;
   den kvitteras genom att spelaren utför den vid rätt häst. `sitt` märker
   den avslutande fasen: den utförs inte, den LÅSER UPP uppsittningen. */
const FASER=[
  {id:"halsa",   namn:"Hälsa lugnt",   krav:false, sitt:false,
   text:"Gå fram från sidan där hon ser dig och säg till innan du rör henne. Aldrig rakt bakifrån."},
  {id:"visitera",namn:"Visitera",      krav:true,  sitt:false,
   text:"Ögon, mungipor, sadelläge, gjordläge och ben. Hittar du något: säg till ridläraren."},
  {id:"rykta",   namn:"Rykta",         krav:true,  sitt:false,
   text:"Skrapa, kardborste, mjuk borste. Huvudet bara med den mjuka."},
  {id:"iordning",namn:"Gör i ordning", krav:true,  sitt:false,
   text:"Kratsa alla fyra hovarna, lägg på underlägg och sadel, gjorda i tre tag."},
  {id:"leda",    namn:"Led till ridhuset", krav:true, sitt:false,
   text:"Led från vänster sida, vid bogen, med tyglarna över halsen. Hon går bredvid dig — inte efter, inte före."},
  {id:"sittupp", namn:"Sitt upp",      krav:false, sitt:true,
   text:"Först nu. Kontrollera gjorden en sista gång och sitt upp från vänster."},
];

/* ── HÄLSNINGEN ─────────────────────────────────────────────────────
   Fasen `halsa` fanns i FASER ovan, men det den LÄR UT låg bara i
   webbens src/moment.js som `VISITGANG`. Roblox fick alltså fasen utan
   innehållet — exakt den dubbla sanningen den här filen finns för att
   ta bort. Texterna nedan är ordagrant flyttade, inte omskrivna.

   Det här är den enda regeln på en ridskola som kan sluta illa på
   riktigt: hon ska se dig komma och höra dig först. Aldrig rakt
   bakifrån, aldrig tyst. Två av tre val är rätt, och det är meningen —
   det finns mer än ett sätt att göra rätt, men bara ett sätt att göra
   fel som gör ont. */
const HALSNING=[
  {t:"Framifrån, och säg hennes namn", ratt:true,
   svar:"Hon lyfter huvudet och ser på dig. Nu vet hon att du är här."},
  {t:"Från sidan vid bogen, med handen på halsen", ratt:true,
   svar:"Bra. Hon känner handen innan hon ser dig — och du står där hon kan se dig."},
  {t:"Rakt bakifrån, tyst", ratt:false,
   svar:"Hon rycker till och slår upp huvudet. Bakifrån ser hon dig inte, och en häst som blir överrumplad sparkar först och tittar sedan."},
];

/* ── HOVARNA ────────────────────────────────────────────────────────
   Fyra hovar, i den ordning man tar dem: vänster fram, vänster bak,
   höger bak, höger fram. Man går ETT varv runt hästen och slutar där
   man började, i stället för att korsa fram och tillbaka under henne.

   Webben har hovmomentet i src/moment.js (HOV, fyra index 0–3) men har
   aldrig haft hovarnas identitet som data — därför kunde Roblox inte
   veta vilken hov spelaren lyfte. Namnen är standardsvenska, inte
   UBRF-specifika, och benföljden vf/hf/vb/hb används redan i
   src/scen3d.js. */
const HOVAR=[
  {id:"vf", namn:"Vänster fram",
   text:"Stå vänd bakåt, stryk ner längs benet och be om foten. Kratsa från trakten mot tån."},
  {id:"vb", namn:"Vänster bak",
   text:"Håll handen på hennes höft hela vägen ner så hon vet var du är."},
  {id:"hb", namn:"Höger bak",
   text:"Gå runt framför henne, aldrig tätt bakom. Samma grepp på andra sidan."},
  {id:"hf", namn:"Höger fram",
   text:"Sista hoven. Titta efter sten i strålfårorna innan du släpper ner foten."},
];

/* ── EFTERVÅRDEN ────────────────────────────────────────────────────
   Passet slutar inte när man sitter av. Det slutar när hästen är
   omhändertagen — och att den ordningen är gameplay och inte en
   avslutningsskärm är hela poängen med `CLAUDE.md`:s rad om att
   ansvaret kring hästen ÄR spelet.

   Ordningen är inte godtycklig:
     · gjorden lossas först, medan sadeln fortfarande ligger still,
     · sadeln av innan tränset, annars står hon lös med sadeln kvar,
     · benen känns igenom medan de fortfarande är varma efter arbetet —
       det är då en värme går att känna,
     · vatten och hö sist, när hon andats ut.

   Inget här är en UBRF-detalj som hittats på: det är samma allmänna
   hästkunskap som resten av filen. */
const EFTERVARD=[
  {id:"gjord",  namn:"Lossa gjorden",
   text:"Lossa några hål direkt. Sadeln ligger kvar en stund till — ryggen ska få komma tillbaka långsamt."},
  {id:"sadel",  namn:"Ta av sadeln",
   text:"Sadel och underlägg av. Lägg handen på ryggen: den ska vara jämnt varm, utan ömma fläckar."},
  {id:"trans",  namn:"Ta av tränset",
   text:"Grimma på först, sedan tränset av. Hon ska aldrig stå lös i gången."},
  {id:"ben",    namn:"Känn igenom benen",
   text:"Nu, medan de är varma. En värme eller svullnad som inte fanns i morse ska ridläraren få veta om."},
  {id:"vatten", namn:"Vatten och hö",
   text:"När andningen gått ner. Hö på golvet och rent vatten — och ett tack innan du går."},
];

const RYKTZON=[
  {x:0.44,y:0.31,typ:"kropp"},{x:0.45,y:0.46,typ:"kropp"},
  {x:0.55,y:0.39,typ:"kropp"},{x:0.55,y:0.54,typ:"kropp"},
  {x:0.66,y:0.52,typ:"kropp"},{x:0.73,y:0.44,typ:"kropp"},
  {x:0.43,y:0.57,typ:"kropp"},{x:0.70,y:0.59,typ:"kropp"},
  {x:0.285,y:0.30,typ:"huvud"},
  {x:0.45,y:0.73,typ:"ben"},{x:0.71,y:0.73,typ:"ben"},
];

const RYKTREDSKAP=[
  {id:"skrapa",namn:"Gummiskrapa",kort:"cirklar",farg:"#7FB489",
   text:"Cirklar på musklerna. Aldrig över ben eller huvud."},
  {id:"hard",  namn:"Kardborste", kort:"korta drag",farg:"#D6AE3C",
   text:"Korta drag med hårets riktning — bakåt."},
  {id:"mjuk",  namn:"Mjuk borste",kort:"långa drag",farg:"#BFD4DE",
   text:"Långa drag, hela kroppen och benen."},
];

/* Vilka redskap varje zon kräver. Huvudet tål bara den mjuka. */
const RYKTKRAV={kropp:["skrapa","hard","mjuk"], ben:["hard","mjuk"], huvud:["mjuk"]};

const SADELFAS=[
  {t:"Lägg underlägget högt på manken och skjut det bakåt i hårets riktning."},
  {t:"Lägg sadeln lite för långt fram och skjut den bakåt på plats, bakom bogbladet."},
  {t:"Klicka i sadelbommen och lyft upp underlägget — manken ska vara fri."},
  {t:"Gjorda i tre tag, med en paus emellan. Aldrig allt på en gång."},
];

const VISITPUNKT=[
  {id:"ogon", x:0.250,y:0.283, namn:"Ögon och nos",
   ok:"Klara ögon, torr nos. %N ser dig i ögonen — hon är pigg idag."},
  {id:"mun",  x:0.267,y:0.330, namn:"Mungiporna",
   ok:"Mjuka och hela. Bettet har inte skavt sedan sist."},
  {id:"sadel",x:0.560,y:0.335, namn:"Sadelläget",
   ok:"Slät och sval rygg. %N står still när du trycker — inget ömmar."},
  {id:"gjord",x:0.500,y:0.560, namn:"Gjordläget",
   ok:"Ingen svullnad bakom bogen. Huden är len där gjorden ska gå."},
  {id:"ben",  x:0.455,y:0.720, namn:"Benen",
   ok:"Svala och tunna hela vägen ner. %N lyfter foten innan du hinner be om det."},
];

const VISITFYND={
  ogon: "Nosen rinner och ögonen är lite matta.",
  mun:  "En liten sårskorpa i vänstra mungipan.",
  sadel:"En varm, öm fläck mitt där sadeln ska ligga.",
  gjord:"Huden är röd och skavd efter gjorden.",
  ben:  "Höger framben är varmare än det vänstra.",
};

const VISITSVAR=[
  {t:"Säg till ridläraren", ratt:true},
  {t:"Det går nog bra idag", ratt:false},
  {t:"Lös det själv och sadla", ratt:false},
];
