-- SGCraftNetwork_Modern.lua
-- BULDACITY // SGCraft Stargate Command Center - NETWORK
-- Starts the same graphical controller as SGCraft_Modern.lua, with BULDACITY network mode.

local Network = require("Network")
local shell = require("shell")

local ok, mode = Network.startClient(
  "BULDACITY // SGCraft Command Center",
  {controller="SGCraft_Modern.lua", mod="SGCraft", network=true}
)

if not ok then
  io.stderr:write("BULDACITY network unavailable: " .. tostring(mode) .. "\n")
end

local path = shell.resolve("SGCraft_Modern.lua")
local started, err = pcall(dofile, path)
if not started then
  io.stderr:write("Unable to start graphical SGCraft controller: " .. tostring(err) .. "\n")
end
