-- BULDACITY Modern Client runtime
-- Shared runtime for every *_Modern.lua client.
-- Flow: CLIENT -> RELAY -> TIER3-CORE.

local Network=require("network-modern.Network")
local Config=require("clients.Config")
local component=require("component")
local computer=require("computer")

local M={started=false,name=nil,controller=nil,capabilities={},lastCommand=nil,commandHandler=nil}

local function modemPresent() return component.isAvailable("modem") end

function M.start(name,controller,capabilities,extra,commandHandler)
  if M.started then return true end
  if not modemPresent() then return false,"NO_MODEM" end
  M.name=name or Config.name
  M.controller=controller
  M.capabilities=capabilities or Config.capabilities
  M.commandHandler=commandHandler
  local info=extra or {}
  info.controller=controller
  info.capabilities=M.capabilities
  info.uptime=computer.uptime()
  info.clientVersion=1
  local ok,err=Network.startClient(M.name,info,function(packet) M.onPacket(packet) end)
  if not ok then return false,err end
  M.started=true
  return true
end

function M.onPacket(packet)
  if not packet then return end
  if packet.type=="COMMAND" then
    M.lastCommand=packet
    local success=false
    local result="NO_COMMAND_HANDLER"
    if M.commandHandler then
      local ok,a,b=pcall(M.commandHandler,packet.payload or {},packet)
      if ok then success=(a~=false);result=b or a else result=a end
    end
    M.sendCommandResult(packet.id,success,result)
  elseif packet.type=="PING" then
    Network.send("PONG","TIER3-CORE",{nodeId=Network.status().nodeId,controller=M.controller})
  elseif packet.type=="EMERGENCY_STOP" then
    if M.commandHandler then pcall(M.commandHandler,{action="EMERGENCY_STOP",emergency=true},packet) end
    M.sendStatus({emergencyStopped=true})
  end
end

function M.sendStatus(status)
  status=status or {}
  status.role="CLIENT"
  status.nodeId=Network.status().nodeId
  status.controller=M.controller
  status.capabilities=M.capabilities
  return Network.send("STATUS","TIER3-CORE",status)
end

function M.sendCommandResult(commandId,success,result)
  return Network.send("STATUS","TIER3-CORE",{role="CLIENT",nodeId=Network.status().nodeId,commandId=commandId,success=success==true,result=result})
end

function M.status()
  local s=Network.status()
  s.started=M.started;s.name=M.name;s.controller=M.controller;s.capabilities=M.capabilities;s.lastCommand=M.lastCommand
  return s
end

return M
