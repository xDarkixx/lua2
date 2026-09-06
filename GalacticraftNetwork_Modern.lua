-- GalacticraftNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Galacticraft // Control Center",{controller="Galacticraft_Modern.lua",mod="Galacticraft",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("Galacticraft_Modern.lua"))
