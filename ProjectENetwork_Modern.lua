-- ProjectENetwork_Modern.lua
-- BULDACITY/2 network wrapper for ProjectE_Modern.lua.
-- Minecraft 1.7.10 / ProjectE PE1.10.1

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("ProjectE // Command Center",{
  controller="ProjectE_Modern.lua",
  mod="ProjectE",
  version="PE1.10.1",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("ProjectE_Modern.lua"))
