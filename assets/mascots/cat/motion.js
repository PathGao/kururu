'use strict';
const $=s=>document.querySelector(s),clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const reduced=matchMedia('(prefers-reduced-motion: reduce)');
const reduceActive=()=>reduced.matches&&!$('#fullMotion').checked;
const channels={x:0,y:0,roll:0,yaw:0,squash:1,earL:0,earR:0,gx:0,gy:0,lid:1,mood:0,wide:1};
const springs=Object.fromEntries(Object.entries(channels).map(([k,x])=>[k,{x,v:0,t:x}]));
let mode='idle',modeAt=0,time=0,last=0,raf=0,paused=false,drag=null,trick=null,blinkAt=2.5,nextLook=0,look=[0,0],cycleAt=0,frames=0;
const names={idle:'安静',curious:'好奇',thinking:'思考',searching:'寻找',happy:'开心',sleeping:'打瞌睡',surprised:'惊讶',suspicious:'怀疑'};
const modes=Object.keys(names);
const svgMarkup=`<svg viewBox="-120 -130 240 260" role="img" aria-label="连续形变猫头"><defs><clipPath id="catFaceClip"><path/></clipPath></defs><ellipse class="shadow" cy="91" rx="51" ry="6"/><g class="head"><path class="body"/><g class="face" clip-path="url(#catFaceClip)"><path class="eye left"/><path class="eye right"/><path class="nose" d="M-3 22 Q0 20 3 22 L0 25Z"/></g></g></svg>`;
for(const [i,el] of [...document.querySelectorAll('.cat')].entries())el.innerHTML=svgMarkup.replaceAll('catFaceClip','catFaceClip'+i);
const cats=[...document.querySelectorAll('.cat')].map(el=>({el,head:el.querySelector('.head'),body:el.querySelector('.body'),clip:el.querySelector('clipPath path'),eyes:[el.querySelector('.left'),el.querySelector('.right')],nose:el.querySelector('.nose'),shadow:el.querySelector('.shadow')}));
function setMode(m){if(!names[m])return;mode=m;modeAt=time;nextLook=0;$('#state').textContent=names[m];document.querySelectorAll('[data-mode]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.mode===m)));wake()}
function kick(kind){trick={kind,at:time};wake()}
function wake(){if(!paused&&!document.hidden&&!raf){last=performance.now();raf=requestAnimationFrame(tick)}}
function targets(t){const age=t-modeAt;const a={...channels};a.y=Math.sin(t*1.7)*1.3;a.roll=Math.sin(t*.8)*1.7;a.squash=1+Math.sin(t*1.7)*.009;
if(t>nextLook){const amp=mode==='searching'?20:mode==='curious'?12:5;look=[(Math.random()*2-1)*amp,(Math.random()*2-1)*6];nextLook=t+(mode==='searching'?.55:1.6)+Math.random()*1.4}
a.gx=look[0];a.gy=look[1];
switch(mode){case'curious':a.roll=12+Math.sin(t*1.4)*5;a.yaw=.2;a.wide=1.12;a.earL=-9;a.earR=7;break;case'thinking':a.roll=-12+Math.sin(t*.8)*4;a.gx=-13;a.gy=-9;a.mood=1.4;a.earR=-12;break;case'searching':a.yaw=Math.sin(t*2)*.55;a.roll=Math.sin(t*2)*8;a.x=Math.sin(t*2)*7;a.wide=1.12;break;case'happy':a.mood=3;a.y=-Math.abs(Math.sin(t*3))*9;a.squash=1+Math.sin(t*6)*.045;a.roll=Math.sin(t*2)*5;a.earL=8;a.earR=8;break;case'sleeping':{const nod=(Math.sin(t*1.3)+1)/2;a.y=9+nod*10;a.roll=8+nod*7;a.lid=.16;a.mood=2;a.squash=.96+Math.sin(t*1.2)*.025;a.earL=-14;a.earR=-14;a.gy=6;break}case'surprised':a.wide=1.4;a.y=-8*Math.exp(-age);a.squash=1.08;a.earL=12;a.earR=12;break;case'suspicious':a.mood=1;a.roll=-9;a.gx=16;a.lid=.65;a.earL=-10;break;}
if($('#follow').checked&&pointer.inside&&!drag){a.gx=pointer.x*16;a.gy=pointer.y*10;a.yaw=pointer.x*.5;a.roll+=pointer.x*5;a.earL+=pointer.x*4;a.earR-=pointer.x*4}
if(t>=blinkAt&&t<blinkAt+.095)a.lid=.045;else if(t>=blinkAt+.095&&t<blinkAt+.19)a.lid=1.1;else if(t>blinkAt+.3)blinkAt=t+2.1+Math.random()*3;
if(trick){const u=t-trick.at;if(trick.kind==='hop'){let cursor=0;const stages=[[38,.5],[19,.35],[8,.25]];a.mood=3;for(const [h,d]of stages){if(u>=cursor&&u<cursor+d){const q=(u-cursor)/d;a.y-=4*h*q*(1-q);a.squash=q<.12?.78:1+Math.sin(q*Math.PI*2)*.14;break}cursor+=d}if(u>1.4)trick=null}else if(trick.kind==='spin'){const q=clamp(u/1.25,0,1),ease=q*q*(3-2*q);a.yaw=ease*Math.PI*2;a.y-=Math.sin(q*Math.PI)*13;a.squash=1+Math.sin(q*Math.PI*2)*.1;if(u>1.9){springs.yaw.x-=Math.PI*2;springs.yaw.t-=Math.PI*2;trick=null}}else if(trick.kind==='blink'){a.lid=u<.12?.04:1;if(u>.5)trick=null}}
if(drag){a.x=drag.x;a.y=drag.y;a.roll=clamp(drag.x*.23,-25,25);a.squash=1+clamp(-drag.y/330,-.18,.27);a.earL=-10;a.earR=-10;a.wide=1.2}
if(reduceActive()){Object.assign(a,channels);a.mood=mode==='happy'?3:mode==='sleeping'?2:0;a.lid=mode==='sleeping'?.15:1}
return a}
function step(dt,a){const n=Math.max(1,Math.ceil(dt*180)),h=dt/n;for(const[k,s]of Object.entries(springs)){s.t=a[k];const w=k.startsWith('ear')?15:k==='lid'?42:k==='mood'?15:k==='gx'||k==='gy'?23:18;const d=k.startsWith('ear')?.48:k==='squash'?.48:.7;for(let i=0;i<n;i++){s.v+=(-w*w*(s.x-s.t)-2*d*w*s.v)*h;s.x+=s.v*h}if(reduceActive()){s.x=s.t;s.v=0}}}
function path(points){return'M'+points.map(p=>p.map(n=>n.toFixed(2)).join(',')).join('L')+'Z'}
function wrap(a){return Math.atan2(Math.sin(a),Math.cos(a))}
function silhouette(s){const pts=[];for(let i=0;i<160;i++){const a=i/160*Math.PI*2;const ear1=Math.exp(-Math.pow(wrap(a+2.28)/.16,2)),ear2=Math.exp(-Math.pow(wrap(a+.86)/.16,2));const r=65+(29+s.earL)*ear1+(29+s.earR)*ear2;const cheek=1+.06*Math.sin(a);const width=.88+.12*Math.abs(Math.cos(s.yaw));pts.push([Math.cos(a)*r*cheek*width,Math.sin(a)*r*.84]);}return path(pts)}
function eyePoints(kind){const pts=[];for(let i=0;i<48;i++){const a=i/48*Math.PI*2,c=Math.cos(a),s=Math.sin(a);let x,y;if(kind===0){x=Math.sign(c)*Math.pow(Math.abs(c),.65)*8;y=Math.sign(s)*Math.pow(Math.abs(s),.65)*16}else if(kind===1){x=c*11;y=s*7+x*.28}else if(kind===2){x=c*12;y=s*3+(x*x/70)}else{x=c*13;y=s*3-7*(1-(x/13)**2)}pts.push([x,y])}return pts}
const eyeShapes=[0,1,2,3].map(eyePoints);
function paint(){const s=Object.fromEntries(Object.entries(springs).map(([k,v])=>[k,v.x]));const squash=clamp(s.squash,.6,1.5),m=clamp(s.mood,0,3),lo=Math.floor(m),hi=Math.min(3,lo+1),f=m-lo;
for(const cat of cats){cat.head.setAttribute('transform',`translate(${s.x} ${s.y}) rotate(${s.roll}) scale(${1/squash} ${squash})`);cat.body.setAttribute('d',silhouette(s));cat.clip.setAttribute('d',silhouette(s));cat.shadow.setAttribute('rx',String(clamp(51+s.y*.25,24,70)));cat.shadow.style.opacity=String(clamp(.1+s.y*.001,.03,.18));
cat.eyes.forEach((el,i)=>{const side=i===0?-1:1,angle=side*.36+s.yaw,depth=Math.cos(angle),rawX=Math.sin(angle)*43+s.gx*.25,rawY=s.gy*.6;const points=eyeShapes[lo].map((p,j)=>{let px=p[0]*(1-f)+eyeShapes[hi][j][0]*f,py=p[1]*(1-f)+eyeShapes[hi][j][1]*f;return[px*s.wide*clamp(depth,.02,1.1),py*clamp(s.lid,.035,1.3)*s.wide]});const rad=clamp(side*wrap(s.yaw)*7,-8,8)*Math.PI/180,rotated=points.map(p=>[p[0]*Math.cos(rad)-p[1]*Math.sin(rad),p[0]*Math.sin(rad)+p[1]*Math.cos(rad)]),rx=Math.max(...rotated.map(p=>Math.abs(p[0]))),ry=Math.max(...rotated.map(p=>Math.abs(p[1]))),x=clamp(rawX,-46+rx,46-rx),y=clamp(rawY,-27+ry,27-ry);el.setAttribute('d',path(rotated));el.setAttribute('transform',`translate(${x} ${y})`);el.style.opacity=String(clamp(depth*5,0,1));});cat.nose.setAttribute('transform',`translate(${Math.sin(s.yaw)*39+s.gx*.15} ${s.gy*.45})`);cat.nose.style.opacity=String(clamp(Math.cos(s.yaw)*4,0,1));}
frames++;}
function tick(now){raf=0;if(paused||document.hidden)return;const dt=clamp((now-last)/1000,0,.05);last=now;time+=dt;if($('#auto').checked&&time>cycleAt){setMode(modes[(modes.indexOf(mode)+1)%modes.length]);cycleAt=time+3.8}step(dt,targets(time));paint();if(!reduceActive()&&!raf)raf=requestAnimationFrame(tick)}
const pointer={inside:false,x:0,y:0},stage=$('#stage');
stage.addEventListener('pointermove',e=>{const r=stage.getBoundingClientRect();pointer.inside=true;pointer.x=clamp((e.clientX-r.left-r.width/2)/(r.width*.4),-1,1);pointer.y=clamp((e.clientY-r.top-r.height/2)/(r.height*.4),-1,1);if(drag){drag.x=clamp((e.clientX-drag.startX)*.6,-75,75);drag.y=clamp((e.clientY-drag.startY)*.6,-65,50)}wake()});
stage.addEventListener('pointerleave',()=>{pointer.inside=false});
$('#hero').addEventListener('pointerdown',e=>{if(reduceActive())return;drag={startX:e.clientX,startY:e.clientY,x:0,y:0};$('#hero').setPointerCapture(e.pointerId);wake()});
function release(){if(!drag)return;drag=null;springs.earL.v+=70;springs.earR.v-=60;wake()}
$('#hero').addEventListener('pointerup',release);$('#hero').addEventListener('pointercancel',release);
for(const b of document.querySelectorAll('[data-mode]'))b.onclick=()=>{$('#auto').checked=false;setMode(b.dataset.mode)};
for(const b of document.querySelectorAll('[data-trick]'))b.onclick=()=>kick(b.dataset.trick);
$('#auto').onchange=()=>{cycleAt=time+3.8;wake()};$('#follow').onchange=wake;
$('#pause').onclick=()=>{paused=!paused;$('#pause').textContent=paused?'继续播放':'暂停';if(paused){cancelAnimationFrame(raf);raf=0}else wake()};
$('#theme').onclick=()=>document.body.classList.toggle('dark');
document.addEventListener('visibilitychange',()=>{if(document.hidden){cancelAnimationFrame(raf);raf=0;drag=null}else wake()});reduced.addEventListener('change',()=>{cancelAnimationFrame(raf);raf=0;wake()});
window.motionDebug=()=>({mode,frames,paused,raf,drag:!!drag,finite:Object.values(springs).every(s=>Number.isFinite(s.x)&&Number.isFinite(s.v)),time});
$('#fullMotion').onchange=()=>{cancelAnimationFrame(raf);raf=0;wake()};
$('#reducedNote').hidden=!reduced.matches;
setMode('idle');cycleAt=3.8;paint();wake();
