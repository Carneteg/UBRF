/* ══════════════════════════════════════════════════════════════════
   G02-B — RYTTARENS HJÄLPER SOM SEMANTIK (issue #83, punkt 1)

   Gate 01 gav ridningen fyra AXLAR: skänkel, styrning, tygel och sits.
   De är enhetens språk — vad ett tangenttryck eller ett spakutslag
   betyder — och de ska inte bytas ut. Det här lagret lägger ridningens
   språk ovanpå dem: skänkel, INNERTYGEL och YTTERTYGEL, säte/vikt, och
   halvhalt/parad som en EGEN signal.

   VARFÖR ÖVERSÄTTNING OCH INTE NYA AXLAR ─────────────────────────────

   En andra tygelaxel hade krävt nya kontroller på tangentbord, pekskärm
   och Roblox samtidigt, och pekskärmen har redan bara två fingrar att ge.
   Inner- och yttertygel härleds därför ur de två axlar spelaren REDAN
   har — och det är inte en gömd genväg, för spelaren styr dem faktiskt:

     · STYRAXELN säger hur mycket innertygeln BER om böjningen.
     · TYGELAXELN säger hur mycket kontakt ryttaren HÅLLER i svängen,
       och det är kontakten som blir yttertygelns stöd.

   Att svänga med släppt tygel ger alltså mycket innertygel och nästan
   inget yttertygelstöd — hästen faller in på inre skuldran och tappar
   rakriktningen. Att hålla kontakten genom svängen ger stöd, och
   svängen blir buren. Det är ridmässigt rätt, det är en riktig
   spelarhandling med de kontroller som finns, och det går att mäta.

   [ANTAGANDE — billigt att kullkasta] Att inner/yttertygel är en
   HÄRLEDNING och inte två egna axlar är ett designval, inte en
   verklighetsfråga. Vill produkten ha två riktiga tyglar är det en
   inputändring på tre ytor, inte en modelländring: fyll `innerTygel`
   och `ytterTygel` från var sin axel i stället, och allt nedanför
   fungerar oförändrat.

   PARADEN ÄR EN EGEN SIGNAL ──────────────────────────────────────────

   Förut fanns halvhalten bara som ett MÖNSTER: sits, skänkel och tygel
   som steg ihop och tygeln som gav efter. Tangenten E låtsades vara en
   ryttare genom att knuffa alla tre samtidigt (`hS`, `hK`, `hT` i
   stegaInput). Det fungerade, men det gick inte att läsa ut, inte att
   mäta och inte att lära ut: telemetrin såg tre hjälper röra sig, inte
   en parad.

   Nu är `parad` en egen kanal 0–1 hela vägen från tangenten till
   modellen. Mönsterläsningen finns kvar — den som rider halvhalten med
   riktiga hjälper ska fortfarande få den — men båda vägarna mynnar i
   SAMMA signal, och det är den signalen modellen och telemetrin läser.

   Modulen räknar ingen fysik och håller inget tillstånd. Den översätter
   en bildrutas hjälper till ridningens ord, och kan därför inte ändra
   känslan på egen hand. ── */

const HJALP_KANON = {
  /* Hur mycket av styrutslaget som läggs på innertygeln. Skalas med det
     som är kvar upp till full tygel, så innertygeln aldrig sprängs. */
  INNER_BER: 0.55,
  /* Hur mycket av styrutslaget som SLÄPPER yttertygeln. En ryttare som
     drar i innertygeln ger med automatik efter på den yttre — det är
     just det felet stödet nedan mäter. */
  YTTER_SLAPP: 0.35,
  /* Fullt styrutslag ur inputlagret. Talet ÄGS av den här kanonen och
     läses av src/game.js — det stod förut som en literal 0,72 i
     ridAvsiktTillHjalp() och behövs på båda ställena, vilket är en
     dublett för mycket.

     Att det behövs här är inte kosmetik: böjkravet måste vara 1 vid
     fullt utslag. Räknat mot 1,0 i stället når begäran aldrig över
     0,72, och stödets skala blir en tredjedel för trång — vilket är
     precis vad första mätningen 2026-09-05 visade (stöd 0,73 på lös
     tygel i full volt, alltså nästan ingen skillnad att rida fel på). */
  STYR_FULLT: 0.72,
  /* Hur mycket EXTRA kontakt en full böjning kräver av yttertygeln,
     utöver neutralläget. Yttertygeln ska bära böjningen, och ju mer
     innertygeln ber desto mer måste den yttre hålla emot. */
  STOD_KRAV: 0.30,
  /* Neutralläget på tygelaxeln, samma tal som K.TYGEL_NEUTRAL i
     modellen. Speglas här för att stödet ska gå att räkna utan
     modellen, och paritetsspecen provar att de två är lika. */
  TYGEL_NEUTRAL: 0.34,
  /* Under det här styrutslaget finns ingen böjning att stödja, och
     stödet är då per definition fullgott — rakt fram finns ingen
     inner- och yttersida. */
  BOJ_TROSKEL: 0.05,
  /* Paradens kvalitet: en halvhalt biter när hästen är framför skänkeln
     och i kontakt. Talen är vikter i en summa som ger 0–1. */
  PARAD_GOLV: 0.20, PARAD_DRIV: 0.50, PARAD_BAND: 0.40,
  /* Signalen räknas som given över den här nivån. Kanalen rampar, så
     tröskeln behövs för att flanken ska gå att läsa. */
  PARAD_TROSKEL: 0.05,
};

