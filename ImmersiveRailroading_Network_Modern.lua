-- Network wrapper for ImmersiveRailroading_Modern.lua
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then pcall(net.startClient,"Immersive Railroading",{controller="ImmersiveRailroading_Modern.lua"}) end
local shell=require("shell")
dofile(shell.resolve("ImmersiveRailroading_Modern.lua"))
