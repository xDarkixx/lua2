-- Network.lua
-- Shared BULDACITY/2 network service for OpenComputers 1.7.10.
-- Robust bidirectional client/server linking on port 4242.
-- All controllers are expected to load this file from /home.

local component=require("component")
local event=require("event")
local computer=require("computer")

local M={
 PROTOCOL="BULDACITY/2",PORT=4242,TIMEOUT=12,SCREEN_INTERVAL=1.0,
 MAX_WIRELESS_STRENGTH=400,
 modem=nil,wireless=false,wirelessStrength=0,
 wirelessAvailable=false,wirelessReady=false,wirelessComponent=nil,
 relayPath=true,relayCount=0,accessPointCount=0,relayWirelessCount=0,
 relayDetected=false,relayPathType="NONE",lastPacketDistance=0,
 server=nil,serverAddress=nil,lastServer=0,serverListening=false,serverCallback=nil,
 clientListening=false,heartbeatTimer=nil,helloTimer=nil,linked=false,linkSince=0,
 diagnostics={},diagnosticTimer=nil
}

local function wirelessComponentCheck()
 local found=nil;local count=0
 for address in component.list("modem",true) do
  local m=component.proxy(address)
  if m and (type(m.setStrength)=="function" or type(m.getStrength)=="function") then
   count=count+1;if not found then found=m end
  end
 end
 M.wirelessAvailable=count>0;M.wirelessComponent=found and found.address or nil;M.wirelessReady=false
 if found then local strength=0;pcall(function() strength=found.getStrength() or 0 end);M.wirelessReady=tonumber(strength) and tonumber(strength)>0 or false end
 return M.wirelessAvailable,M.wirelessReady,count,M.wirelessComponent
end

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
 local hasSet=type(device.setStrength)=="function";local hasGet=type(device.getStrength)=="function"
 if not hasSet and not hasGet then return false,0 end
 if hasSet then pcall(function() device.setStrength(M.MAX_WIRELESS_STRENGTH) end) end
 local strength=0;if hasGet then pcall(function() strength=device.getStrength() or 0 end) end
 return true,tonumber(strength) or 0
end

local function configureRepeaters()
 M.relayCount=0;M.accessPointCount=0;M.relayWirelessCount=0
 for address in component.list("relay",true) do
  local relay=component.proxy(address)
  if relay then
   M.relayCount=M.relayCount+1
   local ok,strength=setMaxWireless(relay);if ok and strength>0 then M.relayWirelessCount=M.relayWirelessCount+1 end
   if type(relay.setRepeater)=="function" then pcall(function() relay.setRepeater(true) end) end
  end
 end
 for address in component.list("access_point",true) do
  local ap=component.proxy(address)
  if ap then
   M.accessPointCount=M.accessPointCount+1
   local ok,strength=setMaxWireless(ap);if ok and strength>0 then M.relayWirelessCount=M.relayWirelessCount+1 end
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
 wirelessComponentCheck()
 if not M.wireless then M.wirelessStrength=0;M.wirelessReady=false;return end
 local ok=pcall(function() m.setStrength(M.MAX_WIRELESS_STRENGTH) end)
 if not ok then pcall(function() m.setStrength(16) end) end
 local strength=0;pcall(function() strength=m.getStrength() or 0 end)
 M.wirelessStrength=tonumber(strength) or 0;M.wirelessReady=M.wirelessStrength>0;M.wirelessAvailable=true;M.wirelessComponent=m.address
end

local function initNetwork(port)
 local m=findModem();if not m then wirelessComponentCheck();return false,"NO_MODEM" end
 M.PORT=port or M.PORT
 local ok,err=pcall(function() m.open(M.PORT) end);if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m);configureRepeaters();wirelessComponentCheck()
 if M.wireless then return true,"WIRELESS:"..tostring(M.wirelessStrength)..":RELAY:"..tostring(M.relayPathType) end
 return true,"WIRED:RELAY:"..tostring(M.relayPathType)
