-- GendustryNetwork_Modern.lua
-- BULDACITY/2 network wrapper for Gendustry_Modern.lua.
-- The Modern controller remains unchanged; this file only adds the shared client bridge.

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("Gendustry // Command Center",{
  controller="Gendustry_Modern.lua",
  mod="Gendustry",
  version="1.6.4.135",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("Gendustry_Modern.lua"))
