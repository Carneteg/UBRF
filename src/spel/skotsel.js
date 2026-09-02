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
  {id:"sittupp", namn:"Sitt upp",      krav:false, sitt:true,
   text:"Först nu. Kontrollera gjorden en sista gång och sitt upp från vänster."},
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
