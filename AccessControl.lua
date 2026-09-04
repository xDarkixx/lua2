-- lua2 Access Control for OpenComputers 1.7.10
-- Player identity comes from OpenComputers event data when available.
-- For tamper-resistant UUID authentication, pair this with the server-side
-- Lua2 security bridge described in LUA2_SECURITY.md.

local AccessControl = {}

local okComponent, component = pcall(require, "component")
local computer = okComponent and component.isAvailable("computer") and component.proxy(component.list("computer")()) or nil
local computerAddress = computer and computer.address or nil

local config = {
  enabled = true,
  defaultPermission = false,
  allowNameFallback = true,
  requireComputer = false,
  computers = {},
  players = {},
  roles = {
    admin = { all = true },
    operator = {
      reactor = true, ae2 = true, network = true, buldacity = true,
      status = true, printer = true
    },
    user = { status = true },
    guest = {}
  }
}

local function loadConfig()
  local ok, cfg = pcall(require, "WhitelistConfig")
  if ok and type(cfg) == "table" then
    for k, v in pairs(cfg) do config[k] = v end
    if type(cfg.roles) == "table" then config.roles = cfg.roles end
  end
end

loadConfig()

local function normalize(value)
  if value == nil then return nil end
  return tostring(value):lower()
end

function AccessControl.getComputerAddress()
  return computerAddress
end

function AccessControl.getPlayerFromEvent(...)
  local args = {...}
  -- OpenComputers keyboard/touch events normally put the player name last.
  -- We intentionally do not treat arbitrary UUID-like data from Lua as trusted.
  for i = #args, 1, -1 do
    if type(args[i]) == "string" and args[i] ~= "" then
      local value = args[i]
      if not value:match("^[0-9a-fA-F%-]+$") or #value < 32 then
        return value
      end
    end
  end
  return nil
end

function AccessControl.getPlayer(playerName, playerUUID)
  local uuid = normalize(playerUUID)
  local name = normalize(playerName)

  if uuid and type(config.players) == "table" then
    for configuredName, entry in pairs(config.players) do
      if type(entry) == "table" and normalize(entry.uuid) == uuid then
        return configuredName, entry
      end
    end
  end

  if name and type(config.players) == "table" then
    for configuredName, entry in pairs(config.players) do
      if normalize(configuredName) == name then
        return configuredName, entry
      end
    end
  end

  return nil, nil
end

function AccessControl.hasPermission(permission, playerName, playerUUID, suppliedComputer)
  if not config.enabled then return true end

  local computerId = normalize(suppliedComputer or computerAddress)
  if config.requireComputer then
    if not computerId or type(config.computers) ~= "table" then return false end
    local computerEntry = config.computers[computerId]
    if not computerEntry then return false end
  end

  local name, entry = AccessControl.getPlayer(playerName, playerUUID)
  if not entry then return config.defaultPermission end

  local role = normalize(entry.role) or "guest"
  local roleRules = config.roles[role]
  if not roleRules then return config.defaultPermission end
  if roleRules.all == true then return true end
  if roleRules[permission] == true then return true end

  -- A per-player permission map can override role defaults.
  if type(entry.permissions) == "table" and entry.permissions[permission] ~= nil then
    return entry.permissions[permission] == true
  end

  return false
end

function AccessControl.require(permission, playerName, playerUUID, suppliedComputer)
  if AccessControl.hasPermission(permission, playerName, playerUUID, suppliedComputer) then
    return true
  end
  io.stderr:write("ACCESS DENIED: " .. tostring(permission) .. "\n")
  return false
end

function AccessControl.wrapEvent(permission, eventName, handler)
  local event = require("event")
  while true do
    local data = {event.pull(eventName)}
    local player = AccessControl.getPlayerFromEvent(unpack(data))
    if AccessControl.hasPermission(permission, player) then
      local ok, stop = pcall(handler, unpack(data))
      if not ok then error(stop, 0) end
      if stop == false then return end
    end
  end
end

return AccessControl
