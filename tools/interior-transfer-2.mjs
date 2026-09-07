#!/usr/bin/env node
import fs from 'node:fs';
import crypto from 'node:crypto';
const s=fs.readFileSync('tools/interior-second-pass.patch.br.b64','utf8').trim();
const hash=v=>crypto.createHash('sha256').update(v).digest('hex');
console.log('Payload length:',s.length,'SHA256:',hash(s));
for(let i=0;i<s.length;i+=2000)console.log('Chunk',Math.floor(i/2000)+1,s.slice(i,i+2000).length,hash(s.slice(i,i+2000)));
if(hash(s)!=='27db81e4dc3a917b632d0e2d8a5fbee0631691364d8aeb47c39f190117de1753')throw Error('Transfer payload differs from reviewed local source; no code modified');
