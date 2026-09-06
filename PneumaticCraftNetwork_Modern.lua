-- PneumaticCraftNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("PneumaticCraft // Control Center",{controller="PneumaticCraft_Modern.lua",mod="PneumaticCraft",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("PneumaticCraft_Modern.lua"))
