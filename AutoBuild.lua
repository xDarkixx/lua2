-- AutoBuild.lua
-- OpenComputers-MC1.7.10-1.8.10+667626d
-- Shows current layer/position and returns to the charging/refill point when low.
-- Slot 1 is reserved for the chest. Slots 2..N are building blocks.

local function loadNibnav()
  local ok, nav = pcall(require, "nibnav")
  if ok and nav then return nav end
  local paths = {"/lib/nibnav.lua", "/nibnav.lua"}
  for i = 1, #paths do
    local loader = loadfile(paths[i])
    if loader then
      local loaded, module = pcall(loader)
      if loaded and type(module) == "table" then return module end
    end
  end
  error("nibnav.lua not found. Install it as /lib/nibnav.lua or /nibnav.lua on the robot.")
end

local nav = loadNibnav()
local sides = require("sides")
local robot = require("robot")
local computer = require("computer")
local filesystem = require("filesystem")

-- The build origin is (0,0,0). The refill/charging point is kept one block
-- in front of it so the robot can leave the build area free.
local START_X, START_Y, START_Z = 0, 0, 0
local CHARGE_X, CHARGE_Y, CHARGE_Z = 1, 0, 0

nav.setPosition(START_X, START_Y, START_Z, sides.east)

local currentLayer = 0
local maxLayer = 0

local function status(message)
  print(string.format("[AutoBuild] Ebene %d/%d | Position X:%d Y:%d Z:%d | %s",
    currentLayer + 1, maxLayer, nav.getX(), nav.getY(), nav.getZ(), message or ""))
end

