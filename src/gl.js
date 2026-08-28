/* ══════════════════════════════════════════════════════════════════
   GL — en liten 3D-motor i rå WebGL, skriven för det här spelet.
   Ingen three.js och ingen CDN: spelet ska förbli en enda fil som
   fungerar utan nätverk. Motorn kan det ridscenen behöver och inte
   mer — perspektiv med djupbuffert, en varm riktad sol med
   hemisfäriskt omgivningsljus, dimma, vertexfärger, canvastexturer
   och plana projicerade skuggor på marken.
   ══════════════════════════════════════════════════════════════════ */
"use strict";

/* ── Matrisräkning (kolumnvis, som GL vill ha den) ─────────────── */
const M4={
  ny(){return new Float32Array([1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1]);},
  mul(a,b,ut){
    const o=ut||new Float32Array(16);
    for(let c=0;c<4;c++){
      const b0=b[c*4],b1=b[c*4+1],b2=b[c*4+2],b3=b[c*4+3];
      o[c*4  ]=a[0]*b0+a[4]*b1+a[8] *b2+a[12]*b3;
      o[c*4+1]=a[1]*b0+a[5]*b1+a[9] *b2+a[13]*b3;
      o[c*4+2]=a[2]*b0+a[6]*b1+a[10]*b2+a[14]*b3;
      o[c*4+3]=a[3]*b0+a[7]*b1+a[11]*b2+a[15]*b3;
    }
    return o;
  },
  translation(x,y,z){const m=M4.ny();m[12]=x;m[13]=y;m[14]=z;return m;},
  skala(x,y,z){const m=M4.ny();m[0]=x;m[5]=y===undefined?x:y;m[10]=z===undefined?x:z;return m;},
  rotX(a){const c=Math.cos(a),s=Math.sin(a),m=M4.ny();
    m[5]=c;m[6]=s;m[9]=-s;m[10]=c;return m;},
  rotY(a){const c=Math.cos(a),s=Math.sin(a),m=M4.ny();
    m[0]=c;m[2]=-s;m[8]=s;m[10]=c;return m;},
  rotZ(a){const c=Math.cos(a),s=Math.sin(a),m=M4.ny();
    m[0]=c;m[1]=s;m[4]=-s;m[5]=c;return m;},
  perspektiv(fovy,aspekt,nara,fjarran){
    const f=1/Math.tan(fovy/2), nf=1/(nara-fjarran), m=new Float32Array(16);
    m[0]=f/aspekt;m[5]=f;m[10]=(fjarran+nara)*nf;m[11]=-1;
    m[14]=2*fjarran*nara*nf;
    return m;
  },
  seFran(oga,mal,upp){
    let zx=oga[0]-mal[0], zy=oga[1]-mal[1], zz=oga[2]-mal[2];
    let l=Math.hypot(zx,zy,zz)||1; zx/=l;zy/=l;zz/=l;
    let xx=upp[1]*zz-upp[2]*zy, xy=upp[2]*zx-upp[0]*zz, xz=upp[0]*zy-upp[1]*zx;
    l=Math.hypot(xx,xy,xz)||1; xx/=l;xy/=l;xz/=l;
    const yx=zy*xz-zz*xy, yy=zz*xx-zx*xz, yz=zx*xy-zy*xx;
    return new Float32Array([
      xx,yx,zx,0, xy,yy,zy,0, xz,yz,zz,0,
      -(xx*oga[0]+xy*oga[1]+xz*oga[2]),
      -(yx*oga[0]+yy*oga[1]+yz*oga[2]),
      -(zx*oga[0]+zy*oga[1]+zz*oga[2]), 1]);
  },
  /* Normalmatris: inversens transponat av 3×3-delen. */
  normalMat(m,ut){
    const o=ut||new Float32Array(9);
    const a00=m[0],a01=m[1],a02=m[2], a10=m[4],a11=m[5],a12=m[6],
          a20=m[8],a21=m[9],a22=m[10];
    const b01=a22*a11-a12*a21, b11=-a22*a10+a12*a20, b21=a21*a10-a11*a20;
    let det=a00*b01+a01*b11+a02*b21;
    if(!det){o.set([1,0,0,0,1,0,0,0,1]);return o;}
    det=1/det;
    o[0]=b01*det; o[1]=(-a22*a01+a02*a21)*det; o[2]=(a12*a01-a02*a11)*det;
    o[3]=b11*det; o[4]=(a22*a00-a02*a20)*det;  o[5]=(-a12*a00+a02*a10)*det;
    o[6]=b21*det; o[7]=(-a21*a00+a01*a20)*det; o[8]=(a11*a00-a01*a10)*det;
    return o;
  },
  /* Plan skuggmatris: projicerar geometrin ner i planet y = h längs
     ljusriktningen. Ger skarpa skuggor med benens form. */
  skugga(ljus,h){
    const lx=ljus[0],ly=ljus[1],lz=ljus[2];
    return new Float32Array([
      ly, 0, 0, 0,
      -lx, 0, -lz, 0,
      0, 0, ly, 0,
      -lx*h, ly*h, -lz*h, ly]);
  },
};

