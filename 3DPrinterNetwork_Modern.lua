-- 3DPrinterNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("3D Printer // Control Center",{controller="3DPrinter_Modern.lua",mod="3D Printer",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("3DPrinter_Modern.lua"))
