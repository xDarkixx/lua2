-- 3DPrinterNetwork_Modern.lua
-- BULDACITY/2 network wrapper for 3DPrinter_Modern.lua.
-- Minecraft 1.7.10 / OpenComputers
-- All BULDACITY files are loaded from /home.

local filesystem=require("filesystem")
local shell=require("shell")
local Network=require("Network")

local HOME="/home/"
pcall(function() shell.setWorkingDirectory(HOME) end)
package.path=HOME.."?.lua;"..HOME.."?/init.lua;"..(package.path or "")

local CONTROLLER="3DPrinter_Modern.lua"
local controllerPath=HOME..CONTROLLER
if not filesystem.exists(controllerPath) or filesystem.isDirectory(controllerPath) then
  error("BULDACITY 3D Printer controller not found: "..controllerPath)
end

local ok,mode=Network.startClient("3D Printer // Command Center",{
  controller=CONTROLLER,
  mod="OpenComputers 3D Printer",
  network=true
})
if not ok then
  io.stderr:write("BULDACITY Network unavailable: "..tostring(mode).."\n")
end

local loaded,err=pcall(dofile,controllerPath)
if not loaded then error("Unable to start /home/"..CONTROLLER..": "..tostring(err)) end
