-- BULDACITY Modern Network Transport
local component=require("component")
local event=require("event")
local M={port=31337,modem=nil}

function M.init(port)
  M.port=port or M.port
  if not component.isAvailable("modem") then return false,"NO_MODEM" end
  M.modem=component.modem
  local ok,err=pcall(function()M.modem.open(M.port)end)
  if not ok then return false,tostring(err) end
  return true
end

function M.send(address,packet)
  if not M.modem then return false,"NOT_INITIALIZED" end
  local ok,err=pcall(function()M.modem.send(address,M.port,packet)end)
  if not ok then return false,tostring(err) end
  return true
end

function M.broadcast(packet)
  if not M.modem then return false,"NOT_INITIALIZED" end
  local ok,err=pcall(function()M.modem.broadcast(M.port,packet)end)
  if not ok then return false,tostring(err) end
  return true
end

function M.receive(timeout)
  local e={event.pull(timeout or 0,"modem_message")}
  if e[1]~="modem_message" then return nil end
  return {receiver=e[2],sender=e[3],port=e[4],distance=e[5],payload=e[6]}
end

function M.status()
  return {port=M.port,modem=M.modem and M.modem.address or nil,available=component.isAvailable("modem")}
end

return M
