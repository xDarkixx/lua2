-- ThermalExpansionNetwork_Modern.lua
-- BULDACITY/2 network wrapper for ThermalExpansion_Modern.lua.
-- Minecraft 1.7.10 / Thermal Expansion 4.1.5-248

local Network=require("Network")
local ok,mode=Network.startClient("Thermal Expansion // Command Center",{
  controller="ThermalExpansion_Modern.lua",
  mod="Thermal Expansion",
  version="4.1.5-248",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile("ThermalExpansion_Modern.lua")
