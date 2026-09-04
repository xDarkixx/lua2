-- Network.lua
-- Shared BULDACITY/2 network service.
-- OpenComputers 1.7.10 / port 4242.
-- Automatically detects wired/wireless modems and Relay/Access Point paths.
-- Relay/Access Point strength and repeater mode are configured automatically.
-- The central server also performs automatic end-to-end PING/PONG diagnostics.

local component=require("component")
local event=require("event")
local computer=require("computer")

local M={
 PROTOCOL="BULDACITY/2",PORT=4242,TIMEOUT=12,SCREEN_INTERVAL=1.0,
 MAX_WIRELESS_STRENGTH=400,
 modem=nil,wireless=false,wirelessStrength=0,
 relayPath=true,relayCount=0,accessPointCount=0,relayWirelessCount=0,
 relayDetected=false,relayPathType="NONE",lastPacketDistance=0,
 server=nil,lastServer=0,serverListening=false,serverCallback=nil,
 clientListening=false,heartbeatTimer=nil,
 diagnostics={},diagnosticTimer=nil
}

local function findModem()
 local wired=nil;local wireless=nil
 for address in component.list("modem",true) do
  local m=component.proxy(address)
  if m then
   local isWireless=type(m.setStrength)=="function" or type(m.getStrength)=="function"
   if isWireless and not wireless then wireless=m end
   if not isWireless and not wired then wired=m end
  end
 end
 if wireless then M.modem=wireless;M.wireless=true;return wireless end
 if wired then M.modem=wired;M.wireless=false;return wired end
 M.modem=nil;M.wireless=false;return nil
end

local function setMaxWireless(device)
 if not device then return false,0 end
 local hasSet=type(device.setStrength)=="function"
 local hasGet=type(device.getStrength)=="function"
 if not hasSet and not hasGet then return false,0 end
 if hasSet then pcall(function() device.setStrength(M.MAX_WIRELESS_STRENGTH) end) end
 local strength=0
 if hasGet then pcall(function() strength=device.getStrength() or 0 end) end
 return true,tonumber(strength) or 0
end

local function configureRepeaters()
 M.relayCount=0;M.accessPointCount=0;M.relayWirelessCount=0
 for address in component.list("relay",true) do
  local relay=component.proxy(address)
  if relay then
   M.relayCount=M.relayCount+1
   local ok,strength=setMaxWireless(relay)
   if ok and strength>0 then M.relayWirelessCount=M.relayWirelessCount+1 end
   if type(relay.setRepeater)=="function" then pcall(function() relay.setRepeater(true) end) end
  end
 end
 for address in component.list("access_point",true) do
  local ap=component.proxy(address)
  if ap then
   M.accessPointCount=M.accessPointCount+1
   local ok,strength=setMaxWireless(ap)
   if ok and strength>0 then M.relayWirelessCount=M.relayWirelessCount+1 end
   if type(ap.setRepeater)=="function" then pcall(function() ap.setRepeater(true) end) end
  end
 end
 M.relayDetected=(M.relayCount>0 or M.accessPointCount>0)
 if M.relayCount>0 and M.accessPointCount>0 then M.relayPathType="RELAY+ACCESS_POINT"
 elseif M.relayCount>0 then M.relayPathType=(M.relayWirelessCount>0) and "WIRED_RELAY+WIRELESS" or "WIRED_RELAY"
 elseif M.accessPointCount>0 then M.relayPathType="ACCESS_POINT"
 else M.relayPathType="NONE" end
end

local function configureWireless(m)
 if not M.wireless then M.wirelessStrength=0;return end
 local ok=pcall(function() m.setStrength(M.MAX_WIRELESS_STRENGTH) end)
 if not ok then pcall(function() m.setStrength(16) end) end
 local strength=0
 pcall(function() strength=m.getStrength() or 0 end)
 M.wirelessStrength=tonumber(strength) or 0
end

local function initNetwork(port)
 local m=findModem();if not m then return false,"NO_MODEM" end
 M.PORT=port or M.PORT
 local ok,err=pcall(function() m.open(M.PORT) end)
 if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m);configureRepeaters()
 if M.wireless then return true,"WIRELESS:"..tostring(M.wirelessStrength)..":RELAY:"..tostring(M.relayPathType) end
 return true,"WIRED:RELAY:"..tostring(M.relayPathType)
