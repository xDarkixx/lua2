-- Network wrapper for IndustrialCraft2_Modern.lua
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then pcall(net.startClient,"IndustrialCraft 2",{controller="IndustrialCraft2_Modern.lua"}) end
local shell=require("shell")
dofile(shell.resolve("IndustrialCraft2_Modern.lua"))
