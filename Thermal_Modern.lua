-- Thermal_Modern.lua
-- BULDACITY // UNIFIED THERMAL CONTROL
-- Minecraft 1.7.10
-- Thermal Expansion 4.1.5-248
-- Thermal Dynamics 1.2.1-172
-- Thermal Foundation 1.2.6-118
-- OpenComputers compatible component discovery; no PRIMARY requirement.

local component=require("component")
local event=require("event")
local gpu=component.gpu
local W,H=gpu.getResolution()
local running=true
local page=1
local selected=1
local devices={}
local lastScan=0
local C={bg=0x05060D,panel=0x0B1020,cyan=0x00E5FF,orange=0xFF8A2B,purple=0xB54CFF,green=0x39FF88,yellow=0xFFE45C,red=0xFF4568,white=0xEAF6FF,dim=0x71809A}

local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function safe(p,m,...)
 if not p or type(p[m])~="function" then return nil end
 local ok,a,b,c,d,e=pcall(p[m],...);if ok then return a,b,c,d,e end
end
local function text(x,y,s,c) if x<1 or y<1 or x>W or y>H then return end;gpu.setForeground(c or C.white);gpu.set(x,y,tostring(s or "")) end
local function box(x,y,w,h,c) if w>0 and h>0 then gpu.setBackground(c);gpu.fill(x,y,w,h," ") end end
local function line(x,y,w,c) box(x,y,w,1,c) end
local function pct(v,m) v=tonumber(v) or 0;m=tonumber(m) or 0;if m<=0 then return 0 end;return clamp(v/m*100,0,100) end
local function bar(x,y,w,p,c,label)
 p=clamp(tonumber(p) or 0,0,100);box(x,y,w,1,C.panel);local n=math.floor(w*p/100);if n>0 then box(x,y,n,1,c or C.cyan) end;text(x,y,label or string.format("%5.1f%%",p),C.white)
end
local function classify(t)
 t=tostring(t or ""):lower()
 if t:find("dynamo") then return "DYNAMO" end
 if t:find("pulver") then return "PULVERIZER" end
 if t:find("sawmill") then return "SAWMILL" end
 if t:find("centrif") then return "CENTRIFUGE" end
 if t:find("redstone") then return "REDSTONE" end
 if t:find("transposer") then return "TRANSPOSER" end
 if t:find("fluid") or t:find("tank") then return "FLUID" end
 if t:find("machine") then return "MACHINE" end
 if t:find("thermal") then return "THERMAL" end
 return string.upper(t)
end
local function family(t)
 t=tostring(t or ""):lower()
 if t:find("dynamo") or t:find("pulver") or t:find("sawmill") or t:find("machine") then return "THERMAL EXPANSION" end
 if t:find("duct") or t:find("transposer") or t:find("servo") then return "THERMAL DYNAMICS" end
 return "THERMAL / OC"
