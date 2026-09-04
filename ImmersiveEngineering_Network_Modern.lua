-- Buldacity network wrapper for ImmersiveEngineering_Modern.lua
local ok,net=pcall(require,"BuldacityNetworkClient")
if ok and net and net.start then pcall(net.start) end
dofile("/ImmersiveEngineering_Modern.lua")
