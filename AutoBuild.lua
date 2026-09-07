-- AutoBuild.lua - OpenComputers 1.7.10 / 1.8.10
-- Automatic builder with a temporary overhead refill container.
-- Slot 1 = the user's container. Slots 2+ = building material.
-- START is never a building position.
-- The container is placed ABOVE the robot at the refill point, used, then broken and recovered.

local function loadNibnav()
  local ok, nav = pcall(require, "nibnav")
  if ok and nav then return nav end
  for _, path in ipairs({"/lib/nibnav.lua", "/nibnav.lua"}) do
    local f = io.open(path, "r")
    if f then
      f:close()
      local ok2, loaded = pcall(dofile, path)
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

local START_X, START_Y, START_Z = 0, 1, 0
local REFILL_X, REFILL_Y, REFILL_Z = 0, 1, 1

local function yieldNow() computer.pullSignal(0) end

local function status(text)
  print(string.format("[%d/%d/%d] %s", nav.getX(), nav.getY(), nav.getZ(), text))
  yieldNow()
end

local function moveToY(y)
  while nav.getY() < y do
    local ok, err = nav.up()
    if not ok then return false, err end
    yieldNow()
  end
  while nav.getY() > y do
    local ok, err = nav.down()
    if not ok then return false, err end
    yieldNow()
  end
  return true
end

local function goToPoint(x, y, z)
  local ok, err = nav.moveXZ(x, z)
  if not ok then return false, err end
  return moveToY(y)
end

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
    if name:sub(-4):lower() == ".txt" then
      result[#result + 1] = "/home/" .. name
    end
    yieldNow()
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
    yieldNow()
  end
  io.write("Nummer wählen: ")
  local n = tonumber(io.read())
  if not n or not models[n] then error("Ungültige Auswahl") end
  return models[n]
end

local function materialCount()
  local total = 0
  for slot = 2, robot.inventorySize() do
    total = total + robot.count(slot)
    yieldNow()
  end
  return total
end

local function findBuildingSlot()
  for slot = 2, robot.inventorySize() do
    if robot.count(slot) > 0 then return slot end
    yieldNow()
  end
  return nil
end

-- Slot 1 is the container. It is temporarily placed ABOVE the robot.
-- OpenComputers supports placeUp/suckUp/swingUp on the robot component.
local function refill()
  local oldX, oldY, oldZ = nav.getX(), nav.getY(), nav.getZ()

  status("Baumaterial leer - fahre zum Nachfüllpunkt")
  local ok, err = goToPoint(REFILL_X, REFILL_Y, REFILL_Z)
  if not ok then error(err) end

  if robot.count(1) <= 0 then
    error("Slot 1 ist leer. Lege dort deinen Container ein.")
  end

  -- The container is ALWAYS placed directly above the robot.
  robot.select(1)
  if robot.detectUp() then
    error("Über dem Nachfüllpunkt ist bereits ein Block. Dort kann der Container nicht aufgestellt werden.")
  end

  local placed, reason = robot.placeUp()
  if not placed then
    error("Container aus Slot 1 konnte nicht über dem Roboter aufgestellt werden: " .. tostring(reason))
  end
  yieldNow()

  -- Pull building material DOWN from the overhead container into slots 2+.
  local before = materialCount()
  local gotMaterial = false
  for _ = 1, 32 do
    local target = findBuildingSlot() or 2
    if target == 1 then target = 2 end
    robot.select(target)
    local sucked = pcall(robot.suckUp, 64)
    yieldNow()
    if sucked and materialCount() > before then
      gotMaterial = true
      break
    end
  end

  -- The overhead container is the only block we remove here.
  robot.select(1)
  if robot.detectUp() then
    local broken = pcall(robot.swingUp)
    yieldNow()
    if not broken then
      error("Der Container über dem Roboter konnte nicht abgebaut werden.")
    end
  end

  -- Recover the container into slot 1 if it dropped above/near the robot.
  if robot.count(1) == 0 then
    robot.select(1)
    pcall(robot.suckUp, 64)
    yieldNow()
  end

  if robot.count(1) <= 0 then
    error("Der Container konnte nicht wieder in Slot 1 aufgenommen werden.")
  end
  if not gotMaterial then
    error("Kein Baumaterial aus dem Container über dem Roboter erhalten.")
  end

  status("Nachfüllung fertig - Container wieder in Slot 1")
  ok, err = goToPoint(oldX, oldY, oldZ)
  if not ok then error(err) end
end

local function placeBlock()
  local slot = findBuildingSlot()
  if not slot then
    refill()
    slot = findBuildingSlot()
  end
  if not slot then error("Kein Baumaterial vorhanden.") end

  -- Never break an existing block at the build target.
  if robot.detectDown() then
    error("Ziel ist bereits belegt. Es wird NICHT abgebaut.")
  end

  robot.select(slot)
  local ok, reason = robot.placeDown()
  if not ok then
    error("Block konnte nicht platziert werden: " .. tostring(reason))
  end
  yieldNow()
end

local function build(modelPath)
  requirePickaxe()
  local sizeX, sizeY, sizeZ, voxels = readModel(modelPath)

  nav.setPosition(START_X, START_Y, START_Z, sides.east)

  -- Fill once before building. START remains completely free.
  refill()

  if sizeX > 0 then
    local ok, err = nav.faceSide(sides.east)
    if not ok then error(err) end
    ok, err = nav.forward()
    if not ok then error(err) end
  end

  for y = 0, sizeY - 1 do
    status(string.format("Ebene %d/%d", y + 1, sizeY))

    for z = 0, sizeZ - 1 do
      local reverse = (z % 2 == 1)

      for step = 0, sizeX - 1 do
        local x = reverse and (sizeX - 1 - step) or step
        local index = x + z * sizeX + y * sizeX * sizeZ + 1

        if voxels[index] == 1 then placeBlock() end

        if step < sizeX - 1 then
          local ok, moveErr = nav.forward()
          if not ok then error(moveErr) end
        end
        yieldNow()
      end

      if z < sizeZ - 1 then
        local ok, err
        if reverse then
          ok, err = nav.turnLeft(); if not ok then error(err) end
          ok, err = nav.forward(); if not ok then error(err) end
          ok, err = nav.turnLeft(); if not ok then error(err) end
        else
          ok, err = nav.turnRight(); if not ok then error(err) end
          ok, err = nav.forward(); if not ok then error(err) end
          ok, err = nav.turnRight(); if not ok then error(err) end
        end
        yieldNow()
      end
    end

    if y < sizeY - 1 then
      local ok, err = nav.up()
      if not ok then error(err) end
      yieldNow()
    end
  end

  status("Aufbau abgeschlossen - STARTPUNKT blieb frei")
end

local model = chooseModel()
print("Modell: " .. model)
print("Slot 1: dein Container -> wird ÜBER dem Roboter aufgestellt")
print("Slots 2+: Baumaterial")
print("START:  X=" .. START_X .. " Y=" .. START_Y .. " Z=" .. START_Z .. " -> niemals bauen")
print("REFILL: X=" .. REFILL_X .. " Y=" .. REFILL_Y .. " Z=" .. REFILL_Z)
print("Starte automatische Nachfüllung...")
yieldNow()
build(model)
