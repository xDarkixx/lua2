-- Network wrapper for ImmersiveEngineering_Modern.lua
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then pcall(net.startClient,"Immersive Engineering",{controller="ImmersiveEngineering_Modern.lua"}) end
dofile("/ImmersiveEngineering_Modern.lua")
