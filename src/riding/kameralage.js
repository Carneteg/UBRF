/* ══════════════════════════════════════════════════════════════════
   G02-E DEL 1 — KAMERALÄGET UNDER RITTEN (issue #150)

   Tobias produktbeslut 2026-09-08: när spelaren rider ska standard-
   kameran vara RYTTARENS perspektiv — vyn från sadeln, med hästens hals
   och öron och vägen framåt. När feedback ges får spelet TILLFÄLLIGT
   visa en annan relevant vinkel — sits, vägval, hinderansats, avstånd,
   hästens form eller tajming — och sedan ska kameran återgå. Växlingen
   ska vara mjuk, kort och inte störa kontrollkänslan.

   VAD SOM FAKTISKT FANNS INNAN. Ingen av ytorna hade ett ryttar-
   perspektiv. Webbens `s3Kamera()` la ögat på en bom BAKOM hästen —
   3,78 m i halt, 4,05 i skritt, 4,59 i trav, 5,13 i galopp — och
   Roblox CameraController gjorde detsamma med Gaits.camera.dist på
   14–23 studs. Båda är tredjepersonskameror. Ett läge som HETER
   `ryttare` men behåller bommen hade varit den gamla vyn under nytt
   namn, och det är inte vad beslutet ber om.

   Del 1 gör därför två saker samtidigt, och båda måste finnas för att
   leveransen ska betyda något:

     · en RIKTIG sadelvy renderas på båda ytorna, byggd ur riggens egen
       ryttare — sits, huvud och ögonpunkt — inte ur påhittade
       anläggningskoordinater eller en uppfunnen ögonhöjd,
     · det här läget äger VEM som får bilden och hur den lämnas
       tillbaka.

   Den gamla tredjepersonskameran är inte kastad. Den är DEGRADERAD
   till en av feedbackvinklarna (`utifran`), där den hör hemma: att se
   sig själv utifrån är pedagogiskt, men det är inte att rida.

   Modulen är ett rent tillstånd utan rendering:

   1. SADELN ÄR STANDARD. Läget börjar i `ryttare` och faller alltid
      tillbaka dit. Det finns inget sätt att sätta ett annat läge
      permanent, och ingen manuell kamerapreferens kan ersätta det.
   2. EN FEEDBACKVINKEL ÅT GÅNGEN, aldrig köad. En begäran tas emot
      eller avvisas på plats. Ingen begäran kan ligga och vänta och
      tändas senare — det är precis så en spelare blir strandsatt i en
      vy hon inte bad om.
   3. TIDEN ÄR BEGRÄNSAD I KODEN, inte i god vilja. Varje vinkel har
      in-, håll- och uttoning, summan är validerad mot ett tak, och
      ovanpå det ligger en hård gräns som tvingar hem bilden även om
      någon skulle lägga in en orimlig konfiguration.
   4. VIKTEN ÄR MJUK OCH DETERMINISTISK. Övergången körs på en smooth-
      step av ackumulerad dt, inte på väggklocka, så samma bildrute-
      följd ger samma bild oavsett bildfrekvens.

   VIKTEN 0 ÄR SADELVYN, VIKTEN 1 ÄR FEEDBACKVINKELN. Renderaren
   interpolerar mellan de två färdiga kamerorna, så en halv vikt är en
   kamera på väg — inte ett tredje specialfall som kan gå sönder för
   sig.

   VINKLARNA ÄR RELATIVA TILL HÄSTEN. Det är inte en förenkling utan
   ett källkrav: `CLAUDE.md` förbjuder påhittade UBRF-detaljer, och en
   kameravinkel angiven i anläggningens koordinater hade varit just det.
   Talen nedan är yaw i radianer runt hästen plus fyra MULTIPLIKATORER
   på den gångartsburna bom som redan finns. Därför bär webben och
   Roblox EXAKT samma tal trots att den ena mäter i meter och radianer
   och den andra i studs och grader — förhållandet är det man känner,
   och det är samma paritetsregel som redan gäller `KAM_GANG`.

   Modulen rör inte hästen, inte inputen och inte fysiken. Den kan
   varken ändra styrningen eller tempot; den säger bara var bilden ska
   tas ifrån. ── */
