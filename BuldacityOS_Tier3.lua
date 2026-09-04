-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers Desktop
-- Minecraft 1.7.10 / OpenComputers / BULDACITY/2 / modem port 4242
-- Central operator desktop for the complete Buldacity controller network.

local component = require("component")
local event = require("event")
local computer = require("computer")
local filesystem = require("filesystem")
local shell = require("shell")
local gpu = component.gpu
local wireless = require("BuldacityWireless")

local PORT = 4242
local PROTOCOL = "BULDACITY/2"
local ok, mode = wireless.init(PORT)
if not ok then error("BuldacityOS: Network/Wireless Network Card required") end

local W,H = gpu.maxResolution()
local running = true
local app = "HOME"
local selected = 1
local lastDraw = 0
local devices = {}
local log = {}
local C={bg=0x060912,bar=0x0D1424,panel=0x111B2F,panel2=0x1A2943,cyan=0x00E5FF,blue=0x4B8DFF,purple=0xB060FF,pink=0xFF3CCB,green=0x36FF91,yellow=0xFFD84D,red=0xFF4D6D,white=0xEDF7FF,dim=0x71839B}

local apps={
 {id="HOME",name="Buldacity Home",icon="OS"},
 {id="NETWORK",name="Network Center",icon="NET"},
 {id="DEVICES",name="Device Manager",icon="DEV"},
 {id="CONTROLLERS",name="Controller Apps",icon="APP"},
 {id="REMOTE",name="Remote Control",icon="REM"},
 {id="TERMINAL",name="Terminal",icon=">_"},
 {id="FILES",name="File Manager",icon="FS"},
 {id="SYSTEM",name="System Monitor",icon="SYS"}
}
local controllers={
 {"AE2","AE2Network_Modern.lua"},{"Diesel","DieselGenerator_Modern.lua"},{"Mekanism","Mekanism_Modern.lua"},{"Thermal","Thermal_Modern.lua"},{"ProjectE","ProjectE_Modern.lua"},{"RFTools","RFTools_Modern.lua"},{"SGCraft","SGCraft_Modern.lua"},{"Reactor","ReactorBigReactors043A_Touch_Responsive.lua"},{"RotaryCraft","RotaryCraftDashboard_Modern.lua"},{"Thermal Expansion","ThermalExpansion_Modern.lua"},{"PneumaticCraft","PneumaticCraftNetwork_Modern.lua"},{"LogisticsPipes","LogisticsPipesNetwork_Modern.lua"},{"Immersive Engineering","ImmersiveEngineering_Network_Modern.lua"},{"Immersive Integration","ImmersiveIntegration_Network_Modern.lua"},{"Immersive Railroading","ImmersiveRailroading_Network_Modern.lua"},{"IndustrialCraft 2","IndustrialCraft2_Network_Modern.lua"},{"Galacticraft","Galacticraft_Modern.lua"},{"Galacticraft Network","GalacticraftNetwork_Modern.lua"},{"ExtraPlanets","ExtraPlanets_Modern.lua"},{"ExtraPlanets Network","ExtraPlanetsNetwork_Modern.lua"},{"Forestry","Forestry_Modern.lua"},{"Forestry Network","ForestryNetwork_Modern.lua"},{"Gendustry","Gendustry_Modern.lua"},{"Gendustry Network","GendustryNetwork_Modern.lua"}
}

local function text(x,y,s,c) gpu.setForeground(c or C.white); gpu.set(x,y,tostring(s or "")) end
local function fill(x,y,w,h,c) gpu.setBackground(c); gpu.fill(x,y,w,h," ") end
local function line(x,y,w,c) gpu.setForeground(c or C.dim); gpu.set(x,y,string.rep("-",math.max(0,w))) end
local function card(x,y,w,h,title,accent) fill(x,y,w,h,C.panel); text(x+2,y,title,accent or C.cyan); line(x,y+1,w,C.dim) end
local function addLog(s) table.insert(log,1,os.date("%H:%M:%S").." "..s); if #log>8 then table.remove(log) end end
local function online(d) return computer.uptime()-(d.last or 0)<=12 end
local function listDevices() local r={}; for _,d in pairs(devices) do r[#r+1]=d end; table.sort(r,function(a,b)return tostring(a.name or "")<tostring(b.name or "") end); return r end
local function selectedDevice() local l=listDevices(); if #l==0 then return nil end; selected=math.max(1,math.min(selected,#l)); return l[selected] end
local function send(d,kind,data) if not d or not online(d) then return false end; return wireless.send(d.address,kind,data) end
local function announce() wireless.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="Buldacity OS",version="2.0",mode=mode}) end
local function drawHeader(title) fill(1,1,W,4,C.bar); text(3,2,"BULDACITY OS",C.cyan); text(17,2,title,C.purple); text(math.max(1,W-18),2,os.date("%H:%M:%S"),C.white); text(3,3,"TIER-3 CENTRAL DESKTOP",C.dim); text(math.max(1,W-18),3,wireless.isWireless() and "WIRELESS" or "WIRED",C.green) end
local function drawTaskbar() fill(1,H-3,W,4,C.bar); text(3,H-1,"[H] HOME",app=="HOME" and C.white or C.dim); text(16,H-1,"[N] NETWORK",app=="NETWORK" and C.white or C.dim); text(32,H-1,"[D] DEVICES",app=="DEVICES" and C.white or C.dim); text(48,H-1,"[A] APPS",app=="CONTROLLERS" and C.white or C.dim); text(61,H-1,"[Q] EXIT",C.red) end