/* ── Färghjälp: "#RRGGBB" → [r,g,b] i 0–1 ─────────────────────── */
function glFarg(h){
  if(Array.isArray(h))return h;
  const n=parseInt(h.slice(1),16);
  return [(n>>16&255)/255, (n>>8&255)/255, (n&255)/255];
}
function glMorka(f,k){const c=glFarg(f);return [c[0]*k,c[1]*k,c[2]*k];}

/* ── Geometribyggare ──────────────────────────────────────────────
   Samlar trianglar med position, normal, färg och uv. Primitiverna
   läggs in med en transform så att en hel byggnad kan bakas till ett
   enda nät — det som ritas varje bildruta ska vara få anrop. ── */
class Bygge{
  constructor(){this.p=[];this.n=[];this.c=[];this.u=[];this.i=[];}
  get antal(){return this.p.length/3;}
  /* Lägger till en triangelmängd transformerad med mat. */
  las(pos,nrm,uv,idx,farg,mat){
    const bas=this.antal, f=glFarg(farg);
    const m=mat||M4.ny(), nm=M4.normalMat(m);
    for(let k=0;k<pos.length;k+=3){
      const x=pos[k],y=pos[k+1],z=pos[k+2];
      this.p.push(m[0]*x+m[4]*y+m[8]*z+m[12],
                  m[1]*x+m[5]*y+m[9]*z+m[13],
                  m[2]*x+m[6]*y+m[10]*z+m[14]);
      const nx=nrm[k],ny=nrm[k+1],nz=nrm[k+2];
      let ax=nm[0]*nx+nm[3]*ny+nm[6]*nz,
          ay=nm[1]*nx+nm[4]*ny+nm[7]*nz,
          az=nm[2]*nx+nm[5]*ny+nm[8]*nz;
      const l=Math.hypot(ax,ay,az)||1;
      this.n.push(ax/l,ay/l,az/l);
      this.c.push(f[0],f[1],f[2]);
    }
    for(let k=0;k<uv.length;k++)this.u.push(uv[k]);
    for(let k=0;k<idx.length;k++)this.i.push(bas+idx[k]);
    return this;
  }
  lada(w,h,d,farg,mat){const g=GEO.lada(w,h,d);return this.las(g.p,g.n,g.u,g.i,farg,mat);}
  klot(r,farg,mat,seg){const g=GEO.klot(r,seg||14);return this.las(g.p,g.n,g.u,g.i,farg,mat);}
  cyl(r0,r1,h,farg,mat,seg,lock){const g=GEO.cyl(r0,r1,h,seg||12,lock!==false);
    return this.las(g.p,g.n,g.u,g.i,farg,mat);}
  yta(w,d,farg,mat,uvSkala){const g=GEO.yta(w,d,uvSkala||1);
    return this.las(g.p,g.n,g.u,g.i,farg,mat);}
  /* Stående rektangel i XY-planet (för skyltar, speglar, banderoller). */
  panel(w,h,farg,mat){const g=GEO.panel(w,h);return this.las(g.p,g.n,g.u,g.i,farg,mat);}
}

