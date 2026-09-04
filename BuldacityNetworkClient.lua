-- BuldacityNetworkClient.lua
-- Shared wireless/network client service for all Buldacity controllers.
-- OpenComputers 1.7.10 / protocol BULDACITY/2 / port 4242
-- Uses the common BuldacityWireless transport.

local event = require("event")
local computer = require("computer")
local wireless = require("BuldacityWireless")

local M = {
  PROTOCOL = "BULDACITY/2",
  PORT = 4242,
  TIMEOUT = 12,
  modem = nil,
  server = nil,
  lastServer = 0
}

local function packet(kind, data)
  return wireless.packet(kind, data)
end

function M.init(name, role)
  M.name = name or "BULDACITY CONTROLLER"
  M.role = role or "CLIENT"
  local ok, mode = wireless.init(M.PORT)
  if not ok then return false, mode or "NO_MODEM" end
  M.mode = mode
  M.modem = wireless.modem
  return true, mode
end

function M.send(address, kind, data)
  return wireless.send(address, kind, data)
end

function M.broadcast(kind, data)
  return wireless.broadcast(kind, data)
end

function M.hello(extra)
  extra = extra or {}
  extra.name = M.name
  extra.role = M.role
  extra.app = M.name
  extra.mode = M.mode
  return M.broadcast("HELLO", extra)
end

function M.heartbeat(extra)
  extra = extra or {}
  extra.name = M.name
  extra.role = M.role
  extra.app = M.name
  extra.uptime = computer.uptime()
  extra.serverOnline = M.server ~= nil and computer.uptime() - M.lastServer <= M.TIMEOUT
  extra.mode = M.mode
  return M.broadcast("HEARTBEAT", extra)
end

function M.handleInput(sender, data)
  if type(data) ~= "table" then return end
  local kind = data.event
  if kind == "key_down" or kind == "key_up" then
    pcall(computer.pushSignal, kind, sender, data.char or 0, data.code or 0)
  elseif kind == "touch" then
    pcall(computer.pushSignal, "touch", sender, data.x or 1, data.y or 1, data.button or 0)
  elseif kind == "scroll" then
    pcall(computer.pushSignal, "scroll", sender, data.x or 0, data.y or 0, data.button or 0)
  end
end

function M.start(name, role, extra)
  local ok, err = M.init(name, role)
  if not ok then return false, err end
  M.hello(extra)

  event.listen("modem_message", function(_, receiver, sender, port, distance, payload)
    if port ~= M.PORT or not wireless.valid(payload) then return end
    if payload.kind == "SERVER_HELLO" or payload.kind == "SERVER" or payload.kind == "PONG" then
      M.server = sender
      M.lastServer = computer.uptime()
    elseif payload.kind == "PING" then
      M.send(sender, "PONG", {name=M.name, role=M.role, app=M.name})
    elseif payload.kind == "INPUT" then
      M.handleInput(sender, payload.data)
    end
  end)

  event.timer(3, function() M.heartbeat(extra) end, math.huge)
  return true, M.mode
end

return M
