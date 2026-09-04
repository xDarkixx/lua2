-- BuldacityOS_Tier3.lua
-- BULDACITY OS // Tier-3 OpenComputers Desktop
-- Minecraft 1.7.10 / OpenComputers / BULDACITY/2
-- Automatic modem + port setup, client discovery, remote controller UI.

local component=require("component")
local event=require("event")
local computer=require("computer")
local filesystem=require("filesystem")
local shell=require("shell")
local gpu=component.gpu
local wireless=require("BuldacityWireless")

local PROTOCOL="BULDACITY/2"
local PORT=4242
local VERSION="3.0"
local ok,mode=wireless.init(PORT)
if not ok then error("BULDACITY OS: modem/network card required") end

local W,H=gpu.maxResolution()
local running=true
local page="HOME"
local selected=1
local devices={}
local logs={}
local remoteFrame=nil
local remoteFrames={}
local remoteSize={w=0,h=0}
local lastDraw=0
local dirty=true
local status="READY"

local C={bg=0x050811,bar=0x0B1220,panel=0x101A2C,panel2=0x172640,line=0x263B59,cyan=0x00E5FF,purple=0xA66CFF,pink=0xFF3EBB,green=0x35F59A,yellow=0xFFD34E,red=0xFF5572,white=0xEAF6FF,dim=0x71859E,black=0x000000}

local controllers={
 {"AE2","AE2Network_Modern.lua"},{"Diesel","DieselGenerator_Modern.lua"},{"Mekanism","Mekanism_Modern.lua"},{"Thermal","Thermal_Modern.lua"},{"ProjectE","ProjectE_Modern.lua"},{"RFTools","RFTools_Modern.lua"},{"SGCraft","SGCraft_Modern.lua"},{"Big Reactors","ReactorBigReactors043A_Touch_Responsive.lua"},{"RotaryCraft","RotaryCraftDashboard_Modern.lua"},{"Thermal Expansion","ThermalExpansion_Modern.lua"},{"PneumaticCraft","PneumaticCraftNetwork_Modern.lua"},{"LogisticsPipes","LogisticsPipesNetwork_Modern.lua"},{"Immersive Engineering","ImmersiveEngineering_Network_Modern.lua"},{"Immersive Integration","ImmersiveIntegration_Network_Modern.lua"},{"Immersive Railroading","ImmersiveRailroading_Network_Modern.lua"},{"IndustrialCraft 2","IndustrialCraft2_Network_Modern.lua"},{"Galacticraft","Galacticraft_Modern.lua"},{"ExtraPlanets","ExtraPlanets_Modern.lua"},{"Forestry","Forestry_Modern.lua"},{"Gendustry","Gendustry_Modern.lua"}}

local function now() return computer.uptime() end
local function addLog(s) table.insert(logs,1,os.date("%H:%M:%S").."  "..s);if #logs>7 then table.remove(logs) end end
local function setStatus(s) status=s;dirty=true end
local function text(x,y,s,c) gpu.setForeground(c or C.white);gpu.set(x,y,tostring(s or "")) end
local function fill(x,y,w,h,c) if w>0 and h>0 then gpu.setBackground(c);gpu.fill(x,y,w,h," ") end end
local function line(x,y,w,c) gpu.setForeground(c or C.line);gpu.set(x,y,string.rep("-",math.max(0,w))) end
local function card(x,y,w,h,title,c)
 fill(x,y,w,h,C.panel);fill(x,y,w,1,c or C.cyan);text(x+2,y+2,title,c or C.cyan);line(x+2,y+3,w-4,C.line)
