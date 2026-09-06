-- SGCraft2 graphical renderer
-- OpenComputers / Minecraft 1.7.10 / SGCraft 1.13.x
-- Pure GPU geometry: no ASCII gate and no hash/block-letter artwork.
local V={}
V.C={bg=0x030507,black=0x000000,metal=0x111A20,metal2=0x1D2A32,edge=0x52636C,cyan=0x37DFFF,blue=0x4B82FF,green=0x45E59A,yellow=0xF4D35E,orange=0xFF9638,red=0xF05262,purple=0x9B68FF,white=0xEAF8FF,dim=0x304049,muted=0x70838D,glass=0x071A22,iris=0x9DA7AD}
local C=V.C
function V.text(g,x,y,s,fg,bg) if x>=1 and y>=1 then g.setForeground(fg or C.white);g.setBackground(bg or C.bg);g.set(x,y,tostring(s or "")) end end
function V.fill(g,x,y,w,h,c) if w>0 and h>0 then g.setBackground(c or C.bg);g.fill(x,y,w,h," ") end end
function V.line(g,x,y,w,c) V.fill(g,x,y,w,1,c) end
function V.fit(s,n) s=tostring(s or "");if n<=0 then return "" end;if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
local function point(cx,cy,rx,ry,a) local r=math.rad(a);return math.floor(cx+math.cos(r)*rx+.5),math.floor(cy+math.sin(r)*ry+.5) end
local function dot(g,x,y,c,b) V.text(g,x,y,"•",c,b) end
local function diamond(g,x,y,c,b) V.text(g,x,y,"◆",c,b) end
local glyphs={"◇","◈","○","△","▽","◆","◊","□","⬡","✦","✧","⊙"}
local function glyph(g,x,y,i,c,b) V.text(g,x,y,glyphs[((i-1)%#glyphs)+1],c,b) end
local function ring(g,cx,cy,rx,ry,c,step,rot)
 for a=0,359,step do local x,y=point(cx,cy,rx,ry,a+(rot or 0));dot(g,x,y,c,C.metal) end
end
local function chevron(g,cx,cy,rx,ry,a,active,pulse)
 local x,y=point(cx,cy,rx,ry,a);local c=active and C.orange or C.dim;if pulse and active then c=C.white end
 diamond(g,x,y,c,C.metal);dot(g,x-1,y,c,C.metal);dot(g,x+1,y,c,C.metal)
end
local function horizon(g,cx,cy,rx,ry,phase)
 for yy=-ry+2,ry-2 do
  local span=math.max(2,math.floor(rx*math.sqrt(math.max(0,1-(yy*yy)/(ry*ry)))))
  for xx=-span,span do
   if ((xx+yy+phase)%5)==0 then dot(g,cx+xx,cy+yy,(yy%2==0) and C.cyan or C.blue,C.glass) end
  end
 end
end
local function iris(g,cx,cy,rx,ry)
 for i=0,7 do
  local a=i*45
  for r=2,math.max(3,math.min(rx,ry)-2) do
   local x,y=point(cx,cy,r,math.floor(r*.62),a)
   dot(g,x,y,C.iris,C.metal2)
  end
 end
 V.text(g,cx-5,cy-1,"◀ IRIS ▶",C.white,C.iris)
 V.text(g,cx-5,cy+1,"  CLOSED",C.red,C.iris)
end
function V.gate(g,x,y,w,h,d,t)
 V.fill(g,x,y,w,h,C.metal);V.line(g,x,y,w,C.cyan);V.line(g,x,y+h-1,w,C.edge)
 V.text(g,x+2,y,"STARGATE  /  LIVE GATE SCHEMATIC",C.white,C.cyan)
 local state=tostring(d and d.state or "NO INTERFACE")
 local active=d and d.present and state~="API ERROR" and state~="NO INTERFACE" and state~="Offline"
 local engaged=tonumber(d and d.engaged or 0) or 0
 local cx=x+math.floor(w*.42);local cy=y+math.floor(h*.52);local rx=math.max(12,math.floor(w*.29));local ry=math.max(7,math.floor(h*.35))
 V.fill(g,cx-rx+2,cy-ry+2,rx*2-4,ry*2-4,C.black)
 ring(g,cx,cy,rx,ry,active and C.edge or C.dim,8,0)
 ring(g,cx,cy,rx-2,ry-2,active and C.cyan or C.dim,12,(state=="Dialling" and ((t or 0)*18) or 0))
 ring(g,cx,cy,rx-4,ry-4,active and C.edge or C.dim,20,0)
 for i=1,39 do
  local a=-90+(i-1)*(360/39)+(state=="Dialling" and ((t or 0)*10) or 0)
  local gx,gy=point(cx,cy,rx-5,ry-4,a)
  glyph(g,gx,gy,i,(active and i<=engaged) and C.orange or (active and C.cyan or C.dim),C.metal)
 end
 for i=1,9 do chevron(g,cx,cy,rx+1,ry+1,-90+(i-1)*40,i<=engaged,((t or 0)*5)%2>1) end
 local irisState=string.lower(tostring(d and d.iris or ""))
 if irisState=="closed" then iris(g,cx,cy,rx-7,ry-5)
 elseif state=="Connected" or state=="Opening" then horizon(g,cx,cy,rx-7,ry-5,math.floor((t or 0)*8))
 elseif state=="Dialling" then V.text(g,cx-5,cy,"DIALING",C.cyan,C.glass);V.text(g,cx-6,cy+2,string.format("SEQUENCE %d/9",engaged),C.orange,C.glass)
 elseif state=="Idle" then V.text(g,cx-4,cy,"STANDBY",C.yellow,C.glass)
 elseif state=="Closing" then V.text(g,cx-4,cy,"CLOSING",C.cyan,C.glass)
 else V.text(g,cx-4,cy,"NO LINK",C.red,C.glass) end
 local sx=x+rx*2+7
 if sx+17<=x+w then
  V.fill(g,sx,y+2,17,h-5,C.glass);V.line(g,sx,y+2,17,C.blue)
  V.text(g,sx+1,y+2,"TELEMETRY",C.cyan,C.glass)
  V.text(g,sx+1,y+4,"STATE",C.muted,C.glass);V.text(g,sx+1,y+5,V.fit(state:upper(),15),state=="Connected" and C.green or state=="Idle" and C.yellow or C.white,C.glass)
  V.text(g,sx+1,y+7,"CHEVRONS",C.muted,C.glass)
  for i=1,9 do V.fill(g,sx+1+((i-1)%3)*5,y+8+math.floor((i-1)/3)*2,4,1,i<=engaged and C.orange or C.dim) end
  V.text(g,sx+1,y+15,"IRIS",C.muted,C.glass);V.text(g,sx+1,y+16,V.fit(tostring(d and d.iris or "UNKNOWN"),15),irisState=="closed" and C.red or C.green,C.glass)
  V.text(g,sx+1,y+18,"LOCAL",C.muted,C.glass);V.text(g,sx+1,y+19,V.fit(tostring(d and d.localAddress or "—"),15),C.white,C.glass)
  V.text(g,sx+1,y+21,"REMOTE",C.muted,C.glass);V.text(g,sx+1,y+22,V.fit(tostring(d and d.remoteAddress or "—"),15),C.cyan,C.glass)
 end
 V.text(g,x+2,y+h-3,"LINK",C.muted,C.metal);V.text(g,x+7,y+h-3,V.fit((d and d.remoteAddress~="") and "CONNECTED" or "STANDBY",12),(d and d.remoteAddress~="") and C.green or C.yellow,C.metal)
 V.text(g,x+w-13,y+h-3,string.format("%d/9",engaged),C.orange,C.metal)
end
return V
