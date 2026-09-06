-- BULDACITY SGCraft2 visual engine
-- Milky Way style: 39 constellation glyphs, rotating inner ring, 9 chevrons and iris.
-- OpenComputers / Minecraft 1.7.10 / SGCraft 1.13.x
local V={}
V.C={bg=0x030507,black=0x000000,metal=0x111A20,metal2=0x1D2A32,edge=0x52636C,cyan=0x37DFFF,blue=0x4B82FF,green=0x45E59A,yellow=0xF4D35E,orange=0xFF9638,red=0xF05262,purple=0x9B68FF,white=0xEAF8FF,dim=0x304049,glass=0x071A22,muted=0x70838D,iris=0x8A949A}
local C=V.C
function V.text(g,x,y,s,fg,bg) if x>=1 and y>=1 then g.setForeground(fg or C.white);g.setBackground(bg or C.bg);g.set(x,y,tostring(s or "")) end end
function V.fill(g,x,y,w,h,c) if w>0 and h>0 then g.setBackground(c or C.bg);g.fill(x,y,w,h," ") end end
function V.line(g,x,y,w,c) V.fill(g,x,y,w,1,c) end
function V.fit(s,n) s=tostring(s or "");if n<=0 then return "" end;if #s<=n then return s end;if n<=3 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
function V.point(cx,cy,rx,ry,a) local r=math.rad(a);return math.floor(cx+math.cos(r)*rx+.5),math.floor(cy+math.sin(r)*ry+.5) end

-- Compact 5x5 constellation-like glyphs. They are deliberately drawn as geometry,
-- rather than relying on Unicode fonts that differ between OpenComputers screens.
local G={
 {"..#..",".#.#.","#...#","..#..",".#.#."},{".#...","###..",".#.#.","..##.","...#."},
 {"#....",".#...","..###",".#...","#...."},{"..#..","#.#..","..#..",".#.#.","#...#"},
 {"#.#..",".#...","###..","...#.","..#.."},{"..#..","#.#.#","..#..",".#.#.","#...#"},
 {"#...#",".#.#.","..#..",".#.#.","#...#"},{"###..","..#..",".###.","#....","###.."},
 {"..#..",".###.","#.#..","..#..",".#..."},{"#..#.",".#.#.","..#..","#.#..",".#.#."},
 {"###..",".#...","..##.","...#.","###.."},{"#....","##...",".#.#.","..##.","...#."},
 {".#...","#.#..","###..","#.#..",".#..."},{"#.#..",".#.#.","..#..",".#.#.","#.#.."},
 {"##...","..#..",".###.","#....","##..."},{"..#..",".##..","#####","..##.","..#.."},
 {"#.#..","###..","..#..","###..","#.#.."},{".#...","###..",".#.#.","..#..","#...#"},
 {"#...#","##.##","..#..","##.##","#...#"},{"###..","#....",".##..","...#.","###.."},
 {"..#..","#.#..","#..#.",".#.#.","..#.."},{"#.#..","#.#..","###..","..#..","..#.."},
 {"...#.","..##.",".###.","#.#..","#...."},{"#....",".#...","..###",".#...","..#.."},
 {".#.#.","..#..","###..","..#..",".#.#."},{"#..#.",".#.#.","..#..",".#.#.","#..#."},
 {"####.","...#.","..#..",".#...","####."},{"...#.","..##.",".###.","..##.","...#."},
 {"#....","###..","#.#..","###..","#...."},{".#.#.","#...#","..#..","#...#",".#.#."},
 {"###..","#.#..","###..","#....","#...."},{"#.#..",".#.#.","..#..",".#.#.","#.#.."},
 {"..#..","###..","#.#..","###..","..#.."},{"#...#","##.##",".###.","##.##","#...#"},
 {"###..","..#..",".##..","#....","####."},{".#...","#.#..","..#..","#.#..",".#..."},
 {"#....",".#...","..#..","...#.","....#"},{"#.#..","..#..","#.#..","..#..","#.#.."},
 {"####.","#....",".###.","....#","####."}
}
local function drawPattern(g,x,y,p,fg,bg,scale)
 scale=scale or 1
 for yy=1,5 do for xx=1,5 do if p[yy]:sub(xx,xx)=="#" then
  if scale==1 then V.text(g,x+xx-1,y+yy-1,"#",fg,bg) else V.fill(g,x+(xx-1)*scale,y+(yy-1)*scale,scale,scale,fg) end
 end end end
