/* ══════════════════════════════════════════════════════════════════
   SYNKEN — molnlagring av ryttaren, hästminnet och passen.

   Spelet är och förblir local-first. localStorage är sanningen, allt
   fungerar utan nät, och den byggda filen har fortfarande inga externa
   beroenden: det här pratar med Supabase över vanliga fetch-anrop mot
   REST- och auth-slutpunkterna i stället för att dra in supabase-js
   från en CDN. Ett bibliotek till skulle bryta regeln om en enda fil.

   Vad synken är till för: kunna rida på mobilen i stallet och fortsätta
   på datorn hemma, och kunna se sin utveckling över fler pass än den
   kväll man råkar sitta vid. Hästminnet är eget per spelare — var och
   en har sin egen relation till varje häst.

   Vad den INTE är: ett krav. Utan inloggning, utan nät eller med en
   trasig server spelar man precis som förut. Varje anrop här får
   misslyckas tyst, och gör det.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

const SYNK={
  url:"https://tdznhaybxmekznasxtts.supabase.co",
  nyckel:"sb_publishable_QZAed4Eo9rxoEgH4S7fUug_hgGQgL3e",  // publicerbar nyckel; RLS skyddar raderna
  session:null,                 // {access_token, refresh_token, user:{id}}
  status:"av",                  // av | ute | inne | jobbar | fel
  info:"",
  lage:"ny",                    // ny | in — vilken ruta som visas
  epost:"",                     // sparas mellan omritningar, aldrig lösenordet
};
const SYNK_SESSION="ubrf-synk-session-v1";

function synkPa(){ return !!(SYNK.url&&SYNK.nyckel); }
function synkInne(){ return !!(SYNK.session&&SYNK.session.access_token); }

function synkLaddaSession(){
  if(!synkPa())return;
  try{
    const s=localStorage.getItem(SYNK_SESSION);
    if(s){SYNK.session=JSON.parse(s); SYNK.status="inne";}
    else SYNK.status="ute";
  }catch(_){ SYNK.status="ute"; }
}
function synkSparaSession(s){
  SYNK.session=s;
  try{
    if(s)localStorage.setItem(SYNK_SESSION,JSON.stringify(s));
    else localStorage.removeItem(SYNK_SESSION);
  }catch(_){}
}

/* ── Anropen ──────────────────────────────────────────────────────
   Ett tunt lager runt fetch. Vid 401 görs ett försök att förnya
   token med refresh_token; misslyckas det loggas man ut lokalt och
   spelet fortsätter som om molnet aldrig funnits. */
async function synkFetch(vag,opt,utanToken){
  const o=opt||{};
  const huvud={apikey:SYNK.nyckel, "Content-Type":"application/json", ...(o.headers||{})};
  if(!utanToken&&synkInne())huvud.Authorization="Bearer "+SYNK.session.access_token;
  const svar=await fetch(SYNK.url+vag,{...o,headers:huvud});
  if(svar.status===401&&!utanToken&&SYNK.session&&SYNK.session.refresh_token){
    const ny=await synkFornya();
    if(ny)return synkFetch(vag,opt,utanToken);
  }
  return svar;
}
async function synkFornya(){
  try{
    const svar=await synkFetch("/auth/v1/token?grant_type=refresh_token",{
      method:"POST", body:JSON.stringify({refresh_token:SYNK.session.refresh_token})},true);
    if(!svar.ok){synkSparaSession(null);SYNK.status="ute";return false;}
    synkSparaSession(await svar.json());
    return true;
  }catch(_){ return false; }
}

/* ── Konto ────────────────────────────────────────────────────────
   E-post och lösenord. Är e-postbekräftelse påslagen i projektet får
   man ingen session direkt — då säger vi det rakt ut i stället för att
   låtsas att något gick fel. */
