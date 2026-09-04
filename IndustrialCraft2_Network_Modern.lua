-- Buldacity network wrapper for IndustrialCraft2_Modern.lua
local ok,net=pcall(require,"BuldacityNetworkClient")
if ok and net and net.start then pcall(net.start) end
dofile("/IndustrialCraft2_Modern.lua")
