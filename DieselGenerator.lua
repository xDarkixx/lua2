-- Immersive Engineering Diesel Generator Manager
-- Minecraft 1.7.10 / ImmersiveEngineering 0.7.7
-- OpenComputers 1.8.10
--
-- Requires an OpenComputers Adapter on one of the Diesel Generator's
-- redstone/control positions. IE exposes the component as:
--     ie_diesel_generator
--
-- Controls:
--   A = automatic mode
--   M = manual ON
--   O = manual OFF
--   R = refresh
--   Q = quit

local component = require("component")
local event = require("event")
local computer = require("computer")
local keyboard = require("keyboard")

local gpu = component.gpu
local gen = component.ie_diesel_generator

if not gen then
  error("Kein ie_diesel_generator gefunden. Adapter an den roten Steueranschluss setzen.")
end

local W, H = 132, 38
local version = "1.0.0"

local C = {
  bg = 0x0B0F14,
  panel = 0x151B22,
  panel2 = 0x1C242D,
  border = 0x34404C,
  blue = 0x3B82F6,
  cyan = 0x22D3EE,
  green = 0x22C55E,
  lime = 0x84CC16,
  yellow = 0xFACC15,
  orange = 0xF97316,
  red = 0xEF4444,
  purple = 0xA855F7,
  white = 0xF8FAFC,
  text = 0xCBD5E1,
  muted = 0x64748B,
  dark = 0x111827
}

local mode = "AUTO"
local low = 10
local high = 20
local running = true
local lastError = nil
local active = false
local enabled = false
local amount = 0
local capacity = 0
local fluidName = "--"
local lastUpdate = 0

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function safeCall(fn, ...)
  local ok, a, b, c = pcall(fn, ...)
  if ok then return true, a, b, c end
  return false, nil, nil, a
end

local function getTank()
  local ok, info, err = safeCall(gen.getTankInfo)
  if not ok then
    return 0, 0, "--", tostring(err)
  end

  -- IE 0.7.x returns the FluidTankInfo table directly.
  -- The fallback also accepts an array in case another OC/IE build wraps it.
  local tank = info
  if type(info) == "table" and info[1] and type(info[1]) == "table" then
    tank = info[1]
  end

  if type(tank) ~= "table" then
    return 0, 0, "--", "Ungültige Tankdaten"
  end

  local cap = tonumber(tank.capacity) or 0
  local fluid = tank.fluid
  local amt = 0
  local name = "--"

  if type(fluid) == "table" then
    amt = tonumber(fluid.amount) or 0
    name = tostring(fluid.name or fluid.fluid or "--")
  elseif fluid ~= nil then
    name = tostring(fluid)
  end

  return amt, cap, name, nil
end

local function setGenerator(value)
  local ok, _, _, err = safeCall(gen.setEnabled, value)
  if not ok then
    lastError = tostring(err)
    return false
  end
  enabled = value
  lastError = nil
  return true
end

local function update()
  local ok, value, _, err = safeCall(gen.isActive)
  if ok then
    active = value == true
  else
    active = false
    lastError = tostring(err)
  end

  amount, capacity, fluidName, err = getTank()
  if err then lastError = err end

  if mode == "AUTO" and capacity > 0 then
    local pct = (amount / capacity) * 100
    if pct <= low and enabled then
      setGenerator(false)
    elseif pct >= high and not enabled then
      setGenerator(true)
    end
  end

  lastUpdate = computer.uptime()
end

local function fill(x, y, w, h, bg)
  gpu.setBackground(bg)
  gpu.fill(x, y, w, h, " ")
end

local function text(x, y, s, fg, bg)
  gpu.setForeground(fg or C.text)
  if bg then gpu.setBackground(bg) end
  gpu.set(x, y, tostring(s))
end

local function panel(x, y, w, h, title)
  fill(x, y, w, h, C.panel)
  gpu.setForeground(C.border)
  gpu.setBackground(C.panel)
  gpu.fill(x, y, w, 1, "─")
  gpu.fill(x, y + h - 1, w, 1, "─")
  gpu.fill(x, y, 1, h, "│")
  gpu.fill(x + w - 1, y, 1, h, "│")
  text(x + 2, y, " " .. title .. " ", C.cyan, C.panel)
end

local function bar(x, y, w, pct, fg)
  pct = clamp(pct, 0, 100)
  local n = math.floor((w - 2) * pct / 100 + 0.5)
  gpu.setBackground(C.dark)
  gpu.fill(x, y, w, 1, " ")
  if n > 0 then
    gpu.setBackground(fg)
    gpu.fill(x + 1, y, n, 1, " ")
  end
  gpu.setBackground(C.panel)
  gpu.setForeground(C.muted)
  gpu.set(x + w + 1, y, string.format("%5.1f%%", pct))