async function synkRegistrera(namn,epost,losen){
  SYNK.status="jobbar"; SYNK.info="Skapar ryttaren…";
  try{
    const svar=await synkFetch("/auth/v1/signup",{method:"POST",
      body:JSON.stringify({email:epost,password:losen,data:{namn}})},true);
    const d=await svar.json();
    if(!svar.ok){SYNK.status="fel";SYNK.info=d.msg||d.error_description||"Kunde inte skapa kontot.";return false;}
    if(!d.access_token){
      SYNK.status="ute";
      SYNK.info="Kontot är skapat. Bekräfta e-posten och logga sedan in.";
      return false;
    }
    synkSparaSession(d); SYNK.status="inne";
    await synkTryck();                    // första raden fylls med det man redan har
    SYNK.info="Inloggad som "+namn+".";
    return true;
  }catch(e){ SYNK.status="fel"; SYNK.info="Ingen kontakt med servern."; return false; }
}
async function synkLoggaIn(epost,losen){
  SYNK.status="jobbar"; SYNK.info="Loggar in…";
  try{
    const svar=await synkFetch("/auth/v1/token?grant_type=password",{method:"POST",
      body:JSON.stringify({email:epost,password:losen})},true);
    const d=await svar.json();
    if(!svar.ok||!d.access_token){
      SYNK.status="ute"; SYNK.info=d.error_description||d.msg||"Fel e-post eller lösenord.";
      return false;
    }
    synkSparaSession(d); SYNK.status="inne";
    await synkDra();
    return true;
  }catch(e){ SYNK.status="fel"; SYNK.info="Ingen kontakt med servern."; return false; }
}
function synkLoggaUt(){
  synkSparaSession(null); SYNK.status="ute";
  SYNK.info="Utloggad. Framstegen ligger kvar i den här webbläsaren.";
}

/* ── Ryttaren, ut och in ──────────────────────────────────────────
   Sammanslagningen är medvetet enkel: hela profilen är en enhet och
   den nyaste vinner. En familj rider inte samma pass samtidigt på två
   enheter, och en riktig sammanslagning fält för fält skulle kosta mer
   i förvirring än den vinner i noggrannhet. */
function synkProfilRad(){
  return {
    namn:(typeof jagNamn==="function"?jagNamn():"Ryttare"),
    grupp:SPAR.grupp, poang:SPAR.poang, pass:SPAR.pass,
    fardighet:(typeof fard==="function")?fard():(SPAR.fardighet||{}),
    /* Utseendet och egenskaperna följer med som ett stycke. Se
       0002_ryttarens_jag.sql för varför det är jsonb och inte kolumner. */
    jag:(typeof jag==="function")?jag():(SPAR.jag||{}),
    uppdaterad:SPAR.uppdaterad||new Date().toISOString(),
  };
}
function synkHastRader(id){
  return Object.entries(SPAR.fortroende||{}).map(([hast_id,m])=>({
    ryttare_id:id, hast_id,
    rang:m.rang??0.45, pass:m.pass??0,
    sista_pass_nr:m.sistaPassNr??null, sista_form:m.sistaForm??null,
    rehab:!!m.rehab, skada:m.skada||null,
    uppdaterad:new Date().toISOString(),
  }));
}
async function synkTryck(){
  if(!synkInne())return false;
  const id=SYNK.session.user&&SYNK.session.user.id;
  if(!id)return false;
  try{
    await synkFetch("/rest/v1/ryttare?on_conflict=id",{method:"POST",
      headers:{Prefer:"resolution=merge-duplicates,return=minimal"},
      body:JSON.stringify([{id,...synkProfilRad()}])});
    const rader=synkHastRader(id);
    if(rader.length)
      await synkFetch("/rest/v1/hastminne?on_conflict=ryttare_id,hast_id",{method:"POST",
        headers:{Prefer:"resolution=merge-duplicates,return=minimal"},
        body:JSON.stringify(rader)});
    SYNK.info="Sparat i molnet.";
    return true;
  }catch(_){ SYNK.info="Kunde inte spara — framstegen ligger kvar lokalt."; return false; }
}
async function synkDra(){
  if(!synkInne())return false;
  const id=SYNK.session.user&&SYNK.session.user.id;
  if(!id)return false;
  try{
    const r=await synkFetch("/rest/v1/ryttare?select=*&id=eq."+id);
    const rad=(await r.json())[0];
    if(!rad){ await synkTryck(); return true; }
    const lokalT=Date.parse(SPAR.uppdaterad||0)||0;
    const synkT=Date.parse(rad.uppdaterad||0)||0;
    if(synkT<=lokalT){ await synkTryck(); SYNK.info="Den här enheten var nyast — molnet uppdaterat."; return true; }

    SPAR.grupp=rad.grupp; SPAR.poang=rad.poang; SPAR.pass=rad.pass;
    if(rad.fardighet)SPAR.fardighet={...(SPAR.fardighet||{}),...rad.fardighet};
    /* Ryttaren du skapat. Bara om molnet faktiskt bär en — en tom rad
       ska inte radera utseendet på den här enheten. */
    if(rad.jag&&rad.jag.skapad){
      SPAR.jag={...(SPAR.jag||{}),...rad.jag};
      if(typeof jagBygg==="function")jagBygg();
    }
    const h=await synkFetch("/rest/v1/hastminne?select=*&ryttare_id=eq."+id);
    const rader=await h.json();
    if(Array.isArray(rader)){
      SPAR.fortroende={};
      for(const m of rader)SPAR.fortroende[m.hast_id]={
        rang:m.rang, pass:m.pass,
        sistaPassNr:m.sista_pass_nr??undefined, sistaForm:m.sista_form??undefined,
        rehab:!!m.rehab, ...(m.skada?{skada:m.skada}:{})};
    }
    SPAR.uppdaterad=rad.uppdaterad;
    G.grupp=SPAR.grupp;
    try{localStorage.setItem(SPAR_NYCKEL,JSON.stringify(SPAR));}catch(_){}
    SYNK.info="Hämtat från molnet.";
    return true;
  }catch(_){ SYNK.info="Ingen kontakt — spelar vidare lokalt."; return false; }
}

