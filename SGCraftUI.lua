-- SGCraftUI.lua
-- BULDACITY // SGCraft futuristic command UI
-- Pure presentation/input helper. NO network code.
local component=require("component")
local gpu=component.gpu
local UI={buttons={}}
UI.C={bg=0x03060D,panel=0x0A1220,panel2=0x0E1A2B,line=0x1B3850,cyan=0x22E6FF,blue=0x3D7CFF,green=0x3CFF9A,yellow=0xFFD65A,red=0xFF4E6E,purple=0xB86CFF,white=0xEAF7FF,muted=0x66819A,off=0x203041}
function UI.resize() local w,h=gpu.getResolution();UI.W,UI.H=w,h;return w,h end
local function txt(x,y,s,c,b) if x>=1 and y>=1 and x<=UI.W and y<=UI.H then gpu.setForeground(c or UI.C.white);gpu.setBackground(b or UI.C.bg);gpu.set(x,y,tostring(s or "")) end end
local function rect(x,y,w,h,b,c) if w>0 and h>0 then gpu.setBackground(b or UI.C.panel);gpu.setForeground(c or UI.C.white);gpu.fill(x,y,w,h," ") end end
local function fit(s,n) s=tostring(s or "");if #s<=n then return s end;if n<4 then return s:sub(1,n) end;return s:sub(1,n-3).."..." end
local function panel(x,y,w,h,title,accent) rect(x,y,w,h,UI.C.panel);rect(x,y,w,1,accent);txt(x+2,y,"◆ "..fit(title,w-5),UI.C.white,accent);if h>2 then rect(x+1,y+h-1,w-2,1,UI.C.line) end end
function UI.button(id,x,y,w,label,accent,active) UI.buttons[id]={x=x,y=y,w=w,h=2};rect(x,y,w,2,active and UI.C.white or (accent or UI.C.cyan));txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),active and (accent or UI.C.cyan) or UI.C.white,active and UI.C.white or (accent or UI.C.cyan)) end
function UI.hit(id,x,y) local b=UI.buttons[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
local function bar(x,y,w,p,c) p=math.max(0,math.min(100,tonumber(p) or 0));rect(x,y,w,1,UI.C.panel2);local n=math.floor(w*p/100);if n>0 then rect(x,y,n,1,c) end end
local function led(x,y,on,c,label) rect(x,y,2,1,on and c or UI.C.off);txt(x+3,y,label,on and c or UI.C.muted,UI.C.panel) end
local function gateGraphic(cx,cy,r,state,chev) 
 local active=(state=="Connected" or state=="Opening" or state=="Dialling")
 local spin=math.floor(os.clock()*4)%4
 local rings={"◉","◎","◌","○"}
 txt(cx-1,cy-1,rings[spin+1],active and UI.C.cyan or UI.C.muted,UI.C.panel)
 txt(cx-2,cy+1,active and "STARGATE" or "OFFLINE",active and UI.C.cyan or UI.C.muted,UI.C.panel)
 for i=1,9 do local x=cx-14+(i-1)*3;local on=i<=tonumber(chev or 0);rect(x,cy+r+2,2,1,on and UI.C.cyan or UI.C.off);txt(x,cy+r+3,tostring(i),on and UI.C.cyan or UI.C.muted,UI.C.panel) end
 txt(cx-15,cy+r+5,active and "◈ WORMHOLE ACTIVE ◈" or "GATE STANDBY",active and UI.C.green or UI.C.muted,UI.C.panel)
end
function UI.draw(d)
 UI.resize();UI.buttons={};gpu.setBackground(UI.C.bg);gpu.fill(1,1,UI.W,UI.H," ")
 rect(1,1,UI.W,4,UI.C.panel);txt(2,1,"◈ BULDACITY",UI.C.cyan,UI.C.panel);txt(15,1,"// SGCraft COMMAND",UI.C.white,UI.C.panel);txt(math.max(1,UI.W-17),1,"1.7.10 / v3",UI.C.muted,UI.C.panel);txt(2,2,fit(d.title or "STARGATE CONTROL",UI.W-4),UI.C.muted,UI.C.panel);rect(1,4,UI.W,1,UI.C.cyan)
 local left=2;local lw=math.max(24,math.floor(UI.W*.23));local right=left+lw+2;local rw=UI.W-right-1
 panel(left,6,lw,UI.H-9,"GATE FLEET",UI.C.blue)
 if #d.gates==0 then txt(left+2,9,"NO INTERFACES",UI.C.red,UI.C.panel);txt(left+2,11,"SCAN REQUIRED",UI.C.muted,UI.C.panel) else for i,g in ipairs(d.gates) do local y=8+(i-1)*3;if y>UI.H-5 then break end;local on=i==d.selected;rect(left+1,y,lw-2,2,on and UI.C.panel2 or UI.C.panel,on and UI.C.cyan or UI.C.line);txt(left+3,y,(on and "▶ " or "  ")..i,UI.C.cyan, on and UI.C.panel2 or UI.C.panel);txt(left+8,y,fit(g.address,14),UI.C.white,on and UI.C.panel2 or UI.C.panel);led(left+8,y+1,g.state=="Connected",g.state=="Connected" and UI.C.green or UI.C.blue,g.state or "Offline") end end
 panel(right,6,rw,UI.H-9,"LIVE GATE TELEMETRY",UI.C.cyan)
 local g=d.gate
 if not g then txt(right+3,9,"Select a Stargate Interface",UI.C.red,UI.C.panel);txt(right+3,11,"Use SCAN to discover gates.",UI.C.muted,UI.C.panel) else
  local gx=right+math.floor(rw*.46);local gy=12;gateGraphic(gx,gy,7,g.state,g.chevrons)
  txt(right+3,8,"STATE",UI.C.muted,UI.C.panel);txt(right+13,8,fit(g.state or "Unknown",14),g.state=="Connected" and UI.C.green or UI.C.white,UI.C.panel)
  txt(right+3,10,"DIRECTION",UI.C.muted,UI.C.panel);txt(right+15,10,fit(g.direction or "-",12),UI.C.white,UI.C.panel)
  txt(right+3,12,"LOCAL",UI.C.muted,UI.C.panel);txt(right+3,13,fit(g.local or "-",16),UI.C.white,UI.C.panel)
  txt(right+3,15,"REMOTE",UI.C.muted,UI.C.panel);txt(right+3,16,fit(g.remote or "-",16),UI.C.cyan,UI.C.panel)
  txt(right+3,18,"CHEVRONS",UI.C.muted,UI.C.panel);txt(right+14,18,tostring(g.chevrons or 0).." / 9",UI.C.cyan,UI.C.panel)
  txt(right+3,20,"ENERGY",UI.C.muted,UI.C.panel);txt(right+13,20,tostring(g.energy or 0).." SU",UI.C.yellow,UI.C.panel);bar(right+3,21,math.max(10,rw-7),d.energyPct,UI.C.yellow)
  txt(right+3,23,"IRIS",UI.C.muted,UI.C.panel);txt(right+10,23,g.iris or "-",g.iris=="Closed" and UI.C.green or UI.C.yellow,UI.C.panel)
  end
 local y=UI.H-4;local labels={{"status","STATUS",UI.C.cyan},{"gates","GATES",UI.C.blue},{"dial","DIAL",UI.C.purple},{"iris","IRIS",UI.C.yellow},{"link","LINK",UI.C.green},{"scan","SCAN",UI.C.cyan}};local bw=math.max(8,math.floor((UI.W-3-#labels*1)/#labels));local x=2;for _,b in ipairs(labels) do UI.button(b[1],x,y,bw,b[2],b[3],d.page==b[1]);x=x+bw+1 end
 txt(2,UI.H-1,"TAB NEXT   D DIAL   X DISCONNECT   O/C IRIS   M MESSAGE   Q EXIT",UI.C.muted,UI.C.bg)
end
return UI
