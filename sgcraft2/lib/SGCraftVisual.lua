-- SGCraft2 cinematic GPU renderer
-- OpenComputers / Minecraft 1.7.10 / SGCraft 1.13.x
-- Character-cell geometry only: no hash/block-art gate.
local V={}
V.C={bg=0x020407,black=0x000000,metal=0x0C151B,metal2=0x17242B,metal3=0x24343C,edge=0x536873,cyan=0x37DFFF,blue=0x4B82FF,green=0x45E59A,yellow=0xF4D35E,orange=0xFF9638,red=0xF05262,purple=0x9B68FF,white=0xEAF8FF,dim=0x304049,muted=0x70838D,glass=0x06151C,iris=0xAAB4BA}
local C=V.C
function V.text(g,x,y,s,fg,bg) if x>=1 and y>=1 then g.setForeground(fg or C.white);g.setBackground(bg or C.bg);g.set(x,y,tostring(s or "")) end end
function V.fill(g,x,y,w,h,c) if w>0 and h>0 then g.setBackground(c or C.bg);g.fill(x,y,w,h," ") end end
function V.line(g,x,y,w,c) V.fill(g,x,y,w,1,c) end
function V.vline(g,x,y,h,c) V.fill(g,x,y,1,h,c) end
function V.fit(s,n) s=tostring(s or "");if n<=0 then return "" end;if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
local function point(cx,cy,rx,ry,a) local r=math.rad(a);return math.floor(cx+math.cos(r)*rx+.5),math.floor(cy+math.sin(r)*ry+.5) end
local function dot(g,x,y,c,b) V.text(g,x,y,"•",c,b) end
local function glyph(g,x,y,i,c,b) local chars={"◇","◈","○","△","▽","◆","◊","□","⬡","✦","✧","⊙"};V.text(g,x,y,chars[((i-1)%#chars)+1],c,b) end
local function ring(g,cx,cy,rx,ry,c,step,rot,phase) for a=0,359,step do local x,y=point(cx,cy,rx,ry,a+(rot or 0));if not phase or ((a/step)%phase==0) then dot(g,x,y,c,C.metal) else dot(g,x,y,c,C.metal2) end end end
local function chevron(g,cx,cy,rx,ry,a,active,pulse)
 local x,y=point(cx,cy,rx,ry,a);local c=active and C.orange or C.dim;if pulse and active then c=C.white end
 V.fill(g,x-1,y-1,3,1,c);V.fill(g,x-1,y+1,3,1,c);dot(g,x,y,c,C.metal3)
end
local function horizon(g,cx,cy,rx,ry,phase)
 for yy=-ry+2,ry-2 do
  local span=math.max(2,math.floor(rx*math.sqrt(math.max(0,1-(yy*yy)/(ry*ry)))))
  for xx=-span,span do
   local wave=(xx*3+yy*2+phase)%9
   if wave<=2 then dot(g,cx+xx,cy+yy,(wave==0 and C.white) or (yy%2==0 and C.cyan or C.blue),C.glass) end
  end
 end
 for i=1,4 do local rr=math.floor(math.min(rx,ry)*i/5);ring(g,cx,cy,rr,math.floor(rr*.62),C.blue,20,phase*.5+i,2) end
end
local function iris(g,cx,cy,rx,ry)
 local maxr=math.max(4,math.min(rx,ry)-1)
 for i=0,7 do
  local a=i*45
  for r=2,maxr do
   local x,y=point(cx,cy,r,math.floor(r*.62),a);dot(g,x,y,(r>maxr-2) and C.white or C.iris,C.metal2)
  end
 end
 V.text(g,cx-6,cy-1,"◀ IRIS ▶",C.white,C.iris);V.text(g,cx-6,cy+1,"  CLOSED",C.red,C.iris)
end
local function frame(g,x,y,w,h,accent)
 V.fill(g,x,y,w,h,C.metal);V.line(g,x,y,w,accent);V.line(g,x+1,y+1,w-2,C.edge);V.line(g,x,y+h-1,w,C.edge)
 V.vline(g,x,y,math.max(1,h-1),accent);V.vline(g,x+w-1,y,math.max(1,h-1),C.edge)
 if w>10 and h>6 then V.fill(g,x+2,y+2,w-4,1,C.metal2);V.fill(g,x+2,y+h-3,w-4,1,C.metal2) end
end
function V.gate(g,x,y,w,h,d,t)
 if w<18 or h<10 then return end
 frame(g,x,y,w,h,C.cyan)
 V.text(g,x+2,y,"STARGATE  /  LIVE GATE SCHEMATIC",C.white,C.cyan)
 local state=tostring(d and d.state or "NO INTERFACE");local active=d and d.present and state~="API ERROR" and state~="NO INTERFACE" and state~="Offline";local engaged=tonumber(d and d.engaged or 0) or 0
 local sideW=math.max(0,math.floor(w*.19));local gateW=w-sideW-3;local cx=x+2+math.floor(gateW*.5);local cy=y+math.floor((h-5)*.5)+3;local rx=math.max(10,math.floor(gateW*.43));local ry=math.max(5,math.floor((h-7)*.43))
 V.fill(g,cx-rx+1,cy-ry+1,rx*2-2,ry*2-2,C.black)
 ring(g,cx,cy,rx+1,ry+1,active and C.edge or C.dim,8,0);ring(g,cx,cy,rx-1,ry-1,active and C.cyan or C.dim,8,state=="Dialling" and t*22 or 0);ring(g,cx,cy,rx-3,ry-3,active and C.edge or C.dim,12,0)
 for i=1,39 do local a=-90+(i-1)*(360/39)+(state=="Dialling" and t*10 or 0);local gx,gy=point(cx,cy,rx-4,ry-3,a);local col=(active and i<=engaged) and C.orange or (active and C.cyan or C.dim);glyph(g,gx,gy,i,col,C.metal) end
 for i=1,9 do chevron(g,cx,cy,rx+1,ry+1,-90+(i-1)*40,i<=engaged,((t or 0)*6)%2>1) end
 local irisState=string.lower(tostring(d and d.iris or ""))
 if irisState=="closed" then iris(g,cx,cy,rx-6,ry-4) elseif state=="Connected" or state=="Opening" then horizon(g,cx,cy,rx-6,ry-4,math.floor((t or 0)*8)) elseif state=="Dialling" then V.text(g,cx-5,cy-1,"DIALING",C.cyan,C.glass);V.text(g,cx-7,cy+1,string.format("SEQUENCE %d/9",engaged),C.orange,C.glass) elseif state=="Idle" then V.text(g,cx-4,cy,"STANDBY",C.yellow,C.glass) elseif state=="Closing" then V.text(g,cx-4,cy,"CLOSING",C.cyan,C.glass) else V.text(g,cx-4,cy,"NO LINK",C.red,C.glass) end
 if sideW>=15 then local sx=x+w-sideW-1;V.fill(g,sx,y+3,sideW-1,h-7,C.glass);V.line(g,sx,y+3,sideW-1,C.blue);V.text(g,sx+1,y+3,"HUD",C.cyan,C.glass);V.text(g,sx+1,y+5,"STATE",C.muted,C.glass);V.text(g,sx+1,y+6,V.fit(state:upper(),sideW-3),stateColor and ((state=="Connected") and C.green or (state=="Idle" and C.yellow or C.white)) or C.white,C.glass);V.text(g,sx+1,y+8,"CHEVRONS",C.muted,C.glass);for i=1,9 do V.fill(g,sx+1+((i-1)%3)*4,y+9+math.floor((i-1)/3)*2,3,1,i<=engaged and C.orange or C.dim) end;V.text(g,sx+1,y+16,"IRIS",C.muted,C.glass);V.text(g,sx+1,y+17,V.fit(tostring(d and d.iris or "UNKNOWN"),sideW-3),irisState=="closed" and C.red or C.green,C.glass);V.text(g,sx+1,y+19,"REMOTE",C.muted,C.glass);V.text(g,sx+1,y+20,V.fit(tostring(d and d.remoteAddress or "—"),sideW-3),C.cyan,C.glass) end
 V.text(g,x+2,y+h-3,"LINK",C.muted,C.metal);V.text(g,x+7,y+h-3,V.fit((d and d.remoteAddress~="") and "CONNECTED" or "STANDBY",12),(d and d.remoteAddress~="") and C.green or C.yellow,C.metal);V.text(g,x+w-13,y+h-3,string.format("%d/9",engaged),C.orange,C.metal)
end
return V