/* ── Passet ───────────────────────────────────────────────────────
   En rad per ridet pass, med det efter-passet räknar fram. Poängen är
   att utvecklingen ska gå att följa över fler pass än den kväll man
   råkar sitta vid datorn. */
async function synkSparaPass(dom){
  if(!synkInne()||typeof PASS==="undefined"||!PASS.klart)return false;
  const id=SYNK.session.user&&SYNK.session.user.id;
  if(!id)return false;
  const P=G.passRes||{};
  try{
    await synkFetch("/rest/v1/pass",{method:"POST",
      headers:{Prefer:"return=minimal"},
      body:JSON.stringify([{
        ryttare_id:id, hast_id:PASS.hastId, grupp:PASS.grupp, plats:G.plats||null,
        snitt:P.snitt??null, fel:dom?dom.totalfel:null, utesluten:!!(dom&&dom.utesluten),
        hamtningar:PASS.hamtningar, tid_ute:PASS.tidUte,
        mjukhet:PASS.mjukhetTid>0?PASS.mjukhetSum/PASS.mjukhetTid:null,
        spanning_fore:PASS.spanningFore, spanning_slut:PASS.spanningSlut,
        losgjord_fore:PASS.losgjordFore, losgjord_slut:PASS.losgjordSlut,
        fard_fore:PASS.fardFore, fard_efter:PASS.fardEfter,
        rang_fore:P.rangFore??null, rang_efter:P.rangEfter??null,
      }])});
    return true;
  }catch(_){ return false; }
}

/* ── Rutan i menyn ────────────────────────────────────────────────
   Ett namn, en e-post och ett lösenord. Inte mer — det här är ett
   familjeprojekt, inte en tjänst. */
