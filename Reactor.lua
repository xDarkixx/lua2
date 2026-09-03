-- MJRLegends Reactor Management
-- Graphical redesign for OpenComputers / Big Reactors / Extreme Reactors
-- Original author notice preserved from the original file.

local component = require("component")
local keyboard = require("keyboard")
local event = require("event")

local gpu = component.gpu
local reactors = {}
local reactorsManagement = {}

local version = "2.0.0"
local displayW, displayH = 132, 38

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

gpu.setResolution(displayW, displayH)

gpu.setBackground(C.bg)
gpu.setForeground(C.white)
gpu.fill(1, 1, displayW, displayH, " ")

local currentScreen = "main"
local currentReactor = 1
local currentRodNumber = 0
local currentPower = 0

local maxFluidTank = 50000
local minLevelPower = 5000000
local maxLevelPower = 9000000
local minLevelSteam = maxFluidTank / 2
local maxLevelSteam = maxFluidTank

local function clamp(value, minValue, maxValue)
  if value < minValue then return minValue end
  if value > maxValue then return maxValue end
  return value
end

local function tableLength(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

local function clearScreen()
  gpu.setBackground(C.bg)
  gpu.setForeground(C.white)
  gpu.fill(1, 1, displayW, displayH, " ")
end

local function rect(x, y, w, h, bg)
  if w < 1 or h < 1 then return end
  gpu.setBackground(bg)
  gpu.fill(x, y, w, h, " ")
end

local function text(x, y, value, fg, bg)
  if y < 1 or y > displayH then return end
  gpu.setBackground(bg or C.bg)
  gpu.setForeground(fg or C.text)
  gpu.set(x, y, tostring(value))
end

local function center(y, value, fg, bg)
  value = tostring(value)
  local x = math.floor((displayW - #value) / 2) + 1
  text(x, y, value, fg, bg)
end

local function panel(x, y, w, h, title, accent)
  rect(x, y, w, h, C.panel)
  gpu.setBackground(C.panel)
  gpu.setForeground(accent or C.blue)
  gpu.fill(x, y, w, 1, " ")
  gpu.set(x + 2, y, "[ " .. title .. " ]")
  gpu.setBackground(C.border)
  gpu.fill(x, y + h - 1, w, 1, " ")
  gpu.fill(x, y, 1, h, " ")
  gpu.fill(x + w - 1, y, 1, h, " ")
end

local function button(x, y, w, label, bg, active)
  local color = active and C.green or (bg or C.blue)
  rect(x, y, w, 3, color)
  gpu.setForeground(C.white)
  gpu.setBackground(color)
  local clean = tostring(label)
  if #clean > w - 2 then clean = clean:sub(1, w - 2) end
  local tx = x + math.max(1, math.floor((w - #clean) / 2))
  gpu.set(tx, y + 1, clean)
end

local function smallButton(x, y, w, label, bg, active)
  local color = active and C.green or (bg or C.blue)
  rect(x, y, w, 1, color)
  gpu.setForeground(C.white)
  gpu.setBackground(color)
  local clean = tostring(label)
  if #clean > w then clean = clean:sub(1, w) end
  gpu.set(x + math.max(0, math.floor((w - #clean) / 2)), y, clean)
end

local function progress(x, y, w, value, maximum, fg, bg)
  maximum = maximum or 1
  value = clamp(value or 0, 0, maximum)
  local filled = math.floor((value / maximum) * w)
  rect(x, y, w, 1, bg or C.panel2)
  if filled > 0 then rect(x, y, filled, 1, fg or C.blue) end
end

local function percent(value, maximum)
  if not maximum or maximum <= 0 then return 0 end
  return math.floor(clamp(value, 0, maximum) / maximum * 100)
end

local function fmt(value)
  value = math.floor(value or 0)
  if value >= 1000000 then return string.format("%.2fM", value / 1000000) end
  if value >= 1000 then return string.format("%.1fk", value / 1000) end
  return tostring(value)
end

local function safeCall(reactor, method, fallback)
  local ok, result = pcall(reactor[method])
  if ok and result ~= nil then return result end
  return fallback or 0
end

local function isCooled(reactor)
  return safeCall(reactor, "isActivelyCooled", false) == true
end

local function drawHeader(title)
  rect(1, 1, displayW, 3, C.panel)
  text(3, 2, "REACTOR CONTROL", C.cyan, C.panel)
  text(21, 2, "|", C.border, C.panel)
  text(24, 2, title, C.white, C.panel)
  text(89, 2, "v" .. version, C.muted, C.panel)
  if #reactors > 0 then
    text(103, 2, "REACTOR", C.muted, C.panel)
    text(112, 2, currentReactor .. "/" .. #reactors, C.white, C.panel)
  else
    text(103, 2, "NO REACTORS", C.red, C.panel)
  end
  rect(1, 4, displayW, 1, C.blue)
end

local function drawFooter()
  rect(1, 35, displayW, 4, C.panel)
  local controlActive = currentScreen == "rods"
  local settingsActive = currentScreen == "settings"
  button(4, 35, 22, "CONTROL", C.blue, controlActive)
  button(29, 35, 22, "DASHBOARD", C.purple, currentScreen == "main")
  button(54, 35, 22, "RODS", C.blue, controlActive)
  button(79, 35, 22, "SETTINGS", C.blue, settingsActive)
  button(104, 35, 24, "EXIT: Q", C.red, false)
end

local function drawReactorSelector()
  if #reactors == 0 then return end
  smallButton(94, 3, 5, "<", C.blue)
  smallButton(100, 3, 5, ">", C.blue)
end

local function drawMainScreen()
  clearScreen()
  drawHeader("SYSTEM DASHBOARD")

  local online, cooled = 0, 0
  local energy, steam, fuel, waste, fuelMax = 0, 0, 0, 0, 0

  for i = 1, #reactors do
    local r = reactors[i]
    if safeCall(r, "getActive", false) then online = online + 1 end
    if isCooled(r) then
      cooled = cooled + 1
      steam = steam + math.floor(safeCall(r, "getHotFluidAmount", 0))
    else
      energy = energy + math.floor(safeCall(r, "getEnergyStored", 0))
    end
    fuel = fuel + math.floor(safeCall(r, "getFuelAmount", 0))
    waste = waste + math.floor(safeCall(r, "getWasteAmount", 0))
    fuelMax = fuelMax + math.floor(safeCall(r, "getFuelAmountMax", 0))
  end

  panel(3, 6, 40, 10, "REACTOR STATUS", C.blue)
  text(6, 8, "ONLINE", C.muted, C.panel)
  text(24, 8, online .. " / " .. #reactors, C.green, C.panel)
  progress(6, 9, 32, online, math.max(#reactors, 1), C.green, C.panel2)
  text(6, 11, "ACTIVE COOLING", C.muted, C.panel)
  text(24, 11, cooled .. " / " .. #reactors, C.cyan, C.panel)
  progress(6, 12, 32, cooled, math.max(#reactors, 1), C.cyan, C.panel2)
  text(6, 14, "MANAGED", C.muted, C.panel)
  text(24, 14, tableLength(reactorsManagement) .. " / " .. #reactors, C.yellow, C.panel)

  panel(46, 6, 83, 10, "ENERGY / STEAM", C.cyan)
  text(49, 8, "ENERGY BUFFER", C.muted, C.panel)
  text(77, 8, fmt(energy) .. " RF", C.white, C.panel)
  progress(49, 9, 76, energy, math.max(10000000 * math.max(#reactors - cooled, 1), 1), C.red, C.panel2)
  text(49, 11, "STEAM BUFFER", C.muted, C.panel)
  text(77, 11, fmt(steam) .. " mb", C.white, C.panel)
  progress(49, 12, 76, steam, math.max(50000 * math.max(cooled, 1), 1), C.cyan, C.panel2)
  text(49, 14, "SYSTEM LOAD", C.muted, C.panel)
  text(77, 14, percent(energy, math.max(10000000 * math.max(#reactors - cooled, 1), 1)) .. "%", C.yellow, C.panel)

  panel(3, 17, 61, 15, "FUEL", C.yellow)
  text(6, 19, "TOTAL FUEL", C.muted, C.panel)
  text(31, 19, fmt(fuel) .. " mb", C.yellow, C.panel)
  progress(6, 20, 55, fuel, math.max(fuelMax, 1), C.yellow, C.panel2)
  text(6, 22, "TOTAL WASTE", C.muted, C.panel)
  text(31, 22, fmt(waste) .. " mb", C.blue, C.panel)
  progress(6, 23, 55, waste, math.max(fuelMax, 1), C.blue, C.panel2)
  text(6, 25, "FUEL CAPACITY", C.muted, C.panel)
  text(31, 25, fmt(fuelMax) .. " mb", C.text, C.panel)
  text(6, 27, "CURRENT REACTOR", C.muted, C.panel)
  text(31, 27, #reactors > 0 and ("#" .. currentReactor) or "--", C.cyan, C.panel)
  text(6, 29, "AUTOMATION", C.muted, C.panel)
  text(31, 29, #reactors > 0 and (reactorsManagement[currentReactor] and "ENABLED" or "DISABLED") or "--", reactorsManagement[currentReactor] and C.green or C.red, C.panel)

  panel(67, 17, 62, 15, "QUICK ACTIONS", C.purple)
  text(70, 19, "Use the controls below to open the selected reactor.", C.text, C.panel)
  button(70, 21, 25, "REACTOR INFO", C.blue, currentScreen == "control")
  button(98, 21, 25, "CONTROL RODS", C.purple, currentScreen == "rods")
  button(70, 26, 25, "SETTINGS", C.blue, currentScreen == "settings")
  button(98, 26, 25, "REFRESH", C.cyan, false)
  text(70, 30, "Q", C.yellow, C.panel)
  text(74, 30, "Exit program", C.muted, C.panel)

  drawFooter()
end

local function drawControl()
  clearScreen()
  drawHeader("REACTOR INFORMATION")
  drawReactorSelector()
  drawFooter()
  if #reactors == 0 then center(18, "No br_reactor component detected.", C.red, C.bg); return end

  local r = reactors[currentReactor]
  local cooled = isCooled(r)
  local casing = math.floor(safeCall(r, "getCasingTemperature", 0))
  local fuelTemp = math.floor(safeCall(r, "getFuelTemperature", 0))
  local fuel = math.floor(safeCall(r, "getFuelAmount", 0))
  local fuelMax = math.floor(safeCall(r, "getFuelAmountMax", 1))
  local waste = math.floor(safeCall(r, "getWasteAmount", 0))
  local active = safeCall(r, "getActive", false)

  panel(3, 6, 62, 13, "THERMAL STATUS", C.orange)
  text(6, 8, "CASING", C.muted, C.panel)
  text(25, 8, casing .. " C", C.white, C.panel)
  progress(6, 9, 55, casing, 5000, casing >= 1500 and C.red or casing >= 1000 and C.yellow or C.green, C.panel2)
  text(6, 11, "FUEL CORE", C.muted, C.panel)
  text(25, 11, fuelTemp .. " C", C.white, C.panel)
  progress(6, 12, 55, fuelTemp, 5000, fuelTemp >= 1500 and C.red or fuelTemp >= 1000 and C.yellow or C.green, C.panel2)
  text(6, 14, "STATUS", C.muted, C.panel)
  text(25, 14, active and "ONLINE" or "OFFLINE", active and C.green or C.red, C.panel)
  text(6, 16, "COOLING", C.muted, C.panel)
  text(25, 16, cooled and "ACTIVE" or "PASSIVE", cooled and C.cyan or C.text, C.panel)

  panel(67, 6, 62, 13, cooled and "COOLANT / STEAM" or "POWER BUFFER", C.cyan)
  if cooled then
    local coolant = math.floor(safeCall(r, "getCoolantAmount", 0))
    local cap = math.floor(safeCall(r, "getHotFluidAmountMax", maxFluidTank))
    local hot = math.floor(safeCall(r, "getHotFluidAmount", 0))
    text(70, 8, "COOLANT", C.muted, C.panel)
    text(91, 8, coolant .. " mb", C.white, C.panel)
    progress(70, 9, 55, coolant, math.max(cap, 1), C.blue, C.panel2)
    text(70, 11, "STEAM", C.muted, C.panel)
    text(91, 11, hot .. " mb", C.white, C.panel)
    progress(70, 12, 55, hot, math.max(cap, 1), C.cyan, C.panel2)
    text(70, 14, "TARGET", C.muted, C.panel)
    text(91, 14, minLevelSteam .. " - " .. maxLevelSteam .. " mb", C.yellow, C.panel)
    text(70, 16, "OUTPUT/T", C.muted, C.panel)
    text(91, 16, math.floor(safeCall(r, "getEnergyProducedLastTick", 0)) .. "", C.green, C.panel)
  else
    local power = math.floor(safeCall(r, "getEnergyStored", 0))
    text(70, 8, "ENERGY", C.muted, C.panel)
    text(91, 8, fmt(power) .. " RF", C.white, C.panel)
    progress(70, 9, 55, power, 10000000, C.red, C.panel2)
    text(70, 11, "CHARGE", C.muted, C.panel)
    text(91, 11, percent(power, 10000000) .. "%", C.yellow, C.panel)
    text(70, 14, "TARGET", C.muted, C.panel)
    text(91, 14, fmt(minLevelPower) .. " - " .. fmt(maxLevelPower) .. " RF", C.yellow, C.panel)
    text(70, 16, "OUTPUT/T", C.muted, C.panel)
    text(91, 16, fmt(safeCall(r, "getEnergyProducedLastTick", 0)) .. " RF", C.green, C.panel)
  end

  panel(3, 21, 62, 11, "FUEL & WASTE", C.yellow)
  text(6, 23, "FUEL", C.muted, C.panel)
  text(25, 23, fuel .. " / " .. fuelMax .. " mb", C.yellow, C.panel)
  progress(6, 24, 55, fuel, math.max(fuelMax, 1), C.yellow, C.panel2)
  text(6, 26, "WASTE", C.muted, C.panel)
  text(25, 26, waste .. " mb", C.blue, C.panel)
  progress(6, 27, 55, waste, math.max(fuelMax, 1), C.blue, C.panel2)
  text(6, 29, "CONSUMPTION", C.muted, C.panel)
  text(25, 29, safeCall(r, "getFuelConsumedLastTick", 0) .. " mB/t", C.white, C.panel)

  panel(67, 21, 62, 11, "LIVE PRODUCTION", C.green)
  text(70, 23, "ENERGY / TICK", C.muted, C.panel)
  text(95, 23, fmt(safeCall(r, "getEnergyProducedLastTick", 0)) .. " RF", C.green, C.panel)
  text(70, 25, "FUEL / TICK", C.muted, C.panel)
  text(95, 25, safeCall(r, "getFuelConsumedLastTick", 0) .. " mB", C.yellow, C.panel)
  text(70, 27, "AUTOMATION", C.muted, C.panel)
  text(95, 27, reactorsManagement[currentReactor] and "ON" or "OFF", reactorsManagement[currentReactor] and C.green or C.red, C.panel)
  text(70, 29, "SELECTED", C.muted, C.panel)
  text(95, 29, "REACTOR #" .. currentReactor, C.cyan, C.panel)
end

local function drawRodScreen()
  clearScreen()
  drawHeader("CONTROL RODS")
  drawReactorSelector()
  drawFooter()
  if #reactors == 0 then center(18, "No reactor available.", C.red, C.bg); return end

  local r = reactors[currentReactor]
  local active = safeCall(r, "getActive", false)
  local count = math.floor(safeCall(r, "getNumberOfControlRods", 0))
  if count < 1 then center(18, "This reactor has no control rods.", C.red, C.bg); return end
  currentRodNumber = clamp(currentRodNumber, 0, count - 1)
  local level = math.floor(safeCall(r, "getControlRodLevel", 0))

  panel(3, 6, 62, 26, "REACTOR CONTROL", active and C.green or C.red)
  text(7, 8, "REACTOR STATUS", C.muted, C.panel)
  text(27, 8, active and "ONLINE" or "OFFLINE", active and C.green or C.red, C.panel)
  smallButton(7, 10, 16, "START", C.green, active)
  smallButton(24, 10, 16, "STOP", C.red, not active)
  text(7, 13, "CONTROL RODS", C.muted, C.panel)
  text(27, 13, tostring(count), C.white, C.panel)
  text(7, 15, "SELECTED ROD", C.muted, C.panel)
  text(27, 15, (currentRodNumber + 1) .. " / " .. count, C.cyan, C.panel)
  smallButton(7, 17, 10, "< PREV", C.blue)
  smallButton(18, 17, 10, "NEXT >", C.blue)
  text(7, 20, "ROD INSERTION", C.muted, C.panel)
  text(27, 20, level .. "%", C.yellow, C.panel)
  progress(7, 21, 51, level, 100, C.yellow, C.panel2)
  smallButton(7, 24, 10, "+1", C.blue)
  smallButton(18, 24, 10, "+5", C.blue)
  smallButton(29, 24, 10, "+10", C.blue)
  smallButton(40, 24, 10, "-1", C.purple)
  smallButton(51, 24, 10, "-5", C.purple)
  smallButton(7, 26, 10, "-10", C.purple)
  smallButton(18, 26, 20, "SET 50%", C.cyan)
  smallButton(40, 26, 20, "COPY TO ALL", C.purple)
  text(7, 29, "0% = fully withdrawn / 100% = fully inserted", C.muted, C.panel)

  panel(67, 6, 62, 26, "ROD PROFILE", C.purple)
  for i = 0, math.min(count - 1, 12) do
    local row = 8 + i * 1.7
    if row <= 30 then
      local v = math.floor(safeCall(r, "getControlRodLevel", 0))
      if i ~= currentRodNumber then
        local ok, result = pcall(r.getControlRodLevel, r, i)
        if ok then v = math.floor(result) end
      end
      text(71, math.floor(row), string.format("ROD %02d", i + 1), i == currentRodNumber and C.cyan or C.text, C.panel)
      progress(82, math.floor(row), 39, v, 100, i == currentRodNumber and C.cyan or C.blue, C.panel2)
      text(123, math.floor(row), v .. "%", C.text, C.panel)
    end
  end
end

local function drawSettingScreen()
  clearScreen()
  drawHeader("SYSTEM SETTINGS")
  drawReactorSelector()
  drawFooter()
  if #reactors == 0 then center(18, "No reactor available.", C.red, C.bg); return end

  local r = reactors[currentReactor]
  local cooled = isCooled(r)

  panel(3, 6, 62, 26, "AUTOMATION", C.green)
  text(7, 8, "REACTOR MANAGEMENT", C.muted, C.panel)
  smallButton(7, 10, 16, "ENABLED", C.green, reactorsManagement[currentReactor])
  smallButton(24, 10, 16, "DISABLED", C.red, not reactorsManagement[currentReactor])
  text(7, 13, "MODE", C.muted, C.panel)
  text(24, 13, cooled and "ACTIVE COOLING" or "POWER BUFFER", C.cyan, C.panel)

  if cooled then
    text(7, 16, "STEAM MIN", C.muted, C.panel)
    text(24, 16, maxFluidTank / 2 .. " mb", C.white, C.panel)
    smallButton(7, 18, 8, "+1k", C.blue)
    smallButton(16, 18, 8, "+10k", C.blue)
    smallButton(25, 18, 8, "-1k", C.purple)
    smallButton(34, 18, 8, "-10k", C.purple)
    text(7, 21, "STEAM MAX", C.muted, C.panel)
    text(24, 21, maxFluidTank .. " mb", C.white, C.panel)
    smallButton(7, 23, 8, "+1k", C.blue)
    smallButton(16, 23, 8, "+10k", C.blue)
    smallButton(25, 23, 8, "-1k", C.purple)
    smallButton(34, 23, 8, "-10k", C.purple)
  else
    text(7, 16, "POWER MIN", C.muted, C.panel)
    text(24, 16, fmt(minLevelPower) .. " RF", C.white, C.panel)
    smallButton(7, 18, 8, "+100k", C.blue)
    smallButton(16, 18, 8, "+1M", C.blue)
    smallButton(25, 18, 8, "-100k", C.purple)
    smallButton(34, 18, 8, "-1M", C.purple)
    text(7, 21, "POWER MAX", C.muted, C.panel)
    text(24, 21, fmt(maxLevelPower) .. " RF", C.white, C.panel)
    smallButton(7, 23, 8, "+100k", C.blue)
    smallButton(16, 23, 8, "+1M", C.blue)
    smallButton(25, 23, 8, "-100k", C.purple)
    smallButton(34, 23, 8, "-1M", C.purple)
  end
  text(7, 29, "Selected reactor: #" .. currentReactor, C.muted, C.panel)

  panel(67, 6, 62, 26, "SYSTEM", C.cyan)
  text(71, 8, "VERSION", C.muted, C.panel)
  text(94, 8, version, C.white, C.panel)
  text(71, 11, "DISPLAY", C.muted, C.panel)
  text(94, 11, displayW .. " x " .. displayH, C.white, C.panel)
  text(71, 14, "DETECTED REACTORS", C.muted, C.panel)
  text(94, 14, tostring(#reactors), C.cyan, C.panel)
  text(71, 17, "AUTO MODE", C.muted, C.panel)
  text(94, 17, reactorsManagement[currentReactor] and "ON" or "OFF", reactorsManagement[currentReactor] and C.green or C.red, C.panel)
  text(71, 20, "POWER TARGET", C.muted, C.panel)
  text(94, 20, fmt(minLevelPower) .. " - " .. fmt(maxLevelPower), C.text, C.panel)
  text(71, 23, "STEAM TARGET", C.muted, C.panel)
  text(94, 23, minLevelSteam .. " - " .. maxLevelSteam, C.text, C.panel)
  text(71, 27, "Q = EXIT", C.yellow, C.panel)
end

local function management()
  for i = 1, #reactors do
    if reactorsManagement[i] then
      local r = reactors[i]
      if isCooled(r) then
        local steam = safeCall(r, "getHotFluidAmount", 0)
        if steam >= maxLevelSteam then
          pcall(r.setActive, r, false)
        elseif steam <= minLevelSteam then
          pcall(r.setActive, r, true)
        end
      else
        local power = safeCall(r, "getEnergyStored", 0)
        if power >= maxLevelPower then
          pcall(r.setActive, r, false)
        elseif power <= minLevelPower then
          pcall(r.setActive, r, true)
        end
      end
    end
  end
end

local function getReactors()
  reactors = {}
  reactorsManagement = {}
  for address in component.list("br_reactor") do
    local proxy = component.proxy(address)
    if proxy then
      table.insert(reactors, proxy)
      table.insert(reactorsManagement, true)
    end
  end
  if currentReactor > #reactors then currentReactor = math.max(#reactors, 1) end
  if #reactors == 0 then currentReactor = 1 end
  currentRodNumber = 0
end

local function changeRodLevel(r, delta)
  local count = math.floor(safeCall(r, "getNumberOfControlRods", 0))
  if count < 1 then return end
  currentRodNumber = clamp(currentRodNumber, 0, count - 1)
  local old = math.floor(safeCall(r, "getControlRodLevel", 0))
  local newLevel = clamp(old + delta, 0, 100)
  pcall(r.setControlRodLevel, r, currentRodNumber, newLevel)
end

local function touch(x, y)
  if y >= 35 then
    if x >= 4 and x <= 26 then currentScreen = "control"
    elseif x >= 29 and x <= 51 then currentScreen = "main"
    elseif x >= 54 and x <= 76 then currentScreen = "rods"
    elseif x >= 79 and x <= 101 then currentScreen = "settings"
    elseif x >= 104 and x <= 128 then os.exit() end
    return
  end

  if #reactors == 0 then return end

  if y == 3 and x >= 94 and x <= 98 then
    currentReactor = math.max(1, currentReactor - 1)
    currentRodNumber = 0
    return
  elseif y == 3 and x >= 100 and x <= 104 then
    currentReactor = math.min(#reactors, currentReactor + 1)
    currentRodNumber = 0
    return
  end

  local r = reactors[currentReactor]

  if currentScreen == "main" then
    if x >= 70 and x <= 95 and y >= 21 and y <= 23 then currentScreen = "control"
    elseif x >= 98 and x <= 123 and y >= 21 and y <= 23 then currentScreen = "rods"
    elseif x >= 70 and x <= 95 and y >= 26 and y <= 28 then currentScreen = "settings"
    end
  elseif currentScreen == "rods" then
    local count = math.floor(safeCall(r, "getNumberOfControlRods", 0))
    if y == 10 and x >= 7 and x <= 22 then pcall(r.setActive, r, true)
    elseif y == 10 and x >= 24 and x <= 40 then pcall(r.setActive, r, false)
    elseif y == 17 and x >= 7 and x <= 17 then currentRodNumber = math.max(0, currentRodNumber - 1)
    elseif y == 17 and x >= 18 and x <= 28 then currentRodNumber = math.min(math.max(count - 1, 0), currentRodNumber + 1)
    elseif y == 24 and x >= 7 and x <= 16 then changeRodLevel(r, 1)
    elseif y == 24 and x >= 18 and x <= 27 then changeRodLevel(r, 5)
    elseif y == 24 and x >= 29 and x <= 38 then changeRodLevel(r, 10)
    elseif y == 24 and x >= 40 and x <= 49 then changeRodLevel(r, -1)
    elseif y == 24 and x >= 51 and x <= 60 then changeRodLevel(r, -5)
    elseif y == 26 and x >= 7 and x <= 16 then changeRodLevel(r, -10)
    elseif y == 26 and x >= 18 and x <= 38 then pcall(r.setControlRodLevel, r, currentRodNumber, 50)
    elseif y == 26 and x >= 40 and x <= 60 then
      local level = math.floor(safeCall(r, "getControlRodLevel", 0))
      pcall(r.setAllControlRodLevels, r, level)
    end
  elseif currentScreen == "settings" then
    if y == 10 and x >= 7 and x <= 23 then reactorsManagement[currentReactor] = true
    elseif y == 10 and x >= 24 and x <= 40 then reactorsManagement[currentReactor] = false
    elseif isCooled(r) then
      if y == 18 and x >= 7 and x <= 14 then minLevelSteam = minLevelSteam + 1000
      elseif y == 18 and x >= 16 and x <= 23 then minLevelSteam = minLevelSteam + 10000
      elseif y == 18 and x >= 25 and x <= 32 then minLevelSteam = math.max(0, minLevelSteam - 1000)
      elseif y == 18 and x >= 34 and x <= 42 then minLevelSteam = math.max(0, minLevelSteam - 10000)
      elseif y == 23 and x >= 7 and x <= 14 then maxLevelSteam = maxLevelSteam + 1000
      elseif y == 23 and x >= 16 and x <= 23 then maxLevelSteam = maxLevelSteam + 10000
      elseif y == 23 and x >= 25 and x <= 32 then maxLevelSteam = math.max(minLevelSteam, maxLevelSteam - 1000)
      elseif y == 23 and x >= 34 and x <= 42 then maxLevelSteam = math.max(minLevelSteam, maxLevelSteam - 10000)
      end
      maxLevelSteam = clamp(maxLevelSteam, minLevelSteam, maxFluidTank)
      minLevelSteam = clamp(minLevelSteam, 0, maxLevelSteam)
    else
      if y == 18 and x >= 7 and x <= 14 then minLevelPower = minLevelPower + 100000
      elseif y == 18 and x >= 16 and x <= 23 then minLevelPower = minLevelPower + 1000000
      elseif y == 18 and x >= 25 and x <= 32 then minLevelPower = math.max(0, minLevelPower - 100000)
      elseif y == 18 and x >= 34 and x <= 42 then minLevelPower = math.max(0, minLevelPower - 1000000)
      elseif y == 23 and x >= 7 and x <= 14 then maxLevelPower = maxLevelPower + 100000
      elseif y == 23 and x >= 16 and x <= 23 then maxLevelPower = maxLevelPower + 1000000
      elseif y == 23 and x >= 25 and x <= 32 then maxLevelPower = math.max(minLevelPower, maxLevelPower - 100000)
      elseif y == 23 and x >= 34 and x <= 42 then maxLevelPower = math.max(minLevelPower, maxLevelPower - 1000000)
      end
      maxLevelPower = math.max(minLevelPower, maxLevelPower)
    end
  end
end

getReactors()
event.listen("touch", function(_, _, _, x, y) touch(x, y) end)

while true do
  management()
  if currentScreen == "main" then
    drawMainScreen()
  elseif currentScreen == "control" then
    drawControl()
  elseif currentScreen == "rods" then
    drawRodScreen()
  elseif currentScreen == "settings" then
    drawSettingScreen()
  end

  local name, address, char, code = event.pull(0.5)
  if name == "key_down" and type(address) == "string" and component.isPrimary(address) and code == keyboard.keys.q then
    os.exit()
  end
  os.sleep(0.5)
end
