-- Buldacity network wrapper for ImmersiveRailroading_Modern.lua
local ok,net=pcall(require,"BuldacityNetworkClient")
if ok and net and net.start then pcall(net.start) end
dofile("/ImmersiveRailroading_Modern.lua")
