-- GalacticraftNetwork_Modern.lua
-- BULDACITY/2 network client wrapper for Galacticraft_Modern.lua.
-- The Modern controller remains unchanged; this file only adds the shared client bridge.

local Network=require("Network")
local ok,mode=Network.startClient("Galacticraft // Command Center",{
  controller="Galacticraft_Modern.lua",
  mod="Galacticraft",
  version="3.0.12.504",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile("/Galacticraft_Modern.lua")
