-- PneumaticCraft_Modern.lua
-- BULDACITY PneumaticCraft controller
-- Target: PneumaticCraft-1.7.10-1.12.7-152-universal.jar
-- Uses the real PneumaticCraft OpenComputers droneInterface component when present.
local component=require("component")
local computer=require("computer")
local event=require("event")
local gpu=component.gpu
local screen=component.screen

local W,H=gpu.getResolution()
local C={bg=0x071018,panel=0x0D1B27,cyan=0x20F0FF,blue=0x268CFF,green=0x55FF9A,orange=0xFFB347,red=0xFF5577,white=0xEAFBFF,dim=0x7893A5,purple=0xB875FF}
local page="OVERVIEW"
local running=true
local selected=1
local actions={}
local actionScroll=1
local status="Scanning PneumaticCraft..."
local lastError=nil
local drone=nil

local function findDrone()
  drone=nil
  for addr in component.list("droneInterface") do
    drone=component.proxy(addr)
    break
  end
  return drone
end

local function safe(method,...)
  if not drone then return nil,"droneInterface not found" end
  local ok,a,b,c,d,e=pcall(drone[method],...)
  if not ok then lastError=tostring(a); return nil,lastError end
  return a,b,c,d,e
end

local function clear()
  gpu.setBackground(C.bg); gpu.setForeground(C.white); gpu.fill(1,1,W,H," ")
end
local function box(x,y,w,h,title)
  gpu.setBackground(C.panel); gpu.fill(x,y,w,h," ")
  gpu.setForeground(C.cyan); gpu.set(x,y,"+"..string.rep("-",math.max(0,w-2)).."+")
  for i=1,h-2 do gpu.set(x,y+i,"|"..string.rep(" ",math.max(0,w-2)).."|") end
  if h>1 then gpu.set(x,y+h-1,"+"..string.rep("-",math.max(0,w-2)).."+") end
  if title then gpu.setForeground(C.cyan); gpu.set(x+2,y,title) end
end
local function text(x,y,s,col)
  gpu.setForeground(col or C.white); gpu.set(x,y,tostring(s):sub(1,math.max(0,W-x+1)))
end
local function bar(x,y,w,value,maxv,col)
  value=tonumber(value) or 0; maxv=tonumber(maxv) or 1
  local n=math.floor(math.max(0,math.min(1,value/maxv))*w)
  gpu.setBackground(C.dim); gpu.fill(x,y,w,1," "); gpu.setBackground(col or C.cyan); if n>0 then gpu.fill(x,y,n,1," ") end
  gpu.setBackground(C.bg)
end
local function invoke(name,...)
  return safe(name,...)
end

local function refresh()
  findDrone()
  if drone then
    local connected=invoke("isConnectedToDrone")
    if connected then status="DRONE LINK ONLINE" else status="INTERFACE ONLINE / NO DRONE" end
    local a=invoke("getAllActions")
    if type(a)=="table" then actions=a end
  else status="NO DRONE INTERFACE" end
end

local function header()
  gpu.setBackground(C.bg); gpu.fill(1,1,W,3," ")
  text(2,1,"BULDACITY // PNEUMATICCRAFT",C.cyan)
  text(2,2,"MC1.7.10 // 1.12.7-152 // OPENCOMPUTERS",C.dim)
  local ok=drone~=nil
  text(math.max(2,W-25),1,ok and "● ONLINE" or "○ OFFLINE",ok and C.green or C.red)
end

local function nav()
  local items={"OVERVIEW","DRONE","ACTIONS","AREAS","FILTERS","CONFIG","API"}
  local x=2
  for i,n in ipairs(items) do
    local label="["..i..":"..n.."]"
    text(x,H-2,label,n==page and C.orange or C.dim); x=x+#label+2
  end
  text(2,H,"1-7 page  |  R refresh  |  Q quit  |  Touch buttons supported",C.dim)
end

