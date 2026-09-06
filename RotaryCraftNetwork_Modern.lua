-- RotaryCraftNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("RotaryCraft // Control Center",{controller="RotaryCraftDashboard_Modern.lua",mod="RotaryCraft",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("RotaryCraftDashboard_Modern.lua"))