/* Primitiver — byggs en gång och återanvänds av Bygge. */
const GEO={
  _cache:{},
  lada(w,h,d){
    const nyckel="l"+w+"_"+h+"_"+d;
    if(this._cache[nyckel])return this._cache[nyckel];
    const x=w/2,y=h/2,z=d/2, p=[],n=[],u=[],i=[];
    const sidor=[
      [[ x,-y,-z],[ x,-y, z],[ x, y, z],[ x, y,-z],[ 1,0,0]],
      [[-x,-y, z],[-x,-y,-z],[-x, y,-z],[-x, y, z],[-1,0,0]],
      [[-x, y,-z],[ x, y,-z],[ x, y, z],[-x, y, z],[0, 1,0]],
      [[-x,-y, z],[ x,-y, z],[ x,-y,-z],[-x,-y,-z],[0,-1,0]],
      [[-x,-y, z],[-x, y, z],[ x, y, z],[ x,-y, z],[0,0, 1]],
      [[ x,-y,-z],[ x, y,-z],[-x, y,-z],[-x,-y,-z],[0,0,-1]],
    ];
    for(const s of sidor){
      const b=p.length/3;
      for(let k=0;k<4;k++){p.push(...s[k]);n.push(...s[4]);}
      u.push(0,0, 1,0, 1,1, 0,1);
      i.push(b,b+1,b+2, b,b+2,b+3);
    }
    return this._cache[nyckel]={p,n,u,i};
  },
  klot(r,seg){
    const nyckel="k"+r+"_"+seg;
    if(this._cache[nyckel])return this._cache[nyckel];
    const p=[],n=[],u=[],i=[], rader=Math.max(6,Math.round(seg*0.6));
    for(let y=0;y<=rader;y++){
      const v=y/rader, fi=v*Math.PI;
      for(let x=0;x<=seg;x++){
        const uu=x/seg, te=uu*Math.PI*2;
        const nx=Math.sin(fi)*Math.cos(te), ny=Math.cos(fi), nz=Math.sin(fi)*Math.sin(te);
        p.push(nx*r,ny*r,nz*r); n.push(nx,ny,nz); u.push(uu,v);
      }
    }
    for(let y=0;y<rader;y++)for(let x=0;x<seg;x++){
      const a=y*(seg+1)+x, b=a+seg+1;
      i.push(a,b,a+1, b,b+1,a+1);
    }
    return this._cache[nyckel]={p,n,u,i};
  },
  /* Kon/cylinder längs +Y, botten i y=0. */
  cyl(r0,r1,h,seg,lock){
    const nyckel="c"+r0+"_"+r1+"_"+h+"_"+seg+"_"+lock;
    if(this._cache[nyckel])return this._cache[nyckel];
    const p=[],n=[],u=[],i=[];
    const lut=Math.atan2(r0-r1,h);
    for(let y=0;y<=1;y++){
      const r=y?r1:r0;
      for(let x=0;x<=seg;x++){
        const uu=x/seg, te=uu*Math.PI*2;
        const cx=Math.cos(te), cz=Math.sin(te);
        p.push(cx*r, y*h, cz*r);
        n.push(cx*Math.cos(lut), Math.sin(lut), cz*Math.cos(lut));
        u.push(uu,y);
      }
    }
    for(let x=0;x<seg;x++){
      const a=x, b=a+seg+1;
      i.push(a,b,a+1, b,b+1,a+1);
    }
    if(lock)for(let y=0;y<=1;y++){
      const r=y?r1:r0; if(r<=0.0001)continue;
      const mitt=p.length/3;
      p.push(0,y*h,0); n.push(0,y?1:-1,0); u.push(0.5,0.5);
      for(let x=0;x<=seg;x++){
        const te=x/seg*Math.PI*2;
        p.push(Math.cos(te)*r, y*h, Math.sin(te)*r);
        n.push(0,y?1:-1,0); u.push(0,0);
      }
      for(let x=0;x<seg;x++){
        if(y)i.push(mitt, mitt+1+x, mitt+2+x);
        else i.push(mitt, mitt+2+x, mitt+1+x);
      }
    }
    return this._cache[nyckel]={p,n,u,i};
  },
  /* Liggande yta i XZ, centrerad. Vindningen moturs sedd uppifrån,
     så att ytan är framsida uppåt och inte kullas bort. */
  yta(w,d,uvS){
    const x=w/2,z=d/2;
    return {p:[-x,0,-z, x,0,-z, x,0,z, -x,0,z],
            n:[0,1,0, 0,1,0, 0,1,0, 0,1,0],
            u:[0,0, uvS,0, uvS,uvS, 0,uvS],
            i:[0,2,1, 0,3,2]};
  },
  /* Stående yta i XY, centrerad, normal +Z. Texturen laddas med
     UNPACK_FLIP_Y, så nederkanten ska ha v = 0 för att bilden ska
     stå rätt upp. */
  panel(w,h){
    const x=w/2,y=h/2;
    return {p:[-x,-y,0, x,-y,0, x,y,0, -x,y,0],
            n:[0,0,1, 0,0,1, 0,0,1, 0,0,1],
            u:[0,0, 1,0, 1,1, 0,1],
            i:[0,1,2, 0,2,3]};
  },
};

