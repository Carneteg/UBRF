/* P0 QA: observera den verkliga 2D-renderaren, inte en fast väntetid.
   Funktionen serialiseras av Playwright och körs i sidans main world.
   Den läser endast speltillstånd; den skapar aldrig en transform. */
export function p0KartaRedo(expected) {
  if (typeof G === 'undefined' || typeof V2T === 'undefined' ||
      typeof cv === 'undefined' || !cv) return false;
  const t = V2T, r = cv.getBoundingClientRect();
  return G.scen === expected && G.vy === '2d' && t.scen === expected &&
    Number.isFinite(t.ox) && Number.isFinite(t.oy) &&
    Number.isFinite(t.s) && t.s > 0 &&
    Number.isFinite(t.hojd) && t.hojd > 0 &&
    cv.width > 0 && cv.height > 0 && r.width > 0 && r.height > 0;
}

export async function invantaP0Karta(page, expected, timeout = 10000) {
  const handle = await page.waitForFunction(p0KartaRedo, expected,
    { polling: 'raf', timeout });
  await handle.dispose();
}
