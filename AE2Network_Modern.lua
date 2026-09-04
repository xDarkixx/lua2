-- AE2Network_Modern.lua
-- Modern responsive LED dashboard for AE2 rv3 beta 6 / OC 1.8.10 / MC 1.7.10
-- Fix: AE2 Craftable methods are called in the OpenComputers userdata style (without self).
local component=require("component")
local event=require("event")
local computer=require("computer")
local gpu=component.gpu
local me=component.me_controller
if not me then error("Kein me_controller gefunden.") end
local W,H=80,25;local page="HOME";local running=true;local items={};local crafts={};local cpus={};local msg="SYSTEM READY";local last=0
local C={bg=0x05080D,panel=0x0D141D,panel2=0x111D29,line=0x26384A,blue=0x35B9FF,cyan=0x55F5FF,green=0x39FF88,red=0xFF4F68,yellow=0xFFE36E,purple=0xB47CFF,white=0xF4FAFF,grey=0x7F95A8,off=0x24313C};local ui={}
local function resize()local mw,mh=gpu.maxResolution();local cw,ch=gpu.getResolution();W,H=mw or cw,mh or ch;if W<40 then W=40 end;if H<20 then H=20 end;pcall(gpu.setResolution,W,H);W,H=gpu.getResolution()end
local function sc(fn,...)local ok,a,b,c,d=pcall(fn,...);if ok then return a,b,c,d end end
local function objcall(o,m,...)
  if not o then return nil end
  local ok,a,b,c=pcall(function(...) return o[m](...) end,...)
  if ok then return a,b,c end
  ok,a,b,c=pcall(function(...) return o[m](o,...) end,...)
  if ok then return a,b,c end
end
local function txt(x,y,s,fg,bg)gpu.setForeground(fg or C.white);gpu.setBackground(bg or C.bg);gpu.set(x,y,tostring(s))end
local function box(x,y,w,h,t,c)gpu.setBackground(C.panel);gpu.fill(x,y,w,h," ");gpu.setBackground(C.line);gpu.fill(x,y,w,1," ");txt(x+2,y,"◆ "..t,c or C.cyan,C.panel)end
local function fit(s,n)s=tostring(s or "");return #s<=n and s or s:sub(1,math.max(1,n-1)).."…"end
local function led(x,y,on,c,label)local cc=on and c or C.off;gpu.setBackground(cc);gpu.fill(x,y,2,1," ");txt(x+3,y,fit(label or(on and"ONLINE"or"OFFLINE"),18),on and cc or C.grey,C.panel)end
local function bar(x,y,w,p,c)p=math.max(0,math.min(100,tonumber(p)or 0));local n=math.floor(w*p/100);gpu.setBackground(C.panel2);gpu.fill(x,y,w,1," ");if n>0 then gpu.setBackground(c);gpu.fill(x,y,n,1," ")end end
local function btn(id,x,y,w,label,c,on)ui[id]={x=x,y=y,w=w,h=2};gpu.setBackground(on and C.white or c);gpu.fill(x,y,w,2," ");txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),on and c or C.white,on and C.white or c)end
local function hit(id,x,y)local b=ui[id];return b and x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h end
local function stackData(s)
  if type(s)=="table" then return s.label or s.displayName or s.name or s.id or s.item,tonumber(s.size or s.amount or s.count or 0)or 0 end
  return nil,0
end
local function itemName(e)local n=stackData(e);return n or tostring(e or"--")end
local function amount(e)local _,a=stackData(e);return a or 0 end
local function craftData(c)
  local s=objcall(c,"getItemStack")
  local n,a=stackData(s)
  if n then return n,a end
  return "UNKNOWN RECIPE",1
end
local function refresh()
  local a=sc(me.getItemsInNetwork);items=type(a)=="table"and a or{}
  local b=sc(me.getCraftables);crafts=type(b)=="table"and b or{}
  local c=sc(me.getCpus);cpus=type(c)=="table"and c or{}
  last=computer.uptime();msg="NETWORK SCANNED"
end
local function cpuInfo(cpu)
  local busy=objcall(cpu,"isBusy")
  if busy~=true then return false,"CPU IDLE",0,0,0 end
  local js=objcall(cpu,"getJobStatus")
  if type(js)=="table"then
    local out=js.output or js.result or js.item
    local n,a=stackData(out)
    if not n and type(out)=="userdata"then local s=objcall(out,"getItemStack");n,a=stackData(s)end
    return true,n or"CRAFTING...",a or 0,tonumber(js.craftedAmount or js.crafted or js.completed or 0),tonumber(js.totalAmount or js.total or 0)
  end
  return true,"CRAFTING...",0,0,0
