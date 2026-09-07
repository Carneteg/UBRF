#!/usr/bin/env node
/* One-shot, branch-scoped transfer of the locally reviewed F02-C patch.
   Never push changes to an existing protected workflow. */
import fs from 'node:fs';
import crypto from 'node:crypto';
import zlib from 'node:zlib';
import {spawnSync} from 'node:child_process';
const BASE='e65675dfe3584f5654aab3280d53692fe9b17f1a';
const BRANCH='chatgpt/interior-fidelity-v1';
const EXPECTED='5aed6aafca16af62d4f056111cdc843cd9feefc332dc4601888004464c64eace';
function run(cmd,args){const r=spawnSync(cmd,args,{stdio:'inherit',encoding:'utf8'});if(r.status!==0)throw Error(`${cmd} failed: ${r.status}`);}
function output(cmd,args){const r=spawnSync(cmd,args,{encoding:'utf8'});if(r.status!==0)throw Error(r.stderr);return r.stdout.trim();}
if(process.env.GITHUB_REF!==`refs/heads/${BRANCH}`)throw Error('Wrong branch');
if(output('git',['merge-base',BASE,'HEAD'])!==BASE)throw Error('Accepted baseline is not an ancestor');
const protectedPaths=['src/site.js','src/inredning.js','src/varld3d.js','roblox/buildings/Anlaggningen.luau','roblox/buildings/UBRFKomplex.luau','tools/exportera-geometri.js'];
run('git',['diff','--exit-code',BASE,'HEAD','--',...protectedPaths]);
const input=fs.readFileSync('tools/interior-fidelity.patch.br.b64','utf8').trim();
const patch=zlib.brotliDecompressSync(Buffer.from(input,'base64'));
if(crypto.createHash('sha256').update(patch).digest('hex')!==EXPECTED)throw Error('Patch checksum mismatch');
fs.writeFileSync('/tmp/ubrf-interior-reviewed.patch',patch);
run('git',['apply','--check','/tmp/ubrf-interior-reviewed.patch']);
run('git',['apply','/tmp/ubrf-interior-reviewed.patch']);
// The local patch included a test registration in grindar.yml. GitHub's
// workflow permission boundary is respected: restore it, do not stage it.
run('git',['restore','--','.github/workflows/grindar.yml']);
run('node',['tools/interiortest.mjs']);
run('node',['tools/exportera-geometri.js','--kontrollera']);
run('python3',['tools/kolla-material.py']);
run('git',['diff','--check']);
const paths=['docs/F02-C-INTERIOR-FIDELITY.md','docs/INTERIOR-GEOMETRY-LOCK.json','roblox/buildings/Anlaggningen.luau','roblox/buildings/UBRFKomplex.luau','src/inredning.js','src/site.js','src/varld3d.js','tools/exportera-geometri.js','tools/interiortest.mjs'];
run('git',['add','--',...paths]);
run('git',['rm','--','tools/interior-source-workbench.mjs','tools/interior-fidelity.patch.br.b64']);
run('git',['-c','user.name=ChatGPT','-c','user.email=83163288+Carneteg@users.noreply.github.com','commit','-m','F02-C: source-driven interior finishes and locker details']);
// Leave the temporary workflow untouched. Remove it separately through the
// authorized GitHub contents API after this code commit is published.
run('git',['push','origin',`HEAD:refs/heads/${BRANCH}`]);
console.log('F02-C implementation published without protected workflow changes.');
