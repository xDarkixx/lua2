-- AE2Network_Modern.lua
-- Buldacity AE2 HUD for OpenComputers / AE2 rv3 beta 6 / MC 1.7.10
-- Adaptive neon interface with live CraftingStatus tracking and scrollable crafting matrix.
local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local me=component.me_controller
if not me then error("Kein me_controller gefunden.") end

local W,H=80,25
local page="HOME"
local running=true
local items,crafts,cpus={},{},{}
local jobs={}
local selectedCraft=1
local craftScroll=1
local msg="BULDACITY SYSTEM READY"
local lastScan=0
local pulse=0
local ui={}

local C={
 bg=0x03060B,panel=0x0A111B,panel2=0x101C29,line=0x214057,
 cyan=0x35E8FF,blue=0x438CFF,green=0x35FF9A,red=0xFF466D,
 yellow=0xFFE36A,purple=0xC56BFF,pink=0xFF4CCB,orange=0xFF9D45,
 white=0xF3FAFF,grey=0x7D96AA,off=0x263541
}

local function safe(fn,...)
 local ok,a,b,c,d=pcall(fn,...)
 if ok then return a,b,c,d end
end

local function objcall(o,m,...)
 if not o then return nil end
 local ok,a,b,c=pcall(function(...) return o[m](...) end,...)
 if ok then return a,b,c end
 ok,a,b,c=pcall(function(...) return o[m](o,...) end,...)
 if ok then return a,b,c end
end

local function resize()
 local mw,mh=safe(gpu.maxResolution)
 local cw,ch=safe(gpu.getResolution)
 mw,mh=mw or cw or 80,mh or ch or 25
 safe(gpu.setResolution,mw,mh)
 W,H=safe(gpu.getResolution)
 W,H=W or mw,H or mh
end

local function clear(bg)
 gpu.setBackground(bg or C.bg);gpu.fill(1,1,W,H," ")
end

local function txt(x,y,s,fg,bg)
 if x<1 or y<1 or x>W or y>H then return end
 gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s))
end

local function fit(s,n)
 s=tostring(s or "");n=math.max(1,n or 1)
 if #s<=n then return s end
 if n==1 then return s:sub(1,1) end
 return s:sub(1,n-1).."…"
end

local function line(x,y,w,c)
 if w<1 or y<1 or y>H then return end
 gpu.setBackground(c or C.line);gpu.fill(x,y,math.min(w,W-x+1),1," ")
end

local function panel(x,y,w,h,title,c)
 if w<2 or h<2 then return end
 gpu.setBackground(C.panel);gpu.fill(x,y,math.min(w,W-x+1),math.min(h,H-y+1)," ")
 line(x,y,w,c or C.cyan);txt(x+2,y,"◆ "..fit(title,w-5),c or C.cyan,C.panel)
 if h>=3 then line(x,y+h-1,w,C.line) end
end

local function led(x,y,on,c,label)
 if y<1 or y>H then return end
 local cc=on and (c or C.green) or C.off
 gpu.setBackground(cc);gpu.fill(x,y,2,1," ")
 txt(x+3,y,fit(label or (on and "ONLINE" or "OFFLINE"),math.max(1,W-x-3)),on and cc or C.grey,C.panel)
end

local function bar(x,y,w,p,c)
 w=math.max(1,w);p=math.max(0,math.min(100,tonumber(p) or 0))
 gpu.setBackground(C.panel2);gpu.fill(x,y,w,1," ")
 local n=math.floor(w*p/100)
 if n>0 then gpu.setBackground(c or C.cyan);gpu.fill(x,y,n,1," ") end
end

local function marqueeBar(x,y,w,phase,c)
 w=math.max(3,w);gpu.setBackground(C.panel2);gpu.fill(x,y,w,1," ")
 local pos=(phase%(w+6))-6;if pos<0 then pos=0 end
 local n=math.min(8,w);if pos+n>w then n=w-pos end
 if n>0 then gpu.setBackground(c or C.cyan);gpu.fill(x+pos,y,n,1," ") end
end

local function button(id,x,y,w,label,c,active)
 w=math.max(3,w);ui[id]={x=x,y=y,w=w,h=2}
 gpu.setBackground(active and C.white or c);gpu.fill(x,y,w,2," ")
 txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),active and c or C.white,active and C.white or c)
end

