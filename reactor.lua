-- ============================================================
-- Big Reactors / Extreme Reactors Control Panel
-- Cleaned and formatted version
-- ============================================================

local API = require("buttonAPI")
local filesystem = require("filesystem")
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
  blue      = 0x4286F4,
  purple    = 0xB673D6,
  red       = 0xC14141,
  green     = 0x0DA841,
  black     = 0x000000,
  white     = 0xFFFFFF,
  grey      = 0x47494C,
  lightGrey = 0xBBBBBB
}

-- Screen size for tier 3 GPU.
gpu.setResolution(132, 38)
gpu.setBackground(colors.black)
gpu.fill(1, 1, 132, 38, " ")

-- ============================================================
-- UI definitions
-- ============================================================

local sections = {}
local graphs = {}
local infos = {}
local debug = {}

sections.graph = {
  x = 5,
  y = 3,
  width = 78,
  height = 33,
  title = "  INFOS  "
}

sections.controls = {
  x = 88,
  y = 3,
  width = 40,
  height = 20,
  title = "  CONTROLS  "
}

sections.info = {
  x = 88,
  y = 26,
  width = 40,
  height = 10,
  title = "  NUMBERS  "
}

graphs.tick = {
  x = 8,
  y = 6,
  width = 73,
  height = 8,
  title = "ENERGY LAST TICK"
}

graphs.stored = {
  x = 8,
  y = 16,
  width = 73,
  height = 8,
  title = "ENERGY STORED"
}

graphs.rods = {
  x = 8,
  y = 26,
  width = 73,
  height = 8,
  title = "CONTROL RODS LEVEL"
}

infos.tick = {
  x = 92,
  y = 28,
  width = 73,
  height = 1,
  title = "RF PER TICK : ",
  unit = " RF"
}

infos.stored = {
  x = 92,
  y = 30,
  width = 73,
  height = 1,
  title = "ENERGY STORED : ",
  unit = " RF"
}

infos.rods = {
  x = 92,
  y = 32,
  width = 73,
  height = 1,
  title = "CONTROL ROD LEVEL : ",
  unit = "%"
}

infos.fuel = {
  x = 92,
  y = 34,
  width = 73,
  height = 1,
  title = "FUEL USAGE : ",
  unit = " Mb/t"
}

debug.print = {
  x = 1,
  y = 38,
  width = 73,
  height = 1,
  title = "DBG : "
}

-- ============================================================
-- Reactor state
-- ============================================================

reactor.stats = {}

local maxRF = 0
local reactorRodsLevel = {}
local currentRodLevel = 0
local currentRf = 0
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

  if file ~= nil then
    file:close()
    return true
  end

  return false
end

-- ============================================================
-- Reactor information
-- ============================================================

local function getInfoFromReactor()
  local energyStats = reactor.getEnergyStats()
  local fuelStats = reactor.getFuelStats()

  reactorRodsLevel = reactor.getControlRodsLevels()

  reactor.stats.tick = toint(math.ceil(energyStats.energyProducedLastTick))
  reactor.stats.stored = toint(energyStats.energyStored)
  reactor.stats.rods = toint(reactorRodsLevel[0])
  reactor.stats.fuel = round(fuelStats.fuelConsumedLastTick, 2)

  currentRf = reactor.stats.stored
end

local function getInfoFromReactorOLD()
  reactor.stats.tick = toint(math.ceil(reactor.getEnergyProducedLastTick()))
  reactor.stats.stored = toint(reactor.getEnergyStored())
  reactor.stats.rods = toint(math.ceil(reactor.getControlRodLevel(0)))
  reactor.stats.fuel = round(reactor.getFuelConsumedLastTick(), 2)

  currentRf = reactor.stats.stored
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
  local rfTotalMax = 10000000
  local differenceMinMax = maxPowerRod - minPowerRod

  currentRf = reactor.stats.stored

  local maxPower = (rfTotalMax / 100) * maxPowerRod
  local minPower = (rfTotalMax / 100) * minPowerRod

  if currentRf >= maxPower then
    currentRf = maxPower
  end

  if currentRf <= minPower then
    currentRf = minPower
  end

  currentRf = toint(currentRf - (rfTotalMax / 100) * minPowerRod)

  local rfInBetween = (rfTotalMax / 100) * differenceMinMax
  local rodLevel = 0

  if rfInBetween > 0 then
    rodLevel = toint(math.ceil((currentRf / rfInBetween) * 100))
  end

  rodLevel = math.max(0, math.min(100, rodLevel))

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
    local newLevel = minPowerRod + amount
    minPowerRod = math.max(0, math.min(maxPowerRod - 10, newLevel))
  else
    local newLevel = maxPowerRod + amount
    maxPowerRod = math.max(minPowerRod + 10, math.min(100, newLevel))
  end

  setInfoToFile()
  calculateAdjustRodsLevel()
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

  minPowerRod = math.max(0, math.min(90, minPowerRod))
  maxPowerRod = math.max(minPowerRod + 10, math.min(100, maxPowerRod))
end

-- ============================================================
-- UI drawing
-- ============================================================