end
local function online(d) return d and now()-(d.last or 0)<=12 end
local function listDevices()
 local r={};for _,d in pairs(devices) do r[#r+1]=d end
 table.sort(r,function(a,b)return tostring(a.name or a.address or "")<tostring(b.name or b.address or "") end);return r
end
local function selectedDevice()
 local l=listDevices();if #l==0 then return nil end;selected=math.max(1,math.min(selected,#l));return l[selected]
end
local function send(d,k,data) if d and d.address and online(d) then return wireless.send(d.address,k,data) end;return false end
local function announce() wireless.broadcast("SERVER_HELLO",{name="BULDACITY TIER-3",role="SERVER",app="BULDACITY OS",version=VERSION,mode=mode,protocol=PROTOCOL,port=PORT}) end
local function requestScreen(d) if d and online(d) then send(d,"SCREEN_REQUEST",{width=W,height=H}) end end
local function pingAll() for _,d in ipairs(listDevices()) do if online(d) then send(d,"PING",{from="TIER3"}) end end;announce();setStatus("NETWORK SCAN SENT");addLog("Network discovery broadcast") end

local function header(title,subtitle)
 fill(1,1,W,5,C.bar);fill(1,5,W,1,C.cyan);text(3,2,"BULDACITY",C.cyan);text(14,2,"OS",C.white);text(18,2,title,C.purple)
 text(3,3,subtitle or "TIER-3 CENTRAL CONTROL",C.dim);text(math.max(1,W-22),2,"AUTO NETWORK",C.green);text(math.max(1,W-22),3,PROTOCOL,C.cyan);text(math.max(1,W-8),4,string.format("%02d:%02d",tonumber(os.date("%H")),tonumber(os.date("%M"))),C.white)
end
local function nav()
 local labels={{"1","HOME"},{"2","NETWORK"},{"3","DEVICES"},{"4","APPS"},{"5","REMOTE"},{"6","SYSTEM"}}
 fill(1,H-3,W,4,C.bar);local x=3
 for _,v in ipairs(labels) do local active=(page==v[2] or (v[2]=="APPS" and page=="APPS"));text(x,H-1,"["..v[1].."] "..v[2],active and C.white or C.dim);x=x+13 end
 text(math.max(1,W-19),H-1,status:sub(1,15),C.green);text(math.max(1,W-7),H-1,"[Q]",C.red)
end

local function home()
 header("HOME","TIER-3 CENTRAL CONTROL")
 local l=listDevices();local up=0;for _,d in ipairs(l) do if online(d) then up=up+1 end end
 card(3,7,30,8,"NETWORK STATUS",C.cyan);text(6,10,"PROTOCOL",C.dim);text(17,10,PROTOCOL,C.cyan);text(6,12,"PORT",C.dim);text(17,12,PORT,C.yellow);text(6,14,"CLIENTS",C.dim);text(17,14,up.." ONLINE",C.green)
 card(35,7,43,8,"CENTRAL DESKTOP",C.purple);text(38,10,"ADDRESS",C.dim);text(49,10,wireless.address(),C.white);text(38,12,"MODE",C.dim);text(49,12,mode,C.green);text(38,14,"DISCOVERY",C.dim);text(49,14,"AUTOMATIC",C.cyan)
 card(3,17,75,9,"LIVE DEVICES",C.pink);if #l==0 then text(7,21,"Searching for Buldacity controllers...",C.dim) end
 for i,d in ipairs(l) do if i>5 then break end;local y=18+i;text(7,y,string.format("%02d",i),C.dim);text(12,y,(d.name or "UNKNOWN"):sub(1,25),C.white);text(41,y,d.role or "CLIENT",C.dim);text(59,y,online(d) and "● ONLINE" or "○ OFFLINE",online(d) and C.green or C.red) end
 card(3,28,75,math.max(4,H-32),"EVENT LOG",C.yellow);for i=1,math.min(#logs,H-35) do text(6,28+i,logs[i],C.dim) end;nav()
end

local function network()
 header("NETWORK","AUTOMATIC BULDACITY/2 NETWORK")
 card(3,7,75,9,"NETWORK CORE",C.cyan);text(6,10,"Protocol",C.dim);text(19,10,PROTOCOL,C.cyan);text(6,12,"Port",C.dim);text(19,12,PORT,C.yellow);text(6,14,"Mode",C.dim);text(19,14,mode,C.green);text(39,10,"Address",C.dim);text(51,10,wireless.address(),C.white);text(39,12,"Wireless",C.dim);text(51,12,wireless.isWireless() and "YES" or "NO",C.green);text(39,14,"Setup",C.dim);text(51,14,"AUTOMATIC",C.cyan)
 card(3,17,75,H-21,"CLIENTS / HEARTBEAT",C.purple);local l=listDevices();for i,d in ipairs(l) do local y=18+i;if y>H-5 then break end;text(7,y,string.format("%02d",i),C.dim);text(12,y,(d.name or "UNKNOWN"):sub(1,24),C.white);text(39,y,(d.address or ""):sub(1,12),C.dim);text(53,y,online(d) and "ONLINE" or "OFFLINE",online(d) and C.green or C.red);text(65,y,online(d) and string.format("%ds",math.floor(now()-(d.last or now()))) or "--",C.dim) end;text(7,H-5,"[R] rediscover all clients",C.dim);nav()
end

local function devicesPage()
 header("DEVICES","SELECT A CONTROLLER")
 card(3,7,75,H-11,"CONNECTED CONTROLLERS",C.purple);local l=listDevices();if #l==0 then text(7,12,"No controller online yet.",C.dim);text(7,14,"Clients announce themselves automatically.",C.dim) end
 for i,d in ipairs(l) do local y=9+i;if y>H-6 then break end;if i==selected then fill(5,y,70,1,C.panel2);fill(5,y,2,1,C.cyan) end;text(8,y,string.format("%02d",i),C.dim);text(13,y,(d.name or "UNKNOWN"):sub(1,24),i==selected and C.cyan or C.white);text(39,y,d.role or "CLIENT",C.dim);text(53,y,online(d) and "● ONLINE" or "○ OFFLINE",online(d) and C.green or C.red) end;text(7,H-5,"↑/↓ select   ENTER live interface   R refresh",C.dim);nav()
end

local function apps()
 header("APPS","CONTROLLER LIBRARY")
 card(3,7,75,H-11,"INSTALLED CONTROLLERS",C.pink);for i,v in ipairs(controllers) do local y=8+i;if y>H-6 then break end;local exists=filesystem.exists(v[2]);text(7,y,string.format("%02d",i),C.dim);text(12,y,v[1],C.white);text(31,y,v[2]:sub(1,34),C.dim);text(68,y,exists and "READY" or "MISS",exists and C.green or C.red) end;text(7,H-5,"Normal/Modern controller files remain available; clients run them remotely.",C.dim);nav()
end

local function remote()
 header("REMOTE","LIVE CONTROLLER DISPLAY")
 local d=selectedDevice();if not d then card(3,7,75,H-11,"REMOTE DESKTOP",C.pink);text(7,12,"No controller selected.",C.dim);text(7,14,"Open DEVICES and select a client first.",C.dim);nav();return end
 local maxW=math.max(10,W-6);local maxH=math.max(8,H-11);local vw=math.min(maxW,remoteSize.w>0 and remoteSize.w or maxW);local vh=math.min(maxH,remoteSize.h>0 and remoteSize.h or maxH);local ox=3;local oy=7
 fill(ox,oy,vw+2,vh+2,C.panel);fill(ox,oy,vw+2,1,C.pink);text(ox+2,oy+2,(d.name or "CONTROLLER").."  "..(online(d) and "ONLINE" or "OFFLINE"),C.white);line(ox+2,oy+3,vw-2,C.line)
 if remoteFrame then for y=1,math.min(vh-3,remoteSize.h) do local row=remoteFrame[y];if row then for x=1,math.min(vw,remoteSize.w) do local cell=row[x];if cell then gpu.setBackground(cell[3] or C.black);gpu.setForeground(cell[2] or C.white);gpu.set(ox+x,oy+3+y,tostring(cell[1] or " ")) end end end end else text(ox+3,oy+7,"CONNECTING TO CONTROLLER...",C.dim) end
 fill(ox,oy+vh+1,vw+2,2,C.bar);text(ox+2,oy+vh+2,"LIVE  |  ENTER=PING  |  R=REFRESH  |  ESC=BACK",C.dim);nav()
end

local function system()
 header("SYSTEM","DESKTOP DIAGNOSTICS")
 card(3,7,36,11,"COMPUTER",C.yellow);text(6,10,"Uptime",C.dim);text(18,10,string.format("%.1fs",computer.uptime()),C.white);text(6,12,"Energy",C.dim);text(18,12,computer.energy and math.floor(computer.energy()) or "N/A",C.green);text(6,14,"Max energy",C.dim);text(18,14,computer.maxEnergy and math.floor(computer.maxEnergy()) or "N/A",C.white);text(6,16,"Tier",C.dim);text(18,16,"TIER-3",C.cyan)
 card(41,7,37,11,"NETWORK AUTO-CONFIG",C.cyan);text(44,10,"Protocol",C.dim);text(56,10,PROTOCOL,C.cyan);text(44,12,"Port",C.dim);text(56,12,PORT,C.yellow);text(44,14,"Modem",C.dim);text(56,14,"AUTO",C.green);text(44,16,"Discovery",C.dim);text(56,16,"AUTO",C.green)
 card(3,20,75,H-24,"ABOUT",C.purple);text(7,23,"BULDACITY OS",C.cyan);text(7,25,"Central Tier-3 desktop for OpenComputers 1.7.10",C.white);text(7,27,"No manual port setup. No whitelist. No external configuration required.",C.dim);text(7,29,"Remote screen + keyboard + touch + scroll are handled over BULDACITY/2.",C.dim);nav()
end

local function draw()
 W,H=gpu.maxResolution();gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ")
 if page=="HOME" then home() elseif page=="NETWORK" then network() elseif page=="DEVICES" then devicesPage() elseif page=="APPS" then apps() elseif page=="REMOTE" then remote() else system() end
 dirty=false
end

local function remember(sender,data)
 local d=devices[sender] or {address=sender};devices[sender]=d;for k,v in pairs(data or {}) do d[k]=v end;d.last=now()
end

addLog("BULDACITY OS "..VERSION.." starting")
addLog("Automatic modem/port setup: port "..PORT)
addLog("Protocol "..PROTOCOL)
announce()
event.timer(3,announce,math.huge)
event.timer(2,pingAll,math.huge)
event.timer(1,function() if page=="REMOTE" then requestScreen(selectedDevice()) end end,math.huge)
draw()

while running do
 local e,a,b,c,distance,message=event.pull(0.20)
 if e=="key_down" then
  local char=b or 0;local key=c or 0;local target=selectedDevice()
  if char==113 or char==81 then running=false
  elseif char==49 then page="HOME";dirty=true
  elseif char==50 then page="NETWORK";dirty=true
  elseif char==51 then page="DEVICES";dirty=true
  elseif char==52 then page="APPS";dirty=true
  elseif char==53 then page="REMOTE";dirty=true;requestScreen(target)
  elseif char==54 then page="SYSTEM";dirty=true
  elseif char==114 or char==82 then pingAll();if target then requestScreen(target) end
  elseif char==27 then page="DEVICES";dirty=true
  elseif key==200 then selected=math.max(1,selected-1);page="DEVICES";dirty=true
  elseif key==208 then selected=selected+1;page="DEVICES";dirty=true
  elseif key==28 and target then page="REMOTE";send(target,"PING",{from="TIER3"});setStatus("PING SENT")
  elseif page=="REMOTE" and target then send(target,"INPUT",{event="key_down",char=char,code=key}) end
 elseif e=="key_up" and page=="REMOTE" then local t=selectedDevice();if t then send(t,"INPUT",{event="key_up",char=b or 0,code=c or 0}) end
 elseif e=="touch" then
  local x,y=a,b;local l=listDevices()
  if y>=H-3 and x<14 then page="HOME"
  elseif y>=H-3 and x<27 then page="NETWORK"
  elseif y>=H-3 and x<40 then page="DEVICES"
  elseif y>=H-3 and x<53 then page="APPS"
  elseif y>=H-3 and x<66 then page="REMOTE"
  elseif page=="DEVICES" and y>=9 and y<=H-6 and #l>0 then selected=math.max(1,math.min(#l,y-9));page="REMOTE";requestScreen(selectedDevice())
  elseif page=="REMOTE" then local t=selectedDevice();if t then local rx=x-3;local ry=y-10;send(t,"INPUT",{event="touch",x=rx,y=ry,button=1}) end end
  dirty=true
 elseif e=="scroll" and page=="REMOTE" then local t=selectedDevice();if t then send(t,"INPUT",{event="scroll",x=a or 0,y=b or 0,button=c or 0}) end
 elseif e=="modem_message" then
  -- OpenComputers: receiver, sender, port, distance, message
  if c==PORT and wireless.valid(message) then
   local p=message;local sender=b
   if p.kind=="HELLO" or p.kind=="HEARTBEAT" or p.kind=="PONG" then
    remember(sender,p.data);setStatus("CLIENT ONLINE")
   elseif p.kind=="SCREEN_BEGIN" then
    remoteSize.w=(p.data and p.data.width) or 0;remoteSize.h=(p.data and p.data.height) or 0;remoteFrames={};setStatus("RECEIVING SCREEN")
   elseif p.kind=="SCREEN_ROW" then
    if p.data and p.data.y then remoteFrames[p.data.y]=p.data.cells end
   elseif p.kind=="SCREEN_END" then
    local t=selectedDevice();if t and sender==t.address then remoteFrame=remoteFrames;setStatus("LIVE SCREEN") end
   end
   dirty=true
  end
 end
 if dirty or now()-lastDraw>=0.75 then lastDraw=now();draw() end
end

gpu.setBackground(C.bg);gpu.fill(1,1,W,H," ");gpu.setForeground(C.cyan);gpu.set(3,3,"BULDACITY OS stopped")
