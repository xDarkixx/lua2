-- LogisticsPipesNetwork_Modern.lua
-- Tier-2 Buldacity network launcher for LogisticsPipes_Modern.lua.
-- Network transport is provided by the repository's BuldacityNetworkClient.
local ok,net=pcall(require,"BuldacityNetworkClient")
if ok and net then pcall(net.start,"BULDACITY // LOGISTICS PIPES","CLIENT",{screen="ACTIVE",controller="LogisticsPipes_Modern.lua"}) end
local shell=require("shell")
dofile(shell.resolve("LogisticsPipes_Modern.lua"))
