-- BULDACITY SGCraft2 visual engine
-- Realistic Stargate-inspired OpenComputers rendering: ring, glyphs, chevrons and iris.
-- OpenComputers / Minecraft 1.7.10 / SGCraft 1.13.x
local V={}
V.C={bg=0x030507,black=0x000000,metal=0x111A20,metal2=0x1D2A32,edge=0x52636C,cyan=0x37DFFF,blue=0x4B82FF,green=0x45E59A,yellow=0xF4D35E,orange=0xFF9638,red=0xF05262,purple=0x9B68FF,white=0xEAF8FF,dim=0x304049,glass=0x071A22,muted=0x70838D,iris=0x6B747A}
local C=V.C
function V.text(g,x,y,s,fg,bg) if x>=1 and y>=1 then g.setForeground(fg or C.white);g.setBackground(bg or C.bg);g.set(x,y,tostring(s or "")) end end
function V.fill(g,x,y,w,h,c) if w>0 and h>0 then g.setBackground(c or C.bg);g.fill(x,y,w,h," ") end end
function V.line(g,x,y,w,c) V.fill(g,x,y,w,1,c) end
function V.fit(s,n) s=tostring(s or "");if n<=0 then return "" end;if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
function V.point(cx,cy,rx,ry,a) local r=math.rad(a);return math.floor(cx+math.cos(r)*rx+.5),math.floor(cy+math.sin(r)*ry+.5) end

-- Compact Stargate-like glyph set. These are deliberately rendered as single-cell
-- cryptic marks so they remain readable on the standard OpenComputers font.
local GLYPHS={
 "⌂","◇","△","▽","∴","⊙","╳","┼","∩","∪","<>","^v","/\\","\\/","<>","><",
 "+o","o+","x+","+x","|>","<|","^o","o^","v<"," >v","#o","o#","@+","+@","%x","x%","=o","o=","*+","+*"
}

local function glyph(g,x,y,i,fg,bg)
 local s=GLYPHS[((i-1)%#GLYPHS)+1]
 -- Multi-cell ASCII glyphs are reduced to one visible cell on small screens.
 if #s>1 then s=s:sub(1,1) end
 V.text(g,x,y,s,fg,bg)
end

local function drawChevron(g,cx,cy,rx,ry,a,active,pulse)
 local px,py=V.point(cx,cy,rx+1,ry+1,a)
 local col=active and C.orange or C.dim
 if pulse and active then col=C.white end
 V.text(g,px-1,py,"[",col,C.metal);V.text(g,px,py,active and ">" or " ",col,C.metal);V.text(g,px+1,py,"]",col,C.metal)
end

local function drawIris(g,cx,cy,rx,ry,closed,t)
 if closed then
  -- Eight metallic iris blades converge toward the centre.
  for i=0,7 do
   local a=i*45+(t and math.floor(t*8)%3 or 0)
   local ex,ey=V.point(cx,cy,math.max(2,rx-3),math.max(2,ry-2),a)
   V.line(g,math.min(cx,ex),math.min(cy,ey),math.max(1,math.abs(ex-cx)+1),C.iris)
   if ey~=cy then V.text(g,ex,ey,"#",C.edge,C.metal) end
  end
  V.text(g,cx-4,cy,"[ IRIS ]",C.white,C.iris)
 elseif t and t%1<0.7 then
  V.text(g,cx-3,cy,"EVENT",C.cyan,C.glass)
  V.text(g,cx-4,cy+1,"HORIZON",C.blue,C.glass)
 end
end

function V.gate(g,x,y,w,h,d,t)
 V.fill(g,x,y,w,h,C.metal);V.line(g,x,y,w,C.cyan);V.text(g,x+2,y,"[ STARGATE / LIVE HARDWARE VIEW ]",C.white,C.cyan)
 local cx=x+math.floor(w/2);local cy=y+math.floor(h/2)-1
 local rx=math.max(10,math.floor(w*.30));local ry=math.max(5,math.floor(h*.34))
 local state=d and d.state or "NO INTERFACE"
 local live=d and d.present and state~="API ERROR" and state~="NO INTERFACE" and state~="Offline"
 local engaged=tonumber(d and d.engaged or 0) or 0
 local irisState=string.lower(tostring(d and d.iris or ""))
 local irisClosed=irisState=="closed"

 -- Heavy outer metal ring.
 for ring=0,4 do
  for a=0,350,10 do
   local px,py=V.point(cx,cy,rx-ring,ry-ring,a)
   local mark=(a%30==0) and "O" or "."
   V.text(g,px,py,mark,live and (ring<2 and C.edge or C.dim) or C.dim,C.metal)
  end
 end
 -- Inner engraved symbol ring: 36/39 cryptic marks around the gate.
 local symbolCount=36
 for i=1,symbolCount do
  local a=-90+(i-1)*(360/symbolCount)
  local px,py=V.point(cx,cy,rx-4,ry-3,a)
  local active=live and (i%9)<=engaged and engaged>0
  local col=active and C.orange or (live and C.cyan or C.dim)
  glyph(g,px,py,i,col,C.metal)
 end
 -- Nine physical chevrons around the outside.
 for i=1,9 do
  local a=-90+(i-1)*40
  drawChevron(g,cx,cy,rx,ry,a,i<=engaged,((t or 0)*4)%2>1)
 end

 if irisClosed then
  drawIris(g,cx,cy,rx-8,ry-5,true,t)
 elseif state=="Connected" or state=="Opening" then
  for yy=-math.min(4,ry-2),math.min(4,ry-2) do
   local span=math.max(2,5-math.abs(yy));local s=""
   for i=1,span*2+1 do s=s..(((math.floor((t or 0)*8)+i+yy)%4==0) and "*" or ".") end
   V.text(g,cx-span,cy+yy,s,yy%2==0 and C.cyan or C.blue,C.glass)
  end
  drawIris(g,cx,cy,rx-8,ry-5,false,t)
 elseif state=="Dialling" then
  V.text(g,cx-6,cy,"DIAL SEQUENCE",C.cyan,C.glass)
 elseif state=="Idle" then
  V.text(g,cx-4,cy,"STANDBY",C.yellow,C.glass)
 elseif state=="Closing" then
  V.text(g,cx-3,cy,"CLOSING",C.cyan,C.glass)
 elseif not live then
  V.text(g,cx-math.floor(#state/2),cy,state,C.red,C.glass)
 end

 -- Status plate under the gate.
 local irisLabel=irisClosed and "IRIS CLOSED" or (irisState=="open" and "IRIS OPEN" or "IRIS ?")
 V.text(g,x+2,y+h-3,"IRIS",C.muted,C.metal);V.text(g,x+7,y+h-3,V.fit(irisLabel,16),irisClosed and C.red or C.green,C.metal)
 V.text(g,x+w-17,y+h-3,"CHEVRONS",C.muted,C.metal);V.text(g,x+w-6,y+h-3,string.format("%d/9",engaged),C.orange,C.metal)
end
return V
