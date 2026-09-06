-- ImmersiveRailroading_Network_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Immersive Railroading // Control Center",{controller="ImmersiveRailroading_Modern.lua",mod="Immersive Railroading",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("ImmersiveRailroading_Modern.lua"))
