-- BuldacityNetworkInstall.lua
-- Validate the complete Buldacity/2 Tier-3 network desktop stack.
local fs=require("filesystem")
local files={
 "BuldacityWireless.lua",
 "BuldacityNetworkClient.lua",
 "BuldacityNetworkLauncher.lua",
 "BuldacityControllerLauncher.lua",
 "BuldacityOS_Tier3.lua"
}
print("BULDACITY NETWORK INSTALL // BULDACITY/2")
for _,name in ipairs(files) do print((fs.exists(name) and "OK   " or "MISS ")..name) end
print("Protocol: BULDACITY/2")
print("Port: 4242")
print("Server: BuldacityOS_Tier3.lua")
print("Client: BuldacityNetworkClient.lua")
print("Controllers: BuldacityControllerLauncher.lua")
