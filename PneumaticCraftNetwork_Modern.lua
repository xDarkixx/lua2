-- PneumaticCraftNetwork_Modern.lua
local netOk,net=pcall(require,"Network")
if netOk and net and net.startClient then pcall(net.startClient,"PneumaticCraft",{screen="ACTIVE",controller="PneumaticCraft_Modern.lua",mod="PneumaticCraft",version="1.12.7-152"}) end
local shell=require("shell")
dofile(shell.resolve("PneumaticCraft_Modern.lua"))