function synkPanelHTML(){
  if(!synkPa())return "";
  if(synkInne()){
    const e=(SYNK.session.user&&SYNK.session.user.email)||"";
    return `<div class="note" id="synkRuta" style="font-size:13px">
      <b class="gold">Molnet är på.</b> Inloggad som ${e}.
      Framstegen följer med till mobilen och tillbaka.
      ${SYNK.info?`<br><span class="dim">${SYNK.info}</span>`:""}
      <div class="btnrow" style="margin-top:8px">
        <button class="btn ghost" id="bSynkDra" style="padding:6px 12px;font-size:12px">Hämta senaste</button>
        <button class="btn ghost" id="bSynkUt" style="padding:6px 12px;font-size:12px">Logga ut</button>
      </div></div>`;
  }
  const ny=SYNK.lage!=="in";
  const namn=(typeof jagNamn==="function")?jagNamn():"";
  return `<div class="note" id="synkRuta" style="font-size:13px">
    <b class="gold">${ny?"Skapa ett konto":"Logga in"}</b> — frivilligt.
    Med konto följer framstegen med mellan datorn och mobilen. Utan konto
    sparas allt i den här webbläsaren, precis som förut.
    <div class="synkFalt">
      ${ny?`<input id="synkNamn" placeholder="Ditt namn" maxlength="18"
        value="${namn.replace(/"/g,"&quot;")}">`:""}
      <input id="synkEpost" placeholder="E-post" type="email" autocomplete="email"
        value="${(SYNK.epost||"").replace(/"/g,"&quot;")}">
      <input id="synkLosen" placeholder="Lösenord${ny?" (minst 6 tecken)":""}"
        type="password" autocomplete="${ny?"new-password":"current-password"}">
    </div>
    ${SYNK.info?`<div class="synkBesked ${SYNK.status==="fel"?"bad":""}">${SYNK.info}</div>`:""}
    <div class="btnrow" style="margin-top:8px">
      <button class="btn" id="${ny?"bSynkNy":"bSynkIn"}" style="padding:7px 16px;font-size:13px"
        ${SYNK.status==="jobbar"?"disabled":""}>${ny?"Skapa konto":"Logga in"}</button>
      <button class="btn ghost" id="bSynkVaxla" style="padding:6px 12px;font-size:12px">
        ${ny?"Jag har redan ett konto":"Skapa ett nytt konto i stället"}</button>
    </div></div>`;
}

/* Kontrollerna görs här och inte på servern först. Ett fel som går att
   se innan anropet ska sägas innan anropet — annars ser det ut som att
   nätet strulade när det egentligen var ett tomt fält. */
function synkGranska(ny,namn,epost,losen){
  if(ny&&!namn)                       return "Skriv ditt namn först.";
  if(!epost)                          return "Skriv din e-postadress.";
  if(!/^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(epost))
                                      return "Det där ser inte ut som en e-postadress.";
  if(!losen)                          return "Skriv ett lösenord.";
  if(ny&&losen.length<6)              return "Lösenordet behöver vara minst sex tecken.";
  return "";
}
function kopplaSynkPanel(){
  if(!synkPa())return;
  const om=()=>{ if(typeof visaMeny==="function"&&G.scen==="meny")visaMeny(); };
  const v=id=>{const e=document.getElementById(id);return e?e.value.trim():"";};
  const b=(id,f)=>{const e=document.getElementById(id);if(e)e.onclick=f;};
  const ny=SYNK.lage!=="in";

  const kor=async()=>{
    const namn=v("synkNamn"), epost=v("synkEpost"), losen=v("synkLosen");
    const fel=synkGranska(ny,namn,epost,losen);
    SYNK.epost=epost;
    if(fel){ SYNK.status="fel"; SYNK.info=fel; om(); return; }
    if(ny)await synkRegistrera(namn||"Ryttare",epost,losen);
    else   await synkLoggaIn(epost,losen);
    om();
  };
  b("bSynkNy",kor); b("bSynkIn",kor);
  b("bSynkVaxla",()=>{ SYNK.lage=ny?"in":"ny"; SYNK.info=""; SYNK.status="ute"; om(); });
  b("bSynkDra", async()=>{ await synkDra(); om(); });
  b("bSynkUt",  ()=>{ synkLoggaUt(); om(); });

  /* Enter i lösenordsfältet gör det knappen gör. */
  const l=document.getElementById("synkLosen");
  if(l)l.onkeydown=e=>{ if(e.key==="Enter"){e.preventDefault();kor();} };
}

/* Sparning sker ofta — varje färdighetssteg och varje syssla. Trycket
   mot molnet läggs därför på en fördröjning, så att ett pass blir några
   anrop och inte hundra. */
let _synkTimer=0;
function synkKnuffa(){
  if(!synkInne())return;
  clearTimeout(_synkTimer);
  _synkTimer=setTimeout(()=>{synkTryck();},4000);
}

synkLaddaSession();
