-- 3DPrinterNetwork_Modern.lua
-- BULDACITY/2 network wrapper for 3DPrinter_Modern.lua.
-- Minecraft 1.7.10 / OpenComputers

local Network=require("Network")
local shell=require("shell")
local ok,mode=Network.startClient("3D Printer // Command Center",{
  controller="3DPrinter_Modern.lua",
  mod="OpenComputers 3D Printer",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

dofile(shell.resolve("3DPrinter_Modern.lua"))
