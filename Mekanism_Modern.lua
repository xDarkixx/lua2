-- Mekanism_Modern.lua
-- BULDACITY // UNIFIED MEKANISM COMMAND
-- Minecraft 1.7.10
-- Mekanism-1.7.10-9.1.1.1031
-- MekanismGenerators-1.7.10-9.1.1.1031
-- MekanismTools-1.7.10-9.1.1.1031
-- One dashboard for all three Mekanism modules.
-- Safe OC discovery: no PRIMARY requirement and no invented component methods.

local component=require("component")
local event=require("event")
local gpu=component.gpu
local W,H=gpu.getResolution()
local running=true
local page=1
local selected=1
local devices={}
local C={bg=0x04050B,panel=0x0A1020,cyan=0x00E5FF,blue=0x2488FF,purple=0xB54CFF,green=0x39FF88,yellow=0xFFE45C,red=0xFF4568,white=0xEAF6FF,dim=0x71809A}
local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function safe(p,m,...)
 if not p or type(p[m])~="function" then return nil end
 local ok,a,b,c,d,e=pcall(p[m],...);if ok then return a,b,c,d,e end
end
local function text(x,y,s,c) if x>=1 and y>=1 and x<=W and y<=H then gpu.setForeground(c or C.white);gpu.set(x,y,tostring(s or "")) end end
local function box(x,y,w,h,c) if w>0 and h>0 then gpu.setBackground(c);gpu.fill(x,y,w,h," ") end end
local function line(x,y,w,c) box(x,y,w,1,c) end
local function pct(v,m) v=tonumber(v) or 0;m=tonumber(m) or 0;if m<=0 then return 0 end;return clamp(v/m*100,0,100) end
local function bar(x,y,w,p,c,label) p=clamp(tonumber(p) or 0,0,100);box(x,y,w,1,C.panel);local n=math.floor(w*p/100);if n>0 then box(x,y,n,1,c) end;text(x,y,label or string.format("%5.1f%%",p),C.white) end
local function family(t)
 t=tostring(t or ""):lower()
 if t:find("generator") or t:find("solar") or t:find("gas") or t:find("wind") or t:find("bio") or t:find("reactor") or t:find("turbine") then return "GENERATORS" end
 if t:find("tool") or t:find("armour") or t:find("armor") then return "TOOLS" end
 return "MEKANISM CORE"
end
local function classify(t)
 t=tostring(t or ""):lower()
 if t:find("digital") then return "DIGITAL MINER" end
 if t:find("induction") then return "INDUCTION" end
 if t:find("generator") then return "GENERATOR" end
 if t:find("solar") then return "SOLAR" end
 if t:find("reactor") then return "REACTOR" end
 if t:find("turbine") then return "TURBINE" end
 if t:find("gas") then return "GAS" end
 if t:find("factory") then return "FACTORY" end
 if t:find("machine") then return "MACHINE" end
 if t:find("energy") then return "ENERGY" end
 if t:find("fluid") then return "FLUID" end
 if t:find("tool") or t:find("armor") or t:find("armour") then return "TOOLS" end
 return string.upper(t)
