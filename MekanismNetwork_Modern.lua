-- MekanismNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Mekanism // Control Center",{controller="Mekanism_Modern.lua",mod="Mekanism",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("Mekanism_Modern.lua"))
