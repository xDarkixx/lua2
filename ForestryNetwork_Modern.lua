-- ForestryNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Forestry // Control Center",{controller="Forestry_Modern.lua",mod="Forestry",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("Forestry_Modern.lua"))
