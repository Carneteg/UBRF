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
   ÅTERTAG 2026-08-30. Tre tal som en tidigare granskning klassade som
   VERIFIED har dragits tillbaka sedan Tobias ifrågasatt dem och
   screenshotarna öppnats igen:

     · 29,28 m är INTE stallets bredd — linjen går inte gavelhörn till
       gavelhörn.
     · 26,57 m är INTE ridhusets bredd — samma sak.
     · 39,83 m är INTE ett direkt längsmått till hästgången — bilden har
       tre mätpunkter, så talet är kumulativt.

   Jag hann bygga alla tre innan återtaget kom. De är nu utrivna.
   BREDDERNA ÄR DÄRMED OLÖSTA IGEN och står som `[REFERENCE GAP]`: 21 och
   25 m nedan är arbetsvärden, inte mått, precis som före hela turen.

   Värt att notera för nästa gång: när jag mätte utrymningsplanens EGEN
   längd/bredd-kvot landade bredden på 22–25 m vid längden 69,95. Jag skrev
   att direktmätningen vann över min avläsning. Planens kvot pekade rätt och
   29,28 låg utanför det spannet — motsägelsen fanns i materialet och jag
   valde bort den i stället för att stanna vid den.

   KVAR SOM MÄTT, med ärlig klassning:

     · stallets långaxel 69,95 m — `MEASURED`, Google Maps-tolerans. Huset
       är oregelbundet, så det definierar inte ett fullständigt rätblock.
     · ridhusets långaxel 77,18 m — `MEASURED`, samma tolerans.
     · gårdsgapet 8,10 m — `MEASURED LOCAL GAP` i det södra tvärsnittet.
       Inte bevis för konstant avstånd längs hela gården.

   Husens LÄGE härleds ur det som finns, i stället för att skrivas var för
   sig, så att ett ändrat mått inte lämnar ett grannobjekt på gammal plats.

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
const STALL_BREDD  = 21;     // `[REFERENCE GAP]` — se noten om återtaget
const RIDHUS_LANGD = 77.18;  // `VERIFIED`
const RIDHUS_BREDD = 25;     // `[REFERENCE GAP]` — se noten om återtaget
const GARDSGAP     = 8.10;   // `VERIFIED LOCAL` i södra tvärsnittet
/* Ridhusets norra gavel. Referenslinjen som allt annat mäts från, eftersom
   det är den gaveln som är mest fotoverifierad — caféet, ståltrappan och
   parkeringen framför. */
const RIDHUS_NORR = 119;

/* `[REFERENCE GAP]` HUSEN LIGGER FÖRSKJUTNA I LÄNGDLED.

   Modellen tvingade tidigare båda husens norra gavlar till SAMMA linje och
   kallade det `[VERIFIED]` "i liv, som i satellitbilden". Det var fel läst:
   satellitbilden visar husen förskjutna längs sin gemensamma axel, inte i
   liv. Ett påstående om liv är dessutom en STARKARE utsaga än underlaget bär
   — det säger att två ändar sammanfaller på decimetern.

   RIKTNINGEN VAR FÖRST FEL. Jag skrev att stallet låg förskjutet söderut
   och kallade riktningen "läsbar i satellitbilden". Den avläsningen gjordes
   ur minnet av en skärmbild som inte finns i repot, och den höll inte.

   Det som avgör finns i repot: `stall-gavel-06-silon.jpg`, tagen söder om
   båda husen. Ridhusets södra ände sträcker sig LÅNGT närmare kameran än
   stallets gavel — de ligger inte i närheten av varandra. Med stallet
   förskjutet söderut hamnade de två södra ändarna nästan i liv (43,05 mot
   41,82), vilket fotot motsäger direkt. Med förskjutningen åt andra hållet
   blir avståndet ~13 m, vilket stämmer med bilden.

   Stallet ligger alltså förskjutet NORRUT relativt ridhuset. Det stämmer
   också med Senior Site Fidelity Review 07:s avläsning av satellitkällan.

   STORLEKEN är fortfarande `[ASSUMPTION]`. 6 m är valt för att
   förskjutningen ska finnas och ha rätt tecken, inte för att den är mätt.

   `[REFERENCE GAP]` Det som stänger den: en satellitmätning från ridhusets
   norra gavelhörn till stallets, längs husens axel. Och — för att den här
   sortens tvist inte ska behöva avgöras ur minnet igen — satellitbilden i
   repot. */
const GAVELFORSKJUTNING = 6;   // stallet NORRUT relativt ridhuset
const RIDHUS_X = 118;
const RIDHUS_Y = RIDHUS_NORR - RIDHUS_LANGD;               // 41,82
const STALL_X  = RIDHUS_X + RIDHUS_BREDD + GARDSGAP;       // 152,67
const STALL_NORR = RIDHUS_NORR + GAVELFORSKJUTNING;        // 125
const STALL_Y  = STALL_NORR - STALL_LANGD;                // 55,05

/* `[REFERENCE GAP]` Hästgångens läge längs husen är OLÖST.

   39,83 m är återtaget: bilden har tre mätpunkter och talet är kumulativt,
   inte ett direkt längsmått till gången. Jag hann ankra gången på det; det
   är utrivet.

   Gången läggs i stället där stallets tvärkorridor mynnar — den enda plats
   den KAN mynna utan att gå in i en boxrad. Korridorens läge följer av den
   mätta längden 69,95 m och utrymningsplanens egna proportioner. Det är en
   härledning, inte ett mått, och den ska bytas mot ett rent tvåpunktsmått
   när ett sådant finns. */
const GANG_FASTE = STALL_Y + 27.8;                         // 76,85
const GANG_DJUP  = 3.5;                                    // `[ASSUMPTION]`

const STALL_BOXAR = 12;      // sex söder om tvärkorridoren, sex norr

/* ══ TRÄNINGSYTORNA ════════════════════════════════════════════════════
   Review 06 blocker 2: lös det här REALITY-FIRST, inte UTEBANA-first.

   Källorna visar FLERA inhägnade sandytor nordost om husen, och spelet hade
   en enda bana. Att fråga "hur stor är spelets bana" var fel fråga; rätt
   fråga är "vilka ytor finns, och vilken av dem rider man på".

   Ytorna listas därför med NEUTRALA plats-ID, oberoende av vad de heter i
   spelet. `33,57` hör till `NO_STOR` oavsett vilket gameplaynamn den ytan
   senare får — det är en egenskap hos marken, inte hos spelobjektet.

   Underlag: references/omnejd/banan-01..03 och
   references/site/BANIDENTITET.md.

     · `NO_STOR`   — den stora ytan. `banan-03` visar ekipage på den och
                    hästar uppbundna längs dess bortre staket; belysnings-
                    masterna står runt DEN. Kortsidan **33,57 m**
                    `MEASURED SIDE`. Långsidan `[REFERENCE GAP]`.
     · `NO_LITEN`  — den lägre sandytan i förgrunden i `banan-03`, avskild
                    från den stora med en kant. Mått `[REFERENCE GAP]`.

   `[REFERENCE GAP]` BÅDA YTORNAS LÄGE på tomten. Marknivåbilderna visar
   deras inbördes ordning men inte var de ligger relativt husen. Rektanglarna
   nedan är arbetslägen som håller dem norr om gavellinjen och innanför
   tomten — inte mätta lägen.

   SPELETS BANA. `UTEBANA` pekar på `NO_LITEN`, och det är ett `[ASSUMPTION]`
   som BANIDENTITET.md redovisar öppet: masterna talar för den stora,
   storleken för den lilla. Kopplingen ligger på EN rad här nere, så när
   Tobias säger vilken det är räcker det att flytta pekaren. ══ */
const TRANINGSYTOR = {
  /* Kortsidan är mätt; långsidan är ett arbetsvärde som ryms mellan
     gavellinjen och tomtdjupet 170. Att den ryms säger inget om UBRF. */
  /* x flyttad från 170 till 173: med stallets gavelförskjutning norrut nådde
     huset in i ytan, och byggnad-i-ridbana-testet fällde det. Läget är ändå
     ett arbetsvärde — det enda som styr det är att ytan ska ligga norr om
     husen, öster om stallet och innanför tomten. */
  NO_STOR:  {x:173, y:126, w:33.57, h:40, matt:"kortsida MEASURED 33,57"},
  NO_LITEN: {x:150, y:132, w:18,    h:24, matt:"REFERENCE GAP"},
};

