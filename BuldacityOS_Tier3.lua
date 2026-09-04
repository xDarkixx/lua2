-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers Desktop
-- Minecraft 1.7.10 / OpenComputers / BULDACITY/2 / modem port 4242
-- Central desktop with live remote controller screen mirroring.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")
local shell=require("shell")
local gpu=component.gpu
local wireless=require("BuldacityWireless")

local PORT=4242
local PROTOCOL="BULDACITY/2"
local ok,mode=wireless.init(PORT)
if not ok then error("BuldacityOS: Network/Wireless Network Card required") end

local W,H=gpu.maxResolution()
local running=true
local app="HOME"
local selected=1
local devices={}
local log={}
local lastDraw=0
local remoteFrame=nil
local remoteFrames={}
local remoteSize={w=0,h=0}
local C={bg=0x060912,bar=0x0D1424,panel=0x111B2F,panel2=0x1A2943,cyan=0x00E5FF,purple=0xB060FF,pink=0xFF3CCB,green=0x36FF91,yellow=0xFFD84D,red=0xFF4D6D,white=0xEDF7FF,dim=0x71839B}

local controllers={
 {"AE2","AE2Network_Modern.lua"},{"Diesel","DieselGenerator_Modern.lua"},{"Mekanism","Mekanism_Modern.lua"},{"Thermal","Thermal_Modern.lua"},{"ProjectE","ProjectE_Modern.lua"},{"RFTools","RFTools_Modern.lua"},{"SGCraft","SGCraft_Modern.lua"},{"Reactor","ReactorBigReactors043A_Touch_Responsive.lua"},{"RotaryCraft","RotaryCraftDashboard_Modern.lua"},{"Thermal Expansion","ThermalExpansion_Modern.lua"},{"PneumaticCraft","PneumaticCraftNetwork_Modern.lua"},{"LogisticsPipes","LogisticsPipesNetwork_Modern.lua"},{"Immersive Engineering","ImmersiveEngineering_Network_Modern.lua"},{"Immersive Integration","ImmersiveIntegration_Network_Modern.lua"},{"Immersive Railroading","ImmersiveRailroading_Network_Modern.lua"},{"IndustrialCraft 2","IndustrialCraft2_Network_Modern.lua"},{"Galacticraft","Galacticraft_Modern.lua"},{"ExtraPlanets","ExtraPlanets_Modern.lua"},{"Forestry","Forestry_Modern.lua"},{"Gendustry","Gendustry_Modern.lua"}
}

local function text(x,y,s,c) gpu.setForeground(c or C.white);gpu.set(x,y,tostring(s or "")) end
local function fill(x,y,w,h,c) if w>0 and h>0 then gpu.setBackground(c);gpu.fill(x,y,w,h," ") end end
local function card(x,y,w,h,title,c) fill(x,y,w,h,C.panel);text(x+2,y,title,c or C.cyan);gpu.setForeground(C.dim);gpu.set(x,y+1,string.rep("-",math.max(0,w))) end
local function addLog(s) table.insert(log,1,os.date("%H:%M:%S").." "..s);if #log>8 then table.remove(log) end end
local function online(d) return computer.uptime()-(d.last or 0)<=12 end
local function listDevices() local r={};for _,d in pairs(devices) do r[#r+1]=d end;table.sort(r,function(a,b)return tostring(a.name or "")<tostring(b.name or "") end);return r end
local function selectedDevice() local l=listDevices();if #l==0 then return nil end;selected=math.max(1,math.min(selected,#l));return l[selected] end
local function send(d,k,data) if d and d.address and online(d) then return wireless.send(d.address,k,data) end;return false end
local function announce() wireless.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version="2.1",mode=mode}) end
local function requestScreen(d) if d and online(d) then send(d,"SCREEN_REQUEST",{width=W,height=H}) end end

local function header(title)
 fill(1,1,W,4,C.bar);text(3,2,"BULDACITY OS",C.cyan);text(18,2,title,C.purple);text(math.max(1,W-18),2,os.date("%H:%M:%S"),C.white);text(3,3,"TIER-3 CENTRAL DESKTOP",C.dim);text(math.max(1,W-18),3,wireless.isWireless() and "WIRELESS" or "WIRED",C.green)
end
local function taskbar()
 fill(1,H-3,W,4,C.bar);text(3,H-1,"[1] HOME",app=="HOME" and C.white or C.dim);text(16,H-1,"[2] NETWORK",app=="NETWORK" and C.white or C.dim);text(31,H-1,"[3] DEVICES",app=="DEVICES" and C.white or C.dim);text(46,H-1,"[4] APPS",app=="CONTROLLERS" and C.white or C.dim);text(59,H-1,"[5] REMOTE",app=="REMOTE" and C.white or C.dim);text(math.max(1,W-10),H-1,"[Q] EXIT",C.red)
end

