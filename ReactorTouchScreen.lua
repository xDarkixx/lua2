-- ReactorTouchScreen.lua
-- New touchscreen version based on Reactor.lua
-- OpenComputers / Big Reactors / Extreme Reactors
-- Requires a Tier 2 or Tier 3 touchscreen screen.

local component = require("component")
local event = require("event")
local keyboard = require("keyboard")

local gpu = component.gpu
local W, H = 132, 38
local version = "1.0.0"

local C = {
  bg = 0x0B0F14, panel = 0x151B22, panel2 = 0x1C242D,
  border = 0x34404C, blue = 0x3B82F6, cyan = 0x22D3EE,
  green = 0x22C55E, yellow = 0xFACC15, orange = 0xF97316,
  red = 0xEF4444, purple = 0xA855F7, white = 0xF8FAFC,
  text = 0xCBD5E1, muted = 0x64748B
}

gpu.setResolution(W, H)
local reactors = {}
local selected = 1
local screen = "dashboard"
local rod = 0
local auto = false
local running = true

local function call(r, method, fallback, ...)
  local f = r and r[method]
  if type(f) ~= "function" then return fallback end
  local ok, a = pcall(f, ...)
  if ok and a ~= nil then return a end
  return fallback
end

local function setcall(r, method, ...)
  local f = r and r[method]
  if type(f) ~= "function" then return false end
  local ok = pcall(f, ...)
  return ok
end

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
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

local function box(x, y, w, h, bg)
  gpu.setBackground(bg or C.panel)
  gpu.fill(x, y, w, h, " ")
end

local function txt(x, y, s, fg, bg)
  if y < 1 or y > H then return end
  gpu.setBackground(bg or C.bg)
  gpu.setForeground(fg or C.text)
  gpu.set(x, y, tostring(s))
end