local function home()
 drawHeader("HOME"); local l=listDevices(); local n=0; for _,d in ipairs(l) do if online(d) then n=n+1 end end
 card(3,6,29,8,"NETWORK",C.cyan); text(6,8,"STATUS",C.dim); text(17,8,"ONLINE",C.green); text(6,10,"CLIENTS",C.dim); text(17,10,#l,C.white); text(6,12,"ONLINE",C.dim); text(17,12,n,C.green)
 card(35,6,43,8,"SERVER",C.purple); text(38,8,"PROTOCOL",C.dim); text(50,8,PROTOCOL,C.cyan); text(38,10,"PORT",C.dim); text(50,10,PORT,C.yellow); text(38,12,"ADDRESS",C.dim); text(50,12,wireless.address(),C.white)
 card(3,16,75,9,"APPLICATIONS",C.pink); for i=1,math.min(6,#apps) do local x=6+((i-1)%3)*24; local y=18+math.floor((i-1)/3)*3; text(x,y,"["..apps[i].icon.."]",C.cyan); text(x+6,y,apps[i].name:sub(1,17),C.white) end
 card(3,27,75,math.max(5,H-31),"SYSTEM LOG",C.yellow); for i=1,math.min(#log,H-34) do text(6,28+i,log[i],C.dim) end; drawTaskbar()
end
local function network()
 drawHeader("NETWORK CENTER"); card(3,6,75,10,"WIRELESS NETWORK",C.cyan); text(6,8,"Protocol",C.dim); text(20,8,PROTOCOL,C.cyan); text(6,10,"Port",C.dim); text(20,10,PORT,C.yellow); text(6,12,"Mode",C.dim); text(20,12,mode,C.green); text(6,14,"Range",C.dim); text(20,14,wireless.strength() or "N/A",C.white); text(40,8,"Address",C.dim); text(53,8,wireless.address(),C.white); text(40,10,"Link",C.dim); text(53,10,"ACTIVE",C.green); card(3,18,75,H-22,"TRAFFIC / STATUS",C.purple); local l=listDevices(); for i,d in ipairs(l) do if i>H-26 then break end; local y=20+i; text(6,y,string.format("%02d",i),C.dim); text(11,y,(d.name or "UNKNOWN"):sub(1,26),C.white); text(40,y,d.role or "CLIENT",C.dim); text(56,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red) end; drawTaskbar()
end
local function deviceManager()
 drawHeader("DEVICE MANAGER"); card(3,6,75,H-10,"CONNECTED CONTROLLERS",C.purple); local l=listDevices(); if #l==0 then text(7,10,"Waiting for Buldacity clients...",C.dim) end; for i,d in ipairs(l) do local y=8+i; if y>H-5 then break end; if i==selected then fill(5,y,70,1,C.panel2) end; text(7,y,string.format("%02d",i),C.dim); text(12,y,(d.name or "UNKNOWN"):sub(1,24),i==selected and C.cyan or C.white); text(39,y,(d.role or "CLIENT"):sub(1,12),C.dim); text(55,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red) end; text(7,H-5,"UP/DOWN select   ENTER remote",C.dim); drawTaskbar()
end
local function controllerApps()
 drawHeader("CONTROLLER APPS"); card(3,6,75,H-10,"INSTALLED CONTROLLERS",C.pink); for i,v in ipairs(controllers) do local y=8+i; if y>H-5 then break end; local exists=filesystem.exists(v[2]); text(7,y,string.format("%02d",i),C.dim); text(12,y,v[1],C.white); text(34,y,v[2]:sub(1,31),C.dim); text(68,y,exists and "READY" or "MISS",exists and C.green or C.red) end; text(7,H-5,"Use BuldacityControllerLauncher.lua for controller startup.",C.dim); drawTaskbar()
end
local function remote()
 drawHeader("REMOTE CONTROL"); card(3,6,75,H-10,"REMOTE DEVICE",C.pink); local d=selectedDevice(); if not d then text(7,10,"No controller selected.",C.dim); drawTaskbar(); return end; text(7,9,"NAME",C.dim); text(20,9,d.name or "UNKNOWN",C.cyan); text(7,11,"ROLE",C.dim); text(20,11,d.role or "CLIENT",C.white); text(7,13,"STATUS",C.dim); text(20,13,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red); text(7,15,"ADDRESS",C.dim); text(20,15,d.address or "-",C.dim); text(7,18,"ENTER",C.yellow); text(20,18,"PING selected controller",C.white); text(7,20,"Keyboard / touch / scroll forwarding is supported.",C.white); drawTaskbar()
end
local function terminal()
 drawHeader("TERMINAL"); card(3,6,75,H-10,"OPENOS TERMINAL",C.green); text(7,9,"Buldacity OS shell access",C.cyan); text(7,11,"Use the physical keyboard. Press Q to return to the desktop.",C.dim); drawTaskbar()
end
local function files()
 drawHeader("FILE MANAGER"); card(3,6,75,H-10,"/",C.blue); local entries={}; for name in filesystem.list("/") do entries[#entries+1]=name end; table.sort(entries); for i=1,math.min(#entries,H-12) do text(7,7+i,entries[i],C.white) end; drawTaskbar()
end
local function system()
 drawHeader("SYSTEM MONITOR"); card(3,6,36,10,"COMPUTER",C.yellow); text(6,8,"Uptime",C.dim); text(18,8,string.format("%.1fs",computer.uptime()),C.white); text(6,10,"Energy",C.dim); text(18,10,computer.energy and math.floor(computer.energy()) or "N/A",C.green); text(6,12,"Max",C.dim); text(18,12,computer.maxEnergy and math.floor(computer.maxEnergy()) or "N/A",C.white); card(41,6,37,10,"NETWORK",C.cyan); text(44,8,"Mode",C.dim); text(56,8,mode,C.green); text(44,10,"Protocol",C.dim); text(56,10,PROTOCOL,C.cyan); text(44,12,"Port",C.dim); text(56,12,PORT,C.yellow); drawTaskbar()
end
local function draw() W,H=gpu.maxResolution(); gpu.setBackground(C.bg); gpu.fill(1,1,W,H," "); if app=="HOME" then home() elseif app=="NETWORK" then network() elseif app=="DEVICES" then deviceManager() elseif app=="CONTROLLERS" then controllerApps() elseif app=="REMOTE" then remote() elseif app=="TERMINAL" then terminal() elseif app=="FILES" then files() elseif app=="SYSTEM" then system() end end

addLog("Buldacity OS started"); addLog("Protocol "..PROTOCOL.." / port "..PORT); announce(); event.timer(3,announce,math.huge); draw()
while running do
 local e,a,b,c,d=event.pull(0.5)
 if e=="key_down" then
  local char=b or 0; local key=c or 0
  if char==113 or char==81 then running=false
  elseif char==104 or char==72 then app="HOME"
  elseif char==110 or char==78 then app="NETWORK"
  elseif char==100 or char==68 then app="DEVICES"
  elseif char==97 or char==65 then app="CONTROLLERS"
  elseif char==49 then app="HOME" elseif char==50 then app="NETWORK" elseif char==51 then app="DEVICES" elseif char==52 then app="CONTROLLERS" elseif char==53 then app="REMOTE" elseif char==54 then app="TERMINAL" elseif char==55 then app="FILES" elseif char==56 then app="SYSTEM"
  elseif key==200 then selected=math.max(1,selected-1)
  elseif key==208 then selected=selected+1
  elseif key==28 and app=="DEVICES" then app="REMOTE"; addLog("Remote device selected")
  elseif char==114 or char==82 then announce(); addLog("Server announcement sent") end
 elseif e=="key_up" and app=="REMOTE" then local t=selectedDevice(); if t then send(t,"INPUT",{event="key_up",char=b or 0,code=c or 0}) end
 elseif e=="touch" and app=="DEVICES" then local l=listDevices(); selected=math.max(1,math.min(#l,(b or 8)-7)); app="REMOTE"
 elseif e=="modem_message" and c==PORT then
  local p=d
  if wireless.valid(p) and p.kind~="SERVER_HELLO" then
   if p.kind=="HELLO" or p.kind=="HEARTBEAT" or p.kind=="PONG" then local dev=devices[b] or {address=b}; devices[b]=dev; for k,v in pairs(p.data or {}) do dev[k]=v end; dev.last=computer.uptime() end
  end
 end
 if computer.uptime()-lastDraw>=1 then lastDraw=computer.uptime(); draw() end
end
gpu.setBackground(0x000000); gpu.setForeground(C.white); gpu.fill(1,1,W,H," ")
