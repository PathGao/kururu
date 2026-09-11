'use strict';
const $=s=>document.querySelector(s),clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
let renderedMeshes=[],currentWebPath='';
const reduced=matchMedia('(prefers-reduced-motion: reduce)');
const reduceActive=()=>reduced.matches&&!$('#fullMotion').checked;
const channels={x:0,y:0,roll:0,yaw:0,squash:1,earL:0,earR:0,gx:0,gy:0,lid:1,mood:0,wide:1};
for(let i=0;i<8;i++)channels['arm'+i]=0;
const springs=Object.fromEntries(Object.entries(channels).map(([k,x])=>[k,{x,v:0,t:x}]));
let mode='idle',modeAt=0,time=0,last=0,raf=0,paused=false,drag=null,blinkAt=2.5,nextLook=0,look=[0,0],cycleAt=0,frames=0;
const names={idle:'安静',happy:'开心',searching:'寻找'};
const modes=Object.keys(names);
const armMarkup=i=>`<g class="limb" data-arm="${i}"><path class="arm"/><path class="ventral"/></g>`;
const svgMarkup=`<svg viewBox="-145 -125 290 270" role="img" aria-label="具有圆润头部和渐细腕足的章鱼"><defs><linearGradient id="skin" gradientUnits="userSpaceOnUse" x1="-60" y1="-90" x2="85" y2="120"><stop stop-color="#555861"/><stop offset=".5" stop-color="#303239"/><stop offset="1" stop-color="#191b20"/></linearGradient><clipPath id="faceClip"><path class="faceClipPath"/></clipPath></defs><ellipse class="shadow" cy="122" rx="64" ry="5"/><g class="head"><g class="rear">${[0,1,2,3].map(armMarkup).join('')}</g><path class="web" fill="url(#skin)"/><path class="body" transform="matrix(1.28 0 0 1.10 0 -1.6)"/><g class="face" transform="matrix(1.28 0 0 1.10 0 -1.6)" clip-path="url(#faceClip)"><path class="eye left"/><path class="eye right"/></g><g class="front">${[4,5,6,7].map(armMarkup).join('')}</g></g></svg>`;
for(const [i,el] of [...document.querySelectorAll('.cat')].entries())el.innerHTML=svgMarkup.replaceAll('faceClip','faceClip'+i);
const cats=[...document.querySelectorAll('.cat')].map(el=>({el,head:el.querySelector('.head'),body:el.querySelector('.body'),web:el.querySelector('.web'),clip:el.querySelector('clipPath path'),arms:[...el.querySelectorAll('.limb')],eyes:[el.querySelector('.left'),el.querySelector('.right')],shadow:el.querySelector('.shadow')}));
function setMode(m){if(!names[m])return;mode=m;modeAt=time;nextLook=0;$('#state').textContent=names[m];document.querySelectorAll('[data-mode]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.mode===m)));actionLabel();wake()}
function kick(kind){if(kind==='load'){setLoad(!loadOn);return;}if(loadOn)setLoad(false);action={kind,at:time};$('#auto').checked=false;actionLabel();wake()}
function wake(){if(!paused&&!document.hidden&&!raf){last=performance.now();raf=requestAnimationFrame(tick)}}
function targets(t){const a={...channels};a.y=Math.sin(t*1.7)*1.3;a.roll=Math.sin(t*.8)*1.7;a.squash=1+Math.sin(t*1.7)*.009;
if(t>nextLook){const amp=5;look=[(Math.random()*2-1)*amp,(Math.random()*2-1)*6];nextLook=t+(mode==='searching'?.55:1.6)+Math.random()*1.4}
a.gx=look[0];a.gy=look[1];
switch(mode){case'searching':{const scan=scanDirection(t);a.yaw=scan*.38;a.roll=scan*5;a.x=scan*4;a.gx=scan*13;a.gy=3;a.wide=1.06;break;}case'happy':a.mood=3;a.y=-Math.abs(Math.sin(t*3))*7;a.squash=1+Math.sin(t*6)*.035;a.roll=Math.sin(t*2)*4;break;}
if($('#follow').checked&&pointer.inside&&!drag&&mode!=='searching'){a.gx=pointer.x*16;a.gy=pointer.y*10;a.yaw=pointer.x*.5;a.roll+=pointer.x*5;a.earL+=pointer.x*4;a.earR-=pointer.x*4}
if(t>=blinkAt&&t<blinkAt+.095)a.lid=.045;else if(t>=blinkAt+.095&&t<blinkAt+.19)a.lid=1.1;else if(t>blinkAt+.3)blinkAt=t+2.1+Math.random()*3;
if(drag){a.x=drag.x;a.y=drag.y;a.roll=clamp(drag.x*.23,-25,25);a.squash=1+clamp(-drag.y/330,-.18,.27);a.earL=-10;a.earR=-10;a.wide=1.2}
if(action){const w=actionAmount();if(action.kind==='scratch'){a.roll-=w*5;a.gx=8*w;a.gy=-8*w;a.mood=1.1*w;}if(action.kind==='hide'){a.lid=1-w*.92;a.gx=0;a.gy=0;a.yaw=0;a.roll+=w*4;}if(action.kind==='rest'){a.lid=1-w*.87;a.y+=w*6;a.mood=w*2;}}
if(reduceActive()){Object.assign(a,channels);a.mood=mode==='happy'?3:0;a.lid=1}
for(let i=0;i<8;i++){const lively=mode==='happy'?1.7:1; a['arm'+i]=reduceActive()?0:Math.sin(t*2.7-i*.62)*8*lively+(squashArm(a.squash))*(i%2?1:-1)+clamp(springs.y.v*.1,-15,15)+clamp(springs.x.v*.06,-10,10)*(i<4?-1:1);}
return a}
function squashArm(s){return (1-s)*65}
function step(dt,a){const n=Math.max(1,Math.ceil(dt*180)),h=dt/n;for(const[k,s]of Object.entries(springs)){s.t=a[k];const w=k.startsWith('arm')?10+Number(k.slice(3))*.7:k.startsWith('ear')?15:k==='lid'?42:k==='mood'?15:k==='gx'||k==='gy'?23:18;const d=k.startsWith('arm')?.42:k.startsWith('ear')?.48:k==='squash'?.48:.7;for(let i=0;i<n;i++){s.v+=(-w*w*(s.x-s.t)-2*d*w*s.v)*h;s.x+=s.v*h}if(reduceActive()){s.x=s.t;s.v=0}}}
function path(points){return'M'+points.map(p=>p.map(n=>n.toFixed(2)).join(',')).join('L')+'Z'}
function wrap(a){return Math.atan2(Math.sin(a),Math.cos(a))}
function silhouette(s){return 'M-34 16 C-38 0 -51 -20 -46 -45 C-41 -72 -21 -84 4 -82 C34 -81 50 -61 47 -36 C45 -12 35 0 34 17 C32 30 17 38 0 38 C-17 38 -31 30 -34 16Z'}
function eyePoints(kind){const pts=[];for(let i=0;i<48;i++){const a=i/48*Math.PI*2,c=Math.cos(a),s=Math.sin(a);let x,y;if(kind===0){x=Math.sign(c)*Math.pow(Math.abs(c),.65)*8;y=Math.sign(s)*Math.pow(Math.abs(s),.65)*16}else if(kind===1){x=c*11;y=s*7+x*.28}else if(kind===2){x=c*12;y=s*3+(x*x/70)}else{x=c*13;y=s*3-7*(1-(x/13)**2)}pts.push([x,y])}return pts}
const eyeShapes=[0,1,2,3].map(eyePoints);
function paint(){const s=Object.fromEntries(Object.entries(springs).map(([k,v])=>[k,v.x]));const squash=clamp(s.squash,.6,1.5),m=clamp(s.mood,0,3),lo=Math.floor(m),hi=Math.min(3,lo+1),f=m-lo;
renderedMeshes=Array.from({length:8},(_,i)=>armMesh(i));currentWebPath=webPath();
for(const cat of cats){cat.head.setAttribute('transform',`translate(${s.x} ${s.y}) rotate(${s.roll*(1-inversion)+180*inversion} 0 15) scale(${1/squash} ${squash})`);cat.body.setAttribute('d',silhouette(s));cat.clip.setAttribute('d',silhouette(s));paintArms(cat,s);cat.shadow.setAttribute('rx',String(clamp(51+s.y*.25,24,70)));cat.shadow.style.opacity=String(clamp(.1+s.y*.001,.03,.18));
const eyeData=cat.eyes.map((el,i)=>{const side=i===0?-1:1,angle=side*.36+clamp(s.yaw,-.65,.65),depth=Math.cos(angle),rad=clamp(side*s.yaw*7,-8,8)*Math.PI/180;
 let pts=eyeShapes[lo].map((p,j)=>{const px=(p[0]*(1-f)+eyeShapes[hi][j][0]*f)*s.wide*clamp(depth,.45,1),py=(p[1]*(1-f)+eyeShapes[hi][j][1]*f)*clamp(s.lid,.035,1.3)*s.wide;return[px*Math.cos(rad)-py*Math.sin(rad),px*Math.sin(rad)+py*Math.cos(rad)]});
 const rawRadius=Math.max(...pts.map(p=>Math.abs(p[0]))),scale=Math.min(1,12.5/rawRadius);pts=pts.map(p=>[p[0]*scale,p[1]]);return {el,pts,rx:rawRadius*scale,ry:Math.max(...pts.map(p=>Math.abs(p[1])))};});
 // Fit the eye pair together: preserve a gap while constraining the full silhouette.
 const [l,r]=eyeData,gap=Math.min(20,62-2*(l.rx+r.rx)),left=-gap/2-l.rx,right=gap/2+r.rx;
 const gaze=clamp(Math.sin(s.yaw)*10+s.gx*.35,-33-left+l.rx,33-right-r.rx);
 eyeData.forEach((e,i)=>{const x=(i?right:left)+gaze,y=clamp(-16+s.gy*.6,-49+e.ry,5-e.ry);const faceAngle=spinAngle+(i?1:-1)*.48,depth=Math.cos(faceAngle),rotX=Math.sin(faceAngle)*37,projected=e.pts.map(p=>[p[0]*mix(1,Math.max(.02,depth),inversion),p[1]]);e.el.setAttribute('d',path(projected));e.el.setAttribute('transform',`translate(${mix(x,rotX,inversion)} ${y})`);e.el.style.opacity=String(mix(1,clamp(depth*5,0,1),inversion));});}

frames++;}
function tick(now){raf=0;if(paused||document.hidden)return;const dt=clamp((now-last)/1000,0,.05);last=now;time+=dt;if($('#auto').checked&&time>cycleAt){const seq=['idle','happy','searching','scratch','hide','rest','load'],next=seq[autoIndex++%seq.length];if(loadOn)setLoad(false);action=null;if(names[next]){setMode(next);actionLabel()}else{setMode('idle');kick(next)}$('#auto').checked=true;cycleAt=time+8}step(dt,targets(time));stepArms(dt);paint();if(!reduceActive()&&!raf)raf=requestAnimationFrame(tick)}
const pointer={inside:false,x:0,y:0},stage=$('#stage');
stage.addEventListener('pointermove',e=>{const r=stage.getBoundingClientRect();pointer.inside=true;pointer.x=clamp((e.clientX-r.left-r.width/2)/(r.width*.4),-1,1);pointer.y=clamp((e.clientY-r.top-r.height/2)/(r.height*.4),-1,1);if(drag){drag.x=clamp((e.clientX-drag.startX)*.6,-75,75);drag.y=clamp((e.clientY-drag.startY)*.6,-65,50)}wake()});
stage.addEventListener('pointerleave',()=>{pointer.inside=false});
$('#hero').addEventListener('pointerdown',e=>{if(reduceActive())return;drag={startX:e.clientX,startY:e.clientY,x:0,y:0};$('#hero').setPointerCapture(e.pointerId);wake()});
function release(){if(!drag)return;const tapped=Math.hypot(drag.x,drag.y)<3;drag=null;if(tapped)kick('scratch');springs.earL.v+=70;springs.earR.v-=60;for(let i=0;i<8;i++)springs['arm'+i].v+=(i%2?1:-1)*100;wake()}
$('#hero').addEventListener('pointerup',release);$('#hero').addEventListener('pointercancel',release);
for(const b of document.querySelectorAll('[data-mode]'))b.onclick=()=>{$('#auto').checked=false;if(loadOn)setLoad(false);action=null;actionLabel();setMode(b.dataset.mode)};
for(const b of document.querySelectorAll('[data-trick]'))b.onclick=()=>kick(b.dataset.trick);
$('#auto').onchange=()=>{cycleAt=time+6;wake()};$('#follow').onchange=wake;
$('#pause').onclick=()=>{paused=!paused;$('#pause').textContent=paused?'继续播放':'暂停';if(paused){cancelAnimationFrame(raf);raf=0}else wake()};
$('#webbing').onchange=()=>{paint();wake()};
$('#theme').onclick=()=>document.body.classList.toggle('dark');
document.addEventListener('visibilitychange',()=>{if(document.hidden){cancelAnimationFrame(raf);raf=0;drag=null}else wake()});reduced.addEventListener('change',()=>{cancelAnimationFrame(raf);raf=0;wake()});
window.motionDebug=()=>({mode,frames,paused,raf,drag:!!drag,finite:Object.values(springs).every(s=>Number.isFinite(s.x)&&Number.isFinite(s.v)),time,action:action?.kind||'idle',loadOn,spinVelocity,spinAngle,inversion,armFinite:armNodes.flat().every(p=>Number.isFinite(p.x+p.y+p.vx+p.vy))});
$('#fullMotion').onchange=()=>{cancelAnimationFrame(raf);raf=0;wake()};
$('#reducedNote').hidden=!reduced.matches;
// Eight volumetric arms. Each centerline has independently damped control points.
// These are authored poses with a traveling bend, not a biological dynamics solver.
// Separate the resting tips by height and direction while keeping the central roots close.
const baseArms=[
 [[-14,21],[-39,39],[-61,49],[-80,47],[-93,37],[-96,24],[-91,17],[-83,21]],
 [[14,21],[38,37],[58,43],[79,38],[91,26],[90,16],[82,13],[76,20]],
 [[-14,21],[-36,54],[-55,74],[-76,86],[-90,83],[-95,72],[-90,65],[-83,70]],
 [[14,21],[39,49],[64,65],[88,74],[103,70],[108,60],[105,51],[97,51]],
 [[-14,21],[-17,53],[-25,79],[-37,101],[-51,108],[-60,101],[-56,91],[-48,91]],
 [[14,21],[15,52],[17,78],[24,98],[35,105],[43,99],[42,91],[36,88]],
 [[-14,21],[-33,44],[-49,49],[-60,43],[-64,32],[-59,23],[-51,23],[-47,30]],
 [[14,21],[34,48],[50,72],[62,96],[74,104],[84,98],[82,88],[74,86]]
];
baseArms.forEach(ps=>{ps[0]=[Math.sign(ps[0][0])*14,21]});
const armNodes=baseArms.map(ps=>ps.map(([x,y])=>({x,y,vx:0,vy:0})));
let action=null,autoIndex=0,loadOn=false,spinAngle=0,spinVelocity=0,inversion=0,modeBeforeLoad='idle';
function setLoad(on){loadOn=on;$('#auto').checked=false;$('#loadSpin').setAttribute('aria-pressed',String(on));$('#loadSpin').textContent=on?'卸载并停转':'模拟高负载';if(on){modeBeforeLoad=mode;action=null;setMode('idle')}else setMode(modeBeforeLoad);actionLabel();wake()}

const actionNames={scratch:'挠挠头',hide:'捂脸',rest:'收腕休息'};
function scanDirection(t){return Math.tanh(Math.sin((t-modeAt)*1.12)*1.8)}
function actionLabel(){ $('#actionState').textContent=loadOn?'高负载 · 倒立旋翼':actionNames[action?.kind]||(mode==='searching'?'左右探查':mode==='happy'?'开心':'自在舒展'); }
const mix=(a,b,t)=>a+(b-a)*t;
const smooth=v=>{v=clamp(v,0,1);return v*v*(3-2*v)};
function actionAmount(){if(!action)return 0;const u=time-action.at;return smooth(u/1.1)*(1-smooth((u-4.7)/1.3))}
function desiredArm(i){
 const u=action?time-action.at:0,k=action?.kind;let weight=actionAmount();
 let pts=baseArms[i].map(p=>[...p]),goal=pts.map(p=>[...p]);
 if(k==='scratch'&&i===7){const tap=Math.sin(u*9)*2.6;goal=[[28,19],[51,11],[64,-12],[63,-42],[51,-62],[40+tap,-65],[37+tap,-61],[42+tap,-56]];}
 if(k==='hide'&&(i===6||i===7)){const sign=i===6?-1:1;goal=[[sign*29,19],[sign*30,5],[sign*22,-14],[sign*9,-18],[sign*-3,-22],[sign*-6,-33],[sign*3,-40],[sign*9,-34]];}
 if(mode==='searching'&&!action&&(i===6||i===7)){
 const sign=i===6?-1:1,scan=scanDirection(time),extend=smooth((sign*scan+.15)/1.15);
 const curl=Math.sin(time*2.3-i)*3;
 goal=[[sign*14,21],[sign*39,32],[sign*62,31],[sign*81,21],[sign*96,9],[sign*105,-3],[sign*108,-10+curl],[sign*101,-13+curl]];
 weight=extend*smooth((time-modeAt)/.7);
 }
 if(k==='rest')goal=pts.map(([x,y],j)=>[x*(1-j*.055),j?mix(y,42+j*3,.65):y]);
 return pts.map(([x,y],j)=>{
 if(j===0)return [...baseArms[i][0]];
 const t=j/7,phase=time*.9-i*.8-t*4;
 // A localized bend travels distally; roots remain anchored.
 const center=(time*.23+i*.17)%1.5;
 const wave=Math.exp(-(((t-center)/.23)**2))*Math.sin(time*1.7-i)*2.8;
 const idle=(reduceActive()?0:1)*(k==='rest'?1-weight*.85:1);
 return [mix(x,goal[j][0],weight)+idle*t*(Math.sin(phase)*1.5+wave),mix(y,goal[j][1],weight)+idle*t*Math.cos(phase)*2];
 });
}
function stepArms(dt){
 const angleError=wrap(spinAngle);
 const canUnfoldBack=!loadOn&&spinVelocity<.03&&Math.abs(angleError)<.02;
 const inversionTarget=loadOn?1:canUnfoldBack?0:1;
 inversion=mix(inversion,inversionTarget,1-Math.exp(-dt*4));
 if(inversion<.001&&!loadOn)inversion=0;
 const desiredSpeed=loadOn&&inversion>.95&&!reduceActive()?Math.PI*6:0;
 spinVelocity=mix(spinVelocity,desiredSpeed,1-Math.exp(-dt*(loadOn?2:3)));
 spinAngle+=spinVelocity*dt;
 if(!loadOn&&spinVelocity<.03){spinVelocity=0;spinAngle-=wrap(spinAngle)*(1-Math.exp(-dt*7));}
 if(reduceActive()){spinVelocity=0;spinAngle=0;inversion=0;}

 if(action&&time-action.at>6.2){action=null;actionLabel()}
 for(let i=0;i<8;i++){const ps=desiredArm(i);armNodes[i].forEach((p,j)=>{const n=Math.max(1,Math.ceil(dt*180)),h=dt/n,w=24-j*.85;for(let z=0;z<n;z++){p.vx+=((ps[j][0]-p.x)*w*w-1.65*w*p.vx)*h;p.vy+=((ps[j][1]-p.y)*w*w-1.65*w*p.vy)*h;p.x+=p.vx*h;p.y+=p.vy*h;}if(reduceActive()){p.x=ps[j][0];p.y=ps[j][1];p.vx=p.vy=0;}});}
}
function sampleSpline(ps,t){const v=t*(ps.length-1),j=Math.min(ps.length-2,Math.floor(v)),u=v-j,a=ps[Math.max(0,j-1)],b=ps[j],c=ps[j+1],d=ps[Math.min(ps.length-1,j+2)];return ['x','y'].map(k=>.5*((2*b[k])+(-a[k]+c[k])*u+(2*a[k]-5*b[k]+4*c[k]-d[k])*u*u+(-a[k]+3*b[k]-3*c[k]+d[k])*u*u*u));}
// Rotor points have actual x/z depth; the screen-plane rotation only turns the
// animal upside down once. Ongoing rotation is about its longitudinal y axis.
function rotorPoint(i,t){
 const speed=clamp(spinVelocity/(Math.PI*6),0,1),phase=time*2.7-i*.73;
 // Tips trail roots and flex at a different phase; no rigid right-angle hinge.
 const lag=(.13+.34*speed)*t*t;
 const theta=i*Math.PI/4+spinAngle+.18-lag+Math.sin(phase-t*3.5)*.075*t*t;
 const bent=i%2===1;
 const flex=Math.sin(phase)*7, tip=Math.sin(phase-1.3)*9;
 const controls=bent?[[15,21],[35,31],[57,33],[72,39],[80+flex*.35,53],[83+flex*.5,70],[77+flex,83],[65+flex,85+tip*.5]]:[[15,21],[35,30],[55,36],[75,37+flex*.3],[93,34+flex*.6],[108,31+flex],[116,33+flex],[115+tip*.3,39+flex]];
 const [radial,axial]=sampleSpline(controls.map(([x,y])=>({x,y})),t);
 const z=Math.sin(theta)*radial,perspective=390/(390-z);
 return {x:Math.cos(theta)*radial*perspective,y:(axial-z*.22)*perspective,z,rScale:perspective};
}
function armMesh(i){const ps=armNodes[i],points=[];
 const center=t=>{const flat=sampleSpline(ps,t),rot=rotorPoint(i,t);return [mix(flat[0],rot.x,inversion),mix(flat[1],rot.y,inversion)]};
 for(let j=0;j<=70;j++){const t=j/70,p=center(t),prev=center(Math.max(0,t-.003)),next=center(Math.min(1,t+.003)),dx=next[0]-prev[0],dy=next[1]-prev[1],l=Math.hypot(dx,dy)||1;points.push({x:p[0],y:p[1],nx:-dy/l,ny:dx/l,r:(3.2+(i<4?8.3:9.3)*Math.pow(1-t,.85))*mix(1,rotorPoint(i,t).rScale,inversion),t});}return points;}
function ribbon(points,scale=1,offset=0){
 const side=(p,s)=>[p.x+p.nx*p.r*(s*scale+offset),p.y+p.ny*p.r*(s*scale+offset)];
 const tip=points[points.length-1],root=points[0],outline=points.map(p=>side(p,1));
 // Round the actual silhouette, including the end cap, rather than stroking a line.
 for(let j=1;j<=10;j++){const a=j/10*Math.PI;outline.push([tip.x+tip.nx*tip.r*offset+tip.r*scale*(tip.nx*Math.cos(a)+tip.ny*Math.sin(a)),tip.y+tip.ny*tip.r*offset+tip.r*scale*(tip.ny*Math.cos(a)-tip.nx*Math.sin(a))]);}
 outline.push(...points.slice().reverse().map(p=>side(p,-1)));
 for(let j=1;j<=10;j++){const a=j/10*Math.PI;outline.push([root.x+root.nx*root.r*offset+root.r*scale*(-root.nx*Math.cos(a)-root.ny*Math.sin(a)),root.y+root.ny*root.r*offset+root.r*scale*(-root.ny*Math.cos(a)+root.nx*Math.sin(a))]);}
 return path(outline);
}
function webPath(){
 // A shallow, concave web joins only the proximal arm sections.
 // Its vertices follow the actual animated arm meshes, including axial rotation.
 const c=[0,19],rim=Array.from({length:8},(_,i)=>{const p=renderedMeshes[i][18];return [p.x,Math.max(16,p.y)]}).sort((a,b)=>Math.atan2(a[1]-c[1],a[0])-Math.atan2(b[1]-c[1],b[0]));
 let d='M-24 18 H24 V34 C24 44 12 49 0 49 C-12 49 -24 44 -24 34Z';for(let i=0;i<rim.length;i++){const a=rim[i],b=rim[(i+1)%rim.length];const gap=(Math.atan2(b[1]-c[1],b[0])-Math.atan2(a[1]-c[1],a[0])+Math.PI*2)%(Math.PI*2);if(gap>Math.PI)continue;const x=(a[0]+b[0])*.33,y=c[1]+((a[1]+b[1])*.5-c[1])*.66;d+=`M${c[0]} ${c[1]} L${a[0]} ${a[1]} Q${x} ${y} ${b[0]} ${b[1]} Z`;}
 return d;
}
function paintArms(cat,s){
 cat.web.setAttribute('d',currentWebPath);cat.web.style.display=$('#webbing').checked?'':'none';
 const ordered=cat.arms.slice().sort((a,b)=>rotorPoint(+a.dataset.arm,.6).z-rotorPoint(+b.dataset.arm,.6).z);
 for(const el of ordered){const i=+el.dataset.arm,front=inversion>.05?rotorPoint(i,.6).z>=0:i>=4;const layer=cat.el.querySelector(front?'.front':'.rear');if(inversion>.05||el.parentNode!==layer)layer.appendChild(el);}
 cat.arms.forEach(el=>{const i=Number(el.dataset.arm),pts=renderedMeshes[i];el.querySelector('.arm').setAttribute('d',ribbon(pts));
 const exposed=pts.slice(16);el.querySelector('.ventral').setAttribute('d',ribbon(exposed.map(p=>({...p,r:p.r*smooth((p.t-.22)/.18)})),.54,.12));

 });

}
actionLabel();
setMode('idle');cycleAt=6;stepArms(0);paint();wake();