local function explode(div, str)
  if div == "" then return false end
  local result, pos = {}, 1
  while true do
    local a, b = string.find(str, div, pos, true)
    if not a then break end
    result[#result + 1] = string.sub(str, pos, a - 1)
    pos = b + 1
  end
  result[#result + 1] = string.sub(str, pos)
  return result
end

-- Fills only non-full material slots. No repeated "slot full" messages.
local function refill()
  status("Material wird aufgefüllt")
  local oldX, oldY, oldZ = nav.getX(), nav.getY(), nav.getZ()

  -- Go to the dedicated refill/charging point first.
  local ok, err = nav.moveXZ(CHARGE_X, CHARGE_Z)
  if not ok then error(err or "Could not reach charging/refill point") end
  ok, err = nav.moveY(CHARGE_Y)
  if not ok then error(err or "Could not reach charging/refill height") end

  robot.select(1)
  robot.swingUp()
  robot.placeUp()

  for slot = 2, robot.inventorySize() do
    if robot.space(slot) > 0 then
      robot.select(slot)
      while robot.space() > 0 do
        local before = robot.count()
        local sucked = robot.suckUp(robot.space())
        local after = robot.count()
        if after == before and not sucked then break end
        if after >= 64 then break end
      end
    end
  end

  robot.select(1)
  robot.swingUp()
  robot.select(2)

  -- Return to the exact position where the robot left the build.
  ok, err = nav.moveY(oldY)
  if not ok then error(err or "Could not restore build height") end
  ok, err = nav.moveXZ(oldX, oldZ)
  if not ok then error(err or "Could not return to build position") end
  status("Material aufgefüllt")
end

-- Never break the block below the robot. This prevents drops from entering
-- the inventory and keeps the inventory clean.
local function placeBlock()
  local findSlot = 0

  if robot.count() < 2 then
    for slot = 2, robot.inventorySize() do
      if robot.count(slot) > 1 then
        findSlot = slot
        break
      end
    end

    if findSlot < 1 then
      refill()
      for slot = 2, robot.inventorySize() do
        if robot.count(slot) > 1 then
          findSlot = slot
          break
        end
      end
    end

    if findSlot < 1 then
      error("No building blocks available in slots 2.." .. robot.inventorySize())
    end
    robot.select(findSlot)
  end

  if robot.detectDown() then
    error("Cannot place block: target position is occupied. No block was broken.")
  end

  if not robot.placeDown() then
    error("Could not place building block without breaking the target block.")
  end
end

-- Return to the dedicated charging point whenever energy is low, recharge,
-- then return to the exact build position.
local function refuel(lastY)
  status("Energie niedrig - gehe zum Charging Point")
  local oldX, oldY, oldZ = nav.getX(), nav.getY(), nav.getZ()

  local ok, err = nav.moveXZ(CHARGE_X, CHARGE_Z)
  if not ok then error(err or "Could not reach charging point") end
  ok, err = nav.moveY(CHARGE_Y)
  if not ok then error(err or "Could not reach charging height") end

  status("Lade Energie auf")
  while computer.maxEnergy() - computer.energy() > 100 do
    os.sleep(1)
  end

  ok, err = nav.moveY(oldY)
  if not ok then error(err or "Could not restore build height") end
  ok, err = nav.moveXZ(oldX, oldZ)
  if not ok then error(err or "Could not return to build position") end
  status("Zurück am Baupunkt")
end

local function readBinvox(file)
  local line = file:read("*l")
  if not line then error("Empty model file") end
  line = file:read("*l")
  if not line then error("Missing binvox dim line") end
  local sx, sy, sz = line:match("dim%s+(%d+)%s+(%d+)%s+(%d+)")
  local maxx, maxy, maxz = tonumber(sx), tonumber(sy), tonumber(sz)
  if not maxx or not maxy or not maxz then
    error("Invalid binvox dimensions: " .. tostring(line))
  end
  local translate = file:read("*l")
  local scale = file:read("*l")
  local data = file:read("*l")
  if not translate or not scale or data ~= "data" then
    error("Invalid binvox header: translate/scale/data missing")
  end
  return maxx, maxy, maxz
end

local function findTextFiles()
  local files = {}
  local ok, iterator = pcall(filesystem.list, "/home")
  if not ok or not iterator then
    error("Cannot read /home. OpenOS filesystem library is unavailable.")
  end
  for name in iterator do
    if type(name) == "string" then
      name = name:gsub("/$", "")
      if name:lower():sub(-4) == ".txt" then
        files[#files + 1] = "/home/" .. name
      end
    end
  end
  table.sort(files)
  return files
end

local function openModel()
  local files = findTextFiles()
  if #files == 0 then
    error("No .txt files found in /home. Copy a binvox ASCII TXT model into /home.")
  end

  print("")
  print("=== AutoBuild: TXT-Dateien in /home ===")
  for i = 1, #files do
    print(string.format("[%d] %s", i, files[i]))
  end

  local selected = 1
  if #files > 1 then
    print("")
    print("Welche Datei soll gebaut werden? Nummer eingeben (1-" .. #files .. "):")
    local answer = io.read()
    local number = tonumber(answer or "")
    if number and number >= 1 and number <= #files then
      selected = math.floor(number)
    else
      print("Ungültige Auswahl - verwende: " .. files[1])
    end
  end

  local path = files[selected]
  local file, err = io.open(path, "r")
  if not file then error("Could not open model " .. path .. ": " .. tostring(err or "")) end
  print("Model ausgewählt: " .. path)
  return file
end

local file = openModel()
local ok, runError = pcall(function()
  local maxx, maxy, maxz = readBinvox(file)
  maxLayer = maxy
  local layer = {}

  status("Start - Charging Point bei X:1 Y:0 Z:0")

  for y = 0, maxy - 1 do
    currentLayer = y
    status("Starte Ebene")
    for z = 1, maxz do
      local line = file:read("*l")
      if not line then error("Unexpected end of model at y=" .. y .. ", z=" .. z) end
      layer[z] = explode(" ", line)
    end

    local findings = 1
    while findings > 0 do
      local minway = maxx * 3 * 15 + 10
      local nextX, nextZ
      findings = 0
      for x = 1, maxx do
        for z = 1, maxz do
          if layer[z] and layer[z][x] == "1" then
            findings = findings + 1
            local travelCost = nav.getCost(x, y, z)
            if travelCost < minway then
              minway, nextX, nextZ = travelCost, x, z
            end
          end
        end
      end

      if nextX and nextZ then
        status("Gehe zu Block X:" .. nextX .. " Z:" .. nextZ)
        local moveOK, moveError = nav.moveXZ(nextX, nextZ)
        if not moveOK then error(moveError or "Unable to reach next block") end
        placeBlock()
        layer[nextZ][nextX] = "0"
        findings = findings - 1

        if computer.energy() < nav.getCost(CHARGE_X, CHARGE_Y, CHARGE_Z) + maxx * 3 * 15 + 10 then
          refuel(y)
        end
        os.sleep(0.1)
      end
    end

    if y < maxy - 1 then
      local upOK, upError = nav.up()
      if not upOK then error(upError or "Unable to move to next layer") end
    end
  end

  status("Bau fertig - Rückkehr zum Start")
  local moveOK, moveError = nav.moveXZ(START_X, START_Z)
  if not moveOK then error(moveError or "Unable to return home") end
  moveOK, moveError = nav.moveY(START_Y)
  if not moveOK then error(moveError or "Unable to return to base height") end
  nav.faceSide(sides.east)
end)

if file then file:close() end
if not ok then error(runError, 0) end
print("AutoBuild finished successfully.")
