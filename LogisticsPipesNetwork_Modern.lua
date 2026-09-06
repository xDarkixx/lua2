-- LogisticsPipesNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Logistics Pipes // Control Center",{controller="LogisticsPipes_Modern.lua",mod="Logistics Pipes",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("LogisticsPipes_Modern.lua"))
