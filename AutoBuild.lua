-- AutoBuild.lua
-- OpenComputers-MC1.7.10-1.8.10+667626d
-- Uses the bundled nibnav.lua navigation library.

local function loadNibnav()
  local ok, nav = pcall(require, "nibnav")
  if ok and nav then
    return nav
  end

  local paths = {"/lib/nibnav.lua", "/nibnav.lua"}
  for i = 1, #paths do
    local loader, loadError = loadfile(paths[i])
    if loader then
      local loaded, navOrError = pcall(loader)
      if loaded and type(navOrError) == "table" then
        return navOrError
      end
    end
  end

  error("nibnav.lua not found. Install it as /lib/nibnav.lua or /nibnav.lua on the robot.")
end

local nav = loadNibnav()
local sides = require("sides")
local robot = require("robot")
local computer = require("computer")

-- OpenComputers/OpenOS normally uses /home for user files.
-- Try common locations so the model does not have to be moved to /.
local MODEL_FILES = {
  "/home/industrialbuilding.txt",
  "/industrialbuilding.txt",
  "industrialbuilding.txt"
}

nav.setPosition(0, 0, 0, sides.east)

local function explode(div, str)
  if div == "" then return false end
  local result = {}
  local pos = 1
  while true do
    local startPos, endPos = string.find(str, div, pos, true)
    if not startPos then break end
    result[#result + 1] = string.sub(str, pos, startPos - 1)
    pos = endPos + 1
  end
  result[#result + 1] = string.sub(str, pos)
  return result
end

local function refill()
  robot.select(1)
  robot.swingUp()
  robot.placeUp()

  for slot = 2, robot.inventorySize() do
    if robot.space(slot) > 0 then
      robot.select(slot)
      print("Filling Slot " .. tostring(slot))
      repeat
        local before = robot.space()
        local sucked = robot.suckUp(robot.space())
        if not sucked or robot.space() == before then
          os.sleep(5)
        end
      until robot.space() < 1
    end
  end

  robot.select(1)
  robot.swingUp()
  robot.select(2)
end

local function placeBlock()
  if robot.count() < 2 then
    local findSlot = 0

    for slot = 2, robot.inventorySize() do
      if robot.count(slot) > 1 then
        findSlot = slot
        print("Next Slot: " .. tostring(findSlot))
        break
      end
    end

    if findSlot < 1 then
      refill()
      findSlot = 2
    end

    robot.select(findSlot)
  end

  repeat
    robot.swingDown()
  until robot.placeDown()
end

local function refuel(lastY)
  print("Need to refuel, going to 0,0,0")
  print("Energy before goto 0,0,0 : " .. tostring(computer.energy()))
  print("Calculated fuel to 0,0,0 : " .. tostring(nav.getCost(0, 0, 0)))

  local ok, err = nav.moveXZ(0, 0)
  if not ok then error(err or "Could not return to refill position") end
  ok, err = nav.moveY(0)
  if not ok then error(err or "Could not return to refill height") end

  print("Energy after goto 0,0,0 : " .. tostring(computer.energy()))
  while computer.maxEnergy() - computer.energy() > 100 do
    os.sleep(1)
  end

  ok, err = nav.moveY(lastY)
  if not ok then error(err or "Could not restore build height") end
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

local function openModel()
  local errors = {}
  for i = 1, #MODEL_FILES do
    local path = MODEL_FILES[i]
    local file, err = io.open(path, "r")
    if file then
      print("Model: " .. path)
      return file, path
    end
    errors[#errors + 1] = path .. " (" .. tostring(err or "not found") .. ")"
  end

  error("industrialbuilding.txt not found. Tried:\n  " .. table.concat(errors, "\n  "))
end

local file = openModel()
local ok, runError = pcall(function()
  local maxx, maxy, maxz = readBinvox(file)
  local layer = {}

  for y = 0, maxy - 1 do
    print("Ebene " .. tostring(y))

    for z = 1, maxz do
      local line = file:read("*l")
      if not line then
        error("Unexpected end of model at y=" .. y .. ", z=" .. z)
      end
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
              minway = travelCost
              nextX = x
              nextZ = z
            end
          end
        end
      end

      if nextX and nextZ then
        print("NextX = " .. tostring(nextX) .. ", NextZ = " .. tostring(nextZ))

        local moveOK, moveError = nav.moveXZ(nextX, nextZ)
        if not moveOK then error(moveError or "Unable to reach next block") end

        placeBlock()
        layer[nextZ][nextX] = "0"
        findings = findings - 1
        print("Noch " .. tostring(findings) .. " Bloecke zu setzen")

        local refuelCost = nav.getCost(0, 0, 0)
        local maxTravelCost = maxx * 3 * 15 + 10
        if computer.energy() < refuelCost + maxTravelCost then
          refuel(y)
        end

        os.sleep(0.1)
      end
    end

    local upOK, upError = nav.up()
    if not upOK then error(upError or "Unable to move to next layer") end
  end

  file:close()
  file = nil

  local moveOK, moveError = nav.moveXZ(0, 0)
  if not moveOK then error(moveError or "Unable to return home") end
  moveOK, moveError = nav.moveY(0)
  if not moveOK then error(moveError or "Unable to return to base height") end
  nav.faceSide(sides.east)
end)

if file then file:close() end
if not ok then error(runError, 0) end

print("AutoBuild finished successfully.")
