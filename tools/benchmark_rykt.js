const moment_fs = require('fs').readFileSync('src/moment.js', 'utf8');

const RYKTREDSKAP = [
  {id: 'skrapa', namn: 'Gummiskrapa', kort: 'lossa smuts', farg: '#D0655A'},
  {id: 'kardborste', namn: 'Kardborste', kort: 'ta bort', farg: '#D6AE3C'},
  {id: 'mjuk', namn: 'Mjuk borste', kort: 'hela hästen', farg: '#A6ABB3'}
];

const clamp = (v, min, max) => Math.max(min, Math.min(max, v));

let code = moment_fs;
code = code.replace(/function momentSk.*/, 'function momentSk(W) { return clamp(W/408, 0.68, 1.30); }');

eval(code);

function ryktChippOld(W,H){
  const b=W*0.29, h=H*0.085, y=H-h-H*0.035;
  return RYKTREDSKAP.map((r,i)=>({r,i,x:W*0.025+i*(b+W*0.012),y,b,h}));
}

let _cachedW = 0, _cachedH = 0, _cachedChipp = null;
function ryktChippNew(W,H){
  if(W===_cachedW && H===_cachedH && _cachedChipp) return _cachedChipp;
  const b=W*0.29, h=H*0.085, y=H-h-H*0.035;
  _cachedW = W; _cachedH = H;
  return _cachedChipp = RYKTREDSKAP.map((r,i)=>({r,i,x:W*0.025+i*(b+W*0.012),y,b,h}));
}

console.log("Benchmarking ryktChipp allocation...");

const iters = 1000000;
const startOld = performance.now();
for (let i = 0; i < iters; i++) {
  ryktChippOld(800, 600);
}
const endOld = performance.now();
console.log(`Original: ${endOld - startOld} ms for ${iters} iterations`);

const startNew = performance.now();
for (let i = 0; i < iters; i++) {
  ryktChippNew(800, 600);
}
const endNew = performance.now();
console.log(`New: ${endNew - startNew} ms for ${iters} iterations`);
