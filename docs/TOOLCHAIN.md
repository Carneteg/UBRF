# UBRF — aktiv verktygskedja

Detta dokument beskriver vilka externa utvecklingsverktyg som är tillgängliga i UBRF-projektets arbetssetup. Det ändrar inte produktkanon eller leveransauktoritet i `CLAUDE.md` och `docs/DELIVERY-PROTOCOL.md`.

## Aktiva verktyg

- **GitHub** — source of truth för kod, dokumentation, branches, PR:er, diffar och review-evidens.
- **Supabase** — datalager/manifest och backend där projektets arkitektur kräver det.
- **Claude** — Lead Implementation Engineer / Builder enligt `CLAUDE.md`.
- **ChatGPT** — Senior Game Director / Game Systems Architect / Independent Reviewer enligt `CLAUDE.md`.
- **Replit** — aktiv utvecklings- och testmiljö för snabb körning, webbprototyper, reproduktion av problem, miljöverifiering och isolerade experiment.
- **Vercel** — tillgängligt för webbdeploy, preview och relevant frontend-/runtime-verifiering.
- **Higgsfield** — tillgängligt för relevanta visuella/generativa assets när sådant uttryckligen behövs.

## Replit-regel

Replit är ett **aktivt verktyg i verktygskedjan**, inte en alternativ source of truth.

Det får användas för att:

- köra HTML/webbversionen,
- reproducera och felsöka webbruntime-problem,
- snabbt testa isolerade implementationer eller verktyg,
- verifiera responsivitet och enklare interaktionsflöden,
- skapa tillfälliga testmiljöer när det ökar utvecklingshastigheten.

Det får inte användas för att:

- ersätta GitHub som kod- eller dokumentationssanning,
- kringgå feature branch + PR + review,
- deklarera Roblox Studio-specifik fidelity eller game feel som PASS,
- skapa en separat konkurrerande implementation som inte återförs till projektets riktiga kodbas.

Resultat från Replit som ska påverka produkten ska återföras till GitHub och följa samma acceptance-/review-process som övriga ändringar.
