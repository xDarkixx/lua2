-- AE2Network_Modern.lua
-- Buldacity AE2 HUD for OpenComputers / AE2 rv3 beta 6 / MC 1.7.10
-- Searchable crafting terminal with live jobs and P2P/OC discovery.
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
local filteredCrafts={}
local jobs={}
local p2ps={}
local selectedCraft=1
local craftScroll=1
local craftSearch=""
local searchActive=false
local msg="BULDACITY SYSTEM READY"
local lastScan=0
local lastP2PScan=0
local pulse=0
local ui={}

local C={bg=0x03060B,panel=0x0A111B,panel2=0x101C29,line=0x214057,cyan=0x35E8FF,blue=0x438CFF,green=0x35FF9A,red=0xFF466D,yellow=0xFFE36A,purple=0xC56BFF,pink=0xFF4CCB,orange=0xFF9D45,white=0xF3FAFF,grey=0x7D96AA,off=0x263541}

local function safe(fn,...)
 local ok,a,b,c,d=pcall(fn,...)
 if ok then return a,b,c,d end
end

local function objcall(o,m,...)
 if not o or type(o[m])~="function" then return nil end
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
 gpu.setBackground(bg or C.bg)
 gpu.fill(1,1,W,H," ")
end

local function txt(x,y,s,fg,bg)
 if x<1 or y<1 or x>W or y>H then return end
 gpu.setForeground(fg or C.white)
 gpu.setBackground(bg or C.bg)
 gpu.set(x,y,tostring(s))
end

local function fit(s,n)
 s=tostring(s or "")
 n=math.max(1,n or 1)
 if #s<=n then return s end
 if n==1 then return s:sub(1,1) end
 return s:sub(1,n-1).."…"
end

local function line(x,y,w,c)
 if w<1 or y<1 or y>H then return end
 gpu.setBackground(c or C.line)
 gpu.fill(x,y,math.min(w,W-x+1),1," ")
end

local function panel(x,y,w,h,title,c)
 if w<2 or h<2 then return end
 gpu.setBackground(C.panel)
 gpu.fill(x,y,math.min(w,W-x+1),math.min(h,H-y+1)," ")
 line(x,y,w,c or C.cyan)
 txt(x+2,y,"◆ "..fit(title,w-5),c or C.cyan,C.panel)
 if h>=3 then line(x,y+h-1,w,C.line) end
end

local function led(x,y,on,c,label)
 if y<1 or y>H then return end
 local cc=on and (c or C.green) or C.off
 gpu.setBackground(cc)
 gpu.fill(x,y,2,1," ")
 txt(x+3,y,fit(label or (on and "ONLINE" or "OFFLINE"),math.max(1,W-x-3)),on and cc or C.grey,C.panel)
end

local function bar(x,y,w,p,c)
 w=math.max(1,w)
 p=math.max(0,math.min(100,tonumber(p) or 0))
 gpu.setBackground(C.panel2)
 gpu.fill(x,y,w,1," ")
 local n=math.floor(w*p/100)
 if n>0 then gpu.setBackground(c or C.cyan);gpu.fill(x,y,n,1," ") end
end

local function marqueeBar(x,y,w,phase,c)
 w=math.max(3,w)
 gpu.setBackground(C.panel2)
 gpu.fill(x,y,w,1," ")
 local pos=(phase%(w+6))-6
 if pos<0 then pos=0 end
 local n=math.min(8,w)
 if pos+n>w then n=w-pos end
 if n>0 then gpu.setBackground(c or C.cyan);gpu.fill(x+pos,y,n,1," ") end
end

local function button(id,x,y,w,label,c,active)
 w=math.max(3,w)
 ui[id]={x=x,y=y,w=w,h=2}
 gpu.setBackground(active and C.white or c)
 gpu.fill(x,y,w,2," ")
 txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),active and c or C.white,active and C.white or c)
end

local function hit(id,x,y)
 local b=ui[id]
 return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h
end

local function stackData(s)
 if type(s)=="table" then
  return s.label or s.displayName or s.name or s.id or s.item,tonumber(s.size or s.amount or s.count or 0) or 0
 end
 return nil,0
end

local function itemName(e)
 local n=stackData(e)
 return n or tostring(e or "--")
end

local function amount(e)
 local _,a=stackData(e)
 return a or 0
end

local function craftData(c)
 local s=objcall(c,"getItemStack")
 local n,a=stackData(s)
 if n then return n,a end
 return "UNKNOWN RECIPE",1
end

