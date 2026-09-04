-- MekanismNetwork_Modern.lua
-- BULDACITY/2 network wrapper for Mekanism_Modern.lua.
-- Minecraft 1.7.10 / Mekanism 9.1.1.1031

local Network=require("Network")
local ok,mode=Network.startClient("Mekanism // Command Center",{
  controller="Mekanism_Modern.lua",
  mod="Mekanism",
  version="9.1.1.1031",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile("Mekanism_Modern.lua")
