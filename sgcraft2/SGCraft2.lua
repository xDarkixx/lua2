-- BULDACITY/2 SGCraft2
-- Separate next-generation entry point. Existing SGCraft files are not modified.

local component = require("component")
local computer = require("computer")

local function has(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function ensure(name, url)
  if has("/home/" .. name) then return true end
  if not component.isAvailable("internet") then return false, "Internet Card fehlt: " .. name end
  local ok, result = pcall(function()
    local req = require("internet").request(url)
    local f = io.open("/home/" .. name .. ".download", "w")
    if not f then error("cannot write /home/" .. name) end
    for chunk in req do f:write(chunk) end
    f:close()
    os.remove("/home/" .. name)
    os.rename("/home/" .. name .. ".download", "/home/" .. name)
  end)
  if not ok then return false, tostring(result) end
  return has("/home/" .. name)
end

local base = "https://raw.githubusercontent.com/xDarkixx/lua2/main/"
local files = {
  {"SGCraftAPI.lua", base .. "clients/sgcraft/SGCraftAPI.lua"},
  {"SGCraftVisual.lua", base .. "clients/sgcraft/SGCraftVisual.lua"},
  {"SGCraft_Buldacity_v3.lua", base .. "SGCraft_Buldacity_v3.lua"}
}

for _, file in ipairs(files) do
  local ok, err = ensure(file[1], file[2])
  if not ok then
    io.write("SGCraft2: " .. tostring(err) .. "\n")
    return
  end
end

if not has("/home/SGCraft_Buldacity_v3.lua") then
  io.write("SGCraft2: UI nicht vorhanden\n")
  return
end

dofile("/home/SGCraft_Buldacity_v3.lua")
computer.beep(1000, 0.05)
