-- BuldacityNetworkClient.lua
-- Shared wireless/network client service for all Buldacity controllers.
-- OpenComputers 1.7.10 / protocol BULDACITY/2 / port 4242
-- Includes optional remote screen streaming for the Tier-3 desktop.

local event = require("event")
local computer = require("computer")
local component = require("component")
local wireless = require("BuldacityWireless")

local M = {
  PROTOCOL = "BULDACITY/2",
  PORT = 4242,
  TIMEOUT = 12,
  SCREEN_INTERVAL = 0.75,
  modem = nil,
  server = nil,
  lastServer = 0,
  screenEnabled = true,
  lastScreen = nil
}

function M.send(address, kind, data)
  return wireless.send(address, kind, data)
end

function M.broadcast(kind, data)
  return wireless.broadcast(kind, data)
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

-- Capture the controller's current GPU surface. Rows are sent separately so
-- ordinary OpenComputers modem packet limits are respected.
local function captureScreen()
  if not M.screenEnabled or not component.isAvailable("gpu") then return nil end
  local gpu = component.gpu
  local w, h = gpu.getResolution()
  local rows = {}
  for y=1,h do
    local cells={}
    for x=1,w do
      local ch, fg, bg = gpu.get(x,y)
      cells[x] = {ch or " ", fg or 0xFFFFFF, bg or 0x000000}
    end
    rows[y] = cells
  end
  return w, h, rows
end

local function sendScreen(address)
  if not address then return end
  local w,h,rows = captureScreen()
  if not w then return end
  -- Start a new frame, then transmit rows individually.
  M.send(address, "SCREEN_BEGIN", {width=w,height=h})
  for y=1,h do
    M.send(address, "SCREEN_ROW", {y=y,cells=rows[y]})
  end
  M.send(address, "SCREEN_END", {width=w,height=h})
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
    elseif payload.kind == "SCREEN_REQUEST" then
      sendScreen(sender)
    end
  end)

  event.timer(3, function() M.heartbeat(extra) end, math.huge)
  event.timer(M.SCREEN_INTERVAL, function()
    if M.server then sendScreen(M.server) end
  end, math.huge)
  return true, M.mode
end

return M
