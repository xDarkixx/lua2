-- PneumaticCraftNetwork_Modern.lua
-- Network-enabled launcher for PneumaticCraft_Modern.lua.
-- Tier-2 client uses the shared BULDACITY/1 network and can be controlled from Tier-3.
local netOk,net=pcall(require,"BuldacityNetworkClient")
if netOk and net then
  pcall(net.start,"BULDACITY // PNEUMATICCRAFT","CLIENT",{
    screen="ACTIVE",
    controller="PneumaticCraft_Modern.lua",
    mod="PneumaticCraft",
    version="1.12.7-152"
  })
end
local shell=require("shell")
local path=shell.resolve("PneumaticCraft_Modern.lua")
dofile(path)
