const fs = require('fs');
let code = fs.readFileSync('src/varld3d.js', 'utf8');

const snip = `  lagg(lak,T.tra);
  {const L=R.laktare;
   S3.statiskt.push({nat:GL.nat(lakN), tex:T.tra,
     tona:{x:L.x0, y:L.y1-LAKTARE_TONAD_ANDE, w:L.dackDjup, h:LAKTARE_TONAD_ANDE}});}
`;

// Remove it from Domarbas
code = code.replace(snip, '');

// Put it at the end of Laktare
const laktareEnd = `      tona: langsX ? {x:t.x0, y:t.y0-0.15, w:t.x1-t.x0, h:0.30} : {x:t.x0-0.15, y:t.y0, w:0.30, h:t.y1-t.y0}});
  }
}`;

code = code.replace(laktareEnd, laktareEnd.replace('  }\n}', '  }\n' + snip + '}'));
fs.writeFileSync('src/varld3d.js', code);
