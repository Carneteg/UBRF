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
   text:"Gå fram från sidan. Säg hennes namn innan du rör henne.",
   namnEn:"Greet her calmly",
   textEn:"Walk up from the side. Say her name before you touch her."},
  {id:"visitera",namn:"Visitera",      krav:true,  sitt:false,
   text:"Kolla ögon, mun, sadelläge, gjordläge och ben.",
   namnEn:"Check her over",
   textEn:"Check eyes, mouth, saddle area, girth area and legs."},
  {id:"rykta",   namn:"Rykta",         krav:true,  sitt:false,
   text:"Skrapa, kardborste, mjuk borste. Huvudet bara mjukt.",
   namnEn:"Groom",
   textEn:"Curry comb, dandy brush, soft brush. Head soft brush only."},
  {id:"iordning",namn:"Gör i ordning", krav:true,  sitt:false,
   text:"Kratsa alla fyra hovar. Sedan underlägg, sadel, gjord och träns.",
   namnEn:"Get her ready",
   textEn:"Pick out all four hooves. Then numnah, saddle, girth and bridle."},
  {id:"leda",    namn:"Led till ridhuset", krav:true, sitt:false,
   text:"Led från vänster sida, vid bogen. Tyglarna över halsen.",
   namnEn:"Lead her to the arena",
   textEn:"Lead from her left side, at her shoulder. Reins over her neck."},
  {id:"sittupp", namn:"Sitt upp",      krav:false, sitt:true,
   text:"Kontrollera gjorden. Sitt upp från vänster.",
   namnEn:"Mount",
   textEn:"Check the girth. Mount from the left."},
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
   svar:"Bra. Nu vet hon att du är där.",
   tEn:"From the front, saying her name",
   svarEn:"Good. Now she knows you are there."},
  {t:"Från sidan vid bogen, med handen på halsen", ratt:true,
   svar:"Bra. Handen först, och du står där hon ser dig.",
   tEn:"From the side at her shoulder, with a hand on her neck",
   svarEn:"Good. Hand first, and you stand where she can see you."},
  {t:"Rakt bakifrån, tyst", ratt:false,
   svar:"Hon skräms. Gå aldrig rakt bakifrån.",
   tEn:"Straight from behind, without a word",
   svarEn:"She startles. Never approach straight from behind."},
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
   text:"Stå vänd bakåt. Stryk ner längs benet och be om foten.",
   namnEn:"Left fore",
   textEn:"Face her tail. Run your hand down the leg and ask for the foot."},
  {id:"vb", namn:"Vänster bak",
   text:"Håll handen på höften hela vägen ner.",
   namnEn:"Left hind",
   textEn:"Keep your hand on her hip all the way down."},
  {id:"hb", namn:"Höger bak",
   text:"Gå runt framför henne. Samma grepp på andra sidan.",
   namnEn:"Right hind",
   textEn:"Walk around in front of her. Same hold on the other side."},
  {id:"hf", namn:"Höger fram",
   text:"Sista hoven. Leta efter sten innan du släpper ner foten.",
   namnEn:"Right fore",
   textEn:"Last hoof. Look for stones before you set the foot down."},
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
   text:"Lossa gjorden några hål. Låt sadeln ligga kvar.",
   namnEn:"Loosen the girth",
   textEn:"Loosen the girth a few holes. Leave the saddle on."},
  {id:"sadel",  namn:"Ta av sadeln",
   text:"Ta av sadel och underlägg. Känn efter ömma fläckar.",
   namnEn:"Take off the saddle",
   textEn:"Take off saddle and numnah. Feel her back for sore spots."},
  {id:"trans",  namn:"Ta av tränset",
   text:"Grimma på först, sedan tränset av.",
   namnEn:"Take off the bridle",
   textEn:"Headcollar on first, then the bridle off."},
  {id:"ben",    namn:"Känn igenom benen",
   text:"Känn igenom benen nu, medan de är varma.",
   namnEn:"Feel her legs over",
   textEn:"Feel her legs now, while they are still warm."},
  {id:"vatten", namn:"Vatten och hö",
   text:"Ge hö och rent vatten. Säg tack innan du går.",
   namnEn:"Water and hay",
   textEn:"Give hay and clean water. Say thank you before you go."},
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
   text:"Cirklar på musklerna. Inte på ben eller huvud.",
   namnEn:"Rubber curry comb", kortEn:"circles",
   textEn:"Circles on the muscles. Not on legs or head."},
  {id:"hard",  namn:"Kardborste", kort:"korta drag",farg:"#D6AE3C",
   text:"Korta drag bakåt, med håret.",
   namnEn:"Dandy brush", kortEn:"short strokes",
   textEn:"Short strokes backwards, with the coat."},
  {id:"mjuk",  namn:"Mjuk borste",kort:"långa drag",farg:"#BFD4DE",
   text:"Långa drag över hela hästen.",
   namnEn:"Soft brush", kortEn:"long strokes",
   textEn:"Long strokes over the whole horse."},
];

