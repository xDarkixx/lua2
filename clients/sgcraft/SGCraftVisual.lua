-- BULDACITY SGCraft Visual Engine
-- OpenComputers T3-safe vector-style Stargate renderer.
-- No external graphics library required.
local V={}
local gpu=require("component").gpu
V.C={bg=0x030507,black=0x000000,metal=0x111A20,metal2=0x1D2A32,edge=0x52636C,cyan=0x37DFFF,blue=0x4B82FF,green=0x45E59A,yellow=0xF4D35E,orange=0xFF9638,red=0xF05262,white=0xEAF8FF,dim=0x304049,glass=0x071A22}
local C=V.C
function V.text(x,y,s,fg,bg) if x>=1 and y>=1 then gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s or "")) end end
function V.fill(x,y,w,h,c) if w>0 and h>0 then gpu.setBackground(c);gpu.fill(x,y,w,h," ") end end
function V.line(x,y,w,c) V.fill(x,y,w,1,c) end
function V.fit(s,n) s=tostring(s or "");if #s<=n then return s end;return n>3 and s:sub(1,n-3).."..." or s:sub(1,n) end
function V.point(cx,cy,rx,ry,a) local r=math.rad(a);return math.floor(cx+math.cos(r)*rx+.5),math.floor(cy+math.sin(r)*ry+.5) end
local function glyph(i,on) return on and (i%2==0 and "O" or "0") or "." end
function V.gate(x,y,w,h,d,t)
 local cx=x+math.floor(w/2);local cy=y+math.floor(h/2)-1;local rx=math.max(12,math.floor(w*.31));local ry=math.max(6,math.floor(h*.35))
 V.fill(x,y,w,h,C.metal);V.line(x,y,w,C.cyan);V.text(x+2,y,"[ STARGATE / LIVE HARDWARE VIEW ]",C.white,C.cyan)
 local live=d and d.present and d.state~="Offline" and d.state~="NO INTERFACE" and d.state~="API ERROR"
 for ring=0,2 do for a=0,350,10 do local px,py=V.point(cx,cy,rx-ring*2,ry-ring,a);V.text(px,py,glyph(a,live),ring==0 and C.edge or C.dim,C.metal) end end
 -- 36 illuminated ring segments, like a physical control display
 for a=0,350,10 do if a%40==0 then local px,py=V.point(cx,cy,rx+1,ry+1,a);V.text(px-1,py,"[ ]",C.edge,C.metal) end end
 -- nine chevrons; the actual engaged count comes from SGCraft
 local engaged=tonumber(d and d.engaged or 0) or 0
 for i=1,9 do local a=-90+(i-1)*40;local px,py=V.point(cx,cy,rx+1,ry+1,a);local on=i<=engaged;V.text(px-1,py,on and "[+]" or "[ ]",on and C.orange or C.dim,C.metal) end
 local state=d and d.state or "NO INTERFACE"
 if state=="Connected" or state=="Opening" then
  for yy=-4,4 do local span=math.max(2,5-math.abs(yy));local s="";for i=1,span*2+1 do s=s..(((math.floor((t or 0)*8)+i+yy)%4==0) and "*" or ".") end;V.text(cx-span,cy+yy,s,yy%2==0 and C.cyan or C.blue,C.glass) end
 elseif state=="Dialling" then V.text(cx-6,cy,"DIAL SEQUENCE",C.cyan,C.glass)
 elseif state=="Idle" then V.text(cx-4,cy,"STANDBY",C.yellow,C.glass)
 elseif state=="Closing" then V.text(cx-4,cy,"CLOSING",C.cyan,C.glass)
 else V.text(cx-math.floor(#state/2),cy,state,C.red,C.glass) end
 V.text(cx-10,y+h-2,"CHEVRONS",C.muted,C.metal);V.text(cx-2,y+h-2,string.format("%d/9",engaged),C.orange,C.metal)
end
function V.bar(x,y,w,label,value,max,fg,bg)
 V.text(x,y,label,C.muted,bg or C.metal);V.fill(x+12,y,math.max(1,w-12),1,C.dim);local n=math.max(0,math.min(1,(tonumber(value) or 0)/(tonumber(max) or 1)));V.fill(x+12,y,math.floor((w-12)*n),1,fg or C.cyan);V.text(x+w-8,y,string.format("%3.0f%%",n*100),C.white,bg or C.metal)
end
return V
