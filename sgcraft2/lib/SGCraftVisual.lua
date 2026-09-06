-- BULDACITY SGCraft2 visual engine
-- Pure OpenComputers GPU drawing; no external graphics library required.
local component=require("component")
local V={};V.C={bg=0x030507,black=0x000000,metal=0x111A20,metal2=0x1D2A32,edge=0x52636C,cyan=0x37DFFF,blue=0x4B82FF,green=0x45E59A,yellow=0xF4D35E,orange=0xFF9638,red=0xF05262,white=0xEAF8FF,dim=0x304049,glass=0x071A22,muted=0x70838D};local C=V.C
function V.text(g,x,y,s,fg,bg) if x>=1 and y>=1 then g.setForeground(fg or C.white);g.setBackground(bg or C.bg);g.set(x,y,tostring(s or "")) end end
function V.fill(g,x,y,w,h,c) if w>0 and h>0 then g.setBackground(c);g.fill(x,y,w,h," ") end end
function V.line(g,x,y,w,c) V.fill(g,x,y,w,1,c) end
function V.fit(s,n) s=tostring(s or "");if n<=0 then return "" end;if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
function V.point(cx,cy,rx,ry,a) local r=math.rad(a);return math.floor(cx+math.cos(r)*rx+.5),math.floor(cy+math.sin(r)*ry+.5) end
function V.gate(g,x,y,w,h,d,t)
 V.fill(g,x,y,w,h,C.metal);V.line(g,x,y,w,C.cyan);V.text(g,x+2,y,"[ STARGATE / LIVE HARDWARE VIEW ]",C.white,C.cyan)
 local cx=x+math.floor(w/2);local cy=y+math.floor(h/2)-1;local rx=math.max(10,math.floor(w*.30));local ry=math.max(5,math.floor(h*.34));local state=d and d.state or "NO INTERFACE";local live=d and d.present and state~="API ERROR" and state~="NO INTERFACE" and state~="Offline"
 for ring=0,2 do for a=0,350,10 do local px,py=V.point(cx,cy,rx-ring*2,ry-ring,a);V.text(g,px,py,(a%20==0) and "O" or ".",live and (ring==0 and C.edge or C.dim) or C.dim,C.metal) end end
 local engaged=tonumber(d and d.engaged or 0) or 0
 for i=1,9 do local a=-90+(i-1)*40;local px,py=V.point(cx,cy,rx+1,ry+1,a);V.text(g,px-1,py,i<=engaged and "[+]" or "[ ]",i<=engaged and C.orange or C.dim,C.metal) end
 if state=="Connected" or state=="Opening" then
  for yy=-4,4 do local span=math.max(2,5-math.abs(yy));local s="";for i=1,span*2+1 do s=s..(((math.floor((t or 0)*8)+i+yy)%4==0) and "*" or ".") end;V.text(g,cx-span,cy+yy,s,yy%2==0 and C.cyan or C.blue,C.glass) end
 elseif state=="Dialling" then V.text(g,cx-6,cy,"DIAL SEQUENCE",C.cyan,C.glass)
 elseif state=="Idle" then V.text(g,cx-4,cy,"STANDBY",C.yellow,C.glass)
 elseif state=="Closing" then V.text(g,cx-3,cy,"CLOSING",C.cyan,C.glass)
 else V.text(g,cx-math.floor(#state/2),cy,state,C.red,C.glass) end
 V.text(g,cx-7,y+h-2,"CHEVRONS ",C.muted,C.metal);V.text(g,cx+2,y+h-2,string.format("%d/9",engaged),C.orange,C.metal)
end
return V
