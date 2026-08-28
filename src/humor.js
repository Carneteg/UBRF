/* ══════════════════════════════════════════════════════════════════
   HUMÖRET OCH LYDNADEN — hästen som en egen vilja.

   Grundproblemet den här filen löser: en häst som inte driver kan inte
   visa något humör. Om tempot ligger still av sig självt spelar det
   ingen roll hur hon mår — resultatet blir detsamma. Därför hänger
   avdriften och humöret ihop; det ena syns bara genom det andra.

   Tre lager, i tur och ordning:

     lydnad   en egenskap. Hur villigt hon svarar på en hjälp. Ligger
              fast för hästen, som känslighet och tyngd.
     humor    ett tillstånd för dagen. Sätts när du hämtar henne, av
              hur du skött henne, vad ni har ihop, vädret och en nypa
              slump som är samma hela dagen.
     avdrift  det du känner i sadeln. Tempot vandrar, och hur mycket
              beror på lydnaden och humöret.

   Poängen är att ridning ska vara att korrigera. En häst som ligger
   still av sig själv gör att stillasittande blir optimalt, och då lär
   man sig ingenting.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* ── Lydnad ───────────────────────────────────────────────────────
   Hur villigt hästen svarar. Härleds ur egenskaper hon redan har, så
   att varje häst får ett eget värde utan att datan skrivs om — men kan
   sättas explicit i data.js där beskrivningen motiverar något annat. */
function hastLydnad(h){
  if(typeof h.lydnad==="number")return clamp(h.lydnad,0,1);
  return clamp(0.30+0.42*(h.utbildning??0.6)+0.22*(h.forlatande??0.7)
    -0.28*(h.skygghet??0.15), 0.12, 0.96);
}

/* Hur mycket hon vandrar av sig själv, i m/s. En lydig och nöjd häst
   ligger nästan still; en olydig och sur vandrar så att du måste rida
   varje steg. Skygga hästar rycker till i stället för att glida. */
function hastAvdrift(h,humor,halla){
  const lyd=hastLydnad(h);
  /* Ryttarens förmåga att hålla ihop henne dämpar avdriften, men tar
     aldrig bort den. En erfaren ryttare på en sur häst rider fortfarande
     mer än en erfaren ryttare på en nöjd — hästen försvinner inte. */
  const d=1-0.45*clamp(halla||0,0,1);
  return {
    glid: (0.22+0.55*(1-lyd)+0.40*(1-humor))*d,   // långsam vandring
    ryck: (0.10+0.85*(h.skygghet??0.15)*(1-humor))*(1-0.55*clamp(halla||0,0,1)),
    tröghet: 1+0.85*(1-lyd),                      // svarar segare på skänkel
  };
}

/* ── Humöret ──────────────────────────────────────────────────────
   Sätts en gång när du hämtar hästen, och ligger sedan fast under
   passet. Det ska gå att påverka — men inte mitt i ritten, för då blir
   det en mätare att spela mot i stället för en häst att lära känna. */
function dagensHumor(hastId){
  const h=HORSES[hastId]; if(!h)return 0.6;
  const m=hastminne(hastId);

  /* Slumpen är samma hela dagen för samma häst: hon är inte på ett nytt
     humör varje gång du klickar. Samma frö som dagens händelser. */
  let fro=(G.seed||1)*7919+hastId.length*131;
  for(let i=0;i<hastId.length;i++)fro=(fro*31+hastId.charCodeAt(i))%2147483647;
  const slump=((fro*16807)%2147483647)/2147483647;

  const skotsel=clamp(G.dagsform??0.7,0,1);
  const relation=clamp(m.rang??0.45,0,1);
  const ro=clamp(G.stallro??0.9,0,1);
  const vader=(G.vader&&G.vader.typ==="regn")?-0.10:(G.vader&&G.vader.typ==="mulet")?-0.03:0;

  /* Känsliga hästar svänger mer, förlåtande hästar mindre. */
  const svang=0.45+0.55*(h.kanslighet??0.4)-0.30*(h.forlatande??0.7);
  const bas=0.30+0.34*skotsel+0.22*relation+0.10*ro+vader;
  return clamp(bas+(slump-0.5)*svang*0.55, 0.05, 1);
}

/* Vad ridläraren säger om humöret när du hämtar henne. Konkret, inte
   en siffra — spelaren ska lära sig läsa hästen, inte en mätare. */
function humorText(hastId,humor){
  const h=HORSES[hastId]; if(!h)return "";
  const namn=h.namn;
  if(humor>0.78)return `${namn} möter dig i dörren. Hon är med dig idag.`;
  if(humor>0.60)return `${namn} är lugn och lyssnar.`;
  if(humor>0.42)return `${namn} är lite trög idag — du får be om det två gånger.`;
  if(humor>0.25)return `${namn} är spänd. Ta det lugnt i början och vinn henne.`;
  return `${namn} är inte med på noterna idag. Rid henne försiktigt.`;
}
