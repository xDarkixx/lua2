-- BuldacityNetworkSetup.lua
-- BULDACITY/2 automatic network setup + diagnostics wizard.
-- Runs briefly before the Tier-3 desktop and checks ALL BULDACITY clients.
-- Minecraft 1.7.10 / OpenComputers 1.8.10 / modem port 4242

local component=require("component")
local computer=require("computer")
local event=require("event")
local network=require("Network")
local UI=require("BuldacityUI")

local PORT=4242
local RUN_SECONDS=8
local VERSION="1.0"
local clients={}
local status="INITIALISIERUNG..."
local started=computer.uptime()
local lastDraw=0

local function merge(a,b)
 if type(b)=="table" then for k,v in pairs(b) do a[k]=v end end
 return a
end

local function online(d)
 return d and computer.uptime()-(tonumber(d.last) or 0)<12
end

local function classify(c)
 local t=tostring(c or ""):lower()
 if t:find("me_controller",1,true) then return "AE2" end
 if t:find("diesel_generator",1,true) then return "DIESEL" end
 if t:find("reactor",1,true) or t:find("br_",1,true) then return "REACTOR" end
 if t:find("rotary",1,true) then return "ROTARYCRAFT" end
 if t:find("ic2",1,true) or t:find("industrial",1,true) then return "INDUSTRIALCRAFT" end
 if t:find("mekanism",1,true) then return "MEKANISM" end
 if t:find("thermal",1,true) then return "THERMAL" end
 if t:find("pneumatic",1,true) then return "PNEUMATICCRAFT" end
 if t:find("rftools",1,true) then return "RFTOOLS" end
 return nil
end

local function localModems()
 local n=0
 for address in component.list("modem",true) do
  n=n+1
  local m=component.proxy(address)
  if m then
   pcall(function()m.open(PORT)end)
   if type(m.setStrength)=="function" then pcall(function()m.setStrength(400)end) end
  end
 end
 return n
end

local function draw()
 UI.clear()
 UI.header("NETZWERK EINRICHTEN","AUTOMATISCHER BULDACITY/2 SYSTEMTEST",UI.C.blue)
 local s=network.status()
 local elapsed=computer.uptime()-started
 local modemCount=tonumber(s.modemCount) or 0
 local total=0
 local up=0
 for _,d in pairs(clients) do total=total+1;if online(d) then up=up+1 end end
 local cw=math.max(18,math.floor((UI.W-8)/4))
 UI.card(2,6,cw,6,"network","MODEMS",tostring(modemCount),modemCount>0 and 100 or 0,UI.C.cyan)
 UI.card(3+cw,6,cw,6,"signal","SIGNAL",tostring(s.wirelessStrength or 0),s.wirelessReady and 100 or 0,UI.C.purple)
 UI.card(4+cw*2,6,cw,6,"computer","CLIENTS",up.." / "..total,total>0 and up/total*100 or 0,UI.C.green)
 UI.card(5+cw*3,6,cw,6,"gear","PROTOKOLL","4242",100,UI.C.orange)
 UI.panel(2,14,UI.W-4,UI.H-18,"AUTOMATISCHER TEST",UI.C.blue)
 UI.text(5,16,"STATUS: "..status,status:find("FEHLER",1,true) and UI.C.red or UI.C.green,UI.C.panel)
 UI.text(5,18,"Modems werden automatisch auf Port 4242 geöffnet.",UI.C.muted,UI.C.panel)
 UI.text(5,19,"Wireless-Stärke wird automatisch auf 400 gesetzt, wenn verfügbar.",UI.C.muted,UI.C.panel)
 local y=21
 local list={}
 for _,d in pairs(clients) do list[#list+1]=d end
 table.sort(list,function(a,b)return tostring(a.name or a.address)<tostring(b.name or b.address)end)
 for _,d in ipairs(list) do
  if y>UI.H-5 then break end
  local c=online(d) and UI.C.green or UI.C.red
  local found=""
  if type(d.components)=="table" then
   local seen={}
   for _,x in ipairs(d.components) do
    local typ=type(x)=="table" and x.type or x
    local name=classify(typ)
    if name and not seen[name] then seen[name]=true;found=found=="" and name or found..","..name end
   end
  end
  if found=="" then found=tostring(d.mod or d.app or "CONTROLLER") end
  UI.statusLed(5,y,online(d))
  UI.text(9,y,UI.fit(d.name or "CLIENT",24),UI.C.white,UI.C.panel)
  UI.text(34,y,UI.fit(found,24),UI.C.cyan,UI.C.panel)
  UI.text(60,y,(d.wireless and "WLAN" or "WIRED"),d.wireless and UI.C.purple or UI.C.blue,UI.C.panel)
  UI.text(70,y,online(d) and "ONLINE" or "OFFLINE",c,UI.C.panel)
  if d.latency then UI.text(80,y,string.format("%.0fms",d.latency),UI.C.yellow,UI.C.panel) end
  y=y+2
 end
 UI.statusLine("AUTOMATISCHER SCAN // ENTER/TOUCH NICHT ERFORDERLICH // STARTET DESKTOP DANACH",UI.C.muted)
end

local function onPacket(sender,p,distance)
 if not network.valid(p) then return end
 local d=clients[sender] or {address=sender}
 merge(d,p.data or {})
 d.address=sender
 d.last=computer.uptime()
 d.distance=tonumber(distance) or 0
 if p.kind=="HELLO" or p.kind=="HEARTBEAT" then
  d.result="ONLINE"
  status="CLIENT GEFUNDEN: "..tostring(d.name or sender)
 elseif p.kind=="LINK_CONFIRM" then
  d.linked=true;d.result="VERBUNDEN"
 elseif p.kind=="PONG" then
  d.result="PING OK"
 elseif p.kind=="COMPONENT_DATA" then
  d.components=p.data and p.data.components or d.components
  d.componentCount=tonumber(p.data and p.data.count) or (type(d.components)=="table" and #d.components or 0)
  d.result="KOMPONENTEN OK"
 end
 clients[sender]=d
end

local ok,mode=network.startServer(onPacket)
local modemCount=localModems()
if not ok or modemCount==0 then
 status="FEHLER: KEIN MODEM"
else
 status="MODEM OK // SCAN LAEUFT"
 pcall(function()network.setWirelessStrength(400)end)
 pcall(function()network.broadcast("SERVER_HELLO",{name="BULDACITY SETUP",role="SERVER",app="NETWORK SETUP",version=VERSION,protocol=network.PROTOCOL,port=PORT,discover=true,scan=true,serverAddress=network.address()})end)
end

draw()
while computer.uptime()-started<RUN_SECONDS do
 local timeout=math.min(0.5,RUN_SECONDS-(computer.uptime()-started))
 if timeout<=0 then break end
 event.pull(timeout)
 local elapsed=computer.uptime()-started
 if elapsed>2 and elapsed<7 then
  pcall(function()network.broadcast("SERVER_HELLO",{name="BULDACITY SETUP",role="SERVER",app="NETWORK SETUP",version=VERSION,protocol=network.PROTOCOL,port=PORT,discover=true,scan=true,serverAddress=network.address()})end)
 end
 if computer.uptime()-lastDraw>0.25 then lastDraw=computer.uptime();draw() end
end

if ok and modemCount>0 then
 local count=0
 for _ in pairs(clients) do count=count+1 end
 status=count>0 and ("FERTIG // "..count.." CLIENT(S) GEFUNDEN") or "FERTIG // NOCH KEIN CLIENT GEFUNDEN"
else
 status="FERTIG // MODEM PRUEFEN"
end
