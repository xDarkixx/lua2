-- Immersive Engineering Diesel Generator Manager
-- Minecraft 1.7.10 / ImmersiveEngineering 0.7.7
-- OpenComputers 1.8.10
--
-- Requires an OpenComputers Adapter on a Diesel Generator control/redstone position.
-- Component: ie_diesel_generator
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

local gpu = component.gpu
local gen = component.ie_diesel_generator

if not gen then
  error("Kein ie_diesel_generator gefunden. Adapter an den Steueranschluss setzen.")
end

local W, H = 132, 38
local version = "2.0.0"

-- OpenComputers 16/256-color friendly palette.
local C = {
  bg = 0x080B10,
  panel = 0x111722,
  panel2 = 0x182131,
  border = 0x334155,
  blue = 0x2563EB,
  cyan = 0x06B6D4,
  green = 0x16A34A,
  lime = 0x65A30D,
  yellow = 0xEAB308,
  orange = 0xEA580C,
  red = 0xDC2626,
  purple = 0x9333EA,
  white = 0xF8FAFC,
  text = 0xCBD5E1,
  muted = 0x64748B,
  dark = 0x030712,
  black = 0x000000
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

local function fill(x, y, w, h, bg)
  gpu.setBackground(bg)
  gpu.fill(x, y, w, h, " ")
end

local function text(x, y, s, fg, bg)
  gpu.setForeground(fg or C.text)
  if bg then gpu.setBackground(bg) end
  gpu.set(x, y, tostring(s))
end

local function centered(y, s, fg, bg)
  s = tostring(s)
  local x = math.max(1, math.floor((W - #s) / 2) + 1)
  text(x, y, s, fg, bg)
end

local function box(x, y, w, h, title, accent)
  fill(x, y, w, h, C.panel)
  gpu.setBackground(C.panel)
  gpu.setForeground(C.border)
  gpu.fill(x, y, w, 1, "─")
  gpu.fill(x, y + h - 1, w, 1, "─")
  gpu.fill(x, y, 1, h, "│")
  gpu.fill(x + w - 1, y, 1, h, "│")
  gpu.setBackground(accent or C.blue)
  gpu.fill(x, y, 1, h, " ")
  text(x + 3, y, " " .. title .. " ", accent or C.cyan, C.panel)
end

local function solidBar(x, y, w, pct, fg, bg)
  pct = clamp(pct, 0, 100)
  fill(x, y, w, 3, bg or C.dark)
  local inner = w - 2
  local filled = math.floor(inner * pct / 100 + 0.5)
  if filled > 0 then
    gpu.setBackground(fg)
    gpu.fill(x + 1, y, filled, 3, " ")
  end
end

local function segmentedBar(x, y, segments, pct, fg, bg)
  pct = clamp(pct, 0, 100)
  local filled = math.floor(segments * pct / 100 + 0.5)
  for i = 1, segments do
    gpu.setBackground(i <= filled and fg or bg)
    gpu.fill(x + (i - 1) * 2, y, 1, 1, " ")
  end
end

local function getTank()
  local ok, info, _, err = safeCall(gen.getTankInfo)
  if not ok then
    return 0, 0, "--", tostring(err)
  end

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
    local pct = amount / capacity * 100
    if pct <= low and enabled then
      setGenerator(false)
    elseif pct >= high and not enabled then
      setGenerator(true)
    end
  end

  lastUpdate = computer.uptime()
end

local function setMode(newMode)
  mode = newMode
  if mode == "AUTO" then update() end
end

local function draw()
  gpu.setResolution(W, H)
  gpu.setBackground(C.bg)
  gpu.setForeground(C.white)
  gpu.fill(1, 1, W, H, " ")

  -- Header
  gpu.setBackground(C.blue)
  gpu.fill(1, 1, W, 4, " ")
  centered(2, "IMMERSIVE ENGINEERING  •  DIESEL GENERATOR", C.white, C.blue)
  centered(3, "OPENCOMPUTERS CONTROL PANEL  v" .. version, 0xBFDBFE, C.blue)
  centered(4, "MC 1.7.10  •  IE 0.7.7  •  OC 1.8.10", 0xDBEAFE, C.blue)

  local pct = capacity > 0 and amount / capacity * 100 or 0
  local fuelColor = pct <= low and C.red or (pct < high and C.yellow or C.green)
  local stateText = active and "RUNNING" or (enabled and "ENABLED / IDLE" or "STOPPED")
  local stateColor = active and C.green or (enabled and C.yellow or C.red)

  -- Main status panel
  box(2, 6, 62, 14, "GENERATOR STATUS", stateColor)
  text(6, 8, "CURRENT STATE", C.muted)
  text(6, 10, "●  " .. stateText, stateColor)
  text(6, 13, "CONTROL MODE", C.muted)
  text(22, 13, mode, mode == "AUTO" and C.cyan or C.orange)
  text(6, 15, "COMMAND", C.muted)
  text(22, 15, enabled and "● ENABLED" or "● DISABLED", enabled and C.green or C.red)
  text(6, 17, "COMPONENT", C.muted)
  text(22, 17, "ie_diesel_generator", C.purple)
  segmentedBar(6, 19, 25, active and 100 or (enabled and 45 or 0), stateColor, C.dark)

  -- Fuel panel
  box(66, 6, 64, 14, "DIESEL TANK", fuelColor)
  text(70, 8, "FUEL LEVEL", C.muted)
  text(115, 8, string.format("%5.1f%%", pct), fuelColor)
  solidBar(70, 10, 54, pct, fuelColor, C.dark)
  text(70, 14, "FLUID", C.muted)
  text(84, 14, fluidName, C.white)
  text(70, 16, "AMOUNT", C.muted)
  text(84, 16, string.format("%d / %d mB", amount, capacity), C.white)
  text(70, 18, "LEVEL", C.muted)
  text(84, 18, pct <= low and "CRITICAL" or (pct < high and "LOW" or "GOOD"), fuelColor)

  -- Automatic control
  box(2, 22, 128, 7, "AUTOMATIC CONTROL", C.cyan)
  text(6, 24, "STOP", C.muted)
  text(17, 24, low .. "%", C.red)
  segmentedBar(22, 24, 35, low, C.red, C.dark)
  text(64, 24, "START", C.muted)
  text(76, 24, high .. "%", C.green)
  segmentedBar(81, 24, 35, high, C.green, C.dark)
  text(6, 27, "AUTO: generator OFF at <= " .. low .. "%   |   ON at >= " .. high .. "%", C.text)

  -- Controls
  box(2, 31, 128, 6, "CONTROLS", C.blue)
  text(6, 33, "[A]", C.cyan);   text(11, 33, "AUTO", C.text)
  text(27, 33, "[M]", C.green);  text(32, 33, "MANUAL ON", C.text)
  text(51, 33, "[O]", C.red);    text(56, 33, "MANUAL OFF", C.text)
  text(80, 33, "[R]", C.yellow); text(85, 33, "REFRESH", C.text)
  text(103, 33, "[Q]", C.red);   text(108, 33, "QUIT", C.text)

  if lastError then
    text(6, 36, "ERROR: " .. lastError, C.red)
  else
    text(6, 36, "● ONLINE   •   Last update " .. string.format("%.1fs", computer.uptime() - lastUpdate) .. " ago", C.muted)
  end
end

update()
draw()

while running do
  local e = {event.pull(0.5)}
  if e[1] == "key_down" then
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

setGenerator(false)
gpu.setBackground(C.black)
gpu.setForeground(C.white)
gpu.fill(1, 1, W, H, " ")
centered(math.floor(H / 2), "Diesel Generator Control beendet.", C.text, C.black)
