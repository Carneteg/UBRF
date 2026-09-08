from pathlib import Path

def change(path,pairs):
    p=Path(path);s=p.read_text(encoding='utf-8')
    for old,new in pairs:
        if s.count(old)!=1:
            raise SystemExit(f'Expected exactly one match in {path}: {old[:80]!r}; found {s.count(old)}')
        s=s.replace(old,new,1)
    p.write_text(s,encoding='utf-8')

change('index.html',[(
    '<script src="src/world.js"></script>',
    '<script src="src/input-impulse.js"></script>\n<script src="src/world.js"></script>')])
change('src/game.js',[(
    '  if(e.repeat)return; IN.ned[e.code]=true;',
    '''  if(e.repeat)return;
  const wasDown=!!IN.ned[e.code];
  IN.ned[e.code]=true;
  /* E är en engångshandling i gångläget. Bevara den tills spelet samplar,
     men skapa aldrig en impuls från autorepeat, en overlay eller ridning. */
  if(e.code==="KeyE"&&!wasDown&&
     (G.scen==="gard"||G.scen==="stallinne"||G.scen==="ridhusinne")&&
     !overlayUppe())InputImpulse.press("KeyE",G.scen);''')])
change('src/world.js',[(
    '''  const e=!!IN.ned.KeyE;
  if(e&&!VD.ePrev&&bast&&!overlayUppe()) bast.gor();
  VD.ePrev=e;''',
    '''  /* Konsumera även om inget giltigt mål finns: ett gammalt tryck får
     aldrig aktivera en dörr som spelaren närmar sig senare. */
  const e=InputImpulse.consume("KeyE",G.scen);
  if(e&&bast&&!overlayUppe()) bast.gor();
  VD.ePrev=!!IN.ned.KeyE;'''),(
    '''function gaTill(scen,spawn){
  G.scen=scen;''',
    '''function gaTill(scen,spawn){
  InputImpulse.clear("KeyE");
  G.scen=scen;'''),(
    '''function startaVandring(){
  if(typeof ridSittAv''',
    '''function startaVandring(){
  InputImpulse.clear("KeyE");
  if(typeof ridSittAv''')])
change('src/scenes.js',[(
    'function overlay(on,html){ov.classList.toggle("hide",!on);if(html!==undefined)sheet.innerHTML=html;}',
    'function overlay(on,html){if(on)InputImpulse.clear("KeyE");ov.classList.toggle("hide",!on);if(html!==undefined)sheet.innerHTML=html;}')])
change('.github/workflows/p0-input-impulse.yml',[(
    '      - run: node tools/input-impulse-test.mjs',
    '      - run: node tools/input-impulse-test.mjs\n      - run: node tools/input-interaction-test.mjs\n      - run: node tools/control-feel-test.mjs')])
