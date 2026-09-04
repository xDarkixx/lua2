-- ReactorBigReactors043A_Touch.lua
-- Legacy-compatible touchscreen controller for:
--   Minecraft 1.7.10
--   BigReactors 0.4.3A
--   OpenComputers MC1.7.10-1.8.10+667626d
--
-- Built from the working legacy Reactor.lua API and adapted for touchscreen use.
-- The legacy Big Reactors Computer Port API is intentionally preferred.

local component = require("component")
local event = require("event")
local keyboard = require("keyboard")

local gpu = component.gpu
local W, H = 132, 38
local VERSION = "1.1.0-BR043A"

local C = {
  bg = 0x000000, panel = 0x151515, panel2 = 0x252525,
  border = 0x47494C, blue = 0x4286F4, purple = 0xB673D6,
  red = 0xC14141, green = 0x00DA41, yellow = 0xFFDB4D,
  white = 0xFFFFFF, grey = 0x47494C, lightGray = 0xBBBBBB,
  lightBlue = 0x66D9FF, lime = 0x80CD32, orange = 0xFF9900
}

local reactors = {}
local management = {}
local turbines = {}
local selected = 1
local rod = 0 -- Big Reactors 0.4.3A control-rod indexes are used as 0-based indexes.
local screen = "main"
local auto = false
local running = true

local MIN_POWER = 5000000
local MAX_POWER = 9000000
local MAX_STEAM = 50000
local MIN_STEAM = MAX_STEAM / 2
local lastPower = 0

local function clamp(v, lo, hi)
  v = tonumber(v) or 0
  if v < lo then return lo end
  if v > hi then return hi end
  return v
end

local function call(obj, name, fallback, ...)
  if not obj then return fallback end
  local f = obj[name]
  if type(f) ~= "function" then return fallback end
  local ok, value = pcall(f, ...)
  if ok and value ~= nil then return value end
  return fallback
end

local function invoke(obj, name, ...)
  if not obj then return false end
  local f = obj[name]
  if type(f) ~= "function" then return false end
  local ok = pcall(f, ...)
  return ok
end

local function fmt(v)
  v = math.floor(tonumber(v) or 0)
  if math.abs(v) >= 1000000000 then return string.format("%.2fG", v / 1000000000) end
  if math.abs(v) >= 1000000 then return string.format("%.2fM", v / 1000000) end
  if math.abs(v) >= 1000 then return string.format("%.1fk", v / 1000) end
  return tostring(v)
end

local function clear()
  gpu.setBackground(C.bg)
  gpu.setForeground(C.white)
  gpu.fill(1, 1, W, H, " ")
end

local function fill(x, y, w, h, color)
  gpu.setBackground(color)
  gpu.fill(x, y, w, h, " ")
end

local function text(x, y, value, fg, bg)
  if y < 1 or y > H then return end
  gpu.setBackground(bg or C.bg)
  gpu.setForeground(fg or C.white)
  gpu.set(x, y, tostring(value))
end

local function bar(x, y, w, value, maximum, color)
  maximum = math.max(tonumber(maximum) or 1, 1)
  value = clamp(value, 0, maximum)
  local n = math.floor((value / maximum) * w)
  fill(x, y, w, 1, C.panel2)
  if n > 0 then fill(x, y, n, 1, color or C.blue) end
end

