-- OpenComputers / Minecraft 1.7.10
-- Reads ONE plain-text SCHEMATIC_TXT file and builds it with a robot.
-- No Schematica, Litematica or Minecraft-side converter is required.
--
-- Usage:
--   builder.lua blueprint.txt
--
-- TXT format:
--   SCHEMATIC_TXT 1
--   name=...
--   size=W,H,L
--   materials=...
--   x,y,z=BLOCK_ID:META
--
-- Coordinates are relative to the robot's starting position.
-- The robot starts at (0,0,0), facing +X.
-- The robot uses its inventory; an inventory_controller is optional.

local component = require("component")
local robot = require("robot")
local computer = require("computer")
local filesystem = require("filesystem")

local file = ...
if not file then
  io.stderr:write("Usage: builder.lua blueprint.txt\n")
  return
end

local function die(msg)
  io.stderr:write("ERROR: " .. msg .. "\n")
  return false
end

local function split(s, sep)
  local out = {}
  for v in string.gmatch(s, "([^" .. sep .. "]+)") do out[#out+1] = v end
  return out
end

local f, err = io.open(file, "r")
if not f then return die(err or "Datei konnte nicht geöffnet werden") end

local sizeW, sizeH, sizeL
local blocks = {}
local maxIndex = 0
local name = "Schematic"

for line in f:lines() do
  line = line:gsub("^%s+", ""):gsub("%s+$", "")
  if line ~= "" and not line:match("^#") then
    if line == "SCHEMATIC_TXT 1" then
      -- header
    elseif line:match("^name=") then
      name = line:sub(6)
    elseif line:match("^size=") then
      local p = split(line:sub(6), ",")
      if #p ~= 3 then f:close(); return die("Ungültige size") end
      sizeW, sizeH, sizeL = tonumber(p[1]), tonumber(p[2]), tonumber(p[3])
    elseif line:match("^materials=") then
      -- Informational only. Inventory matching is based on the robot inventory.
    else
      local raw = line:gsub("%s+#%s*state=.*$", "")
      local a, b = raw:match("^%s*(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)%s*=%s*(%d+)%s*:%s*(%d+)%s*$")
      if not a then f:close(); return die("Ungültige Blockzeile: " .. line) end
      local x,y,z,id,meta = tonumber(a),tonumber(b),tonumber(line:match("^%s*-?%d+%s*,%s*(-?%d+)%s*,")),tonumber(raw:match("=(%d+)%s*:")),tonumber(raw:match(":%s*(%d+)%s*$"))
      local parts = split(raw:match("^%s*(.-)%s*=") or "", ",")
      x, y, z = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3])
      if not sizeW or x < 0 or y < 0 or z < 0 or x >= sizeW or y >= sizeH or z >= sizeL then
        f:close(); return die("Koordinate außerhalb: " .. x .. "," .. y .. "," .. z) end
      blocks[#blocks+1] = {x=x,y=y,z=z,id=id,meta=meta}
      maxIndex = math.max(maxIndex, #blocks)
    end
  end
end
f:close()
if not sizeW then return die("size= fehlt") end

-- Sort bottom-up. Within a layer we use rows so the robot can move systematically.
table.sort(blocks, function(a,b)
  if a.y ~= b.y then return a.y < b.y end
  if a.z ~= b.z then return a.z < b.z end
  return a.x < b.x
end)

local stateFile = file .. ".state"
local startIndex = 1
local sf = io.open(stateFile, "r")
if sf then startIndex = tonumber(sf:read("*l")) or 1; sf:close() end
if startIndex < 1 then startIndex = 1 end

local function saveState(n)
  local s = io.open(stateFile, "w")
  if s then s:write(tostring(n)); s:close() end
end

local function posName()
  return "[" .. name .. "] "
end

local function forward(n)
  for _=1,n do
    while not robot.forward() do
      if robot.detect() then
        io.stderr:write("Hindernis vor dem Roboter. Entfernen und ENTER drücken.\n")
        io.read()
      else
        computer.beep(800,0.1)
        os.sleep(0.2)
      end
    end
  end
end

local function up(n)
  for _=1,n do
    while not robot.up() do
      if robot.detectUp() then
        io.stderr:write("Hindernis oben. Entfernen und ENTER drücken.\n")
        io.read()
      else os.sleep(0.2) end
    end
  end
end

local function down(n)
  for _=1,n do
    while not robot.down() do
      if robot.detectDown() then
        io.stderr:write("Hindernis unten. Entfernen und ENTER drücken.\n")
        io.read()
      else os.sleep(0.2) end
    end
  end
end

local function placeBlock(meta)
  for slot=1,robot.inventorySize() do
    robot.select(slot)
    if robot.count(slot) > 0 then
      if component.isAvailable("inventory_controller") then
        local ic = component.inventory_controller
        local stack = ic.getStackInInternalSlot(slot)
        if stack and (stack.damage == nil or tonumber(stack.damage) == meta) then
          if robot.placeDown() then return true end
          if robot.place() then return true end
        end
      else
        -- Without inventory_controller we cannot reliably inspect metadata.
        -- Try the selected stack; the user should keep one material type per slot.
        if robot.placeDown() then return true end
        if robot.place() then return true end
      end
    end
  end
  return false
end

-- Return to the requested relative position from the current logical position.
local cx, cy, cz = 0, 0, 0
local function moveTo(x,y,z)
  if cy < y then up(y-cy) elseif cy > y then down(cy-y) end
  if cz < z then
    -- Facing +X initially; turn to +Z.
    robot.turnRight(); forward(z-cz); robot.turnLeft()
  elseif cz > z then
    robot.turnLeft(); forward(cz-z); robot.turnRight()
  end
  if cx < x then forward(x-cx)
  elseif cx > x then robot.turnAround(); forward(cx-x); robot.turnAround() end
  cx,cy,cz=x,y,z
end

print(posName() .. "Blöcke: " .. #blocks .. " | Start: " .. startIndex)
print("Roboterspitze: +X, Startposition = 0,0,0")

for i=startIndex,#blocks do
  local b=blocks[i]
  moveTo(b.x,b.y,b.z)
  if not placeBlock(b.meta) then
    saveState(i)
    computer.beep(400,0.5)
    return die("Material fehlt oder konnte nicht platziert werden bei " .. b.x .. "," .. b.y .. "," .. b.z .. " (ID " .. b.id .. ", meta " .. b.meta .. ")")
  end
  saveState(i+1)
  if i % 25 == 0 or i == #blocks then
    print(string.format("Fortschritt: %d/%d (%.1f%%)", i, #blocks, i/#blocks*100))
  end
end

os.remove(stateFile)
print("Fertig: " .. name)
computer.beep(1200,0.2)
