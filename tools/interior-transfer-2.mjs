#!/usr/bin/env node
/* One-shot, branch-scoped transfer of independently reviewed source. */
import fs from 'node:fs';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import {spawnSync} from 'node:child_process';
const BASE='87296f39ab7c06f0827b6f0f8bedba49e8a3fa3b';
const TARGET='chatgpt/interior-fidelity-review';
const TRANSFER='chatgpt/interior-fidelity-transfer-2';
const EXPECTED_TEXT='27db81e4dc3a917b632d0e2d8a5fbee0631691364d8aeb47c39f190117de1753';
const EXPECTED_PATCH='9dd8ba1b0c1115150bec6d59d8337de8f94093ab7b551f606b44cf95a571a9c3';
const paths=['src/site.js','src/varld3d.js','roblox/buildings/Anlaggningen.luau','roblox/buildings/UBRFKomplex.luau','docs/F02-C-INTERIOR-FIDELITY.md','tools/interior-a-gavel-test.mjs'];
const hash=v=>crypto.createHash('sha256').update(v).digest('hex');
function run(cmd,args){const r=spawnSync(cmd,args,{stdio:'inherit',encoding:'utf8'});if(r.status!==0)throw Error(`${cmd} exited ${r.status}`);}
function output(cmd,args){const r=spawnSync(cmd,args,{encoding:'utf8'});if(r.status!==0)throw Error(r.stderr);return r.stdout.trim();}
if(process.env.GITHUB_REF!==`refs/heads/${TRANSFER}`)throw Error('Wrong source branch');
const original=fs.readFileSync('tools/interior-second-pass.patch.br.b64','utf8').trim();
const tail3=fs.readFileSync('tools/interior-second-pass-tail-3.txt','utf8').trim();
const tail4=fs.readFileSync('tools/interior-second-pass-tail-4.txt','utf8').trim();
if(hash(original.slice(0,2000))!=='5b76412698aef392deff7ac8f316efadad3b6523ac42197aa586cca2f6ced3f9'||hash(original.slice(2000,4000))!=='b9943399bc95860a664f74eb9e680d786a3b08ec290c999bb754937c7220f76c')throw Error('Original prefix differs from reviewed source');
if(tail3.length!==2000||hash(tail3)!=='b5008c2a5deb783184be4ee1f44c275c397611206808b7b0268a92a1cec353da')throw Error('Third chunk mismatch');
if(tail4.length!==2060||hash(tail4)!=='8a3146a5662e81821807b57725d89509d1f63be7350c1c394f4a607b9f8fe558')throw Error('Fourth chunk mismatch');
const text=original.slice(0,4000)+tail3+tail4;
if(text.length!==8060||hash(text)!==EXPECTED_TEXT)throw Error('Reconstructed payload checksum mismatch');
const patch=zlib.brotliDecompressSync(Buffer.from(text,'base64'));
if(hash(patch)!==EXPECTED_PATCH)throw Error('Patch checksum mismatch');
fs.writeFileSync('/tmp/ubrf-interior-second-pass.patch',patch);
const remote=output('git',['ls-remote','origin',`refs/heads/${TARGET}`]).split(/\s+/)[0];
if(remote!==BASE)throw Error(`Target changed: ${remote}; stop and reconcile`);
run('git',['checkout','--detach',BASE]);
run('git',['apply','--check','/tmp/ubrf-interior-second-pass.patch']);
run('git',['apply','/tmp/ubrf-interior-second-pass.patch']);
function assertPaths(){const changed=output('git',['diff','--name-only']).split('\n').filter(Boolean);const added=output('git',['ls-files','--others','--exclude-standard']).split('\n').filter(Boolean);for(const p of [...changed,...added])if(!paths.includes(p))throw Error(`Unexpected path: ${p}`);}
assertPaths();
run('node',['tools/interiortest.mjs']);
run('node',['tools/interior-a-gavel-test.mjs']);
run('node',['tools/exportera-geometri.js','--kontrollera']);
run('python3',['tools/kolla-material.py']);
run('python3',['tools/build.py']);
run('git',['diff','--check']);
assertPaths();
const latest=output('git',['ls-remote','origin',`refs/heads/${TARGET}`]).split(/\s+/)[0];
if(latest!==BASE)throw Error('Target moved during testing; stop and reconcile');
run('git',['add','--',...paths]);
run('git',['-c','user.name=ChatGPT','-c','user.email=83163288+Carneteg@users.noreply.github.com','commit','-m','F02-C: source-driven A-gable finish and runtime regression']);
run('git',['push','origin',`HEAD:refs/heads/${TARGET}`]);
console.log('Source-only commit published; full CI, visual review and Tobias acceptance still required.');