end
function M.init(port) return initNetwork(port) end

function M.address()
 local ok,a=pcall(computer.address)
 return ok and a or "unknown"
end
function M.packet(kind,data)
 return {protocol=M.PROTOCOL,kind=kind,sender=M.address(),time=computer.uptime(),data=data or {}}
end
function M.valid(p) return type(p)=="table" and p.protocol==M.PROTOCOL and type(p.kind)=="string" end

function M.send(address,kind,data)
 local m=findModem();if not m then return false,"NO_MODEM" end
 local ok,err=pcall(function() m.open(M.PORT) end)
 if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m);configureRepeaters()
 local sent,sErr=pcall(function() return m.send(address,M.PORT,M.packet(kind,data)) end)
 if not sent then return false,sErr end
 return true
end
function M.broadcast(kind,data)
 local m=findModem();if not m then return false,"NO_MODEM" end
 local ok,err=pcall(function() m.open(M.PORT) end)
 if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m);configureRepeaters()
 local sent,sErr=pcall(function() return m.broadcast(M.PORT,M.packet(kind,data)) end)
 if not sent then return false,sErr end
 return true
end

function M.setWirelessStrength(strength)
 local m=findModem()
 if not m or not M.wireless or type(m.setStrength)~="function" then return false,"NO_WIRELESS" end
 local n=tonumber(strength);if not n then return false,"BAD_STRENGTH" end
 n=math.max(0,n)
 local ok,err=pcall(function() m.setStrength(n) end)
 if not ok then return false,tostring(err) end
 local actual=0;pcall(function() actual=m.getStrength() or 0 end)
 M.wirelessStrength=tonumber(actual) or 0
 return true,M.wirelessStrength
end
function M.getWirelessStrength()
 local m=findModem();if not m or type(m.getStrength)~="function" then return 0 end
 local v=0;pcall(function() v=m.getStrength() or 0 end)
 M.wirelessStrength=tonumber(v) or 0;return M.wirelessStrength
end

function M.status()
 configureRepeaters()
 return {wireless=M.wireless,wirelessStrength=M:getWirelessStrength(),relayReady=M.relayPath,
  relayDetected=M.relayDetected,relayPathType=M.relayPathType,relayCount=M.relayCount,
  accessPointCount=M.accessPointCount,relayWirelessCount=M.relayWirelessCount,
  lastPacketDistance=M.lastPacketDistance or 0,port=M.PORT,protocol=M.PROTOCOL,
  diagnostics=M.diagnostics}
end

function M.getDiagnostics()
 local r={}
 for address,d in pairs(M.diagnostics) do
  r[address]={}
  for k,v in pairs(d) do r[address][k]=v end
 end
 return r
end

local function clientPongData()
 return {name=M.name or "BULDACITY CONTROLLER",role="CLIENT",app=M.name or "BULDACITY CONTROLLER",
  relay=true,relayDetected=M.relayDetected,relayPathType=M.relayPathType,
  relayCount=M.relayCount,accessPointCount=M.accessPointCount,relayWirelessCount=M.relayWirelessCount,
  wireless=M.wireless,wirelessStrength=M.wirelessStrength}
end

