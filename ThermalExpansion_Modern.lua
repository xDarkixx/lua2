-- ThermalExpansion_Modern.lua
-- BULDACITY NEON HUD / Thermal Expansion 4.1.5-248 / OpenComputers / MC 1.7.10
-- Safe component discovery. Works with exposed OpenComputers/OpenComponents adapters.

local component=require("component")
local event=require("event")
local gpu=component.gpu
local W,H=gpu.getResolution()
local C={bg=0x05060D,panel=0x0B1020,cyan=0x00E5FF,orange=0xFF8A2B,purple=0xB54CFF,green=0x39FF88,yellow=0xFFE45C,red=0xFF4568,white=0xEAF6FF,dim=0x71809A}
local running=true
local selected=1
local devices={}
local status="SCANNING THERMAL EXPANSION..."

local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function safe(p,m,...)
  if not p or type(p[m])~="function" then return nil end
  local ok,a,b,c,d=pcall(p[m],...); if ok then return a,b,c,d end
end
local function text(x,y,s,c) gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or "")) end
local function box(x,y,w,h,c) gpu.setBackground(c); gpu.fill(x,y,w,h," ") end
local function line(x,y,w,c) box(x,y,w,1,c) end
local function pct(v,m) v=tonumber(v) or 0;m=tonumber(m) or 0;if m<=0 then return 0 end;return clamp(v/m*100,0,100) end
local function bar(x,y,w,p,label)
 p=clamp(tonumber(p) or 0,0,100);box(x,y,w,1,C.panel);local n=math.floor(w*p/100);if n>0 then box(x,y,n,1,C.orange) end;text(x,y,label or string.format("%5.1f%%",p),C.white)
end
local function classify(t)
 t=tostring(t or ""):lower()
 if t:find("dynamo") then return "REDSTONE FLUX DYNAMO" end
 if t:find("pulver") then return "PULVERIZER" end
 if t:find("sawmill") then return "SAWMILL" end
 if t:find("redstone") then return "REDSTONE MACHINE" end
 if t:find("furnace") then return "FURNACE" end
 if t:find("cell") or t:find("tank") then return "FLUID STORAGE" end
 if t:find("machine") then return "THERMAL MACHINE" end
 return string.upper(t)
end
local function scan()
 devices={}
 for address,ctype in component.list() do
  local s=tostring(ctype):lower()
  if s:find("thermal") or s:find("dynamo") or s:find("pulver") or s:find("sawmill") or s:find("redstone") or s:find("machine") or s:find("tank") or s:find("cell") then
   devices[#devices+1]={address=address,type=ctype,name=classify(ctype),proxy=component.proxy(address)}
  end
 end
 table.sort(devices,function(a,b)return a.name<b.name end)
 selected=clamp(selected,1,math.max(1,#devices));status=(#devices>0 and "THERMAL COMPONENTS ONLINE" or "NO THERMAL COMPONENT FOUND")
end
local function energy(p)
 local a=safe(p,"getEnergyStored");local m=safe(p,"getMaxEnergyStored") or safe(p,"getEnergyStoredMax")
 if tonumber(a) and tonumber(m) and tonumber(m)>0 then return a,m,pct(a,m) end
end
local function draw()
 box(1,1,W,H,C.bg);box(1,1,W,3,C.panel);text(2,2,"BULDACITY // THERMAL EXPANSION CONTROL",C.orange);text(math.max(2,W-24),2,"4.1.5-248 // MC1.7.10",C.dim);line(1,4,W,C.orange)
 text(2,5,status,C.green);text(math.max(2,W-18),5,"DEVICES: "..#devices,C.white)
 local left=2;local top=7;local lw=28;box(left,top,lw,H-top-2,C.panel);text(left+2,top+1,"THERMAL COMPONENTS",C.purple);line(left+1,top+2,lw-2,C.purple)
 for i=1,math.min(#devices,H-top-5) do local d=devices[i];local yy=top+2+i;if i==selected then box(left+1,yy,lw-2,1,C.orange);text(left+2,yy,d.name,C.white) else text(left+2,yy,d.name,C.dim) end end
 local x=32;local y=7;local rw=W-x-1;box(x,y,rw,H-y-2,C.panel)
 if #devices==0 then text(x+3,y+2,"NO THERMAL COMPONENT DETECTED",C.yellow);text(x+3,y+4,"Install/enable an OpenComputers adapter integration if needed.",C.dim);text(x+3,y+6,"Press S to scan again.",C.cyan);return end
 local d=devices[selected];text(x+2,y+1,d.name,C.orange);text(x+2,y+2,d.address,C.dim)
 local e,m,p=energy(d.proxy)
 if e then text(x+2,y+5,"ENERGY STORAGE",C.white);text(x+2,y+7,string.format("%s / %s RF",math.floor(e),math.floor(m)),C.white);bar(x+2,y+9,rw-4,p,string.format("%5.1f%%",p)) else text(x+2,y+5,"TELEMETRY",C.white);text(x+2,y+7,"No compatible energy method exposed.",C.dim) end
 text(x+2,y+12,"SAFE MACHINE MONITOR",C.purple);text(x+2,y+14,"Only methods actually exposed by the detected component are used.",C.dim);text(x+2,y+16,"No PRIMARY Thermal component is required.",C.green)
 text(x+2,y+19,"[ S ] SCAN     [ UP/DOWN ] SELECT     [ Q ] EXIT",C.cyan);text(x+2,y+21,"Thermal Expansion 4.1.5-248 target confirmed.",C.dim)
end
scan();draw()
while running do
 local e=event.pull(0.5)
 if e then
  if e[1]=="key_down" then local ch=e[3];if ch==113 then running=false elseif ch==115 then scan();draw() elseif ch==200 then selected=clamp(selected-1,1,math.max(1,#devices));draw() elseif ch==208 then selected=clamp(selected+1,1,math.max(1,#devices));draw() end
  elseif e[1]=="touch" then local x=e[3] or 0;local yy=e[4] or 0;if x<=30 and yy>=9 and yy<=H-4 then local i=yy-9;if i>=1 and i<=#devices then selected=i;draw() end end end
 end
end
gpu.setBackground(0);gpu.setForeground(0xFFFFFF);gpu.fill(1,1,W,H," ")
