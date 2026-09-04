-- RotaryCraftNetwork_Modern.lua
-- BULDACITY/2 network wrapper for RotaryCraftDashboard_Modern.lua.
-- Minecraft 1.7.10 / RotaryCraft V33a / OpenComputers 1.8.10

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("RotaryCraft // Command Center",{
  controller="RotaryCraftDashboard_Modern.lua",
  mod="RotaryCraft",
  version="V33a",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("RotaryCraftDashboard_Modern.lua"))
