/* ══════════════════════════════════════════════════════════════════
   ANLÄGGNINGEN — UBRF, Husbyvägen 1A, Bro. All geometri i meter.
   Koordinatsystem: origo i sydväst, +x öster, +y norr.
   Byggd mot fotona i references/buildings/ och mot satellit- och
   Street View-bilder över Husbyvägen 1A (se references/SITEPLAN.md):
   ridhuset i mörkröd korrugerad plåt med svarta detaljer, caféet med
   balkong och yttertrappa på gaveln mot grusplanen, UBRF-skylten och
   den långa entrékvisten på västra långsidan mot vägen, gården
   mellan ridhus och stall, stallets faluröda träpanel med huvraden på
   nocken och ett valvfönster per box, förstukvisten på västra
   långsidan, fodersilon vid södra gaveln, hagarna öster om stallet och
   utebanorna norr om dem.

   Väderstrecken: spelets norr är verklighetens nordväst (SITEPLAN.md).
   Grusplanen — parkeringen dit man kommer, den alla foton är tagna
   från — ligger vid husens NORRA gavlar, mot Björklidsvägen. Därifrån
   ser man ridhuset till höger och stallet till vänster, precis som i
   verkligheten. Silon, bakgården och infartsvägen från Husbyvägen
   ligger vid den södra änden.
   Geometrin här är den enda sanningen — rendering läser bara detta.
   ══════════════════════════════════════════════════════════════════ */

/* Fasadernas u löper moturs runt huset: på västra långsidan räknas den
   från NORRA gaveln, på östra från den södra. Stallets foton och kort
   beskriver allt som avstånd från klubbgaveln — den mot grusplanen,
   alltså den norra — så på västra långsidan är u avståndet självt och
   på den östra räknas det om. Stallet är 69,95 m långt (VERIFIED,
   PO-satellitmätning 2026-08-30 — se references/site/MATLISTA-SATELLIT.md). */
const sV = s => s;

/* Stallets längd och boxantal används både av fasadhjälparen nedan (som körs
   när ANL byggs) och av STALLINNE (som deklareras långt senare). De ligger
   därför HÄR, ovanför båda. Att låta fasadhjälparen läsa STALLINNE gav en
   temporal dead zone: ANL byggs först, och STALLINNE fanns inte än. */
/* ══ DE MÄTTA FOTAVTRYCKEN ═══════════════════════════════════════════
   Alla fyra huvudmått är Product Owner-satellitmätningar 2026-08-30, se
   references/site/MATLISTA-SATELLIT.md och issue #24. De ersätter de
   antaganden som stod här förut: stallet 21 × 54 och ridhuset 25 × 75.

   Husens LÄGE härleds ur dem i stället för att skrivas var för sig, så att
   ett ändrat mått inte kan lämna ett grannobjekt kvar på gammal plats:

     · ridhusets västra långsida ligger still på x = 118. Det är sidan mot
       Enköpingsvägen, den med UBRF-skylten, och den är fotograferad.
     · båda husens NORRA gavlar ligger still på y = 119. Det är gavlarna mot
       parkeringen — caféet och ståltrappan på ridhuset, klubbgaveln med
       förstukvisten och spiraltrappan på stallet. Mest fotoverifierat av
       allt, och det spelaren anländer till. Husen växer alltså söderut.
     · stallets läge i x följer av ridhusets bredd plus det mätta gårdsgapet.

   GÅRDSGAPET är mätt i ETT tvärsnitt i söder. Det är inte bevisat att
   väggarna är parallella hela vägen, så 8,10 m används som husens inbördes
   avstånd men får inte läsas som en konstant längs hela gården. Modellen
   har raka, parallella väggar; verkligheten kanske inte har det.
   `[ASSUMPTION]` att gapet är sig likt norrut. ══ */
const STALL_LANGD  = 69.95;  // `VERIFIED` PO-satellitmätning
const STALL_BREDD  = 29.28;  // `VERIFIED` — ersätter antagandet 21 m
const RIDHUS_LANGD = 77.18;  // `VERIFIED`
const RIDHUS_BREDD = 26.57;  // `VERIFIED` — ersätter antagandet 25 m
const GARDSGAP     = 8.10;   // `VERIFIED LOCAL` i södra tvärsnittet
const NORRA_GAVELN = 119;    // gemensam gavellinje, ligger still
const RIDHUS_X = 118;
const RIDHUS_Y = NORRA_GAVELN - RIDHUS_LANGD;              // 41,82
const STALL_X  = RIDHUS_X + RIDHUS_BREDD + GARDSGAP;       // 152,67
const STALL_Y  = NORRA_GAVELN - STALL_LANGD;               // 49,05

/* Hästgångens fäste: 39,83 m från ridhusets MÄTTA södra gavel till den
   mätta fästpunkten. `VERIFIED DIRECT OFFSET`.

   Det är EN punkt, inte gångens mittlinje — issue #24 är uttrycklig om att
   den inte får tolkas om i tysthet. Här läggs den som gångens SÖDRA kant,
   vilket är `[ASSUMPTION]`: fotot avgör inte vilken kant som mättes.
   Väljer man i stället mittlinjen flyttas gången 1,75 m söderut. */
const GANG_FASTE = RIDHUS_Y + 39.83;                       // 81,65
const GANG_DJUP  = 3.5;                                    // `[ASSUMPTION]`

const STALL_BOXAR = 11;      // sju söder om tvärkorridoren, fyra norr

/* ══ TRÄNINGSBANORNA ═══════════════════════════════════════════════════
   `VERIFIED` Uteridbanans KORTSIDA är 33,57 m (PO-satellitmätning, issue
   #24). Den låg som 20 m i spelet — en dressyrbana 20 × 40 som ingen källa
   stödde.

   `[REFERENCE GAP]` LÅNGSIDAN är inte mätt. Issue #24 är uttrycklig om att
   de kumulativa polylinjevärdena (100 m, 190,35 m, 110,96 m) INTE får
   användas som en bansida.

   48 m nedan är ett PLATSHÅLLARE, inte ett mått. Det är valt av en trist
   anledning: modellens tomt är 170 m djup och banan måste ligga norr om
   husens gavellinje på y = 119, så mer än ~50 m ryms inte. Ett första
   försök med 60 m sköt 88 delar utanför tomten, vilket byggbänken fällde.
   Siffran säger alltså något om modellens ram, inte om UBRF. Den ska bytas
   mot ett mätt värde — och behöver då förmodligen att tomten växer.

   `[REFERENCE GAP]` AVSTÅNDET från husen till banan är inte heller mätt.
   Banan ligger norr om husens gemensamma gavellinje, som i satellitbilden;
   x-läget är valt så att den ryms mellan stallet och Husbyvägen.

   Allt runt banan — staket, master, domarkur, torvbalar — läser den här
   rektangeln i stället för egna tal, så att ett mätt långsidemått bara
   behöver skrivas in på ETT ställe. ══ */
/* Namnet är UTEBANA, inte BANA: src/data.js har redan en global BANA för
   dressyrbanans mått, och två `const BANA` i samma bundle är ett
   SyntaxError som fäller hela spelet. Exportörens vm körde bara model.js +
   site.js och såg aldrig krocken — webbygget gjorde det direkt. */
const UTEBANA = {x:172, y:119.5, w:33.57, h:48};
const PADDOCK = {x:152, y:135,   w:16,    h:22};

/* Rektangelns hörn som en sluten polygon, och som fyra punkter. */
const rektRunt = r => [[r.x,r.y],[r.x+r.w,r.y],[r.x+r.w,r.y+r.h],[r.x,r.y+r.h],[r.x,r.y]];
const hornRunt = r => [[r.x,r.y],[r.x+r.w,r.y],[r.x,r.y+r.h],[r.x+r.w,r.y+r.h]];

/* Stallets långsidor har ett valvbågat fönster per box, i samma takt som
   boxarna innanför (STALLINNE: boxarna börjar 10,4 m in och är 3,5 m
   breda). Rytmen är byggnadens tydligaste drag på håll — därför räknas
   den fram ur samma tal i stället för att skrivas av för hand. */
function stallFonster(sida){
  const ut=[];
  for(let i=0;i<STALL_BOXAR;i++){
    const s=10.4+3.5*i+1.75;                    // avstånd från klubbgaveln i norr
    ut.push({sida, u:sida==="W"?sV(s):STALL_LANGD-s, b:1.15, h:1.55, z0:1.55, typ:"valv"});
  }
  return ut;
}

