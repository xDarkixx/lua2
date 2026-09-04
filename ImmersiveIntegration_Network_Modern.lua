-- Network wrapper for ImmersiveIntegration_Modern.lua
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then pcall(net.startClient,"Immersive Integration",{controller="ImmersiveIntegration_Modern.lua"}) end
local shell=require("shell")
dofile(shell.resolve("ImmersiveIntegration_Modern.lua"))