end
local function glyph(g,x,y,i,fg,bg) drawPattern(g,x-2,y-2,G[((i-1)%#G)+1],fg,bg,1) end
local function drawChevron(g,cx,cy,rx,ry,a,active,pulse)
 local px,py=V.point(cx,cy,rx+1,ry+1,a);local col=active and C.orange or C.dim;if pulse and active then col=C.white end
 V.text(g,px-1,py,"<",col,C.metal);V.text(g,px,py,active and "#" or "-",col,C.metal);V.text(g,px+1,py,">",col,C.metal)
end
local function drawIris(g,cx,cy,rx,ry,closed,t)
 if not closed then return end
 -- Eight blades with a stepped triangular profile, closer to the mechanical iris.
 for i=0,7 do
  local a=i*45+(math.floor((t or 0)*2)%2)*3
  for r=0,math.max(2,math.min(rx,ry)-2),1 do
   local px,py=V.point(cx,cy,r,math.floor(r*.62),a)
   V.text(g,px,py,"/",C.iris,C.metal)
   if r%2==0 then local qx,qy=V.point(cx,cy,r,math.floor(r*.62),a+8);V.text(g,qx,qy,"#",C.iris,C.metal) end
  end
 end
 V.text(g,cx-5,cy-1,"< IRIS >",C.white,C.iris);V.text(g,cx-5,cy+1,"  CLOSED",C.red,C.iris)
end
function V.gate(g,x,y,w,h,d,t)
 V.fill(g,x,y,w,h,C.metal);V.line(g,x,y,w,C.cyan);V.text(g,x+2,y,"[ STARGATE / LIVE HARDWARE VIEW ]",C.white,C.cyan)
 local cx=x+math.floor(w/2);local cy=y+math.floor(h/2)-1;local rx=math.max(11,math.floor(w*.30));local ry=math.max(6,math.floor(h*.34))
 local state=d and d.state or "NO INTERFACE";local live=d and d.present and state~="API ERROR" and state~="NO INTERFACE" and state~="Offline";local engaged=tonumber(d and d.engaged or 0) or 0
 local irisState=string.lower(tostring(d and d.iris or ""));local irisClosed=irisState=="closed";local rotating=state=="Dialling"
 for ring=0,4 do for a=0,350,10 do local px,py=V.point(cx,cy,rx-ring,ry-ring,a);local mark=(a%30==0) and "O" or ".";V.text(g,px,py,mark,live and (ring<2 and C.edge or C.dim) or C.dim,C.metal) end end
 local offset=rotating and (((t or 0)*18)%360) or 0
 for i=1,39 do local a=-90+(i-1)*(360/39)+offset;local px,py=V.point(cx,cy,rx-5,ry-4,a);local active=live and i<=engaged;local col=active and C.orange or (live and C.cyan or C.dim);glyph(g,px,py,i,col,C.metal) end
 for i=1,9 do local a=-90+(i-1)*40;drawChevron(g,cx,cy,rx,ry,a,i<=engaged,((t or 0)*4)%2>1) end
 if irisClosed then drawIris(g,cx,cy,rx-8,ry-5,true,t)
 elseif state=="Connected" or state=="Opening" then
  for yy=-math.min(4,ry-2),math.min(4,ry-2) do local span=math.max(2,5-math.abs(yy));local s="";for i=1,span*2+1 do s=s..(((math.floor((t or 0)*8)+i+yy)%4==0) and "*" or ".") end;V.text(g,cx-span,cy+yy,s,yy%2==0 and C.cyan or C.blue,C.glass) end
 elseif state=="Dialling" then V.text(g,cx-6,cy,"DIAL SEQUENCE",C.cyan,C.glass)
 elseif state=="Idle" then V.text(g,cx-4,cy,"STANDBY",C.yellow,C.glass)
 elseif state=="Closing" then V.text(g,cx-3,cy,"CLOSING",C.cyan,C.glass)
 elseif not live then V.text(g,cx-math.floor(#state/2),cy,state,C.red,C.glass) end
 local irisLabel=irisClosed and "IRIS CLOSED" or (irisState=="open" and "IRIS OPEN" or "IRIS ?")
 V.text(g,x+2,y+h-3,"IRIS",C.muted,C.metal);V.text(g,x+7,y+h-3,V.fit(irisLabel,16),irisClosed and C.red or (irisState=="open" and C.green or C.yellow),C.metal)
 V.text(g,x+w-17,y+h-3,"CHEVRONS",C.muted,C.metal);V.text(g,x+w-6,y+h-3,string.format("%d/9",engaged),C.orange,C.metal)
end
return V
