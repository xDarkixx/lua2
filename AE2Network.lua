-- AE2 ME Network Touch Dashboard
-- Minecraft 1.7.10 / AE2 rv3 beta 6 / OpenComputers 1.8.10
local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local me=component.me_controller
if not me then error("Kein me_controller gefunden.") end
local W,H=132,38; local page="HOME"; local running=true; local items={}; local crafts={}; local msg="Bereit"; local last=0
local C={bg=0x080B10,panel=0x111722,blue=0x2563EB,cyan=0x06B6D4,green=0x16A34A,yellow=0xEAB308,red=0xDC2626,purple=0x9333EA,white=0xF8FAFC,text=0xCBD5E1,muted=0x64748B,dark=0x030712,black=0}
local function sc(fn,...) local ok,a,b,c=pcall(fn,...); if ok then return a,b,c end end
local function txt(x,y,s,fg,bg) gpu.setForeground(fg or C.text); gpu.setBackground(bg or C.bg); gpu.set(x,y,tostring(s)) end
local function box(x,y,w,h,t,a) gpu.setBackground(C.panel); gpu.fill(x,y,w,h," "); gpu.setBackground(a or C.blue); gpu.fill(x,y,1,h," "); txt(x+3,y,"[ "..t.." ]",a or C.cyan,C.panel) end
local function btn(x,y,w,t,a,active) gpu.setBackground(active and C.white or a); gpu.fill(x,y,w,3," "); txt(x+math.max(1,math.floor((w-#t)/2)),y+1,t,active and a or C.white,active and C.white or a) end
local function short(s,n) s=tostring(s or "--"); return #s<=n and s or s:sub(1,n-3).."..." end
local function amount(e) return type(e)=="table" and tonumber(e.size or e.amount or e.count or 0) or 0 end
local function name(e) return type(e)=="table" and tostring(e.label or e.name or e.id or "unknown") or tostring(e or "--") end
local function refresh() local a=sc(me.getItemsInNetwork); items=type(a)=="table" and a or {}; local b=sc(me.getCraftables); crafts=type(b)=="table" and b or {}; last=computer.uptime(); msg="Netzwerk aktualisiert" end
local function drawHeader() gpu.setBackground(C.blue); gpu.fill(1,1,W,4," "); txt(4,2,"APPLIED ENERGISTICS 2 // ME NETWORK",C.white,C.blue); txt(4,3,"TOUCH CONTROL CENTER   MC 1.7.10 | AE2 rv3 beta 6",0xBFDBFE,C.blue) end
local function draw()
 gpu.setResolution(W,H); gpu.setBackground(C.bg); gpu.fill(1,1,W,H," "); drawHeader()
 if page=="HOME" then
  box(2,6,62,14,"ME NETWORK",C.cyan); txt(6,8,"CONNECTION",C.muted); txt(22,8,"ONLINE",C.green); txt(6,11,"ITEM TYPES",C.muted); txt(22,11,#items,C.cyan); txt(6,13,"CRAFTABLES",C.muted); txt(22,13,#crafts,C.purple); txt(6,16,"COMPONENT",C.muted); txt(22,16,"me_controller",C.white)
  box(66,6,64,14,"NETWORK",C.blue); txt(70,8,"STORED ITEM TYPES",C.muted); txt(92,8,#items,C.green); txt(70,11,"CRAFTABLE TYPES",C.muted); txt(92,11,#crafts,C.purple); txt(70,14,"UPDATED",C.muted); txt(92,14,string.format("%.1fs",computer.uptime()-last),C.text)
  box(2,22,128,13,"QUICK VIEW",C.purple); txt(6,24,"TOP ITEMS",C.muted); for i=1,math.min(6,#items) do txt(7,25+i-1,i..".",C.cyan); txt(12,25+i-1,short(name(items[i]),62),C.white); txt(80,25+i-1,amount(items[i]),C.green) end
 else
  local list=page=="ITEMS" and items or crafts; local ac=page=="ITEMS" and C.cyan or C.purple; box(2,6,128,29,page=="ITEMS" and "ME STORAGE / ITEMS" or "ME CRAFTING / CRAFTABLES",ac); txt(6,8,"#",C.muted); txt(11,8,page=="ITEMS" and "STORED ITEM" or "CRAFTABLE",C.muted)
  for i=1,math.min(23,#list) do local y=9+i; txt(6,y,string.format("%02d",i),C.cyan); txt(11,y,short(name(list[i]),68),C.white); if page=="ITEMS" then txt(85,y,amount(list[i]),C.green) else txt(85,y,"AVAILABLE",C.green) end end
 end
 box(2,36,128,2,"TOUCH MENU",C.blue); btn(6,36,20,"HOME",C.blue,page=="HOME"); btn(29,36,20,"ITEMS",C.cyan,page=="ITEMS"); btn(52,36,24,"CRAFT",C.purple,page=="CRAFTS"); btn(79,36,20,"REFRESH",C.yellow,false); btn(102,36,22,"QUIT",C.red,false); txt(4,38,msg,C.muted)
end
local function click(x,y)
 if y>=36 then if x>=6 and x<26 then page="HOME" elseif x>=29 and x<49 then page="ITEMS" elseif x>=52 and x<76 then page="CRAFTS" elseif x>=79 and x<99 then refresh() elseif x>=102 and x<124 then running=false end end
end
refresh(); draw()
while running do local e,a,x,y=event.pull(1); if e=="touch" then click(x,y); draw() elseif e=="key_down" then local c=y; if c==string.byte("q") or c==string.byte("Q") then running=false elseif c==string.byte("r") or c==string.byte("R") then refresh() elseif c==string.byte("i") or c==string.byte("I") then page="ITEMS" elseif c==string.byte("c") or c==string.byte("C") then page="CRAFTS" end; draw() end; if computer.uptime()-last>=3 then refresh(); draw() end end
gpu.setBackground(C.black); gpu.fill(1,1,W,H," "); txt(4,18,"AE2 ME Network Manager beendet.",C.text,C.black)