end
function M.init(port) return initNetwork(port) end
function M.address() local ok,a=pcall(computer.address);return ok and a or "unknown" end
function M.packet(kind,data) return {protocol=M.PROTOCOL,kind=kind,sender=M.address(),time=computer.uptime(),data=data or {}} end
function M.valid(p) return type(p)=="table" and p.protocol==M.PROTOCOL and type(p.kind)=="string" end

function M.componentCheck()
 wirelessComponentCheck();local modemCount=0;for _ in component.list("modem",true) do modemCount=modemCount+1 end
 local relayCount=0;for _ in component.list("relay",true) do relayCount=relayCount+1 end
 local apCount=0;for _ in component.list("access_point",true) do apCount=apCount+1 end
 return {modemCount=modemCount,wirelessAvailable=M.wirelessAvailable,wirelessReady=M.wirelessReady,wirelessComponent=M.wirelessComponent,wirelessStrength=M.wirelessStrength,relayCount=relayCount,accessPointCount=apCount,relayWirelessCount=M.relayWirelessCount,wireless=M.wireless}
end

function M.send(address,kind,data)
 if not address then return false,"NO_ADDRESS" end
 local m=findModem();if not m then return false,"NO_MODEM" end
 local ok,err=pcall(function() m.open(M.PORT) end);if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m);configureRepeaters();wirelessComponentCheck()
 local sent,sErr=pcall(function() return m.send(address,M.PORT,M.packet(kind,data)) end);if not sent then return false,sErr end
 return true
end
function M.broadcast(kind,data)
 local m=findModem();if not m then return false,"NO_MODEM" end
 local ok,err=pcall(function() m.open(M.PORT) end);if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m);configureRepeaters();wirelessComponentCheck()
 local sent,sErr=pcall(function() return m.broadcast(M.PORT,M.packet(kind,data)) end);if not sent then return false,sErr end
 return true
end

function M.setWirelessStrength(strength)
 local m=findModem();if not m or not M.wireless or type(m.setStrength)~="function" then return false,"NO_WIRELESS" end
 local n=tonumber(strength);if not n then return false,"BAD_STRENGTH" end;n=math.max(0,n)
 local ok,err=pcall(function() m.setStrength(n) end);if not ok then return false,tostring(err) end
 local actual=0;pcall(function() actual=m.getStrength() or 0 end);M.wirelessStrength=tonumber(actual) or 0;M.wirelessReady=M.wirelessStrength>0;M.wirelessAvailable=true
 return true,M.wirelessStrength
end
function M.getWirelessStrength()
 local m=findModem();wirelessComponentCheck();if not m or type(m.getStrength)~="function" then M.wirelessReady=false;return 0 end
 local v=0;pcall(function() v=m.getStrength() or 0 end);M.wirelessStrength=tonumber(v) or 0;M.wirelessReady=M.wirelessStrength>0;M.wirelessAvailable=true;M.wirelessComponent=m.address;return M.wirelessStrength
end
function M.status()
 configureRepeaters();wirelessComponentCheck()
 return {wireless=M.wireless,wirelessAvailable=M.wirelessAvailable,wirelessReady=M.wirelessReady,wirelessComponent=M.wirelessComponent,wirelessStrength=M:getWirelessStrength(),relayReady=M.relayPath,relayDetected=M.relayDetected,relayPathType=M.relayPathType,relayCount=M.relayCount,accessPointCount=M.accessPointCount,relayWirelessCount=M.relayWirelessCount,lastPacketDistance=M.lastPacketDistance or 0,port=M.PORT,protocol=M.PROTOCOL,server=M.serverAddress,linked=M.linked,linkSince=M.linkSince,diagnostics=M.diagnostics}
end
function M.getDiagnostics()
 local r={};for address,d in pairs(M.diagnostics) do r[address]={};for k,v in pairs(d) do r[address][k]=v end end;return r
end

local function clientData()
 wirelessComponentCheck()
 return {name=M.name or "BULDACITY CONTROLLER",role="CLIENT",app=M.name or "BULDACITY CONTROLLER",relay=true,relayDetected=M.relayDetected,relayPathType=M.relayPathType,relayCount=M.relayCount,accessPointCount=M.accessPointCount,relayWirelessCount=M.relayWirelessCount,wireless=M.wireless,wirelessAvailable=M.wirelessAvailable,wirelessReady=M.wirelessReady,wirelessComponent=M.wirelessComponent,wirelessStrength=M.wirelessStrength,clientAddress=M.address(),serverAddress=M.serverAddress,linked=M.linked}
