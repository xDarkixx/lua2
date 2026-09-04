-- ForestryNetwork_Modern.lua
-- BULDACITY/2 network client wrapper for Forestry_Modern.lua.
-- The Modern controller remains unchanged; this file only adds the shared client bridge.

local Network=require("Network")
local ok,mode=Network.startClient("Forestry // Command Center",{
  controller="Forestry_Modern.lua",
  mod="Forestry",
  version="4.2.16.64",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile("/Forestry_Modern.lua")
