-- AutoBuild.lua
-- OpenComputers 1.7.10 / 1.8.10 compatible
-- Slot 1 = chest/refill. Slots 2..N = building material.
-- The robot's dedicated tool slot is used for mining. No pickaxe item ID is hard-coded:
-- vanilla and modded pickaxes (including Tinkers' Construct) are handled by robot.swing().

local function loadNibnav()
  local ok, nav = pcall(require, "nibnav")
  if ok and nav then return nav end

  local paths = {"/lib/nibnav.lua", "/nibnav.lua"}
  for i = 1, #paths do
    local f = io.open(paths[i], "r")
    if f then
      f:close()
      local ok2, loaded = pcall(dofile, paths[i])
      if ok2 and loaded then return loaded end
    end
  end
  error("nibnav.lua not found")
end

local nav = loadNibnav()
local sides = require("sides")
local robot = require("robot")
local computer = require("computer")
local filesystem = require("filesystem")

-- The robot starts one block above the first model layer.
-- This prevents placeDown() from trying to place into the ground/start block.
local START_X, START_Y, START_Z = 0, 1, 0
local CHARGE_X, CHARGE_Y, CHARGE_Z = 1, 1, 0
local CHARGE_WAIT_MARGIN = 100

local function status(text)
  local x, y, z = nav.getX(), nav.getY(), nav.getZ()
  print(string.format("[%d/%d/%d] %s", x, y, z, text))
end

local function energyOK()
  local max = computer.maxEnergy()
  return computer.energy() >= math.min(max - CHARGE_WAIT_MARGIN, max * 0.25)
end

local function goToChargePoint()
  local x, y, z = nav.getX(), nav.getY(), nav.getZ()
  status("Energie niedrig - fahre zum Ladepunkt")
  local ok, err = nav.moveXZ(CHARGE_X, CHARGE_Z)
  if not ok then error(err) end
  while nav.getY() < CHARGE_Y do
    ok, err = nav.up()
    if not ok then error(err) end
  end
  while nav.getY() > CHARGE_Y do
    ok, err = nav.down()
    if not ok then error(err) end
  end
  while not energyOK() do
    os.sleep(1)
  end
  status("Energie ausreichend - kehre zur Arbeitsposition zurück")
  ok, err = nav.moveXZ(x, z)
  if not ok then error(err) end
  while nav.getY() < y do
    ok, err = nav.up()
    if not ok then error(err) end
  end
  while nav.getY() > y do
    ok, err = nav.down()
    if not ok then error(err) end
  end
end

local function ensureEnergy()
  if not energyOK() then
    goToChargePoint()
  end
end

-- A pickaxe is NOT identified by a fixed item name/id. This is intentional:
-- Tinkers' Construct tools can have generated tool data/NBT and many materials.
-- OpenComputers exposes the equipped robot tool through robot.swing(), so any
-- compatible pickaxe equipped in the robot's tool slot is usable.
local function hasUsableTool()
  local ok, value = pcall(robot.durability)
  if ok and type(value) == "number" then
    return value > 0
  end
  return false
end

local function requirePickaxe()
  if not hasUsableTool() then
    error("Keine verwendbare Spitzhacke im Roboter-Werkzeugslot. Vanilla-, Tinkers'- und Mod-Spitzhacken werden unterstützt, sofern OpenComputers sie als Werkzeug verwenden kann.")
  end
end

-- Optional helper for places where mining is explicitly requested.
-- It only swings when the caller asks for it; navigation itself never mines.
local function mineForward()
  ensureEnergy()
  requirePickaxe()
  local ok, reason = robot.swing()
  if not ok then
    return false, reason or "Block konnte nicht abgebaut werden"
  end
  return true
end

local function readModel(path)
  local f = io.open(path, "r")
  if not f then error("Could not open model: " .. path) end
  local data = f:read("*a")
  f:close()

  local lines = {}
  for line in data:gmatch("([^\r\n]+)") do
    lines[#lines + 1] = line
  end
  if #lines == 0 then error("Model file is empty: " .. path) end

  local dimX, dimY, dimZ
  local start = 1
  for i = 1, math.min(#lines, 20) do
    local x, y, z = lines[i]:match("dim%s+(%d+)%s+(%d+)%s+(%d+)")
    if x then
      dimX, dimY, dimZ = tonumber(x), tonumber(y), tonumber(z)
    end
    if lines[i] == "data" then
      start = i + 1
      break
    end
  end

  if not dimX then error("Invalid binvox model: missing dim line") end

  local voxels = {}
  local idx = 1
  for i = start, #lines do
    local line = lines[i]
    for value in line:gmatch("[01]") do
      voxels[idx] = tonumber(value)
      idx = idx + 1
    end
  end

  return dimX, dimY, dimZ, voxels
end

local function findModels()
  local result = {}
  for name in filesystem.list("/home") do
    if name:sub(-4):lower() == ".txt" then
      result[#result + 1] = "/home/" .. name
    end
  end
  table.sort(result)
  return result
end

local function chooseModel()
  local models = findModels()
  if #models == 0 then
    error("No .txt files found in /home. Put a binvox .txt model there.")
  end
  if #models == 1 then return models[1] end

  print("Gefundene Modelle:")
  for i = 1, #models do
    print(string.format("%d) %s", i, models[i]))
  end
  io.write("Nummer wählen: ")
  local n = tonumber(io.read())
  if not n or not models[n] then error("Ungültige Auswahl") end
  return models[n]
end

local function refill()
  local oldX, oldY, oldZ = nav.getX(), nav.getY(), nav.getZ()
  status("Material leer - fahre zum Lade-/Nachfüllpunkt")

  local ok, err = nav.moveXZ(CHARGE_X, CHARGE_Z)
  if not ok then error(err) end
  while nav.getY() < CHARGE_Y do
    ok, err = nav.up()
    if not ok then error(err) end
  end
  while nav.getY() > CHARGE_Y do
    ok, err = nav.down()
    if not ok then error(err) end
  end

  -- Keep slot 1 reserved for the chest/refill setup.
  for slot = 2, robot.inventorySize() do
    if robot.space(slot) > 0 then
      robot.select(slot)
      robot.suck(64)
    end
  end

  status("Material nachgefüllt - kehre zur Arbeitsposition zurück")
  ok, err = nav.moveXZ(oldX, oldZ)
  if not ok then error(err) end
  while nav.getY() < oldY do
    ok, err = nav.up()
    if not ok then error(err) end
  end
  while nav.getY() > oldY do
    ok, err = nav.down()
    if not ok then error(err) end
  end
end

local function findBuildingSlot()
  for slot = 2, robot.inventorySize() do
    if robot.count(slot) > 1 then
      return slot
    end
  end
  return nil
end

local function placeBlock()
  ensureEnergy()
  local slot = findBuildingSlot()
  if not slot then
    refill()
    slot = findBuildingSlot()
  end
  if not slot then
    error("Kein Baumaterial vorhanden.")
  end

  -- Deliberately do NOT break an occupied target. This preserves the
  -- inventory-safe behavior and prevents unwanted drops/junk.
  if robot.detectDown() then
    error("Cannot place block: target position is occupied. No block was broken.")
  end

  robot.select(slot)
  local ok, reason = robot.placeDown()
  if not ok then
    error("Block konnte nicht platziert werden: " .. tostring(reason))
  end
end

local function build(modelPath)
  local sizeX, sizeY, sizeZ, voxels = readModel(modelPath)
  nav.setPosition(START_X, START_Y, START_Z, sides.east)

  for y = 0, sizeY - 1 do
    status(string.format("Ebene %d/%d", y + 1, sizeY))

    -- Robot stands one block above the layer it builds.
    for z = 0, sizeZ - 1 do
      local reverse = (z % 2 == 1)
      for step = 0, sizeX - 1 do
        local x = reverse and (sizeX - 1 - step) or step
        local index = x + z * sizeX + y * sizeX * sizeZ + 1
        if voxels[index] == 1 then
          placeBlock()
        end

        if step < sizeX - 1 then
          local ok, err = nav.forward()
          if not ok then error(err) end
        end
      end

      if z < sizeZ - 1 then
        if reverse then
          nav.turnLeft()
          local ok, err = nav.forward()
          if not ok then error(err) end
          nav.turnLeft()
        else
          nav.turnRight()
          local ok, err = nav.forward()
          if not ok then error(err) end
          nav.turnRight()
        end
      end
    end

    if y < sizeY - 1 then
      local ok, err = nav.up()
      if not ok then error(err) end
    end
  end

  status("Aufbau abgeschlossen")
end

local model = chooseModel()
print("Modell: " .. model)
print("Werkzeug: Jede von OpenComputers unterstützte Spitzhacke kann verwendet werden, einschließlich Tinkers' Construct.")
print("Startposition des Roboters: X=" .. START_X .. " Y=" .. START_Y .. " Z=" .. START_Z)
print("Lade-/Nachfüllpunkt: X=" .. CHARGE_X .. " Y=" .. CHARGE_Y .. " Z=" .. CHARGE_Z)
build(model)