end

function M.startClient(name,extra)
 local ok,mode=initNetwork(M.PORT);if not ok then return false,mode end
 M.name=name or "BULDACITY CONTROLLER";M.extra=extra or {};M.extra.name=M.name;M.extra.role="CLIENT";M.extra.app=M.name;M.extra.mode=mode;M.extra.network=M.extra.network~=false
 M.extra.relay=true;M.extra.relayDetected=M.relayDetected;M.extra.relayPathType=M.relayPathType;M.extra.relayCount=M.relayCount;M.extra.accessPointCount=M.accessPointCount;M.extra.relayWirelessCount=M.relayWirelessCount;M.extra.wireless=M.wireless;M.extra.wirelessAvailable=M.wirelessAvailable;M.extra.wirelessReady=M.wirelessReady;M.extra.wirelessComponent=M.wirelessComponent;M.extra.wirelessStrength=M.wirelessStrength;M.extra.clientAddress=M.address();M.extra.linked=M.linked
 local function hello() M.extra.clientAddress=M.address();M.extra.serverAddress=M.serverAddress;M.extra.linked=M.linked;M.broadcast("HELLO",M.extra) end
 hello()
 if not M.clientListening then
  M.clientListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,p)
   if port~=M.PORT or not M.valid(p) then return end
   M.lastPacketDistance=tonumber(distance) or 0;local data=p.data or {}
   if p.kind=="SERVER_HELLO" then
    M.server=sender;M.serverAddress=sender;M.lastServer=computer.uptime();M.send(sender,"HELLO",M.extra)
   elseif p.kind=="LINK_ACK" then
    M.server=sender;M.serverAddress=sender;M.lastServer=computer.uptime();M.linked=true;M.linkSince=M.linkSince>0 and M.linkSince or computer.uptime();M.extra.serverAddress=sender;M.extra.linked=true
    M.send(sender,"LINK_CONFIRM",clientData())
   elseif p.kind=="PING" then
    M.server=sender;M.serverAddress=sender;M.lastServer=computer.uptime();M.send(sender,"PONG",{name=M.name,role="CLIENT",app=M.name,wireless=M.wireless,wirelessAvailable=M.wirelessAvailable,wirelessReady=M.wirelessReady,wirelessComponent=M.wirelessComponent,wirelessStrength=M.wirelessStrength,relay=true,relayDetected=M.relayDetected,relayPathType=M.relayPathType,relayCount=M.relayCount,accessPointCount=M.accessPointCount,relayWirelessCount=M.relayWirelessCount,linked=M.linked,clientAddress=M.address(),serverAddress=M.serverAddress,id=data.id})
   elseif p.kind=="INPUT" and type(data)=="table" then
    if data.event=="key_down" or data.event=="key_up" then pcall(computer.pushSignal,data.event,sender,data.char or 0,data.code or 0)
    elseif data.event=="touch" then pcall(computer.pushSignal,"touch",sender,data.x or 1,data.y or 1,data.button or 0)
    elseif data.event=="scroll" then pcall(computer.pushSignal,"scroll",sender,data.x or 0,data.y or 0,data.button or 0) end
   elseif p.kind=="SCREEN_REQUEST" and M.sendScreen then M.sendScreen(sender) end
   M.lastWirelessReceived=(tonumber(distance) or 0)>0
  end)
 end
 if not M.helloTimer then M.helloTimer=event.timer(3,hello,math.huge) end
 if not M.heartbeatTimer then
  M.heartbeatTimer=event.timer(3,function()
   findModem();configureWireless(M.modem);configureRepeaters();wirelessComponentCheck();local data={name=M.name,role="CLIENT",app=M.name,uptime=computer.uptime(),wireless=M.wireless,wirelessAvailable=M.wirelessAvailable,wirelessReady=M.wirelessReady,wirelessComponent=M.wirelessComponent,wirelessStrength=M.wirelessStrength,relay=true,relayReady=M.relayPath,relayDetected=M.relayDetected,relayPathType=M.relayPathType,relayCount=M.relayCount,accessPointCount=M.accessPointCount,relayWirelessCount=M.relayWirelessCount,lastDistance=M.lastDistance or 0,lastWirelessReceived=M.lastWirelessReceived==true,clientAddress=M.address(),serverAddress=M.serverAddress,linked=M.linked}
   if M.serverAddress then M.send(M.serverAddress,"HEARTBEAT",data) else M.broadcast("HEARTBEAT",data) end
  end,math.huge)
 end
 return true,mode
