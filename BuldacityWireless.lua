-- BuldacityWireless.lua
-- Real OpenComputers modem/wireless networking layer.
-- Works with Network Card and Wireless Network Card because both expose
-- the OpenComputers modem component API.

local component = require("component")
local computer = require("computer")

local M = {
  PROTOCOL = "BULDACITY/2",
  PORT = 4242,
  TIMEOUT = 12,
  modem = nil,
  wireless = false,
  maxRange = nil
}

local function findModem()
  if M.modem and type(M.modem.open) == "function" then return M.modem end
  for address in component.list("modem", true) do
    local m = component.proxy(address)
    if m then
      M.modem = m
      M.wireless = type(m.setStrength) == "function" or type(m.getStrength) == "function"
      if M.wireless and type(m.getStrength) == "function" then
        local ok, strength = pcall(m.getStrength)
        if ok then M.maxRange = strength end
      end
      return m
    end
  end
  return nil
end

function M.init(port)
  local m = findModem()
  if not m then return false, "NO_MODEM" end
  M.PORT = port or M.PORT
  m.open(M.PORT)
  return true, M.wireless and "WIRELESS" or "WIRED"
end

function M.address()
  local ok, a = pcall(computer.address)
  return ok and a or "unknown"
end

function M.isWireless()
  findModem()
  return M.wireless
end

function M.setStrength(strength)
  local m = findModem()
  if not m or type(m.setStrength) ~= "function" then return false, "NOT_WIRELESS" end
  return pcall(m.setStrength, strength)
end

function M.strength()
  local m = findModem()
  if not m or type(m.getStrength) ~= "function" then return nil end
  local ok, value = pcall(m.getStrength)
  return ok and value or nil
end

function M.packet(kind, data, session)
  return {
    protocol = M.PROTOCOL,
    kind = kind,
    sender = M.address(),
    time = computer.uptime(),
    session = session,
    data = data or {}
  }
end

function M.broadcast(kind, data, session)
  local m = findModem()
  if not m then return false, "NO_MODEM" end
  m.open(M.PORT)
  return m.broadcast(M.PORT, M.packet(kind, data, session))
end

function M.send(address, kind, data, session)
  local m = findModem()
  if not m then return false, "NO_MODEM" end
  m.open(M.PORT)
  return m.send(address, M.PORT, M.packet(kind, data, session))
end

function M.valid(packet)
  return type(packet) == "table" and packet.protocol == M.PROTOCOL and type(packet.kind) == "string"
end

function M.describe()
  return {
    address = M.address(),
    wireless = M.isWireless(),
    strength = M.strength(),
    port = M.PORT
  }
end

return M
