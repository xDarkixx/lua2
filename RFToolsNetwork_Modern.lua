-- RFToolsNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("RFTools // Control Center",{controller="RFTools_Modern.lua",mod="RFTools",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("RFTools_Modern.lua"))
