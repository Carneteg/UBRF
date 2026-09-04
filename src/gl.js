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

/* Plana ytnormaler — fasettering.
   Varje triangel får en egen normal och egna hörn, så ljuset bryts vid
   varje kant i stället för att glida över ytan. Det är den tekniken som
   ger lågpolygonuttrycket i förlagan: formen är rundad, men varje
   polygon läser som ett eget plan. Kostar tre hörn per triangel, vilket
   är billigt på modeller i den här storleken. */
function glPlatta(b){
  const p=[],n=[],c=[],u=[],idx=[];
  for(let k=0;k<b.i.length;k+=3){
    const t=[b.i[k],b.i[k+1],b.i[k+2]];
    const P=t.map(v=>[b.p[v*3],b.p[v*3+1],b.p[v*3+2]]);
    const e1=[P[1][0]-P[0][0],P[1][1]-P[0][1],P[1][2]-P[0][2]];
    const e2=[P[2][0]-P[0][0],P[2][1]-P[0][1],P[2][2]-P[0][2]];
    let nx=e1[1]*e2[2]-e1[2]*e2[1],
        ny=e1[2]*e2[0]-e1[0]*e2[2],
        nz=e1[0]*e2[1]-e1[1]*e2[0];
    const l=Math.hypot(nx,ny,nz);
    if(l<1e-9)continue;                    // hoppa över degenererade trianglar
    nx/=l; ny/=l; nz/=l;
    const bas=p.length/3;
    for(let j=0;j<3;j++){
      const v=t[j];
      p.push(P[j][0],P[j][1],P[j][2]);
      n.push(nx,ny,nz);
      c.push(b.c[v*3],b.c[v*3+1],b.c[v*3+2]);
      u.push(b.u[v*2],b.u[v*2+1]);
    }
    idx.push(bas,bas+1,bas+2);
  }
  b.p=p; b.n=n; b.c=c; b.u=u; b.i=idx;
  return b;
}

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
  ladaM(w,h,d,farg,mat,varv){const g=GEO.ladaM(w,h,d,varv);
    return this.las(g.p,g.n,g.u,g.i,farg,mat);}
  klot(r,farg,mat,seg){const g=GEO.klot(r,seg||14);return this.las(g.p,g.n,g.u,g.i,farg,mat);}
  cyl(r0,r1,h,farg,mat,seg,lock){const g=GEO.cyl(r0,r1,h,seg||12,lock!==false);
    return this.las(g.p,g.n,g.u,g.i,farg,mat);}
  disk(d,farg,mat,seg){const g=GEO.disk(seg);
    return this.las(g.p,g.n,g.u,g.i,farg,M4.mul(mat||M4.ny(),M4.skala(d,1,d)));}
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
  /* Låda vars textur mäts i meter i stället för att töjas ut över varje
     sida. varv = hur många meter ett texturvarv täcker. Alla fyra
     väggsidorna får u i sidled och v i höjdled, så att en stående
     korrugering står upp på både långsida och gavel — lada() lägger
     u längs höjden på gavelsidorna, vilket lade plåtens ränder ner. */
  ladaM(w,h,d,varv){
    const nyckel="lm"+w+"_"+h+"_"+d+"_"+varv;
    if(this._cache[nyckel])return this._cache[nyckel];
    const g=this.lada(w,h,d), v=varv||2;
    const u=[];
    for(let k=0;k<g.p.length;k+=3){
      const px=g.p[k],py=g.p[k+1],pz=g.p[k+2];
      const nx=g.n[k],ny=g.n[k+1];
      if(Math.abs(nx)>0.5)      u.push(pz/v, py/v);   // långsidorna
      else if(Math.abs(ny)>0.5) u.push(px/v, pz/v);   // tak och botten
      else                      u.push(px/v, py/v);   // gavlarna
    }
    return this._cache[nyckel]={p:g.p,n:g.n,u,i:g.i};
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
  /* Liggande yta i XZ, centrerad, framsida uppåt. Vindningen är samma
     som lada() och panel() använder — den var tidigare handvänd för
     att överleva den spegelvända kameran, och då kullades lådorna bort
     i stället så fort speglingen rättades. En vindning för hela
     motorn, ingen annan. */
  yta(w,d,uvS){
    const x=w/2,z=d/2;
    return {p:[-x,0,-z, x,0,-z, x,0,z, -x,0,z],
            n:[0,1,0, 0,1,0, 0,1,0, 0,1,0],
            u:[0,0, uvS,0, uvS,uvS, 0,uvS],
            i:[0,1,2, 0,2,3]};
  },
  /* Liggande skiva i XZ, normal uppåt. Kontaktskuggan var förut en
     fyrkant, och tre staplade fyrkanter läser som tre rutor på marken —
     sämre än ingen skugga alls. En skiva staplad i ringar läser som en
     mjuk fläck. */
  disk(seg){
    const n=Math.max(6,seg||20);
    const p=[0,0,0], nr=[0,1,0], u=[0.5,0.5], i=[];
    for(let k=0;k<=n;k++){
      const a=k/n*Math.PI*2, c=Math.cos(a), si=Math.sin(a);
      p.push(c*0.5,0,si*0.5); nr.push(0,1,0);
      u.push(0.5+c*0.5,0.5+si*0.5);
      if(k>0)i.push(0,k,k+1);
    }
    return {p,n:nr,u,i};
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
      uniform vec3 uSol, uSolFarg, uHimmel, uMark, uDimFarg, uTon, uOga, uKantFarg;
      uniform float uKant, uSolStyrka, uHalvskugga, uAmbient;
      uniform float uAoHojd, uAoStyrka, uDimStyrka;
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
        float nd = dot(N, uSol);
        float d = max(nd, 0.0);
        // hemisfäriskt omgivningsljus: himmel ovanifrån, grönt återsken under
        float h = N.y * 0.5 + 0.5;
        vec3 amb = mix(uMark, uHimmel, h) * uAmbient;
        // bred halvskugga: skuggsidan behåller sin egen färg i stället för
        // att falla ihop till svart
        float wrap = max(nd * (1.0 - uHalvskugga) + uHalvskugga, 0.0);
        // kamerafyllnad: en svag lykta vid ögat så att den sida vi ser
        // aldrig blir en mörk skiva när solen står bakom
        vec3 mot = normalize(uOga - vPos);
        float fyll = max(dot(N, mot), 0.0);
        // kontaktocklusion: allt nära marken mörknar, som i en riktig scen
        float ao = mix(1.0 - uAoStyrka, 1.0,
          clamp(vPos.y / max(uAoHojd, 0.001), 0.0, 1.0));
        vec3 ljus = amb * ao + uSolFarg *
          (d * uSolStyrka + wrap * wrap * uSolStyrka * 0.72 + fyll * 0.16) * ao;
        vec3 farg = bas * ljus;
        // konturen tänds av ljuset bakifrån och ger volym åt runda former
        float fres = 1.0 - abs(dot(N, mot));
        fres = fres * fres * fres;
        farg *= (1.0 - 0.10 * fres);
        farg += uKantFarg * (fres * uKant * (0.30 + 0.70 * d));
        float dim = clamp((vDjup - uDimNara) / max(uDimFjarr - uDimNara, 0.001), 0.0, 1.0);
        farg = mix(farg, uDimFarg, dim * uDimStyrka);
        gl_FragColor = vec4(farg, uAlfa);
      }`;
    const p=this._program(vs,fs);
    if(!p){this.trasig=true;return false;}
    this.prog=p;
    gl.useProgram(p);
    for(const n of ["aPos","aNrm","aCol","aUv"])this.a[n]=gl.getAttribLocation(p,n);
    for(const n of ["uProj","uVy","uModell","uNM","uSol","uSolFarg","uHimmel","uMark",
      "uDimFarg","uDimNara","uDimFjarr","uAlfa","uAnvTex","uPlatt","uTex","uTon","uOga",
      "uKantFarg","uKant","uSolStyrka","uHalvskugga","uAmbient",
      "uAoHojd","uAoStyrka","uDimStyrka"])
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
    const nat={p:gor(new Float32Array(bygge.p)), n:gor(new Float32Array(bygge.n)),
      c:gor(new Float32Array(bygge.c)), u:gor(new Float32Array(bygge.u)),
      i:ib, antal:bygge.i.length, stor:bygge.antal>65535};
    /* Siktprovet (tools/siktgrind.mjs) behöver trianglarna på CPU-sidan
       för att avgöra om något står mellan kameran och spelaren. Kopian
       hålls bara när QA-harnessen satt SIKTPROV innan scenen byggdes —
       i spelet finns ingen anledning att bära nätet två gånger. */
    if(typeof SIKTPROV!=="undefined"&&SIKTPROV){nat.pos=bygge.p;nat.idx=bygge.i;}
    return nat;
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
    /* Scenen ritas i en textur så att efterbehandlingen — glöd och
       mättnad — kan arbeta på hela bilden innan den når skärmen. */
    this._postRedo=this._post(w,h);
    if(this._postRedo){
      gl.bindFramebuffer(gl.FRAMEBUFFER,this.post.scenFB);
    }
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
    gl.uniform3fv(this.u.uKantFarg,glFarg(ljus.kantFarg||ljus.solFarg));
    const tal=(v,d)=>v===undefined?d:v;
    gl.uniform1f(this.u.uKant,tal(ljus.kant,0.20));
    gl.uniform1f(this.u.uSolStyrka,tal(ljus.solStyrka,0.62));
    gl.uniform1f(this.u.uHalvskugga,tal(ljus.halvskugga,0.38));
    gl.uniform1f(this.u.uAmbient,tal(ljus.ambient,0.74));
    gl.uniform1f(this.u.uAoHojd,tal(ljus.aoHojd,0.85));
    gl.uniform1f(this.u.uAoStyrka,tal(ljus.aoStyrka,0.22));
    gl.uniform1f(this.u.uDimStyrka,tal(ljus.dimStyrka,0.80));
    gl.uniform3f(this.u.uTon,1,1,1);
    this.ljus=ljus;
  },
  kamera(oga,mal,fov){
    const f=fov||1.02, asp=this.bredd/Math.max(this.hojd,1);
    this.proj=M4.perspektiv(f, asp, 0.12, 320);
    /* Anläggningens x går österut och y norrut, och i 3D blir de X och
       Z med Y uppåt. Den kombinationen är vänsterhänt, så en vanlig
       seFran ger en spegelvänd bild: öster hamnar till vänster när man
       tittar norrut. Canvasrenderaren i world.js räknar redan höger-
       axeln som (fy, −fx) — öster till höger — och kamBas.hj här nedan
       gör likadant. Vyn speglas därför i kamerans X, och frontFace är
       satt till CW i start() eftersom speglingen vänder trianglarnas
       varvriktning. */
    this.vy=M4.mul(M4.skala(-1,1,1),M4.seFran(oga,mal,[0,1,0]));
    this.gl.uniformMatrix4fv(this.u.uProj,false,this.proj);
    this.gl.uniformMatrix4fv(this.u.uVy,false,this.vy);
    this.gl.uniform3f(this.u.uOga,oga[0],oga[1],oga[2]);
    this.ogaPos=oga;
    /* Kamerans bas sparas så att himlen kan räknas ut per bildpunkt
       i stället för att ritas som en kupol med tung överritning. */
    const n=v=>{const l=Math.hypot(v[0],v[1],v[2])||1;return [v[0]/l,v[1]/l,v[2]/l];};
    const fwd=n([mal[0]-oga[0],mal[1]-oga[1],mal[2]-oga[2]]);
    const hj=n([fwd[2],0,-fwd[0]]);
    const upp=[hj[1]*fwd[2]-hj[2]*fwd[1], hj[2]*fwd[0]-hj[0]*fwd[2],
               hj[0]*fwd[1]-hj[1]*fwd[0]];
    this.kamBas={fwd, hj, upp, tanF:Math.tan(f/2), asp};
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
  /* Skuggan: samma nät plattat ner i marken längs solens riktning,
     lagt flera gånger i en liten ring så att kanten blir mjuk i
     stället för knivskarp. Färgad, aldrig svart. */
  skugga(nat,modell,markY){
    if(!nat||!this.ljus)return;
    const gl=this.gl, L=this.ljus;
    const y0=(markY||0)+0.055;
    const mj=L.skuggMjukhet===undefined?0.06:L.skuggMjukhet;
    const alfa=L.skuggAlfa===undefined?0.22:L.skuggAlfa;
    const ton=L.skuggFarg||"#000000";
    gl.enable(gl.BLEND);gl.depthMask(false);gl.disable(gl.CULL_FACE);
    /* ringen: två avtryck runt mitten, vart och ett svagare */
    const ring=[[0,0],[mj,mj*0.55],[-mj,-mj*0.55]];
    const vikt=[0.50,0.25,0.25];
    for(let i=0;i<ring.length;i++){
      const sm=M4.skugga(L.sol,y0);
      const m=M4.mul(M4.translation(ring[i][0],0,ring[i][1]),M4.mul(sm,modell));
      this.rita(nat,m,{platt:true,alfa:alfa*vikt[i],ton});
    }
    gl.enable(gl.CULL_FACE);gl.depthMask(true);gl.disable(gl.BLEND);
  },
};

/* ══════════════════════════════════════════════════════════════════
   EFTERBEHANDLING — glöd och mättnad.
   Scenen renderas till en textur. Ur den plockas de ljusaste
   partierna ut, suddas i två pass på fjärdedels upplösning och läggs
   tillbaka ovanpå. Sist höjs mättnaden och exponeringen. Det är det
   som gör skillnaden mellan platt geometri och en solig dag.
   ══════════════════════════════════════════════════════════════════ */
const POST_VS=`
  attribute vec2 aP; varying vec2 vT;
  void main(){ vT=aP*0.5+0.5; gl_Position=vec4(aP,0.0,1.0); }`;
const POST_LJUS=`
  precision mediump float; varying vec2 vT;
  uniform sampler2D uTex; uniform float uTroskel;
  void main(){
    vec3 c=texture2D(uTex,vT).rgb;
    float l=dot(c,vec3(0.299,0.587,0.114));
    float k=max(l-uTroskel,0.0)/max(1.0-uTroskel,0.001);
    gl_FragColor=vec4(c*k*k,1.0);
  }`;
const POST_SUDD=`
  precision mediump float; varying vec2 vT;
  uniform sampler2D uTex; uniform vec2 uSteg;
  void main(){
    vec3 s=texture2D(uTex,vT).rgb*0.227027;
    s+=texture2D(uTex,vT+uSteg*1.3846).rgb*0.316216;
    s+=texture2D(uTex,vT-uSteg*1.3846).rgb*0.316216;
    s+=texture2D(uTex,vT+uSteg*3.2308).rgb*0.070270;
    s+=texture2D(uTex,vT-uSteg*3.2308).rgb*0.070270;
    gl_FragColor=vec4(s,1.0);
  }`;
const POST_KOMP=`
  precision mediump float; varying vec2 vT;
  uniform sampler2D uScen, uGlod;
  uniform float uBloom, uMattnad, uExponering;
  void main(){
    vec3 c=texture2D(uScen,vT).rgb;
    c+=texture2D(uGlod,vT).rgb*uBloom;
    c*=uExponering;
    float l=dot(c,vec3(0.299,0.587,0.114));
    c=mix(vec3(l),c,uMattnad);
    // mjuk knä mot vitt så att glöden inte klipper
    c=c/(1.0+max(c-1.0,0.0)*0.65);
    gl_FragColor=vec4(clamp(c,0.0,1.0),1.0);
  }`;

GL._mal=function(w,h){
  const gl=this.gl;
  const t=gl.createTexture();
  gl.bindTexture(gl.TEXTURE_2D,t);
  gl.texImage2D(gl.TEXTURE_2D,0,gl.RGBA,w,h,0,gl.RGBA,gl.UNSIGNED_BYTE,null);
  gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MIN_FILTER,gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_MAG_FILTER,gl.LINEAR);
  gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_S,gl.CLAMP_TO_EDGE);
  gl.texParameteri(gl.TEXTURE_2D,gl.TEXTURE_WRAP_T,gl.CLAMP_TO_EDGE);
  const f=gl.createFramebuffer();
  gl.bindFramebuffer(gl.FRAMEBUFFER,f);
  gl.framebufferTexture2D(gl.FRAMEBUFFER,gl.COLOR_ATTACHMENT0,gl.TEXTURE_2D,t,0);
  return {tex:t, fb:f};
};

/* Bygger målen en gång per storlek. Returnerar false om kortet inte
   klarar det — då ritas scenen rakt på skärmen som förut. */
GL._post=function(w,h){
  if(this._postTrasig)return false;
  const gl=this.gl;
  const p=this.post;
  if(p&&p.w===w&&p.h===h)return true;
  try{
    if(p){
      for(const m of [p.scen,p.ljus1,p.ljus2]){gl.deleteTexture(m.tex);gl.deleteFramebuffer(m.fb);}
      gl.deleteRenderbuffer(p.djup);
    }
    const bw=Math.max(1,w>>2), bh=Math.max(1,h>>2);
    const scen=this._mal(w,h), ljus1=this._mal(bw,bh), ljus2=this._mal(bw,bh);
    const djup=gl.createRenderbuffer();
    gl.bindRenderbuffer(gl.RENDERBUFFER,djup);
    gl.renderbufferStorage(gl.RENDERBUFFER,gl.DEPTH_COMPONENT16,w,h);
    gl.bindFramebuffer(gl.FRAMEBUFFER,scen.fb);
    gl.framebufferRenderbuffer(gl.FRAMEBUFFER,gl.DEPTH_ATTACHMENT,gl.RENDERBUFFER,djup);
    if(gl.checkFramebufferStatus(gl.FRAMEBUFFER)!==gl.FRAMEBUFFER_COMPLETE)
      throw new Error("ofullständig framebuffer");
    if(!this.kvad){
      this.kvad=gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER,this.kvad);
      gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1, 3,-1, -1,3]),gl.STATIC_DRAW);
      this.pLjus=this._program(POST_VS,POST_LJUS);
      this.pSudd=this._program(POST_VS,POST_SUDD);
      this.pKomp=this._program(POST_VS,POST_KOMP);
      if(!this.pLjus||!this.pSudd||!this.pKomp)throw new Error("postshader");
    }
    this.post={w,h,bw,bh,scen,ljus1,ljus2,djup,
      scenFB:scen.fb, scenTex:scen.tex};
    gl.bindFramebuffer(gl.FRAMEBUFFER,null);
    return true;
  }catch(e){
    console.warn("efterbehandling av:",e.message);
    this._postTrasig=true; this.post=null;
    gl.bindFramebuffer(gl.FRAMEBUFFER,null);
    return false;
  }
};

/* Kallas när bildrutans geometri är ritad. Löser upp scenen till
   skärmen med glöd och mättnad. */
GL.efter=function(){
  if(!this._postRedo||!this.post)return;
  const gl=this.gl, p=this.post, L=this.ljus||{};
  const ritaKvad=()=>{
    gl.bindBuffer(gl.ARRAY_BUFFER,this.kvad);
    const a=gl.getAttribLocation(gl.getParameter(gl.CURRENT_PROGRAM),"aP");
    gl.enableVertexAttribArray(a);
    gl.vertexAttribPointer(a,2,gl.FLOAT,false,0,0);
    gl.drawArrays(gl.TRIANGLES,0,3);
  };
  gl.disable(gl.DEPTH_TEST); gl.disable(gl.CULL_FACE); gl.disable(gl.BLEND);
  gl.activeTexture(gl.TEXTURE0);

  /* 1. Plocka ut det ljusa. */
  gl.bindFramebuffer(gl.FRAMEBUFFER,p.ljus1.fb);
  gl.viewport(0,0,p.bw,p.bh);
  gl.useProgram(this.pLjus);
  gl.uniform1i(gl.getUniformLocation(this.pLjus,"uTex"),0);
  gl.uniform1f(gl.getUniformLocation(this.pLjus,"uTroskel"),
    L.bloomTroskel===undefined?0.78:L.bloomTroskel);
  gl.bindTexture(gl.TEXTURE_2D,p.scen.tex); ritaKvad();

  /* 2. Sudda i två pass. */
  gl.useProgram(this.pSudd);
  gl.uniform1i(gl.getUniformLocation(this.pSudd,"uTex"),0);
  for(const [fran,till,sx,sy] of
      [[p.ljus1,p.ljus2,1/p.bw,0],[p.ljus2,p.ljus1,0,1/p.bh]]){
    gl.bindFramebuffer(gl.FRAMEBUFFER,till.fb);
    gl.uniform2f(gl.getUniformLocation(this.pSudd,"uSteg"),sx,sy);
    gl.bindTexture(gl.TEXTURE_2D,fran.tex); ritaKvad();
  }

  /* 3. Lägg ihop och lyft mättnaden. */
  gl.bindFramebuffer(gl.FRAMEBUFFER,null);
  gl.viewport(0,0,p.w,p.h);
  gl.useProgram(this.pKomp);
  gl.uniform1i(gl.getUniformLocation(this.pKomp,"uScen"),0);
  gl.uniform1i(gl.getUniformLocation(this.pKomp,"uGlod"),1);
  gl.uniform1f(gl.getUniformLocation(this.pKomp,"uBloom"),
    L.bloomStyrka===undefined?0.35:L.bloomStyrka);
  gl.uniform1f(gl.getUniformLocation(this.pKomp,"uMattnad"),
    L.mattnad===undefined?1.2:L.mattnad);
  gl.uniform1f(gl.getUniformLocation(this.pKomp,"uExponering"),
    L.exponering===undefined?1.05:L.exponering);
  gl.activeTexture(gl.TEXTURE1); gl.bindTexture(gl.TEXTURE_2D,p.ljus1.tex);
  gl.activeTexture(gl.TEXTURE0); gl.bindTexture(gl.TEXTURE_2D,p.scen.tex);
  ritaKvad();

  gl.enable(gl.DEPTH_TEST); gl.enable(gl.CULL_FACE);
  gl.useProgram(this.prog);
};


/* ══════════════════════════════════════════════════════════════════
   HIMLEN — en enda helskärmsritning i stället för en kupol.
   En kupol av band ritar över samma bildpunkter tolv gånger om; här
   räknas riktningen ut per bildpunkt och färgen läggs en gång. Solen
   och dess gloria räknas analytiskt i samma pass.
   ══════════════════════════════════════════════════════════════════ */
const HIMMEL_FS=`
  precision mediump float; varying vec2 vT;
  uniform vec3 uFwd, uHoger, uUpp, uSol;
  uniform vec3 uTopp, uMitt, uBotten, uSkiva, uGloria;
  uniform float uTanF, uAsp;
  void main(){
    vec2 s=vT*2.0-1.0;
    vec3 d=normalize(uFwd + uHoger*(s.x*uTanF*uAsp) + uUpp*(s.y*uTanF));
    float h=clamp(d.y,0.0,1.0);
    // två steg: ljust vid horisonten, klart blått i zenit
    vec3 himmel = h<0.30
      ? mix(uBotten,uMitt,h/0.30)
      : mix(uMitt,uTopp,clamp((h-0.30)/0.70,0.0,1.0));
    // under horisonten fortsätter horisontfärgen, aldrig grått
    himmel = mix(uBotten, himmel, smoothstep(-0.12,0.02,d.y));
    float sd=max(dot(d,normalize(uSol)),0.0);
    himmel += uGloria*pow(sd,26.0)*0.55;          // gloria runt solen
    himmel += uSkiva*smoothstep(0.9975,0.9990,sd); // skivan
    gl_FragColor=vec4(himmel,1.0);
  }`;

GL.himmel=function(ljus){
  const gl=this.gl, b=this.kamBas;
  if(!b)return;
  if(!this.pHimmel){
    if(!this.kvad){
      this.kvad=gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER,this.kvad);
      gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1, 3,-1, -1,3]),gl.STATIC_DRAW);
    }
    this.pHimmel=this._program(POST_VS,HIMMEL_FS);
    if(!this.pHimmel)return;
  }
  const P=this.pHimmel, U=n=>gl.getUniformLocation(P,n);
  gl.useProgram(P);
  gl.disable(gl.DEPTH_TEST); gl.disable(gl.CULL_FACE); gl.disable(gl.BLEND);
  gl.uniform3fv(U("uFwd"),b.fwd); gl.uniform3fv(U("uHoger"),b.hj);
  gl.uniform3fv(U("uUpp"),b.upp); gl.uniform1f(U("uTanF"),b.tanF);
  gl.uniform1f(U("uAsp"),b.asp);
  const sl=Math.hypot(ljus.sol[0],ljus.sol[1],ljus.sol[2])||1;
  gl.uniform3f(U("uSol"),ljus.sol[0]/sl,ljus.sol[1]/sl,ljus.sol[2]/sl);
  gl.uniform3fv(U("uTopp"),glFarg(ljus.himmelTopp));
  gl.uniform3fv(U("uMitt"),glFarg(ljus.himmelMitt||ljus.himmelTopp));
  gl.uniform3fv(U("uBotten"),glFarg(ljus.himmelBotten));
  gl.uniform3fv(U("uSkiva"),glFarg(ljus.solskiva||"#FFF6C9"));
  gl.uniform3fv(U("uGloria"),glFarg(ljus.solGloria||"#FFE070"));
  gl.bindBuffer(gl.ARRAY_BUFFER,this.kvad);
  const a=gl.getAttribLocation(P,"aP");
  gl.enableVertexAttribArray(a); gl.vertexAttribPointer(a,2,gl.FLOAT,false,0,0);
  gl.drawArrays(gl.TRIANGLES,0,3);
  gl.enable(gl.DEPTH_TEST); gl.enable(gl.CULL_FACE);
  gl.useProgram(this.prog);
};

/* Textur ur en ritfunktion — allt är målat i spelet, inga bildfiler. */
function glCanvasTex(bredd,hojd,rita,upprepa){
  const c=document.createElement("canvas");
  c.width=bredd;c.height=hojd;
  rita(c.getContext("2d"),bredd,hojd);
  return GL.textur(c,upprepa);
}