end
local function scan()
 devices={}
 for address,ctype in component.list() do
  local s=tostring(ctype):lower()
  if s:find("thermal") or s:find("dynamo") or s:find("pulver") or s:find("sawmill") or s:find("machine") or s:find("duct") or s:find("transposer") or s:find("servo") or s:find("fluid") or s:find("tank") then
   local p=component.proxy(address)
   devices[#devices+1]={address=address,type=ctype,name=classify(ctype),family=family(ctype),proxy=p}
  end
 end
 table.sort(devices,function(a,b)return (a.name..a.address)<(b.name..b.address) end)
 selected=clamp(selected,1,math.max(1,#devices));lastScan=os.time()
end
local function energy(p)
 local a=safe(p,"getEnergyStored");local m=safe(p,"getMaxEnergyStored") or safe(p,"getEnergyStoredMax")
 if tonumber(a) and tonumber(m) and tonumber(m)>0 then return a,m,pct(a,m) end
end
local function fluid(p)
 local t=safe(p,"getTankInfo",0)
 if type(t)=="table" then
  local q=t[1] or t
  if type(q)=="table" then
   local cap=tonumber(q.capacity);local f=q.fluid
   if cap and type(f)=="table" then return f.name or "FLUID",tonumber(f.amount) or 0,cap,pct(tonumber(f.amount) or 0,cap) end
  end
 end
end
local function header()
 box(1,1,W,H,C.bg);box(1,1,W,3,C.panel)
 text(2,2,"BULDACITY // THERMAL COMMAND",C.orange)
 text(math.max(2,W-37),2,"TE 4.1.5-248 | TD 1.2.1-172",C.dim)
 text(math.max(2,W-16),3,"TF 1.2.6-118",C.dim)
 line(1,4,W,C.orange)
end
local function footer()
 line(1,H-2,W,C.orange)
 text(2,H-1,"[1] OVERVIEW  [2] MACHINES  [3] DYNAMOS  [4] FLUID  [S] SCAN  [Q] EXIT",C.cyan)
end
local function drawOverview()
 text(2,6,"THERMAL NETWORK",C.orange);text(2,8,"EXPANSION",C.white);text(2,9,"Machines / Dynamos / Processing",C.dim)
 text(32,8,"DYNAMICS",C.white);text(32,9,"Ducts / Item / Fluid transport",C.dim)
 text(62,8,"FOUNDATION",C.white);text(62,9,"Shared materials / fluids / energy",C.dim)
 box(2,12,W-3,H-16,C.panel)
 text(4,14,"SYSTEM STATUS",C.purple)
 text(4,16,"THERMAL COMPONENTS",#devices>0 and C.green or C.red)
 text(4,18,"Detected devices: "..#devices,C.white)
 text(4,20,"Unified controller: ONLINE",C.green)
 text(4,22,"Primary component required: NO",C.green)
 text(4,24,"Live telemetry: SAFE / METHOD-CHECKED",C.cyan)
 text(4,26,"Use [2]-[4] to inspect available devices.",C.dim)
end
local function drawList(title)
 text(2,6,title,C.orange)
 box(2,8,31,H-12,C.panel);text(4,9,"DEVICE MATRIX",C.purple);line(3,10,29,C.purple)
 local max=math.max(1,math.min(#devices,H-14))
 for i=1,max do local d=devices[i];local yy=10+i
  if i==selected then box(3,yy,29,1,C.orange);text(4,yy,d.name,C.white) else text(4,yy,d.name,C.dim) end
 end
 local x=35;local rw=W-x-1;box(x,8,rw,H-12,C.panel)
 if #devices==0 then text(x+3,11,"NO THERMAL COMPONENT DETECTED",C.yellow);text(x+3,13,"Press S after connecting the OC integration.",C.dim);return end
 local d=devices[selected];text(x+3,10,d.name,C.orange);text(x+3,11,d.family,C.purple);text(x+3,12,d.type,C.dim);text(x+3,13,d.address,C.dim)
 local e,m,p=energy(d.proxy)
 if e then text(x+3,16,"ENERGY",C.white);text(x+3,17,string.format("%s / %s RF",math.floor(e),math.floor(m)),C.white);bar(x+3,18,rw-6,p,C.cyan) else text(x+3,16,"ENERGY",C.white);text(x+3,17,"No compatible energy API exposed.",C.dim) end
 local fn,fa,fm,fp=fluid(d.proxy)
 if fn then text(x+3,21,"FLUID",C.white);text(x+3,22,string.format("%s: %s / %s mB",fn,math.floor(fa),math.floor(fm)),C.white);bar(x+3,23,rw-6,fp,C.orange) end
 text(x+3,27,"SAFE CONTROL",C.purple);text(x+3,29,"Only detected methods are callable.",C.dim);text(x+3,30,"No invented machine API calls.",C.green)
end
local function draw()
 header()
 if page==1 then drawOverview() elseif page==2 then drawList("THERMAL EXPANSION // MACHINES") elseif page==3 then drawList("THERMAL EXPANSION // DYNAMOS") elseif page==4 then drawList("THERMAL FOUNDATION / DYNAMICS // FLUID") end
 footer()
end
scan();draw()
while running do
 local e=event.pull(0.5)
 if e then
  if e[1]=="key_down" then
   local ch=e[3]
   if ch==113 then running=false
   elseif ch==49 then page=1;draw()
   elseif ch==50 then page=2;draw()
   elseif ch==51 then page=3;draw()
   elseif ch==52 then page=4;draw()
   elseif ch==115 then scan();draw()
   elseif ch==200 then selected=clamp(selected-1,1,math.max(1,#devices));draw()
   elseif ch==208 then selected=clamp(selected+1,1,math.max(1,#devices));draw() end
  elseif e[1]=="touch" then
   local x=e[3] or 0;local y=e[4] or 0
   if y==H-1 then
    if x<15 then page=1 elseif x<30 then page=2 elseif x<45 then page=3 elseif x<60 then page=4 elseif x<70 then scan() end;draw()
   elseif page>1 and x<=33 and y>=11 and y<=H-4 then local i=y-10;if i>=1 and i<=#devices then selected=i;draw() end end
  end
 end
end
gpu.setBackground(0);gpu.setForeground(0xFFFFFF);gpu.fill(1,1,W,H," ")
