-- ImmersiveIntegration_Network_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Immersive Integration // Control Center",{controller="ImmersiveIntegration_Modern.lua",mod="Immersive Integration",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("ImmersiveIntegration_Modern.lua"))