local function lower(s)
 return string.lower(tostring(s or ""))
end

local function rebuildCraftFilter()
 filteredCrafts={}
 local q=lower(craftSearch)
 for i=1,#crafts do
  local n=craftData(crafts[i])
  if q=="" or lower(n):find(q,1,true) then
   filteredCrafts[#filteredCrafts+1]=i
  end
 end
 if selectedCraft<1 then selectedCraft=1 end
 if selectedCraft>#filteredCrafts then selectedCraft=math.max(1,#filteredCrafts) end
 craftScroll=1
end

local function clampCraftScroll()
 local h=math.max(4,H-10)
 local visible=math.max(1,h-7)
 local total=#filteredCrafts
 local maxScroll=math.max(1,total-visible+1)
 if selectedCraft<1 then selectedCraft=1 end
 if selectedCraft>total and total>0 then selectedCraft=total end
 if craftScroll<1 then craftScroll=1 end
 if craftScroll>maxScroll then craftScroll=maxScroll end
 if selectedCraft<craftScroll then craftScroll=selectedCraft end
 if selectedCraft>craftScroll+visible-1 then craftScroll=selectedCraft-visible+1 end
end

local function selectedOriginalIndex()
 return filteredCrafts[selectedCraft]
end

local function selectCraft(index)
 if #filteredCrafts==0 then return end
 selectedCraft=math.max(1,math.min(#filteredCrafts,index))
 clampCraftScroll()
 local original=selectedOriginalIndex()
 msg="BULDACITY SELECTED: "..craftData(crafts[original])
end

local function scrollCraft(delta)
 if #filteredCrafts==0 then return end
 clampCraftScroll()
 local h=math.max(4,H-10)
 local visible=math.max(1,h-7)
 local maxScroll=math.max(1,#filteredCrafts-visible+1)
 craftScroll=math.max(1,math.min(maxScroll,craftScroll+delta))
 if selectedCraft<craftScroll then selectedCraft=craftScroll end
 if selectedCraft>craftScroll+visible-1 then selectedCraft=craftScroll+visible-1 end
 msg="CRAFT SCROLL "..craftScroll.."/"..maxScroll
end

local function refresh()
 local a=safe(me.getItemsInNetwork)
 items=type(a)=="table" and a or {}
 local b=safe(me.getCraftables)
 crafts=type(b)=="table" and b or {}
 local c=safe(me.getCpus)
 cpus=type(c)=="table" and c or {}
 rebuildCraftFilter()
 clampCraftScroll()
 lastScan=computer.uptime()
 msg="BULDACITY NETWORK SCANNED"
end

local function cpuInfo(cpu)
 if type(cpu)=="table" then
  return cpu.busy==true,cpu.name or "CPU",tonumber(cpu.storage or 0) or 0,tonumber(cpu.coprocessors or 0) or 0
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
 local original=filteredCrafts[index]
 local c=original and crafts[original]
 if not c then msg="NO CRAFTABLE SELECTED";return end
 count=math.max(1,math.floor(tonumber(count) or 1))
 local name=craftData(c)
 local status,reason=objcall(c,"request",count,true)
 if status then
  table.insert(jobs,1,{status=status,name=name,requested=count,started=computer.uptime(),id=computer.uptime()})
  msg="BULDACITY CRAFT STARTED: "..fit(name,math.max(8,W-30))
  page="JOBS"
 else
  msg="CRAFT FAILED: "..tostring(reason or "UNKNOWN ERROR")
 end
end

local function p2pScore(kind,addr)
 local k=lower(kind)
 local score=0
 if k:find("p2p",1,true) then score=score+5 end
 if k:find("tunnel",1,true) then score=score+4 end
 if k:find("opencomputers",1,true) then score=score+2 end
 if k:find("oc",1,true) then score=score+1 end
 local doc=safe(component.doc,addr)
 if type(doc)=="table" then
  for name,_ in pairs(doc) do
   local n=lower(name)
   if n:find("p2p",1,true) or n:find("tunnel",1,true) then score=score+3 end
  end
 end
 return score,doc
end

local function methodNames(doc)
 local out={}
 if type(doc)=="table" then for name,_ in pairs(doc) do out[#out+1]=tostring(name) end end
 table.sort(out)
 return out
end

local function scanP2P()
 p2ps={}
 local iter=safe(component.list)
 if type(iter)=="function" then
  for addr,kind in iter do
   local score,doc=p2pScore(kind,addr)
   if score>0 then p2ps[#p2ps+1]={address=tostring(addr),kind=tostring(kind),score=score,methods=methodNames(doc)} end
  end
 end
 table.sort(p2ps,function(a,b)return a.score>b.score end)
 lastP2PScan=computer.uptime()
 if #p2ps>0 then msg="BULDACITY P2P SCAN: "..#p2ps.." CANDIDATE(S)" else msg="P2P SCAN: NO EXPOSED OC P2P COMPONENT" end
end

local function header(title)
 gpu.setBackground(C.panel);gpu.fill(1,1,W,4," ")
 txt(2,1,"╔ BULDACITY // AE2 CORE ╗",C.cyan,C.panel)
 txt(3,2,fit(title,math.max(8,W-34)),C.white,C.panel)
 led(math.max(5,W-27),2,true,(pulse%2==0) and C.green or C.cyan,"ONLINE")
 line(1,4,W,C.cyan)
end

local function footer()
 local y=math.max(1,H-3);local n=8;local gap=1
 local bw=math.max(3,math.floor((W-4-(n-1)*gap)/n));local x=2
 button("home",x,y,bw,"HOME",C.purple,page=="HOME");x=x+bw+gap
 button("items",x,y,bw,"ITEMS",C.cyan,page=="ITEMS");x=x+bw+gap
 button("craft",x,y,bw,"CRAFT",C.pink,page=="CRAFTS");x=x+bw+gap
 button("jobs",x,y,bw,"JOBS",C.green,page=="JOBS");x=x+bw+gap
 button("p2p",x,y,bw,"P2P",C.orange,page=="P2P");x=x+bw+gap
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
 txt(6,cy+10,"FILTERED",C.grey,C.panel);txt(math.min(27,pw-8),cy+10,#filteredCrafts,C.pink,C.panel)
 txt(6,cy+12,"CPUs",C.grey,C.panel);txt(math.min(27,pw-8),cy+12,#cpus,C.yellow,C.panel)
 txt(6,cy+14,"ACTIVE JOBS",C.grey,C.panel);txt(math.min(27,pw-8),cy+14,activeJobCount(),C.green,C.panel)
 txt(6,cy+16,"P2P CANDIDATES",C.grey,C.panel);txt(math.min(27,pw-8),cy+16,#p2ps,C.orange,C.panel)
 if two then
  local x=3+pw+gap
  panel(x,cy,pw,ph,"CPU MATRIX",C.purple);local yy=cy+3
  for i=1,math.min(7,#cpus) do
   local b,n=cpuInfo(cpus[i]);led(x+4,yy,b,b and C.green or C.purple,b and fit(n,math.max(8,pw-12)) or "CPU IDLE");yy=yy+2
   if yy>cy+ph-4 then break end
  end
  if #cpus==0 then txt(x+5,cy+5,"NO CPU DATA",C.grey,C.panel) end
  txt(x+4,cy+ph-4,"P2P MONITOR",C.grey,C.panel);marqueeBar(x+4,cy+ph-2,math.max(5,pw-8),pulse,C.orange)
 end
 footer()
end

local function drawItems()
 header("BULDACITY STORAGE MATRIX // LIVE")
 local y=6;local h=math.max(4,H-10);local w=W-6
 panel(3,y,w,h,"ITEM STORAGE",C.cyan)
 local rows=math.max(1,h-3)
 for i=1,math.min(rows,#items) do
  local yy=y+1+i
  txt(6,yy,string.format("%02d",i),C.cyan,C.panel)
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
 if total<=visible then gpu.setBackground(C.green);gpu.fill(x,y,3,trackH," ");return end
 local thumb=math.max(2,math.floor(trackH*visible/total))
 local maxPos=trackH-thumb;local pos=math.floor(maxPos*(scroll-1)/math.max(1,total-visible))
 gpu.setBackground(C.pink);gpu.fill(x,y+pos,3,thumb," ")
end

local function drawCrafts()
 header("BULDACITY CRAFTING MATRIX // SEARCH + START")
 local y=6;local h=math.max(4,H-10);local w=W-6
 local left=math.max(30,math.floor(w*0.64));local right=w-left-2
 panel(3,y,left,h,"CRAFTABLE RECIPES",C.pink)
 ui.craftSearch={x=5,y=y+2,w=math.max(12,left-9),h=2}
 gpu.setBackground(searchActive and C.panel2 or C.bg);gpu.fill(ui.craftSearch.x,ui.craftSearch.y,ui.craftSearch.w,1," ")
 txt(ui.craftSearch.x,ui.craftSearch.y,"SEARCH: ",C.yellow,searchActive and C.panel2 or C.bg)
 txt(ui.craftSearch.x+8,ui.craftSearch.y,fit(craftSearch,math.max(1,ui.craftSearch.w-10)),C.white,searchActive and C.panel2 or C.bg)
 if searchActive then
  local cx=math.min(ui.craftSearch.x+9+#craftSearch,ui.craftSearch.x+ui.craftSearch.w-1)
  txt(cx,ui.craftSearch.y,"_",C.cyan, C.panel2)
 end
 txt(5,y+3,string.format("%d / %d RECIPES",#filteredCrafts,#crafts),C.grey,C.panel)
 local visible=math.max(1,h-7);local maxScroll=math.max(1,#filteredCrafts-visible+1)
 clampCraftScroll()
 local start=craftScroll;local finish=math.min(#filteredCrafts,start+visible-1)
 for pos=start,finish do
  local original=filteredCrafts[pos];local row=pos-start+1;local yy=y+4+row
  local n,a=craftData(crafts[original]);local active=pos==selectedCraft
  if active then gpu.setBackground(C.panel2);gpu.fill(4,yy,left-5,1," ") end
  txt(6,yy,string.format("%02d",pos),active and C.yellow or C.cyan,C.panel)
  txt(11,yy,fit(n,math.max(8,left-29)),C.white,C.panel)
  txt(12+math.max(8,left-29),yy,"x"..tostring(a),C.pink,C.panel)
  ui["craftrow"..pos]={x=4,y=yy,w=left-5,h=1}
 end
 if #filteredCrafts==0 then txt(7,y+7,craftSearch=="" and "NO CRAFTABLE RECIPES" or "NO MATCHING RECIPES",C.red,C.panel) end
 local sx=3+left-4;local sy=y+4;local sh=math.max(2,h-5)
 drawScrollbar(sx,sy,sh,#filteredCrafts,craftScroll,visible)
 button("craftup",sx-1,y+4,5,"▲",C.cyan);button("craftdown",sx-1,y+h-3,5,"▼",C.pink)
 txt(math.max(1,sx-1),y+h-1,fit(tostring(craftScroll).."/"..tostring(maxScroll),5),C.grey,C.panel)
 local x=3+left+2
 panel(x,y,right,h,"CRAFT CONSOLE",C.green)
 local original=selectedOriginalIndex();local n,a=craftData(crafts[original])
 txt(x+3,y+3,"SELECTED",C.grey,C.panel);txt(x+3,y+5,fit(n,math.max(8,right-6)),C.white,C.panel)
 txt(x+3,y+7,"OUTPUT",C.grey,C.panel);txt(x+3,y+8,"x"..tostring(a),C.pink,C.panel)
 button("craft1",x+3,y+10,math.max(6,right-6),"CRAFT x1",C.cyan)
 button("craft16",x+3,y+12,math.max(6,right-6),"CRAFT x16",C.blue)
 button("craft64",x+3,y+14,math.max(6,right-6),"CRAFT x64",C.purple)
 txt(x+3,y+16,"LIVE JOBS",C.grey,C.panel);txt(x+3,y+17,activeJobCount(),C.green,C.panel)
 marqueeBar(x+3,y+19,math.max(5,right-6),pulse,C.green)
 txt(x+3,y+h-3,"CLICK SEARCH / TYPE / ENTER",C.grey,C.panel)
 footer()
end

local function drawJobs()
 header("BULDACITY CRAFTING JOBS // LIVE STATUS")
 local y=6;local h=math.max(4,H-10);local w=W-6
 panel(3,y,w,h,"CRAFTING STATUS",C.green);local yy=y+2
 if #jobs==0 then txt(7,yy,"NO LOCAL CRAFTING REQUESTS",C.grey,C.panel) end
 for i=1,math.min(#jobs,math.max(1,h-4)) do
  local job=jobs[i];local state,col=jobState(job)
  txt(6,yy,string.format("%02d",i),C.cyan,C.panel);txt(10,yy,fit(job.name,math.max(10,w-34)),C.white,C.panel);txt(math.max(1,W-20),yy,state,col,C.panel)
  if state=="RUNNING" then marqueeBar(10,yy+1,math.max(8,w-22),pulse,col) elseif state=="DONE" then bar(10,yy+1,math.max(8,w-22),100,col) else bar(10,yy+1,math.max(8,w-22),0,col) end
  txt(10,yy+2,"REQUEST x"..tostring(job.requested).."  "..string.format("%.1fs",computer.uptime()-job.started),C.grey,C.panel)
  yy=yy+4;if yy>y+h-3 then break end
 end
 footer()
end

local function drawP2P()
 header("BULDACITY P2P // OPENCOMPUTERS LINK MONITOR")
 local y=6;local h=math.max(4,H-10);local w=W-6;local left=math.max(38,math.floor(w*0.58));local right=w-left-2
 panel(3,y,left,h,"P2P / OC DISCOVERY",C.orange);txt(6,y+2,"EXPOSED CANDIDATES",C.grey,C.panel);txt(math.max(1,3+left-12),y+2,#p2ps,C.orange,C.panel)
 local yy=y+4
 if #p2ps==0 then
  led(6,yy,false,C.orange,"NO DIRECT P2P OC COMPONENT")
  txt(6,yy+2,"AE2 rv3 includes the OC P2P tunnel, but this Lua",C.grey,C.panel)
  txt(6,yy+3,"interface only uses methods actually exposed by OC.",C.grey,C.panel)
  txt(6,yy+5,"Configure/link the tunnel in-world with the AE2",C.white,C.panel)
  txt(6,yy+6,"Memory Card when no direct Lua control is exposed.",C.white,C.panel)
 else
  for i=1,math.min(#p2ps,math.max(1,h-7)) do
   local p=p2ps[i];led(6,yy,true,C.orange,fit(p.kind,math.max(10,left-12)));txt(6,yy+1,fit(p.address,math.max(10,left-12)),C.grey,C.panel);txt(6,yy+2,"MATCH SCORE "..tostring(p.score),C.yellow,C.panel)
   txt(6,yy+3,#p.methods>0 and fit(table.concat(p.methods,", "),math.max(10,left-12)) or "NO DOCUMENTED METHODS",#p.methods>0 and C.cyan or C.grey,C.panel)
   yy=yy+5;if yy>y+h-5 then break end
  end
 end
 local x=3+left+2
 panel(x,y,right,h,"P2P STATUS",C.purple);led(x+3,y+3,#p2ps>0,C.orange,#p2ps>0 and "OC P2P CANDIDATE" or "CONFIGURED IN AE2")
 txt(x+3,y+6,"LAST SCAN",C.grey,C.panel);txt(x+3,y+7,string.format("%.1fs",computer.uptime()-lastP2PScan),C.white,C.panel)
 txt(x+3,y+9,"CONTROL MODE",C.grey,C.panel);txt(x+3,y+10,#p2ps>0 and "CAPABILITY DISCOVERY" or "AE2 MEMORY CARD",C.orange,C.panel)
 button("p2pscan",x+3,y+13,math.max(8,right-6),"SCAN P2P",C.orange);txt(x+3,y+16,"NO FAKE API CALLS",C.green,C.panel);txt(x+3,y+18,"BULDACITY monitors what",C.grey,C.panel);txt(x+3,y+19,"the installed OC bridge exposes.",C.grey,C.panel)
 footer()
end

local function drawSystem()
 header("BULDACITY PC // SYSTEM TELEMETRY")
 local y=6;local h=math.max(4,H-10);local w=W-6
 panel(3,y,w,h,"OPENCOMPUTERS SYSTEM",C.blue)
 local mw,mh=safe(gpu.maxResolution);local rw,rh=safe(gpu.getResolution)
 txt(6,y+3,"UPTIME",C.grey,C.panel);txt(26,y+3,string.format("%.1fs",computer.uptime()),C.white,C.panel)
 txt(6,y+5,"GPU RESOLUTION",C.grey,C.panel);txt(26,y+5,tostring(rw or W).."x"..tostring(rh or H),C.cyan,C.panel)
 txt(6,y+7,"GPU MAX",C.grey,C.panel);txt(26,y+7,tostring(mw or W).."x"..tostring(mh or H),C.cyan,C.panel)
 local depth=safe(gpu.getDepth);txt(6,y+9,"COLOR DEPTH",C.grey,C.panel);txt(26,y+9,tostring(depth or "?"),C.pink,C.panel)
 local total=computer.totalMemory and safe(computer.totalMemory) or 0;local free=computer.freeMemory and safe(computer.freeMemory) or 0
 txt(6,y+11,"RAM",C.grey,C.panel);txt(26,y+11,tostring(total or 0).." / "..tostring(free or 0),C.green,C.panel)
 if total and tonumber(total) and tonumber(total)>0 then bar(6,y+13,math.max(10,w-10),100-(tonumber(free or 0)/tonumber(total))*100,C.green) end
 txt(6,y+16,"ME CONTROLLER",C.grey,C.panel);led(26,y+16,true,C.green,"CONNECTED")
 txt(6,y+18,"P2P CANDIDATES",C.grey,C.panel);txt(26,y+18,#p2ps,C.orange,C.panel)
 footer()
end

local function draw()
 ui={};clear(C.bg)
 if page=="HOME" then drawHome() elseif page=="ITEMS" then drawItems() elseif page=="CRAFTS" then drawCrafts() elseif page=="JOBS" then drawJobs() elseif page=="P2P" then drawP2P() elseif page=="SYSTEM" then drawSystem() else page="HOME";drawHome() end
end

local function click(x,y)
 if hit("home",x,y) then page="HOME";searchActive=false
 elseif hit("items",x,y) then page="ITEMS";searchActive=false
 elseif hit("craft",x,y) then page="CRAFTS"
 elseif hit("jobs",x,y) then page="JOBS";searchActive=false
 elseif hit("p2p",x,y) then page="P2P";searchActive=false
 elseif hit("system",x,y) then page="SYSTEM";searchActive=false
 elseif hit("refresh",x,y) then refresh();scanP2P()
 elseif hit("quit",x,y) then running=false
 elseif page=="CRAFTS" and hit("craftSearch",x,y) then searchActive=true;msg="CRAFT SEARCH ACTIVE"
 elseif page=="CRAFTS" and hit("craftup",x,y) then scrollCraft(-1)
 elseif page=="CRAFTS" and hit("craftdown",x,y) then scrollCraft(1)
 elseif page=="CRAFTS" and hit("craft1",x,y) then requestCraft(selectedCraft,1)
 elseif page=="CRAFTS" and hit("craft16",x,y) then requestCraft(selectedCraft,16)
 elseif page=="CRAFTS" and hit("craft64",x,y) then requestCraft(selectedCraft,64)
 elseif page=="CRAFTS" then
  for i=1,#filteredCrafts do if hit("craftrow"..i,x,y) then selectCraft(i);searchActive=false;break end end
 elseif page=="P2P" and hit("p2pscan",x,y) then scanP2P()
 end
end

local function searchKey(char,code)
 if code==1 then searchActive=false;msg="CRAFT SEARCH PAUSED";return true end
 if code==14 then
  if #craftSearch>0 then craftSearch=craftSearch:sub(1,#craftSearch-1);rebuildCraftFilter();msg="SEARCH: "..craftSearch end
  return true
 end
 if code==28 then
  if #filteredCrafts>0 then requestCraft(selectedCraft,1) else msg="NO MATCHING RECIPE" end
  return true
 end
 if code==200 then scrollCraft(-1);return true end
 if code==208 then scrollCraft(1);return true end
 if code==203 then selectCraft(selectedCraft-1);return true end
 if code==205 then selectCraft(selectedCraft+1);return true end
 if char and char>=32 and char<=126 then
  local ch=string.char(char)
  craftSearch=craftSearch..ch
  rebuildCraftFilter()
  msg="SEARCH: "..craftSearch
  return true
 end
 return false
end

resize();refresh();scanP2P();draw()

while running do
 pulse=pulse+1
 local e,a,b,c,d=event.pull(0.5)
 if e=="touch" then
  click(b,c);draw()
 elseif e=="scroll" then
  if page=="CRAFTS" then
   local dir=tonumber(c) or 0
   if dir>0 then scrollCraft(-1) elseif dir<0 then scrollCraft(1) end
   draw()
  end
 elseif e=="key_down" then
  local char=tonumber(b) or 0
  local code=tonumber(c) or 0
  if page=="CRAFTS" and searchActive then
   searchKey(char,code);draw()
  elseif page=="CRAFTS" then
   if code==200 then scrollCraft(-1);draw()
   elseif code==208 then scrollCraft(1);draw()
   elseif code==203 then selectCraft(selectedCraft-1);draw()
   elseif code==205 then selectCraft(selectedCraft+1);draw()
   elseif code==28 then requestCraft(selectedCraft,1);draw()
   elseif code==1 then running=false end
  elseif code==1 then running=false end
 elseif e=="screen_resize" then
  resize();draw()
 end
end

clear(C.bg);txt(3,3,"BULDACITY AE2 CORE OFFLINE",C.cyan,C.bg);txt(3,5,"OpenComputers session ended.",C.grey,C.bg)