/* Spelets uteridbana och paddock pekar in i listan ovan. En rad var. */
const UTEBANA = TRANINGSYTOR.NO_LITEN;
const PADDOCK = TRANINGSYTOR.NO_STOR;

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
    /* Gårdsplanen ska MÖTA stallets södra gavel, inte sluta en bit ifrån
       den. Höjden räknas därför fram; med ett fast tal blev det ett
       gräsband mellan grus och vägg varje gång gaveln flyttade. */
    {typ:"grus",  rekt:{x:148, y:40,  w:44,  h:STALL_Y-40}},  // gårdsplanen vid stallets södra gavel
    {typ:"grus",  rekt:{x:186, y:16,  w:8,   h:28}},   // väggrenen upp från infarten
    {typ:"grus",  rekt:{x:STALL_X+STALL_BREDD, y:STALL_Y+6, w:3, h:STALL_LANGD-8}}, // gången öster om stallet mot hagarna

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
     hV:6.2, hN:9.2, nock:"NS",
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
       /* HÄSTGÅNGEN till stallet. u mäts från södra gaveln och räknas ur
          GANG_FASTE, så den följer med när gången flyttar. Talen 89,3–92,8
          som stod här var två flyttar gamla. */
       {sida:"E", u:(GANG_FASTE+0.55)-RIDHUS_Y, b:2.4, h:2.6,
        z0:0, typ:"portbla", intern:true},
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
    /* Stallets norra gavel ligger INTE i liv med ridhusets — se
       GAVELFORSKJUTNING ovan. Båda vetter mot grusplanen, men förskjutna.
       Ytan mellan husen är inte heller en verifierad obruten gräsgård:
       husen är sammanbyggda (Tobias på plats), och gården är det som blir
       kvar mellan förbindelserna. Se hastgang nedan. */
    {id:"stall", rekt:{x:STALL_X, y:STALL_Y, w:STALL_BREDD, h:STALL_LANGD},
     /* Nocken hör ihop med bredden: 4,4 + 21/2 × tan 28° = 10,0. När bredden
        kortvarigt stod på 29,28 räknades nocken om till 12,18; båda är
        utrivna med återtaget. Geometrispecen mäter resningen, inte nocken. */
     hV:4.4, hN:10.0, nock:"NS",
     fargV:"#6E2F44", fargT:"#5E646C", svart:"#26292E", takfot:"#EEECE4",
     detalj:"stall", sockel:0.35, label:"STALLET",
     oppningar:[
       /* Långsidans dörr. Här satt förstukvisten med sina runda fönster
          fram till 2026-09-02; produktägaren flyttade verandan till gaveln
          (se KORT.md). Kvar blir en enkel ockragul dörr under ett skärmtak
          — den som tidigare satt på gaveln. De två har bytt plats. */
       {sida:"W", u:sV(5.6), b:1.15, h:2.10, z0:0,    typ:"dorrgul", skarm:1.7},
       {sida:"W", u:sV(2.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},
       {sida:"W", u:sV(8.6), b:1.15, h:1.55, z0:1.55, typ:"valv"},
       /* HÄSTGÅNGEN mot ridhuset. På W mäts u från NORRA gaveln söderut,
          så tvärkorridorens mitt (lokalt y 26,05) ligger på u 26,75. */
       {sida:"W", u:sV(STALL_NORR-(GANG_FASTE+GANG_DJUP-0.55)), b:2.4, h:2.6,
        z0:0, typ:"portbla", intern:true},
       ...stallFonster("W"), ...stallFonster("E"),
       /* Norra gaveln — klubbgaveln mot grusplanen, den höga, med
          balkongen och spiraltrappan (stall-fasad-04/05). */
       {sida:"N", u:6.4,  b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"N", u:14.6, b:1.15, h:1.55, z0:4.75, typ:"valv"},
       {sida:"N", u:8.4,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       {sida:"N", u:12.6,  b:1.10, h:1.50, z0:2.60, typ:"valv"},
       /* Balkongdörren och klubbentrén ligger nu BÅDA med sin mitt i
          gavelmitten (u = 10,5). Talen stod förut på u 10,5 som HÖRN, vilket
          la mitten 0,5–0,6 m öster om gaveln mitt — kommentaren sa "i
          gavelns mitt" men koden gjorde något annat. Balkongen har alltid
          centrerats, så de låg heller inte i liv med varandra. */
       {sida:"N", u:10.5-0.95/2, b:0.95, h:2.05, z0:4.60, typ:"dorrvit"},  // balkongdörren
       /* KLUBBENTRÉN, nu under förstukvisten. Inget eget skärmtak: verandan
          är dess tak. Skärmtaket följde med den enkla dörren till
          långsidan. */
       {sida:"N", u:10.5-1.15/2, b:1.15, h:2.05, z0:0, typ:"dorrgul"},
       /* De runda fönstren flankerar entrédörren och hör till förstukvisten
          — de följde med den hit från långsidan. ±1,6 m från dörrens mitt,
          samma avstånd som de hade där. */
       {sida:"N", u:10.5-1.6-0.66/2, b:0.66, h:0.66, z0:1.78, typ:"rund"},
       {sida:"N", u:10.5+1.6-0.66/2, b:0.66, h:0.66, z0:1.78, typ:"rund"},
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
       argument som byggde på ett 54 m långt hus. Det resonemanget — husens
       gemensamma mitt på y 92,0 och korridoren på y 89,3–92,8 — gällde en
       geometri som inte finns längre, och är struket. Det stod kvar i två
       flyttar och sade emot den aktiva koden hela tiden.

       Gången ligger där stallets tvärkorridor mynnar. Läget räknas ur
       GANG_FASTE och följer därför automatiskt med när gaveln flyttar; se
       konstanten längst upp. Det är den enda plats gången KAN mynna utan
       att gå in i en boxrad.

       Gångens eget läge är fortfarande omätt (MATLISTA punkt 4); det här är
       det läge som följer av ett verifierat längdmått plus planens
       proportioner, vilket
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
    /* `[ASSUMPTION]` — LÄGET ÄR INTE KÄNT. Längan låg y 59..65 och hamnade
       inne i husens nya utbredning när måtten kom. Den ligger nu y 43..49.

       RÄTTELSE AV MOTIVERINGEN. Jag skrev först att den flyttats "för att
       behålla sin roll" som gårdens södra avslutning. Senior Site Fidelity
       Review 04 underkänner det resonemanget, och med rätta: ett objekt vars
       verkliga läge är okänt får inte flyttas för att bevara en roll man
       själv har tilldelat det. Den är flyttad av EN anledning — den krockade
       med verifierad geometri — och det nya läget är lika osourcat som det
       gamla. Den styr ingenting annat och ska inte läsas som placerad.

       ANDRA FLYTTEN. När gavelförskjutningen lade stallet sex meter söderut
       krockade längan igen, 17,3 m². Byggnadsöverlappstestet fällde det
       direkt. Flyttad till y 34..40.

       Att den nu har flyttats två gånger utan att någon källa sagt något om
       var den står är i sig ett argument: den kanske inte hör hemma i den
       kanoniska geometrin alls, utan borde plockas bort tills något visar
       att den finns och var. Jag tar inte bort den på eget bevåg — men
       nästa gång den krockar bör frågan ställas i stället för att den
       flyttas en tredje gång. */
    {id:"langa", rekt:{x:147, y:34, w:7, h:6}, hV:3.0, hN:4.4, nock:"EW",
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
    {typ:"tra", p:[[178,65],[206,65],[206,93],[178,93],[178,65]]},     // hage Ö1
    {typ:"tra", p:[[178,97],[206,97],[206,117],[178,117],[178,97]]},   // hage Ö2
    {typ:"el",  p:[[112,20],[112,121]]},                               // trådstängsel mot åkern
    {typ:"rail",p:[[155,121.5],[168,121.5]]},                          // rail framför klubbgaveln
    {typ:"rail",p:[[96,127],[96,136]]},                                // rail vid lekhagen
  ],
  hagar: [ // betande hästar (id ur HORSES) för liv i bilden
    {rekt:{x:178,y:65,w:28,h:28}, hastar:["cosmo","air","mara"]},
    {rekt:{x:178,y:97,w:28,h:20}, hastar:["larry","husky","westside","lydia"]},
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

       ANDRA GÅNGEN. Gaveln flyttade först från y = 65 till 49,05 när längden
       mättes, och silon följde med — som ett TAL. När gavelförskjutningens
       tecken sedan vändes flyttade gaveln till 55,05 och talet stod kvar, så
       silon lämnades 6 m ut på gården trots att källan säger att den står
       tätt mot väggen. Review 08 fällde det.

       Läget räknas därför ur gaveln i stället för att skrivas. Radien är
       1,5 m i v3dRekvisita, så mantelns kant hamnar 0,05 m från väggen
       oavsett var gaveln hamnar härnäst. Samma sak för balarna. */
    {typ:"silo",      pos:[STALL_X+STALL_BREDD/2, STALL_Y-1.55]},
    {typ:"balar",     pos:[STALL_X+2.5, STALL_Y-4.6]},   // ensilagebalarna, väster om silon
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
    /* FÖRSTUKVISTEN sitter på NORRA GAVELN, centrerad i gavelmitten och
       utskjutande mot grusplanen.

       Den satt fram till 2026-09-02 på västra långsidan, 5,6 m från norra
       gaveln, vilket är vad `stall-fasad-03/04/05` visar. Produktägaren har
       efter att ha sett bygget beslutat att verandan och gavelns enkla
       skärmtaksdörr ska BYTA PLATS. Placeringen här följer det beslutet och
       INTE fotografierna; se noten i references/buildings/stall/KORT.md så
       att ingen läser den som fotoverifierad. */
    forstukvist:{uFranOst:10.5, bredd:5.2, djup:2.8,
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
       tvärväggar. När det byggs ska det läsa de här värdena.

       OMMÄTNING (den här gången mot BÅDA bildrutorna, inte en):
       #C39575 och #878783 kom ur EN bildruta med ljust tak. Med samma
       värmemask körd på båda bildrutorna, och maskerna visuellt
       kontrollerade som röd/cyan overlay innan medianen togs:

         limträ    #987B65 (i05, skuggat tak)  /  #C2987B (i06, ljust tak)
         takplåt   #6B6C68 (i05)               /  #767574 (i06)

       De två bildrutorna skiljer sig mycket på limträet — taket är belyst
       helt olika. Medelvärdet är det ärliga enskilda värdet, och spridningen
       står här så att ingen tror att siffran är exaktare än den är.
       `MEASURED`, spridning ±0,15 i ljushet mellan bildrutorna. */
    stallgang:{limtra:"#AD8A70", takplat:"#70716E"},
    /* BOXFRONTERNA — färger MÄTTA, form läst ur samma två bildrutor.

       Bildrutor: `stall-inne-05-stallgangen.jpg` (fronterna utifrån gången)
       och `stall-inne-06-boxen-inifran.jpg` (samma konstruktion inifrån en
       box). Två oberoende vinklar, olika ljus.

       Metod: leta upp ytan, beskär den, TITTA på beskärningen, och mät
       först därefter. Ett första försök med rena tröskelvärden (mörka
       neutrala pixlar = panel) gav #48/#41 beroende på var tröskeln sattes
       — det mätte tröskeln, inte panelen. De beskurna proven nedan är
       visuellt kontrollerade mot rätt yta innan medianen togs.

         mörk heldel   #454B53 (sd 20, 131 kpx)  /  #43474A (sd 10, 43 kpx)
         galvat        #9A998F (sd 20,  24 kpx)  /  #999C97 (sd 37,  8 kpx)

       `KNOWN MISMATCH` som det här åtgärdar: Roblox byggde fronter och
       mellanväggar i BRUNT TRÄ (Color3.fromRGB(126,96,66), WoodPlanks)
       medan fotona visar mörk antracitpanel i galvad stålram, och medan
       webben redan ritade dem grå. Två sanningar om samma yta, och den
       bruna fanns bara i Roblox-filen. Färgerna hör därför hemma här.

       FORM, `VERIFIED` i båda bildrutorna:
       - nedre delen är en tät panel med LODRÄTA spår (skivprofil), mörk
         antracit, med en vågrät stålskarv en bit upp,
       - ovanpå panelen ligger en bred galvad kapp-/hyllregel,
       - däröver sitter VÅGRÄTA runda galvade reglar mellan lodräta
         ändstolpar — jag räknar fem i den breda fasta sektionen,
       - stolparna går upp till ramens överliggare.

       `KNOWN MISMATCH` nummer två: webben ritade sju LODRÄTA spjälor per
       box och inga vågräta alls. Det är fel läsning av samma bild.

       `[REFERENCE GAP]`: dörrbladet är ett rutnät (vågrätt OCH lodrätt)
       och sitter i en smalare sektion av fronten, men vilken del av varje
       box som är dörr går inte att läsa ur bilderna för alla boxar. Det
       modelleras därför inte per box.

       `heldel` = den täta panelen, `ram` = kappregel, ändstolpar och
       reglar. Måtten är DERIVED: panelens överkant och ramens överliggare
       är de mått spelet redan hade, och de fem reglarna delar spannet
       däremellan jämnt. */
    boxfront:{heldel:"#454A4F", ram:"#9A9B93",
              heldelH:1.35, ramZ:1.38, stolpH:2.15, toppregelZ:2.20,
              reglar:5, regelD:0.04},
    /* Balkongen och spiraltrappan på klubbgaveln — stall-fasad-04/05.
       Balkongen sitter mitt för sin dörr, alltså i gavelns mitt. */
    balkong:{z:4.55, bredd:2.2, djup:1.10, rackeH:0.92},
    /* Spiraltrappan flyttad ut från 2,3 till 3,4 m från gavelmitten. När
       förstukvisten (5,2 m bred) kom till gaveln nådde verandan ut till 2,6
       m och trappan stod mitt i den. 3,4 m ger trappans innerkant 0,45 m fri
       från verandans kant. Talet är ett arbetsvärde [enligt Tobias], inte
       en mätning. */
    spiraltrappa:{franGavelmitt:3.4, radie:0.70, steg:18},
  },
  ridhus: {
    /* MOTSÄGELSE 1 — IMG_0183: mörkröd övre långvägg ovanför sargen, med
       vita läkt som horisontella detaljer.

       OM-AUDITENS PUNKT B, nu åtgärdad: spelet målade BÅDA långsidorna i
       hela sin längd. `ridhus-inne-02-langsidan.jpg` visar att den
       rostbruna panelen täcker en DEL av EN långsida — resten av samma
       vägg är ljus. Väggen ligger på västra långsidan, mitt emot läktaren,
       och det är på den sponsorskyltarna hänger (punkt C).

       OMGRANSKAD 2026-09-03 (docs/F02-RIDHUS-OMGRANSKNING.md, rad 3):
       panelen är INTE partiell. `ridhus-inne-31` fångar hela långsidan i
       en bildruta från läktaren och panelen är obruten hörn till hörn;
       `ridhus-inne-17` visar den gå ända in i hörnet mot den vita
       A-gaveln. references/buildings/ridhus/INTERIOR-MATRIS.md § 4:
       "Panelen täcker hela långsidan" — `VERIFIED`. Det "ljusa" som en
       gång lästes som resten av väggen var sargen under och fönstren över.
       y0/y1 härleds därför nedan till hallens hela längd (0 → langd −
       entre); talen här är platshållare. */
    ovreVagg:{overSarg:0.1, underTak:1.6, tjocklek:0.08, listar:3,
              sida:"W", y0:0, y1:0},
    /* FÖNSTERBANDET ovanför panelen — `KNOWN MISMATCH B`, andra halvan.

       `ridhus-inne-02-langsidan.jpg` visar tydligt ett band av fönster
       mellan panelens överkant och takfoten: ljusa fält med mörka karmar
       och poster. Spelet hade bara tom vägg där, och det är en stor del av
       varför långväggen läser som en enfärgad yta.

       OMGRANSKAD 2026-09-03: fönstren är INTE ett löpande band utan
       SEPARATA öppningar, en per väggfält mellan de mörka pilastrarna —
       `ridhus-inne-31`, `-17`, `-24` (INTERIOR-MATRIS § 4, `VERIFIED`).
       Fälten följer takstolarna (`takstomme.delning`, DERIVED); varje
       fönster sitter centrerat i sitt fält, `faltBredd` är
       [uppskattning] ur -17 (ungefär halva fältet).
       `[REFERENCE GAP]`: fönstrens höjd och exakta bredd. */
    fonsterband:{h:0.95, underTak:0.5, tjocklek:0.06, postDelning:2.4,
                 perFalt:true, faltBredd:3.0,
                 glas:"#DCE6EC", karm:"#4A3B2E"},
    /* LÄKTARLÅNGSIDANS VÄGG — `VERIFIED` `ridhus-inne-14` + produktägaren
       2026-08-31 (INTERIOR-MATRIS § 5): ljus stående skivpanel med MÖRKA
       PELARE, en egen yta skild från sponsorväggens panel. Spelet målade
       den i samma platta ton som alla andra väggar. Pelarna står där
       takstolarna landar (`takstomme.start/delning`, DERIVED — samma
       rytm som pilastrarna på panelsidan i `-31`); skivornas skarvar är
       [uppskattning]. Färgen på skivorna är `hallvagg` (mätt), pelarnas
       mörkbruna ton är läst ur -14 [uppskattning]. */
    laktarVagg:{pelareB:0.24, pelareFarg:"#4A3A2C", skarvDelning:1.2,
                skarvFarg:"#C9C6BC", skarvB:0.03},
    /* OM-AUDITENS PUNKT A: läktarens front mot banan.

       Spelet byggde läktaren som öppna ljusa furutrappsteg hela vägen ner.
       Båda interiörfotona är tagna FRÅN läktaren, och båda visar samma sak
       i förgrunden: ovansidan är ett brett plankdäck, och framsidan mot
       banan är en HÖG, SOLID, MÖRKBETSAD BRÄDVÄGG av liggande panel. Man
       ser inte in under den från banan.

       OMGRANSKAD 2026-09-03: läsningen ovan vilar på en BESKUREN
       `ridhus-inne-01`, samma bild som fällde läktarraderna; INTERIOR-
       MATRIS § 2 har återkallat "solid mörkbetsad brädfront" och satt
       kappregeln till `[REFERENCE GAP]`. Fältet står kvar tills F02-B:s
       läktarrader (tre stegade bänkrader, `-07`/`-14`/`-43`) tar över;
       klassen är `[REFERENCE GAP]`, inte VERIFIED. */
    laktarfront:{brada:0.22, tjocklek:0.10, farg:"#4E3626", fogFarg:"#3E2B1E"},
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
  /* `[REFERENCE GAP]` Bredden är projektets äldsta öppna fråga och är
     fortfarande öppen. 29,28 m stod här kortvarigt som VERIFIED och är
     ÅTERTAGET — linjen gick inte gavelhörn till gavelhörn. 21 m är ett
     arbetsvärde i intervallet 15–23 m, se buildings/stall/KORT.md.
     Bandindelningen i STALL_BAND är proportionell och följer med om
     siffran ändras. */
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
  /* Väggen OMMÄTT ur stall-inne-09: #C1C0C3 (sd 2,0), en kall neutral vit.
     Stod som #CFC8BC, varmare och ljusare — det är en del av varför
     servicedelen läste som en krämfärgad korridor. */
  vagg:"#C1C0C3", golv:"#8C8880", gangGolv:"#9A968E", tak:3.4,
  /* Servicedelens golv är en slät ljus BETONGPLATTA, inte marksten.
     stall-inne-09 visar de två materialen sida vid sida med en rak gräns:
     betong under spolbommarna, marksten i genomgångsstråket. `MEASURED`
     #AEA28C (sd 6,9).

     `serviceGolvBredd` är hur långt betongen når ut från ytterväggen. Plattan
     ritades först över HELA buktens rektangel (4,5 m), och då blev den en stor
     ljus yta rakt framför spelaren som kom in genom gaveln — jag identifierade
     den med ett magentatest: 138 535 pixlar, hela vänstra bildhalvan. Fotot
     visar en SMAL remsa längs väggen med marksten i stråket bredvid, inte ett
     betonggolv över hela bukten. `DERIVED`: 2,2 m är buktens djup fram till
     bommarna; gränsens exakta läge går inte att mäta ur bilden. */
  serviceGolv:"#AEA28C", serviceGolvBredd:2.2,
  /* Gångens två golvytor, MÄTTA ur stall-inne-05 med samma
     beskär-titta-mät-metod som boxfronterna.

       marksten   #867D6C  (sd 17)  — varmgrå marksten i löpförband
       spånremsa  #A79679  (sd 49)  — spånet som ligger ut från boxarna

     De låg som lokala tal i src/varld3d.js: markstenen som ren vit
     bottenfärg under en textur, spånremsan som #D8C9A4. Roblox har i sin tur
     en egen INRE.gang. Tre tal för samma golv, och ingen av dem mätt.

     Spånremsan är INTE ett fel: fotot visar tydligt spån som ligger ut i
     gången längs boxfronterna. Den var bara för gul och för ljus. */
  gangSten:"#867D6C", gangSpan:"#A79679",
  /* Takresningen från takfot till nock inne i boxhallen. Låg som ett
     lokalt tal (RESN=2.1) i src/varld3d.js, alltså som en byggnadsfakta
     inuti en renderare — och Roblox hade därför ingen. Nu läser båda
     ytorna den härifrån.
     `DERIVED`: fotona visar en flack sadel över boxhallen, men vinkeln går
     inte att mäta ur dem. 2,1 m på 21 m bredd är den resning spelet redan
     hade och som stämmer med bildernas intryck. Ändras STALL_BREDD ska den
     räknas om. */
  takresning:2.1,
  /* Zonerna följer utrymningsplanens EGNA proportioner, inte en blind
     sträckning. Mätt på references/plans/stall-plan1-utrymning-rak.jpg:
     de genomgående tvärväggarna mellan klubbdel och boxhall ligger på
     0,72–0,755 av längden från södra gaveln, alltså 50,4–52,9 m. klubbY
     sätts till 52,85.

     Boxantalet följer av samma plan: partierna i mittraden räknas till
     ungefär TOLV per rad, inte nio. 12/9 = 1,33 mot längdkvoten
     69,95/54 = 1,30 — planen och det mätta måttet pekar åt samma håll,
     och nio boxar var en följd av det för korta huset.

     Kontroll: 6,8 + 13 × 3,5 = 52,3 ≤ 52,85.

     TRETTON per rad, inte tolv. Tolv var en följd av tvärgången: en
     korridor tvärs hela huset mitt i boxhallen, som tog en boxbredd ur
     varje rad. Planen har ingen sådan korridor — se `brott` nedan — och
     `references/plans/README.md` räknade redan "ungefär 13 boxfack per
     länga". Antalet räknas ut ur måtten längre ner (`antalBoxar`), inte
     skrivs. Fasadens fönsterrytm läser STALL_BOXAR och är låst; de två
     talen är därför medvetet skilda åt. */
  klubbY:52.85, boxStartY:6.8, serviceY:6.5,
  boxB:3.5,
  /* HÄSTFÖRBINDELSEN BRYTER VÄSTRA BOXRADEN — inte hela huset.

     Spelet hade en tvärgång tvärs hela bredden på y 27,8–31,3, med sex
     boxar på var sida. Det var en läsning ur en sned bild av planen. I den
     raka bilden (`stall-plan1-utrymning-rak.jpg`), mätt med
     `tools/f02-planmatning.py`: de två mittraderna och östra raden fortsätter
     obrutna förbi hästgångens höjd — boxskiljare på 38,3 och 41,3 m från
     norra gaveln, och brandsläckarna står i gångarna, inte i en korridor.
     Bara VÄSTRA ytterraden, den som vetter mot ridhuset, är bruten: väggpar
     på 38,7 och 40,8 m från norr, alltså y 29,15–31,25 lokalt. Tobias
     bekräftade läsningen på plats: hästförbindelsen bryter boxraden
     ungefär på mitten.

     Brottet läses ur SAMMA tal som fasadens hästgångsdörr (GANG_FASTE,
     GANG_DJUP och dörrens 2,4 m i ANL), så att den inre öppningen och den
     yttre inte kan glida isär: det är EN förbindelse, inte två. Fasaden är
     låst; planens 29,15–31,25 ligger 0,8 m söder om dörrens 28,35–30,75,
     inom planbildens skalfel. `PLAN` för läget, dörrbredden `ASSUMPTION`. */
  brott:[{rad:"W", id:"hastgang",
          y0:GANG_FASTE+GANG_DJUP-0.55-2.4-STALL_Y,
          y1:GANG_FASTE+GANG_DJUP-0.55-STALL_Y}],
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
  /* `rum` var tre solida lådor som svävade i en "klubbhall": uppehållsrum
     och teorisal på var sin långsida, sadelkammaren i ett hörn. Ingen av
     rektanglarna var läst ur planen — de var `ASSUMPTION` och underkändes
     av Product Owner 2026-09-03. Listan står kvar tom så att servicedelens
     bukter kan läsas ur samma slinga som förut; klubbdelen är `klubb`. */
  rum:[],
  /* ═══ KLUBBDELEN — ur utrymningsplanen, rättad av Product Owner ═══

     Källordning: 1 Tobias rättelse på plats · 2 `stall-plan1-utrymning-rak.jpg`
     för geometri och orientering · 3 foton för utseende · 4 den gamla
     implementationen bara som jämförelse.

     Tobias, som har gått rundan: man kommer in från parkeringen (norra
     gaveln), först in i UPPEHÅLLSRUMMET. TEORISALEN ligger till vänster om
     det. SADELKAMMAREN når man genom att gå vänster och sedan höger. I
     uppehållsrummets bortre ände sitter TVÅ TOALETTER, en på var sida, med
     den inre entrén till stallet emellan. Rakt fram genom den kommer man in
     i STALLGÅNG A. "Vänster" är gående riktning med ryggen mot parkeringen,
     alltså ÖSTER — se docs/F02-INTERIOR-MATRIS.md.

     Planen, mätt i bildpunkter (`tools/f02-planmatning.py`, klubbändens
     vägglinjer): huset spänner rad 273–1657 i bilden för 69,95 m, kolumn
     536–968 för bredden. N nedan är meter från norra gaveln; y = 69,95 − N.
     Tvärled vilar på den olösta bredden 21 m (`ASSUMED_SCALE`), längdled på
     den verifierade längden (`PLAN`).

       · entré i norra gaveln x 3,6–5,5, vindfångets två stumpar N 0–2,0
       · UPPEHÅLLSRUMMET — L-format och större än en tidigare läsning:
         västdelen x 0–5,9, N 0–10,0, och östdelen x 5,9–11,2, N 0–5,6
         (öster om entrén, norr om den slutna volymen) utan vägg emellan.
         Product Owner 2026-09-03: "uppehållsrummet är för litet" — den
         förra läsningen stannade vid x 5,9 och kallade östdelen "passage".
         Pentryt (stall-inne-02: valvfönster + runt fönster, hörn med
         tavla) sitter i NV-hörnet väster om entrédörren; stall-entre-01
         visar samma fönsterpar utifrån, väster om dörren.
       · i västdelen en SLUTEN VOLYM x 2,0–3,0 N 5,6–10,0, ritad med
         dubbla linjer (vägg med tjocklek) — funktion oläsbar. Läst i
         originalbilden `stall-plan1-utrymning.jpg` (4032 px, klubbänden
         beskuren och vriden norr upp); en tidigare läsning i den
         rektifierade 1500 px-bilden såg den som en tjock vägg x 2,8–3,5.
       · W-toaletten x 0–3,0 N 10,0–12,5 med dörr i ÖSTVÄGGEN N 10,8–11,7
         mot lobbyn, och en lucka x 0–0,9 i nordväggen (planens linje
         börjar 0,9 m från västväggen). Foto finns på en
         tillgänglighetsanpassad toalett; vilken av de två är `ASSUMPTION`.
       · lobbyn x 3,0–5,9 N 10,0–12,5 med planens gröna pil ner genom
       · den INRE ENTRÉN: dörr i den genomgående väggen x 4,1–5,0 — rakt
         nedanför gaveldörren och rakt ovanför gång A (4,1–6,7)
       · Ö-toaletten x 5,9–7,3 N 10,7–12,5 (cellen vid symbolrutans fot)
       · en SLUTEN VOLYM x 5,9–7,3 N 4,9–10,7 — planen ritar en symbol i
         rutan som ingen oberoende källa förklarar; funktionen är
         `REFERENCE GAP`, se noten vid `sluten_volym`
       · i uppehållsrummets östdel ett litet slutet rum x 9,0–11,2
         N 0–2,2 (grå ruta = utanför utrymningsytan; funktion oläsbar)
       · TEORISALEN x 11,2–17,3 N 0–5,6, in genom en 2,6 m öppning i
         västväggen N 3,0–5,6
       · SADELKAMMAREN x 7,3–15,5 N 5,6–12,5, in från passagen genom
         x 7,3–8,8 vid N 5,6; egen dörr söderut i den genomgående väggen
         x 7,7–8,8; en halvvägg x 9,0–12,2 vid N 9,1 vars funktion är oläst
       · ÖSTRA RUMMET x 15,5–21 N 5,6–12,5 plus x 17,3–21 N 0–5,6, med
         planens utgång österut vid N 9,9 — `DEFERRED BY EXTERIOR LOCK`
       · den GENOMGÅENDE VÄGGEN vid N 12,5 (y 57,45) tvärs hela huset, med
         de två dörrarna ovan. Förra rundan lästes den som öppen 0–8,97 m i
         väster; det var fel — den mörka andelen 0,61 var den slutna volymens
         och dörrarnas linjer, inte ett hål. Ersatt.

     MOTSÄGELSER som INTE löses här (fasaden är låst, se KORT.md):
       · planens gaveldörr sitter x 3,6–5,5; den låsta fasadens entré sitter
         mitt på gaveln (10,5). `ut_n` nedan pekar in i planens vindfång,
         fasadmarkören står kvar vid den låsta dörren.
       · den låsta långsidesdörren 5,6 m från gaveln (`ut_n2`) finns inte i
         planen; den mynnar i uppehållsrummet och behålls.
       · gavelns runda fönster (x 8,2 och 11,4 i fasaden) hamnar i passagen
         och teorisalen, inte i uppehållsrummet som fotona ger runda fönster.

     `vaggar` är segment med öppningar; `rum` är REGIONER. Ett rum utan
     `stangt` är golv man går på — väggarna gör allt spärrande. Roblox
     bygger samma lista genom Geometri.vaggBitar. */
  klubb:{
    y0:57.45,
    vaggar:[
      {id:"genomgaende", typ:"tvar", y:57.45, x0:0, x1:STALL_BREDD, brand:true,
       oppningar:[{id:"inre_entre", x0:4.1, x1:5.0},
                  {id:"sadelkammare", x0:7.7, x1:8.8}]},
      {id:"vindfang_v",  typ:"langs", x:3.6, y0:67.95, y1:69.95},
      {id:"vindfang_o",  typ:"langs", x:5.5, y0:67.95, y1:69.95},
      {id:"vindfang_fot",typ:"tvar",  y:67.95, x0:5.5, x1:6.0},
      {id:"wc_v_n",      typ:"tvar",  y:59.95, x0:0, x1:3.0,
       oppningar:[{id:"wc_v_lucka_n", x0:0, x1:0.87}]},
      {id:"wc_v_o",      typ:"langs", x:3.0, y0:57.45, y1:59.95,
       oppningar:[{id:"wc_v_dorr", y0:58.25, y1:59.15}]},
      {id:"volym_v",     typ:"langs", x:5.9, y0:57.45, y1:65.05},
      {id:"volym_o",     typ:"langs", x:7.3, y0:57.45, y1:65.05},
      {id:"volym_n",     typ:"tvar",  y:65.05, x0:5.9, x1:7.3},
      {id:"volym_s",     typ:"tvar",  y:59.25, x0:5.9, x1:7.3},
      {id:"litet_v",     typ:"langs", x:9.0, y0:67.75, y1:69.95},
      {id:"litet_s",     typ:"tvar",  y:67.75, x0:9.0, x1:11.2},
      {id:"teorisal_v",  typ:"langs", x:11.2, y0:64.35, y1:69.95,
       oppningar:[{id:"teorisal_dorr", y0:64.35, y1:66.95}]},
      {id:"teorisal_s",  typ:"tvar",  y:64.35, x0:8.8, x1:17.3},
      {id:"teorisal_o",  typ:"langs", x:17.3, y0:64.35, y1:69.95},
      {id:"sadelkammare_o", typ:"langs", x:15.5, y0:57.45, y1:64.35},
      {id:"sadelkammare_mellan", typ:"tvar", y:60.85, x0:9.0, x1:12.2},
    ],
    rum:[
      {id:"vindfang",     rekt:{x:3.6,  y:67.95, w:1.9, h:2.0},  label:"ENTRÉ"},
      /* UPPEHÅLLSRUMMET är L-format: västdelen här och östdelen
         `uppehallsrum_o` nedan, utan vägg emellan (`del` pekar hit). */
      {id:"uppehallsrum", rekt:{x:0,    y:59.95, w:5.9, h:10.0}, label:"UPPEHÅLLSRUM"},
      /* Den dubbellinjeritade rutan i västdelen: 1,0 × 4,4 m, funktion
         oläsbar (`REFERENCE GAP`). Byggs som sluten volym utan namn. */
      {id:"sluten_volym_v", rekt:{x:2.0, y:59.95, w:1.0, h:4.4}, label:"", stangt:true},
      {id:"wc_v",         rekt:{x:0,    y:57.45, w:3.0, h:2.5},  label:"WC"},
      {id:"lobby",        rekt:{x:3.0,  y:57.45, w:2.9, h:2.5},  label:""},
      /* Ö-toaletten: en dörr går inte att läsa i planen och hittas inte på.
         `stangt`: byggs som sluten volym tills dörren är belagd. */
      {id:"wc_o",         rekt:{x:5.9,  y:57.45, w:1.4, h:1.8},  label:"WC", stangt:true},
      /* SLUTEN VOLYM UTAN NAMN. Planen ritar en symbol i den här rutan.
         Vad rutan ÄR finns det ingen oberoende källa för — ingen bild, ingen
         film, inget produktägarbeslut — så funktionen är `REFERENCE GAP`
         och den får inget namn och ingen etikett i spelet. Geometrin är
         `PLAN`: fotavtrycket byggs som en sluten volym så att rummen runt
         den får rätt form, och inget mer. Den enda kanoniska vägen upp i
         anläggningen är ridhusets: läktarplanet → C-kortändans trappor →
         övre gången/caféet (`RIDHUSINNE.kortanda.trappor`). */
      {id:"sluten_volym", rekt:{x:5.9,  y:59.25, w:1.4, h:5.8},  label:"", stangt:true},
      /* Uppehållsrummets ÖSTDEL, öster om entrén och norr om volymen.
         En tidigare runda kallade den "passage"; planen har ingen vägg mot
         västdelen, och pentryt/soffhörnet hör till samma rum. Ingen egen
         etikett — namnet står en gång, i västdelen. */
      {id:"uppehallsrum_o", rekt:{x:5.9, y:64.35, w:5.3, h:5.6}, label:"", del:"uppehallsrum"},
      {id:"litet_rum",    rekt:{x:9.0,  y:67.75, w:2.2, h:2.2},  label:"", stangt:true},
      {id:"teorisal",     rekt:{x:11.2, y:64.35, w:6.1, h:5.6},  label:"TEORISAL"},
      {id:"sadelkammare", rekt:{x:7.3,  y:57.45, w:8.2, h:6.9},  label:"SADELKAMMARE"},
      {id:"ostrum",       rekt:{x:15.5, y:57.45, w:5.5, h:6.9},  label:""},
      {id:"ostrum_n",     rekt:{x:17.3, y:64.35, w:3.7, h:5.6},  label:""},
    ],
  },
  /* SERVICEDELEN — ombyggd efter Product Owners visuella underkännande.

     `KNOWN MISMATCH`, underkänd i spelarvyn: de här två låg som slutna rum
     och BYGGDES som 2,6 m höga täta kritvita lådor på tre sidor. Spelaren
     kliver in genom södra gaveln rakt emellan dem och möttes av en steril
     krämfärgad korridor med en blank återvändsgränd — inte ett stall.

     Rektanglarna var aldrig visuellt verifierade. De passade planen och
     navigeringen, och det räckte för att ingen skulle ifrågasätta dem. Det
     är precis den kontrollen som saknades.

     Vad källorna FAKTISKT visar (stall-inne-07 och -09, två vinklar på
     samma rum, plus brandplanens dörröppningar):
     - ett ÖPPET genomgångsrum, inte slutna rum,
     - vit yttervägg med rörstråk och väggutrustning på ena sidan,
     - mörk antracitpanel — samma produkt som boxfronterna — på den andra,
     - fristående galvade spolbommar i rad, med tvärbindslen,
     - spånsäckar staplade på pall i en öppen bukt, inte bakom en vägg,
     - marksten i genomgångsstråket, slät ljus betong under bommarna,
     - och en gaveldörr med DAGSLJUS och grön utrymningsskylt rakt fram.

     `oppen:true` betyder: bygg buktens innehåll, inte dess väggar. Id, rekt
     och etikett står kvar oförändrade, så navigering, interaktioner och
     brandplanens planform är orörda — det är bara den visuella
     tolkningen som var fel. */
  service:[
    {id:"spolspilta", rekt:{x:0, y:0, w:4.5, h:6.5}, label:"SPOLSPILTA",
     oppen:true, bommar:3, panelH:2.05, railZ:1.15},
    {id:"spanforrad", rekt:{x:16.5, y:0, w:4.5, h:6.5}, label:"SPÅNFÖRRÅD",
     oppen:true, sackar:{rader:2, hojd:1.15, djup:1.2}, panelH:2.05},
  ],
  /* Gaveldörren i söder, sedd inifrån: ett ljust öppet parti med grön
     utrymningsskylt över. `VERIFIED` i både stall-inne-07 och -09 — i båda
     ser man gräset utanför. Att spelaren SER dagsljus rakt fram är det som
     gör att rummet läser som ett genomgångsrum och inte en säck. */
  gaveloppning:{x:4.6, bredd:2.6, hojd:2.5, exitB:0.42, exitH:0.20,
                exitOver:0.22},
  /* TVÄRVÄGGARNA.

     `KNOWN MISMATCH`, lokaliserad genom att reproducera den underkända
     spelarvyn: väggen mot servicedelen (y 6,5) byggdes obruten över hela
     bredden, med hål BARA där gångarna går. Står spelaren mitt för en
     boxrad — och det gör man om man kommer in genom södra gaveln — möts man
     av en tät vägg rakt fram. Det är den "blanka återvändsgränden" som
     underkändes, och den fanns bara därför att väggen fick sina hål ur
     gångarnas lägen i stället för ur planen.

     Brandplanen ritar utrymningsvägen RAKT IGENOM den här väggen, och
     stall-inne-09 visar ett sammanhängande rum utan avstängning.

     `DERIVED`: att det finns en öppning mitt på är läsbart i planen. Exakt
     bredd är det inte — 3,0 m är en dörrbredd för hästpassage och markeras
     som antagande tills någon kan mäta den. */
  tvarvaggar:[
    {y:52.85, brand:true},
    {y:6.5, brand:false, oppningar:[{x0:9.0, x1:12.0}]},
    /* Klubbdelens genomgående vägg stod här en runda som `y:56.97` med ett
       hål 0 → 8,97 m i väster. Läsningen var fel: det som såg ut som ett
       hål var den slutna volymens och dörrarnas linjer. Väggen är nu `klubb.vaggar`
       ovan, på y 57,45, tvärs hela huset med planens två dörrar. */
  ],
  /* Dörrarna beskrivs EN gång. `pos` är innerläget, `spawn` ytterläget,
     `inrikt` vilket håll man tittar när man kliver in och `uttext` vad
     markören på gården säger. ANL.dorrar byggs ur den här listan längre
     ner — förut fanns två listor med var sin uppsättning koordinater, och
     när planformen ändrades följde bara den ena med. Då hamnade utgången
     mot gräsgården inne i en boxrad. */
  dorrar:[
    /* Utgångarnas UTELÄGEN härleds ur fasadöppningarna i stället för att
       skrivas av. Båda stod tidigare på handskrivna tal som glidit isär från
       de dörrar de hör till:

         · "Entré" låg på y 113,4 medan förstukvistens dörr sitter på 118,8 —
           5,4 m fel, alltså i blank vägg mellan två valvfönster. Felet var
           dessutom precis över autogeneratorns dedup-gräns på 4 m, så den
           lade en ANDRA markör vid den riktiga dörren. Två markörer, en dörr.
         · klubbdörren låg 1,6 m öster om sin öppning.

       u mäts från NORRA hörnet på W-sidan och från ÖSTRA på N-sidan — samma
       konvention som väggarnas p0→p1 i autoDorrar och i world.js. Räknat på
       öppningens MITT (u + b/2), inte dess kant. */
    /* De två har bytt ROLL i och med att förstukvisten flyttade till
       gaveln: entrén under verandan ligger nu mot grusplanen, och
       långsidans dörr är den enkla. Texterna följer med dörrarna, annars
       skickas spelaren till fel sida av huset. */
    /* INNERLÄGET ligger i planens vindfång (x 3,6–5,5 i gaveln), inte mitt
       på gaveln där den låsta fasadens dörr står. De två stämmer inte
       överens — `CONTRADICTION`, se noten vid `klubb` — och fasaden får
       inte röras. Spelaren som går in genom fasaddörren står därför inne i
       vindfånget, 5,9 m väster om dörren. Ytterläget (`spawn`) följer
       fasaden som förut. */
    {id:"ut_n", pos:[4.55,69.0], text:"Ut genom entrén — mot grusplanen", mot:"gard", inrikt:-Math.PI/2,
     uttext:"Gå in i stallet (Entré, under verandan)",
     spawn:{x:STALL_X+STALL_BREDD-10.5, y:STALL_NORR+1.6, rikt:Math.PI/2}},
    {id:"ut_n2",pos:[1.6,64.35], text:"Ut på gårdssidan", mot:"gard", inrikt:0,
     uttext:"Gå in i stallet (dörren på gårdssidan)",
     spawn:{x:STALL_X-1.5, y:STALL_NORR-(5.6+1.15/2), rikt:Math.PI}},
    {id:"ut_s", pos:[5.6,1.6],   text:"Ut till gårdsplanen — mot Husbyvägen", mot:"gard", inrikt:Math.PI/2,
     uttext:"Gå in i stallet (gaveldörren vid gårdsplanen)",
     spawn:{x:STALL_X+5.6,y:STALL_Y-1.6,rikt:-Math.PI/2}},
    /* HÄSTGÅNGEN till ridhuset. Den här dörren går inte ut på gården utan
       rakt in i ridhusets entréhall — det är hela poängen med att husen är
       sammanbyggda: hästen leds inomhus. Ingen markör läggs på gården för
       den, eftersom den inte finns där. */
    {id:"hastgang", pos:[0.9, GANG_FASTE+GANG_DJUP/2-STALL_Y],
     text:"Hästgången — in i ridhuset",
     mot:"ridhusinne", inrikt:Math.PI, inne:true,
     spawn:{x:RIDHUS_BREDD-1.4, y:GANG_FASTE+GANG_DJUP/2-RIDHUS_Y, rikt:Math.PI}},
  ],
  /* Klockan i gångens bortre ände, mot servicedelen. `VERIFIED` i två
     oberoende bildrutor: IMG_0160 och stall-inne-05-stallgangen.jpg. */
  klocka:{x:0.35, y:1.2, z:2.7, r:0.26},
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

/* BOXFACKEN per rad, som y-intervall. Samma regel som Geometri.boxfack i
   Roblox: facken börjar vid boxStartY, är boxB djupa och slutar vid klubbY;
   ett fack som skär ett `brott` i sin rad finns inte — där går
   hästförbindelsen. Listan räknas EN gång här och läses av alla som ritar,
   kolliderar eller räknar boxar, så att webben inte kan rita tolv där Roblox
   bygger tretton (vilket den gjorde: boxslingorna följde namnlistornas
   längd, elva, medan Roblox byggde alla tolv fack). */
STALLINNE.fack = (()=>{
  const S=STALLINNE, ut={};
  for(const rad of S.rader){
    const lista=[];
    for(let y=S.boxStartY; y+S.boxB<=S.klubbY+0.001; y+=S.boxB){
      const f={y0:y, y1:y+S.boxB};
      const bruten=(S.brott||[]).some(b=>b.rad===rad.id && f.y1>b.y0+0.01 && f.y0<b.y1-0.01);
      if(!bruten) lista.push(f);
    }
    ut[rad.id]=lista;
  }
  return ut;
})();
/* Boxar per obruten rad — tretton vid 69,95 m. Räknas, inte skrivs. */
STALLINNE.antalBoxar = Math.floor((STALLINNE.klubbY-STALLINNE.boxStartY)/STALLINNE.boxB+0.001);

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
  /* HÄSTFÖRBINDELSENS passage genom västra boxraden: från fasaddörren in
     i gång A. Den ersätter tvärkorridoren tvärs hela huset — planen har
     ingen sådan, bara det här brottet. Sträcks DORRGAP in i gång A av samma
     skäl som gångarna sträcks in i hallarna. */
  for(const b of S.brott){
    const rad=S.rader.find(r=>r.id===b.rad);
    const x0=rad.vetter>0 ? 0.4 : rad.x0-DORRGAP;
    const x1=rad.vetter>0 ? rad.x0+rad.djup+DORRGAP : S.bredd-0.4;
    g.push({x:x0, y:b.y0, w:x1-x0, h:b.y1-b.y0});
  }
  /* TVÄRKORRIDOREN mellan boxhallen och klubbdelen: från brandväggen vid
     klubbY upp till den genomgående väggen. Planen ritar utrymningsvägar
     ut genom båda långsidorna härifrån (`DEFERRED BY EXTERIOR LOCK`). */
  g.push({x:0.4, y:S.klubbY, w:S.bredd-0.8, h:S.klubb.y0-S.klubbY+DORRGAP});
  /* KLUBBDELENS GOLV som EN yta: väggarna i `klubb.vaggar` och de slutna
     rummen gör allt spärrande, i `vandringKollision`. Förut var det tre
     svävande lådor i en hall; nu är det planens rum med planens dörrar.
     Ytan sträcks DORRGAP ner i tvärkorridoren så att de två dörrarna i den
     genomgående väggen inte hamnar i ett dödband. */
  g.push({x:0.4, y:S.klubb.y0-DORRGAP, w:S.bredd-0.8, h:S.langd-0.4-(S.klubb.y0-DORRGAP)});
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

   Gaveldelen i norr — mot parkeringen — är entré och, en trappa upp via
   C-kortändans trappor från läktarplanet, café.
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
  /* ═══ RIDHUSET EFTER UTRYMNINGSPLANEN — Product Owner-godkänd 2026-09-03 ═══

     `references/plans/ridhus-entreplan-utrymning.jpg`, fotograferad liggande
     och rätad upp (skyltens rubrik läses då rakt). Orienteringen är låst av
     tre saker som inte kan tolkas om: entrén vetter mot parkeringen i norr
     (låst exteriör), stallet ligger öster om ridhuset (situationsplanen,
     satellit) och den svarta dörren i norra gaveln sitter 16,1–16,7 m från
     västra väggen i planen mot fasadens 15,8–16,9 (`u:8.1`). Med den
     nyckeln blir planens överkant VÄSTER och dess högra ände NORR.

     Det planen då säger, mätt i bildpunkter (`tools/f02-planmatning.py`
     hjälpte inte här — ridhusplanen mättes med samma metod direkt):

       · LÄKTAREN, fem parallella linjer, löper längs VÄSTRA långsidan från
         södra änden ända upp till entrédelen. Spelet hade den i öster med
         ett gap för hästgången. Det var fel: hästgången kommer in från
         öster, på sidan MITT EMOT läktaren, och bryter ingen läktare.
       · ENTRÉDELEN är 11,5 m djup (bänkblockets kant 11,5 m från norra
         gaveln; 15,1 % av längden mätt redan 2026-08-30). Banan börjar
         alltså 5,7 m från södra gaveln, inte 2.
       · C-BLOCKET — bänkblocket med de två trapporna och glasbandet — står
         vid NORRA änden, 7,05–11,5 m från gaveln, och upptar den östra
         delen av bredden, 8,6–21,6 m från västra väggen. Fyra steg. Spelet
         hade det vid södra kortändan, en slutledning ur var bokstaven C
         antogs sitta. C sitter alltså i norr och A i söder.
       · MITTEN av C-blockets översta rad bär två trappor på 12,4–15,2 och
         16,4–18,9 m från väster. Den kryssade rutan 2,6–4,4 × 7,0–8,8 m
         är `schakt` i datan — funktion oläst, inget namn.
       · HUVUDENTRÉN sitter i VÄSTRA väggen 2,2–2,7 m från norra gaveln, in
         i en korridor längs västväggen. Norr om entrén två mycket smala
         toaletter (Tobias: "två toaletter till vänster om entrén"; fotot
         `ridhus-klubb-05-lilla-toaletten`). Fasadens dubbeldörr sitter 9 m
         från gaveln — `CONTRADICTION`, fasaden låst, se nedan.
       · Två parallella väggar 4,2 och 5,7 m från väster, 1,6–16 m från
         gaveln: SKÅPKORRIDOREN (`ridhus-klubb-01`), som fortsätter söderut
         förbi bänkblockets västra ände.

     Tobias rumsidentiteter för entréklustret (reception, skåpförvaring,
     ombytesrum med dusch, HWC) är knutna till markerade planurklipp,
     Bild 1–7, som INTE finns i repot. Bara det som hans ord ensamma
     fastställer byggs med namn: entrén, de två toaletterna, hästgången.
     Resten av klustrets väggar byggs där planen ritar dem, utan namn —
     `REFERENCE GAP` tills urklippen ligger i references/plans/. */
  bredd:RIDHUS_BREDD, langd:RIDHUS_LANGD, tak:6.2, entre:11.5,
  /* Banan: x följer läktarsidan (härleds nedan ur `sidor`), y ur planen —
     entrédelen 11,5 m i norr lämnar 5,7 m i söder. `PLAN`. */
  bana:{x:0.6, y:RIDHUS_LANGD-11.5-60, w:20, h:60}, sargH:1.35,
  vagg:"#E9E5DC", sockel:"#2E2E2C", sandFarg:"#6F5D4D", gangFarg:"#8C8880",
  /* HALLENS EGNA YTOR, alla MÄTTA i `ridhus-inne-01` och alla tidigare
     literaler i renderaren — samma dolda-literal-mönster som sanden, silon
     och sponsorskyltarna.

       hallvagg   #ACA99D   den vita väggen vid kortändan (sd 27)
       takfarg.balk #5C4C45 takstolarna
       takfarg.plat #5E5B5E undertakets plåt (517 kpx)

     VIKTIGT om taket: ridhusets takstolar är INTE varma som stallets
     limträ. En värmemask på hela takzonen fann bara 35 kpx varma pixlar mot
     517 kpx neutrala — balkarna läser mörkt gråbruna, nästan neutrala.
     Spelet hade `#7A5C3E`, en varm mellanbrun, och undertaket `#3A3E44`,
     en mörk blågrå. Båda drog åt fel håll.

     Väggarna låg på rent `#FFFFFF` och renderades utfrätta. Vit är inte ett
     mätt värde — samma sak som stallets väggar. */
  hallvagg:"#ACA99D",
  /* TAKSTOMMEN. Låg som literaler inne i v3dRidhus (resning 2,8, balkdelning
     6 m, dimensioner) och fanns därför bara i webben — Roblox byggde stål,
     kabelstegar och ventilation men varken trästomme eller undertak.

     Review 10 säger rätt sak: en andra geometrisanning ska inte handkopieras
     in i Anlaggningen.luau. Fakta flyttas hit och båda ytorna läser dem.

     `DERIVED`: resningen och balkdelningen är spelets tidigare tal, inte
     mätta. `MEASURED`: färgerna, se noten ovan. */
  takfarg:{balk:"#5C4C45", plat:"#5E5B5E"},
  takstomme:{resning:2.8, delning:6.0, start:1.0,
             balkH:0.26, balkD:0.24, kungB:0.22, kungH:2.7,
             platT:0.18},
  /* MOTSÄGELSE 1 ur DRIVE-SOURCE-INDEX (`IMG_0183`): långsidans övre
     väggyta är MÖRKRÖD/MAROON med horisontella detaljer, inte brun
     träpanel. Rättad 2026-08-30. Listen är den horisontella detaljen. */
  /* PANELEN OMMÄTT ur `ridhus-inne-02` med färgsökning i det stycke där den
     syns, och masken visuellt kontrollerad som grön overlay: den täcker
     väggen mellan de vita banden och utesluter sponsorskyltarna.

       mätt  #765B59   44 400 px

     Stod som `#5E2C33`, ett mättat rödlila. Fotot visar en betydligt
     dovare, gråbrun-mauve ton. Beskrivningen "mörkröd/maroon" i det gamla
     textderivatet drog åt fel håll — bilden är facit, och den är dovare än
     ordet.

     Sanden ommätt i `-03`: #6F5D4D mot spelets #5E4A36, alltså ljusare och
     gråare än spelet hade den. */
  panel:"#765B59", panelList:"#E8DFCE",
  /* Läktaren längs östväggen. GAPET är påtvingat av verifierad topologi:
     satellitbilden lägger hästgången centralt, på lokala y 45,3–48,8, och
     där kan läktaren inte vara obruten — man ska kunna leda hästen igenom.

     Läktarens utsträckning är själv ett Drive-textderivat (ASSUMPTION), och
     satellitbilden är DIRECT VISUAL. Enligt källhierarkin viker läktaren.
     Exakt hur bred öppningen är i verkligheten vet jag inte; 5,0 m är valt
     för att en häst ska gå igenom med marginal. [ASSUMPTION]

     `KNOWN MISMATCH A`, RÄTTAD HÄR: spelet byggde läktaren som FYRA
     TRAPPSTEG i ljus furu längs hela långsidan. Fotona visar något annat.

     `ridhus-inne-01-glasrummen.jpg`, förgrunden beskuren och tittad på:
     ett PLANT, brett plankdäck i ljust gråbrunt trä, och mot banan en
     SOLID mörkbetsad brädvägg med en ljus kappregel överst. Inga
     trappsteg, inga sittbänkar, ingen stomme av furu.
     `ridhus-inne-02-langsidan.jpg` visar samma sak från samma däck.

     Trappstegen finns — men vid KORTÄNDAN, under glasrummen, och de står
     redan i `kortanda` nedan. De två strukturerna hade blandats ihop.

     `VERIFIED`: plant däck, solid mörk front, ljus kappregel, inga steg.
     `DERIVED`: höjderna, och de är HÄRLEDDA ur en bild, inte valda.
     `ridhus-inne-03-baset-vid-E.jpg` visar sittande personer bakom sargen:
     deras huvuden ligger ungefär 0,7 m över sargkrönet. Sittande ögonhöjd
     är ~1,25 m, och sargen är 1,35 — alltså däck ≈ 1,35 + 0,7 − 1,25
     ≈ 0,80. Fronten går strax över sargkrönet.

     Topologin fotona kräver: man ska från däcket se ÖVER fronten ner i
     banan, och fronten ska stå över bansanden. Testet mäter den
     RELATIONEN, inte talen.

     `[REFERENCE GAP]`, öppet och inte gissat: hur sargen och läktarfronten
     förhåller sig till varandra. `-01` och `-02` visar den mörka
     brädväggen SOM bangräns på däckets sida, utan vit sarg framför. `-03`
     visar en vit sarg med sittplatser bakom, vid bokstaven E — som ligger
     på samma långsida. De två går inte att förena ur bilderna. Spelet
     bygger tills vidare båda, och motsägelsen står i auditen. */
  /* ORIENTERINGEN — `REFERENCE GAP / arbetsorientering`.

     Vilken absolut långsida läktaren ligger på är INTE bevisad. Bevisläget
     efter att jag gått igenom repots material:

     FÖR att spelet står rätt:
     - hästgången förbinder ridhuset med stallet, och situationsplanen i
       `ridhus-entreplan-utrymning.jpg` (insetrutan "SITUATIONSPLAN / SITE
       PLAN") visar ridhuset som den ORANGE, enkla rektangeln till VÄNSTER
       och stallet som den GRÅ, trappstegsformade till HÖGER, med
       Björklidsvägen upptill. Stallet ligger alltså öster om ridhuset,
       precis som spelet har det. Gången måste då gå in på ridhusets ÖSTRA
       sida, och hästgångens grind i sargen ligger just där.

     EMOT:
     - i huvudplanen ligger entré-/trappdelen upptill, och om det är norr
       är den bandade långsidan VÄSTRA. Spelet har läktaren i öster.

     Bandets identitet är dessutom själv en slutledning från en tidigare
     session ("fem parallella linjer = läktarens steg"). Bredden stämmer —
     14,5 % av 25 m = 3,6 m mot däckets 3,4 — men det gör inte tolkningen
     till ett bevis.

     Ingen bild i repot visar läktaren och hästgångens dörr i samma ruta,
     och planen har ingen norrpil. Frågan är därför ÖPPEN.

     `sidor` nedan finns för att en framtida spegling ska vara en
     DATAÄNDRING och inte ett ombygge: byt "E" mot "W" och tvärtom, så
     följer läktare, sponsorvägg och fönsterband med på båda ytorna. */
  /* SPEGLAD 2026-09-03 ur planen: läktaren i VÄSTER, panelen i öster.
     Frågan som stod öppen här är stängd av den svarta gaveldörren — se
     noten överst. Speglingen är precis den dataändring `sidor` fanns för. */
  sidor:{laktare:"W", panel:"E"},
  /* Läktaren löper i planen längs hela banan, från södra änden upp till
     entrédelen. Utan gap: hästgången kommer in på motsatt långsida.
     y0/y1 följer banan (härleds nedan). `PLAN` för sida och utbredning;
     däckets höjd och djup är som förut `DERIVED` ur -03. */
  laktare:{x0:0.6, y0:0, y1:0,
           dackZ:0.80, dackDjup:3.4, frontTopp:1.45, kappH:0.09},
  /* KORTÄNDANS LÄKTARE (`IMG_0179`), Review 05 blocker 3.

     Spelet hade bara en läktare — den längs östra långsidan — och lade de
     glasade rummen längs SAMMA långsida. Fotot visar något annat, och
     bokstaven avgör var:

       · `ridhus-inne-01-glasrummen.jpg` visar ett trappstegsblock i ljust
         trä med TVÅ trappor upp, och ovanför det ett band av glasade rum
         med mörka träkarmar, där man ser in i lokalerna bakom.
       · Rakt framför blocket, på sargen, sitter bokstaven **C** med
         cykelbilden. C ligger per definition mitt på en KORTSIDA — i
         DRESSYRBOKSTAVER på banans (10, 0), alltså husets södra kortända.

     Alltså: blocket och glasrummen hör till SÖDRA KORTÄNDAN, inte till
     långsidan. Långsidans läktare finns kvar — den syns i `-02` och `-03`
     som ett långt däck med mörk brädfront — men glasrummen flyttar hit.

     `VERIFIED`: att blocket finns vid kortändan, att det har två trappor,
     att glasrummen sitter ovanför det, och att C står framför det.
     `[REFERENCE GAP]`: alla meter. Antal steg, blockets djup, trappornas
     lägen och glasbandets höjd är valda så att topologin blir rätt. Det är
     precis vad Review 05 ber om — exakta mått får vara gap, känd topologi
     får inte förbli fel. */
  /* `KNOWN MISMATCH` 3, DIAGNOS FÖRE ÅTGÄRD: blocket syntes inte alls från
     referenskameran. Orsaken var varken kamera, kontrast eller byggordning
     utan ren OCKLUSION, mätbar i datan: fyra steg à 0,30 m gav 1,20 m, och
     sargen är 1,35. Hela blocket stod under sargkrönet.

     `-01` visar tvärtom flera bänkrader ÖVER sargen, med folk sittande på
     dem.

     Att bara höja stegen räckte inte: raderna stiger BORT från banan, så
     bara den översta kom över sargen — 0,25 m på fjorton meters håll, en
     strimma. Blocket står i stället på en SOCKEL, som i fotot: 0,80 m sockel
     plus 5 × 0,32 = 2,40 m totalt, vilket lägger tre rader över sargkrönet.
     Det är den bild `-01` ger.

     Talen är `DERIVED`; kravet som testas är RELATIONEN — blocket måste
     sticka upp så pass över sargen att flera rader syns, annars är det
     osynligt oavsett kamera.

     Jag flyttade inte blocket för att blidka kameran, vilket vore att lösa
     ett byggfel med en vy.

     GLASBANDET är INTE en obruten remsa. `ridhus-inne-01`, beskuren över
     kortändan: glaset går i BÅS med mörka träkarmar och poster, och det
     BRYTS av de två trapporna — deras vita snedställda barriärer skjuter
     upp genom bandet, och mellan dem sitter den vita väggen med
     stjärndekoren och klockan.

     Att bygga bandet som en enda låda ger "generiska upprepade fönster",
     vilket är precis vad ordern säger att det inte ska vara. Det byggs nu i
     SEGMENT mellan trapporna, ur samma `trappor`-tal som trapporna själva
     använder — så att de inte kan glida isär.

     `VERIFIED`: att glaset går i bås med mörka karmar, och att trapporna
     bryter bandet. `[REFERENCE GAP]`: båsens exakta delning. */
  /* FLYTTAD TILL NORRA ÄNDEN 2026-09-03. Planen ritar bänkblockets fyra
     steg 7,05–11,5 m från norra gaveln, 8,6–21,6 m från väster. Blocket
     VÄNDER sig mot banan i söder (`vand:"S"`): stegen stiger norrut från
     y0 mot gavelväggen, glasbandet och den vita väggen står vid y1. Att
     blocket låg i söder var en slutledning ur var C antogs sitta; C står
     alltså i norr, framför entrédelen, och caféet ligger ovanpå den.
     Bredden 13 m är `PLAN` (spelet hade nästan hela kortsidan); stegens
     antal och djup `PLAN`; sockel och steghöjd `DERIVED` som förut. */
  kortanda:{y0:RIDHUS_LANGD-11.5, y1:RIDHUS_LANGD-7.05, x0:8.6, x1:21.6,
            vand:"S", steg:4, stegH:0.32, stegD:1.1,
            sockelH:0.80,
            /* `glasOver` var 0,35 m, alltså glaset nästan direkt ovanpå
               bänkraderna. `ridhus-inne-01` visar en HÖG vit vägg mellan
               översta bänken och fönstrens underkant — ungefär mansehöjd —
               och det är på den väggen kompassrosen och klockan sitter. Utan
               den väggen finns det ingenstans att sätta dem, vilket var
               varför stjärnan hamnade uppe i glaset vid första försöket.
               1,6 m är `DERIVED` ur bildens proportioner. */
            /* Trappornas lägen ur planen: 12,4–15,2 och 16,4–18,9 m från
               väster, alltså mitt 13,8 och 17,65. Planens streckning
               antyder att loppen går längs gaveln (öst–väst), inte mot
               den som här; fotot är auktoritet för formen, planen för
               läget, och den frågan står som `REFERENCE GAP`. */
            trappor:[13.8, 17.65], trappB:1.2, glasH:2.0, glasOver:1.6,
            glasPost:1.9, glasKarm:"#4A3B2E",
            /* Bänkarna MÄTTA i `-01`: #86715B, en varm mellanbrun. Spelet
               hade #D8C7A4 — ljus furu, vilket fotot motsäger. */
            bank:"#86715B", bankSatt:"#6F5C49",
            /* Klockan vid kortändan, MELLAN de två trapporna — x härleds ur
               `trappor` längre ner så att den följer dem. `-01` visar den på
               den vita väggen ovanför blocket. */
            klocka:{overBlock:1.05, r:0.34},
            /* KOMPASSROSEN på den vita väggen — `ridhus-inne-01`, beskuren.
               En TUNN, linjeritad åttauddig stjärna, inte en fylld form.
               Den sitter till VÄNSTER om den vänstra trappan, ovanför
               bänkraderna. `VERIFIED` att den finns, var den sitter och att
               den är linjeritad. `[ASSUMPTION]`: storleken.
               x härleds ur `trappor` längre ner. */
            stjarna:{overBlock:0.85, r:0.78, tjocklek:0.05, farg:"#B9B3A6"}},
  /* MOTSÄGELSE 4 (`IMG_0198`): båset ligger vid dressyrbokstaven E, är
     mörkt trä, och nås av en trappa med träräcken. Över öppningen sitter
     en grön exit-skylt. E ligger vid husets y = 32 sedan bokstäverna
     följer sargporten (se DRESSYRBOKSTAVER i data.js). */
  /* Båsets SADELTAK med utskjutande takfot — `ridhus-inne-03` visar en liten
     stuga med brutet tak, inte en låda med lock. Silhuetten är det man
     känner igen båset på. `[ASSUMPTION]`: resningen. */
  basTak:{resning:0.42, utsprang:0.18},
  /* Båsets x HÄRLEDS ur läktarsidan längre ner — det STÅR på däcket, och ett
     literalt tal här hade lämnat det kvar på fel sida vid en spegling.
     Precis den stale följdgeometri som fällt silon, gårdsplanen och
     sponsorskyltarna i det här arbetet. Talet nedan skrivs över. */
  /* y härleds nedan: E sitter mitt på långsidan, alltså banans halva
     längd. Skrivet som tal följde det inte med när banan flyttade. */
  domarbas:{x:23.2, y:0, b:2.0, h:2.3, trappa:true, exit:true},
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
  /* Caféet ligger OVANPÅ entrédelen, i norr, och nås via C-blockets två
     trappor från läktarnivån (Tobias; `ridhus-klubb-10`). Golvet ligger
     därför där glasbandet börjar — härleds nedan ur kortändan. Den
     separata trätrappan (`trappa`) och den andra klockan (`klocka`) som
     stod här var dubbletter av C-blockets: granskningen 2026-08-31 såg
     en enda klocka i alla bilder av C-blocket och ingen annan. Borta. */
  cafe:{djup:11.5, z0:0, z1:5.9},
  speglar:[ {y:19,b:3.2},{y:37,b:4.2} ],           // på västra långsidan
  skyltar:[
    /* OM-AUDITENS PUNKT C: skyltarna hänger på den rostbruna panelen,
       ovanför sargen — inte utspridda längs hela väggen. De låg på y 8–53
       och hamnade därmed delvis på den ljusa delen. Nu samlade innanför
       IDENTITET.ridhus.ovreVagg:s stycke (y 6–40), i den ordning
       `ridhus-inne-02-langsidan.jpg` visar dem från vänster. */
    /* `KNOWN MISMATCH C`: läget var inte KOPPLAT till panelen. Talen låg
       innanför panelens stycke, men bara därför att någon räknat efter en
       gång. Flyttas `ovreVagg.y0/y1` följer skyltarna inte med, och då
       hänger de på den ljusa väggen igen — samma sorts stale följdgeometri
       som silon och gårdsplanen fällts på i det här arbetet.

       `andel` är läget som andel av panelens stycke, räknat från dess
       södra ände — och stycket är nu HELA långsidan (0 → langd − entre).

       OMGRANSKAD 2026-09-03 mot `ridhus-inne-31` (hela långsidan i en
       bildruta, sedd från läktaren: vänster = norr) och `-17` (södra
       delen mot A-hörnet). Ordning från norr: VÄLKOMMEN strax söder om M,
       ELON, "Vi tror på dig!", spegeln vid B (F02-B), svart panelsektion
       och trädörr, AGRIA, HÄSTSPORTBUTIK rakt ovanför F, två separata
       RS MUSTANG-skyltar, en blå foderskylt närmast A-hörnet. Andelarna
       är lästa mot bokstäverna (M y 54, B y 30, F y 6) — DERIVED, inte
       mätta. */
    {andel:0.80, b:5.0, text:"VÄLKOMMEN TILL UPPLANDS-BRO RYTTARFÖRENING", fg:"#3A3E44", bg:"#F2EDE2"},
    {andel:0.71, b:4.0, text:"HUVUDSPONSOR ELON BARKARBY", fg:"#F0EADC", bg:"#1C1C1E"},
    {andel:0.62, b:3.6, text:"Vi tror på dig! · Sparbanken i Enköping", fg:"#C0392B", bg:"#F7F2E8"},
    {andel:0.19, b:3.0, text:"Agria Djurförsäkring", fg:"#F0EADC", bg:"#2F5C8F"},
    {andel:0.14, b:2.6, text:"Hästsportbutik · Stigeberga Gård", fg:"#3A3E44", bg:"#F2EDE2"},
    {andel:0.10, b:2.2, text:"RS Mustang · Stallströ · Foder", fg:"#F0EADC", bg:"#2F5C8F"},
    {andel:0.064, b:2.2, text:"RS Mustang · Stallströ · Foder", fg:"#F0EADC", bg:"#2F5C8F"},
    {andel:0.03, b:2.0, text:"Svensk kvalitetsfoder", fg:"#F0EADC", bg:"#2F5C8F"},
  ],
  /* SARGPORTEN för folk till fots finns INTE här längre (Senior Re-review
     2026-09-03, blocker 2). Ingen källa visar en grind i sargen och bredden
     var vald — då är den ingen fidelity-sanning. Spelet behöver ändå en väg
     från entrédelen ut på banan; den ligger som uttrycklig SPELABSTRAKTION i
     `SPELABSTRAKTIONER.ridhus.sargport` nedan, utanför RIDHUSINNE, exporten
     `ridhus` och fidelity-testerna. I fidelity-sanningen: `REFERENCE GAP`. */
  /* y härleds ur IDENTITET.ridhus.ovreVagg längre ner — se noten vid
     `skyltar`. Fältet finns här bara så att renderarna kan läsa ett tal. */
  /* GRINDEN mot hästgången, i sargens östra långsida. Den måste finnas: annars
     är hästgången dekoration. Man leder hästen in genom gången, och då ska man
     komma ut på banan — sargen kan inte vara obruten just där.

     Läget härleds ur hästgångens fäste i ridhusets östra långsida
     (GANG_FASTE, GANG_DJUP) — läktaren står på västra sidan och har inget
     gap; det gamla "läktargapet" finns inte. Bredden är vald, inte mätt.
     [ASSUMPTION] */
  sargGrind:{y0:GANG_FASTE-RIDHUS_Y-0.15, y1:GANG_FASTE+GANG_DJUP-RIDHUS_Y+0.15},
  /* ENTRÉDELEN ur planen. `hallMobler` — disk, bänkar, kansli, omklädning,
     trapphus som handritade rektanglar — var uppfunna; borta. Samma schema
     som stallets `klubb`: väggar med öppningar, rum som regioner, slutna
     rum som volymer. Roblox bygger ur Geometri.vaggBitar, webben ur
     klubbVaggBitar. N = m från norra gaveln, x från västra väggen;
     y = 77,18 − N. Måtten är tagna i en sned planbild: ±0,5 m.

     Det som har namn vilar på Tobias ord eller foto; det som saknar namn
     är planens väggar utan känd funktion — `REFERENCE GAP` tills de
     markerade urklippen (Bild 1–7) finns i repot. */
  entrehall:{
    y0:RIDHUS_LANGD-11.5,
    vaggar:[
      /* Korridoren längs västväggen, N 0,3–13, med glaspartiet in i
         hallen vid entrén (N 2,4–3,8; planens 2,2 klipps vid toalettväggen
         så att entrén slutar där toaletten börjar). Planens gröna pilar
         löper här. */
      {id:"korridor_o", typ:"langs", x:2.2, y0:64.2, y1:76.9,
       oppningar:[{id:"glasparti", y0:73.4, y1:74.8}]},
      /* De två smala toaletterna norr om entrén, N 0,3–1,1 och 1,6–2,4. */
      {id:"wc_n_s",     typ:"tvar",  y:74.8, x0:0, x1:1.7},
      {id:"wc_n_mellan",typ:"tvar",  y:75.8, x0:0, x1:1.7},
      {id:"wc_n_o",     typ:"langs", x:1.7, y0:74.8, y1:76.9},
      /* Skåpkorridorens två väggar, 4,2 och 5,7 m från väster, N 1,1–16
         respektive 1,6–16, med de luckor planen visar. */
      {id:"skap_v", typ:"langs", x:4.2, y0:61.2, y1:76.1,
       oppningar:[{id:"a", y0:74.2, y1:76.1},{id:"b", y0:71.7, y1:72.6},
                  {id:"c", y0:69.6, y1:70.4},{id:"d", y0:65.6, y1:67.4}]},
      {id:"skap_o", typ:"langs", x:5.7, y0:61.2, y1:75.6,
       oppningar:[{id:"a", y0:73.1, y1:74.0},{id:"b", y0:70.7, y1:71.4},
                  {id:"c", y0:68.8, y1:69.6},{id:"d", y0:66.3, y1:67.5}]},
      /* Cellraden mellan västkorridoren och skåpkorridoren, x 2,2–4,2, är
         inte en remsa utan FYRA celler: planen drar tvärväggar från
         korridorväggen till skåpväggen vid N 3,9, 6,4 och 7,9, och en
         halv vid N 9,8 (x 2,2–3,1). Varje cell nås från skåpkorridoren
         genom sin egen lucka i `skap_v`. Funktionerna är olästa —
         Tobias Bild 2–5 hör hit men finns inte i repot. */
      {id:"cell_1", typ:"tvar", y:73.3,  x0:2.2, x1:4.2},
      {id:"cell_2", typ:"tvar", y:70.8,  x0:2.2, x1:4.2},
      {id:"cell_3", typ:"tvar", y:69.3,  x0:2.2, x1:4.2},
      {id:"cell_4", typ:"tvar", y:67.35, x0:2.2, x1:3.1},
      /* Hallens tvärvägg N 4,3 i två stycken med en dörr, och rummen mot
         nordöstra hörnet. Funktioner olästa. Rummet innanför (x 5,7–10,5,
         N 4,3–7,2) sluts söderut av en vägg N 7,2 från schaktet till
         `hall_mitt`; mätt om 2026-09-03 i förstoring, den saknades. */
      {id:"hall_n_v",  typ:"tvar",  y:72.9, x0:5.7, x1:10.6,
       oppningar:[{id:"dorr", x0:7.7, x1:9.6}]},
      {id:"hall_n_o",  typ:"tvar",  y:72.9, x0:15.3, x1:18.4},
      {id:"hall_nv_s", typ:"tvar",  y:70.0, x0:7.6, x1:10.5},
      {id:"hall_mitt", typ:"langs", x:10.5, y0:70.0, y1:72.9},
      {id:"hall_no",   typ:"langs", x:18.4, y0:70.1, y1:75.9},
      {id:"hall_no_s", typ:"tvar",  y:71.3, x0:18.4, x1:21.7},
      /* Östra korridorens västvägg, N 0,2–11,4. */
      {id:"ostkorridor_v", typ:"langs", x:21.7, y0:65.7, y1:77.0},
    ],
    rum:[
      {id:"entre",        rekt:{x:0,    y:73.4, w:2.2,  h:1.4},  label:"ENTRÉ"},
      {id:"vastkorridor", rekt:{x:0,    y:64.2, w:2.2,  h:9.2},  label:""},
      {id:"wc_n1",        rekt:{x:0,    y:75.8, w:1.7,  h:1.1},  label:"WC", stangt:true},
      {id:"wc_n2",        rekt:{x:0,    y:74.8, w:1.7,  h:1.0},  label:"WC", stangt:true},
      {id:"cellrad",      rekt:{x:2.2,  y:64.2, w:2.0,  h:12.8}, label:""},
      /* Den kryssade rutan står tätt ÖSTER om skåpkorridorens östvägg,
         x 5,75–7,6, N 7,3–9,0 — inte i cellraden, dit en tidigare läsning
         satte den 3 m fel. Rättad i förstoring 2026-09-03. Fotavtrycket är
         `PLAN`; FUNKTIONEN är okänd — att det vore en hiss är symbolens
         gängse betydelse, inte belagt, och hette ändå `hiss`/`HISS` i datan
         tills Senior Re-review 2026-09-03 (blocker 1). Nu neutralt id utan
         spelarsynlig etikett, sluten volym tills belägg eller
         produktägarbeslut ger den ett namn. `REFERENCE GAP`. */
      {id:"schakt",       rekt:{x:5.78, y:68.2, w:1.82, h:1.7},  label:"", stangt:true},
      {id:"skapkorridor", rekt:{x:4.2,  y:61.2, w:1.5,  h:14.9}, label:"SKÅPKORRIDOREN"},
      {id:"hall",         rekt:{x:5.7,  y:65.7, w:16.0, h:11.3}, label:""},
      {id:"ostkorridor",  rekt:{x:21.7, y:65.7, w:3.3,  h:11.3}, label:""},
    ],
  },
  dorrar:[
    {id:"ut_o", pos:[24.2,5],    text:"Ut på gården", mot:"gard",
     spawn:{x:144.6,y:49,rikt:0}},
    /* HÄSTGÅNGEN till stallet: leder in i stallets klubbdel utan att man
       behöver gå ut på gården. Husen är sammanbyggda. */
    {id:"hastgang", pos:[RIDHUS_BREDD-1.4, GANG_FASTE+GANG_DJUP/2-RIDHUS_Y],
     text:"Hästgången — in i stallet",
     mot:"stallinne", spawn:{x:1.6, y:GANG_FASTE+GANG_DJUP/2-STALL_Y, rikt:0}},
    /* Den svarta dörren i norra gaveln: planens utgång 16,1–16,7 m från
       väster, fasadens `u:8.1` → x 15,8–16,9. Enda dörren där plan och
       låst fasad säger samma sak. Den får sin innerdörr av autogeneratorn
       nedan (`ut_ridhus_N_8`) — den handskrivna `ut_n` som stod här pekade
       på en dörr i nordöstra hörnet som varken plan eller fasad har, och
       en dubblett vid den svarta dörren vore två markörer för en dörr.
       Huvudentrén (dubbeldörren under kvisten, västra långsidan) får också
       sin innerdörr av autogeneratorn; planen sätter den 2,2–2,7 m från
       gaveln, fasaden 9 m — `CONTRADICTION`, fasaden låst. */
  ],
  info:[
    /* Lägena härleds nedan: cafétrappornas markör framför C-blocket,
       domarbåsets vid båset. */
    {pos:[0,0], text:"Trapporna till Café Krubban", cafe:true,
     svar:"Café Krubban ligger ovanpå, bakom glasbandet. Trapporna går upp från läktarnivån — genom fönsterbanden ser man hela banan från borden där uppe."},
    {pos:[0,0], text:"Domarbåset", domarbas:true,
     svar:"Domarbåset — härifrån döms hoppklasserna på Påskhoppet. En trappa, en pall och bästa utsikten i huset."},
    {pos:[10.6,0.8],text:"Hinderförrådet",
     svar:"Hinderförrådet: bommar i blått, vitt och rött, kandelabrar, koner och cavaletti. ”HINDERSTÖD MED KLÄMHÅLLARE”, står det på lappen."},
  ],
};

STALLINNE.info=[
  /* Markörerna står inne i planens rum (`klubb.rum`), inte på gamla
     hall-koordinater söder om brandväggen som förut. */
  {pos:[1.6,63.0], text:"Klubbrummet — rosettväggen", klubb:true,
   svar:"Uppehållsrummet: svarta soffor, hästfoton på pärlsponten och en rosa träponny med riktig sadel. Här väntar man in sin lektion."},
  {pos:[9.8,62.6], text:"Sadelkammaren", sadelkammare:true, svar:""},
  {pos:[14.2,67.0], text:"Teorilektion i teorisalen", teori:true,
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

/* Sponsorskyltarnas y HÄRLEDS ur panelens stycke, så att de följer den om den
   flyttas. Se noten vid RIDHUSINNE.skyltar. Skrivs som uttryck och inte som
   tal av samma skäl som silon och gårdsplanen: varje gång ett ankare flyttats
   i det här arbetet har nästa granskning hittat ett tal som skulle ha följt
   med. */
(()=>{
  const O=IDENTITET.ridhus.ovreVagg;
  /* Panelen täcker hela hallens långsida: från A-gaveln till entrédelens
     vägg (`ridhus-inne-31`, `-17`; INTERIOR-MATRIS § 4). */
  O.y0=0; O.y1=RIDHUSINNE.langd-RIDHUSINNE.entre;
  for(const sk of RIDHUSINNE.skyltar)
    if(sk.andel!==undefined) sk.y=O.y0+(O.y1-O.y0)*sk.andel;
})();

/* ── SPELABSTRAKTIONER — traversal som spelet behöver men ingen källa visar.

   Det här är INTE fidelity-fakta om UBRF. RIDHUSINNE, STALLINNE och exporten
   `ridhus`/`stall` är den kanoniska sanningen om anläggningen; det som står
   här är spelets egna genvägar för att spelaren ska kunna ta sig fram, och
   varje post bär `klass:"SPELABSTRAKTION"` och sin fidelity-status så att
   ingen läsare, byggare eller test tar dem för verklighet.

   `sargport`: en öppning i ridbanans norra sarg för folk till fots, väster
   om C-blocket, där brandplanens utrymningspilar går från banzonen upp till
   entrén. Ingen bild visar en grind i sargen; bredden är vald. Läget följer
   banan (härleds nedan). I Roblox byggs sargen med samma gap och en
   genomskinlig markör märkt SPELABSTRAKTION; i webben är det gapet
   kollisionen släpper igenom. Fidelity-testerna får inte mäta den som
   verklighet — de får bara mäta att den är MÄRKT som abstraktion.
   (Senior Re-review 2026-09-03, blocker 2.) */
const SPELABSTRAKTIONER = {
  ridhus: {
    sargport:{x0:0, x1:0, y:0, bredd:2.2, klass:"SPELABSTRAKTION", fidelity:"REFERENCE GAP",
              motiv:"planens utrymningspilar; ingen bild visar grinden; bredden vald"},
  },
};

/* Läktarens och panelens SIDA härleds ur RIDHUSINNE.sidor, så att en framtida
   spegling blir en dataändring och inte ett ombygge. Se noten vid `sidor`. */
(()=>{
  const R=RIDHUSINNE, S=R.sidor;
  if(!S)return;
  const D=R.laktare.dackDjup;
  IDENTITET.ridhus.ovreVagg.sida = S.panel;
  /* BANAN måste följa med sidan. Den ligger inte centrerad i hallen utan
     tätt mot den vägg som INTE har läktare: 20 m bana i en 25 m hall
     lämnar 4,4 m på läktarsidan och 0,6 m på den andra.

     Speglingsprovet hittade det här: med `laktare:"W"` hamnade läktaren
     INNE PÅ BANAN, 170 m² överlapp. En spegling är alltså inte en ren
     sidoändring — banan måste flytta med, och det gör den nu. */
  R.bana.x = (S.laktare==="E") ? 0.6 : R.bredd-0.6-R.bana.w;
  R.laktare.x0 = (S.laktare==="E") ? R.bredd-D-0.6 : 0.6;
  /* Läktaren löper längs hela banan i planen. */
  R.laktare.y0 = R.bana.y; R.laktare.y1 = R.bana.y+R.bana.h;
  /* Båset står PÅ däcket och måste följa med sidan. Däcket löper alltid
     FRÅN x0 i positiv x-led, åt båda hållen — mitt första försök vände
     tecknet och la båset 2 m utanför däcket. Speglingsprovet fällde det. */
  if(R.domarbas){
    R.domarbas.x = R.laktare.x0+D*0.65;
    /* E sitter mitt på långsidan: banans halva längd. */
    R.domarbas.y = R.bana.y+R.bana.h/2;
  }
  /* SPELABSTRAKTIONEN sargport följer banan (banans nordvästra hörn, väster
     om C-blocket, där planens pilar går). Den är inte fidelity — se
     SPELABSTRAKTIONER — men den måste flytta med banan vid en spegling. */
  {const sp=SPELABSTRAKTIONER.ridhus.sargport;
   sp.x0 = R.bana.x+0.3; sp.x1 = sp.x0+sp.bredd; sp.y = R.bana.y+R.bana.h;}
  /* Fasadens dörrar i läktarens långsida (svarta dörren vid skylten, u 40)
     öppnar i verkligheten ut på läktardäcket. Spelet har inget gående på
     däcksnivå — däcket är solitt i kollisionen — så autogeneratorns
     innerpunkt hamnade INNE I läktaren när sidan vändes: spawn i en
     kolliderare, dörren obrukbar. Punkten flyttas till däckets fot på
     sandsidan: man kommer in genom dörren, över däcket och ner på banan.
     Spelabstraktion, inte ett faktapåstående om dörren; själva dörren
     sitter kvar där fasaden har den. */
  const lakt={x0:R.laktare.x0, x1:R.laktare.x0+D, y0:R.laktare.y0, y1:R.laktare.y1};
  const iLakt=(x,y)=>x>lakt.x0-0.5&&x<lakt.x1+0.5&&y>lakt.y0&&y<lakt.y1;
  const fot=(S.laktare==="E") ? R.bana.x+R.bana.w-0.8 : R.bana.x+0.8;
  for(const d of R.dorrar) if(d.auto&&iLakt(d.pos[0],d.pos[1])) d.pos[0]=fot;
  for(const d of ANL.dorrar) if(d.auto&&d.mot==="ridhusinne"&&iLakt(d.spawn.x,d.spawn.y)) d.spawn.x=fot;
})();

/* Väggdekoren följer också med speglingen nu. Den låg kvar som känd lucka i
   ett pass, och reviewn hade rätt i att en arkitektur som medvetet gjorts
   vändbar inte ska ha gömd stale geometri kvar i sig. */
(()=>{
  const R=RIDHUSINNE, S=R.sidor;
  if(!S)return;
  /* Speglarna hänger på panelväggen, alltså mitt emot läktaren. */
  R.spegelSida = S.panel;
  /* Kortändans klocka sitter MELLAN de två trapporna. */
  const K=R.kortanda;
  if(K&&K.trappor&&K.trappor.length>=2){
    if(K.klocka)  K.klocka.x=(K.trappor[0]+K.trappor[1])/2;
    /* Stjärnan sitter till vänster om vänstra trappan. */
    if(K.stjarna) K.stjarna.x=(K.x0+K.trappor[0])/2;
  }
  /* Caféets golv ligger där C-blockets glasband börjar: det är samma
     våning, nådd via blockets trappor. Ett tal här hade glidit isär från
     blocket vid nästa ändring. */
  if(K&&R.cafe) R.cafe.z0 = (K.sockelH||0)+K.steg*K.stegH+K.glasOver;
  /* Markörerna framför C-blocket och vid domarbåset följer sina objekt. */
  for(const i of R.info||[]){
    if(i.cafe&&K){ i.pos[0]=(K.trappor[0]+K.trappor[1])/2; i.pos[1]=(K.vand==="S"?K.y0:K.y1)-0.8; }
    if(i.domarbas&&R.domarbas){ i.pos[0]=R.domarbas.x+(S.laktare==="E"?-1:1)*(R.domarbas.b/2+0.6); i.pos[1]=R.domarbas.y; }
  }
})();