end

local function center(y, s, fg, bg)
  local x = math.max(1, math.floor((W - #s) / 2) + 1)
  text(x, y, s, fg, bg)
end

local function draw()
  gpu.setResolution(W, H)
  gpu.setBackground(C.bg)
  gpu.setForeground(C.white)
  gpu.fill(1, 1, W, H, " ")

  gpu.setBackground(C.blue)
  gpu.fill(1, 1, W, 3, " ")
  center(2, "IMMERSIVE ENGINEERING  •  DIESEL GENERATOR", C.white, C.blue)
  center(3, "OpenComputers Control System  v" .. version, 0xDBEAFE, C.blue)

  panel(2, 5, 61, 14, "GENERATOR STATUS")
  panel(65, 5, 65, 14, "DIESEL TANK")

  local stateText = active and "RUNNING" or (enabled and "STARTING / IDLE" or "STOPPED")
  local stateColor = active and C.green or (enabled and C.yellow or C.red)
  text(5, 8, "STATUS", C.muted)
  text(5, 10, stateText, stateColor)

  text(5, 13, "CONTROL", C.muted)
  text(18, 13, mode, mode == "AUTO" and C.cyan or C.orange)
  text(5, 15, "COMMAND", C.muted)
  text(18, 15, enabled and "ENABLED" or "DISABLED", enabled and C.green or C.red)

  local pct = capacity > 0 and amount / capacity * 100 or 0
  local barColor = pct <= low and C.red or (pct < high and C.yellow or C.green)
  text(68, 8, "FUEL LEVEL", C.muted)
  bar(68, 10, 47, pct, barColor)
  text(68, 13, "FLUID", C.muted)
  text(82, 13, fluidName, C.white)
  text(68, 15, "AMOUNT", C.muted)
  text(82, 15, string.format("%d / %d mB", amount, capacity), C.white)
  text(68, 17, "THRESHOLDS", C.muted)
  text(82, 17, string.format("STOP %d%%  /  START %d%%", low, high), C.text)

  panel(2, 21, 128, 9, "AUTOMATIC CONTROL")
  text(5, 24, "Mode", C.muted)
  text(17, 24, mode, mode == "AUTO" and C.cyan or C.orange)
  text(5, 26, "AUTO", C.cyan)
  text(17, 26, "starts at " .. high .. "% and stops at " .. low .. "%", C.text)
  text(66, 26, "Manual", C.orange)
  text(78, 26, "M = ON    O = OFF", C.text)

  panel(2, 32, 128, 5, "CONTROLS")
  text(5, 34, "[A]", C.cyan)
  text(10, 34, "AUTO", C.text)
  text(25, 34, "[M]", C.green)
  text(30, 34, "ON", C.text)
  text(43, 34, "[O]", C.red)
  text(48, 34, "OFF", C.text)
  text(63, 34, "[R]", C.yellow)
  text(68, 34, "REFRESH", C.text)
  text(88, 34, "[Q]", C.red)
  text(93, 34, "QUIT", C.text)

  if lastError then
    text(5, 36, "ERROR: " .. lastError, C.red)
  else
    text(5, 36, "Last update: " .. string.format("%.1fs", computer.uptime() - lastUpdate), C.muted)
  end
end

local function setMode(newMode)
  mode = newMode
  if mode == "AUTO" then
    update()
  end
end

update()
draw()

while running do
  local e = {event.pull(0.5)}
  if e[1] == "key_down" then
    local code = e[4]
    if keyboard.isKeyDown(code) then
      -- no-op: handled below by character code where available
    end
    local char = e[3]
    if char == string.byte("a") or char == string.byte("A") then
      setMode("AUTO")
    elseif char == string.byte("m") or char == string.byte("M") then
      setMode("MANUAL")
      setGenerator(true)
    elseif char == string.byte("o") or char == string.byte("O") then
      setMode("MANUAL")
      setGenerator(false)
    elseif char == string.byte("r") or char == string.byte("R") then
      update()
    elseif char == string.byte("q") or char == string.byte("Q") then
      running = false
    end
  end

  if computer.uptime() - lastUpdate >= 1 then
    update()
  end
  draw()
end

-- Leave the generator disabled when the control program exits.
setGenerator(false)
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, W, H, " ")
center(math.floor(H / 2), "Diesel Generator Control beendet.", C.text, 0x000000)
