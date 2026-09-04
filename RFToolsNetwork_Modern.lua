-- RFToolsNetwork_Modern.lua
-- BULDACITY/2 network wrapper for RFTools_Modern.lua.
-- Minecraft 1.7.10 / RFTools 4.23

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("RFTools // Command Center",{
  controller="RFTools_Modern.lua",
  mod="RFTools",
  version="4.23",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("RFTools_Modern.lua"))
