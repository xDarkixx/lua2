-- AutoBuild.lua - OpenComputers 1.7.10 / 1.8.10
-- Watchdog-safe builder. All long loops yield to the OC event loop.

local function loadNibnav()
  local ok, nav = pcall(require, "nibnav")
  if ok and nav then return nav end
  for _, path in ipairs({"/lib/nibnav.lua", "/nibnav.lua"}) do
    local f = io.open(path, "r")
    if f then f:close(); local ok2, loaded = pcall(dofile, path); if ok2 and loaded then return loaded end end
  end
  error("nibnav.lua not found")
end

local nav = loadNibnav()
local sides = require("sides")
local robot = require("robot")
local computer = require("computer")
local filesystem = require("filesystem")

local START_X, START_Y, START_Z = 0, 1, 0
local CHARGE_X, CHARGE_Y, CHARGE_Z = 1, 1, 0
local CHARGE_WAIT_MARGIN = 100

local function yieldNow()
  computer.pullSignal(0)
end

local function status(text)
  print(string.format("[%d/%d/%d] %s", nav.getX(), nav.getY(), nav.getZ(), text))
  yieldNow()
end

local function energyOK()
  local max = computer.maxEnergy()
  return computer.energy() >= math.min(max - CHARGE_WAIT_MARGIN, max * 0.25)
end

local function moveToY(y)
  while nav.getY() < y do
    local ok, err = nav.up(); if not ok then return false, err end
    yieldNow()
  end
  while nav.getY() > y do
    local ok, err = nav.down(); if not ok then return false, err end
    yieldNow()
  end
  return true
end

local function goToPoint(x, y, z)
  local ok, err = nav.moveXZ(x, z)
  if not ok then return false, err end
  yieldNow()
  return moveToY(y)
end

local function goToChargePoint()
  local x, y, z = nav.getX(), nav.getY(), nav.getZ()
  status("Energie niedrig - fahre zum Ladepunkt")
  local ok, err = goToPoint(CHARGE_X, CHARGE_Y, CHARGE_Z)
  if not ok then error(err) end
  while not energyOK() do yieldNow() end
  status("Energie ausreichend - kehre zurück")
  ok, err = goToPoint(x, y, z)
  if not ok then error(err) end
end

local function ensureEnergy()
  if not energyOK() then goToChargePoint() end
end

-- No item IDs are hard-coded. This keeps vanilla, modded and Tinkers' Construct
-- tools usable through the OpenComputers robot tool slot.
local function hasUsableTool()
  local ok, durability = pcall(robot.durability)
  return ok and type(durability) == "number" and durability > 0
end

local function requirePickaxe()
  if not hasUsableTool() then
    error("Keine verwendbare Spitzhacke/Werkzeug im Roboter-Werkzeugslot.")
  end
end

local function readModel(path)
  local f = io.open(path, "r")
  if not f then error("Could not open model: " .. path) end
  local data = f:read("*a")
  f:close()
  yieldNow()

  local lines = {}
  for line in data:gmatch("([^\r\n]+)") do
    lines[#lines + 1] = line
    yieldNow()
  end
  if #lines == 0 then error("Model file is empty: " .. path) end

  local dimX, dimY, dimZ, start = nil, nil, nil, 1
  for i = 1, math.min(#lines, 30) do
    local x, y, z = lines[i]:match("dim%s+(%d+)%s+(%d+)%s+(%d+)")
    if x then dimX, dimY, dimZ = tonumber(x), tonumber(y), tonumber(z) end
    if lines[i] == "data" then start = i + 1; break end
    yieldNow()
  end
  if not dimX then error("Invalid binvox model: missing dim line") end

  local voxels, idx = {}, 1
  for i = start, #lines do
    for value in lines[i]:gmatch("[01]") do
      voxels[idx] = tonumber(value)
      idx = idx + 1
      yieldNow()
    end
  end
  return dimX, dimY, dimZ, voxels
end

local function findModels()
  local result = {}
  for name in filesystem.list("/home") do
    if name:sub(-4):lower() == ".txt" then result[#result + 1] = "/home/" .. name end
    yieldNow()
  end
  table.sort(result)
  return result
end

local function chooseModel()
  local models = findModels()
  if #models == 0 then error("No .txt files found in /home. Put a binvox .txt model there.") end
  if #models == 1 then return models[1] end
  print("Gefundene Modelle:")
  for i = 1, #models do print(string.format("%d) %s", i, models[i])); yieldNow() end
  io.write("Nummer wählen: ")
  local n = tonumber(io.read())
  if not n or not models[n] then error("Ungültige Auswahl") end
  return models[n]
end

local function refill()
  local oldX, oldY, oldZ = nav.getX(), nav.getY(), nav.getZ()
  status("Material leer - fahre zum Lade-/Nachfüllpunkt")
  local ok, err = goToPoint(CHARGE_X, CHARGE_Y, CHARGE_Z)
  if not ok then error(err) end
  for slot = 2, robot.inventorySize() do
    if robot.space(slot) > 0 then robot.select(slot); robot.suck(64) end
    yieldNow()
  end
  status("Material nachgefüllt - kehre zurück")
  ok, err = goToPoint(oldX, oldY, oldZ)
  if not ok then error(err) end
end

local function findBuildingSlot()
  for slot = 2, robot.inventorySize() do
    if robot.count(slot) > 1 then return slot end
    yieldNow()
  end
end

local function placeBlock()
  ensureEnergy()
  local slot = findBuildingSlot()
  if not slot then refill(); slot = findBuildingSlot() end
  if not slot then error("Kein Baumaterial vorhanden.") end
  if robot.detectDown() then error("Cannot place block: target position is occupied. No block was broken.") end
  robot.select(slot)
  local ok, reason = robot.placeDown()
  if not ok then error("Block konnte nicht platziert werden: " .. tostring(reason)) end
  yieldNow()
end

local function build(modelPath)
  local sizeX, sizeY, sizeZ, voxels = readModel(modelPath)
  nav.setPosition(START_X, START_Y, START_Z, sides.east)

  for y = 0, sizeY - 1 do
    status(string.format("Ebene %d/%d", y + 1, sizeY))
    for z = 0, sizeZ - 1 do
      local reverse = (z % 2 == 1)
      for step = 0, sizeX - 1 do
        local x = reverse and (sizeX - 1 - step) or step
        local index = x + z * sizeX + y * sizeX * sizeZ + 1
        if voxels[index] == 1 then placeBlock() end
        if step < sizeX - 1 then
          local ok, err = nav.forward(); if not ok then error(err) end
        end
        yieldNow()
      end
      if z < sizeZ - 1 then
        if reverse then nav.turnLeft() else nav.turnRight() end
        local ok, err = nav.forward(); if not ok then error(err) end
        if reverse then nav.turnLeft() else nav.turnRight() end
        yieldNow()
      end
    end
    if y < sizeY - 1 then
      local ok, err = nav.up(); if not ok then error(err) end
      yieldNow()
    end
  end
  status("Aufbau abgeschlossen")
end

local model = chooseModel()
print("Modell: " .. model)
print("Werkzeug: Vanilla + modded + Tinkers' Construct")
print("Start: X=" .. START_X .. " Y=" .. START_Y .. " Z=" .. START_Z)
print("Lade-/Nachfüllpunkt: X=" .. CHARGE_X .. " Y=" .. CHARGE_Y .. " Z=" .. CHARGE_Z)
yieldNow()
build(model)
