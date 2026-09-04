-- BuldacityNetworkClient.lua
-- Shared wireless/network service for all Buldacity controllers.
-- OpenComputers 1.7.10 / protocol BULDACITY/1 / port 4242
-- Provides discovery, heartbeat and remote input forwarding.

local component=require("component")
local event=require("event")
local computer=require("computer")
local M={PROTOCOL="BULDACITY/1",PORT=4242,TIMEOUT=10,modem=nil,server=nil,lastServer=0}

local function modem()
  if M.modem and type(M.modem.open)=="function" then return M.modem end
  for address in component.list("modem",true) do M.modem=component.proxy(address); if M.modem then return M.modem end end
end
local function packet(kind,data) return {protocol=M.PROTOCOL,kind=kind,sender=computer.address(),time=computer.uptime(),data=data or {}} end
function M.init(name,role)
  M.name=name or "BULDACITY CONTROLLER"; M.role=role or "CLIENT"
  local m=modem(); if not m then return false,"NO MODEM" end
  m.open(M.PORT); return true
end
function M.send(address,kind,data)
  local m=modem(); if not m then return false end
  return m.send(address,M.PORT,packet(kind,data))
end
function M.broadcast(kind,data)
  local m=modem(); if not m then return false end
  return m.broadcast(M.PORT,packet(kind,data))
end
function M.hello(extra) extra=extra or {}; extra.name=M.name; extra.role=M.role; extra.app=M.name; return M.broadcast("HELLO",extra) end
function M.heartbeat(extra) extra=extra or {}; extra.name=M.name; extra.role=M.role; extra.app=M.name; extra.uptime=computer.uptime(); extra.serverOnline=M.server~=nil and computer.uptime()-M.lastServer<=M.TIMEOUT; return M.broadcast("HEARTBEAT",extra) end
function M.handleInput(sender,data)
  if type(data)~="table" then return end
  local kind=data.event
  if kind=="key_down" or kind=="key_up" then
    pcall(computer.pushSignal,kind,sender,data.char or 0,data.code or 0)
  elseif kind=="touch" then
    pcall(computer.pushSignal,"touch",sender,data.x or 1,data.y or 1,data.button or 0)
  elseif kind=="scroll" then
    pcall(computer.pushSignal,"scroll",sender,data.x or 0,data.y or 0,data.button or 0)
  end
end
function M.start(name,role,extra)
  if not M.init(name,role) then return false end
  M.hello(extra)
  event.listen("modem_message",function(_,receiver,sender,port,distance,...)
    if port~=M.PORT then return end
    local p=(...)
    if type(p)=="table" and p.protocol==M.PROTOCOL then
      if p.kind=="SERVER" or p.kind=="SERVER_HELLO" or p.kind=="PONG" then M.server=sender; M.lastServer=computer.uptime() end
      if p.kind=="PING" then M.send(sender,"PONG",{name=M.name,role=M.role,app=M.name}) end
      if p.kind=="INPUT" then M.handleInput(sender,p.data) end
    end
  end)
  event.timer(3,function() M.heartbeat(extra) end,math.huge)
  return true
end
return M
