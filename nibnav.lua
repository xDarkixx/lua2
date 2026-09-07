-- nibnav.lua
-- OpenComputers-MC1.7.10-1.8.10+667626d compatible navigation helper.
-- Inventory-safe mode: NEVER breaks blocks while navigating, so no drops are collected.

local robot = require("robot")
local sides = require("sides")

local nibnav = {}
local NORTH = sides.north
local SOUTH = sides.south
local EAST  = sides.east
local WEST  = sides.west
local POS_X = sides.posx or EAST
local NEG_X = sides.negx or WEST
local POS_Z = sides.posz or SOUTH
local NEG_Z = sides.negz or NORTH

nibnav.sideLookup = {
  turn = {
    [NORTH] = {[SOUTH] = 2, [EAST] = 1, [WEST] = -1},
    [SOUTH] = {[NORTH] = 2, [EAST] = -1, [WEST] = 1},
    [EAST]  = {[NORTH] = -1, [SOUTH] = 1, [WEST] = 2},
    [WEST]  = {[NORTH] = 1, [SOUTH] = -1, [EAST] = 2}
  },
  translation = {
    [NORTH] = {[sides.front] = NORTH, [sides.back] = SOUTH, [sides.left] = WEST, [sides.right] = EAST},
    [SOUTH] = {[sides.front] = SOUTH, [sides.back] = NORTH, [sides.left] = EAST, [sides.right] = WEST},
    [EAST]  = {[sides.front] = EAST, [sides.back] = WEST, [sides.left] = NORTH, [sides.right] = SOUTH},
    [WEST]  = {[sides.front] = WEST, [sides.back] = EAST, [sides.left] = SOUTH, [sides.right] = NORTH}
  },
  offsets = {
    [sides.down] = {0, -1, 0}, [sides.up] = {0, 1, 0},
    [NORTH] = {0, 0, -1}, [SOUTH] = {0, 0, 1},
    [WEST] = {-1, 0, 0}, [EAST] = {1, 0, 0}
  },
  valid = {sides.down, sides.up, NORTH, SOUTH, WEST, EAST}
}

local position = {x = 0, y = 0, z = 0, facing = NORTH}

local function action(actionFn, afterFn, ...)
  local ok, err = actionFn()
  if ok and afterFn then afterFn(...) end
  return ok, err
end

local function repeatAction(times, fn, ...)
  for _ = 1, times do
    local ok, err = fn(...)
    if not ok then return nil, err end
  end
  return true
end

local function protected(fn, ...)
  local ok, result = pcall(fn, ...)
  if ok then return true end
  return nil, result
end

function nibnav.getFacing() return position.facing end
function nibnav.getFacingFromSide(side)
  if side == sides.up or side == sides.down then return side end
  local lookup = nibnav.sideLookup.translation[position.facing]
  assert(lookup and lookup[side], "Invalid side")
  return lookup[side]
end

function nibnav.getPosition() return position.x, position.y, position.z end
-- Compatibility getters for older AutoBuild versions.
function nibnav.getX() return position.x end
function nibnav.getY() return position.y end
function nibnav.getZ() return position.z end

function nibnav.turnLeft()
  local newFacing = nibnav.sideLookup.translation[position.facing][sides.left]
  return action(robot.turnLeft, function() position.facing = newFacing end)
end
function nibnav.turnRight()
  local newFacing = nibnav.sideLookup.translation[position.facing][sides.right]
  return action(robot.turnRight, function() position.facing = newFacing end)
end
function nibnav.turnAround()
  local ok, err = nibnav.turnRight()
  if not ok then return nil, err end
  return nibnav.turnRight()
end
function nibnav.faceSide(side)
  if position.facing == side then return true end
  local turns = nibnav.sideLookup.turn[position.facing]
  local turn = turns and turns[side]
  assert(turn, "Unable to face side: " .. tostring(side))
  if turn == 2 then return nibnav.turnAround() end
  if turn == 1 then return nibnav.turnRight() end
  return nibnav.turnLeft()
end

function nibnav.forward()
  if robot.detect() then
    return nil, "Path blocked: front block was not broken (inventory-safe mode)"
  end
  return action(robot.forward, function()
    if position.facing == POS_X then position.x = position.x + 1
    elseif position.facing == NEG_X then position.x = position.x - 1
    elseif position.facing == POS_Z then position.z = position.z + 1
    elseif position.facing == NEG_Z then position.z = position.z - 1 end
  end)
