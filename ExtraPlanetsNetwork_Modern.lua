-- ExtraPlanetsNetwork_Modern.lua
-- BULDACITY/2 network client wrapper for ExtraPlanets_Modern.lua.
-- The Modern controller remains unchanged; this file only adds the shared client bridge.

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("ExtraPlanets // Command Center",{
  controller="ExtraPlanets_Modern.lua",
  mod="ExtraPlanets",
  version="2.1.4",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("ExtraPlanets_Modern.lua"))
