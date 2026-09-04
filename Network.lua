-- Network.lua
-- Shared BULDACITY/2 network service.
-- OpenComputers 1.7.10 / port 4242.
-- Compatible with Wireless Network Card (Tier 2) and wired Network Cards.

local component=require("component")
local computer=require("computer")
local event=require("event")

local M={
 PROTOCOL="BULDACITY/2",PORT=4242,TIMEOUT=12,SCREEN_INTERVAL=1.0,
 modem=nil,wireless=false,wirelessStrength=0,server=nil,lastServer=0,
 serverListening=false,serverCallback=nil,clientListening=false,heartbeatTimer=nil
}

local function findModem()
 if M.modem and type(M.modem.open)=="function" then return M.modem end
 for address in component.list("modem",true) do
  local m=component.proxy(address)
  if m then
   M.modem=m
   M.wireless=type(m.setStrength)=="function" or type(m.getStrength)=="function"
   return m
  end
 end
end

local function configureWireless(m)
 if not M.wireless then return end
 -- Wireless Network Cards only transmit wirelessly when a signal strength is set.
 -- Tier 2 supports the same modem API as a normal network card, plus setStrength.
 -- Use the maximum normal OC range; older/configured builds clamp or reject it safely.
 local ok=pcall(function() m.setStrength(400) end)
 if not ok then
  pcall(function() m.setStrength(16) end)
 end
 local strength=0
 pcall(function() strength=m.getStrength() or 0 end)
 M.wirelessStrength=tonumber(strength) or 0
end

function M.init(port)
 local m=findModem(); if not m then return false,"NO_MODEM" end
 M.PORT=port or M.PORT
 local ok,err=pcall(function() m.open(M.PORT) end)
 if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m)
 if M.wireless then
  return true,"WIRELESS:"..tostring(M.wirelessStrength)
 end
 return true,"WIRED"
end

function M.address()
 local ok,a=pcall(computer.address)
 return ok and a or "unknown"
end

function M.packet(kind,data)
 return {protocol=M.PROTOCOL,kind=kind,sender=M.address(),time=computer.uptime(),data=data or {}}
end

function M.send(address,kind,data)
 local m=findModem();if not m then return false,"NO_MODEM" end
 local ok,err=pcall(function() m.open(M.PORT) end)
 if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m)
 local sent,sErr=pcall(function() return m.send(address,M.PORT,M.packet(kind,data)) end)
 if not sent then return false,sErr end
 return true
end

function M.broadcast(kind,data)
 local m=findModem();if not m then return false,"NO_MODEM" end
 local ok,err=pcall(function() m.open(M.PORT) end)
 if not ok then return false,"OPEN_PORT_FAILED:"..tostring(err) end
 configureWireless(m)
 local sent,sErr=pcall(function() return m.broadcast(M.PORT,M.packet(kind,data)) end)
 if not sent then return false,sErr end
 return true
end

function M.valid(p)
 return type(p)=="table" and p.protocol==M.PROTOCOL and type(p.kind)=="string"
end

function M.startClient(name,extra)
 local ok,mode=M.init(M.PORT);if not ok then return false,mode end
 M.name=name or "BULDACITY CONTROLLER"
 M.extra=extra or {}
 M.extra.name=M.name;M.extra.role="CLIENT";M.extra.app=M.name;M.extra.mode=mode
 M.broadcast("HELLO",M.extra)

 if not M.clientListening then
  M.clientListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,p)
   if port~=M.PORT or not M.valid(p) then return end
   if p.kind=="SERVER_HELLO" or p.kind=="PONG" then
    M.server=sender;M.lastServer=computer.uptime()
   elseif p.kind=="PING" then
    M.send(sender,"PONG",{name=M.name,role="CLIENT",app=M.name})
   elseif p.kind=="INPUT" and type(p.data)=="table" then
    local d=p.data
    if d.event=="key_down" or d.event=="key_up" then
     pcall(computer.pushSignal,d.event,sender,d.char or 0,d.code or 0)
    elseif d.event=="touch" then
     pcall(computer.pushSignal,"touch",sender,d.x or 1,d.y or 1,d.button or 0)
    elseif d.event=="scroll" then
     pcall(computer.pushSignal,"scroll",sender,d.x or 0,d.y or 0,d.button or 0)
    end
   elseif p.kind=="SCREEN_REQUEST" then
    M.sendScreen(sender)
   end
  end)
 end

 if not M.heartbeatTimer then
  M.heartbeatTimer=event.timer(3,function()
   M.broadcast("HEARTBEAT",{name=M.name,role="CLIENT",app=M.name,uptime=computer.uptime(),wireless=M.wireless,wirelessStrength=M.wirelessStrength})
  end,math.huge)
 end
 return true,mode
end

function M.sendScreen(address)
 if not address or not component.isAvailable("gpu") then return false end
 local gpu=component.gpu;local w,h=gpu.getResolution()
 M.send(address,"SCREEN_BEGIN",{width=w,height=h})
 for y=1,h do
  local cells={}
  for x=1,w do
   local ch,fg,bg=gpu.get(x,y)
   cells[x]={ch or " ",fg or 0xFFFFFF,bg or 0}
  end
  M.send(address,"SCREEN_ROW",{y=y,cells=cells})
 end
 M.send(address,"SCREEN_END",{width=w,height=h})
 return true
end

function M.startServer(onPacket)
 local ok,mode=M.init(M.PORT);if not ok then return false,mode end
 -- BuldacityOS_Tier3.lua initializes the server once before installing its callback.
 M.serverCallback=onPacket or M.serverCallback
 if not M.serverListening then
  M.serverListening=true
  event.listen("modem_message",function(_,receiver,sender,port,distance,p)
   if port~=M.PORT or not M.valid(p) then return end
   if M.serverCallback then M.serverCallback(sender,p,distance) end
  end)
 end
 return true,mode
end

return M