(function(root){
  "use strict";

  /* Neutralläget = sadelvyn. Vikt 0 betyder "ingen feedbackvinkel alls",
     och då rör renderaren inte bomvärdena över huvud taget. Att sadeln
     är frånvaron av en vinkel och inte ett eget specialfall är avsikt:
     går läget sönder är ryttarperspektivet kvar. */
  const NEUTRAL={yaw:0, bak:1, hojd:1, fov:1, blick:1};

  /* Hårda gränser för en feedbackvinkel. En konfiguration som faller
     utanför dem registreras inte alls — hellre ingen vinkel än en
     vinkel som ställer kameran inuti hästen eller håller kvar bilden i
     en kvart. */
  const GRANS={
    yaw  :[-Math.PI, Math.PI],   // runt hästen; ±π är rakt framifrån
    bak  :[0.35, 3.0],           // × gångartens bom
    hojd :[0.40, 4.0],           // × gångartens kamerahöjd
    fov  :[0.75, 1.35],          // × bomkamerans synfält
    blick:[-1.5, 2.5],           // × siktpunkten framför hästen
    in   :[0.15, 1.2],           // intoning, sekunder
    hall :[0.20, 4.0],           // hålltid, sekunder
    ut   :[0.15, 1.5],           // uttoning, sekunder
  };
  /* Taket för in+håll+ut. Kortare än en ridövning och kort nog att man
     aldrig hinner vilja styra ur feedbackvyn. */
  const MAX_TOTAL=6.0;
  /* Nödbromsen ovanpå taket: bilden tvingas hem även om en vinkel
     smiter förbi valideringen. */
  const MAX_UT=GRANS.ut[1];
  /* Samma dt-tak som renderaren använder (src/scen3d.js). En bildruta
     som tagit en halv sekund ska inte hoppa halvvägs genom en
     övergång. */
  const DT_TAK=0.1;

  /* ── Vinklarna ─────────────────────────────────────────────────────
     Fyra vinklar, en per sak Tobias räknade upp, plus den gamla
     utifrånvyn. Fler hör till del 2 och ska in när det är bestämt
     VILKEN händelse som ska visa vad; att lägga in dem nu vore att
     gissa pedagogiken i förväg.

     Talen är DERIVED — spelkänsla, inte UBRF-fakta. */
  const VINKLAR={
    /* DEN GAMLA TREDJEPERSONSVYN, oförändrad tal för tal: yaw 0 och
       alla multiplikatorer 1 ger exakt den bom `KAM_GANG` beskriver.
       Den ligger kvar för att den är den bästa översiktsbilden vi har —
       men som en LÅNAD vy, inte som ridningens standard. */
    utifran:{yaw: 0,         bak:1.00, hojd:1.00, fov:1.00, blick:1.00,
             in:0.45, hall:1.80, ut:0.55},
    /* SITSEN OCH HÄSTENS FORM. Från sidan, med blicken på ekipaget i
       stället för på vägen framåt: det är den enda vinkel där man ser
       sin egen position i sadeln och hästens ram samtidigt. Något
       snävare synfält, för det är en detalj man ska läsa. */
    sits   :{yaw: Math.PI/2, bak:0.95, hojd:0.92, fov:0.94, blick:0.10,
             in:0.40, hall:1.60, ut:0.50},
    /* VÄGVALET OCH AVSTÅNDET. Bakifrån men högre och längre bak, med
       blicken längre fram: spåret, linjen och hur långt det är kvar
       till nästa punkt blir läsbart. Vidare synfält av samma skäl. */
    vagval :{yaw: 0,         bak:1.90, hojd:2.40, fov:1.08, blick:1.30,
             in:0.45, hall:1.70, ut:0.55},
    /* HINDERANSATSEN OCH TAJMINGEN. Framifrån, låg. Blicken dras bakom
       hästen så att hon står mellan kameran och siktpunkten — det är
       vad som gör att man ser rakheten och stegen in mot hindret i
       stället för hindret självt. */
    ansats :{yaw: Math.PI,   bak:1.25, hojd:1.05, fov:1.00, blick:-0.35,
             in:0.40, hall:1.50, ut:0.50},
  };

  /* ── Validering ────────────────────────────────────────────────────
     Körs en gång vid inläsning. En vinkel som inte håller måtten tas
     BORT ur tabellen i stället för att klampas till något närliggande:
     en tyst korrigering hade gjort att felet aldrig upptäcktes. */
  const inom=(v,g)=>typeof v==="number"&&isFinite(v)&&v>=g[0]&&v<=g[1];
  function validera(id,v){
    if(!v||typeof v!=="object")return "ingen tabell";
    for(const nyckel of ["yaw","bak","hojd","fov","blick","in","hall","ut"])
      if(!inom(v[nyckel],GRANS[nyckel]))
        return `${nyckel}=${v[nyckel]} utanför [${GRANS[nyckel][0]}, ${GRANS[nyckel][1]}]`;
    const total=v.in+v.hall+v.ut;
    if(total>MAX_TOTAL)return `in+håll+ut = ${total.toFixed(2)} s över taket ${MAX_TOTAL} s`;
    return null;
  }
  for(const id of Object.keys(VINKLAR)){
    const fel=validera(id,VINKLAR[id]);
    if(fel){
      if(typeof console!=="undefined")
        console.warn(`Kameralage: vinkeln "${id}" registrerades inte — ${fel}`);
      delete VINKLAR[id];
    }
  }

  function giltig(id){ return typeof id==="string"&&Object.prototype.hasOwnProperty.call(VINKLAR,id); }
  function vinkel(id){ return giltig(id)?VINKLAR[id]:null; }
  function vinkelnamn(){ return Object.keys(VINKLAR); }

  /* ── Tillståndet ───────────────────────────────────────────────────
     `fas` är den enda sanningen om var i övergången vi är:
       vila  — sadelvyn, vikt 0, ingen vinkel utlånad
       in    — vikten stiger mot den begärda vinkeln
       hall  — vinkeln ligger stilla på full vikt
       ut    — vikten faller tillbaka mot sadeln
     Det finns AVSIKTLIGT ingen femte fas och ingen kö. */
  function skapa(){
    return {lage:"ryttare", id:null, fas:"vila", t:0, total:0,
            vikt:0, startVikt:0, orsak:null};
  }

  const mjuk=p=>{const w=p<0?0:p>1?1:p; return w*w*(3-2*w);};

  /* Begär en tillfällig feedbackvinkel.

     Returnerar true om begäran togs emot, annars false UTAN att röra
     tillståndet. Avvisning är regel, inte undantag:

     - Okänd vinkel avvisas. Ett stavfel i del 2 ska inte kunna ge en
       tom eller påhittad vy.
     - En ANNAN vinkel medan en redan är uppe avvisas. Att byta vinkel
       mitt i en pågående vikt hade flyttat kameran ett halvt varv i en
       bildruta — ett klipp mitt i styrningen, vilket är precis vad
       beslutet förbjuder. Anroparen får släppa den pågående vyn först
       och begära igen när `aktiv()` är falsk.
     - SAMMA vinkel medan den är uppe TAS EMOT och startar om från
       nuvarande vikt. Offseten är identisk, så det syns ingen skarv —
       det är den enda omstart som är kontinuerlig.

     `total` NOLLSTÄLLS BARA VID EN RIKTIGT NY BEGÄRAN (fas var "vila").
     En upprepad begäran om SAMMA vinkel medan den redan är uppe rör
     inte `total` — annars kunde en anropare som råkar begära om samma
     vinkel varje bildruta (en händelse som triggar upprepat, ett
     dubbeltryck som studsar) hålla kvar feedbackvyn för evigt genom att
     varje anrop nollställde klockan som `MAX_TOTAL`/nödbromsen läser.
     Den ORIGINALA deadlinen, räknad från första begäran, gäller alltså
     oavsett hur många gånger samma vinkel begärs på nytt. */
  function begar(st,id,orsak){
    if(!st||!giltig(id))return false;
    const nyBegaran=st.fas==="vila";
    if(!nyBegaran&&st.id!==id)return false;
    st.lage="feedback";
    st.id=id;
    st.fas="in";
    st.t=0;
    if(nyBegaran)st.total=0;
    st.startVikt=st.vikt;
    st.orsak=orsak==null?null:String(orsak);
    return true;
  }

  /* Släpp vyn i förtid — mjukt. Används när sammanhanget tar slut men
     spelaren fortfarande rider: uttoningen körs, och sedan är sadeln
     tillbaka. Ingen effekt om ingen vy är uppe. */
  function slapp(st,orsak){
    if(!st||st.fas==="vila"||st.fas==="ut")return false;
    st.fas="ut";
    st.t=0;
    st.startVikt=st.vikt;
    if(orsak!=null)st.orsak=String(orsak);
    return true;
  }

  /* Nollställ HÅRT och omedelbart — ingen uttoning.

     Det här är scenbytet, avsittningen, overlayen och lektionsstarten.
     I samtliga fall är bilden ändå på väg att bytas ut eller täckas, och
     en mjuk uttoning över ett scenbyte hade bara betytt att den gamla
     vyn levde vidare en halv sekund in i den nya. Efter det här anropet
     finns ingen begäran kvar som kan tändas senare. */
  function nollstall(st,orsak){
    if(!st)return false;
    const varAktiv=st.fas!=="vila";
    st.lage="ryttare";
    st.id=null;
    st.fas="vila";
    st.t=0;
    st.total=0;
    st.vikt=0;
    st.startVikt=0;
    st.orsak=orsak==null?null:String(orsak);
    return varAktiv;
  }

  function aktiv(st){ return !!st&&st.fas!=="vila"; }

  /* Vad kameran ska använda just nu. Ren avläsning — stegar ingenting,
     så den kan anropas var som helst utan att flytta övergången.

     `vikt` 0 = sadelvyn, 1 = feedbackvinkeln. Multiplikatorerna gäller
     bomkameran och är därför bara meningsfulla när vikten är över noll;
     vid vikt 0 lämnas de som neutrala så att en anropare som ändå läser
     dem inte får skräp. */
  function las(st){
    const v=st&&st.vikt>0?vinkel(st.id):null;
    if(!v)return {lage:"ryttare", id:null, vikt:0,
                  yaw:NEUTRAL.yaw, bak:NEUTRAL.bak, hojd:NEUTRAL.hojd,
                  fov:NEUTRAL.fov, blick:NEUTRAL.blick};
    return {lage:"feedback", id:st.id, vikt:st.vikt,
            yaw:v.yaw, bak:v.bak, hojd:v.hojd, fov:v.fov, blick:v.blick};
  }

  /* Stega övergången en bildruta och lämna tillbaka det upplösta läget.

     All tid som styr faserna kommer HÄRIFRÅN. Inget `Date.now()`, ingen
     `performance.now()`: samma dt-följd ger samma vy, vilket är vad
     "deterministisk återgång" betyder i praktiken och vad testet mäter. */
  function stega(st,dt){
    if(!st)return las(null);
    let d=typeof dt==="number"&&isFinite(dt)?dt:0;
    if(d<0)d=0; else if(d>DT_TAK)d=DT_TAK;

    if(st.fas!=="vila"){
      const v=vinkel(st.id);
      /* Vinkeln försvann under körning — bara möjligt om någon rör
         tabellen i efterhand. Då är sadeln rätt svar, direkt. */
      if(!v){ nollstall(st,"vinkel-borta"); return las(st); }

      st.t+=d;
      st.total+=d;

      /* Nödbromsen först, så att en trasig konfiguration inte kan hålla
         kvar bilden bara för att dess egna faser aldrig tar slut. */
      if(st.total>=MAX_TOTAL+MAX_UT){ nollstall(st,"tidstak"); return las(st); }
      if(st.total>=MAX_TOTAL&&st.fas!=="ut"){
        st.fas="ut"; st.t=0; st.startVikt=st.vikt;
      }

      if(st.fas==="in"){
        const p=v.in>0?st.t/v.in:1;
        st.vikt=st.startVikt+(1-st.startVikt)*mjuk(p);
        if(p>=1){ st.vikt=1; st.fas="hall"; st.t=0; }
      }else if(st.fas==="hall"){
        st.vikt=1;
        if(st.t>=v.hall){ st.fas="ut"; st.t=0; st.startVikt=1; }
      }
      if(st.fas==="ut"){
        const p=v.ut>0?st.t/v.ut:1;
        st.vikt=st.startVikt*(1-mjuk(p));
        /* Uttoningen når exakt noll, och DÄR nollställs allt. Ett
           "nästan noll" hade lämnat en vinkel registrerad som inte
           syns — ett stall-läge som senare kunde vakna. */
        if(p>=1)nollstall(st,"atergang");
      }
    }
    return las(st);
  }

  /* Ritten har EN kamera, alltså ett delat läge. Testerna skapar egna
     med `skapa()`; spelet använder den här. */
  const ritten=skapa();

  root.Kameralage={
    VINKLAR, GRANS, NEUTRAL, MAX_TOTAL,
    skapa, begar, slapp, nollstall, aktiv, las, stega,
    giltig, vinkel, vinkelnamn, validera,
    ritten,
  };
})(typeof globalThis!=="undefined"?globalThis:this);