end

function M.sendScreen(address)
 if not address or not component.isAvailable("gpu") then return false end
 local g=component.gpu;local w,h=g.getResolution();M.send(address,"SCREEN_BEGIN",{width=w,height=h})
 for y=1,h do local cells={};for x=1,w do local ch,fg,bg=g.get(x,y);cells[x]={ch or " ",fg or 0xFFFFFF,bg or 0} end;M.send(address,"SCREEN_ROW",{y=y,cells=cells}) end
 M.send(address,"SCREEN_END",{width=w,height=h});return true
end

function M.startServer(onPacket)
 local ok,mode=initNetwork(M.PORT);if not ok then return false,mode end
 M.server=true;M.serverCallback=onPacket or M.serverCallback
 if not M.serverListening then
  M.serverListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,p)
   if port~=M.PORT or not M.valid(p) then return end
   M.lastPacketDistance=tonumber(distance) or 0;local data=p.data or {}
   if p.kind=="HELLO" or p.kind=="HEARTBEAT" then
    if not M.diagnostics[sender] then M.diagnostics[sender]={address=sender} end
    local d=M.diagnostics[sender];for k,v in pairs(data) do d[k]=v end
    d.address=sender;d.last=computer.uptime();d.distance=tonumber(distance) or 0;d.wireless=d.distance>0 or data.wireless==true;d.wirelessAvailable=data.wirelessAvailable==true;d.wirelessReady=data.wirelessReady==true;d.wirelessComponent=data.wirelessComponent;d.wirelessStrength=tonumber(data.wirelessStrength) or 0;d.relayDetected=data.relayDetected;d.relayPathType=data.relayPathType;d.result=d.linked and "LINKED" or "TESTING";d.pingSent=computer.uptime()
    M.send(sender,"LINK_ACK",{serverAddress=M.address(),protocol=M.PROTOCOL,port=M.PORT,linked=true,serverName="BULDACITY TIER-3"});M.send(sender,"PING",{from="BULDACITY SERVER",diagnostic=true,id=tostring(d.pingSent)})
   elseif p.kind=="LINK_CONFIRM" then
    local d=M.diagnostics[sender] or {address=sender};M.diagnostics[sender]=d;for k,v in pairs(data) do d[k]=v end;d.address=sender;d.last=computer.uptime();d.distance=tonumber(distance) or d.distance or 0;d.linked=true;d.linkSince=d.linkSince or computer.uptime();d.result="LINKED";d.serverAddress=M.address()
   elseif p.kind=="PONG" then
    local d=M.diagnostics[sender] or {address=sender};M.diagnostics[sender]=d;for k,v in pairs(data) do d[k]=v end;d.address=sender;d.last=computer.uptime();d.lastPong=d.last;d.distance=tonumber(distance) or 0;d.wireless=d.distance>0 or data.wireless==true;d.wirelessAvailable=data.wirelessAvailable==true;d.wirelessReady=data.wirelessReady==true;d.wirelessComponent=data.wirelessComponent;d.wirelessStrength=tonumber(data.wirelessStrength) or d.wirelessStrength or 0;d.result=d.linked==false and "PASS" or "LINKED";if d.pingSent then d.latency=(d.last-d.pingSent)*1000 end
   end
   if M.serverCallback then M.serverCallback(sender,p,distance) end
  end)
 end
 return true,mode
end

return M
