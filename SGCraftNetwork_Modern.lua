-- SGCraftNetwork_Modern.lua
local Network=require("network-modern.Network")
local shell=require("shell")
local ok,mode=Network.startClient("BULDACITY // SGCraft Command Center",{controller="SGCraft_Modern.lua",mod="SGCraft",network=true})
if not ok then io.stderr:write("BULDACITY Modern Network unavailable: "..tostring(mode).."\n") end
dofile(shell.resolve("SGCraft_Modern.lua"))
