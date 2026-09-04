-- BuldacityNetwork.lua
-- Shared wireless network protocol for the Buldacity controller family.
-- OpenComputers 1.7.10 compatible.
-- Protocol: BULDACITY/1

local component=require("component")
local event=require("event")
local computer=require("computer")

local M={}
M.PROTOCOL="BULDACITY/1"
M.PORT=4242
M.HEARTBEAT=3
M.TIMEOUT=10
M.server=nil
M.modem=nil
M.lastServer=0
M.serverName=""

local function findModem()
  if M.modem and type(M.modem.open)=="function" then return M.modem end
  for address in component.list("modem",true) do
    local p=component.proxy(address)
    if p then M.modem=p; return p end
  end
end

local function pack(kind,data)
  return {protocol=M.PROTOCOL,kind=kind,sender=computer.address(),time=computer.uptime(),data=data or {}}
end

function M.init(role,name)
  M.role=role or "CLIENT"
  M.name=name or "BULDACITY DEVICE"
  local modem=findModem()
  if not modem then return false,"NO MODEM" end
  modem.open(M.PORT)
  M.modem=modem
  return true
end

function M.broadcast(kind,data)
  if not M.modem then findModem() end
  if not M.modem then return false,"NO MODEM" end
  local p=pack(kind,data)
  return M.modem.broadcast(M.PORT,p)
end

function M.send(address,kind,data)
  if not M.modem then findModem() end
  if not M.modem then return false,"NO MODEM" end
  return M.modem.send(address,M.PORT,pack(kind,data))
end

function M.hello(extra)
  extra=extra or {}
  extra.name=M.name; extra.role=M.role
  return M.broadcast("HELLO",extra)
end

function M.heartbeat(status)
  local d=status or {}
  d.name=M.name; d.role=M.role
  return M.broadcast("HEARTBEAT",d)
end

function M.handle(signal,receiver,sender,port,distance,payload)
  if signal~="modem_message" or port~=M.PORT or type(payload)~="table" then return nil end
  if payload.protocol~=M.PROTOCOL then return nil end
  if payload.kind=="SERVER" or payload.kind=="SERVER_HELLO" then
    M.server=sender; M.serverName=(payload.data and payload.data.name) or "BULDACITY SERVER"; M.lastServer=computer.uptime()
  elseif payload.kind=="PING" then
    M.send(sender,"PONG",{name=M.name,role=M.role})
  elseif payload.kind=="PONG" then
    M.lastServer=computer.uptime()
  end
  return payload
end

function M.serverAlive()
  return M.server~=nil and (computer.uptime()-M.lastServer)<=M.TIMEOUT
end

function M.wait(timeout)
  local e=event.pull(timeout or 0.1)
  if e=="modem_message" then
    local p=M.handle(e,select(2,event.pull))
    return p
  end
  return nil
end

return M
