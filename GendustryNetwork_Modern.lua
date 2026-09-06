-- GendustryNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("Gendustry // Control Center",{controller="Gendustry_Modern.lua",mod="Gendustry",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("Gendustry_Modern.lua"))
