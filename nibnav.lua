-- nibnav.lua
-- OpenComputers-MC1.7.10-1.8.10+667626d compatible navigation helper.
-- Inventory-safe navigation: NEVER breaks blocks.

local robot = require("robot")
local sides = require("sides")
local computer = require("computer")

local nibnav = {}
local NORTH, SOUTH = sides.north, sides.south
local EAST, WEST = sides.east, sides.west
local POS_X, NEG_X = sides.east, sides.west
local POS_Z, NEG_Z = sides.south, sides.north

local function yieldNow()
  computer.pullSignal(0)
end

local position = {x=0, y=0, z=0, facing=NORTH}

function nibnav.getFacing() return position.facing end
function nibnav.getPosition() return position.x, position.y, position.z end
function nibnav.getX() return position.x end
function nibnav.getY() return position.y end
function nibnav.getZ() return position.z end

local function updateForward()
  if position.facing == POS_X then position.x = position.x + 1
  elseif position.facing == NEG_X then position.x = position.x - 1
  elseif position.facing == POS_Z then position.z = position.z + 1
  elseif position.facing == NEG_Z then position.z = position.z - 1 end
end

function nibnav.turnLeft()
  local ok, err = robot.turnLeft()
  yieldNow()
  if ok then
    if position.facing == NORTH then position.facing = WEST
    elseif position.facing == WEST then position.facing = SOUTH
    elseif position.facing == SOUTH then position.facing = EAST
    else position.facing = NORTH end
  end
  return ok, err
end

function nibnav.turnRight()
  local ok, err = robot.turnRight()
  yieldNow()
  if ok then
    if position.facing == NORTH then position.facing = EAST
    elseif position.facing == EAST then position.facing = SOUTH
    elseif position.facing == SOUTH then position.facing = WEST
    else position.facing = NORTH end
  end
  return ok, err
end

function nibnav.turnAround()
  local ok, err = nibnav.turnRight()
  if not ok then return false, err end
  return nibnav.turnRight()
end

function nibnav.faceSide(side)
  if side == sides.up or side == sides.down then return true end
  if position.facing == side then return true end
  if (position.facing == NORTH and side == SOUTH) or
     (position.facing == SOUTH and side == NORTH) or
     (position.facing == EAST and side == WEST) or
     (position.facing == WEST and side == EAST) then
    return nibnav.turnAround()
  end
  if (position.facing == NORTH and side == EAST) or
     (position.facing == EAST and side == SOUTH) or
     (position.facing == SOUTH and side == WEST) or
     (position.facing == WEST and side == NORTH) then
    return nibnav.turnRight()
  end
  return nibnav.turnLeft()
end

function nibnav.forward()
  if robot.detect() then
    return false, "Path blocked: front block was not broken (inventory-safe mode)"
  end
  local ok, err = robot.forward()
  yieldNow()
  if ok then updateForward() end
  return ok, err
end

function nibnav.back()
  local ok, err = robot.back()
  yieldNow()
  if ok then
    if position.facing == POS_X then position.x = position.x - 1
    elseif position.facing == NEG_X then position.x = position.x + 1
    elseif position.facing == POS_Z then position.z = position.z - 1
    else position.z = position.z + 1 end
  end
  return ok, err
end

function nibnav.up()
  if robot.detectUp() then return false, "Path blocked: block above was not broken (inventory-safe mode)" end
  local ok, err = robot.up()
  yieldNow()
  if ok then position.y = position.y + 1 end
  return ok, err
end

function nibnav.down()
  if robot.detectDown() then return false, "Path blocked: block below was not broken (inventory-safe mode)" end
  local ok, err = robot.down()
  yieldNow()
  if ok then position.y = position.y - 1 end
  return ok, err
end

function nibnav.move(direction, distance, wrapper)
  direction, distance = tonumber(direction), tonumber(distance)
  if not direction or not distance then return false, "direction and distance must be numbers" end
  if distance <= 0 then return true end
  local ok, err = nibnav.faceSide(direction)
  if not ok then return false, err end
  for i=1,distance do
    local moved, moveErr
    if direction == sides.up then moved, moveErr = nibnav.up()
    elseif direction == sides.down then moved, moveErr = nibnav.down()
    else moved, moveErr = nibnav.forward() end
    if not moved then return false, moveErr end
    yieldNow()
  end
  return true
end

function nibnav.moveX(x)
  x = tonumber(x); if not x then return false, "x must be a number" end
  if x == position.x then return true end
  local direction = position.x < x and POS_X or NEG_X
  return nibnav.move(direction, math.abs(position.x-x))
end

function nibnav.moveY(y)
  y = tonumber(y); if not y then return false, "y must be a number" end
  if y == position.y then return true end
  local direction = position.y < y and sides.up or sides.down
  return nibnav.move(direction, math.abs(position.y-y))
end

function nibnav.moveZ(z)
  z = tonumber(z); if not z then return false, "z must be a number" end
  if z == position.z then return true end
  local direction = position.z < z and POS_Z or NEG_Z
  return nibnav.move(direction, math.abs(position.z-z))
end

function nibnav.moveXZ(x,z)
  x,z = tonumber(x),tonumber(z)
  if not x or not z then return false,"x,z must be numbers" end
  local ok,err = nibnav.moveX(x)
  if not ok then return false,err end
  return nibnav.moveZ(z)
end

function nibnav.setPosition(x,y,z,facing)
  x,y,z,facing=tonumber(x),tonumber(y),tonumber(z),tonumber(facing)
  if not x or not y or not z then error("Invalid x,y,z") end
  if facing ~= NORTH and facing ~= SOUTH and facing ~= EAST and facing ~= WEST then error("Invalid facing") end
  position.x,position.y,position.z,position.facing=x,y,z,facing
end

function nibnav.distancesq(x1,y1,z1,x2,y2,z2)
  local dx,dy,dz=x2-x1,y2-y1,z2-z1
  return dx*dx+dy*dy+dz*dz
end
function nibnav.distance(x1,y1,z1,x2,y2,z2)
  return math.sqrt(nibnav.distancesq(x1,y1,z1,x2,y2,z2))
end
function nibnav.getCost(x,y,z)
  return math.abs(position.x-x)+math.abs(position.y-y)+math.abs(position.z-z)
end

return nibnav
