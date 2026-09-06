-- ExtraPlanetsNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Extra Planets // Control Center",{controller="ExtraPlanets_Modern.lua",mod="Extra Planets",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("ExtraPlanets_Modern.lua"))
