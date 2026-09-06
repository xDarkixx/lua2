-- BULDACITY TIER-3 MAIN STARTER
local component=require("component")
local computer=require("computer")
local Config=require("network-modern.Tier3Config")
local Logger=require("network-modern.Tier3Logger")
local Storage=require("network-modern.Tier3Storage")
if not component.isAvailable("modem") then error("BULDACITY TIER-3: modem/network card fehlt") end
Logger.init(Config.logFile);Storage.init(Config.stateFile);Logger.info("Tier-3 boot",{event="BOOT"})
local state=Storage.load({bootCount=0,lastBoot=0});state.bootCount=(state.bootCount or 0)+1;state.lastBoot=computer.uptime();Storage.save(state)
print("BULDACITY TIER-3 CONTROL | CORE "..Config.nodeId.." | PORT "..tostring(Config.port))
local ok,err=pcall(dofile,"/home/network-modern/Tier3Server.lua")
if not ok then Logger.error("Tier-3 server stopped",{reason=err});error(err) end
Logger.info("Tier-3 stopped",{event="STOP"})
