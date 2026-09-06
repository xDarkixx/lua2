-- IndustrialCraft2_Network_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("IndustrialCraft 2 // Control Center",{controller="IndustrialCraft2_Modern.lua",mod="IndustrialCraft 2",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("IndustrialCraft2_Modern.lua"))
