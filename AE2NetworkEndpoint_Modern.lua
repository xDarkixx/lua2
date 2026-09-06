-- AE2NetworkEndpoint_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("AE2 // ME Command Center",{controller="AE2Network_Modern.lua",mod="Applied Energistics 2",version="rv3 beta 6",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("AE2Network_Modern.lua"))
