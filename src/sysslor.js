/* ═══════════════════════════════════════════════════════════════
   STALLET — hästbyte hos ridläraren och dagens schema.

   PRODUKTBESLUT 2026-10-04: stallsysslorna (mocka, fodra, spola,
   boxmenyn) och sadelkammarpusslet är borttagna. Stallet sköter boxen
   och utrustningen; spelaren väljer «Rida nu». Kvar är det som inte är
   skötsel: att byta häst och att läsa dagens schema.
   ═══════════════════════════════════════════════════════════════ */
"use strict";

/* ── Byt häst hos ridläraren ──────────────────────────────────── */
/* PO-order 2026-09-06: en tydlig men ENKEL väg att byta häst före
   ridmomentet. Kort lista, ett klick, ingen lång text — och hela
   vägledningskedjan följer med genom sattAktivHast(). */
function visaHastbyte(){
  const nu=G.hastId?HORSES[G.hastId]:null;
  const lista=valbaraHastar();
  const knapp=id=>{
    const h=HORSES[id];
    return `<button class="btn ghost hb-val" data-id="${id}"
      style="justify-content:space-between;width:100%${id===G.hastId?";outline:1px solid var(--gold)":""}">
      <span>${h.namn}</span>
      <span class="dim" style="font-size:12px">${h.typ==="ponny"?"ponny":"häst"}${id===G.hastId?" · din i dag":""}</span></button>`;
  };
  overlay(true,`
  <span class="lbl">Ridläraren · stallgången</span>
  <h1 style="margin-top:6px">Byt häst</h1>
  <p class="dim" style="font-size:13.5px;margin-top:2px">${nu
    ? `Du har ${nu.namn} i dag. Byter du får du börja om med boxen, sadeln och skötseln.`
    : "Välj hästen du ska rida i dag."}</p>
  <div style="display:grid;gap:8px;margin-top:14px;max-height:46vh;overflow:auto">
    ${lista.map(knapp).join("")}
  </div>
  <div class="btnrow"><button class="btn" id="bHbStang">Behåll ${nu?nu.namn:"—"}</button></div>`);
  for(const b of document.querySelectorAll(".hb-val"))
    b.onclick=()=>{
      const id=b.dataset.id;
      if(id!==G.hastId){
        sattAktivHast(id);
        saga(`${HORSES[id].namn} är din i dag. ${hastAnvisning().hur}`,4);
      }
      overlay(false);
    };
  document.getElementById("bHbStang").onclick=()=>overlay(false);
}

/* ── Whiteboarden — dagens schema som checklista ─────────────── */
function visaSchema(){
  const v=G.vader||{typ:"sol",temp:12,tacke:false};
  const vtxt={sol:"Sol",mulet:"Mulet",regn:"Regn"}[v.typ]+` · ${v.temp} °C`
    +(v.tacke?" — hästarna går med täcke":"");
  const hast=G.hastId?HORSES[G.hastId].namn:"—";
  const rad=(klar,txt)=>`<li style="display:flex;gap:10px;align-items:baseline">
    <span class="${klar?'grn':'dim'}" style="font-family:'IBM Plex Mono',monospace">${klar?"✓":"○"}</span>
    <span class="${klar?'':'dim'}">${txt}</span></li>`;
  overlay(true,`
  <span class="lbl">Whiteboarden i servicedelen · dagens schema</span>
  <h1 style="margin-top:8px">${vtxt}</h1>
  <p class="dim" style="font-size:13.5px">Din häst i dag: <b style="color:var(--ink)">${hast}</b>.
  Schemat gäller tills lektionen börjar — ridläraren bockar av resten.</p>
  <ul style="list-style:none;padding:0;margin:14px 0;display:grid;gap:9px;font-size:14.5px">
    ${rad(!!G.hastId,"Din häst i dag — stallet gör henne redo")}
    ${rad(!!G.skotselRes,"Rida nu — hon står i ridhuset")}
    ${rad(false,"Lektion — sitt upp vid sargporten i ridhuset")}
  </ul>
  ${(()=>{
    const hand=(typeof dagensHandelser==="function")?dagensHandelser():{};
    const rader=Object.entries(hand)
      .map(([id,e])=>`<li><b style="color:var(--ink)">${HORSES[id]?HORSES[id].namn:id}</b> — ${e.text}</li>`);
    return rader.length?`<div class="note" style="font-size:13px">
      <b class="lbl" style="display:block;margin-bottom:4px;color:var(--gold-2)">Går ej i dag</b>
      <ul style="list-style:none;padding:0;margin:0;display:grid;gap:4px">${rader.join("")}</ul></div>`:"";
  })()}
  <div class="btnrow"><button class="btn" id="bSchemaOk">Tillbaka till stallet</button></div>`);
  document.getElementById("bSchemaOk").onclick=()=>overlay(false);
}