end
function nibnav.back()
  return action(robot.back, function()
    if position.facing == POS_X then position.x = position.x - 1
    elseif position.facing == NEG_X then position.x = position.x + 1
    elseif position.facing == POS_Z then position.z = position.z - 1
    elseif position.facing == NEG_Z then position.z = position.z + 1 end
  end)
end
function nibnav.up()
  if robot.detectUp() then
    return nil, "Path blocked: block above was not broken (inventory-safe mode)"
  end
  return action(robot.up, function() position.y = position.y + 1 end)
end
function nibnav.down()
  if robot.detectDown() then
    return nil, "Path blocked: block below was not broken (inventory-safe mode)"
  end
  return action(robot.down, function() position.y = position.y - 1 end)
end

function nibnav.move(direction, distance, wrapper)
  direction, distance = tonumber(direction), tonumber(distance)
  assert(direction and distance, "direction and distance must be numbers")
  if distance <= 0 then return true end
  wrapper = wrapper or function(moveFn) return moveFn() end
  assert(type(wrapper) == "function", "wrapper must be a function")
  return protected(function()
    local moveFn
    if direction == sides.up then moveFn = nibnav.up
    elseif direction == sides.down then moveFn = nibnav.down
    else
      assert(nibnav.sideLookup.turn[direction], "invalid direction")
      local ok, err = nibnav.faceSide(direction)
      if not ok then error(err or "unable to turn", 0) end
      moveFn = nibnav.forward
    end
    local ok, err = repeatAction(distance, wrapper, moveFn)
    if not ok then error(err or "movement failed", 0) end
  end)
end
function nibnav.moveX(x, wrapper)
  x = tonumber(x); assert(x, "x must be a number")
  return nibnav.move(position.x < x and POS_X or NEG_X, math.abs(position.x - x), wrapper)
end
function nibnav.moveY(y, wrapper)
  y = tonumber(y); assert(y, "y must be a number")
  return nibnav.move(position.y < y and sides.up or sides.down, math.abs(position.y - y), wrapper)
end
function nibnav.moveZ(z, wrapper)
  z = tonumber(z); assert(z, "z must be a number")
  return nibnav.move(position.z < z and POS_Z or NEG_Z, math.abs(position.z - z), wrapper)
end
function nibnav.moveXZ(x, z, wrapper)
  x, z = tonumber(x), tonumber(z)
  assert(x and z, "x and z must be numbers")
  return protected(function()
    local zDirection = position.z < z and POS_Z or NEG_Z
    if position.facing == zDirection then
      assert(nibnav.moveZ(z, wrapper))
      assert(nibnav.moveX(x, wrapper))
    else
      assert(nibnav.moveX(x, wrapper))
      assert(nibnav.moveZ(z, wrapper))
    end
  end)
end
function nibnav.setPosition(x, y, z, facing)
  x, y, z, facing = tonumber(x), tonumber(y), tonumber(z), tonumber(facing)
  assert(x and y and z, "Invalid x,y,z")
  assert(nibnav.sideLookup.turn[facing], "Invalid facing")
  position.x, position.y, position.z, position.facing = x, y, z, facing
end
function nibnav.distancesq(x1, y1, z1, x2, y2, z2)
  local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
  return dx * dx + dy * dy + dz * dz
end
function nibnav.distance(x1, y1, z1, x2, y2, z2)
  return math.sqrt(nibnav.distancesq(x1, y1, z1, x2, y2, z2))
end
function nibnav.getCost(x, y, z)
  x, y, z = tonumber(x), tonumber(y), tonumber(z)
  assert(x and y and z, "x,y,z must be numbers")
  local dx, dy, dz = math.abs(position.x - x), math.abs(position.y - y), math.abs(position.z - z)
  local cost = dx + dy + dz
  if dx > 0 or dz > 0 then
    local wanted = dx >= dz and (position.x < x and POS_X or NEG_X) or (position.z < z and POS_Z or NEG_Z)
    local turn = nibnav.sideLookup.turn[position.facing]
    if turn and turn[wanted] then cost = cost + math.abs(turn[wanted]) * 0.25 end
  end
  return cost
end

return nibnav
