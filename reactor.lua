-- ============================================================
-- BIG REACTOR // ADVANCED CONTROL PANEL
-- Redesigned dashboard for OpenComputers / Big Reactors
-- ============================================================

local API = require("buttonAPI")
local component = require("component")
local keyboard = require("keyboard")
local event = require("event")

local gpu = component.gpu
local reactor = component.br_reactor

-- ============================================================
-- Configuration
-- ============================================================

local versionType = "NEW"
local DEBUG = false

local colors = {
  cyan      = 0x18D7FF,
  blue      = 0x4286F4,
  purple    = 0xB673D6,
  red       = 0xE04B4B,
  green     = 0x20D46B,
  yellow    = 0xF2C94C,
  orange    = 0xF2994A,
  black     = 0x080B10,
  panel     = 0x111722,
  panel2    = 0x161D2A,
  border    = 0x344052,
  grey      = 0x566070,
  lightGrey = 0xAAB4C3,
  white     = 0xF4F7FB
}

local SCREEN_W = 132
local SCREEN_H = 38
local RF_CAPACITY = 10000000

gpu.setResolution(SCREEN_W, SCREEN_H)
gpu.setBackground(colors.black)
gpu.setForeground(colors.white)
gpu.fill(1, 1, SCREEN_W, SCREEN_H, " ")

-- ============================================================
-- Layout
-- ============================================================

local panels = {
  graphs = { x = 3,  y = 6,  width = 83, height = 29, title = "  LIVE TELEMETRY  " },
  controls = { x = 88, y = 6, width = 42, height = 15, title = "  REACTOR CONTROL  " },
  limits = { x = 88, y = 23, width = 42, height = 12, title = "  POWER LIMITS  " }
}

local graphs = {
  tick   = { x = 7, y = 10, width = 77, height = 5, title = "ENERGY / TICK" },
  stored = { x = 7, y = 18, width = 77, height = 5, title = "ENERGY STORED" },
  rods   = { x = 7, y = 26, width = 77, height = 5, title = "CONTROL RODS" }
}

local reactorStats = {}

local maxRF = 0
local reactorRodsLevel = {}
local currentRodLevel = 0
local currentRf = 0
local currentStored = 0
local currentRfTick = 0
local currentFuel = 0

local minPowerRod = 0
local maxPowerRod = 100

-- ============================================================
-- Helpers
-- ============================================================

local function toint(n)
  local value = tostring(n)
  local i = value:find("%.")

  if i then
    return tonumber(value:sub(1, i - 1))
  end

  return n
end

local function round(value, decimal)
  if decimal then
    return math.floor((value * 10 ^ decimal) + 0.5) / (10 ^ decimal)
  end

  return math.floor(value + 0.5)
end

local function file_exists(name)
  local file = io.open(name, "r")

  if file then
    file:close()
    return true
  end

  return false
end

local function clamp(value, minimum, maximum)
  return math.max(minimum, math.min(maximum, value))
end

local function setText(x, y, text, foreground, background)
  if foreground then
    gpu.setForeground(foreground)
  end

  if background then
    gpu.setBackground(background)
  end

  gpu.set(x, y, text)
end

