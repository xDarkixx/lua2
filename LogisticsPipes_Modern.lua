-- LogisticsPipes_Modern.lua
-- Buldacity controller for Logistics Pipes 0.9.3.132 / Minecraft 1.7.10.
-- Component discovery is refreshed continuously so added/removed OC devices appear automatically.
local component=require("component")
local computer=require("computer")
local event=require("event")
local gpu=component.gpu
local screen=component.screen

local W,H=gpu.getResolution()
local function clamp(n,a,b) if n<a then return a elseif n>b then return b end return n end
local function fit(s,n) s=tostring(s or "") if #s>n then return s:sub(1,n-3).."..." end return s end
local function bar(x,y,w,p) p=clamp(tonumber(p) or 0,0,1); gpu.fill(x,y,w,1," "); if w>2 then gpu.fill(x,y,math.floor((w-2)*p),1,"=") end end
local function title(t) gpu.fill(1,1,W,1," "); gpu.set(2,1,"BULDACITY // LOGISTICS PIPES // "..fit(t,W-35)) end
local function line(y,s) if y<=H then gpu.set(2,y,fit(s,W-2)) end end
local function buttons(items,y)
 for i,b in ipairs(items) do local x=2+(i-1)*math.floor((W-4)/#items); local w=math.floor((W-4)/#items)-1; gpu.fill(x,y,w,2," "); gpu.set(x+1,y,b[1]) end
end
local function clear() gpu.fill(1,1,W,H," ") end
local function findLP()
 local out={}
 for addr,typ in component.list() do
  local ok,methods=pcall(component.methods,addr)
  local name=tostring(typ)
  local score=0
  if name:lower():find("logistic") then score=10 end
  if ok and methods then
   for m,_ in pairs(methods) do if tostring(m):lower():find("logistic") or tostring(m):lower():find("item") or tostring(m):lower():find("request") then score=score+1 end end
  end
  if score>0 then table.insert(out,{addr=addr,typ=name,score=score,methods=methods or {}}) end
 end
 table.sort(out,function(a,b)return a.score>b.score end)
 return out
end
local function allComponents()
 local out={}
 for addr,typ in component.list() do
  local ok,methods=pcall(component.methods,addr)
  table.insert(out,{addr=addr,typ=tostring(typ),methods=ok and methods or {}})
 end
 table.sort(out,function(a,b) return a.typ<b.typ end)
 return out
end

local comps=findLP(); local all=allComponents(); local selected=1; local page="HOME"; local msg="READY"
local lastScan=0
local SCAN_INTERVAL=2
local function selectedComp() return comps[selected] end

-- Rebuild both lists from the live OC component bus. The current LP selection is
-- preserved by address when possible, so hot-plugging does not jump to another device.
local function refreshComponents(force)
 local now=computer.uptime()
 if not force and now-lastScan<SCAN_INTERVAL then return false end
 lastScan=now
 local oldAddr=selectedComp() and selectedComp().addr or nil
 comps=findLP()
 all=allComponents()
 selected=1
 if oldAddr then
  for i,c in ipairs(comps) do if c.addr==oldAddr then selected=i break end end
 end
 return true
end

local function drawHome()
 clear(); title("COMMAND")
 line(3,"LP target: "..(selectedComp() and (selectedComp().typ.." @"..selectedComp().addr:sub(1,8)) or "NOT FOUND"))
 line(4,"OC components: "..#all.."   LP candidates: "..#comps.."   AUTO-SCAN: "..SCAN_INTERVAL.."s")
 line(6,"REAL-TIME COMPONENT DISCOVERY")
 line(8,"The component list is rebuilt from component.list() automatically while this screen runs.")
 line(10,"Pages: NETWORK  COMPONENTS  API  INVENTORY  CONTROL")
 buttons({{"NETWORK","NETWORK"},{"COMPONENTS","COMPONENTS"},{"API","API"},{"INVENTORY","INVENTORY"},{"CONTROL","CONTROL"}},H-3)
end
local function drawComponents()
 clear(); title("COMPONENTS")
 local y=3
 for i,c in ipairs(all) do
  if y>H-3 then break end
  line(y,string.format("%2d  %-20s  %s",i,fit(c.typ,20),c.addr:sub(1,12))); y=y+1
 end
 line(H-4,"LIVE LIST • rescans automatically every "..SCAN_INTERVAL.." seconds")
 buttons({{"HOME","HOME"},{"REFRESH","REFRESH"},{"API","API"}},H-3)
end
local function drawAPI()
 clear(); title("EXPOSED API")
 local c=selectedComp(); if not c then line(4,"NO LOGISTICS PIPES OC OBJECT FOUND"); buttons({{"HOME","HOME"},{"REFRESH","REFRESH"}},H-3); return end
 line(3,c.typ.." @"..c.addr)
 local y=5; local n=0
 for m,v in pairs(c.methods) do if y<=H-4 then line(y,string.format("%-28s %s",fit(m,28),v and "CALLABLE" or "?")); y=y+1; n=n+1 end end
 line(H-4,"Methods shown here come directly from component.methods().")
 buttons({{"HOME","HOME"},{"CONTROL","CONTROL"},{"REFRESH","REFRESH"}},H-3)
end
local function drawInventory()
 clear(); title("INVENTORY / LOGISTICS")
 line(3,"LP 0.9.3.132 is primarily a pipe-routing system; OC exposure depends on the installed integration.")
 line(5,"Available inventory-capable components:")
 local y=7
 for _,c in ipairs(all) do
  local has=false
  for m,_ in pairs(c.methods) do local s=tostring(m):lower(); if s:find("inventory") or s:find("slot") or s:find("item") then has=true end end
  if has and y<H-4 then line(y,c.typ.." @"..c.addr:sub(1,10)); y=y+1 end
 end
 line(H-4,"Use API to inspect the exact methods before issuing a call.")
 buttons({{"HOME","HOME"},{"API","API"}},H-3)
end
local function drawNetwork()
 clear(); title("LOGISTICS NETWORK")
 line(3,"Version target: logisticspipes-0.9.3.132 / Minecraft 1.7.10")
 line(5,"LP OC integration: "..(#comps>0 and "DETECTED" or "NOT DIRECTLY EXPOSED"))
 line(6,"OC components visible: "..#all)
 line(8,"Important: older LP/OC combinations can expose pipes as bc_pipe instead of an LP component.")
 line(9,"This dashboard therefore discovers the runtime API instead of assuming an address/type.")
 line(11,"For full LP routing/crafting control, the exact OC wrapper methods must be present in your installed build.")
 buttons({{"HOME","HOME"},{"COMPONENTS","COMPONENTS"},{"REFRESH","REFRESH"}},H-3)
end
local function drawControl()
 clear(); title("CONTROL")
 local c=selectedComp(); if not c then line(4,"NO CALLABLE LP COMPONENT SELECTED"); buttons({{"HOME","HOME"},{"API","API"}},H-3); return end
 line(3,"Selected: "..c.typ.." @"..c.addr)
 line(5,"Generic safe console: select a method by keyboard input in OpenOS shell.")
 line(7,"This UI does not fabricate arguments for LP methods.")
 line(9,"Use the API page to see exact method names and signatures exposed by OC.")
 line(11,"Press R to rescan components. ESC/Q exits.")
 buttons({{"HOME","HOME"},{"API","API"},{"REFRESH","REFRESH"}},H-3)
end
local function draw()
 if page=="HOME" then drawHome() elseif page=="COMPONENTS" then drawComponents() elseif page=="API" then drawAPI() elseif page=="INVENTORY" then drawInventory() elseif page=="NETWORK" then drawNetwork() else drawControl() end
end
local function refresh()
 refreshComponents(true)
 draw()
end
gpu.setBackground(0x080C14); gpu.setForeground(0x66FFFF); draw()
while true do
 local changed=refreshComponents(false)
 if changed then draw() end
 local e={event.pull(1)}
 if e[1]=="touch" then
  local x,y=e[3],e[4]
  if y>=H-3 then
   local idx=math.floor((x-2)/math.max(1,math.floor((W-4)/5)))+1
   local map={"HOME","NETWORK","COMPONENTS","API","INVENTORY"}
   if page=="CONTROL" then map={"HOME","API","REFRESH"} end
   if page=="NETWORK" then map={"HOME","COMPONENTS","REFRESH"} end
   if page=="COMPONENTS" then map={"HOME","REFRESH","API"} end
   if page=="API" then map={"HOME","CONTROL","REFRESH"} end
   if page=="INVENTORY" then map={"HOME","API"} end
   local action=map[idx]
   if action=="REFRESH" then refresh() else page=action or page; draw() end
  end
 elseif e[1]=="key_down" then
  local c=e[3]
  if c==16 or c==28 then break elseif c==19 then refresh() end
 elseif e[1]=="interrupted" then break end
end