function M.startClient(name,extra)
 local ok,mode=initNetwork(M.PORT);if not ok then return false,mode end
 M.name=name or "BULDACITY CONTROLLER";M.extra=extra or {}
 M.extra.name=M.name;M.extra.role="CLIENT";M.extra.app=M.name;M.extra.mode=mode;M.extra.network=M.extra.network~=false
 M.extra.relay=true;M.extra.relayDetected=M.relayDetected;M.extra.relayPathType=M.relayPathType
 M.extra.relayCount=M.relayCount;M.extra.accessPointCount=M.accessPointCount;M.extra.relayWirelessCount=M.relayWirelessCount
 M.broadcast("HELLO",M.extra)
 if not M.clientListening then
  M.clientListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,p)
   if port~=M.PORT or not M.valid(p) then return end
   M.lastPacketDistance=tonumber(distance) or 0
   if p.kind=="SERVER_HELLO" or p.kind=="PONG" then M.server=sender;M.lastServer=computer.uptime()
   elseif p.kind=="PING" then M.send(sender,"PONG",clientPongData())
   elseif p.kind=="INPUT" and type(p.data)=="table" then
    local d=p.data
    if d.event=="key_down" or d.event=="key_up" then pcall(computer.pushSignal,d.event,sender,d.char or 0,d.code or 0)
    elseif d.event=="touch" then pcall(computer.pushSignal,"touch",sender,d.x or 1,d.y or 1,d.button or 0)
    elseif d.event=="scroll" then pcall(computer.pushSignal,"scroll",sender,d.x or 0,d.y or 0,d.button or 0) end
   elseif p.kind=="SCREEN_REQUEST" and M.sendScreen then M.sendScreen(sender) end
   M.lastWirelessReceived=(tonumber(distance) or 0)>0
  end)
 end
 if not M.heartbeatTimer then
  M.heartbeatTimer=event.timer(3,function()
   findModem();configureWireless(M.modem);configureRepeaters()
   M.broadcast("HEARTBEAT",{name=M.name,role="CLIENT",app=M.name,uptime=computer.uptime(),
    wireless=M.wireless,wirelessStrength=M.wirelessStrength,relay=true,relayReady=M.relayPath,
    relayDetected=M.relayDetected,relayPathType=M.relayPathType,relayCount=M.relayCount,
    accessPointCount=M.accessPointCount,relayWirelessCount=M.relayWirelessCount,
    lastDistance=M.lastDistance or 0,lastWirelessReceived=M.lastWirelessReceived==true})
  end,math.huge)
 end
 return true,mode
end

function M.sendScreen(address)
 if not address or not component.isAvailable("gpu") then return false end
 local g=component.gpu;local w,h=g.getResolution()
 M.send(address,"SCREEN_BEGIN",{width=w,height=h})
 for y=1,h do
  local cells={}
  for x=1,w do local ch,fg,bg=g.get(x,y);cells[x]={ch or " ",fg or 0xFFFFFF,bg or 0} end
  M.send(address,"SCREEN_ROW",{y=y,cells=cells})
 end
 M.send(address,"SCREEN_END",{width=w,height=h});return true
end

-- Server side: every discovered client is automatically pinged. The result
-- is stored in M.diagnostics and is also forwarded to the central UI through
-- the normal PONG callback. Thus the main PC tests every client without a
-- separate diagnostic program.
function M.startServer(onPacket)
 local ok,mode=initNetwork(M.PORT);if not ok then return false,mode end
 M.server=true;M.serverCallback=onPacket or M.serverCallback
 if not M.serverListening then
  M.serverListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,p)
   if port~=M.PORT or not M.valid(p) then return end
   M.lastPacketDistance=tonumber(distance) or 0
   local data=p.data or {}
   if p.kind=="HELLO" or p.kind=="HEARTBEAT" then
    if not M.diagnostics[sender] then M.diagnostics[sender]={address=sender} end
    local d=M.diagnostics[sender]
    for k,v in pairs(data) do d[k]=v end
    d.address=sender;d.last=computer.uptime();d.distance=tonumber(distance) or 0
    d.wireless=d.distance>0;d.relayDetected=data.relayDetected;d.relayPathType=data.relayPathType
    d.result="TESTING";d.pingSent=computer.uptime()
    M.send(sender,"PING",{from="BULDACITY SERVER",diagnostic=true,id=tostring(d.pingSent)})
   elseif p.kind=="PONG" then
    local d=M.diagnostics[sender] or {address=sender};M.diagnostics[sender]=d
    for k,v in pairs(data) do d[k]=v end
    d.address=sender;d.last=computer.uptime();d.lastPong=d.last
    d.distance=tonumber(distance) or 0;d.wireless=d.distance>0;d.result="PASS"
    if d.pingSent then d.latency=(d.last-d.pingSent)*1000 end
   end
   if M.serverCallback then M.serverCallback(sender,p,distance) end
  end)
 end
 return true,mode
end

return M