const ANL = {
  bredd: 210, djup: 170,

  /* Markytor ritas i ordning — senare vinner. */
  mark: [
    {typ:"gras",  rekt:{x:0,   y:0,   w:210, h:170}},
    {typ:"aker",  rekt:{x:9,   y:20,  w:99,  h:100}},  // åkrarna öster om Enköpingsvägen
    {typ:"asfalt",rekt:{x:2,   y:0,   w:5,   h:170}},  // Enköpingsvägen i väster
    {typ:"asfalt",rekt:{x:207, y:0,   w:3,   h:170}},  // Husbyvägen i öster
    {typ:"grus",  rekt:{x:0,   y:146, w:118, h:6}},    // Björklidsvägen in mot grusplanen
    {typ:"grus",  rekt:{x:106, y:121, w:48,  h:34}},   // grusplanen/parkeringen vid norra gavlarna
    {typ:"grus",  rekt:{x:144, y:119, w:36,  h:16}},   // planen framför stallets klubbgavel
    {typ:"grus",  rekt:{x:112, y:20,  w:6,   h:101}},  // grusvägen längs västra långsidan
    {typ:"grus",  rekt:{x:144, y:10,  w:62,  h:8}},    // infartsvägen från Husbyvägen i sydost
    {typ:"grus",  rekt:{x:148, y:40,  w:44,  h:9}},    // gårdsplanen vid stallets södra gavel (kortad: huset når nu y=49,05)
    {typ:"grus",  rekt:{x:186, y:16,  w:8,   h:28}},   // väggrenen upp från infarten
    {typ:"grus",  rekt:{x:STALL_X+STALL_BREDD, y:64, w:3, h:57}}, // gången öster om stallet mot hagarna

    {typ:"sand",  rekt:UTEBANA},                          // uteridbanan
    {typ:"sand",  rekt:PADDOCK},                       // grusbanan/paddocken bredvid
    {typ:"betong",rekt:{x:170, y:100, w:6,   h:5}},    // betongplattan vid uppgången
  ],
  cirklar: [ // runda markytor
    {typ:"sand", c:[100,131], r:4.6, kant:true},       // lekhagen med stenhästarna
  ],

  byggnader: [
    /* Ridhuset. Måtten och färgerna kommer ur byggnadskortet
       references/buildings/ridhus/KORT.md, som i sin tur är läst ur
       fotona i samma mapp — inget här är gissat fritt.
         · mörkt vinröd, vertikalt korrugerad stålplåt. Medelvärdet över
           alla tre fotona är (97,45,57) — mörkare och blåare än kortets
           första avläsning (138,34,40), som togs i en dager. Färgen här
           är råvaran (135,47,64); belysningen tar ner den till fotots.
         · svart list runt hela huset vid 4,1 m: övre bjälklaget, och
           det första man ser från parkeringen
         · sadeltak med 13° resning (kortets ~14°, spann 11–17°),
           svart plåt och svarta vindskivor
         · norra gaveln mot parkeringen: dubbeldörren med
           valvfönstret över, den svarta dörren under sitt vita
           skärmtak, och i väster Café Krubban med fyra valvbågade
           fönster, balkong och utvändig ståltrappa (norra gavelns u
           räknas moturs, från östra hörnet)
       Banan 20×60 därinne; UBRF-skylten mitt på västra långsidan. */
    /* Längden 77,18 m är `VERIFIED` — Product Owner satellitmätning
       2026-08-30, linje längs långsidan mellan motsvarande yttre gavlar.
       Tidigare 75 m var `[ASSUMPTION]`; skillnaden är 2,18 m.

       Liksom stallet ligger NORRA gaveln still (y = 119): det är gaveln
       mot parkeringen med caféet, entrén och ståltrappan, och den är
       fotoverifierad. Huset växer söderut, y 44 → 41,82.

       Ridhusets INRE bana (20 × 60) skalas INTE med skalet — den är en
       egen dimension, och MATLISTA säger uttryckligen att den inte får
       följa med automatiskt. De 2,18 m blir alltså mer marginal i södra
       änden, inte en längre bana. */
    {id:"ridhus", rekt:{x:RIDHUS_X, y:RIDHUS_Y, w:RIDHUS_BREDD, h:RIDHUS_LANGD},
     hV:6.2, hN:9.27, nock:"NS",
     fargV:"#872F40", fargT:"#202022", svart:"#202022", plat:true,
     list:4.10, takfot:true, detalj:"ridhus", label:"RIDHUSET",
     oppningar:[
       {sida:"N", u:3.1, b:1.8, h:2.2, z0:0,   typ:"dorrvit", skarm:2.6}, // dubbeldörren
       {sida:"N", u:3.3, b:1.20,h:1.55,z0:4.45,typ:"valv"},   // valvfönstret över entrén
       {sida:"N", u:8.1, b:1.1, h:2.1, z0:0,   typ:"dorr", skarm:2.1},    // svarta dörren
       {sida:"N", u:20.1,b:1.05,h:1.45,z0:1.35,typ:"valv"},   // caféet, nedre våningen
       {sida:"N", u:24.1,b:1.05,h:1.45,z0:1.35,typ:"valv"},
       {sida:"N", u:20.1,b:1.05,h:1.45,z0:4.45,typ:"valv"},   // caféet, övre våningen
       {sida:"N", u:24.1,b:1.05,h:1.45,z0:4.45,typ:"valv"},
       {sida:"N", u:22.3,b:1.0, h:2.05,z0:4.02,typ:"dorr"},   // cafédörren mot balkongen
       /* Västra långsidan, mot vägen. Street View visar en lång
          entrékvist närmast caféet, den svarta dörren vid UBRF-skylten
          och en rad små fyrkantsfönster högt uppe. */
       {sida:"W", u:9,  b:2.0, h:2.2, z0:0,    typ:"dorrvit"},  // dubbeldörrarna under kvisten
       {sida:"W", u:40, b:1.1, h:2.1, z0:0,    typ:"dorr"},     // svarta dörren vid skylten
       {sida:"W", u:14, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       {sida:"W", u:22, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       {sida:"W", u:30, b:0.9, h:0.7, z0:4.90, typ:"fonster"},
       /* Durkplåtdörrarna mot gården. Låg tidigare vid u = 22, alltså rakt
          bakom läktaren (som upptar lokala y 9–59): både dörrmarkören och
          landningspunkten hamnade inuti en solid läktarstomme och gick inte
          att använda. Flyttad till u = 5, söder om läktaren. */
       {sida:"E", u:5,  b:3.4, h:2.9, z0:0, typ:"portplat"},
       /* HÄSTGÅNGEN till stallet, mitt på östfasaden. u mäts från södra
          gaveln: gången ligger på y 89,3–92,8, alltså 45,3–48,8 lokalt. */
       {sida:"E", u:40.38, b:2.4, h:2.6, z0:0, typ:"portbla", intern:true},
       {sida:"S", u:8,  b:4.0, h:3.6, z0:0, typ:"portsilver"},// stora silverporten [antagande]
     ]},
    /* Stallet. Måtten och färgerna kommer ur byggnadskortet
       references/buildings/stall/KORT.md, läst ur fasad- och
       entrébilderna i samma mapp.
         · liggande träpanel i mörk falurött (80,35,47), vita knutar,
           vitt foder runt varje fönster, ljusgrå betongsockel
         · sadeltak i mörk blågrå bandtäckt plåt, 28° resning, med
           snörasskydd och svart hängränna
         · huvraden på nocken — en huv per box, och den börjar först
           efter förstukvisten, inte vid gaveln
         · ett valvbågat fönster per box längs båda långsidorna
         · förstukvisten på västra långsidan, 5,6 m från norra
           gaveln — klubbgaveln mot grusplanen: ockragul dörr, runda
           fönster, vitt ribbräcke
         · norra gaveln: valvfönster, balkongdörr och spiraltrappa
         · södra gaveln mot gårdsplanen (Street View): två entrédörrar
           under vita skärmtak och en rak ståltrappa till övervåningen */
    /* Stallets NORRA gavel ligger i liv med ridhusets — det syns i
       satellitbilden: båda gavlarna vetter mot grusplanen i samma linje.
       Ytan mellan husen är INTE en verifierad obruten gräsgård: husen är
       sammanbyggda (Tobias på plats), och gården är det som blir kvar
       mellan förbindelserna. Se hastgang nedan. */
    {id:"stall", rekt:{x:STALL_X, y:STALL_Y, w:STALL_BREDD, h:STALL_LANGD},
     /* Nocken följer av den MÄTTA bredden och kortets 28° resning:
        4,4 + 29,28/2 × tan 28° = 12,18. Takfot, nock och resning var alla
        antaganden knutna till den antagna bredden 21 m; när bredden mättes
        måste två av tre räknas om, och kortets resning är den av dem som
        vilar på foto. Geometrispecen mäter resningen, inte nocken. */
     hV:4.4, hN:12.18, nock:"NS",
     fargV:"#6E2F44", fargT:"#5E646C", svart:"#26292E", takfot:"#EEECE4",
     detalj:"stall", sockel:0.35, label:"STALLET",
     oppningar:[
       /* Förstukvisten på västra långsidan. */
       {sida:"W", u:sV(5.6), b:1.15, h:2.10, z0:0,    typ:"dorrgul"},  // ockragula entrédörren
       {sida:"W", u:sV(4.0), b:0.66, h:0.66, z0:1.78, typ:"rund"},     // runda fönstren vid dörren
       {sida:"W", u:sV(7.2), b:0.66, h:0.66, z0:1.78, typ:"rund"},
       {sida:"W", u:sV(2.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},     // valvfönster kring kvisten
       {sida:"W", u:sV(8.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},
       /* HÄSTGÅNGEN mot ridhuset. På W mäts u från NORRA gaveln söderut,
          så tvärkorridorens mitt (lokalt y 26,05) ligger på u 26,75. */
       {sida:"W", u:sV(34.4), b:2.4, h:2.6, z0:0, typ:"portbla", intern:true},
       ...stallFonster("W"), ...stallFonster("E"),
       /* Norra gaveln — klubbgaveln mot grusplanen, den höga, med
          balkongen och spiraltrappan (stall-fasad-04/05). */
       {sida:"N", u:6.4,  b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"N", u:14.6, b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"N", u:8.4,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       {sida:"N", u:12.6,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       {sida:"N", u:10.5,  b:0.95, h:2.05, z0:4.60, typ:"dorrvit"},     // balkongdörren
       /* Klubbentrén i gavelns mitt, rakt under balkongen — den vetter
          mot grusplanen och leder in i klubbdelen. [enligt Tobias] */
       {sida:"N", u:10.5,  b:1.15, h:2.05, z0:0,    typ:"dorrgul", skarm:1.7},
       /* Stora skjutporten mitt på östra långsidan, mot hagarna. */
       {sida:"E", u:34.35, b:3.6, h:3.2, z0:0, typ:"portbla"},
       /* Södra gaveln mot gårdsplanen: servicedelens två entrédörrar
          under vita skärmtak, valvfönster och trappdörren uppe
          (Street View från infartsvägen). */
       {sida:"S", u:5.6,  b:1.15, h:2.10, z0:0,    typ:"dorrvit", skarm:1.7},
       {sida:"S", u:12.5,  b:1.15, h:2.10, z0:0,    typ:"dorrvit", skarm:1.7},
       {sida:"S", u:8.2,  b:1.10, h:1.50, z0:1.60, typ:"valv"},
       {sida:"S", u:10.4,  b:1.10, h:1.50, z0:1.60, typ:"valv"},
       {sida:"S", u:9.2,  b:1.10, h:1.50, z0:4.60, typ:"valv"},
       {sida:"S", u:12.4, b:0.95, h:2.00, z0:4.35, typ:"dorrmork"},    // trappdörren
       /* HÄSTARNAS VÄG VÄSTERUT ÄR HÄSTGÅNGEN. Här satt tidigare en egen
          port på u 30, uppfunnen för att spelaren skulle kunna leda ut
          hästen på gården. Den låg i tvärkorridorens västra ände — exakt
          där satellitbilden nu visar att hästgången går, och två portar i
          samma vägg på samma ställe är en för mycket.

          Den uppfunna porten är borta. Den verifierade förbindelsen står
          kvar och gör samma jobb bättre: hästen leds inomhus, vilket är
          hela poängen med att husen sitter ihop. Österut finns fortfarande
          den stora skjutporten mot hagarna, som är läst i Street View. */
     ]},
    /* HÄSTGÅNGEN mellan ridhuset och stallet. Tobias har varit på plats:
       husen är sammanbyggda, och det som binder dem är en hästgång — man
       leder hästen inomhus mellan stallet och ridhuset i stället för att gå
       ut över gården.

       LÄGET ÄR VERIFIERAT SEDAN 2026-08-30. Satellitbilden som Tobias lade
       fram (references/plans/SATELLIT-HASTGANG-2026-08-30.md) visar en
       taktäckt tvärgående förbindelse i den CENTRALA delen av husens
       gemensamma längd — inte vid någon ände — och den delar mellanrummet i
       två skilda gårdsytor.

       Den låg tidigare i norra änden (y 106–112). Det var ett antagande
       härlett ur var husen hade gångbar insida, och satellitbilden
       underkände det. Placeringen här är inte gissad utan mätt in mellan två
       källor som pekar på samma ställe:

         · husens gemensamma längd är y 65–119, alltså mitten y 92,0
         · stallets egen tvärkorridor, mätt i utrymningsplanen, ligger på
           y 89,3–92,8 med mitten y 91,05

       Under en meter isär. Gången läggs därför i liv med tvärkorridoren: den
       mynnar i den korridor som planen redan visar når båda långsidorna, och
       ingen ny öppning behöver uppfinnas i stallet.

       Måtten är däremot fortfarande antagna. Satellitbilden ger topologi,
       inte meter. [ASSUMPTION: bredd, höjder, taklutning] */
    /* Hästgången ligger där stallets tvärkorridor mynnar. Den låg på
       y = 89,3, avläst ur satellit UTAN skala. När stallets längd mättes
       till 69,95 m hamnade korridoren på världens 76,85–80,35, och gången
       måste följa med — annars mynnar den i en boxrad. Gångens eget läge
       är fortfarande omätt (MATLISTA punkt 4); det här är det läge som
       följer av ett verifierat längdmått plus planens proportioner, vilket
       väger tyngre än en oskalad satellitavläsning. `[DERIVED]` */
    {id:"hastgang", rekt:{x:RIDHUS_X+RIDHUS_BREDD, y:GANG_FASTE,
      w:GARDSGAP, h:GANG_DJUP}, hV:3.2, hN:4.0, nock:"EW",
     fargV:"#7C2A24", fargT:"#5E646C", label:"HÄSTGÅNGEN",
     oppningar:[
       {sida:"N", u:4.6, b:1.2, h:1.4, z0:1.3, typ:"fonster"},
       {sida:"S", u:4.6, b:1.2, h:1.4, z0:1.3, typ:"fonster"},
     ]},
    /* Den låga byggnaden i gårdens södra ände. Att NÅGOT står mellan
       gavlarna i söder syns i Street View; att det ser ut just så här gör
       det inte. Läge, mått, taklutning och den enda dörren är alla
       antagna, och den ska inte läsas som en verifierad förbindelse bara
       för att den råkar heta länga. [ASSUMPTION] */
    /* Låg y 59..65, alltså i liv med stallets dåvarande södra gavel. När
       gaveln flyttade till 49,05 hamnade längan mitt i gräsgården i
       stället för i dess södra ände, och gjorde inte längre det den finns
       till för. Flyttad till y 43..49 så att den fortsatt sluter gården
       söderut. Läget är fortfarande `[ASSUMPTION]`, precis som förut —
       den är flyttad för att behålla sin ROLL, inte för att någon källa
       säger var den står. */
    {id:"langa", rekt:{x:147, y:43, w:7, h:6}, hV:3.0, hN:4.4, nock:"EW",
     fargV:"#7C2A24", fargT:"#7E8288", label:"",
     oppningar:[{sida:"N", u:4.4, b:1.1, h:2.0, z0:0, typ:"dorrmork"}]},
    /* Röda stugan vid infarten från Björklidsvägen (förråd/sekretariat). */
    {id:"stuga", rekt:{x:94, y:140, w:6.5, h:4.5}, hV:2.5, hN:3.8, nock:"EW",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"E", u:1.2, b:1.6, h:0.9, z0:1.1, typ:"fonster"},
                {sida:"S", u:1.6, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Domarkuren vid uteridbanan.

       `[KNOWN MISMATCH → RÄTTAD]` Kuren stod tidigare på x 184..188,5,
       y 148..151,5 — alltså HELT INNANFÖR banans staket (x 176..196,
       y 119..159). En byggnad mitt i ridbanan. Ingen källa säger det;
       det var ett läge som aldrig kontrollerades mot staketrektangeln.

       references/omnejd/banan-01 och -02 visar den röda boden UTANFÖR
       banan, bortom staketet och upp mot trädridån, med rött tak och
       öppen förstukvist.

       `[ASSUMPTION]` VILKEN kortsida den står vid. Fotona visar bara att
       den ligger bortom banan sett från vägen. Här står den centrerad
       utanför den norra kortsidan (y = 159), mot trädridån — dressyrens
       domarplats vid C. Rätt sida kan bara avgöras ur satellit. */
    {id:"domarkur", rekt:{x:UTEBANA.x+(UTEBANA.w-4.5)/2, y:UTEBANA.y+UTEBANA.h+0.8, w:4.5, h:3.5},
     hV:2.3, hN:3.4, nock:"EW",
     fargV:"#8A3A30", fargT:"#8C3A2A", label:"",
     oppningar:[{sida:"S", u:0.95, b:2.6, h:1.0, z0:1.0, typ:"fonster"}]},
    /* Boden vid södra gaveln (vid sopstationen). */
    {id:"bod", rekt:{x:184, y:44, w:5, h:4}, hV:2.3, hN:3.4, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"S", u:1.4, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Elcentralen/boden vid stigen mot banorna. */
    {id:"elbod", rekt:{x:STALL_X+STALL_BREDD+0.6, y:59, w:3, h:2.5}, hV:2.0, hN:2.8, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"", oppningar:[]},
  ],

  /* Staket: postlinjer. "tra" = kraftigt trästaket med två reglar
     (banor och hagar), "el" = trådstängsel mot åkern, "rail" = låg
     falurödmålad trärail (parkering/lekhage). */
  staket: [
    /* `sandkant` = staketet omsluter en sandyta och har därför den grova
       syllen i marknivå som håller sanden på plats (banan-01). Hagarna
       saknar den — där möter staketet gräs. */
    {typ:"tra", sandkant:true, p:rektRunt(UTEBANA)},     // uteridbanan
    {typ:"tra", sandkant:true, p:rektRunt(PADDOCK)},  // paddocken bredvid
    /* Hagarna låg x 178–206 och hamnade inne i det bredare stallet
       (x 152,67–181,95). Flyttade öster om gången. */
    {typ:"tra", p:[[185.5,65],[206,65],[206,93],[185.5,93],[185.5,65]]},   // hage Ö1
    {typ:"tra", p:[[185.5,97],[206,97],[206,117],[185.5,117],[185.5,97]]}, // hage Ö2
    {typ:"el",  p:[[112,20],[112,121]]},                               // trådstängsel mot åkern
    {typ:"rail",p:[[155,121.5],[168,121.5]]},                          // rail framför klubbgaveln
    {typ:"rail",p:[[96,127],[96,136]]},                                // rail vid lekhagen
  ],
  hagar: [ // betande hästar (id ur HORSES) för liv i bilden
    {rekt:{x:185.5,y:65,w:20.5,h:28}, hastar:["cosmo","air","mara"]},
    {rekt:{x:185.5,y:97,w:20.5,h:20}, hastar:["larry","husky","westside","lydia"]},
    {rekt:PADDOCK, hastar:["toblerone","dexter","chip"]},
  ],

  /* Träd: [x, y, radie]. Skogsbryn i norr och väster, björkraden
     längs grusvägen, lövträden runt gårdsplanen. */
  trad: [
    [110,50,1.6],[110,62,1.7],[110,74,1.6],[110,86,1.8],[110,98,1.6],  // björkraden
    [122,14,2.6],[130,12,2.2],[88,10,2.6],[104,24,1.8],
    [150,4,2.8],[160,5,2.4],[172,4,2.8],[184,5,2.6],[196,6,3.0],       // trädraden mot Enköpingsvägen-hållet i söder
    [194,36,2.6],[199,14,2.4],
    [60,118,3.0],[56,130,3.4],[56,138,3.0],[62,158,3.2],[70,164,3.0],
    [80,166,3.4],[92,168,3.0],[104,166,3.2],[116,166,3.0],[128,164,3.4],
    [140,162,3.0],[150,161,2.8],[120,158,2.4],[88,160,2.8],
    [46,120,3.2],[40,132,3.0],[44,156,3.4],[36,160,3.0],
    [98,120,2.2],[92,130,2.0],[200,158,2.6],[192,164,3.0],
  ],

  /* Rekvisita — ritas i 2D och 3D av world.js. */
  props: [
    /* Fodersilon vid stallets södra gavel. Låg tidigare på y = 60, alltså
       5 m ut från gaveln (y = 65) — det var ett satellitläge, avläst
       ovanifrån. `references/buildings/stall/stall-gavel-06-silon.jpg`
       (Byggnaden, IMG_0076) visar den från marknivå: silon står TÄTT MOT
       gaveln, ungefär i dess mitt, och når drygt halva gavelhöjden.

       Gaveln flyttade från y = 65 till y = 49,05 när längden mättes, och
       silon följde med — den låg annars inne i huset. Radien är 1,5 m, så
       y = 47,5 lägger mantelns kant på 49,0 mot gavelns 49,05. Balarna
       bredvid följde av samma skäl. */
    {typ:"silo",      pos:[164.6,47.5]},
    {typ:"balar",     pos:[158,44.5]},                   // ensilagebalarna
    {typ:"grushog",   pos:[122,131]},                    // grushögen på grusplanen (Street View)
    {typ:"transport", pos:[133,125], rikt:0.5},          // hästtransporten på grusplanen
    {typ:"bord",      pos:[150,74]},                     // picknickborden på gården (de syns i stall-fasad-01)
    {typ:"bord",      pos:[148,86]},
    {typ:"bank",      pos:[146,94]},
    {typ:"stol",      pos:[149,102]},
    {typ:"skylt",     pos:[118,82], text:"UPPLANDS-BRO RYTTARFÖRENING", norm:[-1,0]},
    /* CAFÉ-skylten sitter på trappans ÖVRE avsats, inte vid dess fot —
       references/buildings/ridhus/ridhus-trappan-05-cafeskylten.jpg.
       Kommentaren här sade "vid trappans fot"; höjden i v3dRekvisita är
       3,0 m och stämde redan, så det var beskrivningen som var fel, inte
       geometrin. Rättat för att nästa läsare inte ska "rätta" höjden. */
    {typ:"cafeskylt", pos:[124.4,119.8], norm:[0,1]},
    {typ:"flagga",    pos:[123,149]},
    {typ:"vagvisare", pos:[172,123]},    // vägvisaren med åtta armar, vid klubbgaveln
    {typ:"stenhast",  pos:[98.5,129.5]},                 // stenhästarna i lekhagen
    {typ:"stenhast",  pos:[101.5,132]},
    {typ:"stenhast",  pos:[99.5,133]},
    {typ:"stenhast",  pos:[101,129]},
    /* Belysningsmasterna. `VERIFIED` att de finns och att de är flera:
       banan-03 visar minst fyra runt uteridbanan. Att de sitter i banans
       fyra hörn är `[DERIVED]` — fotona visar master längs båda långsidor,
       och hörnplacering är den vanliga lösningen. Måtten i BANOMRADE.mast. */
    ...hornRunt(UTEBANA).map(pos=>({typ:"mast", pos})),
    {typ:"mast",      pos:[PADDOCK.x, PADDOCK.y+PADDOCK.h]},   // paddockens hörn
    /* `VERIFIED` Torvbalarna (RS Mustang) står staplade utomhus vid banan,
       banan-03. Annat än ensilagebalarna vid stallgaveln: fyrkantiga,
       vitplastade med rött tryck. `[ASSUMPTION]` exakt läge — bilden visar
       dem vid banans kant mot vägen, inte var längs kanten. Här står de
       på grusytan strax väster om banans staket — utanför både banan och
       paddocken, som fotot visar. */
    {typ:"torvbalar", pos:[UTEBANA.x-3.6, UTEBANA.y+5.6]},
    {typ:"sopstation",pos:[150,56]},
    {typ:"ac",        pos:[143.4,80], norm:[1,0]},                   // värmepumparna mot gården
    {typ:"ac",        pos:[143.4,84], norm:[1,0]},
    {typ:"busskylt",  pos:[8.6,88]},
  ],

  /* Interaktionspunkter på gården. */
  dorrar: [
    /* 0,9 m ut från väggen, inte 0,4: kollisionsmarginalen mot en byggnad är
       0,55 m, så en markör närmare än så går inte att stå på. */
    {id:"ridhus_o", pos:[RIDHUS_X+RIDHUS_BREDD+0.9,49], text:"In i ridhuset (durkplåtdörrarna)",
     mot:"ridhusinne", spawn:{x:23.4,y:5,rikt:Math.PI}},
    {id:"ridhus_n", pos:[139.9,119.8], text:"In i ridhuset (entrén)",
     mot:"ridhusinne", spawn:{x:21.9,y:73.4,rikt:-Math.PI/2}},
    {id:"cafe", pos:[124.4,120.2], text:"Café Krubban (trappan upp)", mot:"info",
     info:"Café Krubban har stängt för kvällen. Kolla in vyn över banan från läktaren i stället."},
  ],
  /* Man kommer med bil till grusplanen vid norra gavlarna — precis som
     i verkligheten. Härifrån: ridhuset till höger, stallet till vänster. */
  spawn: {x:146, y:136, rikt:-Math.PI/2},
  /* Hagen där dagens häst hämtas: grinden på västra sidan av hage Ö1. */
  hamtHage: {grind:[178,79], falt:[186,77]},
  skylt: {pos:[120,150.5], text:"HUSBYVÄGEN 1A · UPPLANDS-BRO RYTTARFÖRENING"},
};

/* ── Stallet invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 15), +y norr (längd 52).
      Norr: klubbdelen (uppehållsrum, teorisal, toaletter) innanför
      entrén vid klubbgaveln mot grusplanen — vit pärlspont, betonggolv.
      Branddörren in till stallet ("schysst stall"-dekalen). Mitten:
      stallgången — marksten, två rader boxar i antracitgrå komposit
      med galvade galler, namnskyltar, limträbalkar och taklanterniner.
      Söder: servicedelen med spolspilta, spånförråd och
      uppbindningsplatser, mot gårdsplanen.
      klubbY och serviceY är tvärväggarnas y; boxarna ligger emellan. ── */
/* ── Stallet invändigt — DUBBELSTALL ────────────────────────────────
   Byggt mot utrymningsplanen (Presto AB 2025-10-11, "Plan 1"), som sedan
   2026-08-30 finns i repot: `references/plans/stall-plan1-utrymning.jpg`.
   Den är auktoritativ för planform och layout enligt Gate F01.

   MÄTT I PLANEN, inte läst ur prosa. Ett lodrätt tvärsnitt genom
   boxområdet vid tre olika x-lägen ger samma sex band, i samma ordning:

     boxrad — GÅNG A — boxrad · boxrad — GÅNG B — boxrad

   De två mittersta står rygg mot rygg mot en gemensam spine, som i planen
   bär regelbundna ⊞-märken (vattenkoppar eller foderluckor). Bandens
   inbördes andelar av byggnadens bredd, mätta i planen:

     boxrad W   169 px   20,9 %
     gång A     100 px   12,4 %
     boxrad MA  144 px   17,8 %
     boxrad MB  142 px   17,6 %
     gång B      99 px   12,3 %
     boxrad E   153 px   19,0 %

   ANDELARNA ÄR VERIFIERADE — de är oberoende av skala och lika i alla tre
   snitten. Det viktigaste de säger är att GÅNGARNA ÄR SMALARE ÄN BOXARNA
   ÄR DJUPA, ungefär två tredjedelar. Spelet antog tidigare att alla sex
   banden var lika breda; det var fel.

   TOTALBREDDEN ÄR DÄREMOT INTE AVGJORD. `BREDD` nedan är ett antagande i
   mitten av ett intervall som källorna inte är eniga om — se
   `references/buildings/stall/KORT.md` under "Bredden". Ändra bara den
   siffran; allt annat i planen följer andelarna. ── */
/* ══ IDENTITETSDRAGEN ══════════════════════════════════════════════
   De fotoverifierade drag som gör att man KÄNNER IGEN husen — takhuvarna
   på stallets nock, förstukvisten, spiraltrappan, ridhusets mörkröda övre
   långvägg och takets installationer.

   Måtten låg tidigare bara som lokala konstanter inne i src/varld3d.js.
   Det var en dold sanning: webben ritade dem, men Roblox kunde inte läsa
   dem, och primärplattformen saknade alltså just de drag som avgör
   igenkänningen. Senior Fidelity Review 03:s tillägg öppnade det som en
   visual parity blocker.

   Här ligger de i stället en gång, och båda ytorna läser dem — webben
   direkt, Roblox via tools/exportera-geometri.js.

   VAD SOM ÄR VERIFIERAT är att dragen FINNS, och var i grova drag: det
   står i byggnadskorten och i DRIVE-SOURCE-INDEX. De exakta måtten nedan
   är avlästa ur foton eller valda så att formen blir rätt, och är
   `[ASSUMPTION]` var för sig. Det är alltså inte en lista över sanningar
   utan över drag vars existens är verifierad och vars mått är antagna.

   Måtten i meter. Bara det som behövs för att känna igen huset — inte
   varje list och skruv. Dekor utan källa hör inte hemma här. ══ */
const IDENTITET = {
  stall: {
    /* Huvraden på nocken, en huv per box. Det tydligaste draget på håll:
       stall-fasad-03 och -04. Boxarna börjar 10,4 m från klubbgaveln och
       är 3,5 m breda, så första huven sitter mitt över första boxen. */
    huvrad:{antal:11, forstaFranNorr:12.15, delning:3.5,
            sida:0.44, hojd:0.62, hattB:0.66},
    /* Snörasskyddet på båda takfallen, en tredjedel upp. */
    snorasskydd:{andelUpp:0.30, andelUt:0.70, stolpDelning:2.2},
    /* Förstukvisten på västra långsidan, nära klubbgaveln. Sadeltak med
       nocken ut från väggen, vitt ribbräcke, ockragul dörr. */
    forstukvist:{uFranNorr:5.6, bredd:5.2, djup:2.8,
                 takfot:2.95, resning:1.05, oppning:1.5},
    /* Stallgångens två igenkänningsfärger, MÄTTA ur
       references/buildings/stall/stall-inne-05-stallgangen.jpg.

       Metod: leta upp ytorna på FÄRGEN i stället för på gissade koordinater
       — de varma, mättade pixlarna i takzonen är limträbalkarna, de neutrala
       är plåten. Ett första försök med handgissade provrutor gav bara
       gråbruna medelvärden och missade balkarna helt.

       De låg tidigare som lokala tal i src/varld3d.js: #9C4A32 (mörkt
       tegelrött) och #D9DDE1 (nästan vit). Båda var fel, och båda avgör hur
       stallgången läses inifrån — det är balkarna och plåten man känner igen
       den på. De hör därför hemma här och inte i en renderare.

       Roblox bygger ännu inte stallets tak, bara golv, boxrader och
       tvärväggar. När det byggs ska det läsa de här värdena. */
    stallgang:{limtra:"#C39575", takplat:"#878783"},
    /* Balkongen och spiraltrappan på klubbgaveln — stall-fasad-04/05.
       Balkongen sitter mitt för sin dörr, alltså i gavelns mitt. */
    balkong:{z:4.55, bredd:2.2, djup:1.10, rackeH:0.92},
    spiraltrappa:{franGavelmitt:2.3, radie:0.70, steg:18},
  },
  ridhus: {
    /* MOTSÄGELSE 1 — IMG_0183: mörkröd övre långvägg ovanför sargen,
       med vita läkt som horisontella detaljer. */
    ovreVagg:{overSarg:0.1, underTak:1.6, tjocklek:0.08, listar:3},
    /* MOTSÄGELSE 3 — IMG_0179/0183: taket har stål, kabelstegar och
       ventilation, inte bara limträbalkar. Andelarna är av husets bredd. */
    takProfiler:{andelar:[0.18,0.40,0.60,0.82], b:0.14, h:0.30, underTak:0.62},
    kabelstegar:{andelar:[0.30,0.70], bredd:0.34, underTak:1.02, pinnDelning:0.55},
    ventkanaler:{andelar:[0.24,0.76], radie:0.30, underTak:0.95, donDelning:6.5},
  },
};

/* ══ BANOMRÅDET ════════════════════════════════════════════════════
   Uteridbanans mätbara drag, avlästa ur references/omnejd/banan-01..03
   (Drive-mappen Omnejd, IMG_0163–0165). De låg tidigare som lokala tal
   inne i src/varld3d.js och src/world.js, alltså osynliga för Roblox —
   samma dolda sanning som IDENTITET löste för husen.

   Vad som är VERIFIED här är dragens EXISTENS och antal, inte deras
   läge på tomten. Banans placering relativt husen kan bara komma ur
   satellit — se references/site/SATELLIT-MATNING-2026-08-30.md — och
   är alltså inte avgjord här.

   Måtten i meter. ══ */
const BANOMRADE = {
  /* Staketet runt uteridbanan.

     RÄTTELSE AV MIN EGEN AVLÄSNING. Först skrev jag här att staketet har
     "tre liggande reglar", räknat i en nedskalad banan-03. En beskuren
     högupplöst avläsning av banan-01 — samma spann, tre gånger så många
     pixlar — visar att det är fel. Det jag tog för tre reglar är i själva
     verket tre OLIKA saker, och de ska byggas olika:

       1. `VERIFIED` EN kraftig liggande toppregel av trä, högst upp.
       2. `VERIFIED` ELTRÅD på svarta isolatorer under den. Isolatorerna
          syns på stolpen; trådarna är tunna mörka linjer, inte virke.
       3. `VERIFIED` En GROV LIGGANDE SYLL i marknivå längs sandkanten,
          som håller banans sand på plats. Den syns tydligt där sanden
          möter gräset.

     Läxan är densamma som med hästgången: en avläsning gjord på för få
     pixlar blir ett påstående som ser mätt ut men inte är det.

     Avgjord på den närmaste, bäst belysta stolpen i banan-01 (bildens
     högra fjärdedel, uppförstorad 2,4x). Där syns TRE svarta isolatorer på
     stolpen — en strax under toppregeln och två under den — plus två tunna
     trådlinjer och syllen. En tidigare avläsning av banan-02 såg ut att
     visa två liggande träreglar; det var det BORTRE staketets toppregel
     sedd genom det närmaste.

     `[ASSUMPTION]` de exakta höjderna. Skalade mot stolpen, vars topp till
     grässkant antas vara 1,35 m: toppregel 1,30, trådar 0,75 och 0,34,
     syllens mitt 0,13.

     `[ASSUMPTION]` att hagarnas staket är byggda likadant. Inget foto
     visar dem på nära håll. Sandsyllen byggs bara där staketet omsluter
     sand — se `sandkant` på sträckorna i ANL.staket. */
  staket:{
    toppregel:{z:1.30, h:0.13, d:0.09},
    sandsyll:{z:0.13, h:0.26, d:0.11},
    tradar:[0.75, 0.34], tradTjocklek:0.025,
    isolatorB:0.07, isolatorH:0.09,
    stolpH:1.35, stolpDelning:2.6, stolpTvarsnitt:0.12,
  },

  /* `VERIFIED` Belysningsmasterna har DUBBEL armatur på en tvärarm, inte
     ett enkelt huvud. Tydligast på den närmaste masten i banan-03.
     Masthöjden är `[ASSUMPTION]` — ingen skala i bilderna når upp. */
  mast:{hojd:7.5, stamOver:0.13, stamUnder:0.09,
        armB:1.30, armH:0.10, armD:0.10,
        lampB:0.44, lampH:0.20, lampD:0.30, lampDelning:0.92},
};

const STALL_BAND = [
  {id:"W",  typ:"rad",  andel:0.209, vetter:+1, gang:"A", yttervagg:true},
  {id:"A",  typ:"gang", andel:0.124},
  {id:"MA", typ:"rad",  andel:0.178, vetter:-1, gang:"A", yttervagg:false},
  {id:"MB", typ:"rad",  andel:0.176, vetter:+1, gang:"B", yttervagg:false},
  {id:"B",  typ:"gang", andel:0.123},
  {id:"E",  typ:"rad",  andel:0.190, vetter:-1, gang:"B", yttervagg:true},
];

const STALLINNE = {
  /* `VERIFIED` 29,28 m. Bredden var projektets äldsta öppna fråga — ett
     antagande på 21 m i ett intervall källorna inte var eniga om. Nu mätt.
     Bandindelningen i STALL_BAND är proportionell och följer med. */
  bredd:STALL_BREDD,
  /* `VERIFIED` 69,95 m — Product Owner satellitmätning 2026-08-30, linje
     längs långsidan parallellt med nocken, båda ändpunkter på samma
     byggnads ytterkontur. Se references/site/MATLISTA-SATELLIT.md.

     Spelet hade 54 m, en oskalad satellitavläsning. Felet var 16 m, 30 %,
     och det slog igenom hela innerplanen.

     NORRA GAVELN LIGGER STILL. Den är klubbgaveln med förstukvisten,
     balkongen, spiraltrappan och entrén mellan de två runda fönstren — den
     mest fotoverifierade delen av hela anläggningen, och den spelaren
     anländer till. Huset växer i stället söderut, in på gårdsplanen, från
     y = 65 till y = 49,05. Att växa norrut hade lagt huset i parkeringen. */
  langd:STALL_LANGD,
  vagg:"#CFC8BC", golv:"#8C8880", gangGolv:"#9A968E", tak:3.4,
  /* Zonerna följer utrymningsplanens EGNA proportioner, inte en blind
     sträckning. Mätt på references/plans/stall-plan1-utrymning-rak.jpg:
     de genomgående tvärväggarna mellan klubbdel och boxhall ligger på
     0,72–0,755 av längden från södra gaveln, alltså 50,4–52,9 m. klubbY
     sätts till 52,85.

     Boxantalet följer av samma plan: partierna i mittraden räknas till
     ungefär TOLV per rad, inte nio. 12/9 = 1,33 mot längdkvoten
     69,95/54 = 1,30 — planen och det mätta måttet pekar åt samma håll,
     och nio boxar var en följd av det för korta huset.

     Kontroll: 6,8 + 12 × 3,5 + 3,5 (tvärgång) = 52,3 ≤ 52,85. */
  /* boxStartY är flyttad från 6,8 till 8,1 för att boxrutnätet ska gå JÄMNT
     UPP mot tvärkorridoren. Korridoren ligger där hästgången mynnar, och
     gångens läge är mätt (39,83 m från ridhusets södra gavel) — alltså är
     det rutnätet som ska anpassas, inte korridoren. Med 8,1 hamnar
     fackgränserna på 8,1 + n × 3,5 och korridoren på 32,6–36,1 blir exakt
     ett överhoppat fack. Sju boxar söder om den, fyra norr: elva per rad.
     Kontroll: 8,1 + 11 × 3,5 + 3,5 = 50,1 ≤ klubbY 52,85. */
  klubbY:52.85, boxStartY:8.1, serviceY:6.5,
  boxB:3.5, antalBoxar:STALL_BOXAR,
  /* Tvärgången mitt i boxhallen. Mätt på planen ligger den på ~50 % av
     boxhallen räknat från klubbänden; 6,8 + 6 × 3,5 ger sex boxar på var
     sida. Det är också den här korridoren hästgången mynnar i. */
  tvarGang:{y0:32.6, y1:36.1},
  /* Fylls ur STALL_BAND nedan: rader med x0/boxDjup, gångar med x0/x1. */
  rader:[], gangar:{},
  /* Spelets sjutton hästar står i gång A, den man kommer in i från
     förstukvisten. Gång B:s boxar ritas men får ingen häst: spelet har
     sjutton namn och fler får inte hittas på. */
  boxar:{
    W: [ "lady","toblerone","westside","lydia","makadu","conor","mara","hamilton","husky",
         null,null ],
    MA:[ "kennedy","cosmo","tina","air","chip","larry","crokino","dexter",null,null,null ],
    MB:[ null,null,null,null,null,null,null,null,null,null,null ],
    E: [ null,null,null,null,null,null,null,null,null,null,null ],
  },
  rum:[
    /* Klubbrummen behåller sitt avstånd till NORRA gaveln (+15,95 m i
       lokala tal), eftersom det är gaveln som ligger still. */
    {id:"uppehallsrum", rekt:{x:0,    y:66.45, w:7.0, h:3.5}, label:"UPPEHÅLLSRUM"},
    {id:"teorisal",     rekt:{x:14.0, y:66.45, w:7.0, h:3.5}, label:"TEORISAL · WC"},
    {id:"sadelkammare", rekt:{x:0,    y:62.55, w:3.2, h:3.9}, label:"SADELKAMMARE"},
  ],
  service:[
    {id:"spolspilta",   rekt:{x:0,    y:0, w:4.5, h:6.5}, label:"SPOLSPILTA"},
    {id:"spanforrad",   rekt:{x:16.5, y:0, w:4.5, h:6.5}, label:"SPÅNFÖRRÅD"},
  ],
  tvarvaggar:[ {y:52.85, brand:true}, {y:6.5, brand:false} ],
  /* Dörrarna beskrivs EN gång. `pos` är innerläget, `spawn` ytterläget,
     `inrikt` vilket håll man tittar när man kliver in och `uttext` vad
     markören på gården säger. ANL.dorrar byggs ur den här listan längre
     ner — förut fanns två listor med var sin uppsättning koordinater, och
     när planformen ändrades följde bara den ena med. Då hamnade utgången
     mot gräsgården inne i en boxrad. */
  dorrar:[
    {id:"ut_n", pos:[1.6,64.35], text:"Ut genom entrén", mot:"gard", inrikt:0,
     uttext:"Gå in i stallet (Entré)",
     spawn:{x:152.6,y:113.4,rikt:Math.PI}},
    {id:"ut_n2",pos:[10.5,65.95], text:"Ut till grusplanen (klubbdörren)", mot:"gard", inrikt:-Math.PI/2,
     uttext:"Gå in i stallet (klubbdörren)",
     spawn:{x:164.5,y:120.6,rikt:Math.PI/2}},
    {id:"ut_s", pos:[5.6,1.6],   text:"Ut till gårdsplanen — mot Husbyvägen", mot:"gard", inrikt:Math.PI/2,
     uttext:"Gå in i stallet (gaveldörren vid gårdsplanen)",
     spawn:{x:159.6,y:47.45,rikt:-Math.PI/2}},
    /* HÄSTGÅNGEN till ridhuset. Den här dörren går inte ut på gården utan
       rakt in i ridhusets entréhall — det är hela poängen med att husen är
       sammanbyggda: hästen leds inomhus. Ingen markör läggs på gården för
       den, eftersom den inte finns där. */
    {id:"hastgang", pos:[0.9,34.35], text:"Hästgången — in i ridhuset",
     mot:"ridhusinne", inrikt:Math.PI, inne:true,
     spawn:{x:RIDHUS_BREDD-2.97,y:41.58,rikt:Math.PI}},
  ],
  ridlarare:{pos:[0,34], namn:"Ridläraren"},
  whiteboard:{pos:[0,7.2]},
};

/* Banden läggs ut ur andelarna, från västra ytterväggen och österut. */
(()=>{
  const S=STALLINNE; let x=0;
  for(const b of STALL_BAND){
    const w=b.andel*S.bredd;
    if(b.typ==="gang") S.gangar[b.id]={x0:x, x1:x+w};
    else S.rader.push({id:b.id, x0:x, djup:w, vetter:b.vetter,
                       gang:b.gang, yttervagg:b.yttervagg});
    x+=w;
  }
  /* Ridläraren och whiteboarden mitt i gång A. */
  const mA=(S.gangar.A.x0+S.gangar.A.x1)/2;
  S.ridlarare.pos[0]=mA; S.whiteboard.pos[0]=mA;
})();

/* Stallets dörrmarkörer på gården härleds ur STALLINNE.dorrar, så att de
   två sidorna av samma dörr aldrig kan glida isär. Före 2026-08-30 fanns
   två handskrivna listor, och när planformen ändrades följde bara den ena
   med: markören vid klubbgaveln pekade tre meter fel, och den som gick in
   från gräsgården satte spelaren INNE i en boxrad. */
for(const d of STALLINNE.dorrar){
  if(d.inne) continue;                 // hästgången går inte ut på gården
  ANL.dorrar.push({
    id:"stall_"+d.id.replace(/^ut_/,""),
    pos:[d.spawn.x, d.spawn.y],
    text:d.uttext,
    mot:"stallinne",
    spawn:{x:d.pos[0], y:d.pos[1], rikt:d.inrikt},
  });
}

STALLINNE.gangytor = (()=>{
  const S=STALLINNE, g=[];
  /* Gångytorna är spelarens enda framkomliga mängd i stallet — man får
     stå i en gångyta, ingen annanstans. Två ytor som bara TANGERAR
     varandra räcker då inte: kollisionsradien klämmer punkten in i den
     ena eller den andra, och mellan dem blir ett dödband på drygt en
     meter där ingen punkt är fri.

     Det var precis vad som hände vid brandväggen. Gång A slutade på
     klubbY och klubbhallen började på klubbY, och `navVag` hittade
     INGEN väg mellan dem. Den som gick in genom entrén hamnade i
     klubbhallen och kunde inte ta sig ner i stallgången.

     Mätt: felet fanns redan vid den gamla längden 54 m, så det är inte
     en följd av omskalningen — det hittades av att omskalningen tvingade
     fram en mätning som ingen gjort förut.

     Gångarna sträcks därför DORRGAP meter in i klubbhallen och in i
     servicepassagen. Det är dörröppningen i tvärväggen, uttryckt som
     överlapp, och det ger vägsökningen en sammanhängande korridor. */
  const DORRGAP = 1.5;
  for(const k of ["A","B"]){
    const a=S.gangar[k];
    g.push({x:a.x0, y:S.serviceY-DORRGAP, w:a.x1-a.x0,
            h:(S.klubbY+DORRGAP)-(S.serviceY-DORRGAP)});
  }
  /* Tvärkorridoren går hela vägen ut till båda långsidorna: planen har
     utrymningsvägar där, och en korridor som slutar vid gång B når dem
     inte. Den bryter boxlängorna på ett ställe, vilket är precis vad en
     genomgående korridor gör. */
  g.push({x:0.4, y:S.tvarGang.y0, w:S.bredd-0.8, h:S.tvarGang.y1-S.tvarGang.y0});
  /* Klubbhallen går från branddörrsväggen upp till klubbrummen. Gränsen
     LÄSES UR RUMMEN i stället för att skrivas som ett tal: 50,5 stod här
     hårdkodat, och när klubbY flyttades från 43 till 52,85 blev hallens
     höjd negativ. Byggbänken fällde det direkt — en box hamnade i en
     gångyta — men felet hade inte behövt uppstå. */
  const rumY = S.rum[0].rekt.y;
  g.push({x:0.4, y:S.klubbY, w:S.bredd-0.8, h:rumY-S.klubbY});     // klubbhallen
  /* Hallen mot gaveldörren. Den TANGERADE klubbhallen på rumY och var
     därför avskuren på samma sätt som gångarna var — 0,05 m glapp räckte.
     Den sträcks ner i klubbhallen med samma DORRGAP. */
  g.push({x:3.4, y:rumY-DORRGAP, w:7.2, h:3.1+DORRGAP});           // hallen mot gaveldörren
  g.push({x:4.5, y:0.4,        w:12.0,        h:S.serviceY-0.4});  // servicepassagen
  return g;
})();

/* ── Ridhuset invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 25), +y norr (längd 75). Banan 20×60 innanför
      vit murad sarg med svart sockel (IMG_0095–0116): sponsorväggen
      med speglarna i väster, läktaren med domarbåset i öster,
      entré- och cafédelen med fönsterband och trappan i norr — samma
      gavel som vetter mot grusplanen — och hinderförrådet i söder.
      Sargporten vid A släpper in ekipagen. ── */
/* Ridhuset invändigt. Måtten kommer ur utrymningsplanen (se
   references/buildings/ridhus/KORT.md) med banans 20×60 som fast punkt:
   planens längder är ihoptryckta av perspektivet, men banans två kända
   mått ger skalan i båda led och resten faller ut.

     bredd  20 m bana + 4,4 m läktarband  = 25 m
     längd  60 m bana + 13 m gaveldel     = 75 m

   Gaveldelen i norr — mot parkeringen — är entré, trapphus och café.
   Går man in från parkeringen kommer man in i en hall, inte rakt ut
   på banan. entre är gaveldelens djup; den ligger i y > langd−entre. */
/* Läktaren i hela stycken, med hästgångens öppning bortdragen. Alla som
   ritar eller kolliderar mot läktaren läser den här listan i stället för
   y0/y1 — annars murar någon av dem igen gången utan att märka det. */
function laktarSektioner(L){
  if(!L.gap) return [{y0:L.y0, y1:L.y1}];
  const ut=[];
  if(L.gap.y0-L.y0 > 0.2) ut.push({y0:L.y0, y1:L.gap.y0});
  if(L.y1-L.gap.y1 > 0.2) ut.push({y0:L.gap.y1, y1:L.y1});
  return ut;
}

const RIDHUSINNE = {
  /* langd följer fotavtrycket — exportörens validering kräver att de är
     lika, och den fällde just den här när skalet växte till 77,18 utan att
     insidan följde med.

     De 2,18 extra metrarna hamnar i NORRA änden av insidan, alltså i
     entréhallen mot caféet, vars djup ändå är `[ASSUMPTION]`. Insidans
     övriga lokala mått lämnas orörda: de är satta mot interiörfoton, och
     att flytta ett tjugotal tal för 2,9 % vore fler tillfällen att göra
     fel än det vore värt. Följden är att de ligger 2,18 m längre söderut i
     världen än förut — inom osäkerheten för en insida som i sin helhet är
     ett antagande.

     Undantaget är allt som möter hästgången. Det måste sitta på RÄTT
     världsläge, inte bara rätt lokalt, och räknas därför om nedan mot
     origo y = 41,82. */
  bredd:RIDHUS_BREDD, langd:RIDHUS_LANGD, tak:6.2, entre:13,
  bana:{x:0.6, y:2, w:20, h:60}, sargH:1.35,
  vagg:"#E9E5DC", sockel:"#2E2E2C", sandFarg:"#5E4A36", gangFarg:"#8C8880",
  /* MOTSÄGELSE 1 ur DRIVE-SOURCE-INDEX (`IMG_0183`): långsidans övre
     väggyta är MÖRKRÖD/MAROON med horisontella detaljer, inte brun
     träpanel. Rättad 2026-08-30. Listen är den horisontella detaljen. */
  panel:"#5E2C33", panelList:"#E8DFCE",
  /* Läktaren längs östväggen. GAPET är påtvingat av verifierad topologi:
     satellitbilden lägger hästgången centralt, på lokala y 45,3–48,8, och
     där kan läktaren inte vara obruten — man ska kunna leda hästen igenom.

     Läktarens utsträckning är själv ett Drive-textderivat (ASSUMPTION), och
     satellitbilden är DIRECT VISUAL. Enligt källhierarkin viker läktaren.
     Exakt hur bred öppningen är i verkligheten vet jag inte; 5,0 m är valt
     för att en häst ska gå igenom med marginal. [ASSUMPTION] */
  laktare:{x0:21.0, y0:9, y1:59, steg:4, stegH:0.28, stegD:0.85,
           gap:{y0:39.18, y1:43.98}},
  /* MOTSÄGELSE 5 (`IMG_0179`): bakom sargen finns flera glasade rum /
     fönsterpartier ovanför de nivåindelade träbänkarna. Måtten är
     `[ASSUMPTION]` — indexet beskriver att de finns, inte hur stora. */
  /* Det mellersta glasrummet slutade på y = 36 och hamnade därmed inne i
     läktargapet när gången flyttades. Kortat till gapets kant. */
  glasrum:[ {y0:12, y1:22}, {y0:26, y1:34.5}, {y0:44, y1:56} ],
  /* MOTSÄGELSE 4 (`IMG_0198`): båset ligger vid dressyrbokstaven E, är
     mörkt trä, och nås av en trappa med träräcken. Över öppningen sitter
     en grön exit-skylt. E ligger vid husets y = 32 sedan bokstäverna
     följer sargporten (se DRESSYRBOKSTAVER i data.js). */
  domarbas:{x:23.2, y:32, b:2.0, h:2.3, trappa:true, exit:true},
  /* Hindren som står framme mellan lektionerna, ur interiörfotona:
     vita stöd, blå-vita och röd-vita bommar, en bom på marken och
     uppsittningspallen vid sargen. Koordinaterna är i banans system. */
  hinder:[
    {x:6.5, y:24, b:2.8, h:0.68, farg:"bla"},
    {x:13.5,y:38, b:2.8, h:0.52, farg:"rod"},
    {x:9.0, y:50, b:3.0, h:0,    farg:"rod"},
  ],
  koner:[[4.0,17],[16.6,44],[11.0,58]],
  pall:{x:18.9, y:20},
  dynor:12,                                        // elon-dynorna på översta bänken
  cafe:{djup:13.0, z0:2.55, z1:5.4},               // överbyggnaden i norr
  trappa:{x:22.0, y:65.4},                         // trätrappan upp till caféet
  /* MOTSÄGELSE 3 (`IMG_0179`): en rund klocka vid den centrala
     passagen/trappan. Höjden är `[ASSUMPTION]`. */
  klocka:{x:22.0, y:63.6, z:3.6, r:0.42},
  speglar:[ {y:19,b:3.2},{y:37,b:4.2} ],           // på västra långsidan
  skyltar:[
    {y:53,  b:5.0, text:"VÄLKOMMEN TILL UPPLANDS-BRO RYTTARFÖRENING", fg:"#3A3E44", bg:"#F2EDE2"},
    {y:46.5,b:4.0, text:"HUVUDSPONSOR ELON BARKARBY", fg:"#F0EADC", bg:"#1C1C1E"},
    {y:31.5,b:3.6, text:"Vi tror på dig! · Sparbanken i Enköping", fg:"#C0392B", bg:"#F7F2E8"},
    {y:26.5,b:3.0, text:"Agria Djurförsäkring", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:15,  b:3.4, text:"RS Mustang · Stallströ och foder", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:8,   b:3.6, text:"Stigsbergs Gård · Hästsportbutik", fg:"#3A3E44", bg:"#F2EDE2"},
  ],
  port:{x0:9.6, x1:11.6},                         // sargporten vid A (norra kortsidan)
  /* GRINDEN mot hästgången, i sargens östra långsida. Den måste finnas: annars
     är hästgången dekoration. Man leder hästen in genom gången, och då ska man
     komma ut på banan — sargen kan inte vara obruten just där.

     Läget följer läktargapet, alltså hästgången. Bredden är vald, inte mätt.
     [ASSUMPTION] */
  sargGrind:{y0:39.98, y1:43.18},
  /* Möblerna i entréhallen, som solida rektanglar. Utan dem gick man
     rakt genom disken och bänkarna — de syntes men fanns inte.
     Koordinaterna är hallens, alltså husets: hallen ligger i norr,
     y från langd−entre och uppåt. gang är fri passage mot sargporten
     så att vägen in aldrig blockeras av en möbel. */
  hallMobler:[
    {id:"disk",     rekt:{x:8.2, y:68.2, w:3.4, h:0.9}},
    {id:"bank1",    rekt:{x:0.8, y:64.2, w:0.7, h:1.8}},
    {id:"bank2",    rekt:{x:0.8, y:66.4, w:0.7, h:1.8}},
    {id:"bank3",    rekt:{x:0.8, y:68.6, w:0.7, h:1.8}},
    {id:"kansli",   rekt:{x:6.3, y:62.4, w:0.3, h:9.4}},
    {id:"omkl",     rekt:{x:18.5, y:68.4, w:0.3, h:4.4}},
    {id:"trapphus", rekt:{x:19.0, y:66.6, w:1.4, h:2.8}},
  ],
  dorrar:[
    {id:"ut_o", pos:[24.2,5],    text:"Ut på gården", mot:"gard",
     spawn:{x:144.6,y:49,rikt:0}},
    /* HÄSTGÅNGEN till stallet: leder in i stallets klubbdel utan att man
       behöver gå ut på gården. Husen är sammanbyggda. */
    {id:"hastgang", pos:[RIDHUS_BREDD-2.97,41.58], text:"Hästgången — in i stallet",
     mot:"stallinne", spawn:{x:1.6,y:34.35,rikt:0}},
    {id:"ut_n", pos:[21.9,74.2], text:"Ut mot parkeringen (entrén)", mot:"gard",
     spawn:{x:139.9,y:120.6,rikt:Math.PI/2}},
  ],
  info:[
    {pos:[22.2,65.1], text:"Trappan till Café Krubban",
     svar:"Café Krubban har stängt för kvällen. Genom fönsterbanden ser man hela banan från borden där uppe."},
    {pos:[23.6,7],  text:"Domarbåset",
     svar:"Domarbåset — härifrån döms hoppklasserna på Påskhoppet. En trappa, en pall och bästa utsikten i huset."},
    {pos:[10.6,0.8],text:"Hinderförrådet",
     svar:"Hinderförrådet: bommar i blått, vitt och rött, kandelabrar, koner och cavaletti. ”HINDERSTÖD MED KLÄMHÅLLARE”, står det på lappen."},
  ],
};

STALLINNE.info=[
  {pos:[6.2,49.6], text:"Klubbrummet — rosettväggen", klubb:true,
   svar:"Uppehållsrummet: svarta soffor, hästfoton på pärlsponten och en rosa träponny med riktig sadel. Här väntar man in sin lektion."},
  {pos:[6.2,44.4], text:"Sadelkammaren", sadelkammare:true, svar:""},
  {pos:[8.8,47.5], text:"Teorilektion i teorisalen", teori:true,
   svar:""},
  {pos:[6.2,5.8],  text:"Spolspiltan", spolspilta:true, svar:""},
  {pos:[8.8,5.8],  text:"Spånförrådet",
   svar:"Spånförrådet: Mustang kutterspån på pall i galvad bur. Härifrån hämtas spånet du strör med när boxen är mockad."},
];

/* ── Varje ritad dörr ska gå att gå in genom ────────────────────────
   Dörrlistan ovan var handskriven, och husen ritade fler dörrar än den
   kände till — man stod framför en dörr, tryckte E och ingenting hände.
   Här genereras resten ur fasadöppningarna i stället: varje öppning i
   marknivå som är en dörr eller port på ridhuset eller stallet får en
   interaktionspunkt strax utanför och en spawn strax innanför. Redan
   listade dörrar vinner — de har egna texter och exakta spawnpunkter.

   Byggnadens inre koordinatsystem har origo i husets sydvästra hörn,
   så innerpunkten är världspunkten minus hörnet; det är samma tal i
   STALLINNE och RIDHUSINNE eftersom insidorna byggs i husets mått. */
(function autoDorrar(){
  const INNE={ridhus:{mot:"ridhusinne",matt:RIDHUSINNE},
              stall: {mot:"stallinne", matt:STALLINNE}};
  const DORR=/^(dorr|port)/;
  const TEXT={ridhus:"In i ridhuset", stall:"Gå in i stallet"};
  /* Fasadens p0→p1, medurs sett utifrån — samma konvention som
     ritningen i world.js, så u betyder samma sak här som där. */
  const vagg=(r,sida)=>
    sida==="S"?[[r.x,r.y],[r.x+r.w,r.y]]:
    sida==="E"?[[r.x+r.w,r.y],[r.x+r.w,r.y+r.h]]:
    sida==="N"?[[r.x+r.w,r.y+r.h],[r.x,r.y+r.h]]:
               [[r.x,r.y+r.h],[r.x,r.y]];
  const NORM={S:[0,-1], N:[0,1], E:[1,0], W:[-1,0]};
  for(const bg of ANL.byggnader){
    const inne=INNE[bg.id]; if(!inne)continue;
    for(const o of (bg.oppningar||[])){
      if(!DORR.test(o.typ)||o.z0>0.2)continue;
      /* Öppningar mot en sammanbyggd granne leder inte ut på gården. */
      if(o.intern)continue;
      const [p0,p1]=vagg(bg.rekt,o.sida);
      const L=Math.hypot(p1[0]-p0[0],p1[1]-p0[1]);
      const ux=(p1[0]-p0[0])/L, uy=(p1[1]-p0[1])/L, u=o.u+o.b/2;
      const mx=p0[0]+ux*u, my=p0[1]+uy*u;                 // mitt i öppningen
      const n=NORM[o.sida];
      const utx=mx+n[0]*1.1, uty=my+n[1]*1.1;             // markören utanför
      if(ANL.dorrar.some(d=>Math.hypot(d.pos[0]-utx,d.pos[1]-uty)<4))continue;
      const ix=mx-n[0]*1.6-bg.rekt.x, iy=my-n[1]*1.6-bg.rekt.y;   // spawn innanför
      /* En dörr som landar mitt i en boxrad går inte att gå ut genom —
         den hör till en planform stallet ännu inte har (dubbelstallet,
         se stallkortet). Hoppa hellre över den än att sätta en dörr som
         bara fungerar åt ena hållet. */
      if(bg.id==="stall"){
        const M=inne.matt;
        if(!M.gangytor.some(g=>ix>=g.x-0.4&&ix<=g.x+g.w+0.4
                             &&iy>=g.y-0.4&&iy<=g.y+g.h+0.4))continue;
      }
      ANL.dorrar.push({
        id:bg.id+"_"+o.sida+"_"+Math.round(o.u), pos:[utx,uty],
        text:TEXT[bg.id], mot:inne.mot, auto:true,
        spawn:{x:clamp(ix,0.9,inne.matt.bredd-0.9),
               y:clamp(iy,0.9,inne.matt.langd-0.9),
               rikt:Math.atan2(-n[1],-n[0])}});
      /* Motsvarande utgång inifrån, på samma ställe. */
      (inne.matt.dorrar||[]).push({
        id:"ut_"+bg.id+"_"+o.sida+"_"+Math.round(o.u),
        pos:[clamp(ix,0.9,inne.matt.bredd-0.9),clamp(iy,0.9,inne.matt.langd-0.9)],
        text:"Ut", mot:"gard", auto:true,
        spawn:{x:utx, y:uty, rikt:Math.atan2(n[1],n[0])}});
    }
  }
})();