/* Vilka redskap varje zon kräver. Huvudet tål bara den mjuka. */
const RYKTKRAV={kropp:["skrapa","hard","mjuk"], ben:["hard","mjuk"], huvud:["mjuk"]};

/* Zonens namn i momentraden ("Gummiskrapa — kropp"). Låg förut bara som
   det svenska zon-ID:t, vilket gjorde momentnamnet halvsvenskt på
   engelska. Gemener i båda språken: det är en del av en mening, inte en
   rubrik. */
const RYKTZONNAMN={kropp:"kropp", ben:"ben", huvud:"huvud"};
const RYKTZONNAMN_EN={kropp:"body", ben:"legs", huvud:"head"};

const SADELFAS=[
  {t:"Lägg underlägget högt på manken. Skjut det bakåt.",
   tEn:"Lay the numnah high on the withers. Slide it back."},
  {t:"Lägg sadeln för långt fram. Skjut den bakåt, bakom bogbladet.",
   tEn:"Set the saddle too far forward. Slide it back, behind the shoulder."},
  {t:"Lyft upp underlägget i bommen. Manken ska vara fri.",
   tEn:"Lift the numnah into the gullet. Keep the withers clear."},
  {t:"Dra gjorden i tre tag, med paus emellan.",
   tEn:"Do up the girth in three stages, with a pause between."},
  /* TRÄNSNINGEN. Tillagd 2026-09-11 och redovisad som ett tillägg, inte
     som ett fynd: EFTERVARD har sedan länge ett eget `trans`-moment
     ("Ta av tränset"), medan påtagningen aldrig fanns som steg. Att ta av
     något man aldrig satt på är en asymmetri i listan, och `leda` säger
     redan "med tyglarna över halsen" — alltså förutsätter kanon att
     tränset sitter på när hästen leds.

     Innehållet är allmän hästkunskap, som resten av filen, och ingen
     UBRF-detalj: grimman hålls kvar runt halsen medan tränset träs, och
     bettet tas emot i stället för att tryckas in. */
  {t:"Träns på sist. Tummen i mungipan — vänta tills hon öppnar.",
   tEn:"Bridle last. Thumb in her mouth corner — wait until she opens."},
];

const VISITPUNKT=[
  {id:"ogon", x:0.250,y:0.283, namn:"Ögon och nos",
   ok:"Klara ögon, torr nos.",
   namnEn:"Eyes and nose",
   okEn:"Clear eyes, dry nose."},
  {id:"mun",  x:0.267,y:0.330, namn:"Mungiporna",
   ok:"Mungiporna är hela.",
   namnEn:"Corners of the mouth",
   okEn:"The corners of her mouth are sound."},
  {id:"sadel",x:0.560,y:0.335, namn:"Sadelläget",
   ok:"Ryggen är sval och slät.",
   namnEn:"Saddle area",
   okEn:"Her back is cool and smooth."},
  {id:"gjord",x:0.500,y:0.560, namn:"Gjordläget",
   ok:"Ingen svullnad bakom bogen.",
   namnEn:"Girth area",
   okEn:"No swelling behind the shoulder."},
  {id:"ben",  x:0.455,y:0.720, namn:"Benen",
   ok:"Benen är svala och tunna.",
   namnEn:"Legs",
   okEn:"Her legs are cool and clean."},
];

const VISITFYND={
  ogon: "Rinnande nos och matta ögon.",
  mun:  "Sårskorpa i vänstra mungipan.",
  sadel:"Varm, öm fläck där sadeln ska ligga.",
  gjord:"Röd, skavd hud efter gjorden.",
  ben:  "Höger framben är varmare än vänster.",
};

/* Fynden på engelska. De är det spelaren LÄSER när hästen inte får gå —
   välfärdsstoppets mening — och de är därför spelartext, inte en intern
   kod. Meningen får inte tunnas ut i översättningen: ett fynd ska låta
   lika allvarligt på båda språken. */
const VISITFYND_EN={
  ogon: "Runny nose and dull eyes.",
  mun:  "A scab in her left mouth corner.",
  sadel:"A warm, sore spot where the saddle goes.",
  gjord:"Red, rubbed skin where the girth sits.",
  ben:  "The right foreleg is warmer than the left.",
};

const VISITSVAR=[
  {t:"Säg till ridläraren", ratt:true,  tEn:"Tell the instructor"},
  {t:"Det går nog bra idag", ratt:false, tEn:"It will probably be fine today"},
  {t:"Lös det själv och sadla", ratt:false, tEn:"Sort it out yourself and tack up"},
];
