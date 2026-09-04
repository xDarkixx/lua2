-- LogisticsPipes_Modern.lua
-- Buldacity controller for Logistics Pipes 0.9.3.132 / Minecraft 1.7.10.
-- Live component discovery, rich dashboard, API inspection and safe zero-argument probing.
local component=require("component")
local computer=require("computer")
local event=require("event")
local gpu=component.gpu
local W,H=gpu.getResolution()
local BG=0x080C14
local CYAN=0x66FFFF
local GREEN=0x66FF99
local ORANGE=0xFFAA55
local RED=0xFF6677
local WHITE=0xFFFFFF
local SCAN_INTERVAL=2
local comps={}
local all={}
local selected=1
local page="HOME"
local apiRows={}
local result="READY"
local lastScan=0

local function fit(s,n)
 s=tostring(s or "")
 if #s>n then return s:sub(1,math.max(1,n-3)).."..." end
 return s
end
local function clear() gpu.setBackground(BG); gpu.setForeground(CYAN); gpu.fill(1,1,W,H," ") end
local function txt(x,y,s,color) if y>=1 and y<=H then if color then gpu.setForeground(color) end gpu.set(x,y,fit(s,W-x+1)); gpu.setForeground(CYAN) end end
local function header(s)
 gpu.setBackground(BG); gpu.setForeground(CYAN); gpu.fill(1,1,W,1," "); gpu.set(2,1,"BULDACITY // LOGISTICS PIPES // "..fit(s,W-35))
 gpu.setForeground(ORANGE); gpu.fill(1,2,W,1,"-"); gpu.setForeground(CYAN)
end
local function button(x,y,w,label,active)
 gpu.setBackground(active and 0x102A32 or 0x111827); gpu.setForeground(active and CYAN or WHITE); gpu.fill(x,y,w,2," "); gpu.set(x+1,y,fit(label,w-2)); gpu.setBackground(BG); gpu.setForeground(CYAN)
end
local function footer(items)
 local n=#items; local bw=math.max(8,math.floor((W-4)/n))
 for i,v in ipairs(items) do button(2+(i-1)*bw,H-2,bw-1,v,page==v) end
end
local function methodCount(c)
 local n=0; for _ in pairs(c.methods or {}) do n=n+1 end; return n end