end
local function header(title)gpu.setBackground(C.panel);gpu.fill(1,1,W,4," ");txt(3,2,"◈ AE2 // ME CONTROL",C.cyan,C.panel);txt(math.max(25,math.floor(W*.34)),2,fit(title,math.max(8,W-28)),C.white,C.panel);led(math.max(5,W-24),2,true,C.green,"ONLINE");gpu.setBackground(C.cyan);gpu.fill(1,4,W,1," ")end
local function footer()local y=H-3;local gap=1;local n=5;local bw=math.max(7,math.floor((W-4-(n-1)*gap)/n));local x=2;btn("home",x,y,bw,"HOME",C.purple,page=="HOME");x=x+bw+gap;btn("items",x,y,bw,"ITEMS",C.cyan,page=="ITEMS");x=x+bw+gap;btn("craft",x,y,bw,"CRAFT",C.purple,page=="CRAFTS");x=x+bw+gap;btn("refresh",x,y,bw,"SCAN",C.yellow);x=x+bw+gap;btn("quit",x,y,bw,"EXIT",C.red);txt(3,H,fit(msg,W-6),C.grey,C.panel)end
local function drawHome()header("NETWORK OVERVIEW");local cy=6;local h=H-10;local two=W>=82;local gap=2;local pw=two and math.floor((W-6-gap)/2)or W-6;box(3,cy,pw,h,"ME NETWORK",C.cyan);led(6,cy+3,true,C.green,"ME CONTROLLER");txt(6,cy+6,"ITEM TYPES",C.grey,C.panel);txt(22,cy+6,#items,C.cyan,C.panel);txt(6,cy+8,"CRAFTABLES",C.grey,C.panel);txt(22,cy+8,#crafts,C.purple,C.panel);txt(6,cy+10,"CRAFTING CPUs",C.grey,C.panel);txt(22,cy+10,#cpus,C.yellow,C.panel);local busy=0;for i=1,#cpus do local b=cpuInfo(cpus[i]);if b then busy=busy+1 end end;txt(6,cy+12,"ACTIVE JOBS",C.grey,C.panel);txt(22,cy+12,busy,C.green,C.panel);txt(6,cy+14,"LAST SCAN",C.grey,C.panel);txt(22,cy+14,string.format("%.1fs",computer.uptime()-last),C.white,C.panel);if two then local x=3+pw+gap;box(x,cy,pw,h,"CRAFTING STATUS",C.purple);local yy=cy+3;for i=1,math.min(5,#cpus)do local b,n=cpuInfo(cpus[i]);led(x+4,yy,b,C.green,b and fit(n,22)or"CPU IDLE");yy=yy+2 end end;footer()end
local function drawItems()header("STORAGE MATRIX");local y=6;local h=H-10;local w=W-6;box(3,y,w,h,"STORED ITEMS",C.cyan);local rows=math.max(1,h-4);for i=1,math.min(rows,#items)do local yy=y+2+i;txt(6,yy,string.format("%02d",i),C.cyan,C.panel);txt(11,yy,fit(itemName(items[i]),math.max(10,w-35)),C.white,C.panel);txt(W-20,yy,tostring(amount(items[i])),C.green,C.panel)end;if #items==0 then txt(7,y+4,"NO DATA",C.red,C.panel)end;footer()end
local function drawCrafts()header("CRAFTING MATRIX");local y=6;local h=H-10;local w=W-6;box(3,y,w,h,"CRAFTABLE RECIPES + ACTIVE JOBS",C.purple);txt(6,y+2,"CRAFTABLE OUTPUTS",C.grey,C.panel);local rows=math.max(1,math.floor((h-7)/2));for i=1,math.min(rows,#crafts)do local yy=y+3+i*2;local n,a=craftData(crafts[i]);txt(6,yy,string.format("%02d",i),C.cyan,C.panel);txt(11,yy,fit(n,math.max(10,w-38)),C.white,C.panel);txt(W-22,yy,"x"..tostring(a),C.purple,C.panel)end;local start=y+h-6;txt(6,start,"CURRENT CPU JOBS",C.grey,C.panel);local shown=0;for i=1,#cpus do local b,n,a,done,total=cpuInfo(cpus[i]);if b and shown<3 then shown=shown+1;local yy=start+shown;txt(7,yy,"●",C.green,C.panel);txt(11,yy,fit(n,math.max(10,w-35)),C.white,C.panel);if total>0 then txt(W-22,yy,string.format("%d/%d",done,total),C.green,C.panel)else txt(W-22,yy,"RUNNING",C.green,C.panel)end end end;if shown==0 then txt(7,start+1,"NO ACTIVE CRAFTING JOB",C.grey,C.panel)end;footer()end
local function draw()resize();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");if page=="HOME"then drawHome()elseif page=="ITEMS"then drawItems()else drawCrafts()end end
local function click(x,y)if hit("home",x,y)then page="HOME"elseif hit("items",x,y)then page="ITEMS"elseif hit("craft",x,y)then page="CRAFTS"elseif hit("refresh",x,y)then refresh()elseif hit("quit",x,y)then running=false end end
resize();refresh();draw();while running do local e,a,x,y=event.pull(1);if e=="touch"then click(x,y);draw()elseif e=="key_down"then local c=y;if c==string.byte("q")or c==string.byte("Q")then running=false elseif c==string.byte("r")or c==string.byte("R")then refresh()elseif c==string.byte("i")or c==string.byte("I")then page="ITEMS"elseif c==string.byte("c")or c==string.byte("C")then page="CRAFTS"end;draw()end;if computer.uptime()-last>=5 then refresh();draw()end end
gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")
