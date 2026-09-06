-- BULDACITY TIER-3 MAIN STARTER
-- One command to start the complete OC Tier-3 stack.
local component=require("component")
local computer=require("computer")
local Config=require("network-modern.Tier3Config")
local Logger=require("network-modern.Tier3Logger")
local Storage=require("network-modern.Tier3Storage")

if not component.isAvailable("modem") then error("BULDACITY TIER-3: modem/network card fehlt") end
Logger.init(Config.logFile)
Storage.init(Config.stateFile)
Logger.info("Tier-3 boot",{event="BOOT"})

local state=Storage.load({bootCount=0,lastBoot=0})
state.bootCount=(state.bootCount or 0)+1
state.lastBoot=computer.uptime()
Storage.save(state)

print("BULDACITY TIER-3 CONTROL")
print("CORE: "..Config.nodeId)
print("PORT: "..tostring(Config.port))
print("Boot: "..tostring(state.bootCount))
print("Starting central server...")

local ok,err=pcall(dofile,"/home/Tier3Server.lua")
if not ok then
  Logger.error("Tier-3 server stopped",{reason=err})
  error(err)
end
Logger.info("Tier-3 stopped",{event="STOP"})
