-- ThermalExpansionNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Thermal Expansion // Control Center",{controller="ThermalExpansion_Modern.lua",mod="Thermal Expansion",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("ThermalExpansion_Modern.lua"))