/* Hjälpernas semantiska fältnamn — kontraktet telemetrin publicerar och
   Roblox-sidan ska fylla. Listan läses av exportera-ridkanon.mjs, så den
   kan inte glida ur synk med det som faktiskt returneras. */
const HJALP_FALT = ["skankel", "tygel", "sits", "styrning",
  "innerTygel", "ytterTygel", "ytterstod", "bojSida", "vikt", "parad"];

/* Fält som är HÄRLEDDA ur axlarna ovan, inte egna spelarkontroller.
   Ärlig märkning av samma slag som telemetrins `_harledda`. */
const HJALP_HARLEDDA = ["innerTygel", "ytterTygel", "ytterstod", "vikt"];

/* En bildrutas hjälper → ridningens ord. `a` är stegaInput()-utdata
   (eller vilken som helst hjälpuppsättning stepRide tar). */
function hjalpSemantik(a) {
  const H = HJALP_KANON;
  const kl = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
  const t = kl(a.tygel || 0, 0, 1);
  const sb = kl(a.styrning || 0, -1, 1), s = Math.abs(sb);
  const innerTygel = kl(t + s * H.INNER_BER * (1 - t), 0, 1);
  const ytterTygel = kl(t - s * H.YTTER_SLAPP * t, 0, 1);
  /* YTTERTYGELSTÖDET: hur stor del av den begärda böjningen yttertygeln
     kan bära.

       `ber`   hur mycket böjning innertygeln ber om, 0–1 av fullt utslag
       `behov` den kontakt yttertygeln BEHÖVER för att bära den böjningen
       `bar`   hur stor del av behovet den faktiskt har

     Rakt fram är `ber` noll, och då är stödet 1 oavsett tygel — på ett
     rakt spår finns ingen inner- och yttersida att göra fel med, och
     modellen får ingenting att straffa. Formen 1 − ber·(1 − bar) faller
     alltså ur sig själv i rakt läge i stället för att behöva en gräns
     som stänger av termen, och det är avsikten: en gräns som stänger av
     en term är också en gräns som kan råka stänga av den för tidigt. */
  const ber = kl(s / H.STYR_FULLT, 0, 1);
  const behov = H.TYGEL_NEUTRAL + H.STOD_KRAV * ber;
  const bar = kl(ytterTygel / behov, 0, 1);
  const ytterstod = 1 - ber * (1 - bar);
  return {
    skankel: a.skankel || 0,
    tygel: t,
    sits: a.sits || 0,
    styrning: sb,
    innerTygel, ytterTygel, ytterstod,
    bojSida: s > H.BOJ_TROSKEL ? (sb > 0 ? 1 : -1) : 0,
    /* Vikten följer bågen. Det finns ingen egen viktaxel — sitsen säger
       hur djupt ryttaren sitter, bågen åt vilket håll vikten går. */
    vikt: (s > H.BOJ_TROSKEL ? (sb > 0 ? 1 : -1) : 0) * Math.min(1, s * 1.4),
    parad: kl(a.parad || 0, 0, 1),
  };
}

/* Paradens kvalitet i det ögonblick den ges. En halvhalt är inte en
   knapp utan en samverkan: hästen ska vara framför skänkeln och handen
   i kontaktbandet. Ger 0–1 och används både som cue-styrka och som
   samlingens utdelning. */
function paradKvalitet(a) {
  const kl = (v, lo, hi) => v < lo ? lo : v > hi ? hi : v;
  const H = HJALP_KANON;
  /* Kontaktbandet och skänkeltröskeln ÄGS av modellens K. Läses där,
     skrivs inte av här — två uppsättningar av samma tal är exakt den
     dubblett paritetsregeln finns för. Fallbacken gör modulen körbar
     ensam (t.ex. i en enhetsmätning) och är märkt som just det. */
  const KK = (typeof K !== "undefined") ? K : null;
  const trosk = KK ? KK.SKANKEL_TROSKEL : 0.28;
  const bmin = KK ? KK.TYGEL_BAND_MIN : 0.22, bmax = KK ? KK.TYGEL_BAND_MAX : 0.58;
  const driv = kl(((a.skankel || 0) - trosk) / 0.30, 0, 1);
  const mitt = (bmin + bmax) / 2, halv = (bmax - bmin) / 2;
  const iband = kl(1 - Math.abs((a.tygel || 0) - mitt) / (halv * 1.6), 0, 1);
  return kl(H.PARAD_GOLV + H.PARAD_DRIV * driv + H.PARAD_BAND * iband, 0, 1);
}