local function button(x, y, w, label, bg, active)
  local c = active and C.green or (bg or C.blue)
  box(x, y, w, 3, c)
  local s = tostring(label)
  if #s > w - 2 then s = s:sub(1, w - 2) end
  local px = x + math.max(1, math.floor((w - #s) / 2))
  txt(px, y + 1, s, C.white, c)
end

local function small(x, y, w, label, bg)
  box(x, y, w, 1, bg or C.blue)
  local s = tostring(label)
  if #s > w then s = s:sub(1, w) end
  txt(x + math.max(0, math.floor((w - #s) / 2)), y, s, C.white, bg or C.blue)
end

local function bar(x, y, w, value, maximum, fg)
  maximum = math.max(tonumber(maximum) or 1, 1)
  value = clamp(tonumber(value) or 0, 0, maximum)
  local n = math.floor(value / maximum * w)
  box(x, y, w, 1, C.panel2)
  if n > 0 then box(x, y, n, 1, fg or C.blue) end
end

local function panel(x, y, w, h, title, accent)
  box(x, y, w, h, C.panel)
  box(x, y, w, 1, accent or C.blue)
  txt(x + 2, y, "[ " .. title .. " ]", C.white, accent or C.blue)
  box(x, y + h - 1, w, 1, C.border)
end

local function discover()
  reactors = {}
  for addr in component.list("br_reactor") do
    local r = component.proxy(addr)
    if r then reactors[#reactors + 1] = r end
  end
  if selected > #reactors then selected = math.max(#reactors, 1) end
  if rod > 0 then
    local count = #reactors > 0 and tonumber(call(reactors[selected], "getNumberOfControlRods", 0)) or 0
    if rod > count then rod = count end
  end
end

discover()

local function activeReactor()
  return reactors[selected]
end

local function header(title)
  box(1, 1, W, 4, C.panel)
  txt(3, 2, "REACTOR CONTROL", C.cyan, C.panel)
  txt(24, 2, "|", C.border, C.panel)
  txt(27, 2, title, C.white, C.panel)
  txt(92, 2, "v" .. version, C.muted, C.panel)
  if #reactors > 0 then
    txt(106, 2, "UNIT " .. selected .. "/" .. #reactors, C.yellow, C.panel)
  else
    txt(106, 2, "NO REACTOR", C.red, C.panel)
  end
  box(1, 4, W, 1, C.blue)
end

local function footer()
  box(1, 35, W, 4, C.panel)
  button(3, 35, 20, "DASHBOARD", C.purple, screen == "dashboard")
  button(25, 35, 20, "CONTROL", C.blue, screen == "control")
  button(47, 35, 20, "RODS", C.orange, screen == "rods")
  button(69, 35, 20, "REFRESH", C.cyan, false)
  button(91, 35, 20, auto and "AUTO ON" or "AUTO OFF", C.green, auto)
  button(113, 35, 16, "EXIT", C.red, false)
end

local function drawDashboard()
  clear(); header("SYSTEM DASHBOARD")
  local online, energy, fuel, fuelMax, waste, temp = 0, 0, 0, 0, 0, 0
  for i, r in ipairs(reactors) do
    if call(r, "getActive", false) then online = online + 1 end
    energy = energy + tonumber(call(r, "getEnergyStored", 0))
    fuel = fuel + tonumber(call(r, "getFuelAmount", 0))
    fuelMax = fuelMax + tonumber(call(r, "getFuelAmountMax", 0))
    waste = waste + tonumber(call(r, "getWasteAmount", 0))
    temp = temp + tonumber(call(r, "getFuelTemperature", 0))
  end
  if #reactors > 0 then temp = temp / #reactors end

  panel(3, 6, 41, 12, "REACTOR STATUS", C.blue)
  txt(6, 8, "DETECTED", C.muted, C.panel); txt(25, 8, #reactors, C.white, C.panel)
  txt(6, 10, "ONLINE", C.muted, C.panel); txt(25, 10, online .. " / " .. #reactors, C.green, C.panel)
  bar(6, 11, 32, online, math.max(#reactors, 1), C.green)
  txt(6, 14, "SELECTED", C.muted, C.panel); txt(25, 14, #reactors > 0 and selected or "--", C.cyan, C.panel)
  txt(6, 16, "AUTO", C.muted, C.panel); txt(25, 16, auto and "ENABLED" or "DISABLED", auto and C.green or C.red, C.panel)

  panel(47, 6, 82, 12, "ENERGY", C.cyan)
  txt(50, 8, "BUFFER", C.muted, C.panel); txt(72, 8, fmt(energy) .. " RF", C.white, C.panel)
  bar(50, 9, 74, energy, math.max(#reactors * 10000000, 1), C.cyan)
  txt(50, 12, "FUEL", C.muted, C.panel); txt(72, 12, fmt(fuel) .. " mb", C.yellow, C.panel)
  bar(50, 13, 74, fuel, math.max(fuelMax, 1), C.yellow)
  txt(50, 16, "WASTE", C.muted, C.panel); txt(72, 16, fmt(waste) .. " mb", C.white, C.panel)

  panel(3, 20, 61, 12, "FUEL / TEMPERATURE", C.orange)
  txt(6, 22, "FUEL", C.muted, C.panel); txt(28, 22, fmt(fuel) .. " / " .. fmt(fuelMax) .. " mb", C.yellow, C.panel)
  bar(6, 23, 54, fuel, math.max(fuelMax, 1), C.yellow)
  txt(6, 25, "AVERAGE CORE", C.muted, C.panel); txt(28, 25, math.floor(temp) .. " C", C.orange, C.panel)
  bar(6, 26, 54, temp, 3000, temp > 1500 and C.red or C.orange)
  txt(6, 29, "WASTE", C.muted, C.panel); txt(28, 29, fmt(waste) .. " mb", C.blue, C.panel)

  panel(67, 20, 62, 12, "TOUCH ACTIONS", C.purple)
  button(70, 22, 25, "REACTOR CONTROL", C.blue, false)
  button(98, 22, 25, "CONTROL RODS", C.orange, false)
  button(70, 27, 25, "NEXT REACTOR", C.cyan, false)
  button(98, 27, 25, "REFRESH", C.cyan, false)
  footer()
end

local function drawControl()
  clear(); header("REACTOR CONTROL")
  if #reactors == 0 then txt(42, 18, "No br_reactor component found.", C.red, C.bg); footer(); return end
  local r = activeReactor()
  local active = call(r, "getActive", false)
  local temp = tonumber(call(r, "getFuelTemperature", 0))
  local casing = tonumber(call(r, "getCasingTemperature", 0))
  local energy = tonumber(call(r, "getEnergyStored", 0))
  local fuel = tonumber(call(r, "getFuelAmount", 0))
  local maxFuel = tonumber(call(r, "getFuelAmountMax", 1))

  panel(3, 6, 61, 25, "SELECTED REACTOR", C.blue)
  txt(6, 8, "STATUS", C.muted, C.panel); txt(25, 8, active and "ONLINE" or "OFFLINE", active and C.green or C.red, C.panel)
  txt(6, 10, "CORE", C.muted, C.panel); txt(25, 10, math.floor(temp) .. " C", C.orange, C.panel); bar(6, 11, 54, temp, 3000, temp > 1500 and C.red or C.orange)
  txt(6, 14, "CASING", C.muted, C.panel); txt(25, 14, math.floor(casing) .. " C", C.yellow, C.panel); bar(6, 15, 54, casing, 2000, casing > 1200 and C.red or C.yellow)
  txt(6, 18, "ENERGY", C.muted, C.panel); txt(25, 18, fmt(energy) .. " RF", C.cyan, C.panel)
  txt(6, 20, "FUEL", C.muted, C.panel); txt(25, 20, fmt(fuel) .. " / " .. fmt(maxFuel) .. " mb", C.yellow, C.panel); bar(6, 21, 54, fuel, math.max(maxFuel, 1), C.yellow)
  button(8, 24, 23, "START", C.green, active)
  button(34, 24, 23, "STOP", C.red, not active)
  small(8, 28, 49, "Touch START / STOP", C.panel2)

  panel(67, 6, 62, 25, "REACTOR SELECTOR", C.purple)
  txt(70, 8, "CURRENT UNIT", C.muted, C.panel); txt(95, 8, selected .. " / " .. #reactors, C.white, C.panel)
  button(71, 11, 23, "< PREVIOUS", C.blue, false)
  button(100, 11, 23, "NEXT >", C.blue, false)
  txt(70, 16, "AUTO MANAGEMENT", C.muted, C.panel)
  button(71, 18, 23, auto and "AUTO: ON" or "AUTO: OFF", C.green, auto)
  button(100, 18, 23, "RESCAN", C.cyan, false)
  txt(70, 23, "AUTO adjusts rods only when enabled.", C.text, C.panel)
  txt(70, 25, "It never enables AUTO by itself.", C.muted, C.panel)
  footer()
end

local function drawRods()
  clear(); header("CONTROL RODS")
  if #reactors == 0 then txt(42, 18, "No br_reactor component found.", C.red, C.bg); footer(); return end
  local r = activeReactor()
  local count = tonumber(call(r, "getNumberOfControlRods", 0)) or 0
  if count < 1 then txt(42, 18, "No control rods reported by reactor.", C.yellow, C.bg); footer(); return end
  rod = clamp(rod, 1, count)
  local level = tonumber(call(r, "getControlRodLevel", 0, rod)) or 0
  panel(3, 6, 126, 25, "ROD " .. rod .. " / " .. count, C.orange)
  txt(7, 9, "INSERTION", C.muted, C.panel); txt(28, 9, math.floor(level) .. " %", C.yellow, C.panel)
  bar(7, 11, 112, level, 100, level > 80 and C.red or C.yellow)
  button(8, 15, 25, "ROD -10", C.blue, false)
  button(36, 15, 25, "ROD -1", C.blue, false)
  button(66, 15, 25, "ROD +1", C.orange, false)
  button(94, 15, 25, "ROD +10", C.orange, false)
  button(8, 21, 25, "PREVIOUS ROD", C.purple, false)
  button(36, 21, 25, "NEXT ROD", C.purple, false)
  button(66, 21, 25, "ALL 0%", C.green, false)
  button(94, 21, 25, "ALL 100%", C.red, false)
  txt(8, 27, "Rod level is applied only after a touch action.", C.text, C.panel)
  footer()
end

local function click(x, y)
  if y >= 35 then
    if x >= 3 and x < 23 then screen = "dashboard"
    elseif x >= 25 and x < 45 then screen = "control"
    elseif x >= 47 and x < 67 then screen = "rods"
    elseif x >= 69 and x < 91 then discover()
    elseif x >= 91 and x < 113 then auto = not auto
    elseif x >= 113 then running = false end
    return
  end

  if screen == "dashboard" then
    if y >= 22 and y <= 24 and x >= 70 and x < 96 then screen = "control"
    elseif y >= 22 and y <= 24 and x >= 98 then screen = "rods"
    elseif y >= 27 and y <= 29 and x >= 70 and x < 96 then selected = selected % math.max(#reactors, 1) + 1
    elseif y >= 27 and y <= 29 and x >= 98 then discover() end
  elseif screen == "control" then
    if y >= 11 and y <= 13 and x >= 71 and x < 96 then
      selected = selected - 1; if selected < 1 then selected = #reactors end
    elseif y >= 11 and y <= 13 and x >= 100 then
      selected = selected + 1; if selected > #reactors then selected = 1 end
    elseif y >= 18 and y <= 20 and x >= 71 and x < 96 then auto = not auto
    elseif y >= 18 and y <= 20 and x >= 100 then discover()
    elseif y >= 24 and y <= 26 and x >= 8 and x < 32 then setcall(activeReactor(), "setActive", true)
    elseif y >= 24 and y <= 26 and x >= 34 and x < 58 then setcall(activeReactor(), "setActive", false)
  elseif screen == "rods" and #reactors > 0 then
    local r = activeReactor()
    local count = tonumber(call(r, "getNumberOfControlRods", 0)) or 0
    rod = clamp(rod, 1, math.max(count, 1))
    local level = tonumber(call(r, "getControlRodLevel", 0, rod)) or 0
    if y >= 15 and y <= 17 then
      if x >= 8 and x < 33 then level = level - 10
      elseif x >= 36 and x < 62 then level = level - 1
      elseif x >= 66 and x < 92 then level = level + 1
      elseif x >= 94 and x < 120 then level = level + 10 end
      level = clamp(level, 0, 100)
      setcall(r, "setControlRodLevel", rod, level)
    elseif y >= 21 and y <= 23 then
      if x >= 8 and x < 33 then rod = rod - 1; if rod < 1 then rod = count end
      elseif x >= 36 and x < 62 then rod = rod + 1; if rod > count then rod = 1 end
      elseif x >= 66 and x < 92 then setcall(r, "setAllControlRodLevels", 0)
      elseif x >= 94 and x < 120 then setcall(r, "setAllControlRodLevels", 100) end
    end
  end
end

local function draw()
  if screen == "dashboard" then drawDashboard()
  elseif screen == "control" then drawControl()
  else drawRods() end
end

draw()
while running do
  local e, addr, a, b = event.pull(0.5)
  if e == "touch" then
    click(a, b)
    draw()
  elseif e == "key_down" then
    local code = b
    if code == keyboard.keys.q then running = false
    elseif code == keyboard.keys.r then discover(); draw()
    elseif code == keyboard.keys.tab then
      screen = screen == "dashboard" and "control" or screen == "control" and "rods" or "dashboard"
      draw()
    end
  end
end

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, W, H, " ")
