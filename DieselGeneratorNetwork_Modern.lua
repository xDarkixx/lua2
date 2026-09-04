-- DieselGeneratorNetwork_Modern.lua
-- BULDACITY/2 network wrapper for DieselGenerator_Modern.lua.
-- Minecraft 1.7.10 / Immersive Engineering

local Network=require("Network")
local ok,mode=Network.startClient("Diesel Generator // Control Center",{
  controller="DieselGenerator_Modern.lua",
  mod="Immersive Engineering",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile("DieselGenerator_Modern.lua")
