-- ProjectE_Modern.lua
-- BULDACITY // PROJECTE COMMAND CENTER
-- Minecraft 1.7.10 / ProjectE-1.7.10-PE1.10.1
-- Unified OpenComputers dashboard.
-- ProjectE exposes ProjectEAPI, but direct OC components depend on the installed OC integration.
-- This controller therefore discovers real OC components and never invents methods.

local component=require("component")
local event=require("event")
local gpu=component.gpu
local W,H=gpu.getResolution()
local running=true
local page=1
local selected=1
local devices={}
local C={bg=0x05030A,panel=0x10091A,cyan=0x00E5FF,blue=0x4B7CFF,purple=0xC14CFF,pink=0xFF4FD8,green=0x39FF88,yellow=0xFFE45C,red=0xFF4568,white=0xF4EDFF,dim=0x7D7190}
local function clamp(v,a,b)if v<a then return a elseif v>b then return b end return v end
local function safe(p,m,...)
 if not p or type(p[m])~="function" then return nil end
 local ok,a,b,c,d,e=pcall(p[m],...);if ok then return a,b,c,d,e end
end
local function text(x,y,s,c)if x>=1 and y>=1 and x<=W and y<=H then gpu.setForeground(c or C.white);gpu.set(x,y,tostring(s or ""))end end
local function box(x,y,w,h,c)if w>0 and h>0 then gpu.setBackground(c);gpu.fill(x,y,w,h," ")end end
local function line(x,y,w,c)box(x,y,w,1,c)end
local function pct(v,m)v=tonumber(v)or 0;m=tonumber(m)or 0;if m<=0 then return 0 end;return clamp(v/m*100,0,100)end
local function bar(x,y,w,p,c,label)p=clamp(tonumber(p)or 0,0,100);box(x,y,w,1,C.panel);local n=math.floor(w*p/100);if n>0 then box(x,y,n,1,c)end;text(x,y,label or string.format("%5.1f%%",p),C.white)end
local function classify(t)
 t=tostring(t or ""):lower()
 if t:find("transmut")then return "TRANSMUTATION" end
 if t:find("collector")then return "ENERGY COLLECTOR" end
 if t:find("relay")then return "ENERGY RELAY" end
 if t:find("condenser")then return "CONDENSER" end
 if t:find("emc")then return "EMC" end
 if t:find("energy")then return "ENERGY" end
 if t:find("item")then return "ITEM" end
 if t:find("inventory")then return "INVENTORY" end
 if t:find("fluid")or t:find("tank")then return "FLUID" end
 return string.upper(t)
end
local function family(t)
 t=tostring(t or ""):lower()
 if t:find("collector")or t:find("relay")or t:find("condenser")or t:find("energy")then return "ENERGY"end
 if t:find("transmut")or t:find("emc")then return "TRANSMUTATION"end
 if t:find("fluid")or t:find("tank")then return "FLUID"end
 return "PROJECTE / OC"