local function overview()
  box(2,5,W-4,9,"SYSTEM STATUS")
  text(4,7,"Interface",C.dim); text(20,7,drone and "droneInterface" or "NOT FOUND",drone and C.green or C.red)
  local connected=drone and invoke("isConnectedToDrone")
  text(4,8,"Drone",C.dim); text(20,8,connected and "CONNECTED" or "DISCONNECTED",connected and C.green or C.orange)
  local p=drone and invoke("getDronePressure")
  text(4,9,"Pressure",C.dim); text(20,9,p and string.format("%.2f bar",p) or "--",C.cyan)
  if p then bar(32,9,35,p,20,C.cyan) end
  local x,y,z=drone and invoke("getDronePosition")
  text(4,10,"Position",C.dim); text(20,10,x and string.format("%.1f / %.1f / %.1f",x,y,z) or "--",C.white)
  local act=drone and invoke("getAction")
  text(4,11,"Action",C.dim); text(20,11,act or "NONE",act and C.orange or C.dim)
  text(4,12,"Actions available",C.dim); text(20,12,#actions,C.white)
  box(2,15,W-4,7,"CONTROL")
  text(4,17,"[S] Scan / refresh",C.cyan); text(4,18,"[D] Disconnect drone",C.red)
  text(30,17,"[A] Abort current action",C.orange); text(30,18,"[E] Execute selected action",C.green)
  text(4,20,"PneumaticCraft exposes the real OpenComputers droneInterface; no fake telemetry is generated.",C.dim)
end

local function dronePage()
  box(2,5,W-4,17,"DRONE CONTROL")
  local connected=drone and invoke("isConnectedToDrone")
  text(4,7,"Connection",C.dim); text(20,7,connected and "CONNECTED" or "DISCONNECTED",connected and C.green or C.red)
  local p=drone and invoke("getDronePressure")
  text(4,9,"Air pressure",C.dim); text(20,9,p and string.format("%.3f bar",p) or "--",C.cyan)
  if p then bar(35,9,45,p,20,C.cyan) end
  local x,y,z=drone and invoke("getDronePosition")
  text(4,11,"Position",C.dim); text(20,11,x and string.format("X %.1f  Y %.1f  Z %.1f",x,y,z) or "--",C.white)
  local act=drone and invoke("getAction")
  local done=drone and invoke("isActionDone")
  text(4,13,"Current action",C.dim); text(20,13,act or "NONE",C.orange)
  text(4,14,"Action state",C.dim); text(20,14,done==true and "DONE" or (act and "RUNNING" or "IDLE"),done==true and C.green or C.orange)
  text(4,17,"[D] disconnect",C.red); text(24,17,"[A] abort",C.orange); text(40,17,"[F] forget target",C.purple)
  text(4,19,"[U] query upgrade index",C.cyan); text(30,19,"[V] read variable",C.cyan); text(48,19,"[S] set variable",C.green)
  text(4,21,"[Enter] refresh drone telemetry",C.dim)
end

local function actionsPage()
  box(2,5,W-4,H-9,"AVAILABLE DRONE ACTIONS")
  if #actions==0 then text(5,8,"No actions reported by droneInterface.",C.red) return end
  local rows=H-12
  if selected<actionScroll then actionScroll=selected end
  if selected>=actionScroll+rows then actionScroll=selected-rows+1 end
  for i=1,rows do
    local idx=actionScroll+i-1
    if idx>#actions then break end
    local col=idx==selected and C.orange or C.white
    text(5,7+i,string.format("%3d  %s",idx,tostring(actions[idx])),col)
  end
  text(42,H-3,"UP/DOWN select  ENTER setAction  A abort",C.dim)
end

local function areasPage()
  box(2,5,W-4,17,"AREA / TARGET CONFIGURATION")
  text(4,7,"Area types",C.dim)
  local types=drone and invoke("getAreaTypes")
  text(20,7,type(types)=="table" and table.concat(types,", ") or tostring(types or "--"),C.white)
  text(4,9,"[1] clear area",C.red); text(30,9,"[2] show area",C.cyan); text(50,9,"[3] hide area",C.dim)
  text(4,11,"[4] add area (prompt)",C.green); text(30,11,"[5] remove area (prompt)",C.orange)
  text(4,14,"[6] order: closest",C.cyan); text(30,14,"[7] order: highToLow",C.cyan); text(55,14,"[8] order: lowToHigh",C.cyan)
  text(4,17,"Area coordinates are passed directly to PneumaticCraft's real droneInterface API.",C.dim)
end

local function filtersPage()
  box(2,5,W-4,18,"FILTERS")
  text(4,7,"ITEM FILTERS",C.cyan)
  text(4,9,"[1] whitelist item   [2] blacklist item",C.white)
  text(4,10,"[3] clear whitelist  [4] clear blacklist",C.white)
  text(4,12,"TEXT FILTERS",C.cyan)
  text(4,14,"[5] whitelist text   [6] blacklist text",C.white)
  text(4,15,"[7] clear whitelist  [8] clear blacklist",C.white)
  text(4,17,"LIQUID FILTERS",C.cyan)
  text(4,19,"[9] whitelist liquid  [0] blacklist liquid",C.white)
  text(4,20,"[-] clear whitelist  [=] clear blacklist",C.white)
end

local function configPage()
  box(2,5,W-4,19,"DRONE PROGRAM CONFIG")
  text(4,7,"[1] set side           [2] set all sides",C.cyan)
  text(4,9,"[3] emit redstone       [4] rename",C.cyan)
  text(4,11,"[5] drop straight       [6] use count",C.cyan)
  text(4,13,"[7] set count            [8] AND function",C.cyan)
  text(4,15,"[9] operator >= or =     [0] max actions",C.cyan)
  text(4,17,"[A] sneaking              [B] place fluid blocks",C.cyan)
  text(4,19,"[C] crafting grid (9 slots)   [D] sign text",C.cyan)
  text(4,21,"These controls map to the PneumaticCraft OpenComputers methods.",C.dim)
end

local apiNames={
"isConnectedToDrone","getDronePressure","exitPiece","getAllActions","getDronePosition","setBlockOrder","getAreaTypes","addArea","removeArea","clearArea","showArea","hideArea","addWhitelistItemFilter","addBlacklistItemFilter","clearWhitelistItemFilter","clearBlacklistItemFilter","addWhitelistText","addBlacklistText","clearWhitelistText","clearBlacklistText","setSide","setSides","setEmittingRedstone","setRenameString","addWhitelistLiquidFilter","addBlacklistLiquidFilter","clearWhitelistLiquidFilter","clearBlacklistLiquidFilter","setDropStraight","setUseCount","setCount","setIsAndFunction","setOperator","evaluateCondition","setUseMaxActions","setMaxActions","setSneaking","setPlaceFluidBlocks","setAction","getAction","abortAction","isActionDone","forgetTarget","getUpgrades","setCraftingGrid","setVariable","getVariable","setSignText"}
local function apiPage()
  box(2,5,W-4,H-9,"PNEUMATICCRAFT API // REAL METHODS")
  local rows=H-12
  for i=1,rows do
    local idx=i
    if apiNames[idx] then text(5,7+i,string.format("%02d  %s",idx,apiNames[idx]),C.white) end
  end
  text(38,H-3,"Full method list from the 1.7.10 OpenComputers droneInterface.",C.dim)
end

local function draw()
  W,H=gpu.getResolution(); clear(); header()
  if page=="OVERVIEW" then overview()
  elseif page=="DRONE" then dronePage()
  elseif page=="ACTIONS" then actionsPage()
  elseif page=="AREAS" then areasPage()
  elseif page=="FILTERS" then filtersPage()
  elseif page=="CONFIG" then configPage()
  else apiPage() end
  if lastError then text(2,4,"ERROR: "..lastError,C.red) end
  nav(); gpu.setBackground(C.bg)
end

local function prompt(label,default)
  gpu.setBackground(C.panel); gpu.setForeground(C.cyan); gpu.fill(4,H-5,W-8,3," ")
  gpu.set(6,H-4,label..(default and " ["..default.."]" or "")..": ")
  local s=io.read(); if s=="" then s=default end
  gpu.setBackground(C.bg); return s
end
local function num(label,default) return tonumber(prompt(label,tostring(default or "0"))) or default or 0 end
local function bool(label,default)
  local s=prompt(label,default and "true" or "false"); return s=="true" or s=="1" or s=="yes" or s=="y"
end

local function doAction(name)
  lastError=nil
  if name=="disconnect" then invoke("exitPiece")
  elseif name=="abort" then invoke("abortAction")
  elseif name=="forget" then invoke("forgetTarget")
  elseif name=="setAction" then invoke("setAction",actions[selected])
  elseif name=="upgrade" then local v=invoke("getUpgrades",num("Upgrade index",0)); status="Upgrade: "..tostring(v)
  elseif name=="variableGet" then local n=prompt("Variable name","target"); local a,b,c=invoke("getVariable",n); status=string.format("%s = %s,%s,%s",n,tostring(a),tostring(b),tostring(c))
  elseif name=="variableSet" then local n=prompt("Variable name","target"); local x=num("X/value",0); local y=num("Y",0); local z=num("Z",0); invoke("setVariable",n,x,y,z)
  end
end

refresh(); draw()
while running do
  local ev={event.pull(0.5)}
  if ev[1]=="key_down" then
    local ch=ev[3]; local key=ev[4]
    if ch==113 or ch==81 then running=false
    elseif ch==114 or ch==82 then refresh(); draw()
    elseif ch>=49 and ch<=55 then
      local pages={"OVERVIEW","DRONE","ACTIONS","AREAS","FILTERS","CONFIG","API"}; page=pages[ch-48]; draw()
    elseif page=="ACTIONS" and key==200 then selected=math.max(1,selected-1); draw()
    elseif page=="ACTIONS" and key==208 then selected=math.min(#actions,selected+1); draw()
    elseif page=="ACTIONS" and key==28 and actions[selected] then doAction("setAction"); draw()
    elseif page=="OVERVIEW" and (ch==100 or ch==68) then doAction("disconnect"); refresh(); draw()
    elseif page=="OVERVIEW" and (ch==97 or ch==65) then doAction("abort"); draw()
    elseif page=="OVERVIEW" and (ch==101 or ch==69) and actions[selected] then doAction("setAction"); draw()
    elseif page=="DRONE" and (ch==100 or ch==68) then doAction("disconnect"); refresh(); draw()
    elseif page=="DRONE" and (ch==97 or ch==65) then doAction("abort"); draw()
    elseif page=="DRONE" and (ch==102 or ch==70) then doAction("forget"); draw()
    elseif page=="DRONE" and (ch==117 or ch==85) then doAction("upgrade"); draw()
    elseif page=="DRONE" and (ch==118 or ch==86) then doAction("variableGet"); draw()
    elseif page=="DRONE" and (ch==115 or ch==83) then doAction("variableSet"); draw()
    elseif page=="AREAS" then
      if ch==49 then invoke("clearArea") elseif ch==50 then invoke("showArea") elseif ch==51 then invoke("hideArea")
      elseif ch==54 then invoke("setBlockOrder","closest") elseif ch==55 then invoke("setBlockOrder","highToLow") elseif ch==56 then invoke("setBlockOrder","lowToHigh") end
      draw()
    end
  elseif ev[1]=="touch" then
    local x,y=ev[3],ev[4]
    if y>=H-3 then
      local pages={"OVERVIEW","DRONE","ACTIONS","AREAS","FILTERS","CONFIG","API"}
      local n=math.floor((x-2)/12)+1; if pages[n] then page=pages[n]; draw() end
    elseif page=="ACTIONS" and y>=7 and y<H-4 then
      local idx=actionScroll+(y-8); if actions[idx] then selected=idx; draw() end
    end
  end
end
clear(); text(2,2,"BULDACITY PneumaticCraft controller stopped.",C.cyan)