end
local function scan()
 devices={}
 for address,ctype in component.list() do
  local s=tostring(ctype):lower()
  if s:find("mekanism") or s:find("digital") or s:find("induction") or s:find("factory") or s:find("generator") or s:find("solar") or s:find("reactor") or s:find("turbine") or s:find("energy") or s:find("fluid") or s:find("gas") or s:find("tool") or s:find("armor") or s:find("armour") then
   devices[#devices+1]={address=address,type=ctype,name=classify(ctype),family=family(ctype),proxy=component.proxy(address)}
  end
 end
 table.sort(devices,function(a,b)return (a.family..a.name..a.address)<(b.family..b.name..b.address) end)
 selected=clamp(selected,1,math.max(1,#devices))
end
local function energy(p)
 local a=safe(p,"getEnergyStored")
 local m=safe(p,"getMaxEnergyStored") or safe(p,"getEnergyStoredMax")
 if tonumber(a) and tonumber(m) and tonumber(m)>0 then return tonumber(a),tonumber(m),pct(a,m) end
end
local function tank(p)
 for i=0,5 do
  local t=safe(p,"getTankInfo",i)
  if type(t)=="table" then
   local q=t[1] or t
   if type(q)=="table" then local cap=tonumber(q.capacity);local f=q.fluid;if cap and type(f)=="table" then return f.name or "FLUID",tonumber(f.amount) or 0,cap,pct(f.amount,cap) end end
  end
 end
end
local function header()
 box(1,1,W,H,C.bg);box(1,1,W,3,C.panel);text(2,2,"BULDACITY // MEKANISM COMMAND",C.cyan);text(math.max(2,W-29),2,"9.1.1.1031 // MC 1.7.10",C.dim);line(1,4,W,C.blue)
end
local function footer()
 line(1,H-2,W,C.blue);text(2,H-1,"[1] CORE  [2] MACHINES  [3] GENERATORS  [4] ENERGY/FLUID  [5] TOOLS  [S] SCAN  [Q] EXIT",C.cyan)
end
local function overview()
 text(2,6,"MEKANISM COMMAND CENTER",C.cyan)
 local core,gen,tools=0,0,0
 for _,d in ipairs(devices) do if d.family=="GENERATORS" then gen=gen+1 elseif d.family=="TOOLS" then tools=tools+1 else core=core+1 end end
 box(2,9,22,8,C.panel);text(4,11,"CORE",C.purple);text(4,13,"COMPONENTS: "..core,C.white);text(4,15,core>0 and "ONLINE" or "NOT EXPOSED",core>0 and C.green or C.yellow)
 box(26,9,22,8,C.panel);text(28,11,"GENERATORS",C.cyan);text(28,13,"COMPONENTS: "..gen,C.white);text(28,15,gen>0 and "ONLINE" or "NOT EXPOSED",gen>0 and C.green or C.yellow)
 box(50,9,22,8,C.panel);text(52,11,"TOOLS",C.cyan);text(52,13,"COMPONENTS: "..tools,C.white);text(52,15,tools>0 and "AVAILABLE" or "MODULE ONLY",tools>0 and C.green or C.yellow)
 box(2,19,W-3,H-23,C.panel);text(4,21,"UNIFIED MODULE TARGET",C.purple);text(4,23,"Mekanism 9.1.1.1031",C.white);text(4,24,"MekanismGenerators 9.1.1.1031",C.white);text(4,25,"MekanismTools 9.1.1.1031",C.white);text(4,27,"PRIMARY REQUIRED: NO",C.green);text(4,29,"CONTROL POLICY: only APIs actually exposed by the detected OC component are called.",C.dim);text(4,31,"Use pages 2-5 for live telemetry and device selection.",C.cyan)
end
local function listPage(title,filter)
 text(2,6,title,C.cyan);box(2,8,30,H-12,C.panel);text(4,9,"DEVICE MATRIX",C.purple);line(3,10,28,C.purple)
 local list={};for _,d in ipairs(devices) do if not filter or filter(d) then list[#list+1]=d end end
 if #list==0 then text(35,11,"NO MATCHING COMPONENT EXPOSED",C.yellow);text(35,13,"This can be normal when the OC integration does not expose a module directly.",C.dim);return end
 for i,d in ipairs(list) do local y=10+i;if y>=H-3 then break end;if i==selected then box(3,y,28,1,C.blue);text(4,y,d.name,C.white) else text(4,y,d.name,C.dim) end end
 local d=list[clamp(selected,1,#list)];local x=35;local rw=W-x-1;box(x,8,rw,H-12,C.panel);text(x+3,10,d.name,C.cyan);text(x+3,11,d.family,C.purple);text(x+3,12,d.type,C.dim);text(x+3,13,d.address,C.dim)
 local e,m,p=energy(d.proxy);if e then text(x+3,16,"ENERGY",C.white);text(x+3,17,string.format("%s / %s RF",math.floor(e),math.floor(m)),C.white);bar(x+3,18,rw-6,p,C.cyan,string.format("%5.1f%%",p)) else text(x+3,16,"ENERGY: NO COMPATIBLE API",C.dim) end
 local fn,fa,fm,fp=tank(d.proxy);if fn then text(x+3,21,"TANK",C.white);text(x+3,22,string.format("%s  %s / %s mB",fn,math.floor(fa),math.floor(fm)),C.white);bar(x+3,23,rw-6,fp,C.blue,string.format("%5.1f%%",fp)) end
 text(x+3,27,"SAFE CONTROL",C.purple);text(x+3,29,"Read-only telemetry is automatic; control is only enabled when a real OC method exists.",C.dim);text(x+3,31,"No fake generator/reactor/tool commands are issued.",C.green)
end
local function draw()
 header();if page==1 then overview() elseif page==2 then listPage("MEKANISM // MACHINES",function(d)return d.family=="MEKANISM CORE" end) elseif page==3 then listPage("MEKANISM GENERATORS // POWER",function(d)return d.family=="GENERATORS" end) elseif page==4 then listPage("MEKANISM // ENERGY + FLUID",function(d)return energy(d.proxy)~=nil or tank(d.proxy)~=nil end) elseif page==5 then listPage("MEKANISM TOOLS // MODULE",function(d)return d.family=="TOOLS" end) end;footer()
end
scan();draw()
while running do
 local e=event.pull(0.5)
 if e then
  if e[1]=="key_down" then local ch=e[3];if ch==113 then running=false elseif ch==115 then scan();draw() elseif ch>=49 and ch<=53 then page=ch-48;selected=1;draw() elseif ch==200 then selected=clamp(selected-1,1,math.max(1,#devices));draw() elseif ch==208 then selected=clamp(selected+1,1,math.max(1,#devices));draw() end
  elseif e[1]=="touch" then local x=e[3] or 0;local y=e[4] or 0;if y==H-1 then if x<12 then page=1 elseif x<27 then page=2 elseif x<43 then page=3 elseif x<59 then page=4 elseif x<70 then page=5 elseif x<78 then scan() end;selected=1;draw() elseif x<=32 and y>=11 and y<=H-4 then local i=y-10;if i>=1 and i<=#devices then selected=i;draw() end end end
 end
end
gpu.setBackground(0);gpu.setForeground(0xFFFFFF);gpu.fill(1,1,W,H," ")
