-- LogisticsPipesNetwork_Modern.lua
local ok,net=pcall(require,"Network")
if ok and net and net.startClient then pcall(net.startClient,"Logistics Pipes",{controller="LogisticsPipes_Modern.lua"}) end
local shell=require("shell")
dofile(shell.resolve("LogisticsPipes_Modern.lua"))
