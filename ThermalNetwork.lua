-- ThermalNetwork.lua
-- BULDACITY/2 network wrapper for the normal Thermal controller.
-- Minecraft 1.7.10 / Thermal Expansion 4 / Thermal Dynamics / Thermal Foundation

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("Thermal // Command Center",{
  controller="Thermal_Modern.lua",
  mod="Thermal",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("Thermal_Modern.lua"))