local function setButtons()
  API.setTable("ON", powerOn, 91, 5, 106, 7, "ON", {
    on = colors.green,
    off = colors.green
  })

  API.setTable("OFF", powerOff, 109, 5, 125, 7, "OFF", {
    on = colors.red,
    off = colors.red
  })

  API.setTable("lowerMinLimit", lowerMinLimit, 91, 15, 106, 17, "-10", {
    on = colors.blue,
    off = colors.blue
  })

  API.setTable("lowerMaxLimit", lowerMaxLimit, 109, 15, 125, 17, "-10", {
    on = colors.purple,
    off = colors.purple
  })

  API.setTable("augmentMinLimit", augmentMinLimit, 91, 19, 106, 21, "+10", {
    on = colors.blue,
    off = colors.blue
  })

  API.setTable("augmentMaxLimit", augmentMaxLimit, 109, 19, 125, 21, "+10", {
    on = colors.purple,
    off = colors.purple
  })
end

local function printBorders(sectionName)
  local section = sections[sectionName]

  gpu.setBackground(colors.grey)
  gpu.fill(section.x, section.y, section.width, 1, " ")
  gpu.fill(section.x, section.y, 1, section.height, " ")
  gpu.fill(section.x, section.y + section.height, section.width, 1, " ")
  gpu.fill(section.x + section.width, section.y, 1, section.height + 1, " ")

  gpu.setBackground(colors.black)
  gpu.set(section.x + 2, section.y, section.title)
end

local function printGraphs(graphName)
  local graph = graphs[graphName]

  gpu.setBackground(colors.lightGrey)
  gpu.fill(graph.x, graph.y, graph.width, graph.height, " ")

  gpu.setBackground(colors.black)
  gpu.set(graph.x, graph.y - 1, graph.title)
end

local function printActiveGraph(graph)
  gpu.setBackground(colors.green)
  gpu.fill(graph.x, graph.y, graph.width, graph.height, " ")
  gpu.setBackground(colors.black)
end

local function printStaticControlText()
  gpu.setForeground(colors.blue)
  gpu.set(97, 12, "MIN")

  gpu.setForeground(colors.purple)
  gpu.set(116, 12, "MAX")

  gpu.setForeground(colors.white)
  gpu.set(102, 10, "AUTO-CONTROL")
  gpu.set(107, 13, "--")
end

local function printControlInfos()
  gpu.setForeground(colors.blue)
  gpu.set(97, 13, minPowerRod .. "% ")

  gpu.setForeground(colors.purple)
  gpu.set(116, 13, maxPowerRod .. "% ")

  gpu.setForeground(colors.white)
end

local function printInfos(infoName)
  local info = infos[infoName]
  local value = tostring(reactor.stats[infoName]) .. info.unit
  local maxLength = 30
  local padding = math.max(0, maxLength - #value)

  gpu.set(
    info.x,
    info.y,
    info.title .. value .. string.rep(" ", padding)
  )
end

local function printDebug()
  local maxLength = 132
  local info = debug.print
  local rodsValues = ""

  for key, value in pairs(reactorRodsLevel) do
    rodsValues = rodsValues .. "[" .. tostring(key) .. "]" .. tostring(value)
  end

  local debugInformation =
    "maxRF:" .. tostring(maxRF) ..
    ", RodsLev:" .. rodsValues ..
    ", curRodLev:" .. tostring(currentRodLevel) ..
    ", curRf:" .. tostring(currentRf) ..
    ", curRfT:" .. tostring(currentRfTick) ..
    ", min-max:" .. tostring(minPowerRod) .. "-" .. tostring(maxPowerRod)

  local padding = math.max(0, maxLength - #debugInformation)

  gpu.set(
    info.x,
    info.y,
    info.title .. debugInformation .. string.rep(" ", padding)
  )
end

-- ============================================================
-- Main rendering loop
-- ============================================================

local function draw()
  if maxRF < reactor.stats.tick then
    maxRF = reactor.stats.tick
  end

  if currentRfTick ~= reactor.stats.tick then
    currentRfTick = reactor.stats.tick

    local width = 0
    if maxRF > 0 then
      width = math.ceil(graphs.tick.width * (currentRfTick / maxRF))
    end

    local graph = {
      x = graphs.tick.x,
      y = graphs.tick.y,
      width = width,
      height = graphs.tick.height
    }

    printInfos("tick")
    printGraphs("tick")
    printActiveGraph(graph)
  end

  if currentRf ~= reactor.stats.stored then
    currentRf = reactor.stats.stored

    local width = math.ceil(graphs.stored.width * (currentRf / 10000000))
    width = math.max(0, math.min(graphs.stored.width, width))

    local graph = {
      x = graphs.stored.x,
      y = graphs.stored.y,
      width = width,
      height = graphs.stored.height
    }

    printInfos("stored")
    printGraphs("stored")
    printActiveGraph(graph)
  end

  if currentRodLevel ~= reactor.stats.rods then
    currentRodLevel = reactor.stats.rods

    local width = math.ceil(graphs.rods.width * (currentRodLevel / 100))
    width = math.max(0, math.min(graphs.rods.width, width))

    local graph = {
      x = graphs.rods.x,
      y = graphs.rods.y,
      width = width,
      height = graphs.rods.height
    }

    printInfos("rods")
    printGraphs("rods")
    printActiveGraph(graph)
  end

  if currentFuel ~= reactor.stats.fuel then
    currentFuel = reactor.stats.fuel
    printInfos("fuel")
  end

  printControlInfos()

  if DEBUG then
    printDebug()
  end
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

  if DEBUG then
    printDebug()
  end

  for name in pairs(sections) do
    printBorders(name)
  end

  for name in pairs(graphs) do
    printGraphs(name)
  end

  for name in pairs(infos) do
    printInfos(name)
  end

  printStaticControlText()
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
