/* ══════════════════════════════════════════════════════════════════
   ANLÄGGNINGEN — UBRF, Husbyvägen 1A, Bro. All geometri i meter.
   Koordinatsystem: origo i sydväst, +x öster, +y norr.
   Byggd mot referensfotona i Drive-mappen UBRF (IMG_0064–0166):
   ridhuset i mörkröd korrugerad plåt med svarta detaljer, cafétrappan
   på södra gaveln, UBRF-skylten på västra långsidan mot grusvägen och
   åkrarna, gräsgården mellan ridhus och stall, stallets faluröda
   träpanel med vita knutar och välvda småfönster, verandan med den
   gulockra entrédörren på södra gaveln, fodersilon vid norra gaveln,
   utebanorna på slänten i nordväst med domarkuren, hagarna i öster.
   Geometrin här är den enda sanningen — rendering läser bara detta.
   ══════════════════════════════════════════════════════════════════ */

const ANL = {
  bredd: 210, djup: 170,

  /* Markytor ritas i ordning — senare vinner. */
  mark: [
    {typ:"gras",  rekt:{x:0,   y:0,   w:210, h:170}},
    {typ:"aker",  rekt:{x:0,   y:44,  w:112, h:80}},   // åkrarna väster om grusvägen
    {typ:"asfalt",rekt:{x:0,   y:2,   w:210, h:5}},    // Husbyvägen
    {typ:"grus",  rekt:{x:106, y:7,   w:16,  h:14}},   // infarten
    {typ:"grus",  rekt:{x:112, y:16,  w:38,  h:28}},   // grusparkeringen vid södra gaveln
    {typ:"grus",  rekt:{x:112, y:44,  w:6,   h:76}},   // grusvägen längs västra långsidan
    {typ:"grus",  rekt:{x:112, y:110, w:34,  h:16}},   // vägen svänger runt norra gaveln
    {typ:"grus",  rekt:{x:144, y:20,  w:48,  h:26}},   // gårdsplanen vid stallentrén
    {typ:"grus",  rekt:{x:166, y:44,  w:10,  h:60}},   // gången öster om stallet mot hagarna
    {typ:"grus",  rekt:{x:88,  y:112, w:26,  h:10}},   // stigen mot utebanorna
    {typ:"betong",rekt:{x:100, y:112, w:8,   h:6}},    // betongplattan nedanför slänten
    {typ:"slant", rekt:{x:64,  y:114, w:52,  h:6}},    // slänten upp mot banorna
    {typ:"sand",  rekt:{x:92,  y:122, w:20,  h:40}},   // uteridbanan (dressyr, 20×40 synlig del)
    {typ:"sand",  rekt:{x:66,  y:122, w:20,  h:34}},   // grusbanan/paddocken bortom
    {typ:"grus",  rekt:{x:150, y:102, w:26,  h:8}},    // bakgården vid silon
  ],
  cirklar: [ // runda markytor
    {typ:"sand", c:[151,31], r:4.6, kant:true},        // lekhagen med stenhästarna
  ],

  byggnader: [
    /* Ridhuset — mörkröd korrugerad plåt, svart takfot och hörnpartier.
       Tvåvåningsdel i söder med Café Krubban och yttertrappan;
       UBRF-skylten mitt på västra långsidan; banan 20×60 därinne. */
    {id:"ridhus", rekt:{x:118, y:44, w:26, h:66}, hV:6.2, hN:9.2, nock:"NS",
     fargV:"#6E1F1D", fargT:"#26282C", plat:true, label:"RIDHUSET",
     oppningar:[
       {sida:"S", u:4,  b:1.3, h:2.1, z0:0, typ:"dorr"},     // entré under skärmtak
       {sida:"S", u:8,  b:1.3, h:2.1, z0:0, typ:"dorr"},
       {sida:"S", u:15, b:2.0, h:1.4, z0:1.2, typ:"fonster"},// välvda vita fönster nere
       {sida:"S", u:21, b:2.0, h:1.4, z0:1.2, typ:"fonster"},
       {sida:"S", u:15, b:2.0, h:1.3, z0:3.9, typ:"fonster"},// ... och uppe (caféet)
       {sida:"S", u:21, b:2.0, h:1.3, z0:3.9, typ:"fonster"},
       {sida:"S", u:18.6,b:1.1,h:2.0, z0:3.8, typ:"dorr"},   // cafédörren vid trappan
       {sida:"W", u:14, b:1.5, h:2.2, z0:0, typ:"dorr"},     // rampentrén (handikapp)
       {sida:"W", u:52, b:1.1, h:2.1, z0:0, typ:"dorr"},     // personaldörren
       {sida:"E", u:4,  b:3.4, h:2.9, z0:0, typ:"portplat"}, // durkplåtdörrarna mot gården
       {sida:"N", u:9,  b:4.0, h:3.6, z0:0, typ:"portsilver"},// stora silverporten
     ]},
    /* Stallet — faluröd träpanel, vita knutar, välvda småfönster,
       grått plåttak med rad av svarta ventilationshuvar. Byggt 2016.
       Södra gaveln: klubbdelens entré med veranda och gulockra dörr. */
    {id:"stall", rekt:{x:154, y:46, w:15, h:54}, hV:3.5, hN:6.0, nock:"NS",
     fargV:"#7C2A24", fargT:"#7E8288", huvar:true, label:"STALLET",
     oppningar:[
       {sida:"S", u:6.3, b:1.2, h:2.1, z0:0, typ:"dorrgul"}, // Entré (gulockra)
       {sida:"S", u:3.4, b:0.9, h:0.9, z0:1.5, typ:"rund"},  // bullseye-fönstren
       {sida:"S", u:10.6,b:0.9, h:0.9, z0:1.5, typ:"rund"},
       {sida:"W", u:25,  b:1.8, h:2.2, z0:0, typ:"dorrvit"}, // vita dubbeldörren mot gården
       {sida:"W", u:6,  b:1.1, h:1.0, z0:1.4, typ:"valv"},   // välvda småfönster
       {sida:"W", u:12, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"W", u:18, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"W", u:33, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"W", u:39, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"W", u:45, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"E", u:8,  b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"E", u:20, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"E", u:32, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"E", u:44, b:1.1, h:1.0, z0:1.4, typ:"valv"},
       {sida:"N", u:6.1, b:2.8, h:2.7, z0:0, typ:"dorrgra"}, // grå dubbeldörren (service)
     ]},
    /* Förbindelselängan som gör stallet till ett L och stänger gården. */
    {id:"langa", rekt:{x:144, y:100, w:10, h:6}, hV:3.0, hN:4.4, nock:"EW",
     fargV:"#7C2A24", fargT:"#7E8288", label:"",
     oppningar:[{sida:"S", u:4.4, b:1.1, h:2.0, z0:0, typ:"dorrmork"}]},
    /* Röda stugan vid infarten (förråd/sekretariat). */
    {id:"stuga", rekt:{x:94, y:12, w:6.5, h:4.5}, hV:2.5, hN:3.8, nock:"EW",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"E", u:1.2, b:1.6, h:0.9, z0:1.1, typ:"fonster"},
                {sida:"S", u:1.6, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Domarkuren vid uteridbanan. */
    {id:"domarkur", rekt:{x:114, y:146, w:4.5, h:3.5}, hV:2.3, hN:3.4, nock:"EW",
     fargV:"#8A3A30", fargT:"#5A2B26", label:"",
     oppningar:[{sida:"W", u:0.8, b:2.6, h:1.0, z0:1.0, typ:"fonster"}]},
    /* Boden vid norra gaveln (vid sopstationen). */
    {id:"bod", rekt:{x:120, y:116, w:5, h:4}, hV:2.3, hN:3.4, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"",
     oppningar:[{sida:"S", u:1.4, b:1.4, h:0.9, z0:1.1, typ:"fonster"}]},
    /* Elcentralen/boden vid stigen mot banorna. */
    {id:"elbod", rekt:{x:88, y:116, w:3, h:2.5}, hV:2.0, hN:2.8, nock:"NS",
     fargV:"#8A3A30", fargT:"#3A3E44", label:"", oppningar:[]},
  ],

  /* Staket: postlinjer. "tra" = kraftigt trästaket med två reglar
     (banor och hagar), "el" = trådstängsel mot åkern, "rail" = låg
     falurödmålad trärail (parkering/lekhage). */
  staket: [
    {typ:"tra", p:[[92,122],[112,122],[112,162],[92,162],[92,122]]},   // uteridbanan
    {typ:"tra", p:[[66,122],[86,122],[86,156],[66,156],[66,122]]},     // paddocken bortom
    {typ:"tra", p:[[176,44],[206,44],[206,72],[176,72],[176,44]]},     // hage Ö1
    {typ:"tra", p:[[176,76],[206,76],[206,102],[176,102],[176,76]]},   // hage Ö2
    {typ:"tra", p:[[152,110],[202,110],[202,134],[152,134],[152,110]]},// hage N
    {typ:"el",  p:[[112,44],[112,110]]},                               // trådstängsel mot åkern
    {typ:"rail",p:[[112,42],[150,42]]},                                // rail mot parkeringen
    {typ:"rail",p:[[146,26],[146,36]]},                                // rail vid lekhagen
  ],
  hagar: [ // betande hästar (id ur HORSES) för liv i bilden
    {rekt:{x:176,y:44,w:30,h:28}, hastar:["cosmo","air"]},
    {rekt:{x:176,y:76,w:30,h:26}, hastar:["larry"]},
    {rekt:{x:152,y:110,w:50,h:24}, hastar:["lydia","toblerone","dexter"]},
  ],

  /* Träd: [x, y, radie]. Skogsbryn i norr och väster, björkraden
     längs grusvägen, lövträden runt gårdsplanen. */
  trad: [
    [110,50,1.6],[110,62,1.7],[110,74,1.6],[110,86,1.8],[110,98,1.6],  // björkraden
    [122,14,2.6],[130,12,2.2],[88,10,2.6],[104,24,1.8],
    [150,16,2.8],[160,18,2.4],[172,16,2.8],[184,20,2.6],[196,24,3.0],
    [194,36,2.6],[208,60,3.0],[208,90,3.2],[206,106,2.8],
    [60,118,3.0],[56,130,3.4],[58,144,3.0],[62,158,3.2],[70,164,3.0],
    [80,166,3.4],[92,168,3.0],[104,166,3.2],[116,166,3.0],[128,164,3.4],
    [140,162,3.0],[150,158,2.8],[160,150,2.6],[120,158,2.4],[88,160,2.8],
    [46,120,3.2],[40,132,3.0],[44,148,3.4],[36,160,3.0],
    [148,120,2.2],[148,128,2.0],
  ],

  /* Rekvisita — ritas i 2D och 3D av world.js. */
  props: [
    {typ:"silo",      pos:[171,102]},                    // fodersilon vid norra gaveln
    {typ:"balar",     pos:[160,105]},                    // ensilagebalarna
    {typ:"grushog",   pos:[152,104]},
    {typ:"transport", pos:[148,42], rikt:0.3},           // hästtransporten
    {typ:"bord",      pos:[150,60]},                     // picknickborden på gräsgården
    {typ:"bord",      pos:[148,72]},
    {typ:"bank",      pos:[146,80]},
    {typ:"stol",      pos:[149,88]},
    {typ:"bord",      pos:[158,38]},                     // gårdsplanens möbler
    {typ:"bank",      pos:[164,40]},
    {typ:"trappa",    pos:[137,43.6], norm:[0,-1]},                   // cafétrappan på södra gaveln
    {typ:"skylt",     pos:[118,77], text:"UPPLANDS-BRO RYTTARFÖRENING", norm:[-1,0]},
    {typ:"cafeskylt", pos:[135,43.8], norm:[0,-1]},
    {typ:"flagga",    pos:[107,15]},
    {typ:"skyltstolpe",pos:[147,40]},
    {typ:"stenhast",  pos:[149.5,29.5]},                 // stenhästarna i lekhagen
    {typ:"stenhast",  pos:[152.5,32]},
    {typ:"stenhast",  pos:[150.5,33]},
    {typ:"stenhast",  pos:[152,29]},
    {typ:"mast",      pos:[92,162]},                     // belysningsmasterna vid banorna
    {typ:"mast",      pos:[112,122]},
    {typ:"mast",      pos:[66,156]},
    {typ:"sopstation",pos:[103,13]},
    {typ:"ac",        pos:[144.4,54], norm:[1,0]},                   // värmepumparna mot gården
    {typ:"ac",        pos:[144.4,58], norm:[1,0]},
    {typ:"veranda",   pos:[160.3,45.6], norm:[0,-1]},                 // verandan vid stallentrén
    {typ:"busskylt",  pos:[118,7.6]},
  ],

  /* Interaktionspunkter på gården. */
  dorrar: [
    {id:"stallentre", pos:[160.3,45.2], text:"Gå in i stallet (Entré)",
     mot:"stallinne", spawn:{x:7.5, y:2.2, rikt:Math.PI/2}},
    {id:"stall_v",  pos:[153.6,71], text:"Gå in i stallet (gårdsdörren)",
     mot:"stallinne", spawn:{x:1.2, y:25, rikt:0}},
    {id:"stall_n",  pos:[160.3,100.8], text:"Gå in i stallet (bakre dörren)",
     mot:"stallinne", spawn:{x:7.5, y:50, rikt:-Math.PI/2}},
    {id:"ridhus_o", pos:[144.4,50], text:"In i ridhuset (durkplåtdörrarna)",
     mot:"ridhusinne", spawn:{x:24.4,y:4.5,rikt:Math.PI}},
    {id:"ridhus_s", pos:[122.5,43.6], text:"In i ridhuset (entrén)",
     mot:"ridhusinne", spawn:{x:5,y:1.4,rikt:Math.PI/2}},
    {id:"cafe", pos:[137.5,43.4], text:"Café Krubban (trappan upp)", mot:"info",
     info:"Café Krubban har stängt för kvällen. Kolla in vyn över banan från läktaren i stället."},
  ],
  spawn: {x:113, y:10, rikt:Math.PI/2},   // vid infarten från Husbyvägen
  /* Hagen där dagens häst hämtas: grinden på västra sidan av hage Ö1. */
  hamtHage: {grind:[176,58], falt:[184,56]},
  skylt: {pos:[113,5.5], text:"HUSBYVÄGEN 1A · UPPLANDS-BRO RYTTARFÖRENING"},
};

/* ── Stallet invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 15), +y norr (längd 52).
      Söder: klubbdelen (uppehållsrum, teorisal, toaletter) innanför
      entrén — vit pärlspont, betonggolv. Branddörren in till stallet
      ("schysst stall"-dekalen). Mitten: stallgången — marksten, två
      rader boxar i antracitgrå komposit med galvade galler, namn-
      skyltar, limträbalkar och taklanterniner. Norr: servicedelen
      med spolspilta, spånförråd och uppbindningsplatser. ── */
const STALLINNE = {
  bredd:15, langd:52, ganghalva:2.6,
  vagg:"#CFC8BC", golv:"#8C8880", gangGolv:"#9A968E", tak:3.4,
  klubbY:9, boxStartY:10.4, serviceY:45.5,
  boxB:3.5, boxDjup:5.0,
  /* Boxrader: HORSES-id för spelbara hästar, "#NAMN" för boxar med
     riktiga namnskyltar ur fotona (LADY, WESTSIDE, MAKADU, KENNEDY,
     TINA, MARA, HUSKY, CHIP), null = tom box. */
  boxar:{
    W:[ "#LADY","toblerone","#WESTSIDE","lydia","#MAKADU","conor","#MARA","hamilton","#HUSKY",null ],
    E:[ "#KENNEDY","cosmo","#TINA","air","#CHIP","larry","crokino","dexter",null,null ],
  },
  rum:[
    {id:"uppehallsrum", rekt:{x:0,   y:0, w:6.0, h:9}, label:"UPPEHÅLLSRUM"},
    {id:"teorisal",     rekt:{x:9.0, y:0, w:6.0, h:9}, label:"TEORISAL · WC"},
  ],
  service:[
    {id:"spolspilta",   rekt:{x:0,   y:45.5, w:6.0, h:6.5}, label:"SPOLSPILTA"},
    {id:"spanforrad",   rekt:{x:9.0, y:45.5, w:6.0, h:6.5}, label:"SPÅNFÖRRÅD"},
  ],
  /* Tvärväggar med dörröppning i gångens bredd. */
  tvarvaggar:[ {y:9, gap:2.8, brand:true}, {y:45.5, gap:2.8, brand:false} ],
  dorrar:[
    {id:"ut_s", pos:[7.5,0.8],  text:"Ut till gårdsplanen", mot:"gard",
     spawn:{x:160.3,y:44.2,rikt:-Math.PI/2}},
    {id:"ut_v", pos:[0.8,25],   text:"Ut till gräsgården", mot:"gard",
     spawn:{x:152.6,y:71,rikt:Math.PI}},
    {id:"ut_n", pos:[7.5,51.2], text:"Ut till bakgården", mot:"gard",
     spawn:{x:160.3,y:101.8,rikt:Math.PI/2}},
  ],
  ridlarare:{pos:[7.5,18], namn:"Ridläraren"},
  whiteboard:{pos:[7.5,45.0]},   // veckoschemat vid spolspiltan (IMG_0154)
};

/* ── Ridhuset invändigt — lokala koordinater: origo i sydväst,
      +x öster (bredd 26), +y norr (längd 65). Banan 20×60 innanför
      vit murad sarg med svart sockel (IMG_0095–0116): sponsorväggen
      med speglarna i väster, läktaren med domarbåset i öster,
      cafeteria-överbyggnaden med fönsterband och trappan i söder,
      hinderförrådet i norr. Sargporten vid A släpper in ekipagen. ── */
const RIDHUSINNE = {
  bredd:26, langd:65, tak:6.2,
  bana:{x:2.5, y:3, w:20, h:60}, sargH:1.35,
  vagg:"#E9E5DC", sockel:"#2E2E2C", sandFarg:"#5E4A36", gangFarg:"#8C8880",
  panel:"#6B4A34", panelList:"#EFE8D8",           // sponsorväggens bruna trä
  laktare:{x0:23.5, y0:6, y1:54, steg:3, stegH:0.28, stegD:0.8},
  domarbas:{x:24.2, y:56.5, b:1.8, h:2.2},
  cafe:{djup:3.0, z0:2.55, z1:5.4},               // överbyggnaden i söder
  trappa:{x:22.2, y:3.2},                          // trätrappan upp till caféet
  speglar:[ {y:28,b:4.2},{y:45,b:3.2} ],           // på västra långsidan
  skyltar:[
    {y:12,  b:5.0, text:"VÄLKOMMEN TILL UPPLANDS-BRO RYTTARFÖRENING", fg:"#3A3E44", bg:"#F2EDE2"},
    {y:18.5,b:4.0, text:"HUVUDSPONSOR ELON BARKARBY", fg:"#F0EADC", bg:"#1C1C1E"},
    {y:33.5,b:3.6, text:"Vi tror på dig! · Sparbanken i Enköping", fg:"#C0392B", bg:"#F7F2E8"},
    {y:38.5,b:3.0, text:"Agria Djurförsäkring", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:50,  b:3.4, text:"RS Mustang · Stallströ och foder", fg:"#F0EADC", bg:"#2F5C8F"},
    {y:57,  b:3.6, text:"Stigsbergs Gård · Hästsportbutik", fg:"#3A3E44", bg:"#F2EDE2"},
  ],
  port:{x0:11.5, x1:13.5},                         // sargporten vid A (södra kortsidan)
  dorrar:[
    {id:"ut_o", pos:[25.2,4.5],  text:"Ut till gårdsplanen", mot:"gard",
     spawn:{x:145.6,y:50,rikt:0}},
    {id:"ut_s", pos:[5,0.8],   text:"Ut mot parkeringen (entrén)", mot:"gard",
     spawn:{x:122.5,y:42.6,rikt:-Math.PI/2}},
  ],
  info:[
    {pos:[22.4,3.6],  text:"Trappan till Café Krubban",
     svar:"Café Krubban har stängt för kvällen. Genom fönsterbanden ser man hela banan från borden där uppe."},
    {pos:[24.5,57],   text:"Domarbåset",
     svar:"Domarbåset — härifrån döms hoppklasserna på Påskhoppet. En trappa, en pall och bästa utsikten i huset."},
    {pos:[12.5,64.2], text:"Hinderförrådet",
     svar:"Hinderförrådet: bommar i blått, vitt och rött, kandelabrar, koner och cavaletti. ”HINDERSTÖD MED KLÄMHÅLLARE”, står det på lappen."},
  ],
};
/* Infopunkter i stallet (klubbdelen och servicedelen). */
STALLINNE.info=[
  {pos:[6.2,4.5],  text:"Uppehållsrummet",
   svar:"Uppehållsrummet: svarta soffor, hästfoton på pärlsponten och en rosa träponny med riktig sadel. Här väntar man in sin lektion."},
  {pos:[8.8,4.5],  text:"Teorilektion i teorisalen", teori:true,
   svar:""},
  {pos:[6.2,46.2], text:"Spolspiltan",
   svar:"Spolspiltan: gummimattor, duschblandare och slangvinda. Att spola av hästen efter lektionen kommer med stallmomenten i steg 2."},
  {pos:[8.8,46.2], text:"Spånförrådet",
   svar:"Spånförrådet: Mustang kutterspån på pall i galvad bur. Mockning och strö kommer med stallmomenten i steg 2."},
];
