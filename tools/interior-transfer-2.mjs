#!/usr/bin/env node
/* One-shot, branch-scoped source transfer. No workflow or secrets changes. */
import fs from 'node:fs';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import {spawnSync} from 'node:child_process';
const BASE='87296f39ab7c06f0827b6f0f8bedba49e8a3fa3b';
const TARGET='chatgpt/interior-fidelity-review';
const TRANSFER='chatgpt/interior-fidelity-transfer-2';
const EXPECTED='9dd8ba1b0c1115150bec6d59d8337de8f94093ab7b551f606b44cf95a571a9c3';
const paths=['src/site.js','src/varld3d.js','roblox/buildings/Anlaggningen.luau','roblox/buildings/UBRFKomplex.luau','docs/F02-C-INTERIOR-FIDELITY.md','tools/interior-a-gavel-test.mjs'];
function run(cmd,args){const r=spawnSync(cmd,args,{stdio:'inherit',encoding:'utf8'});if(r.status!==0)throw Error(`${cmd} exited ${r.status}`);}
function output(cmd,args){const r=spawnSync(cmd,args,{encoding:'utf8'});if(r.status!==0)throw Error(r.stderr);return r.stdout.trim();}
if(process.env.GITHUB_REF!==`refs/heads/${TRANSFER}`)throw Error('Wrong source branch');
const remote=output('git',['ls-remote','origin',`refs/heads/${TARGET}`]).split(/\s+/)[0];
if(remote!==BASE)throw Error(`Target changed: ${remote}; stop and reconcile`);
run('git',['checkout','--detach',BASE]);
const patch=zlib.brotliDecompressSync(Buffer.from(fs.readFileSync('tools/interior-second-pass.patch.br.b64','utf8').trim(),'base64'));
if(crypto.createHash('sha256').update(patch).digest('hex')!==EXPECTED)throw Error('Patch checksum mismatch');
fs.writeFileSync('/tmp/ubrf-interior-second-pass.patch',patch);
run('git',['apply','--check','/tmp/ubrf-interior-second-pass.patch']);
run('git',['apply','/tmp/ubrf-interior-second-pass.patch']);
const changed=output('git',['diff','--name-only']).split('\n').filter(Boolean);
const added=output('git',['ls-files','--others','--exclude-standard']).split('\n').filter(Boolean);
for(const p of [...changed,...added])if(!paths.includes(p))throw Error(`Unexpected path: ${p}`);
run('node',['tools/interiortest.mjs']);
run('node',['tools/interior-a-gavel-test.mjs']);
run('node',['tools/exportera-geometri.js','--kontrollera']);
run('python3',['tools/kolla-material.py']);
run('python3',['tools/build.py']);
run('git',['diff','--check']);
run('git',['add','--',...paths]);
run('git',['-c','user.name=ChatGPT','-c','user.email=83163288+Carneteg@users.noreply.github.com','commit','-m','F02-C: source-driven A-gable finish and runtime regression']);
run('git',['push','origin',`HEAD:refs/heads/${TARGET}`]);
console.log('Source-only commit published; full CI, visual review and Tobias acceptance still required.');