local function home()
 header("HOME");local l=listDevices();local n=0;for _,d in ipairs(l) do if online(d) then n=n+1 end end
 card(3,6,31,8,"NETWORK",C.cyan);text(6,8,"PROTOCOL",C.dim);text(18,8,PROTOCOL,C.cyan);text(6,10,"PORT",C.dim);text(18,10,PORT,C.yellow);text(6,12,"CLIENTS",C.dim);text(18,12,#l.." / "..n.." online",C.green)
 card(37,6,41,8,"SERVER",C.purple);text(40,8,"ADDRESS",C.dim);text(51,8,wireless.address(),C.white);text(40,10,"MODE",C.dim);text(51,10,mode,C.green);text(40,12,"REMOTE UI",C.dim);text(51,12,"LIVE",C.cyan)
 card(3,16,75,9,"CONTROLLERS",C.pink);for i,d in ipairs(l) do if i>5 then break end;local y=17+i;text(7,y,string.format("%02d",i),C.dim);text(12,y,(d.name or "UNKNOWN"):sub(1,26),C.white);text(42,y,d.role or "CLIENT",C.dim);text(58,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red) end
 card(3,27,75,math.max(5,H-31),"SYSTEM LOG",C.yellow);for i=1,math.min(#log,H-34) do text(6,28+i,log[i],C.dim) end;taskbar()
end

local function network()
 header("NETWORK CENTER");card(3,6,75,9,"BULDACITY NETWORK",C.cyan);text(6,8,"Protocol",C.dim);text(20,8,PROTOCOL,C.cyan);text(6,10,"Port",C.dim);text(20,10,PORT,C.yellow);text(6,12,"Mode",C.dim);text(20,12,mode,C.green);text(40,8,"Address",C.dim);text(53,8,wireless.address(),C.white);text(40,10,"Range",C.dim);text(53,10,wireless.strength() or "N/A",C.white);text(40,12,"Screen stream",C.dim);text(53,12,"ENABLED",C.green)
 card(3,17,75,H-21,"CLIENT TRAFFIC",C.purple);local l=listDevices();for i,d in ipairs(l) do local y=18+i;if y>H-5 then break end;text(7,y,string.format("%02d",i),C.dim);text(12,y,(d.name or "UNKNOWN"):sub(1,27),C.white);text(42,y,d.address or "-",C.dim);text(65,y,online(d) and "UP" or "DOWN",online(d) and C.green or C.red) end;taskbar()
end

local function devicesPage()
 header("DEVICE MANAGER");card(3,6,75,H-10,"CONNECTED CONTROLLERS",C.purple);local l=listDevices();if #l==0 then text(7,10,"Waiting for Buldacity clients...",C.dim) end;for i,d in ipairs(l) do local y=8+i;if y>H-5 then break end;if i==selected then fill(5,y,70,1,C.panel2) end;text(7,y,string.format("%02d",i),C.dim);text(12,y,(d.name or "UNKNOWN"):sub(1,25),i==selected and C.cyan or C.white);text(40,y,d.role or "CLIENT",C.dim);text(56,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red) end;text(7,H-5,"UP/DOWN select   ENTER = live interface",C.dim);taskbar()
end

local function controllerApps()
 header("CONTROLLER APPS");card(3,6,75,H-10,"AVAILABLE CONTROLLERS",C.pink);for i,v in ipairs(controllers) do local y=7+i;if y>H-5 then break end;local exists=filesystem.exists(v[2]);text(7,y,string.format("%02d",i),C.dim);text(12,y,v[1],C.white);text(32,y,v[2]:sub(1,33),C.dim);text(68,y,exists and "READY" or "MISS",exists and C.green or C.red) end;text(7,H-5,"Controller surfaces are shown remotely when their client is running.",C.dim);taskbar()
end

-- Draw the streamed GPU surface inside a bordered viewport. Each controller
-- sends its current OpenComputers GPU cells to this desktop over BULDACITY/2.
local function remote()
 header("REMOTE INTERFACE");local d=selectedDevice();if not d then card(3,6,75,H-10,"LIVE CONTROLLER SCREEN",C.pink);text(7,10,"No controller selected.",C.dim);taskbar();return end
 local vw=math.min(W-6,remoteSize.w>0 and remoteSize.w or W-6);local vh=math.min(H-10,remoteSize.h>0 and remoteSize.h or H-10);local ox=3;local oy=6
 card(ox,oy,vw+2,vh+2,(d.name or "CONTROLLER").."  "..(online(d) and "ONLINE" or "OFFLINE"),C.pink)
 if remoteFrame then
  for y=1,math.min(vh,remoteSize.h) do
   local row=remoteFrame[y]
   if row then
    for x=1,math.min(vw,remoteSize.w) do local cell=row[x];if cell then gpu.setBackground(cell[3] or 0);gpu.setForeground(cell[2] or 0xFFFFFF);gpu.set(ox+x,oy+1+y,tostring(cell[1] or " ")) end end
   end
  end
 else
  text(ox+3,oy+4,"Warte auf Live-Oberfläche...",C.dim);requestScreen(d)
 end
 text(ox+2,oy+vh+3,"[ENTER] Ping   [R] Refresh   Keyboard/Touch/Scroll -> Controller",C.dim);taskbar()
end

local function terminal()
 header("TERMINAL");card(3,6,75,H-10,"OPENOS TERMINAL",C.green);text(7,9,"Desktop terminal",C.cyan);text(7,11,"Q returns to Buldacity OS. The controller desktop remains network active.",C.dim);taskbar()
end
local function system()
 header("SYSTEM MONITOR");card(3,6,36,10,"COMPUTER",C.yellow);text(6,8,"Uptime",C.dim);text(18,8,string.format("%.1fs",computer.uptime()),C.white);text(6,10,"Energy",C.dim);text(18,10,computer.energy and math.floor(computer.energy()) or "N/A",C.green);text(6,12,"Max",C.dim);text(18,12,computer.maxEnergy and math.floor(computer.maxEnergy()) or "N/A",C.white);card(41,6,37,10,"NETWORK",C.cyan);text(44,8,"Mode",C.dim);text(56,8,mode,C.green);text(44,10,"Protocol",C.dim);text(56,10,PROTOCOL,C.cyan);text(44,12,"Port",C.dim);text(56,12,PORT,C.yellow);taskbar()
end
local function draw()
 W,H=gpu.maxResolution();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");if app=="HOME" then home() elseif app=="NETWORK" then network() elseif app=="DEVICES" then devicesPage() elseif app=="CONTROLLERS" then controllerApps() elseif app=="REMOTE" then remote() elseif app=="TERMINAL" then terminal() else system() end
end

addLog("Buldacity OS 2.1 started");addLog("Live remote interfaces enabled");announce();event.timer(3,announce,math.huge);event.timer(1,function() if app=="REMOTE" then requestScreen(selectedDevice()) end end,math.huge);draw()

while running do
 local e,a,b,c,d=event.pull(0.25)
 if e=="key_down" then
  local char=b or 0;local key=c or 0;local target=selectedDevice()
  if char==113 or char==81 then running=false
  elseif char==49 then app="HOME" elseif char==50 then app="NETWORK" elseif char==51 then app="DEVICES" elseif char==52 then app="CONTROLLERS" elseif char==53 then app="REMOTE"
  elseif char==54 then app="TERMINAL" elseif char==55 then app="SYSTEM"
  elseif char==114 or char==82 then announce();requestScreen(target);addLog("Remote interface refresh")
  elseif key==200 then selected=math.max(1,selected-1);app="DEVICES"
  elseif key==208 then selected=selected+1;app="DEVICES"
  elseif key==28 and target then app="REMOTE";send(target,"PING",{from="TIER3"})
  elseif app=="REMOTE" and target then send(target,"INPUT",{event="key_down",char=char,code=key}) end
 elseif e=="key_up" and app=="REMOTE" then local t=selectedDevice();if t then send(t,"INPUT",{event="key_up",char=b or 0,code=c or 0}) end
 elseif e=="touch" then
  local x,y=a,b;local l=listDevices()
  if y>=H-3 and x<14 then app="HOME" elseif y>=H-3 and x<30 then app="NETWORK" elseif y>=H-3 and x<45 then app="DEVICES" elseif y>=H-3 and x<58 then app="CONTROLLERS" elseif y>=H-3 and x<72 then app="REMOTE"
  elseif app=="DEVICES" and y>=8 and y<=H-5 and #l>0 then selected=math.max(1,math.min(#l,y-7));app="REMOTE"
  elseif app=="REMOTE" then local t=selectedDevice();if t then send(t,"INPUT",{event="touch",x=x,y=y,button=1}) end end
 elseif e=="scroll" and app=="REMOTE" then local t=selectedDevice();if t then send(t,"INPUT",{event="scroll",x=a or 0,y=b or 0,button=c or 0}) end
 elseif e=="modem_message" and c==PORT then
  local p=d
  if wireless.valid(p) then
   if p.kind=="HELLO" or p.kind=="HEARTBEAT" or p.kind=="PONG" then local dev=devices[b] or {address=b};devices[b]=dev;for k,v in pairs(p.data or {}) do dev[k]=v end;dev.last=computer.uptime()
   elseif p.kind=="SCREEN_BEGIN" then remoteSize.w=(p.data and p.data.width) or 0;remoteSize.h=(p.data and p.data.height) or 0;remoteFrames={}
   elseif p.kind=="SCREEN_ROW" then if p.data and p.data.y then remoteFrames[p.data.y]=p.data.cells end
   elseif p.kind=="SCREEN_END" then if b==(selectedDevice() and selectedDevice().address) then remoteFrame=remoteFrames end
   end
  end
 end
 if computer.uptime()-lastDraw>=0.5 then lastDraw=computer.uptime();draw() end
end

gpu.setBackground(0x000000);gpu.setForeground(C.white);gpu.fill(1,1,W,H," ")
