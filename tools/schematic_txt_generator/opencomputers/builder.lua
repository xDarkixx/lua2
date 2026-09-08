-- OpenComputers / Minecraft 1.7.10
-- Builds a SCHEMATIC_TXT 1 blueprint directly from ONE plain-text file.
-- No Schematica/Litematica/Minecraft-side converter is needed.
--
-- Usage: builder.lua blueprint.txt
--
-- Start the robot one block BEFORE blueprint X=0:
--   position = (-1, 0, 0), facing +X
-- Blueprint coordinates are 0..W-1, 0..H-1, 0..L-1.
-- The robot places blocks in front of itself, layer by layer.
--
-- Optional material mapping in the same TXT file:
--   slot=1,1:0
--   slot=2,4:0
-- means blueprint ID:meta 1:0 uses robot inventory slot 1.
-- If no mapping exists, the robot tries non-empty inventory slots.

local component = require("component")
local robot = require("robot")
local computer = require("computer")

local file = ...
if not file then
  io.stderr:write("Usage: builder.lua blueprint.txt\n")
  return
end

local function die(msg)
  io.stderr:write("ERROR: " .. msg .. "\n")
  return false
end

local function parse3(s)
  local a,b,c = s:match("^%s*(-?%d+)%s*,%s*(-?%d+)%s*,%s*(-?%d+)%s*$")
  if not a then return nil end
  return tonumber(a), tonumber(b), tonumber(c)
end

local function parsePair(s)
  local a,b = s:match("^%s*(%d+)%s*:%s*(%d+)%s*$")
  if not a then return nil end
  return tonumber(a), tonumber(b)
end

local f, err = io.open(file, "r")
if not f then return die(err or "Datei konnte nicht geöffnet werden") end

local W,H,L,name
local blocks = {}
local slotMap = {}
local validHeader = false

for line in f:lines() do
  line = line:gsub("^%s+", ""):gsub("%s+$", "")
  if line ~= "" and not line:match("^#") then
    if line == "SCHEMATIC_TXT 1" then
      validHeader = true
    elseif line:match("^name=") then
      name = line:sub(6)
    elseif line:match("^size=") then
      W,H,L = parse3(line:sub(6))
    elseif line:match("^slot=") then
      local slot,pair = line:match("^slot=(%d+),(.+)$")
      if slot and pair then
        local id,meta = parsePair(pair)
        if id then slotMap[id .. ":" .. meta] = tonumber(slot) end
      end
    elseif line:match("^materials=") then
      -- informational; actual inventory mapping can be supplied with slot= lines
    else
      local raw = line:gsub("%s+#%s*state=.*$", "")
      local xyz, rhs = raw:match("^%s*(.-)%s*=%s*(.-)%s*$")
      if not xyz or not rhs then
        f:close(); return die("Ungültige Blockzeile: " .. line)
      end
      local x,y,z = parse3(xyz)
      local id,meta = parsePair(rhs)
      if not x or not id then
        f:close(); return die("Ungültige Blockzeile: " .. line)
      end
      if not W or x < 0 or y < 0 or z < 0 or x >= W or y >= H or z >= L then
        f:close(); return die("Koordinate außerhalb: " .. x .. "," .. y .. "," .. z)
      end
      blocks[#blocks+1] = {x=x,y=y,z=z,id=id,meta=meta}
    end
  end
end
f:close()

if not validHeader then return die("SCHEMATIC_TXT 1 Header fehlt") end
if not W or not H or not L then return die("size= fehlt") end

-- Bottom-up and deterministic order.
table.sort(blocks, function(a,b)
  if a.y ~= b.y then return a.y < b.y end
  if a.z ~= b.z then return a.z < b.z end
  return a.x < b.x
end)

local stateFile = file .. ".state"
local startIndex = 1
local sf = io.open(stateFile, "r")
if sf then startIndex = tonumber(sf:read("*l")) or 1; sf:close() end
if startIndex < 1 or startIndex > #blocks + 1 then startIndex = 1 end

local function saveState(n)
  local s = io.open(stateFile, "w")
  if s then s:write(tostring(n)); s:close() end
end

local function forward(n)
  for _=1,n do
    while not robot.forward() do
      if robot.detect() then
        io.stderr:write("Hindernis vor dem Roboter. Entfernen und ENTER drücken.\n")
        io.read()
      else
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

-- Logical robot position. Actual start must be (-1,0,0), facing +X.
local cx,cy,cz = -1,0,0
local function moveTo(x,y,z)
  -- Move vertically first.
  if cy < y then up(y-cy) elseif cy > y then down(cy-y) end

  -- Move Z while returning to +X orientation afterwards.
  if cz < z then
    robot.turnRight(); forward(z-cz); robot.turnLeft()
  elseif cz > z then
    robot.turnLeft(); forward(cz-z); robot.turnRight()
  end

  -- Move X. Negative X is supported from the start position.
  if cx < x then
    forward(x-cx)
  elseif cx > x then
    robot.turnAround(); forward(cx-x); robot.turnAround()
  end
  cx,cy,cz=x,y,z
end

local function selectMaterial(id,meta)
  local mapped = slotMap[id .. ":" .. meta]
  if mapped and mapped >= 1 and mapped <= robot.inventorySize() and robot.count(mapped) > 0 then
    robot.select(mapped)
    return true
  end

  -- With inventory_controller, prefer an exact metadata match.
  if component.isAvailable("inventory_controller") then
    local ic = component.inventory_controller
    for slot=1,robot.inventorySize() do
      if robot.count(slot) > 0 then
        local stack = ic.getStackInInternalSlot(slot)
        if stack and (stack.damage == nil or tonumber(stack.damage) == meta) then
          robot.select(slot)
          return true
        end
      end
    end
  else
    for slot=1,robot.inventorySize() do
      if robot.count(slot) > 0 then
        robot.select(slot)
        return true
      end
    end
  end
  return false
end

local function placeBlock(b)
  if not selectMaterial(b.id,b.meta) then return false end
  return robot.place()
end

print("[" .. (name or "Schematic") .. "] " .. #blocks .. " Blöcke")
print("Start: Robot (-1,0,0), Blickrichtung +X")

for i=startIndex,#blocks do
  local b=blocks[i]
  -- Stand immediately before the target block. This lets the robot place the block
  -- without needing a special builder machine or a second file.
  moveTo(b.x-1,b.y,b.z)
  if not placeBlock(b) then
    saveState(i)
    computer.beep(400,0.5)
    return die("Material fehlt/Platzieren fehlgeschlagen: " .. b.id .. ":" .. b.meta .. " bei " .. b.x .. "," .. b.y .. "," .. b.z)
  end
  saveState(i+1)
  if i % 25 == 0 or i == #blocks then
    print(string.format("Fortschritt: %d/%d (%.1f%%)", i, #blocks, i/#blocks*100))
  end
end

os.remove(stateFile)
print("FERTIG: " .. (name or "Schematic"))
computer.beep(1200,0.2)