local function findLP()
 local out={}
 for addr,typ in component.list() do
  local ok,methods=pcall(component.methods,addr); methods=ok and methods or {}
  local name=tostring(typ); local low=name:lower(); local score=0
  if low:find("logistic") then score=100 end
  for m in pairs(methods) do
   local x=tostring(m):lower()
   if x:find("logistic") then score=score+8 end
   if x:find("request") then score=score+5 end
   if x:find("item") then score=score+3 end
   if x:find("pipe") then score=score+2 end
   if x:find("craft") then score=score+2 end
  end
  if score>0 then out[#out+1]={addr=addr,typ=name,score=score,methods=methods} end
 end
 table.sort(out,function(a,b) if a.score==b.score then return a.addr<b.addr end return a.score>b.score end)
 return out
end
local function scan()
 local old=comps[selected] and comps[selected].addr or nil
 comps=findLP(); all={}
 for addr,typ in component.list() do
  local ok,m=pcall(component.methods,addr); all[#all+1]={addr=addr,typ=tostring(typ),methods=ok and m or {}}
 end
 table.sort(all,function(a,b) if a.typ==b.typ then return a.addr<b.addr end return a.typ<b.typ end)
 selected=1
 if old then for i,c in ipairs(comps) do if c.addr==old then selected=i; break end end end
 lastScan=computer.uptime()
end
local function selectedComp() return comps[selected] end
local function sortedMethods(c)
 local t={}; for m,v in pairs(c.methods or {}) do t[#t+1]={name=tostring(m),value=v} end
 table.sort(t,function(a,b)return a.name<b.name end); return t
end
local function safeCall(c,name)
 local ok,a,b,c2,d=pcall(component.invoke,c.addr,name)
 if not ok then result="ERROR // "..tostring(a); return end
 result="OK // "..name.." // "..fit(tostring(a),W-25)
end
local function drawHome()
 clear(); header("COMMAND")
 local c=selectedComp()
 txt(2,4,"LOGISTICS PIPES 0.9.3.132",ORANGE)
 txt(2,5,"Minecraft 1.7.10  //  OpenComputers integration")
 txt(2,7,"STATUS",WHITE); txt(12,7,c and "ONLINE / DETECTED" or "NOT DIRECTLY EXPOSED",c and GREEN or RED)
 txt(2,8,"LP TARGET",WHITE); txt(12,8,c and (c.typ.." @"..c.addr:sub(1,12)) or "none",CYAN)
 txt(2,9,"COMPONENTS",WHITE); txt(15,9,#all.." total  //  "..#comps.." LP candidates")
 txt(2,11,"LIVE SCAN",ORANGE); txt(14,11,"every "..SCAN_INTERVAL.." seconds",GREEN)
 txt(2,13,"REAL API",ORANGE); txt(14,13,"methods are read from the installed OC runtime",CYAN)
 txt(2,15,"NETWORK",ORANGE); txt(14,15,"Tier-2 controller supported",CYAN)
 txt(2,17,"TIP",WHITE); txt(7,17,"Touch COMPONENTS to select an LP endpoint; API lists every exposed method.")
 footer({"HOME","COMPONENTS","API","NETWORK","CONTROL"})
end
local function drawComponents()
 clear(); header("LIVE COMPONENT BUS")
 txt(2,3,"LIVE COMPONENTS: "..#all,ORANGE); txt(28,3,"LP CANDIDATES: "..#comps,GREEN)
 local y=5
 for i,c in ipairs(all) do
  if y>H-4 then break end
  local active=false
  for j,p in ipairs(comps) do if p.addr==c.addr then active=(j==selected); break end end
  if active then gpu.setBackground(0x102A32); gpu.fill(1,y,W,1," ") end
  txt(2,y,string.format("%02d  %-18s  %s  [%d]",i,fit(c.typ,18),c.addr:sub(1,12),methodCount(c)),active and WHITE or CYAN)
  gpu.setBackground(BG); gpu.setForeground(CYAN); y=y+1
 end
 txt(2,H-4,"Touch an LP candidate row to select it.  R = rescan.",ORANGE)
 footer({"HOME","REFRESH","API"})
end
local function drawAPI()
 clear(); header("EXPOSED API // REAL RUNTIME")
 local c=selectedComp()
 if not c then txt(2,5,"NO LP CANDIDATE DETECTED",RED); footer({"HOME","COMPONENTS","REFRESH"}); return end
 txt(2,3,c.typ.." @"..c.addr,ORANGE); txt(2,4,"METHODS: "..methodCount(c),GREEN)
 apiRows=sortedMethods(c)
 local y=6
 for i,r in ipairs(apiRows) do
  if y>H-5 then break end
  txt(2,y,string.format("%02d  %-30s %s",i,fit(r.name,30),r.value and "CALLABLE" or "EXPOSED"),WHITE)
  y=y+1
 end
 txt(2,H-4,"Touch a method row: zero-argument methods are probed safely; argument methods are only inspected.",ORANGE)
 footer({"HOME","CONTROL","REFRESH"})
end
local function drawNetwork()
 clear(); header("NETWORK")
 local c=selectedComp()
 txt(2,4,"PROTOCOL",ORANGE); txt(15,4,"BULDACITY/1  //  PORT 4242",GREEN)
 txt(2,6,"TIER-2",ORANGE); txt(15,6,"LogisticsPipesNetwork_Modern.lua",CYAN)
 txt(2,7,"TIER-3",ORANGE); txt(15,7,"BuldacityServer_Tier3.lua",CYAN)
 txt(2,9,"LP STATUS",ORANGE); txt(15,9,c and "DETECTED" or "WAITING / FALLBACK",c and GREEN or RED)
 txt(2,11,"REMOTE",ORANGE); txt(15,11,"keyboard / touch / scroll forwarding supported",CYAN)
 txt(2,13,"COMPONENT SCAN",ORANGE); txt(20,13,"live every "..SCAN_INTERVAL.." seconds",GREEN)
 txt(2,15,"NOTE",WHITE); txt(8,15,"Some LP/OpenComputers combinations expose a pipe as bc_pipe.")
 txt(2,16,"The controller therefore discovers the runtime API instead of assuming a fixed LP address.")
 footer({"HOME","COMPONENTS","REFRESH"})
end
local function drawControl()
 clear(); header("CONTROL // SAFE PROBE")
 local c=selectedComp()
 if not c then txt(2,5,"NO LP CANDIDATE DETECTED",RED); footer({"HOME","API","REFRESH"}); return end
 txt(2,3,"TARGET: "..c.typ.." @"..c.addr,ORANGE)
 txt(2,4,"RESULT: "..result,GREEN)
 txt(2,6,"Zero-argument API probe",WHITE)
 local y=8; local n=0
 for _,r in ipairs(sortedMethods(c)) do
  if y>H-5 then break end
  n=n+1
  local lower=r.name:lower()
  local probe=(not lower:find("set")) and (not lower:find("add")) and (not lower:find("remove")) and (not lower:find("clear")) and (not lower:find("request")) and (not lower:find("craft"))
  txt(2,y,string.format("%02d %-28s %s",n,fit(r.name,28),probe and "PROBE" or "INSPECT"),probe and GREEN or WHITE)
  y=y+1
 end
 txt(2,H-4,"CONTROL never invents arguments and does not call mutating methods without parameters.",ORANGE)
 footer({"HOME","API","REFRESH"})
end
local function draw()
 if page=="HOME" then drawHome() elseif page=="COMPONENTS" then drawComponents() elseif page=="API" then drawAPI() elseif page=="NETWORK" then drawNetwork() else drawControl() end
end
scan(); draw()
while true do
 if computer.uptime()-lastScan>=SCAN_INTERVAL then scan(); draw() end
 local e={event.pull(1)}
 if e[1]=="touch" then
  local x,y=e[3],e[4]
  if page=="COMPONENTS" and y>=5 and y<H-4 then
   local idx=y-4; local c=all[idx]
   if c then for i,p in ipairs(comps) do if p.addr==c.addr then selected=i; break end end; page="API"; draw() end
  elseif page=="API" and y>=6 and y<H-4 then
   local idx=y-5; local r=apiRows[idx]; local c=selectedComp()
   if r and c then
    local low=r.name:lower()
    local mut=low:find("set") or low:find("add") or low:find("remove") or low:find("clear") or low:find("request") or low:find("craft")
    if mut then result="INSPECT ONLY // arguments required or method may mutate state" else safeCall(c,r.name) end
    page="CONTROL"; draw()
   end
  elseif y>=H-2 then
   local labels={"HOME","COMPONENTS","API","NETWORK","CONTROL","REFRESH"}
   local idx=math.floor((x-2)/math.max(1,math.floor((W-4)/#labels)))+1
   local a=labels[idx]
   if a=="REFRESH" then scan(); draw() elseif a then page=a; draw() end
  end
 elseif e[1]=="key_down" then
  local code=e[4] or e[3]
  if code==16 or code==28 then break elseif code==19 then scan(); draw() end
 elseif e[1]=="interrupted" then break end
end