end
local function scan()
 devices={}
 for address,ctype in component.list()do
  local s=tostring(ctype):lower()
  if s:find("projecte")or s:find("transmut")or s:find("collector")or s:find("relay")or s:find("condenser")or s:find("emc")or s:find("energy")or s:find("fluid")or s:find("tank")or s:find("inventory")then
   devices[#devices+1]={address=address,type=ctype,name=classify(ctype),family=family(ctype),proxy=component.proxy(address)}
  end
 end
 table.sort(devices,function(a,b)return(a.family..a.name..a.address)<(b.family..b.name..b.address)end)
 selected=clamp(selected,1,math.max(1,#devices))
end
local function energy(p)
 local a=safe(p,"getEnergyStored");local m=safe(p,"getMaxEnergyStored")or safe(p,"getEnergyStoredMax")
 if tonumber(a)and tonumber(m)and tonumber(m)>0 then return tonumber(a),tonumber(m),pct(a,m)end
end
local function tank(p)
 for i=0,5 do local t=safe(p,"getTankInfo",i);if type(t)=="table"then local q=t[1]or t;if type(q)=="table"then local cap=tonumber(q.capacity);local f=q.fluid;if cap and type(f)=="table"then return f.name or "FLUID",tonumber(f.amount)or 0,cap,pct(f.amount,cap)end end end end
end
local function header()
 box(1,1,W,H,C.bg);box(1,1,W,3,C.panel);text(2,2,"BULDACITY // PROJECTE COMMAND",C.pink);text(math.max(2,W-26),2,"PE1.10.1 // MC 1.7.10",C.dim);line(1,4,W,C.purple)
end
local function footer()
 line(1,H-2,W,C.purple);text(2,H-1,"[1] CORE  [2] ENERGY  [3] TRANSMUTE  [4] FLUID  [5] SYSTEM  [S] SCAN  [Q] EXIT",C.cyan)
end
local function overview()
 text(2,6,"PROJECTE // EQUIVALENT EXCHANGE COMMAND CENTER",C.pink)
 local en,tr,fl,ot=0,0,0,0
 for _,d in ipairs(devices)do if d.family=="ENERGY"then en=en+1 elseif d.family=="TRANSMUTATION"then tr=tr+1 elseif d.family=="FLUID"then fl=fl+1 else ot=ot+1 end end
 local cards={{"ENERGY",en,C.cyan},{"TRANSMUTATION",tr,C.pink},{"FLUID",fl,C.blue},{"OC",ot,C.purple}}
 for i,v in ipairs(cards)do local x=2+(i-1)*18;box(x,9,16,7,C.panel);text(x+2,10,v[1],v[3]);text(x+2,12,"FOUND: "..v[2],C.white);text(x+2,14,v[2]>0 and "ONLINE"or"NOT EXPOSED",v[2]>0 and C.green or C.yellow)end
 box(2,18,W-3,H-22,C.panel);text(4,20,"PROJECTE TARGET",C.purple);text(4,22,"ProjectE-1.7.10-PE1.10.1",C.white);text(4,24,"ProjectEAPI is present in this legacy build.",C.dim);text(4,26,"OPENCOMPUTERS INTEGRATION: AUTO-DISCOVER",C.cyan);text(4,28,"No PRIMARY component required.",C.green);text(4,30,"Only methods that actually exist on the detected OC proxy are called.",C.dim)
end
local function listPage(title,filter)
 text(2,6,title,C.pink);box(2,8,29,H-12,C.panel);text(4,9,"DEVICE MATRIX",C.purple);line(3,10,27,C.purple)
 local list={};for _,d in ipairs(devices)do if not filter or filter(d)then list[#list+1]=d end end
 if #list==0 then text(34,11,"NO DIRECT OC COMPONENT EXPOSED",C.yellow);text(34,13,"ProjectE itself can still be installed; direct computer control depends on the OC integration available in the pack.",C.dim);return end
 for i,d in ipairs(list)do local y=10+i;if y>=H-3 then break end;if i==selected then box(3,y,27,1,C.purple);text(4,y,d.name,C.white)else text(4,y,d.name,C.dim)end end
 local idx=clamp(selected,1,#list);local d=list[idx];local x=33;local rw=W-x-1;box(x,8,rw,H-12,C.panel);text(x+3,10,d.name,C.pink);text(x+3,11,d.family,C.purple);text(x+3,12,d.type,C.dim);text(x+3,13,d.address,C.dim)
 local e,m,p=energy(d.proxy);if e then text(x+3,16,"ENERGY STORAGE",C.white);text(x+3,17,string.format("%s / %s RF",math.floor(e),math.floor(m)),C.white);bar(x+3,18,rw-6,p,C.cyan,string.format("%5.1f%%",p))else text(x+3,16,"ENERGY: NO COMPATIBLE API",C.dim)end
 local fn,fa,fm,fp=tank(d.proxy);if fn then text(x+3,21,"FLUID",C.white);text(x+3,22,string.format("%s  %s / %s mB",fn,math.floor(fa),math.floor(fm)),C.white);bar(x+3,23,rw-6,fp,C.blue,string.format("%5.1f%%",fp))end
 text(x+3,27,"SAFE CONTROL",C.purple);text(x+3,29,"Telemetry is live when the component exposes the method.",C.dim);text(x+3,31,"No fake ProjectE API commands are sent.",C.green)
end
local function draw()
 header();if page==1 then overview()elseif page==2 then listPage("PROJECTE // ENERGY",function(d)return d.family=="ENERGY"end)elseif page==3 then listPage("PROJECTE // TRANSMUTATION",function(d)return d.family=="TRANSMUTATION"end)elseif page==4 then listPage("PROJECTE // FLUID",function(d)return d.family=="FLUID"end)elseif page==5 then listPage("PROJECTE // ALL OC COMPONENTS",nil)end;footer()
end
scan();draw()
while running do
 local e=event.pull(0.5)
 if e then
  if e[1]=="key_down"then local ch=e[3];if ch==113 then running=false elseif ch==115 then scan();draw()elseif ch>=49 and ch<=53 then page=ch-48;selected=1;draw()elseif ch==200 then selected=clamp(selected-1,1,math.max(1,#devices));draw()elseif ch==208 then selected=clamp(selected+1,1,math.max(1,#devices));draw()end
  elseif e[1]=="touch"then local x=e[3]or 0;local y=e[4]or 0;if y==H-1 then if x<12 then page=1 elseif x<27 then page=2 elseif x<43 then page=3 elseif x<59 then page=4 elseif x<73 then page=5 elseif x<82 then scan()end;selected=1;draw()elseif x<=31 and y>=11 and y<=H-4 then local i=y-10;if i>=1 and i<=#devices then selected=i;draw()end end end
 end
end
gpu.setBackground(0);gpu.setForeground(0xFFFFFF);gpu.fill(1,1,W,H," ")