local function button(x, y, w, label, color, active)
  local bg = active and C.green or (color or C.blue)
  fill(x, y, w, 3, bg)
  local s = tostring(label)
  if #s > w - 2 then s = s:sub(1, w - 2) end
  local px = x + math.max(1, math.floor((w - #s) / 2))
  text(px, y + 1, s, C.white, bg)
end

local function smallButton(x, y, w, label, color, active)
  local bg = active and C.green or (color or C.blue)
  fill(x, y, w, 1, bg)
  local s = tostring(label)
  if #s > w then s = s:sub(1, w) end
  text(x + math.max(0, math.floor((w - #s) / 2)), y, s, C.white, bg)
end

local function panel(x, y, w, h, title, accent)
  fill(x, y, w, h, C.panel)
  fill(x, y, w, 1, accent or C.blue)
  text(x + 2, y, "[ " .. title .. " ]", C.white, accent or C.blue)
  fill(x, y + h - 1, w, 1, C.border)
  fill(x, y, 1, h, C.border)
  fill(x + w - 1, y, 1, h, C.border)
end

local function discover()
  reactors = {}
  management = {}
  turbines = {}

  for address in component.list("br_reactor") do
    local r = component.proxy(address)
    if r then
      reactors[#reactors + 1] = r
      management[#management + 1] = true
    end
  end

  for address in component.list("br_turbine") do
    local t = component.proxy(address)
    if t then turbines[#turbines + 1] = t end
  end

  if selected > #reactors then selected = math.max(1, #reactors) end
  if #reactors == 0 then rod = 0 return end

  local count = tonumber(call(reactors[selected], "getNumberOfControlRods", 0)) or 0
  if count <= 0 then rod = 0
  elseif rod >= count then rod = count - 1 end
end

discover()

local function reactor()
  return reactors[selected]
end

local function cooled(r)
  return call(r, "isActivelyCooled", false) == true
end

local function setActive(r, state)
  return invoke(r, "setActive", state)
end

local function setAllRods(r, level)
  level = math.floor(clamp(level, 0, 100))
  return invoke(r, "setAllControlRodLevels", level)
end

local function setRod(r, index, level)
  level = math.floor(clamp(level, 0, 100))
  -- Big Reactors 0.4.3A exposes get/set control rod levels through the Computer Port.
  -- Prefer the per-rod method when available; otherwise use all rods.
  if type(r.setControlRodLevel) == "function" then
    return invoke(r, "setControlRodLevel", index, level)
  end
  return setAllRods(r, level)
end

local function rodLevel(r, index)
  -- Legacy MJRLegends code uses getControlRodLevel(0), so keep this 0-based.
  return tonumber(call(r, "getControlRodLevel", 0, index)) or 0
end

local function nextReactor(delta)
  if #reactors == 0 then return end
  selected = selected + delta
  if selected < 1 then selected = #reactors end
  if selected > #reactors then selected = 1 end
  rod = 0
end

local function header(title)
  fill(1, 1, W, 4, C.panel)
  text(3, 2, "MJRLEGENDS REACTOR", C.blue, C.panel)
  text(24, 2, "|", C.border, C.panel)
  text(27, 2, title, C.white, C.panel)
  text(87, 2, "v" .. VERSION, C.lightGray, C.panel)
  if #reactors > 0 then
    text(105, 2, "UNIT " .. selected .. "/" .. #reactors, C.yellow, C.panel)
  else
    text(103, 2, "NO REACTOR", C.red, C.panel)
  end
  fill(1, 4, W, 1, C.blue)
end

local function footer()
  fill(1, 35, W, 4, C.panel)
  button(2, 35, 20, "MAIN", C.purple, screen == "main")
  button(24, 35, 20, "INFO", C.blue, screen == "info")
  button(46, 35, 20, "RODS", C.orange, screen == "rods")
  button(68, 35, 20, "REFRESH", C.lightBlue, false)
  button(90, 35, 20, auto and "AUTO ON" or "AUTO OFF", C.green, auto)
  button(112, 35, 18, "EXIT", C.red, false)
end

local function drawMain()
  clear(); header("SYSTEM OVERVIEW")
  local online, activeCooling = 0, 0
  local energy, steam, fuel, fuelMax, waste = 0, 0, 0, 0, 0

  for _, r in ipairs(reactors) do
    if call(r, "getActive", false) then online = online + 1 end
    if cooled(r) then
      activeCooling = activeCooling + 1
      steam = steam + math.floor(call(r, "getHotFluidAmount", 0))
    else
      energy = energy + math.floor(call(r, "getEnergyStored", 0))
    end
    fuel = fuel + math.floor(call(r, "getFuelAmount", 0))
    fuelMax = fuelMax + math.floor(call(r, "getFuelAmountMax", 0))
    waste = waste + math.floor(call(r, "getWasteAmount", 0))
  end

  panel(3, 6, 41, 12, "REACTORS", C.blue)
  text(6, 8, "DETECTED", C.lightGray, C.panel); text(25, 8, #reactors, C.white, C.panel)
  text(6, 10, "ONLINE", C.lightGray, C.panel); text(25, 10, online .. " / " .. #reactors, C.green, C.panel)
  bar(6, 11, 32, online, math.max(#reactors, 1), C.green)
  text(6, 14, "ACTIVE COOLING", C.lightGray, C.panel); text(25, 14, activeCooling .. " / " .. #reactors, C.lightBlue, C.panel)
  text(6, 16, "TURBINES", C.lightGray, C.panel); text(25, 16, #turbines, C.purple, C.panel)

  panel(47, 6, 82, 12, "ENERGY / STEAM", C.lightBlue)
  text(50, 8, "ENERGY", C.lightGray, C.panel); text(72, 8, fmt(energy) .. " RF", C.white, C.panel)
  bar(50, 9, 74, energy, math.max(10000000 * math.max(#reactors, 1), 1), C.red)
  text(50, 12, "STEAM", C.lightGray, C.panel); text(72, 12, fmt(steam) .. " mb", C.white, C.panel)
  bar(50, 13, 74, steam, math.max(MAX_STEAM * math.max(activeCooling, 1), 1), C.lightBlue)
  text(50, 16, "AUTO", C.lightGray, C.panel); text(72, 16, auto and "ENABLED" or "DISABLED", auto and C.green or C.red, C.panel)

  panel(3, 20, 61, 12, "FUEL / WASTE", C.yellow)
  text(6, 22, "FUEL", C.lightGray, C.panel); text(27, 22, fmt(fuel) .. " / " .. fmt(fuelMax) .. " mb", C.yellow, C.panel)
  bar(6, 23, 54, fuel, math.max(fuelMax, 1), C.yellow)
  text(6, 25, "WASTE", C.lightGray, C.panel); text(27, 25, fmt(waste) .. " mb", C.blue, C.panel)
  bar(6, 26, 54, waste, math.max(fuelMax, 1), C.blue)
  text(6, 29, "THRESHOLDS", C.lightGray, C.panel); text(27, 29, MIN_POWER .. " / " .. MAX_POWER .. " RF", C.white, C.panel)

  panel(67, 20, 62, 12, "TOUCH MENU", C.purple)
  button(70, 22, 25, "REACTOR INFO", C.blue, false)
  button(98, 22, 25, "CONTROL RODS", C.orange, false)
  button(70, 27, 25, "PREVIOUS", C.blue, false)
  button(98, 27, 25, "NEXT", C.blue, false)
  footer()
end

local function drawInfo()
  clear(); header("REACTOR INFORMATION")
  if #reactors == 0 then
    text(42, 18, "No br_reactor Computer Port detected.", C.red, C.bg)
    footer(); return
  end
  local r = reactor()
  local active = call(r, "getActive", false)
  local isCool = cooled(r)
  local casing = math.floor(call(r, "getCasingTemperature", 0))
  local fuelTemp = math.floor(call(r, "getFuelTemperature", 0))
  local energy = math.floor(call(r, "getEnergyStored", 0))
  local fuel = math.floor(call(r, "getFuelAmount", 0))
  local fuelMax = math.floor(call(r, "getFuelAmountMax", 1))
  local waste = math.floor(call(r, "getWasteAmount", 0))
  local output = math.floor(call(r, "getEnergyProducedLastTick", 0))
  local consumed = call(r, "getFuelConsumedLastTick", 0)

  panel(3, 6, 62, 25, "THERMAL / POWER", C.orange)
  text(6, 8, "STATUS", C.lightGray, C.panel); text(25, 8, active and "ONLINE" or "OFFLINE", active and C.green or C.red, C.panel)
  text(6, 10, "CASING HEAT", C.lightGray, C.panel); text(25, 10, casing .. " C", C.white, C.panel)
  bar(6, 11, 54, casing, 5000, casing >= 1500 and C.red or casing >= 1000 and C.yellow or C.lightBlue)
  text(6, 13, "FUEL HEAT", C.lightGray, C.panel); text(25, 13, fuelTemp .. " C", C.white, C.panel)
  bar(6, 14, 54, fuelTemp, 5000, fuelTemp >= 1500 and C.red or fuelTemp >= 1000 and C.yellow or C.lightBlue)
  text(6, 16, "MODE", C.lightGray, C.panel); text(25, 16, isCool and "ACTIVE COOLING" or "PASSIVE", C.lightBlue, C.panel)
  text(6, 19, isCool and "STEAM" or "POWER", C.lightGray, C.panel); text(25, 19, fmt(output) .. (isCool and " mb/t" or " RF/t"), C.yellow, C.panel)
  text(6, 21, "FUEL USE", C.lightGray, C.panel); text(25, 21, tostring(consumed) .. " mB/t", C.white, C.panel)
  text(6, 24, "ENERGY", C.lightGray, C.panel); text(25, 24, fmt(energy) .. " RF", C.cyan, C.panel)
  text(6, 26, "FUEL", C.lightGray, C.panel); text(25, 26, fmt(fuel) .. " / " .. fmt(fuelMax) .. " mb", C.yellow, C.panel)
  text(6, 28, "WASTE", C.lightGray, C.panel); text(25, 28, fmt(waste) .. " mb", C.blue, C.panel)

  panel(67, 6, 62, 25, "REACTOR CONTROL", C.blue)
  text(70, 8, "SELECTED", C.lightGray, C.panel); text(94, 8, selected .. " / " .. #reactors, C.white, C.panel)
  button(70, 11, 23, "< PREVIOUS", C.blue, false)
  button(100, 11, 23, "NEXT >", C.blue, false)
  button(70, 16, 23, "START", C.green, active)
  button(100, 16, 23, "STOP", C.red, not active)
  button(70, 21, 23, auto and "AUTO ON" or "AUTO OFF", C.green, auto)
  button(100, 21, 23, "RESCAN", C.lightBlue, false)
  text(70, 26, "BigReactors 0.4.3A API", C.yellow, C.panel)
  text(70, 28, "OpenComputers 1.8.10", C.lightGray, C.panel)
  text(70, 29, "+667626d", C.lightGray, C.panel)
  footer()
end

local function drawRods()
  clear(); header("CONTROL RODS")
  if #reactors == 0 then text(42, 18, "No br_reactor Computer Port detected.", C.red, C.bg); footer(); return end
  local r = reactor()
  local count = tonumber(call(r, "getNumberOfControlRods", 0)) or 0
  if count <= 0 then text(42, 18, "No control rods reported.", C.yellow, C.bg); footer(); return end
  rod = clamp(rod, 0, count - 1)
  local level = rodLevel(r, rod)

  panel(3, 6, 126, 25, "CONTROL ROD " .. rod .. " / " .. (count - 1), C.orange)
  text(7, 9, "INSERTION", C.lightGray, C.panel); text(30, 9, math.floor(level) .. " %", C.yellow, C.panel)
  bar(7, 11, 112, level, 100, level >= 80 and C.red or C.yellow)
  button(8, 15, 25, "-10", C.blue, false)
  button(36, 15, 25, "-1", C.blue, false)
  button(66, 15, 25, "+1", C.orange, false)
  button(94, 15, 25, "+10", C.orange, false)
  button(8, 21, 25, "PREVIOUS ROD", C.purple, false)
  button(36, 21, 25, "NEXT ROD", C.purple, false)
  button(66, 21, 25, "ALL 0%", C.green, false)
  button(94, 21, 25, "ALL 100%", C.red, false)
  text(8, 27, "Legacy-compatible: getControlRodLevel(index) + setAllControlRodLevels(level).", C.lightGray, C.panel)
  text(8, 29, "Index starts at 0, matching the original working Reactor.lua.", C.yellow, C.panel)
  footer()
end

local function manageAuto()
  if not auto or #reactors == 0 then return end
  for i, r in ipairs(reactors) do
    local active = call(r, "getActive", false)
    if cooled(r) then
      local steam = tonumber(call(r, "getHotFluidAmount", 0)) or 0
      if steam >= MAX_STEAM then
        setActive(r, false)
      elseif steam <= MIN_STEAM then
        setActive(r, true)
      end
    else
      local energy = tonumber(call(r, "getEnergyStored", 0)) or 0
      if energy >= MAX_POWER then
        setActive(r, false)
      elseif energy <= MIN_POWER then
        setActive(r, true)
      end
    end
    management[i] = true
    -- Preserve the original MJR-style behavior: active reactors run with rods fully open.
    if active or call(r, "getActive", false) then
      setAllRods(r, 0)
    end
  end
end

local function touch(x, y)
  if y >= 35 then
    if x >= 2 and x < 22 then screen = "main"
    elseif x >= 24 and x < 44 then screen = "info"
    elseif x >= 46 and x < 66 then screen = "rods"
    elseif x >= 68 and x < 88 then discover()
    elseif x >= 90 and x < 110 then auto = not auto
    elseif x >= 112 then running = false end
    return
  end

  if screen == "main" then
    if y >= 22 and y <= 24 and x >= 70 and x <= 95 then screen = "info"
    elseif y >= 22 and y <= 24 and x >= 98 and x <= 124 then screen = "rods"
    elseif y >= 27 and y <= 29 and x >= 70 and x <= 95 then nextReactor(-1)
    elseif y >= 27 and y <= 29 and x >= 98 and x <= 124 then discover() end

  elseif screen == "info" then
    if #reactors == 0 then return end
    local r = reactor()
    if y >= 11 and y <= 13 and x >= 70 and x <= 93 then nextReactor(-1)
    elseif y >= 11 and y <= 13 and x >= 100 and x <= 123 then nextReactor(1)
    elseif y >= 16 and y <= 18 and x >= 70 and x <= 93 then setActive(r, true)
    elseif y >= 16 and y <= 18 and x >= 100 and x <= 123 then setActive(r, false)
    elseif y >= 21 and y <= 23 and x >= 70 and x <= 93 then auto = not auto
    elseif y >= 21 and y <= 23 and x >= 100 and x <= 123 then discover() end

  elseif screen == "rods" then
    if #reactors == 0 then return end
    local r = reactor()
    local count = tonumber(call(r, "getNumberOfControlRods", 0)) or 0
    if count <= 0 then return end
    rod = clamp(rod, 0, count - 1)
    local level = rodLevel(r, rod)
    if y >= 15 and y <= 17 then
      if x >= 8 and x <= 33 then setRod(r, rod, level - 10)
      elseif x >= 36 and x <= 61 then setRod(r, rod, level - 1)
      elseif x >= 66 and x <= 91 then setRod(r, rod, level + 1)
      elseif x >= 94 and x <= 119 then setRod(r, rod, level + 10) end
    elseif y >= 21 and y <= 23 then
      if x >= 8 and x <= 33 then rod = (rod - 1) % count
      elseif x >= 36 and x <= 61 then rod = (rod + 1) % count
      elseif x >= 66 and x <= 91 then setAllRods(r, 0)
      elseif x >= 94 and x <= 119 then setAllRods(r, 100) end
    end
  end
end

local function draw()
  if screen == "main" then drawMain()
  elseif screen == "info" then drawInfo()
  elseif screen == "rods" then drawRods()
  else screen = "main"; drawMain() end
end

-- Initial screen
draw()

while running do
  manageAuto()
  draw()
  local e, address, a, b = event.pull(0.5)
  if e == "touch" then
    touch(a, b)
  elseif e == "key_down" then
    -- OpenComputers key_down: event, keyboard address, character, key code, player.
    local char = a
    if char == string.byte("q") or char == string.byte("Q") then
      running = false
    elseif char == string.byte("r") or char == string.byte("R") then
      discover()
    elseif char == 15 then -- TAB
      if screen == "main" then screen = "info"
      elseif screen == "info" then screen = "rods"
      else screen = "main" end
    end
  end
end

-- Safety: leave reactors in their current state; no forced shutdown is performed on exit.
clear()
text(49, 19, "Reactor controller stopped.", C.yellow, C.bg)
