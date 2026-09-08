/* One-shot inputimpulser för handlingar som inte får tappas mellan bildrutor. */
(function(root){
  "use strict";
  const pending=Object.create(null);

  function press(code,scope){
    pending[code]={scope:scope==null?null:String(scope)};
  }

  function consume(code,scope){
    const hit=pending[code];
    if(!hit)return false;
    delete pending[code];
    const expected=scope==null?null:String(scope);
    return hit.scope===expected;
  }

  function clear(code){ delete pending[code]; }
  function clearAll(){ for(const code of Object.keys(pending))delete pending[code]; }
  function has(code){ return !!pending[code]; }

  root.InputImpulse={press,consume,clear,clearAll,has};
})(typeof globalThis!=="undefined"?globalThis:this);
