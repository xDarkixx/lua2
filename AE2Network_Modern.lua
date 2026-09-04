-- AE2Network_Modern.lua
-- Futuristic adaptive AE2 HUD for OpenComputers / AE2 rv3 beta 6 / MC 1.7.10
-- Automatically uses the best resolution available from the installed GPU/screen.
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
local msg="SYSTEM READY"
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
  -- Never request a resolution larger than the hardware allows.
  local targetW,targetH=mw,mh
  if targetW<1 then targetW=1 end
  if targetH<1 then targetH=1 end
  safe(gpu.setResolution,targetW,targetH)
  W,H=safe(gpu.getResolution)
  W,H=W or targetW,H or targetH
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
  if w<1 then return end
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
  if y>H then return end
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

local function button(id,x,y,w,label,c,active)
  w=math.max(3,w)
  ui[id]={x=x,y=y,w=w,h=2}
  gpu.setBackground(active and C.white or c)
  gpu.fill(x,y,w,2," ")
  local fg=active and c or C.white
  txt(x+math.max(1,math.floor((w-#label)/2)),y,fit(label,w-2),fg,active and C.white or c)
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

local function refresh()
  local a=safe(me.getItemsInNetwork);items=type(a)=="table" and a or {}
  local b=safe(me.getCraftables);crafts=type(b)=="table" and b or {}
  local c=safe(me.getCpus);cpus=type(c)=="table" and c or {}
  lastScan=computer.uptime()
  msg="NETWORK SCANNED"
end

local function cpuInfo(cpu)
  local busy=objcall(cpu,"isBusy")
  if busy~=true then return false,"CPU IDLE",0,0,0 end
  local js=objcall(cpu,"getJobStatus")
  if type(js)=="table" then
    local out=js.output or js.result or js.item
    local n,a=stackData(out)
    if not n and type(out)=="userdata" then
      local s=objcall(out,"getItemStack");n,a=stackData(s)
    end
    return true,n or "CRAFTING...",a or 0,tonumber(js.craftedAmount or js.crafted or js.completed or 0) or 0,tonumber(js.totalAmount or js.total or 0) or 0
  end
  return true,"CRAFTING...",0,0,0
end

local function systemInfo()
  local energy,maxEnergy=safe(computer.energy),safe(computer.maxEnergy)
  local total,free=safe(computer.totalMemory),safe(computer.freeMemory)
  local depth=safe(gpu.getDepth)
  local screen=safe(gpu.getScreen)
  return energy,maxEnergy,total,free,depth,screen
end

local function header(title)
  gpu.setBackground(C.panel);gpu.fill(1,1,W,4," ")
  txt(2,1,"╔ AE2 // NEON CORE ╗",C.cyan,C.panel)
  txt(3,2,fit(title,math.max(8,W-30)),C.white,C.panel)
  local blink=(pulse%2==0)
  led(math.max(5,W-25),2,true,blink and C.green or C.cyan,"ONLINE")
  line(1,4,W,C.cyan)
end

local function footer()
  local y=math.max(1,H-3)
  local n=6
  local gap=1
  local bw=math.max(3,math.floor((W-4-(n-1)*gap)/n))
  local x=2
  button("home",x,y,bw,"HOME",C.purple,page=="HOME");x=x+bw+gap
  button("items",x,y,bw,"ITEMS",C.cyan,page=="ITEMS");x=x+bw+gap
  button("craft",x,y,bw,"CRAFT",C.pink,page=="CRAFTS");x=x+bw+gap
  button("system",x,y,bw,"PC",C.blue,page=="SYSTEM");x=x+bw+gap
  button("refresh",x,y,bw,"SCAN",C.yellow);x=x+bw+gap
  button("quit",x,y,bw,"EXIT",C.red)
  if H>=2 then txt(2,H,fit(msg,math.max(1,W-4)),C.grey,C.bg) end
end

local function drawHome()
  header("ME NETWORK // LIVE TELEMETRY")
  local cy=6
  local bottom=H-5
  local ph=math.max(4,bottom-cy+1)
  local two=W>=76
  local gap=2
  local pw=two and math.floor((W-6-gap)/2) or W-6
  panel(3,cy,pw,ph,"NETWORK STATUS",C.cyan)
  led(6,cy+3,true,C.green,"ME CONTROLLER")
  txt(6,cy+6,"ITEM TYPES",C.grey,C.panel);txt(math.min(27,pw-8),cy+6,#items,C.cyan,C.panel)
  txt(6,cy+8,"CRAFTABLES",C.grey,C.panel);txt(math.min(27,pw-8),cy+8,#crafts,C.pink,C.panel)
  txt(6,cy+10,"CPUs",C.grey,C.panel);txt(math.min(27,pw-8),cy+10,#cpus,C.yellow,C.panel)
  local busy=0
  for i=1,#cpus do local b=cpuInfo(cpus[i]);if b then busy=busy+1 end end
  txt(6,cy+12,"ACTIVE JOBS",C.grey,C.panel);txt(math.min(27,pw-8),cy+12,busy,C.green,C.panel)
  txt(6,cy+14,"SCAN AGE",C.grey,C.panel);txt(math.min(27,pw-8),cy+14,string.format("%.1fs",computer.uptime()-lastScan),C.white,C.panel)
  if ph>=18 then
    txt(6,cy+16,"NETWORK LOAD",C.grey,C.panel)
    bar(6,cy+17,math.max(5,pw-12),math.min(100,#items/1000*100),C.cyan)
  end
  if two then
    local x=3+pw+gap
    panel(x,cy,pw,ph,"CPU MATRIX",C.purple)
    local yy=cy+3
    for i=1,math.min(6,#cpus) do
      local b,n=cpuInfo(cpus[i])
      led(x+4,yy,b,b and C.green or C.purple,b and fit(n,math.max(8,pw-12)) or "CPU IDLE")
      yy=yy+2
      if yy>cy+ph-4 then break end
    end
    if #cpus==0 then txt(x+5,cy+5,"NO CPU DATA",C.grey,C.panel) end
  end
  footer()
end

local function drawItems()
  header("STORAGE MATRIX // LIVE")
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

local function drawCrafts()
  header("CRAFTING MATRIX // RECIPES + JOBS")
  local y=6;local h=math.max(4,H-10);local w=W-6
  panel(3,y,w,h,"CRAFTABLE OUTPUTS",C.pink)
  local rows=math.max(1,math.floor((h-5)/2))
  for i=1,math.min(rows,#crafts) do
    local yy=y+2+i*2
    local n,a=craftData(crafts[i])
    txt(6,yy,string.format("%02d",i),C.cyan,C.panel)
    txt(11,yy,fit(n,math.max(8,w-38)),C.white,C.panel)
    txt(math.max(1,W-22),yy,"x"..tostring(a),C.pink,C.panel)
  end
  local start=math.max(y+3,y+h-6)
  txt(6,start,"ACTIVE CPU JOBS",C.grey,C.panel)
  local shown=0
  for i=1,#cpus do
    local b,n,a,done,total=cpuInfo(cpus[i])
    if b and shown<3 and start+shown+1<H-3 then
      shown=shown+1
      local yy=start+shown
      txt(7,yy,"●",C.green,C.panel)
      txt(11,yy,fit(n,math.max(8,w-35)),C.white,C.panel)
      if total>0 then
        local pct=done/total*100
        bar(math.max(11,W-42),yy,math.max(5,24),pct,C.green)
      else
        txt(math.max(1,W-22),yy,"RUNNING",C.green,C.panel)
      end
    end
  end
  if shown==0 and start+1<H then txt(7,start+1,"NO ACTIVE CRAFTING JOB",C.grey,C.panel) end
  footer()
end

local function drawSystem()
  header("PC // OPENCOMPUTERS SYSTEM MONITOR")
  local y=6;local h=math.max(4,H-10);local w=W-6
  panel(3,y,w,h,"COMPUTER CORE",C.blue)
  local energy,maxEnergy,total,free,depth,screen=systemInfo()
  txt(6,y+3,"UPTIME",C.grey,C.panel);txt(24,y+3,string.format("%.1fs",computer.uptime()),C.cyan,C.panel)
  txt(6,y+5,"CLOCK",C.grey,C.panel);txt(24,y+5,os.date("%H:%M:%S"),C.white,C.panel)
  if energy and maxEnergy then
    local ep=maxEnergy>0 and energy/maxEnergy*100 or 0
    txt(6,y+7,"ENERGY",C.grey,C.panel);txt(24,y+7,string.format("%.0f / %.0f",energy,maxEnergy),C.yellow,C.panel)
    bar(24,y+8,math.max(8,w-30),ep,C.yellow)
  end
  if total and free then
    local used=total-free
    local mp=total>0 and used/total*100 or 0
    txt(6,y+10,"MEMORY",C.grey,C.panel);txt(24,y+10,string.format("%d / %d B",used,total),C.purple,C.panel)
    bar(24,y+11,math.max(8,w-30),mp,C.purple)
  end
  local rw,rh=safe(gpu.getResolution)
  txt(6,y+13,"GPU RES",C.grey,C.panel);txt(24,y+13,string.format("%dx%d",rw or W,rh or H),C.cyan,C.panel)
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
  else drawSystem() end
end

local function click(x,y)
  if hit("home",x,y) then page="HOME"
  elseif hit("items",x,y) then page="ITEMS"
  elseif hit("craft",x,y) then page="CRAFTS"
  elseif hit("system",x,y) then page="SYSTEM"
  elseif hit("refresh",x,y) then refresh()
  elseif hit("quit",x,y) then running=false end
end

resize();refresh();draw()
while running do
  local e,a,x,y=event.pull(1)
  if e=="touch" then click(x,y);draw()
  elseif e=="key_down" then
    local c=y
    if c==string.byte("q") or c==string.byte("Q") then running=false
    elseif c==string.byte("r") or c==string.byte("R") then refresh()
    elseif c==string.byte("i") or c==string.byte("I") then page="ITEMS"
    elseif c==string.byte("c") or c==string.byte("C") then page="CRAFTS"
    elseif c==string.byte("p") or c==string.byte("P") then page="SYSTEM" end
    draw()
  end
  if computer.uptime()-lastScan>=5 then refresh();draw() end
end

gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")
