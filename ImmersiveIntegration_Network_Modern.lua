-- Network wrapper for ImmersiveIntegration_Modern.lua
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then pcall(net.startClient,"Immersive Integration",{controller="ImmersiveIntegration_Modern.lua"}) end
dofile("/ImmersiveIntegration_Modern.lua")