local function hit(id,x,y)
 local b=ui[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h
end

local function stackData(s)
 if type(s)=="table" then
  return s.label or s.displayName or s.name or s.id or s.item,tonumber(s.size or s.amount or s.count or 0) or 0
 end
 return nil,0
end

local function itemName(e)
 local n=stackData(e);return n or tostring(e or "--")
end

local function amount(e)
 local _,a=stackData(e);return a or 0
end

local function craftData(c)
 local s=objcall(c,"getItemStack");local n,a=stackData(s)
 if n then return n,a end
 return "UNKNOWN RECIPE",1
end

local function clampCraftScroll()
 local h=math.max(4,H-10)
 local visible=math.max(1,h-5)
 local maxScroll=math.max(1,#crafts-visible+1)
 if selectedCraft<1 then selectedCraft=1 end
 if selectedCraft>#crafts and #crafts>0 then selectedCraft=#crafts end
 if craftScroll<1 then craftScroll=1 end
 if craftScroll>maxScroll then craftScroll=maxScroll end
 if selectedCraft<craftScroll then craftScroll=selectedCraft end
 if selectedCraft>craftScroll+visible-1 then craftScroll=selectedCraft-visible+1 end
 if craftScroll>maxScroll then craftScroll=maxScroll end
end

local function selectCraft(index)
 if #crafts==0 then return end
 selectedCraft=math.max(1,math.min(#crafts,index))
 clampCraftScroll()
 msg="BULDACITY SELECTED: "..craftData(crafts[selectedCraft])
end

local function scrollCraft(delta)
 if #crafts==0 then return end
 clampCraftScroll();craftScroll=craftScroll+delta
 local h=math.max(4,H-10);local visible=math.max(1,h-5)
 local maxScroll=math.max(1,#crafts-visible+1)
 craftScroll=math.max(1,math.min(maxScroll,craftScroll))
 if selectedCraft<craftScroll then selectedCraft=craftScroll end
 if selectedCraft>craftScroll+visible-1 then selectedCraft=craftScroll+visible-1 end
 msg="CRAFT SCROLL "..craftScroll.."/"..maxScroll
end

local function refresh()
 local a=safe(me.getItemsInNetwork);items=type(a)=="table" and a or {}
 local b=safe(me.getCraftables);crafts=type(b)=="table" and b or {}
 local c=safe(me.getCpus);cpus=type(c)=="table" and c or {}
 if selectedCraft>#crafts then selectedCraft=math.max(1,#crafts) end
 clampCraftScroll();lastScan=computer.uptime();msg="BULDACITY NETWORK SCANNED"
end

local function cpuInfo(cpu)
 if type(cpu)=="table" then
  local busy=cpu.busy==true
  return busy,cpu.name or "CPU",tonumber(cpu.storage or 0) or 0,tonumber(cpu.coprocessors or 0) or 0
 end
 local busy=objcall(cpu,"isBusy")
 return busy==true,"CRAFTING...",0,0
end

local function jobState(job)
 if not job or not job.status then return "SUBMITTING",C.yellow,false,false end
 local canceled,creason=objcall(job.status,"isCanceled")
 if canceled==true then return "CANCELED",C.red,false,true,creason end
 local done,dreason=objcall(job.status,"isDone")
 if done==true then return "DONE",C.green,true,false,dreason end
 return "RUNNING",C.cyan,false,false,dreason
end

local function activeJobCount()
 local n=0
 for i=1,#jobs do
  local state=jobState(jobs[i])
  if state=="RUNNING" or state=="SUBMITTING" then n=n+1 end
 end
 return n
end

local function requestCraft(index,count)
 local c=crafts[index]
 if not c then msg="NO CRAFTABLE SELECTED";return end
 count=math.max(1,math.floor(tonumber(count) or 1))
 local name=craftData(c)
 local status,reason=objcall(c,"request",count,true)
 if status then
  table.insert(jobs,1,{status=status,name=name,requested=count,started=computer.uptime(),id=computer.uptime()})
  msg="BULDACITY CRAFT STARTED: "..fit(name,math.max(8,W-30));page="JOBS"
 else msg="CRAFT FAILED: "..tostring(reason or "UNKNOWN ERROR") end
end

local function header(title)
 gpu.setBackground(C.panel);gpu.fill(1,1,W,4," ")
 txt(2,1,"╔ BULDACITY // AE2 CORE ╗",C.cyan,C.panel)
 txt(3,2,fit(title,math.max(8,W-34)),C.white,C.panel)
 local blink=(pulse%2==0);led(math.max(5,W-27),2,true,blink and C.green or C.cyan,"ONLINE")
 line(1,4,W,C.cyan)
end

local function footer()
 local y=math.max(1,H-3);local n=7;local gap=1
 local bw=math.max(3,math.floor((W-4-(n-1)*gap)/n));local x=2
 button("home",x,y,bw,"HOME",C.purple,page=="HOME");x=x+bw+gap
 button("items",x,y,bw,"ITEMS",C.cyan,page=="ITEMS");x=x+bw+gap
 button("craft",x,y,bw,"CRAFT",C.pink,page=="CRAFTS");x=x+bw+gap
 button("jobs",x,y,bw,"JOBS",C.green,page=="JOBS");x=x+bw+gap
 button("system",x,y,bw,"PC",C.blue,page=="SYSTEM");x=x+bw+gap
 button("refresh",x,y,bw,"SCAN",C.yellow);x=x+bw+gap
 button("quit",x,y,bw,"EXIT",C.red)
 if H>=2 then txt(2,H,fit(msg,math.max(1,W-4)),C.grey,C.bg) end
end

local function drawHome()
 header("BULDACITY ME NETWORK // LIVE")
 local cy=6;local bottom=H-5;local ph=math.max(4,bottom-cy+1)
 local two=W>=76;local gap=2;local pw=two and math.floor((W-6-gap)/2) or W-6
 panel(3,cy,pw,ph,"NETWORK STATUS",C.cyan)
 led(6,cy+3,true,C.green,"ME CONTROLLER")
 txt(6,cy+6,"ITEM TYPES",C.grey,C.panel);txt(math.min(27,pw-8),cy+6,#items,C.cyan,C.panel)
 txt(6,cy+8,"CRAFTABLES",C.grey,C.panel);txt(math.min(27,pw-8),cy+8,#crafts,C.pink,C.panel)
 txt(6,cy+10,"CPUs",C.grey,C.panel);txt(math.min(27,pw-8),cy+10,#cpus,C.yellow,C.panel)
 txt(6,cy+12,"ACTIVE JOBS",C.grey,C.panel);txt(math.min(27,pw-8),cy+12,activeJobCount(),C.green,C.panel)
 txt(6,cy+14,"SCAN AGE",C.grey,C.panel);txt(math.min(27,pw-8),cy+14,string.format("%.1fs",computer.uptime()-lastScan),C.white,C.panel)
 if ph>=18 then txt(6,cy+16,"NETWORK LOAD",C.grey,C.panel);bar(6,cy+17,math.max(5,pw-12),math.min(100,#items/1000*100),C.cyan) end
 if two then
  local x=3+pw+gap;panel(x,cy,pw,ph,"CPU MATRIX",C.purple);local yy=cy+3
  for i=1,math.min(6,#cpus) do
   local b,n=cpuInfo(cpus[i]);led(x+4,yy,b,b and C.green or C.purple,b and fit(n,math.max(8,pw-12)) or "CPU IDLE");yy=yy+2
   if yy>cy+ph-4 then break end
  end
  if #cpus==0 then txt(x+5,cy+5,"NO CPU DATA",C.grey,C.panel) end
 end
 footer()
end

local function drawItems()
 header("BULDACITY STORAGE MATRIX // LIVE")
 local y=6;local h=math.max(4,H-10);local w=W-6;panel(3,y,w,h,"ITEM STORAGE",C.cyan)
 local rows=math.max(1,h-3)
 for i=1,math.min(rows,#items) do
  local yy=y+1+i;txt(6,yy,string.format("%02d",i),C.cyan,C.panel)
  txt(11,yy,fit(itemName(items[i]),math.max(8,w-38)),C.white,C.panel)
  txt(math.max(1,W-20),yy,fit(tostring(amount(items[i])),18),C.green,C.panel)
  if yy<H-4 then line(6,yy+1,w-8,C.line) end
 end
 if #items==0 then txt(7,y+4,"NO STORAGE DATA",C.red,C.panel) end
 footer()
end

local function drawScrollbar(x,y,h,total,scroll,visible)
 local trackH=math.max(3,h)
 gpu.setBackground(C.panel2);gpu.fill(x,y,3,trackH," ")
 if total<=visible then
  gpu.setBackground(C.green);gpu.fill(x,y,3,trackH," ");return
 end
 local thumb=math.max(2,math.floor(trackH*visible/total))
 local maxPos=trackH-thumb
 local pos=math.floor(maxPos*(scroll-1)/math.max(1,total-visible))
 gpu.setBackground(C.pink);gpu.fill(x,y+pos,3,thumb," ")
end

local function drawCrafts()
 header("BULDACITY CRAFTING MATRIX // SCROLL + START")
 local y=6;local h=math.max(4,H-10);local w=W-6
 local left=math.max(30,math.floor(w*0.64));local right=w-left-2
 panel(3,y,left,h,"CRAFTABLE RECIPES // SCROLLABLE",C.pink)
 local visible=math.max(1,h-5);local maxScroll=math.max(1,#crafts-visible+1)
 clampCraftScroll()
 local start=craftScroll;local finish=math.min(#crafts,start+visible-1)
 for i=start,finish do
  local row=i-start+1;local yy=y+1+row;local n,a=craftData(crafts[i]);local active=i==selectedCraft
  if active then gpu.setBackground(C.panel2);gpu.fill(4,yy,left-5,1," ") end
  txt(6,yy,string.format("%02d",i),active and C.yellow or C.cyan,C.panel)
  txt(11,yy,fit(n,math.max(8,left-29)),active and C.white or C.white,C.panel)
  txt(12+math.max(8,left-29),yy,"x"..tostring(a),C.pink,C.panel)
  ui["craftrow"..i]={x=4,y=yy,w=left-5,h=1}
 end
 if #crafts==0 then txt(7,y+4,"NO CRAFTABLE RECIPES",C.red,C.panel) end

 local sx=3+left-4;local sy=y+1;local sh=math.max(2,h-2)
 drawScrollbar(sx,sy,sh,#crafts,craftScroll,visible)
 button("craftup",sx-1,y+1,5,"▲",C.cyan)
 button("craftdown",sx-1,y+h-3,5,"▼",C.pink)
 txt(math.max(1,sx-1),y+h-1,fit(tostring(craftScroll).."/"..tostring(maxScroll),5),C.grey,C.panel)

 local x=3+left+2;panel(x,y,right,h,"CRAFT CONSOLE",C.green)
 local n,a=craftData(crafts[selectedCraft])
 txt(x+3,y+3,"SELECTED",C.grey,C.panel);txt(x+3,y+5,fit(n,math.max(8,right-6)),C.white,C.panel)
 txt(x+3,y+7,"OUTPUT",C.grey,C.panel);txt(x+14,y+7,"x"..tostring(a),C.pink,C.panel)
 txt(x+3,y+9,"QUICK REQUEST",C.grey,C.panel)
 local bw=math.max(5,math.floor((right-8)/3))
 button("craft1",x+3,y+11,bw,"x1",C.cyan)
 button("craft16",x+4+bw,y+11,bw,"x16",C.blue)
 button("craft64",x+5+bw*2,y+11,bw,"x64",C.purple)
 if h>=18 then
  txt(x+3,y+14,"LIVE JOBS",C.grey,C.panel);txt(x+3,y+16,tostring(activeJobCount()).." RUNNING",C.green,C.panel)
  txt(x+3,y+18,"WHEEL / ▲ ▼ / ARROWS",C.cyan,C.panel)
  txt(x+3,y+20,"100+ RECIPES READY",C.orange,C.panel)
 end
 footer()
end

local function drawJobs()
 header("BULDACITY CRAFTING CORE // LIVE PROCESS")
 local y=6;local h=math.max(4,H-10);local w=W-6;panel(3,y,w,h,"ACTIVE + RECENT CRAFTING",C.green)
 local yy=y+2
 if #jobs==0 then
  txt(7,yy,"NO HUD-TRACKED CRAFTS",C.grey,C.panel);txt(7,yy+2,"Select a recipe in CRAFT and start x1/x16/x64.",C.cyan,C.panel)
 else
  local maxRows=math.max(1,h-5)
  for i=1,math.min(maxRows,#jobs) do
   local j=jobs[i];local state,color,done,canceled,reason=jobState(j)
   txt(6,yy,string.format("%02d",i),C.cyan,C.panel);txt(11,yy,fit(j.name,math.max(8,w-50)),C.white,C.panel)
   txt(math.max(1,W-29),yy,"x"..tostring(j.requested),C.yellow,C.panel);txt(math.max(1,W-16),yy,state,color,C.panel)
   if state=="RUNNING" or state=="SUBMITTING" then
    marqueeBar(11,yy+1,math.max(8,w-16),pulse*2,C.cyan);txt(11,yy+2,"ELAPSED",C.grey,C.panel)
    txt(20,yy+2,string.format("%.1fs",computer.uptime()-j.started),C.white,C.panel);txt(31,yy+2,"LIVE STATUS",C.green,C.panel)
   elseif state=="DONE" then txt(11,yy+1,"✓ CRAFT COMPLETE",C.green,C.panel);txt(11,yy+2,string.format("TOTAL REQUEST: %d",j.requested),C.grey,C.panel)
   else txt(11,yy+1,"× "..fit(reason or "REQUEST CANCELED",w-14),C.red,C.panel) end
   yy=yy+4;if yy>y+h-4 then break end
  end
 end
 footer()
end

local function drawSystem()
 header("BULDACITY PC // OPENCOMPUTERS")
 local y=6;local h=math.max(4,H-10);local w=W-6;panel(3,y,w,h,"COMPUTER CORE",C.blue)
 local energy,maxEnergy=safe(computer.energy),safe(computer.maxEnergy);local total,free=safe(computer.totalMemory),safe(computer.freeMemory)
 local depth=safe(gpu.getDepth);local screen=safe(gpu.getScreen)
 txt(6,y+3,"UPTIME",C.grey,C.panel);txt(24,y+3,string.format("%.1fs",computer.uptime()),C.cyan,C.panel)
 txt(6,y+5,"CLOCK",C.grey,C.panel);txt(24,y+5,os.date("%H:%M:%S"),C.white,C.panel)
 if energy and maxEnergy then local ep=maxEnergy>0 and energy/maxEnergy*100 or 0;txt(6,y+7,"ENERGY",C.grey,C.panel);txt(24,y+7,string.format("%.0f / %.0f",energy,maxEnergy),C.yellow,C.panel);bar(24,y+8,math.max(8,w-30),ep,C.yellow) end
 if total and free then local used=total-free;local mp=total>0 and used/total*100 or 0;txt(6,y+10,"MEMORY",C.grey,C.panel);txt(24,y+10,string.format("%d / %d B",used,total),C.purple,C.panel);bar(24,y+11,math.max(8,w-30),mp,C.purple) end
 local rw,rh=safe(gpu.getResolution);txt(6,y+13,"GPU RES",C.grey,C.panel);txt(24,y+13,string.format("%dx%d",rw or W,rh or H),C.cyan,C.panel)
 txt(6,y+15,"COLOR DEPTH",C.grey,C.panel);txt(24,y+15,tostring(depth or "?"),C.pink,C.panel)
 txt(6,y+17,"SCREEN",C.grey,C.panel);txt(24,y+17,fit(screen or "BOUND",math.max(8,w-28)),C.green,C.panel)
 txt(6,y+19,"HUD MODE",C.grey,C.panel);txt(24,y+19,(W>=150 and "ULTRA 160x50" or (W>=75 and "WIDE" or "COMPACT")),C.orange,C.panel)
 footer()
end

local function draw()
 resize();clear(C.bg);pulse=pulse+1
 if page=="HOME" then drawHome()
 elseif page=="ITEMS" then drawItems()
 elseif page=="CRAFTS" then drawCrafts()
 elseif page=="JOBS" then drawJobs()
 else drawSystem() end
end

local function click(x,y)
 if hit("home",x,y) then page="HOME"
 elseif hit("items",x,y) then page="ITEMS"
 elseif hit("craft",x,y) then page="CRAFTS"
 elseif hit("jobs",x,y) then page="JOBS"
 elseif hit("system",x,y) then page="SYSTEM"
 elseif hit("refresh",x,y) then refresh()
 elseif hit("quit",x,y) then running=false
 elseif page=="CRAFTS" then
  if hit("craftup",x,y) then scrollCraft(-1)
  elseif hit("craftdown",x,y) then scrollCraft(1)
  elseif hit("craft1",x,y) then requestCraft(selectedCraft,1)
  elseif hit("craft16",x,y) then requestCraft(selectedCraft,16)
  elseif hit("craft64",x,y) then requestCraft(selectedCraft,64)
  else
   for i=craftScroll,math.min(#crafts,craftScroll+math.max(1,H-15)) do
    if hit("craftrow"..i,x,y) then selectCraft(i);break end
   end
  end
 end
end

resize();refresh();draw()
while running do
 local e,a,x,y=event.pull(0.5)
 if e=="touch" then click(x,y);draw()
 elseif e=="scroll" then
  if page=="CRAFTS" then
   local dir=tonumber(a) or 0
   if dir>0 then scrollCraft(-1) elseif dir<0 then scrollCraft(1) end
   draw()
  end
 elseif e=="key_down" then
  local c=y
  if c==string.byte("q") or c==string.byte("Q") then running=false
  elseif c==string.byte("r") or c==string.byte("R") then refresh()
  elseif c==string.byte("i") or c==string.byte("I") then page="ITEMS"
  elseif c==string.byte("c") or c==string.byte("C") then page="CRAFTS"
  elseif c==string.byte("j") or c==string.byte("J") then page="JOBS"
  elseif c==string.byte("p") or c==string.byte("P") then page="SYSTEM"
  elseif page=="CRAFTS" and (c==200 or c==208) then
   if c==200 then selectCraft(selectedCraft-1);else selectCraft(selectedCraft+1) end
  end
  draw()
 end
 if computer.uptime()-lastScan>=5 then refresh();draw() end
end

gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")