-- ImmersiveEngineering_Network_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Immersive Engineering // Control Center",{controller="ImmersiveEngineering_Modern.lua",mod="Immersive Engineering",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("ImmersiveEngineering_Modern.lua"))