/* ── Motorn ───────────────────────────────────────────────────── */
const GL={
  gl:null, canvas:null, prog:null, a:{}, u:{}, vitTex:null,
  redo:false, trasig:false,
  bredd:0, hojd:0,
  proj:M4.ny(), vy:M4.ny(),
  _nm:new Float32Array(9),

  init(canvas){
    if(this.redo||this.trasig)return this.redo;
    this.canvas=canvas;
    let gl=null;
    try{
      const opt={antialias:true, alpha:true, depth:true, premultipliedAlpha:false,
        powerPreference:"high-performance"};
      gl=canvas.getContext("webgl",opt)||canvas.getContext("experimental-webgl",opt);
    }catch(_){}
    if(!gl){this.trasig=true;return false;}
    this.gl=gl;
    const vs=`
      attribute vec3 aPos; attribute vec3 aNrm; attribute vec3 aCol; attribute vec2 aUv;
      uniform mat4 uProj, uVy, uModell; uniform mat3 uNM;
      varying vec3 vNrm, vCol; varying vec2 vUv; varying float vDjup; varying vec3 vPos;
      void main(){
        vec4 v = uModell * vec4(aPos,1.0);
        vec4 s = uVy * v;
        gl_Position = uProj * s;
        vNrm = normalize(uNM * aNrm);
        vCol = aCol; vUv = aUv; vPos = v.xyz;
        vDjup = -s.z;
      }`;
    const fs=`
      precision mediump float;
      varying vec3 vNrm, vCol; varying vec2 vUv; varying float vDjup; varying vec3 vPos;
      uniform vec3 uSol, uSolFarg, uHimmel, uMark, uDimFarg, uTon;
      uniform float uDimNara, uDimFjarr, uAlfa, uAnvTex, uPlatt;
      uniform sampler2D uTex;
      void main(){
        vec3 bas = vCol * uTon;
        if(uAnvTex > 0.5) bas *= texture2D(uTex, vUv).rgb;
        if(uPlatt > 0.5){
          gl_FragColor = vec4(bas, uAlfa);
          return;
        }
        vec3 N = normalize(vNrm);
        float d = max(dot(N, uSol), 0.0);
        // hemisfäriskt omgivningsljus: himmel ovanifrån, mark underifrån
        float h = N.y * 0.5 + 0.5;
        vec3 amb = mix(uMark, uHimmel, h);
        // mjuk halvskugga så att skuggsidan inte blir platt svart
        float wrap = max(dot(N, uSol) * 0.5 + 0.5, 0.0);
        vec3 ljus = amb + uSolFarg * (d * 0.78 + wrap * 0.22);
        vec3 farg = bas * ljus;
        float dim = clamp((vDjup - uDimNara) / max(uDimFjarr - uDimNara, 0.001), 0.0, 1.0);
        farg = mix(farg, uDimFarg, dim * 0.85);
        gl_FragColor = vec4(farg, uAlfa);
      }`;
    const p=this._program(vs,fs);
    if(!p){this.trasig=true;return false;}
    this.prog=p;
    gl.useProgram(p);
    for(const n of ["aPos","aNrm","aCol","aUv"])this.a[n]=gl.getAttribLocation(p,n);
    for(const n of ["uProj","uVy","uModell","uNM","uSol","uSolFarg","uHimmel","uMark",
      "uDimFarg","uDimNara","uDimFjarr","uAlfa","uAnvTex","uPlatt","uTex","uTon"])
      this.u[n]=gl.getUniformLocation(p,n);
    gl.enable(gl.DEPTH_TEST);
    gl.depthFunc(gl.LEQUAL);
    gl.enable(gl.CULL_FACE);
    gl.cullFace(gl.BACK);
    gl.blendFunc(gl.SRC_ALPHA,gl.ONE_MINUS_SRC_ALPHA);
    // 1×1 vit textur som standard
    this.vitTex=gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D,this.vitTex);
    gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,1,1,0,gl.RGBA,gl.UNSIGNED_BYTE,
      new Uint8Array([255,255,255,255]));
    gl.uniform1i(this.u.uTex,0);
    this.redo=true;
    return true;
  },
  _program(vsK,fsK){
    const gl=this.gl;
    const bygg=(typ,kod)=>{
      const s=gl.createShader(typ);
      gl.shaderSource(s,kod);gl.compileShader(s);
      if(!gl.getShaderParameter(s,gl.COMPILE_STATUS)){
        console.warn("shaderfel:",gl.getShaderInfoLog(s));return null;}
      return s;
    };
    const v=bygg(gl.VERTEX_SHADER,vsK), f=bygg(gl.FRAGMENT_SHADER,fsK);
    if(!v||!f)return null;
    const p=gl.createProgram();
    gl.attachShader(p,v);gl.attachShader(p,f);gl.linkProgram(p);
    if(!gl.getProgramParameter(p,gl.LINK_STATUS)){
      console.warn("länkfel:",gl.getProgramInfoLog(p));return null;}
    return p;
  },

  /* Nät på grafikkortet. */
  nat(bygge){
    const gl=this.gl;
    const gor=(data,typ)=>{const b=gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER,b);
      gl.bufferData(gl.ARRAY_BUFFER,data,gl.STATIC_DRAW);return b;};
    const ib=gl.createBuffer();
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,ib);
    const idx=bygge.antal>65535?new Uint32Array(bygge.i):new Uint16Array(bygge.i);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER,idx,gl.STATIC_DRAW);
    return {p:gor(new Float32Array(bygge.p)), n:gor(new Float32Array(bygge.n)),
      c:gor(new Float32Array(bygge.c)), u:gor(new Float32Array(bygge.u)),
      i:ib, antal:bygge.i.length, stor:bygge.antal>65535};
  },
  fritt(nat){
    if(!nat)return;const gl=this.gl;
    for(const k of ["p","n","c","u","i"])if(nat[k])gl.deleteBuffer(nat[k]);
  },
  /* Textur ur en canvas (skyltar, sand, gräs, plåt). */
  textur(canvas,upprepa){
    const gl=this.gl, t=gl.createTexture();
    gl.bindTexture(gl.TEXTURE_2D,t);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,true);
    gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,gl.RGBA,gl.UNSIGNED_BYTE,canvas);
    const pot=(canvas.width&(canvas.width-1))===0&&(canvas.height&(canvas.height-1))===0;
    if(pot){
      gl.generateMipmap(gl.TEXTURE_2D);
      gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR_MIPMAP_LINEAR);
    }else gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
    const lage=(upprepa&&pot)?gl.REPEAT:gl.CLAMP_TO_EDGE;
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,lage);
    gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,lage);
    gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL,false);
    return t;
  },

  /* Bildrutans start: storlek, rensning och ljussättning. */
  start(bredd,hojd,dpr,ljus){
    const gl=this.gl;
    const w=Math.max(1,Math.round(bredd*dpr)), h=Math.max(1,Math.round(hojd*dpr));
    if(this.canvas.width!==w||this.canvas.height!==h){
      this.canvas.width=w;this.canvas.height=h;
    }
    this.bredd=bredd;this.hojd=hojd;
    gl.viewport(0,0,w,h);
    gl.useProgram(this.prog);
    gl.clearColor(0,0,0,0);
    gl.depthMask(true);
    gl.disable(gl.BLEND);
    gl.clear(gl.COLOR_BUFFER_BIT|gl.DEPTH_BUFFER_BIT);
    const s=ljus.sol, l=Math.hypot(s[0],s[1],s[2])||1;
    gl.uniform3f(this.u.uSol,s[0]/l,s[1]/l,s[2]/l);
    gl.uniform3fv(this.u.uSolFarg,glFarg(ljus.solFarg));
    gl.uniform3fv(this.u.uHimmel,glFarg(ljus.himmel));
    gl.uniform3fv(this.u.uMark,glFarg(ljus.mark));
    gl.uniform3fv(this.u.uDimFarg,glFarg(ljus.dimFarg));
    gl.uniform1f(this.u.uDimNara,ljus.dimNara);
    gl.uniform1f(this.u.uDimFjarr,ljus.dimFjarr);
    gl.uniform1f(this.u.uAlfa,1);
    gl.uniform1f(this.u.uPlatt,0);
    gl.uniform3f(this.u.uTon,1,1,1);
    this.ljus=ljus;
  },
  kamera(oga,mal,fov){
    this.proj=M4.perspektiv(fov||1.02, this.bredd/Math.max(this.hojd,1), 0.12, 320);
    this.vy=M4.seFran(oga,mal,[0,1,0]);
    this.gl.uniformMatrix4fv(this.u.uProj,false,this.proj);
    this.gl.uniformMatrix4fv(this.u.uVy,false,this.vy);
    this.ogaPos=oga;
  },
  /* Ritar ett nät med given modellmatris. */
  rita(nat,modell,opt){
    if(!nat)return;
    const gl=this.gl, o=opt||{};
    gl.uniformMatrix4fv(this.u.uModell,false,modell);
    gl.uniformMatrix3fv(this.u.uNM,false,M4.normalMat(modell,this._nm));
    gl.uniform1f(this.u.uAlfa,o.alfa===undefined?1:o.alfa);
    gl.uniform1f(this.u.uPlatt,o.platt?1:0);
    gl.uniform3fv(this.u.uTon,o.ton?glFarg(o.ton):[1,1,1]);
    gl.uniform1f(this.u.uAnvTex,o.tex?1:0);
    gl.bindTexture(gl.TEXTURE_2D,o.tex||this.vitTex);
    if(o.alfa!==undefined&&o.alfa<1){gl.enable(gl.BLEND);gl.depthMask(false);}
    if(o.baksidor)gl.disable(gl.CULL_FACE);
    const bind=(buf,attr,storlek)=>{
      if(attr<0)return;
      gl.bindBuffer(gl.ARRAY_BUFFER,buf);
      gl.enableVertexAttribArray(attr);
      gl.vertexAttribPointer(attr,storlek,gl.FLOAT,false,0,0);
    };
    bind(nat.p,this.a.aPos,3);bind(nat.n,this.a.aNrm,3);
    bind(nat.c,this.a.aCol,3);bind(nat.u,this.a.aUv,2);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER,nat.i);
    gl.drawElements(gl.TRIANGLES,nat.antal,
      nat.stor?gl.UNSIGNED_INT:gl.UNSIGNED_SHORT,0);
    if(o.alfa!==undefined&&o.alfa<1){gl.disable(gl.BLEND);gl.depthMask(true);}
    if(o.baksidor)gl.enable(gl.CULL_FACE);
  },
  /* Skuggan: samma nät plattat ner i marken längs solens riktning. */
  skugga(nat,modell,markY){
    if(!nat||!this.ljus)return;
    const gl=this.gl;
    const sm=M4.skugga(this.ljus.sol,(markY||0)+0.012);
    gl.enable(gl.BLEND);gl.depthMask(false);gl.disable(gl.CULL_FACE);
    this.rita(nat,M4.mul(sm,modell),{platt:true,alfa:this.ljus.skuggAlfa||0.22,
      ton:this.ljus.skuggFarg||"#000000"});
    gl.enable(gl.CULL_FACE);gl.depthMask(true);gl.disable(gl.BLEND);
  },
};

/* Textur ur en ritfunktion — allt är målat i spelet, inga bildfiler. */
function glCanvasTex(bredd,hojd,rita,upprepa){
  const c=document.createElement("canvas");
  c.width=bredd;c.height=hojd;
  rita(c.getContext("2d"),bredd,hojd);
  return GL.textur(c,upprepa);
}
