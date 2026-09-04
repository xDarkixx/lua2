-- Buldacity network wrapper for ImmersiveIntegration_Modern.lua
local ok,net=pcall(require,"BuldacityNetworkClient")
if ok and net and net.start then pcall(net.start) end
dofile("/ImmersiveIntegration_Modern.lua")