local function centerText(x, width, y, text, foreground, background)
  local safeText = tostring(text)
  local offset = math.max(0, math.floor((width - #safeText) / 2))
  setText(x + offset, y, safeText, foreground, background)
end

local function horizontalLine(x, y, width, character)
  gpu.setBackground(colors.border)
  gpu.fill(x, y, width, 1, character or " ")
end

local function drawPanel(panel)
  gpu.setBackground(colors.panel)
  gpu.fill(panel.x, panel.y, panel.width, panel.height, " ")

  gpu.setBackground(colors.border)
  gpu.fill(panel.x, panel.y, panel.width, 1, " ")
  gpu.fill(panel.x, panel.y + panel.height, panel.width, 1, " ")
  gpu.fill(panel.x, panel.y, 1, panel.height + 1, " ")
  gpu.fill(panel.x + panel.width, panel.y, 1, panel.height + 1, " ")

  setText(panel.x + 2, panel.y, panel.title, colors.cyan, colors.black)
end

local function drawHeader()
  gpu.setBackground(colors.black)
  gpu.fill(1, 1, SCREEN_W, 4, " ")

  setText(4, 1, "BIG REACTOR", colors.cyan, colors.black)
  setText(4, 2, "ADVANCED CONTROL SYSTEM", colors.lightGrey, colors.black)

  gpu.setBackground(colors.border)
  gpu.fill(1, 4, SCREEN_W, 1, " ")

  centerText(43, 44, 2, "///  REACTOR CORE MONITOR  ///", colors.white, colors.black)
  setText(112, 1, "v2.0", colors.grey, colors.black)
  setText(103, 2, "Q = EXIT", colors.lightGrey, colors.black)
end

local function drawStatusStrip()
  gpu.setBackground(colors.panel2)
  gpu.fill(3, 5, 127, 1, " ")

  setText(5, 5, "SYSTEM", colors.grey, colors.panel2)
  setText(13, 5, "ONLINE", colors.green, colors.panel2)
  setText(29, 5, "MODE", colors.grey, colors.panel2)
  setText(36, 5, "AUTO", colors.cyan, colors.panel2)
  setText(54, 5, "REACTOR", colors.grey, colors.panel2)
  setText(63, 5, "CONNECTED", colors.green, colors.panel2)
  setText(84, 5, "LIMIT", colors.grey, colors.panel2)
  setText(91, 5, minPowerRod .. "% - " .. maxPowerRod .. "%", colors.yellow, colors.panel2)
end

-- ============================================================
-- Reactor information
-- ============================================================

local function getInfoFromReactor()
  local energyStats = reactor.getEnergyStats()
  local fuelStats = reactor.getFuelStats()

  reactorRodsLevel = reactor.getControlRodsLevels()

  reactorStats.tick = toint(math.ceil(energyStats.energyProducedLastTick))
  reactorStats.stored = toint(energyStats.energyStored)
  reactorStats.rods = toint(reactorRodsLevel[0] or 0)
  reactorStats.fuel = round(fuelStats.fuelConsumedLastTick, 2)

  currentRf = reactorStats.stored
end

local function getInfoFromReactorOLD()
  reactorStats.tick = toint(math.ceil(reactor.getEnergyProducedLastTick()))
  reactorStats.stored = toint(reactor.getEnergyStored())
  reactorStats.rods = toint(math.ceil(reactor.getControlRodLevel(0)))
  reactorStats.fuel = round(reactor.getFuelConsumedLastTick(), 2)

  currentRf = reactorStats.stored
end

-- ============================================================
-- Reactor controls
-- ============================================================

local function powerOn()
  reactor.setActive(true)
end

local function powerOff()
  reactor.setActive(false)
end

local function setInfoToFile()
  local file = io.open("reactor.txt", "w")

  if not file then
    return
  end

  file:write(minPowerRod, "\n")
  file:write(maxPowerRod, "\n")
  file:flush()
  file:close()
end

local function calculateAdjustRodsLevel()
  local differenceMinMax = maxPowerRod - minPowerRod

  currentRf = reactorStats.stored or 0

  local maxPower = (RF_CAPACITY / 100) * maxPowerRod
  local minPower = (RF_CAPACITY / 100) * minPowerRod

  currentRf = clamp(currentRf, minPower, maxPower)
  currentRf = toint(currentRf - minPower)

  local rfInBetween = (RF_CAPACITY / 100) * differenceMinMax
  local rodLevel = 0

  if rfInBetween > 0 then
    rodLevel = toint(math.ceil((currentRf / rfInBetween) * 100))
  end

  rodLevel = clamp(rodLevel, 0, 100)

  if versionType == "NEW" then
    for key in pairs(reactorRodsLevel) do
      reactor.setControlRodLevel(key, rodLevel)
    end
  else
    reactor.setAllControlRodLevels(rodLevel)
  end
end

local function modifyRods(limit, amount)
  if limit == "min" then
    minPowerRod = clamp(minPowerRod + amount, 0, maxPowerRod - 10)
  else
    maxPowerRod = clamp(maxPowerRod + amount, minPowerRod + 10, 100)
  end

  setInfoToFile()
  calculateAdjustRodsLevel()
  drawStatusStrip()
end

local function augmentMinLimit()
  modifyRods("min", 10)
end

local function lowerMinLimit()
  modifyRods("min", -10)
end

local function augmentMaxLimit()
  modifyRods("max", 10)
end

local function lowerMaxLimit()
  modifyRods("max", -10)
end

-- ============================================================
-- Persistent configuration
-- ============================================================

local function getInfoFromFile()
  if not file_exists("reactor.txt") then
    local file = io.open("reactor.txt", "w")

    if file then
      file:write("0\n")
      file:write("100\n")
      file:close()
    end

    minPowerRod = 0
    maxPowerRod = 100
    return
  end

  local file = io.open("reactor.txt", "r")

  if not file then
    minPowerRod = 0
    maxPowerRod = 100
    return
  end

  minPowerRod = tonumber(file:read("*l")) or 0
  maxPowerRod = tonumber(file:read("*l")) or 100
  file:close()

  minPowerRod = clamp(minPowerRod, 0, 90)
  maxPowerRod = clamp(maxPowerRod, minPowerRod + 10, 100)
end

-- ============================================================
-- Buttons
-- ============================================================

local function setButtons()
  API.setTable("ON", powerOn, 93, 9, 110, 11, "POWER ON", {
    on = colors.green,
    off = colors.green
  })

  API.setTable("OFF", powerOff, 112, 9, 127, 11, "POWER OFF", {
    on = colors.red,
    off = colors.red
  })

  API.setTable("lowerMinLimit", lowerMinLimit, 93, 28, 109, 30, "MIN -10", {
    on = colors.blue,
    off = colors.blue
  })

  API.setTable("lowerMaxLimit", lowerMaxLimit, 111, 28, 127, 30, "MAX -10", {
    on = colors.purple,
    off = colors.purple
  })

  API.setTable("augmentMinLimit", augmentMinLimit, 93, 32, 109, 34, "MIN +10", {
    on = colors.blue,
    off = colors.blue
  })

  API.setTable("augmentMaxLimit", augmentMaxLimit, 111, 32, 127, 34, "MAX +10", {
    on = colors.purple,
    off = colors.purple
  })
end

-- ============================================================
-- Telemetry rendering
-- ============================================================

local function drawGraphFrame(graph, color, subtitle)
  gpu.setBackground(colors.panel2)
  gpu.fill(graph.x, graph.y, graph.width, graph.height, " ")

  gpu.setBackground(colors.border)
  gpu.fill(graph.x, graph.y, graph.width, 1, " ")
  gpu.fill(graph.x, graph.y + graph.height - 1, graph.width, 1, " ")

  setText(graph.x + 2, graph.y, graph.title, color, colors.panel2)
  setText(graph.x + graph.width - #subtitle - 2, graph.y, subtitle, colors.grey, colors.panel2)
end

local function drawBar(graph, ratio, color)
  local innerX = graph.x + 2
  local innerY = graph.y + 2
  local innerWidth = graph.width - 4
  local innerHeight = graph.height - 3
  local width = clamp(math.floor(innerWidth * ratio), 0, innerWidth)

  gpu.setBackground(colors.black)
  gpu.fill(innerX, innerY, innerWidth, innerHeight, " ")

  if width > 0 then
    gpu.setBackground(color)
    gpu.fill(innerX, innerY, width, innerHeight, " ")
  end

  gpu.setBackground(colors.black)
  gpu.setForeground(colors.white)
end

local function drawTelemetry()
  local tickRatio = 0
  if maxRF > 0 then
    tickRatio = clamp((reactorStats.tick or 0) / maxRF, 0, 1)
  end

  local storedRatio = clamp((reactorStats.stored or 0) / RF_CAPACITY, 0, 1)
  local rodsRatio = clamp((reactorStats.rods or 0) / 100, 0, 1)

  drawGraphFrame(graphs.tick, colors.cyan, tostring(reactorStats.tick or 0) .. " RF/t")
  drawBar(graphs.tick, tickRatio, colors.cyan)

  drawGraphFrame(graphs.stored, colors.green, tostring(reactorStats.stored or 0) .. " RF")
  drawBar(graphs.stored, storedRatio, colors.green)

  drawGraphFrame(graphs.rods, colors.orange, tostring(reactorStats.rods or 0) .. "%")
  drawBar(graphs.rods, rodsRatio, colors.orange)

  setText(7, 16, "OUTPUT", colors.grey, colors.panel)
  setText(77, 16, "MAX " .. tostring(maxRF) .. " RF/t", colors.grey, colors.panel)

  setText(7, 24, "CAPACITY", colors.grey, colors.panel)
  setText(73, 24, "10,000,000 RF", colors.grey, colors.panel)

  setText(7, 32, "AUTO MODULATION", colors.grey, colors.panel)
  setText(27, 32, minPowerRod .. "%  →  " .. maxPowerRod .. "%", colors.yellow, colors.panel)
end

-- ============================================================
-- Control / information rendering
-- ============================================================

local function drawControlPanel()
  drawPanel(panels.controls)

  centerText(90, 38, 13, "POWER CONTROL", colors.lightGrey, colors.panel)
  horizontalLine(92, 14, 34, " ")

  setText(93, 16, "AUTO REGULATION", colors.grey, colors.panel)
  setText(93, 18, "MIN", colors.blue, colors.panel)
  setText(104, 18, minPowerRod .. "%", colors.white, colors.panel)
  setText(113, 18, "MAX", colors.purple, colors.panel)
  setText(124, 18, maxPowerRod .. "%", colors.white, colors.panel)

  setText(93, 20, "ROD TARGET", colors.grey, colors.panel)
  setText(105, 20, tostring(reactorStats.rods or 0) .. "%", colors.orange, colors.panel)
end

local function drawLimitsPanel()
  drawPanel(panels.limits)

  setText(93, 25, "MINIMUM ROD LIMIT", colors.blue, colors.panel)
  setText(120, 25, minPowerRod .. "%", colors.white, colors.panel)

  setText(93, 26, "MAXIMUM ROD LIMIT", colors.purple, colors.panel)
  setText(120, 26, maxPowerRod .. "%", colors.white, colors.panel)

  horizontalLine(92, 27, 34, " ")

  setText(93, 31, "TICK", colors.grey, colors.panel)
  setText(105, 31, tostring(reactorStats.tick or 0) .. " RF", colors.cyan, colors.panel)

  setText(93, 33, "FUEL", colors.grey, colors.panel)
  setText(105, 33, tostring(reactorStats.fuel or 0) .. " Mb/t", colors.yellow, colors.panel)
end

local function drawDebug()
  if not DEBUG then
    return
  end

  local rodsValues = ""
  for key, value in pairs(reactorRodsLevel) do
    rodsValues = rodsValues .. "[" .. tostring(key) .. "]" .. tostring(value) .. " "
  end

  local debugInformation =
    "DBG maxRF=" .. tostring(maxRF) ..
    " rods=" .. rodsValues ..
    " currentRf=" .. tostring(currentRf) ..
    " min/max=" .. tostring(minPowerRod) .. "/" .. tostring(maxPowerRod)

  gpu.setBackground(colors.black)
  gpu.setForeground(colors.grey)
  gpu.fill(1, 37, SCREEN_W, 1, " ")
  gpu.set(2, 37, debugInformation:sub(1, SCREEN_W - 2))
end

-- ============================================================
-- Main rendering
-- ============================================================

local function draw()
  if maxRF < (reactorStats.tick or 0) then
    maxRF = reactorStats.tick
  end

  drawHeader()
  drawStatusStrip()
  drawPanel(panels.graphs)
  drawTelemetry()
  drawControlPanel()
  drawLimitsPanel()
  drawDebug()

  gpu.setBackground(colors.black)
  gpu.setForeground(colors.grey)
end

-- ============================================================
-- Startup / version detection
-- ============================================================

local function testVersion()
  reactor.getEnergyStats()
end

local function setOldVersion()
  versionType = "OLD"
end

local function startup()
  getInfoFromFile()

  if versionType == "NEW" then
    getInfoFromReactor()
  else
    getInfoFromReactorOLD()
  end

  setButtons()
  draw()
end

-- ============================================================
-- Start application
-- ============================================================

xpcall(testVersion, setOldVersion)
startup()
API.screen()
event.listen("touch", API.checkxy)

while event.pull(0.1, "interrupted") == nil do
  if versionType == "NEW" then
    if reactor.mbIsConnected() and reactor.mbIsAssembled() then
      getInfoFromReactor()
    end
  else
    getInfoFromReactorOLD()
  end

  calculateAdjustRodsLevel()
  draw()

  local eventName, address, arg1, arg2, arg3 = event.pull(1)

  if type(address) == "string" and component.isPrimary(address) then
    if eventName == "key_down" and arg2 == keyboard.keys.q then
      os.exit()
    end
  end
end
